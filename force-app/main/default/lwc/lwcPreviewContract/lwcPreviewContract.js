import { LightningElement, api, wire, track} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import CouponSellerStageFIELD from '@salesforce/schema/Coupon_Seller__c.Coupon_Seller_Stage__c';
import { getRecord } from 'lightning/uiRecordApi';
const FIELDS = ['Coupon_Seller__c.Id','Coupon_Seller__c.Coupon_Seller_Stage__c'];

export default class LwcSPEligibility extends LightningElement {
    @api recordId;
    @api callFromChild = false;
    @api objectApiName;
    @api showViewAgreement = false;
    @track couponSellerStageValue = 'Contract Send';
    isHaveRecordId = false;
    showErrorNoPermission = false;
    isPreviewContract = true;
    showSpinner = false;
    isStageContractSend = false;
    errorMsg;
    Coupon_Seller_Stage = CouponSellerStageFIELD;

   
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS} )
    wiredRecord({ error, data }) 
    {
        if (data) {
            //console.log('data: ',data);
            this.isHaveRecordId = true;
            this.objectApiName = data.apiName;
            if(data.fields.Coupon_Seller_Stage__c.value == 'Contract Send'){
                this.isStageContractSend = true;
            }
        }
    }

    renderedCallback() { 
        //console.log('recordId: ',this.recordId);
        //refreshApex(this.getSPEligibilityResult);
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
        this.showSpinner = true;
        event.preventDefault(); // stop the form from submitting
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
     }

    handleError(e) { 
        console.log('error');
        // 05.09.2022 / Sophal Noch / US-0012170
        this.showErrorNoPermission = true;
        this.errorMsg = e.detail.detail;
        this.showSpinner = false;
    }

    handleChange(event) {
        this.spMainDomainValue = event.detail.value;
    }
}