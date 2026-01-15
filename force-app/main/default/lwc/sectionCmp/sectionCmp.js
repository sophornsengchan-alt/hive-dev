/**
 * Author - Anujit
 * description - This is a utility component is used to display the section
 */
import { LightningElement,api } from 'lwc';

export default class SectionCmp extends LightningElement {
    @api title;

    /**
     * @description - handles the summary click
     */
    @api
    handleSummaryClick(event) {
        this.template.querySelector('.slds-accordion__section').classList.toggle('slds-is-open');
    }
}