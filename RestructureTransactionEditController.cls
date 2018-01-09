
public with sharing class RestructureTransactionEditController extends TransactionEditControllerBase{
    private static final String CLASS_NAME = 'RestructureTransactionEditController';
    
    public Transaction_Processing_Queue__c mRestructureTxn {get; set;}
    public List<QueuedTransactionParamObject> mTxnParamObjectList {get; set;}
    
    private TransactionSetupObject mTxnSetupObject;
    private Boolean mIsRedirect;
    private PageReference mRedirectPage;
    
    public Boolean mIsPreviewed {get; private set;}
    public List<RestructuredField> mRestructureResult {get; private set;}
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
        
        mRestructureResult = new List<RestructuredField>();
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
            Lending_Contract__c restructuredContract = tpResultObj.get(0).mProcessingResultDataObject.mLendingContractMap.get(tpObject.mLendingContractId);
            populateRestructureResult(getLendingContract(), restructuredContract);
            
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

    private void populateRestructureResult(Lending_Contract__c pCurrContract, Lending_Contract__c pNewContract){
        mRestructureResult = new List<RestructuredField>();
        
        mRestructureResult.add(new RestructuredField(Lending_Contract__c.Next_Payment_Due_Date__c.getDescribe().getLabel()
                                                   , dateToString(pCurrContract.Next_Payment_Due_Date__c)
                                                   , dateToString(pNewContract.Next_Payment_Due_Date__c)));
        mRestructureResult.add(new RestructuredField(Lending_Contract__c.Term__c.getDescribe().getLabel()
                                                   , String.valueOf(pCurrContract.Current_Term__c)
                                                   , String.valueOf(pNewContract.Current_Term__c)));
        mRestructureResult.add(new RestructuredField(Lending_Contract__c.Remaining_Term__c.getDescribe().getLabel()
                                                   , String.valueOf((pCurrContract.Current_Term__c - pCurrContract.Paid_Term__c))
                                                   , String.valueOf((pNewContract.Current_Term__c - pCurrContract.Paid_Term__c))));
        mRestructureResult.add(new RestructuredField(Lending_Contract__c.Payment_Frequency__c.getDescribe().getLabel()
                                                   , String.valueOf(pCurrContract.Current_Payment_Frequency__c)
                                                   , String.valueOf(pNewContract.Current_Payment_Frequency__c)));
        mRestructureResult.add(new RestructuredField(Lending_Contract__c.Maturity_Date__c.getDescribe().getLabel()
                                                   , dateToString(pCurrContract.Current_Maturity_Date__c)
                                                   , dateToString(pNewContract.Current_Maturity_Date__c)));
        mRestructureResult.add(new RestructuredField(Lending_Contract__c.Payment_Due_Day__c.getDescribe().getLabel()
                                                   , String.valueOf(pCurrContract.Current_Payment_Due_Day__c)
                                                   , String.valueOf(pNewContract.Current_Payment_Due_Day__c)));
        mRestructureResult.add(new RestructuredField(Lending_Contract__c.Rate__c.getDescribe().getLabel()
                                                   , String.valueOf(pCurrContract.Current_Rate__c)
                                                   , String.valueOf(pNewContract.Current_Rate__c)));
        mRestructureResult.add(new RestructuredField(Lending_Contract__c.Payment_Amount__c.getDescribe().getLabel()
                                                   , String.valueOf(pCurrContract.Current_Payment_Amount__c)
                                                   , String.valueOf(pNewContract.Current_Payment_Amount__c)));
        mRestructureResult.add(new RestructuredField(Lending_Contract__c.Final_Payment_Amount__c.getDescribe().getLabel()
                                                   , String.valueOf(pCurrContract.Final_Payment_Amount__c)
                                                   , String.valueOf(pNewContract.Final_Payment_Amount__c)));
        mRestructureResult.add(new RestructuredField(Lending_Contract__c.Total_Interest_Amount__c.getDescribe().getLabel()
                                                   , String.valueOf(pCurrContract.Total_Interest_Amount__c)
                                                   , String.valueOf(pNewContract.Total_Interest_Amount__c)));
    }
    
    private String dateToString(Date pDate){
        String dateStr = String.valueOf(pDate.day()) + '-' + fsCore.DateUtilGlobal.getMonthShortName(pDate.month()) + '-' + String.valueOf(pDate.year());
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
    
    public class RestructuredField{
        public String mFieldName  {get; set;}
        public String mOldValue   {get; set;}
        public String mNewValue   {get; set;}
        
        public RestructuredField(String pFieldName, String pOldValue, String pNewValue){
            mFieldName = pFieldName;
            mOldValue = pOldValue;
            mNewValue = pNewValue;
        }
    }
}
