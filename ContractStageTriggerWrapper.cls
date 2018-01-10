global with sharing class ContractStageTriggerWrapper extends fsCore.TriggerWrapperBase{
    private static final String CLASS_NAME = 'ContractStageTriggerWrapper';
    private static final String TRIGGER_NAME = 'ContractStageTrigger';

    private ContractStageTriggerWrapper(){
        super.setTriggerDetails(TRIGGER_NAME);
    }

    private static ContractStageTriggerWrapper mInstance = null;

    /* Method to get the only instance available */
    global static ContractStageTriggerWrapper getInstance(){
        if (mInstance == null) mInstance = new ContractStageTriggerWrapper();
        return mInstance;
    }

    global override void beforeInsert(List<sObject> pNewRecList) {}

    global override void beforeUpdate(List<sObject> pNewRecList
                                    , List<sObject> pOldRecList
                                    , Map<Id, sObject> pNewRecMap
                                    , Map<Id, sObject> pOldRecMap) {}

    global override void beforeDelete(List<sObject> pOldRecList
                                    , Map<Id, sObject> pOldRecMap) {}

    global override void afterInsert(List<sObject> pNewRecList
                                   , Map<Id, sObject> pNewRecMap) {}

    global override void afterUpdate(List<sObject> pNewRecList
                                   , List<sObject> pOldRecList
                                   , Map<Id, sObject> pNewRecMap
                                   , Map<Id, sObject> pOldRecMap) {}

    global override void afterDelete(List<sObject> pOldRecList
                                   , Map<Id, sObject> pOldRecMap) {}

    global override void afterUndelete(List<sObject> pNewRecList
                                     , Map<Id, sObject> pNewRecMap) {}

}
