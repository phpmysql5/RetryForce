public with sharing class SlackService {
    
    // The Slack webhook URL is configured in Salesforce as the Slack_Webhook named credential.
    private static final String SLACK_WEBHOOK_ENDPOINT = 'callout:Slack_Webhook';
    private static final Integer MAX_ATTEMPTS = 3;

    public class CalloutResult {
        public Boolean success;
        public Integer statusCode;
        public Integer retryCount;
        public String errorMessage;
    }
    
    /**
     * Posts a message to Slack when an Account is created
     */
    public static CalloutResult notifyAccountCreated(Account account) {
        try {
            String messagePayload = buildAccountCreatedMessage(account);
            return sendSlackMessage(messagePayload);
        } catch (Exception e) {
            System.debug('Error sending Slack notification: ' + e.getMessage());
            CalloutResult result = new CalloutResult();
            result.success = false;
            result.statusCode = null;
            result.retryCount = 0;
            result.errorMessage = e.getMessage();
            return result;
        }
    }
    
    /**
     * Builds the JSON payload for Slack message
     */
    private static String buildAccountCreatedMessage(Account account) {
        Map<String, Object> payload = new Map<String, Object>();
        
        payload.put('text', 'New Account Created in Salesforce');
        
        List<Map<String, Object>> attachments = new List<Map<String, Object>>();
        Map<String, Object> attachment = new Map<String, Object>();
        
        attachment.put('color', '36a64f');
        attachment.put('title', account.Name);
        // Build Salesforce URL for the account record
        String recordLink = '/lightning/r/Account/' + account.Id + '/view';
        attachment.put('title_link', recordLink);
        
        List<Map<String, Object>> fields = new List<Map<String, Object>>();
        
        // Add Account Name
        Map<String, Object> nameField = new Map<String, Object>();
        nameField.put('title', 'Account Name');
        nameField.put('value', account.Name);
        nameField.put('short', true);
        fields.add(nameField);
        
        // Add Industry if available
        if (account.Industry != null) {
            Map<String, Object> industryField = new Map<String, Object>();
            industryField.put('title', 'Industry');
            industryField.put('value', account.Industry);
            industryField.put('short', true);
            fields.add(industryField);
        }
        
        // Add Annual Revenue if available
        if (account.AnnualRevenue != null) {
            Map<String, Object> revenueField = new Map<String, Object>();
            revenueField.put('title', 'Annual Revenue');
            revenueField.put('value', '$' + account.AnnualRevenue.format());
            revenueField.put('short', true);
            fields.add(revenueField);
        }
        
        // Add High Value Status
        Map<String, Object> highValueField = new Map<String, Object>();
        highValueField.put('title', 'High Value Account');
        highValueField.put('value', account.Is_High_Value__c ? 'Yes' : 'No');
        highValueField.put('short', true);
        fields.add(highValueField);
        
        attachment.put('fields', fields);
        attachment.put('footer', 'Salesforce');
        attachment.put('ts', System.now().getTime() / 1000);
        
        attachments.add(attachment);
        payload.put('attachments', attachments);
        
        return JSON.serialize(payload);
    }
    
    /**
     * Sends the actual HTTP request to Slack
     */
    private static CalloutResult sendSlackMessage(String payload) {
        Integer attempts = 0;
        Integer lastStatusCode;
        String lastErrorMessage;

        while (attempts < MAX_ATTEMPTS) {
            attempts++;

            try {
                HttpRequest request = new HttpRequest();
                request.setEndpoint(SLACK_WEBHOOK_ENDPOINT);
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');
                request.setBody(payload);
                request.setTimeout(10000);

                Http http = new Http();
                HttpResponse response = http.send(request);

                lastStatusCode = response.getStatusCode();
                if (lastStatusCode >= 200 && lastStatusCode < 300) {
                    CalloutResult result = new CalloutResult();
                    result.success = true;
                    result.statusCode = lastStatusCode;
                    result.retryCount = attempts - 1;
                    result.errorMessage = null;
                    return result;
                }

                lastErrorMessage = 'Slack API error: ' + response.getStatusCode() + ' ' + response.getBody();
                System.debug(lastErrorMessage);
            } catch (Exception e) {
                lastErrorMessage = e.getMessage();
                System.debug('Error sending Slack notification: ' + lastErrorMessage);
            }
        }

        CalloutResult result = new CalloutResult();
        result.success = false;
        result.statusCode = lastStatusCode;
        result.retryCount = attempts - 1;
        result.errorMessage = lastErrorMessage;
        return result;
    }
}
