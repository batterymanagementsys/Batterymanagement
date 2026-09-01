@IsTest
private class BatteryProductionValidationTest {

    @TestSetup
    static void setupTestData() {

        Warehouse__c warehouse = new Warehouse__c(
            Name = 'Validation Test Warehouse',
            Warehouse_Code__c = 'WH-TEST-001',
            Active__c = true
        );

        insert warehouse;


        Battery__c producedBattery = new Battery__c(
            Battery_PIN__c = 'BAT-VALIDATION-001',
            QR_Code__c = 'QR-VALIDATION-001',
            Serial_Number__c = 'SN-VALIDATION-001',
            Battery_Model__c = 'Test Model',
            Batch_Number__c = 'BATCH-VALIDATION-001',
            Manufacturing_Date__c = Date.today(),
            Plant_Code__c = 'PLANT-001',
            Production_Request_ID__c = 'PR-VALIDATION-001',
            Status__c = 'Produced'
        );

        insert producedBattery;


        Battery__c invalidStatusBattery = new Battery__c(
            Battery_PIN__c = 'BAT-INVALID-STATUS-001',
            QR_Code__c = 'QR-INVALID-STATUS-001',
            Serial_Number__c = 'SN-INVALID-STATUS-001',
            Battery_Model__c = 'Test Model',
            Batch_Number__c = 'BATCH-INVALID-001',
            Manufacturing_Date__c = Date.today(),
            Plant_Code__c = 'PLANT-001',
            Production_Request_ID__c = 'PR-INVALID-001',
            Status__c = 'Warehouse_Received'
        );

        insert invalidStatusBattery;
    }


    @IsTest
    static void testInvalidQrFormat() {

        BatteryInwardController.InwardSessionResponse session =
            BatteryInwardController.getOrCreateInwardSession();

        Test.startTest();

        BatteryInwardController.BatteryScanResponse response =
            BatteryInwardController.processBatteryInward(
                'INVALID-QR',
                session.sessionId
            );

        Test.stopTest();

        System.assertEquals(
            false,
            response.success,
            'Invalid QR should not be accepted.'
        );

        System.assertEquals(
            'INVALID_QR_FORMAT',
            response.errorCode,
            'The correct error code should be returned.'
        );

        System.assertEquals(
            'Rejected',
            response.verificationStatus,
            'Invalid QR should have Rejected status.'
        );
    }


    @IsTest
    static void testBatteryQrNotFound() {

        BatteryInwardController.InwardSessionResponse session =
            BatteryInwardController.getOrCreateInwardSession();

        Test.startTest();

        BatteryInwardController.BatteryScanResponse response =
            BatteryInwardController.processBatteryInward(
                'QR-BATTERY-NOT-FOUND',
                session.sessionId
            );

        Test.stopTest();

        System.assertEquals(
            false,
            response.success,
            'A QR code that does not exist should be rejected.'
        );

        System.assertEquals(
            'QR_NOT_FOUND',
            response.errorCode,
            'The correct error code should be returned.'
        );

        System.assertEquals(
            'Rejected',
            response.verificationStatus,
            'Unknown battery should be Rejected.'
        );
    }


    @IsTest
    static void testBatteryLifecycleStatusValidation() {

        BatteryInwardController.InwardSessionResponse session =
            BatteryInwardController.getOrCreateInwardSession();

        Test.startTest();

        BatteryInwardController.BatteryScanResponse response =
            BatteryInwardController.processBatteryInward(
                'QR-INVALID-STATUS-001',
                session.sessionId
            );

        Test.stopTest();

        System.assertEquals(
            false,
            response.success,
            'Battery with an invalid lifecycle status should be rejected.'
        );

        System.assertEquals(
            'INVALID_BATTERY_STATUS',
            response.errorCode,
            'The correct lifecycle status error should be returned.'
        );

        System.assertEquals(
            'Rejected',
            response.verificationStatus,
            'Battery should be rejected when it is not in Produced status.'
        );

        System.assertEquals(
            'BAT-INVALID-STATUS-001',
            response.batteryPin,
            'Battery PIN should be returned.'
        );

        System.assertEquals(
            'SN-INVALID-STATUS-001',
            response.serialNumber,
            'Serial number should be returned.'
        );

        System.assertEquals(
            'Test Model',
            response.batteryModel,
            'Battery model should be returned.'
        );

        System.assertEquals(
            'BATCH-INVALID-001',
            response.batchNumber,
            'Batch number should be returned.'
        );
    }


    @IsTest
    static void testValidProductionBatteryDetails() {

        BatteryInwardController.InwardSessionResponse session =
            BatteryInwardController.getOrCreateInwardSession();

        Test.startTest();

        BatteryInwardController.BatteryScanResponse response =
            BatteryInwardController.processBatteryInward(
                'QR-VALIDATION-001',
                session.sessionId
            );

        Test.stopTest();

        System.assertEquals(
            true,
            response.success,
            'A Produced battery should pass production validation.'
        );

        System.assertEquals(
            'Accepted',
            response.verificationStatus,
            'A valid battery should have Accepted status.'
        );

        System.assertEquals(
            'BAT-VALIDATION-001',
            response.batteryPin,
            'Battery PIN should be returned.'
        );

        System.assertEquals(
            'SN-VALIDATION-001',
            response.serialNumber,
            'Serial number should be returned.'
        );

        System.assertEquals(
            'Test Model',
            response.batteryModel,
            'Battery model should be returned.'
        );

        System.assertEquals(
            'BATCH-VALIDATION-001',
            response.batchNumber,
            'Batch number should be returned.'
        );
    }


    @IsTest
    static void testDuplicateBatteryScan() {

        BatteryInwardController.InwardSessionResponse session =
            BatteryInwardController.getOrCreateInwardSession();

        Battery__c battery = [
            SELECT Id,
                   Name,
                   Battery_PIN__c,
                   QR_Code__c,
                   Serial_Number__c,
                   Battery_Model__c,
                   Batch_Number__c,
                   Status__c
            FROM Battery__c
            WHERE QR_Code__c = 'QR-VALIDATION-001'
            LIMIT 1
        ];

        Warehouse__c warehouse = [
            SELECT Id
            FROM Warehouse__c
            WHERE Name = 'Validation Test Warehouse'
            LIMIT 1
        ];


        Battery_Inward__c existingInward = new Battery_Inward__c(
            Battery__c = battery.Id,
            Scanned_QR__c = battery.QR_Code__c,
            Warehouse__c = warehouse.Id,
            Scanned_By__c = UserInfo.getUserId(),
            Scan_Date_Time__c = System.now(),
            Verification_Status__c = 'Accepted',
            Inward_Session__c = session.sessionId
        );

        insert existingInward;


        Test.startTest();

        BatteryInwardController.BatteryScanResponse response =
            BatteryInwardController.processBatteryInward(
                'QR-VALIDATION-001',
                session.sessionId
            );

        Test.stopTest();

        System.assertEquals(
            false,
            response.success,
            'A battery scanned twice in the same session should not be accepted.'
        );

        System.assertEquals(
            'DUPLICATE_SCAN',
            response.errorCode,
            'The correct duplicate error code should be returned.'
        );

        System.assertEquals(
            'Duplicate',
            response.verificationStatus,
            'Duplicate scan should have Duplicate status.'
        );

        System.assertEquals(
            'BAT-VALIDATION-001',
            response.batteryPin,
            'Battery information should be returned for duplicate scans.'
        );
    }
}