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
        Map<Id, List<Contract_Customer__c>> customersMap = TestQueryHelper.getTestContactCustomers();
        
        Lending_Contract__c testContract = contractMap.get('AT1701000001');
        Contract_Customer__c testCustomer = customersMap.get(testContract.Id).get(0);
        List<fsCore__Bank_Account__c> testBankAccounts = TestQueryHelper.getTestBankAccountsByContact().get(testCustomer.Contact_Name__c);
        
        Test.startTest();
        Contract_Direct_Debit__c testDirectDebit = 
                TestContractDataHelper.getTestContractDirectDebit(
                        testContract
                      , testCustomer
                      , testBankAccounts.get(0)
                      , Constants.DEBIT_SOURCE_FIXED_AMOUNT);
    
        List<Contract_Direct_Debit__c> testDirectDebitList = new List<Contract_Direct_Debit__c>();
        testDirectDebitList.add(testDirectDebit);
        
        ContractDirectDebitDMLWrapper.getInstance().insertData(testDirectDebitList);
        System.assertNotEquals(null, testDirectDebit.Id, 'Direct Debit record created assert');
        
        ContractDirectDebitDMLWrapper.getInstance().updateData(testDirectDebitList);
        ContractDirectDebitDMLWrapper.getInstance().upsertData(testDirectDebitList);
        ContractDirectDebitDMLWrapper.getInstance().deleteData(testDirectDebitList);
        
        Test.stopTest();
    }    
    
}
