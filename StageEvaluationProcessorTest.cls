@isTest(seeAllData=false)
private class StageEvaluationProcessorTest{
    
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
        TestSetupLoader.loadStageSetup();
        
        TestDataLoader.loadLendingContractsActive();
        TestDataLoader.loadContractAssignments();
        TestDataLoader.loadContractStages();
    }   
     
    @isTest
    static void testStageEvaluation_Success(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Set<String> stageCodeSet = new Set<String>{'ON_BOARD','DLQ_30','DLQ_60'};
        
        Map<Id, String> contractToStageEnterMap = new Map<Id, String>();
        contractToStageEnterMap.put(contractMap.get('AT1701000001').Id, 'DLQ_30');
        contractToStageEnterMap.put(contractMap.get('AT1701000002').Id, 'DLQ_60');
        contractToStageEnterMap.put(contractMap.get('AT1701000003').Id, 'DLQ_90');
        contractToStageEnterMap.put(contractMap.get('AT1701000004').Id, 'ON_BOARD');
        
        Map<Id, String> contractToStageExitMap = new Map<Id, String>();
        contractToStageExitMap.put(contractMap.get('AT1701000001').Id, 'ON_BOARD');
        contractToStageExitMap.put(contractMap.get('AT1701000002').Id, 'ON_BOARD');
        contractToStageExitMap.put(contractMap.get('AT1701000005').Id, 'ON_BOARD');
        
        Set<Id> contractIdSet = new Set<Id>();
        contractIdSet.add(contractToStageEnterMap.keySet());
        contractIdSet.add(contractToStageExitMap.keySet());
        
        Test.startTest();
        StageEvaluationProcessor testProc = new StageEvaluationProcessor(stageCodeSet);
        testProc.setContractStageForEntry(contractToStageEnterMap);
        testProc.setContractStageForExit(contractToStageExitMap);
        testProc.process();
        Test.stopTest();
        
        List<fsCore__Diagnostic_Log__c> errors = [SELECT Id FROM fsCore__Diagnostic_Log__c
                                                   WHERE fsCore__Related_Record_ID__c IN :contractIdSet.keySet()];
        System.assertEquals(0, errors.size(), 'No error in processing');
    }

    @isTest
    static void testStageEvaluation_Error(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Set<String> stageCodeSet = new Set<String>{'ON_BOARD','DLQ_30','DLQ_60'};
        
        Map<Id, String> contractToStageEnterMap = new Map<Id, String>();
        contractToStageEnterMap.put(contractMap.get('AT1701000001').Id, 'DUMMY');
        contractToStageEnterMap.put(UserInfo.getUserId(), 'DLQ_60');
        
        Test.startTest();
        StageEvaluationProcessor testProc = new StageEvaluationProcessor(stageCodeSet);
        testProc.setContractStageForEntry(contractToStageEnterMap);
        testProc.process();
        Test.stopTest();
        
        List<fsCore__Diagnostic_Log__c> errors = [SELECT Id FROM fsCore__Diagnostic_Log__c
                                                   WHERE fsCore__Related_Record_ID__c IN :contractToStageEnterMap.keySet()];
        System.assertEquals(2, errors.size(), '2 errors occured during processing');
    }
}
