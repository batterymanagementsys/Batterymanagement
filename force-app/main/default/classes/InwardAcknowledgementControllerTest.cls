@IsTest
private class InwardAcknowledgementControllerTest {

    // =========================================================
    // Helper - Create Warehouse
    // =========================================================
    private static Warehouse__c createWarehouse() {

        Warehouse__c warehouse = new Warehouse__c(
            Warehouse_Code__c = 'WH-ACK-001',
            Active__c = true
        );

        insert warehouse;

        return warehouse;
    }


    // =========================================================
    // Helper - Create Battery
    // =========================================================
    private static Battery__c createBattery(String suffix) {

        Battery__c battery = new Battery__c(
            Batch_Number__c = 'BATCH-' + suffix,
            Battery_Model__c = 'MODEL-A',
            Battery_PIN__c = 'PIN-' + suffix,
            Manufacturing_Date__c = Date.today(),
            Plant_Code__c = 'PLANT-01',
            Production_Request_ID__c = 'REQ-' + suffix,
            QR_Code__c = 'QR-ACK-' + suffix,
            Serial_Number__c = 'SERIAL-' + suffix,
            Status__c = 'Produced'
        );

        insert battery;

        return battery;
    }


    // =========================================================
    // TEST 1 - Null Session Id
    // =========================================================
    @IsTest
    static void testNullSessionId() {

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            InwardAcknowledgementController.getAcknowledgement(null);
        }
        catch (AuraHandledException ex) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'Exception should be thrown when session Id is null.'
        );
    }


    // =========================================================
    // TEST 2 - Session Not Completed
    // =========================================================
    @IsTest
    static void testSessionNotCompleted() {

        Warehouse__c warehouse = createWarehouse();

        Inward_Session__c session = new Inward_Session__c(
            Warehouse__c = warehouse.Id,
            Started_By__c = UserInfo.getUserId(),
            Start_Date_Time__c = System.now(),
            Status__c = 'Started',
            Total_Accepted__c = 0,
            Total_Rejected__c = 0,
            Total_Duplicate__c = 0,
            Total_Scanned__c = 0
        );

        insert session;

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            InwardAcknowledgementController.getAcknowledgement(session.Id);
        }
        catch (AuraHandledException ex) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'Acknowledgement should not be available for an incomplete session.'
        );
    }


    // =========================================================
    // TEST 3 - Completed Session
    // =========================================================
    @IsTest
    static void testCompletedSessionAcknowledgement() {

        Warehouse__c warehouse = createWarehouse();

        Battery__c acceptedBattery =
            createBattery('001');

        Battery__c rejectedBattery =
            createBattery('002');

        Battery__c duplicateBattery =
            createBattery('003');


        Inward_Session__c session = new Inward_Session__c(
            Warehouse__c = warehouse.Id,
            Started_By__c = UserInfo.getUserId(),
            Start_Date_Time__c = System.now().addHours(-1),
            End_Date_Time__c = System.now(),
            Status__c = 'Completed',
            Total_Accepted__c = 1,
            Total_Rejected__c = 1,
            Total_Duplicate__c = 1,
            Total_Scanned__c = 3,
            Acknowledgment__c = 'ACK-TEST-001'
        );

        insert session;


        // ------------------------------
        // Accepted record
        // ------------------------------
        Battery_Inward__c acceptedInward =
            new Battery_Inward__c(
                Battery__c = acceptedBattery.Id,
                Scanned_QR__c = acceptedBattery.QR_Code__c,
                Warehouse__c = warehouse.Id,
                Scanned_By__c = UserInfo.getUserId(),
                Scan_Date_Time__c = System.now().addMinutes(-30),
                Verification_Status__c = 'Accepted',
                Inward_Session__c = session.Id
            );


        // ------------------------------
        // Rejected record
        // ------------------------------
        Battery_Inward__c rejectedInward =
            new Battery_Inward__c(
                Battery__c = rejectedBattery.Id,
                Scanned_QR__c = rejectedBattery.QR_Code__c,
                Warehouse__c = warehouse.Id,
                Scanned_By__c = UserInfo.getUserId(),
                Scan_Date_Time__c = System.now().addMinutes(-20),
                Verification_Status__c = 'Rejected',
                Failure_Reason__c = 'Invalid QR',
                Inward_Session__c = session.Id
            );


        // ------------------------------
        // Duplicate record
        // ------------------------------
        Battery_Inward__c duplicateInward =
            new Battery_Inward__c(
                Battery__c = duplicateBattery.Id,
                Scanned_QR__c = duplicateBattery.QR_Code__c,
                Warehouse__c = warehouse.Id,
                Scanned_By__c = UserInfo.getUserId(),
                Scan_Date_Time__c = System.now().addMinutes(-10),
                Verification_Status__c = 'Duplicate',
                Failure_Reason__c = 'Duplicate Scan',
                Inward_Session__c = session.Id
            );

        insert new List<Battery_Inward__c>{
            acceptedInward,
            rejectedInward,
            duplicateInward
        };


        // ------------------------------
        // Call Controller
        // ------------------------------
        Test.startTest();

        InwardAcknowledgementController.AcknowledgementWrapper result =
            InwardAcknowledgementController.getAcknowledgement(session.Id);

        Test.stopTest();


        // ------------------------------
        // Verify Session Details
        // ------------------------------
        System.assertEquals(
            session.Id,
            result.sessionId
        );

        System.assertNotEquals(
            null,
            result.sessionNumber
        );

        System.assertEquals(
            'ACK-TEST-001',
            result.acknowledgement
        );

        System.assertNotEquals(
            null,
            result.warehouseName
        );

        System.assertNotEquals(
            null,
            result.operatorName
        );

        System.assertNotEquals(
            null,
            result.completedDateTime
        );


        // ------------------------------
        // Verify Counts
        // ------------------------------
        System.assertEquals(
            1,
            result.acceptedCount
        );

        System.assertEquals(
            1,
            result.rejectedCount
        );

        System.assertEquals(
            1,
            result.duplicateCount
        );


        // ------------------------------
        // Verify Lists
        // ------------------------------
        System.assertEquals(
            1,
            result.acceptedItems.size()
        );

        System.assertEquals(
            1,
            result.rejectedItems.size()
        );

        System.assertEquals(
            1,
            result.duplicateItems.size()
        );


        System.assertEquals(
            'Accepted',
            result.acceptedItems[0].Verification_Status__c
        );

        System.assertEquals(
            'Rejected',
            result.rejectedItems[0].Verification_Status__c
        );

        System.assertEquals(
            'Duplicate',
            result.duplicateItems[0].Verification_Status__c
        );
    }


    // =========================================================
    // TEST 4 - Completed Session With No Inward Records
    // =========================================================
    @IsTest
    static void testCompletedSessionNoRecords() {

        Warehouse__c warehouse = createWarehouse();

        Inward_Session__c session = new Inward_Session__c(
            Warehouse__c = warehouse.Id,
            Started_By__c = UserInfo.getUserId(),
            Start_Date_Time__c = System.now().addHours(-1),
            End_Date_Time__c = System.now(),
            Status__c = 'Completed',
            Total_Accepted__c = 0,
            Total_Rejected__c = 0,
            Total_Duplicate__c = 0,
            Total_Scanned__c = 0,
            Acknowledgment__c = 'ACK-EMPTY'
        );

        insert session;

        Test.startTest();

        InwardAcknowledgementController.AcknowledgementWrapper result =
            InwardAcknowledgementController.getAcknowledgement(session.Id);

        Test.stopTest();

        System.assertEquals(
            0,
            result.acceptedCount
        );

        System.assertEquals(
            0,
            result.rejectedCount
        );

        System.assertEquals(
            0,
            result.duplicateCount
        );

        System.assertEquals(
            0,
            result.acceptedItems.size()
        );

        System.assertEquals(
            0,
            result.rejectedItems.size()
        );

        System.assertEquals(
            0,
            result.duplicateItems.size()
        );
    }
}