public with sharing class DisbursementEditController extends ContractRelatedControllerBase{
    private static final String CLASS_NAME = 'DisbursementEditController';

    public Contract_Disbursement__c mDisbursement {get; set;}
    public List<SelectOption> mCustomerSelectList {get; private set;}
    public List<SelectOption> mContactSelectList {get; private set;}
    public List<SelectOption> mBankAccountSelectList {get; private set;}
    
    private Map<Id, Contract_Customer__c> mCustomerMap;
    private Map<Id, fsCore__Bank_Account__c> mBankAccountMap;
    private fsCore__Bank_Account__c mSelectedBankAccount;

    public DisbursementEditController(ApexPages.StandardController pStdController){
        super(pStdController);
        this.mDisbursement = (Contract_Disbursement__c)pStdController.getRecord();
        init();
    }
    
    private void init(){
        if (mDisbursement.Id != null){
            mDisbursement = (Contract_Disbursement__c) fsCore.SObjectQueryUtil.getSObjectRecord(mDisbursement.Id);
        }

        //get parent contract
        Id contractId;
        if (mPageURLParamMap.containsKey(fsCore.Constants.PAGE_PARENT_ID)){
            contractId = Id.valueOf(mPageURLParamMap.get(fsCore.Constants.PAGE_PARENT_ID));
        }
        else if (mDisbursement.Lending_Contract_Number__c != null){
            contractId = mDisbursement.Lending_Contract_Number__c;
        } 
        else {
            throw new ServicingException(Label.Parent_Contract_Id_Missing);
        }
        
        setLendingContract(contractId);
        mCustomerMap = new Map<Id, Contract_Customer__c>(ContractRelatedRecordQueryUtil.getCustomers(contractId));
        setCustomerSelectList();

        if(mDisbursement.Id == null){ //new record
            setDefaultValues();
        }
        
        if (getIsThirdParty()){
            setContactSelectList();
        }
        setBankAccountSelectList();
        setSelectedBankAccount();
    }

    private void setCustomerSelectList(){
        mCustomerSelectList = new List<SelectOption>();
        mCustomerSelectList.add(new SelectOption(Constants.BLANK_STRING, '-- Select a customer --'));
        for(Contract_Customer__c customer : mCustomerMap.values()){
            mCustomerSelectList.add(new SelectOption(customer.Id, customer.Customer_Name__c));
        }
    }
    
    private void setDefaultValues(){
        Map<String, RecordType> recTypeMap = RecordTypeUtil.getInstance()
                                                   .getRecordTypeMapByName(Schema.SObjectType.Contract_Disbursement__c.getName());
        
        mDisbursement = new Contract_Direct_Debit__c();
        mDisbursement.RecordTypeId = recTypeMap.get(Constants.RECORD_TYPE_OPEN).Id;
        mDisbursement.Lending_Contract_Number__c = getLendingContract().Id;
        mDisbursement.Disbursement_Date__c = getBusinessDate();
        mDisbursement.Payment_Method__c = fsCore.Constants.PAYMENT_METHOD_ELECTRONIC;
    }
    
    private void setContactSelectList(){
        List<Contact> contactList = new List<Contact>();
        if (mDisbursement.Account_Name__c != null){
            contactList = fsCore.AccountContactUtil.getContactList(mDisbursement.Account_Name__c);
            if (contactList.size() == 1 && mDisbursement.Contact_Name__c == null){
                mDisbursement.Contact_Name__c = contactList.get(0).Id;
            }
        }
        mContactSelectList = fsCore.AccountContactUtil.getContactSelectList(contactList);
    }

    private void setBankAccountSelectList(){
        mBankAccountMap = new Map<Id, fsCore__Bank_Account__c>();
        if (getIsElectronicPayment()){
            if (mDisbursement.Account_Name__c != null){
                mBankAccountMap.putAll(fsCore.BankAccountUtil.getAccountBankAccountListMap(new Set<Id>{mDisbursement.Account_Name__c}));
            }
            if (mDisbursement.Contact_Name__c != null){
                mBankAccountMap.putAll(fsCore.BankAccountUtil.getContactBankAccountListMap(new Set<Id>{mDisbursement.Contact_Name__c}));
            }
        }

        mBankAccountSelectList = fsCore.BankAccountUtil.getBankAccountSelectList(mBankAccountMap.values());
        
        if (getIsElectronicPayment() && mDisbursement.Bank_Account_Name__c == null){
            for (fsCore__Bank_Account__c bankAcct : mBankAccountMap.values()){
                if (bankAcct.fsCore__Is_Primary__c){
                    mDisbursement.Bank_Account_Name__c = bankAcct.Id;
                    break;
                }
            }
        }
    }
    
    private void setSelectedBankAccount(){
        if (mDisbursement.Bank_Account_Name__c != null && mBankAccountMap.containsKey(mDisbursement.Bank_Account_Name__c)){
            mSelectedBankAccount = mBankAccountMap.get(mDisbursement.Bank_Account_Name__c);
        } else {
            mDisbursement.Bank_Account_Name__c = null;
            mSelectedBankAccount = getBlankBankAccount();
        }
    }
    
    public Boolean getIsCustomer(){
        return (String.IsNotBlank(mDisbursement.Disbursement_Party_Type__c) 
                    && mDisbursement.Disbursement_Party_Type__c.equalsIgnoreCase(fsCore.Constants.DISBURSEMENT_PARTY_CUSTOMER));
    }
    
    public Boolean getIsThirdParty(){
        return (String.IsNotBlank(mDisbursement.Disbursement_Party_Type__c) 
                    && mDisbursement.Disbursement_Party_Type__c.equalsIgnoreCase(fsCore.Constants.DISBURSEMENT_PARTY_THIRD_PARTY));
    }
    
    public Boolean getIsElectronicPayment(){
        return (String.IsNotBlank(mDisbursement.Payment_Method__c) && mDisbursement.Payment_Method__c.equalsIgnoreCase(fsCore.Constants.PAYMENT_METHOD_ELECTRONIC));
    }
    
    public PageReference onPartyTypeChange(){
        mDisbursement.Customer_Reference_Number__c = null;
        mDisbursement.Account_Name__c = null;
        mDisbursement.Contact_Name__c = null;
        
        if (String.IsNotBlank(mDisbursement.Disbursement_Party_Type__c)
                && mAppDisbObject.mDisbursement.Disbursement_Party_Type__c.equalsIgnoreCase(Constants.DISBURSEMENT_PARTY_CUSTOMER)){
            for(Contract_Customer__c customer : mCustomerMap.values()){
                if (customer.Is_Primary__c){
                    mDisbursement.Customer_Reference_Number__c = customer.Id;
                    break;
                }
            }

            if (mDisbursement.Customer_Reference_Number__c != null){
                mDisbursement.Account_Name__c = mCustomerMap.get(mDisbursement.Customer_Reference_Number__c).Account_Name__c;
                mDisbursement.Contact_Name__c = mCustomerMap.get(mDisbursement.Customer_Reference_Number__c).Contact_Name__c;
            }
        } 
        
        setBankAccountSelectList();
        setSelectedBankAccount();
        return null;
    }
    
    public PageReference onAccountChange(){
        mDisbursement.Contact_Name__c = null;
        setContactSelectList();
        setBankAccountSelectList();
        setSelectedBankAccount();
        return null;
    }

    public PageReference onContactChange(){
        setBankAccountSelectList();
        setSelectedBankAccount();
        return null;
    }

    public PageReference onCustomerChange(){
        mDisbursement.Account_Name__c = null;
        mDisbursement.Contact_Name__c = null;
        if (mDisbursement.Customer_Reference_Number__c != null){
            mDisbursement.Account_Name__c = mCustomerMap.get(mDisbursement.Customer_Reference_Number__c).Account_Name__c;
            mDisbursement.Contact_Name__c = mCustomerMap.get(mDisbursement.Customer_Reference_Number__c).Contact_Name__c;
        }
        setBankAccountSelectList();
        setSelectedBankAccount();
        return null;
    }

    public PageReference onPaymentMethodChange(){
        setBankAccountSelectList();
        setSelectedBankAccount();
        return null;
    }

    public PageReference onBankAccountChange(){
        setSelectedBankAccount();
        return null;
    }

    public override List<fsCore.ErrorObject> saveRecord(){
        List<Contract_Disbursement__c> disbursementForUpsert = new List<Contract_Disbursement__c>();
        disbursementForUpsert.add(mDisbursement);
        
        List<fsCore.ErrorObject> errorList = new List<fsCore.ErrorObject>();
        fsCore.DMLResult disbursementSaveRslt = ContractDisbursementDMLWrapper.getInstance().upsertData(disbursementForUpsert);
        if (disbursementSaveRslt.hasErrors()) { errorList = disbursementSaveRslt.getErrorList(); }
        super.setContextRecordId(mDisbursement.Id);

        return errorList;
    }
    
    public override String getClassName(){
        return CLASS_NAME;
    }

    public override PageReference getReturnPageURL(){
        return new PageReference('/' + Schema.sObjectType.Lending_Contract__c.getKeyPrefix() + '/l');
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
        blankBankAcct.fsCore__Is_Primary__c = false;
        blankBankAcct.fsCore__Is_Verified__c = false;
        
        return blankBankAcct;
    }
}
