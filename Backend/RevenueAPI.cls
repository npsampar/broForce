@RestResource(urlMapping='/revenue/opporunity') // Defines class as REST API Endpoint
// global means the class can be accessed anywhere, including outside the org
// global is more permissive than public
global class RevenueAPI {

    @HttpPost
    global static String createOpportunity() {
         // RestRequest is a System class that represents HTTP request
         // RestContext is a system-provided context holder for your REST API call
         // Context holder is a special object that holds all the relevant information about the current execution environment
         // Keeps track of who is requesting and responding
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            // Parse incoming data
            // Create Hashmap of String to Object
            // Unloads JSON data as Apex native structure like Map or List
            Map<String, Object> requestData = (Map<string, Object) JSON.deserializeUntyped(req.requestBody.toString());

            // Create an opportunity and get data from JSON
            Opportunity opp = new Opportunity();
            opp.Name = (String) requestData.get('name');
            opp.Amount = (Decimal) requestData.get('amount');
            opp.CloseDate = Date.valueOf((String) request.Data.get('closeDate'));
            opp.StageName = (String) requestData.get('stage');
            opp.External_Org_ID__c = (String requestData.get('sourceId'));

            // Insert the opportunity to Opportunity object
            insert opp;

            // Return the status code of the API
            res.statusCode = 200;

            // Return JSON
            return JSON.serialize(new Map<String, Object>{
                'success' => true,
                'opportunityId' => opp.Id
            });
        } catch (Exception e) {
            res.StatusCode = 500;
            return JSON.serialize(new Map<String, Object>{
                'success' => false,
                'error' => e.getMessage()
            })
        }
        }
    }

    @HttpGet
    global static String getOpportunity() {
        RestRequest req = RestContext.request;
        String oppId = req.requestURI.substring(
            req.requestURI.lastIndexOf('/') + 1
        ); // Extracts the last part of URL assuming it is an opp ID

        Opportunity opp = [
            SELECT Id, Name, Amount, StageName, CloseDate
            FROM Opportunity
            WHERE Id = :oppId OR External_Org_ID__c = :opp.Id
        ]
    }
}