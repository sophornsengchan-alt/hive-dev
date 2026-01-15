import { LightningElement,api,wire,track} from 'lwc';
import { refreshApex } from '@salesforce/apex';
import {getObjectInfo,getPicklistValuesByRecordType} from 'lightning/uiObjectInfoApi';

import filterFieldsMetadata from "@salesforce/apex/DealListViewFilterController.filterFieldsMetadata";
import getAllPickListValue from "@salesforce/apex/DealListViewFilterController.getAllPickListValue";
import apexGetAccounts from '@salesforce/apex/AccountPickerController.getDEEligibleAccounts'; // SRONG TIN 09.06.2022 : US-0011345 /AC7 // SC 15-05-2022 US-0010787

import { loadStyle, loadScript} from 'lightning/platformResourceLoader';
import customSR from '@salesforce/resourceUrl/ebayDealFilterCalander';
import Aplly from '@salesforce/label/c.Apply';
import Clear from '@salesforce/label/c.Clear';
import LANG from '@salesforce/i18n/lang';
import DIR from '@salesforce/i18n/dir';
export default class LwcListViewFilter extends LightningElement {
   searchData = {};
   lang = LANG;
    dir = DIR;
   error = undefined;
   couponTypeOptions = [];
   filterCheck = false;
   value = '';
   refreshResult;
   @track ObjectSchema = '';
   picklistfilds;
   @api filterObjectName;
   wiredDataResult;
   fieldsWiredDataResult;
   picklistFieldsWiredData;
   picklistFieldValues;
   @track pickListDataType=[];
   picklistFieldAPIs = []; //TH : US-0016318 : create new list to set Picklist Api Name using in getPicklistValuesByRecordType
   @track fieldList=[];
   @track fieldToDisplay;
   @track dataFilterMetadata;
   @track labels={
      Aplly,
      Clear
   }
   siteId = '0';

   // SC 15-05-2022 US-0010787
   @api recordsLinkedAccounts; 
   @api isLinkedAccounts = false; 
   @api currentUser = {}; 
   @api selectedAccId;
   // SC 15-05-2022 US-0010787
   @api recordTypeId; //TH-21022025-US-0016318
   recTypeID; //TH-21022025-US-0016318
   @api listViewName = ''; //MN-08112021-US-0010640
   

   connectedCallback(){
      // console.log('===LANG==='+LANG);
      // console.log('===DIR==='+DIR);
      Promise.all([
         loadStyle(this, customSR + '/dealCalanderStyle.css'),
     ]).then(() => {
          console.log("uploadstyle::",result);
         })
         .catch(error => {
             console.log("error at style: ",error);
         });
      if(LANG == 'de'){
         this.siteId = '77';
      }
      // console.log('siteId: ',this.siteId); 
      // console.log('**** MN - listViewName :: ', this.listViewName); //MN-08112021-US-0010640
      this.doGetAccounts(); // SRONG TIN 09.06.2022 : US-0011345 /AC7 // SC 15-05-2022 US-0010787

   }

   // SB 09.06.2023 US-0013316
   customPicklistValueMapping = {};

   @wire(filterFieldsMetadata, {objectAPIName : '$filterObjectName', listViewName : '$listViewName'}) //MN-08112021-US-0010640-Add listViewName parameter
   filterFieldsMetadata(result) {
         this.fieldsWiredDataResult = result;
         if(result.data) {            
            this.dataFilterMetadata =result.data.fieldsMetadata;
            this.error = undefined; 
            let outerarray =[];
            let pickListDataType =[];
            let sortingArr = [ 'Coupon_Start_Date__c', 'Coupon_End_Date__c', 'Coupon_Contract_Due_Date__c','Coupon_Type__c','Seller_Declined_Reasons__c','Seller__c'];
            this.dataFilterMetadata.forEach((element)=>{
               this.fieldList.push(element.Field_API_Name__c);
               if(element.Field_Data_Type__c === 'Picklist'){
                  outerarray.push({...element,'pcklist':true});
                  pickListDataType.push(element.Field_API_Name__c);
               }
               // SB 09.06.2023 US-0013316
               else if (element.Field_Data_Type__c === 'Custom Picklist') {
                  outerarray.push({...element,'customPicklist':true});
               }
               else if(element.Field_Data_Type__c === 'Lookup'){ // SC 15-05-2022 US-0010787 - - Configure fields available on filter for Coupon List Views 
                  outerarray.push({...element,'lookup':true});
               }   // SC 15-05-2022 US-0010787 - - Configure fields available on filter for Coupon List Views
               else {
                  outerarray.push({...element,'typeDate':true});
               }

               // Start SB 09.06.2023 US-0013316
               if(element.Custom_Picklist_Value_Mapping__c && element.Custom_Picklist_Value_Mapping__c != ''){
                  let customPicklistValueMapping = {};
                  element.Custom_Picklist_Value_Mapping__c.split('\n').forEach((pair) => {
                     if(pair !== '') {
                        let splitpair = pair.split(' => ');
                        let key = splitpair[0];
                        customPicklistValueMapping[key] = splitpair[1].trim();
                     }
                  });
                  this.customPicklistValueMapping = customPicklistValueMapping;
               }
               // End SB 09.06.2023 US-0013316
            })
            if(outerarray.length){
                  outerarray.sort(function(a, b){  
                     return sortingArr.indexOf(a.Field_API_Name__c) - sortingArr.indexOf(b.Field_API_Name__c);
                  });
               this.fieldToDisplay = outerarray;
            }
            this.getCustomPicklistValue();// SB 09.06.2023 US-0013316
            //TH-21022025-US-0016318
            if(this.recordTypeId){
               this.recTypeID = this.recordTypeId;
            }else{
               this.pickListDataType = pickListDataType;
               this.recTypeID = this.objectMetadata.data.defaultRecordTypeId; 
            }
            this.picklistFieldAPIs = pickListDataType;
            //End US-0016318
      } else if (result.error) {
         console.log('error :  ', result.error);
      }
     
   };

   @wire(getAllPickListValue, {objectApiName : '$filterObjectName', field_name: '$pickListDataType'}) 
   getAllPickListValue(result) {
      this.picklistFieldsWiredData = result;
      if(result.data) {         
         this.picklistFieldValues =result.data;
         this.error = undefined; 
         this.pickListDataType.forEach((element)=>{
            let couponTypeOptions = [];
            if(Object.keys(this.picklistFieldValues).includes(element)){
               this.picklistFieldValues[element].forEach(elementKey => {
                  couponTypeOptions.push({
                     label: elementKey.label,
                     value: elementKey.value
                  });
               });
            
               this.couponTypeOptions= couponTypeOptions;
               //  console.log('before sencindd loppppp',this.fieldToDisplay, element);
               this.fieldToDisplay.forEach((field)=>{
                  if(Object.values(field).includes(element)){
                  field.picklistoptions= couponTypeOptions; //MN-26112021-US-0010838 - Uncomment back
                  }
               })
               //  console.log('@@@@ this.fieldToDisplay in second',this.fieldToDisplay)
            }
         })
         //   console.log('this.fieldToDisplay: ',JSON.stringify(this.fieldToDisplay))
      } else if (result.error) {
         console.log('error : ', result.error);
      }
     
   };
   
   @wire(getObjectInfo, {objectApiName: '$filterObjectName' })
   objectMetadata;
   
   @wire(getPicklistValuesByRecordType, {
      objectApiName: '$filterObjectName',
      recordTypeId: '$recTypeID'
   })
   picklistValues({error,data}) {
      if (data) {    
         this.picklistFieldAPIs.forEach((element)=>{
            for (const [key, value] of Object.entries(data.picklistFieldValues)) {
               if(element == key){
                  var picklistValues = [];
                  if(Object.keys(value.controllerValues).length > 0){
                        var controllerValue = value.controllerValues[this.siteId]
                        value.values.forEach(picklistValue => {
                           if(picklistValue.validFor.includes(controllerValue)){
                              picklistValues.push({
                                  label: picklistValue.label,
                                  value: picklistValue.value
                              });
                           }
                        });
                  }
                  else{
                     value.values.forEach(picklistValue => {
                        picklistValues.push({
                           label: picklistValue.label,
                           value: picklistValue.value
                        });
                     });
                  }
                  this.fieldToDisplay.forEach((field)=>{
                     if(field.Field_API_Name__c == element){
                        field.picklistoptions = picklistValues;
                     }
                  });
               }
            }
         });
      }
   }

   // SB 09.06.2023 US-0013316
   getCustomPicklistValue() {
      let picklistOptions = [];
      Object.keys(this.customPicklistValueMapping).forEach(mappingKey => {
         this.value = Object.values(this.customPicklistValueMapping)[0];// Set first value Default
         picklistOptions.push({
            label: mappingKey,
            value: this.customPicklistValueMapping[mappingKey]
         });
         this.fieldToDisplay.forEach((field) => {
            if(field.Field_Data_Type__c == 'Custom Picklist') {
               field.custompicklistoptions = picklistOptions;
            }
         })
      });
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

   handleChange(event) {

      if(this.fieldList.includes(event.target.name)){
         // console.log('match teh keyy',event.target.value, event.target.name );
         this.searchData[event.target.name]= event.target.value;
      }
      // console.log('@@@@ this.searchdatatata',this.searchData);
   }

   handleSearch(event) {
      event.preventDefault();
      const searchEvent = new CustomEvent('search', {
         detail: this.searchData
      });
      this.dispatchEvent(searchEvent);

   }
  
   
   clearHandler(event) {
      this.searchData={};
      const lwcComboFields = this.template.querySelectorAll(
            'lightning-combobox'
      );
      if (lwcComboFields) {
         lwcComboFields.forEach(field => {
               field.value=null;
            });
      }
      const lwcInputFields = this.template.querySelectorAll(
         'lightning-input'
      );
      if (lwcInputFields) {
         lwcInputFields.forEach(field => {
               field.value=null;
         });
      }

      const searchEvent = new CustomEvent('clear', {
         detail: ''
      });
      
      this.dispatchEvent(searchEvent);

   }
   // SRONG TIN 09.06.2022 : US-0011345 /AC7
   doGetAccounts() {        
      apexGetAccounts()
      .then(result => {
         //   console.log("-doGetAccounts-",result);
          this.currentUser = result.curentUser;
          this.recordsLinkedAccounts = result.accRelationCoupons; 
          if (this.recordsLinkedAccounts.length > 1 ) {
               this.isLinkedAccounts = true;
          }
      }).catch(error => {
          console.log("apexGetAccounts error",error);
      });
   }

   get accId(){
      return this.selectedAccId;
   }
   get optionsSeller() {
        
      let opts = [];
      
      if (this.recordsLinkedAccounts) {
         
         var objRec = {};
         this.recordsLinkedAccounts.forEach(function(acc){     
            
            var tmp = acc.AccountId.substring(0, 15); //Because COUNT logic for DE using with field EBH_BusinessName__r.Parent_Account_ID__c and it store only 15 char ID

            opts.push({ label : acc.Account.Name, value: tmp });
            objRec[tmp] = acc;
         
         });
         
         this.mRecords = objRec;

         
      }

      return opts;
   }

}