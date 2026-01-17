public virtual class TriggerHandler {
    // Virtual classes can be extended by another class and functions can be overidden
    protected Boolean isTriggerExecuting;
    protected Integer triggerSize;

    // Contructor for trigger handler
    // Initialized with Variables from Trigger class
    public TriggerHandler() {
        this.isTriggerExecuting = Trigger.isExecuting;
        this.triggerSize = Trigger.size;
    }

    // run trigger
    public void run() {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                this.beforeInsert();
            } else if (Trigger.isUpdate) {
                this.beforeUpdate();
            } else if (Trigger.isDelete) {
                this.beforeDelete();
            }
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                this.afterInsert()
            } else if (Trigger.isUpdate) {
                this.afterUpdate();
            } else if (Trigger.isDelete) {
                this.afterDelete();
            } else if (Trigger.isUndelete) {
                this.afterUndelete();
            }
        }
    }

    // Create Methods here
    protected virtual void beforeInsert() {}
    protected virtual void beforeUpdate() {}
    protected virtual void beforeDelete() {}
    protected virtual void afterInsert() {}
    protected virtual void afterUpdate() {}
    protected virtual void afterDelete() {}
    protected virtual void afterUndelete() {}

}