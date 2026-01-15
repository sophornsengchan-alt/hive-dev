/*********************************************************************************************************************************
@ Component:      lwcRecordInfo
@ Version:        1.0
@ Author:         Sambath Seng
@ Purpose:        US-0010431 - Create Coupon details view on portal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16.5.2021 / Sambath Seng / Create javascript controller.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.11.2022 / Mony Nou / US-0012023 - [FR] Accessibility Configurations
*********************************************************************************************************************************/
import { LightningElement, api, track, wire } from 'lwc';
import initRecordInfo from "@salesforce/apex/SEP_Helper.initRecordInfo"; //MN-17062022-US-0011689

export default class LwcRecordInfo extends LightningElement {
    @api recordId;
    @api overrideMetadataName; //MN-17052022-US-0010656
    @api messageType; //MN-09062022-US-0011689
    @api displayFor; //MN-09062022-US-0011689

    
    @track metadataName;
    @track recordInfoMsg;
    @track isDeploying = false; //MN-09062022-US-0011689
    @track userLang; //MN-16062022-US-0011689 - Display text based on User's lang

    _tmpMsg;  //MN-02112022-US-0012023 - For some reason track variable "recordInfoMsg" always return null after we set value to it directly

    connectedCallback() {
        
        this.initData(); //MN-17062022-US-0011689-Init Data from APEX instead

    }

    //MN-17062022-US-0011689
    initData() {

        initRecordInfo ({recId:this.recordId, metaName: this.metadataName, overrideMetaName: this.overrideMetadataName})
        .then(result => {
            
            var data = result;

            //  console.log('*** initData :: ', data);

            if (data) {
            
                if (data.hasOwnProperty('isDeploying')) this.isDeploying = data.isDeploying;
                if (data.hasOwnProperty('userLang')) this.userLang = data.userLang;
                 
                
                if (data.hasOwnProperty('meta')) {
                    var tmp = data.meta;
                    
                    if (this.userLang != undefined && this.userLang != "") {
                        if(this.userLang == 'de'){
                            // this.recordInfoMsg = tmp.Value_in_German__c;
                            this._tmpMsg = tmp.Value_in_German__c; //MN-02112022-US-0012023
                        } 
                        //MN-02112022-US-0012023
                        else if (this.userLang == 'fr') {
                            this._tmpMsg = tmp.Value_in_French__c; //MN-02112022-US-0012023
                            // this.recordInfoMsg == tmp.Value_in_French__c;
                        }
                        //MN-04112022-US-0012027
                        else if (this.userLang == 'it') {
                            this._tmpMsg = tmp.Value_in_Italian__c; //MN-02112022-US-0012023
                            // this.recordInfoMsg == tmp.Value_in_French__c;
                        }
                        //else if (this.userLang == 'en_US' || this.userLang == 'en') {
                        else { //Default to english
                            /*
                            if (tmp.Value__c) this.recordInfoMsg = tmp.Value__c;
                            else { this.recordInfoMsg = tmp.Value_Big__c; }
                            */
                           //MN-02112022-US-0012023
                            if (tmp.Value__c) this._tmpMsg = tmp.Value__c;
                            else { this._tmpMsg = tmp.Value_Big__c; }
                        }
                    }

                }

                this.recordInfoMsg = this._tmpMsg;
                
                 
            }

            

        })
        .catch(error => {

        });

    }

   
    get isInforType() {
        return this.messageType == undefined || this.messageType == '' || this.messageType == 'Infor';
    }

    get isWarningType() {
        return this.messageType != '' && this.messageType == 'Warning';
    }

    get isAlertType() {
        return this.messageType != '' && this.messageType == 'Alert' && (this.displayFor == "Global" || (this.displayFor == "Deployment" &&  this.isDeploying));
    }

    get isSuccessType() {
        return this.messageType != '' && this.messageType == 'Success';
    }

}