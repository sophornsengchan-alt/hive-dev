import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import doLoadSetting from '@salesforce/apex/ClsBulkUploadCSV.doLoadSettingLinkedAccount';
import doSubmitMultipleDeals from '@salesforce/apex/ClsBulkUploadCSV.doSubmitMultipleDeals';
import getDealRetailCampaign from '@salesforce/apex/ClsBulkUploadCSV.getDealRetailCampaign';
import bulkUploadDealTemplateIT from '@salesforce/resourceUrl/SEP_Bulk_Upload_Deal_Template_IT';
import bulkUploadDealTemplateITXL from '@salesforce/resourceUrl/SEP_Bulk_Upload_Deal_Template_IT_XL'; //MN-24072023-US-0013835
import dealbulkUploadITStep1 from '@salesforce/resourceUrl/Deal_Bulk_Upload_IT_Step1'; //MN-24072023-US-0013835
import dealbulkUploadITStep2 from '@salesforce/resourceUrl/Deal_Bulk_Upload_IT_Step2'; //MN-24072023-US-0013835
import dealbulkUploadITStep3 from '@salesforce/resourceUrl/Deal_Bulk_Upload_IT_Step3'; //MN-24072023-US-0013835
import dealbulkUploadITStep4 from '@salesforce/resourceUrl/Deal_Bulk_Upload_IT_Step4'; //MN-24072023-US-0013835
import ebayLogo from '@salesforce/resourceUrl/eBayLogo'; //MN-24072023-US-0013835
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
import LWCBulkUploadCSVError46 from '@salesforce/label/c.LWCBulkUploadCSVError46';
import RowNumber from '@salesforce/label/c.Row_Number';
import Cancel from '@salesforce/label/c.lwcCancelbtn';
import DealRecordsCreatedPartSuccess from '@salesforce/label/c.DealRecordsCreatedPartSuccess';
import DealRecordsCreatedPartError from '@salesforce/label/c.DealRecordsCreatedPartError';
import DRC_Inline_info from '@salesforce/label/c.DRC_Inline_info';
import PleaseSelectTheEBayAccount from '@salesforce/label/c.Please_select_the_eBay_Account';
import btn_back from '@salesforce/label/c.SEP_BACK_BUTTON';
import thank_You_message from '@salesforce/label/c.Thank_You_message';
import dealBulkUpload_HelpMessage from '@salesforce/label/c.dealBulkUpload_HelpMessage';
import dealBulkUploadBtnDownloadUserGuide  from '@salesforce/label/c.dealBulkUploadBtnDownloadUserGuide';  //MN-24072023-US-0013835
import dealBulkUploadBtnDownloadXL  from '@salesforce/label/c.dealBulkUploadBtnDownloadXL';  //MN-24072023-US-0013835
import UploadUserGuide  from '@salesforce/label/c.UploadUserGuide';  //MN-24072023-US-0013835
import closeBtn from '@salesforce/label/c.Close'; //MN-24072023-US-0013835

export default class DealBulkUploadIT extends NavigationMixin(LightningElement) {
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
    @api showUserGuide = false;  //MN-24072023-US-0013835

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
    //@track csvHeader1  = 'ID oggetto eBay,Prezzo dell\'offerta,Prezzo consigliato/ultimo prezzo,Quantità,Massimo di vendite,Commenti';
    //@track csvHeader2  = '"ID oggetto eBay","Prezzo dell\'offerta","Prezzo consigliato/ultimo prezzo","Quantità","Massimo di vendite","Commenti"';

    //MN-24072023-US-0013835
    @track csvHeader1  = 'ID prodotto eBay,Prezzo consigliato/ultimo prezzo,Prezzo dell\'offerta,Quantità,Massimo di vendite,Codice prodotto,Commenti';
    @track csvHeader2  = '"ID oggetto eBay","Prezzo consigliato/ultimo prezzo","Prezzo dell\'offerta","Quantità","Massimo di vendite","Codice prodotto","Commenti"';
    
    @track defaulCols = [
        { label: '', fieldName: 'row_number', type: 'number', initialWidth: 50},
        { label: 'Status', fieldName: 'status', type: 'text',wrapText: true, initialWidth: 310, cellAttributes: { alignment: 'center' ,class: { fieldName: 'cls_status' } }},                       
        { label: 'ID prodotto eBay*', fieldName: 'EBH_eBayItemID__c', type: 'text'},
        { label: 'Prezzo consigliato/ultimo prezzo*', fieldName: 'EBH_RRPWASPrice__c', type: 'text', initialWidth: 300, typeAttributes: {  step: '0.001'}},//currencyCode: 'USD',
        { label: 'Prezzo dell\'offerta*', fieldName: 'EBH_DealPrice__c', type: 'text', initialWidth: 250, typeAttributes: { step: '0.001'}},//currencyCode: 'USD', //SB 11.05.2023 US-0013640
        { label: 'Quantità*', fieldName: 'EBH_Quantity__c', type: 'text', initialWidth: 160},
        { label: 'Massimo di vendite*', fieldName: 'EBH_MaximumPurchases__c', type: 'text', initialWidth: 160},
        { label: 'Codice prodotto', fieldName: 'SKU_Number__c', type: 'text'}, //MN-24072023-US-0013835
        { label: 'Commenti', fieldName: 'EBH_CommentfromSeller__c', type: 'text'}
    ]; 
    @track requiredDealFields = ["EBH_eBayItemID__c", "EBH_DealPrice__c", "EBH_RRPWASPrice__c", "EBH_Quantity__c","EBH_MaximumPurchases__c"]; //MN-24072023-US-0013835:Added EBH_MaximumPurchases__c
    @track totalSuccess = 0;
    @track isUnableUpload = false;
    @track currentStep = 1;

    @track UPLOAD_IT_DEAL_MTD_NAME = 'SEP_Upload_IT_Deal';  //MN-24072023-US-0013835
    @track CREATED_FROM_XL = 'Excel';   //MN-24072023-US-0013835
    @track CREATED_FROM_CSV = 'CSV';   //MN-24072023-US-0013835
    @track CREATED_FROM_FLD_NAME = 'Created_From__c'; //MN-24072023-US-0013835
    @track ebayLogo = ebayLogo; //MN-24072023-US-0013835
    @track dealbulkUploadITStep1 = dealbulkUploadITStep1; //MN-24072023-US-0013835
    @track dealbulkUploadITStep2 = dealbulkUploadITStep2; //MN-24072023-US-0013835
    @track dealbulkUploadITStep3 = dealbulkUploadITStep3; //MN-24072023-US-0013835
    @track dealbulkUploadITStep4 = dealbulkUploadITStep4; //MN-24072023-US-0013835


    file;
    fileContent;
    fileReader;

    label = {LWCBulkUploadCSVError1, LWCBulkUploadCSVError2, LWCBulkUploadCSVError3,LWCBulkUploadCSVError4,LWCBulkUploadCSVError5,
        LWCBulkUploadCSVError6,LWCBulkUploadCSVError8,LWCBulkUploadCSVError10,LWCBulkUploadCSVError11,LWCBulkUploadCSVError13,
        LWCBulkUploadCSVError12,LWCBulkUploadCSVError14,LWCBulkUploadCSVError15,LWCBulkUploadCSVError16,
        LWCBulkUploadCSVError41,LWCBulkUploadCSVError42,LWCBulkUploadCSVError46,RowNumber, Cancel, DealRecordsCreatedPartSuccess, DealRecordsCreatedPartError,
        DRC_Inline_info, PleaseSelectTheEBayAccount,btn_back,thank_You_message,dealBulkUpload_HelpMessage
        ,dealBulkUploadBtnDownloadUserGuide, dealBulkUploadBtnDownloadXL, UploadUserGuide, closeBtn //MN-24072023-US-0013835
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
        return this.isUnableUpload || this.accountId == undefined || this.accountId=="";
    }
    get isShowTable(){
        return this.data.length > 0;
    }
    get jsonData(){
        return this.data;
    }
    get totalRecord() {
        return this.totalRec;
    }
    get allObjMessageInfos(){
        return this.objMessageInfos;
    }
    get showMessageResults() {
        var messageErrors = [];
        for(var i =0; i < this.allMessageInfo.length; i++){
            var obj = this.allMessageInfo[i];
            if(obj["cls_status"] == "cls_error") {
                messageErrors.push(obj["message"]);
            }
        }
        this.objMessageResult["isHasSuccess"] = (messageErrors.length == 0);
        this.objMessageResult["totalSuccess"] = this.totalSuccess;

        this.objMessageResult["isHasError"] = (messageErrors.length > 0);
        this.objMessageResult["lstError"] = messageErrors;
        return this.objMessageResult;
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
        doLoadSetting({dealReatilCampaingId : this.recordId, accountId: this.accountId})
        .then(result => {
            // console.log('**** doLoadSetting :: ', result);
            this.objMessageInfos = [];
            this.isSomeError = false;
            var status = "error";
            var msg = "";
            var objMsgInfo;
            if(result["status"] == "success"){
                this.dd_DuplicateError = result["dd_DuplicateError"];
                this.email = result["conEmail"];
                this.contactId = result["contactId"];
                this.fullContactName = result["fullContactName"];
                this.availableDeal = result.availableDeal;
                if(this.availableDeal > 0){
                    this.isUnableUpload = false;
                    this.isReachLimit = false;
                    status = "info";  
                    msg = this.label.LWCBulkUploadCSVError1.replace(" x "," "+ this.availableDeal +" "); //"You may upload up to another "+ this.availableDeal + (this.currUserLang == "DE - Seller Portal"? " Deals.":" Deals in this Deal Window.");
                    objMsgInfo = {className : "cls_message-info", mainMsg : this.country == 101?"Nota:":"INFORMATION -", detailMsg : msg};
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

    csvReader(arrAllLine){ //MN-24072023-US-0013835:Added param arrAllLine
        try{
            this.isDisableNextBtn = true;
            this.isShowMessage = false;
            this.isSomeError = false;
            this.allMessageInfo = [];
            this.mRowIndex = {};
            var duplicateEbayIds = [];
            var duplicateRows = [];
            var mDuplicateRow = {};
            var excludeItemIds = [];

            var ebayIds = [];
            //var allTextLines = this.CSVToArray();
            var allTextLines = arrAllLine ? arrAllLine : this.CSVToArray(); //MN-24072023-US-0013835
            var isFromCopyPaste = arrAllLine ? true : false; //MN-24072023-US-0013835
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
                                    msgEbayItem = this.label.LWCBulkUploadCSVError42; 
                                    isInvalidId = true;
                                    continue;
                                }
                            }
                        }

                        //MN-25072023-US-0013835: Make sure to allow , as decimal
                        if (colName == "EBH_RRPWASPrice__c" || colName == "EBH_DealPrice__c") {
                            if(!this.checkPriceFormat(val,16,2)) {
                                msgNumeric += (msgNumeric==""? "" :", ") +cols[x+2].label;
                                isValueInvalidFormat = true;
                                continue;
                            }
                        }

                        //MN-25072023-US-0013835: Validate number
                        if(val != "" && (colName == "EBH_eBayItemID__c" || colName == "EBH_Quantity__c" || colName == "EBH_MaximumPurchases__c")) {
                            if(!this.isNumeric(val) || !this.isInt(val) || val.length > 18) { 
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
                        /* MN-03082023-US-0013835: Instead of showing only one error message type, we will combine those error message types and display all at once
                        var errorMsg = (isInvalidId == true ? msgEbayItem : "");
                        if(msg != ""){
                            errorMsg = this.label.LWCBulkUploadCSVError5.replace("<fields> ", " ["+ msg + "] ")+" ";
                        }
                        if(msgNumeric != "") {
                            errorMsg = this.label.LWCBulkUploadCSVError6.replace("<fields> ", " ["+ msgNumeric + "] ")+" ";
                        }
                        */

                        // MN-03082023-US-0013835: Instead of showing only one error message type, we will combine those error message types and display all at once -- START
                        var errorMsg = "";

                        if (isInvalidId) errorMsg = msgEbayItem;
                        if (msg != "") {
                            var tmp = this.label.LWCBulkUploadCSVError5.replace("<fields> ", " ["+ msg + "] ")+" ";
                            errorMsg += (errorMsg==""? "" :", ") + tmp;
                        }
                        if (msgNumeric != "") {
                            var tmp = this.label.LWCBulkUploadCSVError6.replace("<fields> ", " ["+ msgNumeric + "] ")+" ";
                            errorMsg += (errorMsg==""? "" :", ") + tmp;
                        }
                        // -- END - MN-03082023-US-0013835

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
                    deal["EBH_SellerEmail__c"] = this.email;
                    deal["EBH_Status__c"] = "Processing"; 
                    deal[this.CREATED_FROM_FLD_NAME] = isFromCopyPaste ?  this.CREATED_FROM_XL : this.CREATED_FROM_CSV; //MN-24072023-US-0013835
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
                            if(!excludeItemIds.includes(ebayItem)) excludeItemIds.push(ebayItem);
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
                
                var dealForUpload = this.label.LWCBulkUploadCSVError12;
                dealForUpload = dealForUpload.replace(" x ", " "+ tDeals.length + " ");
                if(tDeals.length > 0) {
                    var objMsgInfo = {className : 'cls_message-info cls_message-success', mainMsg : '', detailMsg : dealForUpload}; //' vailable deals in your file for upload!'};
                    this.objMessageInfos.push(objMsgInfo);
                    this.showLoadingSpinner = false;
                }else {
                    this.showLoadingSpinner = false;
                    var dealForUpload = this.label.LWCBulkUploadCSVError46;
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

    //MN-25072023-US-0013835: Validate Number field
    isInt(val) {
        var intRegex = /^-?\d+$/;
        if (!intRegex.test(val))
            return false;
    
        var intVal = parseInt(val, 10);
        return parseFloat(val) == intVal && !isNaN(intVal);
    }

    //MN-25072023-US-0013835: Validate Currency/Decinmal field
    checkPriceFormat(val, index0, index1) {
        val = val.replace(".","/").replace(",",".");//LA-13-12-2021:US-0010738 - [SP - EU Deals] [Bug] Align Seller Price accepted values on Bulk upload with Single deal form
        var arrVal = val.split(".");
        if(arrVal.length == 2 && (this.isNumeric(arrVal[0]) && arrVal[0]).length <= index0 && this.isNumeric(arrVal[1]) && (arrVal[1]).length <= index1){
            return true;
        } else if ( arrVal.length < 2 && this.isNumeric(arrVal[0]) && (arrVal[0]).length <= index0){
            return true;
        } else {
            return false;
        }
    }

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
        this.currentStep++;
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
        var totalSuccess = 0;
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
            } else totalSuccess++;
        }

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
        this.totalSuccess = totalSuccess;
        this.label.DealRecordsCreatedPartSuccess = this.label.DealRecordsCreatedPartSuccess.replace(" X ", " "+ totalSuccess + " ");
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
        downloadElement.href = bulkUploadDealTemplateIT;
        downloadElement.target = '_self';
        // CSV File Name
        downloadElement.download = "Modello di caricamento in massa di Imperdibili.csv"; 
        // below statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click();
    }

    //MN-24072023-US-0013835
    doDownloadExcelTemplate(){

       // Creating anchor element to download
       let downloadElement = document.createElement('a');
       downloadElement.href = bulkUploadDealTemplateITXL;
       downloadElement.target = '_self';
       // CSV File Name
       downloadElement.download = "Modello di caricamento in massa di Imperdibili.xlsx"; 
       // below statement is required if you are using firefox browser
       document.body.appendChild(downloadElement);
       // click() Javascript function to download CSV file
       downloadElement.click();

       document.body.removeChild(downloadElement);
    }

    //MN-24072023-US-0013835
    handleUserGuideOpen(event){
        
        event.preventDefault(); 
        this.showUserGuide = true;
        
    }

    //MN-24072023-US-0013835
    handleUserGuideClose(event){
        this.showUserGuide = false;
    }

    cancelhandler() {
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: '/my-deal-lists'
            }
        });
    }

    handleAccountChange(event) {
        this.data = [];
        this.deals = [];
        this.file = null;
        this.fileName = '';
        this.isNoFile = true;
        this.accountId = event.detail["selectedVal"];
        this.doLoadCMT();
    }

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

    //MN-24072023-US-0013835
    onPasteResult(event){

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
}