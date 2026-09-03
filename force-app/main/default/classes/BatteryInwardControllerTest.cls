@IsTest
private class BatteryInwardControllerTest {

    // =========================================================
    // Helper - Get a valid value for text/picklist fields
    // =========================================================
    private static String getValidValue(
        Schema.SObjectField fieldToken,
        String defaultValue
    ) {
        Schema.DescribeFieldResult d = fieldToken.getDescribe();

        if (d.getType() == Schema.DisplayType.Picklist) {

            for (Schema.PicklistEntry entry : d.getPicklistValues()) {
                if (entry.isActive()) {
                    return entry.getValue();
                }
            }
        }

        return defaultValue;
    }


    // =========================================================
    // Helper - Create Warehouse
    // =========================================================
    private static Warehouse__c createWarehouse() {

        Warehouse__c warehouse = new Warehouse__c(
            Name = 'Chennai Central',
            Warehouse_Code__c = 'CH-001',
            Active__c = true
        );

        insert warehouse;

        return warehouse;
    }


    // =========================================================
    // Helper - Create Battery
    // =========================================================
    private static Battery__c createBattery(
        String suffix,
        String status
    ) {

        Battery__c battery = new Battery__c();

        battery.Batch_Number__c =
            'BATCH-' + suffix;

        battery.Battery_Model__c =
            getValidValue(
                Battery__c.Battery_Model__c,
                'MODEL-A'
            );

        battery.Battery_PIN__c =
            'PIN-' + suffix;

        battery.Manufacturing_Date__c =
            Date.today();

        battery.Plant_Code__c =
            getValidValue(
                Battery__c.Plant_Code__c,
                'PLANT-01'
            );

        battery.Production_Request_ID__c =
            'REQ-' + suffix;

        battery.QR_Code__c =
            'QR-TEST-' + suffix;

        battery.Serial_Number__c =
            'SERIAL-' + suffix;

        battery.Status__c = status;

        insert battery;

        return battery;
    }


    // =========================================================
    // TEST 1
    // Create Inward Session
    // =========================================================
    @IsTest
    static void testGetOrCreateInwardSession() {

        Warehouse__c warehouse = createWarehouse();

        System.Test.startTest();

        BatteryInwardController.InwardSessionResponse response =
            BatteryInwardController.getOrCreateInwardSession();

        System.Test.stopTest();

        System.assertNotEquals(
            null,
            response.sessionId,
            'Session should be created.'
        );

        System.assertEquals(
            warehouse.Id,
            response.warehouseId,
            'Session should use active warehouse.'
        );

        System.assertEquals(
            'Started',
            response.status,
            'New session should start with Started status.'
        );

        Inward_Session__c session = [
            SELECT Id,
                   Warehouse__c,
                   Status__c,
                   Total_Scanned__c,
                   Total_Accepted__c,
                   Total_Rejected__c,
                   Total_Duplicate__c
            FROM Inward_Session__c
            WHERE Id = :response.sessionId
        ];

        System.assertEquals(
            warehouse.Id,
            session.Warehouse__c
        );

        System.assertEquals(
            0,
            session.Total_Scanned__c
        );
    }


    // =========================================================
    // TEST 2
    // Existing session should be reused
    // =========================================================
    @IsTest
    static void testExistingSessionReturned() {

        createWarehouse();

        BatteryInwardController.InwardSessionResponse firstResponse =
            BatteryInwardController.getOrCreateInwardSession();

        System.Test.startTest();

        BatteryInwardController.InwardSessionResponse secondResponse =
            BatteryInwardController.getOrCreateInwardSession();

        System.Test.stopTest();

        System.assertEquals(
            firstResponse.sessionId,
            secondResponse.sessionId,
            'Existing active session should be reused.'
        );
    }


    // =========================================================
    // TEST 3
    // No active warehouse
    // =========================================================
    @IsTest
    static void testNoActiveWarehouse() {

        Warehouse__c warehouse = createWarehouse();

        warehouse.Active__c = false;
        update warehouse;

        Boolean exceptionThrown = false;

        System.Test.startTest();

        try {

            BatteryInwardController.getOrCreateInwardSession();

        } catch (AuraHandledException ex) {

            exceptionThrown = true;
        }

        System.Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'Exception should be thrown when no active warehouse exists.'
        );
    }


    // =========================================================
    // TEST 4
    // Blank QR Code
    // =========================================================
    @IsTest
    static void testBlankQRCode() {

        System.Test.startTest();

        BatteryInwardController.BatteryScanResponse response =
            BatteryInwardController.processBatteryInward(
                '',
                null
            );

        System.Test.stopTest();

        System.assertEquals(
            false,
            response.success
        );

        System.assertEquals(
            'INVALID_INPUT',
            response.errorCode
        );

        System.assertEquals(
            'Rejected',
            response.verificationStatus
        );
    }


    // =========================================================
    // TEST 5
    // Null Session
    // =========================================================
    @IsTest
    static void testNullSession() {

        System.Test.startTest();

        BatteryInwardController.BatteryScanResponse response =
            BatteryInwardController.processBatteryInward(
                'QR-TEST-001',
                null
            );

        System.Test.stopTest();

        System.assertEquals(
            false,
            response.success
        );

        System.assertEquals(
            'INVALID_SESSION',
            response.errorCode
        );
    }


    // =========================================================
    // TEST 6
    // Invalid QR format
    // =========================================================
    @IsTest
    static void testInvalidQRCodeFormat() {

        createWarehouse();

        BatteryInwardController.InwardSessionResponse session =
            BatteryInwardController.getOrCreateInwardSession();

        System.Test.startTest();

        BatteryInwardController.BatteryScanResponse response =
            BatteryInwardController.processBatteryInward(
                'INVALID_QR',
                session.sessionId
            );

        System.Test.stopTest();

        System.assertEquals(
            false,
            response.success
        );

        System.assertEquals(
            'INVALID_QR_FORMAT',
            response.errorCode
        );
    }


    // =========================================================
    // TEST 7
    // QR code not found
    // =========================================================
    @IsTest
    static void testQRCodeNotFound() {

        createWarehouse();

        BatteryInwardController.InwardSessionResponse session =
            BatteryInwardController.getOrCreateInwardSession();

        System.Test.startTest();

        BatteryInwardController.BatteryScanResponse response =
            BatteryInwardController.processBatteryInward(
                'QR-NOT-FOUND-001',
                session.sessionId
            );

        System.Test.stopTest();

        System.assertEquals(
            false,
            response.success
        );

        System.assertEquals(
            'QR_NOT_FOUND',
            response.errorCode
        );

        Inward_Session__c updatedSession = [
            SELECT Total_Scanned__c,
                   Total_Rejected__c,
                   Status__c
            FROM Inward_Session__c
            WHERE Id = :session.sessionId
        ];

        System.assertEquals(
            1,
            updatedSession.Total_Scanned__c
        );

        System.assertEquals(
            1,
            updatedSession.Total_Rejected__c
        );

        System.assertEquals(
            'In Progress',
            updatedSession.Status__c
        );
    }


    // =========================================================
    // TEST 8
    // Successful Battery Inward
    // =========================================================
    @IsTest
    static void testSuccessfulBatteryInward() {

        Warehouse__c warehouse = createWarehouse();

        Battery__c battery =
            createBattery(
                'SUCCESS-001',
                'Produced'
            );

        BatteryInwardController.InwardSessionResponse session =
            BatteryInwardController.getOrCreateInwardSession();

        System.Test.startTest();

        BatteryInwardController.BatteryScanResponse response =
            BatteryInwardController.processBatteryInward(
                battery.QR_Code__c,
                session.sessionId
            );

        System.Test.stopTest();

        // -----------------------
        // Verify response
        // -----------------------

        System.assertEquals(
            true,
            response.success
        );

        System.assertEquals(
            null,
            response.errorCode
        );

        System.assertEquals(
            'Accepted',
            response.verificationStatus
        );

        System.assertEquals(
            battery.Id,
            response.batteryId
        );


        // -----------------------
        // Verify Battery
        // -----------------------

        Battery__c updatedBattery = [
            SELECT Id,
                   Status__c,
                   Current_Location__c,
                   Inventory_Status__c,
                   FIFO_Eligible__c,
                   Last_Movement_Date_Time__c
            FROM Battery__c
            WHERE Id = :battery.Id
        ];

        System.assertEquals(
            'Warehouse_Received',
            updatedBattery.Status__c
        );

        System.assertEquals(
            warehouse.Id,
            updatedBattery.Current_Location__c
        );

        System.assertEquals(
            'Available',
            updatedBattery.Inventory_Status__c
        );

        System.assertEquals(
            true,
            updatedBattery.FIFO_Eligible__c
        );


        // -----------------------
        // Verify Battery Inward
        // -----------------------

        List<Battery_Inward__c> inwardRecords = [
            SELECT Id,
                   Battery__c,
                   Warehouse__c,
                   Verification_Status__c,
                   Inward_Session__c
            FROM Battery_Inward__c
            WHERE Battery__c = :battery.Id
        ];

        System.assertEquals(
            1,
            inwardRecords.size()
        );

        System.assertEquals(
            'Accepted',
            inwardRecords[0].Verification_Status__c
        );


        // -----------------------
        // Verify Inventory Transaction
        // -----------------------

        List<Inventory_Transaction__c> transactions = [
            SELECT Id,
                   Battery__c,
                   Destination_Location__c,
                   Transaction_Type__c,
                   Status__c,
                   Transaction_Reason__c
            FROM Inventory_Transaction__c
            WHERE Battery__c = :battery.Id
        ];

        System.assertEquals(
            1,
            transactions.size()
        );

        System.assertEquals(
            'INWARD',
            transactions[0].Transaction_Type__c
        );

        System.assertEquals(
            'Posted',
            transactions[0].Status__c
        );

        System.assertEquals(
            warehouse.Id,
            transactions[0].Destination_Location__c
        );


        // -----------------------
        // Verify Inventory Balance
        // -----------------------

        Inventory_Balance__c balance = [
            SELECT Id,
                   Warehouse__c,
                   Batch_Number__c,
                   Available_Quantity__c,
                   Dispatched_Quantity__c
            FROM Inventory_Balance__c
            WHERE Warehouse__c = :warehouse.Id
            AND Batch_Number__c = :battery.Batch_Number__c
            LIMIT 1
        ];

        System.assertEquals(
            1,
            balance.Available_Quantity__c
        );

        System.assertEquals(
            0,
            balance.Dispatched_Quantity__c
        );


        // -----------------------
        // Verify Session Counter
        // -----------------------

        Inward_Session__c updatedSession = [
            SELECT Total_Scanned__c,
                   Total_Accepted__c,
                   Status__c
            FROM Inward_Session__c
            WHERE Id = :session.sessionId
        ];

        System.assertEquals(
            1,
            updatedSession.Total_Scanned__c
        );

        System.assertEquals(
            1,
            updatedSession.Total_Accepted__c
        );

        System.assertEquals(
            'In Progress',
            updatedSession.Status__c
        );
    }


    // =========================================================
    // TEST 9
    // Duplicate scan in same session
    // =========================================================
    @IsTest
    static void testDuplicateScanSameSession() {

        createWarehouse();

        Battery__c battery =
            createBattery(
                'DUP-001',
                'Produced'
            );

        BatteryInwardController.InwardSessionResponse session =
            BatteryInwardController.getOrCreateInwardSession();

        // First successful scan
        BatteryInwardController.processBatteryInward(
            battery.QR_Code__c,
            session.sessionId
        );

        System.Test.startTest();

        // Scan same battery again
        BatteryInwardController.BatteryScanResponse response =
            BatteryInwardController.processBatteryInward(
                battery.QR_Code__c,
                session.sessionId
            );

        System.Test.stopTest();

        System.assertEquals(
            false,
            response.success
        );

        System.assertEquals(
            'DUPLICATE_SCAN',
            response.errorCode
        );

        System.assertEquals(
            'Duplicate',
            response.verificationStatus
        );

        Inward_Session__c updatedSession = [
            SELECT Total_Duplicate__c,
                   Total_Scanned__c
            FROM Inward_Session__c
            WHERE Id = :session.sessionId
        ];

        System.assertEquals(
            1,
            updatedSession.Total_Duplicate__c
        );

        System.assertEquals(
            2,
            updatedSession.Total_Scanned__c
        );
    }


    // =========================================================
    // TEST 10
    // Invalid Battery Status
    // =========================================================
    @IsTest
    static void testInvalidBatteryStatus() {

        createWarehouse();

        Battery__c battery =
            createBattery(
                'STATUS-001',
                'Warehouse_Received'
            );

        BatteryInwardController.InwardSessionResponse session =
            BatteryInwardController.getOrCreateInwardSession();

        System.Test.startTest();

        BatteryInwardController.BatteryScanResponse response =
            BatteryInwardController.processBatteryInward(
                battery.QR_Code__c,
                session.sessionId
            );

        System.Test.stopTest();

        System.assertEquals(
            false,
            response.success
        );

        System.assertEquals(
            'INVALID_BATTERY_STATUS',
            response.errorCode
        );

        System.assertEquals(
            'Rejected',
            response.verificationStatus
        );
    }


    // =========================================================
    // TEST 11
    // Complete Inward Session
    // =========================================================
    @IsTest
    static void testCompleteInwardSession() {

        createWarehouse();

        Battery__c battery =
            createBattery(
                'COMPLETE-001',
                'Produced'
            );

        BatteryInwardController.InwardSessionResponse session =
            BatteryInwardController.getOrCreateInwardSession();

        // Successful inward
        BatteryInwardController.processBatteryInward(
            battery.QR_Code__c,
            session.sessionId
        );

        System.Test.startTest();

        String result =
            BatteryInwardController.completeInwardSession(
                session.sessionId
            );

        System.Test.stopTest();

        System.assertEquals(
            'Inward session completed successfully.',
            result
        );

        Inward_Session__c completedSession = [
            SELECT Status__c,
                   End_Date_Time__c,
                   Total_Scanned__c,
                   Total_Accepted__c,
                   Total_Rejected__c,
                   Total_Duplicate__c,
                   Acknowledgment__c
            FROM Inward_Session__c
            WHERE Id = :session.sessionId
        ];

        System.assertEquals(
            'Completed',
            completedSession.Status__c
        );

        System.assertNotEquals(
            null,
            completedSession.End_Date_Time__c
        );

        System.assertEquals(
            1,
            completedSession.Total_Scanned__c
        );

        System.assertEquals(
            1,
            completedSession.Total_Accepted__c
        );

        System.assertNotEquals(
            null,
            completedSession.Acknowledgment__c
        );
    }


    // =========================================================
    // TEST 12
    // Complete Session - Null Id
    // =========================================================
    @IsTest
    static void testCompleteSessionNullId() {

        Boolean exceptionThrown = false;

        System.Test.startTest();

        try {

            BatteryInwardController.completeInwardSession(null);

        } catch (AuraHandledException ex) {

            exceptionThrown = true;
        }

        System.Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'Exception should occur when session Id is null.'
        );
    }


    // =========================================================
    // TEST 13
    // Already Inwarded in previous session
    // =========================================================
    @IsTest
    static void testAlreadyInwarded() {

        createWarehouse();

        Battery__c battery =
            createBattery(
                'PREVIOUS-001',
                'Produced'
            );

        // Session 1
        BatteryInwardController.InwardSessionResponse firstSession =
            BatteryInwardController.getOrCreateInwardSession();

        // Successful inward
        BatteryInwardController.processBatteryInward(
            battery.QR_Code__c,
            firstSession.sessionId
        );

        // Complete first session
        BatteryInwardController.completeInwardSession(
            firstSession.sessionId
        );

        // Change Battery back to Produced only to reach
        // the "previous inward" validation.
        Battery__c batteryUpdate = new Battery__c(
            Id = battery.Id,
            Status__c = 'Produced'
        );

        update batteryUpdate;

        // Create Session 2
        BatteryInwardController.InwardSessionResponse secondSession =
            BatteryInwardController.getOrCreateInwardSession();

        System.Test.startTest();

        BatteryInwardController.BatteryScanResponse response =
            BatteryInwardController.processBatteryInward(
                battery.QR_Code__c,
                secondSession.sessionId
            );

        System.Test.stopTest();

        System.assertEquals(
            false,
            response.success
        );

        System.assertEquals(
            'ALREADY_INWARDED',
            response.errorCode
        );

        System.assertEquals(
            'Already Inwarded',
            response.verificationStatus
        );
    }
}
