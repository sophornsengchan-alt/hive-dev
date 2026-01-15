/**
 * change logs: 
 *      02.04.2025/vadhanak voun/ US-0016977 - Bulk Upload - Business and internal Testing feedback
 */
import { LightningElement, track, api } from 'lwc';
import { loadScript } from "lightning/platformResourceLoader";
import papaParse from '@salesforce/resourceUrl/PapaParse';
import getExcelImporterTemplate from '@salesforce/apex/ExcelImporterControllerSEP.getExcelImporterTemplate';

import ExcelImporter_PageSize from '@salesforce/label/c.ExcelImporter_PageSize';

export default class LwcExcelImporterSEP extends LightningElement {
    
    @api showSpinner = false;
    @api isDoubleHeightInput = false;

    @api templateName;
    @api parentId;
    @api inputPlaceholder = '';

    @api isDisabled = false; //MN-24072023-US-0013835

    @track isCmpReady = false;
    
    @track excelImporterTemplate = {};
    @track templateSubtitle = '';
    @track descr = '';
    
    @track hasHeader = true;

    @track mappedColumns = [];
    @track mappedRows = [];

    @track inputClass = 'slds-input export-importer-sep-paste_input';
    
    connectedCallback() {

        // 07.06.2023 / Sophal Noch / US-0013657 :

        this.inputClass = this.isDoubleHeightInput ? (this.inputClass + ' doubleHeightInput') : this.inputClass;

        this.showSpinner = true;
        this.numberOfRecordPerPage = (ExcelImporter_PageSize && parseInt(ExcelImporter_PageSize) > 0) ? parseInt(ExcelImporter_PageSize) : this.numberOfRecordPerPage;
        loadScript(this, papaParse).then(() => {});
        getExcelImporterTemplate({templateName:this.templateName, parentId: this.parentId})
        .then(result => {
            
            if(!result.hasNoPermission){
                this.isCmpReady = true;
                this.excelImporterTemplate = result.mapExcelImportTemp;
                this.selectedTemplateData = this.excelImporterTemplate[this.templateName];
                if(this.selectedTemplateData){
                    this.templateSubtitle = this.selectedTemplateData.Subtitle__c;
                    this.inputPlaceholder = (this.selectedTemplateData.Input_Placeholder__c && this.selectedTemplateData.Input_Placeholder__c != '') ?  this.selectedTemplateData.Input_Placeholder__c : this.inputPlaceholder;
                }
            }

            this.showSpinner = false;
            
        })
        .catch(error => {
            this.showSpinner = false;
            console.log("getExcelImporterTemplate error",error);
        });

    }

    handleKeyPress(e){
        if (e.ctrlKey !== true && e.key != 'v') {
            e.preventDefault();
            e.stopPropagation();
          }
    }

    handlePasteData(e){
        e.preventDefault();
        let cb;
        this.clipText = '';
        if (e.clipboardData && e.clipboardData.getData) {
          cb = e.clipboardData;
          this.clipText = cb.getData('text/plain');
        } else {
          cb = e.originalEvent.clipboardData;
          this.clipText = cb.getData('text/plain');
        }

        //NK:02.04.2025:US-0016977
        this.sendStartToParent();   
        setTimeout(() => {
            this.doPasteData();
        }, 100);
        
        // return this.doPasteData();
    }

    doPasteData(){        

        this.mappedColumns = [];
        this.mappedRows = [];

        let pastedResult = {};

        let self = this;

        if(this.clipText != null && this.clipText != ''){

            
            this.showSpinner = true;
            let  self = this;
            Papa.parse(this.clipText,{
                delimiter: "",
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
                    self.handleOnPasteStep(results);
                },
                complete: function(results, file) {

                    self.handleOnPasteComplete(pastedResult);
                    self.sendResultToParent(pastedResult);
                    
                },
                error: function(error , file) {
                    console.log("parsing error: ", error);
                    self.handleOnPasteError(pastedResult, error);
                    self.sendResultToParent(pastedResult);


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

    handleOnPasteStep(results){

        if(this.selectedTemplateData){

            if(Object.keys(results.data[0]).length <= 0) return;
            if(Object.keys(results.data[0]).length == 1) {
                for (let key in results.data[0]) {
                    if(results.data[0].hasOwnProperty(key)) {
                        if(!results.data[0][key] || results.data[0][key] == "") return;
                    }
                }

            }

            this.mappedRows.push(results.data[0]);

            if(this.mappedColumns.length <= 0){this.mappedColumns = results.meta.fields;}
 

        }

    }

    handleOnPasteComplete(pastedResult){
        pastedResult['isSuccess'] = true;
        pastedResult['mappedColumns'] = this.mappedColumns;
        pastedResult['mappedRows'] = this.mappedRows;
    }

    handleOnPasteError(pastedResult, error){
        pastedResult['isSuccess'] = false;
        pastedResult['error'] = error;
    }
    sendResultToParent(pastedResult){
        const excelImporterSEPEvent = new CustomEvent('excelimportersepresult',{detail:pastedResult} );
        this.dispatchEvent(excelImporterSEPEvent);
    }

    sendStartToParent()
    {
        const excelImporterSEPEvent = new CustomEvent('excelimportersestart',{pastStart:true} );
        this.dispatchEvent(excelImporterSEPEvent);
    }
}