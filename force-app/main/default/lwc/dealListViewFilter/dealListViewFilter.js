import { LightningElement,api,wire,track} from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import Deal_Object from '@salesforce/schema/EBH_Deal__c';
// import Status_Field from '@salesforce/schema/EBH_Deal__c.EBH_Status__c';
//import getfields from "@salesforce/apex/DealListViewFilterController.getfields";
import { loadStyle, loadScript} from 'lightning/platformResourceLoader';
import customSR from '@salesforce/resourceUrl/ebayDealFilterCalander';

export default class DealListViewFilter extends LightningElement {
   searchData = {};
   error = undefined;
   statusOptions = [];
   rjectionReasonOptions = [];
   dealFormatOption = [];
   filterCheck = false;
   value = '';
   refreshResult;

   @api fieldSetName= 'Seller_Portal_Filter_Fields';
   @api filterObjectName='EBH_Deal__c';
   @api site;

   connectedCallback(){
      Promise.all([
         loadStyle(this, customSR + '/dealCalanderStyle.css'),
     ]).then(() => {
          
         })
         .catch(error => {
             console.log("error at style: ",error);
         });
   }
   
   // wiredDataResult;
   // getfields;
   // @wire(getfields, {filterObjectName : '$filterObjectName' ,fieldSetName:'$fieldSetName'})
   // getfields(result) {
   //     this.wiredDataResult = result;
   //     console.log('@@@@ result>>>',result);
   //     if(result.data) {            
   //       let objStr = JSON.parse(result.data);   
            
   //       /* retrieve listOfFields from the map,
   //        here order is reverse of the way it has been inserted in the map */
   //       let listOfFields= JSON.parse(Object.values(objStr)[0]);
   //       console.log('@@@@listOfFields',listOfFields);
   //         this.getfields = result.data;
   //         this.error = undefined; 
           
   //     } else if (result.error) {
   //         console.log('error : >>> ', result.error);
   //     }
     
   // };
   // to get the default record type id, if you dont' have any recordtypes then it will get master
   @wire(getObjectInfo, {
      objectApiName: Deal_Object
   })
   dealsMetadata;

   @wire(getPicklistValuesByRecordType, {
      objectApiName: Deal_Object,
      recordTypeId: '$dealsMetadata.data.defaultRecordTypeId'
   })
   picklistValues({
      error,
      data
   }) {
      console.log('site: ',this.site)

      if (data) {
         console.log(data);
         console.log('site: ',this.site)
         let statusData = [];
         let rjectionReasonData = [];
         let dealFormatData = [];
         //fetch status option data
         // Sambath Seng - 15/01/2024 - US-0013136
         /* if (data.picklistFieldValues.Seller_Portal_Status__c) {
            data.picklistFieldValues.Seller_Portal_Status__c.values.forEach(element => {
               statusData.push({
                  label: element.label,
                  value: element.value
               });
            });
            this.statusOptions = statusData;
         }*/

         //  fetch rjection reason data
         if (data.picklistFieldValues.EBH_ReasonforRejection__c) {
            
            data.picklistFieldValues.EBH_ReasonforRejection__c.values.forEach(element => {
               console.log('element: ',element)
               rjectionReasonData.push({
                  label: element.label,
                  value: element.value
               });
            });
            this.rjectionReasonOptions = rjectionReasonData;
         }

         //fetch Deal Format data
         if(data.picklistFieldValues.EBH_DealFormat__c) {
            data.picklistFieldValues.EBH_DealFormat__c.values.forEach(element => {
               dealFormatData.push({
                  label: element.label,
                  value: element.value
               });
            });
            this.dealFormatOption = dealFormatData;
         }

      } else if (error) {
         console.log(error);
      }
   }
   
   handleChange(event) {


      if (event.target.name == 'status') {
         this.searchData.status = event.target.value;
      }
      if (event.target.name == 'rejectionreason') {
         this.searchData.rejectionReason = event.target.value;
      }
      if (event.target.name == 'dealformat') {
         this.searchData.dealFormat = event.target.value;
      }
      if (event.target.name == 'startdate') {
         this.searchData.startDate = event.target.value;
      }
      if (event.target.name == 'enddate') {
         this.searchData.endDate = event.target.value;
      }
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
            console.log('>>>>lwcInputFields',lwcComboFields)
            lwcComboFields.forEach(field => {
                 field.value=null;
             });
         }
         const lwcInputFields = this.template.querySelectorAll(
            'lightning-input'
        );
        if (lwcInputFields) {
           console.log('>>>>lwcInputFields',lwcInputFields)
           lwcInputFields.forEach(field => {
                field.value=null;
            });
        }

      const searchEvent = new CustomEvent('clear', {
         detail: ''
      });
      
      this.dispatchEvent(searchEvent);

   }


}