@IsTest
private class IntegrationServiceTest {

    // ─── Failure plug-in: throws on execute() ───────────────────────────────
    public class FailingHandler implements IntegrationHandler {
        public void execute(Integration_Log__c log) {
            throw new IntegrationService.IntegrationServiceException('Simulated handler failure');
        }
    }

    // ─── SUCCESS SCENARIO ────────────────────────────────────────────────────
    @IsTest
    static void testSendSuccess() {
        Test.startTest();
        IntegrationService.send(
            'https://example.com/invoices',
            '{"invoiceId":"INV-001"}',
            'SampleInvoiceHandler'
        );
        Test.stopTest();

        List<Integration_Log__c> logs = [
            SELECT Status__c, Response__c, Endpoint__c, Handler_Class__c
            FROM Integration_Log__c
            WHERE Handler_Class__c = 'SampleInvoiceHandler'
            LIMIT 1
        ];

        System.assertEquals(1, logs.size(), 'One log record should be created');
        System.assertEquals('Success', logs[0].Status__c, 'Status should be Success');
        System.assertEquals('Success Response', logs[0].Response__c, 'Response should be populated');
        System.assertEquals('https://example.com/invoices', logs[0].Endpoint__c, 'Endpoint should match');
    }

    // ─── FAILURE SCENARIO ────────────────────────────────────────────────────
    @IsTest
    static void testSendFailure() {
        // Register the inner failing handler type so Type.forName can find it
        // by inserting a log and calling the service with full class path
        Integration_Log__c seedLog = new Integration_Log__c(
            Endpoint__c = 'https://example.com/fail',
            Request__c = '{}',
            Handler_Class__c = 'IntegrationServiceTest.FailingHandler',
            Status__c = 'Pending',
            Retry_Count__c = 0
        );
        insert seedLog;

        Test.startTest();
        IntegrationService.send(
            'https://example.com/fail',
            '{}',
            'IntegrationServiceTest.FailingHandler'
        );
        Test.stopTest();

        List<Integration_Log__c> logs = [
            SELECT Status__c, Error_Message__c
            FROM Integration_Log__c
            WHERE Handler_Class__c = 'IntegrationServiceTest.FailingHandler'
              AND Status__c = 'Failed'
            LIMIT 1
        ];

        System.assertEquals(1, logs.size(), 'One failed log record should exist');
        System.assertEquals('Failed', logs[0].Status__c, 'Status should be Failed');
        System.assertNotEquals(null, logs[0].Error_Message__c, 'Error message should be captured');
        System.assert(
            logs[0].Error_Message__c.contains('Simulated handler failure'),
            'Error message should contain the thrown exception message'
        );
    }
}
