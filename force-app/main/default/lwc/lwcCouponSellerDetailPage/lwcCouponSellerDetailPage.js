/*********************************************************************************************************************************
@ Class:          couponItemBulkUploadDE
@ Version:        1.0
@ Author:         mony nou (mony.nou@gaea-sys.com)
@ Purpose:        US-0010656 - Ability to upload/manage items to item based coupons
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16.05.2022 / mony nou / Created the class.
                  10-10-2022/ Chetra Sarom / US-0012679 - Coupons Item Upload deadline Note on Seller portal
                  22.02.2023 / Sambath Seng / US-0012746 - [AU] Accessibility Configurations
@                 18.02.2025 / SRONG TIN / US-0015819 LWS - Upload Components (deal/coupon item)
                  25/09/2025 / Davy SORN / US-0033398 - POP - SP - Ability to view related child Coupons and Item List | Incl Opt Out Part 2
@               : 12/12/2025 / SENG Chan Sophorn / US-0033567 - POP - SP - Add Button, New Field and update text on Program Coupon Layout - view Master Agreement
*********************************************************************************************************************************/
import { LightningElement, api, track,wire } from 'lwc';
import {getFieldValue, getRecord} from 'lightning/uiRecordApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';

import customTabCSS from '@salesforce/resourceUrl/customGlobalSearchTab';
import userId from '@salesforce/user/Id';
import CONTACT_ID from '@salesforce/schema/User.Contact.Id'; //MN-04072023-US-0012496
import SP_COUPONS_FIELD from '@salesforce/schema/User.Contact.Account.SP_Coupons__c';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';

import viewMasterAgreement from '@salesforce/label/c.View_Master_Agreement';//12/12/2025 / CSP: US-0033567
import buttonDownloadItemList from '@salesforce/label/c.CouponSellerDetail_Button_DownloadItemList';
import buttonOptOut from '@salesforce/label/c.CouponSellerDetail_Button_OptOut';

import tabLabel_Overview from '@salesforce/label/c.CouponSellerDetail_TabLabel_Overview';
import tabLabel_Items from '@salesforce/label/c.CouponSellerDetail_TabLabel_Items';
import tabLabel_UploadItems from '@salesforce/label/c.CouponSellerDetail_TabLabel_UploadItems';
import tabLabel_Contract from '@salesforce/label/c.CouponSellerDetail_TabLabel_Contract';// SB 10.6.2022 US-0010429
import button_ViewAgreement from '@salesforce/label/c.CouponSellerDetail_Button_ViewAgreement';// SB 10.6.2022 US-0010429
import SEP_BACK_BUTTON from '@salesforce/label/c.SEP_BACK_BUTTON'; // AMT 14.06.2022 US-0011832 AC8
// import lbl_DownloadAgreement from '@salesforce/label/c.SEP_DownloadAgreement';
import ErrorMessageCouponUploadItem from '@salesforce/label/c.ErrorMessageCouponUploadItem'; // SRONG 15.6.2022 US-0011242
import COUPON_IS_NOW_READY_FOR_ITEM_UPLOAD from '@salesforce/label/c.Coupon_Is_Now_Ready_For_Item_Upload'; // COUPON_IS_NOW_READY_FOR_ITEM_UPLOAD
import INFORMATION from '@salesforce/label/c.INFORMATION'; // 10-10-2022/ Chetra Sarom / US-0012679 - Coupons Item Upload deadline Note on Seller portal
import button_Decline from '@salesforce/label/c.CouponSellerDetail_Button_DeclineParticipant'; //MN-04072023-US-0012496
import SEP_DOWNLOAD_TRANSACTION from '@salesforce/label/c.CouponSellerDetail_DownloadTransaction';//TH:15.08.2023:US-0011560
import getCouponSeller2 from '@salesforce/apex/SEPCouponController.getCouponSeller2';
//import getRelatedFilesByRecordId from '@salesforce/apex/SEPCouponController.getRelatedFilesByRecordId';
import LOCALE from '@salesforce/i18n/locale';
import section_CouponPerformance from '@salesforce/label/c.Coupon_Performance_Section';//LA-17-10-2023:US-0014190
import getFieldSet from '@salesforce/apex/SEPCouponController.getFieldSet';//LA-19-10-2023:US-0014190

import Program_Coupon_Overview_Text from '@salesforce/label/c.Program_Coupon_Overview_Text'; //12/12/2025 / CSP: US-0033567

export default class LwcCouponSellerDetailPage extends NavigationMixin(LightningElement) {

    @api recId;
    @api couponType;

    @track profileName = '';
    @track spCouponValue;
    // Start SB 10.6.2022 US-0010429
    @track csContractDueDate;
    @track csStage;
    @track allowReacceptContract;
    // @track isShowContract = false;
    // End SB 10.6.2022 US-0010429

    @track contactId; //MN-04072023-US-0012496

    isVisibleOptOutButton = false;
    isProgramCouponSeller = false;
    coInvestFileId;
    
    //DS 01/10/2025 US-0033174
    isMasterCoupon = false;
    programCouponFilter = '';

    isCategoryBase = false;
    isItemBase = false;
    isNegotiation = false;
    isReview = false;
    SEP_BACK_BUTTON = SEP_BACK_BUTTON;
    back_url = '/my-coupon-seller-lists';
    isDEPortalProfile = false;// SR 03.11.2022 US-0012716

    isShowContractAgreeButton = false; //MN-26072022-US-0012015
    canDeclineAtNegotiation = false; //MN-11072023-US-0012496
    isDeclineAtNegotiation = false; //MN-13072023-US-0012496
    isVisibleDownloadTransactionFile = false; //TH:US-0011560
    relatedFileId = ''; //TH:US-0011560
    relatedFileName = ''; //TH:US-0011560
    // @api showDownloadPDF = false;
    // @api urlPdfDownload;
    // @api fileNamePDF;
    // @api filePdfId;

    childCoInvCls = 'hideChildCmp';//LA-29-06-2022-US-0011917
    childCateCls = 'hideChildCmp';//LA-29-06-2022-US-0011917
    childPCCls = 'hideChildCmp'; //DS 02-10-2025 US-0033174
    
    Labels = { tabLabel_Overview
            , tabLabel_Items
            , tabLabel_UploadItems
            , tabLabel_Contract
            , button_ViewAgreement
            // , lbl_DownloadAgreement
            , ErrorMessageCouponUploadItem
            , INFORMATION
            , button_Decline //MN-04072023-US-0012496
            , SEP_DOWNLOAD_TRANSACTION
            ,section_CouponPerformance,
            buttonDownloadItemList,
            buttonOptOut,
            viewMasterAgreement,
            Program_Coupon_Overview_Text //12/12/2025 / CSP: US-0033567
        };

    isShowCouponPerformanceSection = false;//LA-19-10-2023:US-0014190
    fiedlsInSection = [];//LA-19-10-2023:US-0014190

    targetUrlMasterAgreementCouponSeller='';

    // CSNotVisibleStage = ['Contract Send','Contract Signed','Coupon Running','Coupon executed','T4 Statement Send','T34 Statement Send','Invoice paid'];// SB 10.6.2022 US-0010429
    finishedRender = false;
    renderedCallback() {
        Promise.all([
            loadStyle( this, customTabCSS )
        ])
        // Acmatac SEING, 30/11/2022. US-0011914 Set Active tab
        this.activeTab(this.getParameterByName('tabset'));
    }

    connectedCallback()
    {
        this.initCS();
        //console.log('sb log: ',this.template.querySelector("lightning-helptext"));
        
    }
    

    // listFields = ['Coupon_Seller__c.Coupon_Seller_Stage__c','Coupon_Seller__c.Coupon_Seller_Stage_Portal__c','Coupon_Seller__c.Coupon_Type__c','Coupon_Seller__c.Coupon_Contract_Due_Date__c','Coupon_Seller__c.Allow_reaccept_contract__c'];
    // @wire(getRecord, { recordId: '$recId', fields: '$listFields' } )
    // getCouponSeller({error, data}){
    //     // console.log('***** getCouponSeller :: ', data);
    //    if(data){
    //         // var csStagePortal = data.fields["Coupon_Seller_Stage_Portal__c"].value;
    //         // var csStage = data.fields["Coupon_Seller_Stage__c"].value; //MN-23052022-US-0010656
    //         // var sellerCouponType = data.fields["Coupon_Type__c"].value;
    //         // if ( sellerCouponType == 'Category Based') this.isCategoryBase = true;
    //         // if ( sellerCouponType == 'Item Based' ) this.isItemBase = true;
    //         // // if ( csStagePortal == 'In Negotiation') this.isNegotiation = true;
    //         // if ( csStage == 'Contract Negotiation') this.isNegotiation = true; //MN-23052022-US-0010656
    //         // // Start SB 10.6.2022 US-0010429
    //         // if ( !this.CSNotVisibleStage.includes(csStage)) this.isShowContract = true;
    //         // this.csContractDueDate = new Date(data.fields["Coupon_Contract_Due_Date__c"].value).toISOString().slice(0, 10);
    //         // this.csStage = data.fields["Coupon_Seller_Stage__c"].value;
    //         // this.allowReacceptContract = data.fields["Allow_reaccept_contract__c"].value;
    //         // End SB 10.6.2022 US-0010429
    //    }
    // }
    initCS() {
        //console.log("init..recId.",this.recId);
        getCouponSeller2({csId:this.recId})
            .then(result => {


                // var csStagePortal = result["Coupon_Seller_Stage_Portal__c"];
                // var csStage = result["Coupon_Seller_Stage__c"]; //MN-23052022-US-0010656
                //var sellerCouponType =result["Coupon_Type__c"];
                this.isVisibleOptOutButton = result.isVisibleOptOutButton;
                this.isProgramCouponSeller = result.isProgramCouponSeller;
                this.coInvestFileId = result.coInvestFileId;

                //DS 01/10/2025 US-0033174
                this.isMasterCoupon = result.isMasterCoupon;
                this.programCouponFilter = " AND MasterCouponId__c = \'" + result.cs.Coupon__c.slice(0, -3) + "\'";

                this.targetUrlMasterAgreementCouponSeller = result.targetUrlMasterAgreementCouponSeller; //12/12/2025 / CSP: US-0033567

                this.isCategoryBase = result.isCategoryBase;
                this.isItemBase = result.isItemBased; //MN-18062022-Fixed the incorrect property
                // if ( csStagePortal == 'In Negotiation') this.isNegotiation = true;
                this.isNegotiation =  result.isNegotiation; //MN-23052022-US-0010656
                this.isReview = result.isItemInReview;
                // Start SB 10.6.2022 US-0010429
                //if ( !this.CSNotVisibleStage.includes(csStage)) this.isShowContract = true;
                this.csContractDueDate = new Date(result['cs']["Coupon_Contract_Due_Date__c"]).toISOString().slice(0, 10);; // 
                this.csStage = result['cs']["Coupon_Seller_Stage__c"];
                this.allowReacceptContract = result['cs']["Allow_reaccept_contract__c"];
                // this.isShowContract = result.isShowContract;
                // this.showDownloadPDF = result.showDownlaodPDF;
                // this.urlPdfDownload = "https://"+window.location.hostname+"/servlet/servlet.FileDownload?file="+result.attachmentId;
                // this.fileNamePDF = result.fileNamePDF;
                // this.filePdfId = result.attachmentId;
                
                // Acmatac SEING, US-0011991: Fixing issues for Coupon Linked Accounts
                this.profileName = result.profileName;
                this.spCouponValue = result.spCouponValue;
                this.hasUploadItemsAccess = result.hasUploadItemsAccess;
                this.isContractAvailable = result.isContractAvailable;
                this.isSPCouponReadOnly = result.isSPCouponReadOnly;
                this.showViewAgreement = result.showViewAgreement;
                this.isShowContractAgreeButton = result.isShowContractAgreeButton; //MN-26072022-US-0012015 
                this.isDEPortalProfile = result.isDEPortalProfile;// SR 03.11.2022 US-0012716
                
                //MN-26072022-US-0012015 - As discussed with BA, When Contract Due Date is dued and field Allow_reaccept_contract__c = false => hide tab "Contract" as well
                if (this.isShowContractAgreeButton && !this.showViewAgreement) {
                    this.isContractAvailable = false;
                }
                this.finishedRender = true;

                // 10-10-2022/ Chetra Sarom / US-0012679
                if (this.csStage == 'Contract Negotiation' && this.isItemBase) {
                    this.isCouponReadyForItemUpload = true;
                
                    this.textCouponReadyForItemUpload = COUPON_IS_NOW_READY_FOR_ITEM_UPLOAD.replace('{NegotiationEndDate}', result['negotiationEndDate']);
                }
                // end 10-10-2022/ Chetra Sarom / US-0012679 

                this.canDeclineAtNegotiation = result.canDeclineAtNegotiation; //MN-11072023-US-0012496
                this.isDeclineAtNegotiation = result.isDeclineAtNegotiation; //MN-13072023-US-0012496
                //TH:US-0011560 - Make Coupon Transaction file available for download in portal
                this.isVisibleDownloadTransactionFile = result.isVisible;
                this.relatedFileId = result.relatedFileId;
                this.relatedFileName = result.relatedFileName;
                //end US-0011560
                this.isShowCouponPerformanceSection = result.showCouponPerformanceSection;//LA-19-10-2023:US-0014190
            })
            .catch(error => {
                console.log("..initCS error",error);
                this.finishedRender = true;
            });

            this.doGetFieldSet();//LA-19-10-2023:US-0014190
    }

    // 10-10-2022/ Chetra Sarom / US-0012679
    // listCSFields = ['Coupon_Seller__c.Coupon_Type__c', 'Coupon_Seller__c.Negotiation_End_Date__c', 'Coupon_Seller__c.Coupon_Seller_Stage__c']; //10-10-2022/ Chetra Sarom / US-0012679
    // @wire(getRecord, { recordId: '$recId', fields: '$listCSFields' } )
    // getCouponSeller({error, data}){
    //     if(data){
    //         if (data.fields["Coupon_Seller_Stage__c"].value == 'Contract Negotiation' && data.fields["Coupon_Type__c"].value == 'Item Based') {
    //             this.isCouponReadyForItemUpload = true;
    //             this.textCouponReadyForItemUpload = COUPON_IS_NOW_READY_FOR_ITEM_UPLOAD.replace('{NegotiationEndDate}', data.fields["Negotiation_End_Date__c"].displayValue);
    //         }
    //     }
    // }
    // end 10-10-2022/ Chetra Sarom / US-0012679 

    // handleDownloadPDF()
    // {        
    //   // this.template.querySelector('.a_downloadPDF').click();     
      
    //   window.location.href = "https://"+window.location.hostname+"/sfc/servlet.shepherd/version/download/"+this.filePdfId+"?asPdf=false&operationContext=CHATTER";

    // }

    // Depreciated by Acmatac SEING, 29/06/2022 - Move all conditions to Apex class
    // fields = [PROFILE_NAME_FIELD, SP_COUPONS_FIELD];
    // @wire(getRecord, {recordId: userId, fields: '$fields'})
    // getSellerInfo({error, data}){
    //     // console.log('***** getSellerInfo :: ', data);
    //     if(data){

    //         this.profileName = getFieldValue(data, PROFILE_NAME_FIELD);
    //         this.spCouponValue = getFieldValue(data, SP_COUPONS_FIELD);

            
    //     }else{
            
    //     }
    // }

    // Depreciated by Acmatac SEING, 29/06/2022 - Move all conditions to Apex class
    // get hasUploadItemsAccess() {
    //     // SRONG 15.6.2022 US-0011242
    //     // SRONG 28.6.2022 US-0011918
    //     return (this.spCouponValue == "Full Access" || this.spCouponValue == "Read Only" || this.spCouponValue == "Allowed") && this.isNegotiation && this.isItemBase;
    // }
    hasUploadItemsAccess;

    // Depreciated by Acmatac SEING, 29/06/2022 - Move all conditions to Apex class
    // // SRONG 15.6.2022 US-0011242
    // get isSPCouponReadOnly() {
    //     return this.spCouponValue == "Read Only";
    // }
    isSPCouponReadOnly;

    // Depreciated by Acmatac SEING, 29/06/2022 - Move all conditions to Apex class
    // get isContractAvailable () {
    //     return this.isShowContract && this.spCouponValue == "Full Access";
    // }
    isContractAvailable;

    // Depreciated by Acmatac SEING, 29/06/2022 - Move all conditions to Apex class
    // // Start SB 10.6.2022 US-0010429
    // get showViewAgreement(){
    //     var today = new Date().toISOString().slice(0, 10);
    //     //console.log('sb log::', this.csContractDueDate);
    //     if(this.csStage == "Contract Send" && (this.csContractDueDate >= today || (this.csContractDueDate < today && this.allowReacceptContract)) && this.spCouponValue == "Full Access"){
    //         return true;
    //     } else {
    //         return false;
    //     }
    // }
    showViewAgreement;
    handleViewAgreementButton(){
        //this.isShowContract = true;
        setTimeout(() => {
            // Acmatac SEING, 30/11/2022. US-0011914 Set Active tab by name instead of customlabel
            // this.activeTab(this.Labels.tabLabel_Contract);
            this.activeTab('tab2');
        }, 100);
    }
    //Start : TH:02/11/2022:US-0012494
    handleViewItem(){
        //this.isShowContract = true;
        setTimeout(() => {
            // Acmatac SEING, 30/11/2022. US-0011914 Set Active tab by name instead of customlabel
            // this.activeTab(this.Labels.tabLabel_Items);
            this.activeTab('tab3');
        }, 100);
    }
    //SRONG TIN - 18.02.2025 - US-0015819 LWS - Upload Components (deal/coupon item)
    handleOverviewTab(){
        setTimeout(() => {
            this.activeTab('tab1');
        }, 100);
    }

    //12/12/2025 / CSP: US-0033567
    handleGoToMasterAgreementButton() {
        const targetUrl = this.targetUrlMasterAgreementCouponSeller;
      
        this[NavigationMixin.Navigate]({
          type: 'standard__webPage',
          attributes: {
              url:targetUrl
          }
      });

    }

    handleDownloadItemListButton(event){
        console.log('DownloadItemList Clicked');
        window.location.href = "https://"+window.location.hostname+"/sfc/servlet.shepherd/version/download/"+this.coInvestFileId+"?asPdf=false&operationContext=CHATTER";
    }

    handleOptOutButton(event){
        this.handleDeclineButton(event);
    }

    @track isShowItem = false;
    handleViewCoInvest(event) {
        this.isShowItem = event.detail;
        this.canDeclineAtNegotiation = false; //MN-13072023-US-0012496:Once uploaded Coupon Co-Invest => this button is hide
    }
    get uploadItemsAccess() {
        return (this.hasUploadItemsAccess &&  !this.isShowItem);
    }
    get viewItemsAccess() {
        return (!this.hasUploadItemsAccess ||  this.isShowItem); 
    }
    

    //End : US-0012494
    activeTab(tabValue){
        setTimeout(() => {
            this.template.querySelector('lightning-tabset').activeTabValue = tabValue;
        }, 200); // fixed error loading 
    }

    //MN-19052022-US-0010656
    handleReloadListView () {
        let child_lwc = this.template.querySelector('c-lwc-coupon-items-co-invests');
        child_lwc.reloadListView();
    }

    // AMT 14.06.2022 US-0011832 AC8
    clickBackhandler() {
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: this.back_url
            }
        });
    
    }

    callFromChild(event){
         if(event.detail.name=="init")
         {
            this.initCS();
         }
         
    }

    //MN-20062022-US-0011863
    handlerFocusTab(event) {
        
        let child_lwc = this.template.querySelector('c-lwc-coupon-upload-items');
        child_lwc.hideSuccessMessage();
    }

    //LA-29-06-2022-US-0011917
    handleChildHasRecord(event){
        if((event.detail['metadataName'] == 'DE_Coupon_Co_List_View' || event.detail['metadataName'] == 'AU_Coupon_Co_List_View') && event.detail["isHasRecord"])  this.childCoInvCls = '';//SB 21.2.2023 US-0012746
        if(event.detail['metadataName'] == 'Coupon_Category_Item_Base_List_View' && event.detail["isHasRecord"])   this.childCateCls = '';
        if(event.detail['metadataName'] == 'DEListProgramCouponSetting' && event.detail["isHasRecord"])   this.childPCCls = ''; // DS 02-10-2025 US-0033174
    }

    //MN-04072023-US-0012496
    @wire(getRecord, {recordId: userId, fields: [CONTACT_ID]})
    getContact({error, data}){
        if(data){
            this.contactId = getFieldValue(data, CONTACT_ID);
        }
    }

    handleDeclineButton(event) {
        let child_lwc = this.template.querySelector('c-lwc-coupon-decline-reason');
        child_lwc.doShowModal();
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

    //TH:US-0011560 - Make Coupon Transaction file available for download in portal
    handleDownload() {

        let downloadLink = document.createElement("a");
        downloadLink.href = "https://"+window.location.hostname+"/sfc/servlet.shepherd/version/download/"+this.relatedFileId;
        downloadLink.target = '_blank';
        downloadLink.download = this.relatedFileName;
        downloadLink.click();
    }

    //LA-19-10-2023:US-0014190 - get field API from fieldset
    doGetFieldSet() {
        getFieldSet({sObjectName:'Coupon_Seller__c', fieldSetName:'SEP_CouponPerformance_Section'})
        .then(result => {
            let csFieldSet = JSON.parse(result);            
            for(let i =0; i < csFieldSet.length; i++){
                this.fiedlsInSection.push(csFieldSet[i].name);
            }        
                            
        })
        .catch(error => {
            console.log("doGetFieldSet error",error);
        });
    }
}