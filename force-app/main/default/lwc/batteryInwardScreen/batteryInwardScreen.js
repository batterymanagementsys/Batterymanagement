import { LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import jsQRResource from '@salesforce/resourceUrl/jsQR';

import getOrCreateInwardSession
    from '@salesforce/apex/BatteryInwardController.getOrCreateInwardSession';

import processBatteryInward
    from '@salesforce/apex/BatteryInwardController.processBatteryInward';

import completeInwardSession
    from '@salesforce/apex/BatteryInwardController.completeInwardSession';


export default class BatteryInwardScreen extends LightningElement {

    // SESSION

    warehouseName = '';
    sessionNumber = '';
    sessionId = '';
    sessionStatus = '';


    // QR

    qrCode = '';


    // RESULT

    showResult = false;
    showBatteryDetails = false;

    resultMessage = '';
    resultType = '';


    // BATTERY

    batteryId = '';
    batteryPin = '';
    batteryQrCode = '';
    serialNumber = '';
    batteryModel = '';
    batchNumber = '';
    manufacturingDate = '';
    plantCode = '';
    productionRequestId = '';
    batteryStatus = '';


    get batteryRecordUrl() {
        return this.batteryId
            ? '/' + this.batteryId
            : '';
    }


    get showBatteryRecordLink() {
        return !!this.batteryId;
    }


    // COUNTERS

    totalScanned = 0;
    totalAccepted = 0;
    totalRejected = 0;
    totalDuplicate = 0;


    // LOADING

    isLoading = false;
    isScanning = false;
    errorMessage = '';


    // jsQR

    jsQRLoaded = false;
    jsQRLoading = false;


    // CAMERA

    showCamera = false;
    cameraStream = null;
    animationFrameId = null;

    cameraFrameCounter = 0;

    // Process every 3rd frame instead of
    // processing every camera frame.
    scanEveryNthFrame = 3;


    // INITIALIZATION

    connectedCallback() {
        this.loadInwardSession();
    }


    disconnectedCallback() {
        this.stopCamera();
    }


    // RESULT CSS CLASS

    get resultClass() {

        if (this.resultType === 'success') {
            return 'result-section result-success';
        }

        if (this.resultType === 'warning') {
            return 'result-section result-warning';
        }

        return 'result-section result-error';
    }


    // RENDERED CALLBACK

    renderedCallback() {

        const input = this.template.querySelector(
            '[data-id="qrInput"]'
        );

        if (
            input &&
            !this.isScanning &&
            !this.showCamera
        ) {
            input.focus();
        }


        // Load jsQR only once.

        if (
            this.jsQRLoaded ||
            this.jsQRLoading
        ) {
            return;
        }


        this.jsQRLoading = true;


        loadScript(this, jsQRResource)

            .then(() => {

                this.jsQRLoaded = true;

                console.log(
                    'jsQR loaded successfully.'
                );

            })

            .catch(error => {

                this.jsQRLoaded = false;

                this.errorMessage =
                    'Unable to load QR scanning library. ' +
                    this.getErrorMessage(error);

                console.error(
                    'jsQR loading error:',
                    error
                );

            })

            .finally(() => {

                this.jsQRLoading = false;

            });
    }


    // LOAD SESSION

    loadInwardSession() {

        this.isLoading = true;
        this.errorMessage = '';

        getOrCreateInwardSession()

            .then(result => {

                this.warehouseName =
                    result.warehouseName;

                this.sessionNumber =
                    result.sessionNumber;

                this.sessionId =
                    result.sessionId;

                this.sessionStatus =
                    result.status;

            })

            .catch(error => {

                this.errorMessage =
                    this.getErrorMessage(error);

            })

            .finally(() => {

                this.isLoading = false;

            });
    }


    // MANUAL QR INPUT

    handleQrChange(event) {

        this.qrCode =
            event.target.value;
    }


    handleKeyDown(event) {

        if (event.key === 'Enter') {

            event.preventDefault();

            this.handleScan();
        }
    }


    // START CAMERA

    startCamera() {

        if (
            this.isScanning ||
            this.showCamera
        ) {
            return;
        }


        if (!this.jsQRLoaded) {

            this.showError(
                'QR scanning library is still loading. Please try again.'
            );

            return;
        }


        if (
            !navigator.mediaDevices ||
            !navigator.mediaDevices.getUserMedia
        ) {

            this.showError(
                'Camera access is not supported by this browser.'
            );

            return;
        }


        this.showCamera = true;
        this.showResult = false;

        this.cameraFrameCounter = 0;


        // Wait until LWC renders the video.

        requestAnimationFrame(() => {

            const video =
                this.template.querySelector(
                    '[data-id="camera"]'
                );


            if (!video) {

                this.showCamera = false;

                this.showError(
                    'Camera preview could not be initialized.'
                );

                return;
            }


            navigator.mediaDevices.getUserMedia({

                video: {

                    facingMode: {
                        ideal: 'environment'
                    },

                    width: {
                        ideal: 1280
                    },

                    height: {
                        ideal: 720
                    }
                },

                audio: false

            })

                .then(stream => {

                    this.cameraStream =
                        stream;

                    video.srcObject =
                        stream;

                    return video.play();

                })

                .then(() => {

                    console.log(
                        'Camera started.'
                    );

                    this.scanCameraFrame();

                })

                .catch(error => {

                    console.error(
                        'Camera error:',
                        error
                    );

                    this.stopCamera();

                    if (
                        error.name ===
                        'NotAllowedError'
                    ) {

                        this.showError(
                            'Camera permission was denied. Please allow camera access and try again.'
                        );

                    } else if (
                        error.name ===
                        'NotFoundError'
                    ) {

                        this.showError(
                            'No camera was found on this device.'
                        );

                    } else {

                        this.showError(
                            'Unable to access the camera.'
                        );
                    }

                });

        });
    }


    // CAMERA QR SCANNING

    scanCameraFrame() {

        if (
            !this.showCamera ||
            !this.cameraStream
        ) {
            return;
        }


        const video =
            this.template.querySelector(
                '[data-id="camera"]'
            );

        const canvas =
            this.template.querySelector(
                '[data-id="canvas"]'
            );


        if (!video || !canvas) {

            this.animationFrameId =
                requestAnimationFrame(
                    () => this.scanCameraFrame()
                );

            return;
        }


        // Wait until camera has a frame.

        if (
            video.readyState < 2 ||
            video.videoWidth === 0 ||
            video.videoHeight === 0
        ) {

            this.animationFrameId =
                requestAnimationFrame(
                    () => this.scanCameraFrame()
                );

            return;
        }


        // Skip frames to reduce CPU usage.

        this.cameraFrameCounter++;

        if (
            this.cameraFrameCounter %
            this.scanEveryNthFrame !== 0
        ) {

            this.animationFrameId =
                requestAnimationFrame(
                    () => this.scanCameraFrame()
                );

            return;
        }


        if (
            typeof window.jsQR !==
            'function'
        ) {

            this.stopCamera();

            this.showError(
                'QR scanning library is not available.'
            );

            return;
        }


        /*
         * Process a smaller image.
         *
         * 640px is normally enough for
         * a QR code while being much faster
         * than processing 1280x720.
         */

        const maxWidth = 640;


        const scale =
            Math.min(
                1,
                maxWidth /
                video.videoWidth
            );


        const width =
            Math.floor(
                video.videoWidth *
                scale
            );


        const height =
            Math.floor(
                video.videoHeight *
                scale
            );


        canvas.width =
            width;

        canvas.height =
            height;


        const context =
            canvas.getContext(
                '2d',
                {
                    willReadFrequently: true
                }
            );


        context.drawImage(
            video,
            0,
            0,
            width,
            height
        );


        let imageData;


        try {

            imageData =
                context.getImageData(
                    0,
                    0,
                    width,
                    height
                );

        } catch (error) {

            console.error(
                'Camera image error:',
                error
            );

            this.animationFrameId =
                requestAnimationFrame(
                    () => this.scanCameraFrame()
                );

            return;
        }


        let code = null;


        try {

            code =
                window.jsQR(
                    imageData.data,
                    imageData.width,
                    imageData.height,
                    {
                        inversionAttempts:
                            'attemptBoth'
                    }
                );

        } catch (error) {

            console.error(
                'QR detection error:',
                error
            );
        }


        // QR FOUND

        if (
            code &&
            code.data
        ) {

            const detectedQr =
                code.data.trim();


            console.log(
                'QR detected:',
                detectedQr
            );


            /*
             * Apex expects:
             *
             * QR-XXXXXXXX
             *
             * Example:
             * QR-10097
             */

            if (
                !detectedQr.startsWith('QR-')
            ) {

                console.log(
                    'QR detected but format is not QR-.'
                );

                this.animationFrameId =
                    requestAnimationFrame(
                        () => this.scanCameraFrame()
                    );

                return;
            }


            this.qrCode =
                detectedQr;


            this.stopCamera();


            this.handleScan();

            return;
        }


        // Continue scanning.

        this.animationFrameId =
            requestAnimationFrame(
                () => this.scanCameraFrame()
            );
    }


    // STOP CAMERA

    stopCamera() {

        if (
            this.animationFrameId
        ) {

            cancelAnimationFrame(
                this.animationFrameId
            );

            this.animationFrameId =
                null;
        }


        if (
            this.cameraStream
        ) {

            this.cameraStream
                .getTracks()
                .forEach(track => {

                    track.stop();

                });

            this.cameraStream =
                null;
        }


        const video =
            this.template.querySelector(
                '[data-id="camera"]'
            );


        if (video) {

            video.pause();

            video.srcObject =
                null;
        }


        this.showCamera =
            false;

        this.cameraFrameCounter =
            0;
    }


    // PROCESS BATTERY INWARD

    handleScan() {

        if (this.isScanning) {
            return;
        }


        if (
            !this.qrCode ||
            !this.qrCode.trim()
        ) {

            this.showError(
                'Please scan or enter a QR code.'
            );

            return;
        }


        if (!this.sessionId) {

            this.showError(
                'Inward session is not available.'
            );

            return;
        }


        const scannedQr =
            this.qrCode.trim();


        /*
         * Client-side QR format check.
         *
         * Apex also validates this.
         */

        if (
            !/^QR-[A-Z0-9-]+$/.test(
                scannedQr
            )
        ) {

            this.showError(
                'Invalid QR code. QR code must start with QR-.'
            );

            return;
        }


        this.isScanning =
            true;

        this.showResult =
            false;

        this.showBatteryDetails =
            false;

        this.errorMessage =
            '';


        processBatteryInward({

            qrCode:
                scannedQr,

            sessionId:
                this.sessionId

        })

            .then(result => {

                this.handleInwardResult(
                    result
                );

            })

            .catch(error => {

                this.showResult =
                    true;

                this.showBatteryDetails =
                    false;

                this.resultType =
                    'error';

                this.resultMessage =
                    this.getErrorMessage(
                        error
                    );

            })

            .finally(() => {

                this.isScanning =
                    false;

                this.qrCode =
                    '';

            });
    }


    // COMPLETE SESSION

    handleCompleteSession() {

        if (!this.sessionId) {

            this.showError(
                'Inward session is not available.'
            );

            return;
        }


        this.isLoading =
            true;

        this.errorMessage =
            '';


        const completedSession =
            this.sessionNumber;


        this.stopCamera();


        completeInwardSession({

            sessionId:
                this.sessionId

        })

            .then(() => {

                return getOrCreateInwardSession();

            })

            .then(result => {

                this.warehouseName =
                    result.warehouseName;

                this.sessionNumber =
                    result.sessionNumber;

                this.sessionId =
                    result.sessionId;

                this.sessionStatus =
                    result.status;


                // Reset counters.

                this.totalScanned =
                    0;

                this.totalAccepted =
                    0;

                this.totalRejected =
                    0;

                this.totalDuplicate =
                    0;


                // Reset scan data.

                this.qrCode =
                    '';

                this.showBatteryDetails =
                    false;


                this.showResult =
                    true;

                this.resultType =
                    'success';


                this.resultMessage =
                    'Session ' +
                    completedSession +
                    ' completed successfully. New session ' +
                    this.sessionNumber +
                    ' is ready for scanning.';

            })

            .catch(error => {

                this.showResult =
                    true;

                this.showBatteryDetails =
                    false;

                this.resultType =
                    'error';

                this.resultMessage =
                    this.getErrorMessage(
                        error
                    );

            })

            .finally(() => {

                this.isLoading =
                    false;

            });
    }


    // HANDLE APEX RESULT

    handleInwardResult(result) {

        this.showResult =
            true;


        // Clear previous battery information
        // before processing the new result.

        this.batteryId = '';
        this.batteryPin = '';
        this.batteryQrCode = '';
        this.serialNumber = '';
        this.batteryModel = '';
        this.batchNumber = '';
        this.manufacturingDate = '';
        this.plantCode = '';
        this.productionRequestId = '';
        this.batteryStatus = '';


        // ACCEPTED

        if (
            result.verificationStatus ===
            'Accepted'
        ) {

            this.resultType =
                'success';

            this.resultMessage =
                result.message;

            this.showBatteryDetails =
                true;

            this.populateBatteryDetails(
                result
            );

            this.totalScanned++;
            this.totalAccepted++;

            this.sessionStatus =
                'In Progress';

            return;
        }


        // ALREADY INWARDED

        if (
            result.verificationStatus ===
            'Already Inwarded'
        ) {

            this.resultType =
                'warning';

            this.resultMessage =
                result.message;

            this.showBatteryDetails =
                true;

            this.populateBatteryDetails(
                result
            );

            this.totalScanned++;
            this.totalDuplicate++;

            this.sessionStatus =
                'In Progress';

            return;
        }


        // DUPLICATE

        if (
            result.verificationStatus ===
            'Duplicate'
        ) {

            this.resultType =
                'warning';

            this.resultMessage =
                result.message;

            /*
             * Populate battery information
             * so the Battery Record hyperlink
             * works for duplicate scans.
             */
            this.populateBatteryDetails(
                result
            );

            this.showBatteryDetails =
                false;

            this.totalScanned++;
            this.totalDuplicate++;

            this.sessionStatus =
                'In Progress';

            return;
        }


        // REJECTED

        this.resultType =
            'error';

        this.resultMessage =
            result.message;

        this.showBatteryDetails =
            false;

        this.totalScanned++;
        this.totalRejected++;

        this.sessionStatus =
            'In Progress';
    }


    // BATTERY DETAILS

    populateBatteryDetails(result) {

        this.batteryId =
            result.batteryId || '';

        this.batteryPin =
            result.batteryPin || '';

        this.batteryQrCode =
            result.qrCode || '';

        this.serialNumber =
            result.serialNumber || '';

        this.batteryModel =
            result.batteryModel || '';

        this.batchNumber =
            result.batchNumber || '';

        this.manufacturingDate =
            result.manufacturingDate || '';

        this.plantCode =
            result.plantCode || '';

        this.productionRequestId =
            result.productionRequestId || '';

        this.batteryStatus =
            result.status || '';
    }


    // ERROR

    showError(message) {

        this.showResult =
            true;

        this.showBatteryDetails =
            false;

        this.resultType =
            'error';

        this.resultMessage =
            message;
    }


    getErrorMessage(error) {

        if (
            error &&
            error.body &&
            error.body.message
        ) {

            return error.body.message;
        }


        if (
            error &&
            error.message
        ) {

            return error.message;
        }


        return 'Unable to process the battery inward.';
    }
}