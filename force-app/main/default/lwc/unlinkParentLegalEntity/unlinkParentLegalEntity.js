import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from "lightning/refresh";
import CustomLabels from 'c/customLabels';
import { NavigationMixin } from 'lightning/navigation';
import unlinkParentLegalEntity from '@salesforce/apex/CustomerController.unlinkParentLegalEntity';

export default class UnlinkParentLegalEntity extends NavigationMixin(LightningElement) {

    @api recordId;
    @api showSpinner = false;
    errorMsg;
    label = CustomLabels;

    handleUnlinkParent() {

        this.showSpinner = true;

        unlinkParentLegalEntity({sellerId: this.recordId})
        .then(result =>{
           
            if(result.status == 'ok'){
                this.dispatchEvent(new RefreshEvent());
                //eval("$A.get('e.force:refreshView').fire();");
                this.handleClose();
                this.refresh();
            }else{
                this.errorMsg = result.error;
                console.log('error ', result.error);
            }
            this.showSpinner = false;

        })
        .catch(error => {  
            this.showSpinner = false; 
            this.errorMsg = result.error;  
            console.log('error ', error); 
        });
    }
    refresh() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account',
                actionName: 'view'
        }}).then((url) => {
            window.location.href = url;
        });
    }
    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    get isError(){
        return this.errorMsg ? true : false;
    }

}