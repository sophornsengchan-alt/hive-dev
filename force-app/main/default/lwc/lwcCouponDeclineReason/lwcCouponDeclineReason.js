/***********************
 * change log: 31/08/2022/vadhanak voun/US-0012297 - BETA Feedback
 *           : 09/06/2023/vadhanak voun/US-0013528 - Allow seller to sign contract after declining until contract due date
 *           : 11/12/2025/Sovantheany Dim/US-0033746 - POP - Trigger to update status of Program Seller to Opt-Out - instead of Seller Declined 
 * *********************** */
import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import userId from '@salesforce/user/Id';
import required from '@salesforce/label/c.Required';
import lblBack from '@salesforce/label/c.SEP_BACK_BUTTON';  //NK:09/06/2023/US-0013528
import pLease_Selete_One from '@salesforce/label/c.PLease_selete_one_of_the_rejection_reasons_below';
import please_Let_Me_Know from '@salesforce/label/c.Please_let_me_know_why_you_don_t_with_to_participate';
import any_comments_you_would_like_to_add from '@salesforce/label/c.Any_comments_you_would_like_to_add';
import requiredFieldForComment from '@salesforce/label/c.Required_field_for_comment';

import select from '@salesforce/label/c.Select';
import successful from '@salesforce/label/c.CouponDecline_Success_Msg'; //MN-13072023-US-0012496
import save from '@salesforce/label/c.Save';
import Submit from '@salesforce/label/c.Submit';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateCouponSellerStageSellDecline from '@salesforce/apex/SEPCouponController.handleUpdateCouponSellerStage';
import getAllPickListValue from '@salesforce/apex/SEPCouponController.getAllPickListValue';
import { getRecord, getFieldValue} from 'lightning/uiRecordApi';

import SELLER_DECLINED_REASONS from '@salesforce/schema/Coupon_Seller__c.Seller_Declined_Reasons__c';
//import CS_COMMENT from '@salesforce/schema/Coupon_Seller__c.Comment__c';

export default class LwcCouponDeclineReason extends NavigationMixin(LightningElement) {
    fieldErrors = {};
    userId = userId;
    @api recId;
    @api recContactId
    Labels = {
        Submit,
        required,
        successful,
        requiredFieldForComment,
        save,
        lblBack,
        select,
        pLease_Selete_One,
        please_Let_Me_Know,
        any_comments_you_would_like_to_add
    };

    @api isModalOpen = false;
    //isSaved = false;
    valueRejectionReasons = '';
    valueReasonsCommand = '';
    rejectionReasons = '';
    rejectionReasonsComments = '';
    requiredCommand = false;
    optionsDeclinedReasons;
    showSpinner = false;

    @wire(getRecord, { recordId: '$recId', fields: [SELLER_DECLINED_REASONS]  })
    wiredCouponSeller({ error, data }) {
        //US-0033746:TH:11/12/2025: Move from connectedCallback to wire to get the latest data
        if (data) {
            this.valueRejectionReasons = data.fields.Seller_Declined_Reasons__c.value;
            this.rejectionReasons = this.valueRejectionReasons;
            //this.valueReasonsCommand = data.fields.Comment__c.value;//Seller portal user don't have permission to read Comment__c field, we can use this field later if needed
        }
    }

    @api doShowModal()
    {
        this.isModalOpen = true;
        return false;
    }
    //NK:09/06/2023/US-0013528
    closeModal()
    {
        this.isModalOpen = false;
    }

    connectedCallback(){
        this.showSpinner = true;
        getAllPickListValue({ objectApiName: 'Coupon_Seller__c', 
            field_name: 'Seller_Declined_Reasons__c'})
            .then(result => {
                this.showSpinner = false;
                this.optionsDeclinedReasons = this.rejectionReasonsOptions(result);
            })
            .catch(error => {
                this.showSpinner = false;
                console.log('error', error);
            });
    }

    isInputValid() {
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
            //this.contact[inputField.name] = inputField.value;
        });
        if (isValid == false && requiredCommand == true) {
            
        }
        return isValid;
    }

    handleSumbit() {
        // to close modal set isModalOpen tarck value as false
        // this.isModalOpen = false;
        this.fieldErrors['comments'] = false;
        if(this.isInputValid() && this.rejectionReasons != '') {
            // if (this.requiredCommand == true && this.rejectionReasonsComments == '') {
            //     //this.isModalOpen = true;
            //     this.handleUpdateCouponSellerStageSellDecline(); 
            // }else {
            //     this.isModalOpen = false;
            //     // let paramData = {sellerDeclined: this.isSaved}; //call parent compnent to re-init
            //     // let ev = new CustomEvent('childmethod', {detail : paramData});
            //     // this.dispatchEvent(ev);        
            //     this.handleUpdateCouponSellerStageSellDecline(); 
            // }
            this.handleUpdateCouponSellerStageSellDecline(); 
        }
    }

    handleSave() {
        if(this.isInputValid() && this.rejectionReasons != '') {
            if (this.requiredCommand == true && this.rejectionReasonsComments == '') {
                //this.isModalOpen = true;
                this.handleUpdateCouponSellerStageSellDecline();
            }else {
                this.handleUpdateCouponSellerStageSellDecline();
                //this.isModalOpen = false;
            }
        }
    }

    

    handleRejectionReasonsChange(event) {
        this.rejectionReasons = event.detail.value;
        //NK:31/08/2022:US-0012297-AC5 - removed Other:  || this.rejectionReasons == 'Other'
        if (this.rejectionReasons == 'Cannot agree on share split') {
            this.requiredCommand = true;
        }else {
            this.requiredCommand = false;
            this.handleValidityLightningTextareaClear();
        }
        //this.handleUpdateCouponSellerStageSellDecline();
    }
    handlReasonsCommentsChange (event) {
        this.rejectionReasonsComments = event.detail.value;
        // if (this.rejectionReasonsComments != '') {
        //     setTimeout(() => {
        //         this.handleUpdateCouponSellerStageSellDecline();
        //     }, 1000);
        // }
    }

    handleValidityLightningTextareaClear() {
        window.setTimeout(() => {
            this.template.querySelectorAll('lightning-textarea').forEach((element) => { 
                element.reportValidity();
            });
        }, 10);
    }

    handleUpdateCouponSellerStageSellDecline () {
        this.showSpinner = true;
        // userId: this.userId
        updateCouponSellerStageSellDecline({ 
            csId: this.recId,
            rejectionReasons: this.rejectionReasons, 
            reasonsComments: this.rejectionReasonsComments,
            contactId: this.recContactId
            })
            .then(result => {
                if (result.status == 'ok') {
                    //this.isSaved = true;
                    this.showSpinner = false;

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: successful,
                            variant: "success"
                        })
                    );

                    this[NavigationMixin.Navigate]({
                        type: "standard__webPage",
                        attributes: {
                            url: '/my-coupon-seller-lists'
                        }
                    });

                    
                }else{
                    console.log("handleAgreeButtonClick error",result);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error updating record',
                            message: result.error,
                            variant: 'error'
                        })
                    );
                }
            }).catch(error => {
                this.showSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
                
                console.log('error', error);
            });
    }

    rejectionReasonsOptions(data) {
        let opts = [];
        if (data) {
            for (var index in data){
                opts.push({ label : index, value: data[index]});
            }
        }

        return opts;
    }

    get getModalOpen(){
        //if changeStle is true, getter will return class1 else class2
          return this.isModalOpen ? 'show': 'hide';
    }
}