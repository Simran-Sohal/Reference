public with sharing class ContractFeeListController {

    public Id mContractId {get;set;}
    public Id mSelectedRecordId {get;set;}
    
    public List<Contract_Fee__c> getFeeList(){
        List<Schema.FieldSetMember> listViewFields = Schema.SObjectType.Contract_Fee__c.fieldSets.List_View_Fields.getFields();
        Set<String> listFieldSet = ContractRelatedRecordQueryUtil.getFieldSet(listViewFields);
        
        List<Contract_Fee__c> feeList = ContractRelatedRecordQueryUtil.getContractFeesWithTiersMap(new Set<Id>{mContractId}, listFieldSet).get(mContractId);
        return feeList;
    }

    public PageReference onDelete(){
        if (!Schema.SObjectType.Contract_Fee__c.isDeletable()
                || mSelectedRecordId == null){ return null; }

        List<Contract_Fee__c> contractFeeToBeDeleted = 
                                        [SELECT Id FROM Contract_Fee__c
                                          WHERE Id = :mSelectedRecordId];
        
        fsCore.DMLResult delResult = ContractFeeDMLWrapper.getInstance().deleteData(contractFeeToBeDeleted);
        if (delResult.hasErrors()){ delResult.throwError(); }

        return new PageReference('/' + mContractId);
    }
}
