// Sambath Seng 15-3-2022 US-0011050 - [SP] Adjust the Generic Error Message
import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import doHelpTextMetadata from '@salesforce/apex/dynamicHelpTextController.helpTextMetadata';
import GenericErrorBackground from '@salesforce/resourceUrl/GenericErrorBackground';
import homeButton from '@salesforce/label/c.lwcGenericErrorMessage_Homebutton';
import getHelpButton from '@salesforce/label/c.GetHelpButton';//TH:06/04/2022:US-0011487
import getHelpUrl from '@salesforce/label/c.Get_Help_URL';//TH:06/04/2022:US-0011487
import SEP_Domain_DE from '@salesforce/label/c.SEP_Domain_DE'; //MN-10062024-US-0015298
import SEP_Domain_FR from '@salesforce/label/c.SEP_Domain_FR'; //MN-10062024-US-0015298
import SEP_Domain_IT from '@salesforce/label/c.SEP_Domain_IT'; //MN-10062024-US-0015298
import SEP_Domain_UK from '@salesforce/label/c.SEP_Domain_UK'; //MN-10062024-US-0015298
import SEP_Domain_NA from '@salesforce/label/c.SEP_Domain_NA'; //MN-10062024-US-0015298

// SB 1-4-2022
import {getFieldValue, getRecord} from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import SP_DEALS_FIELD from '@salesforce/schema/User.Contact.Account.SP_Deals__c';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import SPMAINDOMAIN_FIELD from '@salesforce/schema/User.SPMainDomain__c';

export default class LwcGenericErrorMessage extends NavigationMixin(LightningElement) {
    label = {
        homeButton,
        getHelpButton,
        getHelpUrl,
        SEP_Domain_DE, //MN-10062024-US-0015298
        SEP_Domain_FR, //MN-10062024-US-0015298
        SEP_Domain_IT, //MN-10062024-US-0015298
        SEP_Domain_UK, //MN-10062024-US-0015298
        SEP_Domain_NA //MN-10062024-US-0015298
    };
    backgroundURL = GenericErrorBackground;
    @api customError;
    @api titleName;
    @api baseUrl;
    @api adminEmailAddress;
    @api titleValue;
    @api customLabel;
    @api labelHomeButton;

    @api metadataName;
    @track helpTextMetadata;
    // SB 1-4-2022 US-0011579 - Read Only Access to Deals 
    @api metadataNameReadOnly;
    @track errorMetadataName;
    @track profileName = '';
    @track spDealValue;
    @track spMainDomain; //MN-10062024-US-0015298
    @api isDealReadOnly = false; //Sophal 02-04-2022 US-0011156 - Restrict ability for Sellers to be able to create Deals - Linked Account
    fields = [PROFILE_NAME_FIELD, SP_DEALS_FIELD, SPMAINDOMAIN_FIELD]; //MN10062024-US-0015298: Add SPMainDomain__c field
    dealUrls = ['/s/bulk-upload-deals', '/s/create-single-deal', '/s/deal-window-page'];
    noPermissionUrl = ['/s/no-permission-error'];
    @track helpText = '';
    @track isHomePageURL = false;//TH:06/04/2022:US-0011487

    connectedCallback() {

        // if (this.customError) {
        if (this.customError  && this.customError == 'true') { //MN-05012023-US-0013025 - Fixed the incorrect condition
            if (this.baseUrl == '') {
                this.titleName = this.titleName.replace('<i>{0}</i> ', '');
            }else {
                this.titleName = this.titleName.replace('<i>{0}</i>', this.baseUrl);
            }
            if (this.adminEmailAddress != '') {
                var emailTo = 'mailto:' + this.adminEmailAddress;
                this.customLabel = this.customLabel.replace('mailto:', emailTo);
            }
        }
    }

    // SB 1-4-2022 US-0011579 - Read Only Access to Deals
    @wire(getRecord, {recordId: userId, fields: '$fields'})
    getCustomerInfo({error, data}){
        var path = window.location.pathname;
        this.isHomePageURL = (path=="/s/");//TH:06/04/2022:US-0011487
        if(data){
            this.profileName = getFieldValue(data, PROFILE_NAME_FIELD);
            this.spDealValue = getFieldValue(data, SP_DEALS_FIELD);
            this.spMainDomain = getFieldValue(data, SPMAINDOMAIN_FIELD); //MN-10062024-US-0015298
            // SB 22-2-2022 US-0011686 - add new condition to check if sp deal is null
            if((this.spDealValue == 'Read Only' || this.isDealReadOnly) && this.dealUrls.includes(path)){
                this.errorMetadataName = this.metadataNameReadOnly;
            } else if(this.spDealValue == null && this.dealUrls.includes(path)){
                this.isHomePageURL = true;

                /* MN-10062024-US-0015298 - No longer use profile name
                if(this.profileName == 'NA - Seller Portal'){
                    this.errorMetadataName = 'ENnoPermission';
                } else if (this.profileName == 'DE - Seller Portal'){
                    this.errorMetadataName = 'DEnoPermission';
                }
                */

                //START--MN-10062024-US-0015298: Use SP Main Domain instead of Profile Name
                if(this.spMainDomain == this.label.SEP_Domain_NA){
                    this.errorMetadataName = 'ENnoPermission';
                } else if (this.spMainDomain == this.label.SEP_Domain_DE || this.spMainDomain == this.label.SEP_Domain_IT || this.spMainDomain == this.label.SEP_Domain_UK || this.spMainDomain == this.label.SEP_Domain_FR){
                    this.errorMetadataName = 'DEnoPermission';
                }
                //--END

            } else {
                this.errorMetadataName = this.metadataName;
            }
        }else{//TH:06/04/2022:US-0011487
            this.errorMetadataName = this.metadataName;
        }
        
    }

    @wire(doHelpTextMetadata, {metadataName : '$errorMetadataName'})
    doHelpTextMetadata(result) {
        if(result.data) {
            this.helpTextMetadata = result.data;
            var txt = this.helpTextMetadata.Help_Text__c;
            var biggerBody = this.helpTextMetadata.Bigger_Body_Test__c;
            this.helpText = txt ? txt.replace('{getHelpUrl}',this.label.getHelpUrl) : biggerBody;//TH:04/06/2024:US-0015332 : Change the help text to bigger body text if Help_Text__c is Empty
        } else if (result.error) {
            console.log('error :: ', result.error);
        }
    };

    
    redirectToHome() {
        window.open("/","_top");
    }

    //MN-05012023-US-0013025 -  Fix error of treating customError as boolean when it is just a STRING
    get isCustomError() {
        return (this.customError && this.customError=='true');
    }
}