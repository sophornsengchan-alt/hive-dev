import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

// Define only the specific fields needed for the flow
const CONTACT_FIELDS = [
    'Contact.Id',
    'Contact.Name',
    'Contact.Email',
    'Contact.Phone',
    'Contact.MobilePhone',
    'Contact.Contact_Record_Type__c',
    'Contact.AccountId'];

export default class CallScriptGenesysWrapper extends LightningElement {
    @api taskId;
    @api contactId;
    
    flowInputVariables = [];
    flowApiName = 'Initiate_Call_SubFlow';
    currentTaskId;
    currentContactId;
    contactRecord;
    contactError;
    isContactLoading = false;
    
    // Wire service to get contact record when contactId changes
    @wire(getRecord, { recordId: '$currentContactId', fields: CONTACT_FIELDS })
    wiredContact({ error, data }) {
        if (data) {
            this.contactRecord = data;
            this.contactError = undefined;
            this.isContactLoading = false;
            // console.log('Contact record loaded:', this.contactRecord);
            this.setFlowInputVariables();
        } else if (error) {
            this.contactError = error;
            this.contactRecord = undefined;
            this.isContactLoading = false;
            console.error('Error loading contact:', error);
        }
    }
    
    get hasRequiredParams() {
        // At minimum we need a contactId and the contact record should be loaded
        return this.currentContactId && this.currentContactId !== '' && this.contactRecord && !this.isContactLoading;
    }
    
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            // console.log('CurrentPageReference state:', currentPageReference.state);
            
            // Get parameters from URL (c__ prefix is used for LWC URL parameters)
            this.currentTaskId = currentPageReference.state?.c__taskId || 
                               currentPageReference.state?.taskId || 
                               this.taskId;
            
            const urlContactId = currentPageReference.state?.c__contactId || 
                               currentPageReference.state?.contactId || 
                               this.contactId;
            
            // Only update contactId if it's different to avoid unnecessary wire calls
            if (urlContactId && urlContactId !== this.currentContactId) {
                this.currentContactId = urlContactId;
                this.isContactLoading = true;
            }
            
            // console.log('Updated parameters - taskId:', this.currentTaskId, 'contactId:', this.currentContactId);
        }
    }
    
    connectedCallback() {
        // Set values and trigger contact record loading
        this.currentTaskId = this.taskId || '';
        
        if (this.contactId && this.contactId !== this.currentContactId) {
            this.currentContactId = this.contactId;
            this.isContactLoading = true;
        } else if (!this.currentContactId) {
            // Use default if no contactId provided
            // this.currentContactId = '003VE00000qNyqgYAC';
            this.isContactLoading = true;
        }
        
        // console.log('CallScriptGenesysWrapper connectedCallback - taskId:', this.taskId, 'contactId:', this.contactId);
        // console.log('CallScriptGenesysWrapper using values - currentTaskId:', this.currentTaskId, 'currentContactId:', this.currentContactId);
    }
    
    setFlowInputVariables() {
        // console.log('Setting flow variables - currentTaskId:', this.currentTaskId, 'currentContactId:', this.currentContactId, 'contactRecord:', this.contactRecord);
        
        // Only set flow variables if we have the contact record loaded
        if (!this.contactRecord) {
            // console.log('Contact record not loaded yet, skipping flow variable setup');
            return;
        }
        
        // Transform the contact record to the format expected by the flow
        const transformedContact = {
            Id: this.contactRecord.fields.Id.value,
            Name: this.contactRecord.fields.Name.value,
            Email: this.contactRecord.fields.Email.value,
            Phone: this.contactRecord.fields.Phone.value,
            MobilePhone: this.contactRecord.fields.MobilePhone.value,
            Contact_Record_Type__c: this.contactRecord.fields.Contact_Record_Type__c.value || '',
            AccountId: this.contactRecord.fields.AccountId.value
        };
        
        // console.log('Transformed contact for flow:', transformedContact);
        
        // Create a collection (array) with the transformed contact record for ListContact
        const contactCollection = [transformedContact];
        
        // Prepare flow input variables
        this.flowInputVariables = [
            {
                //name: 'taskId',
                name: 'varRecordId',
                type: 'String',
                value: this.currentTaskId || ''
            },
            {
                name: 'ListContact',
                type: 'SObject',
                value: contactCollection
            } 
        ];
        
        // console.log('Flow input variables with ListContact:', this.flowInputVariables);
    }
    
    handleFlowFinish(event) {
        // Handle flow completion
        // console.log('Flow finished with status:', event.detail.status);
        
        // You can add custom logic here when the flow finishes
        // For example: navigation, refresh, close modal, etc.
        if(event.detail.status === "FINISHED")
        {
            const eventResult = { flowname: 'callScriptGenesysWrapper', flowevent: 'finished' };
            const changeEvent = new CustomEvent("wrapperflowfinished", {
                detail: { eventResult },
            });
            // Fire the custom event
            this.dispatchEvent(changeEvent);
        }
    }
}