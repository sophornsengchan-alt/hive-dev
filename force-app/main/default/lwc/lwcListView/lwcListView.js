/**
 * change log: 31/08/2022/vadhanak voun/US-0012297 - BETA Feedback
 *          : 27/10/2022/vadhanak voun/US-0012853 - Pagination - Seller Portal Changes
 *          : 22/05/2023 / Sambath Seng / US-0013450 - 2. Deal Contract agreement page/ Approve and Decline Actions: Seller Portal
 *          : 09/06/2023 / Sambath Seng / US-0013316 - Cancelled Items - Seller Portal
 */
import { LightningElement, api, track,wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAllSetting from '@salesforce/apex/ClsListViewController.getAllSetting';
//import initLocalCode from '@salesforce/apex/ClsListViewController.initLocalCode';
import getSearchResult from '@salesforce/apex/ClsListViewController.getSearchResult';
import doUpdateContact from '@salesforce/apex/ClsListViewController.doUpdateContact';
import getMtdObjectName from '@salesforce/apex/ClsListViewController.getMtdObjectName';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
//import { updateRecord } from 'lightning/uiRecordApi';
// import PortalDisplayDensity_FIELD from '@salesforce/schema/Contact.Portal_Display_Density__c'; //MN-02122021-US-0010808
import ID_FIELD from '@salesforce/schema/Contact.Id';

import updateInterest from '@salesforce/apex/ClsListViewController.updateInterest';
import updateNotInterest from '@salesforce/apex/ClsListViewController.updateNotInterest';
// import CouponSellerStage_FIELD from '@salesforce/schema/Coupon_Seller__c.Coupon_Seller_Stage__c';
// import CouponSeller_ID_FIELD from '@salesforce/schema/Coupon_Seller__c.Id';
// import SellerDeclinedReasons_FIELD from '@salesforce/schema/Coupon_Seller__c.Seller_Declined_Reasons__c';

import next from '@salesforce/label/c.Next'; 
import prev from '@salesforce/label/c.Previous';

//MN-21022022-US-0011309
import { subscribe, MessageContext } from 'lightning/messageService';
import LWC_CONNECTION_CHANNEL from '@salesforce/messageChannel/LWC_Connection__c';
// SB 5-4-2022 US-0011579 - Read Only Access to Deals
import {getFieldValue, getRecord} from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import SP_DEALS_FIELD from '@salesforce/schema/User.Contact.Account.SP_Deals__c';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import SPMAINDOMAIN_FIELD from '@salesforce/schema/User.SPMainDomain__c'; //MN-10062024-US-0015298
import lblFilterDeal from '@salesforce/label/c.Filter_Deal';
import SEP_Domain_DE from '@salesforce/label/c.SEP_Domain_DE'; //MN-10062024-US-0015298
import SEP_Domain_FR from '@salesforce/label/c.SEP_Domain_FR'; //MN-10062024-US-0015298
import SEP_Domain_IT from '@salesforce/label/c.SEP_Domain_IT'; //MN-10062024-US-0015298
import SEP_Domain_UK from '@salesforce/label/c.SEP_Domain_UK'; //MN-10062024-US-0015298

export default class LwcListView extends LightningElement {
    label = {next, prev, lblFilterDeal, 
        SEP_Domain_DE, //MN-10062024-US-0015298
        SEP_Domain_FR, //MN-10062024-US-0015298
        SEP_Domain_IT, //MN-10062024-US-0015298
        SEP_Domain_UK //MN-10062024-US-0015298
    };

    @api sObjectName = '';
    @api mdtName = "";
    @api site;
    @api lbDensity = "Density";
    @api isShowDensity = false; //MN-02122021-US-0010808
    @api messageNoRecord = "";
    @api listRecord = [];
    //@track displayMode = "Low"; //MN-02122021-US-0010808
    @track highlightFields = {};
    @track detailFields = {};
    @track allRecords = [];
    @track mAllRecords = {};
    @track numberOfRecordPerPage=25;
    @track totalPage = 0;
    @track currentPage = 1;
    @track currentPageBefore = 1;
    @track isLoadRecord = false;
    @track userDisplayMode = {};
    @api isAsc = false;
    @api isDsc = false;

    @api isShowBtnIntr;
    @api lbButtonIntr = "";
    @api lbButtonNotIntr = "";

    @api isCheckBox;

    @api isDisableSearch;
    @api isDisableFilter; //MN-23052022-US-0010437 - To control filter feature

    //@track localCode = 'en';
    @track sortedDirection = 'asc';
    @track sortedColumn;
    @api searchKey = "";
    settingName = this.mdtName;
    refreshResult;
    @api filter=""; //MN-13052022-US-0010437-Add "@api" so that we can assign value to this variable from another lwc 
    filterCheck=false;
    filterObjectName='';
    //@track error = {};
    @api optionalId = ""; //SB 09.06.2023 US-0013316

    @track lstResult = [];
    @track isLoading = false;
    selectedRecordIds = new Set();

    subscription = null; //MN-21022022-US-0011309
    @track spDealsValue;//SB 5-4-2022 US-0011579 - Read Only Access to Deals 
    readyOnlyRestrict = ['DE_Rejected_Deals_Resubmit'];//SB 5-4-2022 US-0011579 - Read Only Access to Deals 
    fields = [SP_DEALS_FIELD, PROFILE_NAME_FIELD, SPMAINDOMAIN_FIELD]; //MN10062024-US-0015298: Add SPMainDomain__c field
    @track profileName = '';
    @track spMainDomain; //MN-10062024-US-0015298
    //NK:31/08/2022:US-0012297
    @api fieldsNoLink = []; //list of field that will ignore hyperlink and display as normal text

    @track VISIBLE_PAGE = 4;    //4 numbe per visibile (exculded first and end)
    @track VISIBLE_PAGE_PREBACK = 1; //1 page number to click back
    @track VISIBLE_PAGE_START = 0;
    @track VISIBLE_PAGE_END = 0;
    isLoadingListView = false; //MN-13012023-US-0013034 
    isLoadingFilter = false;//TH:US-0016318:18/02/2025
    //NK:07/11/2022:US-0012034/	allow header ovrride. e.g. escape user lang translation
    @api mapColHeaderOveride;   //{"Item_ID__c":"Item ID","Item_Title__c": "Item Name","Co_Invest__c":"Seller Share(%*)"}
    @api paginatorLabelOverride;//{"next":"new label","prev":"new label","goto":"new label"}

    recTypeId;//TH:US-0016318
    hierarchyRelationshipName;//LM:US-0033386

    // SB 5-4-2022 US-0011579 - Read Only Access to Deals 
    @wire(getRecord, {recordId: userId, fields: '$fields'})
    getUser({error, data}){
        if(data){
            this.spDealsValue = getFieldValue(data, SP_DEALS_FIELD);
            this.profileName = getFieldValue(data, PROFILE_NAME_FIELD);
            this.spMainDomain = getFieldValue(data, SPMAINDOMAIN_FIELD); //MN-10062024-US-0015298
        }
    }

    showSuccessToast() {
        const evt = new ShowToastEvent({
            title: 'Success:',
            message: 'Opearion sucessful',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    showErrorToast() {
        const evt = new ShowToastEvent({
            title: 'Error:',
            message: 'Some unexpected error',
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
    
    showInfoToast() {
        const evt = new ShowToastEvent({
            title: 'Info',
            message: 'Please select at least 1 record.',
            variant: 'info',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }


    connectedCallback() {

        this.subscribeToMessageChannel(); //MN-21022022-US-0011309 - to refresh handler that called from external lwc using pub/sub messageChannel

        // this.reloadPage();
        if(this.isLoadRecord) return;
        
         
        //this.settingName = this.mdtName;//TH:25/11/2021:US-0010793 : move this to @wire : need to finish loadAllRecords first before continue @wire
        //this.loadLocalCode();  
        this.loadAllRecords();

	}

    //MN-21022022-US-0011309
    @wire(MessageContext)
    messageContext;
    subscribeToMessageChannel() {
        this.subscription = subscribe(
        this.messageContext,
        LWC_CONNECTION_CHANNEL,
        (message) => this.handleMessage(message)
        );
    }

    //MN-21022022-US-0011309
    handleMessage(message) {
        // console.log('***** pub/sub message channel :: ', message);
        if(message.action == 'refresh') {
            refreshApex(this.wiredSearchResult);
        }
    }

    /*loadLocalCode(){
        initLocalCode()
        .then(result => {
            this.localCode = result;
        })
        .catch(error => { 
            console.log("load initLocalCode ERROR:", error);
        }); 
    }*/
    loadAllRecords() {
        
        // console.log('SRO:log:::',this.mdtName);
        getAllSetting({mdtName : this.mdtName})
        .then(result => {
            this.highlightFields = result["highlightFields"];
            this.detailFields = result["detailFields"];
            this.numberOfRecordPerPage = result["numberOfRecordsPerPage"];

            this.sObjectName = result["sObjectName"]; // Samnang MUONG:25-10-2021 
            this.recTypeId = result.recordTypeId;//TH:US-0016318
            /* MN-02122021-US-0010808
            this.userDisplayMode = result["userDisplayMode"];
            if(this.userDisplayMode["ContactId"]) {
                this.displayMode = (this.userDisplayMode["Contact"]["Portal_Display_Density__c"]? this.userDisplayMode["Contact"]["Portal_Display_Density__c"] : "High");
            } else this.displayMode = "High";
            */
            //this.listRecord = result["listRecord"];
            this.currentPage = 1;
            this.currentPageBefore=1;
            this.settingName = this.mdtName; //TH:US-0010793: move from connectedCallback
            return refreshApex(this.refreshResult);
            
            
            
        })
        .catch(error => { 
            
            console.log("first load ERROR::", error);
            
        });
    }
        
    handleKeyChange(evt) {
        this.searchKey = evt.target.value;
        this.settingName = this.mdtName;
        // console.log('TEST');
        return refreshApex(this.refreshResult);
    }
    
    //MN-17122021-US-0010961 
    renderedCallback() { 
        refreshApex(this.wiredSearchResult); //MN-17122021-US-0010961 - this will make record refresh correctly when each tab is active
    }

    @track wiredSearchResult; //MN-17122021-US-0010961 - This wired variable that we will using it with refreshApex whenever we want to refresh wired data on screen
    @wire(getSearchResult, { searchKey: '$searchKey', settingName: '$settingName',filter: '$filter',optionalId: '$optionalId'})//, originalQuery: '$originalQuery',  searchConditionFields: '$searchConditionFields', orderAndLimit : '$orderAndLimit'})
    someFunction(result){ //MN-17122021-US-0010961 - using "result" as return from APEX so that the refreshAPEX will work properly because refreshAPEX doesn't work when we return value from APEX as {error, data}
        // console.log("$$$$$$ wire getSearchResult!!!", result);
        this.isLoadingListView = true; //MN-13012023-US-0013034
        this.wiredSearchResult = result; //MN-17122021-US-0010961
        if(result.data){
            if(result.data["listRecord"]){
                var jsonLstRec = JSON.stringify(result.data["listRecord"]);
                this.listRecord = JSON.parse(jsonLstRec);
                this.onAssignRecords();
            } else this.listRecord = [];
            this.hierarchyRelationshipName = result.data['hierarchyRelationshipName'];//LM:US-0033386

            //LA-29-06-2022-US-0011917 
            const hasRecordEvent = new CustomEvent(
                "listviewhasrecord", {
                    bubbles : true,
                    composed : true,
                    detail : {isHasRecord : this.isHasRecord, metadataName: this.mdtName}
                });
            this.dispatchEvent(hasRecordEvent);
            
            this.isLoadingListView = false; //MN-13012023-US-0013034 
            
        }
    }


    /* //MN-17122021-US-0010961 - Use above method instead
    //searchKey, String query, String conditions, String seachFilters, String order, String maxLimit
    //@wire(getSearchResult, { searchKey: '$searchKey', query: '$query', conditions: '$conditions', seachFilters: '$seachFilters', order: '$order', maxLimit: '$maxLimit'})//, originalQuery: '$originalQuery',  searchConditionFields: '$searchConditionFields', orderAndLimit : '$orderAndLimit'})
    @wire(getSearchResult, { searchKey: '$searchKey', settingName: '$settingName',filter: '$filter'})//, originalQuery: '$originalQuery',  searchConditionFields: '$searchConditionFields', orderAndLimit : '$orderAndLimit'})
    someFunction({ error, data }){

        if(data){
            if(data["listRecord"]){
                var jsonLstRec = JSON.stringify(data["listRecord"]);
                this.listRecord = JSON.parse(jsonLstRec);
                //var tab1 = this.template.querySelector('.tabHeader');
                //tab1.innerHtml = '<p>Test</p>';
                this.onAssignRecords();
            } else this.listRecord = [];
            
        }
    }
    */
    
    //SB 5-4-2022 US-0011579
    get isHasRecord(){

        /* MN-10062024-US-0015298 - No longer use profile name
        if(this.profileName == 'DE - Seller Portal' && this.spDealsValue == 'Read Only' && this.readyOnlyRestrict.includes(this.mdtName)){
            return false;
        } else {
            return this.allRecords.length > 0;
        }
        */
       
        if((this.spMainDomain == this.label.SEP_Domain_DE || this.spMainDomain == this.label.SEP_Domain_IT || this.spMainDomain == this.label.SEP_Domain_UK || this.spMainDomain == this.label.SEP_Domain_FR) 
            && this.spDealsValue == 'Read Only' && this.readyOnlyRestrict.includes(this.mdtName)){
            return false;
        } else {
            return this.allRecords.length > 0;
        }
    }
    /*get lbDensity(){
        var mDensity = {'en' : 'Density', 'de' : 'Dichte', 'km' : 'ដង់ស៊ីតេ'};
        return mDensity[this.localCode]? mDensity[this.localCode] : 'Density';
    }*/

    /* //MN-02122021-US-0010808
    get showDensity(){
        // return (this.isShowDensity == undefined ? true : this.isShowDensity);
        return (this.isShowDensity == undefined ? false : this.isShowDensity); //MN-02122021-US-0010808
    }
    */
    get classSearch(){
        //return "cls_search "+ (this.isShowDensity == false ? " cls_fullWidth ": "");
        //return "cls_search cls_fullWidth "; //MN-02122021-US-0010808 //MN-23052022-US-0010437

        //MN-23052022-US-0010437 - When disable filter => display search box in full width 
        var tmp = "cls_search cls_fullWidth";
        if (this.isDisableFilter) tmp += " cls_disableFilter";

        return tmp;
        
    }
    
    /* //MN-02122021-US-0010808
    get activeMsg(){
        return (this.displayMode=="High"? "High" : "");
    }
    get inactiveMsg(){
        return (this.displayMode=="Low"? "Low" : "");
    }
    */ 
   
    /* //MN-02122021-US-0010808
    get isShowHigh(){
        return (this.displayMode == "High");
    }
    */
    // get displayPagination() {
    //     var arrPage = [];
    //     for(var i =1; i<= this.totalPage; i++){
    //         var objP = {value : i, clsActive : (this.currentPage == i?"active":"")};
    //         arrPage.push(objP);
    //     }
    //     return arrPage;
    // }
   
     
    updateCurrentPage(event)
    {
        this.currentPage = event.detail.currentPage;
    }
     
    get isAllChecked(){
        var lstRec = this.mAllRecords[this.currentPage];
        var isChecked = true;
        for(var i=0; i<lstRec.length; i++){
            if(!lstRec[i]["is_Checked"]) {
                isChecked = false;
                break;
            } 
        }
        return isChecked;
    }
    get displayRecords(){
        //this.allRecords = allRecord;
        //return this.allRecords;//this.allRecords;
        return this.mAllRecords[this.currentPage];
    }

    //NK:07/11/2022:US-0012034/	allow header ovrride. e.g. escape user lang translation
    get displayHighlightFields(){
        if(this.mapColHeaderOveride!=null && this.mapColHeaderOveride !=undefined)
        {
            for(let i=0;i<this.highlightFields.length;i++)
            {
               // console.log("fieldName",this.highlightFields[i].fieldName);
                if(this.mapColHeaderOveride.hasOwnProperty(this.highlightFields[i].fieldName))
                {
                    this.highlightFields[i].label = this.mapColHeaderOveride[this.highlightFields[i].fieldName]; //override label
                }
                
            }
        }

        return this.highlightFields;
    }
   

    get displayDetailFields(){   
        
        return this.detailFields;
    }

    onAssignRecords(){

        this.mAllRecords = {};
        var allRecord = [];
        var numPage = 0;
        var index = 0;
        for(var i =0; i< this.listRecord.length; i++){
            var obj = this.listRecord[i]; //{"is_Checked" : false, "index" : i, "id" : i,"EBH_ProductTitle__c" : "Test-"+i, "EBH_Status__c" : "PENDING", "EBH_DealStartDate__c" : Date.now(),"EBH_eBayLink__c" : "122345"+i,  "EBH_DealEndDate__c" : Date.now(), "EBH_Quantity__c" : 123, "EBH_SoldItems__c" : "1234","EBH_Category__c" : "Home Electronics"};
            
            obj["is_Checked"] = false;
            //obj["is_showdetail"] = false;
            obj["index"] = index;
            allRecord.push(obj);
            index++;
            if(allRecord.length == this.numberOfRecordPerPage){
                numPage++;
                this.mAllRecords[numPage] = allRecord;
                allRecord = [];
                index = 0;
            }
        }
        if(allRecord.length > 0){
            numPage++;
            this.mAllRecords[numPage] = allRecord;
        }

        this.totalPage = numPage;

        //MN-19052022-US-0010656
        if (this.currentPage > this.totalPage) this.currentPage=1;
        
        this.allRecords = (this.mAllRecords[this.currentPage]? this.mAllRecords[this.currentPage]:[]);

        var obj = {
            totalRecord : this.listRecord.length
        }
        const custEvent = new CustomEvent(
            "callupdatenumberofitems", {
                detail : obj
            });
        this.dispatchEvent(custEvent);

    }

    onPrevPage() {
        if(this.currentPage > 1) this.currentPage--;
    }

    onNextPage(){
        if(this.currentPage < this.totalPage) this.currentPage++;
    }

    onChangePage(evt) {
        //.dataset.id
        var pageNumber = evt.target.dataset["id"];
        this.currentPageBefore = this.currentPage;
        this.currentPage = pageNumber;
        //console.log("onChangePage before and after: ",this.currentPageBefore,this.currentPage);
    }

    sortColumns(event){
        var fieldName = event.detail["fieldName"];
        var isNumber = event.detail["isNumber"];
        var direction = event.detail["direction"];

        //this.mAllRecords[this.currentPage] = lstRec;

        this.sortData(fieldName, isNumber, direction);
        this.onAssignRecords();
    }

    updateCheckBox(event){
        var index = event.detail["index"];
        var lstRec = this.mAllRecords[this.currentPage]; 
        lstRec[index]["is_Checked"] = event.detail["ischecked"];        
        this.mAllRecords[this.currentPage] = lstRec;

        //MN-18052022-US-0010656 - Fired Event to handle checkbox box action from this lwc (child lwc) to parent lwc (lwc that called this component)-----
        var obj = {
            mAllRecords: this.mAllRecords,
            totalPage : this.totalPage
        }
        const custEvent = new CustomEvent(
            "callupdatecheckbox", {
                detail : obj
            });
        this.dispatchEvent(custEvent);
        //---------- MN-18052022-US-0010656


    }

    updateCheckBoxAll(event){
        var index = event.detail["index"];
        var lstRec = this.mAllRecords[this.currentPage];
        for(var i = 0; i < lstRec.length; i++){
            lstRec[i]["is_Checked"] = event.detail["ischecked"];            
        }
        
        this.mAllRecords[this.currentPage] = lstRec;

        //MN-18052022-US-0010656 - Fired Event to handle checkbox box action from this lwc (child lwc) to parent lwc (lwc that called this component)-----
        var obj = {
            mAllRecords: this.mAllRecords,
            totalPage : this.totalPage
        }
        const custEvent = new CustomEvent(
            "callupdatecheckbox", {
                detail : obj
            });
        this.dispatchEvent(custEvent);
        //---------- MN-18052022-US-0010656
    }





    handleCheckAll(evt){

        var lstRec = this.mAllRecords[this.currentPage];
        for(var i=0; i<lstRec.length; i++){
            lstRec[i]["is_Checked"] = evt.target.checked;
        }
        this.mAllRecords[this.currentPage] = lstRec;
    }
    
    // MN-02122021-US-0010808
    // changeToggle(){
    //     var objMode = {"High":"Low", "Low":"High"};
    //     this.displayMode = objMode[this.displayMode];
    //     if(this.userDisplayMode["ContactId"]) {
    //         const fields = {'sobjectType': 'Contact'};
    //         fields[ID_FIELD.fieldApiName] = this.userDisplayMode["ContactId"];
    //         fields[PortalDisplayDensity_FIELD.fieldApiName] = this.displayMode;
    //         const recordInput = { fields };
    //         doUpdateContact({con: fields})
    //         .then(result => {
    //         }).catch(error => { console.log('msgErr: ',error.body.message); });
    //         /*updateRecord(recordInput)
    //         .then(() => {
    //             console.log("Update Successful")
    //         })
    //         .catch(error => { 
    //         });*/
    //     }
        
    // }

    sortData(sortColumnName, isNumber, direction) {

        // check previous column and direction
        /*if (this.sortedColumn === sortColumnName) {
            this.sortedDirection = this.sortedDirection === 'asc' ? 'desc' : 'asc';
        } 
        else {
            this.sortedDirection = 'asc';
        }*/
        // this.sortedDirection = this.sortedDirection === 'asc' ? 'desc' : 'asc';
        this.sortedDirection = direction;
        // console.log('sortedDirection: ',this.sortedDirection)
        // check arrow direction
        if (this.sortedDirection === 'asc') {
            this.isAsc = true;
            this.isDsc = false;
        } 
        else {
            this.isAsc = false;
            this.isDsc = true;
        }

        // check reverse direction
        let isReverse = this.sortedDirection === 'asc' ? 1 : -1;

        this.sortedColumn = sortColumnName;
        // sort the data
        var sortAllRecord = JSON.parse(JSON.stringify(this.listRecord)).sort((a, b) => {
            if(isNumber){
                a = a[sortColumnName] ? a[sortColumnName] : ''; // Handle null values
                b = b[sortColumnName] ? b[sortColumnName] : '';
            } else {
                a = a[sortColumnName] ? a[sortColumnName].toLowerCase() : ''; // Handle null values
                b = b[sortColumnName] ? b[sortColumnName].toLowerCase() : '';
            }
            

            //if(isNumber) return (this.sortedDirection === 'asc' ?a - b : b - a);
            //else return a > b ? 1 * isReverse : -1 * isReverse;
            return a > b ? 1 * isReverse : -1 * isReverse;
        });
        this.listRecord = sortAllRecord;
    }

    doShowTast(title, message, variant,) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),

        );
    }

    // searchListView(event)
    // {
    //   this.filter=JSON.stringify(event.detail)
    //   console.log(this.filter);
    //   return refreshApex(this.refreshResult);
      
    // }

    
    searchListView(event)
    {
        
      let keyData = Object.keys(event.detail);
      let valueData = Object.values(event.detail);
      //TH:US-0013558
      var isInputBothStartEndDate = false;
      var keyData_strs = keyData.join(',');
      if((keyData_strs.includes('StartDate') || keyData_strs.includes('Start_Date')) && (keyData_strs.includes('EndDate') || keyData_strs.includes('End_Date'))){
          isInputBothStartEndDate = true;
      }
      //End US-0013558
      let queryData= '';
      keyData.forEach((element,index)=>{
        if((element.includes('StartDate') || element.includes('Start_Date'))){
            if(isInputBothStartEndDate) queryData+=' '+'AND'+' '+element+'>='+valueData[index]; //TH:US-0013558
            else queryData+=' '+'AND'+' '+element+'='+valueData[index];//TH: 31/01/2022:US-0011019
        }else if((element.includes('EndDate') || element.includes('End_Date'))){
            if(isInputBothStartEndDate) queryData+=' '+'AND'+' '+element+'<='+valueData[index]; //TH:US-0013558 
            else queryData+=' '+'AND'+' '+element+'='+valueData[index];//TH: 31/01/2022:US-0011019
        }else if(element.includes('Date__c') && !element.includes('Start_Date') && !element.includes('StartDate') && !element.includes('EndDate') && !element.includes('End_Date')){
            queryData+=' '+'AND'+' '+element+'='+valueData[index];
        }
        // Start SB 09.06.2023 US-0013316
        else if (valueData[index].includes(';')) {
            let multiVal = valueData[index].split(';');
            queryData += ' AND ' + element + ' IN (';
            multiVal.forEach((data, idx, array) => {
                queryData += '\'' + data + '\'';
                // make sure comma is not add to last iteration
                if(idx != array.length - 1){
                    queryData += ',';
                }
            });
            queryData += ')';
        }
        // End SB 09.06.2023 US-0013316
        else{
            queryData+=' '+'AND'+' '+element+'='+'\''+valueData[index] +'\'';
        }

        // newFilter+=' AND Seller_Portal_Status__c='+'\''+filterData.status +'\'';
        // SB 23.05.2023 US-0013450
        if(element.includes('EBH_BusinessName__c')){
            const custEvent = new CustomEvent(
                "getselectedsellerid", {detail: valueData[index]});
            this.dispatchEvent(custEvent);
        }
      })
      //this.filter=JSON.stringify(queryData)
      this.filter=queryData;
      this.currentPage = 1;//TH: 03/02/2022 :US-0011019 - BUG [SP-EU Deals] - Display wrong deal record when set filter on start/end date
      return refreshApex(this.refreshResult);
      
    }

    filterHandler()
    {   
        if(this.filterCheck)
        {
           this.filterCheck=false;
        }

        else{
            this.isLoadingFilter = true;//TH:US-0016318:18/02/2025
            getMtdObjectName({ mdtName: this.settingName })
            .then(res => {
                if(res){
                    this.mdtName = this.settingName; //MN-26112021-US-0010838 
                    this.filterObjectName = res;                
                    this.filterCheck=true;
                    this.isLoadingFilter = false;//TH:US-0016318:18/02/2025
                }
            })
            .catch(error => {      
                console.log('error ::', error.body.message);
            });
        }

        


    }

    clearFilter()
    {
        this.filter='';
      return refreshApex(this.refreshResult);
    }

    //MN-17122021-US-0010961
    @api reloadPage() {
        refreshApex(this.wiredSearchResult);
    }

    getCheckedRecord()
    {
        this.lstResult = [];
        var lstRec = this.mAllRecords[this.currentPage];

        for(var i = 0; i < lstRec.length; i++){
            if(lstRec[i]["is_Checked"] == true){
                // console.log('lstRec[i]: ',lstRec[i]);
                this.lstResult = [...this.lstResult, lstRec[i]];
            }
        }

    }

    doInterest()
    {
        // const fields = {'sobjectType': 'Coupon_Seller__c'};
        // fields[CouponSeller_ID_FIELD.fieldApiName] = 'a1M23000000h1FnEAI';
        // fields[CouponSellerStage_FIELD.fieldApiName] = 'Seller Declined';
        // fields[SellerDeclinedReasons_FIELD.fieldApiName] = 'Other';
        this.isLoading = true;
        this.getCheckedRecord();
        // console.log('lstResult',JSON.parse(JSON.stringify(this.lstResult)));

        var lstCoupon = [];
        var lstRec = this.lstResult;
        if(lstRec.length <= 0){
            this.showInfoToast();
            this.isLoading = false;
            return;
            
        }

        for(var i = 0; i < lstRec.length; i++){
            // console.log('lstRec[i]: ',lstRec[i]);
            // const fields = {'sobjectType': 'Coupon_Seller__c'};
            // fields[CouponSeller_ID_FIELD.fieldApiName] = lstRec[i]['Id'];
            // fields[CouponSellerStage_FIELD.fieldApiName] = 'Seller Declined';
            // fields[SellerDeclinedReasons_FIELD.fieldApiName] = 'Other';
            // lstCoupon = [...lstCoupon, fields];
            
            lstCoupon = [...lstCoupon, lstRec[i]['Id']];
        }

        // console.log('lstCoupon',JSON.parse(JSON.stringify(lstCoupon)));

        updateInterest({coup: lstCoupon})
        .then(result => {
            if(result['status'] == 'success') {
                this.showSuccessToast();
            }else {this.showErrorToast();}

            this.isOverlay = (result['status'] == 'success') ? false : true; // close modal
            this.isLoading = false;

        }).catch(error => { console.log('msgErr: ',error.body.message); this.isLoading = false; });

    }

    doNotInterest()
    {
        this.isLoading = true;
        this.getCheckedRecord();

        var lstCoupon = [];
        var lstRec = this.lstResult;
        if(lstRec.length <= 0){
            this.showInfoToast();
            this.isLoading = false;
            return;
        }
        for(var i = 0; i < lstRec.length; i++){
            lstCoupon = [...lstCoupon, lstRec[i]['Id']];
        }
        updateNotInterest({coup: lstCoupon})
        .then(result => {
            if(result['status'] == 'success') {
                this.showSuccessToast();
            }else {this.showErrorToast();}

            this.isOverlay = (result['status'] == 'success') ? false : true; // close modal
            this.isLoading = false;

        }).catch(error => { console.log('msgErr: ',error.body.message); this.isLoading = false; });

    }

   /* handleClickInterested(){
        console.log('==handleClickNotInterested==>'+JSON.stringify(this.mAllRecords)); 
        this.calltoApexToUpadteCouponSellerStage('Committed');
    }
    handleClickNotInterested(){
        console.log('==handleClickNotInterested==>'+JSON.stringify(this.mAllRecords)); 
        this.calltoApexToUpadteCouponSellerStage('Seller Declined');       
    }
    calltoApexToUpadteCouponSellerStage(Coupon_Seller_Stage){
        for(var i = 0; i < this.mAllRecords.length; i++){
            if(this.mAllRecords[i]["is_Checked"] === true){
                this.selectedRecordIds.add(this.mAllRecords[i]["Id"]);
            }            
        }
        console.log('====>'+JSON.stringify(this.selectedRecordIds));
        if(this.selectedRecordIds.length>0){
           
        }
    }*/
    
}