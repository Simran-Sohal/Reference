public class DirectDebitObject{

    public Contract_Direct_Debit__c mDirectDebit {get;set;}
    
    private Map<Id, Contract_Customer__c> mCustomerMap;
    private List<SelectOption> mCustomerSelectList;

    private Map<Id, List<fsCore__Bank_Account__c>> mCustomerBankAccountsMap;

    private Map<Id, fsCore__Bank_Account__c> mBankAccountMap;
    private List<SelectOption> mBankAccountSelectList;
    private fsCore__Bank_Account__c mSelectedBankAccount;
    
    public DirectDebitObject(Contract_Direct_Debit__c pDirectDebit){
        mDirectDebit = pDirectDebit;
        mCustomerMap = new Map<Id, Contract_Customer__c>();
        mCustomerBankAccountsMap = new Map<Id, List<fsCore__Bank_Account__c>>();
        mBankAccountMap = new Map<Id, fsCore__Bank_Account__c>();
        mSelectedBankAccount = new fsCore__Bank_Account__c();

        mCustomerSelectList = fsCore.SpectraCoreUtil.getBlankList();
        mBankAccountSelectList = fsCore.SpectraCoreUtil.getBlankList();
    }
    
    /* Setters */
    public void setCustomerList(Map<Id, Contract_Customer__c> pCustomerMap){
        mCustomerMap = pCustomerMap;
        
        //set customer select list
        mCustomerSelectList = new List<SelectOption>();
        mCustomerSelectList.add(new SelectOption(Constants.BLANK_STRING, '-- Select a customer --'));
        for(Contract_Customer__c customer : mCustomerMap.values()){
            mCustomerSelectList.add(new SelectOption(customer.Id, customer.Customer_Name__c));
            if (customer.Is_Primary__c){
                mDirectDebit.Customer_Reference_Number__c = customer.Id;
                setBankAccountList();
            }
        }
    }

    public void setCustomerBankAccounts(Map<Id, List<fsCore__Bank_Account__c>> pCustomerBankAccountsMap){
        mCustomerBankAccountsMap = pCustomerBankAccountsMap;
    }

    public void setBankAccountList(){
        mBankAccountMap = new Map<Id, fsCore__Bank_Account__c>();
        if (mDirectDebit.Customer_Reference_Number__c != null
                && mCustomerBankAccountsMap.containsKey(mDirectDebit.Customer_Reference_Number__c)){
            mBankAccountMap = new Map<Id, fsCore__Bank_Account__c>(mCustomerBankAccountsMap.get(mDirectDebit.Customer_Reference_Number__c));
        }
        mBankAccountSelectList = fsCore.BankAccountUtil.getBankAccountSelectList(mBankAccountMap.values());
        mDirectDebit.Bank_Account_Name__c = null;
        mSelectedBankAccount = getBlankBankAccount();
        
        //default to primary bank account
        for (fsCore__Bank_Account__c bankAcct : mBankAccountMap.values()){
            if (bankAcct.fsCore__Is_Primary__c){
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
    public Map<Id, Customer_Customer__c> getCustomerMap(){
        return mCustomerMap;
    }

    public List<SelectOption> getCustomerList(){
        return mCustomerSelectList;
    }

    public List<SelectOption> getBankAccountList(){
        return mBankAccountSelectList;
    }

    public fsCore__Bank_Account__c getSelectedBankAccount(){
        return mSelectedBankAccount;
    }

    private fsCore__Bank_Account__c getBlankBankAccount(){
        fsCore__Bank_Account__c blankBankAcct = new fsCore__Bank_Account__c();
        blankBankAcct.name = null;
        blankBankAcct.fsCore__Account_Name__c = null;
        blankBankAcct.fsCore__Contact_Name__c = null;
        blankBankAcct.fsCore__Bank_Account_Holder_Name__c = null;
        blankBankAcct.fsCore__Bank_Account_Number__c = null;
        blankBankAcct.fsCore__Bank_Account_Type__c = null;
        blankBankAcct.fsCore__Bank_Identification_Code__c = null;
        blankBankAcct.fsCore__Bank_Name__c = null;
        blankBankAcct.fsCore__Bank_Branch_Name__c = null;
        blankBankAcct.fsCore__Is_Active__c = false;
        
        return blankBankAcct;
    }
}
