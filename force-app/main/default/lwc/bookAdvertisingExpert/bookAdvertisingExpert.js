/*********************************************************************************************************************************
@ Class:        BookAdvertisingExpert
@ Version:      2.0
@ Author:       Sovantheany Dim
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11/10/2024 / Sovantheany Dim / US-0015390 - ADS - Create an Advertising program component for Bookings
*********************************************************************************************************************************/
import { LightningElement,api,wire } from 'lwc';
import customLabel from 'c/customLabels';
import doInitData from '@salesforce/apex/CalendlyBookingAdsController.initData';
export default class BookAdvertisingExpert extends LightningElement {
    label = customLabel;
    accManagerName;
    accManagerEmail;
    accManagerImage;
    accManagerCalendlyLink;
    currentUser;
    showCalendlyModal = false;
    showAppointmentDetail = false;
    showSpinner = true;
    calendlyLink = '';
    @api sellerId;
    @api cohortSellerId;
    cohortSellerData = [];
    showPageContent = false;

    _wiredoInitData;
    @wire(doInitData,{cohortSellerId : '$cohortSellerId'})
    doInitData(wireResult) {
        const {data, error} = wireResult;
        this._wiredoInitData = wireResult;
        console.log('cohortSellerId::'+this.cohortSellerId);
        if (data) {
            let result = data;
            if(result){
                this.accManagerName = result.accManagerName;
                this.accManagerEmail = result.accManagerEmail;
                this.accManagerImage = result.accManagerImage;
                this.accManagerCalendlyLink = result.accManagerCalendlyLink;
                this.currentUser = result.currentUser;
                this.cohortSellerData = result.cohortSellerData;
                this.showPageContent = true;
            }
            this.showSpinner = false;
        } else if (error){
            console.log("Error while fetching initData:", error);
            this.showSpinner = false;
        }
    }
}