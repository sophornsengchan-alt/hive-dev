/*********************************************************************************************************************************
@ Class:          LwcDealBulkUploadDCA
@ Version:        1.0
@ Author:         sovantheany dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0012281 - Validation and upload of Deals
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06-09-2022 / sovantheany dim / Created the class.
@ Change history: 07-10-2022 / sovantheany dim / US-0012741 - New column to upload Deals to Deal Contract Agreement    
@ Change history: 28-10-2022 / Chetra Sarom / US-0012778 - Upload Items Validations  
@                 04/04/2023 / Sovantheany dim / US-0013466 - Validation of PM Deals check duing upload    
@               : 02-11-2023 / Sambath Seng / US-0014309 - PM Deals "Quantity" to be mapped with Max purchases
@               : 17-01-2024 / Sambath Seng / US-0014528 - NA Region (US) Increase character limit on Product title field
@               : 22.08.2024 / vadhanak voun / US-0015738 - Upload Components (deal/coupon item) not working due to LWS
@               : 18.02.2025 / SRONG TIN / US-0015819 LWS - Upload Components (deal/coupon item)+
@               : 12.05.2025 / Vadhanak voun / US-0026069 - PM Deals Submission Limit - Seller Portal
*********************************************************************************************************************************/

import { LightningElement, api, track,wire } from 'lwc';

import PapaParse from '@salesforce/resourceUrl/PapaParse';
import { loadScript } from 'lightning/platformResourceLoader';

import { subscribe, MessageContext } from 'lightning/messageService';
import LWC_CONNECTION_CHANNEL from '@salesforce/messageChannel/LWC_Connection__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import {getRecord, updateRecord} from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/Deal_Contract_Agreement__c.Id';
import STATUS_FIELD from '@salesforce/schema/Deal_Contract_Agreement__c.Status__c';


import doLoadDCAUploadDeal from '@salesforce/apex/ClsBulkUploadCSV.doLoadDCAUploadDeal';
import doSubmitMultipleDealsForDCA from '@salesforce/apex/ClsBulkUploadCSV.doSubmitMultipleDealsForDCA';

//import uploadSizeAvailability_Message from '@salesforce/label/c.Deal_Upload_Size_Availability_Message';
import btn_next from '@salesforce/label/c.EBH_Next';
import btn_submit from '@salesforce/label/c.Label_Submit_button';
import btn_downloadSampleFile from '@salesforce/label/c.CouponUploadItems_DownloadCSVSampleFile';
import txt_rownum from '@salesforce/label/c.Row_Number';
import txt_totalrecord from '@salesforce/label/c.CouponUploadItems_TotalRecord';
import prev from '@salesforce/label/c.Previous';
import next from '@salesforce/label/c.Next';
import label_DCA_DownloadSample from '@salesforce/label/c.Label_DCA_DownloadSample';
import COUPON_UPLOAD_ITEM_REQUIRED_FIELD_ITEM_ID from '@salesforce/label/c.COUPON_UPLOAD_ITEM_REQUIRED_FIELD_ITEM_ID';
import COUPON_UPLOAD_ITEM_REQUIRED_FIELD_ITEM_TITLE from '@salesforce/label/c.COUPON_UPLOAD_ITEM_REQUIRED_FIELD_ITEM_TITLE';
import LWCBulkUploadCSVError27 from '@salesforce/label/c.LWCBulkUploadCSVError27';
import LWCBulkUploadCSVError25 from '@salesforce/label/c.LWCBulkUploadCSVError25';
import ITEM_ID_MAXIMUM_CHAR_AND_DIGIT_IS_NUMERIC from '@salesforce/label/c.LWCBulkUploadCSVError4';
import Quantity_Limit from '@salesforce/label/c.Quantity_Limit';
import INVALID_CSV_FORMAT from '@salesforce/label/c.INVALID_CSV_FORMAT';
// import DUPLICATE_DATA from '@salesforce/label/c.DUPLICATE_DATA';
import Duplicate_Entry_msg from '@salesforce/label/c.Duplicate_Entry_msg';
// import MSG_DUPLICATE_DEAL_ITEM_ID_AGAINST_ORG from '@salesforce/label/c.MSG_DUPLICATE_DEAL_ITEM_ID_AGAINST_ORG';
import READY_TO_UPLOAD from '@salesforce/label/c.READY_TO_UPLOAD';
//import MAX_DEAL_PER_DCA from '@salesforce/label/c.MAX_DEAL_PER_DCA';
//import MSG_MAX_ITEMS_FOR_DEAL_UPLOAD from '@salesforce/label/c.MSG_MAX_ITEMS_FOR_DEAL_UPLOAD';
import LWCBulkUploadCSVError26 from '@salesforce/label/c.LWCBulkUploadCSVError26';
import LWCBulkUploadCSVError43 from '@salesforce/label/c.LWCBulkUploadCSVError43';
import LWCBulkUploadCSVError47 from '@salesforce/label/c.LWCBulkUploadCSVError47';
import DealRecordsCreatedPartSuccess from '@salesforce/label/c.DealRecordsCreatedPartSuccess';
import LWCBulkUploadCSVError15 from '@salesforce/label/c.LWCBulkUploadCSVError15';
//import Fail_To_Update_DCA from '@salesforce/label/c.Fail_To_Update_DCA';
import submitForReview from '@salesforce/label/c.Submit_For_Review';
import LWCBulkUploadCSVError3 from '@salesforce/label/c.LWCBulkUploadCSVError3';
import RRP_Price_Msg_Error from '@salesforce/label/c.RRP_Price_Msg_Error'; // TH: US-0012741 :07/10/2022
//import SEP_DCA_UploadDeals_Info from '@salesforce/label/c.SEP_DCA_UploadDeals_Info'; // CS 28-10-2022 / Chetra Sarom / US-0012778 - Upload Items Validations 
import COUPON_UPLOAD_ITEM_INVALID_FORMAT_SELLER_PRICE from '@salesforce/label/c.COUPON_UPLOAD_ITEM_INVALID_FORMAT_SELLER_PRICE'; // CS 28-10-2022 / Chetra Sarom / US-0012778 - Upload Items Validations 
import COUPON_UPLOAD_ITEM_INVALID_FORMAT_QUANTITY_LIMIT from '@salesforce/label/c.COUPON_UPLOAD_ITEM_INVALID_FORMAT_QUANTITY_LIMIT'; // CS 28-10-2022 / Chetra Sarom / US-0012778 - Upload Items Validations 
// import COUPON_UPLOAD_ITEM_LIMIT_RECORDS_SUBMITTED from '@salesforce/label/c.COUPON_UPLOAD_ITEM_LIMIT_RECORDS_SUBMITTED'; // CS 28-10-2022 / Chetra Sarom / US-0012778 - Upload Items Validations
// SB 3.11.2022 US-0012877 - Simplify Item Upload Process for PM Deals
import uploadResult_Message from '@salesforce/label/c.Upload_Result_Fail';
import thank_You_message from '@salesforce/label/c.Thank_You_message';
import btn_cancel from '@salesforce/label/c.lwcCancelbtn';
import btn_back from '@salesforce/label/c.SEP_BACK_BUTTON';
import PM_Deal_Error_Reason from '@salesforce/label/c.PM_Deal_Error_Reason';
import SEP_DCA_UploadDeals_Info_Preview from '@salesforce/label/c.SEP_DCA_UploadDeals_Info_Preview';

import PMDeal_Info_UploadText1_DCA  from '@salesforce/label/c.PMDeal_Info_UploadText1_DCA';
import PMDeal_Info_UploadLimit_DCA  from '@salesforce/label/c.PMDeal_Info_UploadLimit_DCA';
import PMDeal_Info_CapTitle_DCA  from '@salesforce/label/c.PMDeal_Info_CapTitle_DCA';
import PMDeal_Error_UploadLimit_DCA  from '@salesforce/label/c.PMDeal_Error_UploadLimit_DCA';
import bulkUploadDCATemplateNA from '@salesforce/resourceUrl/SEP_Upload_Deal_For_Contract_Template_NA';

export default class LwcDealBulkUploadDCA extends LightningElement {
    @api recId;
    @api dealItems = [];
    @api dcaObj = {};
    @api listRecord = [];

    @track fileName = "";
    @track totalRec = 0;
    @track currentPage = 1;
    @track totalPage = 0;
    @track mAllRecords = {}
    @track columns = [];
    @track objMessageInfos = [];
    @track showLoadingSpinner = false;
    @track isUnableUpload = false;
    @track isShowMessage = false;
    @track allMessageInfo = [];
    @track isNoFile = true;
    @track isDisableNextBtn = true;
    @track isReachLimit = false;
    @track data = [];
    @track mapErrorMessages = {};
    @track isSomeError = false;
    @track mRowIndex = {};
    @track isSomeFail = false;
    @track isLimitRecordsSubmitted = false; // CS 28-10-2022 / Chetra Sarom / US-0012778 - Upload Items Validations
    @track _rows;
    //@track currUserProfileName = '';
    //@track dealItemIds = [];//TH: Comment out : US-0013466 
    @track numberOfRecordPerPage=10;
    @track allRecords = [];
    @track dealCount = 0;
    @track dealComplete = [];
    @track dealsSaveResult = [];
    @track objMessageResult = {};
    @api numberOfDealPerPk = 150;

    //NK:12/05/2025:US-0026069
    _DEFAULT_UPLOAD_LIMIT = 15000;
    @track uploadLimit = this._DEFAULT_UPLOAD_LIMIT; //default 15,000 if NULL limit from DCA
    @track selectedAccountId = '';

    @track defaulCols = [
        { label: '', fieldName: 'row_number', type: 'number', initialWidth: 100},
        { label: 'Status', fieldName: 'status', type: 'text',wrapText: true, initialWidth: 100, cellAttributes: { class: { fieldName: 'cls_status' } }},
        { label: 'eBay Item ID', fieldName: 'EBH_eBayItemID__c', type: 'text', initialWidth: 300},
        { label: 'Item Title', fieldName: 'EBH_ProductTitle__c', type: 'text'},
        { label: 'Seller Price', fieldName: 'EBH_SellerPrice__c', type: 'currency', initialWidth: 160, typeAttributes: { currencyCode: 'USD', step: '0.001'}},
        { label: 'RRP Price', fieldName: 'EBH_RRPWASPrice__c', type: 'currency', initialWidth: 160, typeAttributes: { currencyCode: 'USD', step: '0.001'}},
        //SB 2.11.2023 US-0014309 replace EBH_Quantity__c with EBH_MaximumPurchases__c
        // { label: 'Quantity Limit', fieldName: 'EBH_Quantity__c', type: 'number'},
        { label: 'Quantity Limit', fieldName: 'EBH_MaximumPurchases__c', type: 'number'},
    ];

    @track germanCols = [
        { label: '', fieldName: 'row_number', type: 'number', initialWidth: 100},
        { label: 'Status', fieldName: 'status', type: 'text',wrapText: true, initialWidth: 100, cellAttributes: { class: { fieldName: 'cls_status' } }},
        { label: 'ebay-Artikelnummer', fieldName: 'EBH_eBayItemID__c', type: 'text', initialWidth: 300},
        { label: 'Artikelbezeichnung', fieldName: 'EBH_ProductTitle__c', type: 'text'},
        { label: 'Ihr Preis', fieldName: 'EBH_SellerPrice__c', type: 'currency', initialWidth: 160, typeAttributes: { currencyCode: 'USD', step: '0.001'}},
        { label: 'RRP Preis', fieldName: 'EBH_RRPWASPrice__c', type: 'currency', initialWidth: 160, typeAttributes: { currencyCode: 'USD', step: '0.001'}},
        //SB 2.11.2023 US-0014309 replace EBH_Quantity__c with EBH_MaximumPurchases__c
        // { label: 'Stückzahl', fieldName: 'EBH_Quantity__c', type: 'number'},
        { label: 'Stückzahl', fieldName: 'EBH_MaximumPurchases__c', type: 'number'},
    ];

    //SB 2.11.2023 US-0014309 replace EBH_Quantity__c with EBH_MaximumPurchases__c
    @track requiredDealFields = ['EBH_eBayItemID__c', 'EBH_ProductTitle__c', 'EBH_SellerPrice__c', 'EBH_MaximumPurchases__c'];
    @track validateFormatFields = ['EBH_eBayItemID__c', 'EBH_MaximumPurchases__c','EBH_SellerPrice__c','EBH_RRPWASPrice__c']; 

    //@track uploadSizeAvailability_Message = uploadSizeAvailability_Message;
    Labels = { btn_next, btn_submit, btn_downloadSampleFile,txt_rownum, txt_totalrecord, next, prev,label_DCA_DownloadSample,DealRecordsCreatedPartSuccess,submitForReview, PMDeal_Info_UploadText1_DCA,PMDeal_Info_UploadLimit_DCA,PMDeal_Info_CapTitle_DCA,PMDeal_Error_UploadLimit_DCA, uploadResult_Message,thank_You_message,btn_cancel,btn_back,PM_Deal_Error_Reason,SEP_DCA_UploadDeals_Info_Preview};

    //uploadedSuccess = false;
    lbInputFile = "";
    parserInitialized = false;
    message = "";
    // SB 3.11.2022 US-0012877 - Simplify Item Upload Process for PM Deals
    @track currentStep = 1;
    totalError = 0;

    get onShowLoadingSpinner() {
        return this.showLoadingSpinner;
    }
    get disableNextBtn(){
        return (this.isNoFile || this.isDisableNextBtn);
    }
    // SB 3.11.2022 US-0012877 - Simplify Item Upload Process for PM Deals
    get disableSubmitBtn() {
        return (this.isReachLimit || this.dealItems.length == 0 || this.isLimitRecordsSubmitted || this.totalError > 0); // CS 28-10-2022 / Chetra Sarom / US-0012778 - Upload Items Validations
    }
    get disableUploadFile(){
        return this.isUnableUpload;
    }
    get allObjMessageInfos(){
        return this.objMessageInfos;
    }
    get totalRecord() {
        return this.totalRec;
    }
    get jsonData(){
        // return this.data; 
        return this.mAllRecords[this.currentPage]; //MN-15062022-US-0011863-Pagination
    }  
    get showMessageResults() {
        var messageErrors = [];
        var totalSuccess = 0;
        var totalError = 0;
        
        for(var i =0; i < this.allMessageInfo.length; i++){
            var obj = this.allMessageInfo[i];
            if(obj["cls_status"] == "cls_error") {
                messageErrors.push(obj["message"]);
                totalError++;// SB 3.11.2022 US-0012877 - Simplify Item Upload Process for PM Deals
            } else  totalSuccess++;
        }

        this.objMessageResult["isHasSuccess"] = (messageErrors.length == 0);
        this.objMessageResult["totalSuccess"] = totalSuccess;
        this.objMessageResult["totalError"] = totalError;// SB 3.11.2022 US-0012877 - Simplify Item Upload Process for PM Deals
        this.objMessageResult["isHasError"] = (messageErrors.length > 0);
        this.objMessageResult["lstError"] = messageErrors;
        this.totalError = totalError;
        return this.objMessageResult;
    }
    get isShowTable(){
        return this.data.length > 0;
    }
    get displayPagination() {
        var arrPage = [];
        for(var i =1; i<= this.totalPage; i++){
            var objP = {value : i, clsActive : (this.currentPage == i?"active":"")};
            arrPage.push(objP);
        }
        return arrPage;
    }

    renderedCallback() {
        if(!this.parserInitialized){
            loadScript(this, PapaParse)
                .then(() => {
                    this.parserInitialized = true;
                })
                .catch(error => console.error(error));
        }
    }
    //General Methods
    connectedCallback() {

        this.subscribeToMessageChannel(); //MN-10062022- to refresh handler that called from external lwc using pub/sub messageChannel
        this.doMapErrorMessages();
        this.doLoadDCAUploadDeals();
    }
    /*@api hideSuccessMessage() {
        
        this.uploadedSuccess = false;
    }*/

    listDCAFields = ['Deal_Contract_Agreement__c.Contract_Item_Limit__c','Deal_Contract_Agreement__c.eBay_Seller__c','Deal_Contract_Agreement__c.Deal_Site__c','Deal_Contract_Agreement__c.Deal_Start_Date__c','Deal_Contract_Agreement__c.Deal_End_Date__c','Deal_Contract_Agreement__c.Deal_Start_Time__c','Deal_Contract_Agreement__c.Deal_End_Time__c','Deal_Contract_Agreement__c.Vertical__c','Deal_Contract_Agreement__c.Category__c','Deal_Contract_Agreement__c.eBay_Funding__c','Deal_Contract_Agreement__c.Max_Unit_Subsidy__c'];
    @wire(getRecord, { recordId: '$recId', fields: '$listDCAFields' } )
    getDCA({error, data}){
        if(data){
            this.dcaObj = data; 
                this.selectedAccountId = this.dcaObj.fields.eBay_Seller__c.value.substring(0,15);
                this.uploadLimit =  this.dcaObj.fields.Contract_Item_Limit__c.value? this.dcaObj.fields.Contract_Item_Limit__c.value : this._DEFAULT_UPLOAD_LIMIT;
           
        }else
        {
            console.log('nothing in getDCA: ', error);
        }
    }

    @wire(MessageContext)
    messageContext;
    subscribeToMessageChannel() {
        this.subscription = subscribe(
        this.messageContext,
        LWC_CONNECTION_CHANNEL,
        (message) => this.handleMessage(message)
        );
    }

    handleMessage(message) {
        if(message.action == 'refresh') {
            this.doLoadDCAUploadDeals();
        }
    }
    doLoadDCAUploadDeals(){
        doLoadDCAUploadDeal({dcaID: this.recId})
        .then(result => {
            var msg = "";
            var objMsgInfo;
            if(result["status"] == "success"){
                //this.currUserProfileName = result["currUserProfileName"];
                this.dealCount = result["dealCount"];
                //this.dealItemIds = result["dealItemIds"];//TH: comment out : US-0013466 
                
                //this.uploadSizeAvailability_Message = uploadSizeAvailability_Message;

                /*if(this.dealCount >= MAX_DEAL_PER_DCA) {
                    this.isUnableUpload = true;
                    this.uploadSizeAvailability_Message = uploadSizeAvailability_Message.replace(" X ", " 0 ");
                }else{
                    // Given the seller is looking at the Upload Items sub-tab on the deal detail view
                    this.uploadSizeAvailability_Message = this.uploadSizeAvailability_Message.replace(" X ", " "+(MAX_DEAL_PER_DCA - this.dealCount)+" ");

                } */
            }else {
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
        this.mapErrorMessages["EBH_eBayItemID__c-Required"] = COUPON_UPLOAD_ITEM_REQUIRED_FIELD_ITEM_ID;
        this.mapErrorMessages["EBH_ProductTitle__c-Required"] = COUPON_UPLOAD_ITEM_REQUIRED_FIELD_ITEM_TITLE;
        this.mapErrorMessages["EBH_SellerPrice__c-Required"] = LWCBulkUploadCSVError27;
        //SB 2.11.2023 US-0014309 replace EBH_Quantity__c with EBH_MaximumPurchases__c
        // this.mapErrorMessages["EBH_Quantity__c-Required"] = LWCBulkUploadCSVError25;
        // this.mapErrorMessages["EBH_Quantity__c-limit"] = Quantity_Limit;
        // this.mapErrorMessages["EBH_Quantity__c-Incorrect"] = LWCBulkUploadCSVError26;
        // this.mapErrorMessages["EBH_Quantity__c-limit-InvalidFomat"] = COUPON_UPLOAD_ITEM_INVALID_FORMAT_QUANTITY_LIMIT;
        this.mapErrorMessages["EBH_MaximumPurchases__c-Required"] = LWCBulkUploadCSVError25;
        this.mapErrorMessages["EBH_MaximumPurchases__c-limit"] = Quantity_Limit;
        this.mapErrorMessages["EBH_MaximumPurchases__c-Incorrect"] = LWCBulkUploadCSVError26;
        this.mapErrorMessages["EBH_MaximumPurchases__c-limit-InvalidFomat"] = COUPON_UPLOAD_ITEM_INVALID_FORMAT_QUANTITY_LIMIT;

        this.mapErrorMessages["EBH_eBayItemID__c-Incorrect"] = ITEM_ID_MAXIMUM_CHAR_AND_DIGIT_IS_NUMERIC;
        this.mapErrorMessages["EBH_RRPWASPrice__c-Incorrect"] = LWCBulkUploadCSVError47;
        this.mapErrorMessages["EBH_SellerPrice__c-Incorrect"] = LWCBulkUploadCSVError43;
        this.mapErrorMessages["EBH_SellerPrice__c-InvalidFomat"] = COUPON_UPLOAD_ITEM_INVALID_FORMAT_SELLER_PRICE;
    }
    
    handleFilesChange(event) {
        this.isShowMessage = false;
        this.objMessageInfos = [];
        this.allMessageInfo = [];
        this.objMessageResult = {};
        this.data = [];
        if(event.target.files.length > 0) {
            
            this.isNoFile = false;
            this.isDisableNextBtn = false;
            
            this.file = event.target.files[0];
            this.fileName = event.target.files[0].name;
        }
        // SB 3.11.2022 US-0012877 - Simplify Item Upload Process for PM Deals
        this.currentStep++;
        this.handleClickUpload();
    }
    handleClickUpload(){
        this.showLoadingSpinner = true;
        this.isShowMessage = false;
        let self = this;
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
            self.fileContent =  evt.target.result != null ? evt.target.result.trim() : '';
            if(self.fileContent) {
                Papa.parse(self.fileContent, {
                    //NK:22/08/2024:US-0015738 - worker set to false. LWS prevents script creates worker
                    worker: false,
                    // worker: true, // Handle big file
                    header: false,
                    skipEmptyLines: true,
                    complete: (results) => {
                        self._rows = results.data;
                        self.csvReader();
                        var totalRecords = results.data.length + self.dealCount; // CS 28-10-2022 / Chetra Sarom / US-0012778 - Upload Items Validations
                        //self.isLimitRecordsSubmitted = totalRecords > 15001 ? true:false;  // CS 28-10-2022 / Chetra Sarom / US-0012778 - Upload Items Validations
                        //NK:13/05/2025:US-0026069
                        self.isLimitRecordsSubmitted = totalRecords > (self.uploadLimit+1) ? true:false; 
                        //self.disableSubmitBtn = self.isLimitRecordsSubmitted;
                    },
                    error: (error) => {
                        console.log('error::', error);
                    }
                })
            }
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
            var allTextLines = this._rows;
            var cols = this.defaulCols;
            var tempData = [];
            var tempDeal = [];

            var index = 0;
            var tempMIndex = {};
            var rowNumber = 0;
            var rowT = 0;
            this.isReachLimit = false;

            //Check csv header
            if((allTextLines[0]).length != cols.length - 2){
                var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : LWCBulkUploadCSVError3};
                this.objMessageInfos.push(objMsgInfo);
                this.showLoadingSpinner = false;
                return;
            }

            for(var i = 1; i < allTextLines.length; i++) {

                rowNumber++;
                rowT++;
                var msg = "";
                var msgNumeric = "";
                var rowIncomplete = false;
                var isValueInvalidFormat = false;
                this.isInvalidFormat = false;

                var allCols = allTextLines[i];
                let deal = { "sobjectType": "EBH_Deal__c" };
                var row = {};
                row["id"] = i;

                var isRowEmpty = true;

                for(var x= 0; x < allCols.length; x++) {
                    var colName = cols[x+2].fieldName;
                    if(colName == "status" || colName == "row_number") continue;
                    
                    var val = allCols[x]? allCols[x] : "";
                    // Empty rows should be ignored
                    if(val != undefined && val != "" && val != " ") {
                        isRowEmpty = false;
                    }
                    row[colName] = val;
                    deal[colName] = val;
                    //console.log('row['+colName+']='+JSON.stringify(val));
                    if(row[colName] == "" && this.requiredDealFields.includes(colName)){
                        msgNumeric += (msgNumeric==""? "" :", ") + this.mapErrorMessages[colName+"-Required"];
                        rowIncomplete = true;
                        continue;
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
                
                // Avoid duplicate Item IDs against the deal record
                //TH : comment out : US-0013466 
                /*if(itemId != "" && this.dealItemIds.includes(itemId)){
                    msg = MSG_DUPLICATE_DEAL_ITEM_ID_AGAINST_ORG;
                    row["status"] = msg;
                    row["cls_status"] = "cls_error";
                    this.isSomeError = true;

                    objMsg["cls_status"] = "cls_error";
                    objMsg["message"] = "- " + this.Labels.txt_rownum  + " "+rowNumber+". "+ msg;
                    tempData.push(row);
                    continue;
                }
                // Avoid duplicate Item IDs within the csv file
                else */if(itemId != "" &&  cItemIds.includes(itemId)) {
                    if(!duplicateItemIds.includes(itemId)) duplicateItemIds.push(itemId);
                    msg = Duplicate_Entry_msg;
                    msg = msg.replace("<item_id>", (itemId+"")); //MN-27102022-US-0012841
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
                    msg = READY_TO_UPLOAD; //Ready for upload
                    row["status"] = msg;
                    row["cls_status"] = "cls_success";

                    objMsg["cls_status"] = "cls_success";
                    objMsg["message"] = msg;
                    tempMIndex[index] = rowT-1;
                    
                    index++;
                }
                //Assigned value into Deal record that not defined in CSV file
                deal["Deal_Contract_Agreement__c"] = this.recId;
                deal["EBH_BusinessName__c"] = this.dcaObj.fields["eBay_Seller__c"].value;
                deal["EBH_DealSiteId__c"] = this.dcaObj.fields["Deal_Site__c"].value;
                deal["EBH_DealStartDate__c"] = this.dcaObj.fields["Deal_Start_Date__c"].value;
                deal["EBH_DealEndDate__c"] = this.dcaObj.fields["Deal_End_Date__c"].value;
                deal["EBH_DealStartTime__c"] = this.dcaObj.fields["Deal_Start_Time__c"].value;
                deal["EBH_DealEndTime__c"] = this.dcaObj.fields["Deal_End_Time__c"].value;
                deal["EBH_Vertical__c"] = this.dcaObj.fields["Vertical__c"].value;
                deal["EBH_Category__c"] = this.dcaObj.fields["Category__c"].value;
                //TH:07/10/2022:US-0012741 : AC6 :
                var ebayFunding = this.dcaObj.fields["eBay_Funding__c"].value;
                var maxUnitSubsidy = this.dcaObj.fields["Max_Unit_Subsidy__c"].value;
                var sellerPrice = deal["EBH_SellerPrice__c"];
                var var1 = (ebayFunding/100)*sellerPrice;
                if(var1>maxUnitSubsidy){
                    deal["EBH_DealPrice__c"] = sellerPrice - maxUnitSubsidy;//Deal Price = Seller Price - Deal Contract Agreement.Maximum Unit subsidy
                }else{
                    deal["EBH_DealPrice__c"] = (1-(ebayFunding/100))*sellerPrice;//Deal Price = (1-ebayfunding%)*Seller Price 
                }
                //TH:07/10/2022:US-0012741: AC1: the RRP Price must not be less than Deal Price
                var RRP_Price = deal["EBH_RRPWASPrice__c"];
                if(RRP_Price && RRP_Price <= deal["EBH_DealPrice__c"]){
                    var errorMsg = RRP_Price_Msg_Error;
                    row["status"] = errorMsg;
                    row["cls_status"] = "cls_error";
                    this.isSomeError = true;
                    objMsg["cls_status"] = "cls_error";
                    objMsg["message"] = "- " + this.Labels.txt_rownum  + " " + rowNumber +". "+errorMsg;
                    tempData.push(row);
                    continue;
                }

                // SB 17.01.2024 US-0014528
                var productTitle = deal["EBH_ProductTitle__c"];
                if(productTitle != '' && productTitle.length > 255){
                    deal["EBH_ProductTitle__c"] = productTitle.substring(0,255);
                }

                tempData.push(row);
                tempDeal.push(deal);
            }
            // Avoid duplicate Item IDs within the csv file 
            // Check all the rows again
            for(var i=0; i < tempData.length; i++) {
                var itemId = tempData[i]["EBH_eBayItemID__c"];
                if(duplicateItemIds.includes(itemId) && tempData[i]["status"] != Duplicate_Entry_msg){
                    tempData[i]["cls_status"] = "cls_error";
                    var errMsg = Duplicate_Entry_msg;
                    errMsg = errMsg.replace("<item_id>", (itemId+"")); //MN-27102022-US-0012841 
                    tempData[i]["status"] = errMsg;
                    var objMsg1 = {"row_number": 1};
                    objMsg1["cls_status"] = "cls_error";
                    objMsg1["message"] = "- " + this.Labels.txt_rownum + " "+(i+1)+". "+ errMsg;
                
                    this.allMessageInfo[i] = objMsg1;
                }
            }
            cols[1]["initialWidth"] = this.isSomeError ? 360 : 140;
            var tDeal = [];
            var idx = 0;
            for(var i = 0; i < tempDeal.length; i++){
                var ebayId = tempDeal[i]["EBH_eBayItemID__c"];
                if(!duplicateItemIds.includes(ebayId) ){//&& !this.dealItemIds.includes(ebayId) : TH : comment out : US-0013466 
                    tDeal.push(tempDeal[i]);
                    this.mRowIndex[idx] = tempMIndex[i];
                    idx++;
                }
            }
            this.showLoadingSpinner = false;
            this.data = tempData;
            this.totalRec = tempData.length;
            this.columns = cols;
            this.dealItems = tDeal;

            this.currentPage = 1;
            this.listRecord = this.data;
            this.onAssignRecords();

            // Item Count validation 
            /*if((tDeal.length + this.dealCount) > MAX_DEAL_PER_DCA){
                this.isReachLimit = true;
                var msg = MSG_MAX_ITEMS_FOR_DEAL_UPLOAD.replace("#MAX#", MAX_DEAL_PER_DCA);
                msg = msg.replace(" X ", " "+(MAX_DEAL_PER_DCA - this.dealCount)+ " ");
                var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : msg};
                this.objMessageInfos.push(objMsgInfo);
            }*/
            
        } catch( err ) {
            
            console.log('***** err :: ', err);
            this.showLoadingSpinner = false;
            var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : err.message};
            this.objMessageInfos.push(objMsgInfo);
        }

    }
    doValidateFormatFields(val, colName){
        var tempMsg = "";
        var isValNumeric = this.isNumeric(val);

        // Avoid wrong format on the Item ID
        if(colName == "EBH_eBayItemID__c" && val != ""){
            if(!isValNumeric || val.length != 12) {
                tempMsg = this.mapErrorMessages["EBH_eBayItemID__c-Incorrect"];
                this.isInvalidFormat = true;
            }
        }
        //SB 2.11.2023 US-0014309 replace EBH_Quantity__c with EBH_MaximumPurchases__c
        // else if(colName == "EBH_Quantity__c" && val != ""){
        //     if(!isValNumeric || !this.isInt(val) || val.length > 18){
        //         tempMsg = this.mapErrorMessages["EBH_Quantity__c-Incorrect"];
        //         this.isInvalidFormat = true;
        //     }else if(val > 100){
        //         tempMsg = this.mapErrorMessages["EBH_Quantity__c-limit"];
        //         this.isInvalidFormat = true;
        //     }
        //     // Change history: 10-11-2022 / Chetra Sarom / US-0012778
        //     if(isValNumeric && val == 0) {
        //         tempMsg = this.mapErrorMessages["EBH_Quantity__c-limit-InvalidFomat"];
        //         this.isInvalidFormat = true;
        //     }
        //     // end / US-0012778
        // }
        else if(colName == "EBH_MaximumPurchases__c" && val != ""){
            if(!isValNumeric || !this.isInt(val) || val.length > 18){
                tempMsg = this.mapErrorMessages["EBH_MaximumPurchases__c-Incorrect"];
                this.isInvalidFormat = true;
            }else if(val > 100){
                tempMsg = this.mapErrorMessages["EBH_MaximumPurchases__c-limit"];
                this.isInvalidFormat = true;
            }
            if(isValNumeric && val == 0) {
                tempMsg = this.mapErrorMessages["EBH_MaximumPurchases__c-limit-InvalidFomat"];
                this.isInvalidFormat = true;
            }
        }
        else if(colName == "EBH_SellerPrice__c" && val != ""){
            if(!isValNumeric){
                tempMsg = this.mapErrorMessages["EBH_SellerPrice__c-Incorrect"];
                this.isInvalidFormat = true;
            }
            // Change history: 28-10-2022 / Chetra Sarom / US-0012778
            if(isValNumeric && val == 0) {
                tempMsg = this.mapErrorMessages["EBH_SellerPrice__c-InvalidFomat"];
                this.isInvalidFormat = true;
            }
            // end / US-0012778
        }
        //SRONG TIN US-0015000
        else if(colName == "EBH_RRPWASPrice__c" && val != ""){
            if(!isValNumeric){
                tempMsg = this.mapErrorMessages["EBH_RRPWASPrice__c-Incorrect"];
                this.isInvalidFormat = true;
            }
            
        }
        // end / US-0015000
        return tempMsg;
    }
    isNumeric(val) {
        return /^-?[\d.]+(?:e-?\d+)?$/.test(val);
    }
    isInt(val) {
        var intRegex = /^-?\d+$/;
        if (!intRegex.test(val))
            return false;
    
        var intVal = parseInt(val, 10);
        return parseFloat(val) == intVal && !isNaN(intVal);
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

    doDownloadCSVTemplate(){
        let downloadElement = document.createElement('a');
        downloadElement.href = bulkUploadDCATemplateNA;
        downloadElement.download = this.Labels.label_DCA_DownloadSample;

        downloadElement.target = '_self';
        // below statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click(); 
    }
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

        if (this.currentPage > this.totalPage) this.currentPage=1;
        
        this.allRecords = (this.mAllRecords[this.currentPage]? this.mAllRecords[this.currentPage]:[]);
    }

    handleClickSubmit() {

        this.showLoadingSpinner = true;
        this.dealComplete = [];
        this.dealsSaveResult = [];
        this.objMessageResult = {};
        this.objMessageInfos = []; 
        this.isSomeFail = false;
        this.message = "";
        this.currentStep++;// SB 3.11.2022 US-0012877 - Simplify Item Upload Process for PM Deals
        
        this.onProccessUpload(this.dealItems);
    }
    onProccessUpload(lstDeals){
        // chunk list of deal to small size for pass into apex
        var arrAllDEAL = this.chunkArray(lstDeals, this.numberOfDealPerPk);
        //console.log('arrAllDEAL:'+JSON.stringify(arrAllDEAL));
        this.onSubmitMultipleDeals(arrAllDEAL, 0, arrAllDEAL.length);
    }
    chunkArray(myArray, chunk_size){
        var results = [];
    
        while (myArray.length) {
            results.push(myArray.splice(0, chunk_size));
        }
        
        return results;
    }
    onSubmitMultipleDeals(arrAllDEAL, index, total){ 
        if( index < total && arrAllDEAL[index]){ 
            
            doSubmitMultipleDealsForDCA({lstDeals: arrAllDEAL[index]})
            .then(result => {
                index++;
                if(result['status'] == 'success'){
                    var srList = result["srList"];
                    this.dealsSaveResult = this.dealsSaveResult.concat(JSON.parse(srList));
                }else{
                    this.isSomeFail = true;
                    var msg = result["message"];
                    var objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
                    this.objMessageInfos.push(objMsgInfo);
                }
                if (index < total) {
                    this.onSubmitMultipleDeals(arrAllDEAL, index, total);
                }
                // Final round
                else if(!this.isSomeFail && index == total){
                    this.onUpdateStatus();
                }

            })
            .catch(error => {
                // console.log('$$$$ERROR :: ', error);
                this.isSomeFail = true;
                this.message = (error["body"] != undefined? error.body.message : error);
                this.message = (this.message=="Unable to read SObject's field value[s]"? LWCBulkUploadCSVError15 : this.message);
                var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : this.message};
                this.objMessageInfos.push(objMsgInfo);
                this.dealComplete = [];
                this.isSomeFail = false;
                this.message = "";
                this.showLoadingSpinner = false;
            });  
        }
    } 
    onUpdateStatus() {
        this.isShowMessage = true;
        this.data = [];
        this.objMessageInfos = []; 
        this.fileName = "";
        this.showLoadingSpinner = false;

        var allSaveResult = this.dealsSaveResult;
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
        
        this.doLoadDCAUploadDeals();
        // SB 3.11.2022 US-0012877 - Simplify Item Upload Process for PM Deals
        if(!isHasError){
            this.doUpdateDCAStatus();
        }
        //this.uploadedSuccess = true; //MN-10062022-US-0011863
        const custEvent = new CustomEvent(
            "reloadlistview", {});
        this.dispatchEvent(custEvent);
    }
    //US-0012660 - Submit button in Seller Portal to change the status of DCA
    doUpdateDCAStatus(){
        this.showLoadingSpinner = true;
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recId;
        fields[STATUS_FIELD.fieldApiName] = 'In Progress';
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(result => {
                //SRONG TIN - 18.02.2025 - US-0015819 LWS - Upload Components (deal/coupon item)
                //eval("$A.get('e.force:refreshView').fire();");
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: '',
                        message: this.Labels.thank_You_message,
                        variant: 'success',
                    }),
                );
                this.showLoadingSpinner = false;
                setTimeout(() => {
                    let currentUrl = window.location.href;
                    window.location.href = currentUrl;
                }, 100); 
            })
            .catch(error => {
                // SB 4.11.2022 US-0012877
                var errorMsg ;
                if(error.body.output.errors.length == 0){
                    Object.keys(error.body.output.fieldErrors).forEach(key => {
                        errorMsg = error.body.output.fieldErrors[key][0];
                    });
                } else {
                    errorMsg = error.body.output.errors[0];
                }
                // SB 4.11.2022 US-0012877
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error on data save',
                        //message: error.body.message,
                        message: errorMsg.errorCode + ' - '+errorMsg.message,
                        variant: 'error',
                    }),
                );
                this.showLoadingSpinner = false;
            });
    }

    // SB 3.11.2022 US-0012877 - Simplify Item Upload Process for PM Deals
    updateCurrentPage(event)
    {
        this.currentPage = event.detail.currentPage;
    }
    
    handleCancel(){
        setTimeout(() => {
            //SRONG TIN - 18.02.2025 - US-0015819 LWS - Upload Components (deal/coupon item)
            //eval("$A.get('e.force:refreshView').fire();");
            this.dispatchEvent(new CustomEvent('tab'));
        }, 100); 
    }

    handleBack() {
        this.currentStep--;
        this.isLimitRecordsSubmitted = false;
    }

    handleReupload(){
        this.currentStep = 1;
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
 
    handleAccountChange()
    {

    }

    get PMDeal_Info_UploadLimit_DCA()
    {
        return this.Labels.PMDeal_Info_UploadLimit_DCA.replace("{LIMIT}", this.uploadLimit);
    }
    get PMDeal_Error_UploadLimit_DCA()
    {
        return this.Labels.PMDeal_Error_UploadLimit_DCA.replace("{LIMIT}", this.uploadLimit);
    }
}