@isTest(seeAllData=false)
private class ContractTxnListControllerTest{
    @testSetup static void createTestData(){
        TestDataLoader.loadAccounts();
        TestDataLoader.loadContacts();
        
        TestSetupLoader.loadCompanySetup();
        TestSetupLoader.loadBankSetup();
        TestSetupLoader.loadBranchSetup();
        TestSetupLoader.loadBalanceSetup();
        TestSetupLoader.loadTransactionSetup();
        TestSetupLoader.loadProductSetup();
        TestSetupLoader.loadPaymentAllocMethodSetup();
        TestSetupLoader.loadContractTemplateSetup();

        TestDataLoader.loadLendingContractsActive();
        TestDataLoader.loadQueuedTransactions();
        TestDataLoader.loadContractTransactions();
    }

    @isTest 
    static void testQueuedTxnListController(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Test.startTest();
        ContractTxnQueuedListController listCtrl = new ContractTxnQueuedListController();
        listCtrl.mContractId = contractMap.get('AT1701000001').Id;
        List<Transaction_Processing_Queue__c> queuedTxns = listCtrl.getQueuedTransactionList();
        System.assertEquals(2, queuedTxns.size(), '2 queued transactions found assert');
        
        listCtrl.mSelectedRecordId = queuedTxns.get(0).Id;
        listCtrl.onPost();

        listCtrl.mSelectedRecordId = queuedTxns.get(1).Id;
        listCtrl.onDelete();

        Test.stopTest();
        queuedTxns = listCtrl.getQueuedTransactionList();
        System.assertEquals(0, queuedTxns.size(), 'No queued transactions found after post and delete assert');
    }

    @isTest 
    static void testPostedTxnListController(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Test.startTest();
        ContractTxnPostedListController listCtrl = new ContractTxnPostedListController();
        listCtrl.mContractId = contractMap.get('AT1701000001').Id;
        List<Contract_Transaction__c> postedTxns = listCtrl.getTransactionList();
        System.assertEquals(4, postedTxns.size(), '4 posted transactions found assert');
        
        listCtrl.mSelectedRecordId = postedTxns.get(0).Id;
        listCtrl.onReverse();

        Test.stopTest();
    }

    @isTest 
    static void testRecentTxnListController(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Test.startTest();
        ContractTxnRecentListController listCtrl = new ContractTxnRecentListController();
        listCtrl.mContractId = contractMap.get('AT1701000001').Id;
        List<Contract_Transaction__c> recentTxns = listCtrl.getRecentTransactionList();
        System.assertEquals(1, recentTxns.size(), '1 recent transaction found assert');
        Test.stopTest();
    }

}
