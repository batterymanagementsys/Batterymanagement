@RestResource(urlMapping='/battery/production/*')
global inherited sharing class BatteryProductionRestController {

    @HttpPost
    global static void createBatteryProduction() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');

        try {
            if (request.requestBody == null || String.isBlank(request.requestBody.toString())) {
                sendErrorResponse(response, 400, 'EMPTY_REQUEST', 'Request body is required.');
                return;
            }

            BatteryProductionRequest productionRequest = (BatteryProductionRequest) JSON.deserialize(
                request.requestBody.toString(),
                BatteryProductionRequest.class
            );

            Battery__c battery = BatteryProductionService.processProduction(productionRequest);
            BatteryProductionResponse successResponse = BatteryProductionResponse.success(battery);

            response.statusCode = 201;
            response.responseBody = Blob.valueOf(JSON.serialize(successResponse));

        } catch (BatteryProductionException ex) {
            sendErrorResponse(response, 400, 'VALIDATION_ERROR', ex.getMessage());
        } catch (System.JSONException ex) {
            sendErrorResponse(response, 400, 'INVALID_JSON', 'Malformed JSON request body: ' + ex.getMessage());
        } catch (Exception ex) {
            // Unhandled unexpected exceptions log to 500 without leaking sensitive trace info
            sendErrorResponse(response, 500, 'INTERNAL_ERROR', 'An unexpected error occurred while processing the request.');
        }
    }

    private static void sendErrorResponse(RestResponse response, Integer statusCode, String errorCode, String message) {
        BatteryProductionResponse errorResponse = BatteryProductionResponse.failure(errorCode, message);
        response.statusCode = statusCode;
        response.responseBody = Blob.valueOf(JSON.serialize(errorResponse));
    }
}