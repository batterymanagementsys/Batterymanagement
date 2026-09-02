public with sharing class BatteryFifoController {

    @AuraEnabled(cacheable=true)
    public static List<Battery__c> getFifoStock(
        Id warehouseId,
        String batchNumber
    ) {

        String query =
            'SELECT Id, Name, Battery_PIN__c, QR_Code__c, ' +
            'Serial_Number__c, Battery_Model__c, ' +
            'Batch_Number__c, Manufacturing_Date__c, ' +
            'Status__c, Inventory_Status__c, ' +
            'Current_Location__c, FIFO_Eligible__c, CreatedDate ' +
            'FROM Battery__c ' +
            'WHERE Inventory_Status__c = \'Available\' ' +
            'AND FIFO_Eligible__c = true ';

        // Temporarily DON'T filter warehouse
        // until Current_Location lookup is corrected.

        if (String.isNotBlank(batchNumber)) {
            query += 'AND Batch_Number__c = :batchNumber ';
        }

        query +=
            'ORDER BY Manufacturing_Date__c ASC, CreatedDate ASC';

        System.debug('FIFO Query => ' + query);

        List<Battery__c> batteries = Database.query(query);

        System.debug('FIFO Batteries => ' + batteries);

        return batteries;
    }
}