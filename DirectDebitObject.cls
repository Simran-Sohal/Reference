public class DirectDebitObject{

    public Lending_Application_Direct_Debit__c mDirectDebit {get;set;}
    private Integer mUniqueKey;
    private Boolean mIsPrimary;

    private Map<Id, Lending_Application_Customer__c> mCustomerMap;
    private List<SelectOption> mCustomerSelectList;

    private Map<Id, List<Bank_Account__c>> mCustomerBankAccountsMap;

    private Map<Id, Bank_Account__c> mBankAccountMap;
    private List<SelectOption> mBankAccountSelectList;
    private Bank_Account__c mSelectedBankAccount;
    
    public LendingApplicationDirectDebitObject(Lending_Application_Direct_Debit__c pDirectDebit){
        mDirectDebit = pDirectDebit;
        mUniqueKey = null;
        mIsPrimary = false;
        mCustomerMap = new Map<Id, Lending_Application_Customer__c>();
        mCustomerBankAccountsMap = new Map<Id, List<Bank_Account__c>>();
        mBankAccountMap = new Map<Id, Bank_Account__c>();
        mSelectedBankAccount = new Bank_Account__c();

        mCustomerSelectList = SpectraCoreUtil.getBlankList();
        mBankAccountSelectList = SpectraCoreUtil.getBlankList();
    }
    
    /* Setters */
    public void setUniqueKey(Integer pUniqueKey){
        mUniqueKey = pUniqueKey;
    }

    //public void setIsPrimary(Boolean pIsPrimary){
    //    mIsPrimary = pIsPrimary;
    //}

    public void setCustomerList(Map<Id, Lending_Application_Customer__c> pCustomerMap){
        mCustomerMap = pCustomerMap;
        mCustomerSelectList = LendingApplicationCustomerUtil.getCustomerSelectList(mCustomerMap.values());
    }

    public void setCustomerBankAccounts(Map<Id, List<Bank_Account__c>> pCustomerBankAccountsMap){
        mCustomerBankAccountsMap = pCustomerBankAccountsMap;
    }

    public void setBankAccountList(){
        mBankAccountMap = new Map<Id, Bank_Account__c>();
        if (mDirectDebit.Customer_Reference_Number__c != null
                && mCustomerBankAccountsMap.containsKey(mDirectDebit.Customer_Reference_Number__c)){
            mBankAccountMap = new Map<Id, Bank_Account__c>(mCustomerBankAccountsMap.get(mDirectDebit.Customer_Reference_Number__c));
        }
        mBankAccountSelectList = BankAccountUtil.getBankAccountSelectList(mBankAccountMap.values());
        mDirectDebit.Bank_Account_Name__c = null;
        mSelectedBankAccount = getBlankBankAccount();
        
        //default to primary bank account
        for (Bank_Account__c bankAcct : mBankAccountMap.values()){
            if (bankAcct.Is_Primary__c){
                mDirectDebit.Bank_Account_Name__c = bankAcct.Id;
                mSelectedBankAccount = bankAcct;
                break;
            }
        }
    }

    public void setSelectedBankAccount(){
        if (mDirectDebit.Bank_Account_Name__c != null
                && mBankAccountMap.containsKey(mDirectDebit.Bank_Account_Name__c)){
            mSelectedBankAccount = mBankAccountMap.get(mDirectDebit.Bank_Account_Name__c);
        } 
        else {
            mSelectedBankAccount = getBlankBankAccount();
        }
    }

    /* Getters */
    public Integer getUniqueKey(){
        return mUniqueKey;
    }

    //public Boolean getIsPrimary(){
    //    return mIsPrimary;
    //}

    public Map<Id, Lending_Application_Customer__c> getCustomerMap(){
        return mCustomerMap;
    }

    public List<SelectOption> getCustomerList(){
        return mCustomerSelectList;
    }

    public List<SelectOption> getBankAccountList(){
        return mBankAccountSelectList;
    }

    public Bank_Account__c getSelectedBankAccount(){
        return mSelectedBankAccount;
    }

    private Bank_Account__c getBlankBankAccount(){
        Bank_Account__c blankBankAcct = new Bank_Account__c();
        blankBankAcct.name = null;
        blankBankAcct.Account_Name__c = null;
        blankBankAcct.Contact_Name__c = null;
        blankBankAcct.Bank_Account_Holder_Name__c = null;
        blankBankAcct.Bank_Account_Number__c = null;
        blankBankAcct.Bank_Account_Type__c = null;
        blankBankAcct.Bank_Identification_Code__c = null;
        blankBankAcct.Bank_Name__c = null;
        blankBankAcct.Bank_Branch_Name__c = null;
        blankBankAcct.Is_Active__c = false;
        
        return blankBankAcct;
    }
    
}
