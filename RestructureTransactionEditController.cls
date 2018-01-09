
public with sharing class RestructureTransactionEditController extends TransactionEditControllerBase{
    private static final String CLASS_NAME = 'RestructureTransactionEditController';
    
    public Transaction_Processing_Queue__c mRestructureTxn {get; set;}
    public List<QueuedTransactionParamObject> mTxnParamObjectList {get; set;}
    
    private TransactionSetupObject mTxnSetupObject;
    private Boolean mIsRedirect;
    private PageReference mRedirectPage;
    
    public Boolean mIsPreviewed {get; private set;}
    
    public Lending_Contract__c mRestructuredContract {get; private set;}
    public List<Contract_Repayment__c> mRestructuredRepayments {get; private set;}
    
    public RestructureTransactionEditController(ApexPages.StandardController pStdController){
        super();
        mRestructureTxn = (Transaction_Processing_Queue__c)pStdController.getRecord();
        init();
    }
    
    private void init(){
        if (mRestructureTxn.Id != null){
            mRestructureTxn = (Transaction_Processing_Queue__c) fsCore.SObjectQueryUtil.getSObjectRecord(mRestructureTxn.Id);
        }
        
        Map<String,String> pageURLParamMap = ApexPages.currentPage().getParameters();
        mTxnParamObjectList = new List<QueuedTransactionParamObject>();
        mIsRedirect = false;
        mIsPreviewed = false;
        
        mRestructuredContract = new Lending_Contract__c();
        mRestructuredRepayments = new List<Contract_Repayment__c>();
        
        //get contract Id
        Id contractId = null;
        if (pageURLParamMap.containsKey('parentId')){
            contractId = Id.valueOf(pageURLParamMap.get('parentId'));
        }
        else if (mRestructureTxn.Lending_Contract_Number__c != null){
            contractId = mRestructureTxn.Lending_Contract_Number__c;
        } 
        else {
            throw new ServicingException(Label.Parent_Contract_Id_Missing);
        }

        setLendingContract(LendingContractUtil.getLendingContract(contractId));
        setContractStages(getLendingContract().Id);
        setContractAssignments(getLendingContract().Id);
        setBusinessDate(getLendingContract().Branch_Code__c);
        setPageTitle(getLendingContract().Name);
        
        //get transaction code
        String txnCode = Constants.BLANK_STRING;
        if (pageURLParamMap.containsKey('txnCode')){
            txnCode = pageURLParamMap.get('txnCode');
        } 
        else if (mRestructureTxn.Id != null && String.IsNotBlank(mRestructureTxn.Transaction_Code__c)){
            txnCode = mRestructureTxn.Transaction_Code__c;
        }
        
        //redirect to select transaction screen if transaction code is not found
        if (String.IsBlank(txnCode)) {
            mIsRedirect = true;
            mRedirectPage = getNewTransactionPage();
            mRedirectPage.getParameters().put('Id', contractId);
        }
        else {
            setTransactionCategory(Constants.TRANSACTION_CATEGORY_RESTRUCTURE);
            setAvailableTransactions();
            
            if (!isTransactionAccessible(txnCode)){
                throw new ServicingException(Label.Transaction_Not_Accessible);
            }
            
            mTxnSetupObject = getTransactionObject(txnCode);

            if (mRestructureTxn.Id == null){
                setPageSubtitle(Label.Restructure_contract_title);
            } else {
                //cannot edit processed transactions
                if (mRestructureTxn.RecordTypeId == mTxnQueueRecordTypeMap.get(Constants.RECORD_TYPE_PROCESSED).Id){
                    throw new ServicingException(Label.Processed_Txn_Edit_Not_Allowed);
                }
                
                setPageSubtitle(Label.Restructure_contract_title + ' (#' + mRestructureTxn.Name + ')');
            }
            
            setRestructureTxnDetails();
        }
    }        

    public PageReference onLoad(){
        if (mIsRedirect && mRedirectPage != null){
            mRedirectPage.setRedirect(true);
            return mRedirectPage;
        }
        return null;
    }
    
    private void setRestructureTxnDetails(){
        if (mRestructureTxn.Id == null){
            mRestructureTxn = new Transaction_Processing_Queue__c();
            mRestructureTxn.Lending_Contract_Number__c = getLendingContract().Id;
            mRestructureTxn.Transaction_Date__c = getBusinessDate();
            mRestructureTxn.Transaction_Name__c = mTxnSetupObject.mTransactionId;
            mRestructureTxn.Transaction_Operation_Type__c = mTxnSetupObject.mOperationType;
            mRestructureTxn.Processing_User__c = getProcessingUser().Id;
        }
        
        mTxnParamObjectList = QueuedTransactionParamUtil.getParameterObjectList(mRestructureTxn, mTxnSetupObject);
    }
    
    public PageReference onPreview(){
        if (!isTransactionValid(mRestructureTxn, mTxnParamObjectList)){
            return null;
        }
        
        TransactionProcessingObject tpObject = new TransactionProcessingObject();
        tpObject.mTransactionQueueRecord = mRestructureTxn;
        
        tpObject.mTransactionParameterList = new List<Transaction_Processing_Parameter__c>();
        for (QueuedTransactionParamObject txnParamObj : mTxnParamObjectList){
            tpObject.mTransactionParameterList.add(txnParamObj.getTxnParam());
        }
        
        tpObject.mLendingContractId = getLendingContract().Id;
        tpObject.mLendingContractNumber = getLendingContract().Name;
        tpObject.mTransactionSetupId = mTxnSetupObject.mTransactionId;
        tpObject.mTransactionCategory = mTxnSetupObject.mTransactionCategory;
        tpObject.mTransactionDate = mRestructureTxn.Transaction_Date__c;
        tpObject.mIsRepostingTransaction = false;
        tpObject.mIsProcessingSuspended = false;
        tpObject.mIsTransactionPosting = false;
        tpObject.mProcessingUserId = getProcessingUser().Id;
        tpObject.mProcessingUserProfileId = getProcessingUser().ProfileId;
        tpObject.mBusinessDate = getBusinessDate();
        tpObject.mBranchCode = getLendingContract().Branch_Code__c;
        tpObject.mNewTransactionRecord = new Contract_Transaction__c(Lending_Contract_Number__c=getLendingContract().Id);
        
        //process restructure transaction for preview
        List<TransactionProcessingObject> tpResultObj = TransactionProcessingGateway.processTransactions(
                                                            new List<TransactionProcessingObject>{tpObject}, true);
        
        if (!tpResultObj.get(0).mIsSuccess){
            for(String errMsg : tpResultObj.get(0).mErrorStack){
                addErrorToPage(errMsg);
            }
        }
        else {
            mRestructuredContract = tpResultObj.get(0).mProcessingResultDataObject.mLendingContractMap.get(tpObject.mLendingContractId);
            List<Contract_Repayment__c> allRepayments = tpResultObj.get(0).mProcessingResultDataObject.mContractRepaymentMap.get(tpObject.mLendingContractId);
            for(Contract_Repayment__c repay : allRepayments){
                //add only new repayments to the list for display
                if (repay.Id != null){
                    mRestructuredRepayments.add(repay);
                }
            }
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Please review the processing results.'));
            mIsPreviewed = true;
        }        
        
        return null;
    }

    public PageReference onSaveAsDraft(){
        Savepoint sp = Database.setSavepoint();
        Boolean isSuccess = saveTransaction(mRestructureTxn, mTxnParamObjectList, Constants.TRANSACTION_QUEUE_STATUS_DRAFT);
        if (!isSuccess){
            Database.rollback(sp);
            return null;
        }

        return getRecordPage(mRestructureTxn.Id);
    }
    
    public PageReference onPostTxn(){
        if (!mIsPreviewed){
            addErrorToPage(Label.Transaction_Preview_Before_Save_Or_Post);
            return null;
        }

        Savepoint sp = Database.setSavepoint();
        Boolean isSuccess = saveTransaction(mRestructureTxn, mTxnParamObjectList, Constants.TRANSACTION_QUEUE_STATUS_READY);
        if (isSuccess && mRestructureTxn.Id != null){
            isSuccess = postTransaction(mRestructureTxn.Id);
        }

        if (!isSuccess){
            Database.rollback(sp);
            return null;
        }

        return getContractRecordPage();
    }
    
    public PageReference onCancel(){
        return (mRestructureTxn.Id == null ? getContractRecordPage() : getRecordPage(mRestructureTxn.Id));
    }
    
}
