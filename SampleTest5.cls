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
        
        TestDataLoader.loadLendingContractsActive();
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
        Lending_Contract__c testContract = contractMap.get('AT1701000001').Id;
        List<Contract_Fee__c> currContractFees = ContractRelatedRecordQueryUtil.getContractFees(testContract.Id);
        Integer origRecordCount = currContractFees.size();
        System.assertNotEquals(0, origRecordCount, 'Contract Fees found');
        
        List<Contract_Fee__c> newContractFees = currContractFees.deepClone(false,false,false);
        
        Test.startTest();
        ContractFeeDMLWrapper.getInstance().deleteData(currContractFees);
        currContractFees = ContractRelatedRecordQueryUtil.getContractFees(testContract.Id);
        System.assertEquals(0, currContractFees.size(), 'No contract fees found after delete');
        
        ContractFeeDMLWrapper.getInstance().insertData(newContractFees);
        currContractFees = ContractRelatedRecordQueryUtil.getContractFees(testContract.Id);
        System.assertEquals(origRecordCount, currContractFees.size(), 'New contract fees records created');
        
        ContractFeeDMLWrapper.getInstance().updateData(currContractFees);
        ContractFeeDMLWrapper.getInstance().upsertData(currContractFees);
        Test.stopTest();
    }    

    @isTest
    static void testFeeTierDMLWrapper(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        Lending_Contract__c testContract = contractMap.get('AT1701000001').Id;
        List<Contract_Fee__c> testContractFees = ContractRelatedRecordQueryUtil.getContractFees(testContract.Id);
        
        Contract_Fee__c testFee = testContractFees.get(0);
        testFee.Tier_Based_Calculation_Field__c = 'Outstanding Amount';
        ContractFeeDMLWrapper.getInstance().updateData(testFee);
        
        Test.startTest();
        Contract_Fee_Tier__c testFeeTier_1 = getTestFeeTier(testContract.Id, testFee, 0, 10000, 5);
        Contract_Fee_Tier__c testFeeTier_2 = getTestFeeTier(testContract.Id, testFee, 10001, 50000, 10);
        Contract_Fee_Tier__c testFeeTier_3 = getTestFeeTier(testContract.Id, testFee, 50001, 999999, 20);
      
        List<Contract_Fee_Tier__c> testFeeTierList = new List<Contract_Fee_Tier__c>();
        testFeeTierList.add(testFeeTier_1);
        testFeeTierList.add(testFeeTier_2);
        testFeeTierList.add(testFeeTier_3);
        
        ContractFeeTierDMLWrapper.getInstance().insertData(testFeeTierList);
        System.assertNotEquals(null, testFeeTier_1.Id, 'Fee Tier 1 record created assert');
        System.assertNotEquals(null, testFeeTier_2.Id, 'Fee Tier 2 record created assert');
        System.assertNotEquals(null, testFeeTier_3.Id, 'Fee Tier 3 record created assert');
        
        ContractFeeTierDMLWrapper.getInstance().updateData(testFeeTierList);
        ContractFeeTierDMLWrapper.getInstance().upsertData(testFeeTierList);
        ContractFeeTierDMLWrapper.getInstance().deleteData(testFeeTierList);
        
        Test.stopTest();
    }    

    private static Contract_Fee_Tier__c getTestFeeTier(Id pContractId
                                                     , Contract_Fee__c pContractFee
                                                     , Decimal pTierFromValue
                                                     , Decimal pTierToValue
                                                     , Decimal pValue){
        Contract_Fee_Tier__c testFeeTier = new Contract_Fee_Tier__c();
        testFeeTier.Lending_Contract_Number__c = pContractId;
        testFeeTier.Fee_Reference_Number__c = pContractFee.Id;
        testFeeTier.Tier_From__c = pTierFromValue;
        testFeeTier.Tier_To__c = pTierToValue;
        if (pContractFee.Calculation_Method__c.containsIgnoreCase('Percentage')){
            testFeeTier.Calculation_Percent__c = pValue;
        } else {
            testFeeTier.Fixed_Amount__c = pValue;
        }
        
        return testFeeTier;
    }
}
