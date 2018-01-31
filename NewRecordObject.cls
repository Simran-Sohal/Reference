public with sharing class QueuedTransactionParamObject{

    private Transaction_Processing_Parameter__c mTxnParam;
    private Boolean mIsDateField;
    private Boolean mIsStringField;
    private Boolean mIsNumberField;
    private Boolean mIsBooleanField;
    private Boolean mIsCurrencyField;
    private Boolean mIsReferenceField;
    private List<SelectOption> mListValues;
    
    public QueuedTransactionParamObject(Transaction_Processing_Parameter__c pTxnParam){
        mTxnParam = pTxnParam;
        resetParamProperties();
    }
    
    public void resetParamProperties(){
        mIsDateField = false;
        mIsStringField = false;
        mIsNumberField = false;
        mIsBooleanField = false;
        mIsCurrencyField = false;
        mIsReferenceField = false;
        mListValues = new List<SelectOption>();
    }

    /* Setters */
    public void setAsDateField(){
        mIsDateField = true;
    }
    public void setAsStringField(){
        mIsStringField = true;
    }
    public void setAsNumberField(){
        mIsNumberField = true;
    }
    public void setAsBooleanField(){
        mIsBooleanField = true;
    }
    public void setAsCurrencyField(){
        mIsCurrencyField = true;
    }
    public void setAsReferenceField(){
        mIsReferenceField = true;
    }
    public void setListValues(List<SelectOption> pListValues){
        mListValues = pListValues;
    }

    /* Getters */
    public Transaction_Processing_Parameter__c getTxnParam(){
        return mTxnParam;
    }
    public Boolean getIsDateField(){
        return mIsDateField;
    }
    public Boolean getIsStringField(){
        return mIsStringField;
    }
    public Boolean getIsNumberField(){
        return mIsNumberField;
    }
    public Boolean getIsBooleanField(){
        return mIsBooleanField;
    }
    public Boolean getIsCurrencyField(){
        return mIsCurrencyField;
    }
    public Boolean getIsReferenceField(){
        return mIsReferenceField;
    }
    public Boolean getHasListValues(){
        return (mListValues.size() > 0);
    }
    public List<SelectOption> getListValues(){
        return mListValues;
    }
}
