import { LightningElement, api, wire, track} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
const FIELDS = ['Account.EBH_EmailOut__c'];
import Account_Object from '@salesforce/schema/Account';

import getSPEligibility from '@salesforce/apex/LwcSPEligibilityController.getSPEligibility';
import { refreshApex } from '@salesforce/apex';

import ErrorNoSPEligibilityPermission from '@salesforce/label/c.ErrorNoSPEligibilityPermission';
import WarningMsgSPEligibilityEmailOptOut from '@salesforce/label/c.WarningMsg_SPEligibility_EmailOptOut';//LA-20-09-2022-US-0012611
import SP_Main_Domain_Helptext from '@salesforce/label/c.SP_Main_Domain_Helptext';
import SPEligibilityBlockAccessMessage from '@salesforce/label/c.SPEligibilityBlockAccessMessage';// SB 22.2.2024

export default class LwcSPEligibility extends LightningElement {
    @api recordId;
    @api objectApiName;
    isEmailOut = false;
    showSpinner = false;
    showErrorNoPermission = false;
    error;

    @api spDeal = false;
    @api spCoupon = false;
    @api spProManage = false;
    @api spMainDomain = false;// SB 12.12.2022 US-0013001 - Domain Selection for SP Eligible Sellers
    @api spAccManagement = false;// BR 31.08.2023 US-0014084 - SP Account Management Eligibility flag
    @track spMainDomainValue = '';
    spMainDomainOption = [];
    @track fieldLabels = {};
    // SB 22.2.2024 US-0014476 
    isBlocked = false;

    label = {ErrorNoSPEligibilityPermission,WarningMsgSPEligibilityEmailOptOut,SP_Main_Domain_Helptext,SPEligibilityBlockAccessMessage}
    errorMsg = ErrorNoSPEligibilityPermission;
   
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS} )
    wiredRecord({ error, data }) 
    {
        if (data) {
            this.isEmailOut = data.fields.EBH_EmailOut__c.value;
        }
    }

    @wire(getObjectInfo, { objectApiName: Account_Object })
    getFieldLabels({ data, error }) {
        if(data){
            for (const [key, value] of Object.entries(data['fields'])) {
                this.fieldLabels[value.apiName] = value.label;
            }
        }
    }

    renderedCallback() { 
        refreshApex(this.getSPEligibilityResult);
    }


    @track getSPEligibilityResult;
    @wire(getSPEligibility, { sellerId: '$recordId'})
    wiredSPEligibility( result ) {
        this.getSPEligibilityResult = result;
        if (result.data && !result.data.isBlocked) {
            this.isBlocked = false;// SB 22.2.2024 US-0014476 
            this.spDeal = result.data.SellersEligibleforDeals;
            this.spCoupon = result.data.SellersEligibleforCoupons;
            this.spProManage = result.data.SellersEligibleforProManage; // 02.09.2022 / Sophal Noch / US-0012170
            this.spMainDomain = result.data.SPMainDomain; // SB 12.12.2022 US-0013001 - Domain Selection for SP Eligible Sellers
            this.spAccManagement = result.data.SellersEligibleForAccountManagement;// BR 31.08.2023 US-0014084 - SP Account Management Eligibility flag
            this.spMainDomainValue = result.data.SPMainDomainVal;
            let pklData = [];
            if (result.data.pklDepSPMainDomain) {
                result.data.pklDepSPMainDomain.forEach(element => {
                    pklData.push({
                        label: element.label,
                        value: element.value
                    });
                });
                this.spMainDomainOption = pklData;
            }
            
            this.showErrorNoPermission = false;
            if(!result.data.adminProfile && !this.spDeal && !this.spCoupon && !this.spProManage && !this.spMainDomain && !this.spAccManagement) {
                this.showErrorNoPermission = true;
                //this.isEmailOut = false;
            }
        } 
        // SB 22.2.2024 US-0014476
        else if(result.data && result.data.isBlocked){
            this.isBlocked = true;
        } 
        else if (result.error) {
            this.showErrorNoPermission = true;
            this.error = result.error;
            console.log("--wiredSPEligibility-error",result.error);
        }

    }
 
   get showErrorNoPermission()
   {
    return this.showErrorNoPermission ;
   }
    handleCancel(event) {
    // Add your cancel button implementation here
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    
    handleSuccess(e) {
        // Close the modal window and display a success toast
        this.showSpinner = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSubmit(event){
        this.showErrorNoPermission = false;
        this.showSpinner = true;
        event.preventDefault(); // stop the form from submitting
        if(this.spMainDomainValue == '' || this.spMainDomainValue == undefined){
            this.showSpinner = false;
            this.template.querySelector('.SP_Main_Domain__c').reportValidity();
        } else {
            const fields = event.detail.fields;
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }
     }

    handleError(e) { 
        // 05.09.2022 / Sophal Noch / US-0012170
        this.showErrorNoPermission = true;
        this.errorMsg = e.detail.detail;
        this.showSpinner = false;
    }

    handleChange(event) {
        this.spMainDomainValue = event.detail.value;
    }
}