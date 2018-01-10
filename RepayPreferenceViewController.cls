public with sharing class RepayPreferenceViewController{

    private Id mContractId;
    private List<Contract_Rate_Preference__c> mRatePreferenceList;
    private List<Contract_Payment_Preference__c> mPaymentPreferenceList;
    
    public RepayPreferenceViewController(ApexPages.StandardController pStdController){
        Lending_Contract__c contract = (Lending_Contract__c)pStdController.getRecord();
        mRatePreferenceList = new List<Contract_Rate_Preference__c>();
        mPaymentPreferenceList = new List<Contract_Payment_Preference__c>();
        
        if (contract.Id != null){
            mContractId = contract.Id;
            setRatePreferences();
            setPaymentPreferences();
        }
    }

    private void setRatePreferences(){
        mRatePreferenceList = ContractRelatedRecordQueryUtil.getRatePreferences(mContractId);
    }
    private void setPaymentPreferences(){
        mPaymentPreferenceList = ContractRelatedRecordQueryUtil.getPaymentPreferences(mContractId);
    }
    
    public Id getContractId(){
        return mContractId;
    }
    public List<Contract_Rate_Preference__c> getRatePreferences(){
        return mRatePreferenceList;
    }
    public List<Contract_Payment_Preference__c> getPaymentPreferences(){
        return mPaymentPreferenceList;
    }
}
