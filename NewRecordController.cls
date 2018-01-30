public with sharing class ContractNewTransactionController extends TransactionEditControllerBase{
    private static final String CLASS_NAME = 'ContractNewTransactionController';
    
    public List<SelectOption> mAvailableTxnList {get; private set;}
   
    public String mSelectedTxnCode {get; set;}
    public Boolean mIsSetAsFavoriteTxn {get; set;}
    
    private fsCore__User_Preferences__c mUserPref;
    private Lending_Contract__c mContract;
     
    public ContractNewTransactionController(ApexPages.StandardController pStdController){
        super();
        mContract = (Lending_Contract__c)pStdController.getRecord();
        init();
    }
   
    private void init(){
        if (mContract.Id == null){
            throw new ServicingException(Label.fscore.Edit_Page_For_New_Record_Exception);
        }
        setLendingContract(mContract.Id);
        mContract = getLendingContract();
        
        setPageTitle(mContract.Name);
        setPageSubtitle(Label.New_Contract_Transaction_Record_Title);

        mIsSetAsFavoriteTxn = false;
        mSelectedTxnCode = Constants.BLANK_STRING;
   
        mAvailableTxnList = fscore.SpectraCoreUtil.getBlankList();
        mUserPref = fsCore__User_Preferences__c.getInstance(UserInfo.getUserId());
        
        if (mUserPref.Id != null && String.IsNotBlank(mUserPref.Favorite_Transaction_Code__c)){
            mSelectedTxnCode = mUserPref.Favorite_Transaction_Code__c;
        }

        prepareAvailableTxnList();
    }
   
    private void prepareAvailableTxnList(){
        setAllTransactionCategories();
        setAvailableTransactions();
        
        //populate list of available transactions
        if (getAvailableTransactions().size() > 0){
            mAvailableTxnList = new List<SelectOption>();
            mAvailableTxnList.add(new SelectOption(Constants.BLANK_STRING, Label.List_Option_Select_Transaction));
    
            for (TransactionSetupObject txnSetupObj : getAvailableTransactions().values()){
                mAvailableTxnList.add(new SelectOption(txnSetupObj.mTransactionCode, txnSetupObj.mTransactionName));
            }
        }
        
        if (String.IsNotBlank(mSelectedTxnCode) && !isTransactionAccessible(mSelectedTxnCode)){
            mSelectedTxnCode = Constants.BLANK_STRING;
        }
    }
   
    public PageReference onNext(){
        if (String.IsBlank(mSelectedTxnCode)){
            addErrorToPage(Label.Transaction_Not_Selected);
            return null;
        }
        if (String.IsNotBlank(mSelectedTxnCode) && !isTransactionAccessible(mSelectedTxnCode)){
            addErrorToPage(Label.Transaction_Not_Accessible);
            return null;
        }
        
        //Save favorite transaction for the user 
        if (mIsSetAsFavoriteTxn){
            System.debug(loggingLevel.ERROR, '... Updating user preferences ...');
            mUserPref.Favorite_Transaction_Code__c = mSelectedTxnCode;
            upsert mUserPref;
        }
        
        //redirect to transaction edit page
        PageReference txnEditPage 
                    = TransactionEditPageFactory.getTransactionEditPage(getTransactionObject(mSelectedTxnCode), mContract.Id);
        txnEditPage.setRedirect(true);
        return txnEditPage;
    }

    public PageReference onCancel(){
        return getContractRecordPage();
    }    
}
