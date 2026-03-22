@IsTest
private class RetryFailedIntegrationsTest {

    @IsTest
    static void testRetriesFailedRecordToSuccess() {
        Integration_Log__c failedLog = new Integration_Log__c(
            Endpoint__c = 'https://example.com/retry',
            Request__c = '{"invoiceId":"INV-RETRY-001"}',
            Handler_Class__c = 'SampleInvoiceHandler',
            Status__c = 'Failed',
            Retry_Count__c = 0,
            Error_Message__c = 'Initial failure'
        );
        insert failedLog;

        Test.startTest();
        System.enqueueJob(new RetryFailedIntegrations());
        Test.stopTest();

        Integration_Log__c updated = [
            SELECT Status__c, Retry_Count__c, Response__c, Error_Message__c
            FROM Integration_Log__c
            WHERE Id = :failedLog.Id
        ];

        System.assertEquals(1, Integer.valueOf(updated.Retry_Count__c), 'Retry count should increment by 1');
        System.assertEquals('Success', updated.Status__c, 'Status should become Success after retry');
        System.assertEquals('Success Response', updated.Response__c, 'Response should be populated by handler');
        System.assertEquals(null, updated.Error_Message__c, 'Error message should clear on success');
    }

    @IsTest
    static void testDoesNotRetryWhenCircuitBreakerReached() {
        Integration_Log__c maxedLog = new Integration_Log__c(
            Endpoint__c = 'https://example.com/maxed',
            Request__c = '{"invoiceId":"INV-MAX-001"}',
            Handler_Class__c = 'SampleInvoiceHandler',
            Status__c = 'Failed',
            Retry_Count__c = 5,
            Error_Message__c = 'Exceeded retries'
        );
        insert maxedLog;

        Test.startTest();
        System.enqueueJob(new RetryFailedIntegrations());
        Test.stopTest();

        Integration_Log__c unchanged = [
            SELECT Status__c, Retry_Count__c, Response__c, Error_Message__c
            FROM Integration_Log__c
            WHERE Id = :maxedLog.Id
        ];

        System.assertEquals(5, Integer.valueOf(unchanged.Retry_Count__c), 'Retry count should not change at max limit');
        System.assertEquals('Failed', unchanged.Status__c, 'Status should remain Failed when retries are maxed');
        System.assertEquals(null, unchanged.Response__c, 'No handler should run when max retries reached');
        System.assertEquals('Exceeded retries', unchanged.Error_Message__c, 'Original error should remain unchanged');
    }
}
