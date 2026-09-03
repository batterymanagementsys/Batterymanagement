public with sharing class BatteryMovementHistoryController {

    @AuraEnabled(cacheable=true)
    public static List<Inventory_Transaction__c> getMovementHistory(Id batteryId) {

        if (batteryId == null) {
            throw new AuraHandledException(
                'Battery is required.'
            );
        }

        return [
            SELECT
                Id,
                Name,
                Battery__c,
                Transaction_Type__c,
                Source_Location__c,
                Source_Location__r.Name,
                Destination_Location__c,
                Destination_Location__r.Name,
                Batch_Number__c,
                Transaction_Date_Time__c,
                Reference_Number__c,
                Status__c,
                Transaction_Reason__c,
                CreatedBy.Name
            FROM Inventory_Transaction__c
            WHERE Battery__c = :batteryId
            ORDER BY Transaction_Date_Time__c ASC
        ];
    }
}