/**
 * change log
 *  03/10/2022/vadhanak voun/US-0012739 - The Deal Price is overwritten when the item ID is updated by Seller
 */
import { LightningElement,api,track,wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import doUpdateDeal from '@salesforce/apex/CustomDealController.apexUpdateDeal';
import Deal_Object from '@salesforce/schema/EBH_Deal__c';
import { getRecord,getRecordNotifyChange } from 'lightning/uiRecordApi';
 
import lblCancel from '@salesforce/label/c.Cancel';
import lblResubmit from '@salesforce/label/c.Re_Submit';
import lblTitle from '@salesforce/label/c.Re_Submit_Title';
import lblEnterEID from '@salesforce/label/c.EnterEbayItemID'; //MN-21022022-US-0011309
import lblEnterEIDTitle from '@salesforce/label/c.EnterEbayItemIDTitle'; //MN-21022022-US-0011309
import LWCCreateSingleDeal12 from '@salesforce/label/c.LWCCreateSingleDeal12';//TH:11/03/2022:US-0011464 
import LWC_Valid_Specail_Character from '@salesforce/label/c.LWC_Valid_Specail_Character';//TH:11/03/2022:US-0011464 
import LWC_Valid_Length_SellerPrice from '@salesforce/label/c.LWC_Valid_Length_SellerPrice';//TH:11/03/2022:US-0011464 


import LWCCreateSingleDeal11 from '@salesforce/label/c.LWCCreateSingleDeal11';
import LWCCreateSingleDeal13 from '@salesforce/label/c.LWCCreateSingleDeal13';
import LWCCreateSingleDeal3 from '@salesforce/label/c.LWCCreateSingleDeal3'; //MN-21022022-US-0011309

import lblRequiredDealPrice from '@salesforce/label/c.RequiredDealPrice'; //Sophal:18-03-2022:US-0011032 
import lblInvalidDealPriceFormat from '@salesforce/label/c.InvalidDealPriceFormat'; //Sophal:18-03-2022:US-0011032 
import lblInvalidRRPWASPriceFormat from '@salesforce/label/c.InvalidRRPWASPriceFormat'; //Sophal:18-03-2022:US-0011032 

import LANG from '@salesforce/i18n/lang';

//MN-21022022-US-0011309
import { publish, MessageContext } from 'lightning/messageService';
import LWC_CONNECTION_CHANNEL from '@salesforce/messageChannel/LWC_Connection__c';


export default class LwcModalResubmitDeal extends LightningElement {
    labels = {
        lblCancel,
        lblResubmit,
        lblTitle,
        LWCCreateSingleDeal11,
        LWCCreateSingleDeal13,
        lblEnterEID, //MN-21022022-US-0011309
        lblEnterEIDTitle, //MN-21022022-US-0011309
        LWCCreateSingleDeal3, //MN-21022022-US-0011309
        LWCCreateSingleDeal12,//TH:11/03/2022:US-0011464 
        LWC_Valid_Specail_Character,//TH:11/03/2022:US-0011464 
        LWC_Valid_Length_SellerPrice,//TH:11/03/2022:US-0011464 
        lblRequiredDealPrice,
        lblInvalidDealPriceFormat,
        lblInvalidRRPWASPriceFormat
    };
    lang = LANG;

    @api recordId;

    @api viaListView = false; //MN-17122021-US-0010961
    @api isEid = false; //MN-21022022-US-0011309
    recordTypeId; //MN-20122021-US-0010961 to control the order execution of @wire-getPicklistValuesByRecordType to run after @wire-getRecord
    
    @api showSpinner = false;
    
    @track showModal = false;    
    @track isOverlay = false;

    @track error;
    @api modalTitle = "Resubmit Deal";
    
    @api labelLeave = "Close";   
    
    @api objectApiName = "EBH_Deal__c";
    
    @track fieldLabels = {};
    categoryOptions = [];
    formatOptions = [];

    @track singleDeal = {'sobjectType':'EBH_Deal__c'};

    //to idenfity the action being fire as for Re-Submit not updateitemid, or re-adjust
    @api isResubmit = false;//NK:02/10/2022/US-0012739

    @track categoryMap;
    @wire(getObjectInfo, {objectApiName: Deal_Object })
    dealsMetadata;

    @wire(getObjectInfo, { objectApiName: Deal_Object })
    getFieldLabels({ data, error }) {
        if(data){
    
            for (const [key, value] of Object.entries(data['fields'])) {
                this.fieldLabels[value.apiName] = value.label;
            }

            //console.log("-fieldLabels:"+ JSON.stringify(this.fieldLabels));
        }
        
    }
    renderedCallback(){
       
    }

    canReSubmit = false;

    isReadjustDealV3Price = false;

    listFields = ['EBH_Deal__c.Can_ReSubmit__c','EBH_Deal__c.EBH_DealSiteId__c','EBH_Deal__c.EBH_Category__c','EBH_Deal__c.EBH_Dealdateearliestpossible__c','EBH_Deal__c.EBH_Quantity__c','EBH_Deal__c.EBH_SellerPrice__c','EBH_Deal__c.EBH_DealPrice__c', 'EBH_Deal__c.RecordTypeId', 'EBH_Deal__c.EBH_CommentfromSeller__c'];
    
    @wire(getRecord, { recordId: '$recordId', fields: '$listFields' } )
    wiredDeal({ error, data }) 
    {
    //   console.log("--currentDeal data : "+JSON.stringify(data) +" - recordId: "+ this.recordId);
      if(data)
      {    
        this.singleDeal.Id=this.recordId;
        this.singleDeal.EBH_DealSiteId__c = data.fields.EBH_DealSiteId__c.value;
        this.singleDeal.EBH_Category__c = data.fields.EBH_Category__c.value;
        this.isReadjustDealV3Price = data.fields.Can_ReAdjust__c ? true : false; //Sophal:18-03-2022:US-0011032: Can_ReAdjust__c is set from lwcModalReadjustDeal that extented this cmp
        this.singleDeal.EBH_CommentfromSeller__c = data.fields.EBH_CommentfromSeller__c.value;//TH:31/03/2022 : US-0011517

        if(this.isReadjustDealV3Price){ //Sophal:18-03-2022:US-0011032: for NA unsub with Status_Seller_Portal__c = Editable

            if(data.fields.EBH_DealPrice__c)
            {
                var dealPrice = String(data.fields.EBH_DealPrice__c.value);
                this.singleDeal.EBH_DealPrice__c = dealPrice;
            }

            if(data.fields.EBH_RRPWASPrice__c)
            {
                var rrpPrice = String(data.fields.EBH_RRPWASPrice__c.value);
                rrpPrice = isNaN(rrpPrice) ? '' : rrpPrice;
                this.singleDeal.EBH_RRPWASPrice__c = rrpPrice;
            }

        }else{

            if(data.fields.EBH_Quantity__c)
            {
                this.singleDeal.EBH_Quantity__c = data.fields.EBH_Quantity__c.value;
            }
           
            if(data.fields.EBH_SellerPrice__c)
            {
                //TH:11/03/2022:US-0011464:replace from '.' to ',' for DE
                var price = this.lang=='de'?String(data.fields.EBH_SellerPrice__c.value).replace('.',','):String(data.fields.EBH_SellerPrice__c.value);
                this.singleDeal.EBH_SellerPrice__c = price;
                
            }

            if(data.fields.EBH_Dealdateearliestpossible__c)
            {
                this.singleDeal.EBH_Dealdateearliestpossible__c = data.fields.EBH_Dealdateearliestpossible__c.value;
            }
    
            if (this.dealsMetadata && this.dealsMetadata.data) this.recordTypeId = this.dealsMetadata.data.defaultRecordTypeId; //MN-20122021-US-0010961
            else this.recordTypeId = data.fields.RecordTypeId.value; //MN-22122021-US-0010961

            if(data.fields.Can_ReSubmit__c) // Sophal 09-05-2022 US-0011156
            {
                this.canReSubmit = data.fields.Can_ReSubmit__c.value;
            }
        }
        
 
      }else{
          console.log(error);
      }
       
      
      
    }

    
    @wire(getPicklistValuesByRecordType, {
        objectApiName: Deal_Object,
        //recordTypeId: '$dealsMetadata.data.defaultRecordTypeId'
        recordTypeId: '$recordTypeId' //MN-20122021-US-0010961
    })
    picklistValues({error,data}) {
        if (data) {

            let statusData = [];
            //fetch status option data

            if (data.picklistFieldValues.EBH_Category__c) {
                if(!this.categoryMap){
                    this.categoryMap = data.picklistFieldValues.EBH_Category__c;
                }
                statusData = this.getCategoriesFromSite();                
                this.categoryOptions = statusData;
                statusData = [];
            }

            
        } else if (error) {
        console.log(error);
        }
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

    connectedCallback() {

        
    }

    handleFieldChange(event){
        var value = event.detail.value;
        var apiName = event.target.getAttribute("data-apiname");
        this.singleDeal[apiName] = value;
        //SRONGTIN 08-0202022 : US-0011151
        this.validateInput(apiName,value);
        
    }
    validateInput(field, value){

        if(this.isReadjustDealV3Price){ //Sophal:18-03-2022:US-0011032

            if(field == 'EBH_DealPrice__c'){
                let dealPrice = this.template.querySelector('.EBH_DealPrice__c');
                if(this.singleDeal.EBH_DealPrice__c == undefined || this.singleDeal.EBH_DealPrice__c == ''){
                    dealPrice.setCustomValidity(this.labels.lblRequiredDealPrice);
                }else if(!this.checkPriceFormat(this.singleDeal.EBH_DealPrice__c,16,2,'.')) {
                    if(!this.isNumeric(this.singleDeal.EBH_DealPrice__c)){
                        dealPrice.setCustomValidity(this.labels.lblInvalidDealPriceFormat);
                        
                    }else{
                        dealPrice.setCustomValidity(this.labels.LWC_Valid_Length_SellerPrice);
                    }
                }else {
                    dealPrice.setCustomValidity('');
                }
                dealPrice.reportValidity();
            }

            if(field == 'EBH_RRPWASPrice__c'){
                let rrpPrice = this.template.querySelector('.EBH_RRPWASPrice__c');
                if(this.singleDeal.EBH_RRPWASPrice__c == undefined || this.singleDeal.EBH_RRPWASPrice__c == ''){
                    rrpPrice.setCustomValidity('');
                }else{
                    if(!this.checkPriceFormat(this.singleDeal.EBH_RRPWASPrice__c,16,2,'.')) {
                        if(!this.isNumeric(this.singleDeal.EBH_RRPWASPrice__c)){
                            rrpPrice.setCustomValidity(this.labels.lblInvalidRRPWASPriceFormat);
                            
                        }else{
                            rrpPrice.setCustomValidity(this.labels.LWC_Valid_Length_SellerPrice);
                        }
                    }else {
                        rrpPrice.setCustomValidity('');
                    }
                }
                rrpPrice.reportValidity();
                
            }

        }else{

            //SRONGTIN 08-0202022 : US-0011151
            if(field == 'EBH_Dealdateearliestpossible__c'){
                var dateEarliestPossible = this.template.querySelector('.EBH_Dealdateearliestpossible__c');
                var today = new Date();
                var selectedDate = new Date(this.singleDeal.EBH_Dealdateearliestpossible__c);
                selectedDate.setHours(0,0,0,0)
                today.setHours(0,0,0,0)
                
                if(this.singleDeal.EBH_Dealdateearliestpossible__c == undefined || this.singleDeal.EBH_Dealdateearliestpossible__c ==''){
                    dateEarliestPossible.setCustomValidity(this.labels.LWCCreateSingleDeal11);
                    
                }else if(selectedDate<today){
                    dateEarliestPossible.setCustomValidity(this.labels.LWCCreateSingleDeal13);
                    
                }else {
                    dateEarliestPossible.setCustomValidity('');
                }

                dateEarliestPossible.reportValidity();
            }
            else if(field == 'EBH_eBayItemID__c'){
                var ebayItemID = this.template.querySelector('.EBH_eBayItemID__c');
                if(this.singleDeal.EBH_eBayItemID__c != undefined && this.singleDeal.EBH_eBayItemID__c != '' && (this.singleDeal.EBH_eBayItemID__c.length != 12 || isNaN(this.singleDeal.EBH_eBayItemID__c)) ){ //MN-21022022-US-0011309
                    ebayItemID.setCustomValidity(this.labels.LWCCreateSingleDeal3);
                }
                else {
                    ebayItemID.setCustomValidity('');
                }
                ebayItemID.reportValidity();
            }
            //TH:US-0011464:11/03/2022
            else if(field == 'EBH_SellerPrice__c'){
                let sellerPrice = this.template.querySelector('.EBH_SellerPrice__c');
                if(this.singleDeal.EBH_SellerPrice__c == undefined || this.singleDeal.EBH_SellerPrice__c == ''){
                    sellerPrice.setCustomValidity(this.labels.LWCCreateSingleDeal12);
                }else if(!this.checkPriceFormat(this.singleDeal.EBH_SellerPrice__c,16,2,',')) {
                    if(!this.isNumeric(this.singleDeal.EBH_SellerPrice__c)){
                        sellerPrice.setCustomValidity(this.labels.LWC_Valid_Specail_Character);
                        
                    }else{
                        sellerPrice.setCustomValidity(this.labels.LWC_Valid_Length_SellerPrice);
                    }
                }else {
                    sellerPrice.setCustomValidity('');
                }
                sellerPrice.reportValidity();
            }
        }


    }

    isNumeric(val) {
        return /^-?[\d]+(?:e-?\d+)?$/.test(val);
    }
    checkPriceFormat(val, index0, index1, spChar) {
        var arrVal = val.split(spChar);
        if(arrVal.length == 2 && (this.isNumeric(arrVal[0]) && arrVal[0]).length <= index0 && this.isNumeric(arrVal[1]) && (arrVal[1]).length <= index1){
            return true;
        } else if ( arrVal.length < 2 && this.isNumeric(arrVal[0]) && (arrVal[0]).length <= index0){
            return true;
        } else {
            return false;
        }
    }

    //MN-21022022-US-0011309
    @wire(MessageContext)
    messageContext;

    @api doCloseModal()
    {
        this.showModal = false;
       this.isOverlay = false;
        this.showSpinner = false;

        //MN-21022022-US-0011309
        if (this.viaListView) {
            const payload = { 
                action: 'refresh',
            };
            publish(this.messageContext, LWC_CONNECTION_CHANNEL, payload);
        }
        

        // console.log("--close modal: "+ this.showModal+" --this.isOverlay: "+this.isOverlay);
        // if (this.viaListView) this.dispatchEvent(new CustomEvent('reload')); //MN-17122021-US-0010961

        
        
        return false;
    }
    
    @api doShowModal()
    {
        this.showSpinner = false;
        this.showModal = true;
        this.isOverlay = true;

        return false;
    }
    handleLoad(event)
    {

    }

    //NK:02/10/2022/US-0012739
    //Doing RE-Submit here
    handleRealReSubmit()
    {
        this.isResubmit = true;
        this.handleReSubmit();
    }

    //used by Re-Submit,UpdateItemId,Re-AdjustDeal
    handleReSubmit()
    {
        //console.log("--handleReSubmit1--");
        let panel_msg = this.template.querySelector('lightning-messages');                 
        panel_msg.setError( null);
        //console.log(panel_msg);
        this.showSpinner = true;
        // event.preventDefault();       // stop the form from submitting
        // const fields = event.detail.fields;     
        
        // console.log("--handleReSubmit fields: "+ JSON.stringify(fields) );
        // fields.EBH_Status__c = 'New';

         
        
        // this.template.querySelector('lightning-record-edit-form').submit(fields);
                  
         if(!this.validateFields())
         {
            if(!this.isReadjustDealV3Price){ //Sophal:18-03-2022:US-0011032 When Deal is Not NA Unsub
                 //TH:US-0011464:11/03/2022
                this.singleDeal.EBH_SellerPrice__c = parseFloat((this.singleDeal.EBH_SellerPrice__c+'').replace(',','.'));
                //SRO: 06/04/2022 : US-0011624
                //this.singleDeal.EBH_DealPrice__c = this.singleDeal.EBH_SellerPrice__c;
            }

            //NK:02/10/2022/US-0012739
           if(this.isResubmit)
           {
            this.singleDeal.EBH_DealPrice__c = this.singleDeal.EBH_SellerPrice__c;
            this.isResubmit = false; //just in case
           }

            doUpdateDeal({deal:this.singleDeal, isEnterEID:this.isEid})
            .then(result => {
                if(result.status=="ok")
                {
                    getRecordNotifyChange([{recordId: this.recordId}]);
                    window.postMessage({"name":"refreshCount"}, '*');   //NK:06/09/2022:US-0012132
                    if (this.viaListView) this.dispatchEvent(new CustomEvent('reload')); //MN-17122021-US-0010961
                    this.doCloseModal();
                }else 
                {                   
                    //panel_msg.error = result.error;
                                       
                    panel_msg.setError(result.error);
                    
                    // let h2 = panel_msg.querySelector(h2);
                    // h2.style.fontSize = "20px"; 
                }

                this.showSpinner = false;
            })
            .catch(error => {
                this.error = error;
                console.log(error);

                this.showSpinner = false;
            }); 
         }else
         {
            this.showSpinner = false;
         }
        
         return false;
    }
    validateFields()
    {
        //this.validateInput('EBH_Dealdateearliestpossible__c', this.singleDeal.EBH_Dealdateearliestpossible__c);
        let inputFields = this.template.querySelectorAll('lightning-input');
        //console.log(inputFields);
        let hasError = false;
        for(let i=0;i<inputFields.length;i++)
        {
            let inputOne = inputFields[i];
            if(!inputOne.reportValidity())
            {
                hasError = true;
                //console.log("--input Error: "+inputOne.name+"  :val: "+inputOne.value);
            }
            //else
            //{
                //console.log("--input: "+inputOne.name+"  :val: "+inputOne.value);
            //}
            
        }

        return hasError;
    }

    handleSuccess(event)
    {
        this.showSpinner = false;
        this.doCloseModal();
    }

    handleError(event)
    {
        this.showSpinner = false;
    }

 
    
}