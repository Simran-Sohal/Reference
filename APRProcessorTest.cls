@isTest(seeAllData=false)
private class APRProcessorTest{

    @testSetup static void createTestData(){
        String errMsg = Constants.BLANK_STRING;
        Boolean hasError = false;
        try{
            TestDataLoader.loadAccounts();
            TestDataLoader.loadContacts();
            
            TestSetupLoader.loadCompanySetup();
            TestSetupLoader.loadBankSetup();
            TestSetupLoader.loadBranchSetup();
            TestSetupLoader.loadProductSetup();
            TestSetupLoader.loadPaymentAllocMethodSetup();
            TestSetupLoader.loadContractTemplateSetup();
    
            TestDataLoader.loadLendingContractsActive();
            TestDataLoader.loadContractRepayments();
        } catch (Exception e){
            hasError = true;
            errMsg = String.valueOf(e);
        }
        System.assertEquals(false, hasError, 'Test data creation assert ' + errMsg);
    }
    
    @isTest
    static void testAPRCalc(){
        Lending_Contract__c testContract = TestQueryHelper.getTestLendingContracts().get('AT1701000001');
        
        Test.startTest();
        fsCore.ActionInput acInput = new fsCore.ActionInput();
        acInput.addRecord(testContract.Id);
        
        APRProcessor aprCalc = new APRProcessorTest();
        aprCalc.setInput(acInput);
        aprCalc.process();
        
        fsCore.ActionInput acOutput = aprCalc.getOutput();
        System.assertEquals(true, acOutput.getIsSuccess(), 'Processing completed successfully');
        Test.stopTest();
    }
}
