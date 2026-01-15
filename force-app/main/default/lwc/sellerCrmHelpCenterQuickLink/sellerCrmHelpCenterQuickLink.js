import { api, LightningElement, wire } from 'lwc';
import getHelpCenterConfigByLabel from '@salesforce/apex/HelpCenterController.getHelpCenterConfigByLabel';

export default class SellerCrmHelpCenterQuickLink extends LightningElement {
    @api knowledgeQuickLinks;

    quickLinks= [];
    error;

    @wire(getHelpCenterConfigByLabel, { name: 'Quick Links' })
    wiredHiveKnowledge({ error, data }) { 
        if (data?.status === 'ok') {
            this.quickLinks = data?.result || [];
            this.error = undefined;
        } else {
            this.error = error;
            this.quickLinks= [];
        }
    }
}