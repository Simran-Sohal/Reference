public class ContractStatementObject {
    
    public String contractId {get;set;}
    public String contractNumber {get;set;}
    public Date statementFromDate {get;set;}
    public Date statementToDate {get;set;}
    public String statementPeriod {get;set;}
    public Integer numberOfTransactions {get;set;}
    public Decimal principalCollected {get;set;}
    public Decimal interestCollected {get;set;}
    public List<ContractTransactionObject> transactions {get;set;}
    
    public ContractStatementObject(){
        transactions = new List<ContractTransactionObject>();
    }

    public class ContractTransactionObject{
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
        public List<TransactionAllocationObject> allocations {get;set;}

        public ContractTransactionObject(){
            allocations = new List<TransactionAllocationObject>();
        }
    }

    public class TransactionAllocationObject{
        public String balanceName {get;set;}
        public Decimal allocatedAmount {get;set;}
    }

}
