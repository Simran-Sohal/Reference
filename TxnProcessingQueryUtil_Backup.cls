/*
 * Copyright (c) 2017 FinancialSpectra Pty Ltd
 * All rights reserved.
 * 
 * Class Name   - TransactionProcessingQueryUtil
 *
 * Description  - This class contains utility methods related to querying 
 *                and preparing query based objects for Transaction processing  
 *
 * Developer(s) - ADagur, SSingh
 *
 */
public with sharing class TransactionProcessingQueryUtil {
    private static final String CLASS_NAME = 'TransactionProcessingQueryUtil';
   
    /*
     * Method to get the queued tranactions
     */
    public static Transaction_Processing_Queue__c getQueuedTransaction(Id pQueuedTxnId) {
        Map<Id, Transaction_Processing_Queue__c> queuedTxnMap = new Map<Id, Transaction_Processing_Queue__c>(getQueuedTransactionList(new Set<Id>{pQueuedTxnId}));
        
        return queuedTxnMap.get(pQueuedTxnId);
    }
    
    public static List<Transaction_Processing_Queue__c> getQueuedTransactionList(Set<Id> pQueuedTxnIdSet) {
        Logger.enter(CLASS_NAME, 'getTransactionQueueList');
        
        List<Transaction_Processing_Queue__c> transactionQueueList
                                        = [SELECT Id, Name
                                                , RecordTypeId
                                                , RecordType.DeveloperName
                                                , Lending_Contract_Number__c
                                                , Lending_Contract_Number__r.Name
                                                , Lending_Contract_Number__r.Branch_Code__c
                                                , Transaction_Date__c
                                                , Transaction_Name__c
                                                , Transaction_Code__c
                                                , Transaction_Category__c
                                                , Transaction_Operation_Type__c
                                                , Transaction_Name__r.fsCore__Transaction_Category__c
                                                , Transaction_Name__r.fsCore__Reverse_Transaction_Name__c
                                                , Transaction_Name__r.fsCore__Waive_Transaction_Name__c
                                                , Transaction_Name__r.fsCore__Transaction_Code__c
                                                , Related_Records__c
                                                , Is_Processed__c
                                                , Processing_Status__c
                                                , Processing_Result__c
                                                , OwnerId
                                                , Comments__c 
                                             FROM Transaction_Processing_Queue__c
                                            WHERE Id IN :pQueuedTxnIdSet
                                              AND RecordType.DeveloperName = :Constants.RECORD_TYPE_OPEN
                                              AND Processing_Status__c != :Constants.TRANSACTION_QUEUE_STATUS_VOID
                                                 /***DO NOT CHANGE THE ORDER BY***/
                                            ORDER BY Lending_Contract_Number__c ASC, Transaction_Date__c ASC, Name ASC];
                                         
        Logger.exit(CLASS_NAME, 'getTransactionQueueList');
        return transactionQueueList;
    } 

    /*
     * Method to get the queued tranactions
     */
    public static List<Transaction_Processing_Parameter__c> getQueuedTransactionParameters(Id pQueuedTxnId) {
        return getQueuedTransactionParametersMap(new Set<Id>{pQueuedTxnId}).get(pQueuedTxnId);
    }
    
    public static Map<Id, List<Transaction_Processing_Parameter__c>> getQueuedTransactionParametersMap(Set<Id> pQueuedTxnIdSet) {
        Logger.enter(CLASS_NAME, 'getTransactionQueueParametersMap');
        Map<Id, List<Transaction_Processing_Parameter__c>> transactionQueueParamMap = new Map<Id, List<Transaction_Processing_Parameter__c>>();
        if (pQueuedTxnIdSet == null || (pQueuedTxnIdSet != null && pQueuedTxnIdSet.size() == 0)) return transactionQueueParamMap;
        
        for (Id queuedTxnId : pQueuedTxnIdSet){
            transactionQueueParamMap.put(queuedTxnId, new List<Transaction_Processing_Parameter__c>());
        }
        
        List<Transaction_Processing_Parameter__c> transactionQueueAllParamList
                                        = [SELECT Id, Name
                                                , Object_Name__c
                                                , Field_Name__c
                                                , Data_Type__c
                                                , Default_Value__c
                                                , Display_Order__c
                                                , Boolean_Value__c
                                                , Currency_Value__c
                                                , Date_Value__c
                                                , Number_Value__c
                                                , String_Value__c
                                                , Reference_Value_ID__c
                                                , Transaction_Queue_Name__c
                                                , Transaction_Parameter_Field_ID__c
                                                , Is_Required__c
                                                , Is_Non_Editable__c
                                                , Is_Hidden__c
                                             FROM Transaction_Processing_Parameter__c
                                            WHERE Transaction_Queue_Name__c IN :pQueuedTxnIdSet
                                            /***DO NOT CHANGE THE ORDER BY***/
                                            ORDER BY Transaction_Queue_Name__c ASC, Display_Order__c ASC, Name ASC];

        for(Transaction_Processing_Parameter__c txnParam : transactionQueueAllParamList) {
            if (transactionQueueParamMap.containsKey(txnParam.Transaction_Queue_Name__c)){
                transactionQueueParamMap.get(txnParam.Transaction_Queue_Name__c).add(txnParam);
            }
        }
        
        Logger.exit(CLASS_NAME, 'getTransactionQueueParametersMap');
        return transactionQueueParamMap;
    }

    public static List<fsCore__Fee_Setup__c> getFeeSetupByFeeId(Set<Id> pFeeSetupIdSet, Boolean pActiveOnly) {
        Logger.enter(CLASS_NAME, 'getFeeSetupByFeeId');
        List<fsCore__Fee_Setup__c> feeSetupList = [SELECT Id
                                                        , Name
                                                        , fsCore__Transaction_Name__c
                                                        , fsCore__Calculation_Method__c
                                                        , fsCore__Calculation_Percent_Default__c
                                                        , fsCore__Default_Company_Availability__c
                                                        , fsCore__Default_Product_Availability__c
                                                        , fsCore__Default_Selection_Rule_Result__c
                                                        , fsCore__End_Date__c
                                                        , fsCore__Fee_Amount_Maximum__c
                                                        , fsCore__Fee_Amount_Minimum__c
                                                        , fsCore__Fee_Category__c
                                                        , fsCore__Fixed_Amount_Default__c
                                                        , fsCore__Is_Lease__c
                                                        , fsCore__Is_Line__c
                                                        , fsCore__Is_Loan__c
                                                        , fsCore__Start_Date__c
                                                        , fsCore__Tier_Calculation_Field_Name__c
                                                        , (SELECT Id
                                                                , Name
                                                                , fsCore__Calculation_Percent__c
                                                                , fsCore__Fixed_Amount__c
                                                                , fsCore__Tier_Value_From__c
                                                                , fsCore__Tier_Value_To__c
                                                             FROM fsCore__Fee_Tier_Setup__r
                                                            WHERE (fsCore__Is_Active__c = true OR
                                                                   fsCore__Is_Active__c = :pActiveOnly))
                                                     FROM fsCore__Fee_Setup__c
                                                    WHERE Id IN :pFeeSetupIdSet
                                                      AND (fsCore__Is_Active__c = true OR
                                                           fsCore__Is_Active__c = :pActiveOnly)
                                                 ORDER BY fsCore__Selection_Order__c];
        
        Logger.exit(CLASS_NAME, 'getFeeSetupByFeeId');
        return feeSetupList;
    } 

    public static List<fsCore__Fee_Setup__c> getFeeSetupByTransactionSetupId(Set<Id> pFeeTransactionSetupIdSet) {
        Logger.enter(CLASS_NAME, 'getFeeSetupByTransactionSetupId');
        List<fsCore__Fee_Setup__c> feeSetupList = [SELECT Id
                                                        , Name
                                                        , fsCore__Transaction_Name__c
                                                        , fsCore__Calculation_Method__c
                                                        , fsCore__Calculation_Percent_Default__c
                                                        , fsCore__Default_Company_Availability__c
                                                        , fsCore__Default_Product_Availability__c
                                                        , fsCore__Default_Selection_Rule_Result__c
                                                        , fsCore__End_Date__c
                                                        , fsCore__Fee_Amount_Maximum__c
                                                        , fsCore__Fee_Amount_Minimum__c
                                                        , fsCore__Fee_Category__c
                                                        , fsCore__Fixed_Amount_Default__c
                                                        , fsCore__Is_Lease__c
                                                        , fsCore__Is_Line__c
                                                        , fsCore__Is_Loan__c
                                                        , fsCore__Start_Date__c
                                                        , fsCore__Tier_Calculation_Field_Name__c
                                                        , (SELECT Id
                                                                , Name
                                                                , fsCore__Calculation_Percent__c
                                                                , fsCore__Fixed_Amount__c
                                                                , fsCore__Tier_Value_From__c
                                                                , fsCore__Tier_Value_To__c
                                                             FROM fsCore__Fee_Tier_Setup__r
                                                            WHERE fsCore__Is_Active__c = true)
                                                     FROM fsCore__Fee_Setup__c
                                                    WHERE fsCore__Is_Active__c = true
                                                      AND fsCore__Transaction_Name__c IN :pFeeTransactionSetupIdSet];
        Logger.exit(CLASS_NAME, 'getFeeSetupByTransactionSetupId');
        return feeSetupList;
    } 

    public static List<Contract_Fee__c> getContractFeeByTransactionSetupId(Set<Id> pLendingContractIdSet, Set<Id> pFeeTransactionSetupIdSet) {
        Logger.enter(CLASS_NAME, 'getContractFeeByTransactionSetupId');
        List<Contract_Fee__c> contractFeeList = [SELECT Id
                                                      , Name
                                                      , Lending_Contract_Number__c
                                                      , Transaction_Name__c
                                                      , Calculation_Method__c
                                                      , Calculation_Percent_Default__c
                                                      , Fixed_Amount_Default__c
                                                      , Fee_Category__c
                                                      , Fee_Name__c
                                                      , Fee_Amount_Maximum__c
                                                      , Fee_Amount_Minimum__c
                                                      , Tier_Calculation_Field_Name__c
                                                      , Fee_Name__r.Name
                                                   FROM Contract_Fee__c
                                                  WHERE Lending_Contract_Number__c IN :pLendingContractIdSet
                                                    AND Transaction_Name__c IN :pFeeTransactionSetupIdSet
                                                    AND Is_Active__c = true
                                               ORDER BY Lending_Contract_Number__c, Id];
        Logger.exit(CLASS_NAME, 'getContractFeeByTransactionSetupId');
        return contractFeeList;
    }

    public static List<Contract_Fee_Tier__c> getContractFeeTiersByContractFeeId(Set<Id> pContractFeeIdSet) {
        Logger.enter(CLASS_NAME, 'getContractFeeTiersByContractFeeId');
        List<Contract_Fee_Tier__c> contractFeeTierList = [SELECT Id
                                                               , Name
                                                               , Calculation_Percent__c
                                                               , Fixed_Amount__c
                                                               , Tier_Value_From__c
                                                               , Tier_Value_To__c
                                                               , Fee_Reference_Number__c
                                                            FROM Contract_Fee_Tier__c
                                                           WHERE Fee_Reference_Number__c IN :pContractFeeIdSet
                                                        ORDER BY Fee_Reference_Number__c, Tier_Value_From__c];
        Logger.exit(CLASS_NAME, 'getContractFeeTiersByContractFeeId');
        return contractFeeTierList;
    }

    public static Map<Id, PaymentAllocationMethodSetupObject> getPaymentAllocationSetupObjectMap(Set<Id> pPaymentAllocationSetupIdSet) {
        Logger.enter(CLASS_NAME, 'getPaymentAllocationSetupObjectMap==> '+pPaymentAllocationSetupIdSet);
        List<fsCore__Payment_Allocation_Method_Setup__c> paymentAllocationMethodList = 
                   [SELECT Id
                         , Name
                         , fsCore__Excess_Payment_Handling_Method__c
                         , fsCore__Balance_Collection_Method__c
                         , (SELECT Id
                                 , Name
                                 , fsCore__Allocation_Order__c
                                 , fsCore__Transaction_Name__c
                                 , fsCore__Transaction_Name__r.fsCore__Transaction_Code__c
                                 , fsCore__Transaction_Name__r.fsCore__Balance_Name__c
                                 , fsCore__Transaction_Name__r.fsCore__Balance_Name__r.fsCore__Balance_Family__c
                                 , fsCore__Transaction_Name__r.fsCore__Balance_Name__r.Name
                                 , fsCore__Payment_Allocation_Method__c
                              FROM fsCore__Payment_Allocation_Detail_Setup__r
                          ORDER BY fsCore__Allocation_Order__c)
                      FROM fsCore__Payment_Allocation_Method_Setup__c
                     WHERE Id IN :pPaymentAllocationSetupIdSet
                  ORDER BY Id];

        Map<Id, PaymentAllocationMethodSetupObject> paymentAllocationSetupObjectMap = new Map<Id, PaymentAllocationMethodSetupObject>();
        for(fsCore__Payment_Allocation_Method_Setup__c paymentAllocationMethod : paymentAllocationMethodList) {
            PaymentAllocationMethodSetupObject paymentAllocationSetupObject = new PaymentAllocationMethodSetupObject();
            paymentAllocationSetupObject.mPaymentAllocationMethodId     = paymentAllocationMethod.Id;
            paymentAllocationSetupObject.mPaymentAllocationMethodName   = paymentAllocationMethod.Name;
            paymentAllocationSetupObject.mExcessPaymentHandlingMethod   = paymentAllocationMethod.fsCore__Excess_Payment_Handling_Method__c;
            paymentAllocationSetupObject.mBalanceCollectionMethod       = paymentAllocationMethod.fsCore__Balance_Collection_Method__c;

            List<PaymentAllocationMethodSetupObject.PaymentAllocationDetailSetup> paymentAllocationDetailSetupList = 
                                                                        new List<PaymentAllocationMethodSetupObject.PaymentAllocationDetailSetup>();
            for(fsCore__Payment_Allocation_Detail_Setup__c paymentAllocationDetail : paymentAllocationMethod.fsCore__Payment_Allocation_Detail_Setup__r) {
                PaymentAllocationMethodSetupObject.PaymentAllocationDetailSetup paymentAllocationDetailSetup = 
                                                                        new PaymentAllocationMethodSetupObject.PaymentAllocationDetailSetup();
                paymentAllocationDetailSetup.mAllocationOrder = paymentAllocationDetail.fsCore__Allocation_Order__c == null ? 0 :
                                                                paymentAllocationDetail.fsCore__Allocation_Order__c.intValue();
                paymentAllocationDetailSetup.mTransactionId   = paymentAllocationDetail.fsCore__Transaction_Name__c;
                paymentAllocationDetailSetup.mTransactionCode = paymentAllocationDetail.fsCore__Transaction_Name__r.fsCore__Transaction_Code__c;
                paymentAllocationDetailSetup.mBalanceId       = paymentAllocationDetail.fsCore__Transaction_Name__r.fsCore__Balance_Name__c;
                paymentAllocationDetailSetup.mBalanceName     = paymentAllocationDetail.fsCore__Transaction_Name__r.fsCore__Balance_Name__r.Name;
                paymentAllocationDetailSetup.mBalanceFamily   = paymentAllocationDetail.fsCore__Transaction_Name__r.fsCore__Balance_Name__r.fsCore__Balance_Family__c;

                paymentAllocationDetailSetupList.add(paymentAllocationDetailSetup);
            }
            paymentAllocationSetupObject.mPaymentAllocationDetailSetupList = paymentAllocationDetailSetupList;
            paymentAllocationSetupObjectMap.put(paymentAllocationMethod.Id, paymentAllocationSetupObject);
        }
        Logger.exit(CLASS_NAME, 'getPaymentAllocationSetupObjectMap');
        return paymentAllocationSetupObjectMap;
    }

    public static List<Contract_Transaction__c> getContractTransactionList(Set<Id> pContractTransactionIdSet) {
        Logger.enter(CLASS_NAME, 'getContractTransactionList');
        List<Contract_Transaction__c> contractTxnList = [SELECT Id, Name
                                                              , Lending_Contract_Number__c
                                                              , Lending_Contract_Number__r.Name
                                                              , Lending_Contract_Number__r.Branch_Code__c
                                                              , Transaction_Name__c
                                                              , Transaction_Name__r.fsCore__Reverse_Transaction_Name__c
                                                              , Transaction_Name__r.fsCore__Is_Posting_Suspension_Allowed__c
                                                              , Transaction_Date__c
                                                              , Transaction_Code__c
                                                              , Transaction_Amount__c
                                                              , Transaction_Category__c
                                                              , Transaction_Family__c
                                                              , Transaction_Operation_Type__c
                                                              , Original_Transaction_Amount__c
                                                              , Parent_Transaction_Name__c
                                                              , Is_Parent_Transaction__c
                                                              , Original_Transaction_Name__c
                                                              , Inbound_Payment_Number__c
                                                              , Reversed_Reposted_Transaction_Name__c
                                                              , Balance_Family__c
                                                              , Balance_Name__c
                                                              , Bankruptcy_Filed__c
                                                              , Branch_Name__c
                                                              , Business_Date__c
                                                              , System_Date__c
                                                              , Company_Name__c
                                                              , Contract_Status__c
                                                              , Is_Internal_Reposted__c
                                                              , Is_Internal_Reversed__c
                                                              , Non_Accrual__c
                                                              , Non_Performing__c
                                                              , Payment_Mode__c
                                                              , Payment_Reason__c
                                                              , Payment_Source__c
                                                              , Pool_Repurchased__c
                                                              , Processing_User__c
                                                              , Processing_User_Profile_Id__c
                                                              , Product_Name__c
                                                              , Promotion_Name__c
                                                              , Repossessed__c
                                                              , Securitization_Pool_Name__c
                                                              , Securitized__c
                                                              , Transaction_Queue_Name__c
                                                              , Transaction_Status__c
                                                              , Process_Transaction_As__c
                                                              , Fee_Name__c
                                                              , Contract_Fee_Name__c
                                                              , Transaction_Posting_Set_Key__c
                                                              , Original_Transaction_Posting_Set_Key__c
                                                              , Is_Active__c
                                                              , Lending_Contract_Snapshot__c
                                                              , Contract_Repayment_Schedule_Snapshot__c
                                                              , Contract_Repayment_Snapshot_1__c
                                                              , Contract_Repayment_Snapshot_2__c
                                                              , Contract_Due_Snapshot__c
                                                              , Transaction_Posting_Master_Key__c
                                                              , Payment_Allocation_Method__c 
                                                              , Transaction_Due_Date__c
                                                              , Due_Allocated_Amount__c
                                                              , Excess_Payment_Handling_Method__c
                                                              , Extension_Terms__c
                                                              , Is_Borrower_Military_Duty__c
                                                              , Original_Rate__c
                                                              , Reschedule_Impact_Method__c
                                                              , New_Due_Date__c
                                                              , New_Frequency__c
                                                              , New_Rate__c
                                                              , New_Term__c
                                                              , Is_Recalculate_Repayments__c
                                                              , (SELECT Id
                                                                      , Allocated_Amount__c
                                                                      , Balance_Name__c
                                                                      , Balance_Family__c 
                                                                      , Lending_Contract_Number__c
                                                                      , Transaction_Name__c
                                                                      , Transaction_Name__r.fsCore__Reverse_Transaction_Name__c
                                                                      , Transaction_Code__c 
                                                                      , Transaction_Posting_Master_Key__c
                                                                      , Transaction_Posting_Set_Key__c
                                                                      , Transaction_Reference_Number__c
                                                                   FROM Contract_Transaction_Balance_Allocation__r)                                                                
                                                           FROM Contract_Transaction__c
                                                          WHERE Id IN :pContractTransactionIdSet
                                                            AND Is_Active__c = true
                                                            AND Transaction_Status__c = :Constants.TRANSACTION_STATUS_PROCESSED
                                                          /***DO NOT CHANGE THE ORDER BY***/
                                                          ORDER BY Lending_Contract_Number__c ASC, Transaction_Date__c DESC, Name DESC];
        Logger.exit(CLASS_NAME, 'getContractTransactionList');
        return contractTxnList;
    }

    public static List<Contract_Transaction__c> getBackDateContractTransactionList(Set<Id> pBackDateLendingContractSet, Date pEarliestTxnDate) {
        Logger.enter(CLASS_NAME, 'getBackDateContractTransactionList');
        Logger.logMessage('pEarliestTxnDate ==>'+pEarliestTxnDate);
        Date earliestTxnDate = pEarliestTxnDate.addDays(-1);
        //Date earliestTxnDate = pEarliestTxnDate ; 
        //adagur commented out the below code to 
        //not to pick the txns which are for todays date
        //pEarliestTxnDate.addDays(-1);
        
        List<Contract_Transaction__c> contractTxnList = [SELECT Id
                                                              , Name
                                                              , Lending_Contract_Number__c
                                                              , Lending_Contract_Number__r.Name
                                                              , Lending_Contract_Number__r.Branch_Code__c
                                                              , Transaction_Name__c
                                                              , Transaction_Name__r.fsCore__Reverse_Transaction_Name__c
                                                              , Transaction_Name__r.fsCore__Is_Posting_Suspension_Allowed__c
                                                              , Transaction_Date__c
                                                              , Transaction_Code__c
                                                              , Transaction_Amount__c
                                                              , Transaction_Category__c
                                                              , Transaction_Family__c
                                                              , Transaction_Operation_Type__c
                                                              , Original_Transaction_Amount__c
                                                              , Parent_Transaction_Name__c
                                                              , Is_Parent_Transaction__c
                                                              , Original_Transaction_Name__c
                                                              , Inbound_Payment_Number__c
                                                              , Reversed_Reposted_Transaction_Name__c
                                                              , Balance_Family__c
                                                              , Balance_Name__c
                                                              , Bankruptcy_Filed__c
                                                              , Branch_Name__c
                                                              , Business_Date__c
                                                              , System_Date__c
                                                              , Company_Name__c
                                                              , Contract_Status__c
                                                              , Is_Internal_Reposted__c
                                                              , Is_Internal_Reversed__c
                                                              , Non_Accrual__c
                                                              , Non_Performing__c
                                                              , Payment_Mode__c
                                                              , Payment_Reason__c
                                                              , Payment_Source__c
                                                              , Pool_Repurchased__c
                                                              , Processing_User__c
                                                              , Processing_User_Profile_Id__c
                                                              , Product_Name__c
                                                              , Promotion_Name__c
                                                              , Repossessed__c
                                                              , Securitization_Pool_Name__c
                                                              , Securitized__c
                                                              , Transaction_Queue_Name__c
                                                              , Transaction_Status__c
                                                              , Process_Transaction_As__c
                                                              , Fee_Name__c
                                                              , Contract_Fee_Name__c
                                                              , Transaction_Posting_Set_Key__c
                                                              , Original_Transaction_Posting_Set_Key__c
                                                              , Is_Active__c
                                                              , Lending_Contract_Snapshot__c
                                                              , Contract_Repayment_Schedule_Snapshot__c
                                                              , Contract_Repayment_Snapshot_1__c
                                                              , Contract_Repayment_Snapshot_2__c     
                                                              , Contract_Due_Snapshot__c
                                                              , Transaction_Posting_Master_Key__c     
                                                              , Payment_Allocation_Method__c
                                                              , Transaction_Due_Date__c
                                                              , Due_Allocated_Amount__c
                                                              , Excess_Payment_Handling_Method__c
                                                              , Extension_Terms__c
                                                              , Is_Borrower_Military_Duty__c
                                                              , Original_Rate__c
                                                              , Reschedule_Impact_Method__c
                                                              , New_Due_Date__c
                                                              , New_Frequency__c
                                                              , New_Rate__c
                                                              , New_Term__c      
                                                              , Is_Recalculate_Repayments__c                                                        
                                                              , (SELECT Id
                                                                      , Allocated_Amount__c
                                                                      , Balance_Name__c
                                                                      , Balance_Family__c 
                                                                      , Lending_Contract_Number__c
                                                                      , Transaction_Name__c
                                                                      , Transaction_Name__r.fsCore__Reverse_Transaction_Name__c
                                                                      , Transaction_Code__c 
                                                                      , Transaction_Posting_Master_Key__c
                                                                      , Transaction_Posting_Set_Key__c
                                                                      , Transaction_Reference_Number__c
                                                                   FROM Contract_Transaction_Balance_Allocation__r)                                                              
                                                           FROM Contract_Transaction__c
                                                          WHERE Lending_Contract_Number__c IN :pBackDateLendingContractSet
                                                            AND Is_Active__c = true
                                                            AND Transaction_Status__c = :Constants.TRANSACTION_STATUS_PROCESSED
                                                            AND Transaction_Date__c > :earliestTxnDate 
                                                           /***DO NOT CHANGE THE ORDER BY***/
                                                          ORDER BY Lending_Contract_Number__c ASC, Transaction_Date__c DESC, Name DESC];
        
        logMessage('contractTxnList size :'+contractTxnList.size());

        Logger.exit(CLASS_NAME, 'getBackDateContractTransactionList');
        return contractTxnList;
    }

    public static Map<Id, List<Contract_Balance__c>> getContractBalanceMap(Set<Id> pLendingContractIdSet) {
        Logger.enter(CLASS_NAME, 'getContractBalanceMap');
        Map<Id, List<Contract_Balance__c>> contractBalancesMap = ContractRelatedRecordQueryUtil.getBalancesMap(pLendingContractIdSet);
        
        /*
        if (pLendingContractIdSet == null || (pLendingContractIdSet != null && pLendingContractIdSet.size() == 0)) return contractBalancesMap;
        
        for (Id contractId : pLendingContractIdSet){
            contractBalancesMap.put(contractId, new List<Contract_Balance__c>());
        }

        List<Contract_Balance__c> contractBalanceList = [SELECT Id , Name
                                                              , Balance_Name__c
                                                              , Balance_Name__r.Name
                                                              , Lending_Contract_Number__c
                                                              , Adjusted_Minus_Amount__c
                                                              , Adjusted_Plus_Amount__c
                                                              , Balance_Family__c
                                                              , Billed_Amount__c
                                                              , ChargeOff_Action__c
                                                              , ChargedOff_Amount__c
                                                              , ChargedOff_Opening_Amount__c
                                                              , ChargedOff_Recovered_Amount__c
                                                              , Display_Order__c
                                                              , Is_Billing_Required__c
                                                              , Is_Interest_Accrued__c
                                                              , Rate__c
                                                              , Is_Investor_Payable__c
                                                              , Is_Securitization_Investor_Payable__c
                                                              , Opening_Amount__c
                                                              , Outstanding_Amount__c
                                                              , Paid_Amount__c
                                                              , Posted_Amount__c
                                                              , Waived_Amount__c
                                                              , WriteOff_Action__c
                                                           FROM Contract_Balance__c
                                                          WHERE Lending_Contract_Number__c IN :pLendingContractIdSet
                                                          ORDER BY Lending_Contract_Number__c, Display_Order__c];
        
        for(Contract_Balance__c contractBalance : contractBalanceList) {
            if (contractBalancesMap.containsKey(contractBalance.Lending_Contract_Number__c)){
                contractBalancesMap.get(contractBalance.Lending_Contract_Number__c).add(contractBalance);
            }
        }
        */

        Logger.exit(CLASS_NAME, 'getContractBalanceMap');
        return contractBalancesMap;
    }

    public static Map<Id, List<Contract_Itemization__c>> getContractItemizationMap(Set<Id> pLendingContractIdSet) {
        Logger.enter(CLASS_NAME, 'getContractItemizationMap');
        Map<Id, List<Contract_Itemization__c>> contractItemizationMap = new Map<Id, List<Contract_Itemization__c>>();
        if (pLendingContractIdSet == null || (pLendingContractIdSet != null && pLendingContractIdSet.size() == 0)) return contractItemizationMap;
        
        for (Id contractId : pLendingContractIdSet){
            contractItemizationMap.put(contractId, new List<Contract_Itemization__c>());
        }

        List<Contract_Itemization__c> contractItemizationList = [SELECT Id
                                                                      , Name
                                                                      , Plus_Or_Minus__c
                                                                      , Amortization_Calculation_Method__c
                                                                      , Amortization_Fee_Method__c
                                                                      , Amortization_Frequency__c
                                                                      , Actual_Amount_Unsigned__c
                                                                      , Itemization_Family__c
                                                                      , Itemization_Name_Formula__c
                                                                      , Itemization_Name__c
                                                                      , Itemization_Name__r.fsCore__Transaction_Name__c
                                                                      , Lending_Contract_Number__c
                                                                   FROM Contract_Itemization__c
                                                                  WHERE Lending_Contract_Number__c IN :pLendingContractIdSet
                                                                    AND Itemization_Name__r.fsCore__Transaction_Name__c != null
                                                               ORDER BY Lending_Contract_Number__c];

        for(Contract_Itemization__c contractItemization : contractItemizationList) {
            if (contractItemizationMap.containsKey(contractItemization.Lending_Contract_Number__c)){
                contractItemizationMap.get(contractItemization.Lending_Contract_Number__c).add(contractItemization);
            }
        }

        Logger.exit(CLASS_NAME, 'getContractItemizationMap');
        return contractItemizationMap;
    } 

    public static Map<Id, List<Contract_Direct_Debit__c>> getContractDirectDebitMap(Set<Id> pLendingContractIdSet) {
        Logger.enter(CLASS_NAME, 'getContractDirectDebitMap');
        Map<Id, List<Contract_Direct_Debit__c>> contractDirectDebitMap = ContractRelatedRecordQueryUtil.getDirectDebitsMap(pLendingContractIdSet, true);
        /*
        if (pLendingContractIdSet == null || (pLendingContractIdSet != null && pLendingContractIdSet.size() == 0)) return contractDirectDebitMap;
        
        for (Id contractId : pLendingContractIdSet){
            contractDirectDebitMap.put(contractId, new List<Contract_Direct_Debit__c>());
        }

        List<Contract_Direct_Debit__c> contractDebitList = [SELECT Id, Name
                                                                  , Lending_Contract_Number__c
                                                                  , Next_Debit_Date__c
                                                                  , Debit_End_Date__c
                                                                  , Debit_Frequency__c
                                                                  , Debit_Day__c
                                                               FROM Contract_Direct_Debit__c
                                                              WHERE Lending_Contract_Number__c IN :pLendingContractIdSet
                                                                AND Is_Active__c = true
                                                              ORDER BY Lending_Contract_Number__c];

        for(Contract_Direct_Debit__c contractDebit : contractDebitList) {
            if (contractDirectDebitMap.containsKey(contractDebit.Lending_Contract_Number__c)){
                contractDirectDebitMap.get(contractDebit.Lending_Contract_Number__c).add(contractDebit);
            }
        }
        */
        Logger.exit(CLASS_NAME, 'getContractDirectDebitMap');
        return contractDirectDebitMap;
    }  

    public static Map<Id, List<Contract_Investment__c>> getContractInvestorMap(Set<Id> pLendingContractIdSet) {
        Logger.enter(CLASS_NAME, 'getContractInvestorMap');
        Map<Id, List<Contract_Investment__c>> contractInvestorMap = ContractRelatedRecordQueryUtil.getInvestmentsMap(pLendingContractIdSet, true);

        /*
        if (pLendingContractIdSet == null || (pLendingContractIdSet != null && pLendingContractIdSet.size() == 0)) return contractInvestorMap;
        
        for (Id contractId : pLendingContractIdSet){
            contractInvestorMap.put(contractId, new List<Contract_Investment__c>());
        }

        List<Contract_Investment__c> contractInvestmentList = [SELECT Id, Name
                                                                  , Account_Name__c
                                                                  , Contact_Name__c
                                                                  , Contribution_Percent__c
                                                                  , Contribution_Amount__c
                                                                  , Lending_Contract_Number__c
                                                                  , Rate__c
                                                                  , Service_Rate__c
                                                               FROM Contract_Investment__c
                                                              WHERE Lending_Contract_Number__c IN :pLendingContractIdSet
                                                                AND Is_Active__c = true
                                                            ORDER BY Lending_Contract_Number__c];

        for(Contract_Investment__c contractInvestment : contractInvestmentList) {
            if (contractInvestorMap.containsKey(contractInvestment.Lending_Contract_Number__c)){
                contractInvestorMap.get(contractInvestment.Lending_Contract_Number__c).add(contractInvestment);
            }
        }
        */
        
        Logger.exit(CLASS_NAME, 'getContractInvestorMap');
        return contractInvestorMap;
    }        

    public static Map<Id, List<Contract_Repayment_Schedule__c>> getContractRepaymentScheduleMap(Set<Id> pLendingContractIdSet) {
        Logger.enter(CLASS_NAME, 'getContractRepaymentScheduleMap');
        Map<Id, List<Contract_Repayment_Schedule__c>> contractRepaymentScheduleMap = ContractRelatedRecordQueryUtil.getRepaymentSchedulesMap(pLendingContractIdSet);
        
        /*
        if (pLendingContractIdSet == null || (pLendingContractIdSet != null && pLendingContractIdSet.size() == 0)) return contractRepaymentScheduleMap;
        
        for (Id contractId : pLendingContractIdSet){
            contractRepaymentScheduleMap.put(contractId, new List<Contract_Repayment_Schedule__c>());
        }
        
        List<Contract_Repayment_Schedule__c> contractRepaymentSchList = [SELECT Id, Name
                                                                  , Is_Predefined_Payment__c
                                                                  , Lending_Contract_Number__c
                                                                  , Number_Of_Payments__c
                                                                  , Payment_Amount__c
                                                                  , Start_Date__c
                                                               FROM Contract_Repayment_Schedule__c
                                                              WHERE Lending_Contract_Number__c IN :pLendingContractIdSet
                                                              ORDER BY Lending_Contract_Number__c, Start_Date__c];
        
        for(Contract_Repayment_Schedule__c contractRepaySchedule : contractRepaymentSchList) {
            if (contractRepaymentScheduleMap.containsKey(contractRepaySchedule.Lending_Contract_Number__c)){
                contractRepaymentScheduleMap.get(contractRepaySchedule.Lending_Contract_Number__c).add(contractRepaySchedule);
            }
        }
        */
        Logger.exit(CLASS_NAME, 'getContractRepaymentScheduleMap');
        return contractRepaymentScheduleMap;
    }

    public static Map<Id, List<Contract_Draw_Preference__c>> getContractDrawPreferencesMap(Set<Id> pLendingContractIdSet) {
        Logger.enter(CLASS_NAME, 'getContractDrawPreferencesMap');
        Map<Id, List<Contract_Draw_Preference__c>> contractDrawPreferencesMap = ContractRelatedRecordQueryUtil.getDrawPreferencesMap(pLendingContractIdSet);
        
        /*
        if (pLendingContractIdSet == null || (pLendingContractIdSet != null && pLendingContractIdSet.size() == 0)){
          return contractDrawPreferencesMap;
        }
        for (Id contractId : pLendingContractIdSet){
            contractDrawPreferencesMap.put(contractId, new List<Contract_Draw_Preference__c>());
        }
        
        List<Contract_Draw_Preference__c> contractDrawList = [SELECT Id, Name
                                                                  , Draw_Date__c
                                                                  , Draw_Amount__c
                                                                  , Lending_Contract_Number__c
                                                               FROM Contract_Draw_Preference__c
                                                              WHERE Lending_Contract_Number__c IN :pLendingContractIdSet
                                                              ORDER BY Lending_Contract_Number__c, Draw_Date__c];
        
        logmessage('contractDrawList '+contractDrawList.size());
        for(Contract_Draw_Preference__c contractDraw : contractDrawList) {
            if (contractDrawPreferencesMap.containsKey(contractDraw.Lending_Contract_Number__c)){
                contractDrawPreferencesMap.get(contractDraw.Lending_Contract_Number__c).add(contractDraw);
            }
        }

        logmessage('Map Size :'+contractDrawPreferencesMap.size());
        */
        Logger.exit(CLASS_NAME, 'contractDrawPreferencesMap');
        return contractDrawPreferencesMap;
    }    
    
    public static Map<Id, List<Contract_Repayment__c>> getContractRepaymentMap(Set<Id> pLendingContractIdSet) {
        Logger.enter(CLASS_NAME, 'getContractRepaymentMap');
        Map<Id, List<Contract_Repayment__c>> contractRepaymentMap = new Map<Id, List<Contract_Repayment__c>>();
        if (pLendingContractIdSet == null || (pLendingContractIdSet != null && pLendingContractIdSet.size() == 0)){
          logmessage(' RETURNING NULL FOR CONTRACT REPAYMENTS');
          return contractRepaymentMap;
        }
        logmessage('CONTRACT REPAYMENTS FOUND SO NOT RETURNING NULL');
        for (Id contractId : pLendingContractIdSet){
            contractRepaymentMap.put(contractId, new List<Contract_Repayment__c>());
        }
        
        List<Contract_Repayment__c> contractRepaymentList = [SELECT Id, Name
                                                                  , Is_Active__c
                                                                  , Lending_Contract_Number__c
                                                                  , Due_Amount__c
                                                                  , Due_Date__c
                                                                  , Interest_Due_Amount__c
                                                                  , Opening_Balance_Amount__c
                                                                  , Payment_Number__c
                                                                  , Periodic_Fee_Due_Amount__c
                                                                  , Principal_Due_Amount__c
                                                                  , Closing_Balance_Amount__c
                                                                  , Transaction_Posting_Set_Key__c
                                                               FROM Contract_Repayment__c
                                                              WHERE Lending_Contract_Number__c IN :pLendingContractIdSet
                                                                AND Is_Active__c = true
                                                                 // TODO - DO WE NEED ANOTHER CONDITION OF SAY DUE DATE OR ANYTHING?
                                                                 // WE CAN'T JUST PICK UNSATISFIED AS PAYMENT TXN MAY BE REVERSED
                                                                 // BUT CAN WE RESTRICT FUTURE DATES, ATLEAST??
                                                                 // WE MIGHT NEED FUTURE DATES FOR - FUTURE PMT ALLOCATIONS
                                                              ORDER BY Lending_Contract_Number__c, Payment_Number__c, Due_Date__c];
        
        logmessage('contractRepaymentList '+contractRepaymentList.size());
        for(Contract_Repayment__c contractRepay : contractRepaymentList) {
                //logmessage('contractRepay.Lending_Contract_Number__c ==>'+contractRepay.Lending_Contract_Number__c);
            if (contractRepaymentMap.containsKey(contractRepay.Lending_Contract_Number__c)){
                contractRepaymentMap.get(contractRepay.Lending_Contract_Number__c).add(contractRepay);
            }
        }

        logmessage('Map Size :'+contractRepaymentMap.size());
        Logger.exit(CLASS_NAME, 'getContractRepaymentMap');
        return contractRepaymentMap;
    }

    public static Map<Id, List<Contract_Due__c>> getContractDueMap(Set<Id> pLendingContractIdSet) {
        Logger.enter(CLASS_NAME, 'getContractDueMap');
        Map<Id, List<Contract_Due__c>> contractDueMap = ContractRelatedRecordQueryUtil.getDuesMap(pLendingContractIdSet, new Set<String>(), true);
        
        /*
        if (pLendingContractIdSet == null || (pLendingContractIdSet != null && pLendingContractIdSet.size() == 0)){
          logmessage(' RETURNING NULL FOR CONTRACT DUES');
          return contractDueMap;
        }
        logmessage('CONTRACT DUES FOUND SO NOT RETURNING NULL');
        for (Id contractId : pLendingContractIdSet){
            contractDueMap.put(contractId, new List<Contract_Due__c>());
        }
        
        List<Contract_Due__c> contractDueList = [SELECT Id
                                                      , Name
                                                      , Is_Active__c
                                                      , Balance_Amount__c
                                                      , Is_Delinquency_Fulfilled__c
                                                      , Delinquency_Fulfillment_Date__c
                                                      , Due_Amount__c
                                                      , Due_Amount_Collected__c
                                                      , Due_Date__c
                                                      , Transaction_Date__c
                                                      , Due_Fulfillment_Date__c
                                                      , Is_Due_Fulfilled__c
                                                      , Lending_Contract_Number__c
                                                      , Transaction_Posting_Set_Key__c
                                                      , Delinquency_Amount_Collected__c
                                                      , Delinquency_Category__c
                                                   FROM Contract_Due__c
                                                  WHERE Lending_Contract_Number__c IN :pLendingContractIdSet
                                                    AND Is_Active__c = true
                                                  ORDER BY Lending_Contract_Number__c,Due_Date__c];
        
        logmessage('contractDueList '+contractDueList.size());
        for(Contract_Due__c contractDue : contractDueList) {
                //logmessage('contractDue.Lending_Contract_Number__c ==>'+contractDue.Lending_Contract_Number__c);
            if (contractDueMap.containsKey(contractDue.Lending_Contract_Number__c)){
                contractDueMap.get(contractDue.Lending_Contract_Number__c).add(contractDue);
            }
        }
        */
        Logger.exit(CLASS_NAME, 'getContractDueMap');
        return contractDueMap;
    }

    public static Map<Id, List<Contract_Stage__c>> getContractStageMap(Set<Id> pLendingContractIdSet) {
        Logger.enter(CLASS_NAME, 'getContractStageMap');
        Map<Id, List<Contract_Stage__c>> contractStageMap = ContractRelatedRecordQueryUtil.getStagesMap(pLendingContractIdSet, true);
        
        /*
        if (pLendingContractIdSet == null || (pLendingContractIdSet != null && pLendingContractIdSet.size() == 0)) return contractStageMap;
        
        for (Id contractId : pLendingContractIdSet){
            contractStageMap.put(contractId, new List<Contract_Stage__c>());
        }

        List<Contract_Stage__c> contractStageList = [SELECT Id, Name
                                                          , Lending_Contract_Number__c
                                                          , Stage_Name__c
                                                          , Stage_Name_Formula__c
                                                       FROM Contract_Stage__c
                                                      WHERE Lending_Contract_Number__c IN :pLendingContractIdSet
                                                        AND Is_Active__c = true
                                                   ORDER BY Lending_Contract_Number__c];
        
        for(Contract_Stage__c contractStage : contractStageList) {
            if (contractStageMap.containsKey(contractStage.Lending_Contract_Number__c)){
                contractStageMap.get(contractStage.Lending_Contract_Number__c).add(contractStage);
            }
        }
        */
        Logger.exit(CLASS_NAME, 'getContractStageMap');
        return contractStageMap;
    }
  
    public static List<Lending_Contract__c> getLendingContractList(Set<Id> pLendingContractIdSet) {
        Logger.enter(CLASS_NAME, 'getLendingContractList');
        logMessage('--- Input set size : ' + pLendingContractIdSet.size());

        fsCore.DynamicQueryBuilder contractQuery = fsCore.DynamicQueryFactory.createQuery(Schema.SObjectType.Lending_Contract__c.getName());
        contractQuery.addFields();
        contractQuery.addWhereConditionWithBind(1,'Id','IN', 'pLendingContractIdSet');
        
        String queryString = contractQuery.getQueryString();
        queryString += ' FOR UPDATE ';  //ADAGUR ADDED TO HANDLE CONCURRENCY'
        
        List<Lending_Contract__c> contractList = (List<Lending_Contract__c>)Database.query(contractQuery.getQueryString());

        logMessage('--- contract list size : ' + contractList.size());
        Logger.exit(CLASS_NAME, 'getLendingContractList');
        return contractList;
    }
    
    private static void logMessage(String pMessage) {
        //Logger.logMessage(pMessage);
        System.debug(Logginglevel.ERROR, pMessage);
    }    
}
