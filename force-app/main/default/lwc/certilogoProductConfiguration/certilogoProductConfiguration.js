/*********************************************************************************************************************************  
    @ Change history: 24.10.2024 / Acmatac Seing / US-0015949 Certilogo - Product Selector and Configurator Part 5 - Product Configurator - Side Button Visibility
                      04.11.2024 / Sambath Seng / US-0016089 - Certilogo - updates to Product Configurator - post Sprint 113
                      12.11.2024 / Veenus Gollapalli / US-0015966 - Certilogo - Docgen - 4 docs to be generated
*********************************************************************************************************************************/

import { LightningElement,api,wire, track } from 'lwc';
import { getRecord} from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import { showToastMessage } from "c/hiveUtils";
import LightningConfirm from 'lightning/confirm';
import FREQUENCY_FIELD from '@salesforce/schema/OpportunityLineItem.Frequency__c';
import customLabel from 'c/customLabels';
import doInitData from '@salesforce/apex/CertilogoProductConfigurationController.initData';
import doSaveRecord from '@salesforce/apex/CertilogoProductConfigurationController.saveRecords';

const batchSize = 200;
const btnSplitLine = 'Split Line'; //MN-06032025-US-0016869

export default class CertilogoProductConfiguration extends NavigationMixin(LightningElement) {

    @api opportunityId; 
    @api pricebookId; 
    @api pbEntries = []; 
    @api isLaunchedFromProdSelector = false;

    @track isExpandedView = true;
    @track isViewMode = true;
    @track oppProducts = [];
    @track isAccountLocatedInEU = false;
    @track freqOption;
    @track selectedOppProducts = []; //MN-15102024-US-0015948
    @track selectedButton = ''; //MN-15102024-US-0015948
    @track selectedButtonMeta = ''; //MN-15102024-US-0015948
    @track selectedButtonDevName = ''; //MN-15102024-US-0015948
    @track selectedButtonValidations = []; //MN-16102024-US-0015948
    @track hasActiveConfirmOrder = true; //MN-21112024-US-0016253:AC5

    showSpinner = false;
    isModalOpen = false;
    Labels = customLabel;
    FIELDS = ['Opportunity.Account.Located_in_EU__c'];
    // Sambath US-0016089 Filter the record type to get the picklist values
    filter = {criteria: [
        {
            fieldPath: 'RecordType.Name',
            operator: 'eq',
            value: 'Certilogo'
        }
    ]};
    objectInfoData;
    defaultRecordTypeId='012000000000000AAA'; //Since Opportunity Line Item does not have record type and we cannot use empty string in getPicklistValues, we will use the default record type id for Opportunity Line Item
    isError = false;
    errorMessage = '';

    topButtons = []; //MN-15102024-US-0015948
    buttonValidations = []; //MN-16102024-US-0015948

    rowData = {}; //MN-06032025-US-0016869
    
    /**
     * Name: connectedCallback
     * Purpose: init method to determine whether the component should be in view mode based on the presence or absence of pbEntries. 
    */
    connectedCallback () {

        let columnLabel = this.Labels.CertilogoProdConfig_Columns;
        this.tableColumn = columnLabel.split(',');
        this.isViewMode = (this.pbEntries === undefined || this.pbEntries.length === 0);

        this.loadInitData();
    }

    /**
     * Name: frequencyPicklistValue
     * Purpose: use this method to retrieve Opportunity Line Item's Frequency picklist values
     * @param default record type id 
     * @param FREQUENCY_FIELD
    */
    @wire(getPicklistValues, {
        recordTypeId: '$defaultRecordTypeId',
        fieldApiName: FREQUENCY_FIELD
    })
    frequencyPicklistValue;

    /**
     * Name: wiredRecord
     * Purpose: this method is to get the Account's Located_in_EU__c field value
     * @param recordId 
     * @param FIELDS
    */
    @wire(getRecord, { recordId: '$opportunityId', fields: '$FIELDS'} )
    wiredRecord({ error, data }) 
    {

        if (data) {
            this.isAccountLocatedInEU = data.fields.Account.value.fields.Located_in_EU__c.value;
        }
        else if (error) {
            this.toggleError(true, error);
            showToastMessage(this, {title: 'Error', variant: 'error', message: error});
        }
        
       
    }
    
    /**
     * Name: loadInitData
     * Purpose: this method is to get the Opportunity Line Items related to the Opportunity and prepare records to display on screen
     * @param opportunityId 
     * @param pricebookId (selected pricebook id from the Pricebook Selector)
     * @param pbEntries (selected Products (pricebookentry) from the Product Selector)
    */
    loadInitData() {
        doInitData({opportunityId : this.opportunityId, pricebookId : this.pricebookId, sPricebookEntrytIds : this.pbEntries})
        .then(result => {
            if(result.status == 'success'){
                this.hasActiveConfirmOrder = result.hasActiveConfirmOrder; //MN-21112024-US-0016253:AC5
                this.oppProducts = [];
                this.oppProducts = result.data;
                
                this.oppProducts.forEach(item => {
                    //SRONG 18.04.2025 - US-0017105 - Certilogo - Allow Deliver To to be entered for Freight
                    if(item.hasManufacturer || item.isProdFamilyFreight){
                        item['isShowDeliverTo'] = true;
                    }else{
                        item['isShowDeliverTo'] = false;
                    }
                    //MN-06112024-US-0016092: Added this.isViewMode in criteria so that when we select no product from Product Seclection screen => all row display in view mode
                    if(this.isLaunchedFromProdSelector && (item.oli.InvoiceStatus__c === 'Draft' && !item.hasAnyActiveOppProdDocument && !this.isViewMode)){ 
                        item.editMode = true;
                        item.viewMode = false;
                    }else{
                        item.viewMode = true;
                        item.editMode = false;
                    }

                    this.isViewMode &= item.viewMode; //MN-23102024: ViewMode is true when all items are in view mode

                  });

                this.topButtons = result.topButtons.sort((a, b) => a.metadata.ButtonOrder__c - b.metadata.ButtonOrder__c); //MN-15102024-US-0015948
                this.buttonValidations = result.buttonValidation; //MN-16102024-US-0015948     
                
            } else if (result.status == 'error'){
                this.toggleError(true, this.Labels.CertilogoProdConfig_ErrorMsg1);
                showToastMessage(this, {title: 'Error', variant: 'error', message: this.Labels.CertilogoProdConfig_ErrorMsg1});
            }

        }).catch(error => {
            this.toggleError(true, error);
            showToastMessage(this, {title: 'Error', variant: 'error', message: error});
        });
    }

    get rowSpan() {
        return this.isExpandedView? 2 : 1;
    }

    get viewMode() {
        return this.isViewMode;
    }

    get editMode() {
        return !this.isViewMode;
    }

    /**
     * Name: handleOpenModal
     * Purpose: Open Modal when click on the button
     * @param e
    */
    handleOpenModal(e) {
        
        let idx = e.target.dataset.id;
        
        try {

            this.selectedButtonMeta = (idx !== undefined && this.topButtons[idx] !== undefined)?this.topButtons[idx].metadata:{};
            this.selectedButton = e.target.label;
            
            let cloneProds = JSON.parse(JSON.stringify(this.oppProducts));
            let selectedOliIds = [];
            
            //If the button is "Generate Order Confirmation", get all line products Ids
            if (this.selectedButtonMeta && this.selectedButtonMeta.MasterLabel === this.Labels.CertilogoProdConfig_BtnGenerateOrderConfirmation) {  
                selectedOliIds = cloneProds
                .filter(product => product)
                .map(product => product.oli.Id);
            } 
            //Else Filter to get only "oli.Id" where selected is true
            else { 
                selectedOliIds = cloneProds
                .filter(product => product.selected === true)
                .map(product => product.oli.Id);
            }
            

            this.selectedOppProducts = selectedOliIds;

            

            // Get the validations for the selected button and sort it by ValidationOrder__c
            let cloneValidations = JSON.parse(JSON.stringify(this.buttonValidations));
            this.selectedButtonValidations = [];
            if (cloneValidations[this.selectedButton] !== undefined) {
                this.selectedButtonValidations = cloneValidations[this.selectedButton].sort((a, b) => a.ValidationOrder__c - b.ValidationOrder__c);
            }
            
            //Since we cannot create Service Class name with "Delete" because it matches with the reserved keyword, we will append "Button" to the button name
            this.selectedButton = (this.selectedButton === this.Labels.Delete)?this.selectedButton+"Button":this.selectedButton;

            //MN-06032025-US-0016869
            if (this.selectedButton === btnSplitLine) {
                this.selectedOppProducts = [...this.selectedOppProducts, idx];
                
                let tmp = {
                    qty : e.target.dataset.qty,
                    id : idx
                };
                
                this.rowData = tmp;
            }

            this.isModalOpen = true;

        }catch(err){
            console.log(err);
        }
        
    }

    /**
     * Name: handleCloseModal
     * Purpose: Close Modal when click on "Cancel" or "X" button
     * @param e
    */
    handleCloseModal(e) {
        this.isModalOpen = false;
        if (e.detail.refreshScreen !== undefined && e.detail.refreshScreen) { //Refresh screen after completed action of a button
            this.loadInitData();
        }
    }
    /**
     * Name: openfile
     * Purpose: open conga document on window when event received by child component
     * @param e
    */
   //US-0015966
    openfile(e) {
        this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId:e.detail.fileid
            }
        });
    } 
    /**
     * Name: handleloding
     * Purpose: display loading icon on window when event received by child component
     * @param e
    */
   
    handleloding(e) { //US-0015966

        if (e.detail.load !== undefined ) { //Refresh screen after completed action of a button
            this.showSpinner = e.detail.load;
        }
    }

    /**
     * Name: handleToggleChange
     * Purpose: when click on "Expanded View" Toggle
     * @param e
    */
    handleToggleChange(e) {
        this.isExpandedView = e.target.checked;
        
    }

    /**
     * Name: handleClose
     * Purpose: when click on "Close" button
     * @param e
    */
    handleClose(e) {

        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);

    }

    /**
     * Name: calculateTotalPrice
     * Purpose: calculate the total price based on the quantity and unit price
     * @param e
    */
    calculateTotalPrice(e) {

        let idx = e.target.dataset.id;

        let qty = (e.target.name === 'quantity')?e.target.value:this.oppProducts[idx].oli.Quantity;
        let unitPrice = (e.target.name === 'unitPrice')?e.detail.value:this.oppProducts[idx].oli.UnitPrice;
        // let totalPrice = ((parseInt(qty, 10) || 0) * (parseFloat(unitPrice) || 0)).toFixed(2);  //MN-24012025-US-0016547
        let totalPrice = ((parseInt(qty, 10) || 0) * (parseFloat(unitPrice) || 0)); //MN-24012025-US-0016547
        
        let cloneProds = JSON.parse(JSON.stringify(this.oppProducts));
        cloneProds[idx].oli.Quantity = qty;
        cloneProds[idx].oli.UnitPrice = unitPrice;
        cloneProds[idx].oli.TotalPrice = totalPrice;

        this.oppProducts = cloneProds;

    }

    /**
     * Name: handleChangeValue
     * Purpose: when change the value of Delivery To, Frequency, Description, need to update the value in the oppProducts for reactive rendering
     * @param e
    */
    handleChangeValue(e) {

        let idx = e.target.dataset.id;
        let fname = e.target.name;
        let value = e.detail.value || e.detail.recordId;
        let cloneProds = JSON.parse(JSON.stringify(this.oppProducts));

        switch (fname) {
            case 'frequency':
                cloneProds[idx].oli.Frequency__c = value;
                break;
            case 'description':
                cloneProds[idx].oli.Description = value;
                break;
            case 'select':
                cloneProds[idx].selected = e.target.checked;
            default:
                break;
        }

        this.oppProducts = cloneProds;
    }

    handleDeliveryToChangeValue(e) {
        let idx = e.target.dataset.id;
        let value = e.target.value;
        let cloneProds = JSON.parse(JSON.stringify(this.oppProducts));
        cloneProds[idx].oli.DeliveryTo__c = value;
        this.oppProducts = cloneProds;
    }

    /**
     * Name: handleEdit
     * Purpose: when click on "Edit" button
     * @param e
    */
    handleEdit(){
        this.isViewMode = false;
        //US-0015950 
        this.oppProducts.forEach(item => {
            if (item.oli.InvoiceStatus__c === 'Draft' && !item.hasAnyActiveOppProdDocument) {
              item.editMode = true;
              item.viewMode = false;
            }else{
                item.viewMode = true;
                item.editMode = false;
            }
        });
          
    }

    /**
     * Name: handleAddMore
     * Purpose: when click on "Add More" button
     * @param e
    */
    handleAddMore(e) {
        const openEvent = new CustomEvent('openproductselector', {detail: {isFromAddMore: true}});
        this.dispatchEvent(openEvent);
    }

    /**
     * Name: handleSave
     * Purpose: when click on "Save" button
     * @param e
    */
    handleSave(e) {

        this.showSpinner = true;
        
        // Call the method to validate inputs
        if (this.validateInputs()) {
            // If all inputs are valid, proceed with your logic (e.g., submit form)
            this.doSave(0, false);
            
        } else {
            // If inputs are invalid, show error message
            this.toggleError(true, this.Labels.CertilogoProdConfig_ErrorMsg2);
            showToastMessage(this, {title: 'Error', variant: 'error', message: this.Labels.CertilogoProdConfig_ErrorMsg2});
            this.showSpinner = false;
        }
      
    }

    /**
     * Name: handleSaveClose
     * Purpose: when click on "Save and Close" button
     * @param e
    */
    handleSaveClose(e) {

        this.showSpinner = true;

        // Call the method to validate inputs
        if (this.validateInputs()) {
            // If all inputs are valid, proceed with your logic (e.g., submit form)
            this.doSave(0, true);
            
        } else {
            // If inputs are invalid, show error message
            this.toggleError(true, this.Labels.CertilogoProdConfig_ErrorMsg2);
            showToastMessage(this, {title: 'Error', variant: 'error', message: this.Labels.CertilogoProdConfig_ErrorMsg2});
            this.showSpinner = false;
        }

    }

    /**
     * Name: validateInputs
     * Purpose: method to validate all required inputs inside the component
     @ Return: true if all inputs are valid
    */
    validateInputs() {

        // Get all the input elements inside the component
        const inputs = this.template.querySelectorAll('lightning-input, lightning-textarea');
        let allValid = true;

        // Loop through each input and check validity
        inputs.forEach(input => {
            if (!input.checkValidity()) {
                // If input is invalid, call reportValidity() to display the error
                input.reportValidity();
                allValid = false;
            }
        });

        // Return true if all inputs are valid
        return allValid;
    }

    /**
     * Name: doSave
     * Purpose: when click on "Save and Close" button
     * @param indexStartFrom (index of the product to start saving)
    */
    doSave(indexStartFrom, goToOppRecord){

        let listRecordToSave = this.oppProducts
        .slice(indexStartFrom)  // Slicing from indexStartFrom to avoid manual loop
        .map(prod => {
            let oli = { ...prod.oli };  // Spread operator to create a shallow copy
            oli.OpportunityId = this.opportunityId;
            // Sambath US-0016089 Add AutoRenewal__c = true to OppLineItem if BillingType__c = 'SaaS'
            if(prod.prod.BillingType__c === 'SaaS'){
                oli.AutoRenewal__c = true;
            }
            
            //MN-06112024-US-0016092: For discount products, the unit price should be negative but will display positive on screen
            if(prod.prod.IsDiscount__c === true) {
                oli.UnitPrice *= -1; 
            }

            // Remove unnecessary fields
            delete oli.PricebookEntry;
            delete oli.Product2;
            delete oli.DeliveryTo__r;
            delete oli.TotalPrice;
            
            return oli;
        })
        .slice(0, batchSize);  // Limit the result to the batchSize

        doSaveRecord({ listRecord:listRecordToSave })
        .then(result => {

            if (result.status == 'success') {
                let batchEndIndex = indexStartFrom + listRecordToSave.length;

                if(batchEndIndex >= this.oppProducts.length){
                    if (goToOppRecord) {
                        this.isViewMode = true;
                        //MN-06112024-US-0016092: Set all rows to view mode before closing
                        this.oppProducts.forEach(item => {
                            item.viewMode = true;
                            item.editMode = false;
                            
                        });
                        this.toggleError(false, '');
                        this.handleClose();
                    }else{
                        this.isViewMode = true;
                        this.resetData();
                    }
                }else {
                    this.doSave(batchEndIndex, this.oppProducts);
                }

                   
            }
            else {

                this.toggleError(true, result.error);
                showToastMessage(this, {title: 'Error', variant: 'error', message: result.error});
                
            }

        })
        .catch(error => {
            this.toggleError(true, this.Labels.errorMsg1);
            showToastMessage(this, {title: 'Error', variant: 'error', message: this.Labels.errorMsg1});
        })
        .finally(() => {
            this.showSpinner = false;
        });

        

    }

    /**
     * Name: toggleError
     * Purpose: toggle the error message
    */
    toggleError(_isError, _errorMessage) {
        this.isError = _isError;
        this.errorMessage = _errorMessage;
    }

    /**
     * Name: resetData
     * Purpose: reset the data
    */
    resetData() {
        this.toggleError(false, '');
        this.pbEntries = [];
        this.isLaunchedFromProdSelector = false; //MN-23102024: Reset the flag so that the component will be in view mode
        this.loadInitData();
    }

    /**
     * Name: handleCancel
     * Purpose: when click on "Cancel" button to cancel the changes with confirmation 
    */
    async handleCancel() {

        const result = await LightningConfirm.open({
            message: this.Labels.CertilogoProdConfig_ConfirmMsg,
            variant: 'headerless',
            label: '',
        });

        //Confirm has been closed
        //result is true if OK was clicked
        //and false if cancel was clicked
        if(result){
            
            this.isViewMode = true;
            this.resetData();
        }
    }
    
    previewHandler(e){
        let idx = e.target.dataset.id;
        this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId: e.target.dataset.id
            }
        })
    }
}