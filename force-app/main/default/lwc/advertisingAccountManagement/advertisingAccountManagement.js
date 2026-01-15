/*********************************************************************************************************************************
@ Class:        CalendlyBooking
@ Version:      2.0
@ Author:       Sovantheany Dim
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11/10/2024 / Sovantheany Dim / US-0015390 - ADS - Create an Advertising program component for Bookings
*********************************************************************************************************************************/

import { LightningElement , wire} from 'lwc';
import customLabel from 'c/customLabels';

import getAllAccounts from '@salesforce/apex/CalendlyBookingAdsController.getAllAccountIdsRelated';

export default class CalendlyBooking extends LightningElement {
    label = customLabel;

    showSpinner = true;
    showPageContent = false;
    selectedSeller = '';
    sellerOptions = [];
    eligibleAccIds = [];
    mapEligibleCohortSellers = {};

    get sellerIsNotPartOfAnyProgram() {
        return this.sellerOptions.length === 0;
    }    
    
    get selectedSellerIsEligible() {
        if(this.eligibleAccIds.includes(this.selectedSeller)){
            return true;
        }
        return false;
    } 

    get currentCohortSellerId(){
        return this.selectedSeller && Object.hasOwn(this.mapEligibleCohortSellers, this.selectedSeller) ? this.mapEligibleCohortSellers[this.selectedSeller].Id : null;
    };

    @wire(getAllAccounts)
    wireGetAccounts(result) {
        if (result.data) {
                let mapEligible = result.data.mapResultEligibleCohortSeller;
                this.mapEligibleCohortSellers = mapEligible;
                for (let key in mapEligible) {
                    this.eligibleAccIds.push(key);
                }
            let accounts = [];
            accounts = result.data.listRelatedAccounts;
            let sellerData = [];
            for (let index = 0; index < accounts.length; index++) {
                let oneAcc = accounts[index];
                sellerData.push({
                    label: oneAcc.Name,
                    value: oneAcc.Id
                });
            }
            this.sellerOptions = sellerData;
            if (accounts.length === 1) this.selectedSeller = sellerData[0].value;
            this.showPageContent = true;
            this.showSpinner = false;
        } else {
            console.log('Error : ', result);
            this.showSpinner = false;
        }
    }

    handleChange(event) {
        this.showSpinner = true;
        this.selectedSeller = event.detail.value;
        if (this.selectedSeller) {
            this.showSpinner = false;
        }
    }
}