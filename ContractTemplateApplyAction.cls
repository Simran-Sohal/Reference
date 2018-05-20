public with sharing class ContractTemplateApplyAction{

    private Map<Id, Lending_Application__c> mApplicationMap;
    private Map<Id, Id> mApplicationToSelectedContractTemplateMap;
    private Map<Id, Contract_Template_Setup__c> mContractTemplateMap;
    private Map<Id, List<Contract_Template_Itemization_Setup__c>> mContractTemplateItemizationsMap;
    private Map<Id, List<Contract_Template_Fee_Setup__c>> mContractTemplateFeesMap;
    
    
    
    public ContractTemplateApplyAction(Lending_Application__c pApplication
                                     , Id pSelectedContractTemplateId){
        mApplicationMap = new Map<Id, Lending_Application__c>();
        mApplicationMap.put(pApplication.Id, pApplication);
        
        mApplicationToSelectedContractTemplateMap = new Map<Id, Id>();
        mApplicationToSelectedContractTemplateMap.put(pApplication.Id, pSelectedContractTemplateId);
        init();
    }

    public ContractTemplateApplyAction(Map<Id, Lending_Application__c> pApplicationMap
                                     , Map<Id, Id> pApplicationToSelectedContractTemplateMap){
        mApplicationMap = pApplicationMap;
        mApplicationToSelectedContractTemplateMap = pApplicationToSelectedContractTemplateMap;
        init();
    }

    private void init(){
        Set<Id> contractTemplateIdSet = new Set<Id>(mApplicationToSelectedContractTemplateMap.values());
        List<Contract_Template_Setup__c> contractTemplateList = 
                    (List<Contract_Template_Setup__c>)SObjectQueryUtil.getSObjectRecordListById(
                                                        Schema.SObjectType.Contract_Template_Setup__c.getName()
                                                      , contractTemplateIdSet);
        
        mContractTemplateMap = new Map<Id, Contract_Template_Setup__c>(contractTemplateList);
    
    
    }

    public void process(){
        for (Lending_Application__c application : mApplicationMap.values()){
            if (mApplicationToSelectedContractTemplateMap.containsKey(application.Id)
                  && mContractTemplateMap.containsKey(mApplicationToSelectedContractTemplateMap.get(application.Id))){
                Contract_Template_Setup__c contractTemplate = mContractTemplateMap.get(mApplicationToSelectedContractTemplateMap.get(application.Id));
                
                //copy contract template details
                LendingApplicationUtil.copyContractTemplateToApplication(contractTemplate, application);  
            
                //add itemizations
                if (mContractTemplateItemizationsMap.containsKey(contractTemplate.Id)){
                
                }
                
                //add contractual fees
                if (mContractTemplateFeesMap.containsKey(contractTemplate.Id)){
                
                }
            }
            else {
                LendingApplicationUtil.clearContractTemplateInfo(application);
            }
        }
    }
}
