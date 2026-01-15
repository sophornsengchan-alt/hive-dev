import { LightningElement,api,wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import {CurrentPageReference} from 'lightning/navigation';
import customLabel from 'c/customLabels';
import apexInit from '@salesforce/apex/CancelSubDealDCADetailController.apexInit';
import apexCancelDeals from '@salesforce/apex/CancelSubDealDCADetailController.apexCancelDeals';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class CancelSubDealDCADetail extends LightningElement {
    @api recordId;
    labels = customLabel;
    dealCount = 0;
    hasError = false;
    successCount = 0;
    errorCount = 0;

    showSpinner = false;
    processComplete = false;

    currentChunk = 0;
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
        //console.log('init',this.recordId);
        apexInit({dcaId:this.recordId}).then(result => {
            //console.log('result',result);
            if(result && result.status==="ok")
            {
                this.dealCount = result.numDeals;
            }
        }).catch(error => {
            console.log('error',error);
        });

    }
    handleCancel(e) 
    {
        // Dispatch the CloseActionScreenEvent to close the Quick Action
        this.dispatchEvent(new CloseActionScreenEvent());
        getRecordNotifyChange([{recordId: this.recordId}]);
    }

    handleOK(e)
    {
        this.currentChunk = 0;
        let f_reason = this.template.querySelector('[data-id="Cancellation_Reason__c"]');
        console.log('f_reason',f_reason.value);
        if(f_reason.value)
        {
            console.log('ok');
            this.doApexCancelDeals(f_reason.value);
        } 

    }
    doApexCancelDeals(c_reason)
    {
        this.processComplete = false;
        this.showSpinner = true;
        apexCancelDeals({dcaId:this.recordId,cancelReason:c_reason,currentChunk:this.currentChunk}).then(result => {
            console.log('result',result);
            this.hasError = false;
            if(result && result.status==="ok")
            {
                this.successCount += parseInt(result.sucessCount,10);
                this.errorCount += parseInt(result.errorCount,10);
                
                //all chunks are done
                if(result.done)
                {
                    this.processComplete = true;
                    this.showSpinner = false;
                }else
                {
                    this.currentChunk +=1;
                    this.doApexCancelDeals(c_reason);
                }
                
            }else
            {
                
                this.hasError = true;
                this.showSpinner = false;
                this.showHideMessage(true,'error',result.error,result.errorDetail);
            }
            // this.showHideMessage(true,'error','test errrr','super detail sfs fd  fs\n detail tesdfsdf ');
            // this.hasError = true;
            this.processComplete = true;
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

    get cofirmText()
    {
        return this.labels.CancelSubDealDCADetail_ConfirmMsg;
    }
    get updatedResultText()
    {
        return '<span class="slds-text-color_success">Updated Deals: '+this.successCount+' of '+this.dealCount +'. </span><span class="slds-text-color--error"> Error: '+this.errorCount +'</span>';
    }

    get cancelButtonLabel()
    {
        return this.processComplete?'Close':'Cancel';
    }
}