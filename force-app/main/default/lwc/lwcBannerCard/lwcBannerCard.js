import { LightningElement, wire, api, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getCount from '@salesforce/apex/BannerCardController.getCount';
export default class LwcBannerCard extends LightningElement {
    
    @api mainTextDeal;
    @api customURL;
    @api lastNday;
    @api objectName;
  
    @track error;

    @track isLoaded = false;

    @track numberOfRecords; 


    wiredDataResult;

    @wire(getCount, {lastNday : '$lastNday',objectName : '$objectName'})
    getCount(result) {       
        this.wiredDataResult = result;
        if(result.data) {
            console.log('res Deals>>> 23'+JSON.stringify(result.data));
            var res = result.data;
            if(this.objectName === 'EBH_Deal__c')
            this.numberOfRecords = res.dealCount; // set number of deal counted with last n days
            if(this.objectName === 'Coupon__c')
            this.numberOfRecords = res.dealCouponSeller;  //// set number of deal coupon seller for review
            this.error = undefined;   
        } else if (result.error) {
            console.log('error : deallll>>> 41', result.error);
        }
      
    };


    renderedCallback() {
        this.isLoaded = false;
    }

    connectedCallback(){
        console.log("kjhljj",this.img1);
    }
}