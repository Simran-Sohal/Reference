public with sharing class ContractDirectDebitListController {

    public Id mContractId {get;set;}
    public Id mSelectedRecordId {get;set;}
    
    public List<Contract_Direct_Debit__c> getDirectDebitList(){
        List<Schema.FieldSetMember> listViewFields = Schema.SObjectType.Contract_Direct_Debit__c.fieldSets.List_View_Fields.getFields();
        Set<String> listFieldSet = ContractRelatedRecordQueryUtil.getFieldSet(listViewFields);
        List<Contract_Direct_Debit__c> directDebitList = ContractRelatedRecordQueryUtil.getDirectDebitsMap(new Set<Id>{mContractId}, listFieldSet).get(mContractId);
        return directDebitList;
    }

    public PageReference onDelete(){
        if (!Schema.SObjectType.Contract_Direct_Debit__c.isDeletable()
                || mSelectedRecordId == null){ return null; }

        List<Contract_Direct_Debit__c> directDebitToBeDeleted = 
                                        [SELECT Id FROM Contract_Direct_Debit__c
                                          WHERE Id = :mSelectedRecordId];
        
        fsCore.DMLResult delResult = ContractDirectDebitDMLWrapper.getInstance().deleteData(directDebitToBeDeleted);
        if (delResult.hasErrors()){ delResult.throwError(); }

        return new PageReference('/' + mContractId);
    }
}
