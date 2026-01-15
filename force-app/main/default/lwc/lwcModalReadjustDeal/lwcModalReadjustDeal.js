import LwcModalResubmitDeal from 'c/lwcModalResubmitDeal';
import lblSaveDeal from '@salesforce/label/c.Save_Deal';
import lblReadjustTitle from '@salesforce/label/c.Re_Adjust_Title';

export default class LwcModalReadjustDeal extends LwcModalResubmitDeal {
   
    connectedCallback() {
        //Sophal:18-03-2022:US-0011032 - Edit Deal Option for Sellers to adjust pricing on Submitted Deals
        this.listFields = ['EBH_Deal__c.Can_ReAdjust__c','EBH_Deal__c.EBH_DealSiteId__c','EBH_Deal__c.EBH_Category__c','EBH_Deal__c.EBH_DealPrice__c', 'EBH_Deal__c.EBH_RRPWASPrice__c', 'EBH_Deal__c.RecordTypeId'];
        this.isEid = true;
        this.labels.lblResubmit = lblSaveDeal;
        this.labels.lblTitle = lblReadjustTitle;
    }
    
}