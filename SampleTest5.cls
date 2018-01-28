@isTest(seeAllData=false)
private class ContractFeeTest{
   
   @testSetup static void createTestData(){
        TestDataLoader.loadAccounts();
        TestDataLoader.loadContacts();
        
        TestSetupLoader.loadCompanySetup();
        TestSetupLoader.loadBankSetup();
        TestSetupLoader.loadBranchSetup();
        TestSetupLoader.loadBalanceSetup();
        TestSetupLoader.loadTransactionSetup();
        TestSetupLoader.loadPaymentAllocMethodSetup();
        TestSetupLoader.loadProductSetup();
        TestSetupLoader.loadFeeSetup();
        TestSetupLoader.loadFeeTierSetup();
        TestSetupLoader.loadContractTemplateSetup();
        
        TestDataLoader.loadLendingContracts();
        TestDataLoader.loadContractFees();
    }

    @isTest 
    static void testListController(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Test.startTest();
        ContractFeeListController listCtrl = new ContractFeeListController();
        listCtrl.mContractId = contractMap.get('AT1701000001').Id;
        List<Contract_Fee__c> fees = listCtrl.getFeeList();
        System.assertEquals(1, fees.size(), '1 fee found assert');
        
        listCtrl.mSelectedRecordId = fees.get(0).Id;
        listCtrl.onDelete();
        Test.stopTest();
    
        fees = listCtrl.getFeeList();
        System.assertEquals(0, fees.size(), 'No fee found after delete assert');
    }
    
    @isTest
    static void testFeeDMLWrapper(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        Map<String, fsCore__Fee_Setup__c> feeSetupMap = TestQueryHelper.getTestFees();
                
        Test.startTest();
        Contract_Fee__c testFee = 
                TestContractDataHelper.getTestContractFee(
                        contractMap.get('AT1701000001')
                      , feeSetupMap.get('Late Fee'));
    
        List<Contract_Fee__c> testFeeList = new List<Contract_Fee__c>();
        testFeeList.add(testFee);
        
        ContractFeeDMLWrapper.getInstance().insertData(testFeeList);
        System.assertNotEquals(null, testFee.Id, 'Fee record created assert');
        
        ContractFeeDMLWrapper.getInstance().updateData(testFeeList);
        ContractFeeDMLWrapper.getInstance().upsertData(testFeeList);
        ContractFeeDMLWrapper.getInstance().deleteData(testFeeList);
        
        Test.stopTest();
    }    

    @isTest
    static void testFeeTierDMLWrapper(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        Map<String, fsCore__Fee_Setup__c> feeSetupMap = TestQueryHelper.getTestFees();
        Contract_Fee__c testFee = 
                TestContractDataHelper.getTestContractFee(
                        contractMap.get('AT1701000001')
                      , feeSetupMap.get('Late Fee'));
        ContractFeeDMLWrapper.getInstance().insertData(testFee);
        System.assertNotEquals(null, testFee.Id, 'Fee record created assert');
              
        Test.startTest();
        Contract_Fee_Tier__c testFeeTier_1 = 
                TestContractDataHelper.getTestContractFeeTier(
                        contractMap.get('AT1701000001')
                      , testFee
                      , 0, 10000, 5);
        Contract_Fee_Tier__c testFeeTier_2 = 
                TestContractDataHelper.getTestContractFeeTier(
                        contractMap.get('AT1701000001')
                      , testFee
                      , 10001, 50000, 10);
      
        List<Contract_Fee_Tier__c> testFeeTierList = new List<Contract_Fee_Tier__c>();
        testFeeTierList.add(testFeeTier_1);
        testFeeTierList.add(testFeeTier_2);
        
        ContractFeeTierDMLWrapper.getInstance().insertData(testFeeTierList);
        System.assertNotEquals(null, testFeeTier_1.Id, 'Fee Tier 1 record created assert');
        System.assertNotEquals(null, testFeeTier_2.Id, 'Fee Tier 2 record created assert');
        
        ContractFeeTierDMLWrapper.getInstance().updateData(testFeeTierList);
        ContractFeeTierDMLWrapper.getInstance().upsertData(testFeeTierList);
        ContractFeeTierDMLWrapper.getInstance().deleteData(testFeeTierList);
        
        Test.stopTest();
    }    

}
