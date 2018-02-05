@isTest(seeAllData=false)
private class ContractCalculatorBuilderTest{

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
            
            //create payment preference
            Contract_Payment_Preference__c pmtPref = new Contract_Payment_Preference__c();
            pmtPref.Lending_Contract_Number__c = contractMap.get('AT1701000001').Id;
            pmtPref.Change_Sequence__c = 1;
            pmtPref.Change_Method__c = 'Bullet Payment';
            pmtPref.Change_Value__c = 1000;
            pmtPref.Change_Start_Term__c =  contractMap.get('AT1701000001').Current_Term__c; //setting to last term
            pmtPref.Is_Repetitive__c = false;
            ContractPaymentPreferenceDMLWrapper.getInstance().insertData(pmtPref);
            System.assert(pmtPref.Id != null);
            
            //create holiday preference
            Contract_Holiday_Preference__c holidayPref = new Contract_Holiday_Preference__c();
            holidayPref.Lending_Contract_Number__c = contractMap.get('AT1701000001').Id;
            holidayPref.Payment_Holiday_Unit__c = 'Month';
            holidayPref.Payment_Holiday_Month__c = 'December';
            holidayPref.Is_Repetitive__c = false;
            ContractHolidayPreferenceDMLWrapper.getInstance().insertData(holidayPref);
            System.assert(holidayPref.Id != null);
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
        List<Contract_Rate_Preference__c> ratePref = ContractRelatedRecordQueryUtil.getRatePreferences(testContract.Id);
        List<Contract_Payment_Preference__c> pmtPref = ContractRelatedRecordQueryUtil.getPaymentPreferences(testContract.Id);
        List<Contract_Holiday_Preference__c> holidayPref = ContractRelatedRecordQueryUtil.getHolidayPreferences(testContract.Id);
        
        Test.startTest();
        ContractCalculatorBuilder calcBuilder = new ContractCalculatorBuilder(pContract);
        calcBuilder.setCalculator(fsCore.Constants.CALCULATE_PAYMENT_AMOUNT);
        
        BusinessHours bizHrs = fsCore.SpectraCoreUtil.getBusinessHours(testContract.Branch_Code__c);
        calcBuilder.setBusinessHour(bizHrs);
        
        List<Holiday> bizHolidayList = fsCore.SpectraCoreUtil.getBusinessHolidayList(testContract.Branch_Code__c);
        calcBuilder.setHolidays(bizHolidayList);
        
        calcBuilder.setRepaymentDetails(repayments);
        calcBuilder.setRepaymentSchedule(repaySchedule);
        calcBuilder.setRatePreferences(ratePref);
        calcBuilder.setPaymentPreferences(pmtPref);
        calcBuilder.setHolidayPreferences(holidayPref);
        
        //add extra coverage
        calcBuilder.setPredefinedPayments(repaySchedule);
        calcBuilder.setPredefinedPayments(new List<Contract_Repayment_Schedule__c>);
        
        calcBuilder.setInterestStartDate(testContract.Contract_Date__c);
        calcBuilder.setTerm(testContract.Current_Term__c);
        calcBuilder.setRate(testContract.Current_Rate__c);
        calcBuilder.setPaymentAmount(testContract.Current_Payment_Amount__c);
        calcBuilder.setPaymentStartDate(testContract.Next_Payment_Due_Date__c);
        calcBuilder.setFrequency(testContract.Current_Payment_Frequency__c);
        calcBuilder.setFinancedAmount(testContract.Financed_Amount__c);
        calcBuilder.setSupplementaryInterest(0.00);
        calcBuilder.setBalloonAmount(testContract.Current_Balloon_Method__c);
        calcBuilder.setBalloonMethod(testContract.Balloon_Method__c);
                  
        fsCore.CalculatorObject calcObj = calcBuilder.getCalculatorObject();
        
        System.assertNotEquals(null, calcObj);
        System.assertEquals(testContract.Current_Term__c, calcObj.getCalculatorMain().fsCore__Term__c);
        System.assertEquals(testContract.Current_Rate__c, calcObj.getCalculatorMain().fsCore__Rate__c);
        System.assertEquals(testContract.Current_Payment_Amount__c, calcObj.getCalculatorMain().fsCore__Payment_Amount__c);
        System.assertEquals(testContract.Next_Payment_Due_Date__c, calcObj.getCalculatorMain().fsCore__Payment_Start_Date__c);
        System.assertEquals(testContract.Current_Payment_Frequency__c, calcObj.getCalculatorMain().fsCore__Payment_Frequency__c);
        System.assertEquals(0.00, calcObj.getCalculatorMain().fsCore__Supplementary_Interest_Amount__c);
        Test.stopTest();
    }
}
