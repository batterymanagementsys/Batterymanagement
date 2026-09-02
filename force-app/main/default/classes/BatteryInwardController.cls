public with sharing class BatteryInwardController {

    // GET OR CREATE INWARD SESSION

    @AuraEnabled
    public static InwardSessionResponse getOrCreateInwardSession() 
    {

        InwardSessionResponse response = new InwardSessionResponse();

        List<Warehouse__c> warehouses = [
            SELECT Id, Name
            FROM Warehouse__c
            WHERE Active__c = true
            ORDER BY Name
            LIMIT 1
        ];

        if (warehouses.isEmpty()) {
            throw new AuraHandledException(
                'No active warehouse is available for inward processing.'
            );
        }

        Warehouse__c warehouse = warehouses[0];

        response.warehouseId = warehouse.Id;
        response.warehouseName = warehouse.Name;

        List<Inward_Session__c> existingSessions = [
            SELECT Id,
                   Name,
                   Warehouse__c,
                   Warehouse__r.Name,
                   Started_By__c,
                   Start_Date_Time__c,
                   End_Date_Time__c,
                   Status__c,
                   Total_Scanned__c,
                   Total_Accepted__c,
                   Total_Rejected__c,
                   Total_Duplicate__c
            FROM Inward_Session__c
            WHERE Started_By__c = :UserInfo.getUserId()
            AND Status__c IN ('Started', 'In Progress')
            ORDER BY Start_Date_Time__c DESC
            LIMIT 1
        ];

        if (!existingSessions.isEmpty()) {

            Inward_Session__c session = existingSessions[0];

            response.sessionId = session.Id;
            response.sessionNumber = session.Name;
            response.status = session.Status__c;

            return response;
        }

        Inward_Session__c newSession = new Inward_Session__c(
            Warehouse__c = warehouse.Id,
            Started_By__c = UserInfo.getUserId(),
            Start_Date_Time__c = System.now(),
            Status__c = 'Started',
            Total_Scanned__c = 0,
            Total_Accepted__c = 0,
            Total_Rejected__c = 0,
            Total_Duplicate__c = 0
        );

        insert newSession;

        Inward_Session__c createdSession = [
            SELECT Id,
                   Name,
                   Status__c
            FROM Inward_Session__c
            WHERE Id = :newSession.Id
            LIMIT 1
        ];

        response.sessionId = createdSession.Id;
        response.sessionNumber = createdSession.Name;
        response.status = createdSession.Status__c;

        return response;
    }


    // PROCESS BATTERY INWARD

    @AuraEnabled
    public static BatteryScanResponse processBatteryInward(
        String qrCode,
        Id sessionId) 
    {

        BatteryScanResponse response = new BatteryScanResponse();

        // 1. Validate QR input

        if (String.isBlank(qrCode)) {

            response.success = false;
            response.errorCode = 'INVALID_INPUT';
            response.message =
                'Please scan or enter a QR code.';
            response.verificationStatus = 'Rejected';

            return response;
        }


        // 2. Validate session ID

        if (sessionId == null) {

            response.success = false;
            response.errorCode = 'INVALID_SESSION';
            response.message =
                'An active inward session is required.';
            response.verificationStatus = 'Rejected';

            return response;
        }


        qrCode = qrCode.trim();


        // 3. Validate QR format

        if (!Pattern.matches('^QR-[A-Z0-9-]+$', qrCode)) {

            response.success = false;
            response.errorCode = 'INVALID_QR_FORMAT';
            response.message =
                'The scanned QR code format is invalid.';
            response.verificationStatus = 'Rejected';

            return response;
        }


        // 4. Get current session

        List<Inward_Session__c> sessions = [
            SELECT Id,
                   Name,
                   Warehouse__c,
                   Warehouse__r.Name,
                   Started_By__c,
                   Status__c
            FROM Inward_Session__c
            WHERE Id = :sessionId
            AND Started_By__c = :UserInfo.getUserId()
            AND Status__c IN ('Started', 'In Progress')
            LIMIT 1
        ];


        if (sessions.isEmpty()) {

            response.success = false;
            response.errorCode = 'INVALID_SESSION';
            response.message =
                'The inward session is not available or is no longer active.';
            response.verificationStatus = 'Rejected';

            return response;
        }


        Inward_Session__c session = sessions[0];


        // 5. Find battery

        List<Battery__c> batteries = [
            SELECT Id,
                   Name,
                   Battery_PIN__c,
                   QR_Code__c,
                   Serial_Number__c,
                   Battery_Model__c,
                   Batch_Number__c,
                   Manufacturing_Date__c,
                   Plant_Code__c,
                   Production_Request_ID__c,
                   Status__c,
                   Current_Location__c,
                   Inventory_Status__c
            FROM Battery__c
            WHERE QR_Code__c = :qrCode
            LIMIT 1
        ];


        // 6. Battery not found

        if (batteries.isEmpty()) {

            updateRejectedCounter(session.Id);

            response.success = false;
            response.errorCode = 'QR_NOT_FOUND';
            response.message =
                'No battery was found for the scanned QR code.';
            response.verificationStatus = 'Rejected';

            return response;
        }


        Battery__c battery = batteries[0];


        // 7. Check duplicate in current session

        List<Battery_Inward__c> currentSessionInwards = [
            SELECT Id,
                   Name,
                   Verification_Status__c,
                   Warehouse__c,
                   Warehouse__r.Name,
                   Scan_Date_Time__c,
                   Inward_Session__c
            FROM Battery_Inward__c
            WHERE Battery__c = :battery.Id
            AND Inward_Session__c = :session.Id
            AND Verification_Status__c = 'Accepted'
            LIMIT 1
        ];


        if (!currentSessionInwards.isEmpty()) {

            updateDuplicateCounter(session.Id);

            response.success = false;
            response.errorCode = 'DUPLICATE_SCAN';
            response.message =
                'This battery has already been scanned in this session.';
            response.verificationStatus = 'Duplicate';

            populateBatteryDetails(response, battery);

            return response;
        }


        // 8. Check whether battery was inwarded previously

        List<Battery_Inward__c> previousInwards = [
            SELECT Id,
                   Name,
                   Verification_Status__c,
                   Warehouse__c,
                   Warehouse__r.Name,
                   Scan_Date_Time__c,
                   Inward_Session__c
            FROM Battery_Inward__c
            WHERE Battery__c = :battery.Id
            AND Verification_Status__c = 'Accepted'
            AND Inward_Session__c != :session.Id
            ORDER BY Scan_Date_Time__c DESC
            LIMIT 1
        ];


        if (!previousInwards.isEmpty()) {

            updateDuplicateCounter(session.Id);

            response.success = false;
            response.errorCode = 'ALREADY_INWARDED';
            response.message =
                'This battery has already been inwarded.';
            response.verificationStatus = 'Already Inwarded';

            populateBatteryDetails(response, battery);

            return response;
        }


        // 9. Validate Battery Lifecycle Status

        if (battery.Status__c != 'Produced') {

            updateRejectedCounter(session.Id);

            response.success = false;
            response.errorCode = 'INVALID_BATTERY_STATUS';
            response.message =
                'Battery is not eligible for inward. Current status: '
                + battery.Status__c;
            response.verificationStatus = 'Rejected';

            populateBatteryDetails(response, battery);

            return response;
        }


        // 10. START ATOMIC TRANSACTION

        Savepoint inwardSavepoint = Database.setSavepoint();

        try {

            // ----------------------------------------------------
            // 10.1 Create Battery Inward
            // ----------------------------------------------------

            Battery_Inward__c inward = new Battery_Inward__c(
                Battery__c = battery.Id,
                Scanned_QR__c = qrCode,
                Warehouse__c = session.Warehouse__c,
                Scanned_By__c = UserInfo.getUserId(),
                Scan_Date_Time__c = System.now(),
                Verification_Status__c = 'Accepted',
                Inward_Session__c = session.Id
            );

            insert inward;


            // 10.2 Update Battery

            battery.Status__c = 'Warehouse_Received';

            battery.Current_Location__c =
                session.Warehouse__c;

            battery.Inventory_Status__c =
                'Available';

            battery.FIFO_Eligible__c = true;

            battery.Last_Movement_Date_Time__c =
                System.now();

            update battery;


            // 10.3 Create Inventory Transaction

            Inventory_Transaction__c inventoryTransaction =
                new Inventory_Transaction__c(
                    Battery__c = battery.Id,
                    Batch_Number__c = battery.Batch_Number__c,
                    Destination_Location__c = session.Warehouse__c,
                    Source_Location__c = null,
                    Reference_Number__c = inward.Name,
                    Transaction_Date_Time__c = System.now(),
                    Transaction_Reason__c = 'Warehouse Inward',
                    Transaction_Type__c = 'INWARD',
                    Status__c = 'Posted'
                );

            insert inventoryTransaction;


            // 10.4 Update Inventory Balance

            List<Inventory_Balance__c> balances = [
                SELECT Id,
                       Warehouse__c,
                       Batch_Number__c,
                       Available_Quantity__c,
                       Dispatched_Quantity__c,
                       Last_Updated_Date_Time__c
                FROM Inventory_Balance__c
                WHERE Warehouse__c = :session.Warehouse__c
                AND Batch_Number__c = :battery.Batch_Number__c
                LIMIT 1
                FOR UPDATE
            ];


            Inventory_Balance__c inventoryBalance;


            if (balances.isEmpty()) {

                inventoryBalance = new Inventory_Balance__c(
                    Warehouse__c = session.Warehouse__c,
                    Batch_Number__c = battery.Batch_Number__c,
                    Available_Quantity__c = 1,
                    Dispatched_Quantity__c = 0,
                    Last_Updated_Date_Time__c = System.now()
                );

                insert inventoryBalance;

            } else {

                inventoryBalance = balances[0];

                Decimal currentAvailable =
                    inventoryBalance.Available_Quantity__c == null
                    ? 0
                    : inventoryBalance.Available_Quantity__c;

                inventoryBalance.Available_Quantity__c =
                    currentAvailable + 1;

                inventoryBalance.Last_Updated_Date_Time__c =
                    System.now();

                update inventoryBalance;
            }


            // 10.5 Update Accepted Counter

            updateAcceptedCounter(session.Id);


            // 10.6 Successful response

            response.success = true;
            response.errorCode = null;
            response.message =
                'Battery inward completed successfully.';
            response.verificationStatus = 'Accepted';

            populateBatteryDetails(response, battery);

            return response;


        } catch (Exception ex) {

            // ROLLBACK EVERYTHING

            Database.rollback(inwardSavepoint);

            response.success = false;
            response.errorCode = 'INWARD_PROCESSING_FAILED';
            response.message =
                'Battery inward failed. No changes were saved. '
                + ex.getMessage();
            response.verificationStatus = 'Rejected';

            populateBatteryDetails(response, battery);

            return response;
        }
    }


    // COMPLETE INWARD SESSION

    @AuraEnabled
    public static String completeInwardSession(Id sessionId) {

        if (sessionId == null) {

            throw new AuraHandledException(
                'An inward session is required.'
            );
        }


        List<Inward_Session__c> sessions = [
            SELECT Id,
                   Name,
                   Status__c,
                   Started_By__c,
                   End_Date_Time__c,
                   Total_Accepted__c,
                   Total_Duplicate__c,
                   Total_Rejected__c,
                   Total_Scanned__c
            FROM Inward_Session__c
            WHERE Id = :sessionId
            AND Started_By__c = :UserInfo.getUserId()
            AND Status__c IN ('Started', 'In Progress')
            LIMIT 1
        ];


        if (sessions.isEmpty()) {

            throw new AuraHandledException(
                'The inward session is not available or is already completed.'
            );
        }


        Inward_Session__c session = sessions[0];
        List<Battery_Inward__c> inwardRecords = [SELECT Id,Verification_Status__c
                                                FROM Battery_Inward__c
                                                WHERE Inward_Session__c = :sessionId];

        Integer acceptedCount = 0;
        Integer rejectedCount = 0;
        Integer duplicateCount = 0;
        for (Battery_Inward__c inward : inwardRecords) 
        {

            if (inward.Verification_Status__c == 'Accepted') {
                acceptedCount++;
            }
            else if (inward.Verification_Status__c == 'Rejected') {
                rejectedCount++;
            }
            else if (inward.Verification_Status__c == 'Duplicate') {
                duplicateCount++;
            }
        }

        Integer totalScanned = inwardRecords.size();

        session.Total_Scanned__c = totalScanned;
        session.Total_Accepted__c = acceptedCount;
        session.Total_Rejected__c = rejectedCount;
        session.Total_Duplicate__c = duplicateCount;
        session.Status__c = 'Completed';
        session.End_Date_Time__c = System.now();

        // Generate acknowledgement reference
        session.Acknowledgment__c = 'ACK-' + session.Name;

        update session;

        return 'Inward session completed successfully.';
    }


    // POPULATE BATTERY RESPONSE

    private static void populateBatteryDetails(
        BatteryScanResponse response,
        Battery__c battery
    ) {

        response.batteryId =
            battery.Id;

        response.batteryPin =
            battery.Battery_PIN__c;

        response.qrCode =
            battery.QR_Code__c;

        response.serialNumber =
            battery.Serial_Number__c;

        response.batteryModel =
            battery.Battery_Model__c;

        response.batchNumber =
            battery.Batch_Number__c;

        response.manufacturingDate =
            battery.Manufacturing_Date__c;

        response.plantCode =
            battery.Plant_Code__c;

        response.productionRequestId =
            battery.Production_Request_ID__c;

        response.status =
            battery.Status__c;
    }


    // UPDATE ACCEPTED COUNTER

    private static void updateAcceptedCounter(
        Id sessionId
    ) {

        Inward_Session__c session = [
            SELECT Id,
                   Total_Scanned__c,
                   Total_Accepted__c,
                   Total_Rejected__c,
                   Total_Duplicate__c,
                   Status__c
            FROM Inward_Session__c
            WHERE Id = :sessionId
            LIMIT 1
            FOR UPDATE
        ];


        session.Total_Scanned__c =
            (session.Total_Scanned__c == null
                ? 0
                : session.Total_Scanned__c) + 1;


        session.Total_Accepted__c =
            (session.Total_Accepted__c == null
                ? 0
                : session.Total_Accepted__c) + 1;


        if (session.Status__c == 'Started') {
            session.Status__c = 'In Progress';
        }


        update session;
    }


    // UPDATE REJECTED COUNTER

    private static void updateRejectedCounter(
        Id sessionId
    ) {

        Inward_Session__c session = [
            SELECT Id,
                   Total_Scanned__c,
                   Total_Rejected__c,
                   Status__c
            FROM Inward_Session__c
            WHERE Id = :sessionId
            LIMIT 1
            FOR UPDATE
        ];


        session.Total_Scanned__c =
            (session.Total_Scanned__c == null
                ? 0
                : session.Total_Scanned__c) + 1;


        session.Total_Rejected__c =
            (session.Total_Rejected__c == null
                ? 0
                : session.Total_Rejected__c) + 1;


        if (session.Status__c == 'Started') {
            session.Status__c = 'In Progress';
        }


        update session;
    }


    // UPDATE DUPLICATE COUNTER

    private static void updateDuplicateCounter(
        Id sessionId
    ) {

        Inward_Session__c session = [
            SELECT Id,
                   Total_Scanned__c,
                   Total_Duplicate__c,
                   Status__c
            FROM Inward_Session__c
            WHERE Id = :sessionId
            LIMIT 1
            FOR UPDATE
        ];


        session.Total_Scanned__c =
            (session.Total_Scanned__c == null
                ? 0
                : session.Total_Scanned__c) + 1;


        session.Total_Duplicate__c =
            (session.Total_Duplicate__c == null
                ? 0
                : session.Total_Duplicate__c) + 1;


        if (session.Status__c == 'Started') {
            session.Status__c = 'In Progress';
        }


        update session;
    }


    // INWARD SESSION RESPONSE

    public class InwardSessionResponse {

        @AuraEnabled
        public Id sessionId;

        @AuraEnabled
        public String sessionNumber;

        @AuraEnabled
        public Id warehouseId;

        @AuraEnabled
        public String warehouseName;

        @AuraEnabled
        public String status;
    }


    // BATTERY SCAN RESPONSE

    public class BatteryScanResponse {

        @AuraEnabled
        public Boolean success;

        @AuraEnabled
        public String message;

        @AuraEnabled
        public String errorCode;

        @AuraEnabled
        public String verificationStatus;

        @AuraEnabled
        public Id batteryId;

        @AuraEnabled
        public String batteryPin;

        @AuraEnabled
        public String qrCode;

        @AuraEnabled
        public String serialNumber;

        @AuraEnabled
        public String batteryModel;

        @AuraEnabled
        public String batchNumber;

        @AuraEnabled
        public Date manufacturingDate;

        @AuraEnabled
        public String plantCode;

        @AuraEnabled
        public String productionRequestId;

        @AuraEnabled
        public String status;
    }
}
