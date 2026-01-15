/*********************************************************************************************************************************
@ LWC:          lwcExcelImporterV2
@ Version:        1.0
@ Author:         Mony (mony.nou@gaea-sys.com)
@ Purpose:        US-0014106 - UX Changes for Coupon Seller Bulk Upload Component v2
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23-11-2023 / Mony / Created the lwc.
*********************************************************************************************************************************/
import { LightningElement, api, track,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { loadScript } from "lightning/platformResourceLoader";
// import EXCELJS from '@salesforce/resourceUrl/exceljs';
import { EXCELJS } from 'c/lwcExcelJS';
import { downloadGenerateExcel } from 'c/lwcExcelJS';
import getExcelImporterTemplate from '@salesforce/apex/ExcelImporterController.getExcelImporterTemplate';
//import getCouponCategories from '@salesforce/apex/UploadCouponSellerController.getCouponCategories'; //MN-22042024-US-0015008
import generateSellerToolURLParam from '@salesforce/apex/UploadCouponSellerController.generateSellerToolURLParam'; //MN-22042024-US-0015008
import lblStep1 from '@salesforce/label/c.ExcelImporter_V2_Step1'; 
import lblStep2 from '@salesforce/label/c.ExcelImporter_V2_Step2';
import lblPreStep2 from '@salesforce/label/c.ExcelImporter_V2_Pre_Step2';
import lblStep3 from '@salesforce/label/c.ExcelImporter_V2_Step3';
import lblStep4 from '@salesforce/label/c.ExcelImporter_V2_Step4';
import step3HelpTitle from '@salesforce/label/c.ExcelImporter_V2_Step3_Help_Title';
import salesToolURL from '@salesforce/label/c.salesToolURL';

import Generic_Error_No_Permission_On_Cmp from '@salesforce/label/c.Generic_Error_No_Permission_On_Cmp';

export default class LwcExcelImporterV2 extends NavigationMixin(LightningElement) {

    //For Both Version
    @api showSpinner = false;

    @api templateName;
    @api hideCsvLink;
    @api csvTptName;
    @api csvTptFv;
    @api redirectObjId;
    @api parentId;
    @api isFromLtngCmp = false;

    @track selectedTemplateData;
    @track excelImporterTemplate = {};

    @track hasHeader = false;

    //For Version 2
    @track isCmpReady = false;
    @track hasNoPermission = false;
    // @track excelV2Data = {};
    @track currentStep = 1;
    @track useV2 = false;
    @track isServerSideError = false;
    @track msgServiceSideError = '';
    @track errorMethod = '';

    Labels = {Generic_Error_No_Permission_On_Cmp, lblStep1, lblPreStep2, lblStep2, lblStep3, lblStep4, step3HelpTitle, salesToolURL};

    templateLabel = '';
    templateSubtitle = '';
    mainTitle = ''; //MN-07012026-US-0033626
    isHasSubtitle = false;
    isHasNoData = true;
    isExceedMaximum = false; //MN-11122025-US-0033626
    tableFieldGuidance = [];
    tableCommonReasonStep3 = [];
    tableCommonReasonStep4 = [];
    isHasError = false;
    isHasSomeRecordsToGo = false;
    isConfirmMsg = false;
    isFinished = false;
    isShowOnlyErrorRow = false;
    isHideSwitch = false;
    totalNoRecord;
    displayNoRecord = 0;
    parentObjectLabel = 'previous'; //Default with 'Previous'
    
    isShowAccordion = false;
    mappedErrorRows = [];
    numberOfFailedRecord = 0;
    numberOfSuccessRecord = 0;
    numberOfRecordPerPage = 0;
    failedFileName = 'Failed Records'; //Default value is :
    //SRONG TIN/14.03.2024/US-0014857
    bulkOptionValue = 'bulkUpload';
    isPopupBulkModel = false; //MN-22042024-US-0015008: Changed default value from true to false
    get options() {
        return [
            { label: 'Bulk Upload Coupon Seller', value: 'bulkUpload' },
            { label: 'Auto generate Seller list', value: 'salesTool' }
        ];
    }

    excelJS;
    queryParamReturnUrl;

    
    connectedCallback() {

        this.showSpinner = true;

        this.excelJS = new EXCELJS(this);
        // this.initScript();

         //CSP-04112024-US-0016057: Get the query return url string from the current URL
         const queryString = window.location.search;
         const urlParams = new URLSearchParams(queryString);
         this.queryParamReturnUrl = urlParams.get('c__retURL');
         

        getExcelImporterTemplate({templateName:this.templateName, parentId: this.parentId})
        .then(result => {
            
            if(!result.hasNoPermission){
                this.isCmpReady = true;
                this.excelImporterTemplate = result.mapExcelImportTemp;
                this.selectedTemplateData = this.excelImporterTemplate[this.templateName];
                
                if (this.selectedTemplateData.Use_Version_2__c) {
                    //this.excelV2Data = result.excelV2Data;

                    let tableColumn = [];

                    //Create array for Field Guidance Table
                    let rows = this.selectedTemplateData.Field_Guidance_Detail__c.split(/\r?\n/);

                    for (let i = 0; i < rows.length; i++) {
                        let cols = rows[i].split('#');
                        tableColumn.push(cols);
                    }
                    
                    this.tableFieldGuidance = tableColumn;

                    if (result.parentObjectLabel) {
                        this.parentObjectLabel = result.parentObjectLabel;
                    }

                    this.mainTitle = this.selectedTemplateData.MainTitle__c; //MN-07012026-US-0033626

                } else {
                    this.isHideSwitch = true;
                }
                
                if(this.selectedTemplateData){

                    this.useV2 = this.selectedTemplateData.Use_Version_2__c;

                    this.isHideSwitch = this.selectedTemplateData.HideSwitch__c; //MN-11122025-US-0033626
                    
                    this.templateLabel = this.selectedTemplateData.MasterLabel;
                    this.templateSubtitle = this.selectedTemplateData.Subtitle__c;
                    this.isHasSubtitle = this.selectedTemplateData.Subtitle__c != null? true : false;

                    this.hasHeader = this.selectedTemplateData.Use_Excel_Column_Header_Mapping__c ? true : false;

                    //Create array for Common Reason Table for Step 3
                    if (this.selectedTemplateData.Step_3_Common_Error_Table__c) {
                        let tableColumn = [];
                        let rows = this.selectedTemplateData.Step_3_Common_Error_Table__c.split(/\r?\n/);
                        for (let i = 0; i < rows.length; i++) {
                            let cols = rows[i].split('#');
                            tableColumn.push(cols);
                        }
                        this.tableCommonReasonStep3 = tableColumn;
                    }
                    
                    //Create array for Common Reason Table for Step 4
                    if (this.selectedTemplateData.Step_4_Common_Error_Table__c) {
                        let tableColumn = [];
                        let rows = this.selectedTemplateData.Step_4_Common_Error_Table__c.split(/\r?\n/);
                        for (let i = 0; i < rows.length; i++) {
                            let cols = rows[i].split('#');
                            tableColumn.push(cols);
                        }

                        this.tableCommonReasonStep4 = tableColumn;
                    }

                    if (this.selectedTemplateData.Failed_File_Name__c) {
                        this.failedFileName = this.selectedTemplateData.Failed_File_Name__c;
                    }

                    //MN-22042024-US-0015008
                    if (this.selectedTemplateData.DeveloperName == 'Bulk_Upload_Coupon_Sellers') {
                        this.isPopupBulkModel = true;
                    }
                    
                }
                
            }

            this.hasNoPermission = result.hasNoPermission;
            
            this.showSpinner = false;

            

        })
        .catch(error => {
            this.showSpinner = false;
            console.log("V2 - getExcelImporterTemplate error",error);
        });

    }
    /* Script will load in lwcExcelJS itself
    initScript() {

        //Load Script for ExcelJS
        var regeneratorRuntime = undefined;
        window.regeneratorRuntime = regeneratorRuntime;

        loadScript(this, EXCELJS)
        .then(() => {
            // console.log('ExcelJS loaded');
        })
        .catch(error => {
            console.error('Error loading ExcelJS', error);
        });

    }
    */
    get showSwtich() {
        return this.step1 && !this.showSpinner && !this.isHideSwitch;
    }

    get classicModeOn() {
        return !this.useV2;
    }

    //MN-07012026-US-0033626
    get hasMainTitle() {
        return this.mainTitle != null && this.mainTitle != '';
    }

    get step1() {
        return this.currentStep == 1;
    }

    get step2() {
        return this.currentStep == 2 
    }

    get step3() {
        return this.currentStep == 3 
    }

    get step4() {
        return this.currentStep >= 4;
    }

    get step2n3() {
        return this.step2 || this.step3;
    }

    get step2r3r4() {
        return this.step2 || this.step3 || this.step4;
    }

    get showCommonErrorTable() {
        return (this.step3 && this.tableCommonReasonStep3.length > 0) || (this.step4 && this.tableCommonReasonStep4.length > 0);
    }

    get showCommonErrorTableStep4() {
        return this.tableCommonReasonStep4.length > 0;
    }

    get showOnlyError() {
        return this.isShowOnlyErrorRow;
    }

    get hasSuccessRecord() {
        return this.numberOfSuccessRecord > 0;
    }

    get hasFailedRecord() {
        return this.numberOfFailedRecord > 0;
    }

    get hasNoRecord() {
        return this.totalNoRecord == 0;
    }
    
    get showDownloadFailedRecordBtn() {
        return this.hasFailedRecord && this.isFinished;
    }

    get iconShowErrorDetail(){
        return this.isShowAccordion ? "utility:chevronup" : "utility:chevrondown";
    }
    get displayErrorDetail(){
        return this.isShowAccordion;
    }

    get isAllFailedRecord() {
        return this.isFinished && this.numberOfSuccessRecord == 0 && this.numberOfFailedRecord > 0;
    }
    
    handleToggleChange(e) {
        this.useV2 = !e.target.checked;
        this.resetFeature();
    }

    handleToggleShowOnlyError(e){
        this.isShowOnlyErrorRow = e.target.checked;

        this.template.querySelector("c-lwc-excel-importer").handleShowOnlyErrorRows(this.isShowOnlyErrorRow);
    }

    handleToggleViewErrorRows(e) {
        this.isShowOnlyErrorRow = true;
        
        this.template.querySelector("c-lwc-excel-importer").handleShowOnlyErrorRows(this.isShowOnlyErrorRow);
    }

    handleClose(e){
        this.isConfirmMsg = false;
    }

    handleCheckIsCanNextStep(e){
        if(this.isHasSomeRecordsToGo && this.isHasError){
            this.isConfirmMsg = true;
        }else{
            this.handleNextStep(e);
        }
    }

    handleNextStep(e) {
        this.currentStep += 1;
        
        // MN-11122025-US-0033626: Commented out reset on Step 1→2 transition
        // The child component is freshly mounted at Step 2 and has no data yet
        // Reset is only needed when user clicks "Previous" from Step 3 or uses "Reset" button
        // if (this.step2) {
        //     this.handleReset(e);
        // }

        //Check if it is step 4 then call the child component to insert entries into database
        if (this.step4) {
            this.template.querySelector("c-lwc-excel-importer").handleSaveDataV2(e);
        }
        
    }
    //SRONG TIN/14.03.2024/US-0014857 - Auto generate Coupon Seller - Navigate to Seller Tool
    handleBulkUploadOption(e){
        if(this.bulkOptionValue == 'bulkUpload'){
            this.isPopupBulkModel = false;
        }else{  
            this.goToSalesTool();
        }
    }
    goToSalesTool(){

        /* MN-22042024-US-0015008: Commented out
        getCouponCategories({parentId: this.parentId})
        .then(result => {
           // let couponCategories = result.couponCategories;
            let couponMinSite = result.couponMinSite;
            let url = this.Labels.salesToolURL;
            url += '/shiny/deplanning/sellers/?site='+couponMinSite;//+'&vert='+couponCategories+'&meta=';
            window.open(url, "_blank");
            this.isPopupBulkModel = false;
            this.currentStep = 2;
        })
        .catch(error => { 
             console.log("ERROR:::", error);
        }); 
        */

        //MN-22042024-US-0015008--START
        generateSellerToolURLParam({couponId: this.parentId})
        .then(result => {
            
            let couponMinSite = result.couponMinSite;
            let url = this.Labels.salesToolURL;
            url += '/shiny/deplanning/sellers/?site='+couponMinSite;//+'&vert='+couponCategories+'&meta=';
            
            let couponCode = result.couponCode;
            if (couponCode) {
                url += '&cpn_coupon=' + encodeURIComponent(couponCode);
            }
            
            if (result.hasOwnProperty('mapCategory')) {
                
                let array_cate_urlparam = new Array();

                if (result.mapCategory.hasOwnProperty('1') && result.mapCategory["1"].length > 0) {
                    let meta = result.mapCategory["1"];
                    let encodedArray = meta.map(str => encodeURIComponent(str));
                    let joinedEncodedString = encodedArray.join('|');
                    array_cate_urlparam.push('meta=' + joinedEncodedString);
                }
                if (result.mapCategory.hasOwnProperty('2') && result.mapCategory["2"].length > 0) {
                    let l2 = result.mapCategory["2"];
                    let encodedArray = l2.map(str => encodeURIComponent(str));
                    let joinedEncodedString = encodedArray.join('|');
                    array_cate_urlparam.push('l2=' + joinedEncodedString);
                }
                if (result.mapCategory.hasOwnProperty('3') && result.mapCategory["3"].length > 0) {
                    let l3 = result.mapCategory["3"];
                    let encodedArray = l3.map(str => encodeURIComponent(str));
                    let joinedEncodedString = encodedArray.join('|');
                    array_cate_urlparam.push('l3=' + joinedEncodedString);
                }
                if (result.mapCategory.hasOwnProperty('4') && result.mapCategory["4"].length > 0) {
                    let l4 = result.mapCategory["4"];
                    let encodedArray = l4.map(str => encodeURIComponent(str));
                    let joinedEncodedString = encodedArray.join('|');
                    array_cate_urlparam.push('l4=' + joinedEncodedString);
                }

                if (array_cate_urlparam.length > 0) {
                    let cate_urlparam = array_cate_urlparam.join('&');
                    url += '&' + cate_urlparam;
                }

            }
            
            window.open(url, "_blank");
            this.isPopupBulkModel = false;
            this.currentStep = 2;
        })
        .catch(error => { 
             console.log("ERROR:::", error);
        });
        //--END-MN-22042024-US-0015008
    }
    //End
    handleOnChange(event) {
        this.bulkOptionValue = event.target.value
    }
    
    handlePrevStep(e) {
        if (this.step2) {this.handleReset(e);} //Click Previous from Step-2 to Step-1
        this.currentStep -= 1;
    }

    handleReset(e) {
        if (this.step3) this.currentStep = 2;
        this.isHasNoData = true;
        this.isHasError = false;
        this.isExceedMaximum = false; //MN-11122025-US-0033626
        this.isHasSomeRecordsToGo = false;
        this.resetData();
        
        this.callChildResetWithRetry(e); //MN-11122025-US-0033626
    }

    /**
     * @description Attempts to call the child component's reset method with retry logic.
     *              Queries for the c-lwc-excel-importer child component and calls handleResestDataV2.
     *              If the child is not found, retries once after 5 seconds before logging an error.
     * @param {Event} e - The event object passed from the parent handler
     * @param {Number} retryCount - Current retry attempt count (default: 0, max: 1)
     */
    callChildResetWithRetry(e, retryCount = 0) {
        const v1 = this.template.querySelector("c-lwc-excel-importer");
        
        if (v1) {
            v1.handleResestDataV2(e);
        } else if (retryCount < 1) {
            console.warn('Child not found, retrying...');
            setTimeout(() => this.callChildResetWithRetry(e, retryCount + 1), 5000);
        } else {
            console.error('Child component not found after retry.');
        }
    }

    handleDataIsPasted(e) {
        
        this.isHasNoData = !e.detail.isSuccess;
        this.isExceedMaximum = e.detail.isExceedMaximum; //MN-11122025-US-0033626
    }

    handleGoBack(e){
        
        if(this.redirectObjId && this.redirectObjId != '' && this.selectedTemplateData 
            && this.selectedTemplateData.Sobject_Api_Name__c && this.selectedTemplateData.Sobject_Api_Name__c != ''
        ){
            // Notify Lightning Data Service that record has changed to refresh related lists
            getRecordNotifyChange([{recordId: this.redirectObjId}]);
            
            if(this.isFromLtngCmp){
                this.dispatchEvent(
                    new CustomEvent(
                        'handlegoback', 
                        { 
                            detail: {
                                redirectAttr : {
                                    recordId: this.redirectObjId, 
                                    objectApiName: this.selectedTemplateData.Sobject_Api_Name__c,
                                    returnUrl: this.queryParamReturnUrl //CSP-04112024-US-0016057 
                                }
                            } 
                        }
                    )
                );
            }else{
                this[NavigationMixin.Navigate]({
                    type: "standard__recordPage",
                    attributes: {
                        recordId: this.redirectObjId,
                        objectApiName: this.selectedTemplateData.Sobject_Api_Name__c,
                        actionName: 'view'
                    }
                });
            }
            
        }else{
           window.history.back();
        }

    }

    handleValidateData(e) {

        this.handleNextStep(e);

        this.template.querySelector("c-lwc-excel-importer").handleOnUploadV2(e);
    }

    handleDisplayNoOfRecords(e) {
        this.displayNoRecord = e.detail.currentNoRecordPerPage;
    }

    handleCheckUploadResult(e) {

        var result = e.detail;
        
        this.isHasError = result.isSuccess ? false : true;
        this.isHasSomeRecordsToGo = (result.totalOfRecord == result.numberOfFailedRecord) ? false : true;
        //this.isHasNoData = result.isSuccess ? false : true; //So that the Next button on Step-2 is disabled
        this.totalNoRecord = result.totalOfRecord;
        this.numberOfRecordPerPage = result.numberOfRecordPerPage;
        this.numberOfFailedRecord = result.numberOfFailedRecord;
        //SRONG/27.02.2024/US-0014840
        this.mappedErrorRows = result.mappedErrorRows != null?result.mappedErrorRows:[];
        
        
    }

    handleDownloadErrorRecord(e){
        this.showSpinner = true;
        if(this.mappedErrorRows.length > 0){
            // Rename a key in each object in the jsonData array
            this.mappedErrorRows = this.mappedErrorRows.map(obj => {
                // Create a new object with the old key replaced by the new key
                let newObj = { ...obj };
                if(obj["UPLOAD_RESULT_LWC"] !== undefined){
                    newObj["FAILED_RESULT"] =  obj["UPLOAD_RESULT_LWC"]; // Replace "OldKey" with the actual old key
                }
                
                delete newObj["UPLOAD_RESULT_LWC"]; // Delete the old key
                delete newObj["EXCEL_COL_INDEX_LWC"];
                delete newObj["rowTextColor"]; 
                return newObj;
            });
            
            var mappedFields = this.selectedTemplateData.Mapped_Field_Names__c.split(';');
            for(var i = 0; i < mappedFields.length; i++){
                mappedFields[i] = mappedFields[i] ? (mappedFields[i].trim().toLowerCase()) :  mappedFields[i];
            }

            var excelColumns = this.selectedTemplateData.Excel_Column_Names__c.split(';');
    
            for(var i = 0; i < excelColumns.length; i++){
                var fieldAPI = mappedFields[i];
                var excelColumn = excelColumns[i];
                // Replace API field to Excel Column cos the downloaded file is based on Excel Column
                this.mappedErrorRows = this.mappedErrorRows.map(obj => {
                    // Create a new object with the same property of the obj
                    let newObj = { ...obj };
                    if(newObj[fieldAPI] !== undefined){
                        Object.defineProperty(newObj, excelColumn,
                            Object.getOwnPropertyDescriptor(newObj, fieldAPI));
                        delete newObj[fieldAPI];
                    }
                    return newObj;
                });   
            }
            
        }
       
        // Get the current date
        let date = new Date();
        // Format the date as DDMMYYYY
        let day = String(date.getDate()).padStart(2, '0');
        let month = String(date.getMonth() + 1).padStart(2, '0'); // Months are 0-based in JavaScript
        let year = date.getFullYear();
        let dateString = day + month + year;
        if(this.failedFileName.indexOf('.xlsx') == -1){
            this.failedFileName = this.failedFileName + '_' + dateString + '.xlsx';
        }
        
        //SRONG/27.02.2024/US-0014840
        let data = this.mappedErrorRows.map(obj => {
            // Create a new object with the old key replaced by the new key
            if(obj["FAILED_RESULT"] !== undefined && obj["FAILED_RESULT"].indexOf('</a>') != -1){
                obj["FAILED_RESULT"] = obj["FAILED_RESULT"].replace(/<a[^>]*>([^<]+)<\/a>/g, '$1');
            }
            return obj;
        });
    
      
        
        this.excelJS.downloadGenerateExcel(data, this.failedFileName, 'Sheet 1');
        
        this.showSpinner = false;
    }

    handleDownloadFailedRecord(e) {
        
        this.showSpinner = true;
        // Get the current date
        let date = new Date();
        // Format the date as DDMMYYYY
        let day = String(date.getDate()).padStart(2, '0');
        let month = String(date.getMonth() + 1).padStart(2, '0'); // Months are 0-based in JavaScript
        let year = date.getFullYear();
        let dateString = day + month + year;
        if(this.failedFileName.indexOf('.xlsx') == -1){
            this.failedFileName = this.failedFileName + '_' + dateString + '.xlsx';
        }
        
        //SRONG/27.02.2024/US-0014840
        let data = this.mappedErrorRows.map(obj => {
            // Create a new object with the old key replaced by the new key
            if(obj["FAILED_RESULT"].indexOf('</a>') != -1){
                obj["FAILED_RESULT"] = obj["FAILED_RESULT"].replace(/<a[^>]*>([^<]+)<\/a>/g, '$1');
            }
            return obj;
        });
        this.excelJS.downloadGenerateExcel(data, this.failedFileName, 'Sheet 1');
        
        this.showSpinner = false;
    }

    handleCheckSubmitResult(e) {

        var result = e.detail;
        
        this.currentStep += 1;

        this.numberOfSuccessRecord = result.numberOfSuccessRecord;
        this.numberOfFailedRecord = result.mappedErrorRows.length;
        this.mappedErrorRows = result.mappedErrorRows;


        // Rename a key in each object in the jsonData array
        this.mappedErrorRows = this.mappedErrorRows.map(obj => {
            // Create a new object with the old key replaced by the new key
            let newObj = {
                ...obj,
                "FAILED_RESULT": obj["UPLOAD_RESULT_LWC"] // Replace "OldKey" with the actual old key
            };
            delete newObj["UPLOAD_RESULT_LWC"]; // Delete the old key
            delete newObj["EXCEL_COL_INDEX_LWC"];
            delete newObj["rowTextColor"]; 
            return newObj;
        });


        //Transform Column Name based on the custom metadata configuration
        if(this.hasHeader){
            try{
                var mappedFields = this.selectedTemplateData.Mapped_Field_Names__c.split(';');
                for(var i = 0; i < mappedFields.length; i++){
                    mappedFields[i] = mappedFields[i] ? (mappedFields[i].trim().toLowerCase()) :  mappedFields[i];
                }

                var excelColumns = this.selectedTemplateData.Excel_Column_Names__c.split(';');

                for(var i = 0; i < excelColumns.length; i++){
                    var fieldAPI = mappedFields[i];
                    var excelColumn = excelColumns[i];
                    
                    // Replace API field to Excel Column cos the downloaded file is based on Excel Column
                    this.mappedErrorRows = this.mappedErrorRows.map(obj => {
                        // Create a new object with the same property of the obj
                        let newObj = { ...obj };
                        
                        Object.defineProperty(newObj, excelColumn,
                            Object.getOwnPropertyDescriptor(newObj, fieldAPI));
                        delete newObj[fieldAPI];

                        return newObj;
                    });
                }
            }catch(err) {
                this.isFinished = true;
            }    
            
        }

        this.isFinished = true;
    }

    handleServerSideError(e) {
        var result = e.detail;
        this.isServerSideError = true;
        this.isFinished = true;
        this.msgServiceSideError = result.error;
        this.errormethod = result.method;
        console.log('$$$$$ SERVER SIDE ERROR :: ', this.msgServiceSideError);
    }

    handleShowErrorDetail(e){
        this.isShowAccordion = !this.isShowAccordion;
    }

    handleFinish(e) {
        this.handleGoBack(e);
    }

    handleToggleSwtich(e) {
        this.toggleSwitch(e.detail);
    }

    toggleSwitch(mode) {
        this.isHideSwitch = !mode; //If mode = true, then display switch; else hide switch
    }

    resetFeature() {
        this.currentStep = 1;
        this.resetData();
    }

    resetData() {

        this.numberOfFailedRecord = 0;
        this.numberOfSuccessRecord = 0;
        this.numberOfRecordPerPage = 0;
        this.isShowOnlyErrorRow = false;
    }
    

}