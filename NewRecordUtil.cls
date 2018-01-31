  public with sharing class QueuedTransactionParamUtil{

    public static List<QueuedTransactionParamObject> getParameterObjectList(Transaction_Processing_Queue__c pQueuedTxn
                                                                          , TransactionSetupObject pTxnSetupObject){

        List<Transaction_Processing_Parameter__c> txnParamList = new List<Transaction_Processing_Parameter__c>();
        if (pQueuedTxn.Id == null){
            if (pTxnSetupObject != null && pTxnSetupObject.mTransactionParameterSetupList.size() > 0){
                for(TransactionSetupObject.TransactionParameterSetup txnParamSetup : pTxnSetupObject.mTransactionParameterSetupList){
                    txnParamList.add(getNewParamInstance(txnParamSetup));
                }
            }
        }
        else {
            txnParamList = TransactionProcessingQueryUtil.getTransactionQueueParametersMap(new Set<Id>{pQueuedTxn.Id}).get(pQueuedTxn.Id);
        }
    
        return getParameterObjectList(txnParamList);
    }
    
    public static List<QueuedTransactionParamObject> getParameterObjectList(List<Transaction_Processing_Parameter__c> pTxnParamList){
        Set<Id> txnParamFieldIdSet = new Set<Id>();
        for(Transaction_Processing_Parameter__c param : pTxnParamList){
            txnParamFieldIdSet.add(param.Transaction_Parameter_Field_ID__c);
        }
    
        //get transaction parameter field metedata details
        Map<Id, fsCore.TransactionParamMetadataObject> txnParamMDTMap 
                                = fsCore.TransactionParamMetadataUtil.getTransactionParamFieldObjects(txnParamFieldIdSet);
    
        Set<String> objectNameSet = new Set<String>();
        for (fsCore.TransactionParamMetadataObject txnParamMDTObj : txnParamMDTMap.values()){
            objectNameSet.add(txnParamMDTObj.getObjectName());
        }
        
        //get object describe result
        Map<String, Schema.DescribeSObjectResult> objectDescMap = fsCore.MetadataUtil.getSObjectDescribeMap(objectNameSet);
        
        //get object to its fields descrive result map
        Map<String, Map<String, Schema.DescribeFieldResult>> objectToFieldDescMap
                                = new Map<String, Map<String, Schema.DescribeFieldResult>>();
        for (String objectName : objectNameSet){
            Map<String, Schema.DescribeFieldResult> fieldDescMap = fsCore.MetadataUtil.getSObjectFields(objectDescMap.get(objectName));
            objectToFieldDescMap.put(objectName, fieldDescMap);
        }
        
        Map<Schema.DisplayType, String> displayTypeToFieldTypeMap = fsCore.TypeUtil.getDisplayTypeToFieldTypeMap();

        List<QueuedTransactionParamObject> txnParamObjectList = new List<QueuedTransactionParamObject>();

        for (Transaction_Processing_Parameter__c param : pTxnParamList){
            QueuedTransactionParamObject txnParamObj = new QueuedTransactionParamObject(param);
            txnParamObj.getTxnParam().Object_Name__c = txnParamMDTMap.get(param.Transaction_Parameter_Field_ID__c).getObjectName();
            txnParamObj.getTxnParam().Field_Name__c = txnParamMDTMap.get(param.Transaction_Parameter_Field_ID__c).getFieldName();
            txnParamObj.getTxnParam().Data_Type__c = null;
            
            Schema.DescribeFieldResult paramFieldDesc =  objectToFieldDescMap.get(param.Object_Name__c).get(param.Field_Name__c);
            if (paramFieldDesc != null){
                String fieldType = displayTypeToFieldTypeMap.get(paramFieldDesc.getType());
                setDataType(txnParamObj, fieldType);
                
                if (fieldType.equalsIgnoreCase(fsCore.TypeUtil.FIELD_TYPE_PICKLIST)){
                    setPicklistValueSet(txnParamObj, paramFieldDesc.getPicklistValues());
                }
                else if (fieldType.equalsIgnoreCase(fsCore.TypeUtil.FIELD_TYPE_REFERENCE)){
                    //TODO - implement logic to call the builder class to get the list of values
                    //txnParamObj.setListValues(fsCore.SpectraCoreUtil.getBlankList());
                }
            }        
        
            txnParamObjectList.add(txnParamObj);
        }
        
        return txnParamObjectList;
    }

    private static Transaction_Processing_Parameter__c getNewParamInstance(TransactionSetupObject.TransactionParameterSetup pTxnParamSetup){
        Transaction_Processing_Parameter__c param = new Transaction_Processing_Parameter__c();
        param.Name = pTxnParamSetup.mParameterName;
        param.Is_Required__c = pTxnParamSetup.mIsRequired;
        param.Display_Order__c = pTxnParamSetup.mDisplayOrder;
        param.Transaction_Parameter_Field_ID__c = pTxnParamSetup.mFieldId;
        param.Field_Name__c = pTxnParamSetup.mFieldName.toLowerCase();
        param.Object_Name__c = null;
        param.Currency_Value__c = null;
        param.Date_Value__c = null;
        param.Number_Value__c = null;
        param.String_Value__c = null;
        param.Reference_Value_ID__c = null;
        param.Boolean_Value__c = false;
        
        return param;
    }
    
    private static void setDataType(QueuedTransactionParamObject pTxnParamObject
                                  , String pFieldType){
        if (pFieldType.equalsIgnoreCase(fsCore.TypeUtil.FIELD_TYPE_DOUBLE)
                || pFieldType.equalsIgnoreCase(fsCore.TypeUtil.FIELD_TYPE_INTEGER)
                    || pFieldType.equalsIgnoreCase(fsCore.TypeUtil.FIELD_TYPE_PERCENT)){
            pTxnParamObject.getTxnParam().Data_Type__c = fsCore.TypeUtil.DATA_TYPE_NUMBER;
            pTxnParamObject.setAsNumberField();
        }
        else if (pFieldType.equalsIgnoreCase(fsCore.TypeUtil.FIELD_TYPE_STRING)
                    || pFieldType.equalsIgnoreCase(fsCore.TypeUtil.FIELD_TYPE_PICKLIST)){
            pTxnParamObject.getTxnParam().Data_Type__c = fsCore.TypeUtil.DATA_TYPE_STRING;
            pTxnParamObject.setAsStringField();
        }
        else if (pFieldType.equalsIgnoreCase(fsCore.TypeUtil.FIELD_TYPE_CURRENCY)){
            pTxnParamObject.getTxnParam().Data_Type__c = fsCore.TypeUtil.FIELD_TYPE_CURRENCY;
            pTxnParamObject.setAsCurrencyField();
        }
        else if (pFieldType.equalsIgnoreCase(fsCore.TypeUtil.FIELD_TYPE_DATE)){
            pTxnParamObject.getTxnParam().Data_Type__c = fsCore.TypeUtil.DATA_TYPE_DATE;
            pTxnParamObject.setAsDateField();
        }
        else if (pFieldType.equalsIgnoreCase(fsCore.TypeUtil.FIELD_TYPE_REFERENCE)){
            pTxnParamObject.getTxnParam().Data_Type__c = fsCore.TypeUtil.DATA_TYPE_REFERENCE;
            pTxnParamObject.setAsReferenceField();
        }
        else if (pFieldType.equalsIgnoreCase(fsCore.TypeUtil.FIELD_TYPE_BOOLEAN)){
            pTxnParamObject.getTxnParam().Data_Type__c = fsCore.TypeUtil.DATA_TYPE_BOOLEAN;
            pTxnParamObject.setAsBooleanField();
        }
    }

    private static void setPicklistValueSet(QueuedTransactionParamObject pTxnParamObject
                                          , List<Schema.PicklistEntry> pPicklistValues){
        List<SelectOption> picklistValueSet = fsCore.SpectraCoreUtil.getBlankList();
        
        for (Schema.PicklistEntry pickVal : pPicklistValues){
            if (pickVal.isActive()){
                picklistValueSet.add(new SelectOption(pickVal.getValue(), pickVal.getLabel()));
                
                if (pickVal.isDefaultValue()){
                    pTxnParamObject.getTxnParam().String_Value__c = pickVal.getValue();
                }
            }
        }
        
        pTxnParamObject.setListValues(picklistValueSet);
    }

    public static Boolean isRequiredParamBlank(QueuedTransactionParamObject pTxnParamObject){
        Boolean isBlank = false;
        if (pTxnParamObject.getTxnParam().Is_Required__c){
            if (pTxnParamObject.getIsNumberField() && pTxnParamObject.getTxnParam().Number_Value__c == null){
                isBlank = true;            
            } else if (pTxnParamObject.getIsStringField() && String.IsBlank(pTxnParamObject.getTxnParam().String_Value__c)){
                isBlank = true;            
            } else if (pTxnParamObject.getIsCurrencyField() && pTxnParamObject.getTxnParam().Currency_Value__c == null){
                isBlank = true;            
            } else if (pTxnParamObject.getIsDateField() && pTxnParamObject.getTxnParam().Date_Value__c == null){
                isBlank = true;            
            } else if (pTxnParamObject.getIsReferenceField() && String.IsBlank(pTxnParamObject.getTxnParam().Reference_Value_ID__c)){
                isBlank = true;            
            }
        }

        return isBlank;
    }
    
    public static Map<String, fsCore__Transaction_Parameter_Setup__c> getTransactionParamMap(Id pTxnSetupId){
        return getTransactionParamMap(new Set<Id>{pTxnSetupId}).get(pTxnSetupId);
    }

    public static Map<Id, Map<String, fsCore__Transaction_Parameter_Setup__c>> getTransactionParamMap(Set<Id> pTxnSetupIdSet){
        Map<Id, Map<String, fsCore__Transaction_Parameter_Setup__c>> txnParamMap
                                = new Map<Id, Map<String, fsCore__Transaction_Parameter_Setup__c>>();
        
        if (pTxnSetupIdSet == null || (pTxnSetupIdSet != null && pTxnSetupIdSet.size() == 0)){ return txnParamMap; }
        
        List<fsCore__Transaction_Parameter_Setup__c> allTxnParams
                                            = [SELECT Id, Name
                                                    , fsCore__Display_Order__c
                                                    , fsCore__Field_Name__c
                                                    , fsCore__Is_Required__c
                                                    , fsCore__Transaction_Name__c
                                                    , fsCore__Transaction_Parameter_Field_ID__c
                                                 FROM fsCore__Transaction_Parameter_Setup__c
                                                WHERE fsCore__Transaction_Name__c IN :pTxnSetupIdSet
                                                  AND fsCore__Is_Active__c = true
                                                ORDER BY fsCore__Transaction_Name__c, fsCore__Display_Order__c];
        
        for (fsCore__Transaction_Parameter_Setup__c param : allTxnParams){
            Map<String, fsCore__Transaction_Parameter_Setup__c> paramMap = new Map<String, fsCore__Transaction_Parameter_Setup__c>();
            
            if (txnParamMap.containsKey(param.fsCore__Transaction_Name__c)){
                paramMap = txnParamMap.get(param.fsCore__Transaction_Name__c);
            }
            
            paramMap.put(param.fsCore__Field_Name__c.toLowerCase(), param);
            txnParamMap.put(param.fsCore__Transaction_Name__c, paramMap);
        }
        
        return txnParamMap;
    }

    public static Transaction_Processing_Parameter__c getNewTxnProcessingParam(fsCore__Transaction_Parameter_Setup__c pTxnParamSetup){
        Transaction_Processing_Parameter__c param = new Transaction_Processing_Parameter__c();
        param.Name = pTxnParamSetup.Name;
        param.Is_Required__c = pTxnParamSetup.fsCore__Is_Required__c;
        param.Display_Order__c = pTxnParamSetup.fsCore__Display_Order__c;
        param.Transaction_Parameter_Field_ID__c = pTxnParamSetup.fsCore__Transaction_Parameter_Field_ID__c;
        param.Field_Name__c = pTxnParamSetup.fsCore__Field_Name__c.toLowerCase();
        param.Object_Name__c = null;
        param.Currency_Value__c = null;
        param.Date_Value__c = null;
        param.Number_Value__c = null;
        param.String_Value__c = null;
        param.Reference_Value_ID__c = null;
        param.Boolean_Value__c = false;
        
        return param;
    }

}
