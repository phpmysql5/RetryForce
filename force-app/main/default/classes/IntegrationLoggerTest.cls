@isTest
private class IntegrationLoggerTest {

    @isTest
    static void testLogRequestCreatesPendingRecord() {
        Test.startTest();
        Integration_Log__c createdRecord = IntegrationLogger.logRequest(
            'https://example.com/api/retryforce',
            '{"name":"RetryForce"}',
            'RetryForceHandler'
        );
        Test.stopTest();

        System.assertNotEquals(null, createdRecord, 'Expected logRequest to return a created record');
        System.assertNotEquals(null, createdRecord.Id, 'Expected created record Id to be populated');

        Integration_Log__c storedRecord = [
            SELECT Endpoint__c, Request__c, Handler_Class__c, Status__c, Retry_Count__c
            FROM Integration_Log__c
            WHERE Id = :createdRecord.Id
            LIMIT 1
        ];

        System.assertEquals('https://example.com/api/retryforce', storedRecord.Endpoint__c);
        System.assertEquals('{"name":"RetryForce"}', storedRecord.Request__c);
        System.assertEquals('RetryForceHandler', storedRecord.Handler_Class__c);
        System.assertEquals('Pending', storedRecord.Status__c);
        System.assertEquals(0, Integer.valueOf(storedRecord.Retry_Count__c));
    }
}
