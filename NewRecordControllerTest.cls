@isTest(seeAllData=false)
private class ContractNewTransactionControllerTest{
    
    @testSetup static void createTestData(){
        String errMsg = Constants.BLANK_STRING;
        Boolean hasError = false;
        try{
            TestDataLoader.loadAccounts();
            TestDataLoader.loadContacts();
            
            TestSetupLoader.loadCompanySetup();
            TestSetupLoader.loadBankSetup();
            TestSetupLoader.loadBranchSetup();
            TestSetupLoader.loadBalanceSetup();
            TestSetupLoader.loadTransactionSetup();
            TestSetupLoader.loadTransactionParamSetup();
            TestSetupLoader.loadTransactionControlSetup();
            TestSetupLoader.loadProductSetup();
            TestSetupLoader.loadPaymentAllocMethodSetup();
            TestSetupLoader.loadContractTemplateSetup();
            TestSetupLoader.loadQueueAssignmentSetup();
            TestSetupLoader.loadStageSetup();
            
            TestDataLoader.loadLendingContractsActive();
            TestDataLoader.loadContractAssignments();
            TestDataLoader.loadContractStages();
        } catch (Exception e){
            hasError = true;
            errMsg = String.valueOf(e);
        }
        System.assertEquals(false, hasError, 'Test data creation assert ' + errMsg);
    }
    
    @isTest
    static void testNewTxnController_Success(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        Lending_Contract__c testContract = contractMap.get('AT1701000001');
        fsCore__User_Preferences__c userPref = fsCore__User_Preferences__c.getInstance(UserInfo.getUserId());
        userPref.Favorite_Transaction_Code__c = 'DUMMY';
        upsert userPref;
        
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(testContract);
        ContractNewTransactionController controller = new ContractNewTransactionController(stdController);
        System.assertEquals(false, controller.mIsSetAsFavoriteTxn, 'Set as Favorite unchecked');
        System.assertEquals(testContract.Name, controller.getPageTitle(), 'Contract details loaded');
        System.assertEquals(controller.mAvailableTxnList.size() > 1, 'Transaction List populated');
        
        //successful onNext() method call
        String selectedTxnCode = controller.mAvailableTxnList.get(1).getValue();
        controller.mSelectedTxnCode = selectedTxnCode;
        controller.mIsSetAsFavoriteTxn = true;
        
        userPref = fsCore__User_Preferences__c.getInstance(UserInfo.getUserId());
        System.assertEquals(selectedTxnCode, user.Favorite_Transaction_Code__c, 'Favorite transaction set');
        Test.stopTest();
    }

    @isTest
    static void testNewTxnController_Error(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        Lending_Contract__c testContract = contractMap.get('AT1701000001');
        
        Test.startTest();
        ApexPages.StandardController stdController;
        ContractNewTransactionController controller;
        Boolean hasError = false;
        try{
            stdController = new ApexPages.StandardController(new Lending_Contract__c());
            controller = new ContractNewTransactionController(stdController);
        } catch (Exception e){
            hasError = true;
        }
        System.assertEquals(true, hasError, 'Error occured on init()');
 
        hasError = false;
        try{
            stdController = new ApexPages.StandardController(testContract);
            controller = new ContractNewTransactionController(stdController);
        } catch (Exception e){
            hasError = true;
        }
        System.assertEquals(false, hasError, 'No error occured on init()');
 
        //following calls will cover the validation in the onNext() method
        controller.onNext();
        controller.mSelectedTxnCode = 'DUMMY';
        controller.onNext();
        controller.onCancel();
        Test.stopTest();
    }
}
