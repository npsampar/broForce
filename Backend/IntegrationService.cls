public class IntegrationService {
    
    private static final String PARENT_ORG_ENDPOINT = 'callout:Parent_Org';
    
    // Metadata-driven field mapping
    public class FieldMapping {
        public String sourceField;
        public String targetField;
        public String transformationType; // direct, lookup, formula
    }
    
    // Main sync method
    public static void syncOpportunity(Id opportunityId, String targetOrg) {
        try {
            // Get opportunity data
            Opportunity opp = getOpportunityWithRelated(opportunityId);
            
            // Transform data based on metadata mappings
            Map<String, Object> transformedData = transformData(opp, targetOrg);
            
            // Send to target org
            HttpResponse response = sendToTargetOrg(transformedData, targetOrg);
            
            // Log the integration
            logIntegration(opportunityId, targetOrg, response);
            
        } catch (Exception e) {
            logError(opportunityId, targetOrg, e.getMessage());
        }
    }
    
    private static Opportunity getOpportunityWithRelated(Id oppId) {
        return [
            SELECT Id, Name, Amount, StageName, CloseDate,
                   Revenue_Type__c, Contract_Term_Months__c,
                   Account.Name, Account.Industry,
                   (SELECT Id, Monthly_Amount__c, Recognition_Start_Date__c 
                    FROM Revenue_Schedules__r)
            FROM Opportunity
            WHERE Id = :oppId
        ];
    }
    
    private static Map<String, Object> transformData(
        Opportunity opp, 
        String targetOrg
    ) {
        Map<String, Object> payload = new Map<String, Object>();
        
        // Get metadata-driven mappings
        List<Integration_Field_Mapping__mdt> mappings = [
            SELECT Source_Field__c, Target_Field__c, Transformation_Type__c
            FROM Integration_Field_Mapping__mdt
            WHERE Target_Org__c = :targetOrg
            AND Source_Object__c = 'Opportunity'
        ];
        
        // Apply mappings
        for (Integration_Field_Mapping__mdt mapping : mappings) {
            Object value = getFieldValue(opp, mapping.Source_Field__c);
            payload.put(mapping.Target_Field__c, value);
        }
        
        return payload;
    }
    
    private static Object getFieldValue(SObject record, String fieldPath) {
        // Handle dot notation for related fields
        if (fieldPath.contains('.')) {
            List<String> parts = fieldPath.split('\\\\.');
            SObject currentRecord = record;
            
            for (Integer i = 0; i < parts.size() - 1; i++) {
                currentRecord = currentRecord.getSObject(parts[i]);
                if (currentRecord == null) return null;
            }
            
            return currentRecord.get(parts[parts.size() - 1]);
        }
        
        return record.get(fieldPath);
    }
    
    private static HttpResponse sendToTargetOrg(
        Map<String, Object> data, 
        String targetOrg
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(PARENT_ORG_ENDPOINT + '/services/apexrest/revenue/opportunity');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(data));
        
        Http http = new Http();
        return http.send(req);
    }
    
    private static void logIntegration(
        Id sourceId, 
        String targetOrg, 
        HttpResponse response
    ) {
        Integration_Log__c log = new Integration_Log__c(
            Source_Record_ID__c = sourceId,
            Target_Org__c = targetOrg,
            Status__c = response.getStatusCode() == 200 ? 'Success' : 'Failed',
            Payload__c = response.getBody(),
            Sync_Date__c = System.now()
        );
        insert log;
    }
    
    private static void logError(Id sourceId, String targetOrg, String error) {
        Integration_Log__c log = new Integration_Log__c(
            Source_Record_ID__c = sourceId,
            Target_Org__c = targetOrg,
            Status__c = 'Failed',
            Error_Message__c = error,
            Sync_Date__c = System.now()
        );
        insert log;
    }
}