public with sharing class ContractStatementController extends ContractRelatedControllerBase{
    private static final String CLASS_NAME = 'ContractStatementController';
    private Lending_Contract__c mThisContract;
    
    public List<SelectOption> mDateRangeOptions {get; private set;}
    public String mSelectedDateRange {get; set;}
    public Boolean mIsGenerated {get; set;}
    public Boolean mIsSaved {get; set;}
    
    public ContractStatementObject mStatement {get; private set;}
    
    public ContractStatementController(ApexPages.StandardController pStdController){
        super(pStdController);
        mThisContract = (Lending_Contract__c)pStdController.getRecord();
        init();
    }
    
    private void init(){
        if (mThisContract.Id == null){
            throw new ServicingException(Label.Parent_Contract_Id_Missing);
        }
        setPageSubtitle('Generate Statement');
        setLendingContract(mThisContract.Id);
        
        mSelectedDateRange = Constants.BLANK_STRING;
        setDateRangeOptions();
        mIsGenerated = false;
        mIsSaved = false;
    }
    
    private void setDateRangeOptions(){
        mDateRangeOptions = new List<SelectOption>();
        mDateRangeOptions.add(new SelectOption(Constants.BLANK_STRING, '-- Select an option --'));
        mDateRangeOptions.add(new SelectOption('START_TILL_TODAY', 'Contract start till today'));
        mDateRangeOptions.add(new SelectOption('LAST_30_DAYS', 'Last 30 Days'));
        mDateRangeOptions.add(new SelectOption('LAST_60_DAYS', 'Last 60 Days'));
        mDateRangeOptions.add(new SelectOption('LAST_90_DAYS', 'Last 90 Days'));
        mDateRangeOptions.add(new SelectOption('THIS_FISCAL_YEAR', 'This Fiscal Year'));
        mDateRangeOptions.add(new SelectOption('LAST_FISCAL_YEAR', 'Last Fiscal Year'));
        mDateRangeOptions.add(new SelectOption('CUSTOM_DATE_RANGE', 'Custom Date Range'));
    }

    public PageReference onGenerate(){
        if (String.IsBlank(mSelectedDateRange)){
            addErrorToPage('Please select a date range option');
            return null;
        }
        mStatement = ContractStatementUtil.getStatement(getLendingContract(), mSelectedDateRange);
        mIsGenerated = true;
    }
    
    public PageReference onDownloadAsPDF(){
        if (mIsGenerated){
            String pdfPageName = ContractStatementUtil.getPDFStatementPage();
            PageReference pdfPage = new PageReference('/apex/' + pdfPageName);
            pdfPage.getParameters().put('id', getLendingContract().Id);
            pdfPage.getParameters().put('fromdate', mStatement.statementFromDate);
            pdfPage.getParameters().put('todate', mStatement.statementToDate);
            return pdfPage;
        }
        return null;
    }

    public PageReference onSaveAsFile(){
        if (mIsGenerated){
            String pdfPageName = ContractStatementUtil.getPDFStatementPage();
            PageReference pdfPage = new PageReference('/apex/' + pdfPageName);
            pdfPage.getParameters().put('id', getLendingContract().Id);
            pdfPage.getParameters().put('fromdate', mStatement.statementFromDate);
            pdfPage.getParameters().put('todate', mStatement.statementToDate);
            
            Blob pdfFile;
            Boolean isFileGenerated = false;
            try{
                if (Test.isRunningTest()){
                    pdfFile = pdfPage.getContentAsPDF();
                } else {
                    pdfFile = Blob.valueOf(JSON.serializePretty(mStatement));
                }
                isFileGenerated = true;
            }
            catch (Exception e){
                addErrorToPage('Unable to save statement due to error : ' + e.getMessage());
            }
            
            if (isFileGenerated){
                //add logic to create the record in ContentVersion and ContentDocumentLink
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Statement has been saved successfully'));
                mIsSaved = true;
            }
        }
        return null;
    }

    public override List<fsCore.ErrorObject> saveRecord(){
        return null;
    }
            
    public override String getClassName(){
        return CLASS_NAME;
    }

    public override String getRelatedObjectName(){
        return Schema.SObjectType.Lending_Contract__c.getLabel();
    }   
}
