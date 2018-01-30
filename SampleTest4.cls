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

        TestDataLoader.loadLendingContractsPending();
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
        Lending_Contract__c testContract = contractMap.get('AT1701000001').Id;
        List<Contract_Itemization__c> currItemizations = ContractRelatedRecordQueryUtil.getItemizations(testContract.Id);
        Integer origRecordCount = currItemizations.size();
        System.assertNotEquals(0, origRecordCount, 'Itemizations found');
        
        List<Contract_Itemization__c> newItemizations = currItemizations.deepClone(false,false,false);
        
        Test.startTest();
        ContractItemizationDMLWrapper.getInstance().deleteData(currItemizations);
        currItemizations = ContractRelatedRecordQueryUtil.getItemizations(testContract.Id);
        System.assertEquals(0, currItemizations.size(), 'No itemizations found after delete');
        
        ContractItemizationDMLWrapper.getInstance().insertData(newItemizations);
        currItemizations = ContractRelatedRecordQueryUtil.getItemizations(testContract.Id);
        System.assertEquals(origRecordCount, currItemizations.size(), 'New itemization records created');
        
        ContractItemizationDMLWrapper.getInstance().updateData(currItemizations);
        ContractItemizationDMLWrapper.getInstance().upsertData(currItemizations);
        Test.stopTest();
    }    
    
}
