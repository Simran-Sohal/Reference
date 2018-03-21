@isTest(seeAllData=false)
private class PaymentListControllerTest{

    @testSetup static void createTestData(){
        String errMsg = Constants.BLANK_STRING;
        Boolean hasError = false;
        try{
            TestDataLoader.loadAccounts();
            TestDataLoader.loadContacts();
            TestDataLoader.loadBankAccounts();
                    
            TestSetupLoader.loadCompanySetup();
            TestSetupLoader.loadBankSetup();
            Map<String, fsCore__Branch_Setup__c> branchMap = TestSetupLoader.loadBranchSetup();
            //test branch has business date 5-Jan-2017
            branchMap.get('TCHQ').fsCore__Business_Date__c = branchMap.get('TCHQ').fsCore__Business_Date__c.addDays(12);
            update branchMap.values();
            
            TestSetupLoader.loadProductSetup();
            TestSetupLoader.loadPaymentAllocMethodSetup();
            TestSetupLoader.loadContractTemplateSetup();
            
            TestDataLoader.loadLendingContractsActive();
        } catch (Exception e){
            hasError = true;
            errMsg = String.valueOf(e);
        }
        System.assertEquals(false, hasError, 'Test data creation assert ' + errMsg);
    }
    
    @isTest
    static void testInboundPaymentList(){
        fsCore__Branch_Setup__c testBranch = TestQueryHelper.getTestBranches().get('TCHQ');
        Lending_Contract__c testContract = TestQueryHelper.getTestLendingContracts().get('AT1701000001');
        List<fsCore__Bank_Account__c> bankAccounts = TestQueryHelper.getTestBankAccountsByContact().get(testContract.Primary_Customer_Contact__c);
        
        Inbound_Payment__c inPmt_1 = TestContractDataHelper.getTestInboundPayment(
                                        testContract
                                      , bankAccounts.get(0)
                                      , testContract.Current_Payment_Amount__c
                                      , testBranch.fsCore__Business_Date__c);
        Inbound_Payment__c inPmt_2 = TestContractDataHelper.getTestInboundPayment(
                                        testContract
                                      , bankAccounts.get(0)
                                      , testContract.Current_Payment_Amount__c
                                      , testBranch.fsCore__Business_Date__c);

        List<Inbound_Payment__c> inboundPayments = new List<Inbound_Payment__c>{inPmt_1, inPmt_2};
        InboundPaymentDMLWrapper.getInstance().insertData(inboundPayments);
        System.assert(inPmt_1.Id != null);
        System.assert(inPmt_2.Id != null);
        
        Test.startTest();
        inboundPayments = ContractRelatedRecordQueryUtil.getInboundPayments(testContract.Id);
        System.assertEquals(2, inboundPayments.size(), '2 inbound payments queried');
        
        PaymentInboundListController listCtrl = new PaymentInboundListController();
        listCtrl.mContractId = testContract.Id;
        
        List<Inbound_Payment__c> contractInPmts = listCtrl.getInboundPmtList();
        System.assertEquals(2, contractInPmts.size(), '2 inbound payments found');
        System.assertEquals(4, listCtrl.getRecordSizeList().size());
        List<Inbound_Payment__c> contractInPmtsForDisplay = listCtrl.getInboundPmtDisplayList();
        System.assertEquals(2, contractInPmtsForDisplay.size(), '2 inbound payments for display');
        
        listCtrl.setRecordSize(1);
        System.assertEquals(1, listCtrl.getRecordSize());
        listCtrl.onRecordSizeChange();
        contractInPmtsForDisplay = listCtrl.getInboundPmtDisplayList();
        System.assertEquals(1, contractInPmtsForDisplay.size(), '1 inbound payment for display');
        
        listCtrl.getDisplayedRecordText();
        System.assertEquals(true, listCtrl.getDisablePrevious());
        System.assertEquals(false, listCtrl.getDisableNext());
        listCtrl.onNext();
        System.assertEquals(false, listCtrl.getDisablePrevious());
        System.assertEquals(true, listCtrl.getDisableNext());
        listCtrl.onPrevious();

        Test.stopTest();
    }

    @isTest
    static void testOutboundPaymentList(){
        fsCore__Branch_Setup__c testBranch = TestQueryHelper.getTestBranches().get('TCHQ');
        Lending_Contract__c testContract = TestQueryHelper.getTestLendingContracts().get('AT1701000001');
        List<fsCore__Bank_Account__c> bankAccounts = TestQueryHelper.getTestBankAccountsByContact().get(testContract.Primary_Customer_Contact__c);
        
        fsCore__Outbound_Payment__c outPmt_1 = TestContractDataHelper.getTestOutboundPayment(
                                                    testContract
                                                  , bankAccounts.get(0)
                                                  , (testContract.Financed_Amount__c/2)
                                                  , testBranch.fsCore__Business_Date__c);
        fsCore__Outbound_Payment__c outPmt_2 = TestContractDataHelper.getTestOutboundPayment(
                                                    testContract
                                                  , bankAccounts.get(0)
                                                  , (testContract.Financed_Amount__c/2)
                                                  , testBranch.fsCore__Business_Date__c);

        List<fsCore__Outbound_Payment__c> outboundPayments = new List<fsCore__Outbound_Payment__c>{outPmt_1, outPmt_2};
        fsCore.OutboundPaymentDMLWrapper.getInstance().insertData(outboundPayments);
        System.assert(outPmt_1.Id != null);
        System.assert(outPmt_2.Id != null);
        
        Test.startTest();
        outboundPayments = ContractRelatedRecordQueryUtil.getOutboundPayments(testContract.Id);
        System.assertEquals(2, outboundPayments.size(), '2 outbound payments queried');
        
        PaymentOutboundListController listCtrl = new PaymentOutboundListController();
        listCtrl.mContractId = testContract.Id;
        
        List<fsCore__Outbound_Payment__c> contractOutPmts = listCtrl.getOutboundPmtList();
        System.assertEquals(2, contractOutPmts.size(), '2 outbound payments found');
        System.assertEquals(4, listCtrl.getRecordSizeList().size());
        List<fsCore__Outbound_Payment__c> contractOutPmtsForDisplay = listCtrl.getOutboundPmtDisplayList();
        System.assertEquals(2, contractOutPmtsForDisplay.size(), '2 outbound payments for display');
        
        listCtrl.setRecordSize(1);
        System.assertEquals(1, listCtrl.getRecordSize());
        listCtrl.onRecordSizeChange();
        contractOutPmtsForDisplay = listCtrl.getOutboundPmtDisplayList();
        System.assertEquals(1, contractOutPmtsForDisplay.size(), '1 outbound payment for display');
        
        listCtrl.getDisplayedRecordText();
        System.assertEquals(true, listCtrl.getDisablePrevious());
        System.assertEquals(false, listCtrl.getDisableNext());
        listCtrl.onNext();
        System.assertEquals(false, listCtrl.getDisablePrevious());
        System.assertEquals(true, listCtrl.getDisableNext());
        listCtrl.onPrevious();

        Test.stopTest();
    }

}
