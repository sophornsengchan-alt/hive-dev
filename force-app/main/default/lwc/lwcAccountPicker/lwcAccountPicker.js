/*********************************************************************************************************************************
@ Class:          lwcAccountPicker
@ Version:        1.0
@ Author:         mony nou (mony.nou@gaea-sys.com)
@ Purpose:        US-0010950 - Account Selection field on Deal Creation/List Views
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 26.04.2022 / mony nou / Created the class.
*********************************************************************************************************************************/
import { LightningElement, wire, api, track } from 'lwc';
import apexGetAccounts from '@salesforce/apex/AccountPickerController.getDEEligibleAccounts';
import field_label from '@salesforce/label/c.AccountPicker_Label';
import field_placeholder from '@salesforce/label/c.AccountPicker_Placeholder';
import field_helptext from '@salesforce/label/c.AccountPicker_HelpText';
import field_errorMsg from '@salesforce/label/c.AccountPicker_ErrorMsg_ReqField';


export default class LwcAccountPicker extends LightningElement {

    @api records;
    @api currentUser = {};
    @api selectedAccId;

    @track mRecords = {};

    value="";

    label = { 
        field_label, field_placeholder,field_helptext,field_errorMsg
    };

    

    connectedCallback() {
        this.doGetAccounts();
    } 

    doGetAccounts() {
        
        apexGetAccounts()
        .then(result => {
            // console.log("-doGetAccounts-",result);
            this.currentUser = result.curentUser;
            this.records = result.accRelation;       
            
            if (this.records.length == 1) {
                this.selectedAccId = this.records[0].AccountId.substring(0,15);
                
                let obj = {selectedVal : this.selectedAccId};
                this.dispatchEvent(new CustomEvent('accountchange', {
                    detail: obj
                }));
            }
                        
        })
        .catch(error => {
        
            console.log("apexGetAccounts error",error);
        });
    }

    get accId(){
        return this.selectedAccId;
    }

    
    get options() {
        
        let opts = [];
        
        if (this.records) {
           
            var objRec = {};
            this.records.forEach(function(acc){     
                
                var tmp = acc.AccountId.substring(0, 15); //Because COUNT logic for DE using with field EBH_BusinessName__r.Parent_Account_ID__c and it store only 15 char ID

                opts.push({ label : acc.Account.Name, value: tmp });
                objRec[tmp] = acc;
            
           });
           
           this.mRecords = objRec;

           
        }

        return opts;
    }

    handleChange(event) {

        this.selectedAccId = event.detail.value; 
        let selectedVal = event.detail.value;
        let obj = {selectedVal : selectedVal, record : (selectedVal == ''? '' : this.mRecords[selectedVal])};
        
        this.dispatchEvent(new CustomEvent('accountchange', {
            detail: obj
        }));
        
    }

    @api validateField() {
        
        let accountPicker = this.template.querySelector('.accountPicker');
        // if (this.selectedAccId == undefined || this.selectedAccId == '' ) {
        //     accountPicker.setCustomValidity(' ');
        // }

        accountPicker.reportValidity();
    }
    
}