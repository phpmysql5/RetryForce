@IsTest
private class SampleInvoiceHandlerTest {

    @IsTest
    static void testExecuteSetsSuccessOnLog() {
        // Arrange: create a Pending log record
        Integration_Log__c log = new Integration_Log__c(
            Endpoint__c = 'https://example.com/invoices',
            Request__c = '{"invoiceId":"INV-001"}',
            Handler_Class__c = 'SampleInvoiceHandler',
            Status__c = 'Pending',
            Retry_Count__c = 0
        );
        insert log;

        // Act: run the plug-in handler
        Test.startTest();
        IntegrationHandler handler = new SampleInvoiceHandler();
        handler.execute(log);
        Test.stopTest();

        // Assert: record updated to Success
        Integration_Log__c updated = [
            SELECT Status__c, Response__c
            FROM Integration_Log__c
            WHERE Id = :log.Id
        ];
        System.assertEquals('Success', updated.Status__c, 'Status should be Success');
        System.assertEquals('Success Response', updated.Response__c, 'Response should be populated');
    }
}
