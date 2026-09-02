@IsTest
private class BatteryMovementHistoryControllerTest {

    // =========================================================
    // Helper Method - Create valid Battery
    // =========================================================
    private static Battery__c createBattery(String uniqueValue) {

        Battery__c battery = new Battery__c(
            Batch_Number__c = 'BATCH-' + uniqueValue,
            Battery_Model__c = 'MODEL-A',
            Battery_PIN__c = 'PIN-' + uniqueValue,
            Manufacturing_Date__c = Date.today(),
            Plant_Code__c = 'PLANT-01',
            Production_Request_ID__c = 'REQ-' + uniqueValue,
            QR_Code__c = 'QR-' + uniqueValue,
            Serial_Number__c = 'SERIAL-' + uniqueValue,
            Status__c = 'Produced'
        );

        insert battery;

        return battery;
    }


    // =========================================================
    // Test Setup
    // =========================================================
    @testSetup
    static void setupData() {

        Battery__c battery = createBattery('001');

        Inventory_Transaction__c transaction1 =
            new Inventory_Transaction__c(
                Battery__c = battery.Id,
                Transaction_Date_Time__c =
                    System.now().addDays(-2)
            );

        Inventory_Transaction__c transaction2 =
            new Inventory_Transaction__c(
                Battery__c = battery.Id,
                Transaction_Date_Time__c =
                    System.now().addDays(-1)
            );

        insert new List<Inventory_Transaction__c>{
            transaction1,
            transaction2
        };
    }


    // =========================================================
    // Test 1 - Movement History returned
    // =========================================================
    @IsTest
    static void testGetMovementHistory() {

        Battery__c battery = [
            SELECT Id
            FROM Battery__c
            WHERE Battery_PIN__c = 'PIN-001'
            LIMIT 1
        ];

        System.Test.startTest();

        List<Inventory_Transaction__c> results =
            BatteryMovementHistoryController.getMovementHistory(battery.Id);

        System.Test.stopTest();

        System.assertEquals(
            2,
            results.size(),
            'Two transactions should be returned.'
        );

        System.assertEquals(
            battery.Id,
            results[0].Battery__c,
            'Transaction should belong to requested Battery.'
        );

        System.assert(
            results[0].Transaction_Date_Time__c <=
            results[1].Transaction_Date_Time__c,
            'Movement history should be sorted in ascending order.'
        );
    }


    // =========================================================
    // Test 2 - Battery with no movement history
    // =========================================================
    @IsTest
    static void testBatteryWithoutMovementHistory() {

        Battery__c newBattery = createBattery('002');

        System.Test.startTest();

        List<Inventory_Transaction__c> results =
            BatteryMovementHistoryController.getMovementHistory(newBattery.Id);

        System.Test.stopTest();

        System.assertEquals(
            0,
            results.size(),
            'No transaction should exist for this Battery.'
        );
    }


    // =========================================================
    // Test 3 - Null Battery Id
    // =========================================================
    @IsTest
    static void testNullBatteryId() {

        Boolean exceptionThrown = false;

        System.Test.startTest();

        try {

            BatteryMovementHistoryController.getMovementHistory(null);

        } catch (AuraHandledException e) {

            exceptionThrown = true;
        }

        System.Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'AuraHandledException should be thrown for null Battery Id.'
        );
    }
}
