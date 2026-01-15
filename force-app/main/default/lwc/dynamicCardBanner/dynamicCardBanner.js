import { LightningElement, wire, api, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import pageBannerMetadata from '@salesforce/apex/dynamicCardBannerController.pageBannerMetadata';
import myResource from '@salesforce/resourceUrl/bannerImg';
import { NavigationMixin } from "lightning/navigation";
export default class DynamicCardBanner extends NavigationMixin(LightningElement) {
    @api metadataName;
    
    get img1(){
        if(this.bannerMetadata)
        return myResource +this.bannerMetadata.card_background_image__c;
        else
        return '';
    }
    @track error;
    wiredDataResult;
    @track bannerMetadata;
    @wire(pageBannerMetadata, {metadataName : '$metadataName'})
    pageBannerMetadata(result) {
        this.wiredDataResult = result;
        if(result.data) {            
            
            console.log('res >>> '+JSON.stringify(result.data)); 
            this.bannerMetadata = result.data;
            this.error = undefined; 
            
        } else if (result.error) {
            console.log('error : >>> ', result.error);
        }
      
    };

    openurlintab(event){
        event.stopPropagation()
        this[NavigationMixin.Navigate]({
            type : 'standard__webPage',
            attributes: {
                url : this.bannerMetadata.card_url_link__c
            }
        });
        
    }

    renderedCallback() {
        this.isLoaded = false;
    }

    connectedCallback(){
        console.log("kjhljj",this.img1);
    }
}