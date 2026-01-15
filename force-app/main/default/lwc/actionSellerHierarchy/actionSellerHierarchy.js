/*********************************************************************************************************************************
 * Component:       actionSellerHierarchy
 * Version:         1.0
 * Author:          Sophal Noch
 * Purpose:         US-0033903 - Parent Child seller overview component
 * Used In :        flow Action_Screen_SellerHierarchy_Sub, lwc actionSellerHierarchyWrapper
 * -------------------------------------------------------------------------------------------------------------------------------
 * Change history: 25.11.2025 / Sophal Noch / Created the class.
 *********************************************************************************************************************************/
import { LightningElement, api } from 'lwc';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';
export default class ActionSellerHierarchy extends LightningElement {
    @api sellerId;
    @api title;
    @api hasSellerSameHierachy = false;
    showCmp = false;

    get inputVariables() {
            return [
                {
                    name: 'sellerId', // API name of the input variable in the Flow
                    type: 'String', // Data type of the variable (e.g., 'String', 'Number', 'SObject')
                    value: this.sellerId // The actual value you want to pass
                },
                {
                    name: 'varTitle', // API name of the input variable in the Flow
                    type: 'String', // Data type of the variable (e.g., 'String', 'Number', 'SObject')
                    value: (this.title ? this.title : '') // The actual value you want to pass
                }
            ];
    }

    connectedCallback(){
        this.showCmp = this.sellerId ? true : false;
        this.hasSellerSameHierachy = true;
    }

    handleStatusChange(event) {
        // Check if the flow finished
        if (event?.detail?.status === 'FINISHED_SCREEN' || event?.detail?.status === 'FINISHED') {
            // Get output variables from the flow
            const outputVariables = event?.detail?.outputVariables;
            if (outputVariables) {
                // Find the specific output variable you need
                const outputVar = outputVariables.find(variable => variable.name === 'varHasSellerSameHierachy'); // Match the *API name* of the output variable in your Flow
                if (outputVar) {
                    this.hasSellerSameHierachy = outputVar.value;
                    this.dispatchEvent(new FlowAttributeChangeEvent('hasSellerSameHierachy', this.hasSellerSameHierachy));
                }
                if(!this.hasSellerSameHierachy){
                    this.showCmp = false;
                }
            }
        }
    }
}