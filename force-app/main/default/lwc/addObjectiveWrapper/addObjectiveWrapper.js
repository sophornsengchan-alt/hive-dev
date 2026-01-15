/*********************************************************************************************************************************
@ Component:      AddObjectiveWrapper
@ Version:        1.0
@ Author:         Sothea Horn (sohorn@ebay.com)
@ Created Date:   18 MARCH 2025
@ Purpose:        US-0016851 - Overwrite standard objective editing functionality
----------------------------------------------------------------------------------------------------------------------------------
*********************************************************************************************************************************/
import { LightningElement, api } from 'lwc';

export default class AddObjectiveWrapper extends LightningElement { 
    @api accPlanId;

    get inputVariables() {
        return [
          {
            // Match with the input variable name declared in the flow.
            name: "recordId",
            type: "String",
            // Initial value to send to the flow input.
            value: this.accPlanId,
          }
        ];
      }
}