/*********************************************************************************************************************************
@ Author:         Vimean Heng
@ Purpose:        US-0016717 - Contract Amendment Process - No Change in Subsidy
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.03.2025 / Vimean Heng / Created the component.(replicated from dealBulkUploadDcaSub)
*********************************************************************************************************************************/
import { LightningElement ,api, track} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import doLoadSetting from '@salesforce/apex/DealSubAmendUploadController.doLoadSetting';
import getAllDeals from '@salesforce/apex/DealSubAmendUploadController.getAllDeals';
import submitDeals from '@salesforce/apex/DealSubAmendUploadController.submitDeals';

import { validateTimeString,validateDateString,convertToStandardDateFormat,convertTimeFormat,compareDates,getTodayDateString } from "c/hiveUtils";

import bulkUploadDealTemplate from '@salesforce/resourceUrl/Contract_Amendment_template';
import dealbulkUploadNaStep1 from '@salesforce/resourceUrl/Deal_Bulk_Upload_NA_Step1';
import dealbulkUploadNaStep2 from '@salesforce/resourceUrl/Deal_Bulk_Upload_NA_Step2';
import dealbulkUploadNaStep3 from '@salesforce/resourceUrl/Deal_Bulk_Upload_NA_Step3';
import dealbulkUploadNaStep4 from '@salesforce/resourceUrl/Deal_Bulk_Upload_NA_Step4';
import ebayLogo from '@salesforce/resourceUrl/eBayLogo';

import LWCBulkUploadCSVError3 from '@salesforce/label/c.LWCBulkUploadCSVError3';
import LWCBulkUploadCSVError4 from '@salesforce/label/c.LWCBulkUploadCSVError4';
import LWCBulkUploadCSVError5 from '@salesforce/label/c.LWCBulkUploadCSVError5';
import LWCBulkUploadCSVError6 from '@salesforce/label/c.LWCBulkUploadCSVError6';
import LWCBulkUploadCSVError8 from '@salesforce/label/c.LWCBulkUploadCSVError8';
import LWCBulkUploadCSVError10 from '@salesforce/label/c.LWCBulkUploadCSVError10';
import LWCBulkUploadCSVError12 from '@salesforce/label/c.LWCBulkUploadCSVError12';
import LWCBulkUploadCSVError13 from '@salesforce/label/c.LWCBulkUploadCSVError13';
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
import DealRecordsCreatedPartSuccess from '@salesforce/label/c.DealRecordsCreatedPartSuccess';
import DealRecordsCreatedPartError from '@salesforce/label/c.DealRecordsCreatedPartError';
import DRC_Inline_info from '@salesforce/label/c.DRC_Inline_info';
import PleaseSelectTheEBayAccount from '@salesforce/label/c.Please_select_the_eBay_Account';
import btn_back from '@salesforce/label/c.SEP_BACK_BUTTON';
import thank_You_message from '@salesforce/label/c.Thank_You_message';
import dealBulkUploadBtnDownloadUserGuide  from '@salesforce/label/c.dealBulkUploadBtnDownloadUserGuide';
import dealBulkUploadBtnDownloadXL  from '@salesforce/label/c.dealBulkUploadBtnDownloadXL';
import UploadUserGuide  from '@salesforce/label/c.UploadUserGuide';
import closeBtn from '@salesforce/label/c.Close';
import Generic_Error_No_Permission_On_Cmp from '@salesforce/label/c.Generic_Error_No_Permission_On_Cmp';
import customLabel from 'c/customLabels';
import { isNullorUndefinedorZero} from "c/hiveUtils";
export default class DealSubAmendUpload extends NavigationMixin(LightningElement) {
    @api templateName = "";
        showUserGuide = false;
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
        @track csvHeader1  = '';//'ebay Item Id,Deal Price,List Price,Quantity,Maximum Purchases,Sellers Deal Price MSKU Lower,Sellers Deal Price MSKU Upper,List Price MSKU Lower,List Price MSKU Upper';
        @track hasNoPermission = false;
        labelBtnSubmit = customLabel.Deal_Amend_And_Submit_For_Approval;
        @track mapDCA = {};
        @track mOverlapDeals = {};
        @track defaulCols = [
            { label: '', fieldName: 'row_number', type: 'number', initialWidth: 50},
            { label: 'Status', fieldName: 'status', type: 'text',wrapText: true, initialWidth: 350, cellAttributes: { alignment: 'left' ,class: { fieldName: 'cls_status' } }},                       
            { label: 'ebay Item Id*', fieldName: 'EBH_eBayItemID__c', type: 'text',initialWidth: 160},        
            { label: 'Item Title', fieldName: 'EBH_ProductTitle__c', type: 'text',initialWidth: 200},
            { label: 'Seller Price', fieldName: 'EBH_SellerPrice__c', type: 'currency', initialWidth: 180, typeAttributes: { currencyCode: 'USD', step: '0.001'}},
            { label: 'Deal Price', fieldName: 'EBH_DealPrice__c', type: 'currency', initialWidth: 180, typeAttributes: { currencyCode: 'USD', step: '0.001'}}, 
            { label: 'Quantity', fieldName: 'EBH_Quantity__c', type: 'number', initialWidth: 100},
            { label: 'Maximum Purchases', fieldName: 'EBH_MaximumPurchases__c', type: 'number', initialWidth: 160},
            { label: 'Deal_Start_Date', fieldName: 'EBH_DealStartDate__c', type: 'text', initialWidth: 160},
            { label: 'Deal_Start_Time', fieldName: 'EBH_DealStartTime__c', type: 'text', initialWidth: 160},
            { label: 'Deal_End_Date', fieldName: 'EBH_DealEndDate__c', type: 'text', initialWidth: 160},
            { label: 'Deal_End_Time', fieldName: 'EBH_DealEndTime__c', type: 'text', initialWidth: 160},
            { label: 'Updated Item ID', fieldName: 'UPD_EBH_eBayItemID__c', type: 'text', initialWidth: 200}
        ]; 
        @track requiredDealFields = [];//["EBH_eBayItemID__c", "EBH_DealPrice__c", "EBH_RRPWASPrice__c", "EBH_Quantity__c", "EBH_MaximumPurchases__c", "EBH_SellerPrice__c", "EBH_Dealdateearliestpossible__c", "EBH_ProductTitle__c"];
        @track totalSuccess = 0;
        @track isUnableUpload = false;
        @track currentStep = 1;
        @track CREATED_FROM_XL = 'Excel';
        @track CREATED_FROM_CSV = 'CSV';
        @track CREATED_FROM_FLD_NAME = 'Created_From__c';
        @track ebayLogo = ebayLogo;
        @track dealbulkUploadNaStep1 = dealbulkUploadNaStep1;
        @track dealbulkUploadNaStep2 = dealbulkUploadNaStep2;
        @track dealbulkUploadNaStep3 = dealbulkUploadNaStep3;
        @track dealbulkUploadNaStep4 = dealbulkUploadNaStep4;
        
        @track deals = [];
        @track ignoreFields = [];
        cls_success = 'slds-text-color_success';
        cls_error = 'slds-text-color_error';
        countAmendChage = 0;
        countAmendNoChange = 0;
        lbTotalRecord = 'Total Record';
        numberOfDealPerPk = 50;
        file;
        fileContent;
        fileReader;
        lsItemIdsNotFound = [];
        mapItemDeal = {};
        mItemOriginalDeal = {};
        label = {LWCBulkUploadCSVError3,LWCBulkUploadCSVError4,LWCBulkUploadCSVError5,
            LWCBulkUploadCSVError6,LWCBulkUploadCSVError8,LWCBulkUploadCSVError10,LWCBulkUploadCSVError13,
            LWCBulkUploadCSVError12,LWCBulkUploadCSVError14,LWCBulkUploadCSVError15,LWCBulkUploadCSVError16,
            LWCBulkUploadCSVError41,LWCBulkUploadCSVError42,RowNumber, DealRecordsCreatedPartSuccess, DealRecordsCreatedPartError,
            DRC_Inline_info, PleaseSelectTheEBayAccount,btn_back,thank_You_message, 
            dealBulkUploadBtnDownloadUserGuide, dealBulkUploadBtnDownloadXL, UploadUserGuide, closeBtn,
    
            dealBulkUploadDCASub_Error_DealShouldInFuture,dealBulkUploadDCASub_Error_DealDateFomat,
            dealBulkUploadDCASub_Error_DealEndDateShouldBiger,dealBulkUploadDCASub_Error_DealTimeFomat,
            dealBulkUpload_ErrReachLimit,Generic_Error_No_Permission_On_Cmp
        };
        cLabel = customLabel;
        //The_Following_Item_IDs_Are_Not_Found,Item_ID_Not_Found
        //Deal_Error_Upload_Maximum_For_No_Change,Deal_Error_Upload_Maximum_For_Change,Deal_Amend_Upload_Description,Deal_Amend_Upload_Info
        VALID_DATE_FORMAT = "MM/DD/YYYY";   //from upload
        SFDC_DATE_FORMAT = "YYYY-MM-DD";    //into the system
        metadata;
        mapFieldType = {};
        mapNewValidationFields = {ebh_dealstartdate__c:true,ebh_dealstarttime__c:true,ebh_dealenddate__c:true,ebh_dealendtime__c:true};
        availableDeal = parseInt(this.cLabel.Deal_Amend_No_Change_Limit,10);
        amendChangeLimit = parseInt(this.cLabel.Deal_Amend_Change_Limit,10);
        amendNoChangeLimit = parseInt(this.cLabel.Deal_Amend_No_Change_Limit,10);
        mapItemIdAndName = {};
        lsAmendItemIdChange = [];
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
            return this.isUnableUpload;
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
        get title(){
            return this.metadata ? this.metadata.MasterLabel : "";
        }
        get subTitle(){
            return this.cLabel.Deal_Amend_Upload_Description;
        }
        get description(){
            return this.metadata ? this.metadata.Description__c : "";
        }
        get isNoPermission(){
            return this.hasNoPermission;
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
        errorPermissionMessage(){
            return this.label.Generic_Error_No_Permission_On_Cmp;
        }
        
        connectedCallback() {
            this.doLoadConfig();
        }
    
        doLoadConfig(){
            doLoadSetting({templateName:this.templateName})        
            .then(result => {
                // console.log('result...',result);
                this.objMessageInfos = [];
                this.isSomeError = false;
                let msgLoad = "";
                let objMsgInfo;
                if(result["status"] == "success"){
                    this.hasNoPermission = result.hasNoPermission ? result.hasNoPermission:false;
                    this.metadata = result.metadata;
                    this.csvHeader1 = this.metadata.Excel_Column_Names__c;
                    this.requiredDealFields = this.metadata.Required_Fields__c?this.metadata.Required_Fields__c.split(";"):[];
                    this.numberOfDealPerPk = this.metadata.Batch_Size__c;
                    this.ignoreFields = this.metadata.Skipped_Field_Names__c?this.metadata.Skipped_Field_Names__c.split(";"):[];
                    this.constructMapFieldType();
                    
                    this.dd_DuplicateError = result.dd_DuplicateError;
                    this.email = result.conEmail;
                    
                    this.contactId = result.contactId;
                    this.fullContactName = result.fullContactName;
                    this.availableDeal = result.availableDeal;
                    if(!this.hasNoPermission){
                        this.isUnableUpload = false;
                        this.isReachLimit = false;
                        objMsgInfo = this.generateInfoMessage(this.cLabel.Deal_Amend_Upload_Info);
                    }else {
                        this.isUnableUpload = true;
                        objMsgInfo = this.generateErrorMessage(this.label.Generic_Error_No_Permission_On_Cmp);
                    }
    
                    this.doMapErrorMessages();
                }else {
                    this.isUnableUpload = true;
                    this.isReachLimit = true;
                    msgLoad = result.message;
                    objMsgInfo = this.generateErrorMessage(msgLoad);
                }
                this.objMessageInfos.push(objMsgInfo);
                // this.doLoadDealRetailCampaign();
    
                
            })
            .catch(error => { 
                console.log("first load ERROR::", error);
            }); 
        }
        generateInfoMessage(message){
            return {className : "cls_message-info", mainMsg : "INFORMATION -", detailMsg : message};
        }
        generateErrorMessage(message){
            return {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : message};
        }
        
        doMapErrorMessages(){
            this.mapErrorMessages[this.dd_DuplicateError] = this.label.LWCBulkUploadCSVError16;
        }
        
        extractDealNotFound(itemIds){
            let dealNotFound = [];
            for(let i = 0; i < itemIds.length; i++){
                let itemId = itemIds[i];
                if(this.mapItemDeal[itemId] == null){
                    dealNotFound.push(this.mapItemIdAndName[itemId]);
                }
            }
            return dealNotFound;
        }
        
        getAllDeals(itemIds,overlapItemIds,doResponse){
            this.showLoadingSpinner = true;
            getAllDeals({itemIds: itemIds,overlapItemIds:overlapItemIds})
            .then(result => {
                if(result.status == "success"){
                    this.mOverlapDeals = result.overlapDeals;
                    this.initDeal(result.allDeals);
                    this.lsItemIdsNotFound = this.extractDealNotFound(itemIds);
                    if(doResponse != null){
                        doResponse();
                    }
                }else{
                    let objMsgInfo = this.generateErrorMessage(result.message);
                    this.objMessageInfos.push(objMsgInfo);
                    this.dealsComplete = [];
                }
                this.showLoadingSpinner = false;
            }).catch(error => {
                console.log(error);
                this.isSomeFail = true;
                this.message = (error.body !== undefined? error.body.message : error);
                let objMsgInfo = this.generateErrorMessage(this.message);
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
        initDeal(allDeals){
            this.mapItemDeal = {};
            this.mapDCA = {};
            for(let i = 0; i < allDeals.length; i++){
                let deal = allDeals[i];
                this.mapItemDeal[deal.EBH_eBayItemID__c] = deal;
                let accId = deal.EBH_BusinessName__c;
                let dca = this.mapDCA[accId] === undefined ? null : this.mapDCA[accId];
                if(dca !==null && dca.category !== null){
                    continue;
                }
                let mDca = {};
                mDca.accountId = accId;
                if(deal.Deal_Contract_Agreement__r !== null && deal.Deal_Contract_Agreement__r !== undefined){
                    mDca.category = deal.Deal_Contract_Agreement__r.Category__c;
                    mDca.vertical = deal.Deal_Contract_Agreement__r.Vertical__c;
                    mDca.dealSite = deal.Deal_Contract_Agreement__r.Deal_Site__c;
                }
                this.mapDCA[accId] = mDca;
                
            }   
        }
        
        checkSubsidyChange(allRowRecord){
            this.lsAmendItemIdChange = [];
            for(let i = 0; i < allRowRecord.length; i++){
                let csvDeal = allRowRecord[i];
                let itemId = csvDeal['ebay Item Id*'];
                let deal = this.mapItemDeal[itemId];
                let csvDealPrice = csvDeal['Deal Price'];
                let csvSellerPrice = csvDeal['Seller Price'];
                if(deal != null && ( (!isNullorUndefinedorZero(csvDealPrice) && parseInt(csvDealPrice,10) != deal.EBH_DealPrice__c) || (!isNullorUndefinedorZero(csvSellerPrice) && parseInt(csvSellerPrice,10) != deal.EBH_SellerPrice__c)) ){
                    this.lsAmendItemIdChange.push(itemId);
                }
            }
            if((allRowRecord.length - this.lsAmendItemIdChange.length - this.lsItemIdsNotFound.length) > this.amendNoChangeLimit){
                this.isReachLimit = true;
                let objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : this.cLabel.Deal_Error_Upload_Maximum_For_No_Change};
                this.objMessageInfos.push(objMsgInfo);
            }
            if(this.lsAmendItemIdChange.length > this.amendChangeLimit){
                this.isReachLimit = true;
                let objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : this.cLabel.Deal_Error_Upload_Maximum_For_Change};
                this.objMessageInfos.push(objMsgInfo);
            }
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
                
                let allTextLines = arrAllLine;
                let isFromCopyPaste = true;//arrAllLine ? true : false
                let csvHeader = allTextLines[0];
                this.mItemOriginalDeal = {};
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
                        
    
                        let allCols = allTextLines[i];
    
                       
                        if(allCols.length !== cols.length-2) continue;
    
                        let deal = { "sobjectType": "EBH_Deal__c" };
                        let row = {};
                        row.id = i;
                        let isRowEmpty = true;
                        let isAmendChange = false;
                        let existingDeal = null;
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
                            if(colName === "EBH_eBayItemID__c"){
                                isAmendChange = this.lsAmendItemIdChange.includes(val);
                                //add id and seller to csv deal
                                existingDeal = this.mapItemDeal[val];
                                if(existingDeal != null){
                                    if(!isAmendChange){
                                        //if no change we update the deal
                                        deal.Id = existingDeal.Id;
                                    }else{
                                        //clone the deal
                                        deal.Originating_Deal__c = existingDeal.Id;
                                        deal.EBH_DealSiteId__c = existingDeal.EBH_DealSiteId__c;
                                        deal.EBH_DealEndDate__c = existingDeal.EBH_DealEndDate__c;
                                        deal.EBH_DealEndTime__c = existingDeal.EBH_DealEndTime__c;
                                        deal.EBH_MaximumPurchases__c = existingDeal.EBH_MaximumPurchases__c;
                                        deal.EBH_Quantity__c = existingDeal.EBH_Quantity__c;
                                        deal.EBH_ProductTitle__c = existingDeal.EBH_ProductTitle__c;
                                        deal.EBH_RRPWASPrice__c = existingDeal.EBH_RRPWASPrice__c;
                                        deal.EBH_Vertical__c = existingDeal.EBH_Vertical__c;
                                        deal.EBH_Category__c = existingDeal.EBH_Category__c;
                                        deal.EBH_SellerPrice__c = existingDeal.EBH_SellerPrice__c;
                                        deal.EBH_DealPrice__c = existingDeal.EBH_DealPrice__c;
                                        deal.EBH_DealStartDate__c = getTodayDateString(this.VALID_DATE_FORMAT);
                                        let d = new Date();
                                        d.setHours(d.getHours()+1)
                                        deal.EBH_DealStartTime__c = convertTimeFormat(d.getHours()+':'+d.getMinutes()) + ":00.000Z";
                                        this.mItemOriginalDeal[existingDeal.EBH_eBayItemID__c] = existingDeal.Id;
                                    }
                                    deal.EBH_BusinessName__c = existingDeal.EBH_BusinessName__c;
                                }
                            }
                            if(isAmendChange && colName !== "EBH_eBayItemID__c" && colName !== "EBH_SellerPrice__c" && colName !== "EBH_DealPrice__c"){
                                continue;
                            }
                            
                            //ignore update eBayItemID to blank
                            if(colName === "UPD_EBH_eBayItemID__c" && val === null || val === ""){
                                continue;
                            }
                            //UPD_ is for update field (item id)
                            if(colName.indexOf('UPD_')===0 && val !== ""){
                                colName = colName.replace('UPD_','');
                            }
                            //isAmendChange no need check ignore field
                            if(!isNullorUndefinedorZero(val) && (isAmendChange || !this.ignoreFields.includes(colName))) {
                                deal[colName] = this.correctData(val,colName); //make sure the data is in the correct type. not always string
                            }
                            
    
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
                        let itemId = row.EBH_eBayItemID__c;
                        itemId = itemId !== null ? '"' + itemId +'" ' : "";
                        row.isAmendChange = isAmendChange;
                        let listMoreValidateError = this.validateAdditionalRules(row,fieldsInvalidFormat);

                        if(rowIncomplete || isValueInvalidFormat || fieldsInvalidFormat.length>0 || listMoreValidateError.length>0  || isInvalidId)
                        {
                            let errorMsg = "";
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
                            }
                            if(listMoreValidateError.length>0)
                            {
                                listErr = listErr.concat(listMoreValidateError); //addAll
                            }                       
                                
                            errorMsg = listErr.join("\n");
                            
                            row.status = errorMsg;
                            row.cls_status = this.cls_error;
                            this.isSomeError = true;
                            objMsg.cls_status = "cls_error";
                            objMsg.message = this.constructErrMessageAfterSubmit(rowNumber,itemId + errorMsg);//"- " + this.label.RowNumber  + " " + rowNumber +". "+errorMsg;
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
                            row.cls_status = this.cls_error;
                            this.isSomeError = true;
                            objMsg.cls_status = "cls_error";
                            objMsg.message = "- " + this.label.RowNumber  + " "+rowNumber+": " + itemId + msgRequired;
                            tempData.push(row);
                            continue;
                        }else
                        {
                            mDuplicateRow[allTextLines[i][0]] = rowNumber;
                            ebayIds.push(allTextLines[i][0]);
                            duplicateRows.push(strRow);
                            msgRequired = this.label.LWCBulkUploadCSVError10;   //Ready to Upload
                            row.status = msgRequired;
                            row.cls_status = this.cls_success;
                            objMsg.cls_status = 'cls_success';
                            objMsg.message = msgRequired;
                            tempMIndex[index] = rowT-1;
                            
                            index++;
                        }
                        
                        deal[this.CREATED_FROM_FLD_NAME] = isFromCopyPaste ?  this.CREATED_FROM_XL : this.CREATED_FROM_CSV; 
                        //default for Amend
                       
                        tempData.push(row);
                        tempDeals.push(deal);
                        
                    }
                    //end loop rows
                
                    for(let i = 0; i < tempData.length; i++)
                    {
                        let ebayItem = tempData[i].EBH_eBayItemID__c;
                        if(tempData[i].isNotOverrid !== undefined && tempData[i].isNotOverrid === true) continue;
                        if(ebayItem !== "" && mAllRowNumber[ebayItem] !== undefined) {
                            let allRowIds = mAllRowNumber[ebayItem];
                            if(allRowIds.length > 1) {
                                if(!excludeItemIds.includes(ebayItem)) excludeItemIds.push(ebayItem);
                                tempData[i].cls_status = this.cls_error;
                                let errMsg = '';
                                if(allRowIds.length > 1) {
                                    errMsg = this.label.LWCBulkUploadCSVError8.replace(" x ", " "+allRowIds.join()+" ");
                                }
                                tempData[i].status = errMsg;//"Conflicting data in row "+ allRowIds.join() +". please delete and resubmit";
                                let objMsg1 = {"row_number": i+1};
                                objMsg1.cls_status = "cls_error";
                                objMsg1.message = "- " + this.label.RowNumber  + " "+(i+1)+": "+ '"' + ebayItem +'" ' + errMsg;//"Conflicting data in row "+ allRowIds.join() +". please delete and resubmit";
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
                            idx++;
                        }
                    }
                    
                    this.showLoadingSpinner = false;
                    this.data = tempData;
                    this.totalRec = tempData.length;
                    this.columns = cols;
    
    
                    if(this.lsItemIdsNotFound != null && this.lsItemIdsNotFound.length > 0){
                        let errItemNotFound = this.cLabel.The_Following_Item_IDs_Are_Not_Found;
                        if(tDeals.length > 0){
                            errItemNotFound = errItemNotFound + ' ' + this.cLabel.Please_Click_On_Amend_and_Submit_for_Approval;
                        }
                        errItemNotFound = errItemNotFound + '<br>' + this.lsItemIdsNotFound.join(',');
                        let objMsgInfo = this.generateErrorMessage(errItemNotFound);
                        this.objMessageInfos.push(objMsgInfo);
                        
                    }

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
                    let objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : this.label.LWCBulkUploadCSVError13};
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
            if(csvHeader.length === csvTemplateArray.length){
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
            this.onProccessUpload(this.deals);
        }
    
        onProccessUpload(lstDeal){
            this.showLoadingSpinner = true;
            //no need to chunk cos max limit 150
            this.onSubmitAllDeals(lstDeal); 
        }
        onSubmitAllDeals(arrAllDeals){
            submitDeals({lstDeals: arrAllDeals,mapParam: this.mapDCA, mapItemOriginalDeal:this.mItemOriginalDeal})
            .then(result => {
                console.log('submitDeals result',result);
                if(result.status === 'success'){
                    let srList = result.srList;
                    this.dealSaveResult = this.dealSaveResult.concat(JSON.parse(srList));
                    if(result.lstDeals){
                        this.dealsComplete = this.dealsComplete.concat(result.lstDeals);
                    }
                }
                else {
                    this.isSomeFail = true;
                    this.message = result.message;
                    if((this.message).includes("FIELD_CUSTOM_VALIDATION_EXCEPTION, There are non-cancelled deals with same Listing ID") ){
                        this.message = this.label.LWCBulkUploadCSVError14; 
                    }
                    
                    if((this.message).includes("Cannot deserialize instance of")){
                        this.message =result.message;
                    }
                    this.objMessageInfos.push(this.generateErrorMessage(this.message));
                    this.showLoadingSpinner = false;
                } 
                if(!this.isSomeFail){
                    this.onUpdateStatus();
                }
            })
            .catch(error => {
                console.error(error);
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
        
        onUpdateStatus() {
            this.isShowMessage = true;
            let allSaveResult = this.dealSaveResult;
            let totalSuccess = 0;
            
    
            for(let i = 0; i < allSaveResult.length; i++){
                let index = this.mRowIndex[i];
                if(i >= this.deals.length){
                    break;
                }
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
                    let itemId = this.data[index]['EBH_eBayItemID__c'];
                    itemId = itemId !== null ?'"' + itemId +'" ' : "";
                    this.allMessageInfo[index].message = this.constructErrMessageAfterSubmit((index+1),itemId + msg+"\n");//"- " + this.label.RowNumber  + " "+(index+1)+". "+msg+"\n";
                } else totalSuccess++;
            }
    
            this.totalSuccess = totalSuccess;   
    
            this.showFinalMessage(); 
        }
        
        doDownloadExcelTemplate(){
    
    
            // Creating anchor element to download
            let downloadElement = document.createElement('a');
            downloadElement.href = bulkUploadDealTemplate;
            downloadElement.target = '_self';
            // CSV File Name
            downloadElement.download = "Contract Amendment Template.xlsx"; 
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
                type: "standard__objectPage",
                attributes: {
                    objectApiName: 'EBH_Deal__c',
                    actionName: 'home',
                }
            });
        }
        
        handleAccountChange(event) {
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
            this.addAmendInfo();
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
                type: "standard__objectPage",
                attributes: {
                    objectApiName: 'EBH_Deal__c',
                    actionName: 'home',
                }
            });
        }
    
        handleBackToFirstStep() {
            this.objMessageInfos = [];
            this.addAmendInfo();
            this.fileName = "";
            this.file = null;
            this.data = [];
            this.deals = [];
            this.mAllRecords = {};
            this.currentStep = 1;
        }
        addAmendInfo(){
            let objMsgInfo = this.generateInfoMessage(this.cLabel.Deal_Amend_Upload_Info);
            this.objMessageInfos.push(objMsgInfo); 
        }
        initMissingColumn(rows,cols){
            rows.forEach(row => {
                cols.forEach(col => {
                    if (!(col in row)) {
                        row[col] = null; // Add missing columns with null values
                    }
                });
            });
            return rows;
        }
        onPasteResult(event){
            
            if(event.detail && event.detail.isSuccess && event.detail.mappedRows && event.detail.mappedRows.length > 0){
    
                this.isNoFile = false;
                this.isDisableNextBtn = false;
                let itemIds=[];
                let overlapItemIds=[];
                let arrAllLine = [];
                arrAllLine.push(event.detail.mappedColumns);
                this.isReachLimit = false;
    
                let allRowRecord = this.initMissingColumn(event.detail.mappedRows,event.detail.mappedColumns);
                
                if(allRowRecord.length  > (this.amendNoChangeLimit + this.amendChangeLimit)){
                    this.isReachLimit = true;
                    let objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : this.cLabel.Deal_Error_Upload_Maximum_For_No_Change};
                    this.objMessageInfos.push(objMsgInfo);
                }
                
                if(!this.isReachLimit){
                    this.objMessageInfos = [];
                    this.addAmendInfo();
                    for(let i = 0; i < allRowRecord.length; i++){
                        let rowRecord = [];
                        for(let key in allRowRecord[i]){
                            if(allRowRecord[i].hasOwnProperty(key)) {
                                rowRecord.push(allRowRecord[i][key]);
                            }
                        }
                        arrAllLine.push(rowRecord);
                        itemIds.push(allRowRecord[i]['ebay Item Id*']);
                        if(allRowRecord[i]['Updated Item ID'] != null && allRowRecord[i]['Updated Item ID'] != ''){
                            overlapItemIds.push(allRowRecord[i]['Updated Item ID']);
                        }
                        this.mapItemIdAndName[allRowRecord[i]['ebay Item Id*']] = allRowRecord[i]['Item Title'];
                    }
                    this.getAllDeals(itemIds,overlapItemIds,()=>{
                        this.checkSubsidyChange(allRowRecord);
                        console.log('>>>>lsAmendItemIdChange:',this.lsAmendItemIdChange.length);
                        console.log('>>>>lsItemIdsNotFound:',this.lsItemIdsNotFound.length);
                        console.log('>>>>allRowRecord:',allRowRecord.length);
                        if(!this.isReachLimit){
                            this.csvReader(arrAllLine);
                            this.currentStep++;
                        }
                        
                    });
                }
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
                    correctVal = parseFloat(val);
                    
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
        changeDateFormat(dateString){
            //convert from system format yyyy-mm-dd to mm/dd/yyyy
            if(dateString !== null && dateString !== undefined && dateString.indexOf('-') !== -1){
                let parts = dateString.split('-');
                return parts[1]+'/'+parts[2]+'/'+parts[0];
            }   
            return dateString;
        }
        //biz rule validation
        validateAdditionalRules(oneRow,fieldsInvalidFormat)
        {
            // Deal start date should be a future date (if deal start date < current date)       
            // Deal end date should be greater than start date (if deal end date < = deal start date)
            
        //    let fieldsInvalidFormat = oneRow.fieldsInvalidFormat?oneRow.fieldsInvalidFormat:[]; //{fname:colNameLow,flabel: fieldLabel}
            let listErr = [];
            let isAmendChange = oneRow.isAmendChange;
            //if one of the 2 fields is invalid format, no need to check date rule
            // if(!fieldsInvalidFormat.some(item => item.fname === "ebh_dealstartdate__c") && 
            //         !fieldsInvalidFormat.some(item => item.fname === "ebh_dealenddate__c"))
            // {
                if(isNullorUndefinedorZero(this.mapItemDeal[oneRow.EBH_eBayItemID__c])){
                    listErr.push(this.cLabel.Item_ID_Not_Found);
                    return listErr;
                }
                let sellerPrice = isNullorUndefinedorZero(oneRow.EBH_SellerPrice__c) ? null : oneRow.EBH_SellerPrice__c;
                let dealPrice = isNullorUndefinedorZero(oneRow.EBH_DealPrice__c) ? null : oneRow.EBH_DealPrice__c;
                let maxPurchase = oneRow.EBH_MaximumPurchases__c;
                let quantity = oneRow.EBH_Quantity__c;
                let startTime = oneRow.EBH_DealStartTime__c;
                let endTime = oneRow.EBH_DealEndTime__c;
                let startDate = oneRow.EBH_DealStartDate__c;
                let endDate = oneRow.EBH_DealEndDate__c;
                let updatedItem = oneRow.UPD_EBH_eBayItemID__c;
                if(isAmendChange){
                    if((sellerPrice !== null && parseInt(sellerPrice,10) <= 0) || (dealPrice !== null && parseInt(dealPrice,10) <= 0)){
                        listErr.push(this.cLabel.Seller_Price_and_Deal_Price_cannot_be_negative_or_0);
                    }
                    if(!isNullorUndefinedorZero(quantity) || !isNullorUndefinedorZero(maxPurchase) || !isNullorUndefinedorZero(startDate) || 
                    !isNullorUndefinedorZero(startTime) || !isNullorUndefinedorZero(endDate) || !isNullorUndefinedorZero(endTime) || !isNullorUndefinedorZero(updatedItem)){
                        listErr.push(this.cLabel.If_you_are_updating_the_price);
                    }
                }else{         
                    if(quantity !== '' && quantity !== null && quantity !== undefined && maxPurchase !== '' && maxPurchase !== null && maxPurchase !== undefined){
                        if(parseInt(maxPurchase,10) === 0 || parseInt(maxPurchase,10) > parseInt(quantity,10)){
                            listErr.push(this.cLabel.Maximum_Purchases_should_be_greater_than_0);
                        }
                    }
                    
                    let lsOverlapDeal = this.mOverlapDeals[oneRow.UPD_EBH_eBayItemID__c];   
                    if(lsOverlapDeal != null && lsOverlapDeal.length > 0) {
                        for(let i = 0; i < lsOverlapDeal.length; i++){
                            let deal = lsOverlapDeal[i];
                            let sfDeal = this.mapItemDeal[oneRow.EBH_eBayItemID__c];
                            let cStartDate = startDate;
                            let cEndDate = endDate;
                            if(isNullorUndefinedorZero(startDate)){
                                cStartDate = this.changeDateFormat(sfDeal.EBH_DealStartDate__c);
                            }
                            if(isNullorUndefinedorZero(endDate)){
                                cEndDate = this.changeDateFormat(sfDeal.EBH_DealEndDate__c);
                            }
                            let startDateOverlap = this.changeDateFormat(deal.EBH_DealStartDate__c);
                            let endDateOverlap = this.changeDateFormat(deal.EBH_DealEndDate__c);
                            let comStartDate = compareDates(cStartDate,startDateOverlap,this.VALID_DATE_FORMAT);
                            let comStartDateandEndDate = compareDates(cStartDate,endDateOverlap,this.VALID_DATE_FORMAT);
                            let comEndDate = compareDates(cEndDate,endDateOverlap,this.VALID_DATE_FORMAT);
                            let comEndDateAndStartDate = compareDates(cEndDate,startDateOverlap,this.VALID_DATE_FORMAT);
                            
                            if( (comStartDate !== 1 && comStartDateandEndDate < 2) || 
                                (comEndDateAndStartDate !== 1 && comEndDate < 2) ||
                                (comStartDate < 2 && (comEndDate !== 1))
                            ){
                                listErr.push(this.cLabel.There_is_an_overlapping_subsidy_deal_with_this_item_ID + ': ' + oneRow.UPD_EBH_eBayItemID__c);  
                                break;
                            }
                            /* existing formula
                            if((startDate >= dStart && startDate <= dEnd) || 
                            (endDate   >= dStart && endDate   <= dEnd) || 
                            (startDate <= dStart && endDate   >= dEnd) 
                           )*/
                        }       
                        
                    }
                    if(isNullorUndefinedorZero(startDate) || isNullorUndefinedorZero(endDate)){
                        return listErr;
                    }
                    //check if startdate and end date are in correct format; then validate the biz rules
                    if(!fieldsInvalidFormat.some(item => item.fname === "ebh_dealstartdate__c") && !fieldsInvalidFormat.some(item => item.fname === "ebh_dealenddate__c"))
                    {
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
                    }
                }

            // } 
                
            //    row.status = errorMsg;
            return listErr;
        }
    
        showFinalMessage()
        {
            if(this.totalSuccess > 0){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.thank_You_message,
                        variant: 'success'
                    })
                );
            }
            
            this.data = [];
            this.objMessageInfos = []; 
            this.doLoadConfig();
            this.showLoadingSpinner = false;
        }
        sendServerSideErrorToV2(method, error) {
            const excelImporterEvent = new CustomEvent('serversideerror',{detail: {method: method, error: error}} );
            this.dispatchEvent(excelImporterEvent);
        }
    
        constructErrMessageAfterSubmit(rowNumber, errorMsg)
        {
            return "- " + this.label.RowNumber  + " " + rowNumber +": "+errorMsg;
            
        }
}