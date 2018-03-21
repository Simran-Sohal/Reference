public with sharing class PaymentInboundListController{
    
    public Id mContractId {get;set;}
    private List<Inbound_Payment__c> mInboundPmtList;
    private List<Inbound_Payment__c> mInboundPmtDisplayList;
   
    private List<SelectOption> mDisplayRecordSizeList;
     
    private Integer mRecordSize = fsCore.SystemPreferencesSettingsUtil.getDefaultDisplayRecordSize();
    private Integer mStartIndex = 1;
    private Integer mEndIndex; 
    
    public List<SelectOption> getRecordSizeList(){
        if (mDisplayRecordSizeList == null) { mDisplayRecordSizeList = fsCore.SpectraCoreUtil.getDisplayRecordSizeList(); }
        return mDisplayRecordSizeList;
    }
    
    public Integer getRecordSize(){
        return mRecordSize;
    }    
    
    public void setRecordSize(Integer pRecordSize){
        mRecordSize = pRecordSize;
    }    

    public List<Inbound_Payment__c> getInboundPmtList(){
        setInboundPmtList();
        return mInboundPmtList;
    }
    
    private void setInboundPmtList(){
        if(mInboundPmtList == null){ 
            List<Schema.FieldSetMember> listViewFields = Schema.SObjectType.Inbound_Payment__c.fieldSets.Contract_List_View_Fields.getFields();
            Set<String> listFieldSet = ContractRelatedRecordQueryUtil.getFieldSet(listViewFields);
            mInboundPmtList = ContractRelatedRecordQueryUtil.getInboundPaymentsMap(new Set<Id>{mContractId}, listFieldSet).get(mContractId);
            System.debug(loggingLevel.ERROR, '--- Total Payments : ' + mInboundPmtList.size());
        }
    }
    
    public List<Inbound_Payment__c> getInboundPmtDisplayList(){
        setInboundPmtDisplayList();
        System.debug(loggingLevel.ERROR, '--- Payment Display List size : ' + mInboundPmtDisplayList.size());
        return mInboundPmtDisplayList;
    }
    
    private void setInboundPmtDisplayList(){
        setInboundPmtList();

        setIndicies();

        Map<Integer, Inbound_Payment__c> paymentIndexMap = new Map<Integer, Inbound_Payment__c>();
        Integer paymentNumber = 1;
        for (Inbound_Payment__c payment : mInboundPmtList){
            paymentIndexMap.put(paymentNumber, payment);
            paymentNumber++;
        }
        
        mInboundPmtDisplayList = new List<Inbound_Payment__c>();
        for (Integer i = mStartIndex; i <= mEndIndex; i++){
            if (paymentIndexMap.containsKey(i)){
                mInboundPmtDisplayList.add(paymentIndexMap.get(i));
            }
        }
    }

    private void setIndicies(){
        mRecordSize = (mRecordSize == null) ? fsCore.SystemPreferencesSettingsUtil.getDefaultDisplayRecordSize() : mRecordSize;
        mStartIndex = (mStartIndex == null) ? 1 : mStartIndex;
        mEndIndex = (mStartIndex + mRecordSize - 1);
        mEndIndex = (mEndIndex > mInboundPmtList.size()) ? mInboundPmtList.size() : mEndIndex;
    }
    
    public String getDisplayedRecordText(){
        setIndicies();
        String displayRecMsg = (String.valueOf(mStartIndex) + '-' + String.valueOf(mEndIndex)
                                 + fsCore.Constants.WHITE_SPACE + Label.fsCore.Page_of_Title + fsCore.Constants.WHITE_SPACE
                                     + String.valueOf(mInboundPmtList.size()));
        return displayRecMsg;
    }
    
    public PageReference onRecordSizeChange(){
        mStartIndex = 1;
        setInboundPmtDisplayList();

        return null;
    }
    
    public PageReference onPrevious(){
        mStartIndex -= mRecordSize;
        mStartIndex = (mStartIndex < 1) ? 1 : mStartIndex;
        setInboundPmtDisplayList();
        
        return null;
    }
    
    public PageReference onNext(){
        mStartIndex += mRecordSize;
        setInboundPmtDisplayList();
        
        return null;
    }

    public Boolean getDisablePrevious(){
        return (mStartIndex <= 1);
    }
    
    public Boolean getDisableNext(){
        return (mEndIndex >= mInboundPmtList.size());
    }

}
