@isTest
private class SpectraServicingUtilTest {

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
