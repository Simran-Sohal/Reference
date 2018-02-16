public with sharing class DirectDebitEditController extends ContractRelatedControllerBase{
    private static final String CLASS_NAME = 'DirectDebitEditController';

    public Contract_Direct_Debit__c mDirectDebit {get; set;}
    
    private Map<Id, Contract_Customer__c> mCustomerMap;
    public List<SelectOption> mCustomerSelectList {get; private set;}
    
    private Map<Id, fsCore__Bank_Account__c> mBankAccountMap;
    private fsCore__Bank_Account__c mSelectedBankAccount;
    public List<SelectOption> mBankAccountSelectList {get; private set;}
    
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
        setCustomerSelectList();
        
        if(mDirectDebit.Id == null){ //new record
            setDefaultValues();
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
                                                   .getRecordTypeMapByName(Schema.SObjectType.Contract_Direct_Debit__c.getName());
        
        mDirectDebit = new Contract_Direct_Debit__c();
        mDirectDebit.RecordTypeId = recTypeMap.get(fsCore.Constants.RECORD_TYPE_ACTIVE).Id;
        mDirectDebit.Lending_Contract_Number__c = getLendingContract().Id;
        mDirectDebit.Debit_Amount_Source__c = null;
        //assign the primary customer by default
        for (Customer_Customer__c customer : mCustomerMap.values()){
            if (customer.Is_Primary__c){
                mDirectDebit.Customer_Reference_Number__c = customer.Id;
                break;
            }
        }
    }

    private void setBankAccountSelectList(){
        mBankAccountMap = new Map<Id, fsCore__Bank_Account__c>();
        if (mDirectDebit.Customer_Reference_Number__c != null 
                && mCustomerMap.containsKey(mDirectDebit.Customer_Reference_Number__c)){
            Contract_Customer__c customer = mCustomerMap.get(mDirectDebit.Customer_Reference_Number__c);
            if (customer.Account_Name__c != null){
                mBankAccountMap.putAll(fsCore.BankAccountUtil.getAccountBankAccountListMap(new Set<Id>{customer.Account_Name__c}));
            }
            if (customer.Contact_Name__c != null){
                mBankAccountMap.putAll(fsCore.BankAccountUtil.getContactBankAccountListMap(new Set<Id>{customer.Contact_Name__c}));
            }
        }

        mBankAccountSelectList = fsCore.BankAccountUtil.getBankAccountSelectList(mBankAccountMap.values());
        
        if (mDirectDebit.Bank_Account_Name__c == null){
            for (fsCore__Bank_Account__c bankAcct : mBankAccountMap.values()){
                if (bankAcct.fsCore__Is_Primary__c){
                    mDirectDebit.Bank_Account_Name__c = bankAcct.Id;
                    break;
                }
            }
        }
    }
    
    private void setSelectedBankAccount(){
        if (mDirectDebit.Bank_Account_Name__c != null && mBankAccountMap.containsKey(mDirectDebit.Bank_Account_Name__c)){
            mSelectedBankAccount = mBankAccountMap.get(mDirectDebit.Bank_Account_Name__c);
        } else {
            mDirectDebit.Bank_Account_Name__c = null;
            mSelectedBankAccount = getBlankBankAccount();
        }
    }    
    
    public PageReference onCustomerChange(){
        setBankAccountSelectList();
        setSelectedBankAccount();
        return null;
    }

    public PageReference onBankAccountChange(){
        setSelectedBankAccount();
        return null;
    }
    
    public PageReference onAmountSourceChange(){
        if (String.IsNotBlank(mDirectDebit.Debit_Amount_Source__c) && mDirectDebit.Debit_Amount_Source__c.equalsIgnoreCase(Constants.DEBIT_AMOUNT_SOURCE_REPAYMENT)){
            mDirectDebit.Debit_Amount__c = getLendingContract().Current_Payment_Amount__c;
        }
        else if (String.IsNotBlank(mDirectDebit.Debit_Amount_Source__c) && mDirectDebit.Debit_Amount_Source__c.equalsIgnoreCase(Constants.DEBIT_AMOUNT_SOURCE_TOTAL_DUE)){
            mDirectDebit.Debit_Amount__c = getLendingContract().Total_Due_Amount__c;
        }
        return null;
    }

    public fsCore__Bank_Account__c getSelectedBankAccount(){
        return mSelectedBankAccount;
    }
    
    public override List<fsCore.ErrorObject> saveRecord(){
        List<Contract_Direct_Debit__c> directDebitForUpsert = new List<Contract_Direct_Debit__c>();
        directDebitForUpsert.add(mDirectDebit);
        
        List<fsCore.ErrorObject> errorList = new List<fsCore.ErrorObject>();
        fsCore.DMLResult directDebitSaveRslt = ContractDirectDebitDMLWrapper.getInstance().upsertData(directDebitForUpsert);
        if (directDebitSaveRslt.hasErrors()) { errorList = directDebitSaveRslt.getErrorList(); }
        super.setContextRecordId(mDirectDebit.Id);

        return errorList;
    }
    
    public override String getClassName(){
        return CLASS_NAME;
    }

    public override PageReference getReturnPageURL(){
        return new PageReference('/' + Schema.sObjectType.Lending_Contract__c.getKeyPrefix() + '/l');
    }     
}
