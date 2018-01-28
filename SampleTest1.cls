@isTest(seeAllData=false)
private class ContractBalanceTest{

    @testSetup static void createTestData(){
        TestDataLoader.loadAccounts();
        TestDataLoader.loadContacts();
        
        TestSetupLoader.loadCompanySetup();
        TestSetupLoader.loadBankSetup();
        TestSetupLoader.loadBranchSetup();
        TestSetupLoader.loadBalanceSetup();
        TestSetupLoader.loadProductSetup();
        TestSetupLoader.loadPaymentAllocMethodSetup();
        TestSetupLoader.loadContractTemplateSetup();

        TestDataLoader.loadLendingContracts();
        TestDataLoader.loadContractBalances();
    }

    @isTest 
    static void testListController(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Test.startTest();
        ContractBalanceListController listCtrl = new ContractBalanceListController();
        listCtrl.mContractId = contractMap.get('AT1701000001').Id;
        List<Contract_Balance__c> balances = listCtrl.getBalanceList();
        System.assertEquals(4, balances.size(), '4 balances found assert');
        Test.stopTest();
    }
    
    @isTest
    static void testDMLWrapper(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        Map<String, fsCore__Balance_Setup__c> balancesMap = TestQueryHelper.getTestBalances();
                
        Test.startTest();
        Contract_Balance__c testBalance = 
                TestContractDataHelper.getTestContractBalance(
                        contractMap.get('AT1701000001')
                      , balancesMap.get('NSF Fee Balance')
                      , 0.00);
    
        List<Contract_Balance__c> testBalanceList = new List<Contract_Balance__c>();
        testBalanceList.add(testBalance);
        
        ContractBalanceDMLWrapper.getInstance().insertData(testBalanceList);
        System.assertNotEquals(null, testBalance.Id, 'Balance record created assert');
        
        ContractBalanceDMLWrapper.getInstance().updateData(testBalanceList);
        ContractBalanceDMLWrapper.getInstance().upsertData(testBalanceList);
        ContractBalanceDMLWrapper.getInstance().deleteData(testBalanceList);
        
        Test.stopTest();
    }    
    
}
