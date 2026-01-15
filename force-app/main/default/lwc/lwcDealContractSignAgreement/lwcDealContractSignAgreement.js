import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi'; //MN-26092022-US-0012359
//SRONG:15-09-2022-US-0012298 - Ability to sign Agreement in portal 
import contract_Agreement_Tab_Title from '@salesforce/label/c.Contract_Agreement_Tab_Title';
import contract_Agreement_Tab_TXT from '@salesforce/label/c.Contract_Agreement_Tab_TXT';
import contract_Agreement_Tab_TXT_2 from '@salesforce/label/c.Contract_Agreement_Tab_TXT_2';
import contract_Agreement_Tab_TXT_3 from '@salesforce/label/c.Contract_Agreement_Tab_TXT_3';
import contract_Agreement_Tab_TXT_4 from '@salesforce/label/c.Contract_Agreement_Tab_TXT_4';

import contract_Agreement_Tab_Seller_ID from '@salesforce/label/c.Contract_Agreement_Tab_Seller_ID';
import contract_Agreement_Tab_Title_2 from '@salesforce/label/c.Contract_Agreement_Tab_Title_2';
import contract_Agreement_Tab_eBay_Funding from '@salesforce/label/c.Contract_Agreement_Tab_eBay_Funding';
import contract_Agreement_Tab_Deal_Page_Placement from '@salesforce/label/c.Contract_Agreement_Tab_Deal_Page_Placement';
import contract_Agreement_Tab_Deal_Start_Date_And_Price from '@salesforce/label/c.Contract_Agreement_Tab_Deal_Start_Date_And_Price';
import contract_Agreement_Tab_Deal_Stop_Date_And_Price from '@salesforce/label/c.Contract_Agreement_Tab_Deal_Stop_Date_And_Price';
import contract_Agreement_Tab_Discount_Applied from '@salesforce/label/c.Contract_Agreement_Tab_Discount_Applied';
import contract_Agreement_Tab_Maximum_Subsidy from '@salesforce/label/c.Contract_Agreement_Tab_Maximum_Subsidy';
import contract_Agreement_Tab_Maximum_Unit from '@salesforce/label/c.Contract_Agreement_Tab_Maximum_Unit';
import contract_Agreement_Tab_Ul_TXT from '@salesforce/label/c.Contract_Agreement_Tab_Ul_TXT';
import contract_Agreement_Tab_Ul_TXT_2 from '@salesforce/label/c.Contract_Agreement_Tab_Ul_TXT_2';
import contract_Agreement_Tab_Ul_TXT_3 from '@salesforce/label/c.Contract_Agreement_Tab_Ul_TXT_3';
import contract_Agreement_Tab_Ul_TXT_4 from '@salesforce/label/c.Contract_Agreement_Tab_Ul_TXT_4';
import contract_Agreement_Tab_Ul_TXT_5 from '@salesforce/label/c.Contract_Agreement_Tab_Ul_TXT_5';
import contract_Agreement_Tab_Ul_TXT_6 from '@salesforce/label/c.contract_Agreement_Tab_Ul_TXT_6';
import contract_Agreement_Tab_Ul_TXT_7 from '@salesforce/label/c.Contract_Agreement_Tab_Ul_TXT_7'; //MN-22102025-US-0033377
import contract_Agreement_Tab_I_Agree_Text from '@salesforce/label/c.Contract_Agreement_Tab_I_Agree_Text';
import contract_Agreement_Tab_I_Decline_Text from '@salesforce/label/c.Contract_Agreement_Tab_I_Decline_Text';
import Contract_Agreement_Tab_Decline_Reason from '@salesforce/label/c.Contract_Agreement_Tab_Decline_Reason';
import Contract_Agreement_Tab_Decline_Reason_Text from '@salesforce/label/c.Contract_Agreement_Tab_Decline_Reason_Text';
import Contract_Agreement_Tab_Decline_Reason_Required from '@salesforce/label/c.Contract_Agreement_Tab_Decline_Reason_Required';
import Contract_Agreement_Tab_Decline_Reason_Cancel from '@salesforce/label/c.Contract_Agreement_Tab_Decline_Reason_Cancel';
import Contract_Agreement_Tab_Decline_Reason_Submit from '@salesforce/label/c.Contract_Agreement_Tab_Decline_Reason_Submit';
import Contract_Agreement_Tab_Rejection_Reason_Label from '@salesforce/label/c.Contract_Agreement_Tab_Rejection_Reason_Label';
import Contract_Agreement_Tab_Rejection_Comment_Label from '@salesforce/label/c.Contract_Agreement_Tab_Rejection_Comment_Label';
import Contract_Agreement_Tab_Required from '@salesforce/label/c.Contract_Agreement_Tab_Required';
import contract_Agreement_Tab_Label from '@salesforce/label/c.contract_Agreement_Tab_Label';
import contract_Agreement_Tab_Success_Message from '@salesforce/label/c.Contract_Agreement_Tab_Success_Message';
import contract_Agreement_Tab_View_Agreement from '@salesforce/label/c.Contract_Agreement_Tab_View_Agreement';
import contract_Agreement_Tab_PM_ID from '@salesforce/label/c.Contract_Agreement_Tab_PM_ID'; //MN-22102025-US-0033377
import doAgreeOrDeclineDealContractAgreement from '@salesforce/apex/SEPDealContractAgreementController.doAgreeOrDeclineDealContractAgreement';
import getDealContractAgreementData from '@salesforce/apex/SEPDealContractAgreementController.getDealContractAgreementData';
import lbl_DownloadAgreement from '@salesforce/label/c.SEP_DownloadAgreement';//MN-26092022-US-0012359


                                     
export default class LwcDealContractSignAgreement extends NavigationMixin(LightningElement) {
    @api recId;
    @api showDownloadPDF = false;//MN-26092022-US-0012359

    @track showSpinner = false;
    @track isShowAgreeOrDecline = false;
    @track isHasData = false;
    @track isModalOpen=false;
    
    isDiscountAppliedInCart; //MN-31102022-US-0012856


    Labels = {
        contract_Agreement_Tab_Title,
        contract_Agreement_Tab_TXT,
        contract_Agreement_Tab_TXT_2,
        contract_Agreement_Tab_TXT_3,
        contract_Agreement_Tab_TXT_4,
        contract_Agreement_Tab_Seller_ID,
        contract_Agreement_Tab_Title_2,
        contract_Agreement_Tab_eBay_Funding,
        contract_Agreement_Tab_Deal_Page_Placement,
        contract_Agreement_Tab_Deal_Start_Date_And_Price,
        contract_Agreement_Tab_Deal_Stop_Date_And_Price,
        contract_Agreement_Tab_Discount_Applied,
        contract_Agreement_Tab_Maximum_Subsidy,
        contract_Agreement_Tab_Maximum_Unit,
        contract_Agreement_Tab_Ul_TXT,
        contract_Agreement_Tab_Ul_TXT_2,
        contract_Agreement_Tab_Ul_TXT_3,
        contract_Agreement_Tab_Ul_TXT_4,
        contract_Agreement_Tab_Ul_TXT_5,
        contract_Agreement_Tab_Ul_TXT_6,
        contract_Agreement_Tab_Label,
        contract_Agreement_Tab_View_Agreement,
        contract_Agreement_Tab_I_Agree_Text,
        contract_Agreement_Tab_I_Decline_Text,
        contract_Agreement_Tab_Success_Message,
        Contract_Agreement_Tab_Decline_Reason,
        Contract_Agreement_Tab_Decline_Reason_Text,
        Contract_Agreement_Tab_Decline_Reason_Required,
        Contract_Agreement_Tab_Decline_Reason_Cancel,
        Contract_Agreement_Tab_Decline_Reason_Submit,
        Contract_Agreement_Tab_Rejection_Reason_Label,
        Contract_Agreement_Tab_Rejection_Comment_Label,
        Contract_Agreement_Tab_Required,
        lbl_DownloadAgreement, //MN-26092022-US-0012359
        contract_Agreement_Tab_PM_ID, //MN-22102025-US-0033377
        contract_Agreement_Tab_Ul_TXT_7 //MN-22102025-US-0033377
    };
    dca;
    options;
    // linkPMID; //MN-22102025-US-0033377

    renderedCallback() {
       
    }

    connectedCallback()
    {
        this.init();
    }

    init() {
        this.showSpinner = true;
        getDealContractAgreementData({dcaId:this.recId})
        .then(result => {
            this.showSpinner = false;
            this.isHasData = true;
            this.dca = result.dca;
            this.dca.Deal_Start_Time__c = result.startTime;
            this.dca.Deal_End_Time__c = result.endTime;
            this.isShowAgreeOrDecline = result.isShowAgreeOrDecline;
            this.options = result.listPklValRejectReason;
            this.dca.Rejection_Reason__c = '';
            this.dca.Rejection_Comments__c = '';

            //MN-26092022-US-0012359
            this.showDownloadPDF = result.showDownlaodPDF;
            this.filePdfId = result.attachmentId;

            //MN-31102022-US-0012856
            this.isDiscountAppliedInCart = result.isDiscountAppliedInCart;

            //MN-22102025-US-0033377
            // this.linkPMID = '/' + result.dca.Id;
            
        })
        .catch(error => {
            //console.log("..init error::",error);
        });
    }

    openModal() {
        this.isModalOpen=true;
        this.dca.Rejection_Reason__c = '';
        this.dca.Rejection_Comments__c = '';
    }

    closeModal(event)
    {
        this.isModalOpen=false;
    }

    handleSuccess(event){

    }
    handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        this.dca.Rejection_Reason__c = fields.Rejection_Reason__c;
        this.dca.Rejection_Comments__c = fields.Rejection_Comments__c;
        if(this.dca.Rejection_Reason__c == ''){
            return;
        }
        //decline
        this.handleDeclineButtonClick();
    }
    handleError(event){

    }

    handleAgreeButtonClick () {
        this.showSpinner = true;
        var data = [{ 
            dca:this.dca,
            isAgree:true,

        }];
         
        doAgreeOrDeclineDealContractAgreement({jsonData:JSON.stringify(data)})
        .then(result => {
            if(result.success){
                this.isShowAgreeOrDecline = false;
                this.showSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.Labels.contract_Agreement_Tab_Success_Message,
                        variant: 'success'
                    })
                );

                getRecordNotifyChange([{recordId: this.recId}]);
                
                //MN-26092022-US-0012359 
                if (result.isAgree) {
                    setTimeout(() => {
                        window.location.href = "https://"+window.location.hostname+"/sfc/servlet.shepherd/version/download/"+result.attachmentId+"?asPdf=false&operationContext=CHATTER";
                    }, 100);    
                }

                

            }else{
                this.showSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: result.errorMsg,
                        variant: 'error'
                    })
                );
            }
            
        })
        .catch(error => {

            console.log('**** error :: ', error);

            this.showSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
    }
    
    handleDeclineButtonClick () {
        this.showSpinner = true;
        var data = [{ 
            dca:this.dca,
            isAgree:false,

        }];
        doAgreeOrDeclineDealContractAgreement({jsonData:JSON.stringify(data)})
        .then(result => {
            if(result.success){
                this.isShowAgreeOrDecline = false;
                this.showSpinner = false;
                this[NavigationMixin.Navigate]({
                    type: "standard__webPage",
                    attributes: {
                        url: '/my-deal-contract-agreement-lists'
                    }
                });

            }else{
                this.showSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: result.errorMsg,
                        variant: 'error'
                    })
                );
            }
            
        })
        .catch(error => {
            this.showSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error,
                    variant: 'error'
                })
            );
        });
    }

    //MN-26092022-US-0012359
    handleDownloadPDF(){        
        window.location.href = "https://"+window.location.hostname+"/sfc/servlet.shepherd/version/download/"+this.filePdfId+"?asPdf=false&operationContext=CHATTER";
    }

}