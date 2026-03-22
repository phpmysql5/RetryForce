public with sharing class IntegrationDashboardController {

    @AuraEnabled(cacheable=true)
    public static List<Integration_Log__c> getFailedLogs() {
        return [
            SELECT Id, Endpoint__c, Status__c, Retry_Count__c, CreatedDate, Handler_Class__c, Error_Message__c, Response__c
            FROM Integration_Log__c
            WHERE Status__c = 'Failed'
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];
    }

    @AuraEnabled
    public static Integration_Log__c retrySingle(Id logId) {
        if (logId == null) {
            throw new AuraHandledException('Log Id is required.');
        }

        Integration_Log__c logRecord = [
            SELECT Id, Status__c, Retry_Count__c, Handler_Class__c, Error_Message__c, Response__c
            FROM Integration_Log__c
            WHERE Id = :logId
            LIMIT 1
            FOR UPDATE
        ];

        try {
            Integer currentRetry = (logRecord.Retry_Count__c == null)
                ? 0
                : Integer.valueOf(logRecord.Retry_Count__c);

            logRecord.Retry_Count__c = currentRetry + 1;
            logRecord.Status__c = 'Retrying';
            update logRecord;

            Type handlerType = Type.forName(logRecord.Handler_Class__c);
            if (handlerType == null) {
                throw new AuraHandledException('Handler class not found: ' + logRecord.Handler_Class__c);
            }

            IntegrationHandler handler = (IntegrationHandler) handlerType.newInstance();
            handler.execute(logRecord);

            Integration_Log__c refreshed = [
                SELECT Id, Endpoint__c, Status__c, Retry_Count__c, CreatedDate, Handler_Class__c, Error_Message__c, Response__c
                FROM Integration_Log__c
                WHERE Id = :logId
                LIMIT 1
            ];

            if (refreshed.Status__c != 'Success' || refreshed.Error_Message__c != null) {
                refreshed.Status__c = 'Success';
                refreshed.Error_Message__c = null;
                update refreshed;
            }

            return refreshed;
        } catch (Exception ex) {
            Integration_Log__c failed = [
                SELECT Id, Endpoint__c, Status__c, Retry_Count__c, CreatedDate, Handler_Class__c, Error_Message__c, Response__c
                FROM Integration_Log__c
                WHERE Id = :logId
                LIMIT 1
            ];
            failed.Status__c = 'Failed';
            failed.Error_Message__c = ex.getMessage();
            update failed;

            throw new AuraHandledException('Retry failed: ' + ex.getMessage());
        }
    }
}
