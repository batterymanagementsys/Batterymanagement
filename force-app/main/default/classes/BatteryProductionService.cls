public inherited sharing class BatteryProductionService {

    public static Battery__c processProduction(BatteryProductionRequest request) {
        // 1. Validate request DTO structure & regex formats
        BatteryProductionValidator.validate(request);

        // 2. Concurrency-safe duplicate check using FOR UPDATE row locking
        List<Battery__c> existingBatteries = [
            SELECT Id 
            FROM Battery__c 
            WHERE Battery_PIN__c = :request.batteryPin 
               OR Production_Request_ID__c = :request.productionRequestId
            WITH USER_MODE
            FOR UPDATE
        ];

        if (!existingBatteries.isEmpty()) {
            throw new BatteryProductionException(
                'Duplicate record detected. Battery PIN or Production Request ID already exists.'
            );
        }

        // 3. Construct Record
        Battery__c battery = new Battery__c(
            Battery_PIN__c = request.batteryPin,
            QR_Code__c = request.qrCode,
            Serial_Number__c = request.serialNumber,
            Battery_Model__c = request.batteryModel,
            Batch_Number__c = request.batchNumber,
            Manufacturing_Date__c = request.manufacturingDate,
            Plant_Code__c = request.plantCode,
            Production_Request_ID__c = request.productionRequestId,
            Status__c = 'Produced',
            Created_From_API__c = true
        );

        // 4. Secure Insert honoring user permissions (US-1.2)
        try {
            Database.insert(battery, AccessLevel.USER_MODE);
        } catch (DmlException e) {
            if (e.getDmlType(0) == StatusCode.DUPLICATE_VALUE) {
                throw new BatteryProductionException('Duplicate entry: Battery PIN or Request ID already exists.');
            }
            throw new BatteryProductionException('Failed to insert record: ' + e.getDmlMessage(0));
        }

        // 5. Re-query record to expose Auto-Number (Name) and formula fields
        return [
            SELECT Id, Name, Battery_PIN__c, QR_Code__c, Serial_Number__c, 
                   Battery_Model__c, Batch_Number__c, Manufacturing_Date__c, 
                   Plant_Code__c, Production_Request_ID__c, Status__c, Created_From_API__c
            FROM Battery__c
            WHERE Id = :battery.Id
            WITH USER_MODE
            LIMIT 1
        ];
    }
}