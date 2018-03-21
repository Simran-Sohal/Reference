public with sharing class ContractCollateralListController {

    public Id mContractId {get;set;}
    public Id mSelectedRecordId {get;set;}
    
    public List<Contract_Collateral__c> getCollateralList(){
        List<Schema.FieldSetMember> listViewFields = Schema.SObjectType.Contract_Collateral__c.fieldSets.List_View_Fields.getFields();
        Set<String> listFieldSet = ContractRelatedRecordQueryUtil.getFieldSet(listViewFields);

        List<Contract_Collateral__c> collateralList = ContractRelatedRecordQueryUtil.getCollateralsMap(new Set<Id>{mContractId}, listFieldSet).get(mContractId);
        return collateralList;
    }

    public PageReference onDelete(){
        if (!Schema.SObjectType.Contract_Collateral__c.isDeletable()
                || mSelectedRecordId == null){ return null; }

        List<Contract_Collateral__c> collateralToBeDeleted = 
                                        [SELECT Id FROM Contract_Collateral__c
                                          WHERE Id = :mSelectedRecordId];
        
        fsCore.DMLResult delResult = ContractCollateralDMLWrapper.getInstance().deleteData(collateralToBeDeleted);
        if (delResult.hasErrors()){ delResult.throwError(); }

        return new PageReference('/' + mContractId);
    }
}
