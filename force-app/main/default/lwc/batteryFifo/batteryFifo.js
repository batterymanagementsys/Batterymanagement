import { LightningElement } from 'lwc';
import getFifoStock from '@salesforce/apex/BatteryFifoController.getFifoStock';

export default class BatteryFifo extends LightningElement {

    batchNumber = '';
    batteries = [];
    errorMessage;
    isLoading = false;

    columns = [
        {
            label: 'Battery Number',
            fieldName: 'Name'
        },
        {
            label: 'Battery PIN',
            fieldName: 'Battery_PIN__c'
        },
        {
            label: 'QR Code',
            fieldName: 'QR_Code__c'
        },
        {
            label: 'Batch',
            fieldName: 'Batch_Number__c'
        },
        {
            label: 'Manufacturing Date',
            fieldName: 'Manufacturing_Date__c',
            type: 'date'
        },
        {
            label: 'Inventory Status',
            fieldName: 'Inventory_Status__c'
        },
        {
            label: 'Created Date',
            fieldName: 'CreatedDate'
        }
    ];

    get hasBatteries() {
        return this.batteries && this.batteries.length > 0;
    }

    connectedCallback() {
        this.loadFifoStock();
    }

    handleBatchChange(event) {
        this.batchNumber = event.target.value;
    }

    handleSearch() {
        this.loadFifoStock();
    }

    handleClear() {
        this.batchNumber = '';
        this.loadFifoStock();
    }

    async loadFifoStock() {

        this.isLoading = true;
        this.errorMessage = undefined;

        try {

            const result = await getFifoStock({
                warehouseId: null,
                batchNumber: this.batchNumber
            });

            this.batteries = result;

            if (result.length === 0) {
                this.errorMessage =
                    'No FIFO eligible batteries found.';
            }

        } catch (error) {

            console.error('FIFO Error:', error);

            this.batteries = [];

            this.errorMessage =
                error?.body?.message ||
                'Unable to load FIFO stock.';

        } finally {

            this.isLoading = false;
        }
    }
}