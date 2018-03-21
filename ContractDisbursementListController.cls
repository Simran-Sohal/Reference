public with sharing class ContractDisbursementListController {

    public Id mContractId {get;set;}
    public Id mSelectedRecordId {get;set;}
    
    public List<Contract_Disbursement__c> getDisbursementList(){
        List<Schema.FieldSetMember> listViewFields = Schema.SObjectType.Contract_Disbursement__c.fieldSets.List_View_Fields.getFields();
        Set<String> listFieldSet = ContractRelatedRecordQueryUtil.getFieldSet(listViewFields);
        listFieldSet.add('fsserv__is_processed__c'); //DO NOT CHANGE
        
        List<Contract_Disbursement__c> disbursementList = ContractRelatedRecordQueryUtil.getDisbursementsMap(new Set<Id>{mContractId}, listFieldSet).get(mContractId);
        return disbursementList;
    }

    public PageReference onDelete(){
        if (!Schema.SObjectType.Contract_Disbursement__c.isDeletable()
                || mSelectedRecordId == null){ return null; }

        List<Contract_Disbursement__c> disbursementToBeDeleted = 
                                        [SELECT Id FROM Contract_Disbursement__c
                                          WHERE Id = :mSelectedRecordId];
        
        fsCore.DMLResult delResult = ContractDisbursementDMLWrapper.getInstance().deleteData(disbursementToBeDeleted);
        if (delResult.hasErrors()){ delResult.throwError(); }

        return new PageReference('/' + mContractId);
    }
}
