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
            TestSetupLoader.loadProductSetup();
            TestSetupLoader.loadPaymentAllocMethodSetup();
            TestSetupLoader.loadContractTemplateSetup();
            
            TestDataLoader.loadLendingContractsActive();
        } catch (Exception e){
            hasError = true;
            errMsg = String.valueOf(e);
        }
        System.assertEquals(false, hasError, 'Test data creation assert ' + errMsg);
    }
    
    @isTest
    static void testControllerMethods(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        fsCore__Branch_Setup__c testBranch = TestQueryHelper.getTestBranches().get('TCHQ');
        Contract_Assignment__c newAssignment = new Contract_Assignment__c();
        
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(newAssignment);
        ContractRelatedControllerBase controller = new ContractRelatedControllerBase(stdController);
        controller.setLendingContract(contractMap.get('AT1701000001').Id);
        controller.setPageSubtitle('New Assignment');
        
        System.assertEquals(contractMap.get('AT1701000001').Id, controller.getLendingContract().Id, 'Contract ID assert');
        System.assertEquals(contractMap.get('AT1701000001').Name, controller.getPageTitle(), 'Page Title assert');
        System.assertEquals('New Assignment', controller.getPageSubtitle(), 'Page Sub-Title assert');
        System.assertEquals(testBranch.fsCore__Business_Date__c, controller.getBusinessDate(), 'Business Date Assert');
        
        fsCore.ErrorObject errObj = new fsCore.ErrorObject();
        errObj.setErrorMessage('Test Error');
        controller.addErrorsToPage(new List<fsCore.ErrorObject>{errObj});
        Test.stopTest();
    }
}
