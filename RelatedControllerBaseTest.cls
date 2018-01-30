@isTest(seeAllData=false)
private class ContractRelatedControllerBaseTest{
    
    @testSetup static void createTestData(){
        String errMsg = Constants.BLANK_STRING;
        Boolean hasError = false;
        try{
            TestDataLoader.loadAccounts();
            TestDataLoader.loadContacts();
            
            TestSetupLoader.loadCompanySetup();
            TestSetupLoader.loadBankSetup();
            TestSetupLoader.loadBranchSetup();
            TestSetupLoader.loadBalanceSetup();
            TestSetupLoader.loadTransactionSetup();
            TestSetupLoader.loadTransactionParamSetup();
            TestSetupLoader.loadTransactionControlSetup();
            TestSetupLoader.loadProductSetup();
            TestSetupLoader.loadPaymentAllocMethodSetup();
            TestSetupLoader.loadContractTemplateSetup();
            TestSetupLoader.loadQueueAssignmentSetup();
            TestSetupLoader.loadStageSetup();
            
            TestDataLoader.loadLendingContractsActive();
            TestDataLoader.loadContractAssignments();
            TestDataLoader.loadContractStages();
        } catch (Exception e){
            hasError = true;
            errMsg = String.valueOf(e);
        }
        System.assertEquals(false, hasError, 'Test data creation assert ' + errMsg);
    }
    
    @isTest
    static void testNewTxnController_Load(){
    
    }
}
