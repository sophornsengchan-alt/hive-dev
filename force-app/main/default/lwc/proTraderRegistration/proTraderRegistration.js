/*********************************************************************************************************************************
@ Component:    proTraderRegistration
@ Version:      1.0
@ Author:       Acmatac Seing (acmatac.seing@gaea-sys.com) & Anujit Das
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09.11.2023 / Acmatac Seing (acmatac.seing@gaea-sys.com) / US-0014258 Ph 1 - 3 Pro Trader Registration Page - Registration availability and non-availability
@               : 01.04.2024 / Sophal Noch / US-0015018: 3.1 US for PT The Subscription page updates
*********************************************************************************************************************************/
import { LightningElement,track,api,wire } from 'lwc';
import ProTraderRegistrationPageBundle from '@salesforce/resourceUrl/ProTraderRegistrationPage';
import { NavigationMixin } from 'lightning/navigation';
import customLabel from 'c/customLabels';
import doInitData from '@salesforce/apex/ProTraderRegistrationController.initData';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from "@salesforce/schema/BoB_Seller__c.Id";
import STATUS_FIELD from "@salesforce/schema/BoB_Seller__c.Status__c";
import confirmDialog from 'c/confirmDialog';
export default class ProTraderRegistration extends NavigationMixin(LightningElement) {
    /*** 
    US-0014258 - 3 Pro Trader Registration Page - Registration availability and non-availability
    */
    
    // Icons
    protrader_free_of_charge = ProTraderRegistrationPageBundle + '/protrader_free_of_charge.png';
    protrader_calendar = ProTraderRegistrationPageBundle + '/protrader_calendar.png';
    protrader_headset = ProTraderRegistrationPageBundle + '/protrader_headset.png';
    protrader_tag = ProTraderRegistrationPageBundle + '/protrader_tag.png';
    protrader_guidance = ProTraderRegistrationPageBundle + '/protrader_guidance.png';
    // protrade_form_background = ProTraderRegistrationPageBundle + '/protrade_form_background.png';
    // pro_trader_program_logo = ProTraderRegistrationPageBundle + '/pro_trader_program_logo.svg';
    // ebay_for_business_logo = ProTraderRegistrationPageBundle + '/ebay_for_business_logo.svg';

    label = customLabel;
    registrationIsOver = false;
    isCohortSellerActivated_Success = false;
    error;
    @track showConfirmDialog = false;
    showConfirmLabel = true; //TH:US-0016358:put this value to False In case button don't need to display
    
    @track accManagerCalendlyLink;
    @track showPageContent = false;
    @track showSpinner = true;
    @track currentUser;
    // Current Cohort Seller
    @api cohortSeller;

    renderedCallback() {
        // To make the style in customlabel works we need to load like this
    }
    connectedCallback(){
        // console.log('connectedCallback is here>>>', this.cohortSeller);
        // this.initData();
    }
    onConfirmHandler(e){
        this.showConfirmDialog= false;
        if(e.detail.status === 'confirm'){
            this.updateCohortSeller(this.cohortSeller.Id);
        }
    }
    //TH:US-0016668: add to fix bug
    onCancelHandler(e){
        this.showConfirmDialog= false;
    }

    get updatedInvitationLabel(){
        return this.formatLabel(this.label.Pro_trader_recognize_as_eBay_seller, this.cohortSeller.Bob_Cohort_Name__c);
    }

    get isVideoAvailable(){
        return this.label.WelcomeToProTraderProgram != 'NONE';
    }

    get isExclusiveDealAvailable(){ // 01.04.2024 / Sophal Noch / US-0015018
        return this.label.ProTrader_EclusiveDeal != 'NONE';
    }

    _wiredoInitData;
    @wire(doInitData,{cohortSellerId : '$cohortSeller.Id'})
    doInitData(wireResult) {
        const {data, error} = wireResult;
        this._wiredoInitData = wireResult;
        if (data) {
            var result = data;
            if(result){
                // console.log('doInitData>>> ', JSON.parse(JSON.stringify(result)));
                this.accManagerCalendlyLink = result.accManagerCalendlyLink;
                this.registrationIsOver = result.registrationIsOver;
                this.currentUser = result.currentUser;

                this.error = undefined;
                this.showPageContent = true;
                this.showSpinner = false;
            }
            this.showSpinner = false;
        } else if (error){
            console.log("Error while fetching initData:", error);
        }
    };

    updateCohortSeller(strCohortSellerId) {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = strCohortSellerId;
        fields[STATUS_FIELD.fieldApiName] = 'Draft';
        const recordInput = { fields };
        this.isCohortSellerActivated_Success = true;
        if(!this.accManagerCalendlyLink){
            this.showErrorToast(this.label.Bookings_Calendly_Not_Available_Error_Message, 'sticky');
        }
        updateRecord(recordInput)
        .then(() => {
            // showToast(this, "Success", 'The Cohort Seller has been activated successfully!', "success");
            console.log('The Cohort Seller has been activated successfully!');
            // 16.02.2024 / Bora CHHORN / US-0014686
            if(!this.accManagerCalendlyLink){
                this.dispatchEvent(
                    new CustomEvent('refreshprotraderpage'),
                );
            }
            // END / Bora CHHORN / US-0014686
        })
        .catch((error) => {
            this.isCohortSellerActivated_Success = false;
            this.showErrorToast(this.label.ProTrader_Booking_Failed_Message);
        });
    }

    formatLabel(stringToFormat, ...formattingArguments) {
        if (typeof stringToFormat !== 'string') throw new Error('\'stringToFormat\' must be a String');
        return stringToFormat.replace(/{(\d+)}/gm, (match, index) =>
            (formattingArguments[index] === undefined ? '' : `${formattingArguments[index]}`));     
    }

    handleCalendlyClick(event){
        this.showConfirmDialog = true;
        //this.updateCohortSeller(this.cohortSeller.Id);
    }

    handleCalendlyEventScheduled(event){
        //when the calendly event is scheduled, we need to close the modal
        setTimeout(() => {
            this.handleCalendlyModalClose()
        }, "2000");
    }

    handleCalendlyModalClose(){
        this.showPageContent = false;
        this.isCohortSellerActivated_Success = false;
        this.dispatchEvent(
            new CustomEvent('refreshprotraderpage'),
        );
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