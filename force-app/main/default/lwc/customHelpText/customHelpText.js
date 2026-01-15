import { LightningElement,api } from 'lwc';

export default class CustomHelpText extends LightningElement {
    /**
     * This help text component is used to display the help text primarily rendering the url links in the tooltip 
     * As standard help text LWC component does not support the url links in the tooltip
     * Author: Anujit
     */
    @api helpText =''; //help text to be displayed
}