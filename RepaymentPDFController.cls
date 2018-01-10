public with sharing class RepaymentPDFController extends fsCore.PDFControllerBase{

    public Lending_Contract__c mContract {get; private set;}
    public fsCore__Branch_Setup__c mBranch {get; private set;}
    public List<Contract_Repayment__c> mRepaymentList {get; private set;}
    private String mCompanyLogoURL;
    private Boolean mIsDownload;
    
    public RepaymentPDFController (ApexPages.StandardController pStdController){
        super();
        this.mContract = (Lending_Contract__c)pStdController.getRecord();
        mRepaymentList = new List<Contract_Repayment__c>();
        mCompanyLogoURL = Constants.BLANK_STRING;
        mIsDownload = false;
        
        setPDFContents();
    }
    
    private void setPDFContents(){
        if (mContract.Id != null){
            mContract = LendingContractUtil.getContractForPDF(mContract.Id);
            mBranch = fsCore.UserBranchUtil.getBranchForPDF(mContract.Branch_Name__c);
            mRepaymentList = ContractRelatedRecordQueryUtil.getRepayments(mContract.Id);
            
            if (mBranch.fsCore__Company_Name__r.fsCore__Company_Logo_File_Id__c != null){
                mCompanyLogoURL = '/servlet/servlet.FileDownload?file=' + String.valueOf(mBranch.fsCore__Company_Name__r.fsCore__Company_Logo_File_Id__c);
            }
            
            if (ApexPages.currentPage().getParameters().get('download') != null && 
                    ApexPages.currentPage().getParameters().get('download').equalsIgnoreCase('true')) {
                mIsDownload = true;
            }

            String pdfFileName = String.format(Label.fsCore__PDF_Repayment_Document_Name, new List<String>{mContract.Name});
            
            if (mIsDownload) { downloadPDF(pdfFileName); }
        }
    }
    
    public String getCompanyLogoURL(){
        return mCompanyLogoURL;
    }
    
}
