/*********************************************************************************************************************************
 * Component:       CohortUnsyncing
 * Version:         1.0
 * Author:          Sophal Noch
 * Purpose:         component to unsyncing cohort sellers from flow. US-0033957 - 6. Approve - Deactivation
 * -------------------------------------------------------------------------------------------------------------------------------
 * Change history: 04.12.2025 / Sophal / Created the component.
 *********************************************************************************************************************************/
import { LightningElement, api } from 'lwc';
import runDeactivateCohortSellerBatch from '@salesforce/apex/CohortActionController.runDeactivateCohortSellerBatch';

export default class CohortUnsyncing extends LightningElement {

        @api bobId;
        @api listBsId = [];
        isReady = false;
        showSpinner = false;
        updateCohortError = null;

    /**
     * @description Component lifecycle hook - validates inputs and initiates cohort seller batch deactivation
     * @author Sophal Noch
     * @date 2025-12-04
     */
    connectedCallback() {
        try {

            this.showSpinner = true;
            this.updateCohortError = null;
            
            runDeactivateCohortSellerBatch({ 
                bobId: this.bobId, 
                listBsId: this.listBsId 
            })
            .then(result => {
                this.showSpinner = false;
                if (result && result.status === 'ok') {
                    this.isReady = true;
                } else {
                    this.updateCohortError = result?.error;
                }
            })
            .catch(error => {
                this.showSpinner = false;
                 this.updateCohortError = error?.body?.message || error?.message || 'Unexpected error occurred';
            });

        } catch (error) {
            this.showSpinner = false;
        }
    }

    /**
     * @description Computed property to determine if there are cohort update errors
     * @returns {Boolean} True if there are errors, false otherwise
     * @author Sophal Noch
     * @date 2025-12-04
     */
    get hasUpdateCohortError() {
        return this.updateCohortError ? true : false;
    }
}