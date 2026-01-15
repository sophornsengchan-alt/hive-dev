import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class LwcDisplayListViewItem extends NavigationMixin(LightningElement){//LightningElement {
    @api highlightFields = [];
    @api detailFields = [];
    @api item = {}; 
    @track isShowDetail = false;
    @track typeDates = ["DATE", "DATETIME"];
    @track typeNumbers = ["DOUBLE", "PERCENT", "DECIMAL", "INTEGER", "LONG"];
    get iconShowDetail(){
        return this.isShowDetail ? "utility:chevrondown" : "utility:chevronright";
    }
    get displayDetail(){
        return this.isShowDetail;
    }
    get displayFirstCol(){
        console.log(">>>>>> item:", this.item);
        var obj ={}; 
        
        if(this.highlightFields.length > 0){
            var field = this.highlightFields[0];
            
            obj["label"] = field["label"];
            obj["value"] = (this.item[field["fieldName"]]?this.item[field["fieldName"]]: "");
            if(field["label"] == "Status"){
                obj["isStatus"] = true;
            } else if (field["type"] == "BOOLEAN") {
                obj["isCheckBox"] = true;
            } else if (this.typeDates.includes(field["type"])) {
                obj["isDate"] = true;
            } else if (this.typeNumbers.includes(field["type"])) {
                obj["isNumber"] = true;
            } else {
                obj["isText"] = true;
            }
            
        }
        return obj;
    }

    
    

    get displayHighlightFields(){
        console.log(">>>>>> item:", this.item);
        //console.log(">>>>>> highlightFields:", this.highlightFields);
        var hFields = [];
        for(var i =0; i< this.highlightFields.length; i++){
            var field = this.highlightFields[i];
            var obj ={lable: "Name", value: "", type: "text"};  
            obj["label"] = field["label"];
            obj["value"] = this.item[field["fieldName"]];
            if(field["label"] == "Status"){
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
        //console.log(">>>>>> hFields:", hFields);
        return hFields;//(itemObject["highlightFields"]? itemObject["highlightFields"] : []);
    }

    get displayDetailsFields(){
        console.log(">>>>>> dddd:", this.item["Id"]);
        //console.log(">>>>>> detailFields:", this.item["id"]);
        var tFields = [];
        for(var i =0; i< this.detailFields.length; i++){
            var field = this.detailFields[i];
            var obj ={};  
            obj["label"] = field["label"];
            obj["value"] = this.item[field["fieldName"]];
            if(field["label"] == "Status"){
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
            
            tFields.push(obj);
            
        }
        
        return tFields;
    }

    handleCheckbox(event){
        //console.log(">>>>>>> index:", evt.target.dataset["index"]);
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

    onViewDetail(){
        //https://sepph1dev-hive-partner.cs90.force.com/sellerportal/s/ebh-deal/EBH_Deal__c/Default
        //window.open( "/sellerportal/s/detail/"+ this.item["Id"], "_blank");
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: "/ebh-deal/"+ this.item["Id"]
            }
        });
    }

    /*onCloneButton() {
        //window.open( "/sellerportal/s/createupdatedeal?recordId="+ this.item["Id"]+"&isCloned=true", "_blank");
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: "/createupdatedeal?recordId="+ this.item["Id"]+"&isCloned=true"
            }
        });
    }*/

    isHTML(str) {
        var doc = new DOMParser().parseFromString(str, "text/html");
        return Array.from(doc.body.childNodes).some(node => node.nodeType === 1);
    }
}