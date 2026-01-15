/*********************************************************************************************************************************
@ Author:         vadhanak
@ Purpose:        US-0016262 - 10 - Seller Portal - Upload Sub Deals
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.02.2025 / vadhanak voun / Created the component.(replicated from dealBulkUploadNA)
@               : 31.03.2025 / vadhanak voun / US-0016977 - Bulk Upload - Business and internal Testing feedback
@               : 18.04.2025 / vadhanak voun / US-0017104 - Invalid CSV Error message update and SP updates
@               : 24.02.2025/ Chansophorn Seng/ US-0017008 - Upload Items link should provide proper error message when clicked in non upload status
@               : 06.06.2025/ Chansophorn Seng/ US-0032894 - Show the Row numbers including the Row Header
*********************************************************************************************************************************/
import { LightningElement ,api, track} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import doLoadSetting from '@salesforce/apex/DealBulkUploadDcaSubController.doLoadSettingLinkedAccount';
import submitDeals from '@salesforce/apex/DealBulkUploadDcaSubController.submitDeals';
import apexProcessPostDMLSEP from '@salesforce/apex/ExcelImporterControllerSEP.apexProcessPostDMLSEP';
// import getDealRetailCampaign from '@salesforce/apex/ClsBulkUploadCSV.getDealRetailCampaign';     getDCADetail

import { validateTimeString,validateDateString,convertToStandardDateFormat,convertTimeFormat,compareDates,getTodayDateString,isNullorUndefinedorZero,safeParseFloat,safeParseInt } from "c/hiveUtils";

import bulkUploadDealTemplateNA from '@salesforce/resourceUrl/SEP_Bulk_Upload_Deal_Template_NA';
import bulkUploadDealTemplateNAxL from '@salesforce/resourceUrl/Deal_Bulk_Upload_template_from_dca_sep';
import dealbulkUploadNaStep1 from '@salesforce/resourceUrl/Deal_Bulk_Upload_NA_Step1';
import dealbulkUploadNaStep2 from '@salesforce/resourceUrl/Deal_Bulk_Upload_NA_Step2';
import dealbulkUploadNaStep3 from '@salesforce/resourceUrl/Deal_Bulk_Upload_NA_Step3';
import dealbulkUploadNaStep4 from '@salesforce/resourceUrl/Deal_Bulk_Upload_NA_Step4';
import ebayLogo from '@salesforce/resourceUrl/eBayLogo';

import LWCBulkUploadCSVError1DCASub from '@salesforce/label/c.LWCBulkUploadCSVError1DCASub';
import dealBulkUploadDCASub_Error_ReachLimit from '@salesforce/label/c.dealBulkUploadDCASub_Error_ReachLimit';
import LWCBulkUploadCSVError3 from '@salesforce/label/c.LWCBulkUploadCSVError3';
import LWCBulkUploadCSVError4 from '@salesforce/label/c.LWCBulkUploadCSVError4';
import LWCBulkUploadCSVError5 from '@salesforce/label/c.LWCBulkUploadCSVError5';
import LWCBulkUploadCSVError6 from '@salesforce/label/c.LWCBulkUploadCSVError6';
import LWCBulkUploadCSVError8 from '@salesforce/label/c.LWCBulkUploadCSVError8';
import LWCBulkUploadCSVError10 from '@salesforce/label/c.LWCBulkUploadCSVError10';
import LWCBulkUploadCSVError11 from '@salesforce/label/c.LWCBulkUploadCSVError11';
import LWCBulkUploadCSVError12 from '@salesforce/label/c.LWCBulkUploadCSVError12';
import dealBulkUploadDCASub_Error_InvalidXLS from '@salesforce/label/c.dealBulkUploadDCASub_Error_InvalidXLS';
import LWCBulkUploadCSVError14 from '@salesforce/label/c.LWCBulkUploadCSVError14';
import LWCBulkUploadCSVError15 from '@salesforce/label/c.LWCBulkUploadCSVError15';
import LWCBulkUploadCSVError16 from '@salesforce/label/c.LWCBulkUploadCSVError16';
import LWCBulkUploadCSVError41 from '@salesforce/label/c.LWCBulkUploadCSVError41';
import LWCBulkUploadCSVError42 from '@salesforce/label/c.LWCBulkUploadCSVError42';

import dealBulkUploadDCASub_Error_DealShouldInFuture from '@salesforce/label/c.dealBulkUploadDCASub_Error_DealShouldInFuture';
import dealBulkUploadDCASub_Error_DealDateFomat from '@salesforce/label/c.dealBulkUploadDCASub_Error_DealDateFomat';
import dealBulkUploadDCASub_Error_DealEndDateShouldBiger from '@salesforce/label/c.dealBulkUploadDCASub_Error_DealEndDateShouldBiger'; 
import dealBulkUploadDCASub_Error_DealTimeFomat from '@salesforce/label/c.dealBulkUploadDCASub_Error_DealTimeFomat';
import dealBulkUpload_ErrReachLimit from '@salesforce/label/c.dealBulkUpload_ErrReachLimit';

import RowNumber from '@salesforce/label/c.Row_Number';
import Cancel from '@salesforce/label/c.lwcCancelbtn';
import DealRecordsCreatedPartSuccess from '@salesforce/label/c.DealRecordsCreatedPartSuccess';

import DealRecordsCreatedPartError from '@salesforce/label/c.DealRecordsCreatedPartError';
import DRC_Inline_info from '@salesforce/label/c.DRC_Inline_info';
import PleaseSelectTheEBayAccount from '@salesforce/label/c.Please_select_the_eBay_Account';
import btn_back from '@salesforce/label/c.SEP_BACK_BUTTON';
import thank_You_message from '@salesforce/label/c.Thank_You_message';
import dealBulkUpload_HelpMessage_DCASub from '@salesforce/label/c.dealBulkUpload_HelpMessage_DCASub';
import dealBulkUploadBtnDownloadUserGuide  from '@salesforce/label/c.dealBulkUploadBtnDownloadUserGuide';
import dealBulkUploadBtnDownloadXL  from '@salesforce/label/c.dealBulkUploadBtnDownloadXL';
import UploadUserGuide  from '@salesforce/label/c.UploadUserGuide';
import closeBtn from '@salesforce/label/c.Close';
import dealBulkUploadDCASub_Error_ListPriceLessThanDeal from '@salesforce/label/c.dealBulkUploadDCASub_Error_ListPriceLessThanDeal';
import  dealBulkUploadDCASub_Error_LP_SP_DP_Negative_Null from '@salesforce/label/c.dealBulkUploadDCASub_Error_LP_SP_DP_Negative_Null';
import dealBulkUploadDCASub_Error_QTY_Negative_Null from '@salesforce/label/c.dealBulkUploadDCASub_Error_QTY_Negative_Null';
import dealBulkUploadDCASub_Success_Thankyou from '@salesforce/label/c.dealBulkUploadDCASub_Success_Thankyou';
import dealBulkUploadDCASub_Msg_PleaseWait from '@salesforce/label/c.dealBulkUploadDCASub_Msg_PleaseWait';
import dealBulkUploadDCASub_Msg_PleaseWaitUpload from '@salesforce/label/c.dealBulkUploadDCASub_Msg_PleaseWaitUpload';
import dealBulkUploadDCASub_Error_DealPriceLessSellerPrice from '@salesforce/label/c.dealBulkUploadDCASub_Error_DealPriceLessSellerPrice';
//24.02.2025/ Chansophorn Seng/ US-0017008
import DealSubmissionDCACloseErrorMessage from '@salesforce/label/c.DealSubmissionDCACloseErrorMessage';

    
export default class DealBulkUploadDcaSub extends NavigationMixin(LightningElement) {

    @api tabName = "";
    @api recordId;
    // @api startDate;
    // @api endDate;
    // @api country;
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
    @api showUserGuide = false;

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
    @track mRowItemId = {}; //CSP - US-0032894
    @track selectedSeperator = ',';
    @track dd_DuplicateError = "";
    @track mapErrorMessages = {};
    @track csvHeader1  = '';//'ebay Item Id,Deal Price,List Price,Quantity,Maximum Purchases,Sellers Deal Price MSKU Lower,Sellers Deal Price MSKU Upper,List Price MSKU Lower,List Price MSKU Upper';
  
    @track defaulCols = [
        { label: '', fieldName: 'row_number', type: 'number', initialWidth: 50},
        { label: 'Status', fieldName: 'status', type: 'text',wrapText: true, initialWidth: 350, cellAttributes: { alignment: 'left' ,class: { fieldName: 'cls_status' } }},                       
        { label: 'ebay Item Id*', fieldName: 'EBH_eBayItemID__c', type: 'text',initialWidth: 160},        
        { label: 'Item Title*', fieldName: 'EBH_ProductTitle__c', type: 'text',initialWidth: 200},
        { label: 'Seller Price(without subsidy)*', fieldName: 'EBH_SellerPrice__c', type: 'currency', initialWidth: 180, typeAttributes: { currencyCode: 'USD', step: '0.001'}},
        { label: 'Ideal Deal Price (with subsidy)*', fieldName: 'EBH_DealPrice__c', type: 'currency', initialWidth: 180, typeAttributes: { currencyCode: 'USD', step: '0.001'}},
        { label: 'List Price', fieldName: 'EBH_RRPWASPrice__c', type: 'currency', initialWidth: 140, typeAttributes: { currencyCode: 'USD', step: '0.001'}},
        
        { label: 'Quantity*', fieldName: 'EBH_Quantity__c', type: 'number', initialWidth: 100},
        { label: 'Maximum Purchases*', fieldName: 'EBH_MaximumPurchases__c', type: 'number', initialWidth: 160},
        
        { label: 'Deal_Start_Date*', fieldName: 'EBH_DealStartDate__c', type: 'text', initialWidth: 160},
        { label: 'Deal_Start_Time*', fieldName: 'EBH_DealStartTime__c', type: 'text', initialWidth: 160},
        { label: 'Deal_End_Date*', fieldName: 'EBH_DealEndDate__c', type: 'text', initialWidth: 160},
        { label: 'Deal_End_Time*', fieldName: 'EBH_DealEndTime__c', type: 'text', initialWidth: 160},
        { label: 'Item Condition/ Comments', fieldName: 'EBH_CommentfromSeller__c', type: 'text', initialWidth: 200}
    ]; 
    @track requiredDealFields = [];//["EBH_eBayItemID__c", "EBH_DealPrice__c", "EBH_RRPWASPrice__c", "EBH_Quantity__c", "EBH_MaximumPurchases__c", "EBH_SellerPrice__c", "EBH_Dealdateearliestpossible__c", "EBH_ProductTitle__c"];
    @track totalSuccess = 0;
    @track isUnableUpload = false;
    @track currentStep = 1;
    @track UPLOAD_NA_DEAL_MTD_NAME ='SEP_Upload_Deal_DCA';//for subdeal // 'SEP_Upload_NA_Deal';
    @track CREATED_FROM_XL = 'Excel';
    @track CREATED_FROM_CSV = 'CSV';
    @track CREATED_FROM_FLD_NAME = 'Created_From__c';
    @track ebayLogo = ebayLogo;
    @track dealbulkUploadNaStep1 = dealbulkUploadNaStep1;
    @track dealbulkUploadNaStep2 = dealbulkUploadNaStep2;
    @track dealbulkUploadNaStep3 = dealbulkUploadNaStep3;
    @track dealbulkUploadNaStep4 = dealbulkUploadNaStep4;

    file;
    fileContent;
    fileReader;
    isDealSubmissionDCAAllowUpload;
    isLoadingConfig=false;
    

    label = {LWCBulkUploadCSVError1DCASub, dealBulkUploadDCASub_Error_ReachLimit, LWCBulkUploadCSVError3,LWCBulkUploadCSVError4,LWCBulkUploadCSVError5,
        LWCBulkUploadCSVError6,LWCBulkUploadCSVError8,LWCBulkUploadCSVError10,LWCBulkUploadCSVError11,dealBulkUploadDCASub_Error_InvalidXLS,
        LWCBulkUploadCSVError12,LWCBulkUploadCSVError14,LWCBulkUploadCSVError15,LWCBulkUploadCSVError16,
        LWCBulkUploadCSVError41,LWCBulkUploadCSVError42,RowNumber, Cancel, DealRecordsCreatedPartSuccess, DealRecordsCreatedPartError,
        DRC_Inline_info, PleaseSelectTheEBayAccount,btn_back,thank_You_message,dealBulkUpload_HelpMessage_DCASub, 
        dealBulkUploadBtnDownloadUserGuide, dealBulkUploadBtnDownloadXL, UploadUserGuide, closeBtn,

        dealBulkUploadDCASub_Error_DealShouldInFuture,dealBulkUploadDCASub_Error_DealDateFomat,
        dealBulkUploadDCASub_Error_DealEndDateShouldBiger,dealBulkUploadDCASub_Error_DealTimeFomat,
        dealBulkUpload_ErrReachLimit,
        dealBulkUploadDCASub_Error_ListPriceLessThanDeal,dealBulkUploadDCASub_Error_LP_SP_DP_Negative_Null,dealBulkUploadDCASub_Error_QTY_Negative_Null,
        dealBulkUploadDCASub_Success_Thankyou,dealBulkUploadDCASub_Msg_PleaseWait,dealBulkUploadDCASub_Msg_PleaseWaitUpload,
        dealBulkUploadDCASub_Error_DealPriceLessSellerPrice,
        DealSubmissionDCACloseErrorMessage
    };

    spinnerText = this.label.dealBulkUploadDCASub_Msg_PleaseWait;   //default
    totalDealToUpload = 0;

    VALID_DATE_FORMAT = "MM/DD/YYYY";   //from upload
    SFDC_DATE_FORMAT = "YYYY-MM-DD";    //into the system
    metadata;
    mapFieldType = {};
    mapNewValidationFields = {ebh_dealstartdate__c:true,ebh_dealstarttime__c:true,ebh_dealenddate__c:true,ebh_dealendtime__c:true};

    //not validate in validateFormat but in validateAdditionalRules to have proper error message
    // notValidateFormat = {EBH_Quantity__c:true,EBH_DealPrice__c:true,EBH_SellerPrice__c:true,EBH_RRPWASPrice__c:true};

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
        let messageErrors = [];
        // var totalSuccess = 0;
        for(let i =0; i < this.allMessageInfo.length; i++){
            let obj = this.allMessageInfo[i];
            if(obj.cls_status == "cls_error") {
                messageErrors.push(obj.message);
            }
            // else  totalSuccess++;
        }
        this.objMessageResult.isHasSuccess = (messageErrors.length == 0);
        this.objMessageResult.totalSuccess = this.totalSuccess;

        this.objMessageResult.isHasError = (messageErrors.length > 0);
        this.objMessageResult.lstError = messageErrors;
        return this.objMessageResult;
    }

    get shouldShowErrorMessageNotAllowUpload() {
        return !this.isDealSubmissionDCAAllowUpload && !this.isLoadingConfig;
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
        this.recordId = params.recordId; 
        this.doLoadConfig();

        // this.showLoadingSpinner = true;
    }

    doLoadConfig(){
        this.isLoadingConfig = true;
        doLoadSetting({metaData:this.UPLOAD_NA_DEAL_MTD_NAME, dcaId : this.recordId, sellerId: this.accountId})        
        .then(result => {
            this.objMessageInfos = [];
            this.isSomeError = false;
            let status = "error";
            let msgLoad = "";
            let objMsgInfo;
            if(result["status"] == "success"){
                this.metadata = result.metadata;
                this.csvHeader1 = result.metadata.Excel_Column_Names__c;
                this.requiredDealFields = result.metadata.Required_Fields__c?result.metadata.Required_Fields__c.split(";"):[];
                this.numberOfDealPerPk = result.metadata.Batch_Size__c;
                this.constructMapFieldType();

                this.dd_DuplicateError = result.dd_DuplicateError;
                this.email = result.conEmail;
                this.accountId = result.sellerDCA?result.sellerDCA.substring(0, 15):'';//NK:08/04/2025: for link account .lwc picker returns 15 char
                this.contactId = result.contactId;
                this.fullContactName = result.fullContactName;
                this.availableDeal = result.availableDeal;
                this.isDealSubmissionDCAAllowUpload = result.isDealSubmissionDCAAllowUpload; //CSP:24.02.2025: US-0017008 
                
                if(this.availableDeal > 0){
                    this.isUnableUpload = false;
                    this.isReachLimit = false;
                    status = "info";
                    msgLoad = this.label.LWCBulkUploadCSVError1DCASub.replace(" x "," "+ this.availableDeal +" "); 
                    objMsgInfo = {className : "cls_message-info", mainMsg : "INFORMATION -", detailMsg : msgLoad};
                }else {
                    this.isUnableUpload = true;
                    msgLoad = this.label.dealBulkUploadDCASub_Error_ReachLimit;
                    objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msgLoad};
                }

                this.doMapErrorMessages();
            }else {
                this.isUnableUpload = true;
                this.isReachLimit = true;
                msgLoad = result.message;
                objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msgLoad};
            }
            this.objMessageInfos.push(objMsgInfo);
            // this.doLoadDealRetailCampaign();

            
        })
        .catch(error => { 
            console.log("first load ERROR::", error);
        }).finally(() =>{
            this.isLoadingConfig = false;
        })
    }

 

    doMapErrorMessages(){
        this.mapErrorMessages[this.dd_DuplicateError] = this.label.LWCBulkUploadCSVError16;
    }

     

    csvReader(arrAllLine){
        try{
            this.isDisableNextBtn = true;
            this.isShowMessage = false;
            this.isSomeError = false;
            this.allMessageInfo = [];
            this.mRowIndex = {};
            let duplicateEbayIds = [];
            let duplicateRows = [];
            let mDuplicateRow = {};
            let excludeItemIds = [];

            let ebayIds = [];
            // var allTextLines = this.CSVToArray();
            // let allTextLines = arrAllLine ? arrAllLine : this.CSVToArray();
            let allTextLines = arrAllLine;
            let isFromCopyPaste = true;//arrAllLine ? true : false
            let csvHeader = allTextLines[0];
            // console.log("csvHeader",JSON.stringify(csvHeader));

            if(this.validateHeader(csvHeader,this.csvHeader1))
            {
                let tempData = [];
                let tempDeals = [];
                let cols = this.defaulCols;

                //Invalid CSV file
                if((allTextLines[0]).length !== cols.length - 2){
                    let objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : this.label.LWCBulkUploadCSVError3};
                    this.objMessageInfos.push(objMsgInfo);
                    this.showLoadingSpinner = false;
                    return;
                }
                if(this.availableDeal > 0) this.isReachLimit = false;
                let index = 0;
                let tempMIndex = {};
                let mIdRowNum = {};
                let rowNumber = 0;
                let rowT = 0;
                let mAllRowNumber = {};
                for(let i = 1; i < allTextLines.length; i++) 
                {
                    rowNumber++;
                    rowT++;
                    let msgRequired = "";
                    let msgInvalidFormat = "";
                    let fieldsInvalidFormat = [];
                    let isValueInvalidFormat = false;
                    let isInvalidId = false;
                    let rowIncomplete = false;
                    // let msgEbayItem = "";

                    let allCols = allTextLines[i];

                    //console.log("allCols",JSON.stringify(allCols));

                    if(allCols.length !== cols.length-2) continue;

                    let deal = { "sobjectType": "EBH_Deal__c" };
                    let row = {};
                    row.id = i;
                    let isRowEmpty = true;

                    for(let x= 0; x < allCols.length; x++) 
                    {
                        let colName = cols[x+2].fieldName;
                        let fieldLabel = cols[x+2].label;
                        //let fieldType = cols[x+2].type;
                        if(colName === "status" || colName === "row_number") continue;
                        let val = allCols[x]? allCols[x] : "";
                        if(val !== undefined && val !== "" && val !== " ") {
                            isRowEmpty = false;
                        }
                        row[colName] = val;
                        
                        
                        if(row[colName] === "" && this.requiredDealFields.includes(colName))
                        {
                            msgRequired += (msgRequired===""? "" :", ") +fieldLabel;
                            rowIncomplete = true;
                            continue;
                        }

                        let validateResult = this.validateFormat(val, colName);
                        
                        if(val !== "" && validateResult) 
                        {
                            //console.log("isValueInvalidFormat",isValueInvalidFormat+"   F: "+colName + "  val: " +val);                
                            
                            isValueInvalidFormat = true;
                            let colNameLow = colName.toLocaleLowerCase();
                            //new msg for specifi fields
                            if(this.mapNewValidationFields[colNameLow])
                            {
                                fieldsInvalidFormat.push({fname:colNameLow,flabel: fieldLabel});
                            }else   //existing validation msg format
                            {
                                msgInvalidFormat += (msgInvalidFormat===""? "" :", ") +fieldLabel;
                            }
                           
                            if(colName==="EBH_eBayItemID__c")
                            {
                                isInvalidId = true;
                                msgInvalidFormat += (msgInvalidFormat===""? "" :", ") +fieldLabel;
                                msgInvalidFormat = this.label.LWCBulkUploadCSVError4;
                            }
                            continue;
                        }

                        deal[colName] = this.correctData(val,colName); //make sure the data is in the correct type. not always string

                    }////////////////////////////////////////////////////////end loop cols


                    let strRow = (allTextLines[i]).join();
                    if (allTextLines[i][0] !== "" && (duplicateRows.includes(strRow) || isRowEmpty === true)){
                        if(!duplicateRows.includes(strRow)) duplicateRows.push(strRow);
                        rowT--;
                        rowNumber--;
                        continue;
                    }
                    row.row_number = rowNumber;
                    if(allTextLines[i][0] !== "" && isRowEmpty === true)
                    {
                        rowT--;
                        rowNumber--;
                        continue;
                    }

                    
                    if(mAllRowNumber[allTextLines[i][0]] === undefined) 
                    {
                        mAllRowNumber[allTextLines[i][0]] = [rowNumber];
                    } else {
                        let allRowNum = mAllRowNumber[allTextLines[i][0]];
                        allRowNum.push(rowNumber);
                        mAllRowNumber[allTextLines[i][0]] = allRowNum;
                    }

                    let objMsg = {"row_number" : i};
                    this.allMessageInfo.push(objMsg);

                    let listMoreValidateError = [];
                    //check if startdate and end date are in correct format; then validate the biz rules
                    if(!fieldsInvalidFormat.some(item => item.fname === "ebh_dealstartdate__c") && !fieldsInvalidFormat.some(item => item.fname === "ebh_dealenddate__c"))
                    {
                        listMoreValidateError = this.validateAdditionalRules(row);
                    }

                    if(rowIncomplete || isValueInvalidFormat || fieldsInvalidFormat.length>0 || listMoreValidateError.length>0  || isInvalidId)
                    {
                        let errorMsg = "";//(isInvalidId == true ? msgEbayItem : "");
                        let listErr = [];
                        if(msgRequired !== "")
                        {
                            let errorMsg1 = this.label.LWCBulkUploadCSVError5.replace("<fields> ", " ["+ msgRequired + "] ")+" ";    //Required field &lt;fields&gt; missing value.
                            listErr.push(errorMsg1);
                        }
                        if(msgInvalidFormat !== "" || fieldsInvalidFormat.length>0) 
                        {
                            let errorMsg2 = this.constructInvalidFormatMsg(fieldsInvalidFormat,msgInvalidFormat);
                            listErr.push(errorMsg2);
                            // errorMsg = this.label.LWCBulkUploadCSVError6.replace("<fields> ", " ["+ msgInvalidFormat + "] ")+" "; //&lt;fields&gt; Incorrect Format.
                        }
                        if(listMoreValidateError.length>0)
                        {
                            listErr = listErr.concat(listMoreValidateError); //addAll
                        }                       
                         
                        errorMsg = listErr.join("\n");
                        // row.isNotOverrid = true;
                        row.status = errorMsg;
                        row.cls_status = "cls_error";
                        this.isSomeError = true;
                        objMsg.cls_status = "cls_error";
                        objMsg.message = this.constructErrMessageAfterSubmit(rowNumber,errorMsg);//"- " + this.label.RowNumber  + " " + rowNumber +". "+errorMsg;
                        tempData.push(row);

                        continue;
                    }
                   
                    //check duplicate itemid in file
                    if(allTextLines[i][0] !== "" &&  ebayIds.includes(allTextLines[i][0])) {
                        if(!duplicateEbayIds.includes(allTextLines[i][0])) duplicateEbayIds.push(allTextLines[i][0]);
                        mIdRowNum[allTextLines[i][0]] = (mIdRowNum[allTextLines[i][0]] === undefined?rowNumber : mIdRowNum[allTextLines[i][0]]+","+rowNumber);
                        if(mDuplicateRow[allTextLines[i][0]] !== undefined ){
                            msgRequired = this.label.LWCBulkUploadCSVError8.replace(" x ",mDuplicateRow[allTextLines[i][0]] +","+ i+" ");
                        } else msgRequired = this.label.LWCBulkUploadCSVError41;
                        row.status = msgRequired;
                        row.cls_status = "cls_error";
                        this.isSomeError = true;
                        objMsg.cls_status = "cls_error";
                        objMsg.message = "- " + this.label.RowNumber  + " "+rowNumber+". "+ msgRequired;
                        tempData.push(row);
                        continue;
                    }else
                    {
                        mDuplicateRow[allTextLines[i][0]] = rowNumber;
                        ebayIds.push(allTextLines[i][0]);
                        duplicateRows.push(strRow);
                        msgRequired = this.label.LWCBulkUploadCSVError10;   //Ready to Upload
                        row.status = msgRequired;
                        row.cls_status = "cls_success";
                        objMsg.cls_status = "cls_success";
                        objMsg.message = msgRequired;
                        tempMIndex[index] = rowT-1;
                        
                        index++;
                    }
                    
                    deal[this.CREATED_FROM_FLD_NAME] = isFromCopyPaste ?  this.CREATED_FROM_XL : this.CREATED_FROM_CSV; 
 
                    tempData.push(row);
                    tempDeals.push(deal);
                    if(tempDeals.length > this.availableDeal){
                        this.isReachLimit = true;
                        let errMsg = this.label.dealBulkUpload_ErrReachLimit.replace("_LIMIT_",this.metadata.Maximum_Records__c);
                        // errMsg = errMsg.replace(" x ", " "+ this.availableDeal + " ")
                        let objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : errMsg};
                        this.objMessageInfos.push(objMsgInfo);
                        tempDeals = [];
                        tempData = [];
                        break;
                    }
                }//////////////////////////////////////////////////////////////////end loop rows
            
                for(let i = 0; i < tempData.length; i++)
                {
                    let ebayItem = tempData[i].EBH_eBayItemID__c;
                    if(tempData[i].isNotOverrid !== undefined && tempData[i].isNotOverrid === true) continue;
                    if(ebayItem !== "" && mAllRowNumber[ebayItem] !== undefined) {
                        let allRowIds = mAllRowNumber[ebayItem];
                        if(allRowIds.length > 1) {
                            if(!excludeItemIds.includes(ebayItem)) excludeItemIds.push(ebayItem);
                            tempData[i].cls_status = "cls_error";
                            let errMsg = this.label.LWCBulkUploadCSVError8.replace(" x ", " "+allRowIds.join()+" ")
                            tempData[i].status = errMsg;//"Conflicting data in row "+ allRowIds.join() +". please delete and resubmit";
                            let objMsg1 = {"row_number": i+1};
                            objMsg1.cls_status = "cls_error";
                            objMsg1.message = "- " + this.label.RowNumber  + " "+(i+1)+". "+ errMsg;//"Conflicting data in row "+ allRowIds.join() +". please delete and resubmit";
                            this.allMessageInfo[i] = objMsg1;
                        }
                    }
                }

                cols[1].initialWidth = this.isSomeError ? 330 : 115;
                let tDeals = [];
                let idx = 0;
                for(let i = 0; i < tempDeals.length; i++){
                    let ebayId = tempDeals[i].EBH_eBayItemID__c;
                    if(!duplicateEbayIds.includes(ebayId) && !excludeItemIds.includes(ebayId)){
                        tDeals.push(tempDeals[i]);
                        this.mRowIndex[idx] = tempMIndex[i];
                        this.mRowItemId[idx] = ebayId; //CSP - US-0032894
                        idx++;
                    }
                }
               
                this.showLoadingSpinner = false;
                this.data = tempData;
                this.totalRec = tempData.length;
                this.columns = cols;


                let dealForUpload = this.label.LWCBulkUploadCSVError12;
                dealForUpload = dealForUpload.replace(" x ", " "+ tDeals.length + " ");
                if(tDeals.length > 0) {
                    let objMsgInfo = {className : 'cls_message-info cls_message-success', mainMsg : '', detailMsg : dealForUpload}; //' vailable deals in your file for upload!'};
                    this.objMessageInfos.push(objMsgInfo);
                    this.showLoadingSpinner = false;
                }else {
                    this.showLoadingSpinner = false;
                    let objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : '', detailMsg : dealForUpload}; //' vailable deals in your file for upload!'};
                    this.objMessageInfos.push(objMsgInfo);
                    return;
                } 
                this.deals = tDeals;

            }
            else {
                this.showLoadingSpinner = false;
                let objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : this.label.dealBulkUploadDCASub_Error_InvalidXLS};
                this.objMessageInfos.push(objMsgInfo);
            }
            this.showLoadingSpinner = false;
        } catch( err){
            this.showLoadingSpinner = false;
            let objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : err.message};
            this.objMessageInfos.push(objMsgInfo);
        }
    }

    chunkArray(myArray, chunk_size){
        let results = [];
    
        while (myArray.length) {
            results.push(myArray.splice(0, chunk_size));
        }
        
        return results;
    }

    isNumeric(val) {
        return /^-?[\d.]+(?:e-?\d+)?$/.test(val);
    }

    validateHeader(csvHeader, csvTemplate){
        let error = false;
        let csvTemplateArray = csvTemplate.split(';');
        if(csvHeader.length == csvTemplateArray.length){
            for(let i = 0; i<csvTemplateArray.length; i++){
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
        this.dealsComplete = [];
        this.dealSaveResult = [];
        this.objMessageResult = {};
        this.objMessageInfos = []; 
        this.isSomeFail = false;
        this.message = "";
        this.currentStep++;

        this.totalDealToUpload = this.deals.length;
        this.updateUploadMessageProgress(0);
        this.onProccessUpload(this.deals);
    }

    onProccessUpload(lstDeal){
        this.showLoadingSpinner = true;
        // chunk list of deal to small size for pass into apex
        var arrAllDeals = this.chunkArray(lstDeal, this.numberOfDealPerPk);
        this.onSubmitMultipleDeals(arrAllDeals, 0, arrAllDeals.length);
    }

    onSubmitMultipleDeals(arrAllDeals, index, total){ 
        // console.log('arrAllDeals',arrAllDeals);

        if( index < total && arrAllDeals[index]){
            let mapParams = {"accountId":this.accountId,"dcaId":this.recordId,"contactId":this.contactId,"fullContactName":this.fullContactName,"email":this.email};
            submitDeals({lstDeals: arrAllDeals[index], mapParams: mapParams})
            .then(result => {
                // console.log('submitDeals result',result);
                index++;
                if(result.status === 'success'){
                    let srList = result.srList;
                    this.dealSaveResult = this.dealSaveResult.concat(JSON.parse(srList));
                    if(result.lstDeals){
                        this.dealsComplete = this.dealsComplete.concat(result.lstDeals);

                        this.updateUploadMessageProgress(this.dealsComplete.length);
                    }
                }
                else {
                    this.isSomeFail = true;
                    this.message = result.message;
                    if((this.message).includes("FIELD_CUSTOM_VALIDATION_EXCEPTION, There are non-cancelled deals with same Listing ID") ){
                        this.message = this.label.LWCBulkUploadCSVError14; 
                    }
                    // if((this.message).includes("FIELD_CUSTOM_VALIDATION_EXCEPTION, Listing ID must be numeric and 12 characters in length") ){
                    //     this.message = this.label.LWCBulkUploadCSVError42;
                    // }
                    if((this.message).includes("Cannot deserialize instance of")){
                        this.message =result.message;
                    }
                } 
                
                if (index < total) {

                    this.onSubmitMultipleDeals(arrAllDeals, index, total);

                } else if(!this.isSomeFail && index === total){
                    this.onUpdateStatus();
                }
            })
            .catch(error => {
                this.isSomeFail = true;
                this.message = (error.body !== undefined? error.body.message : error);
                this.message = (this.message==="Unable to read SObject's field value[s]"? this.label.LWCBulkUploadCSVError15 : this.message);
                let objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : this.message};
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
        let allSaveResult = this.dealSaveResult;
        let totalSuccess = 0;
        // console.log('this.mRowIndex',JSON.stringify(this.mRowIndex));
        // console.log('allSaveResult',allSaveResult);
        // console.log('this.allMessageInfo',this.allMessageInfo);

        for(let i = 0; i < allSaveResult.length; i++){
            let index = this.mRowIndex[i];
            const itemId = this.mRowItemId[i]; //CSP - US-0032894
            
            if(allSaveResult[i].success === false) {
                this.isSomeError = true;
                this.allMessageInfo[index].cls_status = "cls_error";
                let msg = "";
                let errors = allSaveResult[i].errors;
                for(let x = 0; x < errors.length; x++){
                    msg += (msg===""? "":", ") + errors[x].message;
                }
                if(this.dd_DuplicateError !== undefined && this.dd_DuplicateError !== "" && this.mapErrorMessages[this.dd_DuplicateError] !== undefined && msg.startsWith(this.dd_DuplicateError)){
                    msg = this.mapErrorMessages[this.dd_DuplicateError];
                }
                this.allMessageInfo[index].message = this.constructErrMessageAfterSubmit((index+1),msg+"\n", itemId);//"- " + this.label.RowNumber  + " "+(index+1)+". "+itemId + " : "+msg+"\n"  ;
            } else totalSuccess++;
        }

        this.totalSuccess = totalSuccess;   
        
        if(totalSuccess > 0){
            // Show success toast when deals create
            // this.dispatchEvent(
            //     new ShowToastEvent({
            //         title: this.label.thank_You_message,
            //         variant: 'success'
            //     })
            // );

            //execute post DML process if applicable
            this.processPostDMLSEP();
        }
        else
        {
                     
            this.showFinalMessage();
        }
        // if(this.isSomeError === false) {
        //     this.redirectToFutureDeals();
        // }
        
    }

    doDownloadCSVTemplate(){
        // Creating anchor element to download
        let downloadElement = document.createElement('a');
        downloadElement.href = bulkUploadDealTemplateNA;
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
        event.preventDefault(); 
        this.showUserGuide = true;
    }

    handleUserGuideClose(event){
        this.showUserGuide = false;
    }

    cancelhandler() {
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: '/my-subsidized-deal-contract-agreement'
            }
        });
    }
    //BR-17-10-2022-US-0012600
    handleAccountChange(event) {
        // console.log("selectedVal: "+event.detail.selectedVal);
        this.data = [];
        this.deals = [];
        this.file = null;
        this.fileName = '';
        this.isNoFile = true;
        this.accountId = event.detail.selectedVal;
        this.doLoadConfig();
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
    handleCloseAndBack()
    {
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: '/my-subsidized-deal-contract-agreement'
            }
        });
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
        //NK:18/04/2025:US-0017104 
        // if(event.detail && event.detail.isSuccess && event.detail.mappedRows && event.detail.mappedRows.length > 0){
        if(event.detail && event.detail.isSuccess){
            this.isNoFile = false;
            this.isDisableNextBtn = false;
            
            let arrAllLine = [];
            arrAllLine.push(event.detail.mappedColumns);

            let allRowRecord = event.detail.mappedRows;

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
        }else 
        {
            console.error("error onPasteResult: "+JSON.stringify(event.detail));
            this.showLoadingSpinner = false;
        }


    }
    //fieldName:boolean;fieldNameB:number;....
    constructMapFieldType()
    {
        try
        {
            let mapFtype = this.metadata.Mapped_Field_Types__c;
            if(mapFtype)
            {                
                this.mapFieldType = this.convertStringToJsonObject(mapFtype);
            }
        }catch(e)
        {
            console.error(e);this.mapFieldType = {};
        }
       
        
        
    }
    convertStringToJsonObject(inputString) {
        // Split the input string by semicolon to get key-value pairs
        const pairs = inputString.split(';');
    
        // Initialize an empty object to store the result
        const jsonObject = {};
    
        // Iterate over each pair
        pairs.forEach(pair => {
            // Split each pair by colon to separate key and value
            const [key, value] = pair.split(':');
    
            // Add the key-value pair to the JSON object
            jsonObject[key] = value;
        });
    
        return jsonObject;
    }
    validateFormat(val,colName)
    {
        let result = false;
        let fieldType = this.mapFieldType[colName];
        try
        {
            // if(this.notValidateFormat[colName])
            // {
            //     return false;   //skip here but to validate in additional rules
            // }
            //console.log("colename: "+ colName + "  fieldType: "+fieldType + "  val: "+val);
            if(fieldType === "number" || fieldType === "currency" || fieldType === "decimal")
            {
                if(!this.isNumeric(val)) 
                {
                    result = true;
                }
          
            }
            else if(fieldType === "date")
            {
                result = !validateDateString(val, this.VALID_DATE_FORMAT);
              
            }else if(fieldType === "time")
            {
                result = !validateTimeString(val);
                
            } 

            if(colName==="EBH_eBayItemID__c")
            {
                result = this.isNumeric(val) && val.length === 12 ? false : true;
            }


        }catch(e)
        {
            console.log(e);return true;
        }
       
        return result;
    }

    constructInvalidFormatMsg(fieldsInvalidFormat,msgInvalidFormat)
    {
        let listAllMsg = [];
        let errorMsg1 = msgInvalidFormat===""?"":this.label.LWCBulkUploadCSVError6.replace("<fields> ", " ["+ msgInvalidFormat + "] ")+" "; //&lt;fields&gt; Incorrect Format.
        if(errorMsg1)
        {
            listAllMsg.push(errorMsg1);
        }
        
        let listDateError = [];
        let listTimeError = [];

        for(let i=0;i<fieldsInvalidFormat.length;i++)
        {
            let fname = fieldsInvalidFormat[i].fname;
            let flabel = fieldsInvalidFormat[i].flabel;
            if(fname==="ebh_dealstartdate__c"|| fname==="ebh_dealenddate__c")
            {
                listDateError.push(flabel);
            }else if(fname==="ebh_dealstarttime__c"|| fname==="ebh_dealendtime__c")
            {
                listTimeError.push(flabel);
            }
        }
        if(listDateError.length>0)
        {
            let errorMsg2 = this.label.dealBulkUploadDCASub_Error_DealDateFomat.replace("_FIELD_", " ["+ listDateError.join(", ") + "] ")+" ";
            listAllMsg.push(errorMsg2);
        }
        if(listTimeError.length>0)
        {
            let errorMsg3 = this.label.dealBulkUploadDCASub_Error_DealTimeFomat.replace("_FIELD_", " ["+ listTimeError.join(", ") + "] ")+" ";
            listAllMsg.push(errorMsg3);
        }

        return listAllMsg.join('\n');
    }

    correctData(val,colName)
    {
        let correctVal = val;
        let fieldType = this.mapFieldType[colName];
        try
        {
            if(fieldType === "number" || fieldType === "currency" || fieldType === "decimal")
            {
                correctVal = safeParseFloat(val);
                
            }
            else if(fieldType === "date")
            {
                correctVal = convertToStandardDateFormat(val, this.VALID_DATE_FORMAT);
              
            }else if(fieldType === "time")
            {
                correctVal = convertTimeFormat(correctVal) + ":00.000Z";
               
            }
        }catch(e)
        {
            console.log(e);
        }
       
        return correctVal;
    }

    //biz rule validation
    validateAdditionalRules(oneRow)
    {
        // Deal start date should be a future date (if deal start date < current date)       
        // Deal end date should be greater than start date (if deal end date < = deal start date)
      
    //    let fieldsInvalidFormat = oneRow.fieldsInvalidFormat?oneRow.fieldsInvalidFormat:[]; //{fname:colNameLow,flabel: fieldLabel}
       let listErr = [];
       //if one of the 2 fields is invalid format, no need to check date rule
     
            let startDate = oneRow.EBH_DealStartDate__c;
            let endDate = oneRow.EBH_DealEndDate__c;
            
            let todayDateStr = getTodayDateString(this.VALID_DATE_FORMAT);
            let comResult1 = compareDates(startDate,todayDateStr,this.VALID_DATE_FORMAT);
            let comResult2 = compareDates(startDate,endDate,this.VALID_DATE_FORMAT);
            
            //if deal start date < current date,1: eariler, 0: sameday, 2: future
            if(comResult1 === 1)
            {              
                listErr.push(this.label.dealBulkUploadDCASub_Error_DealShouldInFuture);
            }
            if(comResult2===2)
            {
                listErr.push(this.label.dealBulkUploadDCASub_Error_DealEndDateShouldBiger);
            }
            
            //List Price cannot be less than the Ideal Deal Price.
            let listPrice = safeParseFloat(oneRow.EBH_RRPWASPrice__c,10);   //empty -> NaN  
            let idealPrice = safeParseFloat(oneRow.EBH_DealPrice__c,10);
            let sellerPrice = safeParseFloat(oneRow.EBH_SellerPrice__c,10);
            let qty = safeParseInt(oneRow.EBH_Quantity__c,10);
            // console.log("listPrice: "+listPrice+"  idealPrice: "+idealPrice);
             if(listPrice > 0 && listPrice < idealPrice)
             {
                listErr.push(this.label.dealBulkUploadDCASub_Error_ListPriceLessThanDeal);
             }

             // List Price, Seller Price and Deal Price cannot be negative or null
             //oneRow.EBH_RRPWASPrice__c+"").trim()==="" || 
             if(this.validateNegOrNull(listPrice) || this.validateNegOrNull(idealPrice) || this.validateNegOrNull(sellerPrice))
             {
                listErr.push(this.label.dealBulkUploadDCASub_Error_LP_SP_DP_Negative_Null);
             }

             //Quantity cannot be 0 or negative
             if(this.validateNegOrNull(qty))
            {
                listErr.push(this.label.dealBulkUploadDCASub_Error_QTY_Negative_Null);
            }
            //When the Deal Price is greater than the Seller Price
             if(idealPrice > sellerPrice)
             {
                listErr.push(this.label.dealBulkUploadDCASub_Error_DealPriceLessSellerPrice);
             }
          

        return listErr;
    }
    validateNegOrNull(val)
    {
        let result = false;
        if(val === null || val === "" || val === undefined ||  val <= 0) 
        {
            result = true;
        }
        return result;

    }
    processPostDMLSEP()
    {            
        if(this.metadata && this.metadata.Server_side_Post_DML__c)
        {
            this.showLoadingSpinner = true;
            let postData = {"parentId":this.recordId};
            apexProcessPostDMLSEP({ "postData" : postData,templateName : this.UPLOAD_NA_DEAL_MTD_NAME}).then(result => {
                if(result.status === 'ok')
                {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: this.label.thank_You_message,
                            variant: 'success'
                        })
                    );

                    console.log("Post DML Processed successfully");
                }
                else
                {
                    console.error("Post DML failed: ",result.error);
                    this.message = "Unexpected Error on Post Upload Processed";
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Post Upload Failed',
                            message: this.message,
                            variant: 'error',
                        }),
                    );    
                    

                    this.sendServerSideErrorToV2('dealBulkUploadDcaSub:processPostDMLSEP()',result.error);
                }
                this.showFinalMessage();
            }).catch(error => {
                console.error("Post DML Processed failed : ",error);
                this.showFinalMessage();
                this.sendServerSideErrorToV2('dealBulkUploadDcaSub:processPostDMLSEP()',error);
                
            });
        }else
        {
            this.showFinalMessage();
           
        }
    }
    showFinalMessage()
    {
        this.data = [];
        this.objMessageInfos = []; 
        this.doLoadConfig();
        this.showLoadingSpinner = false;
    }
    sendServerSideErrorToV2(method, error) {
        const excelImporterEvent = new CustomEvent('serversideerror',{detail: {method: method, error: error}} );
        this.dispatchEvent(excelImporterEvent);
    }

    constructErrMessageAfterSubmit(rowNumber, errorMsg, rowItemId)
    {
        if(rowItemId) return `- ${this.label.RowNumber} ${rowNumber+1}. ${rowItemId}: ${errorMsg}`; //CSP:US-0032894 include the Item ID in the after the Row Number, Like Row Number 5. 987496231481
        return "- " + this.label.RowNumber  + " " + rowNumber +". "+errorMsg;  
    }

    get showThankyou()
    {
        return this.totalSuccess > 0;
    }

    handlePasteStart(e)
    {
        this.showLoadingSpinner = true;
        this.spinnerText = this.label.dealBulkUploadDCASub_Msg_PleaseWait; 
    }
    updateUploadMessageProgress(num)
    {
        // console.log("totalDealToUpload: "+this.totalDealToUpload);
        this.spinnerText = this.label.dealBulkUploadDCASub_Msg_PleaseWaitUpload.replace("{0}",num).replace("{1}",this.totalDealToUpload);
    }
}