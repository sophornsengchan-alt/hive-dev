import { LightningElement, api, track } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import doValidate from '@salesforce/apex/CertilogoProductConfigurationController.validateProducts';
import generatedoc from '@salesforce/apex/CertilogoProductConfigurationController.mergeDocument';
import getFieldSetFields from '@salesforce/apex/CertilogoProductConfigurationController.getFieldSetFields';
import { NavigationMixin } from 'lightning/navigation';
import doSubmit from '@salesforce/apex/CertilogoProductConfigurationController.submitProducts'; //MN-21102024-US-0015957
import {isNullorUndefinedorZero } from "c/hiveUtils";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';//SB 15.03.2023 US-0013185

const OpportunityProductDocument_API = 'OpportunityProductDocument__c';
const PostFixButton = 'Button'; //MN-24102024-US-0015957
const btnSplitLine = 'Split Line'; //MN-06032025-US-0016869
const btnDevSplitLine = 'SplitLine'; //MN-06032025-US-0016869
export default class CertilogoProductConfigurationModalAction extends NavigationMixin(LightningElement){

    @api labels = []; // List of labels to be displayed in the modal
    @api buttonName = ''; // Name of the button
    @api buttonMetaData = {}; // Metadata of the button
    @api selectedOppProducts = []; // Selected Opportunity Product
    @api buttonValidations = []; // List of validations to be performed on the button
    @api opportunityId; // Opportunity Id //MN-21112024-US-0016253
    @api rowData = {}; // Row data of the selected product //MN-06032025-US-0016869
    
    @track errorMessage = ''; // Error message to be displayed in the modal
    @track isError = false; // Flag to determine whether to display the error message or not
    @track isLoading = true; // Flag to determine whether to display the spinner or not
    @track isFormLoading = false; // Flag to determine whether to display the spinner in the form or not //MN-21102024-US-0015957
    @track passValidation = false; // Flag to determine whether the button has passed the validation or not
    @track objectApiName; // Object API Name
    @track fieldSetName; // Field Set Name
    @track fields = []; // Fields to be displayed
    @track showAdditionalField = false; // Flag to determine whether to display the form or not
    @track isFieldsLoaded = false; // Flag to determine whether the fields are loaded or not //MN-21102024-US-0015957
    @track quantity; //MN-06032025-US-0016869
    recordId = ''; // Record Id //MN-06032025-US-0016869
    recordData = {}; // Store form data
    refreshScreen = false; // Flag to determine whether to close the modal with view mode or not //MN-21102024-US-0015957
    confirmMsg = ""; //MN-23102024-US-0015957
    productDocId = '';
    productDocrecordtype = "";
    additionalParams = {}; //MN-06032025-US-0016869

    /**
     * Name: connectedCallback
     * Purpose: init method to determine whether the component should be in view mode based on the presence or absence of pbEntries. 
    */
    connectedCallback () {
        this.executeValidation();
    }

    // Get the button label, if it is static button then it doesn't have metadata record then remove the PostFix "Button" at the end of the button name
    get buttonLabel() {
        return (this.isStaticButton) ? this.buttonName : this.buttonName.replace(PostFixButton,''); //MN-24102024-US-0015957
    }

    // Check if the button is static or not, if it is static then it doesn't have metadata record and there will be PostFix "Button" at the end of the button name
    get isStaticButton() {
        return (!this.buttonMetaData);
    }

    // Get the max quantity that can be split
    get maxQuantity() {
        return this.rowData.qty - 1;
    }

    // get the placeholder for the quantity input field
    get qtyPlaceHolder() {
        let msg = (this.maxQuantity > 1) ? "From 1 to " + this.maxQuantity : "";
        return msg;
    }

    // get the error message for the quantity input field
    get errorMessageQtyOverMax() {
        return "Cannot enter an amount that is > " + this.maxQuantity;
    }

    /**
     * Name: executeValidation
     * Purpose: Validate the selected products based on the button validations configured in the metadata
    */
    executeValidation() {
        
        // this.isLoading = true;
        
        //Default and the first validation where at least one product should be selected except for the Generate Order Confirmation button
        if (this.selectedOppProducts.length === 0) {
            this.toggleError(true, this.labels.CertilogoProdConfig_ErrorMsg3);
        }
        else {

            //Check if it is fix button then it doesn't have Metadata record => using Button's label instead
            let buttonDevName = (this.buttonMetaData.DeveloperName) ? this.buttonMetaData.DeveloperName : this.buttonName;
            
            // Call the apex method to validate the selected products
            //MN-21112024-US-0016253:pass oppId to the apex method
            doValidate({oppId: this.opportunityId, oppLineIds : this.selectedOppProducts, buttonName: buttonDevName, validations : this.buttonValidations})
            .then(result => {

                if(result.status == 'success'){
                    
                    if(!result.isPass){
                        this.toggleError(true, result.validationMessage);
                    }else{
                        this.passValidation = true;
                    }
                } 
                else if (result.status == 'error'){
                    this.toggleError(true, result.error);
                }

            }).catch(error => {
                console.error("Error while validating:", error);
                this.toggleError(true, error);
            }).finally(() => {
                
                if (this.passValidation) {
                    this.postValidation();
                }

                this.isLoading = false;

            });

        }
    }

    // Check if the button has additional fields to be displayed
    get hasAdditionalFields() {
        return (this.buttonMetaData && this.buttonMetaData.FieldSet__c !== undefined); //MN-24102024-US-0015957 //MN-06032025-US-0016869
    }

    //MN-06032025-US-0016869
    get isSplitLineButton() {
        return this.buttonName === btnSplitLine;
    }
    
    //MN-21102024-US-0015957
    get showSubmitButton() { 
        return this.isFieldsLoaded || !this.hasAdditionalFields;
    }
    
    /**
     * Name: postValidation
     * Purpose: Post actions after the validation is done
    */
    postValidation() {

        //Check if the button has additional fields to be displayed
        if (this.hasAdditionalFields) {

            this.isFormLoading = true;

            this.objectApiName = OpportunityProductDocument_API;

            // Call the apex method to fetch the additional fields
            getFieldSetFields({objectName : this.objectApiName, fieldSetName: this.buttonMetaData.FieldSet__c})
            .then(result => {
                
                const objectList = result.map(item => {
                    const [field, value] = item.split(';');
                    return {
                        fieldName: field,
                        isrequired: value === 'true'
                    };
                });
                
                this.fields = objectList;
                this.showAdditionalField = true;

            }).catch(error => {
                console.error("Error while fetching additional fields:", error);
                this.toggleError(true, error);
            });

        } 
        else if (this.isSplitLineButton) {
            
            this.recordId = this.rowData.id;

            if (this.maxQuantity === 1) {this.quantity = 1;}
        }
        else {

            this.confirmMsg = this.labels.CertilogoProdConfig_Msg; //MN-23102024-US-0015957
            this.isLoading = false;
        }
    }


    /**
     * Name: toggleError
     * Purpose: toggle the error message
     * @param _isError: boolean
     * @param _errorMessage: string
    */
    toggleError(_isError, _errorMessage) {
        this.isError = _isError;
        this.errorMessage = _errorMessage;
        this.isLoading = false;
    }

    /**lo
     * Name: closeModal
     * Purpose: close the modal
    */
    closeModal() {

        const closeEvent = new CustomEvent('closemodal', {detail: {refreshScreen : this.refreshScreen}});
        this.dispatchEvent(closeEvent);
    }
    /**
     * Name: previewfile
     * Purpose: handle preview conga document on parent component
    */
    previewfile(contentid) {

        const openfile = new CustomEvent('previewfile', {detail: {fileid:contentid}});
        this.dispatchEvent(openfile);

    }
    /**
     * Name: handlelodingparent
     * Purpose: used to display loading icon on parent component
    */
    handlelodingparent(load) {

        const doload = new CustomEvent('loader', {detail: {load:load}});
        this.dispatchEvent(doload);

    }
    /**
     * Name: handleCancel
     * Purpose: when click on "Cancel" button to close the Modal with confirmation 
    */
    async handleCancel() {

        const result = await LightningConfirm.open({
            message: this.labels.CertilogoProdConfig_ConfirmMsg,
            variant: 'headerless',
            label: '',
        });

        //Confirm has been closed
        //result is true if OK was clicked
        //and false if cancel was clicked
        if(result){
            this.closeModal();
        }
    }

    /**
     * Name: handleOnLoad
     * Purpose: handle the onLoad event of the lightning-record-edit-form
    */
    handleOnLoad(event) {
        
        this.isFormLoading = false; //MN-21102024-US-0015957
        this.isFieldsLoaded = true; //MN-21102024-US-0015957
    }

    /**
     * Name: handleError
     * Purpose: handle the error
    */
    handleError(error) {
        console.error('Error occurred:', error);
        this.toggleError(true, error); //MN-21102024-US-0015957
    }

    /**
     * Name: handleCustomSubmit
     * Purpose: handle the form submission
    */
    handleCustomSubmit(event) {

       if (this.hasAdditionalFields) {
            let isError = false;
            event.preventDefault(); // Prevent the default form submission

            // Get all lightning-input-field components within the form
            let inputFields = this.template.querySelectorAll('lightning-input-field');

            try {
                
                // Loop through each input field to gather values
                inputFields.forEach(field => {
                    let fieldName = field.fieldName; // Get field name
                    let fieldValue = field.value; // Get field value
                    /*
                    if(fieldName === 'ShippingDate__c' && isNullorUndefinedorZero(fieldValue)){
                        isError = true;
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error on Submit',
                                message: 'Please enter Shipping Date',
                                variant: 'error',
                            }),
                        );
                        
                    }
                    */
                    //MN-07032025-US-0016899: Validate required fields before submit
                    if (field.required && isNullorUndefinedorZero(fieldValue)) {
                        field.reportValidity(); // Show error message
                        isError = true;
                    }
                    
                    this.recordData[fieldName] = fieldValue; // Add to recordData object
                });

            }catch(error){
                console.error("Error while fetching additional fields:", error);
                return;
            }
            

            
            if(isError){
                return;
            }
            

       }
       else if (this.isSplitLineButton) {

            // Get the input field
            const inputField = this.template.querySelector('[data-field="qtyInput"]');

            // Check validity
            if (inputField.checkValidity()) {
                inputField.reportValidity(); // Show validation message (if any)
            }else {
                inputField.reportValidity(); // Show validation error
                return;
            }

       }

       // Call the apex method to validate the selected products
       this.submitProducts(); //MN-21102024-US-0015957

    }

    /**
     * Name: submitProducts
     * Purpose: submit the selected products and action it as per button's configuration in CertilogoButtonService apex class
    */
    submitProducts() { //MN-21102024-US-0015957
        this.toggleError(false, '');
        this.confirmMsg = ""; //MN-23102024-US-0015957
        this.isLoading = true;
        //Check if it is fix button then it doesn't have Metadata record => using Button's label instead
        let buttonDevName = (this.buttonMetaData.DeveloperName) ? this.buttonMetaData.DeveloperName : this.buttonName;

        //MN-06032025-US-0016869
        if (this.isSplitLineButton) { 
            buttonDevName = btnDevSplitLine + PostFixButton; 
            // Create a new object with an additional property
            let mAdditionalParams = { ...this.rowData, splitqty: this.quantity };
            this.additionalParams = mAdditionalParams;
        } 

        doSubmit({oppLineIds : this.selectedOppProducts, buttonName: buttonDevName, oppProdDoc : this.recordData, mAdditionalParams : this.additionalParams})
        .then(result => { 
            if(result.status == 'success'){
                this.showAdditionalField = false;
                this.refreshScreen = true;
                this.productDocId = result.opdId;
                this.productDocrecordtype = result.opdIdtype;
                this.closeModal();
                if(this.productDocrecordtype !== undefined || this.productDocrecordtype == 'PurchaseOrder' || this.productDocrecordtype == 'ShippingDocument' || this.productDocrecordtype == 'ProFormaInvoice'|| this.productDocrecordtype == 'ConfirmationOrder'){
                    this.handlelodingparent(true);
                    this.generateCongaDocument();    
                }//US-0015966
                       
            }else {
                this.toggleError(true, result.error);
            }
        }).catch(error => {
            console.error("Error while validating:", error);
            this.toggleError(true, error);
        }).finally(() => {
            this.isLoading = false;
        });

    }
    /**
     * Name: generateCongaDocument
     * Purpose: handle the conga document generation
    */
    generateCongaDocument() {  //US-0015966
        generatedoc({oppProdDocId : this.productDocId, docRecordType: this.productDocrecordtype})
        .then(result => {
            if(result.status == 'success'){
              let cdid = result.cdid;
              this.handlelodingparent(false);
              this.previewfile(cdid);
              this.closeModal();  
            }else {
                this.toggleError(true, result.error);
            }
        }).catch(error => {
            console.error("Error while validating:", error);
            this.toggleError(true, error);
        });
    }
    
    /**
     * Name: handleSplitLineQTYChange
     * Purpose: handle the qunatity change for split line button
    */
    handleSplitLineQTYChange(event) { //MN-06032025-US-0016869
        
        this.quantity = event.detail.value;

    }
}