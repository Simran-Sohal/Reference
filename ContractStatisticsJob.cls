global with sharing class ContractStatisticsJob extends fsCore.BatchQueryableBase{
    private static final String CLASS_NAME = 'ContractStatisticsJob';
    
    global ContractStatisticsJob(){
        setJobQuery(getDefaultQuery()); // this will set the query without branch code parameter
    }

    global override void setParameterizedJobQuery(){
        // this will set the query with branch code parameter, if branch code is set
        setJobQuery(getParameterizedQuery());
    }

    private String getDefaultQuery(){
        return getQuery().getQueryString();
    }

    private String getParameterizedQuery(){
        fsCore.DynamicQueryBuilder jobQuery = getQuery();
        
        //add branch code parameter to query
        if (String.isNotBlank(getBranchCode())){
            jobQuery.addWhereConditionWithValue(4,'fsServ__Branch_Code__c', '=', getBranchCode());
            jobQuery.setWhereConditionCriteria('(1 OR 2) AND 3 AND 4');
        }
        System.debug(loggingLevel.ERROR, '-- Job Query : ' + jobQuery.getQueryString());
        return jobQuery.getQueryString();
    }
    
    private fsCore.DynamicQueryBuilder getQuery(){
        fsCore.DynamicQueryBuilder jobQuery = fsCore.DynamicQueryFactory.createQuery(Schema.SObjectType.Lending_Contract__c.getName())
                                                  .addField('Id')
                                                  .addWhereConditionWithValue(1,'fsServ__Contract_Status__c', '=', Constants.CONTRACT_STATUS_ACTIVE)
                                                  .addWhereConditionWithValue(2,'fsServ__Contract_Status__c', '=', Constants.CONTRACT_STATUS_CHARGED_OFF)
                                                  .addWhereConditionWithValue(3, 'fsServ__Is_Open__c', '=', true)
                                                  .setWhereConditionCriteria('(1 OR 2) AND 3');
        return jobQuery;
    }        


    global override String getClassName(){
        return CLASS_NAME;
    }

    global override void startJob(Database.BatchableContext pContext){}

    global override void finishJob(Database.BatchableContext pContext) {
        //TO Set the next business date for the branch.
    }

    global override List<fsCore.ErrorObject> executeJob(Database.BatchableContext pContext, List<sObject> pScope) {
        Logger.logMessage('Executing Job ' + CLASS_NAME + '...');
        Logger.logMessage('Scope Count : ' + pScope.size());
        
        String branchCode = getBranchCode();
        if(String.isBlank(branchCode)) {
            branchCode = fsCore.SpectraCoreUtil.getDefaultBranchCode();
        }
        Date businessDate = fsCore.SpectraCoreUtil.getBusinessDate(branchCode);

        Set<Id> contractIdSet = new Set<Id>();
        List<TransactionProcessingObject> transactionInputList = new List<TransactionProcessingObject>();

        for (Lending_Contract__c contract : (List<Lending_Contract__c>) pScope){
            TransactionProcessingObject transactionInput = new TransactionProcessingObject();
            transactionInput.mLendingContractId = contract.Id;
            transactionInput.mTransactionDate = businessDate;
            transactionInput.mBusinessDate = businessDate;
            transactionInput.mIsTransactionPosting = false; //Set it to no to bypass validations
            transactionInput.mIsPerformBackdating = false; //Set it to not to querybackdated Txn

            transactionInputList.add(transactionInput);
        }

        TransactionProcessingDataObject transactionData = new TransactionProcessingDataObject();
        
        Map<Id, List<TransactionProcessingObject>> contractTxnProcessingMap = 
                        TransactionProcessingUtil.prepareTransactionsProcessingData(transactionInputList, transactionData);

        List<Lending_Contract__c> updateLendingContractList = new List<Lending_Contract__c>();
        Map<Id,Lending_Contract__c> updateLendingContractMap = new MAP<ID,Lending_Contract__c>();
        List<Contract_Repayment__c> updateContractRepaymentList = new List<Contract_Repayment__c>();
        MAP<Id,List<Contract_Repayment__c>> updateContractRepaymentMap = new MAP<ID,List<Contract_Repayment__c>>();

        for(TransactionProcessingObject tInput : transactionInputList) {
            try{
                Contract_Transaction__c contractTxn = new Contract_Transaction__c();
                contractTxn.Lending_Contract_Number__c = tInput.mLendingContractId;
                contractTxn.Transaction_Date__c = tInput.mBusinessDate;

                Lending_Contract__c lendingContract = transactionData.mLendingContractMap.get(tInput.mLendingContractId);
                Logmessage('Processing ==>'+lendingContract.Name+' Accrual Date :'+lendingContract.Latest_Interest_Accrual_Date__c);

                PayoffQuoteProcessor poqProcess = new PayoffQuoteProcessor();
                lendingContract.Payoff_Amount_Today__c = poqProcess.getPayoffAmount(tInput,transactionData,contractTxn );
                Logmessage('Done PayoffQuoteProcessor ==>'+lendingContract.Payoff_Amount_Today__c);

                DelinquencyProcessor delinquencyProcess = new DelinquencyProcessor();
                delinquencyProcess.processDelinquency(tInput,transactionData, contractTxn);
                Logmessage('Done DelinquencyProcessor ==>'+lendingContract.Total_Delinquent_Amount__c);

                InterestTransactionProcessor interestProcess = new InterestTransactionProcessor();
                interestProcess.getInterest(tInput, transactionData, contractTxn);
                lendingContract.Interest_Accrued_Amount__c  = contractTxn.Transaction_Amount__c;
                Logmessage('Done interestProcess ==>'+lendingContract.Interest_Accrued_Amount__c);

                setContractStats(tInput, transactionData, contractTxn);
                Logmessage('Done setContractStats ==>'+lendingContract.Total_Billed_Amount__c);

                updateLendingContractList.add(lendingContract);
                updateLendingContractMap.put(lendingContract.Id,lendingContract);
                if(transactionData.mContractRepaymentMap != null) {
                    updateContractRepaymentMap.put(lendingContract.Id,transactionData.mContractRepaymentMap.get(tInput.mLendingContractId));
                    //updateContractRepaymentList.addAll(transactionData.mContractRepaymentMap.get(tInput.mLendingContractId));
                }

                
            }
            catch(Exception excptn){
                logmessage(String.format(Label.fsCore.Exception_Message, 
                                new String[]{ excptn.getMessage()
                                            , excptn.getStackTraceString()}));
                Lending_Contract__c lendingContract = transactionData.mLendingContractMap.get(tInput.mLendingContractId);
                Logmessage('Error ==>'+lendingContract.Name);
            }
        }
        
        fsCore.DMLResult cUpdateResult = LendingContractDMLWrapper.getInstance().updateData(updateLendingContractList);
        //
        /*for(Integer i=0; i < updateLendingContractList.size(); i++){
            logmessage('update list :'+updateLendingContractList[i].Name+' Billed Amt :'+updateLendingContractList[i].Total_Billed_Amount__c);
        }*/
        
        if (cUpdateResult.hasErrors()) {
            logmessage('cUpdateResult.hasErrors() :'+cUpdateResult.hasErrors());
            for(Integer i=0; i < cUpdateResult.getErrorList().size(); i++){
                logmessage('Error :'+cUpdateResult.getErrorList()[i].getErrorMessage());
                updateLendingContractMap.remove(cUpdateResult.getErrorList()[i].getErrorRecordId());                
            }
            cUpdateResult.throwError();
        }
        for(Id contractId : updateLendingContractMap.keySet()){    
            updateContractRepaymentList.addAll(updateContractRepaymentMap.get(contractId));
        }

        fsCore.DMLResult rUpdateResult = ContractRepaymentDMLWrapper.getInstance().updateData(updateContractRepaymentList);



        return cUpdateResult.getErrorList();
    }

    private void setContractStats(TransactionProcessingObject  pTransactionInput
                                , TransactionProcessingDataObject pTransactionData
                                , Contract_Transaction__c pContractTransaction){

        //Below code is updating the below fields
        //Total Billed Amount
        //Remaining Terms
        //Paid Terms
        //Next Payment Due Date
        String methodName = 'setContractStats';
        Logger.enter(CLASS_NAME, methodName);            
        if(pTransactionData.mContractRepaymentMap != null) {
            List<Contract_Repayment__c> contractRepaymentList = pTransactionData.mContractRepaymentMap.get(pTransactionInput.mLendingContractId);
            Lending_Contract__c lendingContract = pTransactionData.mLendingContractMap.get(pTransactionInput.mLendingContractId);

            if(contractRepaymentList != null && contractRepaymentList.size()>0) {
                Boolean nextDueDatePopulated = false;
                lendingContract.Total_Billed_Amount__c = 0.00;
                
                for (Contract_Repayment__c repayment:contractRepaymentList){
                    if (repayment.Due_Date__c <= pTransactionInput.mBusinessDate.addDays((Integer)lendingContract.Advance_Billing_Days__c) ){
                        lendingContract.Total_Billed_Amount__c += repayment.Due_Amount__c;
                        if (!repayment.Is_Due_Generated__c){
                            repayment.Is_Due_Generated__c = true;
                        }
                    }

                    if ((!nextDueDatePopulated)
                        && (repayment.Due_Date__c > pTransactionInput.mBusinessDate.addDays((Integer)lendingContract.Advance_Billing_Days__c))){
                        lendingContract.Next_Payment_Due_Date__c = repayment.Due_Date__c;
                        lendingContract.Current_Payment_Amount__c = repayment.Due_Amount__c;
                        nextDueDatePopulated = true;
                    }
                    if (nextDueDatePopulated && !repayment.Is_Due_Fulfilled__c){
                        break;
                    }
                    
                }
            }
        }
        Logger.exit(CLASS_NAME, methodName);
    }

    private void logMessage(String pMessage) {
        System.debug(Logginglevel.ERROR, pMessage);
    }
}
