public with sharing class StageChecklistGenerator{

    private Set<Id> mApplicationIdSet;
    private Map<Id, fsCore__Lending_Application__c> mApplicationMap;
    private Map<Id, fsCore__Lending_Application_Stage__c> mApplicationToCurrentStageMap;
    
    private Map<String, Set<Id>> mApplicationToAvailableChecklistMap;
    private Map<Id, List<fsCore__Checklist_Detail_Setup__c>> mChecklistToItemsMap;
    private List<Lending_Application_Checklist_Item__c> mChecklistItemsForInsert;

    private Map<String, Schema.DescribeFieldResult> mApplicationFieldDescMap;

    public StageChecklistGenerator(Set<Id> pApplicationIdSet){
        mApplicationIdSet = pApplicationIdSet;
    }
    
    public void generate(){
        logMessage('--- generate(+) ---');
        
        /* fetch application records */
        mApplicationMap = fsCore.LendingApplicationUtil.getApplications(mApplicationIdSet);

        /* populate application Id to current stage record map */
        setApplicationCurrentStageMap();
        
        /* get available checklists by evaluating the mappings */
        fetchAvailableChecklists();
        
        /* get checklist items setup for available checklists */
        fetchChecklistSetup();
        
        /* delete existing checklist items for current stage */
        removeExistingChecklistItems();
        
        /* create new checklist items for current stage of application */
        createApplicationChecklistItems();

        logMessage('--- generate(-) ---');
    }
    
    private void setApplicationCurrentStageMap(){
        logMessage('--- setApplicationCurrentStageMap(+) ---');
        
        Set<String> applicableStageStatuses = new Set<String>();
        applicableStageStatuses.add(fsCore.Constants.STAGE_STATUS_OPEN);
        applicableStageStatuses.add(fsCore.Constants.STAGE_STATUS_PENDING);
        applicableStageStatuses.add(fsCore.Constants.STAGE_STATUS_VALIDATED);
        
        /* get current stages of the lending applicaitons */
        List<fsCore__Lending_Application_Stage__c> currentStages = 
                                            [SELECT Id, Name
                                                  , fsCore__Lending_Application_Number__c
                                                  , fsCore__Stage_Name__c
                                               FROM fsCore__Lending_Application_Stage__c
                                              WHERE fsCore__Lending_Application_Number__c IN :mApplicationIdSet
                                                AND fsCore__Stage_Status__c IN :applicableStageStatuses
                                                AND fsCore__Stage_Exit_Time__c = null
                                              ORDER BY fsCore__Lending_Application_Number__c,
                                                    fsCore__Stage_Entry_Time__c DESC];

        mApplicationToCurrentStageMap = new Map<Id, fsCore__Lending_Application_Stage__c>();

        for(fsCore__Lending_Application_Stage__c stage : currentStages){
            if (stage.fsCore__Stage_Name__c != mApplicationMap.get(stage.fsCore__Lending_Application_Number__c).fsCore__Current_Stage_Name__c){
                continue;
            }
            
            if (!mApplicationToCurrentStageMap.containsKey(stage.fsCore__Lending_Application_Number__c)){
                mApplicationToCurrentStageMap.put(stage.fsCore__Lending_Application_Number__c, stage);
            }
        }
        logMessage('--- setApplicationCurrentStageMap(-) ---');
    }

    private void fetchAvailableChecklists(){
        logMessage('--- fetchAvailableChecklists(+) ---');
        
        Set<Id> stageSetupIdSet = new Set<Id>();
        for (fsCore__Lending_Application_Stage__c stage : mApplicationToCurrentStageMap.values()){
            stageSetupIdSet.add(stage.fsCore__Stage_Name__c);
        }
        
        List<fsCore__Checklist_Setup__c> allStageChecklists = 
                                            [SELECT Id, Name
                                                  , fsCore__Stage_Name__c
                                                  , fsCore__Is_Loan__c
                                                  , fsCore__Is_Line__c
                                                  , fsCore__Is_Lease__c
                                                  , fsCore__Line_Of_Business__c
                                                  , fsCore__Default_Company_Availability__c
                                                  , fsCore__Default_Product_Availability__c
                                                  , fsCore__Default_Selection_Rule_Result__c
                                               FROM fsCore__Checklist_Setup__c
                                              WHERE fsCore__Stage_Name__c IN :stageSetupIdSet
                                                AND fsCore__Line_Of_Business__c = :fsCore.Constants.LOB_ORIGINATION
                                                AND fsCore__Is_Active__c = true
                                              ORDER BY fsCore__Selection_Order__c ASC];
        
        Map<Id, List<fsCore__Checklist_Setup__c>> stageToChecklistsMap = new Map<Id, List<fsCore__Checklist_Setup__c>>();

        for (fsCore__Checklist_Setup__c checklist : allStageChecklists){
            List<fsCore__Checklist_Setup__c> stageChecklists = new List<fsCore__Checklist_Setup__c>();
            
            if (stageToChecklistsMap.containsKey(checklist.fsCore__Stage_Name__c)){
                stageChecklists = stageToChecklistsMap.get(checklist.fsCore__Stage_Name__c);
            }
            
            stageChecklists.add(checklist);
            stageToChecklistsMap.put(checklist.fsCore__Stage_Name__c, stageChecklists);
        }
        
        //evaluate mappings for selected checklist setups
        Map<String, fsCore.MappingEvaluationInputObject> mappingEvalInputMap = new Map<String, fsCore.MappingEvaluationInputObject>();
        String productFamily;
        
        for (fsCore__Lending_Application__c application : mApplicationMap.values()){
            Id currentStageSetupId = mApplicationToCurrentStageMap.get(application.Id).fsCore__Stage_Name__c;
            
            if (!stageToChecklistsMap.containsKey(currentStageSetupId)){
                continue;
            }
            
            fsCore.MappingEvaluationInputObject applMappEvalObj = 
                                fsCore.LendingApplicationUtil.getMappingEvalInput(application, stageToChecklistsMap.get(currentStageSetupId));
            mappingEvalInputMap.put(String.valueOf(application.Id), applMappEvalObj);

            productFamily = application.fsCore__Product_Family__c;
        }
        
        fsCore.SetupMappingEvaluator checklistMappEval = new fsCore.SetupMappingEvaluator(mappingEvalInputMap
                                                                         , Schema.SObjectType.fsCore__Checklist_Setup__c.getName()
                                                                         , productFamily);
        
        mApplicationToAvailableChecklistMap = checklistMappEval.evaluate();
        
        logMessage('--- fetchAvailableChecklists(-) ---');
    }

    private void fetchChecklistSetup(){
        logMessage('--- fetchChecklistSetup(+) ---');
        
        Set<Id> checklistSetupIdSet = new Set<Id>();
        for(String applicationId : mApplicationToAvailableChecklistMap.keySet()){
            checklistSetupIdSet.addAll(mApplicationToAvailableChecklistMap.get(applicationId));
        }
        
        List<fsCore__Checklist_Detail_Setup__c> allChecklistItems = 
                                            [SELECT Id, Name
                                                  , fsCore__Checklist_Name__c
                                                  , fsCore__Action_Item__c
                                                  , fsCore__Action_Item_Type__c
                                                  , fsCore__Display_Order__c
                                                  , fsCore__Is_Required__c
                                                  , fsCore__Document_Classification__c
                                                  , fsCore__Object_Name__c
                                                  , fsCore__Field_Name__c
                                               FROM fsCore__Checklist_Detail_Setup__c
                                              WHERE fsCore__Checklist_Name__c IN :checklistSetupIdSet
                                                AND fsCore__Is_Active__c = true
                                              ORDER BY fsCore__Checklist_Name__c,
                                                    fsCore__Display_Order__c];
        
        mChecklistToItemsMap = new Map<Id, List<fsCore__Checklist_Detail_Setup__c>>();
        
        for (fsCore__Checklist_Detail_Setup__c checklistItem : allChecklistItems){
            List<fsCore__Checklist_Detail_Setup__c> checklistItems = new List<fsCore__Checklist_Detail_Setup__c>();
            
            if (mChecklistToItemsMap.containsKey(checklistItem.fsCore__Checklist_Name__c)){
                checklistItems = mChecklistToItemsMap.get(checklistItem.fsCore__Checklist_Name__c);
            }
            
            checklistItems.add(checklistItem);
            mChecklistToItemsMap.put(checklistItem.fsCore__Checklist_Name__c, checklistItems);
        }
        
        logMessage('--- fetchChecklistSetup(-) ---');
    }

    private void removeExistingChecklistItems(){
        logMessage('--- removeExistingChecklistItems(+) ---');

        Set<Id> currentStageRecordIdSet = new Set<Id>();
        for (fsCore__Lending_Application_Stage__c stage : mApplicationToCurrentStageMap.values()){
            currentStageRecordIdSet.add(stage.Id);
        }

        List<Lending_Application_Checklist_Item__c> existingChecklistItems = 
                                            [SELECT Id FROM Lending_Application_Checklist_Item__c
                                              WHERE Stage_Reference_Number__c IN :currentStageRecordIdSet];

        logMessage('--- Records to be deleted : ' + existingChecklistItems.size());

        Savepoint sp = Database.setSavepoint();
        try{
            fsCore.DMLResult deleteResult = LendingApplicationChkItemDMLWrapper.getInstance().deleteData(existingChecklistItems);
            if (deleteResult.hasErrors()) deleteResult.throwError();
        }
        catch (Exception e){
            logMessage('--- !!! EXCEPTION !!! ' + fsCore.ExceptionMessageUtil.getExceptionMessage(e));
            Database.rollback(sp);
            throw e;
        }

        logMessage('--- removeExistingChecklistItems(-) ---');
    }

    /* 
     * TO DO : get the application lending documents for 
     *         the matching document classifications from
     *         the selected checklist items 
     */
    private void createApplicationChecklistItems(){
        logMessage('--- createApplicationChecklistItems(+) ---');
        
        mChecklistItemsForInsert = new List<Lending_Application_Checklist_Item__c>();
        
        mApplicationFieldDescMap =  fsCore.MetadataUtil.getSObjectFields('fsCore__Lending_Application__c');
        
        for(String appIdString : mApplicationToAvailableChecklistMap.keySet()){
            Set<Id> availableChecklistSetupIds = mApplicationToAvailableChecklistMap.get(appIdString);
            
            Id applicationId = Id.valueOf(appIdString);
            Id currentStageId = mApplicationToCurrentStageMap.get(applicationId).Id;
            
            for(Id checklistId : availableChecklistSetupIds){
                for (fsCore__Checklist_Detail_Setup__c checklistItem : mChecklistToItemsMap.get(checklistId)){
                    mChecklistItemsForInsert.add(getApplicationChecklistItem(applicationId, currentStageId, checklistItem));
                }
            }
        } 

        logMessage('--- Records to be inserted : ' + mChecklistItemsForInsert.size());

        Savepoint sp = Database.setSavepoint();
        try{
            fsCore.DMLResult insertResult = LendingApplicationChkItemDMLWrapper.getInstance().insertData(mChecklistItemsForInsert);
            if (insertResult.hasErrors()) insertResult.throwError();
        }
        catch (Exception e){
            logMessage('--- !!! EXCEPTION !!! ' + fsCore.ExceptionMessageUtil.getExceptionMessage(e));
            Database.rollback(sp);
            throw e;
        }
        
        logMessage('--- createApplicationChecklistItems(-) ---');
    }

    private Lending_Application_Checklist_Item__c getApplicationChecklistItem(
                                            Id pApplicationId
                                          , Id pCurrentStageId
                                          , fsCore__Checklist_Detail_Setup__c pChecklistItemSetupRecord){

        Lending_Application_Checklist_Item__c appChecklistItem = new Lending_Application_Checklist_Item__c();
        
        appChecklistItem.Lending_Application_Number__c = pApplicationId;
        appChecklistItem.Stage_Reference_Number__c = pCurrentStageId;
        appChecklistItem.Checklist_Name__c = pChecklistItemSetupRecord.fsCore__Checklist_Name__c;
        appChecklistItem.Action_Item__c = pChecklistItemSetupRecord.fsCore__Action_Item__c;
        appChecklistItem.Action_Item_Type__c = pChecklistItemSetupRecord.fsCore__Action_Item_Type__c;
        appChecklistItem.Display_Order__c = pChecklistItemSetupRecord.fsCore__Display_Order__c;
        appChecklistItem.Is_Required__c = pChecklistItemSetupRecord.fsCore__Is_Required__c;
        
        /* set item value in case Data Field checklist item */
        if (pChecklistItemSetupRecord.fsCore__Action_Item_Type__c.equalsIgnoreCase('Data Field')){ //Replace with fsCore.Constants.CHECKLIST_ITEM_TYPE_DATA_FIELD
            //12-Jun-2017 : On this date, data field type checklist item is
            //              only supported for Lending Application object
            if (pChecklistItemSetupRecord.fsCore__Object_Name__c.equalsIgnoreCase('fsCore__Lending_Application__c')
                    && mApplicationFieldDescMap.containsKey(pChecklistItemSetupRecord.fsCore__Field_Name__c.toLowerCase())){
                
                fsCore__Lending_Application__c application = mApplicationMap.get(pApplicationId);
                Schema.DescribeFieldResult fieldDesc = mApplicationFieldDescMap.get(pChecklistItemSetupRecord.fsCore__Field_Name__c.toLowerCase());
                
                appChecklistItem.Item_Value__c = fsCore.TypeUtil.convertToString(application.get(fieldDesc.getName()), fieldDesc.getType());
            }
        }

        /* set matching record IDs in case of Document checklist item */
        if (pChecklistItemSetupRecord.fsCore__Action_Item_Type__c.equalsIgnoreCase('Document')){ //Replace with fsCore.Constants.CHECKLIST_ITEM_TYPE_DOCUMENT
            //appChecklistItem.Matching_Record_Ids__c = null;
        }

        return appChecklistItem;
    }

    private void logMessage(String pMessage){
        System.debug(loggingLevel.ERROR, pMessage);
    }
}
