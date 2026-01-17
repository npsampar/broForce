/**
 * Queueable job for asynchronously processing revenue schedule generation
 * Implements Queueable interface to handle revenue recognition calculations
 * without blocking transaction execution
 * 
 * Use case: When multiple opportunities need revenue schedules generated,
 * queue this job to avoid governor limits and timeouts
 */
public class RevenueRecognitionQueueable implements Queueable {
    
    // Set of opportunity IDs to process for revenue schedule generation
    private Set<Id> opportunityIds;
    
    /**
     * Constructor to initialize queueable job with opportunity IDs
     * 
     * @param oppIds - Set of opportunity record IDs to process
     */
    public RevenueRecognitionQueueable(Set<Id> oppIds) {
        this.opportunityIds = oppIds;
    }
    
    /**
     * Execute method called by Salesforce when job is dequeued
     * Processes each opportunity and generates its revenue schedule
     * Executes asynchronously to avoid hitting CPU time limits
     * 
     * @param context - QueueableContext providing execution information
     */
    public void execute(QueueableContext context) {
        // Iterate through all opportunity IDs in the queue
        for (Id oppId : opportunityIds) {
            // Generate revenue schedule for each opportunity
            // This delegates to RevenueRecognitionEngine for actual calculations
            RevenueRecognitionEngine.generateRevenueSchedule(oppId);
        }
    }
}