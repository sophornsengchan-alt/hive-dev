/*********************************************************************************************************************************
@ Component:  CustomLookup
@ Purpose  :  Custom  Lookup picker looks similar standard lookup
@ Author   :  Sothea Horn (sohorn@ebay.com)
@ Created  :  19.05.2025 / US-0012817 - Update Linked Customer View
*********************************************************************************************************************************/
import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { getRecord } from "lightning/uiRecordApi";
 
export default class CustomLookup extends NavigationMixin(LightningElement) {
    @api value;
    @api context;
    @api object;
    @api lookupField;
    @api nameField;
    @api editable = false;
    @api filter;
    @api customViewLookupRecord;
    @track showLookup = false;
    //get the sobject record info with fields to show the label of lookup value
    @wire(getRecord, { recordId: '$value', fields: '$nameField' })
    record;
 
    getFieldName() {
        let fieldName = this.nameField[0];
        fieldName = fieldName.substring(fieldName.lastIndexOf('.') + 1, fieldName.length);
        return fieldName;
    }
 
    get lookupLabel() {
        console.log(this.record.data);
        return (this.value != undefined && this.value != '' && this.record.data != null) ?  this.record.data.fields[this.getFieldName()].value : '';
    }
 
    renderedCallback() {
        let container = this.template.querySelector('div.container');
        container?.focus();
        window.addEventListener('click', (evt) => {
           if(container == undefined){
               this.showLookup = false;
           }
        });
        let cellValContainer = this.template.querySelector('button.lookup-value-cell');
        if (!this.value && cellValContainer) {
            cellValContainer.classList.add('lookup-empty-cell');
        }
    }
 
    handleChange(event) {
        //show the selected value on UI
        this.value = event.detail.recordId;
        if(this.value == undefined){
            this.record.data = null;
        }
        let editedData = {Id: this.context};
        editedData[this.lookupField] = this.value;
        //fire event to send context and selected value to the data table
        this.dispatchEvent(new CustomEvent('lookupchange', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: editedData
            }
        }));
    }

    viewLookupRecord(event) {
        if (!this.value) {
            return
        }
        if (this.customViewLookupRecord != null && this.customViewLookupRecord != undefined) {
            this.customViewLookupRecord(this.value);
        } else {
            this.navigateToRecordViewPage()
        }
    }

    navigateToRecordViewPage() {
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: this.value,
                objectApiName: this.object,
                actionName: "view",
            }
        })
    }
 
    handleEditIconClick(event) {
        //wait to close all other lookup edit 
        setTimeout(() => {
            this.showLookup = true;
        }, 100);
    }
}