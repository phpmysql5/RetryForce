trigger AccountTrigger on Account (before insert, before update, after insert) {
    TriggerFactory.run(new AccountTriggerHandler());
}
