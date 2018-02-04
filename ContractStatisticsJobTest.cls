@isTest(seeAllData=false)
private class ContractStatisticsJobTest{

    @testSetup static void createTestData(){
        String errMsg = Constants.BLANK_STRING;
        Boolean hasError = false;
        try{
            TestDataLoader.loadAccounts();
            TestDataLoader.loadContacts();
            
            TestSetupLoader.loadCompanySetup();
            TestSetupLoader.loadBankSetup();
            Map<String, fsCore__Branch_Setup__c> branchMap = TestSetupLoader.loadBranchSetup();
            //test branch has business date 5-Jan-2017
            branchMap.get('TCHQ').fsCore__Business_Date__c = branchMap.get('TCHQ').fsCore__Business_Date__c.addDays(12);
            update branchMap.values();

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
            
            TestDataLoader.loadLendingContractsActive();
            TestDataLoader.loadContractBalancesActive();
        }
        catch (Exception e){
            hasError = true;
            errMsg = String.valueOf(e);
        }
        System.assertEquals(false, hasError, 'Test data creation assert ' + errMsg);
    }

    @isTest 
    static void testStatisticsJob(){
        
    
    }

}
