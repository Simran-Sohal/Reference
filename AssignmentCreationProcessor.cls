public with sharing class AssignmentCreationProcessor{
    private static final String CLASS_NAME = 'AssignmentCreationProcessor';
    
    private Map<String, fsCore__Queue_Assignment_Setup__c> mAssignmentSetupMap;
    private Map<Id, String> mContractToAssignmentMap;

    private Map<Id, Lending_Contract__c> mContractMap;
    private Map<Id, Set<String>> mActiveAssignmentsMap;
    
    private List<Contract_Assignment__c> mNewContractAssignments;
    private Map<Id, fsCore.ErrorObject> mErrorMap;

    public AssignmentCreationProcessor(Map<Id, String> pContractToAssignmentMap){
        mContractToAssignmentMap = pContractToAssignmentMap;
        setAssignmentSetupMap();
    }
    
    private void setAssignmentSetupMap(){
        Set<String> assignCodeSet = new Set<String>(mContractToAssignmentMap.values());
 
        Set<String> allowedLOB = new Set<String>();
        allowedLOB.add(fsCore.Constants.LOB_SERVICING);
        allowedLOB.add(fsCore.Constants.LOB_COLLECTION);
       
        List<fsCore__Queue_Assignment_Setup__c> queueAssignList = 
                                [SELECT Id, fsCore__Assignment_Code__c
                                   FROM fsCore__Queue_Assignment_Setup__c
                                  WHERE fsCore__Assignment_Code__c IN :assignCodeSet
                                    AND fsCore__Line_Of_Business__c IN :allowedLOB
                                    AND fsCore__Is_Active__c = true
                                    AND (fsCore__Object_Name__c = 'fsServ__Lending_Contract__c' OR
                                         fsCore__Object_Name__c = 'fsServ__Contract_Assignment__c')];
        
        mAssignmentSetupMap = new Map<String, fsCore__Queue_Assignment_Setup__c>();
        for (fsCore__Queue_Assignment_Setup__c queueAssign : queueAssignList){
            mAssignmentSetupMap.put(queueAssign.fsCore__Assignment_Code__c, queueAssign);
        }
    }
    
    public void process(){
        prepareMaps();
        
        mErrorMap = new Map<Id, fsCore.ErrorObject>();
        mNewContractAssignments = new List<Contract_Assignment__c>();
        
        //evaluate assignments
        if (mContractToAssignmentMap.size() > 0){
            for (Id contractId : mContractToAssignmentMap.keySet()){
                String assignmentCode = mContractToAssignmentMap.get(contractId);
                
                if (!isValid(contractId, assignmentCode)){ continue; }
                 
                if (mActiveAssignmentsMap.containsKey(contractId)){
                    if (mActiveAssignmentsMap.get(contractId).contains(assignmentCode)){
                        continue; //skip assignment creation because an active assignment record already exists
                    }
                }
                
                Contract_Assignment__c newAssignment = new Contract_Assignment__c();
                newAssignment.Lending_Contract_Number__c = contractId;
                newAssignment.Assignment_Name__c = mAssignmentSetupMap.get(assignmentCode).Id;
                newAssignment.Assigned_On__c = Datetime.now();
                newAssignment.Status__c = Constants.ASSIGNMENT_STATUS_OPEN;
                newAssignment.Is_Assign_Using_Queue_Assignments__c = true;
                
                mNewContractAssignments.add(newAssignment);
            }
        }
        
        //save records
        if (mNewContractAssignments.size() > 0){
            fsCore.DMLResult assgnDMLRslt = ContractAssignmentDMLWrapper.getInstance().insertData(mNewContractAssignments);
            if (assgnDMLRslt.hasErrors()){
                Database.SaveResult[] assgnSaveRslt = assgnDMLRslt.getSaveResult();
                
                for (Integer i = 0; i < assgnSaveRslt.size(); i++){
                    if (!assgnSaveRslt.get(i).isSuccess()){
                        for(Database.Error err : assgnSaveRslt.get(i).getErrors()){
                            addError(mNewContractAssignments.get(i).Lending_Contract_Number__c
                                   , String.valueOf(err.getStatusCode())
                                   , err.getMessage()
                                   , 'process() ... saving records');
                        }
                    }
                }
            }
        }

        //save errors to diagnostic log
        if (mErrorMap.size() > 0){
            fsCore.DiagnosticLogUtil.logErrors(CLASS_NAME, 'process', mErrorMap.values());
        }
    }
    
    private void prepareMaps(){
        mContractMap = new Map<Id, Lending_Contract__c>(
                          [SELECT Id, Name FROM Lending_Contract__c
                            WHERE Id IN :mContractToAssignmentMap.keySet()]);
        
        List<Contract_Assignment__c> activeAssignments
                        = [SELECT Id
                                , Lending_Contract_Number__c
                                , Assignment_Code__c
                             FROM Contract_Assignment__c
                            WHERE Lending_Contract_Number__c IN :mContractToAssignmentMap.keySet()
                              AND Is_Active__c = true
                            ORDER BY Lending_Contract_Number__c, Assigned_On__c]; 
        
        mActiveAssignmentsMap = new Map<Id, Set<String>>();
        
        for (Contract_Assignment__c ctAssgn : activeAssignments){
            Set<String> assignmentCodeSet = new Set<String>();
            
            if (mActiveAssignmentsMap.containsKey(ctAssgn.Lending_Contract_Number__c)){
                assignmentCodeSet = mActiveAssignmentsMap.get(ctAssgn.Lending_Contract_Number__c);
            }
            assignmentCodeSet.add(ctAssgn.Assignment_Code__c);
            mActiveAssignmentsMap.put(ctAssgn.Lending_Contract_Number__c, assignmentCodeSet);
        }
    }
 
    private Boolean isValid(Id pContractId, String pAssignmentCode){
        if (!mContractMap.containsKey(pContractId)){
            addError(pContractId
                   , fsCore.Constants.VALIDATION_FAILURE
                   , String.format(Label.Contract_Not_Found_For_Id, new String[]{pContractId})
                   , 'isValid()');
            return false;
        }
        
        if (mContractMap.containsKey(pContractId) && !mAssignmentSetupMap.containsKey(pAssignmentCode)){
            addError(pContractId
                   , fsCore.Constants.VALIDATION_FAILURE
                   , String.format(Label.Assignment_Not_Found_For_Code, new String[]{pAssignmentCode})
                   , 'isValid()');
            return false;
        }
        return true;
    }
    
    private void addError(Id pContractId, String pErrorCode, String pErrorMsg, String pMethod){
        fsCore.ErrorObject errObj = new fsCore.ErrorObject();
        errObj.setErrorRecordId(pContractId);
        if (mContractMap.containsKey(pContractId)){
            errObj.setErrorRecordName(mContractMap.get(pContractId).Name);
        }
        errObj.setErrorCode(pErrorCode);
        errObj.setErrorMessage(pErrorMsg);
        errObj.setErrorStackTrace(CLASS_NAME + '.' + pMethod);
       
        mErrorMap.put(pContractId, errObj);
    }
}
