public class StatementObject {
    
    public String contractId {get;set;}
    public String contractNumber {get;set;}
    public Date statementFromDate {get;set;}
    public Date statementToDate {get;set;}
    public String statementPeriod {get;set;}
    public Integer numberOfTransactions {get;set;}
    public Decimal principalCollected {get;set;}
    public Decimal interestCollected {get;set;}
    public List<TransactionObject> transactions {get;set;}
    
    public StatementObject(){
        transactions = new List<TransactionObject>();
    }

    public class TransactionObject{
        public String transactionId {get;set;}
        public Integer serialNumber {get;set;}
        public String referenceNumber {get;set;}
        public String transactionName {get;set;}
        public String transactionCode {get;set;}
        public String transactionDescription {get;set;}
        public Date transactionDate {get;set;}
        public Decimal transactionAmount {get;set;}
        public Decimal runningBalanceAmount {get;set;}
        public Boolean isPaymentTransaction {get;set;}
        public List<AllocationObject> allocations {get;set;}

        public TransactionObject(){
            allocations = new List<AllocationObject>();
        }
    }

    public class AllocationObject{
        public String balanceName {get;set;}
        public Decimal allocatedAmount {get;set;}
    }

}
