@IsTest
private class BatteryFifoControllerTest {

    // =========================================================
    // Helper - Create Battery
    // =========================================================
    private static Battery__c createBattery(
        String suffix,
        String batchNumber,
        Date manufacturingDate,
        String inventoryStatus,
        Boolean fifoEligible
    ) {
        Battery__c battery = new Battery__c(
            Batch_Number__c = batchNumber,
            Battery_Model__c = 'MODEL-A',
            Battery_PIN__c = 'PIN-' + suffix,
            Manufacturing_Date__c = manufacturingDate,
            Plant_Code__c = 'PLANT-01',
            Production_Request_ID__c = 'REQ-' + suffix,
            QR_Code__c = 'QR-FIFO-' + suffix,
            Serial_Number__c = 'SERIAL-' + suffix,
            Status__c = 'Warehouse_Received',
            Inventory_Status__c = inventoryStatus,
            FIFO_Eligible__c = fifoEligible
        );

        insert battery;

        return battery;
    }


    // =========================================================
    // TEST 1 - Get all FIFO eligible available stock
    // =========================================================
    @IsTest
    static void testGetFifoStockWithoutBatchFilter() {

        Battery__c oldBattery = createBattery(
            '001',
            'BATCH-A',
            Date.today().addDays(-10),
            'Available',
            true
        );

        Battery__c newBattery = createBattery(
            '002',
            'BATCH-B',
            Date.today().addDays(-5),
            'Available',
            true
        );

        // Should NOT be returned - dispatched
        createBattery(
            '003',
            'BATCH-C',
            Date.today().addDays(-15),
            'Dispatched',
            true
        );

        // Should NOT be returned - FIFO not eligible
        createBattery(
            '004',
            'BATCH-D',
            Date.today().addDays(-20),
            'Available',
            false
        );

        Test.startTest();

        List<Battery__c> results =
            BatteryFifoController.getFifoStock(
                null,
                null
            );

        Test.stopTest();

        System.assertEquals(
            2,
            results.size(),
            'Only available and FIFO eligible batteries should be returned.'
        );

        System.assertEquals(
            oldBattery.Id,
            results[0].Id,
            'Oldest manufacturing date should be returned first.'
        );

        System.assertEquals(
            newBattery.Id,
            results[1].Id,
            'Newer battery should come after older battery.'
        );

        for (Battery__c battery : results) {

            System.assertEquals(
                'Available',
                battery.Inventory_Status__c
            );

            System.assertEquals(
                true,
                battery.FIFO_Eligible__c
            );
        }
    }


    // =========================================================
    // TEST 2 - Filter by Batch Number
    // =========================================================
    @IsTest
    static void testGetFifoStockWithBatchFilter() {

        Battery__c batchABattery = createBattery(
            '101',
            'BATCH-A',
            Date.today().addDays(-10),
            'Available',
            true
        );

        createBattery(
            '102',
            'BATCH-B',
            Date.today().addDays(-20),
            'Available',
            true
        );

        Test.startTest();

        List<Battery__c> results =
            BatteryFifoController.getFifoStock(
                null,
                'BATCH-A'
            );

        Test.stopTest();

        System.assertEquals(
            1,
            results.size(),
            'Only batteries from the requested batch should be returned.'
        );

        System.assertEquals(
            batchABattery.Id,
            results[0].Id
        );

        System.assertEquals(
            'BATCH-A',
            results[0].Batch_Number__c
        );
    }


    // =========================================================
    // TEST 3 - No matching Batch
    // =========================================================
    @IsTest
    static void testNoMatchingBatch() {

        createBattery(
            '201',
            'BATCH-A',
            Date.today().addDays(-5),
            'Available',
            true
        );

        Test.startTest();

        List<Battery__c> results =
            BatteryFifoController.getFifoStock(
                null,
                'BATCH-NOT-EXIST'
            );

        Test.stopTest();

        System.assertEquals(
            0,
            results.size(),
            'No batteries should be returned for an unknown batch.'
        );
    }


    // =========================================================
    // TEST 4 - Blank Batch Number
    // =========================================================
    @IsTest
    static void testBlankBatchNumber() {

        createBattery(
            '301',
            'BATCH-X',
            Date.today().addDays(-3),
            'Available',
            true
        );

        Test.startTest();

        List<Battery__c> results =
            BatteryFifoController.getFifoStock(
                null,
                ''
            );

        Test.stopTest();

        System.assertEquals(
            1,
            results.size(),
            'Blank batch number should not apply batch filtering.'
        );
    }


    // =========================================================
    // TEST 5 - Warehouse Id currently ignored
    // =========================================================
    @IsTest
    static void testWarehouseIdCurrentlyIgnored() {

        Battery__c battery = createBattery(
            '401',
            'BATCH-WH',
            Date.today().addDays(-2),
            'Available',
            true
        );

        Test.startTest();

        List<Battery__c> results =
            BatteryFifoController.getFifoStock(
                null,
                'BATCH-WH'
            );

        Test.stopTest();

        System.assertEquals(
            1,
            results.size()
        );

        System.assertEquals(
            battery.Id,
            results[0].Id
        );
    }
}