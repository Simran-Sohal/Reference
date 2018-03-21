public with sharing class ContractInvestmentListController {

    public Id mContractId {get;set;}
    public Id mSelectedRecordId {get;set;}
    
    public List<Contract_Investment__c> getInvestmentList(){
        List<Schema.FieldSetMember> listViewFields = Schema.SObjectType.Contract_Investment__c.fieldSets.List_View_Fields.getFields();
        Set<String> listFieldSet = ContractRelatedRecordQueryUtil.getFieldSet(listViewFields);
        List<Contract_Investment__c> investmentList = ContractRelatedRecordQueryUtil.getInvestmentsMap(new Set<Id>{mContractId}, listFieldSet).get(mContractId);
        return investmentList;
    }

    public PageReference onDelete(){
        if (!Schema.SObjectType.Contract_Investment__c.isDeletable()
                || mSelectedRecordId == null){ return null; }

        List<Contract_Investment__c> investmentToBeDeleted = 
                                        [SELECT Id FROM Contract_Investment__c
                                          WHERE Id = :mSelectedRecordId];
        
        fsCore.DMLResult delResult = ContractInvestmentDMLWrapper.getInstance().deleteData(investmentToBeDeleted);
        if (delResult.hasErrors()){ delResult.throwError(); }

        return new PageReference('/' + mContractId);
    }
}
