public with sharing class PayoffQuoteListController {

    public Id mContractId {get;set;}
    public Id mSelectedRecordId {get;set;}
    
    public List<Contract_Payoff_Quote__c> getPayoffQuoteList(){
        List<Schema.FieldSetMember> listViewFields = Schema.SObjectType.Contract_Payoff_Quote__c.fieldSets.List_View_Fields.getFields();
        Set<String> listFieldSet = ContractRelatedRecordQueryUtil.getFieldSet(listViewFields);
        List<Contract_Payoff_Quote__c> payoffQuoteList = ContractRelatedRecordQueryUtil.getPayoffQuotesMap(new Set<Id>{mContractId}, listFieldSet, false).get(mContractId);
        return payoffQuoteList;
    }

    public PageReference onDelete(){
        if (!Schema.SObjectType.Contract_Payoff_Quote__c.isDeletable()
                || mSelectedRecordId == null){ return null; }

        List<Contract_Payoff_Quote__c> payoffQuoteToBeDeleted = 
                                        [SELECT Id FROM Contract_Payoff_Quote__c
                                          WHERE Id = :mSelectedRecordId];
        
        fsCore.DMLResult delResult = PayoffQuoteDMLWrapper.getInstance().deleteData(payoffQuoteToBeDeleted);
        if (delResult.hasErrors()){ delResult.throwError(); }

        return new PageReference('/' + mContractId);
    }
}
