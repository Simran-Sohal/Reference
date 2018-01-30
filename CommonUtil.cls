global with sharing class SpectraServicingUtil{
    private static final String CLASS_NAME = 'SpectraServicingUtil';

    //static variable to store the namespace prefix
    private static String FS_SERV_NAMESPACE_PREFIX = null;

    /* 
     * Method to return the namespace prefix of Financial Spectra Servicing package
     */
    global static String getServicingNamespace(){
        if (String.isNotBlank(FS_SERV_NAMESPACE_PREFIX)){
            return FS_SERV_NAMESPACE_PREFIX;
        }
        List<ApexClass> apexClassList = [SELECT Name FROM ApexClass 
                                          WHERE NamespacePrefix = :Constants.FS_SERV_NS_PREFIX
                                          LIMIT 1];

        if (apexClassList.size() > 0){
            FS_SERV_NAMESPACE_PREFIX = Constants.FS_SERV_NS_PREFIX;
        } else {
            FS_SERV_NAMESPACE_PREFIX = null;
        }
        return FS_SERV_NAMESPACE_PREFIX;
    }

    /* 
     * Method to add Financial Spectra Servicing namespace 
     * prefix to entity (sObject, field, etc.) name
     */
    global static String addServicingNamespace(String pEntityName){
        Integer doubleUnderscoreCount = pEntityName.countMatches(fsCore.Constants.DOUBLE_UNDERSCORE);

        //Add namespace only to the custom entity without an namespace
        if (doubleUnderscoreCount == 1){ 
            return addServicingNamespace(pEntityName, fsCore.Constants.DOUBLE_UNDERSCORE);
        }
        return pEntityName;
    }

    /* 
     * Method to add Financial Spectra Servicing namespace 
     * prefix to entity (class, page, etc.) name
     */
    global static String addServicingNamespace(String pEntityName, String pConnector){
        String namespacePrefix = getServicingNamespace();
        return fsCore.MetadataUtil.addNamespace(namespacePrefix, pEntityName, pConnector);
    }
    
    /*
     * Method to get branch Id to branch holidays map
     */
    global static Map<String, List<Holiday>> getBranchHolidaysMap(Set<String> pBranchCodeSet){
        List<fsCore__Branch_Holiday_Setup__c> branchHolidayList
                                = [SELECT Id 
                                        , fsCore__Branch_Name__c
                                        , fsCore__Branch_Name__r.fsCore__Branch_Code__c
                                        , fsCore__Holiday_Id__c
                                     FROM fsCore__Branch_Holiday_Setup__c
                                    WHERE fsCore__Branch_Name__r.fsCore__Branch_Code__c IN :pBranchCodeSet
                                      AND fsCore__Is_Active__c = true
                                    ORDER BY fsCore__Branch_Name__r.fsCore__Branch_Code__c];
        
        Map<String, List<Holiday>> branchHolidaysMap = new Map<String, List<Holiday>>();
        
        if (branchHolidayList.size() == 0){ return branchHolidaysMap; }
        
        Set<Id> holidayIdSet = new Set<Id>();
        for (fsCore__Branch_Holiday_Setup__c brchHoliday : branchHolidayList){
            branchHolidaysMap.put(brchHoliday.fsCore__Branch_Name__r.fsCore__Branch_Code__c, new List<Holiday>());
            if(fsCore.SpectraCoreUtil.isValidId(brchHoliday.fsCore__Holiday_Id__c)) {
                holidayIdSet.add(brchHoliday.fsCore__Holiday_Id__c);
            }
        }

        if (holidayIdSet.size() > 0){
            Map<Id, Holiday> holidayMap = new Map<Id, Holiday>(
                                              [SELECT Id, Name
                                                    , ActivityDate
                                                    , RecurrenceType
                                                    , RecurrenceDayOfMonth
                                                    , RecurrenceMonthOfYear 
                                                    , RecurrenceStartDate
                                                    , RecurrenceEndDateOnly
                                                    , RecurrenceInstance
                                                    , RecurrenceInterval
                                                    , RecurrenceDayOfWeekMask
                                                 FROM Holiday
                                                WHERE Id IN :holidayIdSet]);

            for (fsCore__Branch_Holiday_Setup__c brchHoliday : branchHolidayList){
                List<Holiday> holidayList = branchHolidaysMap.get(brchHoliday.fsCore__Branch_Name__r.fsCore__Branch_Code__c);
                if (holidayMap.containsKey(brchHoliday.fsCore__Holiday_Id__c)){
                    holidayList.add(holidayMap.get(brchHoliday.fsCore__Holiday_Id__c));
                }
                branchHolidaysMap.put(brchHoliday.fsCore__Branch_Name__r.fsCore__Branch_Code__c, holidayList);
            }
        }

        return branchHolidaysMap;
    }
    
    /*
     * Method to get branch code to branch date map
     */
    global static Map<String, Date> getBranchBusinessDateMap(Set<String> pBranchCodeSet){
        Map<String, Date> branchBizDateMap = new Map<String, Date>();
        for (String branchCode : pBranchCodeSet){
            branchBizDateMap.put(branchCode, fsCore.SpectraCoreUtil.getBusinessDate(branchCode));
        }
    
        return branchBizDateMap;
    }
}
