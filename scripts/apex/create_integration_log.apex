Integration_Log__c logRecord = IntegrationLogger.logRequest(
    'https://example.com/api/retryforce',
    '{"event":"retryforce","source":"execute-anonymous"}',
    'RetryForceHandler'
);

System.debug('Created Integration Log Id: ' + logRecord.Id);
