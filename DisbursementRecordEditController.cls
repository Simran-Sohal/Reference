public with sharing class DisbursementRecordEditController extends ContractRelatedControllerBase{
    private static final String CLASS_NAME = 'DisbursementRecordEditController';

    public Lending_Contract__c mContract {get; private set;}
    public Contract_Disbursement__c mDisburement {get; set;}
    private Date mBranchDate; 
    
    public class RelatedDrawPreference {
        public Boolean mIsSelected {get; set;}
        public Contract_Draw_Preference__c mDrawPreference {get; set;}

        public RelatedDrawPreference (Boolean pIsSelected, Contract_Draw_Preference__c pDrawPreference){
            mIsSelected = pIsSelected;
            mDrawPreference = pDrawPreference;
        }
    }
    
    public List<RelatedDrawPreference> mRelatedDrawPreferences {get; set;}
    private Map<Id, RelatedDrawPreference> mRelatedDrawPreferenceMap;
    public Id mActionedDrawPrefId {get; set;}
    
    public DisbursementRecordEditController(ApexPages.StandardController pStdController){
        super(pStdController);
        this.mDisbursement = (Contract_Disbursement__c)pStdController.getRecord();
        init();
    }
    
    private void init(){
        if (mDisbursement.Id != null){
            mDisbursement = (Contract_Disbursement__c) SObjectQueryUtil.getSObjectRecord(mDisbursement.Id);
        }

        Map<String,String> pageURLParamMap = ApexPages.currentPage().getParameters();
        
        //get parent contract
        Id contractId = null;
        if (pageURLParamMap.containsKey(fsCore.Constants.PAGE_PARENT_ID)){
            contractId = Id.valueOf(pageURLParamMap.get(fsCore.Constants.PAGE_PARENT_ID));
        }
        else if (mDirectDebit.Lending_Contract_Number__c != null){
            contractId = mDisbursement.Lending_Contract_Number__c;
        } 
        else {
            throw new ServicingException(Label.Parent_Contract_Id_Missing);
        }

        setLendingContract(contractId);
        mCustomerMap = new Map<Id, Contract_Customer__c>(ContractRelatedRecordQueryUtil.getCustomers(mContract.Id));
        setCustomerList();
        mBranchDate = fsCore.BusinessDateSettingsUtil.getBusinessDate(mContract.Branch_Code__c);
        
        if (mDisbursement.Id == null){
            setDefaultValues();
        }
        initRelatedData();
        
        if (mDisbursement.Is_Future_Disbursement__c){
            setRelatedDrawPreferences();
        } else {
            setRelatedItemizations();
        }
        
        if (mDisbursement.Id != null){ validateRecord(); }
    }

    private void setDefaultValues(){
        mDisbursement.Lending_Contract_Number__c = mContract.Id;
        mDisbursement.Disbursement_Date__c = mBranchDate;
        mDisbursement.Disbursement_Party_Type__c = mContract.Product_Name__r.fsCore__Default_Disbursement_Party_Type__c;
        mDisbursement.Payment_Method__c = mContract.Product_Name__r.fsCore__Default_Disbursement_Payment_Method__c;
        mDisbursement.Is_Future_Disbursement__c = true;
        mDisbursement.Is_Recalculate_Repayments__c = true;
        if (UserInfo.isMultiCurrencyOrganization()){
            mDisbursement.put(Constants.FIELD_NAME_CURRENCY, mContract.get(Constants.FIELD_NAME_CURRENCY));
        }
    }

    private void setRelatedDrawPreferences(){
        mRelatedDrawPreferenceMap = new Map<Id, RelatedDrawPreference>();
        
        if (mContract.Is_Funding_In_Tranches_Allowed__c){
            List<Contract_Draw_Preference__c> drawPreferences;
            if (mDisbursement.Id == null){
                drawPreferences = LendingContractRepaymentUtil.getDrawPreferences(mContract.Id, false);
            }
            else {
                drawPreferences = LendingContractDisbursementUtil.getRelatedDrawPreferences(mDisbursement.Id);
            }
            
            for (Lending_Contract_Draw_Preference__c drawPref : drawPreferences){
                RelatedDrawPreference relatedDrawPref;
                if (mDisbursement.Id != null && drawPref.Disbursement_Reference_Number__c == mDisbursement.Id){
                    relatedDrawPref = new RelatedDrawPreference(true, drawPref);
                } else {
                    relatedDrawPref = new RelatedDrawPreference(false, drawPref);
                }
                mRelatedDrawPreferences.add(relatedDrawPref);
                mRelatedDrawPreferenceMap.put(drawPref.Id, relatedDrawPref);
            }
        }
    }
    
    public PageReference onSelectDrawPreference(){
        System.debug(loggingLevel.ERROR, '-- Actioned Draw Preference : ' + mActionedDrawPrefId);
        
        RelatedDrawPreference actionedDrawPref = null;
        if (mActionedDrawPrefId != null && mRelatedDrawPreferenceMap.containsKey(mActionedDrawPrefId)){
            actionedDrawPref = mRelatedDrawPreferenceMap.get(mActionedDrawPrefId);
        }
        
        if (actionedDrawPref != null){    
            //if the action draw preference is selected then unselect the other records
            for(RelatedDrawPreference relatedDrawPref : mRelatedDrawPreferences){
                if (relatedDrawPref.mDrawPreference.Id != actionedDrawPref.mDrawPreference.Id && actionedDrawPref.mIsSelected){
                    relatedDrawPref.mIsSelected = false;
                }
            }
        }
        
        Decimal disbursementAmount = null;
        Date disbursementDate = null;
        //set the disbursement amount and date with the values of selected draw preference
        for(RelatedDrawPreference relatedDrawPref : mRelatedDrawPreferences){
            if (relatedDrawPref.mIsSelected){
                disbursementAmount = relatedDrawPref.mDrawPreference.Draw_Amount__c;
                disbursementDate = relatedDrawPref.mDrawPreference.Draw_Date__c;
                break;
            }
        }

        mAppDisbObject.mDisbursement.Disbursement_Amount__c = disbursementAmount;
        mAppDisbObject.mDisbursement.Disburse_On__c = disbursementDate;
        
        return null;
    }

    public PageReference onPartyTypeChange(){
        mAppDisbObject.setPartyType();
        mAppDisbObject.mDisbursement.Account_Name__c = null;
        mAppDisbObject.mDisbursement.Contact_Name__c = null;
        
        if (String.IsNotBlank(mAppDisbObject.mDisbursement.Disbursement_Party_Type__c)
                && mAppDisbObject.mDisbursement.Disbursement_Party_Type__c.equalsIgnoreCase(Constants.DISBURSEMENT_PARTY_CUSTOMER)){
            Map<Id, Lending_Contract_Customer__c> customerMap = new Map<Id, Lending_Contract_Customer__c>(LendingContractCustomerUtil.getCustomers(mContract.Id));
            mAppDisbObject.setCustomerList(customerMap);
            
            for(Lending_Contract_Customer__c customer : customerMap.values()){
                if (customer.Is_Primary__c){
                    mAppDisbObject.mDisbursement.Customer_Reference_Number__c = customer.Id;
                    break;
                }
            }

            mAppDisbObject.setCustomerDetails();
        } 
        return null;
    }
    
    public PageReference onAccountChange(){
        mAppDisbObject.mDisbursement.Contact_Name__c = null;
        mAppDisbObject.setAccountContactList();
        return null;
    }

    public PageReference onCustomerChange(){
        mAppDisbObject.setCustomerDetails();
        return null;
    }

    public override Boolean validateRecord(){
        Boolean isValid = true;
        if (mAppDisbObject.mDisbursement.Disburse_On__c == null){
            isValid = false;
            addError(Label.Disbursement_Date_Blank);
        }
        else if (mAppDisbObject.mDisbursement.Disburse_On__c != null && mAppDisbObject.mDisbursement.Is_Future_Disbursement__c
                && mAppDisbObject.mDisbursement.Disburse_On__c <= mBranchDate){
            isValid = false;
            addError(Label.Future_Disbursement_Date_Not_In_Future);
        }
        else if (mAppDisbObject.mDisbursement.Disburse_On__c != null && !mAppDisbObject.mDisbursement.Is_Future_Disbursement__c
                && mAppDisbObject.mDisbursement.Disburse_On__c > mBranchDate){
            isValid = false;
            addError(Label.Disbursement_Date_In_Future);
        }
        else if (mAppDisbObject.mDisbursement.Disbursement_Amount__c == null){
            isValid = false;
            addError(Label.Disbursement_Amount_Blank);
        }
        else if (mAppDisbObject.mDisbursement.Disbursement_Amount__c != null && mAppDisbObject.mDisbursement.Disbursement_Amount__c <= 0){
            isValid = false;
            addError(Label.Disbursement_Amount_Zero);
        }
        else if (String.IsNotBlank(mAppDisbObject.mDisbursement.Disbursement_Party_Type__c)
                && mAppDisbObject.mDisbursement.Disbursement_Party_Type__c.equalsIgnoreCase(Constants.DISBURSEMENT_PARTY_CUSTOMER)
                    && mAppDisbObject.mDisbursement.Customer_Reference_Number__c == null){
            isValid = false;
            addError(Label.Customer_Not_Selected_For_Disbursement);
        }
        else if (String.IsNotBlank(mAppDisbObject.mDisbursement.Disbursement_Party_Type__c)
                && !mAppDisbObject.mDisbursement.Disbursement_Party_Type__c.equalsIgnoreCase(Constants.DISBURSEMENT_PARTY_CUSTOMER)
                    && (mAppDisbObject.mDisbursement.Account_Name__c == null && mAppDisbObject.mDisbursement.Contact_Name__c == null)){
            isValid = false;
            addError(Label.Account_Contact_Blank_For_Disbursement);
        }
        
        isValid = isRelatedDataValid();
        return isValid;
    }
    
    private Boolean isRelatedDataValid(){
        Boolean isValid = true;
        
        if (mAppDisbObject.mDisbursement.Is_Future_Disbursement__c){
            List<Lending_Contract_Draw_Preference__c> selectedDrawPref = new List<Lending_Contract_Draw_Preference__c>(); 
            for(RelatedDrawPreference relatedDrawPref : mRelatedDrawPreferences){
                if (relatedDrawPref.mIsSelected){
                    selectedDrawPref.add(relatedDrawPref.mDrawPreference);
                }
            }
            
            if (mRelatedDrawPreferences.size() > 0 && selectedDrawPref.size() == 0){
                isValid = false;
                addError(Label.Draw_Pref_For_Disbursement_Not_Selected);
            }
            else if (selectedDrawPref.size() > 1){
                isValid = false;
                addError(Label.Multi_Draw_Pref_Per_Disbursement_Not_Allowed);
            }
            else if (selectedDrawPref.size() == 1){
                if (selectedDrawPref.get(0).Draw_Amount__c != mAppDisbObject.mDisbursement.Disbursement_Amount__c){
                    isValid = false;
                    addError(Label.Disbursement_Amount_Draw_Amount_Mismatch);
                }
                if (selectedDrawPref.get(0).Draw_Date__c != mAppDisbObject.mDisbursement.Disburse_On__c){
                    isValid = false;
                    addError(Label.Disbursement_Date_Draw_Date_Mismatch);
                }
            }
        } 
        else {
            if (mRelatedItemizations.size() == 0){
                isValid = false;
                addError(Label.No_Related_Itemization_Found);
            } 
            else {
                Decimal totalItmzAmount = 0.00;
                for(RelatedItemization relatedItmz : mRelatedItemizations){
                    if (relatedItmz.mIsSelected){
                        totalItmzAmount += (relatedItmz.mItemization.Actual_Amount_Signed__c == null ? 0 : relatedItmz.mItemization.Actual_Amount_Signed__c);
                    }
                }
    
                if (totalItmzAmount != mAppDisbObject.mDisbursement.Disbursement_Amount__c){
                    isValid = false;
                    addError(Label.Disbursement_Amount_Itemization_Total_Mismatch);
                }
            }
        }
        
        return isValid;
    }
    
    public override List<ErrorObject> saveRecord(){
        List<ErrorObject> errorList = new List<ErrorObject>();
        List<Lending_Contract_Disbursement__c> disbForUpsert = new List<Lending_Contract_Disbursement__c>();
        
        mAppDisbObject.mDisbursement.Is_Recalculate_Repayments__c = (mAppDisbObject.mDisbursement.Is_Future_Disbursement__c && mRelatedDrawPreferences.size() == 0);
        disbForUpsert.add(mAppDisbObject.mDisbursement);
        
        DMLResult disbSaveRslt = LendingContractDisbursementDMLWrapper.getInstance().upsertData(disbForUpsert);
        if (disbSaveRslt.hasErrors()) { errorList = disbSaveRslt.getErrorList(); }
        
        if (errorList.size() > 0){
            return errorList;
        }
        
        super.setContextRecordId(mAppDisbObject.mDisbursement.Id);

        if (mAppDisbObject.mDisbursement.Is_Future_Disbursement__c){
            errorList = saveRelatedDrawPreferences();
        } else {
            errorList = saveRelatedItemizations();
        }
        
        return errorList;
    }
    
    private List<ErrorObject> saveRelatedItemizations(){
        List<Lending_Contract_Itemization__c> itemizationForUpdate = new List<Lending_Contract_Itemization__c>(); 
        List<ErrorObject> errorList = new List<ErrorObject>();
        
        for(RelatedItemization relatedItmz : mRelatedItemizations){
            if (relatedItmz.mIsSelected){
                relatedItmz.mItemization.Disbursement_Reference_Number__c = mAppDisbObject.mDisbursement.Id;
                itemizationForUpdate.add(relatedItmz.mItemization);
            }
        }

        if (itemizationForUpdate.size() > 0){
            DMLResult itmzSaveRslt = LendingContractItemizationDMLWrapper.getInstance().updateData(itemizationForUpdate);
            if (itmzSaveRslt.hasErrors()) { errorList = itmzSaveRslt.getErrorList(); }
        }
        
        return errorList;
    }
    
    private List<ErrorObject> saveRelatedDrawPreferences(){
        List<Lending_Contract_Draw_Preference__c> drawPrefForUpdate = new List<Lending_Contract_Draw_Preference__c>(); 
        List<ErrorObject> errorList = new List<ErrorObject>();
        
        for(RelatedDrawPreference relatedDrawPref : mRelatedDrawPreferences){
            if (relatedDrawPref.mIsSelected){
                relatedDrawPref.mDrawPreference.Disbursement_Reference_Number__c = mAppDisbObject.mDisbursement.Id;
                drawPrefForUpdate.add(relatedDrawPref.mDrawPreference);
            }
        }

        if (drawPrefForUpdate.size() > 0){
            DMLResult drawPrefSaveRslt = LendingContractDrawPrefDMLWrapper.getInstance().updateData(drawPrefForUpdate);
            if (drawPrefSaveRslt.hasErrors()) { errorList = drawPrefSaveRslt.getErrorList(); }
        } 
        
        return errorList;
    }
    
    public override PageReference onCancel(){
        PageReference returnPage;
        if (mAppDisbObject.mDisbursement.Id != null){
            returnPage = new PageReference('/' + mAppDisbObject.mDisbursement.Id);
        } else if (mContract.Id != null){
            returnPage = new PageReference('/' + mContract.Id);
        } else {
            returnPage = new PageReference('/');
        }
        returnPage.setRedirect(true);
        return returnPage;
    }

    public override String getClassName(){
        return CLASS_NAME;
    }

    public override PageReference getReturnPageURL(){
        return new PageReference('/' + Schema.sObjectType.Lending_Contract__c.getKeyPrefix() + '/l');
    }     
}
