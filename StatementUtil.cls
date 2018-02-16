public with sharing class StatementUtil{

    public static Map<String, String> getAllowedDateRanges(){
        Map<String, String> allowedDateRanges = new Map<String, String>();
        allowedDateRanges.put('START_TILL_TODAY', 'Contract start till today');
        allowedDateRanges.put('LAST_30_DAYS', 'Last 30 Days');
        allowedDateRanges.put('LAST_60_DAYS', 'Last 60 Days');
        allowedDateRanges.put('LAST_90_DAYS', 'Last 90 Days');
        allowedDateRanges.put('LAST_180_DAYS', 'Last 180 Days');
        allowedDateRanges.put('THIS_FISCAL_YEAR', 'This Fiscal Year');
        allowedDateRanges.put('LAST_FISCAL_YEAR', 'Last Fiscal Year');
        
        return allowedDateRanges;
    }

    public class DateRange{
        public Date fromDate;
        public Date toDate;
    }

    public static DateRange getCurrentFiscalYearDateRange(Date pBusinessDate){
        List<Period> fiscalPeriods = [SELECT StartDate, EndDate
                                        FROM Period
                                       WHERE Type = 'Year'
                                         AND StartDate <= :pBusinessDate
                                         AND EndDate >= :pBusinessDate
                                       ORDER BY StartDate];

        if (fiscalPeriods.size() == 0){
            throw new ServicingException('Unable to find the Fiscal Year period for ' + pBusinessDate.day() + '-' + pBusinessDate.month() + '-' + pBusinessDate.year());
        }

        DateRange fiscalYrDtRange = new DateRange();
        fiscalYrDtRange.fromDate = fiscalPeriods.get(0).StartDate;                    
        fiscalYrDtRange.toDate = fiscalPeriods.get(0).EndDate;
        
        return fiscalYrDtRange;
    }
    
    public static DateRange getDateRange(Date pContractStartDate
                                       , Date pFiscalYearStartDate
                                       , Date pFiscalYearEndDate
                                       , Date pBusinessDate
                                       , String pDateRangeCode){
        DateRange dtRange = new DateRange();
        
        if (String.IsBlank(pDateRangeCode) || (String.IsNotBlank(pDateRangeCode) && !getAllowedDateRanges().conatinsKey(pDateRangeCode))){
            throw new ServicingException('Invalid Date Range');
        }
        
        if (pDateRangeCode.equalsIgnoreCase('START_TILL_TODAY')){
            dtRange.fromDate = pContractStartDate;
            dtRange.toDate = pBusinessDate;
        }
        else if (pDateRangeCode.equalsIgnoreCase('LAST_30_DAYS')){
            dtRange.fromDate = pBusinessDate.addDays(-30);
            dtRange.toDate = pBusinessDate;
        }
        else if (pDateRangeCode.equalsIgnoreCase('LAST_60_DAYS')){
            dtRange.fromDate = pBusinessDate.addDays(-60);
            dtRange.toDate = pBusinessDate;
        }
        else if (pDateRangeCode.equalsIgnoreCase('LAST_90_DAYS')){
            dtRange.fromDate = pBusinessDate.addDays(-90);
            dtRange.toDate = pBusinessDate;
        }
        else if (pDateRangeCode.equalsIgnoreCase('LAST_180_DAYS')){
            dtRange.fromDate = pBusinessDate.addDays(-180);
            dtRange.toDate = pBusinessDate;
        }
        else if (pDateRangeCode.equalsIgnoreCase('THIS_FISCAL_YEAR')){
            dtRange.fromDate = pFiscalYearStartDate;
            dtRange.toDate = pFiscalYearEndDate;
        }
        else if (pDateRangeCode.equalsIgnoreCase('LAST_FISCAL_YEAR')){
            dtRange.fromDate = Date.newInstance(pFiscalYearStartDate.year() - 1, pFiscalYearStartDate.month(), pFiscalYearStartDate.day());
            dtRange.toDate = Date.newInstance(pFiscalYearEndDate.year() - 1, pFiscalYearEndDate.month(), pFiscalYearEndDate.day());
        }
        
        return dtRange;
    } 
    
    public static StatementObject getStatement(Id pContractId, Date pFromDate, Date pToDate){
        return getStatements(new Set<Id>{pContractId}, pFromDate, pToDate).get(pContractId);
    }
    
    public static Map<Id, StatementObject> getThisFicalYearStatements(Set<Id> pContractIdSet){
        DateRange fiscalYearDateRange = getCurrentFiscalYearDateRange(System.today());
        return getStatements(pContractIdSet, fiscalYearDateRange.formDate, fiscalYearDateRange.toDate);
    }
    
    public static Map<Id, StatementObject> getStatements(Set<Id> pContractIdSet, Date pFromDate, Date pToDate){
        Map<Id, Lending_Contract__c> contractMap = new Map<Id, Lending_Contract__c>(
                                                            [SELECT Id, Name
                                                                  , Contract_Status__c
                                                                  , Primary_Customer_Account__r.Name
                                                                  , Primary_Customer_Contact__r.Name
                                                               FROM Lending_Contract__c
                                                              WHERE Id = :pContractIdSet]);
        
        //add logic to fetch the transactions for the contracts
        Map<Id, List<Contract_Transaction__c>> contractTransactionMap = new Map<Id, List<Contract_Transaction__c>>();
        
        Map<Id, StatementObject> contractStatementMap = new Map<Id, StatementObject>();
        for(Lending_Contract__c contract : contractMap.values()){
            StatementObject statement = getContractStatement(contract, contractTransactionMap.get(contract.Id), pFromDate, pToDate);
            contractStatementMap.put(contract.Id, statement);
        }
        
        return contractStatementMap;
    }
    
    private static StatementObject getContractStatement(Lending_Contract__c pContract
                                                      , List<Contract_Transaction__c> pTransactions
                                                      , Date pFromDate
                                                      , Date pToDate){
        StatementObject stmt = new StatementObject();
        stmt.contractId = String.valuesOf(pContract.Id);
        stmt.contractNumber = pContract.Name;
        stmt.statementFromDate = pFromDate;
        stmt.statementToDate = pToDate;
        stmt.statementPeriod = 'Contract Statement for period ' + pFromDate + ' - ' + pToDate;
        stmt.numberOfTransactions = (pTransactions == null) ? 0 : pTransactions.size();
        
        
        return stmt;
    }
}
