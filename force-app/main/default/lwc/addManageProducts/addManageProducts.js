/*********************************************************************************************************************************
@ Component:      addManageProducts
@ Version:        1.0
@ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:        Handle the Add/Manage Products functionality
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.09.2024 / Sambath Seng / US-0015493 Create the component
                : 10.12.2024 / Sothea Horn / US-0016235 - ADS - Apply Filters on Price books in Edit line items screen
*********************************************************************************************************************************/
import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import customLabels from 'c/customLabels';
import getPriceBooks from '@salesforce/apex/CertilogoAddManageProductsController.getPriceBooks';
import updateOpportunityPricebook from '@salesforce/apex/CertilogoAddManageProductsController.updateOpportunityPricebook';
import opportunityHasLineItems from '@salesforce/apex/CertilogoAddManageProductsController.opportunityHasLineItems';
import getlistofProducts from '@salesforce/apex/CertilogoAddManageProductsController.getlistofProducts';
import opptyDetails from '@salesforce/apex/CertilogoAddManageProductsController.getOpptyDetails';


export default class addManageProducts extends NavigationMixin(LightningElement) {

    productColumn = [
        { label: 'Product Name', fieldName: 'productName' },
        { label: 'Product Code', fieldName: 'productCode' },
        { label: 'List Price', fieldName: 'listPrice' },
        { label: 'Product Description', fieldName: 'productDescription'},
        { label: 'Product Family', fieldName: 'productFamily'}
    ]; //By default, each column will have a datatype as text.

    labels = customLabels;

    // Price Book Selector Variables
    @api oppId;
    @api hasLineItems;
    

    @track showPricebookSelector = false;
    @track priceBooks = [];
    @track filteredPriceBooks = [];
    @track searchKey = '';
    @track selectedPriceBookId = null;
    // Product Selector Variables
    @track showProductSelector = false;
    // Product Configurator Variables
    @track showProductConfigurator = false;
    @track productDataList = [];
    @track productDataFinal = [];
    
    selectedData = []; //contains the oppty line item ids that the user selected on the table in Screen 2 (product selector)
    opportunityCurrency = '';

    prodNameCodetextValue = '';
    prodFamilySelectedValue = '';
    showSpinner = true;
    isFromAddMore = false;
    clickedOnProdSelectorNext = false;
    

    connectedCallback() {
        
        // Check if opportunity has line items
        opportunityHasLineItems({ opportunityId: this.oppId })
            .then((result) => {
                if(result === false){
                    this.showPricebookSelector = true;
                } else {
                    this.showProductConfigurator = true;
                }
                this.showSpinner = false;
            })
            .catch(error => {
                console.log(error);
            });

            this.getOpptyDetails();
    }

    /*********************************************************************************************************************************
     @ Change history: 10.12.2024 / Sothea Horn / US-0016235 - ADS - Apply Filters on Price books in Edit line items screen
    *********************************************************************************************************************************/
    @wire(getPriceBooks, { opportunityId: '$oppId'})
    wiredPriceBooks({ error, data }) {
        if (data) {
            if (data.status == 'ok') {
                this.priceBooks = data.pricebooks;
            } else if (data.status == 'ko') {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Failed to get Pricebooks',
                        message: data.error,
                        variant: 'error'
                    })
                );
            }
        } else if (error) {
            console.error('error', error);
        }
    }

    /**
    * This method is used to search for pricebook
    */
    handleSearchKeyChange(event) {
        this.searchKey = event.target.value.toLowerCase();
        // If search key is empty, reset the filteredPriceBooks and selectedPriceBookId
        if (this.searchKey === '') {
            this.filteredPriceBooks = [];
            this.selectedPriceBookId = null;
        } else {
            // Filter pricebooks based on search key
            this.filteredPriceBooks = this.priceBooks.filter(priceBook =>
                priceBook.Name?.toLowerCase().includes(this.searchKey)
            );
        }
    }

    /**
    * This method is used to store selected pricebook and reset the search key
    */
    handlePriceBookSelect(event) {
        this.selectedPriceBookId = event.target.dataset.id;
        this.searchKey = event.target.dataset.name;
        this.filteredPriceBooks = [];
    }

    handleCancel() {
        
        if (this.isFromAddMore && this.showProductSelector) { //If Product Selector is open from button "Add More" on Product Configurator Page then return to Product Configurator Page in View Mode
            this.selectedData = [];
            this.handleProductSelectorNext();
        }
        else if (this.showPricebookSelector) { //MN-23102024: If Pricebook Selector is open then return to Opportunity Page
            this.handleClose();
        }
        else {
            window.history.back(); // Navigate back to the previous page
        }
        
        
        
    }

    /**
    * This method is used to call apex method to update opportunity after click next button
    */
    handlePricebookNext() {
        this.showSpinner = true;
        updateOpportunityPricebook({ opportunityId: this.oppId, pricebookId: this.selectedPriceBookId })
            .then((result) => {
                if(result.status == 'success'){
                    this.showPricebookSelector = false;
                    this.showProductSelector = true;
                    this.getProductsData(this.oppId);
                    this.showSpinner = false;
                } else if (result.status == 'error'){
                    this.showSpinner = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: this.labels.CertilogoAddManageProductsUpdateError,
                            variant: 'error'
                        })
                    );
                }
            })
            .catch(error => {
                this.showSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: this.labels.CertilogoAddManageProductsUpdateError,
                        variant: 'error'
                    })
                );
            });
    }

    /**
    * Make next button disabled if no pricebook is selected
    */
    get isNextDisabled() {
        return this.selectedPriceBookId === null;
    }

    /* This method is used to get the related products data under the pricebook 
    */
    getProductsData(oppId){
        this.showSpinner = true;
        getlistofProducts({ opportunityId: oppId})
            .then((result) => {
                if(result){
                    this.productDataList = result.map(item => {
                        return {
                          productId: item.Id,
                          productName: item.Name,
                          productCode: item.Product2.ProductCode,
                          listPrice: this.opportunityCurrency+' '+item.UnitPrice,
                          productDescription: item.Product2.Description,
                          productFamily: item.Product2.Family                          
                        };
                      });
                    this.showSpinner = false;
                    this.productDataFinal = this.productDataList;
                } else{
                    this.showSpinner = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'INFO',
                            message: 'No products found',
                            variant: 'info'
                        })
                    );
                }
            })
            .catch(error => {
                this.showSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: this.labels.CertilogoAddManageProductsUpdateError,
                        variant: 'error'
                    })
                );
            });
    }

    //User can enter a keyword - this will search product name, code and description for like matches using '%<keyword>%'
    handleProductNameInputChange(event) {
        this.prodNameCodetextValue = event.detail.value;
        try{
            let keywordLowerCase = this.prodNameCodetextValue?.toLowerCase();
            const filteredData = this.prodNameCodetextValue.length >= 3 
                                ? this.productDataFinal.filter(word => word.productCode?.toLowerCase().indexOf(keywordLowerCase) > -1 || word.productDescription?.toLowerCase().indexOf(keywordLowerCase) > -1 || word.productName?.toLowerCase().indexOf(keywordLowerCase) > -1)
                                : this.productDataFinal;
            
            if(filteredData.length > 0){
                this.productDataList = filteredData;
            }

            if(this.prodNameCodetextValue.length === 0){
                this.productDataList = this.productDataFinal;
            }
            
        }catch(error){
            console.log('error-->'+error)
        }
    }

    /**
     * get product family options for the the Certilogo product record
     */
    /*get prodFamilyoptions() {
        return this.labels.Certilogo_product_family.split(';').map(item => {
            return { label: item, value: item };
        });
    }*/
    get prodFamilyoptions() {
        return [{ label: '', value: '' }, ...this.labels.Certilogo_product_family.split(';').map(item => {
            return { label: item, value: item };
        })];
    }

    /**
     * user an enter a product family - this will search for products matching the product family. 
     * This is a picklist based on the Product2.ProductFamily for the Certilogo product record type
     * @param {*} event 
     */
    handleProdFamilyChange(event) {
        this.prodFamilySelectedValue = event.detail.value;
        try{
            const filteredData = this.productDataFinal.reduce((accumulator, item) => {
                if (item.productFamily !== undefined && item.productFamily === this.prodFamilySelectedValue) {
                    accumulator.push(item);
                }
                return accumulator;
            }, []);
            if(filteredData.length > 0){
                this.productDataList = filteredData;
            }
            if(filteredData.length === 0){
                this.productDataList = [];
            }

            if(this.prodFamilySelectedValue.length === 0){ //if user selects nothing(blank), reset
                this.productDataList = this.productDataFinal;
            }
            
        }catch(error){
            console.log('error==>'+error)
        }
    }

    /**
     * This method is used to store selected products when user clicks on checkboxes
     * @param {*} event 
     */
    handleRowSelection(event) {
        switch (event.detail.config.action) {
          case 'selectAllRows':
            for (let i = 0; i < event.detail.selectedRows.length; i++) {
              this.selectedData.push(event.detail.selectedRows[i].productId);
            }
            break;
          case 'deselectAllRows':
            this.selectedData = [];
            break;
          case 'rowSelect':
            this.selectedData.push(event.detail.config.value);
            break;
          case 'rowDeselect':
            this.selectedData = this.selectedData.filter(function (e) {
              return e !== event.detail.config.value;
            });
            break;
          default:
            break;
        }
    }

    handleProductSelectorNext(){
        //show product configurator page here.
        this.showProductConfigurator = true;
        this.showProductSelector = false; 
        this.clickedOnProdSelectorNext = true;   
        //this.selectedData contains all the row ids
    }

    /**
     * Name: handleOpenProdSelection
     * Purpose: This method is used to open the product selection screen
     * @param event
    */
    handleOpenProdSelection(event) {

        this.isFromAddMore = event.detail.isFromAddMore;

        this.selectedData = [];
        this.getProductsData(this.oppId);
        this.showProductSelector = true;
        this.showProductConfigurator = false;
    }

    /**
     * Name: handleClose
     * Purpose: This method is to reidrect to the opportunity page
     * @param event
    */
    handleClose(event) {

        //use function below instead of NavigationMixin.Navigate because it can refresh record detail page after redirect
        this[NavigationMixin.GenerateUrl]({ 
            type: 'standard__recordPage',
            attributes: {
                recordId: this.oppId,
                actionName: 'view'
            }
        }).then((url) => {
            window.open(url, '_self');
        });

    }

    /**
     * Name: getOpptyDetails
     * Purpose: This method is to get the opportunity details on page load
    */
    getOpptyDetails(){
         // Check if opportunity has line items
         opptyDetails({ opportunityId: this.oppId })
         .then((result) => {
             this.opportunityCurrency = result.CurrencyIsoCode;
             this.showSpinner = false;
         })
         .catch(error => {
             console.log(error);
         });
    }

    

}