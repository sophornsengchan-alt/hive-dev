/*********************************************************************************************************************************
@ Component:    ProTraderProgram
@ Version:      1.0
@ Author:       Acmatac Seing
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 18.01.2023 / Acmatac Seing US-0014494 Ph 1 - Account Manager Page - Rework
*********************************************************************************************************************************/

import { LightningElement,api,wire } from 'lwc';
import customLabel from 'c/customLabels';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { showToast } from 'c/hiveUtils';
import { NavigationMixin } from 'lightning/navigation';
import communityPath from '@salesforce/community/basePath';
import {refreshApex} from '@salesforce/apex';
// START import apex methods
import getProTraderProgramEligibility from '@salesforce/apex/ProTraderRegistrationController.getProTraderProgramEligibility';
// END import apex methods

export default class ProTraderProgram extends NavigationMixin(LightningElement) {

    label = customLabel;
    @api error;
    @api selectedSeller;

    showSpinner = true;
    showPageContent = false;
    isEligibleFor_RegistrationCat = false;
    isEligibleFor_CatDashboard = false;
    cohortSeller;

    connectedCallback(){
    }

    renderedCallback() {
    }

    _wireGetProTraderProgramEligibility;
    @wire(getProTraderProgramEligibility,{sellerId : '$selectedSeller'})
    getProTraderProgramEligibility(wireResult) {
        const { data, error } = wireResult;
        this._wireGetProTraderProgramEligibility = wireResult;
        if (data) {
            var result = data;
            // console.log('getProTraderProgramEligibility>>> ', JSON.parse(JSON.stringify(result)));
            if (result && result.status && result.status =='ok') {
                // console.log("ProtraderProgram GetSelectedSellerInfo >>", result);
                this.showPageContent = result.isEligibleFor_Protrader_Program;
                this.isEligibleFor_RegistrationCat = result.isEligibleFor_RegistrationCat;
                this.isEligibleFor_CatDashboard = result.isEligibleFor_CatDashboard;
                this.cohortSeller = result.cohortSeller;
                // console.log('Call inside >>>', this.template.querySelector('c-pro-trader-registration').initresult());
                this.error = undefined;
                this.showPageContent = true;
                this.showSpinner = false;
            } else  if (result && result.error) {
                this.error = result.error;
                // console.log("Error while doGetProTraderProgramEligibility:", result);
                showToast(this, "Error", this.error, "error");
            }
            this.showSpinner = false;
            // console.log("Error while fetching getProTraderProgramEligibility:", error);
        }else if (error) {
                console.log("Error while fetching getProTraderProgramEligibility:", error);
        }
    };

    doGetProTraderProgramEligibility_callFromChild(){
        refreshApex(this._wireGetProTraderProgramEligibility);
    }

    get isCohortActivated() {
        return this.cohortSeller && this.cohortSeller.Status__c === 'Draft';
    }

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