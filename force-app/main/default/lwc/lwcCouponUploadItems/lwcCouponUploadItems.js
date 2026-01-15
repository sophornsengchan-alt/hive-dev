/*********************************************************************************************************************************
@ Class:          couponItemBulkUploadDE
@ Version:        1.0
@ Author:         mony nou (mony.nou@gaea-sys.com)
@ Purpose:        US-0010656 - Ability to upload/manage items to item based coupons
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16.05.2022 / mony nou / Created the class.
@                 25-7-2022 / sovantheany dim/ US-0012014 - NA Localization for Item Upload template file
@                 30-08-2022/vadhanak voun/US-0012297 - BETA Feedback
@                 01-11-2022 / Chetra Sarom / US-0012857 - Success message not translation to German Language     
@                 24.11.2022/ vadhanak voun/US-0012035 - [UK] Localization for Item Upload template file
@                 22.02.2023 / Sambath Seng / US-0012548 - [AU] Localization for Item Upload template file
@                 23.02.2023/ vadhanak voun/ US-0013150 - FR Champion Testing Fixes
@                 25.04.2023 / Sambath Seng / US-0013527 - [IT] Champion Testing Fixes
@                 22.08.2024 / vadhanak voun / US-0015738 - Upload Components (deal/coupon item) not working due to LWS
@                 18.02.2025 / SRONG TIN / US-0015819 LWS - Upload Components (deal/coupon item)
*********************************************************************************************************************************/
import { LightningElement, api, track,wire } from 'lwc';

import PapaParse from '@salesforce/resourceUrl/PapaParse';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, MessageContext } from 'lightning/messageService'; //MN-10062022-US-0011863
import LWC_CONNECTION_CHANNEL from '@salesforce/messageChannel/LWC_Connection__c'; //MN-10062022-US-0011863

import {getFieldValue, getRecord,updateRecord} from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/Coupon_Seller__c.Id';
import STAGE_FIELD from '@salesforce/schema/Coupon_Seller__c.Coupon_Seller_Stage__c';
//import userId from '@salesforce/user/Id';
import doSubmitMultipleCPItems from '@salesforce/apex/ClsBulkUploadCSV.doSubmitMultipleCouponItems';
import doLoadCouponUploadItems from '@salesforce/apex/ClsBulkUploadCSV.doLoadCouponUploadItems';

import btn_preview from '@salesforce/label/c.CouponUploadItems_Preview';
import btn_submit from '@salesforce/label/c.Label_Upload_button'; //NK:US-0012297: Label_Submit_button -> Label_Upload_button
import btn_downloadSampleFile from '@salesforce/label/c.CouponUploadItems_DownloadCSVSampleFile';
import bulkUploadCouponItemsTemplateDE from '@salesforce/resourceUrl/SEP_Bulk_Upload_CouponItems_Template_DE'; //SB 20.5.2022 US-0010659 - Template for item upload available to seller
import bulkUploadCouponItemsTemplateNA from '@salesforce/resourceUrl/SEP_Bulk_Upload_CouponItems_Template_NA';//TH:US-0012014
import bulkUploadCouponItemsTemplateFR from '@salesforce/resourceUrl/SEP_Bulk_Upload_CouponItems_Template_FR';//SB 22.11.2022 US-0012026 - [FR] Localization for Item Upload template file
import bulkUploadCouponItemsTemplateIT from '@salesforce/resourceUrl/SEP_Bulk_Upload_CouponItems_Template_IT';//SB 22.11.2022 US-0012030 - [IT] Localization for Item Upload template file
import bulkUploadCouponItemsTemplateUK from '@salesforce/resourceUrl/SEP_Bulk_Upload_CouponItems_Template_UK';//NK:24/11/2022:US-0012035
import bulkUploadCouponItemsTemplateAU from '@salesforce/resourceUrl/SEP_Bulk_Upload_CouponItems_Template_AU';//SB 22.2.2023 US-0012548

import btn_cancel from '@salesforce/label/c.lwcCancelbtn';
import btn_back from '@salesforce/label/c.SEP_BACK_BUTTON';
import btn_submit2 from '@salesforce/label/c.Submit_btn';
import txt_rownum from '@salesforce/label/c.Row_Number';
import txt_totalrecord from '@salesforce/label/c.CouponUploadItems_TotalRecord';
import uploadSizeAvailability_Message from '@salesforce/label/c.COUPON_ITEM_UPLOAD_SIZE_AVAILABILITY_MESSAGE';
import uploadResult_Message from '@salesforce/label/c.Upload_Result_Fail';//TH:02.11.2022:US-0012494 - Simplify Item Upload Process
import thank_You_message from '@salesforce/label/c.Thank_You_message';//TH:02.11.2022:US-0012494 - Simplify Item Upload Process
//US-0012857 import coInvest_success_message from '@salesforce/label/c.CoInvest_success_message';//TH:02.11.2022:US-0012494 - Simplify Item Upload Process

import COUPON_UPLOAD_ITEM_REQUIRED_FIELD_ITEM_ID from '@salesforce/label/c.COUPON_UPLOAD_ITEM_REQUIRED_FIELD_ITEM_ID';
import COUPON_UPLOAD_ITEM_REQUIRED_FIELD_ITEM_TITLE from '@salesforce/label/c.COUPON_UPLOAD_ITEM_REQUIRED_FIELD_ITEM_TITLE';
import READY_TO_UPLOAD from '@salesforce/label/c.READY_TO_UPLOAD';
import DUPLICATE_DATA from '@salesforce/label/c.DUPLICATE_DATA';
import ITEM_ID_MAXIMUM_CHAR_AND_DIGIT_IS_NUMERIC from '@salesforce/label/c.LWCBulkUploadCSVError4';
import ITEM_TITLE_MAXIMUM_CHARACTERS from '@salesforce/label/c.ITEM_TITLE_MAXIMUM_CHARACTERS';
import MSG_MAXIMUM_NUMBER_OF_ITEMS_FOR_COUPON_UPLOAD from '@salesforce/label/c.MSG_MAXIMUM_NUMBER_OF_ITEMS_FOR_COUPON_UPLOAD';
import MAX_COINVEST_PER_COUPON from '@salesforce/label/c.MAX_COINVEST_PER_COUPON';
import INVALID_CSV_FORMAT from '@salesforce/label/c.INVALID_CSV_FORMAT';
import MSG_DUPLICATE_ITEM_ID_AGAINST_ORG from '@salesforce/label/c.MSG_DUPLICATE_ITEM_ID_AGAINST_ORG';
import INFORMATION from '@salesforce/label/c.INFORMATION'; // 10-10-2022/ Chetra Sarom / US-0012679 - Coupons Item Upload deadline Note on Seller portal


import next from '@salesforce/label/c.Next'; //MN-14062022-US-0011863-Pagination
import prev from '@salesforce/label/c.Previous'; //MN-14062022-US-0011863-Pagination

import label_CS_DownloadSample from '@salesforce/label/c.Label_CS_DownloadSample';//30-08-2022/vadhanak voun/US-0012297
import COUPON_UPLOAD_ITEM_FOLLOWING_RECORDS_CREATED_REASONS from '@salesforce/label/c.COUPON_UPLOAD_ITEM_FOLLOWING_RECORDS_CREATED_REASONS';//01-11-2022 / Chetra Sarom / US-0012857 - Success message not translation to German Language   

export default class LwcCouponUploadItems extends LightningElement {
    parserInitialized = false;
    @track _rows;
    //@api Variables
    @api recId; //Coupon Seller's Id
    @api csObj = {};
    @api accountId;
    @api cpItems = [];
    @api numberOfCPItemsPerPk = 150;
    @track currentStep = 1;

    //@track Variables
    @track showLoadingSpinner = false;
    @track isShowMessage = false;
    @track objMessageInfos = [];
    @track allMessageInfo = [];
    @track objMessageResult = {};

    @track data = [];
    @track cpItemsComplete = [];
    @track cpItemsSaveResult = [];
    @track totalRec = 0;
    @track columns = [];
    @track isNoFile = true;
    @track isDisableNextBtn = true;
    @track fileName = "";
    @track isSomeError = false;
    @track isSomeFail = false;
    @track mRowIndex = {};
    @track mapErrorMessages = {};
    @track isInvalidFormat = false;
    @track currUserProfileName = '';
    @track isUnableUpload = false;
    @track couponCoInvestCount = 0;
    @track uploadSizeAvailability_Message = uploadSizeAvailability_Message;
    @track uploadResult_Message = uploadResult_Message;
    @track thank_You_message = thank_You_message;
    @track isReachLimit = false;
    @track isCouponReadyForItemUpload = false;  // 10-10-2022/ Chetra Sarom / US-0012679
    @track couponCoInvestItemIds = [];
    @track maxCoinvestPerCoupon = MAX_COINVEST_PER_COUPON; // 09.06.2023 / Sophal Noch / US-0013666

    @track selectedSeperator = ';';
    @track csvHeaderGerman1 = '';
    @track csvHeaderGerman2 = '""';
    @track csvHeaderEnglish1 = '';
    @track csvHeaderEnglish2 = '';
    @track textCouponReadyForItemUpload = '';

    @track isDE =false;
    @track isNA = false;
    @track isAU = false;
    @track isFR = false;//SB 22.11.2022 US-0012026 - [FR] Localization for Item Upload template file
    @track isIT = false;//SB 23.11.2022 US-0012030 - [IT] Localization for Item Upload template file
    @track isUK = false;//NK:24/11/2022:US-0012035
    @track isMainSiteUK = false;//BR 20.02.2023 US-0013232 - UK Beta Testing Fixes

    @track defaulCols = [
        { label: '', fieldName: 'row_number', type: 'number', initialWidth: 100},
        { label: 'Status', fieldName: 'status', type: 'text',wrapText: true, initialWidth: 100, cellAttributes: { class: { fieldName: 'cls_status' } }},
        { label: 'eBay Item ID', fieldName: 'Item_ID__c', type: 'text', initialWidth: 300},
        { label: 'Item Title', fieldName: 'Item_Title__c', type: 'text'},
    ];

    //MN-10102022-US-0012620
    @track naCols = [
        { label: '', fieldName: 'row_number', type: 'number', initialWidth: 100},
        { label: 'Status', fieldName: 'status', type: 'text',wrapText: true, initialWidth: 100, cellAttributes: { class: { fieldName: 'cls_status' } }},
        { label: 'eBay Item ID', fieldName: 'Item_ID__c', type: 'text', initialWidth: 300},
        { label: 'Item Title (optional)', fieldName: 'Item_Title__c', type: 'text'},
    ];

    @track germanCols = [
        { label: '', fieldName: 'row_number', type: 'number', initialWidth: 100},
        { label: 'Status', fieldName: 'status', type: 'text',wrapText: true, initialWidth: 100, cellAttributes: { class: { fieldName: 'cls_status' } }},
        { label: 'ebay-Artikelnummer', fieldName: 'Item_ID__c', type: 'text', initialWidth: 300},
        { label: 'Artikelbezeichnung', fieldName: 'Item_Title__c', type: 'text'},
    ];

    //SB 22.11.2022 US-0012026 - [FR] Localization for Item Upload template file
    @track frCols = [
        { label: '', fieldName: 'row_number', type: 'number', initialWidth: 100},
        { label: 'Status', fieldName: 'status', type: 'text',wrapText: true, initialWidth: 100, cellAttributes: { class: { fieldName: 'cls_status' } }},
        { label: 'Numero d\'objet eBay', fieldName: 'Item_ID__c', type: 'text', initialWidth: 300},
        { label: 'Nom de l\'objet eBay', fieldName: 'Item_Title__c', type: 'text'},
    ];

    //SB 23.11.2022 US-0012030 - [IT] Localization for Item Upload template file
    //SB 25.04.2023 US-0013527 - [IT] Champion Testing Fixes
    @track itCols = [
        { label: '', fieldName: 'row_number', type: 'number', initialWidth: 100},
        { label: 'Status', fieldName: 'status', type: 'text',wrapText: true, initialWidth: 100, cellAttributes: { class: { fieldName: 'cls_status' } }},
        { label: 'ID prodotto eBay', fieldName: 'Item_ID__c', type: 'text', initialWidth: 300},
        { label: 'Titolo prodotto eBay', fieldName: 'Item_Title__c', type: 'text'},
    ];

    //NK:24/11/2022:US-0012035
    @track ukCols = [
        { label: '', fieldName: 'row_number', type: 'number', initialWidth: 100},
        { label: 'Status', fieldName: 'status', type: 'text',wrapText: true, initialWidth: 100, cellAttributes: { class: { fieldName: 'cls_status' } }},
        { label: 'eBay Item ID', fieldName: 'Item_ID__c', type: 'text', initialWidth: 300},
        { label: 'eBay Item Title', fieldName: 'Item_Title__c', type: 'text'}
    ];

    //SB 22.2.2023 US-0012548
    @track auCols = [
        { label: '', fieldName: 'row_number', type: 'number', initialWidth: 100},
        { label: 'Status', fieldName: 'status', type: 'text',wrapText: true, initialWidth: 100, cellAttributes: { class: { fieldName: 'cls_status' } }},
        { label: 'eBay Item ID', fieldName: 'Item_ID__c', type: 'text', initialWidth: 300},
        { label: 'eBay Item Title', fieldName: 'Item_Title__c', type: 'text'},
    ];

    //Variables
    Labels = { btn_preview, btn_submit,btn_submit2, btn_downloadSampleFile, btn_cancel, txt_rownum, txt_totalrecord, next, prev,label_CS_DownloadSample,INFORMATION, COUPON_UPLOAD_ITEM_FOLLOWING_RECORDS_CREATED_REASONS,btn_back}; //coInvest_success_message
    

    @track requiredDealFields = ['Item_ID__c', 'Item_Title__c'];

    @track ignoreFields = ['Item_Title__c']; //MN-07102022-US-0012620

    @track validateFormatFields = ['Item_ID__c', 'Item_Title__c'];

    lbInputFile = "";
    file;
    fileContent;
    fileReader;
    message = "";

    uploadedSuccess = false; //MN-10062022-US-0011863

    //GET Methods
    get onShowLoadingSpinner() {
        return this.showLoadingSpinner;
    }

    get disableNextBtn(){
        return (this.isNoFile || this.isDisableNextBtn);
    }
    get disableSubmitBtn() {
        return (this.isReachLimit || this.cpItems.length == 0 || this.isSomeError);
    }

    get disableUploadFile(){
        return this.isUnableUpload;
    }

    get showMessageResults() {
        var messageErrors = [];
        var totalSuccess = 0;
        var totalFail = 0;

        for(var i =0; i < this.allMessageInfo.length; i++){
            var obj = this.allMessageInfo[i];
            if(obj["cls_status"] == "cls_error") {
                messageErrors.push(obj["message"]);
                totalFail++;
            } else  totalSuccess++;
        }

        this.objMessageResult["isHasSuccess"] = (messageErrors.length == 0);
        this.objMessageResult["totalSuccess"] = totalSuccess;
        this.objMessageResult["totalFail"] = totalFail;

        this.objMessageResult["isHasError"] = (messageErrors.length > 0);
        this.objMessageResult["lstError"] = messageErrors;
        return this.objMessageResult;
    }

    get isShowTable(){
        return this.data.length > 0;
    }

    get totalRecord() {
        return this.totalRec;
    }
    
    get jsonData(){
        // return this.data; 
        return this.mAllRecords[this.currentPage]; //MN-15062022-US-0011863-Pagination
    }

    get allObjMessageInfos(){
        return this.objMessageInfos;
    }

    renderedCallback() {
        if(!this.parserInitialized){
            loadScript(this, PapaParse)
                .then(() => {
                    this.parserInitialized = true;
                    
                })
                .catch(error => console.error(error.message));
        }
    }

    //General Methods
    connectedCallback() {

        this.subscribeToMessageChannel(); //MN-10062022- to refresh handler that called from external lwc using pub/sub messageChannel

        // this.getCouponSeller();
        this.doMapErrorMessages();
        this.doLoadCouponUploadItems();
        // console.log('CouponId ::::', this.couponId);
        
        
    }

    //MN-20062022-US-0011863
    @api hideSuccessMessage() {
        
        this.uploadedSuccess = false;
    }

    //MN-10062022-US-0011863
    @wire(MessageContext)
    messageContext;
    subscribeToMessageChannel() {
        this.subscription = subscribe(
        this.messageContext,
        LWC_CONNECTION_CHANNEL,
        (message) => this.handleMessage(message)
        );
    }

    //MN-10062022-US-0011863
    handleMessage(message) {
        // console.log('***** pub/sub message channel :: ', message);
        if(message.action == 'refresh') {
            this.doLoadCouponUploadItems();
        }
      }

    doLoadCouponUploadItems(){
        doLoadCouponUploadItems({couponSellerId: this.recId})
        .then(result => {
            // this.objMessageInfos = [];
            var msg = "";
            var objMsgInfo;
            if(result["status"] == "success"){
                this.currUserProfileName = result["currUserProfileName"];
                this.couponCoInvestCount = result["couponCoInvestCount"];
                this.couponCoInvestItemIds = result["couponCoInvestItemIds"];
                this.maxCoinvestPerCoupon = result["maxCoinvestPerCoupon"] ? result["maxCoinvestPerCoupon"] : this.maxCoinvestPerCoupon; // 09.06.2023 / Sophal Noch / US-0013666
                
                this.uploadSizeAvailability_Message = uploadSizeAvailability_Message; //MN-10062022-Fixed incorrect recalculate upload limit amount.

                this.isDE = result.isDE;
                this.isNA = result.isNA;
                this.isAU = result.isAU;
                this.isFR = result.isFR;//SB 22.11.2022 US-0012026 - [FR] Localization for Item Upload template file
                this.isIT = result.isIT;//SB 22.11.2022 US-0012030 - [IT] Localization for Item Upload template file
                this.isUK = result.isUK;//NK:24/11/2022:US-0012035
                this.isMainSiteUK = result.isMainSiteUK;
                // if(this.couponCoInvestCount >= MAX_COINVEST_PER_COUPON) {
                if(this.couponCoInvestCount >= this.maxCoinvestPerCoupon) { // 09.06.2023 / Sophal Noch / US-0013666
                    // this.isReachLimit = true;
                    this.isUnableUpload = true;
                    this.uploadSizeAvailability_Message = uploadSizeAvailability_Message.replace(" X ", " 0 ");
                }else{
                    // AC10: Given the seller is looking at the Upload Items sub-tab on the coupon detail view
                    // this.uploadSizeAvailability_Message = this.uploadSizeAvailability_Message.replace(" X ", " "+(MAX_COINVEST_PER_COUPON - this.couponCoInvestCount)+" ");
                    this.uploadSizeAvailability_Message = this.uploadSizeAvailability_Message.replace(" X ", " "+(this.maxCoinvestPerCoupon - this.couponCoInvestCount)+" ");

                } 
            }else {
                // this.isReachLimit = true;
                msg = result["message"];
                objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
                this.objMessageInfos.push(objMsgInfo);
            }
        })
        .catch(error => { 
            console.log("first load ERROR::", error);
        }); 
    }
    
    doMapErrorMessages(){
        // US-0010660 AC1: column Item ID not empty
        this.mapErrorMessages["Item_ID__c-Required"] = COUPON_UPLOAD_ITEM_REQUIRED_FIELD_ITEM_ID;
        // US-0010660 AC2: column Item Title not empty
        this.mapErrorMessages["Item_Title__c-Required"] = COUPON_UPLOAD_ITEM_REQUIRED_FIELD_ITEM_TITLE;

        // US-0010660 AC5: Avoid wrong format on the Item ID
        this.mapErrorMessages["Item_ID__c-Incorrect"] = ITEM_ID_MAXIMUM_CHAR_AND_DIGIT_IS_NUMERIC;
        // US-0010660 AC6: Item Title must be no more than 80 characters
        this.mapErrorMessages["Item_Title__c-Incorrect"] = ITEM_TITLE_MAXIMUM_CHARACTERS;
    }

    
    csCouponType = '';
    listCSFields = ['Coupon_Seller__c.Coupon__c', 'Coupon_Seller__c.Seller__c','Coupon_Seller__c.SellerShareHolder__c'
                    ,'Coupon_Seller__c.CurrencyIsoCode','Coupon_Seller__c.Coupon_Type__c']; 
    @wire(getRecord, { recordId: '$recId', fields: '$listCSFields' } )
    getCouponSeller({error, data}){
        if(data){
            this.csObj = data;
            this.csCouponType = data.fields["Coupon_Type__c"].value;
        }
    }

    handleFilesChange(event) {
        this.isShowMessage = false;
        this.objMessageInfos = [];
        this.allMessageInfo = [];
        this.objMessageResult = {};
        this.data = [];
        this.deals = [];
        if(event.target.files.length > 0) {
            
            this.isNoFile = false;
            this.isDisableNextBtn = false;
            
            this.file = event.target.files[0];
            this.fileName = event.target.files[0].name;
        }
        
        //TH-02112022-US-0012494
        this.handleClickUpload();
        this.currentStep++;
    }

    get isStep1(){
        return this.currentStep == 1;
    }

    get isStep2(){
        return this.currentStep == 2;
    }

    get isStep3(){
        return this.currentStep == 3;
    }

    handleBack() {
        this.currentStep--;
        this.fileName = "";
    }
    handleBackToFirstStep() {
        this.currentStep = 1;
    }
    handleCancel(){
        setTimeout(() => {
            //SRONG TIN - 18.02.2025 - US-0015819 LWS - Upload Components (deal/coupon item)
            //eval("$A.get('e.force:refreshView').fire();");
            this.dispatchEvent(new CustomEvent('tab1'));

        }, 100); 
    }

 

    handleClickUpload(){
         
        try{
            this.showLoadingSpinner = true;
            this.isShowMessage = false;
            let self = this;
            //TH:US-0012014:Verify csv file format
            if(!this.file.name.toLowerCase().endsWith(".csv")){
                self.showLoadingSpinner = false;
                var msg = INVALID_CSV_FORMAT;
                var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : msg};
                self.objMessageInfos.push(objMsgInfo);
                return;
            }
            var reader = new FileReader();
            reader.readAsText(this.file, "UTF-8");
            reader.onload = function(evt) {
                try{
                    self.fileContent =  evt.target.result != null ? evt.target.result.trim() : '';
                    if(self.fileContent) {
                        Papa.parse(self.fileContent, {
                            //NK:22/08/2024:US-0015738 - worker set to false. LWS prevents script creates worker
                            // worker: true, // Handle big file
                            worker: false,  
                            //delimiter: this.selectedSeperator,//TH:US-0012014:comment out selectedSeperator
                            header: false,
                            skipEmptyLines: true,
                            complete: (results) => {
                                //console.log('result:', results)
                                //TH:US-0012014:comment out selectedSeperator
                                /*if(results.meta.delimiter == self.selectedSeperator){
                                    self._rows = results.data;
                                    self.csvReader();
                                }else{
                                    self.showLoadingSpinner = false;
                                    var msg = INVALID_CSV_FORMAT;
                                    var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : msg};
                                    self.objMessageInfos.push(objMsgInfo);
                                }*/
                                self._rows = results.data;
                                self.csvReader();
                            },
                            error: (error) => {
                                console.error('error::', error.message);
                            }
                        })
                    }
                }catch(ex2)
                {
                    console.error('Error in handleClickUpload:2:', ex2.message);
                }


                
            }
        }catch(ex)
        {
            console.error('Error in handleClickUpload::', ex.message);
        }
        
    }

    csvReader(){
        try{
            this.isDisableNextBtn = true;
            this.isShowMessage = false;
            this.isSomeError = false;
            this.allMessageInfo = [];
            this.mRowIndex = {};
            var duplicateRows = [];
            var duplicateItemIds = [];
            var cItemIds = [];
            this.totalRec = 0;
            this.isSomeFail = false;
            // var allTextLines = this.CSVToArray(); DEPRECIATED
            var allTextLines = this._rows;

            //MN-10102022-US-0012620
            // var cols = this.currUserProfileName == 'DE - Seller Portal' ? this.germanCols : this.defaulCols;
            var cols = this.defaulCols;

            if (this.isDE) cols = this.germanCols;
            else if (this.isNA) cols = this.naCols;
            else if (this.isFR) cols = this.frCols;//SB 22.11.2022 US-0012026 - [FR] Localization for Item Upload template file
            else if (this.isIT) cols = this.itCols;//SB 22.11.2022 US-0012030 - [IT] Localization for Item Upload template file
            else if (this.isUK) cols = this.ukCols;//NK:24/11/2022:US-0012035
            else if (this.isAU) cols = this.auCols;//SB 22.2.2023 US-0012548
            
            //----MN-10102022-US-0012620

            var tempData = [];
            var tempCPCI = [];

            var index = 0;
            var tempMIndex = {};
            var rowNumber = 0;
            var rowT = 0;
            // var mAllRowNumber = {};
            this.isReachLimit = false;

            for(var i = 1; i < allTextLines.length; i++) {

                rowNumber++;
                rowT++;
                var msg = "";
                var msgNumeric = "";
                var rowIncomplete = false;
                var isValueInvalidFormat = false;
                this.isInvalidFormat = false;

                var allCols = allTextLines[i];
                let cpCoInvest = { "sobjectType": "Coupon_Co_Invest__c" };
                var row = {};
                row["id"] = i;

                var isRowEmpty = true;
                for(var x= 0; x < allCols.length; x++) {
                    var colName = cols[x+2].fieldName;
                    if(colName == "status" || colName == "row_number") continue;
                    
                    var val = allCols[x]? allCols[x] : "";
                    // US-0010660 - AC8: Empty rows should be ignored
                    if(val != undefined && val != "" && val != " ") {
                        isRowEmpty = false;
                    }
                    row[colName] = val;
                    cpCoInvest[colName] = val;

                    if(row[colName] == "" && this.requiredDealFields.includes(colName)){
                        //NK:24/02/2023:US-0013150 - added isFR
                        if ((!this.isNA && !this.isMainSiteUK && !this.isFR) || !this.ignoreFields.includes(colName)) { //MN-07102022-US-0012620

                            msgNumeric += (msgNumeric==""? "" :", ") + this.mapErrorMessages[colName+"-Required"];
                            rowIncomplete = true;
                            continue;
                        }

                        
                    }
                    if(this.validateFormatFields.includes(colName)){
                        var validateMesg = this.doValidateFormatFields(val, colName);
                        if(validateMesg != "") msgNumeric += (msgNumeric==""? "" :", ") + validateMesg;
                        isValueInvalidFormat = this.isInvalidFormat;
                    }
                }

                var strRow = (allTextLines[i]).join();

                if (allTextLines[i][0] != "" && (duplicateRows.includes(strRow) || isRowEmpty)){
                    if(!duplicateRows.includes(strRow)) duplicateRows.push(strRow);
                    rowT--;
                    rowNumber--;
                    continue;
                }

                //Check if row is empty
                if (isRowEmpty){
                    rowT--;
                    rowNumber--;
                    continue;
                }

                row["row_number"] = rowNumber;
                var itemId = allTextLines[i][0];
                var objMsg = {"row_number" : i};
                this.allMessageInfo.push(objMsg);

                if(rowIncomplete || isValueInvalidFormat){
                    
                    var errorMsg = "";
                    errorMsg = msgNumeric;
                    row["status"] = errorMsg;
                    row["cls_status"] = "cls_error";
                    this.isSomeError = true;
                    objMsg["cls_status"] = "cls_error";
                    objMsg["message"] = "- " + this.Labels.txt_rownum  + " " + rowNumber +". "+errorMsg;
                    tempData.push(row);
                    continue;
                }
                
                // AC4: Avoid duplicate Item IDs against the Coupon record
                if(itemId != "" && this.couponCoInvestItemIds.includes(itemId)){
                    msg = MSG_DUPLICATE_ITEM_ID_AGAINST_ORG;
                    row["status"] = msg;
                    row["cls_status"] = "cls_error";
                    this.isSomeError = true;

                    objMsg["cls_status"] = "cls_error";
                    objMsg["message"] = "- " + this.Labels.txt_rownum  + " "+rowNumber+". "+ msg;
                    tempData.push(row);
                    continue;
                }
                // US-0010660 - AC3: Avoid duplicate Item IDs within the csv file
                else if(itemId != "" &&  cItemIds.includes(itemId)) {
                    if(!duplicateItemIds.includes(itemId)) duplicateItemIds.push(itemId);

                    msg = DUPLICATE_DATA;
                    row["status"] = msg;
                    row["cls_status"] = "cls_error";
                    this.isSomeError = true;

                    objMsg["cls_status"] = "cls_error";
                    objMsg["message"] = "- " + this.Labels.txt_rownum  + " "+rowNumber+". "+ msg;
                    tempData.push(row);
                    continue;
                }else {
                    cItemIds.push(itemId);
                    duplicateRows.push(strRow);
                    msg = READY_TO_UPLOAD; //AC11: Ready for upload
                    row["status"] = msg;
                    row["cls_status"] = "cls_success";

                    objMsg["cls_status"] = "cls_success";
                    objMsg["message"] = msg;
                    tempMIndex[index] = rowT-1;
                    
                    index++;
                }

                //Assigned value into draft Coupon Co-Invest record that not defined in CSV file
                cpCoInvest["Coupon_Seller__c"] = this.recId;
                cpCoInvest["Seller_Name__c"] = this.csObj.fields["Seller__c"].value;
                cpCoInvest["Co_Invest__c"] = this.csObj.fields["SellerShareHolder__c"].value;
                cpCoInvest["CurrencyIsoCode"] = this.csObj.fields["CurrencyIsoCode"].value;
                
                // US-0010660 - AC12: Auto populate coupon fields
                cpCoInvest["Coupon_Name__c"] = this.csObj.fields["Coupon__c"].value;

                tempData.push(row);
                tempCPCI.push(cpCoInvest);
            }

            // US-0010660 - AC3: Avoid duplicate Item IDs within the csv file 
            // Check all the rows again
            for(var i=0; i < tempData.length; i++) {
                var itemId = tempData[i]["Item_ID__c"];
                if(duplicateItemIds.includes(itemId) && tempData[i]["status"] != DUPLICATE_DATA){
                    tempData[i]["cls_status"] = "cls_error";
                    var errMsg = DUPLICATE_DATA;
                    tempData[i]["status"] = errMsg;
                    var objMsg1 = {"row_number": 1};
                    objMsg1["cls_status"] = "cls_error";
                    objMsg1["message"] = "- " + this.Labels.txt_rownum + " "+(i+1)+". "+ errMsg;
                
                    this.allMessageInfo[i] = objMsg1;
                }
            }

            cols[1]["initialWidth"] = this.isSomeError ? 360 : 140;
            var tCPCI = [];
            var idx = 0;
            for(var i = 0; i < tempCPCI.length; i++){
                var ebayId = tempCPCI[i]["Item_ID__c"];
                if(!duplicateItemIds.includes(ebayId) && !this.couponCoInvestItemIds.includes(ebayId)){
                    tCPCI.push(tempCPCI[i]);
                    this.mRowIndex[idx] = tempMIndex[i];
                    idx++;
                }
            }
            this.showLoadingSpinner = false;
            this.data = tempData;
            this.totalRec = tempData.length;
            this.columns = cols;
            this.cpItems = tCPCI;

            this.currentPage = 1; //MN-14062022-US-0011863-Pagination
            this.listRecord = this.data; //MN-14062022-US-0011863-Pagination
            this.onAssignRecords(); //MN-14062022-US-0011863-Pagination

            // AC9: Item Count validation 
            // if((tCPCI.length + this.couponCoInvestCount) > MAX_COINVEST_PER_COUPON){
            if((tCPCI.length + this.couponCoInvestCount) > this.maxCoinvestPerCoupon){ // 09.06.2023 / Sophal Noch / US-0013666
                
                this.isReachLimit = true;
                // var msg = MSG_MAXIMUM_NUMBER_OF_ITEMS_FOR_COUPON_UPLOAD.replace("#MAX#", MAX_COINVEST_PER_COUPON);
                var msg = MSG_MAXIMUM_NUMBER_OF_ITEMS_FOR_COUPON_UPLOAD.replace("#MAX#", this.maxCoinvestPerCoupon); // 09.06.2023 / Sophal Noch / US-0013666
                // msg = msg.replace(" X ", " "+(MAX_COINVEST_PER_COUPON - this.couponCoInvestCount)+ " ");
                msg = msg.replace(" X ", " "+(this.maxCoinvestPerCoupon - this.couponCoInvestCount)+ " "); // 09.06.2023 / Sophal Noch / US-0013666
                var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : msg};
                this.objMessageInfos.push(objMsgInfo);
            }

        } catch( err ) {
            
            console.log('***** err :: ', err.message);
            this.showLoadingSpinner = false;
            var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : err.message};
            this.objMessageInfos.push(objMsgInfo);
        }

    }

    // DEPRECIATED
    // CSVToArray() {
    //     var objPattern = new RegExp(("(\\" + this.selectedSeperator + "|\\r?\\n|\\r|^)" +"(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" + "([^\"\\" + this.selectedSeperator + "\\r\\n]*))"), "gi");
    //     var arrData = [[]];
    //     var arrMatches = null;
    //     while (arrMatches = objPattern.exec(this.fileContent)) {
    //         var strMatchedDelimiter = arrMatches[1];
    //         if (strMatchedDelimiter.length && (strMatchedDelimiter != this.selectedSeperator)) {
    //             arrData.push([]);
    //         }
    //         if (arrMatches[2]) {
    //             var strMatchedValue = arrMatches[2].replace(new RegExp("\"\"", "g"), "\"");
    //         } else {
    //             var strMatchedValue = arrMatches[3];
    //         } 
    //         arrData[arrData.length - 1].push(strMatchedValue);
    //     }
    //     return (arrData);
    // }

    validateHeader(csvHeader, csvTemplate){
        var error = false;
        var csvTemplateArray = csvTemplate.split(',');
        if(csvHeader.length == csvTemplateArray.length){
            for(var i = 0; i<csvTemplateArray.length; i++){
                if(!csvHeader[i].startsWith(csvTemplateArray[i].substring(0,3))){
                    error = true;
                }
            }
        } else {
            error = true;
        }
        return error ? false : true;
    }

    handleClickSubmit() {

        this.showLoadingSpinner = true;
        this.cpItemsComplete = [];
        this.cpItemsSaveResult = [];
        this.objMessageResult = {};
        this.objMessageInfos = []; 
        this.isSomeFail = false;
        this.message = "";
        this.currentStep++;
        this.onProccessUpload(this.cpItems);
    }

    onProccessUpload(lstCPItems){
        // chunk list of coupon co-invest to small size for pass into apex
        var arrAllCPI = this.chunkArray(lstCPItems, this.numberOfCPItemsPerPk);
        this.onSubmitMultipleCPItems(arrAllCPI, 0, arrAllCPI.length);
    }

    onSubmitMultipleCPItems(arrAllCPI, index, total){
        if( index < total && arrAllCPI[index]){ 
            doSubmitMultipleCPItems({lstCPItems: arrAllCPI[index], csCouponType: this.csCouponType})
            .then(result => {
                index++;
                if(result['status'] == 'success'){
                    var srList = result["srList"];
                    this.cpItemsSaveResult = this.cpItemsSaveResult.concat(JSON.parse(srList));
                    if(result["lstCPItems"]){
                        this.cpItemsComplete = this.cpItemsComplete.concat(result["lstCPItems"]);
                    }
                    else {
                        this.isSomeFail = true;
                        this.message = result['message'];
                    }
                }
                if (index < total) {
                    this.onSubmitMultipleCPItems(arrAllCPI, index, total);
                }
                // Final round
                else if(!this.isSomeFail && index == total){
                    this.onUpdateStatus();
                }

            })
            .catch(error => {
                this.isSomeFail = true;
                this.message = (error["body"] != undefined? error.body.message : error);
                var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : this.message};
                this.objMessageInfos.push(objMsgInfo);
                this.cpItemsComplete = [];
                this.isSomeFail = false;
                this.message = "";
                this.showLoadingSpinner = false;
                console.log('Error:'+this.message);
            });  
        }
    }

    //TH:US-0012494 - update Coupon seller stage to review
    @track isSuccess = false;
    doUpdateCSStage(){
        this.showLoadingSpinner = true;
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recId;
        fields[STAGE_FIELD.fieldApiName] = 'Review';
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: thank_You_message,
                        variant: 'success'
                    })
                );
                
                this.isSuccess = true;
                const custEvent = new CustomEvent(
                    "viewcoinvest", {detail: this.isSuccess});
                this.dispatchEvent(custEvent);
                this.showLoadingSpinner = false;
                /*setTimeout(() => {
                    eval("$A.get('e.force:refreshView').fire();");
                }, 100);*/
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error on data save',
                        //message: error.body.message,
                        message: error.body.output.errors[0].errorCode + ' - '+error.body.output.errors[0].message,
                        variant: 'error',
                    }),
                );
                this.showLoadingSpinner = false;
            });
    }

    onUpdateStatus() {
        this.isShowMessage = true;
        this.data = [];
        this.objMessageInfos = []; 
        this.fileName = "";
        this.showLoadingSpinner = false;

        var allSaveResult = this.cpItemsSaveResult;
        var isHasError = false;
        for(var i = 0; i < allSaveResult.length; i++){
            var index = this.mRowIndex[i];
            if(allSaveResult[i]["success"] == false) {
                isHasError = true;
                this.isSomeError = true;
                this.allMessageInfo[index]["cls_status"] = "cls_error";
                var msg = "";
                var errors = allSaveResult[i]["errors"];
                for(var x = 0; x < errors.length; x++){
                    msg += (msg==""? "":", ") + errors[x]["message"];
                }
                this.allMessageInfo[index]["message"] = "- " + this.Labels.txt_rownum  + " "+(index+1)+". "+msg+"\n";
            }      
        }

        this.doLoadCouponUploadItems();

        const custEvent = new CustomEvent(
            "reloadlistview", {});
        this.dispatchEvent(custEvent);

        this.uploadedSuccess = true; //MN-10062022-US-0011863
        //TH:03.11.2022:US-0012494 - toast message success
        if(!isHasError){
            this.doUpdateCSStage();
        }

        // Reload limitation upload size
        

        // eval("$A.get('e.force:refreshView').fire();");
    }

    chunkArray(myArray, chunk_size){
        var results = [];
    
        while (myArray.length) {
            results.push(myArray.splice(0, chunk_size));
        }
        
        return results;
    }
    
    // SB 20.5.2022 US-0010659 - Template for item upload available to seller
    //30-08-2022/vadhanak/US-0012297
    doDownloadCSVTemplate(){
        
        let downloadElement = document.createElement('a');
        // if(this.currUserProfileName == 'DE - Seller Portal'){
        //     downloadElement.href = bulkUploadCouponItemsTemplateDE; 
        //     // CSV File Name
        //     downloadElement.download = "Vorlage zum Hochladen von Artikel.csv"; 
        // }else{//TH:US-0012014
        //     downloadElement.href = bulkUploadCouponItemsTemplateNA; 
        //     // CSV File Name
        //     downloadElement.download = "Template for Item Upload.csv"; 
        // }
        if(this.isDE)
        {
            downloadElement.href = bulkUploadCouponItemsTemplateDE; 
             
        }else if(this.isNA)
        {
            downloadElement.href = bulkUploadCouponItemsTemplateNA; 
        } 
        else if(this.isAU){//SB 22.2.2023 US-0012548
            downloadElement.href = bulkUploadCouponItemsTemplateAU; 
        }
        //SB 22.11.2022 US-0012026 - [FR] Localization for Item Upload template file
        else if(this.isFR){
            downloadElement.href = bulkUploadCouponItemsTemplateFR;
        }
        //SB 23.11.2022 US-0012030 - [IT] Localization for Item Upload template file
        else if(this.isIT){
            downloadElement.href = bulkUploadCouponItemsTemplateIT;
        }
        //NK:24/11/2022:US-0012035
        else if(this.isUK)
        {
            downloadElement.href = bulkUploadCouponItemsTemplateUK;
        }

        downloadElement.download = this.Labels.label_CS_DownloadSample;

        downloadElement.target = '_self';
        // below statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click(); 
        
    }

    doValidateFormatFields(val, colName){
        var tempMsg = "";
        var isValNumeric = this.isNumeric(val);

        // US-0010660 AC5: Avoid wrong format on the Item ID
        if(colName == "Item_ID__c" && val != ""){
            if(!isValNumeric || val.length != 12) {
                tempMsg = this.mapErrorMessages["Item_ID__c-Incorrect"];
                this.isInvalidFormat = true;
            }
        }else if(colName == "Item_Title__c" && val != ""){
            if(val.length > 80) {
                tempMsg = this.mapErrorMessages["Item_Title__c-Incorrect"];
                this.isInvalidFormat = true;
            }
        }
        return tempMsg;
    }

    // Utils
    isNumeric(val) {
        return /^-?[\d.]+(?:e-?\d+)?$/.test(val);
    }

    //MN-14062022-US-0011863-Pagination
    @track allRecords = [];
    @track mAllRecords = {}
    @api listRecord = [];
    @track numberOfRecordPerPage=50;
    @track totalPage = 0;
    @track currentPage = 1;

    onAssignRecords(){
        this.mAllRecords = {};
        var allRecord = [];
        var numPage = 0;
        var index = 0;
        for(var i =0; i< this.listRecord.length; i++){
            var obj = this.listRecord[i]; //{"is_Checked" : false, "index" : i, "id" : i,"EBH_ProductTitle__c" : "Test-"+i, "EBH_Status__c" : "PENDING", "EBH_DealStartDate__c" : Date.now(),"EBH_eBayLink__c" : "122345"+i,  "EBH_DealEndDate__c" : Date.now(), "EBH_Quantity__c" : 123, "EBH_SoldItems__c" : "1234","EBH_Category__c" : "Home Electronics"};
            
            obj["index"] = index;
            allRecord.push(obj);
            index++;
            if(allRecord.length == this.numberOfRecordPerPage){
                numPage++;
                this.mAllRecords[numPage] = allRecord;
                allRecord = [];
                index = 0;
            }
        }
        if(allRecord.length > 0){
            numPage++;
            this.mAllRecords[numPage] = allRecord;
        }

        this.totalPage = numPage;

        //MN-19052022-US-0010656
        if (this.currentPage > this.totalPage) this.currentPage=1;
        
        this.allRecords = (this.mAllRecords[this.currentPage]? this.mAllRecords[this.currentPage]:[]);

    }

    onPrevPage() {
        if(this.currentPage > 1) this.currentPage--;
    }

    onNextPage(){
        if(this.currentPage < this.totalPage) this.currentPage++;
    }

    onChangePage(evt) {
        
        var pageNumber = evt.target.dataset["id"];
        this.currentPage = pageNumber;

        //console.log('*** pageNumber :: ', pageNumber);
    }
    updateCurrentPage(event)
    {
        this.currentPage = event.detail.currentPage;
    }
    get displayPagination() {
        var arrPage = [];
        for(var i =1; i<= this.totalPage; i++){
            var objP = {value : i, clsActive : (this.currentPage == i?"active":"")};
            arrPage.push(objP);
        }
        return arrPage;
    }
}