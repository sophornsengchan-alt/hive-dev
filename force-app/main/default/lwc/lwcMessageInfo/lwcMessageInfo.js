import { LightningElement, wire, api, track } from 'lwc';
export default class LwcBannerCard extends LightningElement {
    
    @api type;
    @api message;
    @api messageDetail;

    isError = false;
    isWarning = false;
    isSuccess = false;
    isMessageDetail = false;

    connectedCallback(){
        console.log('loggggg');
        this.isError = (this.type == 'Error');
        this.isWarning = (this.type == 'Warning');
        this.isSuccess = (this.type == 'Success');
        this.isMessageDetail = (this.messageDetail != null && this.messageDetail != '');
    }

}