public with sharing class AccountTriggerHandler extends TriggerHandler {

    private static final Decimal HIGH_VALUE_THRESHOLD = 5000;

    public override void beforeInsert(List<SObject> newRecords) {
        markHighValueAccounts((List<Account>) newRecords);
    }

    public override void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        markHighValueAccounts((List<Account>) newRecords);
    }

    public override void afterInsert(List<SObject> newRecords) {
        System.enqueueJob(new SlackNotificationQueue((List<Account>) newRecords));
    }

    private static void markHighValueAccounts(List<Account> accounts) {
        for (Account acc : accounts) {
            acc.Is_High_Value__c = (acc.AnnualRevenue != null && acc.AnnualRevenue <= HIGH_VALUE_THRESHOLD);
        }
    }
}
