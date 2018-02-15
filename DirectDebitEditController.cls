public with sharing class DirectDebitEditController extends ContractRelatedControllerBase{
    private static final String CLASS_NAME = 'DirectDebitEditController';

    public Contract_Direct_Debit__c mDirectDebit {get; set;}
    
    private Map<Id, Contract_Customer__c> customerMap;
    private List<SelectOption> mCustomerSelectList;
    private Map<Id, fsCore__Bank_Account__c> mBankAccountMap;
    private List<SelectOption> mBankAccountSelectList;
    
    private Map<Id, List<fsCore__Bank_Account__c>> mCustomerBankAccountsMap;
    private fsCore__Bank_Account__c mSelectedBankAccount;
 
    public DirectDebitEditController(ApexPages.StandardController pStdController){
        super(pStdController);
        this.mDirectDebit = (Contract_Direct_Debit__c)pStdController.getRecord();
        init();
    }
    
    private void init(){
        if (mDirectDebit.Id != null){
            mDirectDebit = (Contract_Direct_Debit__c) fsCore.SObjectQueryUtil.getSObjectRecord(mDirectDebit.Id);
        }

        //get parent contract
        Id contractId;
        if (mPageURLParamMap.containsKey(fsCore.Constants.PAGE_PARENT_ID)){
            contractId = Id.valueOf(mPageURLParamMap.get(fsCore.Constants.PAGE_PARENT_ID));
        }
        else if (mDirectDebit.Lending_Contract_Number__c != null){
            contractId = mDirectDebit.Lending_Contract_Number__c;
        } 
        else {
            throw new ServicingException(Label.Parent_Contract_Id_Missing);
        }
        
        setLendingContract(contractId);
        mCustomerMap = new Map<Id, Contract_Customer__c>(ContractRelatedRecordQueryUtil.getCustomers(contractId));

        if(mDirectDebitObject.mDirectDebit.Id == null){ //new record
            setDefaultValues();
        }
        setDirectDebitObject();
    }

    private void setDefaultValues(){
        Map<String, RecordType> recTypeMap = RecordTypeUtil.getInstance()
                                                   .getRecordTypeMapByName(Schema.SObjectType.Contract_Direct_Debit__c.getName());
        
        mDirectDebitObject.mDirectDebit = new Lending_Application_Direct_Debit__c();
        mDirectDebitObject.mDirectDebit.RecordTypeId = recTypeMap.get(Constants.RECORD_TYPE_ACTIVE).Id;
        mDirectDebitObject.mDirectDebit.Lending_Application_Number__c = mApplication.Id;
        mDirectDebitObject.mDirectDebit.Debit_Amount_Source__c = null;
        //if there is only one customer assign it by default
        if (mCustomerMap.size() == 1){
            mDirectDebitObject.mDirectDebit.Customer_Reference_Number__c = mCustomerMap.values().get(0).Id;
        } else {
            for (Customer_Customer__c customer : mCustomerMap.values()){
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
