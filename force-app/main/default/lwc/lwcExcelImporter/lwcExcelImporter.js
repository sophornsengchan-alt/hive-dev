/*********************************************************************************************************************************
@ LWC:          lwcExcelImporter
@ Version:        1.0
@ Author:         ...
@ Purpose:        ...
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: ...
@               :  24.09.2024/ vadhanak voun/ US-0015465 - Cohort bulk upload - fail scenario messages
@               :  01.07.2025/ Chansophorn Seng/ US-0033008 - Upload Deals functionality in DCA Sub Deals is ignoring the non copied columns
*********************************************************************************************************************************/
import { LightningElement, track,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadScript } from "lightning/platformResourceLoader";
import LightningConfirm from 'lightning/confirm'; //MN-18082023-US-0013630
import papaParse from '@salesforce/resourceUrl/PapaParse';
import getExcelImporterTemplate from '@salesforce/apex/ExcelImporterController.getExcelImporterTemplate';
import getCSVFile from '@salesforce/apex/CSVExporterController.getCSVFile';
import saveRecords from '@salesforce/apex/ExcelImporterController.saveRecords';
import serverSidePreDMLCheck from '@salesforce/apex/ExcelImporterController.serverSidePreDMLCheck';
import sendEmailResult from '@salesforce/apex/ExcelImporterController.sendEmailResult';
import apexProcessPostDML from '@salesforce/apex/ExcelImporterController.apexProcessPostDML';   //NK:15/01/2025:US-0016265

import ExcelImporter_PageSize from '@salesforce/label/c.ExcelImporter_PageSize';
import ExcelImporter_Label_1 from '@salesforce/label/c.ExcelImporter_Label_1';
import ExcelImporter_Label_2 from '@salesforce/label/c.ExcelImporter_Label_2';
import ExcelImporter_Label_3 from '@salesforce/label/c.ExcelImporter_Label_3';
import ExcelImporter_Label_Insert_Success from '@salesforce/label/c.ExcelImporter_Label_Insert_Success';//TH:US-0013870
import ExcelImporter_Label_Update_Success from '@salesforce/label/c.ExcelImporter_Label_Update_Success';//TH:US-0013870
import ExcelImporter_Label_4 from '@salesforce/label/c.ExcelImporter_Label_4';
import ExcelImporter_Label_5 from '@salesforce/label/c.ExcelImporter_Label_5';
import ExcelImporter_Label_6 from '@salesforce/label/c.ExcelImporter_Label_6';
import ExcelImporter_Label_7 from '@salesforce/label/c.ExcelImporter_Label_7';
import ExcelImporter_Label_8 from '@salesforce/label/c.ExcelImporter_Label_8';
import ExcelImporter_Label_9 from '@salesforce/label/c.ExcelImporter_Label_9';
import ExcelImporter_Label_10 from '@salesforce/label/c.ExcelImporter_Label_10';
import ExcelImporter_Label_12 from '@salesforce/label/c.ExcelImporter_Label_12';
import Generic_Error_No_Permission_On_Cmp from '@salesforce/label/c.Generic_Error_No_Permission_On_Cmp';

export default class LwcExcelImporter extends NavigationMixin(LightningElement) {

    @track isCmpReady = false;
    @track hasNoPermission = false;
    @track hasConfirmed = false; //MN-18082023-US-0013630

    @api showSpinner = false;
    @api templateName;

    @api inputPlaceholder;

    @api hideTemplateName;
    @api hideActionBtns;
    @api hideUploadBtn;
    @api hideResetBtn;
    @api hideBackBtn;
    @api hideListTable;

    @api hideCsvLink;
    @api csvTptName;
    @api csvTptFv;

    // 01.07.2025/ CSP:US-0033008 Start
    @track showValidateHeaderErrorMsg;
    @track validateHeaderColumns;
    @track validateHeaderErrorMsg;
    // 01.07.2025/ CSP:US-0033008 End

    @api hideDescr;
    @track descr = '';
    @track hasDescr = false;

    @track csvDownloadFile = '';
    @track hasCsvDownloadFile = false;

    templateLabel = '';
    templateSubtitle = '';
    isHasSubtitle = false;
    canUpload = false;
    isUpsert = false; //TH:US-0013870
    isInsert = false; //VM US-0016749
    @track hasHeader = false;
    
    colHeadersMeta = []; //NK:24/09/2024:US-0015465. Store column name from metadata to pass to apex for validation (if required)
    colHeadersExcel = []; //NK:24/09/2024:US-0015465.Store column name from csv/excel to pass to apex for validation (if required)

    @track excelImporterTemplate = {};
    @track mapFldApiNameToFldLabel = {};
    @track clipText = '';
    @track displayTableContent = false;
    @track mapColsToFields = {};
    @track tableColumns = [];
    @track tableRows = [];
    @track mappedColumns = [];
    @track mappedRows = [];
    @track selectedTemplateData;
    @track batchSize = 25;
    numberOfSuccessRecord = 0;
    numberOfInsertSuccessRecord = 0;//TH:US-0013870
    numberOfUpdateSuccessRecord = 0;//TH:US-0013870
    numberOfFailedRecord = 0;
    numberOfInformRecord = 0; //MN-18082023-US-0013630
    chunkIndex = 0;
    totalChunkSize = 0;
    mainErrorMsg = '';
    isDMLProgress = false;
    @track showProgress = false;
    @track showMainErrorMsg = false;
    @track successMsgClassStyle = '';
    @track errorMsgClassStyle = '';
    @track informMsgClassStyle = ''; //MN-18082023-US-0013630
    @track disablePasteContent = false;
    
    @api redirectObjId;
    @api parentId;
    
    // Pagination
    @track numberOfRecordPerPage=200;
    @track totalPage = 0;
    @track currentPage = 1;
    prevNav = 'Prev';
    nextNav = 'Next';

    @api isFromLtngCmp = false;

    mapRequiredFields = {};
    mapDuplicatedFields = {}; //TH:US-0013870

    @track columnsWidth = 141;
    INDEX_COLNAME = 'EXCEL_COL_INDEX_LWC';

    listAllRecordToSave = [];
    setExistingIds = new Set(); //MN-18082023-US-0013630 

    listError = []; // SB 26.10.2023 US-0013554

    //MN-09122023-US-0014505--START
    showAmountRecordInfor = false; //MN-09122023-US-0014505
    @track maximumAmountRecord = 0; //MN-09122023-US-0014505
    @track existedAmountRecord = 0; //MN-09122023-US-0014505
    @track uploadingAmountRecord = 0; //MN-09122023-US-0014505
    @track isAllowUpload = true;
    //MN-09122023-US-0014505--END
    @track countRecord = 0; //VM US-0016749
    Labels = {ExcelImporter_Label_1,ExcelImporter_Label_2,ExcelImporter_Label_3,ExcelImporter_Label_4,ExcelImporter_Label_5,ExcelImporter_Label_6,ExcelImporter_Label_7,ExcelImporter_Label_8,ExcelImporter_Label_9,ExcelImporter_Label_10,ExcelImporter_Label_12,Generic_Error_No_Permission_On_Cmp,ExcelImporter_Label_Insert_Success,ExcelImporter_Label_Update_Success};


    //MN-24112023-US-0014106--START 
    @api isExcelImporterV2 = false;
    @track mappedErrorRows = [];
    showInput = true;
    showPreviewTable = false;
    isExcelImportV2Enabled = false;
    isShowOnlyError = false;
    indexOfError = [];
    //---END

    connectedCallback() {
        this.showSpinner = true;
        this.inputPlaceholder = this.Labels.ExcelImporter_Label_6; // 07.06.2023 / Sophal Noch / US-0013657 :
        this.numberOfRecordPerPage = (ExcelImporter_PageSize && parseInt(ExcelImporter_PageSize) > 0) ? parseInt(ExcelImporter_PageSize) : this.numberOfRecordPerPage;
        loadScript(this, papaParse).then(() => {          
        }).catch(error => {
            console.error({
              message: 'Error occured on loadScript papaParse',
              error
            });
          });
        
        

        getExcelImporterTemplate({templateName:this.templateName, parentId: this.parentId})
        .then(result => {
            
            if(!result.hasNoPermission){
                this.isCmpReady = true;
                this.excelImporterTemplate = result.mapExcelImportTemp;
                this.mapFldApiNameToFldLabel = result.mapFldApiNameToFldLabel; // 26.09.2022 / Sophal Noch / US-0011695 : map field api name to field label
                
                this.selectedTemplateData = this.excelImporterTemplate[this.templateName];
                if(this.selectedTemplateData){
                    this.templateLabel = this.selectedTemplateData.MasterLabel;
                    this.templateSubtitle = this.selectedTemplateData.Subtitle__c;
                    this.isHasSubtitle = this.selectedTemplateData.Subtitle__c != null? true : false;
                    this.batchSize = (this.selectedTemplateData.Batch_Size__c && this.selectedTemplateData.Batch_Size__c > 0) ? Math.ceil(this.selectedTemplateData.Batch_Size__c) : this.batchSize;
                    this.descr = (this.selectedTemplateData.Description__c && this.selectedTemplateData.Description__c != '') ?  this.selectedTemplateData.Description__c : null;
                    this.inputPlaceholder = (this.selectedTemplateData.Input_Placeholder__c && this.selectedTemplateData.Input_Placeholder__c != '') ?  this.selectedTemplateData.Input_Placeholder__c : this.inputPlaceholder; // 07.06.2023 / Sophal Noch / US-0013657 :
                    this.hasDescr = this.descr != null ? true : false;
                    // 07.06.2023 / Sophal Noch / US-0013657 : start
                    this.hideActionBtns =  this.selectedTemplateData.Hide_Action_Buttons__c;
                    this.hideBackBtn =  this.selectedTemplateData.Hide_Back_Button__c;
                    this.hideDescr =  this.selectedTemplateData.Hide_Description__c;
                    this.hideListTable =  this.selectedTemplateData.Hide_List_Table__c;
                    this.hideResetBtn =  this.selectedTemplateData.Hide_Reset_Button__c;
                    this.hideTemplateName =  this.selectedTemplateData.Hide_Template_Name__c;
                    this.hideUploadBtn =  this.selectedTemplateData.Hide_Upload_Button__c;
                    // 07.06.2023 / Sophal Noch / US-0013657 : stop

                    // 01.07.2025/ CSP:US-0033008 start:
                    this.validateHeaderColumns = this.selectedTemplateData.Validate_Header_Columns_Client_Side__c;
                    this.validateHeaderErrorMsg = this.selectedTemplateData.Validate_Header_Client_Side_Error_Msg__c;
                    // 01.07.2025/ CSP:US-0033008 End
                    
                    this.isUpsert =  this.selectedTemplateData.Operator__c == 'Upsert' ? true : false; //TH:US-0013870
                    this.isInsert =  this.selectedTemplateData.Operator__c == 'Insert' ? true : false; //VM US-0016749
                    
                    this.isExcelImportV2Enabled = this.selectedTemplateData.Use_Version_2__c; //MN-05122023-US-0014106 
                    
                    this.doInitTableColumn();
                    if(this.csvTptName && this.csvTptName != ''){
                        this.hasCsvDownloadFile = true;
                    }

                    //MN-09122023-US-0014505--START
                    if (result.existedRecords >= 0) {
                        this.existedAmountRecord = result.existedRecords;
                        this.countRecord = result.existedRecords;
                        this.maximumAmountRecord = this.selectedTemplateData.Maximum_Records__c;
                        this.showAmountRecordInfor = true;
                    }
                    //MN-09122023-US-0014505--END
                }

            }
            this.hasNoPermission = result.hasNoPermission;

            this.showSpinner = false;

        })
        .catch(error => {
            this.showSpinner = false;
            //MN-08122023-US-0014106--START
            this.sendServerSideErrorToV2('ExcelImporterV1:getExcelImporterTemplate()',error);
            //--END
        });

    }

    //MN-09122023-US-0014505--START
    get isExceedMaximum() {
        if(this.isInsert) {
            //VM US-0016749
            return this.existedAmountRecord > this.maximumAmountRecord;
        }
        return this.existedAmountRecord >= this.maximumAmountRecord;
    }
    get isDisplayUploadFeature() {
        return (!this.showAmountRecordInfor || (this.showAmountRecordInfor && (!this.isExceedMaximum || this.isUpsert))); 
    }
    get remainRecordAmount() {
        return (this.isExceedMaximum? 0 : (this.maximumAmountRecord - this.existedAmountRecord));
    }

    get isExceedUploadAmount() { 
        var isExceed = this.uploadingAmountRecord > this.remainRecordAmount;
        if(this.isInsert){
            isExceed = this.uploadingAmountRecord > (this.maximumAmountRecord - this.countRecord);
        }
        if (isExceed) this.canUpload = false; //In case of Insert, we don't allow to upload if exceed maximum amount
        return isExceed;
    }
    //MN-09122023-US-0014505--END

    doGetCSVFile(callback){

        if(this.csvTptName && this.csvTptName != ''){
            var arrFilter = [];
            if(this.csvTptFv && this.csvTptFv != '') arrFilter = this.csvTptFv.split(',');
            getCSVFile({templateName : this.csvTptName, listFilterVal : arrFilter, parentId : this.parentId, tptSetting : null})
            .then(result => {

                if(result.status == 'ok'){
                    this.csvDownloadFile = result.fileContent == null ? '' : result.fileContent;
                    if(callback != null) callback();
                }else if(result.status == 'ko'){
                    console.log("getCSVFile error : ",result.error);
                }
                this.showSpinner = false;
            })
            .catch(error => {
                this.showSpinner = false;
                console.log("getCSVFile error : ",error);
                //MN-08122023-US-0014106--START
                this.sendServerSideErrorToV2('ExcelImporterV1:doGetCSVFile()',error);
                //--END
            });
        }

    }

    doInitTableColumn(){
        // 26.09.2022 / Sophal Noch / US-0011695 : set table column when component is loaded
        this.hasHeader = false;
        this.mapColsToFields = {};
        if(this.selectedTemplateData){
            this.hasHeader = this.selectedTemplateData.Use_Excel_Column_Header_Mapping__c ? true : false;

            if(this.selectedTemplateData.Required_Fields__c && this.selectedTemplateData.Required_Fields__c != ''){
                var listRequiredField = this.selectedTemplateData.Required_Fields__c.split(';');
                for(var i = 0; i < listRequiredField.length; i++){
                    this.mapRequiredFields[listRequiredField[i].trim().toLowerCase()] = true;
                }
            }
            //TH:US-0013870 - getDuplicatedField
            if(this.selectedTemplateData.Duplicated_Fields__c && this.selectedTemplateData.Duplicated_Fields__c != ''){
                var listDupField = this.selectedTemplateData.Duplicated_Fields__c.split(';');
                for(var i = 0; i < listDupField.length; i++){
                    this.mapDuplicatedFields[listDupField[i].trim().toLowerCase()] = true;
                }
            }
            var mappedFields = this.selectedTemplateData.Mapped_Field_Names__c.split(';');
            for(var i = 0; i < mappedFields.length; i++){
                mappedFields[i] = mappedFields[i] ? (mappedFields[i].trim().toLowerCase()) :  mappedFields[i];
            }
            this.tableColumns.push({label: 'No', fieldName: this.INDEX_COLNAME,initialWidth: 70, cellAttributes: {class: {fieldName: 'rowTextColor'}}});
            
            if(this.hasHeader){
                var excelColumns = this.selectedTemplateData.Excel_Column_Names__c.split(';');
                for(var i = 0; i < excelColumns.length; i++){
                    var fieldLabel = (this.mapFldApiNameToFldLabel[mappedFields[i]] ? this.mapFldApiNameToFldLabel[mappedFields[i]] : mappedFields[i]);
                    if(this.mapRequiredFields[mappedFields[i]]){
                        fieldLabel = fieldLabel+'*';
                    }
                    this.colHeadersMeta.push(excelColumns[i]); //NK:24/09/2024:US-0015465

                    this.mapColsToFields[excelColumns[i]] = mappedFields[i];
                    //NK:24/09/2024:US-0015465
                    //this.columnsWidth = excelColumns.length <= 7? '': 141;
                    this.tableColumns.push({label: fieldLabel, fieldName: mappedFields[i],initialWidth: this.columnsWidth,cellAttributes: {class: {fieldName: 'rowTextColor'}}});
                }
                this.mappedColumns = mappedFields;
            }else{
                this.mappedColumns = mappedFields;
                for(var i = 0; i < this.mappedColumns.length; i++){
                    this.tableColumns.push({label: (this.mapFldApiNameToFldLabel[mappedFields[i]] ? this.mapFldApiNameToFldLabel[mappedFields[i]] : mappedFields[i]), fieldName: this.mappedColumns[i],initialWidth:  this.columnsWidth,cellAttributes: {class: {fieldName: 'rowTextColor'}}});
                }
            }
            this.displayTableContent = true;
        }
    }

    handleKeyPress(e){
        if (e.ctrlKey !== true && e.key != 'v') {
            e.preventDefault();
            e.stopPropagation();
          }
    }

    handlePasteData(e){
        e.preventDefault();
        var cb;
        this.clipText = '';
        if (e.clipboardData && e.clipboardData.getData) {
          cb = e.clipboardData;
          this.clipText = cb.getData('text/plain');
        } else {
          cb = e.originalEvent.clipboardData;
          this.clipText = cb.getData('text/plain');
        }
        
        return this.doPasteData();
    }


    handleGoBack(e){
    
        if(this.redirectObjId && this.redirectObjId != '' && this.selectedTemplateData 
            && this.selectedTemplateData.Sobject_Api_Name__c && this.selectedTemplateData.Sobject_Api_Name__c != ''
        ){
            
            if(this.isFromLtngCmp){
                this.dispatchEvent(
                    new CustomEvent(
                        'handlegoback', 
                        { 
                            detail: {
                                redirectAttr : {
                                    recordId: this.redirectObjId, 
                                    objectApiName: this.selectedTemplateData.Sobject_Api_Name__c
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

    handleResetData(e){
        try
        {
            this.showSpinner = true;
            this.disablePasteContent = false;
            this.tableRows = [];
            this.mappedRows = [];
            this.mappedErrorRows = [];
            this.listAllRecordToSave = [];
            this.mappedRowArr = [];
            this.canUpload = false;
            this.isDMLProgress = false;
            this.hasConfirmed = false; //MN-18082023-US-0013630
    
            this.totalPage = 0; //MN-15122023-US-0014505: Reset total page
            this.showValidateHeaderErrorMsg=false; // 01.07.2025/ CSP:US-0033008 hide display 
    
            //MN-09122023-US-0014505--START
            if (this.showAmountRecordInfor) {
                this.uploadingAmountRecord = 0; 
                this.isAllowUpload = true;
                this.setExistingIds = new Set();
                this.countRecord = this.existedAmountRecord;
            }
            //MN-09122023-US-0014505--END
    
            this.handleResetBeforeUpload();
            
            //MN-05122023-US-0014106--START
            if (this.isExcelImportV2Enabled) {
                this.isShowOnlyError = false;
                // Fire event to parent
                const toggleSwitch = new CustomEvent('toggleswitch',{detail: true} ); //Turn on switch when reset data for Classic Excel Importer
                this.dispatchEvent(toggleSwitch); 
            }
            //MN-05122023-US-0014106--END
    
            
        }catch(ex)
        {
            console.error('Error in handleResetData : ',ex);
        }

        this.showSpinner = false;
    }

    handleResetBeforeUpload(){
        try
        {
            this.removeUploadResultColumn();
            this.numberOfSuccessRecord = 0;
            this.numberOfFailedRecord = 0;
            this.numberOfInsertSuccessRecord = 0;
            this.numberOfUpdateSuccessRecord = 0;
            this.setErrorAndSuccessMessageClassStyle();
            this.totalChunkSize = 0;
            this.chunkIndex = 0;
            this.showProgress = false;
            this.showMainErrorMsg = false;
            this.mainErrorMsg = '';
        }catch(ex)
        {
            console.error('Error in handleResetBeforeUpload : ',ex);
        }
        
    }

    doPasteData(){

        // this.displayTableContent = false;

        var pastedResult = {}

        this.handleResetData(null);

        var index = 0;

        var hasRemovedNotFoundColumn = false;
        var mapNotFoundCsvColHeader = {};
        
        if(this.clipText != null && this.clipText != ''){
            
            //MN-06092023-US-0014119:Fixed the delimiter problem when we don't use header
            var delimiter = "" 
            if (this.templateName == "Bulk_Upload_Nominated_Item" && this.hasHeader === false) {
                delimiter = "\t";
            }

            this.showSpinner = true;
            var  self = this;
            Papa.parse(this.clipText,{
                // delimiter: "",
                delimiter: delimiter, 
                newline: "",	// auto-detect
                quoteChar: '"',
                escapeChar: '"',
                header: this.hasHeader,
                transformHeader: undefined,
                dynamicTyping: false,
                preview: 0,
                encoding: "",
                worker: false,
                comments: false,
                step: function(results) {
                    
                    var indexColname = self.INDEX_COLNAME;
                    var rowRecord = {};
                    rowRecord[indexColname] = (index+1);
                    
                    if(self.selectedTemplateData){
                        //console.log('self.selectedTemplateData',JSON.stringify(self.selectedTemplateData));
                        if(self.hasHeader){

                            if(Object.keys(results.data[0]).length <= 0) return;
                            if(Object.keys(results.data[0]).length == 1) {
                                for (var key in results.data[0]) {
                                    if(results.data[0].hasOwnProperty(key)) {                                        
                                        if(!results.data[0][key] || results.data[0][key] == "") return;
                                    }
                                }
                            }
                            self.colHeadersExcel = Object.keys(results.data[0]); //NK:24/09/2024:US-0015465
                            //console.log('--colHeadersExcel: '+self.colHeadersExcel);
                            if(!hasRemovedNotFoundColumn){
                                // 12.12.2022 / Sophal Noch / US-0012119 : if column exists in custom metadata but not exist in excel, it does not include in table
                                var mapCsvColHeader = {};
                                for(var i = 0; i < results.meta.fields.length; i++){
                                    mapCsvColHeader[results.meta.fields[i]] = true;
                                }

                                var newTableColumns = [];
                                newTableColumns.push({label: 'No', fieldName: self.INDEX_COLNAME,initialWidth: 70, cellAttributes: {class: {fieldName: 'rowTextColor'}}});
                                for(var key in self.mapColsToFields){
                                    if(self.mapColsToFields.hasOwnProperty(key)) {
                                        var mappedField = self.mapColsToFields[key];
                                        if(mapCsvColHeader[key]){
                                            var fieldLabel = (self.mapFldApiNameToFldLabel[mappedField] ? self.mapFldApiNameToFldLabel[mappedField] : mappedField);
                                            if(self.mapRequiredFields[mappedField]){
                                                fieldLabel = fieldLabel+'*';
                                            }
                                            //NK:24/09/2024:US-0015465
                                            //var mapColsToFields = JSON.parse(JSON.stringify(self.mapColsToFields));
                                            //self.columnsWidth = Object.keys(mapColsToFields).length <= 7? '': 141;
                                            newTableColumns.push({label: fieldLabel, fieldName: mappedField,initialWidth: self.columnsWidth,cellAttributes: {class: {fieldName: 'rowTextColor'}}});
                                        }else{
                                            mapNotFoundCsvColHeader[mappedField] = true;
                                        }
                                    }
                                }
                                self.tableColumns = newTableColumns;

                                hasRemovedNotFoundColumn = true;
                            }

                            for (var col in self.mapColsToFields) {
                                if(self.mapColsToFields.hasOwnProperty(col)){
                                    if(!mapNotFoundCsvColHeader[self.mapColsToFields[col]]){
                                        rowRecord[self.mapColsToFields[col]] = results.data[0][col] ? results.data[0][col] : null;
                                    }     
                                }
                            }
                        }else{

                            if(results.data[0].length <= 0 || (results.data[0].length == 1 && (!results.data[0] || results.data[0] == ""))) return;

                            var cellArr = [];
                            for (var col in results.data[0]) {
                                cellArr.push({value:results.data[0][col]});
                            }
                            for(var i = 0; i < self.mappedColumns.length; i++){
                                rowRecord[self.mappedColumns[i]] = cellArr[i] ? cellArr[i].value : null;
                            }
                            
                        }
                        self.mappedRows.push(rowRecord);

                    }else{
                        var cellArr = [];
                        for (var col in results.data[0]) {
                            cellArr.push({value:results.data[0][col]});
                        }
                        for(var i = 0; i < cellArr.length; i++){
                            if(index == 0) self.tableColumns.push({label: i+1, fieldName: i+1, initialWidth:  self.columnsWidth});
                            rowRecord[i+1] = cellArr[i] ? cellArr[i].value : null;
                        }

                        self.mappedRows.push(rowRecord);

                    }

                    index++;

                },
                complete: function(results, file) {

                    // self.displayTableContent = true;

                    if(self.selectedTemplateData) self.canUpload = true;

                    self.totalPage = self.mappedRows.length > 0 ? Math.ceil(self.mappedRows.length / self.numberOfRecordPerPage) : self.mappedRows.length;
                    self.populateTableRows(self);
                    
                    self.showSpinner = false;
                    self.displayTableContent = true;
                    
                    //MN-27112023-US-0014106--START
                    if (self.isExcelImporterV2) {

                        self.showPreviewTable = true;
                        self.showInput = false;
                        
                        let isExceedMaximum = self.maximumAmountRecord && self.maximumAmountRecord > 0 && self.mappedRows.length > self.remainRecordAmount; //MN-11122025-US-0033626 fix: changed from self.isExceedMaximum to this line to avoid issue when user switch between V1 and V2

                        // Fire event to parent
                        const dataIsPasted = new CustomEvent('dataispasted',{detail: {isSuccess: true, isExceedMaximum:isExceedMaximum} }); //MN-11122025-US-0033626 fix: added isExceedMaximum to inform parent component
                        self.dispatchEvent(dataIsPasted);   

                    } else if (self.isExcelImportV2Enabled) {
                        // Fire event to parent
                        const toggleSwitch = new CustomEvent('toggleswitch',{detail: false} ); // Turn off switch when data is pased for Classic Excel Importer
                        self.dispatchEvent(toggleSwitch); 
                    }
                    //--END

                    //MN-09122023-US-0014505--START
                    if (self.showAmountRecordInfor && self.remainRecordAmount == self.maximumAmountRecord) {
                        self.uploadingAmountRecord = self.mappedRows.length;
                    }
                    //MN-09122023-US-0014505--END

                    pastedResult['isSuccess'] = true;
                    pastedResult['mappedColumns'] = self.mappedColumns;
                    pastedResult['mappedRows'] = self.mappedRows;
                    
                    self.sendResultToParent(pastedResult);
                    
                    // 01.07.2025/ CSP:US-0033008
                    if(self.validateHeaderColumns) {
                        self.onValidatePasteResult(pastedResult);
                    }
                     
                },
                error: function(error , file) {
                    console.error("parsing error: ", error);
                    pastedResult['isSuccess'] = false;
                    pastedResult['error'] = error;
                    self.sendResultToParent(pastedResult);
                    //MN-08122023-US-0014106--START
                    self.sendServerSideErrorToV2('ExcelImporterV1:doPasteData()',error);
                    //--END

                },
                download: false,
                downloadRequestHeaders: undefined,
                downloadRequestBody: undefined,
                skipEmptyLines: false,
                chunk: undefined,
                chunkSize: undefined,
                fastMode: undefined,
                beforeFirstChunk: undefined,
                withCredentials: undefined,
                transform: undefined,
                delimitersToGuess: [',', '\t', '|', ';', Papa.RECORD_SEP, Papa.UNIT_SEP]
            });            
        }
    }

    sendResultToParent(pastedResult){

        const excelImporterEvent = new CustomEvent('excel_importer_result',{detail: pastedResult} );
        this.dispatchEvent(excelImporterEvent);
    }

    handleOnUpload(e){
        this.showSpinner = true;
        this.canUpload = false;
        this.disablePasteContent = true;

        this.handleResetBeforeUpload();

        var newTableColumns = [];
        this.mappedErrorRows = [];
       
        for(var i = 0; i < this.tableColumns.length;i++){
            if(i == 1){
                newTableColumns.push({label: 'Upload Result', fieldName: 'UPLOAD_RESULT_LWC',initialWidth: 564,wrapText: true, type: "richText" ,cellAttributes: {class: {fieldName: 'rowTextColor'}}});
            }
            newTableColumns.push(this.tableColumns[i]);
        }
        this.tableColumns = newTableColumns;


        this.showProgress = true;
        this.totalChunkSize = Math.ceil(this.mappedRows.length / this.batchSize);
        this.chunkIndex = 0;
        var indexStartFrom = 0;
        let mySet1 = new Set();
        // console.log('this.mappedRows before client-side validation: ',JSON.parse(JSON.stringify(this.mappedRows)));
        for(var i = 0; i < this.mappedRows.length; i++){ // 12.12.2022 / Sophal Noch / US-0012119 : client-side validation, to check required field
            delete this.mappedRows[i]['UPLOAD_RESULT_LWC'];
            for(var key in this.mappedRows[i]){
                var fieldLabel = (this.mapFldApiNameToFldLabel[key] ? this.mapFldApiNameToFldLabel[key] : key);//TH:US-0013870: get field label
                if(this.mappedRows[i].hasOwnProperty(key) && key != this.INDEX_COLNAME && this.mapRequiredFields[key] && (this.mappedRows[i][key] == null || this.mappedRows[i][key] == '' || (this.mappedRows[i][key] && this.mappedRows[i][key].trim() == '')) ){
                    this.mappedRows[i]['UPLOAD_RESULT_LWC'] = fieldLabel + ' ' +this.Labels.ExcelImporter_Label_9;
                    this.mappedRows[i]['rowTextColor'] = 'slds-text-color_error';
                    this.numberOfFailedRecord++;
                    this.mappedErrorRows.push(this.mappedRows[i]);
                    break;
                }
                //TH:US-0013870: if duplicate field not empty
                if(this.mapDuplicatedFields[key]){
                    if(this.mappedRows[i].hasOwnProperty(key) && mySet1.has(this.mappedRows[i][key])){
                        this.mappedRows[i]['UPLOAD_RESULT_LWC'] = 'Duplicate '+fieldLabel+' Found';
                        this.mappedRows[i]['rowTextColor'] = 'slds-text-color_error';
                        this.numberOfFailedRecord++;
                        this.mappedErrorRows.push(this.mappedRows[i]);
                        break;
                    }
                    mySet1.add(this.mappedRows[i][key]);
                }
            }

        }
        var className;
        var methodName;
        
        if(this.numberOfFailedRecord > 0){
            this.setErrorAndSuccessMessageClassStyle();
            this.populateTableRows();
            this.showSpinner = false;

            //MN-04122023-US-0014106--START: For Excel Importer V2: Send some data to parent
            if (this.isExcelImporterV2) {
                const excelImporterEvent = new CustomEvent('uploadresult',{detail: {phase:"client-side-validation", isSuccess: false, totalOfRecord:this.mappedRows.length, numberOfFailedRecord: this.numberOfFailedRecord, numberOfRecordPerPage: this.numberOfRecordPerPage,mappedErrorRows:this.mappedErrorRows}} );//SRONG/27.02.2024/US-0014840
                this.dispatchEvent(excelImporterEvent);
            }
            //--END

        }else{

            // 12.12.2022 / Sophal Noch / US-0012119 : call server-side to validate and populate fields in records
            if(this.selectedTemplateData.Server_Side_Pre_DML_Check__c && this.selectedTemplateData.Server_Side_Pre_DML_Check__c != '' && this.selectedTemplateData.Server_Side_Pre_DML_Check__c.indexOf('.') !== -1){

                var requestLength = this.selectedTemplateData.Server_Side_Pre_DML_Check__c.length;
                var methodIndex = this.selectedTemplateData.Server_Side_Pre_DML_Check__c.lastIndexOf(".");

                className = this.selectedTemplateData.Server_Side_Pre_DML_Check__c.substring(0, methodIndex);
                methodName = this.selectedTemplateData.Server_Side_Pre_DML_Check__c.substring(methodIndex + 1, requestLength);

            }

            if(className && methodName){
                this.doServerSideCheck(indexStartFrom, className, methodName);
            }else{
                this.doSave(indexStartFrom, null);
            }
           
        }

        
        
    }
    doSave(indexStartFrom){
        this.isDMLProgress = true;
        var listRecordToSave = [];
        if(indexStartFrom == 0){this.mappedErrorRows = [];}
        if(this.listAllRecordToSave.length <= 0){
            for(var i = indexStartFrom; i < this.mappedRows.length; i++){
                // Delete the old key
                listRecordToSave.push(JSON.parse(JSON.stringify(this.mappedRows[i])));
                delete listRecordToSave[listRecordToSave.length -1][this.INDEX_COLNAME];
                if(listRecordToSave.length >= this.batchSize) break;
            }
        }else{
            // 12.12.2022 / Sophal Noch / US-0012119 : save records after server-side validation
            for(var i = indexStartFrom; i < this.listAllRecordToSave.length; i++){
                listRecordToSave.push(this.listAllRecordToSave[i]);
                if(listRecordToSave.length >= this.batchSize) break;
            }
        }
        
        //SRONG/27.02.2024/US-0014840
        if (this.isExcelImporterV2 && indexStartFrom == 0) {
            var newMappedRows = [];
            for(var i = indexStartFrom; i < this.mappedRows.length; i++){
                var isError = false;
                for(var index = 0; index < this.indexOfError.length; index++ ){
                    if(i == this.indexOfError[index]){
                        isError = true;
                        break;
                    }
                }
                if(!isError){
                    newMappedRows.push(this.mappedRows[i]);
                }
            }
            this.mappedRows = newMappedRows;
        }
        // console.log('listRecordToSave==>', listRecordToSave);
        saveRecords({sobjectApiName:this.selectedTemplateData.Sobject_Api_Name__c, operator:this.selectedTemplateData.Operator__c, listRecord:listRecordToSave, templateName : this.templateName })
        .then(result => {
            if(result.status == 'ok'){
                this.chunkIndex ++;
                if(result.listResult){
                    for(var i = 0; i < listRecordToSave.length; i++){
                        var msgResult = result.listResult[i].msg;
                        this.mappedRows[indexStartFrom + i]['UPLOAD_RESULT_LWC'] = msgResult;
                        if(result.listResult[i].isSucess){
                            this.mappedRows[indexStartFrom + i]['rowTextColor'] = 'slds-text-color_success';
                            this.numberOfSuccessRecord++;
                            //TH:US-0013870
                            if(this.isUpsert){
                                if(msgResult.includes('Insert')){
                                    this.numberOfInsertSuccessRecord++;
                                }else if(msgResult.includes('Update')){
                                    this.numberOfUpdateSuccessRecord++;
                                }
                            }//end US-0013870
                        }else{
                            this.mappedRows[indexStartFrom + i]['rowTextColor'] = 'slds-text-color_error';
                            this.numberOfFailedRecord++;
                            // SB 26.10.2023 US-0013554
                            this.listError.push('- Row number : ' + (indexStartFrom + i + 1) + '. ' + msgResult);
                        }
                    }
                }
                var batchEndIndex = indexStartFrom + listRecordToSave.length;
                if(batchEndIndex >= this.mappedRows.length){
                    this.setErrorAndSuccessMessageClassStyle();
                    this.populateTableRows();
                    this.showSpinner = false;
                    // SB 26.10.2023 US-0013554 Send email when process is completed
                    if (this.selectedTemplateData && this.selectedTemplateData.DeveloperName == 'Upload_Deal_V2') {
                        this.handleSendEmailResult(this.numberOfSuccessRecord,this.listError);
                    }

                    //MN-05122023-US-0014106--START
                    if (this.isExcelImporterV2) {
                        
                        if (this.listError.length > 0) {
                            this.isShowOnlyError = true;
                            this.currentPage = 1;
                            this.populateErrorTableRows(true);
                            this.showPreviewTable = true;
                        }

                        // Fire event to parent
                        const submitresultEvent = new CustomEvent('submitresult',{detail: {numberOfSuccessRecord:this.numberOfSuccessRecord, mappedErrorRows: this.mappedErrorRows}} );
                        this.dispatchEvent(submitresultEvent);
                    }
                    //--END

                    //MN-09122023-US-0014505--START
                    if (this.showAmountRecordInfor) {
                        if (this.isUpsert) {
                            this.existedAmountRecord += this.numberOfInsertSuccessRecord;
                        }else {
                            this.existedAmountRecord += this.numberOfSuccessRecord;
                        }
                        
                    }
                    //MN-09122023-US-0014505--END

                    //NK:15/01/2025:US-0016265
                    this.processPostDML();

                }else{
                    this.doSave(batchEndIndex);
                }

                
            }else{
                
                this.mainErrorMsg = result.error;
                for(var i = 0; i < listRecordToSave.length; i++){
                    this.mappedRows[indexStartFrom + i]['UPLOAD_RESULT_LWC'] = this.mainErrorMsg;
                    this.mappedRows[indexStartFrom + i]['rowTextColor'] = 'slds-text-color_error';
                    this.numberOfFailedRecord++;
                }
                this.showMainErrorMsg = true;
                this.setErrorAndSuccessMessageClassStyle();
                this.populateTableRows();
                this.showSpinner = false;
                
                //MN-08122023-US-0014106--START
                this.sendServerSideErrorToV2('ExcelImporterV1:doSave()',this.mainErrorMsg);
                //--END
            }

        })
        .catch(error => {
            //this.mainErrorMsg = error.body.message; //MN-09122023-US-0014505
            this.mainErrorMsg = error; //MN-09122023-US-0014505: Fixed error due to undefined body.message
            this.showMainErrorMsg = true;
            this.populateTableRows();
            this.showSpinner = false;
            console.log("saveRecord error : ",error);
            
            //MN-08122023-US-0014106--START
            this.sendServerSideErrorToV2('ExcelImporterV1:doSave():catch',error);
            //--END
        });

    }

    //NK:15/01/2025:US-0016265 - after saving complete successfully
    processPostDML()
    {
        //MN-27012025-US-0016676: using this.selectedTemplateData.Server_side_Post_DML__c instead of this.selectedTemplateData.Server_side_Post_DML__c !== '', so that it can handle both empty string and undefined value
        if(this.selectedTemplateData && this.selectedTemplateData.Server_side_Post_DML__c) 
        {
            
            this.showHideSpinner(true);

            let postData = {"parentId":this.parentId};
            apexProcessPostDML({ "postData" : postData,templateName : this.templateName}).then(result => {
                if(result.status === 'ok')
                {
                    console.log("Post DML Processed successfully");
                }
                else
                {
                    console.error("Post DML failed: ",result.error);
                    this.showMainErrorMsg = true;
                    this.mainErrorMsg = result.error;
                    this.sendServerSideErrorToV2('ExcelImporterV1:processPostDML()',result.error);
                }
                this.showHideSpinner(false);
            }).catch(error => {
                console.error("Post DML Processed failed : ",error);
                this.showHideSpinner(false);
                this.sendServerSideErrorToV2('ExcelImporterV1:processPostDML()',error);
                
            });
        }
    }
  
    showHideSpinner(visible){
        this.showSpinner = visible;
    }

    // SB 26.10.2023 US-0013554
    handleSendEmailResult(insertedCount,listError){
        sendEmailResult({insertedCount:insertedCount,listError:listError})
        .then(result => {
            this.listError = [];
            console.log("Email sent successfully");
        })
        .catch(error => {
            this.listError = [];
            console.log("sendEmailResult error : ",error);
            
            //MN-08122023-US-0014106--START
            this.sendServerSideErrorToV2('ExcelImporterV1:handleSendEmailResult()',error);
            //--END
        });
    }

    onPrevPage() {
        if(this.currentPage > 1) this.currentPage--;
        
        //MN-05122023-US-0014106--START
        if (this.isExcelImporterV2 && this.isShowOnlyError) {
            this.populateErrorTableRows(true);
            return;
        }
        //--END

        this.populateTableRows();

    }

    onNextPage(){
        if(this.currentPage < this.totalPage) this.currentPage++;
        
        //MN-05122023-US-0014106--START
        if (this.isExcelImporterV2 && this.isShowOnlyError) {
            this.populateErrorTableRows(true);
            return;
        }
        //--END

        this.populateTableRows();
        
    }

    onChangePage(evt) {
        
        var pageNumber = evt.target.dataset["id"];
        this.currentPage = pageNumber;

        //MN-05122023-US-0014106--START
        if (this.isExcelImporterV2 && this.isShowOnlyError) {
            this.populateErrorTableRows(true);
            return;
        }
        //--END

        this.populateTableRows();
        
    }

    populateTableRows() {

        if(!this.hideListTable){
            this.tableRows = [];
            var countRecord = 0; //MN-07122023-US-0014106-Counting the number of records in the current page and not including the blank row
            var pageIndex = (this.currentPage - 1) * this.numberOfRecordPerPage;
            for(var i = pageIndex; i < (pageIndex + this.numberOfRecordPerPage); i++){
                if(this.mappedRows[i] != null) this.tableRows.push(this.mappedRows[i]); // SRONG/14.05.2024/US-0015291
                if (this.isExcelImporterV2 && this.mappedRows[i] != null) countRecord++; //MN-07122023-US-0014106-Counting the number of records in the current page and not including the blank row
            }
            
            //MN-07122023-US-0014106--START
            if (this.isExcelImporterV2) {
                var currentNoRecordPerPage = countRecord;

                // Fire event to parent
                const excelImporterEvent = new CustomEvent('displaynumberofrecords',{detail: {currentNoRecordPerPage : currentNoRecordPerPage}} );
                this.dispatchEvent(excelImporterEvent);
            }
            //--END
        }

    }

    get displayPagination() {
        var arrPage = [];
        for(var i =1; i<= this.totalPage; i++){
            var objP = {value : i, clsActive : (this.currentPage == i?"active":"")};
            arrPage.push(objP);
        }
        return arrPage;
    }

    downloadCSVTemplate(){ // 26.09.2022 / Sophal Noch / US-0011695 : action to download report csv

        this.showSpinner = true;
        var self = this;
        this.doGetCSVFile(function(){
            
            var link = document.createElement('a');
            link.href = 'data:text/csv;charset=utf-8,\ufeff' + encodeURIComponent(self.csvDownloadFile);
            link.target = '_blank';
            link.download = self.Labels.ExcelImporter_Label_1+'.csv';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);

        });
        
    }

    setErrorAndSuccessMessageClassStyle(){
        this.successMsgClassStyle = this.numberOfSuccessRecord > 0 ? 'slds-text-color_success' : '';
        this.errorMsgClassStyle = this.numberOfFailedRecord > 0 ? 'slds-text-color_error' : '';
    }

    removeUploadResultColumn(){
        if(this.tableColumns.length > 1 && this.tableColumns[1].fieldName == 'UPLOAD_RESULT_LWC'){
            
            this.tableColumns.splice(1,1);
            var newTableColumns = [];
            for(var i = 0; i < this.tableColumns.length;i++){
                newTableColumns.push(this.tableColumns[i]);
            }
            this.tableColumns = newTableColumns;
            
        }
    }

    doServerSideCheck(indexStartFrom, className, methodName){

         // 12.12.2022 / Sophal Noch / US-0012119 :
        var listRecordToSave = [];
        if(indexStartFrom == 0){ this.indexOfError = [];}
        for(var i = indexStartFrom; i < this.mappedRows.length; i++){
            listRecordToSave.push(JSON.parse(JSON.stringify(this.mappedRows[i])));
            // Delete the old key
            delete listRecordToSave[listRecordToSave.length -1][this.INDEX_COLNAME];
            if(listRecordToSave.length >= this.batchSize) break;
        }
        

        var mapArgs = {};
        mapArgs['listRecord'] = listRecordToSave;
        mapArgs['startIndex'] = indexStartFrom;
        mapArgs['parentId'] = this.parentId;
        mapArgs['hasHeader'] = this.hasHeader; //MN-19122023-US-0014106: Send hasHeader to server side
        mapArgs['isExcelImporterV2'] = this.isExcelImporterV2; //MN-19122023-US-0014106: Send hasHeader to server side
        //NK:24/09/2024:US-0015465
        mapArgs.colHeadersMeta = this.colHeadersMeta; 
        mapArgs.colHeadersExcel = this.colHeadersExcel;
        mapArgs.vadlidateHeader = this.selectedTemplateData.Validate_Header_Columns__c;
        mapArgs.templateLink = this.selectedTemplateData.Template_Link__c;
        
        serverSidePreDMLCheck({className : className, methodName : methodName, mapArgs: mapArgs})
        .then(result => {

            if(result.status == 'ok'){
                this.chunkIndex ++;
                
                //MN-18082023-US-0014008: Store all the existing listing id for each chunk and display it at the end of chunk
                if (result.mapExistListingId) {

                    for(var key in result.mapExistListingId){
                        if(result.mapExistListingId.hasOwnProperty(key)) {
                            this.setExistingIds.add(key);
                        }
                    }
                }
                if(result.mapIndexToErrMsg){
                    for(var key in result.mapIndexToErrMsg){
                        if(result.mapIndexToErrMsg.hasOwnProperty(key)) {
                            var errorIndex = parseInt(key);
                            this.mappedRows[errorIndex]['UPLOAD_RESULT_LWC'] = result.mapIndexToErrMsg[key];
                            this.mappedRows[errorIndex]['rowTextColor'] = 'slds-text-color_error';
                            this.numberOfFailedRecord++;
                            //SRONG/27.02.2024/US-0014840
                            if (this.isExcelImporterV2) {
                                this.mappedErrorRows.push(this.mappedRows[errorIndex]);
                                this.indexOfError.push(parseInt(key));
                            }
                            
                        }
                    }

                }
                //SRONG/27.02.2024/US-0014840
                if (this.isExcelImporterV2) {
                    for(var i = 0; i < result.listRecord.length; i++){
                        var currentIndexOfRecord = indexStartFrom + i;
                        var isError = false;
                        for(var index = 0; index < this.indexOfError.length; index++ ){
                            if(currentIndexOfRecord == this.indexOfError[index]){
                                isError = true;
                                break;
                            }
                        }
                        if(!isError){
                            this.listAllRecordToSave.push(result.listRecord[i]);
                        } 
                    }
                }else{
                    for(var i = 0; i < result.listRecord.length; i++){
                        this.listAllRecordToSave.push(result.listRecord[i]);
                    }
                }
                var batchEndIndex = indexStartFrom + listRecordToSave.length;
                if(batchEndIndex >= this.mappedRows.length){

                    //MN-15122023-US-0014505--START
                    if(this.showAmountRecordInfor) {
                        var totalNewRecord = this.listAllRecordToSave.length;

                        if (this.setExistingIds.size > 0) { //Check if there are any existing listing id
                            totalNewRecord = totalNewRecord - this.setExistingIds.size;
                        }
                        // console.log('>>>>remainRecordAmount:' + this.remainRecordAmount);
                        this.uploadingAmountRecord = totalNewRecord;
                        this.isAllowUpload = this.uploadingAmountRecord <= this.remainRecordAmount; 
                        
                        if (!this.isAllowUpload) {

                            if (this.isExceedMaximum) {
                                //Adding "Upload Failed" to the new record that is not allowed to upload due to the limit 
                                for(var i = 0; i < this.listAllRecordToSave.length; i++) {
                                    
                                    this.mappedRows[i]['UPLOAD_RESULT_LWC'] = 'Upload Failed';
                                    this.mappedRows[i]['rowTextColor'] = 'slds-text-color_error';
                                    
                                }
                                this.setErrorAndSuccessMessageClassStyle();
                                this.populateTableRows();
                            }
                            

                            this.listAllRecordToSave = [];
                            this.showSpinner = false;
                            return;
                        }
                    }
                    //MN-15122023-US-0014505--END

                    if(this.numberOfFailedRecord > 0){
                       // this.listAllRecordToSave = [];
                        this.setErrorAndSuccessMessageClassStyle();
                        this.populateTableRows();
                        this.showSpinner = false;
                        
                        //MN-04122023-US-0014106--START: For Excel Importer V2: Send some data to parent
                        if (this.isExcelImporterV2) {
                            const excelImporterEvent = new CustomEvent('uploadresult',{detail: {phase: 'server-side-validate', isSuccess: false, totalOfRecord:this.mappedRows.length, numberOfFailedRecord: this.numberOfFailedRecord,mappedErrorRows:this.mappedErrorRows}} );
                            this.dispatchEvent(excelImporterEvent);
                        }
                        //--END
                        
                    }
                    //MN-18082023-US-0014008: Need to popup the confirm on screen in order to continue upload 
                    else if (result.showConfirm && !this.hasConfirmed) {

                        let strListingIds = Array.from(this.setExistingIds);
                        let msg = result.showConfirm + strListingIds.join(', ');

                        const res = LightningConfirm.open({
                            message: msg,
                            variant: 'headerless',
                            label: '',
                            
                        }).then(res => {
                            
                            this.hasConfirmed = res;
                            
                            if (this.hasConfirmed === false) {
                            
                                this.listAllRecordToSave = [];
                                this.showSpinner = false;
                            } else {
                                this.chunkIndex = 0;
                                this.doSave(0);    
                            }

                        });
                        
                    }
                    //MN-05122023-US-0014106--START: For Version 2, Once both client and server side validation are passed, user can press "Next" button to insert data into database
                    else if (this.isExcelImporterV2) {
                        

                        if (this.mappedRows.length == 0) {
                            const excelImporterEvent = new CustomEvent('uploadresult',{detail: {phase: 'server-side-validate', isSuccess: false, totalOfRecord:this.mappedRows.length, numberOfFailedRecord: this.numberOfFailedRecord}} );
                            this.dispatchEvent(excelImporterEvent);
                        }else {
                            this.chunkIndex = 0;
                            const excelImporterEvent = new CustomEvent('uploadresult',{detail: {phase: 'server-side-validate', isSuccess: true, totalOfRecord:this.mappedRows.length, numberOfFailedRecord: this.numberOfFailedRecord}} );
                            this.dispatchEvent(excelImporterEvent);
                        }

                        
                        this.showSpinner = false;
                    }
                    //--END
                    else{

                        this.chunkIndex = 0;
                        this.doSave(0);
                    }
                    
                }else{
                    this.doServerSideCheck(batchEndIndex, className, methodName);
                }
                
            }else{
                this.listAllRecordToSave = [];
                this.mainErrorMsg = result.error;
                for(var i = 0; i < listRecordToSave.length; i++){
                    this.mappedRows[indexStartFrom + i]['UPLOAD_RESULT_LWC'] = this.mainErrorMsg;
                    this.mappedRows[indexStartFrom + i]['rowTextColor'] = 'slds-text-color_error';
                    this.numberOfFailedRecord++;
                }
                this.showMainErrorMsg = true;
                this.setErrorAndSuccessMessageClassStyle();
                this.populateTableRows();
                this.showSpinner = false;
                console.log("serverSidePreDMLCheck error : ",result);

                //MN-08122023-US-0014106--START
                this.sendServerSideErrorToV2('ExcelImporterV1:doServerSideCheck()',this.mainErrorMsg);
                //--END
            }
            
        })
        .catch(error => {
            this.listAllRecordToSave = [];
            this.mainErrorMsg = error.body.message;
            this.showMainErrorMsg = true;
            this.populateTableRows();
            this.showSpinner = false;
            console.log("serverSidePreDMLCheck error : ",error);
            //MN-08122023-US-0014106--START
            this.sendServerSideErrorToV2('ExcelImporterV1:doServerSideCheck():catch',error);
            //--END
        });
    }


    //FOR EXCEL IMPORTER VERSION 2
    //MN-27112023-US-0014106--START
    @api
    handleResestDataV2(e){

        this.showInput = true;
        this.showPreviewTable = false;
        this.mappedErrorRows = [];
        this.handleResetData(e);

    }

    @api
    handleOnUploadV2(e) {
        this.handleOnUpload(e);
    }

    @api
    handleSaveDataV2(e) {

        this.showPreviewTable = false;
        this.chunkIndex = 0;
        this.doSave(0);
    }

    @api
    handleShowOnlyErrorRows(mode) {
        this.isShowOnlyError = mode;
        this.currentPage = 1;
        this.populateErrorTableRows(mode);
        
    }

    populateErrorTableRows(mode) { //mode = true: show only error rows, mode = false: show all rows
        
        if (!mode) {
            this.totalPage = this.mappedRows.length > 0 ? Math.ceil(this.mappedRows.length / this.numberOfRecordPerPage) : this.mappedRows.length;
            this.populateTableRows();
            return;
        }

        if(!this.hideListTable){

            this.mappedErrorRows = [];
            
            for (var i=0; i<this.mappedRows.length; i++) {
                var row = this.mappedRows[i];
                if (row && row.hasOwnProperty('rowTextColor') && row.rowTextColor == 'slds-text-color_error') {
                    this.mappedErrorRows.push(this.mappedRows[i]);
                }
            }

            this.totalPage = this.mappedErrorRows.length > 0 ? Math.ceil(this.mappedErrorRows.length / this.numberOfRecordPerPage) : this.mappedErrorRows.length;
            
            this.tableRows = [];
            var countRecord = 0; 
            var pageIndex = (this.currentPage - 1) * this.numberOfRecordPerPage;
            for(var i = pageIndex; i < (pageIndex + this.numberOfRecordPerPage); i++){
                if (this.mappedErrorRows[i] != null){
                    this.tableRows.push(this.mappedErrorRows[i]);
                    countRecord++;
                }  //Counting the number of records in the current page and not including the blank row
            }

            
            var currentNoRecordPerPage = countRecord;

            // Fire event to parent
            const excelImporterEvent = new CustomEvent('displaynumberofrecords',{detail: {currentNoRecordPerPage : currentNoRecordPerPage}} );
            this.dispatchEvent(excelImporterEvent);
            

        }

    }

    sendServerSideErrorToV2(method, error) {
        const excelImporterEvent = new CustomEvent('serversideerror',{detail: {method: method, error: error}} );
        this.dispatchEvent(excelImporterEvent);
    }

    // 01.07.2025/ CSP:US-0033008
    onValidatePasteResult(event) {
        if (event?.isSuccess) {
            const dataImport = event?.mappedRows;
            const csvTemplate = event?.mappedColumns;
            if (!this.validateHeader({dataImport,csvTemplate})) {
                this.showValidateHeaderErrorMsg = true
                this.canUpload = false;
            } else {
                this.showValidateHeaderErrorMsg = false
                this.canUpload = true;
            }
        }
    }

    // 01.07.2025/ CSP:US-0033008
    validateHeader({ dataImport, csvTemplate }) {
        const allKeys = new Set();
        for (let i = 0; i < dataImport.length; i++) {
            const row = dataImport[i];
            for (let key in row) {
                if (key !== 'EXCEL_COL_INDEX_LWC' && row.hasOwnProperty(key)) {
                  allKeys.add(key);
                }
            }
        }

        const csvHeader = Array.from(allKeys);
        if (csvHeader.length != csvTemplate.length)  return false;
        for (let index = 0; index < csvTemplate.length; index++) {
            const expectedPrefix = csvTemplate[index].substring(0, 3);
            if (!csvHeader[index].startsWith(expectedPrefix)) {
                return false;
            }
        }
        return true;
    }
    //--END
    
}