public with sharing class ContractActivationProcessor implements fsCore.ActionProcessor{

    private fsCore.ActionInput mActionInput;
    private fsCore.ActionOutput mActionOutput;
    private Id mProcessingUserId;
    
    public ContractActivationProcessor(){
        this(UserInfo.getUserId());
    }
    public ContractActivationProcessor(Id pUserId){
        mProcessingUserId = pUserId;
        mActionInput = new fsCore.ActionInput();
        mActionOutput = new fsCore.ActionOutput();
    }
    
    public void setInput(fsCore.ActionInput pInput){
        mActionInput = pInput;
    }
    
    public void process(){
        //get contract activation transaction 
        fsCore__Transaction_Setup__c contractActivateTxn = getTransactionSetup();

        if (!mActionOutput.getIsSuccess() || contractActivateTxn == null){ return; }
        
        //get lending contract record
        List<Lending_Contract__c> contractList = [SELECT Id, Name, Contract_Date__c
                                                    FROM Lending_Contract__c
                                                   WHERE Id IN :mActionInput.getRecords()];
        
        //get contract disbursements map        
        Map<Id, List<Contract_Disbursement__c>> contractDisbsMap = getContractDisbursements();
        
        //get existing queued transactions for contract activation for the input contracts        
        Map<Id, Transaction_Processing_Queue__c> contractToExistingTxnMap 
                                            = getUnprocessedActivationTxn(contractActivateTxn.Id);
        
        //create transaction queue
        List<Transaction_Processing_Queue__c> queuedTxnList = new List<Transaction_Processing_Queue__c>();
        Map<String, RecordType> txnQueueRecordTypeMap = fsCore.RecordTypeUtil.getInstance()
                                                            .getRecordTypeMapByName(Schema.SObjectType.Transaction_Processing_Queue__c.getName());
                                                
        for(Lending_Contract__c contract : contractList){
            Transaction_Processing_Queue__c queuedTxn;
            
            if (contractToExistingTxnMap.containsKey(contract.Id)){
                queuedTxn = contractToExistingTxnMap.get(contract.Id);
            }
            else {
                queuedTxn = new Transaction_Processing_Queue__c();
                queuedTxn.Lending_Contract_Number__c = contract.Id;
                queuedTxn.Transaction_Date__c = contract.Contract_Date__c;
                queuedTxn.Transaction_Name__c = contractActivateTxn.Id;
                queuedTxn.Transaction_Operation_Type__c = contractActivateTxn.fsCore__Operation_Type__c;
            }

            queuedTxn.RecordTypeId = txnQueueRecordTypeMap.get(Constants.RECORD_TYPE_OPEN).Id;
            queuedTxn.Processing_Status__c = Constants.TRANSACTION_QUEUE_STATUS_PROCESSING;
            queuedTxn.Processing_User__c = mProcessingUserId;
            queuedTxn.Processing_Result__c = Constants.BLANK_STRING;
            queuedTxn.Related_Records__c = Constants.BLANK_STRING;
            
            if (contractDisbsMap.containsKey(contract.Id)){
                String relatedRecordJSON = SObjectJSONUtil.getJSONString(contractDisbsMap.get(contract.Id));
                relatedRecordJSON = relatedRecordJSON.length() > Constants.RELATED_REC_JSON_SIZE ? 
                                        relatedRecordJSON.substring(0, (Constants.RELATED_REC_JSON_SIZE - 1)) : relatedRecordJSON;

                queuedTxn.Related_Records__c = relatedRecordJSON;
            }
            
            queuedTxnList.add(queuedTxn);
        }
        
        fsCore.DMLResult txnQueueSaveRslt = QueuedTransactionDMLWrapper.getInstance().upsertData(queuedTxnList);
        if (txnQueueSaveRslt.hasErrors()){
            mActionOutput.addErrors(txnQueueSaveRslt.getErrorList());
        }
        
        //process queued transactions
        if (txnQueueSaveRslt.getSuccessRecordSet().size() > 0){
            TransactionProcessingObjectBuilder tpObject = new TransactionProcessingObjectBuilder();
            tpObject.addQueuedTransactions(txnQueueSaveRslt.getSuccessRecordSet());
            tpObject.build();
            
            TransactionProcessingGateway.processTransactions(tpObject.getTransactionProcessingObjectList(),false);
        }
    }


    public fsCore.ActionOutput getOutput(){
        return mActionOutput;
    }
    
    private fsCore__Transaction_Setup__c getTransactionSetup(){
        fsCore__Transaction_Setup__c contractActivateTxn;
        try{
            contractActivateTxn =  [SELECT Id, fsCore__Operation_Type__c
                                      FROM fsCore__Transaction_Setup__c
                                     WHERE fsCore__Transaction_Code__c = :TransactionConstants.CONTRACT_ACTIVATED
                                       AND fsCore__Is_Active__c = true];
        }
        catch (Exception e){
            fsCore.ErrorObject pError = new fsCore.ErrorObject();
            pError.setErrorMessage(fsCore.ExceptionMessageUtil.getExceptionMessage(e));
            if (mActionInput.getRecords().size() == 1){
                mActionOutput.setMessage(fsCore.ExceptionMessageUtil.getExceptionMessage(e));    
            }
            mActionOutput.addError(pError);
        }
        
        return contractActivateTxn;
    }

    private Map<Id, List<Contract_Disbursement__c>> getContractDisbursements(){
        List<Contract_Disbursement__c> contractDisbList = 
                                                 [SELECT Id, Lending_Contract_Number__c
                                                    FROM Contract_Disbursement__c
                                                   WHERE Lending_Contract_Number__c IN :mActionInput.getRecords()
                                                     AND Is_Future_Disbursement__c = false
                                                   ORDER BY Lending_Contract_Number__c, Id];
        
        Map<Id, List<Contract_Disbursement__c>> contractDisbsMap = new Map<Id, List<Contract_Disbursement__c>>();
        for (Contract_Disbursement__c disb : contractDisbList){
            List<Contract_Disbursement__c> ctDisbList = new List<Contract_Disbursement__c>();
            
            if (contractDisbsMap.containsKey(disb.Lending_Contract_Number__c)){
                ctDisbList = contractDisbsMap.get(disb.Lending_Contract_Number__c);
            }
            ctDisbList.add(disb);
            contractDisbsMap.put(disb.Lending_Contract_Number__c, ctDisbList);
        }
        
        return contractDisbsMap;
    }

    private Map<Id, Transaction_Processing_Queue__c> getUnprocessedActivationTxn(Id pActivationTxnId){
        Set<String> unprocessedTxnStatusSet = new Set<String>();
        unprocessedTxnStatusSet.add(Constants.TRANSACTION_QUEUE_STATUS_DRAFT);
        unprocessedTxnStatusSet.add(Constants.TRANSACTION_QUEUE_STATUS_READY);
        unprocessedTxnStatusSet.add(Constants.TRANSACTION_QUEUE_STATUS_ERROR);
        
        List<Transaction_Processing_Queue__c> existingQueuedTxnList = 
                                                 [SELECT Id, Name, RecordTypeId
                                                       , Lending_Contract_Number__c
                                                       , Transaction_Name__c
                                                       , Transaction_Date__c
                                                       , Transaction_Operation_Type__c
                                                       , Processing_Status__c
                                                       , Processing_User__c
                                                       , Processing_Result__c
                                                    FROM Transaction_Processing_Queue__c
                                                   WHERE Lending_Contract_Number__c IN :mActionInput.getRecords()
                                                     AND Transaction_Name__c = :pActivationTxnId
                                                     AND Processing_Status__c IN :unprocessedTxnStatusSet];
        
        Map<Id, Transaction_Processing_Queue__c> contractToExistingTxnMap = new Map<Id, Transaction_Processing_Queue__c>();
        for (Transaction_Processing_Queue__c queuedTxn : existingQueuedTxnList){
            contractToExistingTxnMap.put(queuedTxn.Lending_Contract_Number__c, queuedTxn);
        }
        
        return contractToExistingTxnMap;
    }
}
