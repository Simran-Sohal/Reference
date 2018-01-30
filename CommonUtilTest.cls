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
            Holiday hd1 = getTestHoliday('Holiday 1', branchDate.addDays(12));
            Holiday hd2 = getTestHoliday('Holiday 2', branchDate.addDays(20));
            List<Holiday> holidayList = new List<Holiday>();
            holidayList.add(hd1);
            holidayList.add(hd2);
            insert holidayList;
            System.assert(hd1.Id != null, 'Holiday 1 created');
            System.assert(hd2.Id != null, 'Holiday 2 created');
            
            //attach holiday to branch
            List<fsCore__Branch_Holiday_Setup__c> branchHolidays = new List<fsCore__Branch_Holiday_Setup__c>();
            branchHolidays.add(new fsCore__Branch_Holiday_Setup__c(fsCore__Branch_Name__c));
            
        } catch (Exception e){
            hasError = true;
            errMsg = String.valueOf(e);
        }
        System.assertEquals(false, hasError, 'Test data creation assert ' + errMsg);
    }
    
    private static Holiday getTestHoliday(String pHolidayName, Date pHolidayDate){
        Holiday hd = new Holiday();
        hd.Name = pHolidayName;
        hd.ActivityDate = pHolidayDate;
        hd.IsAllDay = true;
        hd.IsRecurrence = false;
        
        System.assertNotEquals(null, hd);
        return hd;
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

}
