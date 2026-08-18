@IsTest
private class BatteryProductionTest {

    // ============================================================
    // HELPER: VALID REQUEST
    // ============================================================

    private static BatteryProductionRequest getValidRequest() {

        BatteryProductionRequest request =
            new BatteryProductionRequest();

        request.batteryPin = 'BAT-TEST-001';
        request.qrCode = 'QR-TEST-001';
        request.serialNumber = 'SN-TEST-001';
        request.batteryModel = 'MODEL-X';
        request.batchNumber = 'BATCH-001';
        request.manufacturingDate = Date.today();
        request.plantCode = 'PLANT-01';
        request.productionRequestId = 'REQ-TEST-001';

        return request;
    }


    // ============================================================
    // HELPER: REST CONTEXT
    // ============================================================

    private static void setupRestContext(String requestBody) {

        RestRequest request = new RestRequest();

        request.requestUri =
            '/services/apexrest/battery/production';

        request.httpMethod = 'POST';

        if (requestBody != null) {
            request.requestBody = Blob.valueOf(requestBody);
        }

        RestContext.request = request;
        RestContext.response = new RestResponse();
    }


    // ============================================================
    // HELPER: CREATE BATTERY
    // ============================================================

    private static Battery__c createBattery(
        String batteryPin,
        String productionRequestId
    ) {

        Battery__c battery = new Battery__c(
            Battery_PIN__c = batteryPin,
            QR_Code__c = 'QR-TEST-001',
            Serial_Number__c = 'SN-TEST-001',
            Battery_Model__c = 'MODEL-X',
            Batch_Number__c = 'BATCH-001',
            Manufacturing_Date__c = Date.today(),
            Plant_Code__c = 'PLANT-01',
            Production_Request_ID__c = productionRequestId,
            Status__c = 'Produced',
            Created_From_API__c = true
        );

        insert battery;

        return battery;
    }


    // ============================================================
    // 1. BATTERY PRODUCTION REQUEST
    // ============================================================

    @IsTest
    static void testProductionRequestDTO() {

        BatteryProductionRequest request =
            getValidRequest();

        System.Assert.isNotNull(request);

        System.Assert.areEqual(
            'BAT-TEST-001',
            request.batteryPin
        );

        System.Assert.areEqual(
            'QR-TEST-001',
            request.qrCode
        );

        System.Assert.areEqual(
            'SN-TEST-001',
            request.serialNumber
        );

        System.Assert.areEqual(
            'MODEL-X',
            request.batteryModel
        );

        System.Assert.areEqual(
            'BATCH-001',
            request.batchNumber
        );

        System.Assert.areEqual(
            Date.today(),
            request.manufacturingDate
        );

        System.Assert.areEqual(
            'PLANT-01',
            request.plantCode
        );

        System.Assert.areEqual(
            'REQ-TEST-001',
            request.productionRequestId
        );
    }


    // ============================================================
    // 2. RESPONSE DEFAULT CONSTRUCTOR
    // ============================================================

    @IsTest
    static void testResponseConstructor() {

        BatteryProductionResponse response =
            new BatteryProductionResponse();

        System.Assert.isNotNull(response);

        System.Assert.isNull(response.success);
        System.Assert.isNull(response.message);
        System.Assert.isNull(response.errorCode);
        System.Assert.isNull(response.batteryId);
        System.Assert.isNull(response.batteryNumber);
        System.Assert.isNull(response.productionRequestId);
        System.Assert.isNull(response.status);
    }


    // ============================================================
    // 3. RESPONSE SUCCESS
    // ============================================================

    @IsTest
    static void testResponseSuccess() {

        Battery__c battery =
            createBattery(
                'BAT-RESP-001',
                'REQ-RESP-001'
            );

        battery = [
            SELECT Id,
                   Name,
                   Production_Request_ID__c,
                   Status__c
            FROM Battery__c
            WHERE Id = :battery.Id
            LIMIT 1
        ];

        Test.startTest();

        BatteryProductionResponse response =
            BatteryProductionResponse.success(battery);

        Test.stopTest();

        System.Assert.isNotNull(response);

        System.Assert.areEqual(
            true,
            response.success
        );

        System.Assert.areEqual(
            'Battery production data processed successfully',
            response.message
        );

        System.Assert.isNull(
            response.errorCode
        );

        System.Assert.areEqual(
            battery.Id,
            response.batteryId
        );

        System.Assert.areEqual(
            battery.Name,
            response.batteryNumber
        );

        System.Assert.areEqual(
            battery.Production_Request_ID__c,
            response.productionRequestId
        );

        System.Assert.areEqual(
            battery.Status__c,
            response.status
        );
    }


    // ============================================================
    // 4. RESPONSE FAILURE
    // ============================================================

    @IsTest
    static void testResponseFailure() {

        Test.startTest();

        BatteryProductionResponse response =
            BatteryProductionResponse.failure(
                'VALIDATION_ERROR',
                'Battery PIN is required.'
            );

        Test.stopTest();

        System.Assert.isNotNull(response);

        System.Assert.areEqual(
            false,
            response.success
        );

        System.Assert.areEqual(
            'VALIDATION_ERROR',
            response.errorCode
        );

        System.Assert.areEqual(
            'Battery PIN is required.',
            response.message
        );

        System.Assert.isNull(
            response.batteryId
        );

        System.Assert.isNull(
            response.batteryNumber
        );

        System.Assert.isNull(
            response.productionRequestId
        );

        System.Assert.isNull(
            response.status
        );
    }


    // ============================================================
    // 5. VALIDATOR - VALID REQUEST
    // ============================================================

    @IsTest
    static void testValidatorValidRequest() {

        BatteryProductionRequest request =
            getValidRequest();

        Test.startTest();

        BatteryProductionValidator.validate(request);

        Test.stopTest();

        System.Assert.isTrue(true);
    }


    // ============================================================
    // 6. VALIDATOR - NULL REQUEST
    // ============================================================

    @IsTest
    static void testValidatorNullRequest() {

        try {

            Test.startTest();

            BatteryProductionValidator.validate(null);

            Test.stopTest();

            System.Assert.fail(
                'Expected BatteryProductionException.'
            );

        } catch (BatteryProductionException ex) {

            System.Assert.areEqual(
                'Request body is required.',
                ex.getMessage()
            );
        }
    }


    // ============================================================
    // 7. VALIDATOR - MISSING BATTERY PIN
    // ============================================================

    @IsTest
    static void testValidatorMissingBatteryPin() {

        BatteryProductionRequest request =
            getValidRequest();

        request.batteryPin = null;

        try {

            Test.startTest();

            BatteryProductionValidator.validate(request);

            Test.stopTest();

            System.Assert.fail(
                'Expected BatteryProductionException.'
            );

        } catch (BatteryProductionException ex) {

            System.Assert.areEqual(
                'Battery PIN is required.',
                ex.getMessage()
            );
        }
    }


    // ============================================================
    // 8. VALIDATOR - MISSING QR CODE
    // ============================================================

    @IsTest
    static void testValidatorMissingQRCode() {

        BatteryProductionRequest request =
            getValidRequest();

        request.qrCode = null;

        try {

            Test.startTest();

            BatteryProductionValidator.validate(request);

            Test.stopTest();

            System.Assert.fail(
                'Expected BatteryProductionException.'
            );

        } catch (BatteryProductionException ex) {

            System.Assert.areEqual(
                'QR Code is required.',
                ex.getMessage()
            );
        }
    }


    // ============================================================
    // 9. VALIDATOR - MISSING SERIAL NUMBER
    // ============================================================

    @IsTest
    static void testValidatorMissingSerialNumber() {

        BatteryProductionRequest request =
            getValidRequest();

        request.serialNumber = null;

        try {

            Test.startTest();

            BatteryProductionValidator.validate(request);

            Test.stopTest();

            System.Assert.fail(
                'Expected BatteryProductionException.'
            );

        } catch (BatteryProductionException ex) {

            System.Assert.areEqual(
                'Serial Number is required.',
                ex.getMessage()
            );
        }
    }


    // ============================================================
    // 10. VALIDATOR - MISSING BATTERY MODEL
    // ============================================================

    @IsTest
    static void testValidatorMissingBatteryModel() {

        BatteryProductionRequest request =
            getValidRequest();

        request.batteryModel = null;

        try {

            Test.startTest();

            BatteryProductionValidator.validate(request);

            Test.stopTest();

            System.Assert.fail(
                'Expected BatteryProductionException.'
            );

        } catch (BatteryProductionException ex) {

            System.Assert.areEqual(
                'Battery Model is required.',
                ex.getMessage()
            );
        }
    }


    // ============================================================
    // 11. VALIDATOR - MISSING BATCH NUMBER
    // ============================================================

    @IsTest
    static void testValidatorMissingBatchNumber() {

        BatteryProductionRequest request =
            getValidRequest();

        request.batchNumber = null;

        try {

            Test.startTest();

            BatteryProductionValidator.validate(request);

            Test.stopTest();

            System.Assert.fail(
                'Expected BatteryProductionException.'
            );

        } catch (BatteryProductionException ex) {

            System.Assert.areEqual(
                'Batch Number is required.',
                ex.getMessage()
            );
        }
    }


    // ============================================================
    // 12. VALIDATOR - MISSING MANUFACTURING DATE
    // ============================================================

    @IsTest
    static void testValidatorMissingManufacturingDate() {

        BatteryProductionRequest request =
            getValidRequest();

        request.manufacturingDate = null;

        try {

            Test.startTest();

            BatteryProductionValidator.validate(request);

            Test.stopTest();

            System.Assert.fail(
                'Expected BatteryProductionException.'
            );

        } catch (BatteryProductionException ex) {

            System.Assert.areEqual(
                'Manufacturing Date is required.',
                ex.getMessage()
            );
        }
    }


    // ============================================================
    // 13. VALIDATOR - MISSING PLANT CODE
    // ============================================================

    @IsTest
    static void testValidatorMissingPlantCode() {

        BatteryProductionRequest request =
            getValidRequest();

        request.plantCode = null;

        try {

            Test.startTest();

            BatteryProductionValidator.validate(request);

            Test.stopTest();

            System.Assert.fail(
                'Expected BatteryProductionException.'
            );

        } catch (BatteryProductionException ex) {

            System.Assert.areEqual(
                'Plant Code is required.',
                ex.getMessage()
            );
        }
    }


    // ============================================================
    // 14. VALIDATOR - MISSING REQUEST ID
    // ============================================================

    @IsTest
    static void testValidatorMissingRequestId() {

        BatteryProductionRequest request =
            getValidRequest();

        request.productionRequestId = null;

        try {

            Test.startTest();

            BatteryProductionValidator.validate(request);

            Test.stopTest();

            System.Assert.fail(
                'Expected BatteryProductionException.'
            );

        } catch (BatteryProductionException ex) {

            System.Assert.areEqual(
                'Production Request ID is required.',
                ex.getMessage()
            );
        }
    }


    // ============================================================
    // 15. INVALID BATTERY PIN FORMAT
    // ============================================================

    @IsTest
    static void testInvalidBatteryPinFormat() {

        BatteryProductionRequest request =
            getValidRequest();

        request.batteryPin = 'INVALID-PIN';

        try {

            Test.startTest();

            BatteryProductionValidator.validate(request);

            Test.stopTest();

            System.Assert.fail(
                'Expected exception.'
            );

        } catch (BatteryProductionException ex) {

            System.Assert.areEqual(
                'Invalid Battery PIN format.',
                ex.getMessage()
            );
        }
    }


    // ============================================================
    // 16. INVALID QR FORMAT
    // ============================================================

    @IsTest
    static void testInvalidQRCodeFormat() {

        BatteryProductionRequest request =
            getValidRequest();

        request.qrCode = 'INVALID-QR';

        try {

            Test.startTest();

            BatteryProductionValidator.validate(request);

            Test.stopTest();

            System.Assert.fail(
                'Expected exception.'
            );

        } catch (BatteryProductionException ex) {

            System.Assert.areEqual(
                'Invalid QR Code format.',
                ex.getMessage()
            );
        }
    }


    // ============================================================
    // 17. INVALID SERIAL FORMAT
    // ============================================================

    @IsTest
    static void testInvalidSerialNumberFormat() {

        BatteryProductionRequest request =
            getValidRequest();

        request.serialNumber = 'INVALID-SERIAL';

        try {

            Test.startTest();

            BatteryProductionValidator.validate(request);

            Test.stopTest();

            System.Assert.fail(
                'Expected exception.'
            );

        } catch (BatteryProductionException ex) {

            System.Assert.areEqual(
                'Invalid Serial Number format.',
                ex.getMessage()
            );
        }
    }


    // ============================================================
    // 18. SERVICE - SUCCESS
    // ============================================================

    @IsTest
    static void testServiceSuccess() {

        BatteryProductionRequest request =
            getValidRequest();

        Test.startTest();

        Battery__c battery =
            BatteryProductionService.processProduction(request);

        Test.stopTest();

        System.Assert.isNotNull(battery);
        System.Assert.isNotNull(battery.Id);

        System.Assert.areEqual(
            'BAT-TEST-001',
            battery.Battery_PIN__c
        );

        System.Assert.areEqual(
            'QR-TEST-001',
            battery.QR_Code__c
        );

        System.Assert.areEqual(
            'SN-TEST-001',
            battery.Serial_Number__c
        );

        System.Assert.areEqual(
            'MODEL-X',
            battery.Battery_Model__c
        );

        System.Assert.areEqual(
            'BATCH-001',
            battery.Batch_Number__c
        );

        System.Assert.areEqual(
            Date.today(),
            battery.Manufacturing_Date__c
        );

        System.Assert.areEqual(
            'PLANT-01',
            battery.Plant_Code__c
        );

        System.Assert.areEqual(
            'REQ-TEST-001',
            battery.Production_Request_ID__c
        );

        System.Assert.areEqual(
            'Produced',
            battery.Status__c
        );

        System.Assert.areEqual(
            true,
            battery.Created_From_API__c
        );
    }


    // ============================================================
    // 19. SERVICE - DUPLICATE PIN
    // ============================================================

    @IsTest
    static void testServiceDuplicatePin() {

        createBattery(
            'BAT-DUPLICATE-001',
            'REQ-EXISTING-001'
        );

        BatteryProductionRequest request =
            getValidRequest();

        request.batteryPin =
            'BAT-DUPLICATE-001';

        request.productionRequestId =
            'REQ-NEW-001';

        try {

            Test.startTest();

            BatteryProductionService.processProduction(request);

            Test.stopTest();

            System.Assert.fail(
                'Expected duplicate exception.'
            );

        } catch (BatteryProductionException ex) {

            System.Assert.isTrue(
                ex.getMessage().contains(
                    'Duplicate record detected'
                )
            );
        }
    }


    // ============================================================
    // 20. SERVICE - DUPLICATE REQUEST ID
    // ============================================================

    @IsTest
    static void testServiceDuplicateRequestId() {

        createBattery(
            'BAT-EXISTING-001',
            'REQ-DUPLICATE-001'
        );

        BatteryProductionRequest request =
            getValidRequest();

        request.batteryPin =
            'BAT-NEW-001';

        request.productionRequestId =
            'REQ-DUPLICATE-001';

        try {

            Test.startTest();

            BatteryProductionService.processProduction(request);

            Test.stopTest();

            System.Assert.fail(
                'Expected duplicate exception.'
            );

        } catch (BatteryProductionException ex) {

            System.Assert.isTrue(
                ex.getMessage().contains(
                    'Duplicate record detected'
                )
            );
        }
    }


    // ============================================================
    // 21. CONTROLLER - SUCCESS
    // ============================================================

    @IsTest
    static void testControllerSuccess() {

        BatteryProductionRequest request =
            getValidRequest();

        setupRestContext(
            JSON.serialize(request)
        );

        Test.startTest();

        BatteryProductionRestController.createBatteryProduction();

        Test.stopTest();

        System.Assert.areEqual(
            201,
            RestContext.response.statusCode
        );

        System.Assert.isNotNull(
            RestContext.response.responseBody
        );

        BatteryProductionResponse response =
            (BatteryProductionResponse) JSON.deserialize(
                RestContext.response.responseBody.toString(),
                BatteryProductionResponse.class
            );

        System.Assert.areEqual(
            true,
            response.success
        );

        System.Assert.areEqual(
            'Produced',
            response.status
        );

        System.Assert.areEqual(
            'REQ-TEST-001',
            response.productionRequestId
        );

        Battery__c battery = [
            SELECT Id,
                   Battery_PIN__c,
                   Status__c,
                   Production_Request_ID__c
            FROM Battery__c
            WHERE Battery_PIN__c = 'BAT-TEST-001'
            LIMIT 1
        ];

        System.Assert.areEqual(
            'BAT-TEST-001',
            battery.Battery_PIN__c
        );

        System.Assert.areEqual(
            'Produced',
            battery.Status__c
        );
    }


    // ============================================================
    // 22. CONTROLLER - EMPTY BODY
    // ============================================================

    @IsTest
    static void testControllerEmptyBody() {

        setupRestContext('');

        Test.startTest();

        BatteryProductionRestController.createBatteryProduction();

        Test.stopTest();

        System.Assert.areEqual(
            400,
            RestContext.response.statusCode
        );

        BatteryProductionResponse response =
            (BatteryProductionResponse) JSON.deserialize(
                RestContext.response.responseBody.toString(),
                BatteryProductionResponse.class
            );

        System.Assert.areEqual(
            false,
            response.success
        );

        System.Assert.areEqual(
            'EMPTY_REQUEST',
            response.errorCode
        );

        System.Assert.areEqual(
            'Request body is required.',
            response.message
        );
    }


    // ============================================================
    // 23. CONTROLLER - MISSING REQUIRED FIELD
    // ============================================================

    @IsTest
    static void testControllerMissingRequiredField() {

        Map<String, Object> requestMap =
            new Map<String, Object>{
                'qrCode' => 'QR-TEST-001',
                'serialNumber' => 'SN-TEST-001',
                'batteryModel' => 'MODEL-X',
                'batchNumber' => 'BATCH-001',
                'manufacturingDate' => Date.today(),
                'plantCode' => 'PLANT-01',
                'productionRequestId' => 'REQ-TEST-002'
            };

        setupRestContext(
            JSON.serialize(requestMap)
        );

        Test.startTest();

        BatteryProductionRestController.createBatteryProduction();

        Test.stopTest();

        System.Assert.areEqual(
            400,
            RestContext.response.statusCode
        );

        BatteryProductionResponse response =
            (BatteryProductionResponse) JSON.deserialize(
                RestContext.response.responseBody.toString(),
                BatteryProductionResponse.class
            );

        System.Assert.areEqual(
            false,
            response.success
        );

        System.Assert.areEqual(
            'VALIDATION_ERROR',
            response.errorCode
        );

        System.Assert.areEqual(
            'Battery PIN is required.',
            response.message
        );
    }


    // ============================================================
    // 24. CONTROLLER - DUPLICATE BATTERY
    // ============================================================

    @IsTest
    static void testControllerDuplicateBattery() {

        createBattery(
            'BAT-DUP-CONTROLLER',
            'REQ-DUP-CONTROLLER'
        );

        BatteryProductionRequest request =
            getValidRequest();

        request.batteryPin =
            'BAT-DUP-CONTROLLER';

        request.productionRequestId =
            'REQ-NEW-CONTROLLER';

        setupRestContext(
            JSON.serialize(request)
        );

        Test.startTest();

        BatteryProductionRestController.createBatteryProduction();

        Test.stopTest();

        System.Assert.areEqual(
            400,
            RestContext.response.statusCode
        );

        BatteryProductionResponse response =
            (BatteryProductionResponse) JSON.deserialize(
                RestContext.response.responseBody.toString(),
                BatteryProductionResponse.class
            );

        System.Assert.areEqual(
            false,
            response.success
        );

        System.Assert.areEqual(
            'VALIDATION_ERROR',
            response.errorCode
        );

        System.Assert.isTrue(
            response.message.contains(
                'Duplicate record detected'
            )
        );
    }


    // ============================================================
    // 25. CONTROLLER - INVALID JSON
    // ============================================================

    @IsTest
    static void testControllerInvalidJson() {

        setupRestContext(
            '{"batteryPin":"BAT-001",INVALID_JSON}'
        );

        Test.startTest();

        BatteryProductionRestController.createBatteryProduction();

        Test.stopTest();

        System.Assert.areEqual(
            400,
            RestContext.response.statusCode
        );

        BatteryProductionResponse response =
            (BatteryProductionResponse) JSON.deserialize(
                RestContext.response.responseBody.toString(),
                BatteryProductionResponse.class
            );

        System.Assert.areEqual(
            false,
            response.success
        );

        System.Assert.areEqual(
            'INVALID_JSON',
            response.errorCode
        );

        System.Assert.isTrue(
            response.message.contains(
                'Malformed JSON request body'
            )
        );
    }


    // ============================================================
    // 26. CONTROLLER - INVALID BATTERY PIN
    // ============================================================

    @IsTest
    static void testControllerInvalidBatteryPin() {

        BatteryProductionRequest request =
            getValidRequest();

        request.batteryPin =
            'INVALID-PIN';

        setupRestContext(
            JSON.serialize(request)
        );

        Test.startTest();

        BatteryProductionRestController.createBatteryProduction();

        Test.stopTest();

        System.Assert.areEqual(
            400,
            RestContext.response.statusCode
        );

        BatteryProductionResponse response =
            (BatteryProductionResponse) JSON.deserialize(
                RestContext.response.responseBody.toString(),
                BatteryProductionResponse.class
            );

        System.Assert.areEqual(
            'VALIDATION_ERROR',
            response.errorCode
        );

        System.Assert.areEqual(
            'Invalid Battery PIN format.',
            response.message
        );
    }


    // ============================================================
    // 27. CONTROLLER - MISSING QR CODE
    // ============================================================

    @IsTest
    static void testControllerMissingQRCode() {

        BatteryProductionRequest request =
            getValidRequest();

        request.qrCode = null;

        setupRestContext(
            JSON.serialize(request)
        );

        Test.startTest();

        BatteryProductionRestController.createBatteryProduction();

        Test.stopTest();

        System.Assert.areEqual(
            400,
            RestContext.response.statusCode
        );

        BatteryProductionResponse response =
            (BatteryProductionResponse) JSON.deserialize(
                RestContext.response.responseBody.toString(),
                BatteryProductionResponse.class
            );

        System.Assert.areEqual(
            'VALIDATION_ERROR',
            response.errorCode
        );

        System.Assert.areEqual(
            'QR Code is required.',
            response.message
        );
    }
}