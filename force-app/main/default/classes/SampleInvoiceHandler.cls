public with sharing class SampleInvoiceHandler implements IntegrationHandler {
    public void execute(Integration_Log__c log) {
        // Simulate an API call (no real HTTP callout needed for plug-in demo)
        log.Response__c = 'Success Response';
        log.Status__c = 'Success';
        update log;
    }
}
