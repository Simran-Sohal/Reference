public with sharing class ContractStageHistoryController{

    public Id mContractId {get;set;}
    public Id mSelectedRecordId {get;set;}
    
    public List<Contract_Stage__c> getStageHistoryList(){
        List<Schema.FieldSetMember> listViewFields = Schema.SObjectType.Contract_Stage__c.fieldSets.List_View_Fields.getFields();
        Set<String> listFieldSet = ContractRelatedRecordQueryUtil.getFieldSet(listViewFields);
        listFieldSet.add('fsserv__is_active__c');
        
        List<Contract_Stage__c> stageHistoryList = ContractRelatedRecordQueryUtil.getStagesMap(new Set<Id>{mContractId}, listFieldSet).get(mContractId);
        return stageHistoryList;
    }

    public PageReference onDelete(){
        if (!Schema.SObjectType.Contract_Stage__c.isDeletable()
                || mSelectedRecordId == null){ return null; }

        List<Contract_Stage__c> stageToBeDeleted = 
                                        [SELECT Id FROM Contract_Stage__c
                                          WHERE Id = :mSelectedRecordId];
        
        fsCore.DMLResult delResult = ContractStageDMLWrapper.getInstance().deleteData(stageToBeDeleted);
        if (delResult.hasErrors()){ delResult.throwError(); }

        return new PageReference('/' + mContractId);
    }
}
