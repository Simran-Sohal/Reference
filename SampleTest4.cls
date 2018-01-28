@isTest(seeAllData=false)
private class ContractItemizationTest{

    @testSetup static void createTestData(){
        TestDataLoader.loadAccounts();
        TestDataLoader.loadContacts();
        
        TestSetupLoader.loadCompanySetup();
        TestSetupLoader.loadBankSetup();
        TestSetupLoader.loadBranchSetup();
        TestSetupLoader.loadBalanceSetup();
        TestSetupLoader.loadTransactionSetup();
        TestSetupLoader.loadItemizationSetup();
        TestSetupLoader.loadPaymentAllocMethodSetup();
        TestSetupLoader.loadProductSetup();
        TestSetupLoader.loadContractTemplateSetup();

        TestDataLoader.loadLendingContracts();
        TestDataLoader.loadContractItemizations();
    }

    @isTest 
    static void testListController(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Test.startTest();
        ContractItemizationListController listCtrl = new ContractItemizationListController();
        listCtrl.mContractId = contractMap.get('AT1701000001').Id;
        List<Contract_Itemization__c> itemizations = listCtrl.getItemizationList();
        System.assertEquals(3, itemizations.size(), '3 itemizations found assert');
        Test.stopTest();
    }
    
    @isTest
    static void testDMLWrapper(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        Map<String, fsCore__Itemization_Setup__c> itemizationMap = TestQueryHelper.getTestItemizations();
                
        Test.startTest();
        Contract_Itemization__c testItemization = 
                TestContractDataHelper.getTestContractCustomer(
                        contractMap.get('AT1701000001').Id
                      , null //Blank Account
                      , testContactsMap.get('Tony Stark').Id);
    
        List<Contract_Itemization__c> testItemizationList = new List<Contract_Itemization__c>();
        testItemizationList.add(testItemization);
        
        ContractItemizationDMLWrapper.getInstance().insertData(testItemizationList);
        System.assertNotEquals(null, testItemization.Id, 'Itemization record created assert');
        
        ContractItemizationDMLWrapper.getInstance().updateData(testItemizationList);
        ContractItemizationDMLWrapper.getInstance().upsertData(testItemizationList);
        ContractItemizationDMLWrapper.getInstance().deleteData(testItemizationList);
        
        Test.stopTest();
    }    
    
}
