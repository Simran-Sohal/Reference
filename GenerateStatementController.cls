public with sharing class GenerateStatementController extends ContractRelatedControllerBase{
    private static final String CLASS_NAME = 'GenerateStatementController';
    private Lending_Contract__c mThisContract;
    
    public List<SelectOption> mDateRangeOptions {get; private set;}
    public String mSelectedDateRange {get; set;}
    public Boolean mIsGenerated {get; set;}
    public Boolean mIsSaved {get; set;}
    private Map<String, String> mAllowedDateRanges;
    
    public StatementObject mStatement {get; private set;}
    
    public GenerateStatementController(ApexPages.StandardController pStdController){
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
        mAllowedDateRanges = StatementUtil.getAllowedDateRanges();
        
        mDateRangeOptions = new List<SelectOption>();
        mDateRangeOptions.add(new SelectOption(Constants.BLANK_STRING, '-- Select an option --'));
        
        for (String dateRangeCode : mDateRangeOptions.keySet()){
            mDateRangeOptions.add(new SelectOption(dateRangeCode, mDateRangeOptions.get(dateRangeCode)));
        }
    }

    public PageReference onGenerate(){
        if (String.IsBlank(mSelectedDateRange)){
            addErrorToPage('Please select a date range option');
            return null;
        }
        
        mSelectedDateRange = String.escapeSingleQuotes(mSelectedDateRange);
        if (!mAllowedDateRanges.containsKey(mSelectedDateRange)){
            addErrorToPage('Please select a valid date range option');
            return null;
        }
        
        StatementUtil.DateRange statementDateRange = StatementUtil.getDateRange(getBusinessDate()
                                                                              , mSelectedDateRange);
        
        if (mSelectedDateRange.equalsIgnoreCase('START_TILL_TODAY')){
            statementDateRange.formDate = getLendingContract().Contract_Date__c;
        }
        
        mStatement = StatementUtil.getStatement(getLendingContract().Id, statementDateRange.formDate, statementDateRange.toDate);
        mIsGenerated = true;
    }
    
    public PageReference onDownloadAsPDF(){
        if (mIsGenerated){
            String pdfPageName = StatementUtil.getPDFStatementPage();
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
            String pdfPageName = StatementUtil.getPDFStatementPage();
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
