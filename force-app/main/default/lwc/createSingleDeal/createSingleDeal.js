import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import initData from '@salesforce/apex/CustomDealController.initData';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import fetchSEPGlobalVarWithPrefix from "@salesforce/apex/SEP_ItemSearchController.fetchSEPGlobalVarWithPrefix"; //MN-23112021-US-0010805
import fetchDealRetailCampaignBySite from '@salesforce/apex/DealRetailCampaignCtrl.fetchDealRetailCampaignBySite';
import getSelectedCategories from '@salesforce/apex/CustomDealController.getSelectedCategories';//Sambath Seng - 13/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
import { createRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import Id from '@salesforce/user/Id';
import Deal_Object from '@salesforce/schema/EBH_Deal__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LWCCreateSingleDeal2 from '@salesforce/label/c.LWCCreateSingleDeal2';
import LWCCreateSingleDeal5 from '@salesforce/label/c.LWCCreateSingleDeal5';
import LWCCreateSingleDeal3 from '@salesforce/label/c.LWCCreateSingleDeal3';
import LWCCreateSingleDeal4 from '@salesforce/label/c.LWCCreateSingleDeal4';
import LWCCreateSingleDeal6 from '@salesforce/label/c.LWCCreateSingleDeal6';
import LWCCreateSingleDeal11 from '@salesforce/label/c.LWCCreateSingleDeal11';
import LWCCreateSingleDeal8 from '@salesforce/label/c.LWCCreateSingleDeal8';
import LWCCreateSingleDeal9 from '@salesforce/label/c.LWCCreateSingleDeal9';
import LWCCreateSingleDeal10 from '@salesforce/label/c.LWCCreateSingleDeal10';
import LWCCreateSingleDeal12 from '@salesforce/label/c.LWCCreateSingleDeal12';
import LWCCreateSingleDeal7 from '@salesforce/label/c.LWCCreateSingleDeal7';
import LWCCreateSingleDeal13 from '@salesforce/label/c.LWCCreateSingleDeal13';
import LWCCreateSingleDeal14 from '@salesforce/label/c.LWCCreateSingleDeal14';
import LWCCreateSingleDeal15 from '@salesforce/label/c.LWCCreateSingleDeal15';
import LWCCreateSingleDeal16 from '@salesforce/label/c.LWCCreateSingleDeal16';
import LWCCreateSingleDeal17 from '@salesforce/label/c.LWCCreateSingleDeal17';
import LWCCreateSingleDeal23 from '@salesforce/label/c.LWCCreateSingleDeal23';//SRO-04-02-2022:US-0011151
import LWCCreateSingleSameEbayIdDuplicated from '@salesforce/label/c.LWCCreateSingleSameEbayIdDuplicated';//SRO-14-03-2022:US-0011338
import LWCBulkUploadCSVError29 from '@salesforce/label/c.LWCBulkUploadCSVError29';
import LWCCreateSingleDealLimitDRC from '@salesforce/label/c.LWCCreateSingleDealLimitDRC';//LA-29-11-2021-US-0010733
import LWCBulkUploadCSVError39 from '@salesforce/label/c.LWCBulkUploadCSVError39'; //MN-30112021-US-0010797 
import LWCCreateSingleDeal18 from '@salesforce/label/c.LWCCreateSingleDeal18'; //MN-01122021-US-0010797 
import LWCCreateSingleDeal19 from '@salesforce/label/c.LWCCreateSingleDeal19'; //MN-01122021-US-0010797 
import LWCCreateSingleDeal20 from '@salesforce/label/c.LWCCreateSingleDeal20'; //MN-01122021-US-0010797 
import LwcErrorLimitSingleDealHomePage from '@salesforce/label/c.lwcErrorLimitSingleDealHomePage';//LA-29-11-2021-US-0010733
import LwcMaxDEDealLimitPerDay from '@salesforce/label/c.LwcMaxDEDealLimitPerDay';//LA-29-11-2021-US-0010733
import LWCCreateSingleDeal21 from '@salesforce/label/c.LWCCreateSingleDeal21'; //SB-10122021-US-0010766
import LWCCreateSingleDealERROR from '@salesforce/label/c.LWCCreateSingleDealERROR'; //SRO-24-03-2022:US-0011338
import LWC_Default_Picklist_Placeholder from '@salesforce/label/c.LWC_Default_Picklist_Placeholder'; //MN-06012022-US-0010947 
import LWC_Valid_Specail_Character from '@salesforce/label/c.LWC_Valid_Specail_Character'; //Loumang-11-01-2022:US-0010959
import LWC_Valid_Length_SellerPrice from '@salesforce/label/c.LWC_Valid_Length_SellerPrice';//Loumang-11-01-2022:US-0010959
import LWCCreateSingleDeal22 from '@salesforce/label/c.LWCCreateSingleDeal22'; //MN-03022021-US-0011024
import DRC_Inline_info from '@salesforce/label/c.DRC_Inline_info'; //SB 21-2-2022 US-0011212 - Feedback - QA/BA/UAT/GCX
import lbl_None from '@salesforce/label/c.LWCCreateSingleDeal23'; //NK: 14-03-2022 US-0011415
import Back_Text from '@salesforce/label/c.SEP_BACK_BUTTON'; 

import LANG from '@salesforce/i18n/lang';
import RequiredField from '@salesforce/label/c.Required_field';
// import getTodayDealSetting from '@salesforce/apex/CustomDealController.getTodayDealSetting';
import getTodayDealSetting from '@salesforce/apex/CustomDealController.getTodayDEDealSetting'; //MN-27042021-US-0010950
import getDuplicateEbayItemID from '@salesforce/apex/CustomDealController.getDuplicateEbayItemID';//SRO-14-03-2022:US-0011338
import getLinkedAccSpDeal from '@salesforce/apex/CustomDealController.getLinkedAccSpDeal';  //Sophal 02-04-2022 US-0011156 - Restrict ability for Sellers to be able to create Deals - Linked Account

export default class CreateSingleDeal extends NavigationMixin(LightningElement) {

    @track fieldLabels = {};
    @track fieldErrors = {};
    label = {
        LWCCreateSingleDeal2,
        LWCCreateSingleDeal5,
        LWCCreateSingleDeal3,
        LWCCreateSingleDeal4,
        LWCCreateSingleDeal6,
        LWCCreateSingleDeal11,
        LWCCreateSingleDeal8,
        LWCCreateSingleDeal9,
        LWCCreateSingleDeal10,
        LWCCreateSingleDeal12,
        LWCCreateSingleDeal7,
        LWCCreateSingleDeal13,
        LWCCreateSingleDeal14,
        LWCCreateSingleDeal15,
        LWCCreateSingleDeal16,
        LWCCreateSingleDeal17,
        LWCCreateSingleDeal23,//SRO-04-02-2022:US-0011151
        LWCCreateSingleSameEbayIdDuplicated,//SRO-14-03-2022:US-0011338
        LWCBulkUploadCSVError29,
        LWCCreateSingleDealLimitDRC,//LA-29-11-2021-US-0010733
        LwcMaxDEDealLimitPerDay,//LA-29-11-2021-US-0010733
        LWCCreateSingleDealERROR,//SRO-24-03-2022:US-0011338
        LwcErrorLimitSingleDealHomePage,//LA-29-11-2021-US-0010733 
        LWCBulkUploadCSVError39, //MN-30112021-US-0010797 
        LWCCreateSingleDeal18, //MN-01122021-US-0010797 
        LWCCreateSingleDeal19, //MN-01122021-US-0010797 
        LWCCreateSingleDeal20, //MN-01122021-US-0010797 
        LWCCreateSingleDeal21, //SB-10122021-US-0010766 
        LWC_Default_Picklist_Placeholder, //MN-06012022-US-0010947 
        LWC_Valid_Specail_Character,//Loumang-11-01-2022:US-0010959
        LWC_Valid_Length_SellerPrice, //Loumang-11-01-2022:US-0010959
        LWCCreateSingleDeal22, //MN-03022021-US-0011024
        DRC_Inline_info, //SB 21-2-2022 US-0011212 - Feedback - QA/BA/UAT/GCX
        lbl_None,
        Back_Text
    };
    lang = LANG;
    req = RequiredField;
    @api showComponent;
    @track todayDate;
    @track dateValue;
    
    @api recordId;
    @api isCloned;    

    @api title;
    @api rowData;
    @api labelCancelBtn; 
    @api labelSubmitBtn;
    @api successMessage;
    @api accountId; //MN-29042022-US-0010950

    @track isShowMessage = false;

    @track objMessageInfos = [];
    @track disableBtn = false;

    @track userId = Id;

    @track emailval;
    @track titleval;
    @track categoryval ;
    @track currentPriceval;
    @track itemIdval;

    //La-29-11-2021-US-0010733
    @track totalDealOfDEToday = 0;
    //@track maxDEDealLimitPerDay = -1;
    @track isDEUser = false;
    @track openSeatsAvailable = 0;

    @api showLoadingSpinner = false;

    @track singleDeal = new Object();
    @track blankDeal = new Object(); //MN-09052021-US-0010950

    errors = [];
    options = [];
    siteOptions = [];
    conditionOptions = [];
    categoryOptions = [];
    formatOptions = [];
    @track categoryMap;
    @wire(getObjectInfo, {objectApiName: Deal_Object })
    dealsMetadata;

    // @track todayval = new Date().toISOString();

    jsonMapRes;

    @track selectedCategories = [];//Sambath Seng - 10/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
    @track defaultDrc = '';//SB 25-2-2022 US-0011351 - Deal creation button on the DRC view page

    @track isAccountSelectable = false;
    @track isAccountNoAccess = false;
    mapLinkedAcc = {isHavingNoFullAccess : true, mapAccIdToFullAccess :{}};
    @track DealReadOnlyErrorMessage = '';
    fullAccess = 'Full Access';

    connectedCallback(){

        // Sophal 02-04-2022 US-0011156 - Start Here
        getLinkedAccSpDeal()
        .then(result => {
            
            if(result.status == 'ok'){

                /* //MN-05062024-US-0015298
                if(result.profileName == 'DE - Seller Portal') this.DealReadOnlyErrorMessage = 'DEdealLinkedAccountReadOnlyErrorMessage'; // Sophal 02-04-2022 US-0011156 - custom meta data record of custom meta data "Component help text setting"
                if(result.profileName != 'DE - Seller Portal') this.DealReadOnlyErrorMessage = 'NAdealLinkedAccountReadOnlyErrorMessage'; // Sophal 02-04-2022 US-0011156 - custom meta data record of custom meta data "Component help text setting"
                */

                //START--MN-05062024-US-0015298: Check SP Main Domain instead of Profile Name
                var isEU = result["isEU"];
                if(isEU) this.DealReadOnlyErrorMessage = 'DEdealLinkedAccountReadOnlyErrorMessage'; // Sophal 02-04-2022 US-0011156 - custom meta data record of custom meta data "Component help text setting"
                if(!isEU) this.DealReadOnlyErrorMessage = 'NAdealLinkedAccountReadOnlyErrorMessage'; // Sophal 02-04-2022 US-0011156 - custom meta data record of custom meta data "Component help text setting"
                //--END

                if(!result.isHavingNoFullAccess){
                    this.isAccountSelectable = true;
                    this.mapLinkedAcc['isHavingNoFullAccess'] = result.isHavingNoFullAccess;
                    this.mapLinkedAcc['mapAcc'] = result.mapAcc;
                    this.mapLinkedAcc['mapAccIdToFullAccess'] = {};
                    for (var key in this.mapLinkedAcc.mapAcc) {
                        if (this.mapLinkedAcc.mapAcc.hasOwnProperty(key) && this.mapLinkedAcc.mapAcc[key].SP_Deals__c == this.fullAccess){
                            this.mapLinkedAcc['mapAccIdToFullAccess'][key.substring(0, key.length-3)] = true;
                        }
                    }
                }                

            }else if(result.status == 'ko'){
                console.log("error result.error == ", result.error);
            }

        }).catch(error => { 
            console.log("error createSingleDeal == ", error);
        });
        // Sophal 02-04-2022 US-0011156 - Stop Here

        // console.log('*** accountId :: ', this.accountId);

        //console.log('isDE::',this.lang);
        var today = new Date();
        var dd = String(today.getDate()).padStart(2, '0');
        var mm = String(today.getMonth() + 1).padStart(2, '0'); 
        var yyyy = today.getFullYear();
        this.isCloned = false;
        this.singleDeal.EBH_Dealdateearliestpossible__c = yyyy + "-" + mm + "-" + dd;
        this.title = this.title;
        if(this.rowData !=undefined && this.rowData !=null && Object.keys(this.rowData).length>0){
            this.rowData = JSON.parse(JSON.stringify(this.rowData));
            //console.log("@@@conneted",this.rowData);
            // console.log("@@@email",this.emailval);
            
            this.singleDeal.EBH_eBayItemID__c = this.rowData.itemId;
            this.singleDeal.EBH_ProductTitle__c = this.rowData.title;
            //var price = this.rowData.currentPrice.split(' ')[1]; //MN-06122021-For old Search API
            //var price = this.rowData.currentPrice; //MN-06122021-For new Search API
            var price = this.lang=='de'?(this.rowData.currentPrice).replace('.',','):this.rowData.currentPrice;
            //console.log("price::",price);
            // this.singleDeal.EBH_SellerPrice__c =parseFloat(price);
            this.singleDeal.EBH_SellerPrice__c =price;
            this.singleDeal.EBH_Category__c = this.rowData.category;
            this.singleDeal.SiteURL__c = '';
            this.singleDeal.EBH_EAN__c = '';
            this.singleDeal.EBH_DealSiteId__c = this.rowData.site

            if (this.rowData.EAN && this.rowData.EAN != '') this.singleDeal.EBH_EAN__c = this.rowData.EAN; //MN-01122021-US-0010735
            //TH:23/Feb/2022:Comment Out: US-0011264 - Seller Contact / Seller email - For Hive internal view
            //if (this.rowData.email && this.rowData.email != '') this.singleDeal.EBH_SellerEmail__c = this.rowData.email; //MN-01122021-US-0010735

        }
        else{
            this.singleDeal.EBH_DealSiteId__c = '77'
        }
        if(this.singleDeal.EBH_DealSiteId__c){
            this.fetchDealRetailCampaign(this.singleDeal.EBH_DealSiteId__c)
        }
        //SB 25-2-2022 US-0011351 - Deal creation button on the DRC view page
        var url = new URL(location.href);
        if(url.searchParams.get('drc')){
            let decodeDRCId = decodeURI(url.searchParams.get('drc'));
            this.defaultDRC = decodeDRCId;
            this.singleDeal.EBH_DealRetailCampaign__c = decodeDRCId;
        }


    }
    //SB 25-2-2022 US-0011351 - Deal creation button on the DRC view page
    get drcId (){
        return this.defaultDRC;
    }
    @wire(getObjectInfo, { objectApiName: Deal_Object })
    getFieldLabels({ data, error }) {
        if(data){
    
            for (const [key, value] of Object.entries(data['fields'])) {
                this.fieldLabels[value.apiName] = value.label;
            }
        }
        
    }

    @wire(initData) 
    wireInitData({error, data}) {
        if (data) {
            this.jsonMapRes = data;
            this.error = undefined;
            // auto populate email
            var mapRes = JSON.parse(this.jsonMapRes); 
            // console.log('mapRes::',mapRes);
            // console.log('mapRes.contactId::',mapRes.contactId);
            // console.log('mapRes.email::',mapRes.email);
            if (!this.singleDeal.EBH_SellerEmail__c || this.singleDeal.EBH_SellerEmail__c == '') { //MN-01122021-US-0010735 - In case there is seller email from EbaySearch, then no need to take from Hive
                this.singleDeal.EBH_SellerEmail__c = mapRes.email;
                //TH:23/Feb/2022:US-0011264 - Seller Contact / Seller email - For Hive internal view
                this.singleDeal.Seller_Contact__c = mapRes.contactId;
            }


        } else if(error) {
            this.error = error;
            this.jsonMapRes = undefined;
        }
    };    

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) {
          this.urlStateParameters = currentPageReference.state;
          this.setParametersBasedOnUrl();
       }
    }

    //Sambath Seng - 13/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
    @wire(getSelectedCategories)
    getSelectedCategories({error, data}) {
        if (data) {
            data.forEach(category =>{
                this.selectedCategories.push(category);
            });
        }
    }
 
    setParametersBasedOnUrl() {
       this.startDate = this.urlStateParameters.startDate || null;
       this.endDate = this.urlStateParameters.endDate || null;       
    }

    //MN-29042021-US-0010950
    handleAccountChange(event) {

        // MN-09052021-US-0010950----
        let tmp = this.rowData;
        let accId = event.detail["selectedVal"];

        if (Object.keys(tmp).length > 0) {

            if (this.accountId != undefined && this.accountId != "" && this.accountId != accId) { //MN-23052022-US-0010950
                this.blankDeal.EBH_Dealdateearliestpossible__c = this.singleDeal.EBH_Dealdateearliestpossible__c;
                this.blankDeal.EBH_DealSiteId__c = this.singleDeal.EBH_DealSiteId__c;
                this.blankDeal.EBH_DealRetailCampaign__c = this.singleDeal.EBH_DealRetailCampaign__c;
                this.singleDeal = this.blankDeal;
            }
        }
        // ----MN-09052021-US-0010950
        
        if(this.mapLinkedAcc['mapAccIdToFullAccess'][accId]){  // Sophal 02-04-2022 US-0011156
            this.isAccountNoAccess = false;
        }else{
            this.isAccountNoAccess = true;
        }
        this.accountId = accId;
        
    }


    handleSuccess(event){
        this.objMessageInfos = [];
        this.disableBtn = false; // enable button

        var objMsgInfo = {className : "cls_message-success", mainMsg : "SUCCESS", detailMsg : event.detail.apiName + ' record updated/created.'};
        this.objMessageInfos.push(objMsgInfo);       
        
        const updatedRecord = event.detail.id;

        this.isShowMessage = true;
        let _this = this;
        setTimeout(function(){ 
            console.log('inside time out::')
            _this.redirectToFutureDeals();
        }, 1500);
        

        
     }

     handleError(event) {

        this.disableBtn = false; // enable button
        this.objMessageInfos = [];
        let msg = event.detail.detail;
        var objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
        this.objMessageInfos.push(objMsgInfo);
        
    }

     redirectToFutureDeals() {
        // redirect to create deal page
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: '/my-deal-lists'
            }
        });
     }

     redirectToPicker() {
        // redirect to item picker
        console.log
        this.showComponent = false;
     }

     redirectToHome() {
        // redirect to home
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: '/s'
            }
        });
     }

     handleSubmit(event) {
        event.preventDefault();       // stop the form from submitting​
        this.showLoadingSpinner = true;
        
        const fields = event.detail.fields;       
        this.disableBtn = true; // disable button
        this.objMessageInfos = [];
        if (this.isCloned == 'true' && this.recordId) {   // clone record     

            this.recordId = '';         
            delete fields.Id;

            fields.EBH_BusinessName__c = this.accId.data; //'0011F00000tatlRQAQ'; // test fix account          

            const cloneDeal = {apiName: 'EBH_Deal__c', fields};        
            createRecord(cloneDeal)
            .then(res => {
               // this.recordId = res.id;
                // console.log('res.id >>>>> ', res.id);                

                var objMsgInfo = {className : "cls_message-info", mainMsg : "SUCCESS", detailMsg : 'Clone record created'};
                this.objMessageInfos.push(objMsgInfo);

                this.handleSuccess();
            })
            .catch(error => {             
                var objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : error.body.message};
                this.objMessageInfos.push(objMsgInfo);
            });

            
        
        }else { 
            //console.log('this.singleDeal >>>>> ', JSON.stringify(this.singleDeal));
            var validateResult = this.validateInputs();
            console.log('this.validateResult >>>>> ', validateResult);  
            if(!validateResult){
                this.showLoadingSpinner = false;
                this.disableBtn = false;
                return
            }
            this.singleDeal.EBH_Quantity__c = parseInt(this.singleDeal.EBH_Quantity__c);
            //La-29-11-2021:US-0010733
            //this.singleDeal.EBH_SellerPrice__c = parseFloat(this.singleDeal.EBH_SellerPrice__c.replace(',','.'));   
            this.singleDeal.EBH_SellerPrice__c = parseFloat((this.singleDeal.EBH_SellerPrice__c+'').replace(',','.'));//La-29-11-2021:US-0010733 prevent to convert from text //MN-06122021-Since we use Input type=number and expect that it will give the correct value based on User's locale //Loumang-11-01-2022:US-0010959
            const fields = this.singleDeal;
            var mapRes = JSON.parse(this.jsonMapRes);   
            
            // // populate background field value
            // fields.EBH_BusinessName__c = mapRes.accountId //'0011F00000tatlRQAQ'; // test fix account //MN-29042022-US-0010950
            fields.EBH_BusinessName__c = this.accountId; //MN-29042022-US-0010950 - Need to use with selected account from Account Picker (lwcAccountPicker)
            fields.OwnerId = this.userId;
            
            // fields.Seller_Name__c = mapRes.contactId; // contact id
            // fields.CreatedById = mapRes.intUser; // test fix id Integration user
            // fields.EBH_SellerEmail__c = mapRes.email;
            const recordInput = { apiName: 'EBH_Deal__c', fields };
            this.validateAndCreateDeal(this.singleDeal.EBH_DealRetailCampaign__c,recordInput);//La-29-11-2021:US-0010733: validate limit deal
            //Loumang move this code to new method
            /*createRecord(recordInput)
            .then(deal => {
                console.log('dealid: ',deal)
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.LWCCreateSingleDeal16,
                        message: this.label.LWCCreateSingleDeal15,
                        variant: 'success',
                    }),
                );
                this.redirectToHome();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.LWCCreateSingleDeal17,
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
                
            });*/
            //this.showLoadingSpinner = false;
            //this.disableBtn = false;
        }
    } 

    cancelhandler() {

        // console.log('called from cancel button ...');
        this.redirectToFutureDeals();
        
    }

    renderedCallback() {
        // console.log('map response data xxx rendered >>>>> ', this.jsonMapRes);         
    }

    validateInputs(){
        
        this.errors = [];
        var today = new Date();
        this.fieldErrors = {}
        this.validateInput('EBH_DealSiteId__c', this.singleDeal.EBH_DealSiteId__c)
        
        this.validateInput('EBH_eBayItemID__c', this.singleDeal.EBH_eBayItemID__c)
        
        this.validateInput('EBH_EAN__c', this.singleDeal.EBH_EAN__c)
        
        this.validateInput('Item_Condition__c', this.singleDeal.Item_Condition__c)
        
        this.validateInput('EBH_ProductTitle__c', this.singleDeal.EBH_ProductTitle__c)
        
        this.validateInput('EBH_Category__c', this.singleDeal.EBH_Category__c)
        
        this.validateInput('EBH_AmazonLink__c', this.singleDeal.EBH_AmazonLink__c)
        
        this.validateInput('EBH_IdealoLink__c', this.singleDeal.EBH_IdealoLink__c)
        
        this.validateInput('EBH_Quantity__c', this.singleDeal.EBH_Quantity__c)
        
        this.validateInput('EBH_Dealdateearliestpossible__c', this.singleDeal.EBH_Dealdateearliestpossible__c)
        
        this.validateInput('EBH_SellerPrice__c', this.singleDeal.EBH_SellerPrice__c)
        
        if(this.errors.length == 0){
            return true;
        }
        else{
            return false;
        }
    }

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

    @wire(getPicklistValuesByRecordType, {
        objectApiName: Deal_Object,
        recordTypeId: '$dealsMetadata.data.defaultRecordTypeId'
    })
    picklistValues({error,data}) {
        if (data) {

            let statusData = [];
            //fetch status option data
            /* MN-23112021-US-0010805 - No longer get Deal Site based on Profile's Deal Default Record Type
            if (data.picklistFieldValues.EBH_DealSiteId__c) {
                data.picklistFieldValues.EBH_DealSiteId__c.values.forEach(element => {
                    statusData.push({
                        label: element.label,
                        value: element.value
                    });
                });
                this.siteOptions = statusData;
                statusData = [];
            }
            */
            if (data.picklistFieldValues.Item_Condition__c) {
                
                var valuesToShow = ['New', 'Used', 'Refurbished', 'New other']; //MN-22052023-US-0013541
                data.picklistFieldValues.Item_Condition__c.values.forEach(element => {
                    if(valuesToShow.includes(element.value)){
                        statusData.push({
                            label: element.label,
                            value: element.value
                        });
                    }
                    
                });
                this.conditionOptions = statusData;
                statusData = [];
            }

            if (data.picklistFieldValues.EBH_Category__c) {
                if(!this.categoryMap){
                    this.categoryMap = data.picklistFieldValues.EBH_Category__c;
                }
                statusData = this.getCategoriesFromSite();                
                this.categoryOptions = statusData;
                statusData = [];
            }

            if (data.picklistFieldValues.EBH_DealFormat__c) {
                data.picklistFieldValues.EBH_DealFormat__c.values.forEach(element => {
                    statusData.push({
                        label: element.label,
                        value: element.value
                    });
                });
                this.formatOptions = statusData;
                this.formatOptions.unshift({label:this.label.lbl_None,value:null});
                // console.log('final format: ',this.formatOptions)

            }
        } else if (error) {
        // console.log(error);
        }
    }

    getDRCOptions(){
        let opts = [];
        //console.log('>>>>> this.records:::: ', this.records);

        if (this.records) {
           var objRec = {};
        //    opts.push({ label: ' --- ', value : ''}); //MN-07012022-US-0010947
           opts.push({ label: this.label.LWCCreateSingleDeal23 , value : ''}); //SRO-04-02-2022:US-0011151
           this.records.forEach(function(drc){          
                var startDate = new Date(drc.EBH_Date__c).toLocaleDateString('en-GB'); //Sambath Seng - 07.12.2021 - US-0010837 - Store start date field value //TH:14/03/2022:US-0011444 - Date format change needed on DRC ()
                var endDate = new Date(drc.EPH_EndDate__c).toLocaleDateString('en-GB'); //Sambath Seng - 07.12.2021 - US-0010837 - Store end date field value //TH:14/03/2022:US-0011444 - Date format change needed on DRC ()
                opts.push({ label: drc.EBH_DealTitle__c+' ('+startDate+' - '+endDate+')', value :drc.Id}); //Sambath Seng - 07.12.2021 - US-0010837 - [SP - EU Deals] Include start and end date in DRC picklist
                objRec[drc.Id] = drc;
           });
           //console.log('>>>>> objRec:::: ', objRec);
           this.options = opts;
        }

        return opts;
    }
    get options() {
        return this.getDRCOptions();
    }

    

    fetchDealRetailCampaign(siteNumber){
        fetchDealRetailCampaignBySite({siteNumber : siteNumber})
        .then(result => {
            //console.log(">>>>resultxxx ", result);
                if(result){
                    this.records = result;
                    this.error = undefined;
                    this.getDRCOptions();
                }
            })
            .catch(error => { 
                // console.log(">>>>>DRC fetch error:", error);
            }); 
    }  

    onSiteChange(event){
        var siteNumber = event.detail.value;
        this.singleDeal.EBH_DealSiteId__c = siteNumber;
        this.fetchDealRetailCampaign(siteNumber);

    }

    handleChange(event){
        var value = event.detail.value
        var apiName = event.target.getAttribute("data-apiname")
        if(apiName == 'EBH_DealSiteId__c'){
            this.onSiteChange(event)
            this.categoryOptions = this.getCategoriesFromSite()
        }
        this.singleDeal[apiName] = value;
        this.validateInput(apiName, value);
    }

    validateInput(field, value){
        this.fieldErrors[field] = undefined;
        if(field == 'EBH_DealSiteId__c'){
            if(this.singleDeal.EBH_DealSiteId__c == undefined || this.singleDeal.EBH_DealSiteId__c == null){
                this.fieldErrors['EBH_DealSiteId__c'] = this.label.LWCCreateSingleDeal2;
                this.errors.push(field)
            }
        }
        else if(field == 'EBH_eBayItemID__c'){
            // if(this.singleDeal.EBH_eBayItemID__c != undefined && (this.singleDeal.EBH_eBayItemID__c.length != 12 || isNaN(this.singleDeal.EBH_eBayItemID__c))){ //MN-30112021-US-0010797 
            if(this.singleDeal.EBH_eBayItemID__c != undefined && this.singleDeal.EBH_eBayItemID__c != '' && (this.singleDeal.EBH_eBayItemID__c.length != 12 || isNaN(this.singleDeal.EBH_eBayItemID__c)) ){ //MN-30112021-US-0010797 
                this.fieldErrors['EBH_eBayItemID__c'] = this.label.LWCCreateSingleDeal3;
                this.errors.push(field)

            }
        }
        else if(field == 'EBH_EAN__c'){
            let ean = this.template.querySelector('.EBH_EAN__c');//Sambath Seng - 10/12/2021 - US-0010766
            //Loumang:03-11-2021:US-0010729 - [SP - EU Deals] [Bug] EAN accepting text
            //if(this.singleDeal.EBH_EAN__c != undefined && (this.singleDeal.EBH_EAN__c != '' && this.singleDeal.EBH_EAN__c.length < 5)){   
            //if(this.singleDeal.EBH_EAN__c != undefined && this.singleDeal.EBH_EAN__c != '' && (this.singleDeal.EBH_EAN__c.length < 5 || isNaN(this.singleDeal.EBH_EAN__c))){ //MN-30112021-US-0010797 
            if(this.singleDeal.EBH_EAN__c != undefined && this.singleDeal.EBH_EAN__c != '' && (this.singleDeal.EBH_EAN__c.length < 5 || isNaN(this.singleDeal.EBH_EAN__c)) ) { //MN-30112021-US-0010797 

                this.fieldErrors['EBH_EAN__c'] = this.label.LWCCreateSingleDeal4;//SB 25-1-2022 US-0011042
                // this.fieldErrors['EBH_EAN__c'] = this.label.LWCBulkUploadCSVError29;//Loumang:03-11-2021:US-0010729
                // this.fieldErrors['EBH_EAN__c'] = this.label.LWCCreateSingleDeal4; //MN-30112021-US-0010797 
                this.errors.push(field)

            }
            //Sambath Seng - 10/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
            if(this.singleDeal.EBH_DealSiteId__c == '77' && (this.singleDeal.EBH_EAN__c == undefined || this.singleDeal.EBH_EAN__c == '') && this.selectedCategories.includes(this.singleDeal.EBH_Category__c)){
                ean.setCustomValidity(this.label.LWCCreateSingleDeal21);
                this.errors.push(field);
            }
            else {
                ean.setCustomValidity('');
            }
            ean.reportValidity();
        }
        else if(field == 'Item_Condition__c'){
            let itemCondition = this.template.querySelector('.Item_Condition__c');
            if(this.singleDeal.Item_Condition__c == undefined || this.singleDeal.Item_Condition__c == ''){
                //this.flagEmpty(field);
                
                itemCondition.setCustomValidity(this.label.LWCCreateSingleDeal18);
                this.errors.push(field);

            }else {
                itemCondition.setCustomValidity('');
            }
            itemCondition.reportValidity();
        }
        else if(field == 'EBH_ProductTitle__c'){
            let productTitle = this.template.querySelector('.EBH_ProductTitle__c');

            if (this.singleDeal.EBH_ProductTitle__c == undefined || this.singleDeal.EBH_ProductTitle__c == '' || this.singleDeal.EBH_ProductTitle__c.length > 80) {
                productTitle.setCustomValidity(this.label.LWCCreateSingleDeal20);
                this.errors.push(field);
            } else {
                productTitle.setCustomValidity('');
            }
            productTitle.reportValidity();
        }
        else if(field == 'EBH_Category__c'){
            let category = this.template.querySelector('.EBH_Category__c');
            let ean = this.template.querySelector('.EBH_EAN__c');//SB 23-0-2022 US-0011294 - EAN required message is not dynamic
            if(this.singleDeal.EBH_Category__c == undefined){
                /* //MN-30112021-US-0010797  - Changed to use with standard LWC's codes to handle custom error message
                this.fieldErrors['EBH_Category__c'] = this.label.LWCCreateSingleDeal6;
                this.errors.push(field)
                */
                category.setCustomValidity(this.label.LWCCreateSingleDeal6);
                this.errors.push(field);
            }else {
                category.setCustomValidity('');
                //SB 23-0-2022 US-0011294 - EAN required message is not dynamic
                if(this.singleDeal.EBH_DealSiteId__c == '77' && (this.singleDeal.EBH_EAN__c == undefined || this.singleDeal.EBH_EAN__c == '') && this.selectedCategories.includes(this.singleDeal.EBH_Category__c)){
                    ean.setCustomValidity(this.label.LWCCreateSingleDeal21);
                    this.errors.push(field);
                }
                else {
                    ean.setCustomValidity('');
                }
                ean.reportValidity();
                //SB 23-0-2022 US-0011294 - EAN required message is not dynamic
            }
            category.reportValidity();
        }
        else if(field == 'SiteURL__c'){
            if(this.singleDeal.SiteURL__c != undefined && (!this.singleDeal.SiteURL__c.startsWith('http://') && !this.singleDeal.SiteURL__c.startsWith('https://'))){
                this.fieldErrors['SiteURL__c'] = this.label.LWCCreateSingleDeal7;
                this.errors.push(field)

            }
        }
        else if(field == 'EBH_AmazonLink__c'){
            if(this.singleDeal.EBH_AmazonLink__c != undefined && this.singleDeal.EBH_AmazonLink__c != '' && (!this.singleDeal.EBH_AmazonLink__c.startsWith('http://') && !this.singleDeal.EBH_AmazonLink__c.startsWith('https://'))){
                this.fieldErrors['EBH_AmazonLink__c'] = this.label.LWCCreateSingleDeal8;
                this.errors.push(field)

            }
        }
        else if(field == 'EBH_IdealoLink__c'){
            if(this.singleDeal.EBH_IdealoLink__c != undefined && this.singleDeal.EBH_IdealoLink__c != '' &&  (!this.singleDeal.EBH_IdealoLink__c.startsWith('http://') && !this.singleDeal.EBH_IdealoLink__c.startsWith('https://'))){
                this.fieldErrors['EBH_IdealoLink__c'] = this.label.LWCCreateSingleDeal9;
                this.errors.push(field)

            }
        }
        else if(field == 'EBH_Quantity__c'){
            let quantity = this.template.querySelector('.EBH_Quantity__c');
            console.log('SRO::: quantity: ',this.singleDeal.EBH_Quantity__c);
            if(this.singleDeal.EBH_Quantity__c == undefined || this.singleDeal.EBH_Quantity__c == ''){
                quantity.setCustomValidity(this.label.LWCCreateSingleDeal19);
                this.errors.push(field);
            }
            else if(!this.isInt(this.singleDeal.EBH_Quantity__c)){
                /* //MN-30112021-US-0010797  - Changed to use with standard LWC's codes to handle custom error message
                this.fieldErrors['EBH_Quantity__c'] = this.label.LWCCreateSingleDeal10;
                this.errors.push(field)
                */
                quantity.setCustomValidity(this.label.LWCCreateSingleDeal10);
                this.errors.push(field);
            }else if(!this.isNumeric(this.singleDeal.EBH_Quantity__c)){
                // SRONG TIN 29.03.2022 : US-0011338 
                quantity.setCustomValidity(this.label.LWCCreateSingleDeal22);
                this.errors.push(field);
             }else {
                quantity.setCustomValidity('');
            }
            quantity.reportValidity();
            
        }
        else if(field == 'EBH_Dealdateearliestpossible__c'){
            let dateEarliestPossible = this.template.querySelector('.EBH_Dealdateearliestpossible__c');
            var today = new Date();
            var selectedDate = new Date(this.singleDeal.EBH_Dealdateearliestpossible__c);
            selectedDate.setHours(0,0,0,0)
            today.setHours(0,0,0,0)
            if(this.singleDeal.EBH_Dealdateearliestpossible__c == undefined || this.singleDeal.EBH_Dealdateearliestpossible__c ==''){
                /* //MN-30112021-US-0010797  - Changed to use with standard LWC's codes to handle custom error message
                this.fieldErrors['EBH_Dealdateearliestpossible__c'] = this.label.LWCCreateSingleDeal11;
                this.errors.push(field)
                */
                dateEarliestPossible.setCustomValidity(this.label.LWCCreateSingleDeal11);
                this.errors.push(field);
            }
            else if(selectedDate<today){
                /* //MN-30112021-US-0010797  - Changed to use with standard LWC's codes to handle custom error message
                this.fieldErrors['EBH_Dealdateearliestpossible__c'] = this.label.LWCCreateSingleDeal13;
                this.errors.push(field)
                */
                dateEarliestPossible.setCustomValidity(this.label.LWCCreateSingleDeal13);
                this.errors.push(field);
            }else {
                dateEarliestPossible.setCustomValidity('');
            }
            dateEarliestPossible.reportValidity();
        }
        else if(field == 'EBH_SellerPrice__c'){
            let sellerPrice = this.template.querySelector('.EBH_SellerPrice__c');
            let sellerPrice_str = String(this.singleDeal.EBH_SellerPrice__c);
            let DE ='de';
            if(this.singleDeal.EBH_SellerPrice__c == undefined || this.singleDeal.EBH_SellerPrice__c == ''){
               
                //this.flagEmpty(field);
                //this.errors.push(field)
                sellerPrice.setCustomValidity(this.label.LWCCreateSingleDeal12);
                this.errors.push(field);
            }else if(!this.checkPriceFormat(this.singleDeal.EBH_SellerPrice__c,16,2) && this.lang==DE) {//Loumang-11-01-2022:US-0010959
               
                if(!this.isNumeric(this.singleDeal.EBH_SellerPrice__c)){
                    sellerPrice.setCustomValidity(this.label.LWC_Valid_Specail_Character);
                    
                }else{
                    sellerPrice.setCustomValidity(this.label.LWC_Valid_Length_SellerPrice);
                    //this.errors.push(field);
                }
                this.errors.push(field);
                
            }
            // MN-06122021-No longer check this since we are now using input type=number
            // else if(isNaN(String(this.singleDeal.EBH_SellerPrice__c).replace(',','.'))){
            //     /* //MN-30112021-US-0010797  - Changed to use with standard LWC's codes to handle custom error message
            //     this.fieldErrors['EBH_SellerPrice__c'] = this.label.LWCCreateSingleDeal14;
            //     this.errors.push(field)
            //     */

            //     sellerPrice.setCustomValidity(this.label.LWCCreateSingleDeal14);
            //     this.errors.push(field);
            // }
            
            else {
                //this.singleDeal.EBH_SellerPrice__c.replace(",",".");
                sellerPrice.setCustomValidity('');
            }
            sellerPrice.reportValidity();
        }
    }

    isInt(value) {
        return !isNaN(value) && 
               parseInt(Number(value)) == value && 
               !isNaN(parseInt(value, 10));
    }

    flagEmpty(field){
        var query = '[data-apiname='+field+']';
        var element = this.template.querySelector(query)
        element.reportValidity();  
    }

    getCategoriesFromSite(){
        var statusData = [];
        var controllerValue = this.categoryMap.controllerValues[this.singleDeal.EBH_DealSiteId__c];

        this.categoryMap.values.forEach(element => {
            if(element.validFor.includes(controllerValue)){
                statusData.push({
                    label: element.label,
                    value: element.value
                });
            }
        });
        statusData.sort(function(a, b){
            if(a.label < b.label) { return -1; }
            if(a.label > b.label) { return 1; }
            return 0;
        })
        return statusData;
    }
    //LA-29-11-2021-US-0010733: validate when Deal has reached daily or DRC limit
    validateAndCreateDeal(dealReatilCampaingId,recordInput){

        //MN-27042021-US-0010950
        
        getTodayDealSetting({dealReatilCampaingId : dealReatilCampaingId, accountId : this.accountId})
        .then(result => {
            //console.log('***** getTodayDealSetting :: ', result);
            this.objMessageInfos = [];
            var msg = "";
            var objMsgInfo;
            if(result["status"] == "success"){
                
                this.availableDeal = result["availableDeal"];
                this.totalDealOfDEToday = (result["totalDealOfDEToday"] != undefined ? result["totalDealOfDEToday"] : 0);
                if(result["currUserLang"]) this.currUserLang = result["currUserLang"];
                //var availableDealToday = this.maxDEDealLimitPerDay - this.totalDealOfDEToday;
                var availableDealToday = parseInt(this.label.LwcMaxDEDealLimitPerDay) - this.totalDealOfDEToday;
                //console.log('DRC::',result["drc"]);
                if(result["drc"] != null && result["drc"]["EBH_OpenSeatsAvailable__c"] != undefined && result["drc"]["EBH_OpenSeatsAvailable__c"] != null){ this.openSeatsAvailable = result["drc"]["EBH_OpenSeatsAvailable__c"]; }
                
                //if(this.currUserLang == "DE - Seller Portal") {this.isDEUser = true;} //MN-05062024-US-0015298
                if(result["isEU"]) {this.isDEUser = true;} //MN-05062024-US-0015298: Check SP Main Domain instead of Profile Name

                if(
                    (this.isDEUser && result["drc"] == null && availableDealToday <= 0)
                    || (this.isDEUser && result["drc"] != null && this.openSeatsAvailable <= 0)
                    || (!this.isDEUser && this.availableDeal <= 0)
                ){
                    this.showLoadingSpinner = false;
                    this.disableBtn = false;
                    //msg = 'INFO You have reached your daily limit or maximum 500 Deals created per day';
                    msg = this.label.LwcErrorLimitSingleDealHomePage;
                    if(this.isDEUser && result["drc"] != null && this.openSeatsAvailable <= 0)
                    {
                        msg = this.label.LWCCreateSingleDealLimitDRC;
                    }

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: '',
                            message: msg,
                            variant: 'error',
                        }),
                    );
                }else{
                   // SRONG TIN 14.03.2022 : US-0011338
                    if(this.singleDeal.EBH_eBayItemID__c != undefined && this.singleDeal.EBH_eBayItemID__c != ''){
                        this.checkDuplicateEbayItemID(this.singleDeal.EBH_DealRetailCampaign__c,recordInput);
                    }else{
                        this.creatDeal(recordInput);
                    }
                }
            } else {
                this.showLoadingSpinner = false;
                this.disableBtn = false;
                msg = result["message"];
                objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
                this.objMessageInfos.push(objMsgInfo);
            }
        })
        .catch(error => { 
             console.log("first load ERROR:::", error);
        });  
        
    }
    // SRONG TIN 14.03.2022 : US-0011338 - System allowing Deals with same item ID & overlapping dates
    checkDuplicateEbayItemID(dealReatilCampaingId,recordInput){
        var eBayItemId = this.singleDeal.EBH_eBayItemID__c;
        getDuplicateEbayItemID({dealReatilCampaingId : dealReatilCampaingId,eBayItemId: eBayItemId})
        .then(result => {
            //console.log('result',result);
            this.objMessageInfos = [];
            var msg = "";
            var objMsgInfo;
            if(result["status"] == "success"){
                // create deal
                if(result["deals"].length != 0){
                    this.showLoadingSpinner = false;
                    this.disableBtn = false;
                    msg = this.label.LWCCreateSingleSameEbayIdDuplicated;
                    objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : this.label.LWCCreateSingleDealERROR, detailMsg : msg};
                    this.objMessageInfos.push(objMsgInfo);
                    return;
                }else{
                    //
                    this.creatDeal(recordInput);
                }
            } else {
                this.showLoadingSpinner = false;
                this.disableBtn = false;
                msg = result["message"];
                objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
                this.objMessageInfos.push(objMsgInfo);
            }
        })
        .catch(error => { 
             console.log("first load ERROR:::", error);
        }); 
    }
    
    creatDeal(recordInput){
        createRecord(recordInput)
            .then(deal => {
                // console.log('dealid: ',deal);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.LWCCreateSingleDeal16,
                        message: this.label.LWCCreateSingleDeal15,
                        variant: 'success',
                    }),
                );
                //this.redirectToHome(); //MN-07012022-US-0010947
                this.redirectToFutureDeals(); //MN-07012022-US-0010947
            })
            .catch(error => {
                // console.log('Error - createDeal: ',error)
                this.showLoadingSpinner = false;
                this.disableBtn = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.LWCCreateSingleDeal17,
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
                
            });
    }

    isNumeric(val) {//Loumang-11-01-2022:US-0010959
        return /^-?[\d]+(?:e-?\d+)?$/.test(val);
    }
    checkPriceFormat(val, index0, index1) {//Loumang-11-01-2022:US-0010959
        val = val+'';
        var arrVal = val.split(",");
        //console.log('la arrVal::',arrVal);
        if(arrVal.length == 2 && (this.isNumeric(arrVal[0]) && arrVal[0]).length <= index0 && this.isNumeric(arrVal[1]) && (arrVal[1]).length <= index1){
            return true;
        } else if ( arrVal.length < 2 && this.isNumeric(arrVal[0]) && (arrVal[0]).length <= index0){
            return true;
        } else {
            return false;
        }
    }
    
}