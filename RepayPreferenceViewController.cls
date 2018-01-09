public with sharing class RepayPreferenceViewController{

    private Id mApplicationId;
    private List<LendingApplicationHolidayPrefObject> mHolidayPrefList;
    private List<LendingApplicationPaymentPrefObject> mPaymentPrefList;
    private List<LendingApplicationRatePrefObject> mRatePrefList;
    
    public RepayPreferenceViewController(ApexPages.StandardController pStdController){
        Lending_Application__c application = (Lending_Application__c)pStdController.getRecord();
        mHolidayPrefList = new List<LendingApplicationHolidayPrefObject>();
        mPaymentPrefList = new List<LendingApplicationPaymentPrefObject>();
        mRatePrefList = new List<LendingApplicationRatePrefObject>();
        
        if (application.Id != null){
            mApplicationId = application.Id;
            setHolidayPreferences();
            setPaymentPreferences();
            setRatePreferences();
        }
    }

    private void setHolidayPreferences(){
        mHolidayPrefList = LendingApplicationRepaymentUtil.getHolidayPreferenceObjectList(mApplicationId);    
    }
    private void setPaymentPreferences(){
        mPaymentPrefList = LendingApplicationRepaymentUtil.getPaymentPreferenceObjectList(mApplicationId);
    }
    private void setRatePreferences(){
        mRatePrefList = LendingApplicationRepaymentUtil.getRatePreferenceObjectList(mApplicationId);
    }

    public Id getApplicationId(){
        return mApplicationId;
    }
    public List<LendingApplicationHolidayPrefObject> getHolidayPreferences(){
        return mHolidayPrefList;
    }
    public List<LendingApplicationPaymentPrefObject> getPaymentPreferences(){
        return mPaymentPrefList;
    }
    public List<LendingApplicationRatePrefObject> getRatePreferences(){
        return mRatePrefList;
    }
}
