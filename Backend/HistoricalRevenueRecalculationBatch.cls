/**
 * Batch job for recalculating revenue schedules for historical opportunities
 * Implements Database.Batchable to process large volumes of closed opportunities
 * without hitting governor limits
 * 
 * Use case: When revenue recognition rules change, run this batch to
 * regenerate schedules for all previously closed opportunities
 * 
 * Execution: System.scheduleBatch(new HistoricalRevenueRecalculationBatch(), 
 *            'Revenue Recalculation', 1)
 */
public class HistoricalRevenueRecalculationBatch implements Database.Batchable<SObject> {
    
    /**
     * Start method - defines the scope of records to process
     * Queries all closed won opportunities with defined revenue types
     * Batches will process these records in chunks
     * 
     * @param bc - BatchableContext providing batch job information
     * @return Database.QueryLocator containing all opportunities to recalculate
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query all closed won opportunities that have revenue type defined
        // These are the opportunities requiring revenue schedule recalculation
        return Database.getQueryLocator([
            SELECT Id, Amount, Contract_Term_Months__c, 
                   Revenue_Type__c, CloseDate
            FROM Opportunity
            WHERE StageName = 'Closed Won'
            AND Revenue_Type__c != null
        ]);
    }
    
    /**
     * Execute method - processes each batch of records
     * Called for every batch (default batch size is 200 records)
     * Collects opportunity IDs and passes to revenue engine for recalculation
     * 
     * @param bc - BatchableContext providing batch job information
     * @param scope - List of Opportunity records in current batch
     */
    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        // Initialize set to hold opportunity IDs from current batch
        Set<Id> oppIds = new Set<Id>();
        
        // Extract all opportunity IDs from batch scope
        for (Opportunity opp : scope) {
            oppIds.add(opp.Id);
        }
        
        // Delegate to RevenueRecognitionEngine to recalculate schedules
        // This deletes old schedules and regenerates them based on current rules
        RevenueRecognitionEngine.recalculateRevenue(oppIds);
    }
    
    /**
     * Finish method - executes after all batches complete
     * Queries batch job statistics and sends completion email notification
     * 
     * @param bc - BatchableContext providing batch job information and ID
     */
    public void finish(Database.BatchableContext bc) {
        // Query batch job details to get processing statistics
        AsyncApexJob job = [
            SELECT TotalJobItems, NumberOfErrors, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];
        
        // Create notification email with batch execution summary
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{job.CreatedBy.Email});
        email.setSubject('Revenue Recalculation Complete');
        // Include batch statistics: total batches processed and error count
        email.setPlainTextBody('Processed ' + job.TotalJobItems + 
                               ' batches with ' + job.NumberOfErrors + ' errors.');
        // Send completion notification email
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    }
}