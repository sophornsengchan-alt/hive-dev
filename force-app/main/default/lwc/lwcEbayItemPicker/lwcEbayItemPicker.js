import { LightningElement, wire, api, track } from 'lwc';
import apexSearch from '@salesforce/apex/SEP_ItemSearchController.apexSearch';
import apexGetItemDetail from '@salesforce/apex/SEP_ItemSearchController.apexGetItemDetail'; //MN-01122021-US-0010735
import getCategories from '@salesforce/apex/SEP_ItemSearchController.getCategories';
//import getAccountName from "@salesforce/apex/AccountManagementController.getAccountName"; //MN-17102023-US-0012769: AC3: Comment out unused codes
import fetchSEPGlobalVarWithPrefix from "@salesforce/apex/SEP_ItemSearchController.fetchSEPGlobalVarWithPrefix"; //MN-23112021-US-0010805

import {getRecord} from 'lightning/uiRecordApi'; //MN-29042022-US-0010950
import NAME_FIELD from "@salesforce/schema/Account.Name"; //MN-29042022-US-0010950
import { getObjectInfo } from 'lightning/uiObjectInfoApi'; 
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import Deal_Object from '@salesforce/schema/EBH_Deal__c';
import LANG from '@salesforce/i18n/lang';
import DIR from '@salesforce/i18n/dir';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

import Create_Deal from '@salesforce/label/c.Create_Deal'
import Search from '@salesforce/label/c.Search'
import Search_Result from '@salesforce/label/c.Search_Result'
import Website from '@salesforce/label/c.Website'
import Category from '@salesforce/label/c.Category'
import Brand from '@salesforce/label/c.Brand'
import Additional_Search
from '@salesforce/label/c.Additional_Search'
import Seller_Name from '@salesforce/label/c.Seller_Name'
import Next from '@salesforce/label/c.Next'
import Previous from '@salesforce/label/c.Previous'
import Leave from '@salesforce/label/c.Leave'
import Cancel from '@salesforce/label/c.Cancel'
import Clear from '@salesforce/label/c.Clear'
import Total_Number_of_Items from '@salesforce/label/c.Total_Number_of_Items'
import Page from '@salesforce/label/c.Page'
import of from '@salesforce/label/c.of'
import hoverMessageOnSingleDealBtn from '@salesforce/label/c.hoverMessageOnSingleDealBtn'//TH:US-0012782:11/10/2022

import { loadStyle } from 'lightning/platformResourceLoader';
// import SAMPLE_CSS from '@salesforce/resourceUrl/searchItemStyle'; /* SB 21-2-2022 US-0011303 - Cosmetic Defects 4 */

import search_result_ebayitem from '@salesforce/label/c.search_result_ebayitem';
import ebay_item_id from '@salesforce/label/c.ebay_item_id';
import ebay_item_name from '@salesforce/label/c.ebay_item_name';
import ebay_item_category from '@salesforce/label/c.ebay_item_category';
import ebay_item_current_price from '@salesforce/label/c.ebay_item_current_price';
import BrandPlaceHolder from '@salesforce/label/c.BrandPlaceHolder';
import NoBrandToolTip from '@salesforce/label/c.NoBrandToolTip';
import LWC_Default_Picklist_Placeholder from '@salesforce/label/c.LWC_Default_Picklist_Placeholder'; //MN-06012022-US-0010947 
import NoBrandPlaceHolder from '@salesforce/label/c.NoBrandPlaceHolder'; //MN-24022022-US-0011304
import getLinkedAccSpDeal from '@salesforce/apex/CustomDealController.getLinkedAccSpDeal';  //Sophal 02-04-2022 US-0011156 - Restrict ability for Sellers to be able to create Deals - Linked Account

const fields = [NAME_FIELD]; //MN-29042022-US-0010950

//export default class LwcEbayItemPicker extends LightningElement {//LA-02-12-2021-US-0010846 
export default class LwcEbayItemPicker extends NavigationMixin(LightningElement) {//LA-02-12-2021-US-0010846 
    @track isAccountSelectable = false;
    @track isAccountNoAccess = false;
    @track isEnableGotoDealBtn = false;
    @track step = 0;
    mapLinkedAcc = {isHavingNoFullAccess : true};
    @track DealReadOnlyErrorMessage = '';
    fullAccess = 'Full Access';

    renderedCallback() {
        // console.log('renderd ',this.hasRendered)

        // console.log(this.template.querySelector('article'))

        var article = this.template.querySelector('article'); // <div>First</div>

        // console.log('firstClass: ',article);
        // console.log('firstClass: ',JSON.stringify(article));
    }

    connectedCallback(){

        //Sophal 02-04-2022 US-0011156 - Start Here
        this.step = 0;
        getLinkedAccSpDeal() 
        .then(result => {
            // console.log('nsp: result == ',result);
            if(result.status == 'ok'){

                /* MN-05062024-US-0015298
                if(result.profileName == 'DE - Seller Portal') this.DealReadOnlyErrorMessage = 'DEdealLinkedAccountReadOnlyErrorMessage'; // Sophal 02-04-2022 US-0011156 - custom meta data record of custom meta data "Component help text setting"
                if(result.profileName != 'DE - Seller Portal') this.DealReadOnlyErrorMessage = 'NAdealLinkedAccountReadOnlyErrorMessage'; // Sophal 02-04-2022 US-0011156 - custom meta data record of custom meta data "Component help text setting"
                */

                //START--MN-05062024-US-0015298: Check SP Main Domain instead of Profile Name
                var isEU = result["isEU"];
                if(isEU) this.DealReadOnlyErrorMessage = 'DEdealLinkedAccountReadOnlyErrorMessage'; // Sophal 02-04-2022 US-0011156 - custom meta data record of custom meta data "Component help text setting"
                if(!isEU) this.DealReadOnlyErrorMessage = 'NAdealLinkedAccountReadOnlyErrorMessage'; // Sophal 02-04-2022 US-0011156 - custom meta data record of custom meta data "Component help text setting"
                //END
                if(result.isHavingNoFullAccess){
                    this.step = 1;
                }else{
                    this.mapLinkedAcc['isHavingNoFullAccess'] = result.isHavingNoFullAccess;
                    this.mapLinkedAcc['mapAcc'] = result.mapAcc;
                    this.mapLinkedAcc['mapAccIdToFullAccess'] = {};
                    for (var key in this.mapLinkedAcc.mapAcc) {
                        if (this.mapLinkedAcc.mapAcc.hasOwnProperty(key) && this.mapLinkedAcc.mapAcc[key].SP_Deals__c == this.fullAccess){
                            this.mapLinkedAcc['mapAccIdToFullAccess'][key.substring(0, key.length-3)] = true;
                        }
                    }
                    this.isAccountSelectable = true;
                    
                }

            }else if(result.status == 'ko'){
                console.log("error result.error == ", result.error);
            }
            
        }).catch(error => { 
            console.log("error getLinkedAccSpDeal == ", error);
        });
        //Sophal 02-04-2022 US-0011156 - Stop Here

        // console.log('connectedCallback')
        // console.log('connected: ',this.isConnected)
        this.siteId = this.defaultSite;
        this.getCategoriesData(this.defaultSite);
        // SB 24-2-2022
        // var url = new URL(location.href);
        // if(url.searchParams.get('drc')){
        //     this.ebayListContainer = false;
        //     this.modalContainer = true;
        // }


    }

    label = {
        search_result_ebayitem,
        ebay_item_id,
        ebay_item_name,
        ebay_item_category,
        ebay_item_current_price,
        BrandPlaceHolder, //MN-06012022-US-0010947 
        LWC_Default_Picklist_Placeholder, 
        NoBrandToolTip,
        NoBrandPlaceHolder  //MN-24022022-US-0011304
    };
    lang = LANG;
    dir = DIR;
    @track siteId;
    @api CreateDeal= 'Create Deal';
    @api inputLabel;
    @api labelCancelBtn; 
    @api placeHolderBrand;
    @api labelSubmitBtn;
    @api successMessage;
    @track catId;
    @track catLabel;
    @api inputLabelSite;
    @api pageSize;// = 10;
    @api searchOffset = 0;
    @api searchLimit;
    @api title;
    @api recordId;
    @track defaultSite = '77';
    siteOptions = [];
    categoryOptions = [];
    picklistFieldsWiredData;
    accountName;
    @api titleMetadataName;//SB 22-2-2022 US-0011212 - Feedback - QA/BA/UAT/GCX

    @api sellerId = ''; //MN-29042022-US-0010950
    @track sellerName='';
    @track records;
    @track items = []; 
    @track error;
    @track mRecords = {};
    @track currentPage = 1;
    @track totalPage = 0;
    @track brand;
    @track searchKey; 
    @track totalCount = 0;     
    @track page = 1; 
    @track startingRecord = 1; 
    @track isLoading = false;
    @track objMessageInfos = [];
    @track modalContainer = false;
    @track ebayListContainer = true;
    @track rowData = {};

    @track brandList; //aspectDistributions     
    @track distCatList; // categoryDistributions
    @track selectedDistCat;  //sub cat being selected

    get hasNoBrand() {
        return !(this.brandList != undefined && this.brandList.length >0);
    }

    @track labels = {
        Create_Deal,
        Search,
        Search_Result,
        Website,
        Category,
        Brand,
        Additional_Search,
        Seller_Name,
        Next,
        Previous,
        Leave,
        Cancel,
        Clear,
        Total_Number_of_Items,
        Page,
        of,
        hoverMessageOnSingleDealBtn
    }

    columns = [
        {label: ebay_item_id, fieldName: 'itemWebUrl', type: 'url',typeAttributes: { tooltip: { fieldName: 'itemId' } ,target:"_blank", label:{ fieldName: 'itemId'}} },
        {label: ebay_item_name, fieldName: 'itemWebUrl', type: 'url', typeAttributes: { tooltip: { fieldName: 'title' },target:"_blank", label:{ fieldName: 'title'}} },
        {label: ebay_item_category, fieldName: 'categoryName', type: 'text', },
        {label: ebay_item_current_price, fieldName: 'currentPrice', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }}},
        {
            label: '',
            type: 'button',
            initialWidth: 180,
            cellAttributes: { alignment: 'center' },
            typeAttributes: {
                title: this.labels.Create_Deal,
                label: this.labels.Create_Deal,
                variant: 'brand',
                alternativeText: this.labels.Create_Deal
            }
        }
   ];

    //  @wire(getAllPickListValue, {objectApiName : 'EBH_Deal__c', field_name: ['EBH_Category__c']})
    //  getAllPickListValue(result) {
    //      this.picklistFieldsWiredData = result;
    //      console.log('res for field>>>',result); 
    //      if(result.data) {            
    //          console.log('res >>> in metadaat'+JSON.stringify(result.data)); 
    //          this.picklistFieldValues =result.data.EBH_Category__c;
    //          console.log('res >>> in metadaat',this.picklistFieldValues); 
    //          this.error = undefined; 
    //             let categoryData = [];
    //                this.picklistFieldValues.forEach(element => {
    //                 categoryData.push({
    //                     label: element.label,
    //                     value: element.value
    //                  });
    //               });
    //               this.categoryOptions = categoryData;
             
    //      } else if (result.error) {
    //          console.log('error : >>> ', result.error);
    //      }
       
    //  };

// to get the default record type id, if you dont' have any recordtypes then it will get master
   @wire(getObjectInfo, {
    objectApiName: Deal_Object
 })
 dealsMetadata;

//MN-23112021-US-0010805 - Deal Site will be get from SEP Global Variable Metadata with prefix "DealSite" in field DeveloperName
@wire(fetchSEPGlobalVarWithPrefix, {
    prefix: 'DealSite'
})
dealSiteRecs ( {error, data} ) {
    
    if ( data ) {

        let dealSiteData = [];

        data.forEach(element => {
            
            dealSiteData.push({
                label: element.Label, 
                value: element.Value__c
            });

        });

        this.siteOptions = dealSiteData;
    }else if (error) {
        // console.log('*** MN - metadata - ERROR :: ', error.body.message);
    }
}


 /* MN-23112021-US-0010805 - No longer get Deal Site based on Profile's Deal Default Record Type
 @wire(getPicklistValuesByRecordType, {
        objectApiName: Deal_Object,
        recordTypeId: '$dealsMetadata.data.defaultRecordTypeId'
    })
    picklistValues({
        error,
        data
    }) {
        if (data) {
            console.log('data: ', data);

            let statusData = [];
            //fetch status option data
            if (data.picklistFieldValues.EBH_DealSiteId__c) {
                data.picklistFieldValues.EBH_DealSiteId__c.values.forEach(element => {
                    
                    //MN-22112021-US-0010805 - Change label "ES" => "SP" for Spain
                    var elemLabel = element.label;
                    if (elemLabel == "ES") elemLabel = "SP";

                    statusData.push({
                        //label: element.label
                        label: elemLabel, //MN-22112021-US-0010805
                        value: element.value
                    });

                });

                this.siteOptions = statusData;
            }
        } else if (error) {
        console.log(error);
        }
    }
    */

    //MN-29042022-US-0010950
    @wire(getRecord, {recordId: '$sellerId', fields})
    accountRec ({error, data}){
        // console.log('**** accountRec - data :: ', data);
        if(data){
            this.sellerName = data.fields.Name.value;
        }
    }

    /*MN-29042022-US-0010950 - Using standard function getRecord instead
    @wire(getAccountName)
    accountName(result) {
        // console.log('accres result>>> ',result);  
        if(result.data) {                  
            // console.log('res result>>> '+JSON.stringify(result.data));   
            this.sellerId=result.data.Id;    
            this.sellerName=result.data.Name;
        } else if (result.error) {
            console.log('error : >>> ', result.error);
        }
        // console.log(this.template.querySelector('.card'))
        
    
    }
    */
    //MN-27042021-US-0010950
    handleAccountChange(event) {
        

        let accId = event.detail["selectedVal"];
        let accRec = event.detail["record"];
        if(this.mapLinkedAcc['mapAccIdToFullAccess'][accId]){  // Sophal 02-04-2022 US-0011156
            this.isAccountNoAccess = false;
            this.isEnableGotoDealBtn = true;
        }else{
            this.modalContainer = false;
            this.isAccountNoAccess = true;
            this.isEnableGotoDealBtn = false;
        }
        this.sellerId = accId;
        this.sellerName = accRec.Account.Name;
       
        event.target.validateField(); // call method on chind cmp
        
        //console.log('--handleAccountChange3 sellerName: '+this.sellerName +' siteId: '+ this.siteId);

        if(!this.checkRequireFieldsToSearch())
        {            
            return;
        }

        this.clearFormdata();

       
        
        //NK:US-0012018:20/07/2022: make no sense to call search after clearing all form data! missing search param!
        //this.doSearchEbayItem(this.catId ,this.brand,this.searchKey,0,this.pageSize);

    }
    
    //category change (L1)
     handleChange(event) {        

        var isValid = this.validateAccount(); //MN-29042022-US-0010950

        if (isValid) {

            this.catId = event.detail.value; 
            this.catLabel = event.target.options.find(opt => opt.value === event.detail.value).label;; 
            let selectedVal = event.detail.value;
            // console.log('>>>>> obj:::: ', this.catId);
            // console.log('>>>>> obj:::: ', this.catLabel);

            event.target.reportValidity(); 

            this.selectedDistCat = null;
            this.brand = null;    
            this.brandList = []; 
            this.searchOffset = 0;
            this.currentPage = 1;

            this.doSearchEbayItem(this.catId ,this.brand,this.searchKey,0,this.pageSize);
        }

        

        
     }

     handleSiteChange(event) {
        
        var isValid = this.validateAccount(); //MN-29042022-US-0010950

        if (isValid) {

            // this.template.querySelector('[data-id="card"]').childNodes[0].classList.add('card');

            this.selectedValue = event.detail.value; 
            this.siteId = event.detail.value;
            //  console.log('>>>>> obj:::: in site>> ', this.siteId);
            this.getCategoriesData(this.siteId);

            this.selectedDistCat = null;
            this.brand = null;    
            this.brandList = []; 
            this.distCatList = [];
            this.searchOffset = 0;
            this.currentPage = 1;

            this.doSearchEbayItem(this.catId ,this.brand,this.searchKey,0,this.pageSize);

        } 
        
     }
    handleRowAction(event){
        this.rowData = JSON.parse(JSON.stringify(event.detail.row));
        // console.log('dataRow@@ ', this.rowData);
        this.rowData.catId = this.catId;

        //MN-01122021-US-0010735 - request ebaySearch API to get EAN & Email from seller and populate it back (if exists) to new Single Deal 
        apexGetItemDetail({ siteId:this.rowData.site,itemId:this.rowData.itemId2}).then(result => {
    
            // console.log('***result:  ', result);

            if (result.status) {

                if (result.email) { //Prepopulate Email to Single Deal, if exists
                    this.rowData.email = result.email;
                }

                if (result.result && result.result.length > 0) { //Prepopulate EAN to Single Deal, if exists
                    if (result.result[0].localizedAspects && result.result[0].localizedAspects.length > 0) {
                        for (var i=0; i<result.result[0].localizedAspects.length;i++) {
                            if (result.result[0].localizedAspects[i].name == "EAN") {
                                this.rowData.EAN = result.result[0].localizedAspects[i].value;
                            }
                        }
                    }
                }

             }
             
            this.modalContainer=true;
            this.ebayListContainer=false;

        }).catch(error => {      
            this.isLoading = false;
            // console.log('error >>>>> ', error);
            this.modalContainer=true;
            this.ebayListContainer=false;
        }); 

        // this.modalContainer=true;
        // this.ebayListContainer=false;
    }

    //MN-29042022-US-0010950
    get accountSelected () {
        return this.sellerId != undefined && this.sellerId != "";
    }

    //MN-29042022-US-0010950
    validateAccount() {
        
        if (this.sellerName == undefined || this.sellerName == "") {
            this.template.querySelector("c-lwc-account-picker").validateField();
            return false;
        }

        return true;
    }

    redirectToDeal(event){

        var isValid = this.validateAccount(); //MN-29042022-US-0010950
        
        if (isValid) {
            // console.log('dataRow@@ ');
            this.modalContainer=true;
            this.ebayListContainer=false;
        }
        
    }

    closeModalAction(){
        this.modalContainer=false;
    }
    storeBrandVaue(event){
        //console.log('eveenenttttttttt',event.target.value);
        //console.log('eveenenttttttttt',event.target.name);
        let fieldName= event.target.name;
        this.searchOffset = 0;
        if(fieldName == 'brand'){
            this.brand= event.target.value;
            
            this.searchOffset = 0;
            this.currentPage = 1;
            this.searchEbayItem();

        }else if(fieldName == 'additionalSearch'){
            this.searchKey = event.target.value;
        }

        
    }
    handleDisCatClick(event)
    {
        let catId = event.target.name;
        this.searchOffset = 0;
        this.currentPage = 1;

        let toUnselect = (this.selectedDistCat == catId);

        //console.log("--catId: "+catId+" --selectedDistCat: "+this.selectedDistCat+"  -toUnselect: "+toUnselect);
         //toggle?
         if(toUnselect)
         {
             this.selectedDistCat = null;                         
         }else
         {
             this.selectedDistCat = catId;
         }

        let allBadges = this.template.querySelectorAll("lightning-badge");
        allBadges.forEach(badge => {
            if(badge.name==catId)
            {
                badge.className = toUnselect?"slds-badge my-badge":"my-badge slds-badge slds-theme_success";
            }else
            {
                badge.className = "slds-badge my-badge";
            }
            
        });

        this.brand = null;  
        this.brandList = [];

        //console.log("222--catId: "+catId+" --selectedDistCat: "+this.selectedDistCat+"  -toUnselect: "+toUnselect);
        this.doSearchEbayItem((toUnselect?this.catId:catId),this.brand,this.searchKey,0,this.pageSize);
    }
    searchEbayItem(){
        const allCombobox = this.template.querySelectorAll('.inputValidate');// SB 22-2-2022 US-0011355 - Suchbegriffe on Item Listing page, is not clearing for next search
        let catId = (this.selectedDistCat !=null && this.selectedDistCat !="" && this.selectedDistCat != undefined) ? this.selectedDistCat: this.catId;
        //console.log('request: ',this.siteId, catId, this.sellerName, this.brand, this.searchKey,this.searchLimit,this.searchOffset)
        //console.log('--searchEbayItem:',this.sellerName,this.siteId,catId);
        // if(this.siteId != undefined && catId != undefined){
        if(this.sellerName != undefined && this.siteId != undefined && catId != undefined){
            this.isLoading= true;

            this.doSearchEbayItem(catId,this.brand,this.searchKey,this.searchOffset,parseInt(this.pageSize));
                      
        }
        // SB 22-2-2022 US-0011355 - Suchbegriffe on Item Listing page, is not clearing for next search
        else {
            
            var isValid = this.validateAccount(); //MN-29042022-US-0010950

            if (isValid){
                allCombobox.forEach(inputField => {
                    if(!inputField.checkValidity()) {
                        inputField.reportValidity();
                    }
                });
            }
            
        }
    }
    
    //NK:US-0012018:20/07/2022
    checkRequireFieldsToSearch()
    {
        let catId = (this.selectedDistCat !=null && this.selectedDistCat !="" && this.selectedDistCat != undefined) ? this.selectedDistCat: this.catId;

        //console.log('--checkRequireFieldsToSearch sellerName: '+this.sellerName + ' siteId: '+this.siteId +' catId: '+catId);

        if(this.sellerName != undefined && this.siteId != undefined && catId != undefined)
        {
            return true;
        }
        return false;
    }

    doSearchEbayItem(catId,brand,searchKey,searchOffset,pageSize){
        this.isLoading = true;      
        // console.log('request: ',this.siteId, catId, this.sellerName, brand, searchKey,searchOffset,pageSize)
        this.items = [];
        this.objMessageInfos = [];
        apexSearch({sellerId:this.sellerName,'siteId' :this.siteId,catId:catId,brand:brand,searchKey:searchKey,searchOffset:searchOffset,searchLimit:pageSize}).then(result => {
            
            // console.log('***result:  ', result);

              if(result.isok){                

                    //assign distributed categories
                    if(result.refinement && result.refinement.categoryDistributions && catId == this.catId)//click on disCat not renew the disCat list
                    {
                         
                        this.distCatList = result.refinement.categoryDistributions;
                        
                    }
                    
                    //assign Brand list if any
                    if(result.refinement && result.refinement.aspectDistributions)
                    {                        
                        
                        let hasBrand =  (this.brandList != undefined && this.brandList.length >0);
                        // console.log("--hasBrand: "+hasBrand);

                        if(!hasBrand)
                        {
                            this.brandList = [];
                            result.refinement.aspectDistributions.forEach(element => {
                                if(element.localizedAspectName == "Marke" || element.localizedAspectName == "Brand" || element.localizedAspectName == "Marque" || element.localizedAspectName == "Marca")
                                {
                                    
                                    element.aspectValueDistributions.forEach(asp => {
                                        //number is not trustable. matchCount vs reall size vs total
                                        //this.brandList.push({label:asp.localizedAspectValue+" ("+asp.matchCount+")",value:asp.localizedAspectValue}); 
                                         this.brandList.push({label:asp.localizedAspectValue,value:asp.localizedAspectValue}); 
                                    });                                    
                                }
                                                            
                            });
                        }
                        
                         
                    }
                    
                    
                    if(result.listResult)
                    {
                         //console.log('@@@@listResult: ',result.listResult);
                        let listItem = [];
                        result.listResult.forEach(item => {
                            listItem.push({
                                             itemId: item.legacyItemId,
                                             itemId2: item.itemId, //MN-01122021-US-0010735
                                             title: item.title,
                                             categoryName: this.catLabel,
                                             category: this.catLabel,
                                             site : this.siteId,
                                             //currentPrice: item.price.currency + ' '+item.price.value  
                                             currentPrice: item.price.value ,
                                             CurrencyIsoCode: item.price.currency,
                                             itemWebUrl:item.itemWebUrl
                                
                                         });
                        });
                        let currentCount = result.listResult.length;
                        this.totalCount = result.total < currentCount ? currentCount: result.total; //some time total nummber returns incorrectly
                        this.totalPage = Math.ceil(this.totalCount / this.pageSize);    

                        //this.items = listItem;
                        this.records = listItem;
                         
        
                    }
                    else   
                    {
                        //NK:20/07/2022:US-0012018 - clear the display list when no search result
                        this.records = [];
                        this.totalCount = 0;
                        this.totalPage = 0;
                        this.currentPage = 1;
                         
                    }

                    //console.log("--brandList: "+JSON.stringify(this.brandList));
                    //console.log("--distCatList: "+JSON.stringify(this.distCatList));

                     
                     
                    //console.log('@@@@result.listResult',result.listResult);
                 }else {
                      
                     this.records = [];
                     this.totalCount = 0;
                     this.totalPage = 0;
                     this.currentPage = 1;
                     var objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : result.msg.errors[0].longMessage};
                     this.objMessageInfos.push(objMsgInfo);
                 }

                 this.isLoading = false;
                 
             })
             .catch(error => {     
                
              this.isLoading = false;
              console.log('error >>>>> ', error);
          });
    }
     
    isBlank(str) {
        return (!str || /^\s*$/.test(str));
    } 
     
     getCategoriesData(siteId){
        //  console.log('request',siteId)
         this.objMessageInfos = [];
         getCategories({'siteId' :siteId}).then(result => {
            //  console.log('res.id >>>>> ', result);
              if(result.listCats.length > 0){
                let categoryData = [];
                result.listCats.forEach(element => {
                    categoryData.push({
                        label: element.label,
                        value: element.value
                     });
                  });
                  categoryData.sort(function(a, b){
                    if(a.label < b.label) { return -1; }
                    if(a.label > b.label) { return 1; }
                    return 0;
                })
                this.categoryOptions = categoryData;
                // console.log('@@@@this.listItem>>>>',this.categoryOptions);
                }
            })
            .catch(error => {      
             this.isLoading = false;
             console.log('error >>>>> ', error);
         });            
     }

     //clicking on previous button this method will be called
    previousHandler() {
       
        if(this.currentPage > 1)
        {
            this.searchOffset = this.searchOffset - this.pageSize;
            this.searchOffset = this.searchOffset <=0 ? 0 : this.searchOffset;
            this.currentPage-=1;
            
            this.searchEbayItem();
        }

    }

    //clicking on next button this method will be called
    nextHandler() {
         
        if(this.currentPage < this.totalPage)
        {
            this.searchOffset = this.searchOffset + this.pageSize;
            this.currentPage+=1;

            this.searchEbayItem();
        }        
    }

     

    get showPrevious(){
        if(this.totalPage>1){
            return true;
        }
    }
    get showNext(){
        if(this.totalPage>1){
            return true;
        }
    }

    clearFormdata(){
        const lwcComboFields = this.template.querySelectorAll(
            'lightning-combobox'
      );
      if (lwcComboFields) {
        //  console.log('>>>>lwcInputFields',lwcComboFields)
         lwcComboFields.forEach(field => {

               field.value=null;
            });
      }
      const lwcInputFields = this.template.querySelectorAll(
         'lightning-input'
      );
      if (lwcInputFields) {
        //  console.log('>>>>lwcInputFields',lwcInputFields)
         lwcInputFields.forEach(field => {
               field.value=null;
         });
      }
      const siteIdField = this.template.querySelector('.siteIdField');//SB 22-2-2022 US-0011355 - Suchbegriffe on Item Listing page, is not clearing for next search
      this.records = [];
      this.totalCount = 0;
      this.totalPage = 0;
      this.page = 0;

      this.selectedDistCat = null;
      this.brand = null;    
      this.brandList = []; 
      this.distCatList = [];
      this.searchOffset = 0;
      //SB 22-2-2022 US-0011355 - Suchbegriffe on Item Listing page, is not clearing for next search
      this.searchKey = undefined;
      this.catId = null;
      siteIdField.value = this.siteId;
      //SB 22-2-2022 US-0011355 - Suchbegriffe on Item Listing page, is not clearing for next search

    }
     

    redirectToFutureDeals() {
        // redirect to create deal page
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                // SB 16-3-2022 US-0011312
                url: '/my-deal-lists'
            }
        });
     }
    /* SB 21-2-2022 US-0011303 - Cosmetic Defects 4 */
    //  renderedCallback() {

    //     Promise.all([loadStyle(this, SAMPLE_CSS + '/searchItemStyle.css')]);
    // }

    get isStep0()
    {
        return this.step==0;
    }
    get isStep1()
    {
        return this.step==1;
    }

}