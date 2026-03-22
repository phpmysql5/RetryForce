@isTest
public class SlackServiceTest {

    @isTest
    static void testNotifyAccountCreatedSuccess() {
        SequencedSlackCalloutMock mock = new SequencedSlackCalloutMock(
            new List<Integer>{ 200 },
            new List<String>{ 'OK' }
        );
        Test.setMock(HttpCalloutMock.class, mock);
        
        Account acc = new Account(Name = 'Test Account', 
                                  Industry = 'Technology', 
                                  AnnualRevenue = 2000000,
                                  Is_High_Value__c = true);
        
        SlackService.CalloutResult result;

        Test.startTest();
        result = SlackService.notifyAccountCreated(acc);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Expected the Slack callout to succeed');
        System.assertEquals(200, result.statusCode, 'Expected a 200 response');
        System.assertEquals(0, result.retryCount, 'Expected no retries for a successful callout');
        System.assertEquals(1, mock.invocationCount, 'Expected exactly one callout attempt');
    }

    @isTest
    static void testNotifyAccountCreatedWithoutRevenue() {
        SequencedSlackCalloutMock mock = new SequencedSlackCalloutMock(
            new List<Integer>{ 200 },
            new List<String>{ 'OK' }
        );
        Test.setMock(HttpCalloutMock.class, mock);
        
        Account acc = new Account(Name = 'Test Account No Revenue', 
                                  Industry = 'Finance',
                                  Is_High_Value__c = false);
        
        SlackService.CalloutResult result;

        Test.startTest();
        result = SlackService.notifyAccountCreated(acc);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Expected the Slack callout to succeed without revenue');
        System.assertEquals(0, result.retryCount, 'Expected no retries for a successful callout');
    }

    @isTest
    static void testNotifyAccountCreatedRetriesThenSucceeds() {
        SequencedSlackCalloutMock mock = new SequencedSlackCalloutMock(
            new List<Integer>{ 500, 502, 200 },
            new List<String>{ 'Internal Server Error', 'Bad Gateway', 'OK' }
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Account acc = new Account(Name = 'Retry Success Account', AnnualRevenue = 1500000);

        SlackService.CalloutResult result;

        Test.startTest();
        result = SlackService.notifyAccountCreated(acc);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Expected the Slack callout to eventually succeed');
        System.assertEquals(200, result.statusCode, 'Expected the final status code to be 200');
        System.assertEquals(2, result.retryCount, 'Expected two retries before success');
        System.assertEquals(3, mock.invocationCount, 'Expected three total attempts');
    }

    @isTest
    static void testNotifyAccountCreatedHttpError() {
        SequencedSlackCalloutMock mock = new SequencedSlackCalloutMock(
            new List<Integer>{ 500, 500, 500 },
            new List<String>{ 'Internal Server Error', 'Internal Server Error', 'Internal Server Error' }
        );
        Test.setMock(HttpCalloutMock.class, mock);
        
        Account acc = new Account(Name = 'Test Account', AnnualRevenue = 1500000);

        SlackService.CalloutResult result;
        
        Test.startTest();
        result = SlackService.notifyAccountCreated(acc);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Expected the Slack callout to fail after max attempts');
        System.assertEquals(500, result.statusCode, 'Expected the final status code to be captured');
        System.assertEquals(2, result.retryCount, 'Expected two retries after the initial attempt');
        System.assert(result.errorMessage.contains('Slack API error'), 'Expected the error message to capture the Slack error');
        System.assertEquals(3, mock.invocationCount, 'Expected the service to exhaust all retry attempts');
    }

    private class SequencedSlackCalloutMock implements HttpCalloutMock {
        private List<Integer> configuredStatusCodes;
        private List<String> configuredBodies;
        public Integer invocationCount = 0;

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
