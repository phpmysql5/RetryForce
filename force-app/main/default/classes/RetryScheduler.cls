public with sharing class RetryScheduler implements Schedulable {

    public void execute(SchedulableContext context) {
        System.enqueueJob(new RetryFailedIntegrations());
    }

    public static void scheduleEveryTenMinutes() {
        // Runs every 10 minutes at second 0.
        String cronExpression = '0 0/10 * * * ?';
        System.schedule('Retry Failed Integrations - Every 10 Minutes', cronExpression, new RetryScheduler());
    }
}
