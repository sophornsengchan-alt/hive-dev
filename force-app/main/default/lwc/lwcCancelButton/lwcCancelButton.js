import { LightningElement, api, wire, track} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import BackButton from '@salesforce/label/c.BackButton';//Loumang:12-01-2022:US-0010747
// SB 25-2-2022 US-0011351 - Deal creation button on the DRC view page
import {getFieldValue, getRecord} from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import DRC_ACCEPT_START from '@salesforce/schema/EBH_DealRetailCampaign__c.EBH_AcceptProposalsStart__c';
import DRC_ACCEPT_END from '@salesforce/schema/EBH_DealRetailCampaign__c.EBH_AcceptProposalsEnd__c';
import DRC_STATUS from '@salesforce/schema/EBH_DealRetailCampaign__c.Status__c';// SRONG 21.07.2023 US-0013839
//import DRC_OPEN_SEAT_AVAILABLE from '@salesforce/schema/EBH_DealRetailCampaign__c.EBH_OpenSeatsAvailable__c';*/
import DRC_OPEN_SEAT_AVAILABLE from '@salesforce/schema/EBH_DealRetailCampaign__c.Open_Slots_Available_w__c';//TH:US-0011519 - Deal Retail Campaign Updates : AC4 :04/04/2021
import submitSingleDeal from '@salesforce/label/c.lwcCancelButton_submitSingleDeal';
import bulkUploadDeals from '@salesforce/label/c.lwcCancelButton_bulkUploadDeals';
import notAvailableForSubmissionmessage from '@salesforce/label/c.lwc_Not_Available_For_Submission_message';//TH:US-0011519:04/04/2022
// SB 25-2-2022 US-0011351 - Deal creation button on the DRC view page
import getPortalDomain from "@salesforce/apex/SEP_Helper.getPortalDomain";// SB 27.04.2023 US-0013312


//Loumang:12-01-2022:US-0010747: new component for Back Button
export default class LwcCancelButton extends NavigationMixin(LightningElement) {
    labels = {BackButton, submitSingleDeal, bulkUploadDeals,notAvailableForSubmissionmessage}// SB 25-2-2022 US-0011351 - Deal creation button on the DRC view page
    // SB 25-2-2022 US-0011351 - Deal creation button on the DRC view page
    @api recordId;
    @track profileName = '';
    @api buttonAvailable;
    @api isShowMessage;
    @track isValidDRC = false;
    @track isNotAvailableForSubmission = false;
    // SRONG 21.07.2023 US-0013839
    drcFields = [DRC_ACCEPT_START, DRC_ACCEPT_END, DRC_OPEN_SEAT_AVAILABLE,DRC_STATUS];
    
    @track isITDomain = false;
    @track isNADomain = false;
    @track isAUDomain = false;
    @track isEUDomain = false; //MN-05062024-US-0015298

    buttonAvailableForIT_AU_NA = false;
    DRC_STATUS_OPEN_FOR_SUBMISSIONS = 'Open for Submissions';
    drcCurrentStatus = '';
    //Loumang:12-01-2022:US-0010747: new component for Back Button
    onPrevPage() {
        var prev = window.history.back();
    }

    // SB 27.04.2023 US-0013312
    // SRONG 21.07.2023 US-0013839
    @wire(getPortalDomain)
    getPortalDomain(result) {     
        if(result.data) {  
            this.isITDomain = result.data.isIT;
            this.isNADomain = result.data.isNA;
            this.isAUDomain = result.data.isAU;
            //console.log('**** data :: ', this.isITDomain);
            // SRONG 21.07.2023 US-0013839
            this.buttonAvailableForIT_AU_NA = (this.drcCurrentStatus == this.DRC_STATUS_OPEN_FOR_SUBMISSIONS && (this.isITDomain || this.isNADomain || this.isAUDomain));

            this.isEUDomain = result.data.isEU; //MN-05062024-US-0015298

        } else if (result.error) {
            console.log('ERROR :: ', result.error);
        }
    
    };
    
    //Start SB 25-2-2022 US-0011351 - Deal creation button on the DRC view page  
    @wire(getRecord, {recordId: userId, fields: [PROFILE_NAME_FIELD]})
    getUser({error, data}){
        if(data){
            this.profileName = getFieldValue(data, PROFILE_NAME_FIELD);
        }
    }

    @wire(getRecord, {recordId: '$recordId', fields: '$drcFields'})
    getDRC({error, data}){
        if(data){
            var today = new Date().toISOString().slice(0, 10);
            var acceptStart = new Date(getFieldValue(data, DRC_ACCEPT_START)).toISOString().slice(0, 10);
            var acceptEnd = new Date(getFieldValue(data, DRC_ACCEPT_END)).toISOString().slice(0, 10);
            var openSeatAvailable = getFieldValue(data, DRC_OPEN_SEAT_AVAILABLE);
            if(today >= acceptStart && today <= acceptEnd && openSeatAvailable > 0){
                this.isValidDRC = true;
            }else{
                this.isNotAvailableForSubmission = true;
            }
            // SRONG 21.07.2023 US-0013839
            this.drcCurrentStatus = data.fields.Status__c.value;
            this.buttonAvailableForIT_AU_NA = (this.drcCurrentStatus == this.DRC_STATUS_OPEN_FOR_SUBMISSIONS && (this.isITDomain || this.isNADomain || this.isAUDomain));
        }
    }
    //End US-0011519
    get buttonAvailable(){

        /* MN-05062024-US-0015298
        if(this.profileName == 'DE - Seller Portal' && this.isValidDRC){
            return true;
        }
        */

        return (this.isEUDomain && this.isValidDRC); //MN-05062024-US-0015298: Use SP Main Domain instead of Profile Name
    }
    //TH:US-0011519:07/04/2022
    // SB 27.04.2023 US-0013312
    get isShowMessage(){

        /* MN-05062024-US-0015298
        if(this.profileName == 'DE - Seller Portal' && this.isNotAvailableForSubmission && !this.isITDomain){
            return true;
        }
        */

        return (this.isEUDomain && this.isNotAvailableForSubmission && !this.isITDomain); //MN-05062024-US-0015298: Use SP Main Domain instead of Profile Name
    }

    singleDealClickHandler(){
        const config = {
            type: 'standard__webPage',
            attributes: {
                url: '/create-single-deal?drc='+this.recordId
            }
        };
        this[NavigationMixin.Navigate](config);
    }

    bulkUploadClickHandler(){
        const config = {
            type: 'standard__webPage',
            attributes: {
                url: '/bulk-upload-deals?recordId='+this.recordId
            }
        };
        this[NavigationMixin.Navigate](config);
    }
    //End SB 25-2-2022 US-0011351 - Deal creation button on the DRC view page
}