@isTest(seeAllData=false)
private class ContractDirectDebitTest{
    
    @testSetup static void createTestData(){
        TestDataLoader.loadAccounts();
        TestDataLoader.loadContacts();
        TestDataLoader.loadBankAccounts();
        
        TestSetupLoader.loadCompanySetup();
        TestSetupLoader.loadBankSetup();
        TestSetupLoader.loadBranchSetup();
        TestSetupLoader.loadProductSetup();
        TestSetupLoader.loadPaymentAllocMethodSetup();
        TestSetupLoader.loadContractTemplateSetup();

        TestDataLoader.loadLendingContractsActive();
        TestDataLoader.loadContractCustomers();
        TestDataLoader.loadContractDirectDebits();
    }

    @isTest 
    static void testListController(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Test.startTest();
        ContractDirectDebitListController listCtrl = new ContractDirectDebitListController();
        listCtrl.mContractId = contractMap.get('AT1701000001').Id;
        List<Contract_Direct_Debit__c> directDebits = listCtrl.getDirectDebitList();
        System.assertEquals(1, directDebits.size(), '1 direct debit found assert');
        
        listCtrl.mSelectedRecordId = directDebits.get(0).Id;
        listCtrl.onDelete();
        Test.stopTest();
    
        directDebits = listCtrl.getDirectDebitList();
        System.assertEquals(0, directDebits.size(), 'No direct debit found after delete assert');
    }
    
    @isTest
    static void testDMLWrapper(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        Lending_Contract__c testContract = contractMap.get('AT1701000001').Id;
        List<Contract_Direct_Debit__c> currDirectDebits = ContractRelatedRecordQueryUtil.getDirectDebits(testContract.Id);
        Integer origRecordCount = currDirectDebits.size();
        System.assertNotEquals(0, origRecordCount, 'Direct Debits found');
        
        List<Contract_Direct_Debit__c> newDirectDebits = currDirectDebits.deepClone(false,false,false);
        
        Test.startTest();
        ContractDirectDebitDMLWrapper.getInstance().deleteData(currDirectDebits);
        currDirectDebits = ContractRelatedRecordQueryUtil.getDirectDebits(testContract.Id);
        System.assertEquals(0, currDirectDebits.size(), 'No direct debit found after delete');
        
        ContractDirectDebitDMLWrapper.getInstance().insertData(newDirectDebits);
        currDirectDebits = ContractRelatedRecordQueryUtil.getDirectDebits(testContract.Id);
        System.assertEquals(origRecordCount, currDirectDebits.size(), 'New direct debit records created');
        
        ContractDirectDebitDMLWrapper.getInstance().updateData(currDirectDebits);
        ContractDirectDebitDMLWrapper.getInstance().upsertData(currDirectDebits);
        Test.stopTest();
    }    
    
}
