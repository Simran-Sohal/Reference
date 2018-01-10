public with sharing class StageEvaluationProcessor{
    private static final String CLASS_NAME = 'StageEvaluationProcessor';
    
    private Map<String, fsCore__Stage_Setup__c> mStageSetupMap;
    private Map<Id, String> mContractToStageEnterMap;
    private Map<Id, String> mContractToStageExitMap;

    private Map<Id, Lending_Contract__c> mContractMap;
    private Map<Id, Map<String, Contract_Stage__c>> mActiveStagesMap;
    
    private List<Contract_Stage__c> mContractStageForUpsert;
    private Map<Id, fsCore.ErrorObject> mErrorMap;

    public StageEvaluationProcessor(Set<String> pStageCodeSet){
        setStageSetupMap(pStageCodeSet);
        
        mContractToStageEnterMap = new Map<Id, String>();
        mContractToStageExitMap = new Map<Id, String>();
    }
    
    private void setStageSetupMap(Set<String> pStageCodeSet){
        Set<String> allowedLOB = new Set<String>();
        allowedLOB.add(fsCore.Constants.LOB_SERVICING);
        allowedLOB.add(fsCore.Constants.LOB_COLLECTION);
        
        List<fsCore__Stage_Setup__c> stageList = 
                                [SELECT Id, fsCore__Stage_Code__c
                                   FROM fsCore__Stage_Setup__c
                                  WHERE fsCore__Stage_Code__c IN :pStageCodeSet
                                    AND fsCore__Is_Active__c = true
                                    AND fsCore__Line_Of_Business__c IN :allowedLOB
                                    AND fsCore__Object_Name__c = 'fsServ__Lending_Contract__c'];
        
        mStageSetupMap = new Map<String, fsCore__Stage_Setup__c>();
        for (fsCore__Stage_Setup__c stage : stageList){
            mStageSetupMap.put(stage.fsCore__Stage_Code__c, stage);
        }
    }
    
    public void setContractStageForEntry(Map<Id, String> pContractToStageEnterMap){
        mContractToStageEnterMap = pContractToStageEnterMap;
    }

    public void setContractStageForExit(Map<Id, String> pContractToStageExitMap){
        mContractToStageExitMap = pContractToStageExitMap;
    }
    
    public void process(){
        prepareMaps();
        
        mErrorMap = new Map<Id, fsCore.ErrorObject>();
        mContractStageForUpsert = new List<Contract_Stage__c>();
        
        //evaluate stages for entry
        if (mContractToStageEnterMap.size() > 0){
            processStageEntry();
        }

        //evaluate stages for exit
        if (mContractToStageExitMap.size() > 0){
            processStageExit();
        }
        
        //save records
        if (mContractStageForUpsert.size() > 0){
            fsCore.DMLResult stageDMLRslt = ContractStageDMLWrapper.getInstance().upsertData(mContractStageForUpsert);
            if (stageDMLRslt.hasErrors()){
                Database.UpsertResult[] stageUpsertRslt = stageDMLRslt.getUpsertResult();
                
                for (Integer i = 0; i < stageUpsertRslt.size(); i++){
                    if (!stageUpsertRslt.get(i).isSuccess()){
                        for(Database.Error err : stageUpsertRslt.get(i).getErrors()){
                            addError(mContractStageForUpsert.get(i).Lending_Contract_Number__c
                                   , String.valueOf(err.getStatusCode())
                                   , err.getMessage()
                                   , 'process() ... saving records');
                        }
                    }
                }
            }
        }
        
        //save errors to diagnostic log
        if (mErrorMap.size() > 0){
            fsCore.DiagnosticLogUtil.logErrors(CLASS_NAME, 'process', mErrorMap.values());
        }
    }
    
    private void prepareMaps(){
        Set<Id> contractIdSet = new Set<Id>();
        contractIdSet.addAll(mContractToStageEnterMap.keySet());
        contractIdSet.addAll(mContractToStageExitMap.keySet());
        
        mContractMap = new Map<Id, Lending_Contract__c>(
                          [SELECT Id, Name FROM Lending_Contract__c
                            WHERE Id IN :contractIdSet]);
        
        List<Contract_Stage__c> activeStages
                        = [SELECT Id
                                , Lending_Contract_Number__c
                                , Stage_Name__c
                                , Stage_Code__c
                                , Entry_Date_Time__c
                                , Exit_Date_Time__c
                             FROM Contract_Stage__c
                            WHERE Lending_Contract_Number__c IN :contractIdSet
                              AND Is_Active__c = true
                            ORDER BY Lending_Contract_Number__c, Entry_Date_Time__c]; 
        
        mActiveStagesMap = new Map<Id, Map<String, Contract_Stage__c>>();
        
        for (Contract_Stage__c ctStage : activeStages){
            Map<String, Contract_Stage__c> contractStages = new Map<String, Contract_Stage__c>();
            
            if (mActiveStagesMap.containsKey(ctStage.Lending_Contract_Number__c)){
                contractStages = mActiveStagesMap.get(ctStage.Lending_Contract_Number__c);
            }
            contractStages.put(ctStage.Stage_Code__c, ctStage);
            mActiveStagesMap.put(ctStage.Lending_Contract_Number__c, contractStages);
        }
    }

    private void processStageEntry(){
        for (Id contractId : mContractToStageEnterMap.keySet()){
            String stageToEnter = mContractToStageEnterMap.get(contractId);
            
            if (!isValid(contractId, stageToEnter)){ continue; }
            
            if (mActiveStagesMap.containsKey(contractId)){
                if (mActiveStagesMap.get(contractId).containsKey(stageToEnter)){
                    continue; //skip stage entry because an active record for same stage already exists
                }
            }
            
            
            Contract_Stage__c newStage = new Contract_Stage__c();
            newStage.Lending_Contract_Number__c = contractId;
            newStage.Stage_Name__c = mStageSetupMap.get(stageToEnter).Id;
            newStage.Entry_Date_Time__c = Datetime.now();
            
            mContractStageForUpsert.add(newStage);        
        }
    }
    
    private void processStageExit(){
        for (Id contractId : mContractToStageExitMap.keySet()){
            String stageToExit = mContractToStageExitMap.get(contractId);
            
            if (!isValid(contractId, stageToExit)){ continue; }
            
            if (mActiveStagesMap.containsKey(contractId)){
                if (mActiveStagesMap.get(contractId).containsKey(stageToExit)){
                    Contract_Stage__c stageForUpdate = mActiveStagesMap.get(contractId).get(stageToExit);
                    stageForUpdate.Exit_Date_Time__c = Datetime.now();
                    
                    mContractStageForUpsert.add(stageForUpdate);
                }
            }
        }
    
    }
    
    private Boolean isValid(Id pContractId, String pStageCode){
        if (!mContractMap.containsKey(pContractId)){
            addError(pContractId
                   , fsCore.Constants.VALIDATION_FAILURE
                   , String.format(Label.Contract_Not_Found_For_Id, new String[]{pContractId})
                   , 'isValid()');
            return false;
        }
        
        if (mContractMap.containsKey(pContractId) && !mStageSetupMap.containsKey(pStageCode)){
            addError(pContractId
                   , fsCore.Constants.VALIDATION_FAILURE
                   , String.format(Label.Stage_Not_Found_For_Code, new String[]{pStageCode})
                   , 'isValid()');
            return false;
        }
        return true;
    }
    
    private void addError(Id pContractId, String pErrorCode, String pErrorMsg, String pMethod){
        fsCore.ErrorObject errObj = new fsCore.ErrorObject();
        errObj.setErrorRecordId(pContractId);
        if (mContractMap.containsKey(pContractId)){
            errObj.setErrorRecordName(mContractMap.get(pContractId).Name);
        }
        errObj.setErrorCode(pErrorCode);
        errObj.setErrorMessage(pErrorMsg);
        errObj.setErrorStackTrace(CLASS_NAME + '.' + pMethod);
       
        mErrorMap.put(pContractId, errObj);
    }
}
