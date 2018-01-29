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
