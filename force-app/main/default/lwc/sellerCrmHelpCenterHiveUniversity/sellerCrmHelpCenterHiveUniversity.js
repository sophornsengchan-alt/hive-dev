import { LightningElement, wire } from 'lwc';
import getHelpCenterConfigByLabel from '@salesforce/apex/HelpCenterController.getHelpCenterConfigByLabel';

export default class SellerCrmHelpCenterHiveUniversity extends LightningElement {
    hiveUniversityLinks= [];
    error;

    @wire(getHelpCenterConfigByLabel, { name: 'Gain More Knowledge' })
    wiredHiveKnowledge({ error, data }) { 
        
        if (data?.status === 'ok') {
            this.hiveUniversityLinks = data?.result || [];
            this.error = undefined;
        } else {
            this.error = error;
            this.hiveUniversityLinks = [];
        }
    }
}