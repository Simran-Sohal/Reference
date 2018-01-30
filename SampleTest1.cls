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

        TestDataLoader.loadLendingContractsActive();
        TestDataLoader.loadContractBalancesActive();
    }

    @isTest 
    static void testListController(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Test.startTest();
        ContractBalanceListController listCtrl = new ContractBalanceListController();
        listCtrl.mContractId = contractMap.get('AT1701000001').Id;
        List<Contract_Balance__c> balances = listCtrl.getBalanceList();
        System.assertEquals(3, balances.size(), '3 balances found assert');
        Test.stopTest();
    }
    
    @isTest
    static void testDMLWrapper(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        Map<String, fsCore__Balance_Setup__c> balancesMap = TestQueryHelper.getTestBalances();
        
        Lending_Contract__c testContract = contractMap.get('AT1701000001').Id;
        List<Contract_Balance__c> currBalances = ContractRelatedRecordQueryUtil.getBalances(testContract.Id);
        Integer origRecordCount = currBalances.size();
        System.assertNotEquals(0, origRecordCount, 'Balances found');
        
        List<Contract_Balance__c> newBalances = currBalances.deepClone(false,false,false);
        
        Test.startTest();
        ContractBalanceDMLWrapper.getInstance().deleteData(currBalances);
        currBalances = ContractRelatedRecordQueryUtil.getBalances(testContract.Id);
        System.assertEquals(0, currBalances.size(), 'No balances found after delete');
        
        ContractBalanceDMLWrapper.getInstance().insertData(newBalances);
        currBalances = ContractRelatedRecordQueryUtil.getBalances(testContract.Id);
        System.assertEquals(origRecordCount, currBalances.size(), 'New balance records created');
        
        ContractBalanceDMLWrapper.getInstance().updateData(currBalances);
        ContractBalanceDMLWrapper.getInstance().upsertData(currBalances);
        
        Test.stopTest();
    }    
    
}
