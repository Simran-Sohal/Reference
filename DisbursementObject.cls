public with sharing class DisbursementObject{

    public Lending_Application_Disbursement__c mDisbursement {get;set;}
    private Integer mUniqueKey;
    private Boolean mIsCustomer;
    private Boolean mIsElectronicPayment;

    private Map<Id, Lending_Application_Customer__c> mCustomerMap;
    private Map<Id, List<Bank_Account__c>> mPartyBankAccountsMap;
    private Map<Id, Bank_Account__c> mBankAccountMap;

    private List<SelectOption> mCustomerSelectList;
    private List<SelectOption> mContactSelectList;
    private List<SelectOption> mBankAccountSelectList;
    private List<Lending_Application_Itemization__c> mAppItemizationList;
    private Bank_Account__c mSelectedBankAccount;
    
    public LendingApplicationDisbursementObject(Lending_Application_Disbursement__c pDisbursement){
        mDisbursement = pDisbursement;

        mUniqueKey = null;
        mIsCustomer = (String.IsNotBlank(mDisbursement.Disbursement_Party_Type__c)
                            && mDisbursement.Disbursement_Party_Type__c.equalsIgnoreCase(Constants.DISBURSEMENT_PARTY_CUSTOMER));
        
        if (String.IsBlank(mDisbursement.Payment_Method__c)){
            mDisbursement.Payment_Method__c = Constants.PAYMENT_METHOD_ELECTRONIC;
        }

        mIsElectronicPayment = (String.IsNotBlank(mDisbursement.Payment_Method__c)
                                    && mDisbursement.Payment_Method__c.equalsIgnoreCase(Constants.PAYMENT_METHOD_ELECTRONIC));
                                    
        mCustomerMap = new Map<Id, Lending_Application_Customer__c>();
        mPartyBankAccountsMap = new Map<Id, List<Bank_Account__c>>();
        mBankAccountMap = new Map<Id, Bank_Account__c>();

        mCustomerSelectList = new List<SelectOption>();
        mContactSelectList = new List<SelectOption>();
        mBankAccountSelectList = new List<SelectOption>();
        mSelectedBankAccount = new Bank_Account__c();
        mAppItemizationList = new List<Lending_Application_Itemization__c>();
    }
    
    /* Setter */
    public void setUniqueKey(Integer pUniqueKey){
        mUniqueKey = pUniqueKey;
    }

    public void setPartyType(){
        mIsCustomer = (String.IsNotBlank(mDisbursement.Disbursement_Party_Type__c)
                            && mDisbursement.Disbursement_Party_Type__c.equalsIgnoreCase(Constants.DISBURSEMENT_PARTY_CUSTOMER));
        System.debug(loggingLevel.ERROR, '-- Is Customer : ' + mIsCustomer);
        resetPartyDetails();
    }

    public void setFutureFlag(){
        if (!mDisbursement.Is_Future_Disbursement__c){
            mDisbursement.Future_Disbursement_Date__c = null;
        }
    }

    public void setCustomerList(Map<Id, Lending_Application_Customer__c> pCustomerMap){
        mCustomerMap = pCustomerMap;
        mCustomerSelectList = LendingApplicationCustomerUtil.getCustomerSelectList(mCustomerMap.values());
    }

    public void setItemizationList(List<Lending_Application_Itemization__c> pItemizationList){
        mAppItemizationList = pItemizationList;
    }

    public void setCustomerDetails(){
        if (String.IsNotBlank(mDisbursement.Customer_Reference_Number__c)
                && mDisbursement.Disbursement_Party_Type__c.equalsIgnoreCase(Constants.DISBURSEMENT_PARTY_CUSTOMER)
                && mCustomerMap.containsKey(mDisbursement.Customer_Reference_Number__c)){
            mIsCustomer = true;
            mDisbursement.Account_Name__c = mCustomerMap.get(mDisbursement.Customer_Reference_Number__c).Account_Name__c;
            mDisbursement.Contact_Name__c = mCustomerMap.get(mDisbursement.Customer_Reference_Number__c).Contact_Name__c;
        }
    }

    public void setAccountContactList(List<Contact> pContactList){
        mContactSelectList = AccountContactUtil.getContactSelectList(pContactList);
    }

    public void setAccountContactList(){
        List<Contact> contactList = new List<Contact>();
        if (mDisbursement.Account_Name__c != null){
            contactList = AccountContactUtil.getContactList(mDisbursement.Account_Name__c);
        }
        setAccountContactList(contactList);
    }

    public void setPartyBankAccounts(Map<Id, List<Bank_Account__c>> pPartyBankAccountsMap){
        mPartyBankAccountsMap = pPartyBankAccountsMap;
    }

    public void addPartyBankAccounts(Id pPartyId, List<Bank_Account__c> pPartyBankAccounts){
        mPartyBankAccountsMap.put(pPartyId, pPartyBankAccounts);
    }
    
    public void setBankAccountList(){
        List<Bank_Account__c> partyBankAccountList = new List<Bank_Account__c>();
        if (mDisbursement.Account_Name__c != null && mPartyBankAccountsMap.containsKey(mDisbursement.Account_Name__c)){
            partyBankAccountList.addAll(mPartyBankAccountsMap.get(mDisbursement.Account_Name__c));
        }
        if (mDisbursement.Contact_Name__c != null && mPartyBankAccountsMap.containsKey(mDisbursement.Contact_Name__c)){
            partyBankAccountList.addAll(mPartyBankAccountsMap.get(mDisbursement.Contact_Name__c));
        }
        
        mBankAccountMap = new Map<Id, Bank_Account__c>();
        Bank_Account__c primaryBankAcct;
        for (Bank_Account__c bankAcct : partyBankAccountList){
            mBankAccountMap.put(bankAcct.Id, bankAcct);
            if (bankAcct.Is_Primary__c){
                primaryBankAcct = bankAcct;
            }
        }
        mBankAccountSelectList = BankAccountUtil.getBankAccountSelectList(mBankAccountMap.values());
        
        if (primaryBankAcct != null){
            mDisbursement.Bank_Account_Name__c = primaryBankAcct.Id;
            mSelectedBankAccount = primaryBankAcct;
        }
    }
    
    public void setIsElectronicPayment(){
        mIsElectronicPayment = (String.IsNotBlank(mDisbursement.Payment_Method__c)
                                    && mDisbursement.Payment_Method__c.equalsIgnoreCase(Constants.PAYMENT_METHOD_ELECTRONIC));
    }
    
    public void setSelectedBankAccount(){
        if (mDisbursement.Bank_Account_Name__c != null
                && mBankAccountMap.containsKey(mDisbursement.Bank_Account_Name__c)){
            mSelectedBankAccount = mBankAccountMap.get(mDisbursement.Bank_Account_Name__c);
        } 
        else {
            mSelectedBankAccount = getBlankBankAccount();
        }
    }

    /* Getter */
    public Integer getUniqueKey(){
        return mUniqueKey;
    }

    public Boolean getIsCustomer(){
        return mIsCustomer;
    }

    public List<SelectOption> getCustomerList(){
        return mCustomerSelectList;
    }

    public List<SelectOption> getAccountContactList(){
        return mContactSelectList;
    }

    public Map<Id, List<Bank_Account__c>> getPartyBankAccountsMap(){
        return mPartyBankAccountsMap;
    }

    public Boolean getIsElectronicPayment(){
        return mIsElectronicPayment;
    }

    public List<SelectOption> getBankAccountList(){
        return mBankAccountSelectList;
    }
    
    public Bank_Account__c getSelectedBankAccount(){
        return mSelectedBankAccount;
    }

    public List<Lending_Application_Itemization__c> getItemizationList(){
        return mAppItemizationList;
    }

    /* Helper Methods */
    public void resetPartyDetails(){
        mDisbursement.Customer_Reference_Number__c = null;
        mDisbursement.Account_Name__c = null;
        mDisbursement.Contact_Name__c = null;
        
        resetBankAccountDetails();
        setBankAccountList();
        resetAddressDetails();
    }

    public void resetBankAccountDetails(){
        mDisbursement.Bank_Account_Name__c = null;
        setSelectedBankAccount();
    }

    public void resetAddressDetails(){
        mDisbursement.Address_Number__c = null;
        mDisbursement.Suite__c = null;
        mDisbursement.Street__c = null;
        mDisbursement.City__c = null;
        mDisbursement.State__c = null;
        mDisbursement.Country__c = null;
        mDisbursement.Zip_Code__c = null;
        mDisbursement.Zip_Extension__c = null;
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
        blankBankAcct.Is_Primary__c = false;
        blankBankAcct.Is_Verified__c = false;
        
        return blankBankAcct;
    }

}
