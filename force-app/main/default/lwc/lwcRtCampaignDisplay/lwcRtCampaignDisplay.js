import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

//MN-12012022-US-0010934
export default class LwcRtCampaignDisplay extends NavigationMixin(LightningElement) {

    @api retailCampaign;
    @track isShowDetail = false; 

    get iconShowDetail(){
        return this.isShowDetail ? "utility:chevrondown" : "utility:chevronright";
    }
    get displayDetail(){
        return this.isShowDetail;
    }

    get rtCmpDescription() {
        let textValue = this.retailCampaign.NA_Retail_Campaign_Description__c;
        console.log('**** textValue :: ', textValue);
        return textValue;
    }

    onShowDetail(){
        this.isShowDetail = !this.isShowDetail;
    }

}