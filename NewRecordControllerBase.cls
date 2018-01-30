public with sharing virtual class TransactionEditControllerBase{
    private static final String CLASS_NAME = 'TransactionEditControllerBase';
    
    private String mPageTitle;
    private String mPageSubtitle;
    private Date   mBusinessDate;
    private Map<String, TransactionSetupObject> mAvailableTxnMap;

    public Lending_Contract__c mContract;
    private List<Contract_Stage__c> mContractStages;
    private List<Contract_Assignment__c> mContractAssignments;
    
    private Set<String> mTxnCategories;
    private Set<String> mTxnOperationTypes;

    public Map<String, RecordType> mTxnQueueRecordTypeMap;
    private User mProcessingUser;
    
    public TransactionEditControllerBase(){
        mPageTitle = Constants.BLANK_STRING;
        mPageSubtitle = Constants.BLANK_STRING;
        mBusinessDate = null;
        mAvailableTxnMap = new Map<String, TransactionSetupObject>();
        mTxnCategories = new Set<String>();
        mTxnOperationTypes = new Set<String>();
        mContractStages = new List<Contract_Stage__c>();
        mContractAssignments = new List<Contract_Assignment__c>();
        mTxnQueueRecordTypeMap = fsCore.RecordTypeUtil.getInstance().getRecordTypeMapByName(
                                        Schema.SObjectType.Transaction_Processing_Queue__c.getName());
        setProcessingUser(UserInfo.getUserId());
    }

    public virtual void setPageTitle(String pPageTitle){
        mPageTitle = pPageTitle;
    }
    public String getPageTitle(){
        return mPageTitle;
    }

    public virtual void setPageSubtitle(String pPageSubtitle){
        mPageSubtitle = pPageSubtitle;
    }
    public String getPageSubtitle(){
        return mPageSubtitle;
    }

    protected void setProcessingUser(Id pUserId){
        mProcessingUser = [SELECT Id, ProfileId FROM User WHERE Id = :pUserId];
    }
    protected User getProcessingUser(){
        return mProcessingUser;
    }
    
    protected void setLendingContract(Lending_Contract__c pContract){
        mContract = pContract;
    }

    protected void setLendingContract(Id pContractId){
        mContract = [SELECT Id, Name
                          , Contract_Status__c
                          , Product_Family__c
                          , Branch_Code__c
                       FROM Lending_Contract__c 
                      WHERE Id = :pContractId];

        setContractStages(mContract.Id);
        setContractAssignments(mContract.Id);
        setBusinessDate(mContract.Branch_Code__c);
    }

    protected void setContractStages(Id pContractId){
        mContractStages = [SELECT Id, Stage_Name__c
                                , Stage_Name_Formula__c
                             FROM Contract_Stage__c
                            WHERE Lending_Contract_Number__c = :pContractId
                              AND Is_Active__c = true
                            ORDER BY Entry_Date_Time__c ASC];
    }

    protected void setContractAssignments(Id pContractId){
        mContractAssignments = [SELECT Id, Assignment_Name__c
                                     , Assignment_Name_Formula__c
                                  FROM Contract_Assignment__c
                                 WHERE Lending_Contract_Number__c = :pContractId
                                   AND Is_Active__c = true
                                 ORDER BY Assigned_On__c ASC];
    }

    public Lending_Contract__c getLendingContract(){
        return mContract;
    }

    protected void setBusinessDate(String pBranchCode){
        mBusinessDate = fsCore.SpectraCoreUtil.getBusinessDate(pBranchCode);
    }
    protected Date getBusinessDate(){
        if (mBusinessDate == null){ setBusinessDate(mContract.Branch_Code__c); }
        return mBusinessDate;
    }
    
    public void setTransactionCategory(String pTxnCategory){
        mTxnCategories.add(pTxnCategory);
    }

    public void setAllTransactionCategories(){
        mTxnCategories.add(Constants.TRANSACTION_CATEGORY_CONTRACT_STATUS);
        mTxnCategories.add(Constants.TRANSACTION_CATEGORY_PAYMENT);
        mTxnCategories.add(Constants.TRANSACTION_CATEGORY_RESTRUCTURE);
        mTxnCategories.add(Constants.TRANSACTION_CATEGORY_FEE);
        
        //SSingh : To Be uncommented when supported
        //mTxnCategories.add(Constants.TRANSACTION_CATEGORY_CUSTOMER_STATEMENT);
        //mTxnCategories.add(Constants.TRANSACTION_CATEGORY_EXPENSE);
        //mTxnCategories.add(Constants.TRANSACTION_CATEGORY_INTEREST_ACCRUAL);
        //mTxnCategories.add(Constants.TRANSACTION_CATEGORY_INTEREST_REBATE);
        //mTxnCategories.add(Constants.TRANSACTION_CATEGORY_REFUND);
    }
    
    protected void setAvailableTransactions(){
        //prepare transaction access control object
        TransactionAccessControlObject txnAccessControl = new TransactionAccessControlObject();
        txnAccessControl.mUserId = UserInfo.getUserId();
        txnAccessControl.mProfileId = UserInfo.getProfileId();
        txnAccessControl.mStatus = mContract.Contract_Status__c;
        txnAccessControl.mStageMap = new Map<Id, String>();
        txnAccessControl.mAssignmentMap = new Map<Id, String>();

        if(mContractStages != null && !mContractStages.isEmpty()) {
            for(Contract_Stage__c contractStage : mContractStages) {
                txnAccessControl.mStageMap.put(contractStage.Stage_Name__c, contractStage.Stage_Name_Formula__c);
            }
        }
        
        if(mContractAssignments != null && !mContractAssignments.isEmpty()) {
            for(Contract_Assignment__c contractAssgn : mContractAssignments) {
                txnAccessControl.mAssignmentMap.put(contractAssgn.Assignment_Name__c, contractAssgn.Assignment_Name_Formula__c);
            }
        }    
        
        //get all manual transactions for servicing
        Map<String, TransactionSetupObject> manualTransactionMap = getManualTransactionSetupMap();
       
        //populate list of available transactions
        for (TransactionSetupObject txnSetupObj : manualTransactionMap.values()){
            txnAccessControl.mTransactionSetup = txnSetupObj;
            Boolean isAccessGranted = TransactionAccessControlManager.isTransactionAccessGranted(txnAccessControl);
            
            if (isAccessGranted && txnSetupObj.mProductFamily.containsIgnoreCase(mContract.Product_Family__c)){
                mAvailableTxnMap.put(txnSetupObj.mTransactionCode, txnSetupObj);
            }
        }
    }
    
    private Map<String, TransactionSetupObject> getManualTransactionSetupMap() {
        Logger.enter(CLASS_NAME, 'getManualTransactionSetupMap');
        
        mTxnOperationTypes = new Set<String>();
        mTxnOperationTypes.add(Constants.TRANSACTION_OPERATION_TYPE_POST);
        mTxnOperationTypes.add(Constants.TRANSACTION_OPERATION_TYPE_ADJPLUS);
        mTxnOperationTypes.add(Constants.TRANSACTION_OPERATION_TYPE_ADJMINUS);
        mTxnOperationTypes.add(Constants.TRANSACTION_OPERATION_TYPE_CHARGEOFF);
        mTxnOperationTypes.add(Constants.TRANSACTION_OPERATION_TYPE_WRITEOFF);
        
        List<fsCore__Transaction_Setup__c> transactionSetupList = 
                                [SELECT Id, Name
                                      , fsCore__Balance_Name__c
                                      , fsCore__Balance_Name__r.fsCore__Balance_Family__c
                                      , fsCore__Reverse_Transaction_Name__c
                                      , fsCore__Waive_Transaction_Name__c
                                      , fsCore__Is_Batch_Only__c
                                      , fsCore__Is_Loan__c
                                      , fsCore__Is_Line__c
                                      , fsCore__Is_Lease__c
                                      , fsCore__Product_Family__c
                                      , fsCore__Is_Manual_Posting_Allowed__c
                                      , fsCore__Operation_Type__c
                                      , fsCore__Is_Approval_Required__c
                                      , fsCore__Is_Preview_Required__c
                                      , fsCore__Transaction_Category__c
                                      , fsCore__Transaction_Code__c
                                      , fsCore__Transaction_Family__c
                                      , fsCore__Custom_Class_Name__c
                                      //, fsCore__Custom_Page_Name__c
                                      , fsCore__Is_Financial_Transaction__c
                                      , fsCore__Is_General_Ledger_Required__c
                                      , fsCore__Is_Statement_Eligible__c
                                      , fsCore__Process_Transaction_As__c
                                      , fsCore__Is_Posting_Suspension_Allowed__c
                                      , fsCore__Is_Default_Posting_Allowed_For_Profile__c
                                      , fsCore__Is_Default_Posting_Allowed_For_Queue__c
                                      , fsCore__Is_Default_Posting_Allowed_For_Stage__c
                                      , fsCore__Is_Default_Posting_Allowed_For_Status__c
                                      , fsCore__Is_Default_Posting_Allowed_For_User__c
                                      , fsCore__Dependent_Transaction_Count__c
                                      , (SELECT Id, Name
                                              , fsCore__Is_Required__c
                                              , fsCore__Field_Name__c
                                              , fsCore__Transaction_Parameter_Field_ID__c
                                              , fsCore__Display_Order__c
                                           FROM fsCore__Transaction_Parameter_Setup__r
                                          WHERE fsCore__Is_Active__c = true
                                          ORDER BY fsCore__Display_Order__c)
                                      , (SELECT Id, Name
                                              , fsCore__Is_Posting_Allowed__c
                                              , fsCore__Controlling_Entity__c
                                              , fsCore__Queue_Assignment_Name__c
                                              , fsCore__User__c
                                              , fsCore__Contract_Status__c
                                              , fsCore__Stage_Name__c
                                              , fsCore__Profile_Id__c
                                              , fsCore__Profile_Name__c
                                              , fsCore__Controlling_Value__c
                                              , fsCore__Is_Processing_Suspended__c
                                              , fsCore__Suspend_Processing_Action__c
                                           FROM fsCore__Transaction_Validation_Setup__r
                                          WHERE fsCore__Is_Active__c = true)
                                   FROM fsCore__Transaction_Setup__c
                                  WHERE fsCore__Transaction_Family__c = :fsCore.Constants.TXN_FAMILY_SERVICING
                                    AND fsCore__Transaction_Category__c IN :mTxnCategories
                                    AND fsCore__Operation_Type__c IN :mTxnOperationTypes
                                    AND fsCore__Is_Active__c = true
                                    AND fsCore__Is_Manual_Posting_Allowed__c = true
                                    AND fsCore__Is_Batch_Only__c = false
                                  ORDER BY Name ASC];

        Map<String, TransactionSetupObject> transactionSetupMap = new Map<String, TransactionSetupObject>();
        for(fsCore__Transaction_Setup__c txnSetup : transactionSetupList) {
            TransactionSetupObject txnSetupObject
                                = TransactionSetupObject.getInstance(
                                        txnSetup
                                      , txnSetup.fsCore__Transaction_Parameter_Setup__r
                                      , txnSetup.fsCore__Transaction_Validation_Setup__r);

            transactionSetupMap.put(txnSetup.fsCore__Transaction_Code__c, txnSetupObject);
        }
        Logger.exit(CLASS_NAME, 'getManualTransactionSetupMap');
        return transactionSetupMap;
    }

    protected Boolean isTransactionAccessible(String pTxnCode){
        return (mAvailableTxnMap.containsKey(pTxnCode));
    }

    protected Map<String, TransactionSetupObject> getAvailableTransactions(){
        return mAvailableTxnMap;
    }

    protected TransactionSetupObject getTransactionObject(String pTxnCode){
        return mAvailableTxnMap.get(pTxnCode);
    }
    
    public virtual Boolean isTransactionValid(Transaction_Processing_Queue__c pTransaction
                                            , List<QueuedTransactionParamObject> pTxnParamObjectList){
        Boolean isValid = true;
        if (pTransaction.Transaction_Date__c == null){
            isValid = false;
            addErrorToPage(Label.Transaction_Processing_Date_Blank);
        }
        
        if (pTransaction.Processing_User__c == null){
            isValid = false;
            addErrorToPage(Label.Transaction_Processing_User_Blank);
        }

        for(QueuedTransactionParamObject txnParamObj : pTxnParamObjectList){
            if(QueuedTransactionParamUtil.isRequiredParamBlank(txnParamObj)){
                isValid = false;
                addErrorToPage(String.format(Label.Transaction_Processing_Required_Parameter_Blank, new String[]{txnParamObj.getTxnParam().Name}));
            }
        }
        
        return isValid;
    }

    public virtual Boolean saveTransaction(Transaction_Processing_Queue__c pTransaction
                                         , List<QueuedTransactionParamObject> pTxnParamObjectList
                                         , String pTxnQueueStatus){
        if (!isTransactionValid(pTransaction, pTxnParamObjectList)){
            return false;
        }
        
        pTransaction.Processing_Status__c = pTxnQueueStatus;
        pTransaction.Processing_Result__c = Constants.BLANK_STRING;

        fsCore.DMLResult txnQueueSaveRslt = QueuedTransactionDMLWrapper.getInstance().upsertData(new List<Transaction_Processing_Queue__c>{pTransaction});
        if (txnQueueSaveRslt.hasErrors()){
            addErrorsToPage(txnQueueSaveRslt.getErrorList());
            return false;
        }
        
        List<Transaction_Processing_Parameter__c> queuedTxnParamList = new List<Transaction_Processing_Parameter__c>();
        for(QueuedTransactionParamObject txnParamObj : pTxnParamObjectList){
            Transaction_Processing_Parameter__c txnParam = txnParamObj.getTxnParam();
            if (txnParam.Transaction_Queue_Name__c == null){
                txnParam.Transaction_Queue_Name__c = pTransaction.Id;
            }
            queuedTxnParamList.add(txnParam);
        }                 

        fsCore.DMLResult txnParamSaveRslt = QueuedTransactionParamDMLWrapper.getInstance().upsertData(queuedTxnParamList);
        if (txnParamSaveRslt.hasErrors()){
            addErrorsToPage(txnParamSaveRslt.getErrorList());
            return false;
        }
        
        return true;
    }

    public virtual Boolean postTransaction(Id pTransactionId){
        TransactionProcessingObjectBuilder tpObject = new TransactionProcessingObjectBuilder();
        tpObject.addQueuedTransaction(pTransactionId);
        tpObject.build();
        
        List<TransactionProcessingObject> tpResultObj = TransactionProcessingGateway.processTransactions(tpObject.getTransactionProcessingObjectList(), false);

        if (!tpResultObj.get(0).mIsSuccess){
            for(String errMsg : tpResultObj.get(0).mErrorStack){
                addErrorToPage(errMsg);
            }
            return false;
        }
        return true;
    }

    public void addErrorToPage(String pErrorMessage){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, pErrorMessage));
    }

    public void addErrorsToPage(List<fsCore.ErrorObject> pErrorList){
        for (fsCore.ErrorObject errObj : pErrorList){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errObj.getErrorMessage()));
        }
    }

    protected PageReference getNewTransactionPage(){
        PageReference newTxnPage = new PageReference('/apex/fsserv__contractnewtxnpage');
        newTxnPage.setRedirect(true);
        return newTxnPage;
    }

    protected PageReference getContractRecordPage(){
        PageReference contractPage = new PageReference('/' + String.valueOf(mContract.Id));
        contractPage.setRedirect(true);
        return contractPage;
    }

    protected PageReference getRecordPage(Id pRecordId){
        PageReference recordPage = new PageReference('/' + String.valueOf(pRecordId));
        recordPage.setRedirect(true);
        return recordPage;
    }

}
