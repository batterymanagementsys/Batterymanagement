@IsTest
private class BatteryInwardSessionTest {

    @TestSetup
    static void setupTestData() {
        Warehouse__c warehouse = new Warehouse__c(
            Warehouse_Code__c = 'WH-TEST-001',
            Name = 'Session Test Warehouse',
            Active__c = true
        );
        insert warehouse;
    }

    @IsTest
    static void testCreateInwardSession() {
        System.Test.startTest();

        BatteryInwardController.InwardSessionResponse response =
            BatteryInwardController.getOrCreateInwardSession();

        System.Test.stopTest();

        System.assertNotEquals(
            null,
            response,
            'Session response should not be null.'
        );

        System.assertNotEquals(
            null,
            response.sessionId,
            'A new inward session should be created.'
        );

        System.assertNotEquals(
            null,
            response.sessionNumber,
            'Session number should be populated.'
        );

        System.assertNotEquals(
            null,
            response.warehouseId,
            'Warehouse should be assigned to the session.'
        );

        System.assertEquals(
            'Session Test Warehouse',
            response.warehouseName,
            'The active warehouse should be returned.'
        );

        System.assertEquals(
            'Started',
            response.status,
            'A newly created session should have Started status.'
        );
    }

    @IsTest
    static void testReuseExistingActiveSession() {
        BatteryInwardController.InwardSessionResponse firstResponse =
            BatteryInwardController.getOrCreateInwardSession();

        System.Test.startTest();

        BatteryInwardController.InwardSessionResponse secondResponse =
            BatteryInwardController.getOrCreateInwardSession();

        System.Test.stopTest();

        System.assertEquals(
            firstResponse.sessionId,
            secondResponse.sessionId,
            'An existing active session should be reused.'
        );

        System.assertEquals(
            firstResponse.sessionNumber,
            secondResponse.sessionNumber,
            'The same session number should be returned.'
        );

        System.assertEquals(
            'Started',
            secondResponse.status,
            'The existing session should still be Started.'
        );

        Integer sessionCount = [
            SELECT COUNT()
            FROM Inward_Session__c
            WHERE Started_By__c = :UserInfo.getUserId()
        ];

        System.assertEquals(
            1,
            sessionCount,
            'Only one active session should exist for the current user.'
        );
    }

    @IsTest
    static void testCompleteInwardSession() {
        BatteryInwardController.InwardSessionResponse response =
            BatteryInwardController.getOrCreateInwardSession();

        System.Test.startTest();

        String result =
            BatteryInwardController.completeInwardSession(
                response.sessionId
            );

        System.Test.stopTest();

        System.assertEquals(
            'Inward session completed successfully.',
            result,
            'The session should be completed successfully.'
        );

        Inward_Session__c session = [
            SELECT Id,
                   Status__c,
                   End_Date_Time__c
            FROM Inward_Session__c
            WHERE Id = :response.sessionId
            LIMIT 1
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

    @IsTest
    static void testCompleteSessionWithNullId() {
        System.Test.startTest();

        try {
            BatteryInwardController.completeInwardSession(null);

            System.assert(
                false,
                'An exception should be thrown when session Id is null.'
            );
        } catch (AuraHandledException ex) {
            System.assert(
                ex.getMessage().contains(
                    'An inward session is required.'
                ),
                'The correct error message should be returned.'
            );
        }

        System.Test.stopTest();
    }
}
