/*********************************************************************************************************************************
@ Author:         Sovantheany Dim
@ Purpose:        US-0010998 - [SP] Refactor Bulk Upload Component per Region
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.01.2022 / Sovantheany Dim / Created the component.
                  11.10.2022 / Sambath Seng / US-0012737 - Incorrect error message when upload deal with duplicate item id
                  17.10.2022 / Bora Chhorn / US-0012600 - Enable Link Multiple Accounts for NA/ AU Portal Sellers
                  16.03.2023 / Sambath Seng / US-0013185 - AU - Deals Bulk Upload pages to match the design and function as Coupon
                  07.06.2023 / Sophal Noch / US-0013657 - Bulk Upload - Copy Paste Functionality in Seller Portal
*********************************************************************************************************************************/
import { LightningElement ,api, track} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
// import doLoadSetting from '@salesforce/apex/ClsBulkUploadCSV.doLoadSetting'; //BR-24-10-22-US-0012600
import { ShowToastEvent } from 'lightning/platformShowToastEvent';//SB 15.03.2023 US-0013185
import doLoadSetting from '@salesforce/apex/ClsBulkUploadCSV.doLoadSettingLinkedAccount'; //BR-24-10-22-US-0012600
import doSubmitMultipleDeals from '@salesforce/apex/ClsBulkUploadCSV.doSubmitMultipleDeals';
import getDealRetailCampaign from '@salesforce/apex/ClsBulkUploadCSV.getDealRetailCampaign';

import bulkUploadDealTemplateNA from '@salesforce/resourceUrl/SEP_Bulk_Upload_Deal_Template_NA'; //MN-14122021-US-0010945
import bulkUploadDealTemplateNAxL from '@salesforce/resourceUrl/SEP_Bulk_Upload_Deal_Template_NA_XL'; //SP-07062023-US-0013657
import dealbulkUploadNaStep1 from '@salesforce/resourceUrl/Deal_Bulk_Upload_NA_Step1'; //SP-13062023-US-0013657
import dealbulkUploadNaStep2 from '@salesforce/resourceUrl/Deal_Bulk_Upload_NA_Step2'; //SP-13062023-US-0013657
import dealbulkUploadNaStep3 from '@salesforce/resourceUrl/Deal_Bulk_Upload_NA_Step3'; //SP-13062023-US-0013657
import dealbulkUploadNaStep4 from '@salesforce/resourceUrl/Deal_Bulk_Upload_NA_Step4'; //SP-13062023-US-0013657
import ebayLogo from '@salesforce/resourceUrl/eBayLogo'; //SP-13062023-US-0013657

import LWCBulkUploadCSVError1 from '@salesforce/label/c.LWCBulkUploadCSVError1';
import LWCBulkUploadCSVError2 from '@salesforce/label/c.LWCBulkUploadCSVError2';
import LWCBulkUploadCSVError3 from '@salesforce/label/c.LWCBulkUploadCSVError3';
import LWCBulkUploadCSVError4 from '@salesforce/label/c.LWCBulkUploadCSVError4';
import LWCBulkUploadCSVError5 from '@salesforce/label/c.LWCBulkUploadCSVError5';
import LWCBulkUploadCSVError6 from '@salesforce/label/c.LWCBulkUploadCSVError6';
import LWCBulkUploadCSVError8 from '@salesforce/label/c.LWCBulkUploadCSVError8';
import LWCBulkUploadCSVError10 from '@salesforce/label/c.LWCBulkUploadCSVError10';
import LWCBulkUploadCSVError11 from '@salesforce/label/c.LWCBulkUploadCSVError11';
import LWCBulkUploadCSVError12 from '@salesforce/label/c.LWCBulkUploadCSVError12';
import LWCBulkUploadCSVError13 from '@salesforce/label/c.LWCBulkUploadCSVError13';
import LWCBulkUploadCSVError14 from '@salesforce/label/c.LWCBulkUploadCSVError14';
import LWCBulkUploadCSVError15 from '@salesforce/label/c.LWCBulkUploadCSVError15';
import LWCBulkUploadCSVError16 from '@salesforce/label/c.LWCBulkUploadCSVError16';
import LWCBulkUploadCSVError41 from '@salesforce/label/c.LWCBulkUploadCSVError41';
import LWCBulkUploadCSVError42 from '@salesforce/label/c.LWCBulkUploadCSVError42';

import RowNumber from '@salesforce/label/c.Row_Number';
import Cancel from '@salesforce/label/c.lwcCancelbtn';//Loumang:12-01-2022:US-0010747
import DealRecordsCreatedPartSuccess from '@salesforce/label/c.DealRecordsCreatedPartSuccess';
import DealRecordsCreatedPartError from '@salesforce/label/c.DealRecordsCreatedPartError';//SB 21-2-2022 US-0011212 - Feedback - QA/BA/UAT/GCX
import DRC_Inline_info from '@salesforce/label/c.DRC_Inline_info';//SB 21-2-2022 US-0011212 - Feedback - QA/BA/UAT/GCX
import PleaseSelectTheEBayAccount from '@salesforce/label/c.Please_select_the_eBay_Account';//BR 10-11-2022 US-0012600
import btn_back from '@salesforce/label/c.SEP_BACK_BUTTON';//SB 15.03.2023 US-0013185
import thank_You_message from '@salesforce/label/c.Thank_You_message';//SB 15.03.2023 US-0013185
import dealBulkUpload_HelpMessage from '@salesforce/label/c.dealBulkUpload_HelpMessage';//SB 24.03.2023 US-0013185
import dealBulkUploadBtnDownloadUserGuide  from '@salesforce/label/c.dealBulkUploadBtnDownloadUserGuide';  // 07.06.2023 / Sophal Noch / US-0013657
import dealBulkUploadBtnDownloadXL  from '@salesforce/label/c.dealBulkUploadBtnDownloadXL';  // 12.06.2023 / Sophal Noch / US-0013657
import UploadUserGuide  from '@salesforce/label/c.UploadUserGuide';  // 13.06.2023 / Sophal Noch / US-0013657
import closeBtn from '@salesforce/label/c.Close'; // 13.06.2023 / Sophal Noch / US-0013657

export default class DealBulkUploadNA extends NavigationMixin(LightningElement) {
    @api tabName = "";
    @api recordId;
    @api startDate;
    @api endDate;
    @api country;
    @api availableDeal;
    @api lbInputFile;
    @api lbTotalRecord;
    @api redirectToUrl = "";
    @api numberOfDealPerPk = 150;
    @api labelBtnNext;
    @api labelBtnSubmit;
    @api labelBtnDownloadTemplate;
    @api labelBtnDownloadSampleFile;
    @api deals = [];
    @api showUserGuide = false;  // 07.06.2023 / Sophal Noch / US-0013657

    @track message = "";
    @track isSomeFail = false;
    @track dealSaveResult = [];
    @track dealsComplete = [];
    @track isReachLimit = false;
    @track objMessageInfos = [];
    @track isSomeError = false;
    @track showLoadingSpinner = false;
    @track fileName = "";
    @track data = [];
    @track totalRec = 0;
    @track columns = [];
    @track isShowMessage = false;
    @track allMessageInfo = [];
    @track objMessageResult = {};
    @track isNoFile = true;
    @track mRowIndex = {};
    @track selectedSeperator = ',';
    @track dd_DuplicateError = "";
    @track mapErrorMessages = {};
    @track csvHeader1  = 'ebay Item Id,Deal Price,List Price,Quantity,Maximum Purchases,Sellers Deal Price MSKU Lower,Sellers Deal Price MSKU Upper,List Price MSKU Lower,List Price MSKU Upper';
    @track csvHeader2  = '"ebay Item Id","Deal Price","List Price","Quantity","Maximum Purchases","Sellers Deal Price MSKU Lower","Sellers Deal Price MSKU Upper","List Price MSKU Lower","List Price MSKU Upper"';
    @track csvHeaderGerman1 = 'eBay-Artikelnr,Artikelbezeichnung des eBay-Angebots,EAN,Artikel Zustand,Artikelstückzahl für WOW! Angebot,Angebotspreis des Verkäufers,Format des WOW! Angebots,Artikel frühestens verfügbar für WOW! Angebot ab,Preisvergleichsportal 1 (Amazon für DE),Preisvergleichsportal 2 (Idealo für DE),eBay-Hauptkategorie,Kommentare des Verkäufers';
    @track csvHeaderGerman2 = '"eBay-Artikelnr","Artikelbezeichnung des eBay-Angebots","EAN","Artikel Zustand","Artikelstückzahl für WOW! Angebot","Angebotspreis des Verkäufers","Format des WOW! Angebots","Artikel frühestens verfügbar für WOW! Angebot ab","Preisvergleichsportal 1 (Amazon für DE)","Preisvergleichsportal 2 (Idealo für DE)","eBay-Hauptkategorie","Kommentare des Verkäufers"';
    @track defaulCols = [
        { label: '', fieldName: 'row_number', type: 'number', initialWidth: 50},
        { label: 'Status', fieldName: 'status', type: 'text',wrapText: true, initialWidth: 310, cellAttributes: { alignment: 'center' ,class: { fieldName: 'cls_status' } }},                       
        { label: 'eBay Item ID', fieldName: 'EBH_eBayItemID__c', type: 'text'},
        { label: 'Deal Price', fieldName: 'EBH_DealPrice__c', type: 'currency', initialWidth: 160, typeAttributes: { currencyCode: 'USD', step: '0.001'}},
        { label: 'List Price', fieldName: 'EBH_RRPWASPrice__c', type: 'currency', initialWidth: 160, typeAttributes: { currencyCode: 'USD', step: '0.001'}},
        { label: 'Quantity', fieldName: 'EBH_Quantity__c', type: 'number', initialWidth: 160},
        { label: 'Maximum Purchases', fieldName: 'EBH_MaximumPurchases__c', type: 'number', initialWidth: 160},
        { label: 'Sellers Deal Price MSKU Lower', fieldName: 'SellersDealPriceMSKULower__c', type: 'number', initialWidth: 160},
        { label: 'Sellers Deal Price MSKU Upper', fieldName: 'SellersDealPriceMSKUUpper__c', type: 'number', initialWidth: 160},
        { label: 'List Price MSKU Lower', fieldName: 'ListPriceMSKULower__c', type: 'number', initialWidth: 160},
        { label: 'List Price MSKU Upper', fieldName: 'ListPriceMSKUUpper__c', type: 'number', initialWidth: 160}
    ]; 
    @track requiredDealFields = ["EBH_eBayItemID__c", "EBH_DealPrice__c", "EBH_RRPWASPrice__c", "EBH_Quantity__c", "EBH_MaximumPurchases__c", "EBH_SellerPrice__c", "EBH_Dealdateearliestpossible__c", "EBH_ProductTitle__c"];
    @track totalSuccess = 0;// Sambath Seng 11.10.2022 US-0012737 - Incorrect error message when upload deal with duplicate item id
    @track isUnableUpload = false; //BR-24-10-22-US-0012600
    @track currentStep = 1;//SB 15.03.2023 US-0013185
    @track UPLOAD_NA_DEAL_MTD_NAME = 'SEP_Upload_NA_Deal';  // 07.06.2023 / Sophal Noch / US-0013657
    @track CREATED_FROM_XL = 'Excel';   // 07.06.2023 / Sophal Noch / US-0013657
    @track CREATED_FROM_CSV = 'CSV';   // 07.06.2023 / Sophal Noch / US-0013657
    @track CREATED_FROM_FLD_NAME = 'Created_From__c'; // 07.06.2023 / Sophal Noch / US-0013657
    @track ebayLogo = ebayLogo; //SP-13062023-US-0013657
    @track dealbulkUploadNaStep1 = dealbulkUploadNaStep1; //SP-13062023-US-0013657
    @track dealbulkUploadNaStep2 = dealbulkUploadNaStep2; //SP-13062023-US-0013657
    @track dealbulkUploadNaStep3 = dealbulkUploadNaStep3; //SP-13062023-US-0013657
    @track dealbulkUploadNaStep4 = dealbulkUploadNaStep4; //SP-13062023-US-0013657

    file;
    fileContent;
    fileReader;

    label = {LWCBulkUploadCSVError1, LWCBulkUploadCSVError2, LWCBulkUploadCSVError3,LWCBulkUploadCSVError4,LWCBulkUploadCSVError5,
        LWCBulkUploadCSVError6,LWCBulkUploadCSVError8,LWCBulkUploadCSVError10,LWCBulkUploadCSVError11,LWCBulkUploadCSVError13,
        LWCBulkUploadCSVError12,LWCBulkUploadCSVError14,LWCBulkUploadCSVError15,LWCBulkUploadCSVError16,
        LWCBulkUploadCSVError41,LWCBulkUploadCSVError42,RowNumber, Cancel, DealRecordsCreatedPartSuccess, DealRecordsCreatedPartError,
        DRC_Inline_info, PleaseSelectTheEBayAccount,btn_back,thank_You_message,dealBulkUpload_HelpMessage, 
        dealBulkUploadBtnDownloadUserGuide, dealBulkUploadBtnDownloadXL, UploadUserGuide, closeBtn  // 12.06.2023 / Sophal Noch / US-0013657 : add label dealBulkUploadBtnDownloadUserGuide, dealBulkUploadBtnDownloadXL, UploadUserGuide, Close
    };

    get onShowLoadingSpinner() {
        return this.showLoadingSpinner;
    }
    get disableNextBtn(){
        return (this.isNoFile || this.isDisableNextBtn);
    }
    get disableSubmitBtn() {
        return (this.isReachLimit || this.deals.length == 0);
    }
    get disableUploadFile(){
        return this.isUnableUpload || this.accountId == undefined || this.accountId==""; //BR-24-10-22-US-0012600
    }
    get isShowTable(){
        return this.data.length > 0;
    }
    get jsonData(){
        return this.data;
        // return this.mAllRecords[this.currentPage];//SB 17.03.2023 US-0013185
    }
    get totalRecord() {
        return this.totalRec;
    }
    get allObjMessageInfos(){
        return this.objMessageInfos;
    }
    get showMessageResults() {
        var messageErrors = [];
        // var totalSuccess = 0;// Sambath Seng 11.10.2022 US-0012737 - Incorrect error message when upload deal with duplicate item id
        for(var i =0; i < this.allMessageInfo.length; i++){
            var obj = this.allMessageInfo[i];
            if(obj["cls_status"] == "cls_error") {
                messageErrors.push(obj["message"]);
            }
            // else  totalSuccess++;// Sambath Seng 11.10.2022 US-0012737 - Incorrect error message when upload deal with duplicate item id
        }
        this.objMessageResult["isHasSuccess"] = (messageErrors.length == 0);
        this.objMessageResult["totalSuccess"] = this.totalSuccess;// Sambath Seng 11.10.2022 US-0012737 - Incorrect error message when upload deal with duplicate item id

        this.objMessageResult["isHasError"] = (messageErrors.length > 0);
        this.objMessageResult["lstError"] = messageErrors;
        return this.objMessageResult;
    }

    //SB 15.03.2023 US-0013185
    get isStep1(){
        return this.currentStep == 1;
    }

    get isStep2(){
        return this.currentStep == 2;
    }

    get isStep3(){
        return this.currentStep == 3;
    }

    getQueryParameters() {
        var params = {};
        var search = location.search.substring(1);
        if (search) {
            params = JSON.parse('{"' + search.replace(/&/g, '","').replace(/=/g, '":"') + '"}', (key, value) => {
                return key === "" ? value : decodeURIComponent(value)
            });
        }
        return params;
    }
    

    connectedCallback() {
        var params = this.getQueryParameters();
        this.recordId = params["recordId"];
        this.startDate = params["startDate"];
        this.endDate = params["endDate"];
        this.country = params["country"];
        this.doLoadCMT();
    }

    doLoadCMT(){
        doLoadSetting({dealReatilCampaingId : this.recordId, accountId: this.accountId}) //BR-24-10-22-US-0012600
        .then(result => {
            this.objMessageInfos = [];
            this.isSomeError = false;
            var status = "error";
            var msg = "";
            var objMsgInfo;
            if(result["status"] == "success"){
                this.dd_DuplicateError = result["dd_DuplicateError"];
                this.email = result["conEmail"];
                // this.accountId = result["accountId"]; //BR-24-10-22-US-0012600
                this.contactId = result["contactId"];
                this.fullContactName = result["fullContactName"];
                this.availableDeal = result.availableDeal;
                if(this.availableDeal > 0){
                    this.isUnableUpload = false;
                    this.isReachLimit = false;
                    status = "info";  
                    msg = this.label.LWCBulkUploadCSVError1.replace(" x "," "+ this.availableDeal +" "); //"You may upload up to another "+ this.availableDeal + (this.currUserLang == "DE - Seller Portal"? " Deals.":" Deals in this Deal Window.");
                    objMsgInfo = {className : "cls_message-info", mainMsg : "INFORMATION -", detailMsg : msg};
                }else {
                    this.isUnableUpload = true;
                    msg = this.label.LWCBulkUploadCSVError2;
                    objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
                }

                this.doMapErrorMessages();
            }else {
                this.isUnableUpload = true;
                this.isReachLimit = true;
                msg = result["message"];
                objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
            }
            this.objMessageInfos.push(objMsgInfo);
            this.doLoadDealRetailCampaign();
        })
        .catch(error => { 
            console.log("first load ERROR::", error);
        }); 
    }

    doLoadDealRetailCampaign(){
        getDealRetailCampaign({recordId : this.recordId})
            .then(result => {
                if(result["status"] == "success"){
                    this.dealRetailCampaign = result["dealRetailCampaign"];
                }
            })
    }

    doMapErrorMessages(){
        this.mapErrorMessages[this.dd_DuplicateError] = this.label.LWCBulkUploadCSVError16;
    }

    handleFilesChange(event) {
        this.isShowMessage = false;
        this.objMessageInfos = [];
        this.data = [];
        this.deals = [];
        if(event.target.files.length > 0) {
            this.isNoFile = false;
            this.isDisableNextBtn = false;
            this.file = event.target.files[0];
            this.fileName = event.target.files[0].name;
        }
        //SB 15.03.2023 US-0013185
        this.handleClickUpload();
        this.currentStep++;
    }

    handleClickUpload(){
        this.objMessageInfos = [];
        this.allMessageInfo = [];
        this.objMessageResult = {};
        this.showLoadingSpinner = true;
        this.isShowMessage = false;
        let self = this;
        var reader = new FileReader();
        reader.readAsText(this.file, "UTF-8");//UTF-8 not working with german char , Cp1252 not working with gdoc
        reader.onload = function(evt) {
            self.fileContent =  evt.target.result;
            if(self.fileContent) self.csvReader();
        }
    }

    csvReader(arrAllLine){
        try{
            this.isDisableNextBtn = true;
            this.isShowMessage = false;
            this.isSomeError = false;
            this.allMessageInfo = [];
            this.mRowIndex = {};
            var duplicateEbayIds = [];
            var duplicateRows = [];
            var mDuplicateRow = {};
            var excludeItemIds = [];// Sambath Seng 11.10.2022 US-0012737 - Incorrect error message when upload deal with duplicate item id

            var ebayIds = [];
            // var allTextLines = this.CSVToArray();
            var allTextLines = arrAllLine ? arrAllLine : this.CSVToArray();
            var isFromCopyPaste = arrAllLine ? true : false
            var csvHeader = allTextLines[0];
            if(this.validateHeader(csvHeader,this.csvHeader1) || this.validateHeader(csvHeader,this.csvHeader2)){
                var tempData = [];
                var tempDeals = [];
                var cols = this.defaulCols;
                if((allTextLines[0]).length != cols.length - 2){
                    var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : this.label.LWCBulkUploadCSVError3};
                    this.objMessageInfos.push(objMsgInfo);
                    this.showLoadingSpinner = false;
                    return;
                }
                if(this.availableDeal > 0) this.isReachLimit = false;
                var index = 0;
                var tempMIndex = {};
                var mIdRowNum = {};
                var rowNumber = 0;
                var rowT = 0;
                var mAllRowNumber = {};
                for(var i = 1; i < allTextLines.length; i++) {
                    rowNumber++;
                    rowT++;
                    var msg = "";
                    var msgNumeric = "";
                    var isValueInvalidFormat = false;
                    var isInvalidId = false;
                    var rowIncomplete = false;
                    var msgEbayItem = "";

                    var allCols = allTextLines[i];
                    if(allCols.length != cols.length-2) continue;

                    let deal = { "sobjectType": "EBH_Deal__c" };
                    var row = {};
                    row["id"] = i;
                    var isRowEmpty = true;
                    for(var x= 0; x < allCols.length; x++) {
                        var colName = cols[x+2].fieldName;
                        var fieldType = cols[x+2]["type"];
                        if(colName == "status" || colName == "row_number") continue;
                        var val = allCols[x]? allCols[x] : "";
                        if(val != undefined && val != "" && val != " ") {
                            isRowEmpty = false;
                        }
                        row[colName] = val;
                        deal[colName] = val;
                        
                        if(row[colName] == "" && this.requiredDealFields.includes(colName)){
                            msg += (msg==""? "" :", ") +cols[x+2].label;
                            rowIncomplete = true;
                            continue;
                        }
                        if(colName == "EBH_eBayItemID__c") {
                            if(this.isNumeric(val)) {
                                if(val.length != 12){
                                    ///msgEbayItem = "Listing ID must be numeric and 12 characters in length. ";
                                    msgEbayItem = this.label.LWCBulkUploadCSVError4;
                                    isInvalidId = true;
                                    continue;
                                }
                            }
                        }

                        if(val != "" && (colName == "EBH_eBayItemID__c" || fieldType == "number" || fieldType == "currency")) {
                            if(!this.isNumeric(val)) {
                                msgNumeric += (msgNumeric==""? "" :", ") +cols[x+2].label;
                                isValueInvalidFormat = true;
                                continue;
                            }
                        }
                    }
                    var strRow = (allTextLines[i]).join();
                    if (allTextLines[i][0] != "" && (duplicateRows.includes(strRow) || isRowEmpty == true)){
                        if(!duplicateRows.includes(strRow)) duplicateRows.push(strRow);
                        rowT--;
                        rowNumber--;
                        continue;
                    }
                    row["row_number"] = rowNumber;
                    if(mAllRowNumber[allTextLines[i][0]] == undefined) {
                        mAllRowNumber[allTextLines[i][0]] = [rowNumber];
                    } else {
                        var allRowNum = mAllRowNumber[allTextLines[i][0]];
                        allRowNum.push(rowNumber);
                        mAllRowNumber[allTextLines[i][0]] = allRowNum;
                    }
                    var objMsg = {"row_number" : i};
                    this.allMessageInfo.push(objMsg);
                    if(rowIncomplete || isValueInvalidFormat || isInvalidId){
                        var errorMsg = (isInvalidId == true ? msgEbayItem : "");
                        if(msg != ""){
                            errorMsg = this.label.LWCBulkUploadCSVError5.replace("<fields> ", " ["+ msg + "] ")+" ";
                        }
                        if(msgNumeric != "") {
                            errorMsg = this.label.LWCBulkUploadCSVError6.replace("<fields> ", " ["+ msgNumeric + "] ")+" ";
                        }
                        row["isNotOverrid"] = true;
                        row["status"] = errorMsg;
                        row["cls_status"] = "cls_error";
                        this.isSomeError = true;
                        objMsg["cls_status"] = "cls_error";
                        objMsg["message"] = "- " + this.label.RowNumber  + " " + rowNumber +". "+errorMsg;
                        tempData.push(row);
                        continue;
                    }
                    //check duplicate itemid in file
                    if(allTextLines[i][0] != "" &&  ebayIds.includes(allTextLines[i][0])) {
                        if(!duplicateEbayIds.includes(allTextLines[i][0])) duplicateEbayIds.push(allTextLines[i][0]);
                        mIdRowNum[allTextLines[i][0]] = (mIdRowNum[allTextLines[i][0]] == undefined?rowNumber : mIdRowNum[allTextLines[i][0]]+","+rowNumber);
                        if(mDuplicateRow[allTextLines[i][0]] != undefined ){
                            msg = this.label.LWCBulkUploadCSVError8.replace(" x ",mDuplicateRow[allTextLines[i][0]] +","+ i+" ");
                        } else msg = this.label.LWCBulkUploadCSVError41;
                        row["status"] = msg;
                        row["cls_status"] = "cls_error";
                        this.isSomeError = true;
                        objMsg["cls_status"] = "cls_error";
                        objMsg["message"] = "- " + this.label.RowNumber  + " "+rowNumber+". "+ msg;
                        tempData.push(row);
                        continue;
                    }else{
                        mDuplicateRow[allTextLines[i][0]] = rowNumber;
                        ebayIds.push(allTextLines[i][0]);
                        duplicateRows.push(strRow);
                        msg = this.label.LWCBulkUploadCSVError10;
                        row["status"] = msg;
                        row["cls_status"] = "cls_success";
                        objMsg["cls_status"] = "cls_success";
                        objMsg["message"] = msg;
                        tempMIndex[index] = rowT-1;
                        
                        index++;
                    }
                    deal["EBH_BusinessName__c"] = this.accountId;
                    deal["Seller_Contact__c"] = this.contactId;
                    deal["Seller_Name__c"] = this.fullContactName;
                    //SCH: EBAY-720: Remove seller email field from Bulk upload. We also need to stamp the User.Contact.Email into the EBH_SellerEmail__c field on all bulk created deals.
                    deal["EBH_SellerEmail__c"] = this.email;
                    //TH:09/12/2021:US-0010968 - BUG-[SP-NA Deals] Unsub Deal showing wrong status in HIVE and SEP Portal
                    deal["EBH_Status__c"] = "Processing"; 
                    deal[this.CREATED_FROM_FLD_NAME] = isFromCopyPaste ?  this.CREATED_FROM_XL : this.CREATED_FROM_CSV; //SP-07062023-US-0013657
                    if(this.dealRetailCampaign != undefined ){
                        if(this.dealRetailCampaign["EBH_Date__c"] != undefined) deal["EBH_DealStartDate__c"] = this.dealRetailCampaign.EBH_Date__c;
                        
                        if(this.dealRetailCampaign["Start_Time__c"] != undefined) deal["EBH_DealStartTime__c"] = this.dealRetailCampaign.Start_Time__c;
                        if(this.dealRetailCampaign["EPH_EndDate__c"] != undefined) deal["EBH_DealEndDate__c"] = this.dealRetailCampaign.EPH_EndDate__c;
                        
                        if(this.dealRetailCampaign["End_Time__c"] != undefined) deal["EBH_DealEndTime__c"] = this.dealRetailCampaign.End_Time__c;
                        if(this.dealRetailCampaign["startDate"] != undefined) deal["EBH_Dealdateearliestpossible__c"] = this.startDate;
                        
                        if(this.recordId != undefined) deal["EBH_DealRetailCampaign__c"] = this.recordId;
                        if(this.dealRetailCampaign["EBH_Country__c"] != undefined) deal["EBH_DealSiteId__c"] = this.dealRetailCampaign.EBH_Country__c;
                    }
                    tempData.push(row);
                    tempDeals.push(deal);
                    if(tempDeals.length > this.availableDeal){
                        this.isReachLimit = true;
                        var errMsg = this.label.LWCBulkUploadCSVError11;
                        errMsg = errMsg.replace(" x ", " "+ this.availableDeal + " ")
                        var objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : errMsg};
                        this.objMessageInfos.push(objMsgInfo);
                        tempDeals = [];
                        tempData = [];
                        break;
                    }
                }
            
                for(var i = 0; i < tempData.length; i++){
                    var ebayItem = tempData[i]["EBH_eBayItemID__c"];
                    if(tempData[i]["isNotOverrid"] != undefined && tempData[i]["isNotOverrid"] == true) continue;
                    if(ebayItem != "" && mAllRowNumber[ebayItem] != undefined) {
                        var allRowIds = mAllRowNumber[ebayItem];
                        if(allRowIds.length > 1) {
                            if(!excludeItemIds.includes(ebayItem)) excludeItemIds.push(ebayItem);// Sambath Seng 11.10.2022 US-0012737 - Incorrect error message when upload deal with duplicate item id
                            tempData[i]["cls_status"] = "cls_error";
                            var errMsg = this.label.LWCBulkUploadCSVError8.replace(" x ", " "+allRowIds.join()+" ")
                            tempData[i]["status"] = errMsg;//"Conflicting data in row "+ allRowIds.join() +". please delete and resubmit";
                            var objMsg1 = {"row_number": i+1};
                            objMsg1["cls_status"] = "cls_error";
                            objMsg1["message"] = "- " + this.label.RowNumber  + " "+(i+1)+". "+ errMsg;//"Conflicting data in row "+ allRowIds.join() +". please delete and resubmit";
                            this.allMessageInfo[i] = objMsg1;
                        }
                    }
                }
                cols[1]["initialWidth"] = this.isSomeError ? 330 : 115;
                var tDeals = [];
                var idx = 0;
                for(var i = 0; i < tempDeals.length; i++){
                    var ebayId = tempDeals[i]["EBH_eBayItemID__c"];
                    // Sambath Seng 11.10.2022 US-0012737 - Incorrect error message when upload deal with duplicate item id
                    if(!duplicateEbayIds.includes(ebayId) && !excludeItemIds.includes(ebayId)){
                        tDeals.push(tempDeals[i]);
                        this.mRowIndex[idx] = tempMIndex[i];
                        idx++;
                    }
                }
                this.showLoadingSpinner = false;
                this.data = tempData;
                this.totalRec = tempData.length;
                this.columns = cols;

                //SB 15.03.2023 US-0013185
                // this.currentPage = 1;
                // this.listRecord = this.data;
                // this.onAssignRecords();

                var dealForUpload = this.label.LWCBulkUploadCSVError12;
                dealForUpload = dealForUpload.replace(" x ", " "+ tDeals.length + " ");
                if(tDeals.length > 0) {
                    var objMsgInfo = {className : 'cls_message-info cls_message-success', mainMsg : '', detailMsg : dealForUpload}; //' vailable deals in your file for upload!'};
                    this.objMessageInfos.push(objMsgInfo);
                    this.showLoadingSpinner = false;
                }else {
                    this.showLoadingSpinner = false;
                    var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : '', detailMsg : dealForUpload}; //' vailable deals in your file for upload!'};
                    this.objMessageInfos.push(objMsgInfo);
                    return;
                } 
                this.deals = tDeals;
            }
            else {
                this.showLoadingSpinner = false;
                var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : this.label.LWCBulkUploadCSVError13};
                this.objMessageInfos.push(objMsgInfo);
            }
            this.showLoadingSpinner = false;
        } catch( err){
            this.showLoadingSpinner = false;
            var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : err.message};
            this.objMessageInfos.push(objMsgInfo);
        }
    }

    chunkArray(myArray, chunk_size){
        var results = [];
    
        while (myArray.length) {
            results.push(myArray.splice(0, chunk_size));
        }
        
        return results;
    }

    isNumeric(val) {
        return /^-?[\d.]+(?:e-?\d+)?$/.test(val);
    }

    //Sambath Seng - 17/12/2021 - US-001766 - fixing bulk upload
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

    CSVToArray() {
        var objPattern = new RegExp(("(\\" + this.selectedSeperator + "|\\r?\\n|\\r|^)" +"(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" + "([^\"\\" + this.selectedSeperator + "\\r\\n]*))"), "gi");
        var arrData = [[]];
        var arrMatches = null;
        while (arrMatches = objPattern.exec(this.fileContent)) {
            var strMatchedDelimiter = arrMatches[1];
            if (strMatchedDelimiter.length && (strMatchedDelimiter != this.selectedSeperator)) {
                arrData.push([]);
            }
            if (arrMatches[2]) {
                var strMatchedValue = arrMatches[2].replace(new RegExp("\"\"", "g"), "\"");
            }else {
                var strMatchedValue = arrMatches[3];
            } 
            arrData[arrData.length - 1].push(strMatchedValue);
        }
        return (arrData);
    }

    handleClickSubmit() {
        this.dealsComplete = [];
        this.dealSaveResult = [];
        this.objMessageResult = {};
        this.objMessageInfos = []; 
        this.isSomeFail = false;
        this.message = "";
        this.currentStep++;// SB 15.03.2023 US-0013185
        this.onProccessUpload(this.deals);
    }

    onProccessUpload(lstDeal){
        this.showLoadingSpinner = true;
        // chunk list of deal to small size for pass into apex
        var arrAllDeals = this.chunkArray(lstDeal, this.numberOfDealPerPk);
        this.onSubmitMultipleDeals(arrAllDeals, 0, arrAllDeals.length);
    }

    onSubmitMultipleDeals(arrAllDeals, index, total){ 
        if( index < total && arrAllDeals[index]){
            doSubmitMultipleDeals({lstDeals: arrAllDeals[index], accountId: this.accountId})
            .then(result => {
                index++;
                if(result['status'] == 'success'){
                    var srList = result["srList"];
                    this.dealSaveResult = this.dealSaveResult.concat(JSON.parse(srList));
                    if(result["lstDeals"]){
                        this.dealsComplete = this.dealsComplete.concat(result["lstDeals"]);
                    }
                }
                else {
                    this.isSomeFail = true;
                    this.message = result['message'];
                    if((this.message).includes("FIELD_CUSTOM_VALIDATION_EXCEPTION, There are non-cancelled deals with same Listing ID") ){
                        this.message = this.label.LWCBulkUploadCSVError14; 
                    }
                    if((this.message).includes("FIELD_CUSTOM_VALIDATION_EXCEPTION, Listing ID must be numeric and 12 characters in length") ){
                        this.message = this.label.LWCBulkUploadCSVError42;
                    }
                    if((this.message).includes("Cannot deserialize instance of")){
                        this.message =result['message'];
                    }
                } 
                if (index < total) {

                    this.onSubmitMultipleDeals(arrAllDeals, index, total);

                } else if(!this.isSomeFail && index == total){
                    this.onUpdateStatus();
                }
            })
            .catch(error => {
                this.isSomeFail = true;
                this.message = (error["body"] != undefined? error.body.message : error);
                this.message = (this.message=="Unable to read SObject's field value[s]"? this.label.LWCBulkUploadCSVError15 : this.message);
                var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : this.message};
                this.objMessageInfos.push(objMsgInfo);
                //SB 16.03.2023 US-0013185
                // Show error toast when facing error of process creating deal
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error on data save',
                        message: this.message,
                        variant: 'error',
                    }),
                );
                this.dealsComplete = [];
                this.isSomeFail = false;
                this.message = "";
                this.showLoadingSpinner = false;
            });
        }
    }

    onUpdateStatus() {
        this.isShowMessage = true;
        var allSaveResult = this.dealSaveResult;
        var totalSuccess = 0;// Sambath Seng 11.10.2022 US-0012737 - Incorrect error message when upload deal with duplicate item id
        for(var i = 0; i < allSaveResult.length; i++){
            var index = this.mRowIndex[i];
            if(allSaveResult[i]["success"] == false) {
                this.isSomeError = true;
                this.allMessageInfo[index]["cls_status"] = "cls_error";
                var msg = "";
                var errors = allSaveResult[i]["errors"];
                for(var x = 0; x < errors.length; x++){
                    msg += (msg==""? "":", ") + errors[x]["message"];
                }
                if(this.dd_DuplicateError != undefined && this.dd_DuplicateError != "" && this.mapErrorMessages[this.dd_DuplicateError] != undefined && msg.startsWith(this.dd_DuplicateError)){
                    msg = this.mapErrorMessages[this.dd_DuplicateError];
                }
                this.allMessageInfo[index]["message"] = "- " + this.label.RowNumber  + " "+(index+1)+". "+msg+"\n";
            } else totalSuccess++;// Sambath Seng 11.10.2022 US-0012737 - Incorrect error message when upload deal with duplicate item id
        }

        //SB 16.03.2023 US-0013185
        if(totalSuccess > 0){
            // Show success toast when deals create
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.thank_You_message,
                    variant: 'success'
                })
            );
        }

        if(this.isSomeError == false) {
            this.redirectToFutureDeals();
        }
        this.totalSuccess = totalSuccess;// Sambath Seng 11.10.2022 US-0012737 - Incorrect error message when upload deal with duplicate item id
        this.data = [];
        this.objMessageInfos = []; 
        this.doLoadCMT();
        this.showLoadingSpinner = false;
    }

    redirectToFutureDeals() {
        if(this.redirectToUrl != ""){
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                    url: this.redirectToUrl + (this.tabName !=""? "?"+ this.tabName : "") //'/ebh-deal/EBH_Deal__c/Default' + (this.tabName !=""? "?"+ this.tabName : "")
                }
            });
        }else {
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'home'
                },
            });
        }
    }

    doDownloadCSVTemplate(){
        // Creating anchor element to download
        let downloadElement = document.createElement('a');
        downloadElement.href = bulkUploadDealTemplateNA; //MN-14122021-US-0010945- Download the NA Template via Static Resource
        downloadElement.target = '_self';
        // CSV File Name
        downloadElement.download = "Bulk Deal Upload Template.csv"; 
        // below statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click();

        document.body.removeChild(downloadElement);
    }

    doDownloadExcelTemplate(){

         // 07.06.2023 / Sophal Noch / US-0013657

        // Creating anchor element to download
        let downloadElement = document.createElement('a');
        downloadElement.href = bulkUploadDealTemplateNAxL;
        downloadElement.target = '_self';
        // CSV File Name
        downloadElement.download = "Bulk Deal Upload Template.xlsx"; 
        // below statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click();

        document.body.removeChild(downloadElement);
    }

    handleUserGuideOpen(event){
        event.preventDefault();  // 07.06.2023 / Sophal Noch / US-0013657
        this.showUserGuide = true;
    }

    handleUserGuideClose(event){
        // 07.06.2023 / Sophal Noch / US-0013657
        this.showUserGuide = false;
    }

    cancelhandler() {
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                // SB 16-3-2022 US-0011312
                url: '/my-deal-lists'
            }
        });
    }
    //BR-17-10-2022-US-0012600
    handleAccountChange(event) {
        this.data = [];
        this.deals = [];
        this.file = null;
        this.fileName = '';
        this.isNoFile = true;
        this.accountId = event.detail["selectedVal"];
        this.doLoadCMT();
    }

    //SB 15.03.2023 US-0013185
    handleBack() {
        this.objMessageInfos = [];
        this.fileName = "";
        this.file = null;
        this.data = [];
        this.deals = [];
        this.mAllRecords = {};
        this.currentStep--;
    }

    handleBackToFirstStep() {
        this.objMessageInfos = [];
        this.fileName = "";
        this.file = null;
        this.data = [];
        this.deals = [];
        this.mAllRecords = {};
        this.currentStep = 1;
    }

    onPasteResult(event){

        // 07.06.2023 / Sophal Noch / US-0013657 :

        if(event.detail && event.detail['isSuccess'] && event.detail['mappedRows'] && event.detail['mappedRows'].length > 0){

            this.isNoFile = false;
            this.isDisableNextBtn = false;
            
            let arrAllLine = [];
            arrAllLine.push(event.detail['mappedColumns']);

            let allRowRecord = event.detail['mappedRows'];

            for(let i = 0; i < allRowRecord.length; i++){
                let rowRecord = [];
                for(let key in allRowRecord[i]){
                    if(allRowRecord[i].hasOwnProperty(key)) {
                        rowRecord.push(allRowRecord[i][key]);
                    }
                }
                arrAllLine.push(rowRecord);
            }

            this.csvReader(arrAllLine);
            this.currentStep++;
        }


    }

    // @track allRecords = [];
    // @track mAllRecords = {}
    // @api listRecord = [];
    // @track numberOfRecordPerPage=50;
    // @track totalPage = 0;
    // @track currentPage = 1;

    // onAssignRecords(){
    //     this.mAllRecords = {};
    //     var allRecord = [];
    //     var numPage = 0;
    //     var index = 0;
    //     for(var i =0; i< this.listRecord.length; i++){
    //         var obj = this.listRecord[i]; //{"is_Checked" : false, "index" : i, "id" : i,"EBH_ProductTitle__c" : "Test-"+i, "EBH_Status__c" : "PENDING", "EBH_DealStartDate__c" : Date.now(),"EBH_eBayLink__c" : "122345"+i,  "EBH_DealEndDate__c" : Date.now(), "EBH_Quantity__c" : 123, "EBH_SoldItems__c" : "1234","EBH_Category__c" : "Home Electronics"};
            
    //         obj["index"] = index;
    //         allRecord.push(obj);
    //         index++;
    //         if(allRecord.length == this.numberOfRecordPerPage){
    //             numPage++;
    //             this.mAllRecords[numPage] = allRecord;
    //             allRecord = [];
    //             index = 0;
    //         }
    //     }
    //     if(allRecord.length > 0){
    //         numPage++;
    //         this.mAllRecords[numPage] = allRecord;
    //     }

    //     this.totalPage = numPage;

    //     if (this.currentPage > this.totalPage) this.currentPage=1;
        
    //     this.allRecords = (this.mAllRecords[this.currentPage]? this.mAllRecords[this.currentPage]:[]);

    // }

    // updateCurrentPage(event)
    // {
    //     this.currentPage = event.detail.currentPage;
    // }
}