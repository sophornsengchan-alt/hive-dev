import { LightningElement,api,wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import {CurrentPageReference} from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import customLabel from 'c/customLabels';
import apexInviteSeller from '@salesforce/apex/InviteSellerSubDealDCADetailController.apexInviteSeller';
 
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class InviteSellerSubDealDCADetail extends LightningElement {
    @api recordId;
    labels = customLabel;
   
    hasError = false;
    showSpinner = false;
    processComplete = false;
    dontSendToSeller = false;
    connectedCallback()
    {
        this.init();
    }
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) 
    {
        if (currentPageReference) 
            {
            this.recordId = currentPageReference.state.recordId;           
        }
    }
 
    init()
    {
       

    }
    handleCancel(e) 
    {
        // Dispatch the CloseActionScreenEvent to close the Quick Action
        this.dispatchEvent(new CloseActionScreenEvent());
        getRecordNotifyChange([{recordId: this.recordId}]);
    }

    handleOK(e)
    {
        this.doInvite();
    }
    handleChkSendChanged(e)
    {
        this.dontSendToSeller = e.target.checked;
        // console.log('dontSendToSeller',this.dontSendToSeller);

    }
    doInvite()
    {
        this.processComplete = false;
        this.showSpinner = true;
        let moreParams = {dontSendToSeller:this.dontSendToSeller};
        apexInviteSeller({dcaId:this.recordId,moreParam:moreParams}).then(result => {
            // console.log('result',result);
            this.hasError = false;
            this.showSpinner = false;
            this.processComplete = true;

            if(result && result.status==="ok")
            {
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: "DCA Updated Successfully",
                //         variant: 'success'
                //     })
                // );
                this.handleCancel(null);

            }else
            {
                this.hasError = true;
                this.showSpinner = false;
                this.showHideMessage(true,'error',result.error,result.errorDetail);
            }
 
            
        }).catch(error => {
            console.log('error',error);
            this.hasError = true;
            this.processComplete = true;
            this.showSpinner = false;
            this.showHideMessage(true,'error',error+'','');
            
        });
    }
    showHideMessage(state,type,message,msgDetail)
    {
        let msgObj = {type:type,msg:message,msgDetail:msgDetail}
        let msgBlock = this.template.querySelector('c-lwc-message');
        if (msgBlock) {
            msgBlock.setMessage(msgObj,state,0);
        }
    }

    get cancelButtonLabel()
    {
        return this.processComplete?'Close':'Cancel';
    }
}