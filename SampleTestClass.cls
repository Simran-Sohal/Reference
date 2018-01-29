@isTest(seeAllData=false)
private class SampleTestClass{
    
    @testSetup static void createTestData(){
        TestDataLoader.loadAccounts();
        TestDataLoader.loadContacts();
        TestDataLoader.loadBankAccounts();
        TestDataLoader.loadCollaterals();
        
        TestSetupLoader.loadCompanySetup();
        TestSetupLoader.loadBankSetup();
        TestSetupLoader.loadBranchSetup();
        
        TestSetupLoader.loadBalanceSetup();
        TestSetupLoader.loadTransactionSetup();
        TestSetupLoader.loadTransactionParamSetup();
        TestSetupLoader.loadTransactionControlSetup();
        TestSetupLoader.loadItemizationSetup();
        TestSetupLoader.loadPaymentAllocMethodSetup();
        TestSetupLoader.loadPaymentAllocDetailSetup();

        TestSetupLoader.loadProductSetup();
        TestSetupLoader.loadFeeSetup();
        TestSetupLoader.loadFeeTierSetup();
        TestSetupLoader.loadContractTemplateSetup();
        TestSetupLoader.loadQueueAssignmentSetup();
        TestSetupLoader.loadStageSetup();

        TestDataLoader.loadLendingContracts();
        TestDataLoader.loadContractCustomers();
        TestDataLoader.loadContractCollaterals();
        TestDataLoader.loadContractItemizations();
        TestDataLoader.loadContractBalances();
        TestDataLoader.loadContractFees();
        TestDataLoader.loadContractDirectDebits();
        TestDataLoader.loadContractDisbursements();
        TestDataLoader.loadContractStages();
        TestDataLoader.loadContractAssignments();
        TestDataLoader.loadContractTransactions();
    }   
    
}
