/*********************************************************************************************************************************
@ Author:         Sovantheany Dim
@ Purpose:        US-0010998 - [SP] Refactor Bulk Upload Component per Region
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.01.2022 / Sovantheany Dim / Created the component.
@               : 24.10.2022 / Bora Chhorn / US-0012600 - Enable Link Multiple Accounts for NA/ AU Portal Sellers
@               : 15.03.2023 / Sambath Seng / US-0013185 - AU - Deals Bulk Upload pages to match the design and function as Coupon
*********************************************************************************************************************************/
import {LightningElement, api, track, wire} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';//SB 15.03.2023 US-0013185

// import doLoadSetting from '@salesforce/apex/ClsBulkUploadCSV.doLoadSetting'; //MN-26042022-US-0010950 - Using individual method for DE instead
import doLoadSetting from '@salesforce/apex/ClsBulkUploadCSV.doLoadSettingLinkedAccount'; //MN-26042022-US-0010950 - Using individual method for DE instead //BR-24-10-22-US-0012600
import getDealRetailCampaign from '@salesforce/apex/ClsBulkUploadCSV.getDealRetailCampaign';
import getDealOverlapDateDRC from '@salesforce/apex/ClsBulkUploadCSV.getDealOverlapDateDRC';
import getSelectedCategories from '@salesforce/apex/CustomDealController.getSelectedCategories';//Sambath Seng - 13/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
import doSubmitMultipleDeals from '@salesforce/apex/ClsBulkUploadCSV.doSubmitMultipleDeals';

import bulkUploadDealTemplateDE from '@salesforce/resourceUrl/SEP_Bulk_Upload_Deal_Template_DE'; //MN-14122021-US-0010945//TH:21032022:US-0011516 - DE - Bulk Upload Component Configuration

import LWCBulkUploadCSVError1 from '@salesforce/label/c.LWCBulkUploadCSVError1';
import LWCBulkUploadCSVError2 from '@salesforce/label/c.LWCBulkUploadCSVError2';
import LWCBulkUploadCSVError3 from '@salesforce/label/c.LWCBulkUploadCSVError3';
import LWCBulkUploadCSVError8 from '@salesforce/label/c.LWCBulkUploadCSVError8';
import LWCBulkUploadCSVError10 from '@salesforce/label/c.LWCBulkUploadCSVError10';
import LWCBulkUploadCSVError11 from '@salesforce/label/c.LWCBulkUploadCSVError11';
import LWCBulkUploadCSVError12 from '@salesforce/label/c.LWCBulkUploadCSVError12';
import LWCBulkUploadCSVError13 from '@salesforce/label/c.LWCBulkUploadCSVError13';
import LWCBulkUploadCSVError14 from '@salesforce/label/c.LWCBulkUploadCSVError14';
import LWCBulkUploadCSVError15 from '@salesforce/label/c.LWCBulkUploadCSVError15';
import LWCBulkUploadCSVError16 from '@salesforce/label/c.LWCBulkUploadCSVError16';
import LWCBulkUploadCSVError17 from '@salesforce/label/c.LWCBulkUploadCSVError17';
import LWCBulkUploadCSVError20 from '@salesforce/label/c.LWCBulkUploadCSVError20';
import LWCBulkUploadCSVError21 from '@salesforce/label/c.LWCBulkUploadCSVError21';
import LWCBulkUploadCSVError22 from '@salesforce/label/c.LWCBulkUploadCSVError22';
import LWCBulkUploadCSVError23 from '@salesforce/label/c.LWCBulkUploadCSVError23';
import LWCBulkUploadCSVError24 from '@salesforce/label/c.LWCBulkUploadCSVError24';
import LWCBulkUploadCSVError25 from '@salesforce/label/c.LWCBulkUploadCSVError25';
import LWCBulkUploadCSVError26 from '@salesforce/label/c.LWCBulkUploadCSVError26';
import LWCBulkUploadCSVError27 from '@salesforce/label/c.LWCBulkUploadCSVError27';
import LWCBulkUploadCSVError29 from '@salesforce/label/c.LWCBulkUploadCSVError29';
import LWCBulkUploadCSVError30 from '@salesforce/label/c.LWCBulkUploadCSVError30';
import LWCBulkUploadCSVError31 from '@salesforce/label/c.LWCBulkUploadCSVError31';
import LWCBulkUploadCSVError32 from '@salesforce/label/c.LWCBulkUploadCSVError32';
import LWCBulkUploadCSVError33 from '@salesforce/label/c.LWCBulkUploadCSVError33';
import LWCBulkUploadCSVError35 from '@salesforce/label/c.LWCBulkUploadCSVError35';
import LWCBulkUploadCSVError36 from '@salesforce/label/c.LWCBulkUploadCSVError36';
import LWCBulkUploadCSVError37 from '@salesforce/label/c.LWCBulkUploadCSVError37';
import LWCBulkUploadCSVError38 from '@salesforce/label/c.LWCBulkUploadCSVError38';
import LWCBulkUploadCSVError40 from '@salesforce/label/c.LWCBulkUploadCSVError40';
import LWCBulkUploadCSVError41 from '@salesforce/label/c.LWCBulkUploadCSVError41';
import LWCBulkUploadCSVError42 from '@salesforce/label/c.LWCBulkUploadCSVError42';
import LWCBulkUploadCSVError43 from '@salesforce/label/c.LWCBulkUploadCSVError43';
import LWCBulkUploadCSVError44 from '@salesforce/label/c.LWCBulkUploadCSVError44';
import LWCBulkUploadCSVError45 from '@salesforce/label/c.LWCBulkUploadCSVError45';//SRONG TIN:25-03-2022:US-0011338
import LWCCreateSingleSameEbayIdDuplicated from '@salesforce/label/c.LWCCreateSingleSameEbayIdDuplicated';
import LWC_Valid_Specail_Character from '@salesforce/label/c.LWC_Valid_Specail_Character';
import dealBulkUploadDE_ErrorMaxReach1 from '@salesforce/label/c.dealBulkUploadDE_ErrorMaxReach1';//SB 4-2-2022 US-0011030 - [SP - EU Deals] [Bug] Wrong error message shown when DRC limit reached
import dealBulkUploadDE_ErrorMaxReach2 from '@salesforce/label/c.dealBulkUploadDE_ErrorMaxReach2';//SB 4-2-2022 US-0011030 - [SP - EU Deals] [Bug] Wrong error message shown when DRC limit reached

import Cancel from '@salesforce/label/c.lwcCancelbtn';//Loumang:12-01-2022:US-0010747
import DealRecordsCreatedPartSuccess from '@salesforce/label/c.DealRecordsCreatedPartSuccess'
import RowNumber from '@salesforce/label/c.Row_Number';
import DealRecordsCreatedPartError from '@salesforce/label/c.DealRecordsCreatedPartError'//SB 21-2-2022 US-0011212 - Feedback - QA/BA/UAT/GCX
import DRC_Inline_info from '@salesforce/label/c.DRC_Inline_info'//SB 21-2-2022 US-0011212 - Feedback - QA/BA/UAT/GCX
import getLinkedAccSpDeal from '@salesforce/apex/CustomDealController.getLinkedAccSpDeal';  //Sophal 02-04-2022 US-0011156 - Restrict ability for Sellers to be able to create Deals - Linked Account
import PleaseSelectTheEBayAccount from '@salesforce/label/c.Please_select_the_eBay_Account';//BR 10-11-2022 US-0012600
import btn_back from '@salesforce/label/c.SEP_BACK_BUTTON';//SB 15.03.2023 US-0013185
import thank_You_message from '@salesforce/label/c.Thank_You_message';//SB 15.03.2023 US-0013185
import dealBulkUpload_HelpMessage from '@salesforce/label/c.dealBulkUpload_HelpMessage';//SB 24.03.2023 US-0013185

export default class DealBulkUploadDE extends NavigationMixin(LightningElement) {
    @api recordId;
    @api startDate;
    @api endDate;
    @api country;
    @api availableDeal;
    @api accountId;
    @api contactId;
    @api email;
    @api siteNumber;
    @api placeholder;
    @api placeholderSite;
    @api inputLabel;
    @api inputLabelSite;
    @api lbInputFile;
    @api labelBtnNext;
    @api deals = [];
    @api labelBtnSubmit;
    @api labelBtnDownloadTemplate;
    @api labelBtnDownloadSampleFile;
    @api lbTotalRecord;
    @api tabName = "";
    @api redirectToUrl = "";
    @api numberOfDealPerPk = 150;
    @api fullContactName;

    @track objMessageInfos = [];
    @track isUnableUpload = false;
    @track selectedVal = "";
    @track siteselectedVal = "";
    @track isNoFile = true;
    @track isReachLimit = false;
    @track isSomeFail = false;
    @track fileName = "";
    @track data = [];
    @track totalRec = 0;
    @track columns = [];
    @track isShowMessage = false;
    @track allMessageInfo = [];
    @track objMessageResult = {};
    @track existingItemIds = [];
    @track mSiteWithCategorys = {};
    @track maxDEDealLimitPerDay = 500;
    @track totalDealOfDEToday = 0;
    @track dd_DuplicateError = "";
    @track drcDE = {};
    @track openSeatsAvailable = 0;
    @track existingDEDealItemIds = [];
    @track mapErrorMessages = {};
    @track currUserLang = '';
    @track mRowIndex = {};
    @track showLoadingSpinner = false;
    @track isSomeError = false;
    @track dealsComplete = [];
    @track dealSaveResult = [];
    @track isInvalidFormat = false;
    @track isDefaultDrcId = false;//SB 25-2-2022 US-0011351 - Deal creation button on the DRC view page
    @track categoryValue = "";

    @track selectedSeperator = ';';//TH:21032022:Change from , to ; :US-0011516 - DE - Bulk Upload Component Configuration
    @track csvHeaderGerman1 = 'Angebotstitel,eBay-Artikelnummer,Stückzahl,Ihr Preis,Artikelzustand,Verfügbar ab,Kategorie,EAN,WOW! Format,Ihre Kommentare,Amazon-Link,Idealo-Link';
    @track csvHeaderGerman2 = '"Angebotstitel","eBay-Artikelnummer","Stückzahl","Ihr Preis","Artikelzustand","Verfügbar ab","Kategorie","EAN","WOW! Format","Ihre Kommentare","Amazon-Link,Idealo-Link"';

    @track requiredDealFields = ["EBH_eBayItemID__c", "EBH_DealPrice__c", "List_Price__c", "EBH_Quantity__c", "EBH_MaximumPurchases__c", "EBH_SellerPrice__c", "EBH_Dealdateearliestpossible__c", "EBH_ProductTitle__c"];
    @track validateFormatFields = ["EBH_eBayItemID__c", "EBH_DealPrice__c", "List_Price__c", "EBH_Quantity__c", "EBH_SellerPrice__c", "EBH_Dealdateearliestpossible__c", "EBH_ProductTitle__c", "EBH_EAN__c", "EBH_Category__c", "EBH_DealFormat__c", "Item_Condition__c", "EBH_AmazonLink__c", "EBH_IdealoLink__c"];

    @track isAccountSelectable = false;
    @track isAccountNoAccess = false;
    @track step = 0;
    mapLinkedAcc = {isHavingNoFullAccess : true};

    @track DealReadOnlyErrorMessage = '';
    fullAccess = 'Full Access';
    @track currentStep = 1;//SB 15.03.2023 US-0013185

    @track defaulColsGerman = [
        { label: '', fieldName: 'row_number', type: 'number', initialWidth: 50},
        { label: 'Status', fieldName: 'status', type: 'text',wrapText: true, initialWidth: 260, cellAttributes: { class: { fieldName: 'cls_status' } }},
        { label: 'Angebotstitel', fieldName: 'EBH_ProductTitle__c', type: 'text', initialWidth: 125},
        { label: 'eBay-Artikelnummer', fieldName: 'EBH_eBayItemID__c', type: 'text', initialWidth: 125},
        { label: 'Stückzahl', fieldName: 'EBH_Quantity__c', type: 'text', initialWidth: 125},
        { label: 'Ihr Preis', fieldName: 'EBH_SellerPrice__c', type: 'text', initialWidth: 125},
        { label: 'Artikelzustand', fieldName: 'Item_Condition__c', type: 'text', initialWidth: 125},
        { label: 'Verfügbar ab', fieldName: 'EBH_Dealdateearliestpossible__c', type: 'text', initialWidth: 125},
        { label: 'Kategorie', fieldName: 'EBH_Category__c', type: 'text', initialWidth: 125},
        { label: 'EAN', fieldName: 'EBH_EAN__c', type: 'text', initialWidth: 125},
        { label: 'WOW! Format', fieldName: 'EBH_DealFormat__c', type: 'text', initialWidth: 125},
        { label: 'Ihre Kommentare', fieldName: 'EBH_CommentfromSeller__c', type: 'text', initialWidth: 125},
        { label: 'Amazon-Link', fieldName: 'EBH_AmazonLink__c', type: 'text', initialWidth: 125},
        { label: 'Idealo-Link', fieldName: 'EBH_IdealoLink__c', type: 'text', initialWidth: 125}
    ];
    //Sambath Seng - 14/2/2022 - US-0011042 - [SP - EU Deals] Update Deals translations in Portal
    @track mDEItemConditionVal = { 
        "Neu" : "New",
        "Gebraucht" : "Used",
        "Refurbished" : "Refurbished",
        "Neu: Sonstige" : "New other" //MN-22052023-US-0013541
    };

    file;
    fileContent;
    fileReader;

    label = {LWCBulkUploadCSVError1, LWCBulkUploadCSVError2, LWCBulkUploadCSVError3,
        LWCBulkUploadCSVError8,LWCBulkUploadCSVError10,
        LWCBulkUploadCSVError11,LWCBulkUploadCSVError12,LWCBulkUploadCSVError13,LWCBulkUploadCSVError14,
        LWCBulkUploadCSVError15,LWCBulkUploadCSVError16,LWCBulkUploadCSVError17,
        LWCBulkUploadCSVError20,LWCBulkUploadCSVError21,LWCBulkUploadCSVError22,
        LWCBulkUploadCSVError23,LWCBulkUploadCSVError24,LWCBulkUploadCSVError25,LWCBulkUploadCSVError26,
        LWCBulkUploadCSVError27,LWCBulkUploadCSVError29,LWCBulkUploadCSVError30,
        LWCBulkUploadCSVError31,LWCBulkUploadCSVError32,LWCBulkUploadCSVError33,
        LWCBulkUploadCSVError35,LWCBulkUploadCSVError36,LWCBulkUploadCSVError37,
        LWCBulkUploadCSVError38,LWCBulkUploadCSVError40, LWCBulkUploadCSVError41,LWCBulkUploadCSVError42,
        Cancel, DealRecordsCreatedPartSuccess, RowNumber, LWC_Valid_Specail_Character, LWCBulkUploadCSVError43,
        LWCBulkUploadCSVError44,LWCBulkUploadCSVError45,dealBulkUploadDE_ErrorMaxReach1, dealBulkUploadDE_ErrorMaxReach2, DealRecordsCreatedPartError,
        DRC_Inline_info,LWCCreateSingleSameEbayIdDuplicated, PleaseSelectTheEBayAccount,
        btn_back,thank_You_message,dealBulkUpload_HelpMessage //SB 15.03.2023 US-0013185
    };

    @track selectedCategories = [];//Sambath Seng - 10/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
    //Sambath Seng - 13/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
    @wire(getSelectedCategories)
    getSelectedCategories({error, data}) {
        if (data) {
            data.forEach(category =>{
                this.selectedCategories.push(category);
            });
        }
    }

    get onShowLoadingSpinner() {
        return this.showLoadingSpinner;
    }

    get allObjMessageInfos(){
        return this.objMessageInfos;
    }
    get disableUploadFile(){
        return this.isUnableUpload || this.siteselectedVal == "" || this.accountId == undefined || this.accountId==""; //MN-26042022-US-0010950-Need to select account in order to upload
    }
    get disableNextBtn(){
        return (this.isNoFile || this.isDisableNextBtn); //MN-26042022-US-0010950-Need to select account in order to upload
    }
    get disableSubmitBtn() {
        return (this.isReachLimit || this.deals.length == 0);
    }
    get isShowTable(){
        return this.data.length > 0;
    }
    get totalRecord() {
        return this.totalRec;
    }
    get jsonData(){
        return this.data;
        // return this.mAllRecords[this.currentPage];//SB 15.03.2023 US-0013185
    }
    get showMessageResults() {
        var messageErrors = [];
        var totalSuccess = 0;        
        for(var i =0; i < this.allMessageInfo.length; i++){
            var obj = this.allMessageInfo[i];
            if(obj["cls_status"] == "cls_error") {
                messageErrors.push(obj["message"]);
            } else  totalSuccess++;
        }

        this.objMessageResult["isHasSuccess"] = (messageErrors.length == 0);
        this.objMessageResult["totalSuccess"] = totalSuccess;

        this.objMessageResult["isHasError"] = (messageErrors.length > 0);
        this.objMessageResult["lstError"] = messageErrors;
        return this.objMessageResult;
    }

    //SB 15.03.2023 US-0013185
    get step1(){
        return this.currentStep == 1;
    }

    get step2(){
        return this.currentStep == 2;
    }

    get step3(){
        return this.currentStep == 3;
    }


    connectedCallback() {

        // Sophal 02-04-2022 US-0011156 - Start Here
        this.step = 0;
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

            }if(result.status == 'ko'){
                console.log("error result.error == ", result.error);
            }

            
            
        }).catch(error => { 
            console.log("error getLinkedAccSpDeal == :", error);
        });

        // Sophal 02-04-2022 US-0011156 - Stop Here


        var params = this.getQueryParameters();
        this.recordId = params["recordId"];
        this.startDate = params["startDate"];
        this.endDate = params["endDate"];
        this.country = params["country"];
        this.doLoadCMT();
        //SB 1-3-2022 US-0011351 - Deal creation button on the DRC view page
        if(this.recordId){
            this.selectedVal = this.recordId;
        }


    }

    //SB 25-2-2022 US-0011351 - Deal creation button on the DRC view page
    get defaultDRC (){
        return this.recordId;
    }

    getQueryParameters() {
        var params = {};
        var search = location.search.substring(1);
        if (search) {
            params = JSON.parse('{"' + search.replace(/&/g, '","').replace(/=/g, '":"') + '"}', (key, value) => {
                return key === "" ? value : decodeURIComponent(value)
            });
        }
        return params;
    }

    doLoadCMT(){
        this.existingItemIds = [];
        doLoadSetting({dealReatilCampaingId : this.recordId, accountId: this.accountId})
        .then(result => {
            this.objMessageInfos = [];
            this.isSomeError = false;
            var status = "error";
            var msg = "";
            var objMsgInfo;
            if(result["status"] == "success"){
                this.dd_DuplicateError = result["dd_DuplicateError"];
                this.email = result["conEmail"];
                // this.accountId = result["accountId"]; //MN-26042022-US-0010950
                this.contactId = result["contactId"];
                this.fullContactName = result["fullContactName"];
                this.totalDealOfDEToday = (result["totalDealOfDEToday"] != undefined ? result["totalDealOfDEToday"] : 0);
                this.availableDeal = result.availableDeal;
                if(result["currUserLang"]) this.currUserLang = result["currUserLang"];
                this.mSiteWithCategorys = result["fieldDependencies"];
                var availableDealToday = this.maxDEDealLimitPerDay - this.totalDealOfDEToday;
                if(availableDealToday <= 0) {
                    this.isReachLimit = true;
                    this.isUnableUpload = true;
                    this.isNoFile = true;
                    this.isDisableNextBtn = true;
                    msg = this.label.LWCBulkUploadCSVError2;
                    objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
                } 
                //Start SB 25-2-2022 US-0011351 - Deal creation button on the DRC view page
                else if(this.recordId != undefined && result["drc"].EBH_OpenSeatsAvailable__c != undefined && result["drc"].EBH_OpenSeatsAvailable__c > 0 ){
                    this.isDefaultDrcId = true;
                    this.availableDeal = availableDealToday;
                    this.openSeatsAvailable = result["drc"].EBH_OpenSeatsAvailable__c;
                    var msgInfo = '';
                    if(this.availableDeal >= this.openSeatsAvailable){
                        msgInfo = this.label.LWCBulkUploadCSVError1.replace(" x "," "+ this.openSeatsAvailable +" "); 
                        this.availableDeal = this.openSeatsAvailable;
                    } else {
                        msgInfo = this.label.LWCBulkUploadCSVError1.replace(" x "," "+ this.availableDeal +" ");
                    }
                    objMsgInfo = {className : "cls_message-info", mainMsg : "INFORMATION -", detailMsg : msgInfo};
                //End SB 25-2-2022 US-0011351 - Deal creation button on the DRC view page
                }else {
                    this.availableDeal = availableDealToday;
                    var infoMsg = this.label.LWCBulkUploadCSVError38;
                    infoMsg = infoMsg.replace(" X ", " "+ this.availableDeal + " ");
                    infoMsg = infoMsg.replace(" x ", " "+ this.availableDeal + " ");
                    objMsgInfo = {className : "cls_message-info", mainMsg : "INFORMATION -", detailMsg : infoMsg};
                }
                this.doMapErrorMessages();
            }else {
                this.isReachLimit = true;
                msg = result["message"];
                objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : msg};
            }
            this.objMessageInfos.push(objMsgInfo);
            this.doLoadDealRetailCampaign();
        })
        .catch(error => { 
            console.log("first load ERROR::", error);
        }); 
    }

    doMapErrorMessages(){
        this.mapErrorMessages[this.dd_DuplicateError] = this.label.LWCBulkUploadCSVError16;
        //SCH: EBAY-413
        this.mapErrorMessages["EBH_ProductTitle__c-Required"] = this.label.LWCBulkUploadCSVError20; // Required Field - ProductTitle
        //this.mapErrorMessages["EBH_ProductTitle__c-Incorrect"] = this.label.LWCBulkUploadCSVError21; // Product Title needs shouldn't be more than 150 characters
        this.mapErrorMessages["EBH_ProductTitle__c-Incorrect"] = this.label.LWCBulkUploadCSVError44; // Product Title needs shouldn't be more than 80 characters // TH: 05/02/2022 : US-0011009 - Bug [ SP-EU Deals] - error message displayed incorrectly when Product Title >80
        this.mapErrorMessages["EBH_Dealdateearliestpossible__c-Required"] = this.label.LWCBulkUploadCSVError22; // Required Field - Available from Date
        this.mapErrorMessages["EBH_Dealdateearliestpossible__c-Incorrect"] = this.label.LWCBulkUploadCSVError23; // Available From Date cannot be in past
        this.mapErrorMessages["EBH_Quantity__c-Required"] = this.label.LWCBulkUploadCSVError25; // Required Field - Quantity
        this.mapErrorMessages["EBH_Quantity__c-Incorrect"] = this.label.LWCBulkUploadCSVError26; // Incorrect Format - Quantity
        this.mapErrorMessages["EBH_SellerPrice__c-Required"] = this.label.LWCBulkUploadCSVError27; // Required Field - Seller Price
        // this.mapErrorMessages["EBH_SellerPrice__c-Incorrect"] = this.label.LWC_Valid_Specail_Character;//Loumnag:2022-01-17:US-0010959
        this.mapErrorMessages["EBH_SellerPrice__c-Incorrect"] = this.label.LWCBulkUploadCSVError43;//SB 25-1-2022 US-0011042
        this.mapErrorMessages["EBH_EAN__c-Incorrect"] = this.label.LWCBulkUploadCSVError29; // Incorrect EAN - Only numeric values are allowed and cannot be lesser than 5 digits"
        this.mapErrorMessages["EBH_EAN__c-Required"] = this.label.LWCBulkUploadCSVError40; //Sambath Seng - 10/12/2021 - US-0010766 - [SP - EU Deals] Required EAN for some categories
        this.mapErrorMessages["EBH_Category__c-Incorrect"] = this.label.LWCBulkUploadCSVError24; // Incorrect => Category allowed are: List all the categories which are allowed for this particular Deal Site
        this.mapErrorMessages["EBH_DealFormat__c-Incorrect"] = this.label.LWCBulkUploadCSVError32; // Incorrect => Invalid value enterred for Deal Format, allowed values are: List the picklist values in the language"
        this.mapErrorMessages["EBH_eBayItemID__c-Required"] = this.label.LWCBulkUploadCSVError35; // Required Field - Item Id
        this.mapErrorMessages["EBH_eBayItemID__c-Incorrect"] = this.label.LWCBulkUploadCSVError36; // Incorrect => Invalid format - Item Id: Need to be 12 digits numeric value
        this.mapErrorMessages["Item_Condition__c-Incorrect"] = this.label.LWCBulkUploadCSVError33; // Incorrect => Invalid values: Item Condition - Allowed values are: New, Used or Refurbished"
        this.mapErrorMessages["EBH_AmazonLink__c-Incorrect"] = this.label.LWCBulkUploadCSVError30; // Incorrect => Invalid Format: Amazon URL, must start with http:// or https://
        this.mapErrorMessages["EBH_IdealoLink__c-Incorrect"] = this.label.LWCBulkUploadCSVError31; // Incorrect => Invalid Format: Idealo Link, must start with http:// or https://  
    }

    doLoadDealRetailCampaign(){
        getDealRetailCampaign({recordId : this.recordId})
            .then(result => {
                if(result["status"] == "success"){
                    this.dealRetailCampaign = result["dealRetailCampaign"];
                }
            })
    }

    handleSelectedChange(event){
        if((this.maxDEDealLimitPerDay - this.totalDealOfDEToday) <= 0) return;
        this.showLoadingSpinner = true;
        this.data = [];
        this.objMessageInfos = [];
        this.fileName = "";
        this.drcDE = event.detail["record"];
        this.selectedVal = event.detail["selectedVal"];
        this.isNoFile = true;
        this.isDisableNextBtn = true;
        this.deals = [];
        this.existingDEDealItemIds = [];
        this.availableDeal = this.maxDEDealLimitPerDay - this.totalDealOfDEToday;
        ///Command cuz of EBAY-719
        var objMsgInfo = {};
        if( this.selectedVal == undefined || this.selectedVal == "") {
            this.isReachLimit = false;
            this.isUnableUpload = false;
            if(this.availableDeal <= 0) {
                this.isUnableUpload = true;
                objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : this.label.LWCBulkUploadCSVError2};
            } else {
                var infoMsg = this.label.LWCBulkUploadCSVError38;
                infoMsg = infoMsg.replace(" X ", " "+ this.availableDeal + " ");
                infoMsg = infoMsg.replace(" x ", " "+ this.availableDeal + " ");
                objMsgInfo = {className : "cls_message-info", mainMsg : "INFORMATION -", detailMsg : infoMsg};
            }
            this.showLoadingSpinner = false;
        }else if(this.drcDE["EBH_OpenSeatsAvailable__c"] != undefined && this.drcDE["EBH_OpenSeatsAvailable__c"] > 0){
            this.isReachLimit = false;
            this.isUnableUpload = false;
            this.openSeatsAvailable = this.drcDE["EBH_OpenSeatsAvailable__c"];
            if(this.availableDeal >= this.openSeatsAvailable){
                var msgInfo = this.label.LWCBulkUploadCSVError1.replace(" x "," "+ this.openSeatsAvailable +" "); 
                this.availableDeal = this.openSeatsAvailable;
                objMsgInfo = {className : "cls_message-info", mainMsg : "INFORMATION -", detailMsg : msgInfo};//SB 23-2-2022 US-0011212 - Feedback - QA/BA/UAT/GCX
            } else {
                /* MN-22112021-US-0010731
                var infoMsg = this.label.LWCBulkUploadCSVError38;
                infoMsg = infoMsg.replace(" X ", " "+ this.availableDeal + " ");
                infoMsg = infoMsg.replace(" x ", " "+ this.availableDeal + " ");
                objMsgInfo = {className : "cls_message-info", mainMsg : "INFO", detailMsg : infoMsg};
                this.objMessageInfos.push(objMsgInfo);
                */
                
                //MN-22112021-US-0010731
                var msgInfo = this.label.LWCBulkUploadCSVError1.replace(" x "," "+ this.availableDeal +" "); 
                objMsgInfo = {className : "cls_message-info", mainMsg : "INFORMATION -", detailMsg : msgInfo}; //SB 23-2-2022 US-0011212 - Feedback - QA/BA/UAT/GCX
            }
            this.doLoadDealOverlapDateDRC();
        } else {
            this.isReachLimit = true;
            this.isUnableUpload = true;
            this.isNoFile = true;
            this.isDisableNextBtn = true;
            objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : this.label.LWCBulkUploadCSVError17};
            this.showLoadingSpinner = false;
        }
        this.objMessageInfos.push(objMsgInfo);
    }

    doLoadDealOverlapDateDRC(){
        getDealOverlapDateDRC({drcId : this.selectedVal, currUserLang : this.currUserLang})
        .then(result => {
            this.existingDEDealItemIds = [];
            if(result["status"] == "success"){
                var lstDeal = result["lstDeal"];
                for(var i = 0; i < lstDeal.length; i++){
                    var deal = lstDeal[i];
                    this.existingDEDealItemIds.push(deal["EBH_eBayItemID__c"]);
                }

                //MN-21122021-US-0011048 - Moved from doLoadCMT()
                var lstExistedDeal = result["lstExistedDeal"];
                for(var i = 0; i < lstExistedDeal.length; i++){
                    var deal = lstExistedDeal[i];
                    this.existingItemIds.push(deal["EBH_eBayItemID__c"]);
                }
            }
            this.showLoadingSpinner = false;
        })
        .catch(error => {
            this.showLoadingSpinner = false;
        }); 
    }

    handleSiteSelectedChange(event){
        if((this.maxDEDealLimitPerDay - this.totalDealOfDEToday) <= 0) return;

        this.data = [];
        this.objMessageInfos = [];
        var availableDealToday = this.maxDEDealLimitPerDay - this.totalDealOfDEToday;
        this.availableDeal = availableDealToday;
        if(this.availableDeal <= 0) {
            this.isUnableUpload = true;
            var objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : this.label.LWCBulkUploadCSVError2};
        } else {
            var infoMsg = this.label.LWCBulkUploadCSVError38;
            infoMsg = infoMsg.replace(" X ", " "+ this.availableDeal + " ");
            infoMsg = infoMsg.replace(" x ", " "+ this.availableDeal + " ");
            var objMsgInfo = {className : "cls_message-info", mainMsg : "INFORMATION -", detailMsg : infoMsg};
        }
        this.objMessageInfos.push(objMsgInfo);

        this.siteselectedVal = event.detail["selectedVal"];
        if(this.siteselectedVal !=="" && this.file != undefined && this.file.name!=""){
            this.isNoFile = false;
            this.isDisableNextBtn = false;
        }
    }

    //MN-26042021-US-0010950
    handleAccountChange(event) {

        // MN-09052021-US-0010950
        this.data = [];
        this.deals = [];
        this.file = null;
        this.fileName = '';
        this.isNoFile = true;
         

        let accId =  event.detail["selectedVal"];
        if(this.mapLinkedAcc['mapAccIdToFullAccess'][accId]){  // Sophal 02-04-2022 US-0011156
            this.accountId = accId;
            this.isAccountNoAccess = false;

            this.doLoadCMT();
        }else{
            this.accountId = accId;
            this.isAccountNoAccess = true;
        }

        

    }

    handleFilesChange(event) {
        this.isShowMessage = false;
        this.objMessageInfos = [];
        this.data = [];
        this.deals = [];
        if(event.target.files.length > 0) {
            if(this.siteselectedVal ==""){
                this.isNoFile = true;
                this.isDisableNextBtn = true;
            }else{
                this.isNoFile = false;
                this.isDisableNextBtn = false;
            }
            this.file = event.target.files[0];
            this.fileName = event.target.files[0].name;
        }
        //SB 15.03.2023 US-0013185
        this.handleClickUpload();
        this.currentStep++;
    }

    handleClickUpload(){

        this.objMessageInfos = [];
        this.allMessageInfo = [];
        this.objMessageResult = {};
        this.showLoadingSpinner = true;
        this.isShowMessage = false;
        let self = this;
        var reader = new FileReader();
        reader.readAsText(this.file, "UTF-8");
        reader.onload = function(evt) {
            self.fileContent =  evt.target.result;
            if(self.fileContent) self.csvReader();
        }
    }

    //Sambath Seng - 17/12/2021 - US-001766 - fixing bulk upload
    validateHeader(csvHeader, csvTemplate){
        var error = false;
        var csvTemplateArray = csvTemplate.split(',');
        if(csvHeader.length == csvTemplateArray.length){
            for(var i = 0; i<csvTemplateArray.length; i++){
                if(!csvHeader[i].startsWith(csvTemplateArray[i].substring(0,3))){
                    error = true;
                }
            }
        } else {
            error = true;
        }
        return error ? false : true;
    }

    csvReader(){
        try{
            this.isDisableNextBtn = true;
            this.isShowMessage = false;
            this.isSomeError = false;
            this.allMessageInfo = [];
            this.mRowIndex = {};
            var duplicateRows = [];
            var duplicateEbayIds = [];
            var mDuplicateRow = {};
            var ebayIds = [];
            this.totalRec = 0;
            this.isSomeFail = false;
            var allTextLines = this.CSVToArray();
            var csvHeader = allTextLines[0];
            let EBH_DealFormat = {
                "WOW! Angebot (Basket)": "Core",
                "WOW! Angebot": "Deal",
                "WOW! Angebot der Woche": "Featured",
                "WOW! Angebot des Tages": "Primary",
            };

            //Sambath Seng - 17/12/2021 - US-001766 - fixing bulk upload
            if(this.validateHeader(csvHeader,this.csvHeaderGerman1) || this.validateHeader(csvHeader,this.csvHeaderGerman2)){       
                var tempData = [];
                var tempDeals = [];
                var cols = this.defaulColsGerman;
                if((allTextLines[0]).length != cols.length - 2){
                    var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : this.label.LWCBulkUploadCSVError3};
                    this.objMessageInfos.push(objMsgInfo);
                    this.showLoadingSpinner = false;
                    return;
                }
                if(this.availableDeal > 0) this.isReachLimit = false;
                var index = 0;
                var tempMIndex = {};
                var mIdRowNum = {};
                var rowNumber = 0;
                var rowT = 0;
                var mAllRowNumber = {};
                for(var i = 1; i < allTextLines.length; i++) {
                    rowNumber++;
                    rowT++;
                    var msg = "";
                    var msgNumeric = "";
                    var isValueInvalidFormat = false;
                    this.isInvalidFormat = false;
                    var rowIncomplete = false;

                    var allCols = allTextLines[i];
                    if(allCols.length != cols.length-2) continue;
                    let deal = { "sobjectType": "EBH_Deal__c" };
                    var row = {};
                    row["id"] = i;
                    var isRowEmpty = true;
                    //var eanValue = "";//Sambath Seng - 10/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
                    for(var x= 0; x < allCols.length; x++) {
                        var colName = cols[x+2].fieldName;
                        var fieldType = cols[x+2]["type"];
                        if(colName == "status" || colName == "row_number") continue;
                        var val = allCols[x]? allCols[x] : "";
                        if(val != undefined && val != "" && val != " ") {
                            isRowEmpty = false;
                        }
                        row[colName] = val;
                        deal[colName] = val;
                        if(colName != "EBH_eBayItemID__c" && row[colName] == "" && this.requiredDealFields.includes(colName)){
                            msgNumeric += (msgNumeric==""? "" :", ") + this.mapErrorMessages[colName+"-Required"];
                            rowIncomplete = true;
                            continue;
                        }
                        if(this.validateFormatFields.includes(colName)){
                            var tempMsg = this.doValidateFormatFields(val, colName, deal, EBH_DealFormat);
                            if(tempMsg != "") msgNumeric += (msgNumeric==""? "" :", ") + tempMsg;
                            isValueInvalidFormat = this.isInvalidFormat;
                        }
                    }
                    var strRow = (allTextLines[i]).join();
                    if (allTextLines[i][0] != "" && (duplicateRows.includes(strRow) || isRowEmpty == true)){
                        if(!duplicateRows.includes(strRow)) duplicateRows.push(strRow);
                        rowT--;
                        rowNumber--;
                        continue;
                    }
                    row["row_number"] = rowNumber;
                    var itemId = allTextLines[i][1];
                    if(this.selectedVal != ""){
                        if(mAllRowNumber[itemId] == undefined) {
                            mAllRowNumber[itemId] = [rowNumber];
                        } else {
                            var allRowNum = mAllRowNumber[itemId];
                            allRowNum.push(rowNumber);
                            mAllRowNumber[itemId] = allRowNum;
                        }
                    }
                    
                    var objMsg = {"row_number" : i};
                    this.allMessageInfo.push(objMsg);
                    if(rowIncomplete || isValueInvalidFormat){
                        var errorMsg = "";
                        errorMsg = msgNumeric;
                        row["isNotOverrid"] = true;
                        row["status"] = errorMsg;
                        row["cls_status"] = "cls_error";
                        this.isSomeError = true;
                        objMsg["cls_status"] = "cls_error";
                        objMsg["message"] = "- " + this.label.RowNumber  + " " + rowNumber +". "+errorMsg;
                        tempData.push(row);
                        continue;
                    }
                    //check duplicate itemid in file
                    if(itemId != "" &&  ebayIds.includes(itemId) && this.selectedVal != "") {
                        if(!duplicateEbayIds.includes(itemId)) duplicateEbayIds.push(itemId);
                        mIdRowNum[itemId] = (mIdRowNum[itemId] == undefined?rowNumber : mIdRowNum[itemId]+","+rowNumber);
                        if(mDuplicateRow[itemId] != undefined ){
                            msg = this.label.LWCBulkUploadCSVError45;//this.label.LWCBulkUploadCSVError8.replace(" x ",mDuplicateRow[itemId] +","+ i+" ");
                        } else msg = this.label.LWCBulkUploadCSVError41;
                        row["status"] = msg;
                        row["cls_status"] = "cls_error";
                        this.isSomeError = true;

                        objMsg["cls_status"] = "cls_error";
                        objMsg["message"] = "- " + this.label.RowNumber  + " "+rowNumber+". "+ msg;
                        tempData.push(row);
                        continue;
                    }else {
                        mDuplicateRow[itemId] = rowNumber;
                        ebayIds.push(itemId);
                        duplicateRows.push(strRow);
                        msg = this.label.LWCBulkUploadCSVError10; //"Ready to Upload";
                        row["status"] = msg;
                        row["cls_status"] = "cls_success";

                        objMsg["cls_status"] = "cls_success";
                        objMsg["message"] = msg;
                        tempMIndex[index] = rowT-1;
                        
                        index++;
                    }
                    
                    
                    deal["EBH_BusinessName__c"] = this.accountId;
                    deal["Seller_Contact__c"] = this.contactId;
                    deal["Seller_Name__c"] = this.fullContactName;
                    //SCH: EBAY-720: Remove seller email field from Bulk upload. We also need to stamp the User.Contact.Email into the EBH_SellerEmail__c field on all bulk created deals.
                    deal["EBH_SellerEmail__c"] = this.email;
                    deal["EBH_Status__c"] = "New"; 
                    deal["EBH_DealPrice__c"] = deal["EBH_SellerPrice__c"];
                    if(this.selectedVal != ""){
                        deal["EBH_DealRetailCampaign__c"] = this.selectedVal;
                    }
                    if(this.siteselectedVal != ""){
                        deal["EBH_DealSiteId__c"] = this.siteselectedVal;
                    }
                    tempData.push(row);
                    tempDeals.push(deal);
                    // Start - SB 4-2-2022 US-0011030 - [SP - EU Deals] [Bug] Wrong error message shown when DRC limit reached
                    if(tempDeals.length > this.availableDeal){ // SB 23-2-2022 US-0011330 - Bulk Upload - Limit Error
                        this.isReachLimit = true;
                        // var errMsg = this.label.LWCBulkUploadCSVError11;
                        var errMsg = "";
                        if(Object.keys(this.drcDE).length !== 0 || this.isDefaultDrcId){//SB 25-2-2022 US-0011351 - Deal creation button on the DRC view page
                            if(this.openSeatsAvailable > this.availableDeal){
                                errMsg = this.label.dealBulkUploadDE_ErrorMaxReach1;
                            } else {
                                errMsg = this.label.dealBulkUploadDE_ErrorMaxReach2;
                            }
                        } else {
                            errMsg = this.label.dealBulkUploadDE_ErrorMaxReach1;
                        }
                        errMsg = errMsg.replace("{X}", this.availableDeal)
                        // End - SB 4-2-2022 US-0011030 - [SP - EU Deals] [Bug] Wrong error message shown when DRC limit reached
                        var objMsgInfo = {className : "cls_message-info cls_message-error", mainMsg : "ERROR", detailMsg : errMsg};
                        this.objMessageInfos.push(objMsgInfo);
                        tempDeals = [];
                        tempData = [];
                        break;
                    }
                }

                for(var i = 0; i < tempData.length; i++){
                    var ebayItem = tempData[i]["EBH_eBayItemID__c"];
                    if(tempData[i]["isNotOverrid"] != undefined && tempData[i]["isNotOverrid"] == true) continue;
                    if(ebayItem != "" && mAllRowNumber[ebayItem] != undefined) {
                        var allRowIds = mAllRowNumber[ebayItem];
                        if(allRowIds.length > 1) {
                            tempData[i]["cls_status"] = "cls_error";
                            var errMsg = this.label.LWCBulkUploadCSVError45;//this.label.LWCBulkUploadCSVError8.replace(" x ", " "+allRowIds.join()+" ")
                            tempData[i]["status"] = errMsg;
                            var objMsg1 = {"row_number": i+1};
                            objMsg1["cls_status"] = "cls_error";
                            objMsg1["message"] = "- " + this.label.RowNumber  + " "+(i+1)+". "+ errMsg;
                        
                            this.allMessageInfo[i] = objMsg1;

                            if(!duplicateEbayIds[ebayItem]) duplicateEbayIds.push(ebayItem); // 13.01.2023 / Sophal Noch / US-0012946 : fixed issue to show correct message when there are 2 duplicated ebayItemId Record and Second Record has format error.
                            
                        }
                    }
                }
                //cols[1]["initialWidth"] = this.isSomeError ? 360 : 200;
                var tDeals = [];
                var idx = 0;
                for(var i = 0; i < tempDeals.length; i++){
                    var ebayId = tempDeals[i]["EBH_eBayItemID__c"];
                    if(!duplicateEbayIds.includes(ebayId)){
                        tDeals.push(tempDeals[i]);
                        this.mRowIndex[idx] = tempMIndex[i];
                        idx++;
                    }
                }
                this.showLoadingSpinner = false;
                this.data = tempData;
                this.totalRec = tempData.length;
                this.columns = cols;

                //SB 15.03.2023 US-0013185
                // this.currentPage = 1;
                // this.listRecord = this.data;
                // this.onAssignRecords();

                var dealForUpload = this.label.LWCBulkUploadCSVError12;
                dealForUpload = dealForUpload.replace(" x ", " "+ tDeals.length + " ");
                if(tDeals.length > 0) {
                    var objMsgInfo = {className : 'cls_message-info cls_message-success', mainMsg : '', detailMsg : dealForUpload}; //' vailable deals in your file for upload!'};
                    this.objMessageInfos.push(objMsgInfo);
                    this.showLoadingSpinner = false;
                } else {
                    this.showLoadingSpinner = false;
                    var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : '', detailMsg : dealForUpload}; //' vailable deals in your file for upload!'};
                    this.objMessageInfos.push(objMsgInfo);
                    return;
                } 
                this.deals = tDeals;

            }else {
                this.showLoadingSpinner = false;
                var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : this.label.LWCBulkUploadCSVError13};// 'Invalid CSV format'};
                
                this.objMessageInfos.push(objMsgInfo);
            }
            this.showLoadingSpinner = false;
        }
        catch( err){
            this.showLoadingSpinner = false;
            var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : err.message};
            this.objMessageInfos.push(objMsgInfo);
        }
    }

    doValidateFormatFields(val, colName, deal,EBH_DealFormat){
        var tempMsg = "";
        var isValNumeric = this.isNumeric(val);
        if(colName == "EBH_eBayItemID__c" && val != ""){
            if(!isValNumeric || val.length != 12) {
                tempMsg = this.mapErrorMessages["EBH_eBayItemID__c-Incorrect"];
                this.isInvalidFormat = true;
            }
        }
        
        if (colName == "EBH_Quantity__c") {
            if(!isValNumeric || !this.isInt(val) || val.length > 18){
                tempMsg = (this.mapErrorMessages[colName + "-Incorrect"] != undefined? this.mapErrorMessages[colName + "-Incorrect"] : "");
                this.isInvalidFormat = true;
            }
        }
        if (colName == "EBH_SellerPrice__c") {
            if(!this.checkPriceFormat(val,16,2)) {
                tempMsg = (this.mapErrorMessages[colName + "-Incorrect"] != undefined? this.mapErrorMessages[colName + "-Incorrect"] : "");
                this.isInvalidFormat = true;
            } else {
                deal[colName] = val;
            }
        } 
        if (colName == "EBH_Dealdateearliestpossible__c") {
            if(val.includes("/") || val.includes(".") || val.includes("-")) {
                var dateParts = ( val.includes("/")? val.split("/") : (val.includes(".")? val.split(".") : val.split("-")));
                if(dateParts.length == 3 && dateParts[0] > 0 && dateParts[1] > 0 && dateParts[1] <= 12 && (dateParts[2]).length == 4){
                    var dt1 = new Date(+dateParts[2], dateParts[1] - 1, +dateParts[0]);
                    
                    var d = new Date();
                    d.setHours(0,0,0,0);
                    if(dt1 == undefined) {
                        // tempMsg = this.label.LWCBulkUploadCSVError37;
                        tempMsg = (this.mapErrorMessages[colName + "-Required"] != undefined? this.mapErrorMessages[colName + "-Required"] : ""); //SB 3-2-2022 US-0011042 fix showing wrong error message
                        this.isInvalidFormat = true;
                    } else if(dt1 < d) {
                        tempMsg = (this.mapErrorMessages[colName + "-Incorrect"] != undefined? this.mapErrorMessages[colName + "-Incorrect"] : "");
                        this.isInvalidFormat = true;
                    }
                } else {
                    tempMsg = this.label.LWCBulkUploadCSVError37;
                    this.isInvalidFormat = true;
                }
            } else {
                tempMsg = this.label.LWCBulkUploadCSVError37;
                this.isInvalidFormat = true;
            }

            if(!this.isInvalidFormat){
                deal[colName] = this.convertDateToString(val);
            }
        }

        //if (colName == "EBH_ProductTitle__c" && val.length > 150) {
        if (colName == "EBH_ProductTitle__c" && val.length > 80) {//TH:05/Feb/2022 : US-0011009 - Bug [ SP-EU Deals] - error message displayed incorrectly when Product Title >80
            tempMsg = this.mapErrorMessages[colName + "-Incorrect"];
            this.isInvalidFormat = true;
        } 

        //Start - Sambath Seng - 10/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
        if (colName == "EBH_EAN__c"){
            if (val != "" ) {
                if(!isValNumeric || val.length < 5) {
                    tempMsg = this.mapErrorMessages[colName + "-Incorrect"];
                    this.isInvalidFormat = true;
                }
            } else {
                 // TH :22/Feb/2022:US-0011268:move code into colName = "EBH_EAN__c", because csv Column is reOrdering
                 if(val == "" && this.categoryValue != "" && this.selectedCategories.includes(this.categoryValue)){
                    tempMsg = this.mapErrorMessages["EBH_EAN__c-Required"];
                    this.isInvalidFormat = true;//Sambath Seng - 28/1/2022 - US-0011042
                }
            }
        }
        //End - Sambath Seng - 10/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category

        if (colName == "EBH_Category__c" && this.siteselectedVal != "") {
            var allCatg = (this.mSiteWithCategorys[this.siteselectedVal] != undefined ? this.mSiteWithCategorys[this.siteselectedVal] : []);
            if(!allCatg.includes(val)) {
                tempMsg = (this.mapErrorMessages[colName + "-Incorrect"] != undefined? this.mapErrorMessages[colName + "-Incorrect"]+" '"+allCatg.join("' , '")+"'" : "");
                this.isInvalidFormat = true;
            }
            this.categoryValue = val;
            //Start - Sambath Seng - 10/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
           // TH :22/Feb/2022:US-0011268: move to if colName == "EBH_EAN__c" 
            /*if(eanValue == "" && this.selectedCategories.includes(val)){
                tempMsg = this.mapErrorMessages["EBH_EAN__c-Required"];
                this.isInvalidFormat = true;//Sambath Seng - 28/1/2022 - US-0011042
            }*/
            //End - Sambath Seng - 10/12/2021 - US-0010766 - [SP - EU Deals] EAN is required for specific Category
        } 

        if (colName == "EBH_DealFormat__c" && val != "") {
            if(Object.keys(EBH_DealFormat).includes(deal['EBH_DealFormat__c'])){
                deal['EBH_DealFormat__c'] = EBH_DealFormat[deal['EBH_DealFormat__c']];
            }else {
                tempMsg = (this.mapErrorMessages[colName + "-Incorrect"] != undefined? this.mapErrorMessages[colName + "-Incorrect"] : "");
                this.isInvalidFormat = true;
            }
        } 

        if (colName == "Item_Condition__c") {
            if(val == "" || this.mDEItemConditionVal[val] == undefined) {
                tempMsg = (this.mapErrorMessages[colName + "-Incorrect"] != undefined? this.mapErrorMessages[colName + "-Incorrect"] : "");
                this.isInvalidFormat = true;
            } else {
                deal[colName] = this.mDEItemConditionVal[val];
            }
        } 

        if (colName == "EBH_AmazonLink__c" && val != "") {
            if(!val.startsWith("http://") && !val.startsWith("https://")){
                tempMsg = (this.mapErrorMessages[colName + "-Incorrect"] != undefined? this.mapErrorMessages[colName + "-Incorrect"] : "");
                this.isInvalidFormat = true;
            }
        } 
        if (colName == "EBH_IdealoLink__c" && val != "") {
            if(!val.startsWith("http://") && !val.startsWith("https://")){
                tempMsg = (this.mapErrorMessages[colName + "-Incorrect"] != undefined? this.mapErrorMessages[colName + "-Incorrect"] : "");
                this.isInvalidFormat = true;
            }
        }
        return tempMsg;
    }

    chunkArray(myArray, chunk_size){
        var results = [];
    
        while (myArray.length) {
            results.push(myArray.splice(0, chunk_size));
        }
        
        return results;
    }

    isNumeric(val) {
        return /^-?[\d.]+(?:e-?\d+)?$/.test(val);
    }

    isInt(val) {
        var intRegex = /^-?\d+$/;
        if (!intRegex.test(val))
            return false;
    
        var intVal = parseInt(val, 10);
        return parseFloat(val) == intVal && !isNaN(intVal);
    }

    checkPriceFormat(val, index0, index1) {
        val = val.replace(".","/").replace(",",".");//LA-13-12-2021:US-0010738 - [SP - EU Deals] [Bug] Align Seller Price accepted values on Bulk upload with Single deal form
        var arrVal = val.split(".");
        if(arrVal.length == 2 && (this.isNumeric(arrVal[0]) && arrVal[0]).length <= index0 && this.isNumeric(arrVal[1]) && (arrVal[1]).length <= index1){
            return true;
        } else if ( arrVal.length < 2 && this.isNumeric(arrVal[0]) && (arrVal[0]).length <= index0){
            return true;
        } else {
            return false;
        }
    }

    convertDateToString(val1){
        var dateParts = ( val1.includes("/")? val1.split("/") : (val1.includes(".")? val1.split(".") : val1.split("-")));
        var dt1 = new Date(+dateParts[2], dateParts[1] - 1, +dateParts[0]);

        const date1 = dt1.getDate();
        const month1 = dt1.getMonth()+1;
        const year1 = dt1.getFullYear();
        return year1+"-"+ ( month1 < 10? "0"+month1 : month1) +"-"+ (date1 < 10 ? "0"+date1 : date1);
    }

    CSVToArray() {
        var objPattern = new RegExp(("(\\" + this.selectedSeperator + "|\\r?\\n|\\r|^)" +"(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" + "([^\"\\" + this.selectedSeperator + "\\r\\n]*))"), "gi");
        var arrData = [[]];
        var arrMatches = null;
        while (arrMatches = objPattern.exec(this.fileContent)) {
            var strMatchedDelimiter = arrMatches[1];
            if (strMatchedDelimiter.length && (strMatchedDelimiter != this.selectedSeperator)) {
                arrData.push([]);
            }
            if (arrMatches[2]) {
                var strMatchedValue = arrMatches[2].replace(new RegExp("\"\"", "g"), "\"");
            } else {
                var strMatchedValue = arrMatches[3];
            } 
            arrData[arrData.length - 1].push(strMatchedValue);
        }
        return (arrData);
    }

    handleClickSubmit() {
        this.showLoadingSpinner = true;
        this.dealsComplete = [];
        this.dealSaveResult = [];
        this.objMessageResult = {};
        this.objMessageInfos = []; 
        this.isSomeFail = false;
        this.message = "";
        this.currentStep++;// SB 15.03.2023 US-0013185
        this.onProccessUpload(this.deals);
        
    }

    onProccessUpload(lstDeal){
        // chunk list of deal to small size for pass into apex
        var arrAllDeals = this.chunkArray(lstDeal, this.numberOfDealPerPk);
        this.onSubmitMultipleDeals(arrAllDeals, 0, arrAllDeals.length);
    }

    onSubmitMultipleDeals(arrAllDeals, index, total){ 
        if( index < total && arrAllDeals[index]){ 
            doSubmitMultipleDeals({lstDeals: arrAllDeals[index], accountId: this.accountId})
            .then(result => {
                index++;
                if(result['status'] == 'success'){
                    var srList = result["srList"];
                    this.dealSaveResult = this.dealSaveResult.concat(JSON.parse(srList));
                    if(result["lstDeals"]){
                        this.dealsComplete = this.dealsComplete.concat(result["lstDeals"]);
                    }
                    else {
                        this.isSomeFail = true;
                        this.message = result['message'];
                        if((this.message).includes("FIELD_CUSTOM_VALIDATION_EXCEPTION, There are non-cancelled deals with same Listing ID") ){
                            this.message = this.label.LWCBulkUploadCSVError14; //"One of the items included in this upload has already been submitted for this deal period. ";
                        }
                        //One of the items included in this upload has already been submitted for this deal period.
                        if((this.message).includes("FIELD_CUSTOM_VALIDATION_EXCEPTION, Listing ID must be numeric and 12 characters in length") ){
                            this.message = this.label.LWCBulkUploadCSVError42;
                        }
                        if((this.message).includes("Cannot deserialize instance of")){
                            this.message =result['message'];
                        }
                    }
                    
                }
                
                if (index < total) {
                    this.onSubmitMultipleDeals(arrAllDeals, index, total);
                }
                else if(!this.isSomeFail && index == total){
                    this.onUpdateStatus();
                }
                
            })
            .catch(error => {
                this.isSomeFail = true;
                this.message = (error["body"] != undefined? error.body.message : error);
                //"You have entered your data incorretcly, please try again."
                this.message = (this.message=="Unable to read SObject's field value[s]"? this.label.LWCBulkUploadCSVError15 : this.message);
                var objMsgInfo = {className : 'cls_message-info cls_message-error', mainMsg : 'ERROR', detailMsg : this.message};
                this.objMessageInfos.push(objMsgInfo);
                //SB 15.03.2023 US-0013185
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
    }

    onUpdateStatus() {
        this.isShowMessage = true;
        var allSaveResult = this.dealSaveResult;
        var totalSuccess = 0;//SB 17.03.2023 US-0013185
        for(var i = 0; i < allSaveResult.length; i++){
            var index = this.mRowIndex[i];
            if(allSaveResult[i]["success"] == false) {
                this.isSomeError = true;
                this.allMessageInfo[index]["cls_status"] = "cls_error";
                var msg = "";
                var errors = allSaveResult[i]["errors"];
                for(var x = 0; x < errors.length; x++){
                    msg += (msg==""? "":", ") + errors[x]["message"];
                }

                if(this.dd_DuplicateError != undefined && this.dd_DuplicateError != "" && this.mapErrorMessages[this.dd_DuplicateError] != undefined && msg.startsWith(this.dd_DuplicateError)){
                    msg = this.mapErrorMessages[this.dd_DuplicateError];
                }

                this.allMessageInfo[index]["message"] = "- " + this.label.RowNumber  + " "+(index+1)+". "+msg+"\n";
            } else totalSuccess++;//SB 17.03.2023 US-0013185  
        }

        //SB 16.03.2023 US-0013185
        if(totalSuccess > 0){
            // Show success toast when deals create
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.thank_You_message,
                    variant: 'success'
                })
            );
        }
        
        if(this.isSomeError == false) {
            this.redirectToFutureDeals();
        }
        this.data = [];
        this.objMessageInfos = []; 
        this.doLoadCMT();
        this.showLoadingSpinner = false;
    }

    redirectToFutureDeals() {
        if(this.redirectToUrl != ""){
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                    url: this.redirectToUrl + (this.tabName !=""? "?"+ this.tabName : "") //'/ebh-deal/EBH_Deal__c/Default' + (this.tabName !=""? "?"+ this.tabName : "")
                }
            });
        }else {
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'home'
                },
            });
        }
    }

    doDownloadCSVTemplate(){
        let downloadElement = document.createElement('a');
        downloadElement.href = bulkUploadDealTemplateDE;  //MN-14122021-US-0010945- Download the DE Template via Static Resource
        downloadElement.target = '_self';
         // CSV File Name
         downloadElement.download = "Vorlage zum Hochladen von gebündelten WOW! Angeboten.csv"; 
         // below statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click(); 
    }

    cancelhandler() {
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: '/my-deal-lists'
            }
        });
        
    }

    get isStep0()
    {
        return this.step==0;
    }
    get isStep1()
    {
        return this.step==1;
    }

    //SB 15.03.2023 US-0013185
    handleBack() {
        this.objMessageInfos = [];
        this.fileName = "";
        this.file = null;
        this.data = [];
        this.deals = [];
        this.mAllRecords = {};
        this.currentStep--;
    }

    handleBackToFirstStep() {
        this.objMessageInfos = [];
        this.fileName = "";
        this.file = null;
        this.data = [];
        this.deals = [];
        this.mAllRecords = {};
        this.currentStep = 1;
    }

    // @track allRecords = [];
    // @track mAllRecords = {}
    // @api listRecord = [];
    // @track numberOfRecordPerPage=50;
    // @track totalPage = 0;
    // @track currentPage = 1;

    // onAssignRecords(){
    //     this.mAllRecords = {};
    //     var allRecord = [];
    //     var numPage = 0;
    //     var index = 0;
    //     for(var i =0; i< this.listRecord.length; i++){
    //         var obj = this.listRecord[i]; //{"is_Checked" : false, "index" : i, "id" : i,"EBH_ProductTitle__c" : "Test-"+i, "EBH_Status__c" : "PENDING", "EBH_DealStartDate__c" : Date.now(),"EBH_eBayLink__c" : "122345"+i,  "EBH_DealEndDate__c" : Date.now(), "EBH_Quantity__c" : 123, "EBH_SoldItems__c" : "1234","EBH_Category__c" : "Home Electronics"};
            
    //         obj["index"] = index;
    //         allRecord.push(obj);
    //         index++;
    //         if(allRecord.length == this.numberOfRecordPerPage){
    //             numPage++;
    //             this.mAllRecords[numPage] = allRecord;
    //             allRecord = [];
    //             index = 0;
    //         }
    //     }
    //     if(allRecord.length > 0){
    //         numPage++;
    //         this.mAllRecords[numPage] = allRecord;
    //     }

    //     this.totalPage = numPage;

    //     if (this.currentPage > this.totalPage) this.currentPage=1;
        
    //     this.allRecords = (this.mAllRecords[this.currentPage]? this.mAllRecords[this.currentPage]:[]);

    // }

    // updateCurrentPage(event)
    // {
    //     this.currentPage = event.detail.currentPage;
    // }
    
}