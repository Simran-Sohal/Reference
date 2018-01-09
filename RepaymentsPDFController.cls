public with sharing class RepaymentsPDFController extends fsCore.PDFControllerBase{

    public Lending_Application__c mApplication {get; private set;}
    public Branch_Setup__c mBranch {get; private set;}
    public List<Lending_Application_Repayment__c> mRepaymentDtlList {get; private set;}
    private String mCompanyLogoURL;
    private Boolean mIsDownload;
    
    public LendingAppRepayPDFController (ApexPages.StandardController pStdController){
        super();
        this.mApplication = (Lending_Application__c)pStdController.getRecord();
        mRepaymentDtlList = new List<Lending_Application_Repayment__c>();
        mCompanyLogoURL = Constants.BLANK_STRING;
        mIsDownload = false;
        
        setPDFContents();
    }
    
    private void setPDFContents(){
        if (mApplication.Id != null){
            mApplication = LendingApplicationUtil.getApplicationForPDF(mApplication.Id);
            mBranch = UserBranchUtil.getBranchForPDF(mApplication.Branch_Name__c);
            mRepaymentDtlList = LendingApplicationRepaymentUtil.getRepaymentDetails(mApplication.Id);
            
            if (mBranch.Company_Name__r.Company_Logo_File_Id__c != null){
                mCompanyLogoURL = '/servlet/servlet.FileDownload?file=' + String.valueOf(mBranch.Company_Name__r.Company_Logo_File_Id__c);
            }
            
            if (ApexPages.currentPage().getParameters().get('download') != null && 
                    ApexPages.currentPage().getParameters().get('download').equalsIgnoreCase('true')) {
                mIsDownload = true;
            }

            String pdfFileName = String.format(Label.PDF_Repayment_Document_Name, new List<String>{mApplication.Name});
            
            if (mIsDownload) { downloadPDF(pdfFileName); }
        }
    }
    
    public String getCompanyLogoURL(){
        return mCompanyLogoURL;
    }
    
}
