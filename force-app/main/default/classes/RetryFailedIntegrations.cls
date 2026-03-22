public with sharing class RetryFailedIntegrations implements Queueable {

    public void execute(QueueableContext context) {
        List<Integration_Log__c> failedLogs = [
            SELECT Id, Status__c, Retry_Count__c, Handler_Class__c, Error_Message__c
            FROM Integration_Log__c
            WHERE Status__c = 'Failed'
              AND Retry_Count__c < 5
            LIMIT 200
        ];

        if (failedLogs.isEmpty()) {
            return;
        }

        for (Integration_Log__c logRecord : failedLogs) {
            Integer currentRetry = (logRecord.Retry_Count__c == null)
                ? 0
                : Integer.valueOf(logRecord.Retry_Count__c);

            logRecord.Retry_Count__c = currentRetry + 1;
            logRecord.Status__c = 'Retrying';

            try {
                Type handlerType = Type.forName(logRecord.Handler_Class__c);
                if (handlerType == null) {
                    throw new RetryFailedIntegrationsException(
                        'Handler class not found: ' + logRecord.Handler_Class__c
                    );
                }

                IntegrationHandler handler = (IntegrationHandler) handlerType.newInstance();
                handler.execute(logRecord);

                logRecord.Status__c = 'Success';
                logRecord.Error_Message__c = null;
            } catch (Exception ex) {
                logRecord.Status__c = 'Failed';
                logRecord.Error_Message__c = ex.getMessage();
            }
        }

        update failedLogs;
    }

    public class RetryFailedIntegrationsException extends Exception {}
}
