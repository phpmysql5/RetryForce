public with sharing class AccountTriggerHandler {

    private static final Decimal HIGH_VALUE_THRESHOLD = 10000;

    public static void handle(List<Account> newAccounts) {
        markHighValueAccounts(newAccounts);
    }

    public static void handleInsert(List<Account> newAccounts) {
        // Queue the Slack notification asynchronously
        // This avoids "Callout from triggers are not supported" error
        System.enqueueJob(new SlackNotificationQueue(newAccounts));
    }

    private static void markHighValueAccounts(List<Account> accounts) {
        for (Account acc : accounts) {
            acc.Is_High_Value__c = (acc.AnnualRevenue != null && acc.AnnualRevenue > HIGH_VALUE_THRESHOLD);
        }
    }
}
