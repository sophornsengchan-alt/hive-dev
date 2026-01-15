import { LightningElement, api, wire, track } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';

import { refreshApex } from '@salesforce/apex';
import getAccountIdUser from '@salesforce/apex/CustomDealController.getAccountIdUser';
import getExistingDeals from '@salesforce/apex/CustomDealController.getExistingDeals'; 

import { CurrentPageReference } from 'lightning/navigation';

import { NavigationMixin } from 'lightning/navigation';

const columns = [{
    label: 'Product Title',
    fieldName: 'Id',
    type: 'url',
    typeAttributes: {label: { fieldName: 'Name' },value:{fieldName: 'Id'}}
}];


export default class LwcCreateUpdateDeal extends NavigationMixin(LightningElement) {

    @api recordId;
    @api isCloned; 

    @api startDate;
    @api endDate;

    @api title;
    @api footerText;

    @api labelNoProduct;
    @api labelChooseItem;

    @api labelURLSite;
    @api labelProductTitle;
    @api labelDealSite;
    @api labelRetailCampaign; 
    @api labelFormat;
    @api labelQuantity;
    @api labelStartDateTime;
   
    @api labelEndDateTime;
   
    @api labelDealPrice;
    @api labelMaximumPurchase;
    @api labelSellerPrice;
    @api labelRRPorWAS;
    @api labelRRPorWASPrice;

    @api labelItemNumber;

    @api labelSubmitBtn;
    @api footerHeaderText;

    @track isChecked;
    
    sortedDirection = 'asc';
    sortedBy = 'Name';
    searchKey = '';
    columns = columns; 
    @track data = []; 
    @track error;
    result;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) {
          this.urlStateParameters = currentPageReference.state;
          this.setParametersBasedOnUrl();
       }
    }
 
    setParametersBasedOnUrl() {
       this.startDate = this.urlStateParameters.startDate || null;
       this.endDate = this.urlStateParameters.endDate || null;       
    }
     
    @wire(getAccountIdUser) 
    accId;    

    @wire(getExistingDeals, { searchKey: '$searchKey', sortedBy: '$sortedBy', sortedDirection: '$sortedDirection' })
    wiredProducts({ error, data }) {      
        if (data) {
            console.log('yeye get deals ehhehe', data);
            var products = [];
           

            data.forEach(function(d) {             
                var product = {};  
                product.Id = '/createupdatedeal?recordId='+d.Id;
                product.Name = ((d.EBH_ProductTitle__c) ? d.EBH_ProductTitle__c : d.Name) + ' ('+((d.EBH_eBayItemID__c) ? d.EBH_eBayItemID__c : '')+')';

                // add to list
                products.push(product);
            });

            console.log('new products >>> ', products);

             this.data = products;           
           

            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = undefined;
            console.log('error : ',error);
        }
    } 
    
    handleKeyChange( event ) {
        this.searchKey = event.target.value;
        return refreshApex(this.result);
    }

    sortColumns( event ) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        return refreshApex(this.result);
        
    }
    handleNoProduct(event) {
        this.isChecked = event.target.checked;    
    }

    handleSubmit(event) {
        event.preventDefault();       // stop the form from submitting​

        const fields = event.detail.fields;       

        if (this.isCloned == 'true' && this.recordId) {   // clone record     

            console.log('test clone >>>>> ');
            this.recordId = '';         
            delete fields.Id;

            fields.EBH_BusinessName__c = this.accId.data; //'0011F00000tatlRQAQ'; // test fix account
            //var newFields = {'EBH_ProductTitle__c'}; 

            const cloneDeal = {apiName: 'EBH_Deal__c', fields};        
            createRecord(cloneDeal)
            .then(res => {
               // this.recordId = res.id;
                console.log('res.id >>>>> ', res.id);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Clone record created',
                        variant: 'success',
                    }),
                );

                this.redirectToFutureDeals();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            });

            
        
        } else if(!this.recordId){          
            fields.EBH_BusinessName__c = this.accId.data; //'0011F00000tatlRQAQ'; // test fix account
        }
      
       
        if(!this.isCloned || this.isCloned != 'true') this.template.querySelector('lightning-record-edit-form').submit(fields);
    }    
    
    handleSuccess(event){
        console.log('init onsuccess');
       
        
        const evt = new ShowToastEvent({
                    title: 'Success',
                    message: event.detail.apiName + ' record updated/created.',
                    variant: 'success',
            });

        this.dispatchEvent(evt);
        
        const updatedRecord = event.detail.id;
        console.log('onsuccess: ', updatedRecord);

        this.redirectToFutureDeals();

        
     }

     redirectToFutureDeals() {
        // redirect to create deal page
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: '/my-deals-lists'
            }
        });
     }

     connectedCallback() {
       //

       console.log('start date >>> ', this.startDate);
       console.log('end date >>> ', this.endDate);
    }
    

}