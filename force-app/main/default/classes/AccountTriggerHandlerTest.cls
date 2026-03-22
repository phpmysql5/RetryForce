@isTest
public class AccountTriggerHandlerTest {

    @isTest
    static void testHighValueAccountOnInsert() {
        Account acc = new Account(Name = 'High Value Corp', AnnualRevenue = 5000);
        insert acc;

        acc = [SELECT Is_High_Value__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(true, acc.Is_High_Value__c, 'Account with AnnualRevenue <= 5000 should be marked as high value');
    }

    @isTest
    static void testLowValueAccountOnInsert() {
        Account acc = new Account(Name = 'Low Value Corp', AnnualRevenue = 6000);
        insert acc;

        acc = [SELECT Is_High_Value__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(false, acc.Is_High_Value__c, 'Account with AnnualRevenue > 5000 should not be marked as high value');
    }

    @isTest
    static void testNullRevenueOnInsert() {
        Account acc = new Account(Name = 'No Revenue Corp');
        insert acc;

        acc = [SELECT Is_High_Value__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(false, acc.Is_High_Value__c, 'Account with null AnnualRevenue should not be marked as high value');
    }

    @isTest
    static void testAccountUpdateBecomesHighValue() {
        Account acc = new Account(Name = 'Growing Corp', AnnualRevenue = 15000);
        insert acc;

        acc.AnnualRevenue = 5000;
        update acc;

        acc = [SELECT Is_High_Value__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(true, acc.Is_High_Value__c, 'Account updated to AnnualRevenue <= 5000 should be marked as high value');
    }

    @isTest
    static void testAccountUpdateLosesHighValue() {
        Account acc = new Account(Name = 'Declining Corp', AnnualRevenue = 4000);
        insert acc;

        acc.AnnualRevenue = 100000;
        update acc;

        acc = [SELECT Is_High_Value__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(false, acc.Is_High_Value__c, 'Account updated to AnnualRevenue > 5000 should no longer be high value');
    }

    @isTest
    static void testBulkInsert() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Bulk Account ' + i,
                AnnualRevenue = (i < 100) ? 4000 : 6000
            ));
        }
        insert accounts;

        List<Account> highValue = [SELECT Id FROM Account WHERE Is_High_Value__c = true];
        List<Account> lowValue  = [SELECT Id FROM Account WHERE Is_High_Value__c = false];

        System.assertEquals(100, highValue.size(), 'Should have 100 high value accounts');
        System.assertEquals(100, lowValue.size(),  'Should have 100 low value accounts');
    }

    @isTest
    static void testAfterInsertCreatesSuccessLog() {
        SequencedSlackCalloutMock mock = new SequencedSlackCalloutMock(
            new List<Integer>{ 200 },
            new List<String>{ 'OK' }
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Account acc = new Account(Name = 'Logged Success Account', AnnualRevenue = 3000);

        Test.startTest();
        insert acc;
        Test.stopTest();

        Slack_Callout_Log__c logRecord = [
            SELECT Account__c, Outcome__c, Status_Code__c, Retry_Count__c, Error_Message__c
            FROM Slack_Callout_Log__c
            WHERE Account__c = :acc.Id
            LIMIT 1
        ];

        System.assertEquals(acc.Id, logRecord.Account__c, 'Expected the log to reference the inserted account');
        System.assertEquals('Success', logRecord.Outcome__c, 'Expected a successful log outcome');
        System.assertEquals(200, Integer.valueOf(logRecord.Status_Code__c), 'Expected the success status code to be stored');
        System.assertEquals(0, Integer.valueOf(logRecord.Retry_Count__c), 'Expected zero retries for a successful first attempt');
        System.assertEquals(null, logRecord.Error_Message__c, 'Expected no error message for successful callouts');
    }

    @isTest
    static void testAfterInsertCreatesFailureLogWithRetryCount() {
        SequencedSlackCalloutMock mock = new SequencedSlackCalloutMock(
            new List<Integer>{ 500, 500, 500 },
            new List<String>{ 'Internal Server Error', 'Internal Server Error', 'Internal Server Error' }
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Account acc = new Account(Name = 'Logged Failure Account', AnnualRevenue = 2500);

        Test.startTest();
        insert acc;
        Test.stopTest();

        Slack_Callout_Log__c logRecord = [
            SELECT Outcome__c, Status_Code__c, Retry_Count__c, Error_Message__c
            FROM Slack_Callout_Log__c
            WHERE Account__c = :acc.Id
            LIMIT 1
        ];

        System.assertEquals('Error', logRecord.Outcome__c, 'Expected a failed log outcome');
        System.assertEquals(500, Integer.valueOf(logRecord.Status_Code__c), 'Expected the final status code to be stored');
        System.assertEquals(2, Integer.valueOf(logRecord.Retry_Count__c), 'Expected retry count to capture retries after the first attempt');
        System.assert(logRecord.Error_Message__c.contains('Slack API error'), 'Expected the final error message to be stored');
    }

    private class SequencedSlackCalloutMock implements HttpCalloutMock {
        private List<Integer> configuredStatusCodes;
        private List<String> configuredBodies;
        private Integer invocationCount = 0;

        public SequencedSlackCalloutMock(List<Integer> statusCodes, List<String> bodies) {
            configuredStatusCodes = new List<Integer>(statusCodes);
            configuredBodies = new List<String>(bodies);
        }

        public HttpResponse respond(HttpRequest request) {
            Integer responseIndex = Math.min(invocationCount, configuredStatusCodes.size() - 1);
            invocationCount++;

            HttpResponse response = new HttpResponse();
            response.setStatusCode(configuredStatusCodes[responseIndex]);
            response.setBody(configuredBodies[responseIndex]);
            return response;
        }
    }
}
