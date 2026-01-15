/*********************************************************************************************************************************
@ Class:          LwcLoginForm
@ Version:        1.0
@ Author:         Trigg
@ Purpose:        
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09.02.2022 / US-0010903 - [Add User] Allow DE Deals Users to add others Contacts to the Seller Portal
@                           / meta-xml no longer use. fully use custom labels
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 31.03.2022 / US-0011535 - Better Solution for domain switch
@ Change history: 03.06.2022 / SAROM CHETRA / US-0011820 - Login Page Button design Changes needed.
@ Change history: 15.08.2022 / Sophal Noch / US-0011816 - Login Page for AU Seller Portal
@                02.12.2022 / Acmatac Seing / US-0011914 - Set redirect URL when user isn't logged.
@ Change history: 09.12.2022 / Mony Nou / US-0012328 - FR Login Page for Seller Portal
@ Change history: 12.12.2022 / Mony Nou / US-0012331 - UK Login Page for Seller Portal
                : 28.03.2024 / Sambath Seng / US-0014727 - Seller-Friendly Coupon ‘Contract Send’ email NA, UK, AU
*********************************************************************************************************************************/
import { LightningElement, track,api,wire } from 'lwc';
import doLogin from '@salesforce/apex/LwcLoginFormController.doLogin';
import fetchLoginLabelTranslation from "@salesforce/apex/LwcLoginFormController.fetchLoginLabelTranslation"; //MN-31032022-US-0011535
import Continue_with_eBay_login from '@salesforce/label/c.Continue_with_eBay_login';
import lbl_Or from '@salesforce/label/c.Or';
import eBay_Login from '@salesforce/label/c.eBay_Login';
import login_diff from '@salesforce/label/c.Login_with_a_Different_Account';
import login_username from '@salesforce/label/c.SEP_Login_username';
import login_pwd from '@salesforce/label/c.SEP_Login_password';
import login_btn from '@salesforce/label/c.SEP_Login_btn_login';
import login_forgot_pwd from '@salesforce/label/c.SEP_Login_forgot_pwd';
import login_forgot_url from '@salesforce/label/c.SEP_Login_forgot_url';

import domain_DE from '@salesforce/label/c.SEP_Domain_DE'; //MN-31032022-US-0011535
import domain_NA from '@salesforce/label/c.SEP_Domain_NA'; //MN-31032022-US-0011535
import domain_AU from '@salesforce/label/c.SEP_Domain_AU'; // 15.08.2022 / Sophal Noch / US-0011816
import domain_FR from '@salesforce/label/c.SEP_Domain_FR'; //MN-09122022-US-0012328
import domain_UK from '@salesforce/label/c.SEP_Domain_UK'; //MN-12122022-US-0012331
import domain_IT from '@salesforce/label/c.SEP_Domain_IT'; //MN-04042022-US-0012171

const paramLabel = ["eBay_Login","Continue_with_eBay_login","Or","Login_with_a_Different_Account","SEP_Login_username","SEP_Login_password","SEP_Login_btn_login", "SEP_Login_forgot_pwd", "SEP_Login_sso_service", "SEP_Login_forgot_url", "SellerPortalLabel"]; //MN-31032022-US-0011535 // 15.08.2022 / Sophal Noch / US-0011816

export default class LwcLoginForm extends LightningElement {

    Labels = {
        Continue_with_eBay_login, 
        lbl_Or,
        eBay_Login,
        login_diff,login_username,login_pwd,login_btn,login_forgot_pwd,login_forgot_url
    };


   @api diffacmsg;
   @api usernameplaceholder;
   @api passwordplaceholder;
   @api buttonlabel;
   @api forgotpasswordlabel;
   @api forgotpassworurl;
    username;
    password;
    @track errorCheck;
    @track loginCheck;
    @track errorMessage;

    // 03.06.2022 / SAROM CHETRA / US-0011820 
    // @track isDomainDE = true;
    @track isDomainDE = false; // 15.08.2022 / Sophal Noch / US-0011816 start
    @track isCalloutDone = false;
    // end US-0011820 

    // 15.08.2022 / Sophal Noch / US-0011816 start
    @track isDomainAU = false;
    @track showSSOLoginHeader = true;
    @track ssoService;
    @track forgetPassUrl;

    // 15.08.2022 / Sophal Noch / US-0011816 end

    //MN-09122022-US-0012328 start
    @track isDomainFR = false;
    @track isDomainEU = false; //MN-05012023-US-0012328
    @track isDomainIT = false; //MN-04042022-US-0012171
    //MN-09122022-US-0012328 end

    //MN-31032022-US-0011535-Variables to replace custom label ******

    lbleBay_Login; //replace: eBay_Login
    lblContinue_with_eBay_login; //replace Continue_with_eBay_login
    lblOr; //replace Or
    lbllogin_diff; //replace Login_with_a_Different_Account
    lbllogin_username; //replace login_username
    lbllogin_pwd; //replace SEP_Login_password
    lbllogin_btn; //replace SEP_Login_btn_login
    lbllogin_forgot_pwd; //replace SEP_Login_forgot_pwd
    lblSellerPortal; //replace SellerPortalLabel //MN-09122022-US-0012328 - Moved out from CommunityLoginTheme aura
    
    //****** MN-31032022-US-0011535 */

    connectedCallback(){
        var meta = document.createElement("meta");
        meta.setAttribute("name", "viewport");
        meta.setAttribute("content", "width=device-width, initial-scale=1.0");
        document.getElementsByTagName('head')[0].appendChild(meta);

        
    }

    //MN-31032022-US-0011535
    
    @track _wiredMetaResult; //This wired variable, we will using it with refreshApex whenever we want to refresh wired data on screen
    @wire(fetchLoginLabelTranslation, {
        lstLabels: paramLabel
    })
    translateLabel (result) {

        this._wiredMetaResult = result;
        // console.log('**** result :: ', result);
        
        var url = new URL(location.href);
        var domain = url.host;
        var domainDE = domain_DE;
        var domainNA = domain_NA;
        var domainAU = domain_AU; // 15.08.2022 / Sophal Noch / US-0011816
        var domainFR = domain_FR; //MN-09122022-US-0012328
        var domainUK = domain_UK; //MN-12122022-US-0012331
        var domainIT = domain_IT; //MN-04042022-US-0012171
        //default value
        // this.lbleBay_Login = this.Labels.eBay_Login; 
        // this.lblContinue_with_eBay_login = this.Labels.Continue_with_eBay_login;
        // this.lblOr = this.Labels.lbl_Or;
        // this.lbllogin_diff = this.Labels.login_diff;
        // this.lbllogin_username = this.Labels.login_username;
        // this.lbllogin_pwd = this.Labels.login_pwd;
        // this.lbllogin_btn = this.Labels.login_btn;
        // this.lbllogin_forgot_pwd = this.Labels.login_forgot_pwd;

        if(result.data){

            //MN-09122022-US-0012328 - We will using custom label "SEP_Current_Sandbox_Domain" to be the place that define the specific domain that Sandbox will act as
            if (result.data.SandboxDomain && result.data.SandboxDomain != '') {
                domain = result.data.SandboxDomain;
            }

            
            //----- MN-09122022-US-0012328

            // console.log('nsp: domain == ',domain);

            //Check SEP Domain
            if (this.compareDomain(domainDE, domain)) {  //DE Domain
                this.lblSellerPortal = result.data['LoginLabel_SellerPortalLabel'].Value_in_German__c;
                this.lbleBay_Login = result.data['LoginLabel_eBay_Login'].Value_in_German__c;
                this.lblContinue_with_eBay_login = result.data['LoginLabel_Continue_with_eBay_login'].Value_in_German__c;
                this.lblOr = result.data['LoginLabel_Or'].Value_in_German__c;
                this.lbllogin_diff = result.data['LoginLabel_Login_with_a_Different_Accoun'].Value_in_German__c;
                this.lbllogin_username = result.data['LoginLabel_SEP_Login_username'].Value_in_German__c;
                this.lbllogin_pwd = result.data['LoginLabel_SEP_Login_password'].Value_in_German__c;
                this.lbllogin_btn = result.data['LoginLabel_SEP_Login_btn_login'].Value_in_German__c;
                this.lbllogin_forgot_pwd = result.data['LoginLabel_SEP_Login_forgot_pwd'].Value_in_German__c;
                // US-0011820 
                this.isDomainDE = true; 
                this.isDomainEU = true; //MN-05012023-US-0012328
                this.loginCheck=true;
                // end US-0011820

                // 15.08.2022 / Sophal Noch / US-0011816
                this.ssoService =  result.data['LoginLabel_SEP_Login_sso_service'].Value_in_German__c; 
                this.forgetPassUrl = result.data['LoginLabel_SEP_Login_forgot_url'].Value_in_German__c; 
            }
            else if (this.compareDomain(domainNA, domain) || this.compareDomain(domainAU, domain) || this.compareDomain(domainUK, domain)) { //NA Domain OR AU Domain OR UK Domain
                this.lblSellerPortal = result.data['LoginLabel_SellerPortalLabel'].Value_Big__c;
                this.lbleBay_Login = result.data['LoginLabel_eBay_Login'].Value_Big__c;
                this.lblContinue_with_eBay_login = result.data['LoginLabel_Continue_with_eBay_login'].Value_Big__c;
                this.lblOr = result.data['LoginLabel_Or'].Value_Big__c;
                this.lbllogin_diff = result.data['LoginLabel_Login_with_a_Different_Accoun'].Value_Big__c;
                this.lbllogin_username = result.data['LoginLabel_SEP_Login_username'].Value_Big__c;
                this.lbllogin_pwd = result.data['LoginLabel_SEP_Login_password'].Value_Big__c;
                this.lbllogin_btn = result.data['LoginLabel_SEP_Login_btn_login'].Value_Big__c;
                this.lbllogin_forgot_pwd = result.data['LoginLabel_SEP_Login_forgot_pwd'].Value_Big__c;
                 
                // this.isDomainDE = false; // US-0011820
                
                // 15.08.2022 / Sophal Noch / US-0011816
                this.ssoService =  result.data['LoginLabel_SEP_Login_sso_service'].Value_Big__c;
                this.forgetPassUrl = result.data['LoginLabel_SEP_Login_forgot_url'].Value_Big__c;
                if(this.compareDomain(domainAU, domain)){  
                    this.isDomainAU = true;
                    this.ssoService =  result.data['LoginLabel_SEP_Login_sso_service'].Value_in_Australian__c;
                    this.forgetPassUrl = result.data['LoginLabel_SEP_Login_forgot_url'].Value_in_Australian__c;
                }

                //MN-12122022-US-0012331
                else if(this.compareDomain(domainUK, domain)) {
                    this.ssoService =  result.data['LoginLabel_SEP_Login_sso_service'].Value_in_UK__c;
                    this.isDomainEU = true; //MN-05012023-US-0012328
                    this.loginCheck=true; //MN-05012023-US-0012328
                }
            }
            else if (this.compareDomain(domainFR, domain)) {  //FR Domain //MN-09122022-US-0012328
                this.isDomainFR = true;
                this.isDomainEU = true; //MN-05012023-US-0012328
                this.loginCheck=true; //MN-05012023-US-0012328

                this.lblSellerPortal = result.data['LoginLabel_SellerPortalLabel'].Value_in_French__c;
                this.lbleBay_Login = result.data['LoginLabel_eBay_Login'].Value_in_French__c;
                this.lblContinue_with_eBay_login = result.data['LoginLabel_Continue_with_eBay_login'].Value_in_French__c;
                this.lblOr = result.data['LoginLabel_Or'].Value_in_French__c;
                this.lbllogin_diff = result.data['LoginLabel_Login_with_a_Different_Accoun'].Value_in_French__c;
                this.lbllogin_username = result.data['LoginLabel_SEP_Login_username'].Value_in_French__c;
                this.lbllogin_pwd = result.data['LoginLabel_SEP_Login_password'].Value_in_French__c;
                this.lbllogin_btn = result.data['LoginLabel_SEP_Login_btn_login'].Value_in_French__c;
                this.lbllogin_forgot_pwd = result.data['LoginLabel_SEP_Login_forgot_pwd'].Value_in_French__c;
                this.ssoService =  result.data['LoginLabel_SEP_Login_sso_service'].Value_in_French__c; 
                this.forgetPassUrl = result.data['LoginLabel_SEP_Login_forgot_url'].Value_in_French__c; 
            }
            else if (this.compareDomain(domainIT, domain)) {  //IT Domain //MN-04042022-US-0012171
                this.isDomainIT = true;
                this.isDomainEU = true; 
                this.loginCheck=true; 

                this.lblSellerPortal = result.data['LoginLabel_SellerPortalLabel'].Value_in_Italian__c;
                this.lbleBay_Login = result.data['LoginLabel_eBay_Login'].Value_in_Italian__c;
                this.lblContinue_with_eBay_login = result.data['LoginLabel_Continue_with_eBay_login'].Value_in_Italian__c;
                this.lblOr = result.data['LoginLabel_Or'].Value_in_Italian__c;
                this.lbllogin_diff = result.data['LoginLabel_Login_with_a_Different_Accoun'].Value_in_Italian__c;
                this.lbllogin_username = result.data['LoginLabel_SEP_Login_username'].Value_in_Italian__c;
                this.lbllogin_pwd = result.data['LoginLabel_SEP_Login_password'].Value_in_Italian__c;
                this.lbllogin_btn = result.data['LoginLabel_SEP_Login_btn_login'].Value_in_Italian__c;
                this.lbllogin_forgot_pwd = result.data['LoginLabel_SEP_Login_forgot_pwd'].Value_in_Italian__c;
                this.ssoService =  result.data['LoginLabel_SEP_Login_sso_service'].Value_in_Italian__c; 
                this.forgetPassUrl = result.data['LoginLabel_SEP_Login_forgot_url'].Value_in_Italian__c; 
            }
            
            this.isCalloutDone = true; // US-0011820

            
        }

    }
    

    handleUserNameChange(event){
        this.username = event.target.value;
    }
    handlePasswordChange(event){ 
        this.password = event.target.value;
    }
    handleLogin(event){
       if(this.username && this.password){
        //console.log('users>>>',this.username+this.password);
        event.preventDefault();
        // var url = new URL(location.href);
        // let paramLang= decodeURI(url.searchParams.get('language'));
        
        // 15.08.2022 / Sophal Noch / US-0011816
        let paramLang = 'en_US';
        if(this.isDomainDE){
            paramLang = 'de';
        }
        else if (this.isDomainFR) { //MN-09122022-US-0012328
            paramLang = 'fr';
        }
        else if (this.isDomainIT) { //MN-04042022-US-0012171
            paramLang = 'it';
        }

        // US-0011914 - Set redirect URL when user isn't logged.
        let surl = this.getParameterByName("startURL");
        // SB 28.4.2022 US-0014727
        surl = surl==null?'':surl;

        doLogin({ username: this.username, password: this.password, lang: paramLang,  starturllogin: surl })
            .then((result) => {  
                //console.log('esult>>>',result)             
                window.location.href = result+surl;
                //window.location.href = "https://sepdev-hive-partner.cs28.force.com/s/";
            })
            .catch((error) => {
                console.log('error--',error)         
                this.error = error;      
                this.errorCheck = true;
                this.errorMessage = error.body.message;
            });
        }
    }

    Login()
    {
       this.loginCheck=true;
    }

    loginClick()
    {  
        

        //console.log(":::loginClick:::::");   
        /*
        let lang = this.getParameterByName('language');        
        lang = (lang == null || lang =='') ? 'en_US' : lang;        

        if(lang=="de")
        {   
            window.location.href = "/services/auth/sso/eBay_DE_Login";
        }else{
            window.location.href = "/services/auth/sso/Sign_in_with_eBay_Logins";
        }
        */

        //MN-04042022-US-0011535
        // var url = new URL(location.href);
        // var domain = url.host;
        // var domainDE = domain_DE;
        // var domainAU = domain_AU;
        
        // if (domainDE.indexOf(domain) > -1) { 
        //     window.location.href = "/services/auth/sso/eBay_DE_Login";
        // }else if(domainAU.indexOf(domain) > -1) { 
        //     window.location.href = "/services/auth/sso/ to be defined later ??? ";
        // }
        // else {
        //     window.location.href = "/services/auth/sso/Sign_in_with_eBay_Logins";
        // }
        
        // US-0011914 - Set redirect URL when user isn't logged.
        let surl = this.getParameterByName("startURL");
        surl = surl==null?'':'?startURL='+surl;
        
        // 15.08.2022 / Sophal Noch / US-0011816
        window.location.href = this.ssoService+surl;
    }
    
    getParameterByName(name) 
    {        
        var url = window.location.href;        

        name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
        var regexS = "[\\?&]"+name+"=([^&#]*)";
        var regex = new RegExp( regexS );
        var results = regex.exec( url );
        
        return results == null ? null : results[1];
    }

    // SB 17.5.2022 US-0011138 - Login form doesn't treat Enter as Submit
    handleEnterKey(event){
        if(event.keyCode === 13){
          this.template.querySelector('.login-button').click();
        }
    }

    // US-0011820 
    get lblloginClass() { 
        // return this.isDomainDE ? 'forgot-password-text cus-unlink' : 'forgot-password-text';
        return this.isDomainEU ? 'forgot-password-text cus-unlink' : 'forgot-password-text'; //MN-05012023-US-0012328
    }
    // end US-0011820 

    compareDomain(labelDomain, domain){
        if((labelDomain.indexOf(';') > -1 && labelDomain.indexOf(domain) > -1) || labelDomain == domain){
            return true;
        }else{
            return false;
        }
    }
}