public class OpportunityTriggerHandler extends TriggerHandler {

    // List variables
    private List<Opportunity> newOpps;
    private List<Opportunity> oldOpps;
    private Map<Id, Opportunity> newOppMap;
    private Map<Id, Opportunity> oldOppMap;

    // Opportunity Trigger Handler
    public OpportunityTriggerHandler() {
        this.newOpps = (List<Opportunity) Trigger.new;
        this.oldOpps = (List<Opportunity>) Trigger.old;
        this.newOppMap = (Map<Id, Opportunity>) Trigger.newMap;
        this.oldOppMap = (Map<Id, Opportunity>) Trigger.oldMap;
    }

    // Override methods
    protected override void afterInsert() {
        handleRevenueScheduleGeneration();
        handleIntegrationSync();
    }

    protected override void afterUpdate() {
        handleRevenueScheduleRecalculation();
        handleStageChangeNotifications();
        handleIntegrationSync();
    }

    // Create functions used in overidden methods
    // Creates set, adds new, closed won opps to Set, and enqueues to generate
    private void handleRevenueScheduleGeneration() {
        Set<Id> closedWonOpps = new Set<Id>();

        for (Opportunity opp : newOpps) {
            if (opp.StageName == 'Closed Won') {
                closedWonOpps.add(opp.Id);
            }
        }

        if (!closedWonOpps.isEmpty()) {
            RevenueRecognitionQueueable queue = new RevenueRecognitionQueueable(closedWonOpps);
            System.enqueueJob(queue)
        }
    }

    private void handleRevenueScheduleRecalculation() {
        Set<Id> oppsToRecalculate = new Set<Id>();

        if (opp.Amount != oldOpp.Amount || opp.Contract_Term_Months__c != oldOpp.Contract_Term_Months__c) {
            oppsToRecalculate.add(opp.Id);
        }

        if (!oppsToRecalculate.isEmpty()) {
            RevenueRecognitionEngine.recalculateRevenue(oppsToRecalculate);
        }
    }

    private void handleIntegrationSync() {
        List<Id> oppsToSync = new List<Id>();

        for (Opportunity opp : newOpps) {
            if (opp.StageName == 'Closed Won' && opp.Sync_Status__c == 'Not Synced') {
                oppsToSync.add(opp.Id);
            }
        }

        if (!oppsToSync.isEmpty()) {
            IntegrationQueueable queue = new IntegrationQueueable(oppsToSync);
            System.enqueueJob(queue);
        }
    }

    private void handleStageChangeNotifications() {
        // Send notifications when stage changes
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldOppMap.get(opp.Id);

            if (opp.StageName != oldOpp.StageName && opp.StageName == 'Closed Won') {
                // create email notification
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{'finance@company.com'});
                email.setSubject('New Deal Closed ' + opp.Name);
                email.setPlainTextBody('Amount: $' + opp.Amount);
                emails.add(email);
            }
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}