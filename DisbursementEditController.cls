public with sharing class DisbursementEditController extends SingleRecordControllerBase{
    private static final String CLASS_NAME = 'DisbursementEditController';

    public Lending_Application__c mApplication {get; private set;}
    public LendingApplicationDisbursementObject mAppDisbObject {get; set;}
    private Lending_Application_Disbursement__c mDisbursement;

    public DisbursementEditController(ApexPages.StandardController pStdController){
        super(pStdController);
        this.mDisbursement = (Lending_Application_Disbursement__c)pStdController.getRecord();
        init();
    }
    
    private void init(){
        if (mContextRecordId != null){
            mDisbursement = (Lending_Application_Disbursement__c) SObjectQueryUtil.getSObjectRecord(mContextRecordId);
        }

        //get parent application
        Id applicationId;
        if (mPageURLParamMap.containsKey(Constants.PAGE_PARENT_ID)){
            applicationId = Id.valueOf(mPageURLParamMap.get(Constants.PAGE_PARENT_ID));
        }
        else if (mDisbursement.Lending_Application_Number__c != null){
            applicationId = mDisbursement.Lending_Application_Number__c;
        } 
        else {
            throw new CustomException(Label.Parent_Application_Id_Missing);
        }
        
        mApplication = (Lending_Application__c) SObjectQueryUtil.getSObjectRecord(applicationId);
        if (mDisbursement.Id == null){
            mDisbursement.Lending_Application_Number__c = mApplication.Id;
        }
        setDisbursementObject();
    }

    private void setDisbursementObject(){
        mAppDisbObject = new LendingApplicationDisbursementObject(mDisbursement);
        mAppDisbObject.setUniqueKey(SpectraCoreUtil.getRandomInteger());
        if (String.IsNotBlank(mDisbursement.Disbursement_Party_Type__c) && mDisbursement.Disbursement_Party_Type__c.equalsIgnoreCase(Constants.DISBURSEMENT_PARTY_CUSTOMER)){
            Map<Id, Lending_Application_Customer__c> customerMap = new Map<Id, Lending_Application_Customer__c>(LendingApplicationCustomerUtil.getCustomers(mApplication.Id));
            mAppDisbObject.setCustomerList(customerMap);
            mAppDisbObject.setCustomerDetails();
        } 
        
        if (mDisbursement.Account_Name__c != null && String.IsNotBlank(mDisbursement.Disbursement_Party_Type__c)
                && !mDisbursement.Disbursement_Party_Type__c.equalsIgnoreCase(Constants.DISBURSEMENT_PARTY_CUSTOMER)){
            mAppDisbObject.setAccountContactList();
        }

        if (String.isNotBlank(mDisbursement.Payment_Method__c)
                && mDisbursement.Payment_Method__c.equalsIgnoreCase(Constants.PAYMENT_METHOD_ELECTRONIC)){
            mAppDisbObject.setIsElectronicPayment();
            setPartyBankAccounts();
        }
    }
    
    private void setPartyBankAccounts(){
        Set<Id> searchByAccountIdSet = new Set<Id>();
        Set<Id> searchByContactIdSet = new Set<Id>();
        
        if (mDisbursement.Account_Name__c != null){ searchByAccountIdSet.add(mDisbursement.Account_Name__c); }
        if (mDisbursement.Contact_Name__c != null){ searchByContactIdSet.add(mDisbursement.Contact_Name__c); }
        
        Map<Id, List<Bank_Account__c>> partyBankAccountsMap = new Map<Id, List<Bank_Account__c>>();
        partyBankAccountsMap.putAll(BankAccountUtil.getAccountBankAccountListMap(searchByAccountIdSet));
        partyBankAccountsMap.putAll(BankAccountUtil.getContactBankAccountListMap(searchByContactIdSet));

        mAppDisbObject.setPartyBankAccounts(partyBankAccountsMap);
        mAppDisbObject.setBankAccountList();
        mAppDisbObject.setSelectedBankAccount();
    }

    public PageReference onPartyTypeChange(){
        mAppDisbObject.setPartyType();
        
        mAppDisbObject.mDisbursement.Account_Name__c = null;
        mAppDisbObject.mDisbursement.Contact_Name__c = null;
        mAppDisbObject.mDisbursement.Bank_Account_Name__c = null;
        
        if (String.IsNotBlank(mAppDisbObject.mDisbursement.Disbursement_Party_Type__c)
                && mAppDisbObject.mDisbursement.Disbursement_Party_Type__c.equalsIgnoreCase(Constants.DISBURSEMENT_PARTY_CUSTOMER)){
            Map<Id, Lending_Application_Customer__c> customerMap = new Map<Id, Lending_Application_Customer__c>(LendingApplicationCustomerUtil.getCustomers(mApplication.Id));
            mAppDisbObject.setCustomerList(customerMap);
            
            for(Lending_Application_Customer__c customer : customerMap.values()){
                if (customer.Is_Primary__c){
                    mAppDisbObject.mDisbursement.Customer_Reference_Number__c = customer.Id;
                    break;
                }
            }

            mAppDisbObject.setCustomerDetails();

        } 
        mAppDisbObject.resetBankAccountDetails();
        setPartyBankAccounts();
        return null;
    }
    
    public PageReference onAccountChange(){
        mAppDisbObject.mDisbursement.Contact_Name__c = null;
        mAppDisbObject.mDisbursement.Bank_Account_Name__c = null;
        mAppDisbObject.setAccountContactList();
        mAppDisbObject.resetBankAccountDetails();
        setPartyBankAccounts();
        return null;
    }

    public PageReference onContactChange(){
        mAppDisbObject.mDisbursement.Bank_Account_Name__c = null;
        mAppDisbObject.resetBankAccountDetails();
        setPartyBankAccounts();
        return null;
    }

    public PageReference onFutureFlagChange(){
        mAppDisbObject.setFutureFlag();
        return null;
    }

    public PageReference onCustomerChange(){
        mAppDisbObject.setCustomerDetails();
        mAppDisbObject.resetBankAccountDetails();
        setPartyBankAccounts();
        return null;
    }

    public PageReference onPaymentMethodChange(){
        mAppDisbObject.setIsElectronicPayment();
        mAppDisbObject.resetBankAccountDetails();
        mAppDisbObject.resetAddressDetails();
        return null;
    }

    public PageReference onBankAccountChange(){
        mAppDisbObject.setSelectedBankAccount();
        return null;
    }

    public override Boolean validateRecord(){
        Boolean isValid = true;
        if (String.IsNotBlank(mAppDisbObject.mDisbursement.Disbursement_Party_Type__c)
                && mAppDisbObject.mDisbursement.Disbursement_Party_Type__c.equalsIgnoreCase(Constants.DISBURSEMENT_PARTY_CUSTOMER)
                    && mAppDisbObject.mDisbursement.Customer_Reference_Number__c == null){
            isValid = false;
            addError(Label.Customer_Not_Selected_For_Disbursement);
        }
        if (String.IsNotBlank(mAppDisbObject.mDisbursement.Disbursement_Party_Type__c)
                && mAppDisbObject.mDisbursement.Disbursement_Party_Type__c.equalsIgnoreCase(Constants.DISBURSEMENT_PARTY_THIRD_PARTY)
                    && (mAppDisbObject.mDisbursement.Account_Name__c == null && mAppDisbObject.mDisbursement.Contact_Name__c == null)){
            isValid = false;
            addError(Label.Account_Contact_Blank_For_Disbursement);
        }
        return isValid;
    }
    
    public override List<ErrorObject> saveRecord(){
        List<ErrorObject> errorList = new List<ErrorObject>();
        List<Lending_Application_Disbursement__c> disbForUpsert = new List<Lending_Application_Disbursement__c>();
        disbForUpsert.add(mAppDisbObject.mDisbursement);
        
        DMLResult disbSaveRslt = LendingApplicationDisbursementDMLWrapper.getInstance().upsertData(disbForUpsert);
        if (disbSaveRslt.hasErrors()) { errorList = disbSaveRslt.getErrorList(); }
        super.setContextRecordId(mAppDisbObject.mDisbursement.Id);

        return errorList;
    }
    
    public override String getClassName(){
        return CLASS_NAME;
    }

    public override PageReference getReturnPageURL(){
        return new PageReference('/' + Schema.sObjectType.Lending_Application__c.getKeyPrefix() + '/l');
    }     
}
