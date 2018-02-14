public with sharing class DirectDebitEditController extends SingleRecordControllerBase{
    private static final String CLASS_NAME = 'DirectDebitEditController';

    public Lending_Application__c mApplication {get; private set;}
    public LendingApplicationDirectDebitObject mAppDirectDebitObject {get; set;}
    private Lending_Application_Direct_Debit__c mDirectDebit;

    private Map<Id, Lending_Application_Customer__c> mCustomerMap;
 
    public DirectDebitEditController(ApexPages.StandardController pStdController){
        super(pStdController);
        this.mDirectDebit = (Lending_Application_Direct_Debit__c)pStdController.getRecord();
        init();
    }
    
    private void init(){
        if (mContextRecordId != null){
            mDirectDebit = (Lending_Application_Direct_Debit__c) SObjectQueryUtil.getSObjectRecord(mContextRecordId);
        }

        //get parent application
        Id applicationId;
        if (mPageURLParamMap.containsKey(Constants.PAGE_PARENT_ID)){
            applicationId = Id.valueOf(mPageURLParamMap.get(Constants.PAGE_PARENT_ID));
        }
        else if (mDirectDebit.Lending_Application_Number__c != null){
            applicationId = mDirectDebit.Lending_Application_Number__c;
        } 
        else {
            throw new CustomException(Label.Parent_Application_Id_Missing);
        }
        
        mApplication = (Lending_Application__c) SObjectQueryUtil.getSObjectRecord(applicationId);
        mCustomerMap = new Map<Id, Lending_Application_Customer__c>(LendingApplicationCustomerUtil.getCustomers(mApplication.Id));

        if(mDirectDebit.Id == null){ //new record
            setDefaultValues();
        }
        setDirectDebitObject();
    }

    private void setDefaultValues(){
        Map<String, RecordType> recTypeMap = RecordTypeUtil.getInstance()
                                                   .getRecordTypeMapByName(Schema.SObjectType.Lending_Application_Direct_Debit__c.getName());
        
        mDirectDebit = new Lending_Application_Direct_Debit__c();
        mDirectDebit.RecordTypeId = recTypeMap.get(Constants.RECORD_TYPE_ACTIVE).Id;
        mDirectDebit.Lending_Application_Number__c = mApplication.Id;
        mDirectDebit.Debit_Amount_Source__c = null;
        //if there is only one customer assign it by default
        if (mCustomerMap.size() == 1){
            mDirectDebit.Customer_Reference_Number__c = mCustomerMap.values().get(0).Id;
        } else {
            for (Lending_Application_Customer__c customer : mCustomerMap.values()){
                if (customer.Is_Primary__c){
                    mDirectDebit.Customer_Reference_Number__c = customer.Id;
                    break;
                }
            }
        }
    }
    
    private void setDirectDebitObject(){
        Map<Id, List<Bank_Account__c>> customerBankAccountsMap = LendingApplicationCustomerUtil.getBankAccountsMap(mCustomerMap.values());
        
        mAppDirectDebitObject = new LendingApplicationDirectDebitObject(mDirectDebit);
        mAppDirectDebitObject.setUniqueKey(SpectraCoreUtil.getRandomInteger());
        mAppDirectDebitObject.setCustomerList(mCustomerMap);
        mAppDirectDebitObject.setCustomerBankAccounts(customerBankAccountsMap);
        mAppDirectDebitObject.setBankAccountList();
        mAppDirectDebitObject.setSelectedBankAccount();
    }

    public PageReference doReloadDetails(){
        setDirectDebitObject();
        return null;
    }
    
    public override List<ErrorObject> saveRecord(){
        List<ErrorObject> errorList = new List<ErrorObject>();
        List<Lending_Application_Direct_Debit__c> directDebitForUpsert = new List<Lending_Application_Direct_Debit__c>();
        directDebitForUpsert.add(mAppDirectDebitObject.mDirectDebit);
        
        DMLResult directDebitSaveRslt = LendingApplicationDirectDebitDMLWrapper.getInstance().upsertData(directDebitForUpsert);
        if (directDebitSaveRslt.hasErrors()) { errorList = directDebitSaveRslt.getErrorList(); }
        super.setContextRecordId(mAppDirectDebitObject.mDirectDebit.Id);

        return errorList;
    }
    
    public override String getClassName(){
        return CLASS_NAME;
    }

    public override PageReference getReturnPageURL(){
        return new PageReference('/' + Schema.sObjectType.Lending_Application__c.getKeyPrefix() + '/l');
    }     
}
