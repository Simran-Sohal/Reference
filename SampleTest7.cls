@isTest(seeAllData=false)
private class ContractDisbursementTest{

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
        TestDataLoader.loadContractDisbursements();
    }

    @isTest 
    static void testListController(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Test.startTest();
        ContractDisbursementListController listCtrl = new ContractDisbursementListController();
        listCtrl.mContractId = contractMap.get('AT1701000001').Id;
        List<Contract_Disbursement__c> disbursements = listCtrl.getDisbursementList();
        System.assertEquals(1, disbursements.size(), '1 disbursement found assert');
        
        listCtrl.mSelectedRecordId = disbursements.get(0).Id;
        listCtrl.onDelete();
        Test.stopTest();
    
        disbursements = listCtrl.getDisbursementList();
        System.assertEquals(0, disbursements.size(), 'No disbursement found after delete assert');
    }
    
    @isTest
    static void testDMLWrapper(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        Map<Id, List<Contract_Customer__c>> customersMap = TestQueryHelper.getTestContactCustomers();
        
        Lending_Contract__c testContract = contractMap.get('AT1701000001');
        Contract_Customer__c testCustomer = customersMap.get(testContract.Id).get(0);
        List<fsCore__Bank_Account__c> testBankAccounts = TestQueryHelper.getTestBankAccountsByContact().get(testCustomer.Contact_Name__c);
        
        List<Contract_Disbursement__c> currDisbursments = [SELECT Id FROM Contract_Disbursement__c 
                                                            WHERE Lending_Contract_Number__c = :testContract.Id];
 
        Test.startTest();
        ContractDisbursementDMLWrapper.getInstance().deleteData(currDisbursments);
        currDisbursments = [SELECT Id FROM Contract_Disbursement__c 
                             WHERE Lending_Contract_Number__c = :testContract.Id];
        System.assertEquals(0, currDisbursments.size(), 'No disbursement record found after delete assert');
        
        Contract_Disbursement__c testDisbursement = 
                TestContractDataHelper.getTestContractDisbursement(
                        testContract
                      , testCustomer
                      , testBankAccounts.get(0)
                      , testContract.Financed_Amount__c);
    
        List<Contract_Disbursement__c> testDisbursementList = new List<Contract_Disbursement__c>();
        testDisbursementList.add(testDisbursement);
        
        ContractDisbursementDMLWrapper.getInstance().insertData(testDisbursementList);
        System.assertNotEquals(null, testDisbursement.Id, 'Disbursement record created assert');
        
        ContractDisbursementDMLWrapper.getInstance().updateData(testDisbursementList);
        ContractDisbursementDMLWrapper.getInstance().upsertData(testDisbursementList);
        Test.stopTest();
    }
}
