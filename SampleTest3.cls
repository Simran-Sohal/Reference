@isTest(seeAllData=false)
private class ContractCustomerTest{

    @testSetup static void createTestData(){
        TestDataLoader.loadAccounts();
        TestDataLoader.loadContacts();
        
        TestSetupLoader.loadCompanySetup();
        TestSetupLoader.loadBankSetup();
        TestSetupLoader.loadBranchSetup();
        TestSetupLoader.loadProductSetup();
        TestSetupLoader.loadPaymentAllocMethodSetup();
        TestSetupLoader.loadContractTemplateSetup();
        
        TestDataLoader.loadLendingContractsPending();
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
        Lending_Contract__c testContract = contractMap.get('AT1701000001').Id;
        List<Contract_Customer__c> currCustomers = ContractRelatedRecordQueryUtil.getCustomers(testContract.Id);
        Integer origRecordCount = currCustomers.size();
        System.assertNotEquals(0, origRecordCount, 'Customers found');
        
        List<Contract_Customer__c> newCustomers = currCustomers.deepClone(false,false,false);
                
        Test.startTest();
        ContractCustomerDMLWrapper.getInstance().deleteData(currCustomers);
        currCustomers = ContractRelatedRecordQueryUtil.getCustomers(testContract.Id);
        System.assertEquals(0, currCustomers.size(), 'No customer found after delete');
        
        ContractCustomerDMLWrapper.getInstance().insertData(newCustomers);
        currCustomers = ContractRelatedRecordQueryUtil.getCustomers(testContract.Id);
        System.assertEquals(origRecordCount, currCustomers.size(), 'Customer records created assert');
        
        ContractCustomerDMLWrapper.getInstance().updateData(currCustomers);
        ContractCustomerDMLWrapper.getInstance().upsertData(currCustomers);
        Test.stopTest();
    }    
    
}
