import { api, LightningElement } from 'lwc';

export default class SellerCrmHelpCenterItem extends LightningElement {
    @api iconUrl='';
    @api iconName='';
    @api title='';
    @api id='';
    @api description='';
    @api iconClass='';
    @api urlName='';
    @api link='';
    @api isUseStandardIcon = false;

    get shouldDisplayCustomIcon() {
        return !this.isUseStandardIcon && this.iconUrl;
    }

    get knowledgeDetailUrl() {
        if(this.urlName)
            return '/article/'+this.urlName;
        else if(this.link)
            return this.link;
        return '';
    }
}