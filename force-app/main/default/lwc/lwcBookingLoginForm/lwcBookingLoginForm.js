/*********************************************************************************************************************************
@ lwc:            lwcBookingLoginForm
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0013565 - eBay Registration Handler for Call booking site.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 24.04.2023 / Sophal Noch / create lwc
*********************************************************************************************************************************/
import { LightningElement, track,api,wire } from 'lwc';
import fetchLoginLabelTranslation from "@salesforce/apex/LwcLoginFormController.fetchLoginLabelTranslation";
import Continue_with_eBay_login from '@salesforce/label/c.Continue_with_eBay_login';
import eBay_Login from '@salesforce/label/c.eBay_Login';
import login_btn from '@salesforce/label/c.SEP_Login_btn_login';


const paramLabel = ["eBay_Login","Continue_with_eBay_login","Or","Login_with_a_Different_Account","SEP_Login_username","SEP_Login_password","SEP_Login_btn_login", "SEP_Login_forgot_pwd", "SEP_Login_sso_service", "SEP_Login_forgot_url", "SellerPortalLabel"]; //MN-31032022-US-0011535 // 15.08.2022 / Sophal Noch / US-0011816

export default class LwcBookingLoginForm extends LightningElement {

    Labels = {
        Continue_with_eBay_login, 
        eBay_Login,
        login_btn
    };

    @track isCalloutDone = false;

    @track ssoService;

    @track isDomainEU = false; 

    lbleBay_Login;
    lblContinue_with_eBay_login;
    lblSellerPortal;
    

    connectedCallback(){
        var meta = document.createElement("meta");
        meta.setAttribute("name", "viewport");
        meta.setAttribute("content", "width=device-width, initial-scale=1.0");
        document.getElementsByTagName('head')[0].appendChild(meta);
    }

    
    @track _wiredMetaResult; //This wired variable, we will using it with refreshApex whenever we want to refresh wired data on screen
    @wire(fetchLoginLabelTranslation, {
        lstLabels: paramLabel
    })
    translateLabel (result) {

        this._wiredMetaResult = result;

        if(result.data){


            this.lblSellerPortal = result.data['LoginLabel_SellerPortalLabel'].Value_in_German__c;
            this.lbleBay_Login = result.data['LoginLabel_eBay_Login'].Value_in_German__c;
            this.lblContinue_with_eBay_login = result.data['LoginLabel_Continue_with_eBay_login'].Value_in_German__c;
            this.isDomainEU = true;

            // this.ssoService =  result.data['LoginLabel_SEP_Login_sso_service'].Value_in_German__c; 
            let currentUrl = window.location.href;
            let arrUrl = currentUrl.split("/s/login/");
            let hostName = ''
            if(arrUrl.length > 1){
                hostName = arrUrl[0];
            }else{
                let url = new URL(location.href);
                hostName = url.host;
            }
            this.ssoService = hostName + '/services/auth/sso/Booking_eBay_DE_Login';

            
            this.isCalloutDone = true; 

            
        }

    }


    loginClick()
    {  
        let surl = this.getParameterByName("startURL");
        surl = surl==null?'':'?startURL='+surl;
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

}