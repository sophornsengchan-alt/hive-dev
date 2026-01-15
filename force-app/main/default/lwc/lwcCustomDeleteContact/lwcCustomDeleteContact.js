import { LightningElement,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import customLabels from 'c/customLabels';
import checkForValidContact from '@salesforce/apex/CustomDeleteContactController.checkForValidContact';
import createContactRemovalTicket from '@salesforce/apex/CustomDeleteContactController.createContactRemovalTicket';
 
export default class LwcCustomDeleteContact extends  NavigationMixin(LightningElement) {
    @api recordId;
    recordTypeContactRemovalId=null;
    isValidContact =false;
    validationMsg = '';
    showReason = false
    showSpinner = true;
    caseReason="";
    labels = customLabels;
    // caseSummary="";
    connectedCallback() {
        this.init();
    }

    init()
    {
        //console.log('recordId: ', this.recordId);
        checkForValidContact({ conId: this.recordId })
        .then(result => {
            //console.log('result:', result);
            if(result.isValidContact) 
            {
                this.isValidContact = true;
                this.recordTypeContactRemovalId = result.recordTypeContactRemovalId;
                this.showReason = true;
            }else
            {
                this.validationMsg = result.message;
            }
            this.showSpinner = false;
        })
        .catch(error => {
            console.error('Init Error in checkForValidContact:', error);
        });
    }

    get showMessge()
    {
        return this.validationMsg.length > 0;
    }
    handleFieldChanged(event)
    {
        if(event.target.dataset.fname==='reason')
        {
            this.caseReason = event.target.value;
            this.template.querySelector('[data-fname="reason"]').reportValidity();
        }
        // else if( event.target.dataset.fname==='summary__c')
        // {
        //     this.caseSummary = event.target.value;
        // }
       
    }
    doSubmit(event)
    {
        // console.log('doSubmit caseReason: '+this.caseReason);
        // console.log('doSubmit caseSummary: '+this.caseSummary);
        
        if(!this.doValidate())
        {
            console.log('doValidate failed');
        }else
        {
            this.showSpinner = true;
            createContactRemovalTicket({ conId: this.recordId,  caseReason: this.caseReason })
            .then(result => {
                this.showSpinner = false;
                if(result.status === 'ok')
                {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: result.message,
                            variant: 'success',
                        }),
                    );
                    this.doCancel();//refresh the page
                    
                }else if(result.status === 'ko')
                {
                    this.validationMsg = result.message;
                    console.log('errorDetail', result.errorDetail);
                }
            })
            .catch(error => {
                console.error('Error in createContactRemovalTicket:', error);
                this.showSpinner = false;
            });
        }
    }
    doValidate()
    {
        let isValid = true;
        if(this.caseReason===undefined || this.caseReason==='')
        {
            this.template.querySelector('[data-fname="reason"]').reportValidity(); isValid= false;
        }
        // if(this.caseSummary===undefined || this.caseSummary==='')
        // {
        //     this.template.querySelector('[data-fname="summary__c"]').reportValidity(); isValid= false;
        // }

        return isValid;
    }
    doCancel(event)
    {
        this[NavigationMixin.Navigate]({
            type:'standard__recordPage', 
            attributes:{
            "recordId": this.recordId,
            "objectApiName":"Contact",
            "actionName": "view"
            }});
    }
    
}