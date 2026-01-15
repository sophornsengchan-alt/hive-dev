/*********************************************************************************************************************************
@ Author:         Vimean Heng 
@ Purpose:        US-0016475 - 12.1 - Seller Portal - Overview tab + Deal List Views
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 24.02.2025 / Vimean Heng / Created the component.
@               : 10.03.2025 / vadhanak voun / US-0016782 - 14.1 - Seller Portal Contract Page within DCA
@               : 31.03.2025 / Sovantheany Dim / US-0016979 - Business Testing feedback - Subsidy per sold item is required in DCA related list
*********************************************************************************************************************************/
import {LightningElement, api,wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import tabLabel_Overview from '@salesforce/label/c.SEP_Overview';
import contract_Agreement_Tab_Label from '@salesforce/label/c.contract_Agreement_Tab_Label';
import btn_downloadDealItems from '@salesforce/label/c.PM_Download_Deal_Items'; //TH:US-0016567:25/02/2025
import { NavigationMixin } from 'lightning/navigation';
import customTabCSS from '@salesforce/resourceUrl/customGlobalSearchTab';
import getDealContractAgreement from '@salesforce/apex/SEPDealContractAgreementController.getDealContractAgreement';
import getDealContractAgreementData from '@salesforce/apex/SEPDealContractAgreementController.getDealContractAgreementData';
import getDealsRelatedToDCA from '@salesforce/apex/SEPDealContractAgreementController.getDealsRelatedToDCA';
import { EXCELJS } from 'c/lwcExcelJS';
import sep_deals_list_view from '@salesforce/label/c.SEP_Deals_List_View';
import sep_deals_sub_title from '@salesforce/label/c.SEP_Deals_Sub_Title';
import sepBackButton from '@salesforce/label/c.SEP_BACK_BUTTON';
import customLabel from 'c/customLabels';

export default class LwcSubDealContractAgreementDetailPage extends NavigationMixin(LightningElement) {
    @api recId; 
    //@api fieldsNoLink = ["EBH_eBayItemID__c"]; //US-0016979:TH:CommentOut 
    labels = customLabel;
    attachmentId ;
    showDownlaodPDF = false;
    //isContractAgreement;
    //showViewAgreement;
    dcaTitle = '';
    selectedTab = '';
    dcaName = '';
    backURL = ''; 
    mySubDCAURL = 'my-subsidized-deal-contract-agreement';
    Labels = {
        tabLabel_Overview, 
        contract_Agreement_Tab_Label,
        btn_downloadDealItems,
        sep_deals_list_view,
        sep_deals_sub_title,
        sepBackButton,
        SEP_DownloadAgreement:customLabel.SEP_DownloadAgreement
    }; 
    showDownloadSpinner = false;//TH:US-0016567:25/02/2025
    excelJS;//TH:US-0016567:25/02/2025
    //showButtons = false;//TH:US-0016567
    connectedCallback()
    {
        this.init();
        this.loadAgreementData();
        this.excelJS = new EXCELJS(this);
    }
    init() {
        getDealContractAgreement({dcaId:this.recId})
        .then(result => {
            //this.isContractAgreement = result.isContractAgreement;
            //this.showViewAgreement = result.showViewAgreement;
            this.dcaTitle = result.dca.Title__c;
            this.dcaName = result.dca.Name;
            this.activeTab(this.selectedTab);
        })
        .catch(error => {
            console.log("..init error::",error);
        });
         
    }
    renderedCallback() {
        Promise.all([
            loadStyle( this, customTabCSS )
        ])
    }
    activeTab(tabValue){
        setTimeout(() => {
            this.template.querySelector('lightning-tabset').activeTabValue = tabValue;
        }, 100);
    }
    get title(){
        return this.Labels.sep_deals_list_view;
    }
    get sub_title(){
        var strSubTitle = "<span class='slds-text-title_bold'>" + this.dcaTitle +"</span>" + " ("+this.dcaName+")";
        return this.Labels.sep_deals_sub_title.replace('{1}',strSubTitle);
    }
    get allTabs(){
        return [
            {name:'All Deals',label:'All Deals', mdtname:"Subsidize_All_Deals"},
            {name:'Approved Deals',label:'Approved Deals', mdtname:"Subsidize_Approved_Deals"},
            {name:'In Review Deals',label:'In Review Deals', mdtname:"Subsidize_In_Review_Deals"},
            {name:'Rejected Deals',label:'Rejected Deals', mdtname:"Subsidize_Rejected_Deals"},
            {name:'Declined Deals',label:'Declined Deals', mdtname:"Subsidize_Declined_Deals"},
            {name:'Cancelled Deals',label:'Cancelled Deals', mdtname:"Subsidize_Cancelled_Deals"}
        ];
    }
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) {
            this.currentPageReference = currentPageReference;
            this.recId = currentPageReference.state?.id;
            this.selectedTab = currentPageReference.state?.tabset;
            this.backURL = currentPageReference.state?.retURL;
       }
    }
    /*
    //TH:US-0016567:25/02/2025
    handlerFocusTab(event) {
        let currentTab = event.target.value;
        if(currentTab === 'All_Deals'){
            this.showButtons = true;
        }else{
            this.showButtons = false
        }
    }
    //onactive={handlerFocusTab}
    */
    backToMySubDCA() {
        let sepUrl = this.backURL != null && this.backURL != '' ? this.backURL : this.mySubDCAURL;
        this.gotoSEPPage(sepUrl);
    } 
    gotoSEPPage(url){
        if(url.indexOf('/') === -1){
            url = '/' + url;
        }
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
              url: url 
            }
        });
    }
    //TH:US-0016567:25/02/2025
    handleDownloadDealItems(event) {
        let mdtName = event.currentTarget.dataset.id;
            this.showDownloadSpinner = true;
            getDealsRelatedToDCA({dcaId : this.recId, mdtName : mdtName})
            .then(result => {
                let jsonData = result.lstRecords;
                // Rename a key in each object in the jsonData array
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
                    const oo = renameKeys(key, obj);
                    return oo;
                });
                let fileName = mdtName+ "_Items_"+this.dcaName+".xlsx";
                this.excelJS.downloadGenerateExcel(jsonData,fileName,"Sheet1");
                this.showDownloadSpinner = false;
            })
            .catch(error => {
               console.log('error = ',error);
               this.showDownloadSpinner = false;
            });
        }
     
    //NK:10/03/2025:US-0016782
    loadAgreementData()
    {
        // console.log('loadAgreementData',this.recId);
        getDealContractAgreementData({dcaId:this.recId})
        .then(result => {
            // console.log('result::',result);
            this.attachmentId = result.attachmentId;
            this.showDownlaodPDF = result.showDownlaodPDF;
        })
        .catch(error => {
            console.error("..getDealContractAgreementData error::",error);
        });
    }
        
    handleDownloadAgreement()
    {
        window.location.href = "https://"+window.location.hostname+"/sfc/servlet.shepherd/version/download/"+this.attachmentId+"?asPdf=false&operationContext=CHATTER";
    }
}