/*********************************************************************************************************************************
@ Version:        1.0
@ Author:         Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:        Controller class for “Deal Window Feature in SEP”
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11.05.2023 / Mony Nou / Created lwc.
*********************************************************************************************************************************/
import { LightningElement, api, track,wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import getDWDailyDealDownloadExcel from '@salesforce/apex/SEPDealWindowController.getDWDailyDealRetailWeekExcel';

import customTabCSS from '@salesforce/resourceUrl/customGlobalSearchTab';
import btn_downloadDailyDeal from '@salesforce/label/c.DW_Download_Deal';
import noRecordMessage from '@salesforce/label/c.DW_Download_NoDealMessage';
import getPortalDomain from '@salesforce/apex/SEP_Helper.getPortalDomain'; //LA-25-07-US-0013830
export default class LwcDealWindowDealList extends NavigationMixin(LightningElement) {

    @api dwId;
    @api showDownloadSpinner = false;
    @api fieldsNoLink = ["EBH_BusinessName__c"]; 

    @track totalRecord = 0;
    @track dwStartRetailWeek;
    @track isITDomain = false; //LA-25-07-US-0013830

    btnDownloadLabel = '';

    Labels = {
        btn_downloadDailyDeal, noRecordMessage
    };

    renderedCallback() {
        Promise.all([
            loadStyle( this, customTabCSS )
        ])
    }
    //LA-25-07-US-0013830
    @wire(getPortalDomain)
    getPortalDomain(result) {     
        if(result.data) {   
            this.isITDomain = result.data.isIT;
        } else if (result.error) {
            console.log('ERROR :: ', result.error);
        }
    };

    @wire(getRecord, { recordId: '$dwId', fields: ['EBH_DealRetailCampaign__c.Start_Retail_Week__c'] })
    wiredRecord({error, data}){
        if(data){
            this.dwStartRetailWeek = data.fields.Start_Retail_Week__c.value;
            this.btnDownloadLabel = this.Labels.btn_downloadDailyDeal;
            if(this.dwStartRetailWeek != null){
                this.btnDownloadLabel = this.btnDownloadLabel + ' ' + this.dwStartRetailWeek;
            }
        }
    }

    get showButtons() {
        return this.totalRecord > 0 ;
    }
    get isITListView(){ //LA-25-07-2023-US-0013830
        return this.isITDomain;    
    }

    updateTotalRecord(event) {
        this.totalRecord = event.detail["totalRecord"];
    }

    handleDownloadDeals() {
        this.showDownloadSpinner = true;    //NK:10/1//2022/US-0012764
        getDWDailyDealDownloadExcel({dwId : this.dwId})
        .then(result => {

            let downloadLink = document.createElement("a");
            downloadLink.href = "data:application/vnd.ms-excel;base64,"+result;
            
            downloadLink.download = this.btnDownloadLabel + ".xls";

            downloadLink.click();
            this.showDownloadSpinner = false;
        })
        .catch(error => {
           console.log('error = ',error);
           this.showDownloadSpinner = false;
        });
    }
}