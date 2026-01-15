/*********************************************************************************************************************************
@ Class:          lwcCouponItemsCoInvests
@ Version:        1.0
@ Author:         mony nou (mony.nou@gaea-sys.com)
@ Purpose:        US-0010437 - Ability to view item list view on coupon record
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.05.2022 / mony nou / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 18.05.2022 / mony nou / US-0010656 - Ability to upload/manage items to item based coupons
@               : 30.01.2023/vadhanak / US-0013146 - UK Champion Testing Fixes
@                                    / by default lwclistview using fieldset. so the label is fixed. BA need to add '*' -> '%*'
@               : 22.02.2023 / Sambath Seng / US-0012746 - [AU] Accessibility Configurations
*********************************************************************************************************************************/
import { LightningElement, api, track,wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; //MN-19052022-US-0010656

import { publish, MessageContext } from 'lightning/messageService';
import LWC_CONNECTION_CHANNEL from '@salesforce/messageChannel/LWC_Connection__c';

import doDeleteCouponCoInvest from '@salesforce/apex/SEPCouponController.doDeleteCouponCoInvest'; //MN-19052022-US-0010656
import updateCouponSellerStage2Review from '@salesforce/apex/SEPCouponController.updateCouponSellerStage2Review'; //MN-19052022-US-0010656
import getDownloadExcel from '@salesforce/apex/SEPDownloadController.getDownloadExcel';//LA-17-06-2022-US-0010534
import getCouponSeller2 from '@salesforce/apex/SEPCouponController.getCouponSeller2'; //SB 23.6.2022 US-0011958 - Change Requests Focus 75

import errorMsg from '@salesforce/label/c.ViewCoupon_ErrorMsg';
import btnDelete from '@salesforce/label/c.ViewCoupon_Button_Delete'; //MN-18052022-US-0010656
import btnSubmitAll from '@salesforce/label/c.ViewCoupon_Button_SubmitAll'; //MN-18052022-US-0010656
import btnCancel from '@salesforce/label/c.lwcCancelbtn'; //MN-19052022-US-0010656
import btnDelete2 from '@salesforce/label/c.ViewCoupon_Button_Delete2'; //MN-19052022-US-0010656
import deleteConfirmMsg from '@salesforce/label/c.ViewCoupon_Delete_CofirmMsg'; //MN-19052022-US-0010656
import deleteErrorMsg from '@salesforce/label/c.ViewCoupon_Delete_ErrorMsg'; //MN-19052022-US-0010656
import deleteSuccessMsg from '@salesforce/label/c.ViewCoupon_Delete_SuccessMsg'; //MN-19052022-US-0010656
import categoryTitle from '@salesforce/label/c.Category_Title';//SRONG23-05-2022:US-0010438
import btnDownloadItems from '@salesforce/label/c.DownloadItems_Button';//LA-17-06-2022-US-0010534
import Seller_Share_Description from '@salesforce/label/c.Seller_Share_Description_Item_Base';// SR 03.11.2022 US-0012716
import Seller_Share_DescriptionCategory from '@salesforce/label/c.Seller_Share_Description';// SR 03.11.2022 US-0012716
import SellerShare_PercentStar from '@salesforce/label/c.SellerShare_PercentStar';//NK:30/01/2023:US-0013146 
import SellerFundingRate from '@salesforce/label/c.SellerFundingRate';//SB 21.2.2023 US-0012746 - [AU] Accessibility Configurations


export default class LwcCouponItemsCoInvests extends LightningElement {

    @api recId;
    @api additionalFilter;
    @api cpAccess; //MN-20052022-US-0010656
    
    @track showLoadingSpinner = false; //MN-19052022-US-0010656
    @track mAllRecords = {}; //MN-18052022-US-0010656
    @track isModalOpen = false; //MN-19052022-US-0010656
    @track totalRecord = 0; //MN-19052022-US-0010656
    
    // isReview = false;
    isCategoryBase = false;
    isItemBase = false;
    isDEPortalProfile = false;// SR 03.11.2022 US-0012716
    isAU = false;//SB 21.2.2023 US-0012746 - [AU] Accessibility Configurations
    // isNegotiation = false; //SB 23.6.2022 US-0011958 - Change Requests Focus 75
    
    excelTitle;//LA-17-06-2022-US-0010534

    curPage=0;
    totalPage=0;

    Labels = { errorMsg
        , btnDelete //MN-18052022-US-0010656
        , btnSubmitAll //MN-18052022-US-0010656
        , btnCancel //MN-19052022-US-0010656
        , deleteConfirmMsg //MN-19052022-US-0010656
        , btnDelete2 //MN-19052022-US-0010656
        , deleteErrorMsg //MN-19052022-US-0010656
        , deleteSuccessMsg //MN-19052022-US-0010656
        , categoryTitle //SRONG23-05-2022:US-0010438
        , btnDownloadItems //LA-17-06-2022-US-0010534
        , Seller_Share_Description // SR 03.11.2022 US-0012716
        , Seller_Share_DescriptionCategory // SR 03.11.2022 US-0012716
        ,SellerShare_PercentStar    //NK:30/01/2023:US-0013146 
        ,SellerFundingRate//SB 21.2.2023 US-0012746 - [AU] Accessibility Configurations
    }; 

    //NK:30/01/2023:US-0013146 
    mapColHeaderOveride = {};

    connectedCallback() {
        this.additionalFilter = " AND Coupon_Seller__c =\'" + this.recId +"\'";
        this.getCouponSeller();//SB 23.6.2022 US-0011958 - Change Requests Focus 75
    }

    //MN-19052022-US-0010656
    get onShowLoadingSpinner() {
        return this.showLoadingSpinner;
    }

    // Depreciated by Sambath SENG, 05/07/2022 - Move all conditions to Apex class
    // get isValid() {
    //     // return this.additionalFilter != undefined && this.additionalFilter != "" && !this.isReview;
    //     return !this.isReview;
    // }

    //MN-19052022-US-0010656
    // SRONG 28.6.2022 US-0011918
    get showButtons() {
        return this.totalRecord > 0 && (this.cpAccess == 'Full Access' || this.cpAccess == 'Allowed');
    }

    //MN-18052022-US-0010656
    get disableBtnDelete(){

        var isDisable = true;
        var tmpMap = this.mAllRecords;

        if (Object.keys(tmpMap).length > 0) {

            var isTicked = false;

            for (var i=1; i<=this.totalPage; i++) {
                
                if (isTicked) break;

                var recPerPage = tmpMap[i];

                for (var j=0; j<recPerPage.length; j++) {
                    var rec = recPerPage[j];
                    
                    if (rec.is_Checked) {
                        isTicked = true;
                    }

                    if (isTicked) break;
                }
            }


            isDisable = !isTicked;

        } 

        return isDisable;
        
    }

    //MN-19052022-US-0010656
    // SRONG 28.6.2022 US-0011918
    // Depreciated by Sambath SENG, 05/07/2022 - Move all conditions to Apex class
    // get showCheckBox() {
    //     return (this.cpAccess == 'Full Access' || this.cpAccess == 'Allowed');
    // }

    //SB 23.6.2022 US-0011958 - Change Requests Focus 75
    // Depreciated by Sambath SENG, 05/07/2022 - Move all conditions to Apex class
    // get isNegotiationAndItemBased(){
    //     return this.isNegotiation && this.isItemBase;
    // }

    // listFields = ['Coupon_Seller__c.Coupon_Seller_Stage_Portal__c','Coupon_Seller__c.Coupon_Type__c','Coupon_Seller__c.Marketing_Coupon_Name__c','Coupon_Seller__c.Coupon_ID__c'];
    // @wire(getRecord, { recordId: '$recId', fields: '$listFields' } )
    // getCouponSeller({error, data}){
    //    if(data){
    //         var csStagePortal = data.fields["Coupon_Seller_Stage_Portal__c"].value;
    //         this.excelTitle = (data.fields["Coupon_ID__c"] ? data.fields["Coupon_ID__c"].value :'_') + '_'+ (data.fields["Marketing_Coupon_Name__c"] ? data.fields["Marketing_Coupon_Name__c"].value : '_');
    //         var sellerCouponType = data.fields["Coupon_Type__c"].value;
    //         if ( sellerCouponType == 'Category Based') this.isCategoryBase = true;
    //         if ( sellerCouponType == 'Item Based') this.isItemBase = true;
    //         if ( csStagePortal == 'Items in Review') this.isReview = true;
    //    }
    // }
    getCouponSeller() {
        getCouponSeller2({csId:this.recId})
            .then(result => {
                var excel_title1 = result.isDEPortalProfile ? (result.cs.Coupon_ID__c ? result.cs.Coupon_ID__c :'_') : (result.cs.Seller__r.Name ? result.cs.Seller__r.Name :'_');//TH:US-0012534
                this.excelTitle = excel_title1 + '_'+ (result.cs.Marketing_Coupon_Name__c ? result.cs.Marketing_Coupon_Name__c : '_');  
                this.isItemBase  = result.isItemBased;
                this.isCategoryBase = result.isCategoryBase;
                // this.isNegotiation = result.isNegotiation;//SB 23.6.2022 US-0011958 - Change Requests Focus 75  
                this.showCheckBox = result.isNegoFullAccessOrAllowed;//SB 5.7.2022 US-0011958 - Change Requests Focus 75
                this.isNegotiationAndItemBased = (result.isNegotiation && result.isItemBased);//SB 5.7.2022 US-0011958 - Change Requests Focus 75
                //this.isValid = !result.isItemInReview;//SB 5.7.2022 US-0011958 - Change Requests Focus 75
                this.isValid = !result.isNegotiation;//TH-01112022-US-0012494
                this.isItemInReview = result.isItemInReview;//TH-01112022-US-0012494
                this.isDEPortalProfile = result.isDEPortalProfile;// SR 03.11.2022 US-0012716
                this.isAU = result.isAU;//SB 21.2.2023 US-0012746 - [AU] Accessibility Configurations

                //console.log(result);
                //NK:30/01/2023:US-0013146 
                if(result.isUK)
                {
                    this.mapColHeaderOveride = {"Co_Invest__c":this.Labels.SellerShare_PercentStar};
                } else if(result.isAU){//SB 21.2.2023 US-0012746 - [AU] Accessibility Configurations
                    this.mapColHeaderOveride = {"Seller_Funding__c":this.Labels.SellerFundingRate};
                }
            })
            .catch(error => {
                console.log("error",error);
            });
    }

    //MN-18052022-US-0010656
    updateCheckBox(event){
        
        this.mAllRecords = event.detail["mAllRecords"];
        this.totalPage = event.detail["totalPage"];
        
        
    }

    updateTotalRecord(event) {

        this.totalRecord = event.detail["totalRecord"];
    }
    
    //MN-19052022-US-0010656
    handleConfirmDelete() {
        this.isModalOpen = true;
    }
    
    //MN-19052022-US-0010656
    closeModal() {
        this.isModalOpen = false;
    }

    //MN-19052022-US-0010656
    handleSubmitAll() {

        this.showLoadingSpinner = true;

        updateCouponSellerStage2Review({csId : this.recId})
        .then(result => {
            
            // console.log('***** updateCouponSellerStage2Review - result :: ', result);

            if(result["status"] == "success"){

                window.location.reload();

            }else if(result["status"] == "error") {

                this.showErrorToast('',this.Labels.deleteErrorMsg);
            }

            this.showLoadingSpinner = false;
        })
        .catch(error => {

            this.showLoadingSpinner = false;
        });
    }

    @wire(MessageContext)
    messageContext;
    
    //MN-19052022-US-0010656
    handleDelete() {

        this.showLoadingSpinner = true;
        this.isModalOpen = false;

        var tmpMap = this.mAllRecords;

        var tmpArr = new Array();
        for (var i=1; i<=this.totalPage; i++) {
            var recPerPage = tmpMap[i];
            for (var j=0; j<recPerPage.length; j++) {
                var rec = recPerPage[j];
                if (rec.is_Checked) {
                    tmpArr.push(rec.Id);
                    // rec.is_Checked = false;
                }
            }
        }

        doDeleteCouponCoInvest({cciIds : tmpArr})
        .then(result => {
            
            // console.log('***** doDeleteCouponCoInvest - result :: ', result);

            if(result["status"] == "success"){

                this.mAllRecords = {};

                this.showSuccessToast('',this.Labels.deleteSuccessMsg);

                this.reloadListView();

                const payload = { 
                    action: 'refresh',
                };
                publish(this.messageContext, LWC_CONNECTION_CHANNEL, payload);

                
                
            }else if(result["status"] == "error") {

                this.showErrorToast('',this.Labels.deleteErrorMsg);
            }

            this.showLoadingSpinner = false;
        })
        .catch(error => {

            this.showLoadingSpinner = false;
        }); 

    }

    //MN-19052022-US-0010656
    @api reloadListView() {
        let child_lwc = this.template.querySelector('c-lwc-list-view');
        child_lwc.reloadPage();
    }

    //MN-19052022-US-0010656
    showErrorToast(title, msg) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    //MN-19052022-US-0010656
    showSuccessToast(title, msg) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
    //LA-14-06-2022-US-0010534
    handleDownload() {
        getDownloadExcel({csId : this.recId})
        .then(result => {
            
            let downloadLink = document.createElement("a");
            // downloadLink.href = "data:application/pdf;base64,"+result;
            downloadLink.href = "data:application/vnd.ms-excel;base64,"+result;
            downloadLink.download = this.excelTitle+".xls";
            downloadLink.click();

        })
        .catch(error => {

           console.log('error = ',error);
        });
    }


}