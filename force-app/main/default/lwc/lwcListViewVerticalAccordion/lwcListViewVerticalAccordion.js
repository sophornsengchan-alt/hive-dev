import { LightningElement, api, track, wire } from 'lwc';
import getSettings from '@salesforce/apex/ClsVerticalAccordion.getSettings';
import getExistingRecords from '@salesforce/apex/ClsVerticalAccordion.getExistingRecords';
import Next from '@salesforce/label/c.Next'; //TH:US-0013313
import Prev from '@salesforce/label/c.Prev'; //TH:US-0013313
//import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class LwcListViewVerticalAccordion extends LightningElement {
    //TH:US-0013313
    label = {
        Next,
        Prev
    };
    @api mdtName = "";
    @api profileHiddenBtnSingleDeal = "";
    @api messageNoRecord = ""; 
    @api userProfile = "";

    @api sepDomainHiddenBtnSingleDeal = ""; //MN-10062024-US-0015298
    @api userSEPDomain = ""; //MN-10062024-US-0015298
    
    @api highlightFields = [];
    @api labelBtnSingleDeal;
    @api labelBtnMultipleDeals;
    @track numberOfRecordsPerPage = 25;
    @track isHasRecord = false;
    @track totalPage = 0;
    @track currentPage= 1;
    @track mAllRecords = {};
    @track listRecord = [];
    searchKey = '';
    sortedBy = '';
    sortedDirection = '';
    settingName = this.mdtName;
    connectedCallback() {
        if(this.isLoadRecord) return;
        this.settingName = this.mdtName;
        this.sepDomainHiddenBtnSingleDeal = this.profileHiddenBtnSingleDeal; //MN-10062024-US-0015298
        this.isLoadRecord = true;
		this.loadAllSettings();
	}

    loadAllSettings() {
        getSettings({mdtName : this.mdtName})
        .then(result => {
                //console.log(">>>>resultddd ", JSON.stringify(result));
                //console.log(">>>>highlightFieldsddddd ", result["highlightFields"]);
                //console.log(">>>>detailFieldsdddddddd ", result["detailFields"]);
                //console.log(">>>>lstRecordsdddddddddd ", result["listRecord"]);
                //console.log(">>>>geurey ", result["soql"]);
                //ContactId, Contact.Portal_Display_Density__c
                this.userProfile = result["userProfile"];
                this.userSEPDomain = result["sepDomain"]; //MN-10062024-US-0015298
                this.highlightFields = result["highlightFields"];
                this.numberOfRecordsPerPage = result["numberOfRecordsPerPage"];
                //var listRecord = result["listRecord"];
                this.currentPage = 1;
                
			})
			.catch(error => { 
                console.log(">>>>>first load ERROR:", error);
				//this.error = error;
                //console.log(">>>>errordddd ", error);
                //this.doShowTast('Error!', error.body.message, 'error');
			}); 
	}

    @wire(getExistingRecords, { searchKey: '$searchKey', sortedBy: '$sortedBy', sortedDirection: '$sortedDirection', settingName: '$settingName' })
    wiredExistingRecords({ error, data }) {      
        if (data) {         
             //console.log(">>>>> data:", JSON.stringify(data));
            this.listRecord = [];
            if(data["listRecord"]){
                var jsonLstRec = JSON.stringify(data["listRecord"]);
                this.listRecord = JSON.parse(jsonLstRec);
                this.onAssignRecords();
            } else this.listRecord = [];
           
        } else if (error) {
            console.log('error : ',error);
        }
    }

    get sortFieldsOpt(){
        var arrOpt = [];
        var optNone = {label : " - NONE - ", value : ""};
        arrOpt.push(optNone);
        for( var i =0; i < this.highlightFields.length ; i++){
            //console.log(">>>>>>>> this.highlightFields:", this.highlightFields[i]);
            //console.log(">>>>>>>> ::::", this.highlightFields[i]["type"]);
            if(this.highlightFields[i]["type"] != "MULTIPICKLIST"){
                var direcAsc = (this.highlightFields[i]["type"] != "DATE" ? " (A - Z)" : " (Ascending)");
                var direcDesc = (this.highlightFields[i]["type"] != "DATE" ? " (Z - A)" : " (Descending)");
                
                var optAsc = {label : this.highlightFields[i]["label"] + direcAsc, value : this.highlightFields[i]["fieldName"] + ",asc"};
                var optDesc = {label : this.highlightFields[i]["label"] + direcDesc, value : this.highlightFields[i]["fieldName"] + ",desc"};
                
                arrOpt.push(optAsc);
                arrOpt.push(optDesc);
            }
        }

        return arrOpt;
    }
    get displayHighlightFields(){
        return this.highlightFields; 
    }

    get displayRecords(){
        return this.mAllRecords[this.currentPage]; 
    }

    get displayPagination() {
        var arrPage = [];
        for(var i =1; i<= this.totalPage; i++){
            var objP = {value : i, clsActive : (this.currentPage == i?"active":"")};
            arrPage.push(objP);
        }
        return arrPage;
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
        this.currentPage = pageNumber;
    }

    handleKeyChange(evt) {
        // console.log(">>>>> ", evt.target.value);
        this.searchKey = evt.target.value;
        //this.settingName = this.mdtName;
        //return refreshApex(this.refreshResult);
    }

    handleOptChange(event){
        //this.selectedLabel = event.detail.value;
        // console.log(">>>>>>>> selectedVal:",event.detail.value);
        var value = event.detail.value;
        if(value == ""){
            this.sortedBy = "";
            this.sortedDirection = "";
        } else {
            var arrVal = value.split(",");
            this.sortedBy = arrVal[0];
            this.sortedDirection = arrVal[1];
        }
    }

    onAssignRecords(){
        this.mAllRecords = {};
        var allRecs = [];
        var pageNum = 0;
        // console.log(">>>>>>>>> this.listRecord:", this.listRecord);
        for(var i =0; i < this.listRecord.length; i++){

            var rec = this.listRecord[i];//{"EBH_DealTitle__c" : "Test "+i, "EBH_Date__c" : today, "EPH_EndDate__c" : today, "Status__c" : "OPEN"};
            allRecs.push(rec);
            if(this.numberOfRecordsPerPage == allRecs.length){
                pageNum++;
                this.mAllRecords[pageNum] = allRecs;
                allRecs = [];
            }
        }
        if(allRecs.length > 0){
            pageNum++;
            this.mAllRecords[pageNum] = allRecs;
            allRecs = [];
        }
        this.totalPage = pageNum;
        this.isHasRecord = (pageNum>0);
    }
}