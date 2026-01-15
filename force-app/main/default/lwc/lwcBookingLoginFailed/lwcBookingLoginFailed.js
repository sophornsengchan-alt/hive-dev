/*********************************************************************************************************************************
@ lwc:            lwcBookingLoginFailed
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0013565 - eBay Registration Handler for Call booking site.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 24.04.2023 / Sophal Noch / create lwc
*********************************************************************************************************************************/
import { LightningElement, track,api, wire } from 'lwc';
import myResource from '@salesforce/resourceUrl/customTheme'; 
import { NavigationMixin } from 'lightning/navigation';
import translateErrMsg from '@salesforce/apex/LwcLoginFormController.translateLoginFailedErrorMessage';
import fetchLoginLabelTranslation from "@salesforce/apex/LwcLoginFormController.fetchLoginLabelTranslation"; //MN-31032022-US-0011535
import label_1 from '@salesforce/label/c.SEP_Loginfail_Label1';
import label_2 from '@salesforce/label/c.SEP_Loginfail_Label2';
import label_3 from '@salesforce/label/c.SEP_Loginfail_Label3';
import label_Title from '@salesforce/label/c.SellerPortalLabel'; //MN-14032022-US-0011406

const paramLabel = ["SellerPortalLabel","SEP_Loginfail_Label1","SEP_Loginfail_Label2","SEP_Loginfail_Label3"]; //MN-31032022-US-0011535

export default class lwcBookingLoginFailed extends NavigationMixin(LightningElement) {
    Labels = {
      label_1,label_2,label_3,label_Title
    }

    @track logoImg;
    @api errorMessage = "";
    @api errorMessageTranslated = '';
    @api lang;

    @track isCalloutDone = false;

    lbllabel_Title; 
    lbllabel_1; 
    lbllabel_2; 
    lbllabel_3; 
    

    connectedCallback() {

        this.logoImg = myResource + '/logo.svg';

	}

  @track _wiredMetaResult; //This wired variable, we will using it with refreshApex whenever we want to refresh wired data on screen
  @wire(fetchLoginLabelTranslation, {
      lstLabels: paramLabel
  })
  translateLabel (result) {

      this._wiredMetaResult = result; 

      
      if(result.data){


          this.lang = 'de'; 
          this.lbllabel_Title = result.data['LoginLabel_SellerPortalLabel'].Value_in_German__c;
          this.lbllabel_1 = result.data['LoginLabel_SEP_Loginfail_Label1'].Value_in_German__c;
          this.lbllabel_2 = result.data['LoginLabel_SEP_Loginfail_Label2'].Value_in_German__c;
          this.lbllabel_3 = result.data['LoginLabel_SEP_Loginfail_Label3'].Value_in_German__c;
    
          let msg = this.getParameterByName('ErrorDescription');
          this.errorMessage = (msg==null?"":decodeURIComponent(msg));

      }

  }

  @track _errorMessage;
  @wire(translateErrMsg, { errMsg: '$errorMessage', lang: '$lang'})
  translateFunc(result){ 
      
      this._errorMessage = result;

      if(result.data){
        if(result.data["errorMessageTranslated"]){
            this.errorMessageTranslated = result.data["errorMessageTranslated"];
        }else {
          this.errorMessageTranslated = this.errorMessage;
        }

        this.isCalloutDone = true; 
      }
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