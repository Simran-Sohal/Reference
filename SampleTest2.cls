@isTest(seeAllData=false)
private class ContractCollateralTest{
    
    @testSetup static void createTestData(){
        TestDataLoader.loadAccounts();
        TestDataLoader.loadContacts();
        TestDataLoader.loadCollaterals();
        
        TestSetupLoader.loadCompanySetup();
        TestSetupLoader.loadBankSetup();
        TestSetupLoader.loadBranchSetup();
        TestSetupLoader.loadBalanceSetup();
        TestSetupLoader.loadPaymentAllocMethodSetup();
        TestSetupLoader.loadProductSetup();
        TestSetupLoader.loadContractTemplateSetup();
    
        TestDataLoader.loadLendingContracts();
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
        Map<String, fsCore__Collateral__c> collateralMap = TestQueryHelper.getTestCollaterals();
                
        Test.startTest();
        Contract_Collateral__c testCollateral = 
                TestContractDataHelper.getTestContractCollateral(
                        contractMap.get('AT1701000001')
                      , collateralMap.get('B3M2W8'));
    
        List<Contract_Collateral__c> testCollateralList = new List<Contract_Collateral__c>();
        testCollateralList.add(testCollateral);
        
        ContractCollateralDMLWrapper.getInstance().insertData(testCollateralList);
        System.assertNotEquals(null, testCollateral.Id, 'Collateral record created assert');
        
        ContractCollateralDMLWrapper.getInstance().updateData(testCollateralList);
        ContractCollateralDMLWrapper.getInstance().upsertData(testCollateralList);
        ContractCollateralDMLWrapper.getInstance().deleteData(testCollateralList);
        
        Test.stopTest();
    }    
    
}
