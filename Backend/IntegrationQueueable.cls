/**
 * Queueable job for asynchronously syncing opportunities to parent organization
 * Implements Queueable and Database.AllowsCallouts to handle HTTP callouts
 * without blocking transaction execution
 * 
 * Use case: When opportunities are created/updated, queue this job to sync
 * data to parent org asynchronously, avoiding callout limits in triggers
 */
public class IntegrationQueueable implements Queueable, Database.AllowsCallouts {
    
    // List of opportunity IDs to sync to parent organization
    private List<Id> opportunityIds;
    
    /**
     * Constructor to initialize queueable job with opportunity IDs
     * 
     * @param oppIds - List of opportunity record IDs to sync
     */
    public IntegrationQueueable(List<Id> oppIds) {
        this.opportunityIds = oppIds;
    }
    
    /**
     * Execute method called by Salesforce when job is dequeued
     * Syncs each opportunity to the parent organization
     * Executes asynchronously to avoid callout governor limits
     * Database.AllowsCallouts interface enables HTTP callouts in async context
     * 
     * @param context - QueueableContext providing execution information
     */
    public void execute(QueueableContext context) {
        // Iterate through all opportunity IDs queued for synchronization
        for (Id oppId : opportunityIds) {
            // Sync opportunity data to Parent_Org using IntegrationService
            // This transforms and sends data via HTTP callout to parent organization
            IntegrationService.syncOpportunity(oppId, 'Parent_Org');
        }
    }
}