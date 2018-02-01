/*
 * Description  - Test class for 
 *                (1) QueuedTransactionEditController
 *                (2) QueuedTransactionParamUtil
 *                (3) QueuedTransactionParamObject
 *                (4) QueuedTransactionDMLWrapper
 *                (5) QueuedTransactionParamDMLWrapper
 */
@isTest
private class QueuedTransactionTest{

    @testSetup static void createTestData() {
        String errMsg = Constants.BLANK_STRING;
        Boolean hasError = false;
        try {                
            TestDataLoader.loadAccounts();
            TestDataLoader.loadContacts();
            TestDataLoader.loadBankAccounts();
            
            TestSetupLoader.loadCompanySetup();
            TestSetupLoader.loadBankSetup();
            Map<String, fsCore__Branch_Setup__c> branchMap = TestSetupLoader.loadBranchSetup();
            //test branch has business date 5-Jan-2017
            branchMap.get('TCHQ').fsCore__Business_Date__c = branchMap.get('TCHQ').fsCore__Business_Date__c.addDays(12);
            update branchMap.values();

            TestSetupLoader.loadBalanceSetup();
            Map<String, fsCore__Transaction_Setup__c> txnSetupMap = TestSetupLoader.loadTransactionSetup();
            Map<String, List<fsCore__Transaction_Parameter_Setup__c>> txnParamSetupMap = TestSetupLoader.loadTransactionParamSetup();
            TestSetupLoader.loadTransactionControlSetup();
            TestSetupLoader.loadPaymentAllocMethodSetup();
            TestSetupLoader.loadPaymentAllocDetailSetup();

            TestSetupLoader.loadProductSetup();
            TestSetupLoader.loadContractTemplateSetup();
            
            Map<String, Lending_Contract__c> contractMap = TestDataLoader.loadLendingContractsActive();
            TestDataLoader.loadContractBalancesActive();
            TestDataLoader.loadContractTransactions();
            
            //create draft queued transactions for the contracts
            TestContractDataHelper.createQueuedTransactions(contractMap.values()
                                                          , branchMap.get('TCHQ')
                                                          , txnSetupMap.get('PAYMENT_APPLIED')
                                                          , txnParamSetupMap.get('PAYMENT_APPLIED')
                                                          , Constants.TRANSACTION_STATUS_DRAFT);
        }
        catch (Exception e){
            hasError = true;
            errMsg = String.valueOf(e);
        }
        System.assertEquals(false, hasError, 'Test data creation assert ' + errMsg);
    }


    private static List<TransactionProcessingObject> getTxnProcessingObject(
                                        List<Lending_Contract__c> pContractList
                                      , fsCore__Transaction_Setup__c pPaymentTxn
                                      , List<fsCore__Transaction_Parameter_Setup__c> pPaymentTxnParams
                                      , Date pTxnDate){
        
        List<TransactionProcessingObject> queuedTxnList = new List<TransactionProcessingObject>();
        
        for(Lending_Contract__c contract : pContractList){
            TransactionProcessingObject queuedTxnObject = new TransactionProcessingObject();
            queuedTxnObject.mTransactionQueueRecord = TestContractDataHelper.getTestQueuedTransaction(contract, pPaymentTxn, pTxnDate);
            
            Map<String, Transaction_Processing_Parameter__c> txnParamMap 
                    = TestContractDataHelper.getTestQueuedTxnParams(queuedTxnObject.mTransactionQueueRecord, pPaymentTxnParams);
            
            txnParamMap.get('fsserv__transaction_amount__c').Currency_Value__c = contract.Current_Payment_Amount__c;
            txnParamMap.get('fsserv__transaction_amount__c').Data_Type__c = 'Currency';

            txnParamMap.get('fsserv__payment_mode__c').String_Value__c = 'ACH';
            txnParamMap.get('fsserv__payment_mode__c').Data_Type__c = 'String';

            txnParamMap.get('fsserv__payment_source__c').String_Value__c = 'Direct Debit';
            txnParamMap.get('fsserv__payment_source__c').Data_Type__c = 'String';

            txnParamMap.get('fsserv__payment_reason__c').String_Value__c = 'Regular Payment';
            txnParamMap.get('fsserv__payment_reason__c').Data_Type__c = 'String';

            queuedTxnObject.mTransactionParameterList = txnParamMap.values();
            queuedTxnList.add(queuedTxnObject);
        }
        
        return queuedTxnList;
    }

    @isTest
    private static void testProcessingContractPaymentSuccess() {
        fsCore__Branch_Setup__c testBranch = TestQueryHelper.getTestBranches().get('TCHQ');
        //test branch has business date 5-Jan-2017
        testBranch.fsCore__Business_Date__c = testBranch.fsCore__Business_Date__c.addDays(7);
        update testBranch;
        
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        fsCore__Transaction_Setup__c paymentTxn = TestQueryHelper.getTestTxnSetup().get('PAYMENT_APPLIED');
        System.assertNotEquals(null, paymentTxn);
        
        List<fsCore__Transaction_Parameter_Setup__c> paymentTxnParams 
                = TestQueryHelper.getTestTxnParamSetup().get(paymentTxn.Id);
        System.assertEquals(4, paymentTxnParams.size());
        
        List<TransactionProcessingObject> queuedTxnProcessList 
                = getTxnProcessingObject(contractMap.values(), paymentTxn, paymentTxnParams, testBranch.fsCore__Business_Date__c);
        
        //Test Execution starts here
        Test.startTest();
        List<Transaction_Processing_Queue__c> queuedTxnList = new List<Transaction_Processing_Queue__c>();
        for (TransactionProcessingObject tpqObj : queuedTxnProcessList){
            queuedTxnList.add(tpqObj.mTransactionQueueRecord);
        }
        QueuedTransactionDMLWrapper.getInstance().upsertData(queuedTxnList);
        
        List<Transaction_Processing_Parameter__c> queuedTxnParamList = new List<Transaction_Processing_Parameter__c>();
        Set<Id> savedQueuedTxnSet = new Set<Id>();
        for (TransactionProcessingObject tpqObj : queuedTxnProcessList){
            if (tpqObj.mTransactionQueueRecord.Id != null){
                for(Transaction_Processing_Parameter__c txnParam : tpqObj.mTransactionParameterList){
                    if (txnParam.Transaction_Queue_Name__c == null){
                        txnParam.Transaction_Queue_Name__c = tpqObj.mTransactionQueueRecord.Id;
                    }
                    queuedTxnParamList.add(txnParam);
                }
                savedQueuedTxnSet.add(tpqObj.mTransactionQueueRecord.Id);
            }
        }
        QueuedTransactionParamDMLWrapper.getInstance().upsertData(queuedTxnParamList);
        
        Test.stopTest();
    }
    
    @isTest
    static void testQueuedTxnDMLWrapper(){
        fsCore__Branch_Setup__c testBranch = TestQueryHelper.getTestBranches().get('TCHQ');
        Lending_Contract__c testContract = TestQueryHelper.getTestLendingContracts().get('AT1701000001');
        fsCore__Transaction_Setup__c paymentTxnSetup = TestQueryHelper.getTestTxnSetup().get('PAYMENT_APPLIED');
        
        Transaction_Processing_Queue__c queuedTxn 
                = TestContractDataHelper.getTestQueuedTransaction(testContract, paymentTxnSetup, testBranch.fsCore__Business_Date__c);
        
        Test.startTest();
        List<Transaction_Processing_Queue__c> queuedTxnList = new List<Transaction_Processing_Queue__c>{queuedTxn};
        QueuedTransactionDMLWrapper.getInstance().insertData(queuedTxnList);
        System.assert(queuedTxn.Id != null, 'Record created assert');
        
        QueuedTransactionDMLWrapper.getInstance().updateData(queuedTxnList);
        QueuedTransactionDMLWrapper.getInstance().upsertData(queuedTxnList);
        QueuedTransactionDMLWrapper.getInstance().deleteData(queuedTxnList);
        Test.stopTest();
    }

    @isTest
    static void testQueuedTxnParamDMLWrapper(){
        fsCore__Branch_Setup__c testBranch = TestQueryHelper.getTestBranches().get('TCHQ');
        Lending_Contract__c testContract = TestQueryHelper.getTestLendingContracts().get('AT1701000001');
        fsCore__Transaction_Setup__c balloonAmtChgTxn = TestQueryHelper.getTestTxnSetup().get('BALLOON_AMOUNT_CHANGED');
        List<fsCore__Transaction_Parameter_Setup__c> balloonAmtChgTxnParams 
                = TestQueryHelper.getTestTxnParamSetup().get(balloonAmtChgTxn.Id);
        System.assertEquals(1, balloonAmtChgTxnParams.size());
        
        Transaction_Processing_Queue__c queuedTxn 
                = TestContractDataHelper.getTestQueuedTransaction(testContract, balloonAmtChgTxn, testBranch.fsCore__Business_Date__c);
        QueuedTransactionParamDMLWrapper.getInstance().insertData(queuedTxn);
        System.assert(queuedTxn.Id != null, 'Record created assert');
        
        Map<String, Transaction_Processing_Parameter__c> queuedTxnParamMap 
                = TestContractDataHelper.getTestQueuedTxnParams(queuedTxn, balloonAmtChgTxnParams);
        System.assert(queuedTxnParamMap.containsKey('fsserv__transaction_amount__c'));
        queuedTxnParamMap.get('fsserv__transaction_amount__c').Currency_Value__c = 1000;
        queuedTxnParamMap.get('fsserv__transaction_amount__c').Data_Type__c = 'Currency';

        Test.startTest();
        List<Transaction_Processing_Parameter__c> queuedTxnParamList = queuedTxnParamMap.values();
        fsCore.DMLResult saveRslt = QueuedTransactionParamDMLWrapper.getInstance().insertData(queuedTxnParamList);
        System.assert(1, saveRslt.getSuccessRecordSet().size(), 'Record created assert');
        
        QueuedTransactionParamDMLWrapper.getInstance().updateData(queuedTxnParamList);
        QueuedTransactionParamDMLWrapper.getInstance().upsertData(queuedTxnParamList);
        QueuedTransactionParamDMLWrapper.getInstance().deleteData(queuedTxnParamList);
        Test.stopTest();
    }
}
