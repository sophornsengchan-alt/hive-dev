/*********************************************************************************************************************************
@ lwc:          ConfirmDealUploadDcaSep
@ Version:        1.0
@ Author:         vadhanak voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        US-0016415 - 11 - Seller Self Initiated Deal Upload on Seller Portal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25/02/2025 / vadhanak voun / Created the lwc.
@                06/06/2025 / vadhanak voun / US-0032878 - Re-label the Record type and add description
*********************************************************************************************************************************/
import { LightningElement,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import createNewDca from '@salesforce/apex/DealBulkUploadDcaSubController.createNewDca';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import {getPicklistValuesByRecordType} from 'lightning/uiObjectInfoApi';
import DCA_OBJECT from '@salesforce/schema/Deal_Contract_Agreement__c';

import customLabels from 'c/customLabels';
export default class ConfirmDealUploadDcaSep extends NavigationMixin(LightningElement){
    recordTypeDCASubId;
    picklistValuesCat;
    selectedCat="";
    selectedEmail="";
    selectedAccount="";

    error;
    labels = customLabels;
    showModal = false;
    showSpinner = false;
    connectedCallback()
    {
         
    }
    @wire(getObjectInfo, { objectApiName: DCA_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            //console.log("data",data);
            // Get the record type ID by name
            //NK:06/06/2025:US-0032878 - relabel sub deal rt
            const recordTypeName = 'Item Level Subsidy Deals';//'Subsidized Deals'; //not support dev name
            const recordTypes = data.recordTypeInfos;
            this.recordTypeDCASubId = Object.keys(recordTypes).find(rtId => recordTypes[rtId].name === recordTypeName);
        } else if (error) {
            this.error = error;
        }
    }
    @wire(getPicklistValuesByRecordType, { objectApiName: DCA_OBJECT, recordTypeId: '$recordTypeDCASubId' })
    picklistValues({ data, error }) 
    {
        if (data) 
        {
            // Get picklist values for a specific field
            const fieldName = 'Category__c'; // Replace with your picklist field API name
            this.picklistValuesCat = data.picklistFieldValues[fieldName].values;
        } else if (error) 
        {
            this.error = error;
        }
    }

    handlePklCatChange(event)
    {
        this.selectedCat = event.target.value;
        // console.log("selectedCat",this.selectedCat);
    }
    // handleTxtEmailChange(event)
    // {
    //     let valid = event.target.validity.valid;
    //     console.log("valid",valid);
    //     this.selectedEmail = event.target.value;
    //     console.log("selectedEmail",this.selectedEmail);
    // }
     
    showPopup()
    {
        this.showModal = true;
    }
    hidePopup()
    {
        this.showModal = false;
    }

    handleContinue()
    {
        // console.log("handleContinue") 
        let isValidPkl = this.simpleValidate("pklCategory");           
        let isValidEmail = this.simpleValidate("txtEmail"); 
       
       if(!isValidPkl || !isValidEmail || (this.selectedAccount===""||this.selectedAccount===null))
       {
        return;
       }

       const emailInput = this.template.querySelector('[data-element="txtEmail"]');
       this.selectedEmail = emailInput.value;

       this.processNewDCA();
    }
    simpleValidate(elName)
    {
        const eleOne = this.template.querySelector('[data-element="'+elName+'"]');
        let isValid = false;
        if(eleOne)
        {
            isValid = eleOne.checkValidity();
            if(!isValid)
            {
                eleOne.reportValidity();
            }
        }
        return isValid;
    }
    processNewDCA()
    {
        this.showHideSpinner(true);
        let mapParam = {catManagerEmail:this.selectedEmail, category:this.selectedCat, accountId:this.selectedAccount};
        createNewDca({mapParam:mapParam})
        .then(result => {
            //console.log("result",result);

            this.showHideSpinner(false);

            if(result.status==="ok")
            {
                this[NavigationMixin.Navigate]({
                    type: "standard__webPage",
                    attributes: {
                        url: "/s/upload-multiple-sub-deals?recordId="+result.dcaId
                    }
                });

            }else
            {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'DCA Creation Failed',
                        message: result.error,
                        variant: 'error',
                        mode:'sticky'
                    }),
                );    
                console.log("error",result);
            }
            
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'DCA Creation Failed',
                    message: error,
                    variant: 'error',
                    mode:'sticky'
                }),
            );    
            console.log("error",error);
            this.showHideSpinner(false);
        });
    }

    handleAccountChange(event)
    {
        this.selectedAccount = event.detail.selectedVal;
        //console.log("selectedAccount",this.selectedAccount);
    }

    showHideSpinner(spinnerState)
    {
        this.showSpinner = spinnerState;
    }
}