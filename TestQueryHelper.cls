@isTest
public class TestQueryHelper{

    public static Map<String, fsCore__Company_Setup__c> getTestCompanies(){
        fsCore.DynamicQueryBuilder companyQuery = fsCore.DynamicQueryFactory.createQuery(Schema.SObjectType.fsCore__Company_Setup__c.getName())
                                                    .addFields();

        List<fsCore__Company_Setup__c> companyList = (List<fsCore__Company_Setup__c>)Database.query(companyQuery.getQueryString());
        Map<String, fsCore__Company_Setup__c> companyMap = new Map<String, fsCore__Company_Setup__c>();
        for(fsCore__Company_Setup__c company : companyList){
            companyMap.put(company.fsCore__Company_Code__c, company);
        }

        System.assertEquals(2, companyMap.size(), 'TestHelperQuery.getTestCompanies() assert');
        return companyMap;
    }

    public static Map<String, fsCore__Branch_Setup__c> getTestBranches(){
        fsCore.DynamicQueryBuilder branchQuery = fsCore.DynamicQueryFactory.createQuery(Schema.SObjectType.fsCore__Branch_Setup__c.getName())
                                                    .addFields();

        List<fsCore__Branch_Setup__c> branchList = (List<fsCore__Branch_Setup__c>)Database.query(branchQuery.getQueryString());
        Map<String, fsCore__Branch_Setup__c> branchMap = new Map<String, fsCore__Branch_Setup__c>();
        for(fsCore__Branch_Setup__c branch : branchList){
            branchMap.put(branch.fsCore__Branch_Code__c, branch);
        }

        System.assertEquals(2, branchMap.size(), 'TestHelperQuery.getTestBranches() assert');
        return branchMap;
    }

    public static Map<String, fsCore__Product_Setup__c> getTestProducts(){
        fsCore.DynamicQueryBuilder productQuery = fsCore.DynamicQueryFactory.createQuery(Schema.SObjectType.fsCore__Product_Setup__c.getName())
                                                    .addFields();

        List<fsCore__Product_Setup__c> productList = (List<fsCore__Product_Setup__c>)Database.query(productQuery.getQueryString());
        Map<String, fsCore__Product_Setup__c> productMap = new Map<String, fsCore__Product_Setup__c>();
        for(fsCore__Product_Setup__c product : productList){
            productMap.put(product.fsCore__Product_Code__c, product);
        }

        System.assertEquals(2, productMap.size(), 'TestHelperQuery.getTesProducts() assert');
        return productMap;
    }

    public static Map<String, fsCore__Queue_Assignment_Setup__c> getTestQueueAssignments(){
        fsCore.DynamicQueryBuilder queueAssgnQuery = fsCore.DynamicQueryFactory.createQuery(Schema.SObjectType.fsCore__Queue_Assignment_Setup__c.getName())
                                                        .addFields();

        List<fsCore__Queue_Assignment_Setup__c> queueAssgnList = (List<fsCore__Queue_Assignment_Setup__c>)Database.query(queueAssgnQuery.getQueryString());
        Map<String, fsCore__Queue_Assignment_Setup__c> queueAssgnMap = new Map<String, fsCore__Queue_Assignment_Setup__c>();
        for(fsCore__Queue_Assignment_Setup__c queueAssgn : queueAssgnList){
            queueAssgnMap.put(queueAssgn.fsCore__Assignment_Code__c, queueAssgn);
        }

        System.assertEquals(7, queueAssgnMap.size(), 'TestHelperQuery.getTestQueueAssignments() assert');
        return queueAssgnMap;
    }

    public static Map<String, fsCore__Stage_Setup__c> getTestStages(){
        fsCore.DynamicQueryBuilder stageQuery = fsCore.DynamicQueryFactory.createQuery(Schema.SObjectType.fsCore__Stage_Setup__c.getName())
                                                    .addFields();

        List<fsCore__Stage_Setup__c> stageList = (List<fsCore__Stage_Setup__c>)Database.query(stageQuery.getQueryString());
        Map<String, fsCore__Stage_Setup__c> stageMap = new Map<String, fsCore__Stage_Setup__c>();
        for(fsCore__Stage_Setup__c stage : stageList){
            stageMap.put(stage.fsCore__Stage_Code__c, stage);
        }

        System.assertEquals(7, stageMap.size(), 'TestHelperQuery.getTestStages() assert');
        return stageMap;
    }

    public static Map<String, Account> getTestAccounts(){
        fsCore.DynamicQueryBuilder accountQuery = fsCore.DynamicQueryFactory.createQuery(Schema.SObjectType.Account.getName())
                                                    .addFields();

        List<Account> accountList = (List<Account>)Database.query(accountQuery.getQueryString());
        Map<String, Account> accountMap = new Map<String, Account>();
        for(Account acc : accountList){
            accountMap.put(acc.Name, acc);
        }

        System.assertNotEquals(0, accountMap.size(), 'TestHelperQuery.getTestAccounts() assert');
        return accountMap;
    }

    public static Map<String, Contact> getTestContacts(){
        fsCore.DynamicQueryBuilder contactQuery = fsCore.DynamicQueryFactory.createQuery(Schema.SObjectType.Contact.getName())
                                                    .addFields();

        List<Contact> contactList = (List<Contact>)Database.query(contactQuery.getQueryString());
        Map<String, Contact> contactMap = new Map<String, Contact>();
        for(Contact ct : contactList){
            contactMap.put(ct.Name, ct);
        }

        System.assertNotEquals(0, contactMap.size(), 'TestHelperQuery.getTestContacts() assert');
        return accountMap;
    }

    public static Map<Id, List<fsCore__Bank_Account__c>> getTestBankAccountsByAccount(){
        fsCore.DynamicQueryBuilder bankAccountQuery = fsCore.DynamicQueryFactory.createQuery(Schema.SObjectType.fsCore__Bank_Account__c.getName())
                                                        .addFields()
                                                        .addWhereConditionByValue(1, 'fsCore__Account_Name__c', '!=', null);

        List<fsCore__Bank_Account__c> allBankAccountsList = (List<fsCore__Bank_Account__c>)Database.query(bankAccountQuery.getQueryString());
        Map<Id, List<fsCore__Bank_Account__c>> accountBankAcctsMap = new Map<Id, List<fsCore__Bank_Account__c>>();
        for(fsCore__Bank_Account__c bankAcct : allBankAccountsList){
            List<fsCore__Bank_Account__c> bankAccountsList = new List<fsCore__Bank_Account__c>();
            if (accountBankAcctsMap.containsKey(bankAcct.fsCore__Account_Name__c)){
                bankAccountsList = accountBankAcctsMap.get(bankAcct.fsCore__Account_Name__c);
            }
            bankAccountsList.add(bankAcct);
            accountBankAcctsMap.put(bankAcct.fsCore__Account_Name__c, bankAccountsList);
        }

        System.assertNotEquals(0, accountBankAcctsMap.size(), 'TestHelperQuery.getTestBankAccountsByAccount() assert');
        return accountBankAcctsMap;
    }

    public static Map<Id, List<fsCore__Bank_Account__c>> getTestBankAccountsByContact(){
        fsCore.DynamicQueryBuilder bankAccountQuery = fsCore.DynamicQueryFactory.createQuery(Schema.SObjectType.fsCore__Bank_Account__c.getName())
                                                        .addFields()
                                                        .addWhereConditionByValue(1, 'fsCore__Contact_Name__c', '!=', null);

        List<fsCore__Bank_Account__c> allBankAccountsList = (List<fsCore__Bank_Account__c>)Database.query(bankAccountQuery.getQueryString());
        Map<Id, List<fsCore__Bank_Account__c>> contactBankAcctsMap = new Map<Id, List<fsCore__Bank_Account__c>>();
        for(fsCore__Bank_Account__c bankAcct : allBankAccountsList){
            List<fsCore__Bank_Account__c> bankAccountsList = new List<fsCore__Bank_Account__c>();
            if (contactBankAcctsMap.containsKey(bankAcct.fsCore__Contact_Name__c)){
                bankAccountsList = contactBankAcctsMap.get(bankAcct.fsCore__Contact_Name__c);
            }
            bankAccountsList.add(bankAcct);
            contactBankAcctsMap.put(bankAcct.fsCore__Contact_Name__c, bankAccountsList);
        }

        System.assertNotEquals(0, contactBankAcctsMap.size(), 'TestHelperQuery.getTestBankAccountsByContact() assert');
        return contactBankAcctsMap;
    }

    public static Map<String, Lending_Contract__c> getTestLendingContracts(){
        fsCore.DynamicQueryBuilder contractQuery = fsCore.DynamicQueryFactory.createQuery(
                                                       Schema.SObjectType.Lending_Contract__c.getName()).addFields();

        List<Lending_Contract__c> contractList = (List<Lending_Contract__c>)Database.query(contractQuery.getQueryString());
        Map<String, Lending_Contract__c> contractMap = new Map<String, Lending_Contract__c>();
        for(Lending_Contract__c contract : contractList){
            contractMap.put(contract.Name, contract);
        }
        
        System.assertEquals(8, contractMap.size(), 'TestHelperQuery.getTestLendingContracts() assert');
        return contractMap;
    }

}
