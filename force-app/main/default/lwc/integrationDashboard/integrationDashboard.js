import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getFailedLogs from '@salesforce/apex/IntegrationDashboardController.getFailedLogs';
import retrySingle from '@salesforce/apex/IntegrationDashboardController.retrySingle';

const COLUMNS = [
    { label: 'Endpoint', fieldName: 'Endpoint__c', type: 'text' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'Retry Count', fieldName: 'Retry_Count__c', type: 'number' },
    {
        label: 'Created',
        fieldName: 'CreatedDate',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }
    },
    {
        type: 'button',
        typeAttributes: {
            label: 'Retry',
            name: 'retry',
            title: 'Retry this integration',
            variant: 'brand'
        }
    }
];

export default class IntegrationDashboard extends LightningElement {
    columns = COLUMNS;
    logs = [];
    wiredResult;

    @wire(getFailedLogs)
    wiredLogs(result) {
        this.wiredResult = result;
        const { data, error } = result;
        if (data) {
            this.logs = data;
        } else if (error) {
            this.showToast('Error', this.reduceError(error), 'error');
        }
    }

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName !== 'retry') {
            return;
        }

        try {
            await retrySingle({ logId: row.Id });
            this.showToast('Success', 'Manual retry triggered successfully.', 'success');
            await refreshApex(this.wiredResult);
        } catch (error) {
            this.showToast('Retry Failed', this.reduceError(error), 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        return error?.body?.message || error?.message || 'Unknown error';
    }
}
