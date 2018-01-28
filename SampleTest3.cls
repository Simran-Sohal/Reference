@isTest(seeAllData=false)
private class ContractCustomerTest{

    @testSetup static void createTestData(){
        TestDataLoader.loadAccounts();
        TestDataLoader.loadContacts();
        
        TestSetupLoader.loadCompanySetup();
        TestSetupLoader.loadBankSetup();
        TestSetupLoader.loadBranchSetup();
        TestSetupLoader.loadBalanceSetup();
        TestSetupLoader.loadPaymentAllocMethodSetup();
        TestSetupLoader.loadProductSetup();
        TestSetupLoader.loadContractTemplateSetup();
        
        TestDataLoader.loadLendingContracts();
        TestDataLoader.loadContractCustomers();
    }

    @isTest 
    static void testListController(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Test.startTest();
        ContractCustomerListController listCtrl = new ContractCustomerListController();
        listCtrl.mContractId = contractMap.get('AT1701000001').Id;
        List<Contract_Customer__c> customers = listCtrl.getCustomerList();
        System.assertEquals(1, customers.size(), '1 customer found assert');
        
        listCtrl.mSelectedRecordId = customers.get(0).Id;
        listCtrl.onDelete();
        Test.stopTest();
    
        customers = listCtrl.getCustomerList();
        System.assertEquals(0, customers.size(), 'No customer found after delete assert');
    }
    
    @isTest
    static void testDMLWrapper(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        Map<String, Contact> contactMap = TestQueryHelper.getTestContacts();
                
        Test.startTest();
        Contract_Customer__c testCustomer = 
                TestContractDataHelper.getTestContractCustomer(
                        contractMap.get('AT1701000001')
                      , null //Blank Account
                      , contactMap.get('Tony Stark')
                      , fsCore.Constants.CUSTOMER_TYPE_GUARANTOR);
    
        List<Contract_Customer__c> testCustomerList = new List<Contract_Customer__c>();
        testCustomerList.add(testCustomer);
        
        ContractCustomerDMLWrapper.getInstance().insertData(testCustomerList);
        System.assertNotEquals(null, testCustomer.Id, 'Customer record created assert');
        
        ContractCustomerDMLWrapper.getInstance().updateData(testCustomerList);
        ContractCustomerDMLWrapper.getInstance().upsertData(testCustomerList);
        ContractCustomerDMLWrapper.getInstance().deleteData(testCustomerList);
        
        Test.stopTest();
    }    
    
}
