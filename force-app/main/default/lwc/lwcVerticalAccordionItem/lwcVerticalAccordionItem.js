import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import LWCBtnMyDeal from '@salesforce/label/c.LWCBtnMyDeal'; //TH-26112021-US-0010793
import LWCBtnHideMyDeal from '@salesforce/label/c.LWCBtnHideMyDeal'; //TH-26112021-US-0010793
import LANG from '@salesforce/i18n/lang'; //MN-26112021-US-0010775

import LWCVerticalAccorItemJunction01 from '@salesforce/label/c.LWCVerticalAccorItemJunction01'; //MN-26112021-US-0010775
import LWCVerticalAccorItemJunction02 from '@salesforce/label/c.LWCVerticalAccorItemJunction02'; //MN-26112021-US-0010775
import LWCVerticalAccorItemJunction03 from '@salesforce/label/c.LWCVerticalAccorItemJunction03'; //MN-26112021-US-0010775
import LWCNoDealAbailable from '@salesforce/label/c.LWCNoDealAvailable';//TH-24/04/2023-US-0013313
import Pending_Status from '@salesforce/label/c.Pending_Status';//TH-24/04/2023-US-0013313
import Open_for_Submissions_Status from '@salesforce/label/c.Open_for_Submissions_Status';//TH-24/04/2023-US-0013313
import Closed_for_Submissions_Status from '@salesforce/label/c.Closed_for_Submissions_Status';//TH-24/04/2023-US-0013313
import Running_Status from '@salesforce/label/c.Running_Status';//TH-24/04/2023-US-0013313
import Completed_Status from '@salesforce/label/c.Completed_Status';//TH-24/04/2023-US-0013313

export default class LwcVerticalAccordionItem extends NavigationMixin(LightningElement){//LightningElement {

    @api highlightFields = [];
    @api profileHiddenBtnSingleDeal = "";
    @api userProfile = "";

    @api sepDomainHiddenBtnSingleDeal = ""; //MN-10062024-US-0015298
    @api userSepDomain = ""; //MN-10062024-US-0015298

    @api detailFields = [];
    @api item = {}; 
    @api labelBtnSingleDeal;
    @api labelBtnMultipleDeals;
    @track isShowDetail = false;
    @track isShowDetailDealRelatedList = false;
    @track typeDates = ["DATE", "DATETIME"];
    @track typeNumbers = ["DOUBLE", "PERCENT", "DECIMAL", "INTEGER", "LONG"];
    //TH:US-0013313: Comment out , move to custom label
    //@track isGreen = ["Completed", "Running", "Open for Submissions"];
    @track isGreen = [Completed_Status, Running_Status, Open_for_Submissions_Status];
    //TH:US-0013313: Comment out , move to custom label
    //@track isYellow = ["Draft", "Pending"];
    @track isYellow = ["Draft", Pending_Status];
    //TH:US-0013313: Comment out , move to custom label
    //@track isRed = ["Closed for Submissions"];
    @track isRed = [Closed_for_Submissions_Status];
    @track isBulkUploadDeal = false;
    //TH:US-0013313: Comment out , move to custom label
    //@track statusDisables = ["Draft", "Closed for Submissions", "Completed", "Running", "Pending"];
    @track statusDisables = ["Draft", Closed_for_Submissions_Status, Completed_Status, Running_Status, Pending_Status];
    @track url;
    label = {
        LWCBtnMyDeal,
        LWCBtnHideMyDeal,
        LWCVerticalAccorItemJunction01, 
        LWCVerticalAccorItemJunction02, 
        LWCVerticalAccorItemJunction03,
        LWCNoDealAbailable
    };
    get iconShowDetail(){
        return this.isShowDetail ? "utility:chevrondown" : "utility:chevronright";
    }
    get displayDetail(){
        return this.isShowDetail;
    }

    //TH:24/11/2021:US-0010793 
    get displayDetailDealRelatedList(){
        return this.isShowDetailDealRelatedList;
    }
    get statusName(){
        return (this.isGreen.includes(this.item["Status_Seller_Portal__c"])? "cls_status_open" : (this.isYellow.includes(this.item["Status_Seller_Portal__c"])? "cls_status_Pending" : (this.isRed.includes(this.item["Status_Seller_Portal__c"])? "cls_status_closed" : "")));
    }
    get hideButtonSingleDeal() {
        //return (this.profileHiddenBtnSingleDeal != "" && this.userProfile != "" && this.profileHiddenBtnSingleDeal.includes(this.userProfile)); //MN-10062024-US-0015298: No longer use with Profile
        return (this.sepDomainHiddenBtnSingleDeal != "" && this.userSepDomain != "" && this.sepDomainHiddenBtnSingleDeal.includes(this.userSepDomain)); //MN-10062024-US-0015298: Use SP Main Domain instead of Profile Name
    }
    get disableButton() {
        return (this.statusDisables.includes(this.item["Status_Seller_Portal__c"])? true : false);
    }
    get windowTitle(){
        //return (this.item["Deal_Window__c"] ? this.item["Deal_Window__c"] : "");
        return (this.item["EBH_DealTitle__c"] ? this.item["EBH_DealTitle__c"] : "");
    }
    get focusCategories(){
        return (this.item["Focus_Categories__c"] ? (this.item["Focus_Categories__c"]).replaceAll(';', ', ') : "");
    }
    //TH:24/11/2021:US-0010793 - [SEP] Seller views their Deals in Deal Windows
    get itemId(){
        return (this.item["Id"] ? (this.item["Id"]): "");
    }

    get displayHighlightFields(){
        var hFields = [];

        for(var i =0; i< this.highlightFields.length; i++){
            var field = this.highlightFields[i];

            var obj ={lable: "Name", value: "", type: "text"}; 
            if(field["fieldName"] == "Deal_Window__c" || field["fieldName"] == "Focus_Categories__c" || field["fieldName"] == "EBH_DealTitle__c") continue;
            obj["label"] = field["label"];
            obj["value"] = this.item[field["fieldName"]];
            if(field["label"] == "Status" || field["fieldName"] == "Status_Seller_Portal__c"){
                obj["isStatus"] = true; 
            } else if (field["type"] == "BOOLEAN") {
                obj["isCheckBox"] = true;
            } else if (this.typeDates.includes(field["type"])) {
                obj["isDate"] = true;
            } else if (this.typeNumbers.includes(field["type"])) {
                obj["isNumber"] = true;
            } else if(this.isHTML(obj["value"])){
                obj["isHTML"] = true;
            } else {
                obj["isText"] = true;
            }
            
            //type: "STRING"
            if(i > 0) {
                hFields.push(obj);
            }
        }
        
        return hFields;//(itemObject["highlightFields"]? itemObject["highlightFields"] : []);
    }

    get displayDetailsFields(){
        var tFields = [];
        //var today = new Date();
        var isFirst = true;
        var childs = (this.item["Deal_Retail_Campaigns__r"]? this.item["Deal_Retail_Campaigns__r"] : []);
        //SELECT Id, EBH_DealTitle__c, Status_Seller_Portal__c, EBH_Date__c, EPH_EndDate__c
        for(var i =0; i < childs.length; i++){
            var child = childs[i];
            var cls_status = (this.isGreen.includes(child["Status_Seller_Portal__c"])? "cls_status_open" : (this.isYellow.includes(child["Status_Seller_Portal__c"])? "cls_status_Pending" : (this.isRed.includes(child["Status_Seller_Portal__c"])? "cls_status_closed" : "")))
            var obj = {id : i, name: child["EBH_DealTitle__c"], status: child["Status_Seller_Portal__c"], cls_rowName: (isFirst?"cls_rowWrapper" : "cls_rowWrapper cls_rowColor"), cls_status : cls_status, startDate : child["EBH_Date__c"], endDate : child["EPH_EndDate__c"]};
            isFirst = !isFirst;
            tFields.push(obj);
        }
        return tFields;
    }

    handleCheckbox(event){
        //this.item["is_Checked"] = event.target.checked;
        var obj = {
            index : event.target.dataset["index"],
            ischecked : event.target.checked
        }
        const custEvent = new CustomEvent(
            "callupdatecheckbox", {
                detail : obj
            });
        this.dispatchEvent(custEvent);
    }

    onShowDetail(){
        this.isShowDetail = !this.isShowDetail;
    }

    onCreateDeal() {
        //window.open( "/sellerportal/s/createupdatedeal", "_blank");
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: "/createupdatedeal?startDate="+this.item["EBH_Date__c"]+"&endDate="+this.item["EPH_EndDate__c"]
            }
        });
    }

    onBulkUploadDeals(){
        //this.isBulkUploadDeal = true;
        //EBH_Date__c, EPH_EndDate__c
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: "/bulk-upload-deals?recordId="+this.item["Id"]+"&startDate="+this.item["EBH_Date__c"]+"&endDate="+this.item["EPH_EndDate__c"]+"&country="+this.item["EBH_Country__c"]
            }
        });
    }
    //TH:24/11/2021:US-0010793 
    // Expand to Deal related list of Deal Window
    onShowDealRelatedList(){
        this.isShowDetailDealRelatedList = !this.isShowDetailDealRelatedList;
    }

    isHTML(str) {
        var doc = new DOMParser().parseFromString(str, "text/html");
        return Array.from(doc.body.childNodes).some(node => node.nodeType === 1);
    }

    onExpand(event){
        var parent = event.currentTarget;

        var parentParent = parent.parentNode;

        var parentParentChildren = parentParent.childNodes;
    }
}