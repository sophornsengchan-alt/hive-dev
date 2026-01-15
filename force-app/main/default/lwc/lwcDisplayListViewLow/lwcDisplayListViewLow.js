/**
 * change log: 31/08/2022/vadhanak voun/US-0012297 - BETA Feedback
 *           : 02.04.2023 / Sambath Seng / US-0013377 - AU Champion UAT Fixes
 *           : 08.05.2023 / Sambath Seng / US-0013312 - IT - Page Translation and Regional Localization Deals List and Record view
 *           : 10.11.2023 / Sambath Seng / US-0012162 - Seller_Portal_Status__c - Remove Seller Facing References
 *           : 20.02.2025 / Sovanthean Dim / US-0016318 - 9.1 - Seller Portal - My Subsidized Deal Contract Agreements Page 
 *           : 25.02.2025 / Sovanthean Dim / US-0016567 - 12.2 - Seller Portal - Details of the deal in the Deals List View
 */
 import { LightningElement, api, track } from 'lwc';
 import { NavigationMixin } from 'lightning/navigation';
 import lblResubmit from '@salesforce/label/c.Re_Submit'; //MN-16122021-US-0010961
 import lblEnterEID from '@salesforce/label/c.EnterEbayItemID'; //MN-21022022-US-0011309
 import lblManageContracts from '@salesforce/label/c.Manage_Contracts'; // 07/09/2022 : Sophal Noch : US-0012273
 import lblDCADetailPageSPUrl from '@salesforce/label/c.DCADetailPageSPUrl'; // 07/09/2022 : Sophal Noch : US-0012273
 import DCA_Object_ApiName from '@salesforce/label/c.DCA_Object_ApiName';
 import DCA_ListView_MtNames from '@salesforce/label/c.DCA_ListView_MtNames';
 import lblCancellation from '@salesforce/label/c.Seller_Deal_Cancellation'; //MN-13032023-US-0012628
 import SEP_Deal_Status_Editable from '@salesforce/label/c.SEP_Deal_Status_Editable'; //SB 8.5.2023 US-0013312
 import getActionMetadata from '@salesforce/apex/ClsListViewController.fetchActionMetadata';//TH:19.2.2025 US-0016318
 import lblDCASubDetailURL from '@salesforce/label/c.SEP_DCA_Sub_Detail_URL';
 export default class LwcDisplayListViewLow extends NavigationMixin(LightningElement) {
     @api sObjectName; //SB US-0010431 12-5-2022
     @api isshowcheckbox;
     @api highlightFields = [];
     @api allRecord = [];
     @api hierarchyRelationshipName; //LM US-0033386
     @track expandedIds = []; //LM US-0033386
     @api isDsc = false;
     @track headers = [];
     @track isLoadFirst = true;
     @track typeDates = ["DATE", "DATETIME"];
     typeTime = ["TIME"];
     @track typeNumbers = ["DOUBLE", "PERCENT", "DECIMAL", "INTEGER", "LONG"];

     
     //NK:31/08/2022:US-0012297
     @api fieldsNoLink = []; //list of field that will ignore hyperlink and display as normal text
 
     @track isSort = false;    
 
     @api lvName = ''; //MN-16122021-US-0010961
     labels = {       //MN-16122021-US-0010961
         lblResubmit,
         lblDCASubDetailURL   
         ,lblEnterEID  //MN-21022022-US-0011309
         ,lblManageContracts // 07/09/2022 : Sophal Noch : US-0012273
         ,lblDCADetailPageSPUrl // 07/09/2022 : Sophal Noch : US-0012273
         ,lblCancellation //MN-13032023-US-0012628
       };
 
     // 09/09/2022 : Sophal Noch : US-0012273
     dcaObjApiName = DCA_Object_ApiName;
     dcaListViewMtNames = DCA_ListView_MtNames;
     isNaDcaLandPageListView = null;

     cancellationListView = ["DE_Pending_Deals","Processing_Deals","Created_Last_7_Days", "Future_Deals", "Past_Deals"]; //MN-16032023-US-0012628 - All the list view that display "Cancellation" link will store in it
    //  cancellationStatusNAAU = ["Editable"]; //MN-16032023-US-0012628 - The Seller_Portal_Status__c that will enable display "Cancellation" link
     cancellationStatusNAAU = [SEP_Deal_Status_Editable]; //SB 8.5.2023 US-0013312
    
    actionResult;//TH:US-0016318
    hasAction = false; //TH:US-0016318
    firstLoadActionHeader = false; //TH:US-0016318

     //TH:US-0016318
    connectedCallback() {
        this.fetchActionMetadata();
    }

    //TH:US-0016318
    fetchActionMetadata() {
        getActionMetadata({objectAPIName : this.sObjectName, listViewName : this.lvName})
             .then(result => {
                this.actionResult = result;
                if(!this.isEmpty(this.actionResult)){
                    this.hasAction = true;
                }
             }).catch(error => {
                console.log("load ERROR::", error);
             });
         }

     get displayHighlightFields(){
         if(this.isLoadFirst) {
             var dup_i = 0; //MN-16122021-US-0010961
             for(var i = 0; i < this.highlightFields.length; i++){
 
                 var index;

                 // LM US-0033386
                 if (this.hierarchyRelationshipName) {
                     if (i==0) {
                         var hd = {index: i, type: "STRING", isSort : false};
                         this.headers.push(hd);
                     }
 
                     dup_i += 1;
                     index = dup_i;
                 }
                 //MN-16122021-US-0010961
                 if (this.lvName && this.lvName == 'DE_Rejected_Deals_Resubmit') {
                     if (i==0) {
                         var hd = {index: i, label : this.labels.lblResubmit, fieldName : this.labels.lblResubmit, type: "STRING", isSort : false};
                         this.headers.push(hd);
                     }
 
                     dup_i += 1;
                     index = dup_i;
                 }
                 //MN-21022022-US-0011309
                 if (this.lvName && this.lvName == 'DE_Enter_eBayItemID') {
                     if (i==0) {
                         var hd = {index: i, label : this.labels.lblEnterEID, fieldName : this.labels.lblResubmit, type: "STRING", isSort : false};
                         this.headers.push(hd);
                     }
 
                     dup_i += 1;
                     index = dup_i;
                 }
                 /*
                 //MN-13032023-US-0012628
                 if (this.lvName && this.lvName == 'DE_Pending_Deals') {
                    if (i==0) {
                        var hd = {index: i, label : this.labels.lblCancellation, fieldName : this.labels.lblCancellation, type: "STRING", isSort : false};
                        this.headers.push(hd);
                    }

                    dup_i += 1;
                    index = dup_i;
                }
                //MN-15032023-US-0012628
                if (this.lvName && this.lvName == 'Processing_Deals') {
                    if (i==0) {
                        var hd = {index: i, label : this.labels.lblCancellation, fieldName : this.labels.lblCancellation, type: "STRING", isSort : false};
                        this.headers.push(hd);
                    }

                    dup_i += 1;
                    index = dup_i;
                }
                //MN-16032023-US-0012628
                if (this.lvName && this.lvName == 'Created_Last_7_Days') {
                    if (i==0) {
                        var hd = {index: i, label : this.labels.lblCancellation, fieldName : this.labels.lblCancellation, type: "STRING", isSort : false};
                        this.headers.push(hd);
                    }

                    dup_i += 1;
                    index = dup_i;
                }
                */
                //MN-16032023-US-0012628
                if (this.lvName && this.cancellationListView.includes(this.lvName)) {
                    if (i==0) {
                        var hd = {index: i, label : this.labels.lblCancellation, fieldName : this.labels.lblCancellation, type: "STRING", isSort : false};
                        this.headers.push(hd);
                    }

                    dup_i += 1;
                    index = dup_i;
                }
                
                 else {
                     index = i;
                 }
                 //-----MN-16122021-US-0010961
                 
                 //{fieldName: "EBH_eBayItemID__c", label: "eBay Item ID", type: "STRING"}
                 //MN-16122021-US-0010961 - changed index:i to index: index
                 var hd = {index: index, label : this.highlightFields[i]["label"], fieldName : this.highlightFields[i]["fieldName"], type: this.highlightFields[i]["type"], isSort : false};
                 
                 this.headers.push(hd);
             }
 
             
             if (this.checkNaDcaLandPageListView() && this.headers.length > 0){ // 07/09/2022 : Sophal Noch : US-0012273
                 var hd = {index: this.headers.length, label : '', fieldName : this.labels.lblManageContracts, type: 'STRING', isSort : false};
                 this.headers.push(hd);
             } 
 
             this.isLoadFirst = false;
         }
         //TH:US-0016318
         if(this.hasAction && !this.firstLoadActionHeader) {
            var hd = {index: this.headers.length, label : 'Action', fieldName : 'Action', type: 'STRING', isSort : false};
            this.headers.push(hd);
            this.firstLoadActionHeader = true;
         }
         return this.headers;
     }
 
     get iconShowDetail(){
         //return this.isDsc? "utility:chevronup" : "utility:chevrondown";
         return this.isDsc? "utility:chevrondown" : "utility:chevronup"; //MN-03112021-US-0010639
     }
 
     get displayRecords(){

        var temAllRec = [];
         for(var i=0; i < this.allRecord.length; i++){
             var rec = this.allRecord[i];
             var obj = this.buildDisplayRecordObject(rec, i, 0);
             temAllRec.push(obj);
             if (this.hierarchyRelationshipName && rec[this.hierarchyRelationshipName] && this.expandedIds.includes(rec.Id)) {
                for (var j=0; j < rec[this.hierarchyRelationshipName].length; j++) {
                   var recLevel2 = rec[this.hierarchyRelationshipName][j];
                   var objLevel2 = this.buildDisplayRecordObject(recLevel2, i+'-'+j, 1);
                   temAllRec.push(objLevel2);
                }
             }
         }
         //this.allRecord = allRecs;
         return temAllRec;
     }

    buildDisplayRecordObject(rec, index, level) {
         var obj = {index : index, is_Checked : rec["is_Checked"], id : rec["Id"]};
         var cols = [];

        // LM US-0033386
        if (this.hierarchyRelationshipName) {
            const isExpandable = rec[this.hierarchyRelationshipName] && rec[this.hierarchyRelationshipName].length > 0;
            const isExpanded = this.expandedIds.includes(rec.Id);
            var col = {};
            col["isHierarchy"] = true;
            col["isExpandable"] = isExpandable;
            if (isExpandable) {
                col["iconName"] = isExpanded ? "utility:chevrondown" : "utility:chevronright";
            } else {
                col["iconName"] = level > 0 ? "utility:level_down" : "";
            }

            cols.push(col);
        } 

         //MN-16122021-US-0010961
         if (this.lvName && this.lvName == 'DE_Rejected_Deals_Resubmit') {
             var col = {};
             col["label"] = this.labels.lblResubmit;
             col["value"] = this.labels.lblResubmit;
             col["isResubmit"] = true;
             
             cols.push(col);
         }
         //-----MN-16122021-US-0010961

         //MN-21022022-US-0011309
         if (this.lvName && this.lvName == 'DE_Enter_eBayItemID') {
             var col = {};
             col["label"] = this.labels.lblEnterEID;
             col["value"] = this.labels.lblEnterEID;
             col["isEnterEID"] = true; //EID = Enter Item ID
             
             cols.push(col);
         }

        //MN-16032023-US-0012628
        if (this.lvName && this.cancellationListView.includes(this.lvName)) {
            var col = {};
            col["label"] = this.labels.lblCancellation;
            col["value"] = this.labels.lblCancellation;
            col["isCancellation"] = true;

            if (this.lvName == 'DE_Pending_Deals') col["isShow"] = true;
            else {
                // SB 10.11.2023 US-0012162
                // col["isShow"] = this.cancellationStatusNAAU.includes(rec.Seller_Portal_Status__c);
                col["isShow"] = this.cancellationStatusNAAU.includes(rec.Status_Seller_Portal__c);
            }
            
            cols.push(col);
        } 
        
        for(var x = 0; x < this.highlightFields.length; x++){
             var field = this.highlightFields[x];
             var col = {};
             col["label"] = field["label"];
             col["value"] = rec[field["fieldName"]];

             //NK:31/08/2022:US-0012297
             let noLink = this.fieldsNoLink.includes(field["fieldName"]);
             //SRONG-US-0010438-US-0011375:24.05.2022
             if( x == 0 && !noLink &&
                 this.lvName != "Coupon_Items_Co_Invests" && 
                 this.lvName !="Coupon_Category_Item_Base_List_View" && 
                 this.lvName !="DE_Coupon_Co_List_View") { //MN-13052022-US-0010437-For this list view, do not display link

                 col["isLink"] = true;
                 col["url"] =  "/sellerportal/s/detail/"+ rec["Id"];
             } else if (field["fieldName"] == "EBH_eBayItemID__c" && this.lvName == "DW_Deals_List_Tab") { //MN-11052023-US-0013472
                 col["isLink"] = true;
                 col["url"] =  "/sellerportal/s/detail/"+ rec["Id"];
             } else if (field["fieldName"] == "EBH_BusinessName__c") { //MN-27042021-US-0010950
                 col["isText"] = true;
                 col["value"] = rec.EBH_BusinessName__r.Name;
             }else if (field["fieldName"] == "eBay_Seller__c") { //MN-11012023-US-0012905 
                col["isText"] = true;
                col["value"] = rec.eBay_Seller__r.Name;
            }else if (field["fieldName"] == "Seller_Name__c" && !noLink) { //SRO-29.04.2022-US-US-0010435
                 col["isLink"] = true;
                 col["id2"] = rec.Seller__c;
            } else if(field["label"] == "Status"){
                 col["isStatus"] = true;
             } else if (field["type"] == "BOOLEAN") {
                 col["isCheckBox"] = true;
             } else if (field["fieldName"] == "Seller_Funding__c") { //SB 02.04.2023 US-0013377 - AU Champion UAT Fixes
                col["isText"] = true; 
                col["value"] = rec.Seller_Funding__c + '%';
             } else if (this.typeDates.includes(field["type"])) {
                 col["isDate"] = true;
            } else if (this.typeTime.includes(field["type"])) {//TH:25/02/2025 US-0016567 
                col["isTime"] = true;
             } else if (this.typeNumbers.includes(field["type"])) {
                 col["isNumber"] = true;
             } else {
                 col["isText"] = true;
             }
             cols.push(col);
         }
         //TH:US-0016318:20/02/2025
        if(!this.isEmpty(this.actionResult) && this.highlightFields.length > 0){
            this.checkVisibleActionWithCondition(rec,cols)
        }
        if (this.checkNaDcaLandPageListView() && this.highlightFields.length > 0){ // 07/09/2022 : Sophal Noch : US-0012273
             var col = {};
             col["label"] = this.labels.lblManageContracts;
             col["value"] =  this.labels.lblManageContracts;
             col["isLink"] = true;
             cols.push(col);
         }
         
         obj["cols"] = cols;
         return obj;
     }

     get isCheckAll(){
         var isCheck = true;
         for(var i = 0; i < this.allRecord.length; i++){
             if(this.allRecord[i]["is_Checked"] == false) {
                 isCheck = false;
                 break;
             } 
         }
         return isCheck;
     }
 
     handleExpand(event) {
        var recId = event.currentTarget.dataset["id"];
        if (recId) {
            this.expandedIds = this.expandedIds.includes(recId) ? this.expandedIds.filter(id => id !== recId) : [...this.expandedIds, recId];
        }
        var clickedRec = this.allRecord.find(rec => rec.Id == recId);
        // console.log(this.expanded, clickedRec, recId, JSON.stringify(this.allRecord));
        if (clickedRec) {
           clickedRec.expanded = !clickedRec.expanded;
        }
    }

     handleCheckboxAll(event) {
         var obj = {
             ischecked : event.target.checked
         }
         const custEvent = new CustomEvent(
             "callupdatecheckboxall", {
                 detail : obj
             });
         this.dispatchEvent(custEvent);
     }
 
     handleCheckbox(event) {
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
 
     onOpenDetail(event){
         var recId = event.target.dataset["id"];
         var selectedDCA = this.allRecord.find(rec => rec.Id == recId);
         // let objPath = (this.sObjectName == 'EBH_Deal__c') ? 'ebh-deal': 'ebh-dealretailcampaign'; // Samnang MUONG : if not deal then deal retail campaign
         // SB US-0010431 12-5-2022
         let objPath = '';
         if(this.sObjectName == 'EBH_Deal__c'){
             objPath = 'ebh-deal';
         } else if(this.sObjectName == 'Coupon_Seller__c'){ // SRONG 29.04.2022 : US-0010435
             objPath = 'coupon-seller';
             var recordId = event.target.dataset["record"];
             if(recordId != null && recordId.slice(0, 3) == '001'){
                 objPath = 'account';
                 recId = recordId;
             }
         }else if(this.sObjectName == this.dcaObjApiName){ // 06/09/2022 : Sophal Noch : US-0012273
            objPath = this.labels.lblDCADetailPageSPUrl;
         }
         else {
             objPath = 'ebh-dealretailcampaign';
         }
         var sepDetailURL = '';
        let retURL = encodeURIComponent(window.location.href.substring(window.location.href.lastIndexOf('/') + 1));
         if(this.sObjectName == this.dcaObjApiName && selectedDCA != null && selectedDCA.RecordType != null && selectedDCA.RecordType.DeveloperName=='Subsidized_Deals'){
            //DCA Sub Detail Page require id parameter
            retURL = retURL != '' ? '&retURL=' + retURL : '';
            sepDetailURL = "/" + this.labels.lblDCASubDetailURL +"?id="+ recId+retURL;
         }else if(this.sObjectName == 'EBH_Deal__c'){//TH:01.04.2025:US-0016979 : Add retURL to the URL of Deal Detail Page
            retURL = retURL != '' ? '?retURL=' + retURL : '';
            sepDetailURL = "/"+objPath+"/"+ recId+retURL;
         } else {
            sepDetailURL = "/"+objPath+"/"+ recId;
         }
         this[NavigationMixin.Navigate]({
             type: "standard__webPage",
             attributes: {
                 //url:  "/"+objPath+"/"+ recId
                 url : sepDetailURL
             }
         });
     }
 
     //MN-16122021-US-0010961
     onOpenModal(event){
         
         let child_lwc = event.currentTarget.parentNode.querySelector('c-lwc-modal-resubmit-deal');
         child_lwc.doShowModal();
 
     }

     //MN-13032023-US-0012628
     onOpenCancellationModal(event){
         
        let child_lwc = event.currentTarget.parentNode.querySelector('c-lwc-deal-cancellation');
        child_lwc.doShowModal();

    }
 
     //MN-17122021-US-0010961
     reloadPage() {
         this.dispatchEvent(new CustomEvent('reload'));
     }
 
     //MN-09122021-US-0010639 - When mouse over column header => appear the sort icon
     handleHover(event) {
 
         if (event.currentTarget.classList.contains("sort-arrow-active")) return;
 
         let elem_asc = event.currentTarget.querySelector('.asc');
         if (elem_asc.classList.contains("slds-hide")) elem_asc.classList.remove("slds-hide"); 
         else elem_asc.classList.add("slds-hide");
         
     }
 
     handleSort(event){
         var elems = this.template.querySelectorAll(".sort-arrow-active"); // Get all arrow inons that are highlighted
         [].forEach.call(elems, function(el) {
             el.classList.remove("sort-arrow-active"); // Un-highlight them
         });
         var target = event.currentTarget.classList.add('sort-arrow-active'); // Highlight selected arrow
 
         var index = event.currentTarget.dataset.index;
         var type = event.currentTarget.parentNode.dataset.type;
 
         var hds = [];
         var sortDirection = event.currentTarget.dataset.direction;
 
         event.currentTarget.parentNode.classList.add('sort-column-active'); //MN-09122021-US-0010639
         
         //MN-05112021-US-0010639
         if (!sortDirection) { //Click from Label
             
             let elem_asc = event.currentTarget.querySelector('.asc');
             let elem_desc = event.currentTarget.querySelector('.desc');
 
             let prev_mode = "";
             let cur_mode = "";
 
             if (elem_asc.classList.contains("active")) prev_mode = 'asc';
             else if (elem_desc.classList.contains("active")) prev_mode = 'desc';
 
             var elems_all = this.template.querySelectorAll(".active"); // Get all columns that are Sort Active
             [].forEach.call(elems_all, function(el) {
                 if (el.dataset.index != index) {
                     
                     if (el.classList.contains("active")) el.classList.remove("active"); 
                     if (!el.classList.contains("slds-hide")) el.classList.add("slds-hide");
 
                     el.parentNode.parentNode.parentNode.classList.remove("sort-column-active"); //MN-09122021-US-0010639
                 }
                 
             });
 
             if (!prev_mode || prev_mode == "") cur_mode = 'asc';
             else if (prev_mode == 'asc') cur_mode = 'desc';
             else if (prev_mode == 'desc') cur_mode = 'asc';
 
             if (cur_mode == 'asc') {
                 elem_asc.classList.remove('slds-hide');
                 elem_asc.classList.add('active');
 
                 elem_desc.classList.remove('active');
                 elem_desc.classList.add('slds-hide');
             }
             else if (cur_mode == 'desc') {
                 elem_desc.classList.remove('slds-hide');
                 elem_desc.classList.add('active');
 
                 elem_asc.classList.remove('active');
                 elem_asc.classList.add('slds-hide');
             }
              
             sortDirection = cur_mode;
 
         }
 
         
         /* NOT USE
         //MN-03112021-US-0010639
         if (sortDirection == "asc") {
             this.isDsc = true; 
             
         }
         else{
             this.isDsc = false;
             
         }   
         */
 
        for(var x=0; x < this.headers.length; x++) {
             var hd = this.headers[x];
             hd["isSort"] = (x == index? true : false);
             hds.push(hd);
         }
         this.headers = hds;
 
         var obj = {
             fieldName : event.currentTarget.parentNode.dataset.id,
             isNumber : this.typeNumbers.includes(type),
             direction : sortDirection
         }
         // console.log('obj: ',obj)
         const custEvent = new CustomEvent(
             "callsortcolumns", {
                 detail : obj
             });
         this.dispatchEvent(custEvent);
         //console.log("obj ::", obj);
         //this.sortData(event.currentTarget.dataset.id, isNumber);
     }
 /*
     sortData(sortColumnName, isNumber) {
         // check previous column and direction
         /*if (this.sortedColumn === sortColumnName) {
             this.sortedDirection = this.sortedDirection === 'asc' ? 'desc' : 'asc';
         } 
         else {
             this.sortedDirection = 'asc';
         }*/
 /*        this.sortedDirection = this.sortedDirection === 'asc' ? 'desc' : 'asc';
 
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
         var sortAllRecord = JSON.parse(JSON.stringify(this.allRecord)).sort((a, b) => {
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
         this.allRecord = sortAllRecord;
     }
 */
     /*handleClone(event){
         var recId = event.target.dataset["id"];
         this[NavigationMixin.Navigate]({
             type: "standard__webPage",
             attributes: {
                 url:  "/sellerportal/s/createupdatedeal?recordId="+ recId+"&isCloned=true"
             }
         });
     }*/
 
     checkNaDcaLandPageListView() { // 07/09/2022 : Sophal Noch : US-0012273
        if(this.isNaDcaLandPageListView === null){
            if (this.sObjectName && this.sObjectName == this.dcaObjApiName && this.lvName && this.dcaListViewMtNames){
                var mtNames = this.dcaListViewMtNames.split(';');
                for(var i = 0; i < mtNames.length; i++){
                    if(this.lvName == mtNames[i]){
                        this.isNaDcaLandPageListView = true;
                        break;
                    }
                }
            }

            if(this.isNaDcaLandPageListView === null) {this.isNaDcaLandPageListView = false;}
        }

        return this.isNaDcaLandPageListView;
 
     }

    //TH:US-0016318 : 19/02/2025
    checkVisibleActionWithCondition(rec,cols) {
        var col = {};
        col["isAction"] = true;
        col["label"] = '';
        col["value"] = '';
        col["url"] =  '';
        //loop through all return Action in current list view
        for (let key in this.actionResult) {
            if (this.actionResult.hasOwnProperty(key)) {
                const actionCondition = JSON.parse(this.actionResult[key].Action_Condition__c);
                if(actionCondition) {
                    let isMeetAllcondition = false;
                    //loop through each condition in actionCondition
                    for (var field in actionCondition) {
                        if(rec.hasOwnProperty(field)) {
                            let valueInRecord = rec[field];
                            let valueInactionCondition = actionCondition[field] ? actionCondition[field].split(';') : [];
                            if(valueInactionCondition.includes(valueInRecord)) {
                                isMeetAllcondition = true;
                            }else {
                                isMeetAllcondition = false;
                                break;
                            }
                        }
                    }
                    if(isMeetAllcondition) {
                        let actionName = this.actionResult[key].Action_Label__c;
                        let actionUrl = this.actionResult[key].Url__c;
                        col["label"] = actionName;
                        col["value"] = actionName;
                        col["url"] =  actionUrl.replace("{recId}", rec["Id"]);;
                        break;
                    }
                }
            }
        }
        cols.push(col);
    }
    
    isEmpty(value) {
    return value && Object.keys(value).length === 0;
    }
 }