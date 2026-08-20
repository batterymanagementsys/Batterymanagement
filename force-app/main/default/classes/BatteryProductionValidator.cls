public inherited sharing class BatteryProductionValidator {

    private static final Pattern PIN_PATTERN = Pattern.compile('^BAT-[A-Z0-9-]+$');
    private static final Pattern QR_PATTERN = Pattern.compile('^QR-[A-Z0-9-]+$');
    private static final Pattern SERIAL_PATTERN = Pattern.compile('^SN-[A-Z0-9-]+$');

    public static void validate(BatteryProductionRequest request) {
        if (request == null) {
            throw new BatteryProductionException('Request body is required.');
        }

        // Required Field Checks
        if (String.isBlank(request.batteryPin)) {
            throw new BatteryProductionException('Battery PIN is required.');
        }
        if (String.isBlank(request.qrCode)) {
            throw new BatteryProductionException('QR Code is required.');
        }
        if (String.isBlank(request.serialNumber)) {
            throw new BatteryProductionException('Serial Number is required.');
        }
        if (String.isBlank(request.batteryModel)) {
            throw new BatteryProductionException('Battery Model is required.');
        }
        if (String.isBlank(request.batchNumber)) {
            throw new BatteryProductionException('Batch Number is required.');
        }
        if (request.manufacturingDate == null) {
            throw new BatteryProductionException('Manufacturing Date is required.');
        }
        if (String.isBlank(request.plantCode)) {
            throw new BatteryProductionException('Plant Code is required.');
        }
        if (String.isBlank(request.productionRequestId)) {
            throw new BatteryProductionException('Production Request ID is required.');
        }

        // Format Regex Validation
        validateFormat(request.batteryPin, PIN_PATTERN, 'Invalid Battery PIN format.');
        validateFormat(request.qrCode, QR_PATTERN, 'Invalid QR Code format.');
        validateFormat(request.serialNumber, SERIAL_PATTERN, 'Invalid Serial Number format.');
    }

    private static void validateFormat(String value, Pattern pattern, String errorMessage) {
        if (!pattern.matcher(value).matches()) {
            throw new BatteryProductionException(errorMessage);
        }
    }
}