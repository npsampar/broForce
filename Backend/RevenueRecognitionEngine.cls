public class RevenueRecognitionEngine {
    
    public class RevenueSchedule {
        public Date startDate;
        public Date endDate;
        public Decimal monthlyAmount;
        public String method;
    }
    
    public static void generateRevenueSchedule(Id opportunityId) {
        Opportunity opp = [
            SELECT Amount, CloseDate, Contract_Term_Months__c, 
                   Revenue_Type__c
            FROM Opportunity
            WHERE Id = :opportunityId
        ];
        
        if (opp.Revenue_Type__c == 'Subscription') {
            generateSubscriptionSchedule(opp);
        } else if (opp.Revenue_Type__c == 'Multi-year') {
            generateMultiYearSchedule(opp);
        } else {
            generateOneTimeSchedule(opp);
        }
    }
    
    private static void generateSubscriptionSchedule(Opportunity opp) {
        List<Revenue_Schedule__c> schedules = new List<Revenue_Schedule__c>();
        
        Decimal monthlyAmount = opp.Amount / opp.Contract_Term_Months__c;
        Date startDate = opp.CloseDate;
        
        for (Integer i = 0; i < opp.Contract_Term_Months__c; i++) {
            Revenue_Schedule__c schedule = new Revenue_Schedule__c(
                Opportunity__c = opp.Id,
                Recognition_Start_Date__c = startDate.addMonths(i),
                Recognition_End_Date__c = startDate.addMonths(i + 1).addDays(-1),
                Monthly_Amount__c = monthlyAmount,
                Total_Amount__c = monthlyAmount,
                Status__c = 'Active',
                Recognition_Method__c = 'Straight-line',
                Compliance_Standard__c = 'ASC 606'
            );
            schedules.add(schedule);
        }
        
        insert schedules;
    }
    
    /**
     * Generates revenue schedule records for multi-year contracts
     * Divides total opportunity amount equally across contract years
     * Handles partial years at the end of contract terms
     * Uses ASC 606 straight-line recognition method
     * 
     * @param opp - Opportunity record containing contract amount and term length
     */
    private static void generateMultiYearSchedule(Opportunity opp) {
        // Initialize list to hold all yearly revenue schedule records
        List<Revenue_Schedule__c> schedules = new List<Revenue_Schedule__c>();
        
        // Calculate annual revenue amount: convert monthly rate to annual
        Decimal annualAmount = opp.Amount / opp.Contract_Term_Months__c * 12;
        
        // Set contract start date from opportunity close date
        Date startDate = opp.CloseDate;
        
        // Calculate total number of years needed to cover entire contract term
        Integer totalYears = Integer.valueOf(Math.ceil(opp.Contract_Term_Months__c / 12));
        
        // Iterate through each year of the contract
        for (Integer i = 0; i < totalYears; i++) {
            // Calculate year start and end dates (end of year is last day before next year starts)
            Date yearStart = startDate.addYears(i);
            Date yearEnd = startDate.addYears(i + 1).addDays(-1);
            
            // Initialize amount for current year (default to full annual amount)
            Decimal yearAmount = annualAmount;
            
            // Check if this is the final year and contract doesn't end on year boundary
            if (i == totalYears - 1 && Math.mod(Integer.valueOf(opp.Contract_Term_Months__c), 12) != 0) {
                // Calculate remaining months in final year
                Integer remainingMonths = Math.mod(Integer.valueOf(opp.Contract_Term_Months__c), 12);
                // Adjust final year amount to only cover remaining months
                yearAmount = (opp.Amount / opp.Contract_Term_Months__c) * remainingMonths;
                // Adjust final year end date to contract end date
                yearEnd = yearStart.addMonths(remainingMonths).addDays(-1);
            }
            
            // Create revenue schedule record for this year
            Revenue_Schedule__c schedule = new Revenue_Schedule__c(
                Opportunity__c = opp.Id,
                Recognition_Start_Date__c = yearStart,
                Recognition_End_Date__c = yearEnd,
                Monthly_Amount__c = yearAmount / 12,  // Divide annual amount by 12 for monthly rate
                Total_Amount__c = yearAmount,          // Total revenue to recognize this year
                Status__c = 'Active',
                Recognition_Method__c = 'Straight-line',  // Evenly distribute revenue across period
                Compliance_Standard__c = 'ASC 606'    // Follows ASC 606 revenue recognition standard
            );
            schedules.add(schedule);
        }
        
        // Insert all yearly schedules into database
        insert schedules;
    }
    
    private static void generateOneTimeSchedule(Opportunity opp) {
        Revenue_Schedule__c schedule = new Revenue_Schedule__c(
            Opportunity__c = opp.Id,
            Recognition_Start_Date__c = opp.CloseDate,
            Recognition_End_Date__c = opp.CloseDate,
            Total_Amount__c = opp.Amount,
            Monthly_Amount__c = opp.Amount,
            Status__c = 'Completed',
            Recognition_Method__c = 'Milestone-based',
            Compliance_Standard__c = 'ASC 606'
        );
        insert schedule;
    }
    
    // Recalculation when contract terms change
    public static void recalculateRevenue(Set<Id> opportunityIds) {
        // Delete existing schedules
        delete [
            SELECT Id FROM Revenue_Schedule__c 
            WHERE Opportunity__c IN :opportunityIds
        ];
        
        // Regenerate
        for (Id oppId : opportunityIds) {
            generateRevenueSchedule(oppId);
        }
    }
}