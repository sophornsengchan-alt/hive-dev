/**
 * change log
 *  - 02-02-2022 /vadhanak voun / US-0010870 - [SP] Just in Time Provisioning of Sellers (Deals, Monetization) - NA, DE
 * - 10-02-2022/vadhanak/ US-0010742 - [SP - EU Deals] [Bug] Redirect SSO Login/ Translation - LOGIN PAGE FOR DE - Region Specific
 *                      / moved all site properties to custom labels
 * - 31-03-2022 / US-0011535 - Better Solution for domain switch
 * - 09-12-2022 / US-0012328 - FR Login Page for Seller Portal
 * - 12-12-2022 / US-0012331 - UK Login Page for Seller Portal
 * - 04-04-2023 / US-0012171 - IT Login Page for Seller Portal
 */
import { LightningElement, track, api, wire } from 'lwc';
//import fectchUrl from '@salesforce/apex/LwcLoginFormController.fectchUrl';
import myResource from '@salesforce/resourceUrl/customTheme';
import { NavigationMixin } from 'lightning/navigation';
import translateErrMsg from '@salesforce/apex/LwcLoginFormController.translateLoginFailedErrorMessage';
import fetchLoginLabelTranslation from '@salesforce/apex/LwcLoginFormController.fetchLoginLabelTranslation'; //MN-31032022-US-0011535
import getApexLog from '@salesforce/apex/LwcLoginFormController.getApexLog';
import label_1 from '@salesforce/label/c.SEP_Loginfail_Label1';
import label_2 from '@salesforce/label/c.SEP_Loginfail_Label2';
import label_3 from '@salesforce/label/c.SEP_Loginfail_Label3';
import label_Title from '@salesforce/label/c.SellerPortalLabel'; //MN-14032022-US-0011406

import domain_DE from '@salesforce/label/c.SEP_Domain_DE'; //MN-31032022-US-0011535
import domain_NA from '@salesforce/label/c.SEP_Domain_NA'; //MN-31032022-US-0011535
import domain_AU from '@salesforce/label/c.SEP_Domain_AU'; // 15.08.2022 / Sophal Noch / US-0011816
import domain_FR from '@salesforce/label/c.SEP_Domain_FR'; //MN-09122022-US-0012328
import domain_UK from '@salesforce/label/c.SEP_Domain_UK'; //MN-12122022-US-0012331
import domain_IT from '@salesforce/label/c.SEP_Domain_IT'; //MN-04042023-US-0012171

const paramLabel = [
    'SellerPortalLabel',
    'SEP_Loginfail_Label1',
    'SEP_Loginfail_Label2',
    'SEP_Loginfail_Label3',
    'SEP_Login_sso_service',
    'LoginLabel_SEP_Loginfail_eBay_Account',
    'Bookings_Login_sso_service' //MN-03022025-US-0015466
]; //MN-31032022-US-0011535

export default class LwcLoginFailed extends NavigationMixin(LightningElement) {
    Labels = {
        label_1,
        label_2,
        label_3,
        label_Title
    };

    @track logoImg;
    @track rightSideImg;
    @api headerMessage; //MN-09122022-unuse attribuate
    @api errorMessage = '';
    @api errorMessageTranslated = '';
    @api lang;
    @api helpMessage; //MN-09122022-unuse attribuate
    @api contactUsMessage; //MN-09122022-unuse attribuate
    @api logInMessage; //MN-09122022-unuse attribuate
    @api startHereURL; //MN-09122022-unuse attribuate
    @api startHereLabel; //MN-09122022-unuse attribuate
    @api afterStartHereText; //MN-09122022-unuse attribuate
    @track whiteSpacing = ' ';
    @track baseUrl = 'https://' + location.host + '/s/login';
    @track contactUsUrl = 'https://www.ebay.com/help/home';

    @track isCalloutDone = false; //MN-09122022-US-0012328

    @api portal; //MN-03022025-US-0015466

    //MN-31032022-US-0011535-Variables to replace custom label ******

    lbllabel_Title; //replace: SellerPortalLabel
    lbllabel_1; //replace: SEP_Loginfail_Label1
    lbllabel_2; //replace: SEP_Loginfail_Label2
    lbllabel_3; //replace: SEP_Loginfail_Label3
    lbllabel_eBayAccount;
    lbllabel_ssolink;

    //****** MN-31032022-US-0011535 */

    //MN-03022025-US-0015466: To check if the portal is Booking Portal
    get isBooking() {
        return (this.portal && this.portal != "" && this.portal == "Booking Portal");
    }

    connectedCallback() {
        this.logoImg = myResource + '/logo.svg';
    }

    //MN-31032022-US-0011535
    @track _wiredMetaResult; //This wired variable, we will using it with refreshApex whenever we want to refresh wired data on screen
    @wire(fetchLoginLabelTranslation, {
        lstLabels: paramLabel
    })
    translateLabel(result) {
        this._wiredMetaResult = result;
        // console.log('**** result :: ', result);

        var url = new URL(location.href);
        var domain = url.host;
        var domainDE = domain_DE;
        var domainNA = domain_NA;
        var domainAU = domain_AU; // 15.08.2022 / Sophal Noch / US-0011816
        var domainFR = domain_FR; //MN-09122022-US-0012328
        var domainUK = domain_UK; //MN-12122022-US-0012331
        var domainIT = domain_IT; //MN-04042023-US-0012171

        if (result.data) {
            //MN-09122022-US-0012328 - We will using custom label "SEP_Current_Sandbox_Domain" to be the place that define the specific domain that Sandbox will act as
            if (result.data.SandboxDomain && result.data.SandboxDomain != '') {
                domain = result.data.SandboxDomain;
            }
            //console.log('result.data >>>', result.data);
            var LoginLabel_SellerPortalLabel,LoginLabel_SEP_Loginfail_Label1,LoginLabel_SEP_Loginfail_Label2,LoginLabel_SEP_Loginfail_Label3,LoginLabel_SEP_Login_sso_service,LoginLabel_SEP_Loginfail_eBay_Account;
            LoginLabel_SellerPortalLabel = result.data['LoginLabel_SellerPortalLabel'];
            LoginLabel_SEP_Loginfail_Label1 = result.data['LoginLabel_SEP_Loginfail_Label1'];
            LoginLabel_SEP_Loginfail_Label2 = result.data['LoginLabel_SEP_Loginfail_Label2'];
            LoginLabel_SEP_Loginfail_Label3 = result.data['LoginLabel_SEP_Loginfail_Label3'];
            LoginLabel_SEP_Login_sso_service = result.data['LoginLabel_SEP_Login_sso_service'];
            LoginLabel_SEP_Loginfail_eBay_Account = result.data['LoginLabel_SEP_Loginfail_eBay_Account'];
            //----- MN-09122022-US-0012328
            //Check SEP Domain
            if (this.compareDomain(domainDE, domain)) {
                //DE Domain
                this.lang = 'de';
                this.lbllabel_Title = LoginLabel_SellerPortalLabel.Value_in_German__c;
                this.lbllabel_1 = LoginLabel_SEP_Loginfail_Label1.Value_in_German__c;
                this.lbllabel_2 = LoginLabel_SEP_Loginfail_Label2.Value_in_German__c;
                this.lbllabel_3 = LoginLabel_SEP_Loginfail_Label3.Value_in_German__c;
                this.lbllabel_eBayAccount = LoginLabel_SEP_Loginfail_eBay_Account.Value_in_German__c;;
                this.lbllabel_ssolink = LoginLabel_SEP_Login_sso_service.Value_in_German__c+'?prompt=login';
            } else if (this.compareDomain(domainNA, domain)) {
                //NA Domain
                this.lang = 'en_US';
                this.lbllabel_Title = LoginLabel_SellerPortalLabel.Value_Big__c;
                this.lbllabel_1 = LoginLabel_SEP_Loginfail_Label1.Value_Big__c;
                this.lbllabel_2 = LoginLabel_SEP_Loginfail_Label2.Value_Big__c;
                this.lbllabel_3 = LoginLabel_SEP_Loginfail_Label3.Value_Big__c;
                this.lbllabel_eBayAccount = LoginLabel_SEP_Loginfail_eBay_Account.Value_Big__c;
                this.lbllabel_ssolink = LoginLabel_SEP_Login_sso_service.Value_Big__c+'?prompt=login';
            } else if (this.compareDomain(domainAU, domain)) {
                // AU Domain
                this.lang = 'en_US';
                // 15.08.2022 / Sophal Noch / US-0011816
                this.lbllabel_Title = LoginLabel_SellerPortalLabel.Value_Big__c;
                this.lbllabel_1 = LoginLabel_SEP_Loginfail_Label1.Value_Big__c;
                this.lbllabel_2 = LoginLabel_SEP_Loginfail_Label2.Value_in_Australian__c;
                this.lbllabel_3 = LoginLabel_SEP_Loginfail_Label3.Value_in_Australian__c;
                this.lbllabel_eBayAccount = LoginLabel_SEP_Loginfail_eBay_Account.Value_in_Australian__c;
                this.lbllabel_ssolink = LoginLabel_SEP_Login_sso_service.Value_in_Australian__c+'?prompt=login';
            } else if (this.compareDomain(domainFR, domain)) {
                //FR Domain //MN-09122022-US-0012328
                this.lang = 'fr';
                this.lbllabel_Title = LoginLabel_SellerPortalLabel.Value_in_French__c;
                this.lbllabel_1 = LoginLabel_SEP_Loginfail_Label1.Value_in_French__c;
                this.lbllabel_2 = LoginLabel_SEP_Loginfail_Label2.Value_in_French__c;
                this.lbllabel_3 = LoginLabel_SEP_Loginfail_Label3.Value_in_French__c;
                this.lbllabel_eBayAccount = LoginLabel_SEP_Loginfail_eBay_Account.Value_in_French__c;
                this.lbllabel_ssolink = LoginLabel_SEP_Login_sso_service.Value_in_French__c+'?prompt=login';
            } else if (this.compareDomain(domainUK, domain)) {
                // UK Domain //MN-12122022-US-0012331
                this.lang = 'en_US';
                this.lbllabel_Title = LoginLabel_SellerPortalLabel.Value_Big__c;
                this.lbllabel_1 = LoginLabel_SEP_Loginfail_Label1.Value_Big__c;
                this.lbllabel_2 = LoginLabel_SEP_Loginfail_Label2.Value_in_UK__c;
                this.lbllabel_3 = LoginLabel_SEP_Loginfail_Label3.Value_Big__c;
                this.lbllabel_eBayAccount = LoginLabel_SEP_Loginfail_eBay_Account.Value_Big__c;
                this.lbllabel_ssolink = LoginLabel_SEP_Login_sso_service.Value_in_UK__c+'?prompt=login';
            } else if (this.compareDomain(domainIT, domain)) {
                //IT Domain //MN-04042023-US-0012171
                this.lang = 'it';
                this.lbllabel_Title = LoginLabel_SellerPortalLabel.Value_in_Italian__c;
                this.lbllabel_1 = LoginLabel_SEP_Loginfail_Label1.Value_in_Italian__c;
                this.lbllabel_2 = LoginLabel_SEP_Loginfail_Label2.Value_in_Italian__c;
                this.lbllabel_3 = LoginLabel_SEP_Loginfail_Label3.Value_in_Italian__c;
                this.lbllabel_eBayAccount = LoginLabel_SEP_Loginfail_eBay_Account.Value_in_Italian__c;
                this.lbllabel_ssolink = LoginLabel_SEP_Login_sso_service.Value_in_Italian__c+'?prompt=login';
            }

            // //MN-09122022-US-0012328 - Moved out from connectedCallback so that the translation won't depend on url param "lang" but depend on domain instead
            // let msg = this.getParameterByName('ErrorDescription');
            // this.errorMessage = msg == null ? '' : decodeURIComponent(msg);

            if (this.isBooking) { //MN-03022025-US-0015466
                let LoginLabel_Bookings_Login_sso_service = result.data['LoginLabel_Bookings_Login_sso_service'];
                this.lbllabel_ssolink = LoginLabel_Bookings_Login_sso_service.Value_Big__c+'?prompt=login';
                this.lang = 'en_US';
                this.lbllabel_Title = LoginLabel_SellerPortalLabel.Value_Big__c;
                this.lbllabel_1 = LoginLabel_SEP_Loginfail_Label1.Value_Big__c;
                this.lbllabel_2 = LoginLabel_SEP_Loginfail_Label2.Value_Big__c;
                this.lbllabel_3 = LoginLabel_SEP_Loginfail_Label3.Value_Big__c;
                this.lbllabel_eBayAccount = LoginLabel_SEP_Loginfail_eBay_Account.Value_Big__c;
                

            }
        }
    }

    //MN-17032022-US-0011406-Translate Error Message base on URL Param "Language"
    @track _errorMessage;
    @wire(translateErrMsg, { errMsg: '$errorMessage', lang: '$lang' })
    translateFunc(result) {
        this._errorMessage = result; //MN-17122021-US-0010961

        // console.log('nsp: result == ',result);

        if (result.data) {
            if (result.data['errorMessageTranslated']) {
                this.errorMessageTranslated = result.data['errorMessageTranslated'];
            } else {
                this.errorMessageTranslated = this.errorMessage;
            }

            this.isCalloutDone = true; //MN-09122022-US-0012328
        }
    }

    // 06.06.2024 / Acmatac Seing / US-0015181 Implement Seamless eBay SSO Authentication
    strUniqueId = this.getParameterByName('ErrorDescription');
    sellerUsername = '';
    @wire(getApexLog, { uniqueId: '$strUniqueId' })
    getApexLog({ data, error }) {
        if (data) {
            const { errorMessage, sellerUsername } = data;
            this.errorMessage = errorMessage;
            this.sellerUsername = sellerUsername;
        } else if (error) {
            console.error('Problem retrieving log!');
        }
    }

    getParameterByName(name) {
        var url = window.location.href;

        name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
        var regexS = '[\\?&]' + name + '=([^&#]*)';
        var regex = new RegExp(regexS);
        var results = regex.exec(url);

        return results == null ? null : results[1];
    }

    compareDomain(labelDomain, domain) {
        if (
            (labelDomain.indexOf(';') > -1 && labelDomain.indexOf(domain) > -1) ||
            labelDomain == domain
        ) {
            return true;
        } else {
            return false;
        }
    }
}