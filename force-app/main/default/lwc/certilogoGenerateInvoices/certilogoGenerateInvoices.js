import { LightningElement,track} from 'lwc';
import apexGenerateInvoices from '@salesforce/apex/CertilogoGenerateInvoicesController.generateBillInv';
import apexGenerateFrequencyBillInv from '@salesforce/apex/CertilogoGenerateInvoicesController.generateFrequencyBillInv';

export default class CertilogoGenerateInvoices extends LightningElement {
    
    @track isShowModal = false;

    handleClick() {
        this.isShowModal = true;
    }

    handleGenerateInvoice() {

        apexGenerateInvoices()
        .catch(error =>{
            console.log(error);
        });
        
        apexGenerateFrequencyBillInv()
        .catch(error =>{
            console.log(error);
        });

        this.isShowModal = false;
    
    }
    
    handleCancel() {
        this.isShowModal = false;
    }

   
}