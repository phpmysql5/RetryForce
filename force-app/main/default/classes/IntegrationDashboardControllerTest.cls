@IsTest
private class IntegrationDashboardControllerTest {

    public class DashboardTestException extends Exception {}

    public class FailingDashboardHandler implements IntegrationHandler {
        public void execute(Integration_Log__c log) {
            throw new DashboardTestException('Dashboard forced failure');
        }
    }

    @IsTest
    static void testGetFailedLogsReturnsOnlyFailed() {
        Integration_Log__c failedLog = new Integration_Log__c(
            Endpoint__c = 'https://example.com/failed',
            Request__c = '{}',
            Handler_Class__c = 'SampleInvoiceHandler',
            Status__c = 'Failed',
            Retry_Count__c = 0
        );

        Integration_Log__c successLog = new Integration_Log__c(
            Endpoint__c = 'https://example.com/success',
            Request__c = '{}',
            Handler_Class__c = 'SampleInvoiceHandler',
            Status__c = 'Success',
            Retry_Count__c = 1
        );

        insert new List<Integration_Log__c>{ failedLog, successLog };

        Test.startTest();
        List<Integration_Log__c> results = IntegrationDashboardController.getFailedLogs();
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Only failed logs should be returned');
        System.assertEquals('Failed', results[0].Status__c, 'Returned row should be failed');
        System.assertEquals('https://example.com/failed', results[0].Endpoint__c);
    }

    @IsTest
    static void testRetrySingleSuccess() {
        Integration_Log__c failedLog = new Integration_Log__c(
            Endpoint__c = 'https://example.com/retry-one',
            Request__c = '{"invoiceId":"INV-DASH-001"}',
            Handler_Class__c = 'SampleInvoiceHandler',
            Status__c = 'Failed',
            Retry_Count__c = 0,
            Error_Message__c = 'Initial failure'
        );
        insert failedLog;

        Test.startTest();
        Integration_Log__c returnedLog = IntegrationDashboardController.retrySingle(failedLog.Id);
        Test.stopTest();

        Integration_Log__c updated = [
            SELECT Status__c, Retry_Count__c, Response__c, Error_Message__c
            FROM Integration_Log__c
            WHERE Id = :failedLog.Id
        ];

        System.assertEquals('Success', updated.Status__c, 'Status should be success after manual retry');
        System.assertEquals(1, Integer.valueOf(updated.Retry_Count__c), 'Retry count should increment');
        System.assertEquals('Success Response', updated.Response__c, 'Handler should set response body');
        System.assertEquals(null, updated.Error_Message__c, 'Error should be cleared after success');
        System.assertEquals(updated.Id, returnedLog.Id, 'Returned record should match updated record');
    }

    @IsTest
    static void testRetrySingleFailure() {
        Integration_Log__c failedLog = new Integration_Log__c(
            Endpoint__c = 'https://example.com/retry-fail',
            Request__c = '{}',
            Handler_Class__c = 'IntegrationDashboardControllerTest.FailingDashboardHandler',
            Status__c = 'Failed',
            Retry_Count__c = 0,
            Error_Message__c = 'Old error'
        );
        insert failedLog;

        Test.startTest();
        try {
            IntegrationDashboardController.retrySingle(failedLog.Id);
            System.assert(false, 'Expected AuraHandledException to be thrown');
        } catch (AuraHandledException ex) {
            System.assertNotEquals(null, ex.getMessage(), 'Expected an exception message');
        }
        Test.stopTest();

        Integration_Log__c updated = [
            SELECT Status__c, Retry_Count__c, Error_Message__c
            FROM Integration_Log__c
            WHERE Id = :failedLog.Id
        ];

        System.assertEquals('Failed', updated.Status__c, 'Status should remain failed');
        System.assertEquals(1, Integer.valueOf(updated.Retry_Count__c), 'Retry count should still increment');
        System.assert(updated.Error_Message__c.contains('Dashboard forced failure'));
    }
}
