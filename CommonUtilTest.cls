@isTest
private class SpectraServicingUtilTest {
    @testSetup
    static void createTestSetup(){
        String errMsg = Constants.BLANK_STRING;
        Boolean hasError = false;
        try{
            //create company and branch
            TestSetupLoader.loadCompanySetup();
            TestSetupLoader.loadBankSetup();
            Map<String, fsCore__Branch_Code__c> branchMap = TestSetupLoader.loadBranchSetup();
            
            //create some holidays
            fsCore__Branch_Setup__c testBranch = branchMap.get('TCHQ');
            Date branchDate = testBranch.fsCore__Business_Date__c;
            Holiday hd1 = new Holiday(Name='Holiday 1',ActivityDate=branchDate.addDays(12),IsAllDay=true,IsRecurrence=false);
            Holiday hd1 = new Holiday(Name='Holiday 2',ActivityDate=branchDate.addDays(20),IsAllDay=true,IsRecurrence=false);
            List<Holiday> holidayList = new List<Holiday>{hd1,hd2};
            insert holidayList;
            
            System.assert(hd1.Id != null, 'Holiday 1 created');
            System.assert(hd2.Id != null, 'Holiday 2 created');
            
            //attach holiday to branch
            List<fsCore__Branch_Holiday_Setup__c> branchHolidays = new List<fsCore__Branch_Holiday_Setup__c>();
            branchHolidays.add(new fsCore__Branch_Holiday_Setup__c(fsCore__Branch_Name__c=testBranch.Id,fsCore__Holiday_Id__c=hd1.Id,fsCore__Is_Active__c=true));
            branchHolidays.add(new fsCore__Branch_Holiday_Setup__c(fsCore__Branch_Name__c=testBranch.Id,fsCore__Holiday_Id__c=hd2.Id,fsCore__Is_Active__c=true));
            insert branchHolidays;
            
        } catch (Exception e){
            hasError = true;
            errMsg = String.valueOf(e);
        }
        System.assertEquals(false, hasError, 'Test data creation assert ' + errMsg);
    }
    
    @isTest
    private static void testNamespaceRelatedMethods(){
        Test.startTest();
        String namespacePrefix = SpectraServicingUtil.getServicingNamespace();
        System.assertEquals(Constants.FS_SERV_NS_PREFIX, namespacePrefix, 'Servicing namespace prefix assert');
        
        String entityNameWithNS = SpectraServicingUtil.addServicingNamespace('Lending_Contract__c');
        System.assertEquals(namespacePrefix + '__Lending_Contract__c', entityNameWithNS, 'Entity Name with added namespace prefix assert');
        
        entityNameWithNS = SpectraServicingUtil.addServicingNamespace('Account');
        System.assertEquals('Account', entityNameWithNS, 'Entity Name with no namespace prefix assert');        
        Test.stopTest();
    }

    @isTest
    private static void testBranchRelatedMethods(){
        Map<String, fsCore__Branch_Setup__c> branchMap = TestQueryHelper.getTestBranches();
        
        Test.startTest();
        Map<String, Date> branchBizDateMap = SpectraServicingUtil.getBranchBusinessDateMap(branchMap.keySet());
        System.assertEquals(Date.newInstance(2017,1,5), branchBizDateMap.get('TCHQ'), 'Test branch business date');
        
        Map<String, List<Holiday>> branchHolidaysMap = SpectraServicingUtil.getBranchHolidaysMap(branchMap.keySet());
        System.assertEquals(2, branchHolidaysMap.get('TCHQ').size(), 'Holiday List size for test branch');
        Test.stopTest();
    }
    
}
