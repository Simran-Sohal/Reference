@isTest(seeAllData=false)
private class TestHelperBulkData{

    @isTest
    private static void testBulkAppCreation(){
        //create custom settings
        SeedCustomSettings.createCustomSettings(new Set<String>{Constants.CUSTOM_SETTING_CUSTOM_NUMBER_FORMAT});
       
        //create company and branch
        Company_Setup__c testCompany = TestHelperCompany.getTestCompanySetup('Test Company', 'TESTCO', '123456789');
        insert testCompany;
        System.assert(testCompany.Id != null, 'Test company created assert');        
            
        Branch_Setup__c testBranch = TestHelperCompany.getTestBranchSetup('Test Branch', 'TBRCH', testCompany.Id, null, null);
        insert testBranch;
        System.assert(testBranch.Id != null, 'Test branch created assert');        

        //
        //create product
        //
        Product_Setup__c testProduct = TestHelperProduct.getTestProductSetup('Test Product'
                                                                            , 'TPROD'
                                                                            , Constants.PRODUCT_FAMILY_LOAN
                                                                            , Constants.CYCLE_MONTHLY
                                                                            , 1);
        insert testProduct;
        System.assert(testProduct.Id != null, 'Test product created assert');        
 
        //
        //create contract template
        //
        Payment_Allocation_Method_Setup__c testPaymentAlloc = TestHelperFinancial.getTestPaymentAllocMethod('Test Payment Allocation');
        insert testPaymentAlloc;

        Contract_Template_Setup__c testContractTemplate = TestHelperProduct.getTestContractTemplateSetup
                                                                                ('Test Contract Template'
                                                                               , Constants.PRODUCT_FAMILY_LOAN
                                                                               , testPaymentAlloc.Id
                                                                               , 1);
        insert testContractTemplate;    
        System.assert(testContractTemplate.Id != null, 'Test contract template created assert');        
    
        //
        //create Lending Applications by populating company, branch, product, contract template
        //
        Test.startTest();
        List<Lending_Application__c> testApps = TestHelperLendingApplication.getTestApplicationBulk(testCompany
                                                                              , testBranch
                                                                              , testProduct
                                                                              , testContractTemplate
                                                                              , 1000);
        DMLResult saveRslt = LendingApplicationDMLWrapper.getInstance().insertData(testApps);
        Test.stopTest();
        
        System.assertEquals(1000, saveRslt.getSuccessRecordList().size());
    }

}
