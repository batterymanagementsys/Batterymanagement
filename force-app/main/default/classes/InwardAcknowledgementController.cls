public with sharing class InwardAcknowledgementController {

    public class AcknowledgementWrapper {

        @AuraEnabled
        public Id sessionId;

        @AuraEnabled
        public String sessionNumber;

        @AuraEnabled
        public String acknowledgement;

        @AuraEnabled
        public String warehouseName;

        @AuraEnabled
        public String operatorName;

        @AuraEnabled
        public Datetime completedDateTime;

        @AuraEnabled
        public Integer acceptedCount;

        @AuraEnabled
        public Integer rejectedCount;

        @AuraEnabled
        public Integer duplicateCount;

        @AuraEnabled
        public List<Battery_Inward__c> acceptedItems;

        @AuraEnabled
        public List<Battery_Inward__c> rejectedItems;

        @AuraEnabled
        public List<Battery_Inward__c> duplicateItems;
    }


    @AuraEnabled(cacheable=true)
    public static AcknowledgementWrapper getAcknowledgement(Id sessionId) {

        if (sessionId == null) {
            throw new AuraHandledException(
                'Inward Session Id is required.'
            );
        }

        Inward_Session__c session = [
            SELECT Id,
                   Name,
                   Acknowledgment__c,
                   Warehouse__r.Name,
                   Started_By__r.Name,
                   End_Date_Time__c,
                   Total_Accepted__c,
                   Total_Rejected__c,
                   Total_Duplicate__c,
                   Status__c
            FROM Inward_Session__c
            WHERE Id = :sessionId
            LIMIT 1
        ];

        if (session.Status__c != 'Completed') {
            throw new AuraHandledException(
                'Acknowledgement is available only for completed sessions.'
            );
        }

        List<Battery_Inward__c> inwardRecords = [
            SELECT Id,
                   Name,
                   Battery__c,
                   Battery__r.Name,
                   Scanned_QR__c,
                   Verification_Status__c,
                   Failure_Reason__c,
                   Scan_Date_Time__c
            FROM Battery_Inward__c
            WHERE Inward_Session__c = :sessionId
            ORDER BY Scan_Date_Time__c ASC
        ];

        AcknowledgementWrapper result =
            new AcknowledgementWrapper();

        result.sessionId =
            session.Id;

        result.sessionNumber =
            session.Name;

        result.acknowledgement =
            session.Acknowledgment__c;

        result.warehouseName =
            session.Warehouse__r != null
                ? session.Warehouse__r.Name
                : '';

        result.operatorName =
            session.Started_By__r != null
                ? session.Started_By__r.Name
                : '';

        result.completedDateTime =
            session.End_Date_Time__c;

        result.acceptedCount =
            session.Total_Accepted__c == null
                ? 0
                : Integer.valueOf(session.Total_Accepted__c);

        result.rejectedCount =
            session.Total_Rejected__c == null
                ? 0
                : Integer.valueOf(session.Total_Rejected__c);

        result.duplicateCount =
            session.Total_Duplicate__c == null
                ? 0
                : Integer.valueOf(session.Total_Duplicate__c);

        result.acceptedItems =
            new List<Battery_Inward__c>();

        result.rejectedItems =
            new List<Battery_Inward__c>();

        result.duplicateItems =
            new List<Battery_Inward__c>();

        for (Battery_Inward__c inward : inwardRecords) {

            if (inward.Verification_Status__c == 'Accepted') {
                result.acceptedItems.add(inward);
            }
            else if (inward.Verification_Status__c == 'Rejected') {
                result.rejectedItems.add(inward);
            }
            else if (inward.Verification_Status__c == 'Duplicate') {
                result.duplicateItems.add(inward);
            }
        }

        return result;
    }
}