public with sharing class IntegrationService {

    public static void send(String endpoint, String requestBody, String handlerClass) {
        // Step 1: Create a Pending log record
        Integration_Log__c log = IntegrationLogger.logRequest(endpoint, requestBody, handlerClass);

        if (log == null) {
            return;
        }

        try {
            // Step 2: Dynamically instantiate the handler by class name
            Type handlerType = Type.forName(handlerClass);
            if (handlerType == null) {
                throw new IntegrationServiceException('Handler class not found: ' + handlerClass);
            }

            // Step 3: Cast to IntegrationHandler interface
            IntegrationHandler handler = (IntegrationHandler) handlerType.newInstance();

            // Step 4: Execute the handler — plug-in does its work
            handler.execute(log);

        } catch (Exception ex) {
            // Step 5: On any failure, mark log as Failed and capture the error
            log.Status__c = 'Failed';
            log.Error_Message__c = ex.getMessage();
            update log;
        }
    }

    public class IntegrationServiceException extends Exception {}
}
