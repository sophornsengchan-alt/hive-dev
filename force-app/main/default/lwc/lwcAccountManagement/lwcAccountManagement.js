/*********************************************************************************************************************************
@ Class:        LwcAccountManagement
@ Version:      2.0
@ Author:       Trigg, Acmatac Seing
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09.11.2023 / Acmatac Seing / US-0014494 Ph 1 - Account Manager Page - Rework
@                 15.05.2025 / Davy Sorn / US-0012764 - 3. Add Advertising Bookings component to the Seller Portal
*********************************************************************************************************************************/
import { api, LightningElement, wire, track } from 'lwc';
import customLabel from 'c/customLabels';

// START import apex methods
import getSellerInfo from '@salesforce/apex/AccountManagementController.getSellerInfo';
import getAllAccounts from '@salesforce/apex/AccountManagementController.getAllAccounts';
// END import apex methods

import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LwcAccountManagement extends NavigationMixin(LightningElement) {
    label = customLabel;
    @api errors;
    @api metadataName;

    showSpinner = true;
    showPageContent = false;
    mapSellerIdCohortSeller = {}; 
    eligibleFor_BookAM = false; //AMT 14.Nov.23 US-0014258
    eligibleFor_Protrader_Program = false; //AMT 14.Nov.23 US-0014258
    eligibleFor_Booking_Advertising = false; //DS 15.05/2025 US-0012764
    eligibleFor_Booking_AdsPartnerManager = false; //DS 27.05/2025 US-0012764
    eligibleFor_PaidProgram = false; // 07.01.2026 / Sophal Noch / US-0033990

    selectedSeller = '';
    selectedCohortSellerForAM; //For Booking Account Management
    selectedCohortSellerForAds; //For Booking Advertising
    sellerOptions = [];
    // START Get Set
    
    // Acmatac Seing 24.11.2023 / US-0014258
    get sellerIsNotPartOfAnyProgram() {
        return this.sellerOptions.length == 0;
    }

    // START Imperative Method
    handleChange(event) {
        this.showSpinner = true;
        this.selectedSeller = event.detail.value;
    }
    // END Imperative Method

    // START Wire Method
    _wireSellerInfo;
    @wire(getSellerInfo, {
        sellerId: '$selectedSeller'
    })
    // AMT: 20.Nov.2023 Method name cleaning and refactoring
    // StoreSubscription(result) {
    getSellerInfo(result) {
        this._wireSellerInfo = result;
        if (result.data && result.data.status && result.data.status =='ok') {
            // US-0014258 Condition to show the Pro Trader Registration page or Book Account Manager page
            this.eligibleFor_BookAM = result.data.eligibleFor_BookAM;
            this.eligibleFor_Protrader_Program = result.data.eligibleFor_Protrader_Program;
            this.eligibleFor_Booking_Advertising = result.data.eligibleFor_Booking_Advertising; // DS 15.05.2025 US-0012764
            this.eligibleFor_Booking_AdsPartnerManager = result.data.eligibleFor_Booking_AdsPartnerManager // DS 27.05.2025 US-0012764
            this.eligibleFor_PaidProgram = result.data.eligibleFor_PaidProgram; // 07.01.2026 / Sophal Noch / US-0033990
            this.selectedCohortSellerForAM = result.data.selectedCohortSellerForAM;
            this.selectedCohortSellerForAds = result.data.selectedCohortSellerForAds;
            
        } else {
            console.log('Error >>', result.data);
        }
        this.showSpinner = false;

    };

    // Sambath Seng 1.2.2023 US-0011155 - [AM]Add Account Picker to DE Book Account Manager
    _wireGetAllAccounts;
    @wire(getAllAccounts)
    wireGetAccounts(result) {
        if (result.data) {
            // console.log('wireGetAccounts >>', result.data);
            this._wireGetAllAccounts = result;
            var accounts = [];
            accounts = result.data.listEligibleAccount;
            this.mapSellerIdCohortSeller = result.data.mapCohortSeller;
            var sellerData = [];
            for (var index = 0; index < accounts.length; index++) {
                var oneAcc = accounts[index];
                sellerData.push({
                    label: oneAcc.Name,
                    value: oneAcc.Id
                });
            }
            this.sellerOptions = sellerData;
            if (accounts.length == 1) this.selectedSeller = sellerData[0].value;
            this.showPageContent = true;
            this.showSpinner = false;
        } else {
            // console.log('Error >>', result.data.error);
        }
    };
    // END Wire Method

    // UTILS
    showSuccessToast(message,mode){
        this.showToast("Success",message,"success",mode)
    }

    showErrorToast(message,mode){
        this.showToast("Error",message,"error",mode)
    }
    // Mode: dismissible, sticky, pester
    showToast(title,message,variant,mode){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode
            }),
        );
    }
}