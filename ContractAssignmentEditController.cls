public with sharing class ContractAssignmentEditController extends ContractRelatedControllerBase{
    private static final String CLASS_NAME = 'ContractAssignmentEditController';
    
    public Contract_Assignment__c mAssignment {get; set;}
    public List<SelectOption> mAssignmentSelectList {get; private set;}
    private Map<Id, fsCore__Queue_Assignment_Setup__c> mAvailableAssignmentMap;
         
    public ContractAssignmentEditController(ApexPages.StandardController pStdController){
        super(pStdController);
        this.mAssignment = (Contract_Assignment__c)pStdController.getRecord();
        init();
    }
    
    private void init(){
        if (this.mAssignment.Id != null){
            this.mAssignment = (Contract_Assignment__c) fsCore.SObjectQueryUtil.getSObjectRecord(this.mAssignment.Id);
            setPageSubtitle(Contract_Assignment__c.Name.getDescribe().getLabel() + this.mAssignment.Name);
        }
        
        Map<String,String> pageURLParamMap = ApexPages.currentPage().getParameters();
        //get contract Id
        Id contractId;
        if (pageURLParamMap.containsKey('parentId')){
            contractId = Id.valueOf(pageURLParamMap.get('parentId'));
        }
        else if (this.mAssignment.Lending_Contract_Number__c != null){
            contractId = this.mAssignment.Lending_Contract_Number__c;
        } 
        
        mAssignmentSelectList = fsCore.SpectraCoreUtil.getBlankList();

        if (contractId != null){
            if (mAssignment.Id == null){ 
                mAssignment.Lending_Contract_Number__c = contractId;
                mAssignment.Assigned_On__c = Datetime.now();
            }
            setLendingContract(contractId);
            getAvailableAssignments();
        }        
    }
    
    public PageReference onContractChange(){
        if (mAssignment.Lending_Contract_Number__c != null){
            setLendingContract(mAssignment.Lending_Contract_Number__c);
            getAvailableAssignments();
            if (mAssignment.Id == null){ 
                mAssignment.Assigned_On__c = Datetime.now();
            }
        }
        else {
            mAssignmentSelectList = fsCore.SpectraCoreUtil.getBlankList();
        }
        return null;
    }
    
    private void getAvailableAssignments(){
        fsCore.MappingEvaluationInputObject contractMappEvalObj = LendingContractUtil.getMappingEvalInput(getLendingContract(), getBusinessDate());
        Map<String, fsCore.MappingEvaluationInputObject> mappingEvalInputMap = new Map<String, fsCore.MappingEvaluationInputObject>();
        mappingEvalInputMap.put(String.valueOf(getLendingContract().Id), contractMappEvalObj);
        
        fsCore.SetupMappingEvaluator assignmentSetupMappEval = new fsCore.SetupMappingEvaluator(mappingEvalInputMap
                                                                             , Schema.SObjectType.fsCore__Queue_Assignment_Setup__c.getName()
                                                                             , getLendingContract().Product_Family__c);
                                                                              
        Set<Id> availableAssignmentIdSet = assignmentSetupMappEval.evaluate().get(String.valueOf(getLendingContract().Id));
        List<fsCore__Queue_Assignment_Setup__c> availableAssignmentList = 
                                (List<fsCore__Queue_Assignment_Setup__c>) assignmentSetupMappEval.getSetupRecords(availableAssignmentIdSet);
        
        mAvailableAssignmentMap = new Map<Id, fsCore__Queue_Assignment_Setup__c >(availableAssignmentList);
        if (mAvailableAssignmentMap.size() > 0){
            mAssignmentSelectList = new List<SelectOption>();
            mAssignmentSelectList.add(new SelectOption(Constants.BLANK_STRING, Label.fsCore.List_Option_Select_Value));
    
            for (fsCore__Queue_Assignment_Setup__c assignment : mAvailableAssignmentMap.values()){
                mAssignmentSelectList.add(new SelectOption(assignment.Id, assignment.Name));
            }
        }    
    }
    
    public override List<fsCore.ErrorObject> saveRecord(){
        List<fsCore.ErrorObject> errorList = new List<fsCore.ErrorObject>();
        
        fsCore.DMLResult assgnSaveRslt = ContractAssignmentDMLWrapper.getInstance().upsertData(new List<Contract_Assignment__c>{mAssignment});
        if (assgnSaveRslt.hasErrors()) { errorList = assgnSaveRslt.getErrorList(); }
        super.setContextRecordId(mAssignment.Id);

        return errorList;
    }
    
    public override String getClassName(){
        return CLASS_NAME;
    }

    public override String getRelatedObjectName(){
        return Schema.SObjectType.Contract_Assignment__c.getLabel();
    }

}
