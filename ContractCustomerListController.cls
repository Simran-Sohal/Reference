public with sharing class ContractCustomerListController {

    public Id mContractId {get;set;}
    public Id mSelectedRecordId {get;set;}
    
    public List<Contract_Customer__c> getCustomerList(){
        List<Schema.FieldSetMember> listViewFields = Schema.SObjectType.Contract_Customer__c.fieldSets.List_View_Fields.getFields();
        Set<String> listFieldSet = ContractRelatedRecordQueryUtil.getFieldSet(listViewFields);
        List<Contract_Customer__c> customerList = ContractRelatedRecordQueryUtil.getCustomersMap(new Set<Id>{mContractId}, listFieldSet).get(mContractId);
        return customerList;
    }

    public PageReference onDelete(){
        if (!Schema.SObjectType.Contract_Customer__c.isDeletable()
                || mSelectedRecordId == null){ return null; }

        List<Contract_Customer__c> customerToBeDeleted = 
                                        [SELECT Id FROM Contract_Customer__c
                                          WHERE Id = :mSelectedRecordId];
        
        fsCore.DMLResult delResult = ContractCustomerDMLWrapper.getInstance().deleteData(customerToBeDeleted);
        if (delResult.hasErrors()){ delResult.throwError(); }

        return new PageReference('/' + mContractId);
    }
}
