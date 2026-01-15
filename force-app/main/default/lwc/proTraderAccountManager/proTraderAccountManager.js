/*********************************************************************************************************************************
@ Component:    ProTraderAccountManager
----------------------------------------------------------------------------------------------------------------------------------
created by Anujit to show account manager details. 11/01/2024
@ Change history: 18.01.2024/ Acmatac Seing / US-0014602 Design - Seller Registration and Confirmation Pages
*********************************************************************************************************************************/

import { LightningElement,api,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import customLabel from 'c/customLabels';
import doInitData from '@salesforce/apex/ProTraderRegistrationController.initData';
//import communityPath from '@salesforce/community/basePath';
import getCommunityBasePath from '@salesforce/apex/ProTraderSellerDashboardController.getCommunityBasePath';


export default class ProTraderAccountManager extends NavigationMixin(LightningElement) {
    @api cohortSellerData;
    @api registrationPage;
    @api cohortSellerId;

    accManagerCalendlyLink;
    accManagerName;
    accManagerEmail;
    accManagerImage;
    currentUser;
    isEligibleFor_CatDashboard;
    error;

    label = customLabel;
    communityBasePath = '';


    connectedCallback(){
        this.getCommunityBasePath();

    }

    getCommunityBasePath(){
        getCommunityBasePath().then(result => {
            this.communityBasePath = result;
        }).catch(error => { 
                console.log("Error while fetching community base url", error);
            }); 
    }

    _wiredoInitData;
    @wire(doInitData,{cohortSellerId : '$cohortSellerId', registrationPage : '$registrationPage'})
    doInitData(wireResult) {
        const {data, error} = wireResult;
        this._wiredoInitData = wireResult;
        if (data) {
            var result = data;
            if(result){
                // console.log('doInitData ::: ', result);
                this.accManagerCalendlyLink = result.accManagerCalendlyLink;
                this.accManagerName = result.accManagerName;
                this.accManagerEmail = result.accManagerEmail;
                this.accManagerImage = result.accManagerImage;
                this.currentUser = result.currentUser;
                this.isEligibleFor_CatDashboard = result.isEligibleFor_CatDashboard;
                this.error = undefined;
            }
            //this.showSpinner = false;
        } else if (error){
            console.log("Error while fetching initData:", error);
        }
    };

    handleShowDashboardClick(){
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: `${this.communityBasePath}`+'protrader-seller-dashboard?c__cohSelId='+this.cohortSellerId
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }
}