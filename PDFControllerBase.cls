global with sharing virtual class PDFControllerBase {

    private String mTodayDate;
    
    global PDFControllerBase(){
        mTodayDate = System.today().format();
    }
    
    global String getTodayDate(){
        return mTodayDate;
    }
    
    global void downloadPDF(String pPDFFileName){
        String downloadFileName = String.IsBlank(pPDFFileName) ? 'Download.pdf' : pPDFFileName;
        Apexpages.currentPage().getHeaders().put('content-disposition', 'attachment; filename=' + downloadFileName);
    }
    
}
