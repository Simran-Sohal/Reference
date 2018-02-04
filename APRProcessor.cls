public with sharing class APRProcessor implements fsCore.ActionProcessor{

    private fsCore.ActionInput mInput;
    private fsCore.ActionOutput mOutput;
    
    private Map<Id, Lending_Contract__c> mContractMap;
    private Map<Id, List<Contract_Repayment__c>> mContractRepaymentsMap;
    private List<Lending_Contract__c> mContractForUpdate;
    
    public APRProcessor(){
        mInput = new fsCore.ActionInput();
        mOutput = new fsCore.ActionOutput();
    }
    
    public void setInput(fsCore.ActionInput pInput){
        mInput = pInput;
    }
    
    public void process(){
        mContractMap = LendingContractUtil.getLendingContracts(mInput.getRecords());
        mContractRepaymentsMap = ContractRelatedRecordQueryUtil.getRepaymentsMap(mInput.getRecords());
        
        mContractForUpdate = new List<Lending_Contract__c>();
        for(Lending_Contract__c contract : mContractMap.values()){
            if (contract.Product_Family__c.equalsIgnoreCase(fsCore.Constants.PRODUCT_FAMILY_LOAN)){
                calculateAPR(contract);
            }
        }
        
        if (mContractForUpdate.size() > 0){
            fsCore.DMLResult updateResult = LendingContractDMLWrapper.getInstance().updateData(mContractForUpdate);
            if (updateResult.hasErrors()){ addErrors(updateResult.getErrorList()); }
        }
    }
    
    private void calculateAPR(Lending_Contract__c pContract){
        CalculatorBuilder calcBuilder = new CalculatorBuilder(pContract);
        calcBuilder.setCalculator(fsCore.Constants.CALCULATE_APR);
        calcBuilder.setRepaymentDetails(mContractRepaymentsMap.get(pContract.Id));
        
        fsCore.CalculatorObject calcObj = calcBuilder.getCalculatorObject();
        calcObj = fsCore.Calculator.calculate(calcObj);
        
        if (!calcObj.getIsSuccess()){
            String errMsg = (calcObj.getErrorStack().size() > 0) ? calcObj.getErrorStack().get(0) : 'APR Calculation failed';
            addError(pContract.Id, errMsg, 'CALCULATION_ERROR');
        }
        else {
            pContract.Current_Annual_Percent_Rate__c = calcObj.getCalculatorMain().fsCore__Annual_Percent_Rate__c;
            mContractForUpdate.add(pContract);
        }
    }

    public fsCore.ActionOutput getOutput(){
        return mOutput;
    }

    private void addError(Id pContractId, String pErrorMsg, String pErrorCode){
        fsCore.ErrorObject errObj = new fsCore.ErrorObject();
        errObj.setErrorRecordId(pContractId);
        errObj.setErrorRecordName(mContractMap.get(pContractId).Name);
        errObj.setErrorMessage(pErrorMsg);
        errObj.setErrorCode(pErrorCode);
        
        mOutput.addError(errObj);
    }
    
    private void addErrors(List<fsCore.ErrorObject> pErrorList){
        for(fsCore.ErrorObject errObj : pErrorList){
            if (errObj.getErrorRecordId() != null && mContractMap.containsKey(errObj.getErrorRecordId())){
                errObj.setErrorRecordName(mContractMap.get(errObj.getErrorRecordId()).Name);
            }
            mOutput.addError(errObj);
        }
    }
    
}
