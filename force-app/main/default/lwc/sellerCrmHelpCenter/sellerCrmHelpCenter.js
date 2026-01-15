/*********************************************************************************************************************************
@ Component:    SellerCrmHelpCenter
@ Version:      1.0
@ Author:       Chan Sophorn Seng
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.12.2024 / Chan Sophorn Seng US-0016132  create Help Center Page Layout for Experience Cloud Help Center Site Creation - Part 1
@               : 12.12.2024 / Chan Sophorn Seng / US-0016112 - integrate value to Help Center Page Layout - Part 3

*********************************************************************************************************************************/
import { LightningElement, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import tailwindCSS from '@salesforce/resourceUrl/tailwind';
import getAllKnowledge from '@salesforce/apex/HelpCenterController.getAllKnowledge';

export default class SellerCrmHelpCenter extends LightningElement {
    knowledgeFaqs = [];
    knowledgeQuickLinks = [];
    error;

    @wire(getAllKnowledge)
    wiredKnowledge({ error, data }) { 
        
        if (data?.status === 'ok') {
            this.knowledgeFaqs = data?.FAQ || []
            this.knowledgeQuickLinks = data?.Regular_Request || []
            this.error = undefined;
        } else {
            this.error = error;
            this.knowledgeFaqs = [];
            this.knowledgeQuickLinks = [];
        } 
    }

    connectedCallback() {
        loadStyle(this, tailwindCSS)
            .then(() => console.log('Tailwind CSS loaded successfully'))
            .catch((error) => console.error('Failed to load Tailwind CSS:', error));
    }
}