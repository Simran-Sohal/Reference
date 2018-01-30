@isTest(seeAllData=false)
private class ContractRepaymentTest{

    @testSetup static void createTestData(){
        TestDataLoader.loadAccounts();
        TestDataLoader.loadContacts();
        
        TestSetupLoader.loadCompanySetup();
        TestSetupLoader.loadBankSetup();
        TestSetupLoader.loadBranchSetup();
        TestSetupLoader.loadProductSetup();
        TestSetupLoader.loadPaymentAllocMethodSetup();
        TestSetupLoader.loadContractTemplateSetup();

        TestDataLoader.loadLendingContractsActive();
        TestDataLoader.loadRepayments();
        TestDataLoader.loadRepaymentSchedules();
        TestDataLoader.loadRatePreferences();
        TestDataLoader.loadPaymentPreferences();
    }

    @isTest 
    static void testRepaymentListController(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Test.startTest();
        ContractRepaymentListController listCtrl = new ContractRepaymentListController();
        listCtrl.mContractId = contractMap.get('AT1701000001').Id;
        List<Contract_Repayment__c> repayments = listCtrl.getRepaymentList();
        System.assertEquals(36, repayments.size(), '36 repayments found assert');
        
        //test pagination methods
        //listCtrl.hasNext();
        //listCtrl.hasPrevious();
        //listCtrl.onNext();
        //listCtrl.onPrevious();
        
        Test.stopTest();
    }
    
    @isTest 
    static void testRepayScheduleListController(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Test.startTest();
        ContractRepayScheduleListController listCtrl = new ContractRepayScheduleListController();
        listCtrl.mContractId = contractMap.get('AT1701000001').Id;
        List<Contract_Repayment_Schedule__c> repaySchedules = listCtrl.getRepaymentScheduleList();
        System.assertEquals(1, repaySchedules.size(), '1 repayment schedule found assert');
        Test.stopTest();
    }

    @isTest 
    static void testAdvanceRepayPrefController(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Test.startTest();
        Test.stopTest();
    }

    @isTest
    static void testRepaymentDMLWrapper(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        Lending_Contract__c testContract = contractMap.get('AT1701000001').Id;
        List<Contract_Repayment__c> currRepayments = ContractRelatedRecordQueryUtil.getRepayments(testContract.Id);
        Integer origRecordCount = currRepayments.size();
        System.assertNotEquals(0, origRecordCount, 'Repayments found');
        
        List<Contract_Repayment__c> newRepayments = currRepayments.deepClone(false,false,false);
        
        Test.startTest();
        ContractRepaymentDMLWrapper.getInstance().deleteData(currRepayments);
        currRepayments = ContractRelatedRecordQueryUtil.getRepayments(testContract.Id);
        System.assertEquals(0, currRepayments.size(), 'No repayments after delete');
        
        ContractRepaymentDMLWrapper.getInstance().insertData(newRepayments);
        currRepayments = ContractRelatedRecordQueryUtil.getRepayments(testContract.Id);
        System.assertEquals(origRecordCount, currRepayments.size(), 'New Repayments created');
        
        ContractRepaymentDMLWrapper.getInstance().updateData(currRepayments);
        ContractRepaymentDMLWrapper.getInstance().upsertData(currRepayments);
        Test.stopTest();
    }

    @isTest
    static void testRepaySchDMLWrapper(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        Lending_Contract__c testContract = contractMap.get('AT1701000001').Id;
        List<Contract_Repayment_Schedule__c> currRepaySch = ContractRelatedRecordQueryUtil.getRepaymentSchedules(testContract.Id);
        Integer origRecordCount = currRepaySch.size();
        System.assertNotEquals(0, origRecordCount, 'Repayment Schedules found');
        
        List<Contract_Repayment_Schedule__c> newRepaySch = currRepaySch.deepClone(false,false,false);
        
        Test.startTest();
        ContractRepayScheduleDMLWrapper.getInstance().deleteData(currRepaySch);
        currRepaySch = ContractRelatedRecordQueryUtil.getRepaymentSchedules(testContract.Id);
        System.assertEquals(0, currRepaySch.size(), 'No repayment schedule after delete');
        
        ContractRepayScheduleDMLWrapper.getInstance().insertData(newRepaySch);
        currRepaySch = ContractRelatedRecordQueryUtil.getRepaymentSchedules(testContract.Id);
        System.assertEquals(origRecordCount, currRepaySch.size(), 'New Repayment Schedule records created');
        
        ContractRepayScheduleDMLWrapper.getInstance().updateData(currRepaySch);
        ContractRepayScheduleDMLWrapper.getInstance().upsertData(currRepaySch);
        Test.stopTest();
    }
    
    @isTest
    static void testRatePrefDMLWrapper(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        Lending_Contract__c testContract = contractMap.get('AT1701000001').Id; //CHANGE CONTRACT NUMBER
        List<Contract_Rate_Preference__c> currRatePrefs = ContractRelatedRecordQueryUtil.getRatePreferences(testContract.Id);
        Integer origRecordCount = currRatePrefs.size();
        System.assertNotEquals(0, origRecordCount, 'Rate Preferences found');
        
        List<Contract_Rate_Preference__c> newRatePrefs = currRatePrefs.deepClone(false,false,false);
        
        Test.startTest();
        ContractRatePreferenceDMLWrapper.getInstance().deleteData(currRatePrefs);
        currRatePrefs = ContractRelatedRecordQueryUtil.getRatePreferences(testContract.Id);
        System.assertEquals(0, currRatePrefs.size(), 'No rate preference after delete');
        
        ContractRatePreferenceDMLWrapper.getInstance().insertData(newRatePrefs);
        currRatePrefs = ContractRelatedRecordQueryUtil.getRatePreferences(testContract.Id);
        System.assertEquals(origRecordCount, currRatePrefs.size(), 'New Rate Preference records created');
        
        ContractRatePreferenceDMLWrapper.getInstance().updateData(currRatePrefs);
        ContractRatePreferenceDMLWrapper.getInstance().upsertData(currRatePrefs);
        Test.stopTest();
    }   

    @isTest
    static void testPaymentPrefDMLWrapper(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        Lending_Contract__c testContract = contractMap.get('AT1701000001').Id; //CHANGE CONTRACT NUMBER
        List<Contract_Payment_Preference__c> currPmtPrefs = ContractRelatedRecordQueryUtil.getPaymentPreferences(testContract.Id);
        Integer origRecordCount = currPmtPrefs.size();
        System.assertNotEquals(0, origRecordCount, 'Payment Preferences found');
        
        List<Contract_Payment_Preference__c> newPmtPrefs = currPmtPrefs.deepClone(false,false,false);
        
        Test.startTest();
        ContractPaymentPreferenceDMLWrapper.getInstance().deleteData(currPmtPrefs);
        currPmtPrefs = ContractRelatedRecordQueryUtil.getPaymentPreferences(testContract.Id);
        System.assertEquals(0, currPmtPrefs.size(), 'No payment preference after delete');
        
        ContractPaymentPreferenceDMLWrapper.getInstance().insertData(newPmtPrefs);
        currPmtPrefs = ContractRelatedRecordQueryUtil.getPaymentPreferences(testContract.Id);
        System.assertEquals(origRecordCount, currPmtPrefs.size(), 'New Payment Preference records created');
        
        ContractPaymentPreferenceDMLWrapper.getInstance().updateData(currPmtPrefs);
        ContractPaymentPreferenceDMLWrapper.getInstance().upsertData(currPmtPrefs);
        
        Test.stopTest();
    }   
}
