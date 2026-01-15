/*********************************************************************************************************************************
@ Component:    LwcExportDeal
@ Version:      1.0
@ Author:       sovantheany Dim (sovantheany.dim@gaea-sys.com)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.01.2025 / sovantheany Dim / US-0016358 - (3) Data Import and Export from Deal Contract Agreement
*********************************************************************************************************************************/
import { LightningElement,wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { EXCELJS } from 'c/lwcExcelJS';
import customLabels from 'c/customLabels';
import { NavigationMixin } from 'lightning/navigation';
import bulkExport from '@salesforce/apex/ExcelImporterController.bulkExport';
// import apexInit from '@salesforce/apex/BulkExportDealController.apexInit';
import { getRecord } from 'lightning/uiRecordApi';
import hasPermission from '@salesforce/customPermission/US_Manage_Deals';

export default class LwcExportDeal extends NavigationMixin(LightningElement) {
    FIELDS = ['Deal_Contract_Agreement__c.Name'];
    parentId;
    excelJS;
    showConfirmDialog = false;
    showConfirmBtn = false;
    msgPopUp;
    labels = customLabels;
    templateMDT;
    //isUserHasPermission = false;
    showSpinner = true;

    connectedCallback(){
        this.excelJS = new EXCELJS(this);
    }

    get isUserHasPermission() {
        return hasPermission;
    }


    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        this.showSpinner = true;
       if (currentPageReference) {
        this.currentPageReference = currentPageReference;
        this.parentId = currentPageReference.state?.c__parentId;
        this.templateMDT = currentPageReference.state?.c__template;
        if(this.parentId == undefined){
            this.parentId = currentPageReference.attributes?.attributes?.c__parentId;
        }
        if(this.templateName == undefined){
            this.templateMDT = currentPageReference.attributes?.attributes?.c__template
        }
        this.init();
       }
    }

    @wire(getRecord, { recordId: '$parentId', fields: '$FIELDS'} )
    wiredRecord({ error, data }) 
    {
        if (data) {
            this.DCAName =  data.fields["Name"].value;
        }
       
    }

    init() {
        if(this.isUserHasPermission){
            this.showConfirmBtn = true;
            this.msgPopUp = this.labels.Export_Deal_msg;
            this.showConfirmDialog = true;
        }else{
            this.showConfirmBtn = false;
            this.msgPopUp = this.labels.Export_Deal_ErrorNoPermission_msg;
            this.showConfirmDialog = true;
        }
    }

    onConfirmHandler(e){
        this.showConfirmDialog= false;
        if(e.detail.status === 'confirm'){
            this.handleExportDeal();
        }
    }
    onCancelHandler(e){
        this.showConfirmDialog= false;
        this.showSpinner = false;
        if(e.detail.status === 'cancel'){
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                  //url: '/lightning/r/Deal_Contract_Agreement__c/'+this.parentId+'/related/Deals__r/view'
                  url: '/lightning/r/Deal_Contract_Agreement__c/'+this.parentId+'/view'
                }
            });
        }
    }

    convertMillisecondsToTime(milliseconds) {
        // Calculate total seconds
        let totalSeconds = Math.floor(milliseconds / 1000);
    
        // Calculate hours
        let hours = Math.floor(totalSeconds / 3600);
        totalSeconds %= 3600;
    
        // Calculate minutes
        let minutes = Math.floor(totalSeconds / 60);
    
        // Format hours and minutes to ensure two digits
        let formattedHours = String(hours).padStart(2, '0');
        let formattedMinutes = String(minutes).padStart(2, '0');
    
        // Return the formatted time
        return `${formattedHours}:${formattedMinutes}`;
    }

    fixtimeFormat(val){
        return this.convertMillisecondsToTime(parseInt(val));
    }

    handleExportDeal() {
        bulkExport({templateName :this.templateMDT, parentId : this.parentId})
        .then(result => {
            if(result.status === 'ok'){
                let fileName =result.exportName + "_" + this.DCAName + ".xlsx";
                let jsonData = result.lstSobjectNew;
                const renameKeys = (keysMap, obj) =>
                    Object.keys(obj).reduce(
                      (acc, key) => ({
                        ...acc,
                        ...{ [keysMap[key] || key]: obj[key] }
                      }),
                      {}
                    );
                const key = result.mapFieldColHeader;
                jsonData = jsonData.map(obj => {
                    obj.EBH_DealStartTime__c = this.fixtimeFormat(obj.EBH_DealStartTime__c);
                    obj.EBH_DealEndTime__c = this.fixtimeFormat(obj.EBH_DealEndTime__c);
                    const oo = renameKeys(key, obj);
                    return oo;
                });
                this.excelJS.downloadGenerateExcel(jsonData,fileName,'Sheet 1');
                this.showSpinner = false;

                this[NavigationMixin.Navigate]({
                    type: "standard__webPage",
                    attributes: {
                      //url: '/lightning/r/Deal_Contract_Agreement__c/'+this.parentId+'/related/Deals__r/view'
                      url: '/lightning/r/Deal_Contract_Agreement__c/'+this.parentId+'/view'
                    }
                });
            }else{
                console.log('status = ko');
                console.log('error = '+result.error);
                this.showSpinner = false;
            }
        })
        .catch(error => {
           console.log('error = ',error);
           this.showSpinner = false;
        });
    }
}