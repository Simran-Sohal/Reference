public with sharing class APRProcessor implements fsCore.ActionProcessor{

    private fsCore.ActionInput mActionInput;
    private fsCore.ActionOutput mActionOutput;
    
    private Map<Id, Lending_Contract__c> mContractMap;
    
    public APRProcessor(){
        mActionInput = new fsCore.ActionInput();
        mActionOutput = new fsCore.ActionOutput();
        mContractMap = new Map<Id, Lending_Contract__c>();
    }
    
    public void setInput(fsCore.ActionInput pInput){
        mActionInput = pInput;
    }
    
    public void process(){
    }

    public fsCore.ActionOutput getOutput(){
        return mActionOutput;
    }

}
