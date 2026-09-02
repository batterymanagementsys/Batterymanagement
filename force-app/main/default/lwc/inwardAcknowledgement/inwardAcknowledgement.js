import { LightningElement, api, wire } from 'lwc';

import getAcknowledgement
    from '@salesforce/apex/InwardAcknowledgementController.getAcknowledgement';

export default class InwardAcknowledgement extends LightningElement {

    @api recordId;

    acknowledgementData;
    errorMessage;
    isLoading = true;


    @wire(getAcknowledgement, {
        sessionId: '$recordId'
    })
    wiredAcknowledgement({ error, data }) {

        this.isLoading = false;

        if (data) {

            this.acknowledgementData = data;
            this.errorMessage = undefined;

        }
        else if (error) {

            this.acknowledgementData = undefined;

            this.errorMessage =
                error?.body?.message ||
                'Unable to load inward acknowledgement.';
        }
    }


    get hasAcceptedItems() {
        return (
            this.acknowledgementData?.acceptedItems?.length > 0
        );
    }


    get hasRejectedItems() {
        return (
            this.acknowledgementData?.rejectedItems?.length > 0
        );
    }


    get hasDuplicateItems() {
        return (
            this.acknowledgementData?.duplicateItems?.length > 0
        );
    }
}