import { LightningElement, api, wire } from 'lwc';

import getMovementHistory
    from '@salesforce/apex/BatteryMovementHistoryController.getMovementHistory';

export default class BatteryMovementHistory extends LightningElement {

    @api recordId;

    transactions = [];
    errorMessage;

    columns = [
        {
            label: 'Transaction',
            fieldName: 'Name'
        },
        {
            label: 'Type',
            fieldName: 'Transaction_Type__c'
        },
        {
            label: 'Source',
            fieldName: 'sourceName'
        },
        {
            label: 'Destination',
            fieldName: 'destinationName'
        },
        {
            label: 'Batch',
            fieldName: 'Batch_Number__c'
        },
        {
            label: 'Date/Time',
            fieldName: 'Transaction_Date_Time__c',
            type: 'date'
        },
        {
            label: 'Status',
            fieldName: 'Status__c'
        },
        {
            label: 'Created By',
            fieldName: 'createdByName'
        }
    ];

    @wire(getMovementHistory, {
        batteryId: '$recordId'
    })
    wiredHistory({ data, error }) {

        if (data) {

            this.transactions = data.map(transaction => ({
                ...transaction,
                sourceName:
                    transaction.Source_Location__r?.Name || '-',
                destinationName:
                    transaction.Destination_Location__r?.Name || '-',
                createdByName:
                    transaction.CreatedBy?.Name || '-'
            }));

            this.errorMessage = undefined;
        }

        if (error) {

            this.errorMessage =
                error.body?.message ||
                'Unable to load movement history.';
        }
    }
}