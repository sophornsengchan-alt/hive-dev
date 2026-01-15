import { LightningElement, wire, track, api } from 'lwc';
/* DEPRECATED: 11.10.2022 / Mony Nou / US-0011802 - Retire Legacy Components no longer used on Seller Portal
import sidebarMetadata from '@salesforce/apex/dynamicCardBannerController.sidebarMetadata';
import Useful_Li nks from '@salesforce/label/c.Useful_Links';
import customSR from '@salesforce/resourceUrl/ebaydealseller';
*/
export default class LwcSidebarUsefulLink extends LightningElement {
    
    /* DEPRECATED: 11.10.2022 / Mony Nou / US-0011802 - Retire Legacy Components no longer used on Seller Portal
    @track sidebarMetadata=[];
    @track userDeal;
    */ 
    @api region;
    @api features; //SB 18-3-2022 US-0011390 - Refactor Useful Links for new Permission Model 

    /* DEPRECATED: 11.10.2022 / Mony Nou / US-0011802 - Retire Legacy Components no longer used on Seller Portal
    @track label = {
        Useful_Links
    }
    //Start - Sambath Seng - 16/12/2021 - US-0010845 - [AM] AM Useful links / Landing Page Layout
    // SB 18-3-2022 US-0011390 - Refactor Useful Links for new Permission Model 
    // pageName = '';
    // renderedCallback(){
    //     var urlString = document.location.href;
    //     this.pageName = urlString.substring(urlString.lastIndexOf('/')+1);
    // }
    //End - Sambath Seng - 16/12/2021 - US-0010845 - [AM] AM Useful links / Landing Page Layout
    //wiredDataResult
    // SB 18-3-2022 US-0011390 - Refactor Useful Links for new Permission Model 
    @wire(sidebarMetadata, { region: '$region', feature: '$features'})
    sidebarMetadata(result) {
        //this.wiredDataResult = result;
        if(result.data) {                       
            //console.log('res -------->>> '+JSON.stringify(result.data));              
            this.sidebarMetadata = JSON.parse(JSON.stringify(result.data));
            this.error = undefined; 

            this.sidebarMetadata.forEach(item => {
                if(item.Is_Mail_To__c)
                {
                    item.redirect_url__c = "mailto:"+item.redirect_url__c;
                }                 
            });
        } else if (result.error) {
            console.log('error : neah>>> ', result.error);
        }
      
    };

    */
    
}