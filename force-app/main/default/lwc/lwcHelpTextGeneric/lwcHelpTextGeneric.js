import { LightningElement,api,track,wire } from 'lwc';
/* DEPRECATED: 11.10.2022 / Mony Nou / US-0011802 - Retire Legacy Components no longer used on Seller Portal
import helpTextMetadata from '@salesforce/apex/dynamicHelpTextController.helpTextMetadata';
*/
export default class LwcHelpTextGeneric extends LightningElement {
    @api metadataName;
    /* DEPRECATED: 11.10.2022 / Mony Nou / US-0011802 - Retire Legacy Components no longer used on Seller Portal
    @track helpTextMetadata;
    wiredDataResult;
    @wire(helpTextMetadata, {metadataName : '$metadataName'})
    helpTextMetadata(result) {
        this.wiredDataResult = result;
        if(result.data) {
            console.log('res >>> '+JSON.stringify(result.data)); 
            this.helpTextMetadata = result.data;
            this.error = undefined;             
        } else if (result.error) {
            console.log('error : >>> ', result.error);
        }
      
    };
    */
}