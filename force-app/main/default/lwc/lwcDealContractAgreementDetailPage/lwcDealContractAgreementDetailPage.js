/*
    change log
        10/10/2022/vadhanak voun/US-0012764 - [Bug] Download of items - PM Deals
        07/06/2023 / Sambath Seng / US-0013316 - Cancelled Items - Seller Portal
        18.02.2025 / SRONG TIN / US-0015819 LWS - Upload Components (deal/coupon item)
*/

import { LightningElement, api, track,wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { EXCELJS } from 'c/lwcExcelJS';//SRONG TIN - 05/12/2023 : US-0014342
import { NavigationMixin } from 'lightning/navigation';
import customTabCSS from '@salesforce/resourceUrl/customGlobalSearchTab';
import tabLabel_Overview from '@salesforce/label/c.CouponSellerDetail_TabLabel_Overview';
import label_uploadDeal from '@salesforce/label/c.Upload_Deal';
import getDealContractAgreement from '@salesforce/apex/SEPDealContractAgreementController.getDealContractAgreement';
import tabLabel_DealItems from '@salesforce/label/c.DCA_DealItem_Tab';//LA:07-09-2022-US-0012283
import excel_FileName from '@salesforce/label/c.DCA_Deal_Item_Excel_Header';//MN-27102022-US-0012841
import btn_downloadDealItems from '@salesforce/label/c.PM_Download_Deal_Items';//LA:07-09-2022-US-0012283
import getPMDealItemDownloadExcel from '@salesforce/apex/PMDealItemDownloadController.getPMDealItemDownloadExcel';//LA:07-09-2022-US-0012283
//SRONG:15-09-2022-US-0012298 - Ability to sign Agreement in portal 
import contract_Agreement_Tab_Label from '@salesforce/label/c.contract_Agreement_Tab_Label';
import contract_Agreement_Tab_View_Agreement from '@salesforce/label/c.Contract_Agreement_Tab_View_Agreement';
import tabLabel_UploadItems from '@salesforce/label/c.CouponSellerDetail_TabLabel_UploadItems';
                                     
export default class LwcDealContractAgreementDetailPage extends NavigationMixin(LightningElement) {
    @api recId; 
    // @api additionalFilter;//TH:28/09/2022 comment out : US-0012660 : no status check
    @track totalRecord = 0;
    @api fieldsNoLink = ["EBH_eBayItemID__c"]; 

    //NK:10/1//2022/US-0012764
    @api showDownloadSpinner = false;
    @api additionalStatusFilter;//SB 09.06.2023 US-0013316

    Labels = {
        tabLabel_Overview, 
        label_uploadDeal,
        tabLabel_DealItems,
        btn_downloadDealItems,
        //SRONG:15-09-2022-US-0012298
        contract_Agreement_Tab_Label,
        contract_Agreement_Tab_View_Agreement,
        excel_FileName, //MN-27102022-US-0012841
        tabLabel_UploadItems
    }; 
    hasUploadItemsAccess;
    hasDealItemsAccess;//LA:07-09-2022-US-0012283
    //SRONG:15-09-2022-US-0012298
    isContractAgreement;
    showViewAgreement;

    pmId; //MN-27102022-US-0012841

    excelJS;

    renderedCallback() {
        Promise.all([
            loadStyle( this, customTabCSS )
        ])
    }

    connectedCallback()
    {
        this.init();
        // SRONG TIN - 05/12/2023 : US-0014342
        this.excelJS = new EXCELJS(this);
    }

    /*handlerFocusTab(event) {
        
        let child_lwc = this.template.querySelector('c-lwc-deal-bulk-upload-d-c-a');
        child_lwc.hideSuccessMessage();
    }*/
    
    handleReloadListView () {
        let child_lwc = this.template.querySelector('c-lwc-list-view');
        child_lwc.reloadPage();
    }

    handleViewAgreementButton(){
        setTimeout(() => {
            this.activeTab(this.Labels.contract_Agreement_Tab_Label);
        }, 100);
    }
    activeTab(tabValue){
        this.template.querySelector('lightning-tabset').activeTabValue = tabValue;
    }

    //SRONG TIN - 18.02.2025 - US-0015819 LWS - Upload Components (deal/coupon item)
    handleOverviewTab(){
        setTimeout(() => {
            this.activeTab(this.Labels.tabLabel_Overview);
        }, 100);
    }
    
    init() {
        getDealContractAgreement({dcaId:this.recId})
        .then(result => {

            this.hasUploadItemsAccess = result.hasUploadItemsAccess;
            this.hasDealItemsAccess = result.hasDealItemsAccess;
            // this.additionalFilter = " AND Deal_Contract_Agreement__c  =\'" + this.recId +"\'";//LA:07-09-2022-US-0012283////TH:28/09/2022 comment out : US-0012660 : no status check
            //SRONG:15-09-2022-US-0012298
            this.isContractAgreement = result.isContractAgreement;
            this.showViewAgreement = result.showViewAgreement;

            this.pmId = result.pmID; //MN-27102022-US-0012841
            this.additionalStatusFilter = " AND EBH_Status__c = 'New'";//SB 09.06.2023 US-0013316
        })
        .catch(error => {
            console.log("..init error::",error);
        });
         
    }
    //LA:07-09-2022-US-0012283
    updateTotalRecord(event) {
        this.totalRecord = event.detail["totalRecord"];
    }
    //LA:07-09-2022-US-0012283
    get showButtons() {
        return this.totalRecord > 0 ;
    }
    //LA:07-09-2022-US-0012283
    handleDownloadDealItems() {
        this.showDownloadSpinner = true;    //NK:10/1//2022/US-0012764
        getPMDealItemDownloadExcel({dcaId : this.recId})
        .then(result => {
            //SRONG TIN - 05/12/2023 : US-0014342
            let jsonData = result;
            // Rename a key in each object in the jsonData array
            jsonData = jsonData.map(obj => {
                // Create a new object with the old key replaced by the new key
                let newObj = {
                    "eBay Item ID": obj["eBayItemID"],
                    "Item Title": obj["itemTitle"],
                    "Seller Price": obj["sellerPrice"],
                    "RRP Price": obj["rRPPrice"],
                    "Deal Price": obj["dealPrice"],
                    "Quantity": obj["quantity"],
                    "Cancellation Reason": obj["cancellationReason"]
                };
                return newObj;
            });
            //console.log('result = ',jsonData);
            let fileName =this.Labels.excel_FileName + "_" + this.pmId + ".xlsx";
            this.excelJS.downloadGenerateExcel(jsonData,fileName,this.Labels.tabLabel_DealItems);
            this.showDownloadSpinner = false;
        })
        .catch(error => {
           console.log('error = ',error);
           this.showDownloadSpinner = false;
        });
    }

    // SB 3.11.2022 US-0012877 - Simplify Item Upload Process for PM Deals
    handleViewItem(){
        setTimeout(() => {
            this.activeTab(this.Labels.tabLabel_DealItems);
        }, 100);
    }

}