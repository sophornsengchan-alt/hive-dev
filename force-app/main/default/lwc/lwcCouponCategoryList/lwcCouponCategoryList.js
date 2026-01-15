/*********************************************************************************************************************************
@ Class:          lwcCouponItemsCoInvests
@ Version:        1.0
@ Author:         mony nou (mony.nou@gaea-sys.com)
@ Purpose:        US-0010437 - Ability to view item list view on coupon record
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.05.2022 / mony nou / Created the class.
*********************************************************************************************************************************/
import { LightningElement, api, track,wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import categoryTitle from '@salesforce/label/c.Item_Based_Title';//LA-30-06-2022-US-0011917

export default class LwcCouponItemsCoInvests extends LightningElement {

    @api recId;
    @api additionalFilter;
    Labels = { categoryTitle };

    connectedCallback() {
        //this.additionalFilter = " AND Coupon__c =\'" + this.couponId +"\'";
    }

    listFields = ['Coupon_Seller__c.Coupon__c'];
    @wire(getRecord, { recordId: '$recId', fields: '$listFields' } )
    getCouponSeller({error, data}){
    if(data){
        var couponId = data.fields["Coupon__c"].value;
        this.additionalFilter = " AND Coupon__c =\'" + couponId +"\'";
    }
   }
}