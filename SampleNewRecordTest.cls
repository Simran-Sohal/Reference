/*
 * Description  - Test class for 
 *                (1) QueuedTransactionEditController
 *                (2) QueuedTransactionParamUtil
 *                (3) QueuedTransactionParamObject
 *                (4) QueuedTransactionParamDMLWrapper
 *                (5) QueuedTransactionDMLWrapper
 *                (6) QueuedTransactionParamDMLWrapper
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
            TestSetupLoader.loadBranchSetup();
            
            TestSetupLoader.loadBalanceSetup();
            TestSetupLoader.loadTransactionSetup();
            TestSetupLoader.loadTransactionParamSetup();
            TestSetupLoader.loadTransactionControlSetup();
            TestSetupLoader.loadPaymentAllocMethodSetup();
            TestSetupLoader.loadPaymentAllocDetailSetup();

            TestSetupLoader.loadProductSetup();
            TestSetupLoader.loadContractTemplateSetup();
            
            TestDataLoader.loadLendingContractsActive();
            TestDataLoader.loadContractBalancesActive();
            TestDataLoader.loadContractTransactions();
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
}
