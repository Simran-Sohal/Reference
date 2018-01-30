@isTest
public class TestContractDataHelper{

    /*
     * Lending Contract - 10K Loan @ 4% rate for 12 months with 851.47 payment
     */
    public static Lending_Contract__c getTestContract(fsCore__Company_Setup__c pCompany
                                                    , fsCore__Branch_Setup__c pBranch
                                                    , fsCore__Product_Setup__c pProduct
                                                    , fsCore__Contract_Template_Setup__c pTemplate
                                                    , String pContractTitle){
        Lending_Contract__c testContract = new Lending_Contract__c();
        boolean exceptionFlag = false;
        try{

            testContract.RecordTypeId = fsCore.RecordTypeUtil.getInstance()
                                                    .getRecordTypeMapByName(Schema.SObjectType.Lending_Contract__c.getName())
                                                        .get(pProduct.fsCore__Product_Family__c).Id;
            
            testContract.Product_Family__c = pProduct.fsCore__Product_Family__c;
            testContract.Product_Name__c = pProduct.Id;
            testContract.Company_Name__c = pCompany.Id;
            testContract.Branch_Name__c = pBranch.Id;
            testContract.Contract_Template_Name__c = pTemplate.Id;

            //copy product attributes to contract            
            LendingContractUtil.copyProductToContract(pProduct, testContract);

            //copy contract template attributes to contract            
            LendingContractUtil.copyContractTemplateToContract(pTemplate, testContract);
            
            testContract.Title__c = pContractTitle;
            //TO DO add contract fields here

        }catch(DmlException ex){
            exceptionFlag = true;
            printError(ex);
        }
        System.assertEquals(false, exceptionFlag, 'getTestContract success assert ');
        
        return testContract;
    }        

    private static void printError(Exception ex){
        System.debug(logginglevel.ERROR, ex);
    }

    public static Contract_Direct_Debit__c getTestContractDirectDebit(
                                    Lending_Contract__c pContract
                                  , Contract_Customer__c pCustomer
                                  , fsCore__Bank_Account__c pBankAccount
                                  , String pDebitAmountSource
                                  , Decimal pDebitAmount){
        Map<String, RecordType> directDebitRecTypeMap
                = fsCore.RecordTypeUtil.getInstance()
                        .getRecordTypeMapByName(Schema.SObjectType.Contract_Direct_Debit__c.getName());

        Contract_Direct_Debit__c testDirectDebit = new Contract_Direct_Debit__c();
        testDirectDebit.Lending_Contract_Number__c = pContract.Id;
        testDirectDebit.RecordTypeId = directDebitRecTypeMap.get(Constants.RECORD_TYPE_ACTIVE).Id;
        testDirectDebit.Customer_Reference_Number__c = pCustomer.Id;
        testDirectDebit.Bank_Account__c = pBankAccount.Id;
        testDirectDebit.Debit_Amount_Source__c = pDebitAmountSource;
        testDirectDebit.Debit_Amount__c = pDebitAmount;
        testDirectDebit.Debit_Start_Date__c = System.today();
        testDirectDebit.Next_Debit_Date__c = pContract.Next_Payment_Due_Date__c;
        testDirectDebit.Debit_Frequency__c = pContract.Current_Payment_Frequency__c;
        
        System.assertNotEquals(null, testDirectDebit);
        return testDirectDebit;
    }

    public static Contract_Disbursement__c getTestContractDisbursement(
                                    Lending_Contract__c pContract
                                  , Contract_Customer__c pCustomer
                                  , Id pBankAccountId
                                  , Decimal pAmount){
        Contract_Disbursement__c testDisbursement = getTestContractDisbursement(pContract
                                                           , 'Customer'
                                                           , pCustomer.Account_Name__c
                                                           , pCustomer.Contact_Name__c
                                                           , pBankAccountId
                                                           , pAmount);
        testDisbursement.Customer_Reference_Number__c = pCustomer.Id;
        
        System.assertNotEquals(null, testDisbursement);
        return testDisbursement;
    }

    public static Contract_Disbursement__c getTestContractDisbursement(
                                    Lending_Contract__c pContract
                                  , String pPartyType
                                  , Id pPartyAccountId
                                  , Id pPartyContactId
                                  , Id pBankAccountId
                                  , Decimal pAmount){
        Map<String, RecordType> disbursementRecTypeMap
                = fsCore.RecordTypeUtil.getInstance()
                        .getRecordTypeMapByName(Schema.SObjectType.Contract_Disbursement__c.getName());

        Contract_Disbursement__c testDisbursement = new Contract_Direct_Debit__c();
        testDisbursement.Lending_Contract_Number__c = pContract.Id;
        testDisbursement.RecordTypeId = disbursementRecTypeMap.get(Constants.RECORD_TYPE_OPEN).Id;
        testDisbursement.Party_Type__c = pPartyType;
        testDisbursement.Account_Name__c = pPartyAccountId;
        testDisbursement.Contact_Name__c = pPartyContactId;
        testDisbursement.Bank_Account__c = pBankAccountId;
        testDisbursement.Amount__c = pAmount;
        testDisbursement.Disbursement_Date__c = System.today();
        testDisbursement.Payment_Method__c = 'Electronic Clearing';
        testDisbursement.Debit_Frequency__c = pContract.Current_Payment_Frequency__c;
        
        System.assertNotEquals(null, testDisbursement);
        return testDisbursement;
    }
    
    public static Contract_Assignment__c getTestContractAssignment(
                                    Lending_Contract__c pContract
                                  , fsCore__Queue_Assignment_Setup__c pAssignment){
        Contract_Assignment__c testAssignment = new Contract_Assignment__c();
        testAssignment.Lending_Contract_Number__c = pContract.Id;
        testAssignment.Assignment_Name__c = pAssignment.Id;
        testAssignment.Assigned_On__c = System.Now();
        testAssignment.Completed_On__c = null;
        testAssignment.Is_Assign_Using_Queue_Assignments__c = true;
        testAssignment.Comments__c = null;
        testAssignment.Status__c = 'Open';
        
        System.assertNotEquals(null, testAssignment);
        return testAssignment;
    }

    public static Contract_Stage__c getTestContractStage(
                                    Lending_Contract__c pContract
                                  , fsCore__Stage_Setup__c pStage){
        Contract_Stage__c testStage = new Contract_Stage__c();
        testStage.Lending_Contract_Number__c = pContract.Id;
        testStage.Stage_Name__c = pStage.Id;
        testStage.Entry_Date_Time__c = System.Now();
        testStage.Exit_Date_Time__c = null;
        testStage.Is_Evaluate_Related_Assignments__c = false;
        testStage.Comments__c = null;
        
        System.assertNotEquals(null, testStage);
        return testStage;
    }

    public static Transaction_Processing_Queue__c getTestQueuedTransaction(
                                    Lending_Contract__c pContract
                                  , fsCore__Transaction_Setup__c pTxnSetup){
        Map<String, RecordType> txnQueueRecordTypeMap
                = fsCore.RecordTypeUtil.getInstance()
                        .getRecordTypeMapByName(Schema.SObjectType.Transaction_Processing_Queue__c.getName());
        
        Transaction_Processing_Queue__c testQueuedTxn = new Transaction_Processing_Queue__c();
        testQueuedTxn.Lending_Contract_Number__c = pContract.Id;
        testQueuedTxn.Transaction_Date__c = System.today();
        testQueuedTxn.Transaction_Name__c = pTxnSetup.Id;
        testQueuedTxn.Transaction_Operation_Type__c = pTxnSetup.fsCore__Operation_Type__c;
        testQueuedTxn.RecordTypeId = txnQueueRecordTypeMap.get(Constants.RECORD_TYPE_OPEN).Id;
        testQueuedTxn.Processing_Status__c = Constants.TRANSACTION_QUEUE_STATUS_READY;
        testQueuedTxn.Processing_User__c = UserInfo.getUserId();
        testQueuedTxn.Processing_Result__c = Constants.BLANK_STRING;
        testQueuedTxn.Related_Records__c = Constants.BLANK_STRING;
        
        System.assertNotEquals(null, testQueuedTxn);
        return testQueuedTxn;
    }

    public static Map<String, Transaction_Processing_Parameter__c> getTestQueuedTxnParams(
                                    Transaction_Processing_Queue__c pQueuedTxn
                                  , List<fsCore__Transaction_Parameter_Setup__c> pTxnParamSetupList){
        Map<String, Transaction_Processing_Parameter__c> testQueuedTxnParamMap
                = new Map<String, Transaction_Processing_Parameter__c>();
        
        for(fsCore__Transaction_Parameter_Setup__c param : pTxnParamSetupList){
            Transaction_Processing_Parameter__c txnParam = new Transaction_Processing_Parameter__c();
            txnParam.Name = param.fsCore__Parameter_Name__c;
            
            testQueuedTxnParamMap.put(param.fsCore__Field_Name__c.toLowerCase(), txnParam);
        }
        
        System.assertNotEquals(0, testQueuedTxnParamMap.size());
        return testQueuedTxnParamMap;
    }
}
