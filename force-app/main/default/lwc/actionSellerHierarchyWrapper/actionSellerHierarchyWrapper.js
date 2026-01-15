/*********************************************************************************************************************************
 * Component:       actionSellerHierarchyWrapper
 * Version:         1.0
 * Author:          Sophal Noch
 * Purpose:         US-0033903 - Parent Child seller overview component
 * Used In :        flexipage Change Request Record Page
 * -------------------------------------------------------------------------------------------------------------------------------
 * Change history: 25.11.2025 / Sophal Noch / Created the class.
 *********************************************************************************************************************************/
import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import SELLER_FIELD from '@salesforce/schema/Action__c.Managed_Seller__c';
export default class ActionSellerHierarchyWrapper extends LightningElement {
    
    @api recordId;
    @api title;
    @wire(getRecord, { recordId: '$recordId', fields: [SELLER_FIELD] })
    action;

    get sellerId() {
        return this.action.data ? this.action.data.fields?.Managed_Seller__c?.value : '';
    }

    get isReady(){
        return this.sellerId ? true : false;
    }
}