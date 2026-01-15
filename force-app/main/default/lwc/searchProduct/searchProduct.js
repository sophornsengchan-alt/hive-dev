import { LightningElement, wire, api } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import { getListUi } from 'lightning/uiListApi';


export default class SearchProduct extends LightningElement {

    data = [];
    products;
    @api selectedProduct;
    @api isValid = false;

    @wire(getListUi, {
        objectApiName: 'HIVE_Products__c',
        listViewApiName: 'All' 
    })
    wiredProducts({ error, data }) {
        if (data) {
            this.products = data.records.records.map((record, index) => {
                let product = record.fields;
                let indexForbackground = index + 1;
                return {
                    label: product.Name.value,
                    value: product.Id.value,
                    idx: index + 1,
                    appicon: this.getAcronym(product.Name.value),
                    pickerSize: 'slds-visual-picker slds-visual-picker_small',
                    appIconBackgroundColor: 'slds-avatar__initials slds-icon-custom-' + indexForbackground
                };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.products = undefined;
        }
    }
    getAcronym(inputString) {
        let words = inputString.split(' ');
        let result = words.map(word => word[0].toUpperCase());
        return result.join('');
    }
    handleProductSelection(event) {
        this.selectedProduct = event.currentTarget.getAttribute("data-value");;
         // If a product is selected, set isValid to true and notify the flow
         if (this.selectedProduct) {
            this.isValid = true;
            const attributeChangeEvent = new FlowNavigationNextEvent('isValid', this.isValid);
            this.dispatchEvent(attributeChangeEvent);

            this.dispatchEvent(new FlowNavigationNextEvent());
        }
    }

     // This method is called when the flow tries to move to the next screen
     @api validate() {
        if (!this.selectedProduct) {
            // If no product is selected, set isValid to false and return an error message
            this.isValid = false;
            return {
                isValid: this.isValid,
                errorMessage: 'Please select a product.'
            };
        } else {
            // If a product is selected, set isValid to true
            this.isValid = true;
            return { isValid: this.isValid };
        }
    }
}