public with sharing abstract class ContractRelatedControllerBase extends fsCore.SingleRecordControllerBase{
    
    private String mPageTitle;
    private String mPageSubtitle;
    private Date   mBusinessDate;
    private Lending_Contract__c mContract;
    
    public ContractRelatedControllerBase(ApexPages.StandardController pStdController){
        super(pStdController);
        mPageTitle = Constants.BLANK_STRING;
        mPageSubtitle = Constants.BLANK_STRING;
        mBusinessDate = null;
    }

    public abstract String getRelatedObjectName();
    
    public virtual void setPageTitle(String pPageTitle){
        mPageTitle = pPageTitle;
    }
    
    public String getPageTitle(){
        return mPageTitle;
    }

    public virtual void setPageSubtitle(String pPageSubtitle){
        mPageSubtitle = pPageSubtitle;
    }
    
    public String getPageSubtitle(){
        if (String.IsBlank(mPageSubtitle)){
            mPageSubtitle = Label.fsCore.New_Record_Title + ' ' + getRelatedObjectName();
        }
        return mPageSubtitle;
    }

    protected void setLendingContract(Id pContractId){
        mContract = LendingContractUtil.getLendingContract(pContractId);
        setPageTitle(mContract.Name);
        setBusinessDate(mContract.Branch_Code__c);
    }

    protected Lending_Contract__c getLendingContract(){
        return mContract;
    }

    protected void setBusinessDate(String pBranchCode){
        mBusinessDate = fsCore.SpectraCoreUtil.getBusinessDate(pBranchCode);
    }
    
    protected Date getBusinessDate(){
        if (mBusinessDate == null){ setBusinessDate(mContract.Branch_Code__c); }
        return mBusinessDate;
    }

    public void addErrorsToPage(List<fsCore.ErrorObject> pErrorList){
        for (fsCore.ErrorObject errObj : pErrorList){
            addErrorToPage(errObj.getErrorMessage());
        }
    }

    public void addErrorToPage(String pErrorMessage){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, pErrorMessage));
    }
}
