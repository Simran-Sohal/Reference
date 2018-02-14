public with sharing class ContractStatementController extends ContractRelatedControllerBase{
    private static final String CLASS_NAME = 'ContractStatementController';
    
    public ContractStatementController(ApexPages.StandardController pStdController){
        super(pStdController);
        init();
    }
    
    private void init(){
        setPageSubtitle('Generate Statement');
        
        Map<String,String> pageURLParamMap = ApexPages.currentPage().getParameters();
        //get contract Id
        Id contractId = null;
        if (pageURLParamMap.containsKey('id')){
            contractId = Id.valueOf(pageURLParamMap.get('id'));
        }
        else {
            throw new ServicingException(Label.Parent_Contract_Id_Missing);
        }

        setLendingContract(contractId);
    }

    public override List<fsCore.ErrorObject> saveRecord(){
        return null;
    }
            
    public override String getClassName(){
        return CLASS_NAME;
    }

    public override String getRelatedObjectName(){
        return Schema.SObjectType.Lending_Contract__c.getLabel();
    }   
}
