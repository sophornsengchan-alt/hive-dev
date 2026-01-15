//import { LightningElement, api } from 'lwc';
import { LightningElement, api, track, wire} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getTodayDealSetting from '@salesforce/apex/CustomDealController.getTodayDealSetting';
import checkCurrentUserEligible from '@salesforce/apex/CustomDealController.checkCurrentUserEligible';//TH:04.04.2025:US-0016623 - Enable Link Multiple Account for NA
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LwcErrorLimitSingleDealHomePage from '@salesforce/label/c.lwcErrorLimitSingleDealHomePage';
import LwcMaxDEDealLimitPerDay from '@salesforce/label/c.LwcMaxDEDealLimitPerDay';
// SB 31-3-2022 US-0011579 - Read Only Access to Deals 
import lwcErrorDealReadonly from '@salesforce/label/c.lwcErrorDealReadonly';
//import {getFieldValue, getRecord} from 'lightning/uiRecordApi';//TH:04.04.2025:US-0016623 : comment out
import userId from '@salesforce/user/Id';
//import SP_DEALS_FIELD from '@salesforce/schema/User.Contact.Account.SP_Deals__c';
// import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name'; // SB 21-4-2022 US-0011686 - SP Deals field values behavior - NA Seller Portal////TH:04.04.2025:US-0016623 : comment out

//TH:04.04.2025:US-0016623 : comment out
//CSP:18/02/2025:US-0016413 - Seller Portal - Deals tab
//import NA_Deal_Program_Vetted_FIELD from '@salesforce/schema/User.Contact.Account.NA_Deal_Program_Vetted__c';
//import Seller_Portal_Beta_User_FIELD from '@salesforce/schema/User.Contact.Account.Seller_Portal_Beta_User__c';
import customLabels from 'c/customLabels';

export default class LwcDealsSelectOptions extends NavigationMixin(LightningElement) {

    @api headerTitle0; //Sophal 08-04-2022 US-0011443
    @api labelDownload0; //Sophal 08-04-2022 US-0011443

    @api headerTitle1;
    @api headerTitle2;
    @api headerTitle3;

    @api bodyText1;
    @api bodyText2;
    @api bodyText3;

    @api url1;
    @api url2;
    @api url3;

    @api labelDownload1;
    @api labelDownload2;
    @api labelDownload3;

    @api enableTile1;
    @api enableTile2;
    @api enableTile3;
   
    //CSP:18/02/2025:US-0016413 - Seller Portal - Deals tab
    labels = customLabels;

    //SB 31-3-2022 US-0011579 - Read Only Access to Deals 
    @track spDealsValue;
    label = {LwcErrorLimitSingleDealHomePage,LwcMaxDEDealLimitPerDay,lwcErrorDealReadonly};
    //fields = [SP_DEALS_FIELD,Seller_Portal_Beta_User_FIELD,NA_Deal_Program_Vetted_FIELD];//TH:04.04.2025:US-0016623 : comment out

    @track naDealProgram;
    @track sellerPortalBetaUser;
    
    isUserEligibleForSubsidized = false;//TH:04.04.2025:US-0016623 : Check is NA user is eligible for subsidized deal

    //TH:04.04.2025:US-0016623
    connectedCallback()
    {
        this.init();
    }

    init()
        {
            checkCurrentUserEligible({mdtName:'DealSelectedOptionSubEligible',userID:userId}).then(result => {
            this.isUserEligibleForSubsidized = result;
        }).catch(error => {
            console.log('error',error);
        });

    }

    // SB 31-3-2022 US-0011579 - Read Only Access to Deals 
    //TH:04.04.2025:US-0016623 : comment Out
    // @wire(getRecord, {recordId: userId, fields: '$fields'})
    // getUser({error, data}){
    //     if(data){
    //         this.spDealsValue = getFieldValue(data, SP_DEALS_FIELD); 

    //         //CSP:18/02/2025:US-0016413 - Seller Portal - Deals tab               
    //         this.sellerPortalBetaUser = getFieldValue(data, Seller_Portal_Beta_User_FIELD);
    //         this.naDealProgram = getFieldValue(data, NA_Deal_Program_Vetted_FIELD);       
    //     }
    // }

    //CSP:18/02/2025:US-0016413 - Seller Portal - Deals tab
    get isEligibleSubsidizedAndUnsubsidized() {
        //TH:04.04.2025:US-0016623 : comment out
        //return this.sellerPortalBetaUser && this.naDealProgram && this.spDealsValue=='Full Access' && !this.isMultipleOptions && this.enableTile1;
        return this.isUserEligibleForSubsidized && !this.isMultipleOptions && this.enableTile1;//TH:04.04.2025:US-0016623
    }

    get isMultipleOptions(){
        //Sophal 12-04-2022 US-0011443
        let optionCount = 0;
        if(this.enableTile1) optionCount++;
        if(this.enableTile2) optionCount++;
        if(this.enableTile3) optionCount++;
        return optionCount > 1 ? true : false;

    }

    //CSP:18/02/2025:US-0016413 - Seller Portal - Deals tab
    handleBtnSubsidizedDeals() {
        this.navigateTo(this.labels.UrlSubsidizedDCA);
    }

    handleBtn1() {
        this.validateSPDeals(this.url1);//SB 4-4-2022 US-0011579
    }

    handleBtn2() {

        this.validateLimitDeals();//LA-29-11-2021-US-0010733
        
    }

    handleBtn3() {
        this.navigateTo(this.url3);
    }

    navigateTo(customURL) {

         // redirect to create deal page
         this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: customURL
            }
        });
    }
    validateLimitDeals(){//LA-29-11-2021-US-0010733
        getTodayDealSetting({dealReatilCampaingId : null})
        .then(result => {
            var msg = "";
            var currUserLang ='';
            var isEU = false; //MN-05062024-US-0015298
            if(result["status"] == "success"){
                var availableDeal = result["availableDeal"];
                var totalDealOfDEToday = (result["totalDealOfDEToday"] != undefined ? result["totalDealOfDEToday"] : 0);
                if(result["currUserLang"]) currUserLang = result["currUserLang"];
                if(result["isEU"]) isEU = result["isEU"]; //MN-05062024-US-0015298
                var availableDealToday = parseInt(this.label.LwcMaxDEDealLimitPerDay) - totalDealOfDEToday;

                if((isEU && availableDealToday <= 0) || (!isEU && availableDeal <= 0)) { //MN-05062024-US-0015298: Check SP Main Domain instead of Profile Name
                    msg = this.label.LwcErrorLimitSingleDealHomePage;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: '',
                            message: msg,
                            variant: 'error',
                        }),
                    );
                }else{
                    this.navigateTo(this.url2);
                }
            }else {
                msg = result["message"];
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'INFO',
                        message: msg,
                        variant: 'error',
                    }),
                );
            }
           
        })
        .catch(error => { 
            console.log("first load ERROR:", error);
        });  
        
    }

    // SB 1-4-2022 US-0011579 - Read Only Access to Deals 
    validateSPDeals(redirectUrl) {

        this.navigateTo(redirectUrl);
    }

    closeMessageHandle() {
        var errorElement = this.template.querySelector('.errorMessage');
        errorElement.style = 'display:none';
    }

}