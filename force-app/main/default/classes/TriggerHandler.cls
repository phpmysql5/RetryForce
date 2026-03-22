public virtual class TriggerHandler {

    public virtual void beforeInsert(List<SObject> newRecords) {
        return;
    }

    public virtual void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        return;
    }

    public virtual void afterInsert(List<SObject> newRecords) {
        return;
    }
}
