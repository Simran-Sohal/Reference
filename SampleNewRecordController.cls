public with sharing class QueuedTransactionEditController extends TransactionEditControllerBase{
    private static final String CLASS_NAME = 'QueuedTransactionEditController';

    public Transaction_Processing_Queue__c mTransaction {get; set;}
    public List<QueuedTransactionParamObject> mTxnParamObjectList {get; set;}
    
    private TransactionSetupObject mTxnSetupObject;
    
    private String  mTxnCode;
    private Boolean mIsRedirect;
    private PageReference mRedirectPage;

    public QueuedTransactionEditController(ApexPages.StandardController pStdController){
        super();
        mTransaction = (Transaction_Processing_Queue__c)pStdController.getRecord();
        init();
    }

    private void init(){
        if (mTransaction.Id != null){
            mTransaction = (Transaction_Processing_Queue__c) fsCore.SObjectQueryUtil.getSObjectRecord(mTransaction.Id);
            setTransactionCategory(mTransaction.Transaction_Category__c);
            setPageSubtitle(Transaction_Processing_Queue__c.Name.getDescribe().getLabel() + mTransaction.Name);
        } else {
            setAllTransactionCategories();
            setPageSubtitle(Label.New_Contract_Transaction_Record_Title);
        }

        mTxnParamObjectList = new List<QueuedTransactionParamObject>();
        mTxnCode = Constants.BLANK_STRING;
        mIsRedirect = false;
        
        Map<String,String> pageURLParamMap = ApexPages.currentPage().getParameters();
        //get contract Id
        Id contractId = null;
        if (pageURLParamMap.containsKey('parentId')){
            contractId = Id.valueOf(pageURLParamMap.get('parentId'));
        }
        else if (mTransaction.Lending_Contract_Number__c != null){
            contractId = mTransaction.Lending_Contract_Number__c;
        } 
        else {
            throw new ServicingException(Label.Parent_Contract_Id_Missing);
        }
        
        //get transaction code
        if (pageURLParamMap.containsKey('txnCode')){
            mTxnCode = pageURLParamMap.get('txnCode');
        } 
        else if (mTransaction.Id != null && String.IsNotBlank(mTransaction.Transaction_Code__c)){
            mTxnCode = mTransaction.Transaction_Code__c;
        }
        
        //redirect to select transaction screen if transaction code is not found
        if (String.IsBlank(mTxnCode)) {
            mIsRedirect = true;
            mRedirectPage = getNewTransactionPage();
            mRedirectPage.getParameters().put('Id', contractId);
        }
        else {
            setLendingContract(contractId);
            setPageTitle(getLendingContract().Name);
            setAvailableTransactions();
                
            if (!isTransactionAccessible(mTxnCode)){
                throw new ServicingException(Label.Transaction_Not_Accessible);
            }

            mTxnSetupObject = getTransactionObject(mTxnCode);

            if (!TransactionEditPageFactory.hasDefaultEditPage(mTxnSetupObject)){
                mIsRedirect = true;
                mRedirectPage = TransactionEditPageFactory.getTransactionEditPage(mTxnSetupObject, contractId, mTransaction.Id);
            }
            else {
                //cannot edit processed transactions
                if (mTransaction.RecordTypeId == mTxnQueueRecordTypeMap.get(Constants.RECORD_TYPE_PROCESSED).Id){
                    throw new ServicingException(Label.Processed_Txn_Edit_Not_Allowed);
                }
    
                setTransactionDetails();
            }
        }
    }
    
    public PageReference onLoad(){
        if (mIsRedirect && mRedirectPage != null){
            mRedirectPage.setRedirect(true);
            return mRedirectPage;
        }
        return null;
    }
    
    private void setTransactionDetails(){
        if (mTransaction.Id == null){
            mTransaction = new Transaction_Processing_Queue__c();
            mTransaction.RecordTypeId = mTxnQueueRecordTypeMap.get(Constants.RECORD_TYPE_OPEN).Id;
            mTransaction.Lending_Contract_Number__c = getLendingContract().Id;
            mTransaction.Transaction_Date__c = getBusinessDate();
            mTransaction.Transaction_Name__c = mTxnSetupObject.mTransactionId;
            mTransaction.Transaction_Operation_Type__c = mTxnSetupObject.mOperationType;
            mTransaction.Processing_User__c = UserInfo.getUserId();
        }
        
        mTxnParamObjectList = QueuedTransactionParamUtil.getParameterObjectList(mTransaction, mTxnSetupObject);
    }

    public PageReference onSaveAsDraft(){
        Savepoint sp = Database.setSavepoint();
        Boolean isSuccess = saveTransaction(mTransaction, mTxnParamObjectList, Constants.TRANSACTION_QUEUE_STATUS_DRAFT);
        if (!isSuccess){
            Database.rollback(sp);
            return null;
        }

        return getRecordPage(mTransaction.Id);
    }
    
    public PageReference onPostTxn(){
        Savepoint sp = Database.setSavepoint();
        Boolean isSuccess = saveTransaction(mTransaction, mTxnParamObjectList, Constants.TRANSACTION_QUEUE_STATUS_READY);
        if (isSuccess && mTransaction.Id != null){
            isSuccess = postTransaction(mTransaction.Id);
        }

        if (!isSuccess){
            Database.rollback(sp);
            return null;
        }

        return getContractRecordPage();
    }
    
    public PageReference onQueueTxn(){
        Savepoint sp = Database.setSavepoint();
        Boolean isSuccess = saveTransaction(mTransaction, mTxnParamObjectList, Constants.TRANSACTION_QUEUE_STATUS_READY);
        if (!isSuccess){
            Database.rollback(sp);
            return null;
        }
        
        return getRecordPage(mTransaction.Id);
    }
    
    public PageReference onCancel(){
        return (mTransaction.Id == null ? getContractRecordPage() : getRecordPage(mTransaction.Id));
    }
    
}
