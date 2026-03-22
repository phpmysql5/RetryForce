public with sharing class IntegrationLogger {

    public static Integration_Log__c logRequest(String endpoint, String requestBody, String handlerClass) {
        if (!Schema.sObjectType.Integration_Log__c.isCreateable()) {
            return null;
        }

        Integration_Log__c logRecord = new Integration_Log__c(
            Endpoint__c = endpoint,
            Request__c = requestBody,
            Handler_Class__c = handlerClass,
            Status__c = 'Pending',
            Retry_Count__c = 0
        );

        insert logRecord;
        return logRecord;
    }
}
