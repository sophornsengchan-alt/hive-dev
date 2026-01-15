import { api, LightningElement } from 'lwc';

export default class FlowContractUserGuidedUX extends LightningElement {

    /*

        Mode = 1 (default)  => Path (Status Indicator)
        Mode = 5            => Opportunity_Screen_ContractGuided (Status Indicator)
    */
    
    @api mode = 1;


    //Mode 1
    cssClassNameStep = "stepper-item";
    
    //1= Add Seller, 2= Verify Legal Entity, 3= Create Contract
    @api currentStep = 1; //Default 1st step

    @api isStandardVIP = false;

    @api isCreatePricingLA = false;

    @api isTCContractFound = false; //MN-30102025-US-0033722

    
    get showPath() {

        return this.mode == 1;
    }
    get showPath1() {

        return this.mode == 2;
    }

    get showPath2() {

        return this.mode == 3;
    }

    get showPath3() {

        return this.mode == 4;
    }

    //MN-30102025-US-0033722
    get showPath4() {
        return this.mode == 5; 
    }
    
    /**
     * @description Dynamically generates CSS class names for stepper items based on current step
     * @param {number} stepNumber - The step number to generate CSS class for
     * @return {string} CSS class name with appropriate state (active, completed, or default)
     */
    getCssClassNameForStep(stepNumber) {
        if (!stepNumber || stepNumber < 1) {
            return this.cssClassNameStep;
        }
        
        let mode = (this.currentStep === stepNumber) ? " active" : 
                  (this.currentStep > stepNumber) ? " completed" : "";
        return this.cssClassNameStep + mode;
    }

    // Getter methods for template compatibility
    get cssClassNameStep1() {
        return this.getCssClassNameForStep(1);
    }

    get cssClassNameStep2() {
        return this.getCssClassNameForStep(2);
    }

    get cssClassNameStep3() {
        return this.getCssClassNameForStep(3);
    }

    get cssClassNameStep4() {
        return this.getCssClassNameForStep(4);
    }

    get cssClassNameStep5() {
        return this.getCssClassNameForStep(5);
    }
}