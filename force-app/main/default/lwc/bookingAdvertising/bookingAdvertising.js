/*********************************************************************************************************************************
@ Class:        BookingAdvertising
@ Version:      1.0
@ Author:       Davy Sorn
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 15/05/2025 / Davy Sorn / US-0026115 - 2. Create a new component for Account Management
*********************************************************************************************************************************/
import { LightningElement,api,wire } from 'lwc';
import customLabel from 'c/customLabels';
import doInitData from '@salesforce/apex/AccountManagementController.initDataBookingAdvertising';
export default class BookingAdvertising extends LightningElement {
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