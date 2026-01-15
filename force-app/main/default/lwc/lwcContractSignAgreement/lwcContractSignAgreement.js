/**
 * change log: 31/08/2022/vadhanak voun/US-0012297 - BETA Feedback
 *          : 13/10/2022/vadhanak voun/US-0012700 - Move location of contract signature to top
 *          : 08.11.2022/ vadhanak voun///NK:05/11/US-0012034 - [UK] Localization for Coupon Contract
 *          : 20.02.2023/ mony nou/ US-0012748 - [AU] Localization for Coupon Contract
 *          : 24.02.2023 / Sambath Seng / US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive
 *          : 02.04.2023 / Sambath Seng / US-0013377 - AU Champion UAT Fixes
 *          : 12.07.2023 / Sambath Seng / US-0012639 - Allow contract download at contract send, before contract is signed
 */
import { LightningElement,api,wire,track } from 'lwc';
import { getRecord,getFieldValue,getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContractTemplate from '@salesforce/apex/SEPCouponController.getCouponContractTemplate';
import getCouponSeller2 from '@salesforce/apex/SEPCouponController.getCouponSeller2';
import handleContractCouponSellerAggree from '@salesforce/apex/SEPCouponController.handleContractCouponSellerAgree';
import downloadDraftContractPdf from '@salesforce/apex/SEPCouponContractDownloadController.downloadDraftContractPdf';//12.07.2023 SB US-0012639
// import getDownloadExcel from '@salesforce/apex/SEPDownloadController.getDownloadExcel';//LA-17-06-2022-US-0010534
import userId from '@salesforce/user/Id';
import CONTACT_ID from '@salesforce/schema/User.Contact.Id';
import button_Agree from '@salesforce/label/c.CouponSellerDetail_Button_Agree';
import button_Decline from '@salesforce/label/c.CouponSellerDetail_Button_Decline';
import labelTextBody2 from '@salesforce/label/c.CouponSellerDetail_AgreementTextBody';
import successMsg from '@salesforce/label/c.EBH_UKTrackingResponse'; 
// import btnDownloadItems from '@salesforce/label/c.DownloadItems_Button';//LA-17-06-2022-US-0010534
import lbl_DownloadAgreement from '@salesforce/label/c.SEP_DownloadAgreement';//SB 29.6.2022 US-0010429
import accordionTitle from '@salesforce/label/c.accordionTitle';//LA-08-08-2022-US-0012206
import msgPreInfo from '@salesforce/label/c.SEP_CouponContract_Pre_Info';//NK:13/10/2022:US-0012700
 
//NK:08/11/2022:US-0012034
import button_Agree_UK from '@salesforce/label/c.button_Agree_UK';
import button_Decline_UK from '@salesforce/label/c.button_Decline_UK';
import msgPre_Info_UK from '@salesforce/label/c.SEP_CouponContract_Pre_Info_UK';
import draftPdfDownloadButton from '@salesforce/label/c.SEP_Download_Button';//12.07.2023 SB US-0012639

//MN-21022023-US-0012748
import msgContractSignConfirm from '@salesforce/label/c.SEPCouponContractConfirmMsg';



export default class LwcContractSignAgreement extends LightningElement {
    @api recId;
    @api additionalFilter;
    @api isViewAgreementClick;// SB 22.6.2022 US-0010429
    @track contactId;
    @track agreeUrl;
    @track showSpinner = false;
    @api showDeclineReason = false;
    @track excelTitle;
    @api isPreviewContract = false;
    isCouponSellerStageNotContractSend = false;
    isShowContractAgreeButton = false; // SB 20.6.2022 US-0010429 - Ability to sign Agreement in portal
    isItemBased = false;
    isCategoryBase = false;
    agreementTextBody1;
    agreementTextBody2;
    agreementTextBody3;
    agreementTextBody4;
    agreementTextBody2_tmp; //MN-25072022-US-0012015
    isShowAccordion = false;//LA-08-08-2022-US-0012206
    TermConditionText;//LA-08-08-2022-US-0012206
    isDefaultSite = false;

    excelTitle;//LA-17-06-2022-US-0010534
    Labels = {  button_Agree
                , button_Decline
                , labelTextBody2
                , successMsg
                // , btnDownloadItems //LA-14-06-2022-US-0010534
                , lbl_DownloadAgreement //SB 29.6.2022 US-0010429
                , accordionTitle
                , msgPreInfo
                ,button_Agree_UK
                ,button_Decline_UK
                ,msgPre_Info_UK
                ,msgContractSignConfirm
                ,draftPdfDownloadButton //12.07.2023 SB US-0012639
            };

    @api urlPdfDownload;
    @api fileNamePDF;
    @api showDownloadPDF = false;//SB 29.6.2022 US-0010429
    @api filePdfId;//SB 29.6.2022 US-0010429

    profileName; //MN-25072022-US-0012015
    isDEPortal = false;
    
    isUK = false;
    isFR = false;
    isIT = false;
    isAU = false; //MN-20022023-US-0012748

    isMcCoupon = false;//LA-03-09-2025-US-0033254

    @track fullTemplate='';
    @track templateReady=false;
    //NK:31/08/2022:US-0012297
    @api fieldsNoLink = ["Item_ID__c","Category_ID__c"]; //list of field that will ignore hyperlink and display as normal text

    isCheck2SignContract = false; //MN-21022023-US-0012748

    isNADomain = false; //MN-05062024-US-0015298

    connectedCallback() {
        this.showSpinner = true;
        this.additionalFilter = " AND Coupon_Seller__c =\'" + this.recId +"\'";
        this.getCouponSeller();
    }
    
  
    getCouponSeller() {
        getCouponSeller2({csId:this.recId})
            .then(result => {
                //console.log(result);
                var csContractDueDate = new Date(result.cs.Coupon_Contract_Due_Date__c);
                var formattedContractDueDate = csContractDueDate.getDate() + '/' + (csContractDueDate.getMonth()+1) + '/' + csContractDueDate.getFullYear();
                var sellerCouponType = result.sellerCouponType;
                //if(sellerCouponType == 'Item Based') this.isItemBased = true;
                this.isItemBased  = result.isItemBased;
                this.isCategoryBase = result.isCategoryBase;
                this.isMcCoupon = result.isMcCoupon; //LA-03-09-2025-US-0033254
                /////////////////////////////////////////////////////////////////
                // if (result.cs.Coupon_Seller_Stage__c != 'Contract Send') {
                //     this.isCouponSellerStageNotContractSend = true;
                // }
                ////////////////////////////////////////////////////////////////
                this.isCouponSellerStageNotContractSend = result.isCouponSellerStageNotContractSend;
                this.profileName = result.profileName; //MN-25072022-US-0012015
                
                this.isNADomain = result.isNADomain; //MN-05062024-US-0015298

                //MN-23082022-US-0012016
                //if (this.profileName == 'NA - Seller Portal') { //MN-05062024-US-0015298
                if (this.isNADomain) { //MN-05062024-US-0015298: Use SP Main Domain instead of Profile Name
                    var dd = (csContractDueDate.getDate() < 10 ? '0' : '') + csContractDueDate.getDate();
                    var MM = ((csContractDueDate.getMonth() + 1) < 10 ? '0' : '') + (csContractDueDate.getMonth() + 1);
                    formattedContractDueDate = MM + '/' + dd + '/' +  csContractDueDate.getFullYear();
                }
                 
                // this.agreementTextBody2 = this.Labels.labelTextBody2.replace('{ContractDueDate}', formattedContractDueDate); //MN-25072022-US-0012015   
                this.agreementTextBody2_tmp = this.Labels.labelTextBody2.replace('{ContractDueDate}', formattedContractDueDate); //MN-25072022-US-0012015 - This text keep showing before contract template is loaded so we will set it in getTemplate()

                this.isShowContractAgreeButton = (this.isViewAgreementClick && result.isShowContractAgreeButton); // SB 20.6.2022 US-0010429
                // LA 16.6.2022 
                this.excelTitle = (result.cs.Coupon_ID__c ? result.cs.Coupon_ID__c :'_') + '_'+ (result.cs.Marketing_Coupon_Name__c ? result.cs.Marketing_Coupon_Name__c : '_');  
                this.showDownloadPDF = result.showDownlaodPDF;//SB 29.6.2022 US-0010429
                this.filePdfId = result.attachmentId;//SB 29.6.2022 US-0010429
                this.isDEPortal = result.isDEPortalProfile;

                this.isUK = result.isUK;
                this.isFR = result.isFR;
                this.isIT = result.isIT;
                this.isAU = result.isAU; //MN-20022023-US-0012748
                this.isCA = result.isCA; //SRONG TIN - US-0033261
                this.isDefaultSite = result.isDefault;//SRO

                this.getContractTemplate(); //SB 2.3.2023 US-0012755
               
            })
            .catch(error => {
                console.log("error",error);
            });
    }
    
    // Commented by SB 2.2023 US-0012755
    // @wire(getContractTemplate, { csId: '$recId'}) 
    // getTemplate(data,error){ 
    //     //console.log("--tmpl",data);
    //     if(data){
    //         this.agreementTextBody1 = data.data;
    //         this.fullTemplate = data.data;
    //         if(this.agreementTextBody1){
    //             var arrTextBody = this.agreementTextBody1.split("<!--section-->");
    //             //console.log("--arrTextBody",arrTextBody);
    //             if( arrTextBody.length > 1){
    //                 this.agreementTextBody1 =  arrTextBody[0];
    //                 this.TermConditionText =  arrTextBody[1];
    //             }
    //         }
            
    //         this.agreementTextBody2 = this.agreementTextBody2_tmp; //MN-25072022-US-0012015
    //         this.showSpinner = false;
    //         this.templateReady = true;
    //        // console.log(" this.templateReady", this.templateReady);
    //     }
    // }

    // SB 2.3.2023 US-0012755
    getContractTemplate() {
        getContractTemplate({csId:this.recId})
            .then(result => {
                this.agreementTextBody1 = result;
                this.fullTemplate = result;
                if(this.agreementTextBody1){
                    var arrTextBody = this.agreementTextBody1.split("<!--section-->");
                    if( arrTextBody.length > 1){
                        this.agreementTextBody1 =  arrTextBody[0];
                        this.TermConditionText =  arrTextBody[1];
                    }
                }
                
                this.agreementTextBody2 = this.agreementTextBody2_tmp; //MN-25072022-US-0012015
                this.showSpinner = false;
                this.templateReady = true;
            })
            .catch(error => {
                this.showSpinner = false;
                console.log("error",error);
            });
    }

    @wire(getRecord, {recordId: userId, fields: [CONTACT_ID]})
    getContact({error, data}){
        if(data){
            this.contactId = getFieldValue(data, CONTACT_ID);
        }
    }

    handleAgreeButtonClick(){

        this.showSpinner = true;
        handleContractCouponSellerAggree({ csId: this.recId, userId: this.userId, currentContactId: this.contactId})
            .then(result => {
                if(result.status=="ok")
                {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: this.Labels.successMsg,
                            variant: 'success'
                        })
                    );
                  // console.log("attid: ",result.attachmentId);
                    
                    
                    //this.urlPdfDownload = "https://"+window.location.hostname+"/servlet/servlet.FileDownload?file="+result.attachmentId;
                    //this.fileNamePDF = result.fileNamePDF;
                    
                    getRecordNotifyChange([{recordId: this.recId}]);
                    this.callParent();
                    
                    //MN-21022023-US-0012748-Skip Create Downloaded PDF For now, this criteria can be removed once we have story to create downloaded PDF for AU
                    // SB 24.02.2023 US-0012755 - [AU] Downloading /storing Coupon Contract on Portal and in Hive
                    // if (!this.isAU) { 
                        setTimeout(() => {
                            //this.template.querySelector('.a_downloadPDF').click();
                            window.location.href = "https://"+window.location.hostname+"/sfc/servlet.shepherd/version/download/"+result.attachmentId+"?asPdf=false&operationContext=CHATTER";
                        }, 100);
                    // }
                    
                }else
                {
                    console.log("handleAgreeButtonClick error",result);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error updating record',
                            message: result.error,
                            variant: 'error'
                        })
                    );
                }
                this.getContractTemplate(); //MN-251125-US-0033542-Refresh template 
                //this.showSpinner = false;
                this.isShowContractAgreeButton = false;
                
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
                this.showSpinner = false;
                console.log('error', error);
            });
    }
    
    handleDeclineButtonClick () {
        //this.showDeclineReason = true;
        let child_lwc = this.template.querySelector('c-lwc-coupon-decline-reason');
        // console.log(child_lwc);
        child_lwc.doShowModal();
    }

    callParent(){
        let paramData = {name:"init"}; //call parent compnent to re-init
        let ev = new CustomEvent('childmethod', {detail : paramData});
            this.dispatchEvent(ev);                    
    }
    
    //LA-14-06-2022-US-0010534
    //LA-22-06-2022-US-0010534: UAT feedback to remove btn from tab Contract Sign
    /*handleDownload() {
        getDownloadExcel({csId : this.recId})
        .then(result => {
            
            let downloadLink = document.createElement("a");
            downloadLink.href = "data:application/pdf;base64,"+result;
            downloadLink.download = this.excelTitle+".xls";
            downloadLink.click();

        })
        .catch(error => {

           console.log('error = ',error);
        });
    }*/

    //SB 29.6.2022 US-0010429
    handleDownloadPDF(){        
        window.location.href = "https://"+window.location.hostname+"/sfc/servlet.shepherd/version/download/"+this.filePdfId+"?asPdf=false&operationContext=CHATTER";
    }

    //MN-21022023-US-0012748
    handleCheck2SignContract(event) {
        this.isCheck2SignContract = event.target.checked;   
    }

    get iconShowDetail(){
        return this.isShowAccordion ? "utility:chevronup" : "utility:chevrondown";
    }
    get displayDetail(){
        return this.isShowAccordion;
    }
    onShowDetail(){
        this.isShowAccordion = !this.isShowAccordion;
    }
    
    get isDESite(){ //LA-US-0012025: show contract to all Portal profile or EU profile with (site != uk , site != fr,...)
        //MN-20022023-US-0012748-Added AU into below criteria
        //(!this.isDEPortal && !this.isAU) || (this.isDEPortal && (!this.isUK && !this.isFR && !this.isIT && !this.isAU)); //AND !this.isIT,... just add more site here
        return this.isDefaultSite; 
    }

    // SB 2.4.2023 US-0013377 - AU Champion UAT Fixes
    get dynamicAgreementHeight(){
        let buttonWrapperHeight;
        // If show agreement button for AU
        if(this.isAU && this.isShowContractAgreeButton){
          buttonWrapperHeight = '108px';
        // If show agreement button for other site
        } else if ((!this.isAU && this.isShowContractAgreeButton) || this.showDownloadPDF){
            buttonWrapperHeight = '48px';
        } else {
            buttonWrapperHeight = '0px';
        }
        // 320px : size wihtout button div
        return 'max-height: calc(100vh - (320px + '+ buttonWrapperHeight +'));';
    }

    // SB 11.07.2023 US-0012639 - Allow contract download at contract send, before contract is signed
    handleDownloadDraftPdf(){
        this.showSpinner = true;
        downloadDraftContractPdf({ csId: this.recId, isDraft: 'true'})
        .then(result => {
            let link = document.createElement('a');
            link.href = 'data:application/pdf;base64,' + result.downloadContent;
            link.target = '_blank';
            link.download = result.fileName;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            this.showSpinner = false;            
        })
        .catch(error => {
            this.showSpinner = false;
            console.log('error', error);
        });
    }
}