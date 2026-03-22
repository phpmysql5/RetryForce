public class SlackNotificationQueue implements Queueable, Database.AllowsCallouts {
    
    private List<Account> accounts;
    
    public SlackNotificationQueue(List<Account> accounts) {
        this.accounts = accounts;
    }
    
    public void execute(QueueableContext context) {
        List<SlackService.CalloutResult> results = new List<SlackService.CalloutResult>();

        for (Account acc : accounts) {
            results.add(SlackService.notifyAccountCreated(acc));
        }

        SlackCalloutLogService.logResults(accounts, results);
    }
}
