@isTest(seeAllData=false)
private class ContractCollateralTest{
    
    @testSetup static void createTestData(){
        TestDataLoader.loadAccounts();
        TestDataLoader.loadContacts();
        TestDataLoader.loadCollaterals();
        
        TestSetupLoader.loadCompanySetup();
        TestSetupLoader.loadBankSetup();
        TestSetupLoader.loadBranchSetup();
        TestSetupLoader.loadProductSetup();
        TestSetupLoader.loadPaymentAllocMethodSetup();
        TestSetupLoader.loadContractTemplateSetup();
    
        TestDataLoader.loadLendingContractsActive();
        TestDataLoader.loadContractCollaterals();
    }

    @isTest 
    static void testListController(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Test.startTest();
        ContractCollateralListController listCtrl = new ContractCollateralListController();
        listCtrl.mContractId = contractMap.get('AT1701000001').Id;
        List<Contract_Collateral__c> collaterals = listCtrl.getCollateralList();
        System.assertEquals(1, collaterals.size(), '1 collateral found assert');
        
        listCtrl.mSelectedRecordId = collaterals.get(0).Id;
        listCtrl.onDelete();
        Test.stopTest();
    
        collaterals = listCtrl.getCollateralList();
        System.assertEquals(0, collaterals.size(), 'No collateral found after delete assert');
    }
    
    @isTest
    static void testDMLWrapper(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        Lending_Contract__c testContract = contractMap.get('AT1701000001').Id;
        List<Contract_Collateral__c> currCollaterals = ContractRelatedRecordQueryUtil.getCollaterals(testContract.Id);
        Integer origRecordCount = currCollaterals.size();
        System.assertNotEquals(0, origRecordCount, 'Collaterals found');
        
        List<Contract_Collateral__c> newCollaterals = currCollaterals.deepClone(false,false,false);
                
        Test.startTest();
        ContractCollateralDMLWrapper.getInstance().deleteData(currCollaterals);
        currCollaterals = ContractRelatedRecordQueryUtil.getCollaterals(testContract.Id);
        System.assertEquals(0, currCollaterals.size(), 'No collateral found after delete');
        
        ContractCollateralDMLWrapper.getInstance().insertData(newCollaterals);
        currCollaterals = ContractRelatedRecordQueryUtil.getCollaterals(testContract.Id);
        System.assertEquals(origRecordCount, currCollaterals.size(), 'Collateral records created assert');
        
        ContractCollateralDMLWrapper.getInstance().updateData(currCollaterals);
        ContractCollateralDMLWrapper.getInstance().upsertData(currCollaterals);
        
        Test.stopTest();
    }    
    
}
