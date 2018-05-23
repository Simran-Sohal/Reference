public class SeedDataRelationProcessingJob extends fsCore.BatchQueryableBase {
    
    private static final String CLASS_NAME = 'SeedDataRelationProcessingJob';
    private String mDataCategory {get; set;}
    
    
    // Valid values for pDataCategory are System or Sample
    public SeedDataRelationProcessingJob(String pDataCategory){
        mDataCategory = pDataCategory;
        super.setExecutionDate(System.today());
        super.setJobQuery(getQueryString());
        
    }
    //Default constructor will create System data
    // Not the sample data
    public SeedDataRelationProcessingJob(){
        mDataCategory = 'System';
        super.setExecutionDate(System.today());
        super.setJobQuery(getQueryString());
        
    }
    
    private String getQueryString(){
        //Logger.enter(CLASS_NAME, 'getQueryString');
        // Since there is a problem with custom metadata in 
        //selecting with where clause, so I am selecting all the records and will filter them later
        String queryString =
            ' SELECT Id '+
            ' , DeveloperName '+
            ' , fsCore__Is_Active__c '+
            ' , fsCore__Category__c '+
            ' , NamespacePrefix '+
            ' , fsCore__Execution_Order__c '+
            ' , fsCore__Seed_Data_Name__c '+
            ' FROM fsCore__Seed_Data_Setup__mdt ';
        
        //Logger.logMessage('Transaction Job Query : ' + queryString );
        //Logger.exit(CLASS_NAME, 'getQueryString');
        
        return queryString ;
        
    }
    
    public override String getClassName(){
        return CLASS_NAME;
    }
    
    public override void startJob(Database.BatchableContext pContext){
        
    }
    
    
    private String getCustomObjectFromMetadata(String pMetadataName){
        return (pMetadataName.replace('mdt', 'c')).replace('Seed_','');
    }
    
    private List<fsCore__Seed_Data_Setup__mdt> getSortedList(List<fsCore__Seed_Data_Setup__mdt> pSeedDataScopeList){
        fsCore.SeedDataSetupMdtWrapper[] seedDataScopeWrapperList =  new List<fsCore.SeedDataSetupMdtWrapper>();
        for(fsCore__Seed_Data_Setup__mdt seedDataSetup : pSeedDataScopeList) {
            seedDataScopeWrapperList.add(new fsCore.SeedDataSetupMdtWrapper(seedDataSetup,'Execution_Order__c'));
        }    
        seedDataScopeWrapperList.sort();
        pSeedDataScopeList.clear();
        
        for(fsCore.SeedDataSetupMdtWrapper seedDataSetup : seedDataScopeWrapperList) {
            pSeedDataScopeList.add(seedDataSetup.mSeedDataSetup);
        }  
        
        return pSeedDataScopeList;
        
    }  
    
    private List<fsCore__Seed_Data_Setup__mdt> getFilteredList(List<fsCore__Seed_Data_Setup__mdt> pSeedDataScopeList){
        List<fsCore__Seed_Data_Setup__mdt> seedDataList = new List<fsCore__Seed_Data_Setup__mdt>();
        for(fsCore__Seed_Data_Setup__mdt seedDataSetup : pSeedDataScopeList) {
            if ((seedDataSetup.fsCore__Is_Active__c)
                &&(seedDataSetup.fsCore__Category__c == mDataCategory)){
                    seedDataList.add(seedDataSetup);
                }
            
        }    
        
        return seedDataList;
        
    }  
    
    public override List<fsCore.ErrorObject> executeJob(Database.BatchableContext pContext
                                                        , List<SObject> pScope) {
                                                            
        //Logger.enter(CLASS_NAME, 'executeJob');
        //System.debug(LoggingLevel.ERROR, '>>>Execute Job, Initial Scope Size : ' + pScope.size()); 
        
        List<fsCore__Seed_Data_Setup__mdt> seedDataScopeList = (List<fsCore__Seed_Data_Setup__mdt>)pScope;
        List<fsCore.ErrorObject> errorList = new List<fsCore.ErrorObject>();
        
        //Logger.logMessage('Scope Count : ' + pScope.size());
        
        seedDataScopeList = getSortedList(seedDataScopeList);
        seedDataScopeList = getFilteredList(seedDataScopeList);
        
        //Logger.logMessage('Executing Job ' + CLASS_NAME + '...');
        //Logger.logMessage('Scope Count : ' + seedDataScopeList.size());
        System.debug(LoggingLevel.ERROR, '>>>Execute Job, Final Scope Size : ' + seedDataScopeList.size());  
        Map<String, Schema.DescribeFieldResult> sourceFieldMap;
        List<String> fieldsList ;
        Map<Id, Id> metaDataReferenceMap;
        
        
        for(fsCore__Seed_Data_Setup__mdt seedDataSetup : seedDataScopeList){
            
            
            String sourceDataObject = seedDataSetup.fsCore__Seed_Data_Name__c;/*fsCore.MetadataUtil.addNamespace(seedDataSetup.NamespacePrefix
                                                                       ,seedDataSetup.fsCore__Seed_Data_Name__c
                                                                       ,fsCore.Constants.DOUBLE_UNDERSCORE);*/
            
            
            String metaDataFieldName = fsCore.MetadataUtil.addNamespace(seedDataSetup.NamespacePrefix, 'Seed_Metadata_Id__c');
            String dObjectName = getCustomObjectFromMetadata(seedDataSetup.fsCore__Seed_Data_Name__c);
            String destinationObjectName = fsCore.MetadataUtil.addNamespace(seedDataSetup.NamespacePrefix, dObjectName);
            
            String existingRecordQueryCheck = 'select id,Name, '+metaDataFieldName+
                ' from '+ destinationObjectName +
                ' where '+metaDataFieldName+ ' != null ';
            
            
            
            List<sObject> existingRecordsList = database.query(existingRecordQueryCheck);  
            MAP<Id,sObject> existingRecordsMap = new MAP<Id,sObject>();
            Set<Id> existingMetadataIdSet = new Set<Id>();
            if (existingRecordsList.size() > 0){
                for(sObject checkRecs:existingRecordsList){
                    existingMetadataIdSet.add((Id)checkRecs.get(metaDataFieldName));
                    existingRecordsMap.put((Id)checkRecs.get(metaDataFieldName),checkRecs);
                }   
            } 
            
            
            /*****************Constructing the source query*****/
            
            
            sourceFieldMap = fsCore.MetadataUtil.getSObjectFields(sourceDataObject);
            String sourceFields = '';
            Set<String> selfLookupSet = new Set<String>();
            fieldsList = new List<String>();
            for(String sFields:sourceFieldMap.keySet()){
                if ((sFields.endsWithIgnoreCase('__c'))
                    ||(sFields.equalsIgnoreCase('Id'))){
                        if (sFields.endsWithIgnoreCase('Sid__c')){ //All the fields which ends with _Sid__c are self lookup Id fields
                            selfLookupSet.add(sFields);
                            //continue;
                        }
                        
                        //The below field(fsCore__Is_Available_For_Investor_Workbench__c) was deleted from the 
                        //custom object (fsCore__Seed_User_Parameter_Setup__c) but metadata (fsCore__Seed_User_Parameter_Setup__mdt)
                        // still have it. So skipping the seed data creation for this field.
                        if ((sFields == 'fsCore__Is_Available_For_Investor_Workbench__c')
                            && (sourceDataObject == 'fsCore__Seed_User_Parameter_Setup__mdt')){
                                continue;   
                            }
                        
                        
                        sourceFields += sFields+' ,';
                        fieldsList.add(sFields);
                    }
            }
            if(sourceFields.endsWith(',')){
                sourceFields = sourceFields.substring(0,sourceFields.lastIndexOf(','));
                
            }
            if (selfLookupSet.size()>0 ){
                
                String sourceQueryAllRecs = 
                    ' SELECT '+sourceFields+
                    ' ,DeveloperName '+
                    ' FROM '+sourceDataObject+
                    ' WHERE id In :existingMetadataIdSet ';
                
                system.debug(logginglevel.error,'sourceQueryAllRecs ==>'+sourceQueryAllRecs);
                
                List<sObject> sourceAllSObjList = database.query(sourceQueryAllRecs);   
                
                For ( String selfLookupFieldName : selfLookupSet){
                                        
                    List<sObject> sourceSObjList = new List<sObject> ();
                    MAP<String,sObject> sourceAllSObjMap = new MAP<String,sObject> ();
                    for(sObject sObjectRecs:sourceAllSObjList){
                        if (sObjectRecs.get(selfLookupFieldName) != null){
                            sourceSObjList.add(sObjectRecs);
                            system.debug(logginglevel.error,'Metadata =>'+sObjectRecs.get('fsCore__Name__c'));
                        }
                        sourceAllSObjMap.put((String)sObjectRecs.get('DeveloperName'),sObjectRecs);
                        
                    }
                    
                    
                    for(sObject sObjectRecs:sourceSObjList){
                        sObject relationShipObject = sourceAllSObjMap.get((String)sObjectRecs.get(selfLookupFieldName));
                        if (relationShipObject == null) continue;
                        sObject updateRow = existingRecordsMap.get((Id)sObjectRecs.get('Id'));
                        sObject referenceObjectRow = existingRecordsMap.get((Id)relationShipObject.get('Id'));
                        
                        //This below replace is to get the field name from object
                        // In metadata it will always be with sid__c but in actual object, it will be __c
                        updateRow.put(selfLookupFieldName.Replace('sid__c', '_c'),(Id)referenceObjectRow.get('Id'));
                        existingRecordsMap.put((Id)sObjectRecs.get('Id'),updateRow);
                    }
                    
                }
                
                List<sObject> updateRecordsList = new List<sObject>();
                for(Id recsToBeUpdated:existingRecordsMap.keySet()){
                    updateRecordsList.add(existingRecordsMap.get(recsToBeUpdated));
                    system.debug(logginglevel.error,'existingRecordsMap.get(recsToBeUpdated) :'+ (String)(existingRecordsMap.get(recsToBeUpdated)).get('Name'));
                }
                
                
                /*****************Constructing the source query End*****/
                
                
                Database.SaveResult[] srList = Database.update(updateRecordsList, true);
                
                
                fsCore.DMLResult result = new fsCore.DMLResult();
                for (Database.SaveResult sR : srList) {
                    system.debug(logginglevel.error,' is Success : '+sR.isSuccess()); 
                    if (sR.isSuccess()) {
                        result.addToSuccessRecords(sR.getId());
                    } else {
                        for(Database.Error err : sR.getErrors()){
                            system.debug(logginglevel.error,err);
                            result.addToErrors(err);
                        }
                    }
                }
                
                //Logger.logMessage('Number of records updated  for '+destinationObjectName+' : ' + updateRecordsList.size());
            }   
        }
        
        //Logger.exit(CLASS_NAME, 'executeJob');
        return errorList;
    }
    
    public override void finishJob(Database.BatchableContext pContext) {}
        
}
/*
 * Copyright (c) 2017 FinancialSpectra Pty Ltd
 * All rights reserved.
 *
 * Class Name   - SeedDataRelationProcessingJob 
 *
 * Description  - DO NOT RELEASE THIS JOB
 *                -- This is for the testing 
 * 
 * Developer(s) - ADagur
 *
 */
