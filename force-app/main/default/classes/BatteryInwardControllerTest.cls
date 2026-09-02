@IsTest
private class BatteryInwardControllerTest {

    @TestSetup
    static void setupTestData() {

        // Create Warehouse
        Warehouse__c warehouse = new Warehouse__c(
            Name = 'Test Warehouse',
            Active__c = true
        );

        insert warehouse;

        // Create Battery
        Battery__c battery = new Battery__c(
            Battery_PIN__c = 'BAT-TEST-001',
            QR_Code__c = 'QR-TEST-001',
            Serial_Number__c = 'SN-TEST-001',
            Battery_Model__c = 'Test Model',
            Batch_Number__c = 'BATCH-TEST-001',
            Manufacturing_Date__c = Date.today(),
            Plant_Code__c = 'PLANT-001',
            Production_Request_ID__c = 'PR-TEST-001',
            Status__c = 'Produced'
        );

        insert battery;
    }


    @IsTest
    static void testGetOrCreateInwardSession() {

        Test.startTest();

        BatteryInwardController.InwardSessionResponse response =
            BatteryInwardController.getOrCreateInwardSession();

        Test.stopTest();

        System.assertNotEquals(
            null,
            response,
            'Response should not be null.'
        );

        System.assertNotEquals(
            null,
            response.sessionId,
            'An inward session should be created.'
        );

        System.assertNotEquals(
            null,
            response.warehouseId,
            'Warehouse should be assigned.'
        );

        System.assertEquals(
            'Started',
            response.status,
            'New inward session should have Started status.'
        );
    }


    @IsTest
    static void testSuccessfulBatteryInward() {

        // Create session
        BatteryInwardController.InwardSessionResponse sessionResponse =
            BatteryInwardController.getOrCreateInwardSession();

        Test.startTest();

        BatteryInwardController.BatteryScanResponse response =
            BatteryInwardController.processBatteryInward(
                'QR-TEST-001',
                sessionResponse.sessionId
            );

        Test.stopTest();

        System.assertEquals(
            true,
            response.success,
            'Valid battery should be accepted.'
        );

        System.assertEquals(
            'Accepted',
            response.verificationStatus,
            'Verification status should be Accepted.'
        );

        System.assertEquals(
            'BAT-TEST-001',
            response.batteryPin,
            'Battery PIN should be returned.'
        );

        System.assertEquals(
            'SN-TEST-001',
            response.serialNumber,
            'Serial number should be returned.'
        );

        System.assertEquals(
            'Test Model',
            response.batteryModel,
            'Battery model should be returned.'
        );

        System.assertEquals(
            'BATCH-TEST-001',
            response.batchNumber,
            'Batch number should be returned.'
        );
    }


    @IsTest
    static void testInvalidQrFormat() {

        BatteryInwardController.InwardSessionResponse sessionResponse =
            BatteryInwardController.getOrCreateInwardSession();

        Test.startTest();

        BatteryInwardController.BatteryScanResponse response =
            BatteryInwardController.processBatteryInward(
                'INVALID-QR',
                sessionResponse.sessionId
            );

        Test.stopTest();

        System.assertEquals(
            false,
            response.success,
            'Invalid QR should be rejected.'
        );

        System.assertEquals(
            'INVALID_QR_FORMAT',
            response.errorCode,
            'Correct error code should be returned.'
        );

        System.assertEquals(
            'Rejected',
            response.verificationStatus,
            'Verification status should be Rejected.'
        );
    }


    @IsTest
    static void testQrNotFound() {

        BatteryInwardController.InwardSessionResponse sessionResponse =
            BatteryInwardController.getOrCreateInwardSession();

        Test.startTest();

        BatteryInwardController.BatteryScanResponse response =
            BatteryInwardController.processBatteryInward(
                'QR-NOT-EXIST',
                sessionResponse.sessionId
            );

        Test.stopTest();

        System.assertEquals(
            false,
            response.success,
            'Unknown QR should be rejected.'
        );

        System.assertEquals(
            'QR_NOT_FOUND',
            response.errorCode,
            'Correct error code should be returned.'
        );

        System.assertEquals(
            'Rejected',
            response.verificationStatus,
            'Verification status should be Rejected.'
        );
    }


    @IsTest
    static void testCompleteInwardSession() {

        BatteryInwardController.InwardSessionResponse sessionResponse =
            BatteryInwardController.getOrCreateInwardSession();

        Test.startTest();

        String result =
            BatteryInwardController.completeInwardSession(
                sessionResponse.sessionId
            );

        Test.stopTest();

        System.assertEquals(
            'Inward session completed successfully.',
            result,
            'Session should be completed successfully.'
        );

        Inward_Session__c session = [
            SELECT Status__c, End_Date_Time__c
            FROM Inward_Session__c
            WHERE Id = :sessionResponse.sessionId
        ];

        System.assertEquals(
            'Completed',
            session.Status__c,
            'Session status should be Completed.'
        );

        System.assertNotEquals(
            null,
            session.End_Date_Time__c,
            'End date/time should be populated.'
        );
    }
}