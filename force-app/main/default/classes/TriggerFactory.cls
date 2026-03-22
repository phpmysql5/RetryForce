public with sharing class TriggerFactory {

    public static void run(TriggerHandler handler) {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                handler.beforeInsert(Trigger.new);
            }

            if (Trigger.isUpdate) {
                handler.beforeUpdate(Trigger.new, Trigger.oldMap);
            }
        }

        if (Trigger.isAfter && Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
    }
}
