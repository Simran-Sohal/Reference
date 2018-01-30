@isTest(seeAllData=false)
private class ContractDisbursementTest{

    @testSetup static void createTestData(){
        TestDataLoader.loadAccounts();
        TestDataLoader.loadContacts();
        TestDataLoader.loadBankAccounts();
        
        TestSetupLoader.loadCompanySetup();
        TestSetupLoader.loadBankSetup();
        TestSetupLoader.loadBranchSetup();
        TestSetupLoader.loadProductSetup();
        TestSetupLoader.loadPaymentAllocMethodSetup();
        TestSetupLoader.loadContractTemplateSetup();

        TestDataLoader.loadLendingContractsPending();
        TestDataLoader.loadContractCustomers();
        TestDataLoader.loadContractDisbursements();
    }

    @isTest 
    static void testListController(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        
        Test.startTest();
        ContractDisbursementListController listCtrl = new ContractDisbursementListController();
        listCtrl.mContractId = contractMap.get('AT1701000001').Id;
        List<Contract_Disbursement__c> disbursements = listCtrl.getDisbursementList();
        System.assertEquals(1, disbursements.size(), '1 disbursement found assert');
        
        listCtrl.mSelectedRecordId = disbursements.get(0).Id;
        listCtrl.onDelete();
        Test.stopTest();
    
        disbursements = listCtrl.getDisbursementList();
        System.assertEquals(0, disbursements.size(), 'No disbursement found after delete assert');
    }
    
    @isTest
    static void testDMLWrapper(){
        Map<String, Lending_Contract__c> contractMap = TestQueryHelper.getTestLendingContracts();
        Lending_Contract__c testContract = contractMap.get('AT1701000001').Id;
        List<Contract_Disbursement__c> currDisbursments = ContractRelatedRecordQueryUtil.getDisbursements(testContract.Id);
        Integer origRecordCount = currDisbursments.size();
        System.assertNotEquals(0, origRecordCount, 'Disbursments found');
        
        List<Contract_Disbursement__c> newDisbursments = currDisbursments.deepClone(false,false,false);
        
        Test.startTest();
        ContractDisbursementDMLWrapper.getInstance().deleteData(currDisbursments);
        currDisbursments = ContractRelatedRecordQueryUtil.getDisbursements(testContract.Id);
        System.assertEquals(0, currDisbursments.size(), 'No disbursement found after delete');
        
        ContractDisbursementDMLWrapper.getInstance().insertData(newDisbursments);
        currDisbursments = ContractRelatedRecordQueryUtil.getDisbursements(testContract.Id);
        System.assertEquals(origRecordCount, currDisbursments.size(), 'New disbursement records created');
        
        ContractDisbursementDMLWrapper.getInstance().updateData(currDisbursments);
        ContractDisbursementDMLWrapper.getInstance().upsertData(currDisbursments);
        Test.stopTest();
    }
}
