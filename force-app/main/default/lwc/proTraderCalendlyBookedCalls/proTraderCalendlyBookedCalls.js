/**
 * ...
 * : 14.02.2025/ vadhanak voun/ US-0016605 - Calendly reporting wrong day of week
 */
import { LightningElement,api,track ,wire} from 'lwc';
import getCalendlyEvents from '@salesforce/apex/ProTraderSellerDashboardController.getEvents';
import { isNullorUndefinedorZero,removeString,replaceString} from "c/hiveUtils";
import customLabel from 'c/customLabels';
import LOCALE from '@salesforce/i18n/locale';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LANGUAGE from '@salesforce/i18n/lang';

export default class ProTraderCalendlyBookedCalls extends LightningElement {
    @track userEventDetails = [];
    
    noEventDataAvailable = false;
    label = customLabel;
    showCalendlyModal = false;
    calendlyLink = '';
    locale = LOCALE;
    language = LANGUAGE;

    @api accountManagerCalendlyLink = '';
    @api currentUser;
    @api cohortSellerDetails;
    @api cohortSellerId;
    @api utmCampaign = 'seller_portal_protrader';

    calendlyCallsReschduleBackgroundStyle = 'box-border-C5E5FB mb-4';
    calendlyCallsCancelBackgroundStyle = 'box-border-3665F3 mb-4';

    // TH:US-0015390: Move getCalendlyEvents to wire method
    @wire(getCalendlyEvents,{cohortSellerId : '$cohortSellerId'})
    getCalendlyEvents(wireResult) {
        const {data, error} = wireResult;
        this.userEventDetails = [];
        if (data) {
            var result = data;
            if(isNullorUndefinedorZero(result.events) || result.events.length == 0){
                this.noEventDataAvailable = true;
                return;
            }
            if(!isNullorUndefinedorZero(result.events)){

                let allCancelledEvents = result?.events?.filter(eachEvent => {
                    return (
                        eachEvent.isCancelled__c == false
                    )
                });
                if(allCancelledEvents.length == 0){ //if all events are cancelled, then show book a call button
                    this.noEventDataAvailable = true;
                    return;
                }
                //console.log("result", result);
                this.error = undefined;
                this.noEventDataAvailable = false;               
                result?.events?.forEach(eachEvent =>{
                    let calendlyEventObj;
                    calendlyEventObj = {Id: eachEvent.Id,userName:eachEvent.Owner.Name,
                                            Subject: eachEvent.isCancelled__c == true ? this.replaceSpecificString(removeString(eachEvent.Subject,'with'),'Canceled','') : eachEvent.Subject,
                                             //NK:14/02/2035:US-0016605: formatedStartDateTime --> formatedStartDateTime2
                                            //eventStartTime:this.getProperDateTime(result['formatedStartDateTime2'+eachEvent.Id], eachEvent.StartDateTime),
                                            eventStartTime:result['formatedStartDateTime2'+eachEvent.Id],
                                            rescheduleLink:this.label.Bookings_Calendly_Reschedule_URL+eachEvent.Calendly__InviteeUuid__c,
                                            cancelLink:this.label.Bookings_Calendly_Cancellation_URL+eachEvent.Calendly__InviteeUuid__c,
                                            showRescheduleCancelButton : eachEvent.isCancelled__c == false,
                                            calendlyCallsBackgroundStyle : eachEvent.isCancelled__c == true ? this.calendlyCallsCancelBackgroundStyle : this.calendlyCallsReschduleBackgroundStyle };
        
                    this.userEventDetails.push(calendlyEventObj);
                    
                }) 
                this.userEventDetails.sort((b, a) => a.showRescheduleCancelButton - b.showRescheduleCancelButton);
            }
            
        } else if (error){
            console.log("Error Test:", error);
        }
    }
  

    /**
     * 
     * @param {*} eventStartDateTime 
     * @param {*} unformatedDateTime
     * description - returns the proper date time format
     */
    //NK:14/02/2035:US-0016605: deprecated
    // getProperDateTime(eventStartDateTime,unformatedDateTime){ 
    //     const dateStr = unformatedDateTime.substring(0, 10); 
    //     const dayName = this.getDayName(dateStr, this.locale);
    //     return dayName+' '+eventStartDateTime;
    // }

    /**
     * 
     * @param {*} dateStr 
     * @param {*} locale 
     * description - returns the day name
     */
    //NK:14/02/2035:US-0016605: deprecated
    // getDayName(dateStr, locale){
    //     let date = new Date(dateStr);
    //     return date.toLocaleDateString(locale, { weekday: 'short' });        
    // }

    /**
     * 
     * @param {*} event 
     * description - handles the reschedule click
     */
    handleRescheduleClick(event){
        console.log('handleRescheduleClick::'+event.target.dataset.id)
        this.showCalendlyModal = true;
        this.calendlyLink = event.target.dataset.id;
        console.log('this.calendlyLink::'+this.calendlyLink)
    }
    /**
     * 
     * @param {*} event 
     * description - handles the cancel click
     */
    handleCancelClick(event){
        console.log('handlecencelClick::'+event.target.dataset.id)
        this.showCalendlyModal = true;
        this.calendlyLink = event.target.dataset.id;
        console.log('this.calendlyLink::'+this.calendlyLink)
    }

    /**
     * 
     * @param {*} event 
     * description - handles the modal close
     */
    handleCalendlyModalClose(){
        this.showCalendlyModal = false;
        this.calendlyLink = '';
        window.location.reload();
    }

    /**
     * 
     * @param {*} event 
     * description - handles the book first call
     */
    @api
    handleBookFirstCall(){
        this.showCalendlyModal = true;
        // 16.02.2024 / Bora CHHORN / US-0014686
        if(this.accountManagerCalendlyLink){ // 18.06.2025 / Sophal Noch / US-0032929 : replace "!== undefined" check with a check for only true value that is not empty, null, or undefined
            this.calendlyLink = this.accountManagerCalendlyLink; 
        } else {
            this.showCalendlyModal = false;
            this.showErrorToast(this.label.Bookings_Calendly_Not_Available_Error_Message,'sticky');
        }
        // ENDUS-0014686
    }

    /**
     * 
     * @param {*} event 
     * description - handles the calendly event scdeuled click
     */
    handleCalendlyEventScheduled(event){
        //when the calendly event is scheduled, we need to close the modal
        setTimeout(() => {
            this.handleCalendlyModalClose()
          }, "1000");
        
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

    /**
     * 
     * @param {*} textVal 
     * @param {*} toReplace 
     * @param {*} replaceWith 
     * @returns 
     * description - replaces the specific string
     */
    replaceSpecificString(textVal,toReplace,replaceWith){
        if(textVal.includes('Canceled')){
             let updatedTextVal = this.label.Cancelled_Status + textVal.replace(toReplace,replaceWith);
             return updatedTextVal;       
        }else{
             return textVal;
        }
    }
}