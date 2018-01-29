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
            //TO DO add contract fiels here

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

    public static Contract_Balance__c getTestContractBalance(
                                    Lending_Contract__c pContract
                                  , fsCore__Balance_Setup__c pBalance
                                  , Decimal pPostedAmount){
        Contract_Balance__c testBalance = new Contract_Balance__c();
        testBalance.Lending_Contract_Number__c = pContract.Id;
        testBalance.Balance_Name__c = pBalance.Id;
        testBalance.Balance_Family__c = pBalance.fsCore__Balance_Family__c;
        testBalance.ChargeOff_Action__c = 'Charge-Off';
        testBalance.Display_Order__c = 9;
        testBalance.Is_Billing_Required__c = false;
        testBalance.Is_Interest_Accrued__c = false;
        testBalance.Is_Investor_Payable__c = false;
        testBalance.Is_Securitization_Investor_Payable__c = false;
        testBalance.WriteOff_Action__c = 'Waive';
        testBalance.Posted_Amount__c = pPostedAmount;
        testBalance.Adjusted_Minus_Amount__c = 0.00;
        testBalance.Adjusted_Plus_Amount__c = 0.00;
        testBalance.Billed_Amount__c = 0.00;
        testBalance.ChargedOff_Amount__c = 0.00;
        testBalance.ChargedOff_Opening_Amount__c = 0.00;
        testBalance.ChargedOff_Recovered_Amount__c = 0.00;
        testBalance.Opening_Amount__c = 0.00;
        testBalance.Paid_Amount__c = 0.00;
        testBalance.Waived_Amount__c = 0.00;
        
        System.assertNotEquals(null, testBalance);
        return testBalance;
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

}
