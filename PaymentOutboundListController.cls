public with sharing class PaymentOutboundListController{
    
    public Id mContractId {get;set;}
    private List<fsCore__Outbound_Payment__c> mOutboundPmtList;
    private List<fsCore__Outbound_Payment__c> mOutboundPmtDisplayList;
   
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

    public List<fsCore__Outbound_Payment__c> getOutboundPmtList(){
        setOutboundPmtList();
        system.debug(loggingLevel.ERROR, '-- Outbound Payments count : ' + mOutboundPmtList.size());
        return mOutboundPmtList;
    }
    
    private void setOutboundPmtList(){
        if(mOutboundPmtList == null){ 
            List<Schema.FieldSetMember> listViewFields = Schema.SObjectType.fsCore__Outbound_Payment__c.fieldSets.Contract_List_View_Fields.getFields();
            Set<String> listFieldSet = ContractRelatedRecordQueryUtil.getFieldSet(listViewFields);
            system.debug(loggingLevel.ERROR, '-- fetching outbound payments for contract ' + mContractId);
            mOutboundPmtList = ContractRelatedRecordQueryUtil.getOutboundPaymentsMap(new Set<Id>{mContractId}, listFieldSet).get(mContractId);
        }
    }
    
    public List<fsCore__Outbound_Payment__c> getOutboundPmtDisplayList(){
        setOutboundPmtDisplayList();
        return mOutboundPmtDisplayList;
    }
    
    private void setOutboundPmtDisplayList(){
        setOutboundPmtList();

        setIndicies();

        Map<Integer, fsCore__Outbound_Payment__c> paymentIndexMap = new Map<Integer, fsCore__Outbound_Payment__c>();
        Integer paymentNumber = 1;
        for (fsCore__Outbound_Payment__c payment : mOutboundPmtList){
            paymentIndexMap.put(paymentNumber, payment);
            paymentNumber++;
        }
        
        mOutboundPmtDisplayList = new List<fsCore__Outbound_Payment__c>();
        for (Integer i = mStartIndex; i <= mEndIndex; i++){
            if (paymentIndexMap.containsKey(i)){
                mOutboundPmtDisplayList.add(paymentIndexMap.get(i));
            }
        }
    }

    private void setIndicies(){
        mRecordSize = (mRecordSize == null) ? fsCore.SystemPreferencesSettingsUtil.getDefaultDisplayRecordSize() : mRecordSize;
        mStartIndex = (mStartIndex == null) ? 1 : mStartIndex;
        mEndIndex = (mStartIndex + mRecordSize - 1);
        mEndIndex = (mEndIndex > mOutboundPmtList.size()) ? mOutboundPmtList.size() : mEndIndex;
    }
    
    public String getDisplayedRecordText(){
        setIndicies();
        String displayRecMsg = (String.valueOf(mStartIndex) + '-' + String.valueOf(mEndIndex)
                                 + fsCore.Constants.WHITE_SPACE + Label.fsCore.Page_of_Title + fsCore.Constants.WHITE_SPACE
                                     + String.valueOf(mOutboundPmtList.size()));
        return displayRecMsg;
    }
    
    public PageReference onRecordSizeChange(){
        mStartIndex = 1;
        setOutboundPmtDisplayList();

        return null;
    }
    
    public PageReference onPrevious(){
        mStartIndex -= mRecordSize;
        mStartIndex = (mStartIndex < 1) ? 1 : mStartIndex;
        setOutboundPmtDisplayList();
        
        return null;
    }
    
    public PageReference onNext(){
        mStartIndex += mRecordSize;
        setOutboundPmtDisplayList();
        
        return null;
    }

    public Boolean getDisablePrevious(){
        return (mStartIndex <= 1);
    }
    
    public Boolean getDisableNext(){
        return (mEndIndex >= mOutboundPmtList.size());
    }

}
