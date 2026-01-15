/*********************************************************************************************************************************************************************************
@ Change history:  	17.02.2023 / Andy Clark / Created - This is a Headless LWC called from an Action on account (no HTML). It opens JIRA in a new window based on the partner name
**********************************************************************************************************************************************************************************/

import { LightningElement, api, wire } from "lwc";
import { getRecord } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import AdsPartnerJiraURL from '@salesforce/label/c.AdsPartnerJIRAURL';


export default class LwcOpenJIRAForPartners extends LightningElement {

  @wire(getRecord, {
    recordId: '$recordId',
    fields: [NAME_FIELD]
  })
  account;

  @api recordId;
  @api async invoke() {
       var URLString = AdsPartnerJiraURL.replace('{accountName}', this.account.data.fields.Name.value);
       window.open(URLString);

  }

}