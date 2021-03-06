/*
 * This class has methods to submit the apex test classes for execution and processing
 * the result of that last execution of the test classes
 *
 * Test classes to be executed automatically should be maintained in a list type 
 * Custom Setting AutomatedApexTest__c
 *     AutomatedApexTest__c.Name             -> Name of the test class
 *     AutomatedApexTest__c.LastTestJobID__c -> Id of the Async Job that executed the test class most recently
 *     AutomatedApexTest__c.IsReported__c    -> Determines whethere the results of the last test job are reported or not
 *
 * Here, we are reporting the Apex Test Results via email.
 * Enhance the processing logic to report the test failures.
 *
 * Write Schedulable classes to enqueue test classes and process the test results
 */
public with sharing class AutomatedApexTestUtil {

    /*
     * Method to enqueue all the test classes in Automated Apex Test custom setting
     */ 
    public static void enqueueTests() {
        Map<String, AutomatedApexTest__c> autoTestsMap = AutomatedApexTest__c.getAll();
        
        List<ApexClass> testClasses = [SELECT Id, Name FROM ApexClass 
                                        WHERE Name IN :autoTestsMap.keySet()];
              
        if (testClasses.size() > 0) {
            /*
             * Insertion of the ApexTestQueueItem causes the unit tests to be 
             * executed. Since they are asynchronous, the apex async job id
             * needs to be stored somewhere so we can process the test results
             * when the job is complete.
             */
            List<ApexTestQueueItem> queueItems = new List<ApexTestQueueItem>();
            for (ApexClass testClass : testClasses) {
                queueItems.add(new ApexTestQueueItem(ApexClassId=testClass.Id));
            }
            insert queueItems;

            // Get the job ID of the first queue item returned. 
            Set<Id> queuedItemsIds = new Set<Id>();
            for (ApexTestQueueItem item : queueItems){
                queuedItemsIds.add(item.Id);
            }
            
            for(ApexTestQueueItem item : [SELECT ApexClass.Name, ParentJobId FROM ApexTestQueueItem WHERE Id IN :queuedItemsIds]){
                autoTestsMap.get(item.ApexClass.Name).LastTestJobID__c = item.ParentJobId;
                autoTestsMap.get(item.ApexClass.Name).IsReported__c = false;
            }
            update autoTestsMap.values();
        }
    }
    
    /*
     * Method to processes the result of the Automated Apex Test execution
     */ 
    public static void processTestResults(){
        Set<Id> testJobIds = new Set<Id>();
        List<AutomatedApexTest__c> testsToBeReported = new List<AutomatedApexTest__c>();
        
        for (AutomatedApexTest__c autoTest : AutomatedApexTest__c.getAll().values()){
            if (!autoTest.IsReported__c && String.IsNotBlank(autoTest.LastTestJobID__c)
                    && (autoTest.LastTestJobID__c instanceOf Id)){
                testJobIds.add(autoTest.LastTestJobID__c);
                testsToBeReported.add(autoTest);
            }
        }
        
        if (testJobIds.size() == 0) {
            System.debug(loggingLevel.ERROR, 'No tests found for reporting.');
            return;
        }
        
        // Get the queued apex test classes
        List<ApexTestQueueItem> queuedItems = [SELECT ApexClass.Name
                                                    , Status
                                                    , ExtendedStatus
                                                    , ParentJobId
                                                 FROM ApexTestQueueItem 
                                                WHERE ParentJobId in :testJobIds];
        System.debug(loggingLevel.ERROR, String.valueOf(queuedItems.size()) + ' tests submitted for auto execution');

        Map<Id, List<ApexTestQueueItem>> groupedTestsByJob = new Map<Id, List<ApexTestQueueItem>>();
        
        for (ApexTestQueueItem atqi : queuedItems){
            List<ApexTestQueueItem> groupedTests = new List<ApexTestQueueItem>();
            if (groupedTestsByJob.containsKey(atqi.ParentJobId)){
                groupedTests = groupedTestsByJob.get(atqi.ParentJobId);
            }
            groupedTests.add(atqi);
            groupedTestsByJob.put(atqi.ParentJobId, groupedTests);
        }

        Set<Id> completedTestJobIds = getCompletedTestJobsIds(groupedTestsByJob);
        if (completedTestJobIds.size() == 0) return;
        
        // Get the test results 
        List<ApexTestResult> testResults = getApexTestResults(completedTestJobIds);
        System.debug(loggingLevel.ERROR, String.valueOf(testResults.size()) + ' test results generated by the automated apex test execution');

        //send email
        sendTestResultEmail(testResults);
        
        //mark tests as reported
        for (AutomatedApexTest__c autoTest : testsToBeReported){
            autoTest.IsReported__c = true;
        }
        update testsToBeReported;
    }
    
    // Get the set of completed test jobs 
    private static Set<Id> getCompletedTestJobsIds(Map<Id, List<ApexTestQueueItem>> groupedTestsByJob){
        Set<Id> completedTestJobIds = new Set<Id>();
        
        for (Id testJobID : groupedTestsByJob.keySet()){
            Boolean allCompleted = true;
            
            for (ApexTestQueueItem queuedTest : groupedTestsByJob.get(testJobId)){
                if (queuedTest.Status != 'Completed' && queuedTest.Status != 'Failed' && queuedTest.Status != 'Aborted'){
                    allCompleted = false;
                    break;
                }
            }
            
            if (allCompleted){
                System.debug(loggingLevel.ERROR, String.valueOf(groupedTestsByJob.get(testJobId).size()) + ' tests completed for Job Id ' + String.valueOf(testJobID));
                completedTestJobIds.add(testJobID);
            }
        }
        
        return completedTestJobIds;
    }

    // Get the result for each test method that was executed. 
    private static List<ApexTestResult> getApexTestResults(Set<ID> jobIds) {
        List<ApexTestResult> testResults = 
           [SELECT Outcome,
                   MethodName,
                   Message,
                   StackTrace,
                   AsyncApexJobId, 
                   ApexClass.Name,
                   ApexClass.Body,
                   ApexClass.LengthWithoutComments,
                   ApexClass.NamespacePrefix,
                   ApexClass.Status,
                   ApexLogId,
                   ApexLog.DurationMilliseconds,
                   ApexLog.Operation,
                   ApexLog.Request,
                   ApexLog.Status,
                   ApexLog.Location,
                   ApexLog.Application
              FROM ApexTestResult 
             WHERE AsyncApexJobId in :jobIds];
            
        return testResults;
    }
    
    private static void sendTestResultEmail(List<ApexTestResult> jobTestResults){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] { UserInfo.getUserEmail() };
        mail.setToAddresses(toAddresses);
        
        String emailSubject = 'Automated Apex Test Results ' + String.valueOf(Date.today()); 
        mail.setSubject(emailSubject);

        String testResultEmailbody = getTestResultHtmlEmailBody(jobTestResults);
        mail.setHtmlBody(testResultEmailbody);

        Messaging.sendEmail(new Messaging.Email[] { mail });
    }
    
    private static String getTestResultHtmlEmailBody(List<ApexTestResult> jobTestResults){
        List<ApexTestResult> successTests = new List<ApexTestResult>();
        List<ApexTestResult> failedTests = new List<ApexTestResult>();
        
        for (ApexTestResult jobTestResult : jobTestResults){
            if (jobTestResult.Outcome == 'Pass'){
                successTests.add(jobTestResult);
            }
            else{
                failedTests.add(jobTestResult);
            }
        }
        
        Integer numSuccess = successTests.size();
        Integer numFailures = failedTests.size();
        Integer numTestsRun = successTests.size() + failedTests.size();
        
        String testResultBody = '<div style="margin: 5px 0px; font-weight: bold;">Automated Apex Test Results</div>';
        testResultBody += '<br/>';
        testResultBody += '<table><tbody>';
        testResultBody += '<tr><td>Tests Run:</td><td style="text-align: right;">' + numTestsRun + '</td></tr>';
        testResultBody += '<tr><td>Success Count:</td><td style="text-align: right;">' + numSuccess + '</td></tr>';
        testResultBody += '<tr><td>Failure Count:</td><td style="text-align: right;">' + numFailures + '</td></tr>';
        testResultBody += '</tbody></table><br/><br/>';
                
        if (numFailures > 0){
            testResultBody += '<div style="margin: 5px 0px; font-weight: bold;">Test Failures</div>';
            testResultBody += '<table>';
            testResultBody += '<thead>';
            testResultBody += '<th style="text-align: left; padding-left: 5px;">Test Class</th>';
            testResultBody += '<th style="text-align: left; padding-left: 5px;">Unit Test</th>';
            testResultBody += '<th style="text-align: left; padding-left: 5px;">Message</th>';
            testResultBody += '<th style="text-align: left; padding-left: 5px;">Stack Trace</th>';
            testResultBody += '<th style="text-align: left; padding-left: 5px;">Time (Ms)</th>';
            testResultBody += '</thead>';
            testResultBody += '<tbody>';
            for (ApexTestResult testFailure : failedTests){
                testResultBody += '<tr>';
                testResultBody += '<td style="padding: 5px; vertical-align: top;">' + testFailure.ApexClass.Name +'</td>';
                testResultBody += '<td style="padding: 5px; vertical-align: top;">' + testFailure.MethodName +'</td>';
                testResultBody += '<td style="padding: 5px; vertical-align: top;">' + testFailure.message +'</td>';
                testResultBody += '<td style="padding: 5px; vertical-align: top;">' + testFailure.stackTrace +'</td>';
                testResultBody += '<td style="padding: 5px; vertical-align: top;">' + testFailure.ApexLog.DurationMilliseconds +'</td>';
                testResultBody += '</tr>';
            }
            testResultBody += '</tbody>';
            testResultBody += '</table>';
        }       
        
        return testResultBody;
    }
}
