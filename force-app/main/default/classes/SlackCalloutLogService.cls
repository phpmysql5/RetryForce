public with sharing class SlackCalloutLogService {

    public static void logResults(List<Account> accounts, List<SlackService.CalloutResult> results) {
        if (!Schema.sObjectType.Slack_Callout_Log__c.isCreateable()) {
            return;
        }

        List<Slack_Callout_Log__c> logRecords = new List<Slack_Callout_Log__c>();
        Integer itemCount = Math.min(accounts.size(), results.size());

        for (Integer index = 0; index < itemCount; index++) {
            Account accountRecord = accounts[index];
            SlackService.CalloutResult result = results[index];

            logRecords.add(new Slack_Callout_Log__c(
                Account__c = accountRecord.Id,
                Outcome__c = result.success ? 'Success' : 'Error',
                Status_Code__c = result.statusCode,
                Retry_Count__c = result.retryCount,
                Error_Message__c = result.errorMessage
            ));
        }

        if (!logRecords.isEmpty()) {
            insert logRecords;
        }
    }
}
