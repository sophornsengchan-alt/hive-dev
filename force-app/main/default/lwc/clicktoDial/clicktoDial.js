import { LightningElement, api } from 'lwc';

export default class ClickToDial extends LightningElement {
  @api phone;
  @api mobile;
  @api recordId; // Optional, useful for logging or CTI context
  @api params;   // Optional comma-separated key-value pairs: e.g., accountSid=xxx,sourceId=abc
  
  get number() {
    // Prioritize phone over mobile
    return this.phone || this.mobile || '';
  }

  get hasNumber() {
    return !!this.number;
  }
}