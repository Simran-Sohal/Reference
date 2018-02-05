@isTest(seeAllData=false)
private class CalculatorBuilderTest{

    @testSetup static void createTestData(){
        String errMsg = Constants.BLANK_STRING;
        Boolean hasError = false;
        try{
            TestDataLoader.loadAccounts();
            TestDataLoader.loadContacts();
            
            TestSetupLoader.loadCompanySetup();
            TestSetupLoader.loadBankSetup();
            TestSetupLoader.loadBranchSetup();
            TestSetupLoader.loadProductSetup();
            TestSetupLoader.loadPaymentAllocMethodSetup();
            TestSetupLoader.loadContractTemplateSetup();
    
            Map<String, Lending_Contract__c> contractMap = TestDataLoader.loadLendingContractsActive();
            TestDataLoader.loadContractRepayments();
            TestDataLoader.loadContractRepaySchedules();
            
            //create rate preference
            Contract_Rate_Preference__c ratePref = new Contract_Rate_Preference__c();
            ratePref.Lending_Contract_Number__c = contractMap.get('AT1701000001').Id;
            ratePref.Start_Date__c = contractMap.get('AT1701000001').Contract_Date__c;
            ratePref.Rate__c = contractMap.get('AT1701000001').Current_Rate__c;
            ContractRatePreferenceDMLWrapper.getInstance().insertData(ratePref);
            System.assert(ratePref.Id != null);
        } catch (Exception e){
            hasError = true;
            errMsg = String.valueOf(e);
        }
        System.assertEquals(false, hasError, 'Test data creation assert ' + errMsg);
    }
    
    @isTest
    static void testCalcBuilder(){
        Lending_Contract__c testContract = TestQueryHelper.getTestLendingContracts().get('AT1701000001');
        List<Contract_Repayment__c> repayments = ContractRelatedRecordQueryUtil.getRepayments(testContract.Id);
        List<Contract_Repayment_Schedule__c> repaySchedule = ContractRelatedRecordQueryUtil.getRepaymentSchedules(testContract.Id);
        
        Test.startTest();
        
        Test.stopTest();
    }
}
