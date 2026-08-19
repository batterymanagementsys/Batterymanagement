public class BatteryProductionResponse {
    public Boolean success;
    public String message;
    public String errorCode;
    public String batteryId;
    public String batteryNumber;
    public String productionRequestId;
    public String status;

    public BatteryProductionResponse() {}

    public static BatteryProductionResponse success(Battery__c battery) {
        BatteryProductionResponse response = new BatteryProductionResponse();
        response.success = true;
        response.message = 'Battery production data processed successfully';
        response.batteryId = battery.Id;
        response.batteryNumber = battery.Name;
        response.productionRequestId = battery.Production_Request_ID__c;
        response.status = battery.Status__c;
        return response;
    }

    public static BatteryProductionResponse failure(String errorCode, String message) {
        BatteryProductionResponse response = new BatteryProductionResponse();
        response.success = false;
        response.errorCode = errorCode;
        response.message = message;
        return response;
    }
}