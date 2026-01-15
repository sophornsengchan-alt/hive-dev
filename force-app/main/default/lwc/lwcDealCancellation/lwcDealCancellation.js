/***********************
 * change log: 13-03-2023/ Mony Nou / US-0012628 - Seller Deal Cancellation - on Seller Portal
 * 
 * 
 * *********************** */
import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { publish, MessageContext } from 'lightning/messageService';
import LWC_CONNECTION_CHANNEL from '@salesforce/messageChannel/LWC_Connection__c';

import updateDealStatus from '@salesforce/apex/CustomDealController.processDealCancellation';

import lblTitle from '@salesforce/label/c.Seller_Deal_Cancellation_Title';
import lblCancel from '@salesforce/label/c.Cancel';
import required from '@salesforce/label/c.Required';
// import lblCancellation from '@salesforce/label/c.Seller_Deal_Cancellation';
import lblFieldLabel from '@salesforce/label/c.Seller_Deal_Cancellation_Label';
import lblCancellationButton from '@salesforce/label/c.Seller_Deal_Cancellation_ConfirmButton';


export default class LwcDealCancellation extends NavigationMixin(LightningElement) {
    fieldErrors = {};
    
    @api recId;
    @api viaListView = false; 
    
    Labels = {
        lblTitle, lblCancel, lblCancellationButton, lblFieldLabel, required
    };

    @api isModalOpen = false;
    
    valueCancellationReason = '';
    cancellationReasonsComments = '';
    
    showSpinner = false;
    isDisabled = true;

    renderedCallback() {}

    connectedCallback() {}

    @api doShowModal()
    {
        this.isModalOpen = true;
        
        return false;
    }

    

    get getModalOpen(){
        //if changeStle is true, getter will return class1 else class2
          return this.isModalOpen ? 'show': 'hide';
    }

    @wire(MessageContext)
    messageContext;

    closeModal() {

        this.isModalOpen = false;
        this.showSpinner = false;

        if (this.viaListView) {
            const payload = { 
                action: 'refresh',
            };
            publish(this.messageContext, LWC_CONNECTION_CHANNEL, payload);
        }

    }

    handlReasonsCommentsChange (event) {
        this.cancellationReasonsComments = event.detail.value;

        if (!this.cancellationReasonsComments || this.cancellationReasonsComments == '') {
            this.isDisabled = true;
        }else {
            this.isDisabled = false;
        }
        
    }

    handleCancellation () {

        this.showSpinner = true;

        updateDealStatus({ 
            dealId: this.recId,
            cancelReason: this.cancellationReasonsComments
        })
            .then(result => {
                
                if (result.status == 'ok') {
                    
                    getRecordNotifyChange([{recordId: this.recId}]);
                    window.postMessage({"name":"refreshCount"}, '*');   
                    if (this.viaListView) this.dispatchEvent(new CustomEvent('reload')); 
                    this.closeModal();

                    /*
                    this[NavigationMixin.Navigate]({
                        type: "standard__webPage",
                        attributes: {
                            url: '/my-deal-lists'
                        }
                    });
                    */
                    
                }else{
                    console.log("handleUpdateDealStatusSellerCancellation error",result);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error updating record',
                            message: result.error,
                            variant: 'error'
                        })
                    );
                }
            }).catch(error => {
                this.showSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
                
                console.log('error', error);
            });

        
    }

    
}