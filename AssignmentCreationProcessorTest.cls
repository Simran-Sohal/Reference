@isTest(seeAllData=false)
private class AssignmentCreationProcessorTest{
    
    @testSetup static void createTestData(){
        TestDataLoader.loadAccounts();
        TestDataLoader.loadContacts();
        
        TestSetupLoader.loadCompanySetup();
        TestSetupLoader.loadBankSetup();
        TestSetupLoader.loadBranchSetup();
        TestSetupLoader.loadProductSetup();
        TestSetupLoader.loadPaymentAllocMethodSetup();
        TestSetupLoader.loadContractTemplateSetup();
        TestSetupLoader.loadQueueAssignmentSetup();
        
        TestDataLoader.loadLendingContractsActive();
        TestDataLoader.loadContractAssignments();
    }   
     
    @isTest
    static void testAssignmentCreation_Success(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Map<Id, String> contractToAssignmentMap = new Map<Id, String>();
        contractToAssignmentMap.put(contractMap.get('AT1701000001').Id, 'DLQ_30');
        contractToAssignmentMap.put(contractMap.get('AT1701000002').Id, 'DLQ_60');
        contractToAssignmentMap.put(contractMap.get('AT1701000003').Id, 'DLQ_90');
        contractToAssignmentMap.put(contractMap.get('AT1701000004').Id, 'ON_BOARD');
        
        Test.startTest();
        AssignmentCreationProcessor testProc = new AssignmentCreationProcessor(contractToAssignmentMap);
        testProc.process();
        Test.stopTest();
        
        List<fsCore__Diagnostic_Log__c> errors = [SELECT Id FROM fsCore__Diagnostic_Log__c
                                                   WHERE fsCore__Related_Record_ID__c IN :contractToAssignmentMap.keySet()];
        System.assertEquals(0, errors.size(), 'No error in processing');
    }

    @isTest
    static void testAssignmentCreation_Error(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Map<Id, String> contractToAssignmentMap = new Map<Id, String>();
        contractToAssignmentMap.put(contractMap.get('AT1701000001').Id, 'DUMMY');
        contractToAssignmentMap.put(UserInfo.getUserId(), 'DLQ_30');
        
        Test.startTest();
        AssignmentCreationProcessor testProc = new AssignmentCreationProcessor(contractToAssignmentMap);
        testProc.process();
        Test.stopTest();
        
        List<fsCore__Diagnostic_Log__c> errors = [SELECT Id FROM fsCore__Diagnostic_Log__c
                                                   WHERE fsCore__Related_Record_ID__c IN :contractToAssignmentMap.keySet()];
        System.assertEquals(2, errors.size(), '2 errors occured during processing');
    }
}
