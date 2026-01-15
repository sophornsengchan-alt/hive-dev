import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord } from 'lightning/uiRecordApi';
import getBobSellerId from '@salesforce/apex/CohortActionController.getBobSellerId';


import Cancel from '@salesforce/label/c.Cancel';
import Next from '@salesforce/label/c.Next';
import Close from '@salesforce/label/c.Close';

import Update_Cohort_Status from '@salesforce/label/c.Update_Cohort_Status';
import Choose_Status from '@salesforce/label/c.Choose_Status';
import Close_Modal_When_BatchCohortAction_Running from '@salesforce/label/c.Close_Modal_When_BatchCohortAction_Running';

export default class UpdateCohortStatus extends LightningElement {

    @api recordId;

    Labels = { 
        Cancel,
        Next,
        Close,
        Update_Cohort_Status,
        Choose_Status,
        Close_Modal_When_BatchCohortAction_Running
    };

    FIELDS = ['BOB__c.Id'];

    fromCohort = true;
    isProTrader = false;

    bob = {};

    listStatusOption = [];
    selectedOption = '';
    isReady = false;
    showSpinner = false;

    isBatchRunning = false;
    isChooseStatus = false;
    isActivateCohort = false;
    isDeactivateCohort = false;

    step = 1;


    @wire(getRecord, { recordId: '$recordId', fields: '$FIELDS'} )
    wiredRecord({ error, data }) 
    {

        if(this.isReady){return;}

        if (data) {
            this.showSpinner = true;
            getBobSellerId({bobId : this.recordId, fromCohort : this.fromCohort})
            .then(result =>{
                this.showSpinner = false;
                if(result.status == 'ok'){

                    this.isReady = true;
                     
                    if(result.isBatchRunning){
                         this.isBatchRunning = result.isBatchRunning; 
                         return;
                    }

                    this.bob = result.bob;
                    this.isProTrader = result.isProTrader;

                    this.isChooseStatus = true;
                    for(let i = 0; i < result.listStatusOpt.length; i++){
                        let opt = result.listStatusOpt[i];
                        if(opt.value != this.bob.Status__c){
                            opt['key'] = opt.value.replace(' ','_');
                            this.listStatusOption.push(opt);
                        }
                    }
                        
                    if(this.listStatusOption.length > 0){
                        this.listStatusOption[0]['checked'] = true;
                        this.selectedOption = this.listStatusOption[0].value;
                    }

                }else{
                    console.log('error ',result.error);
                }

            })
            .catch(error => {  this.showSpinner = false; console.log('error ', error); });
            

        }
       
    }


    handleClose(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
        
    handleNext(e) {

        if(this.selectedOption && this.selectedOption != ''){
            if(this.selectedOption == 'BoB Active'){
                this.isChooseStatus = false;
                this.isActivateCohort = true;
            }else if(this.selectedOption == 'BoB Inactive'){
                this.isChooseStatus = false;
                this.isDeactivateCohort = true;
            }
        }

    }

    handleChooseStatus(event){
        if(event.detail && event.detail){
            if(event.detail == 'prev'){
                this.isChooseStatus = true;
                this.isActivateCohort = false;
                this.isDeactivateCohort = false;
            }

        }
    }

    handleChangeStatus(event) {
        this.selectedOption = event.target.value;
        let listStatusOption = [];
        for(let i = 0; i < this.listStatusOption.length; i++){
            if(this.listStatusOption[i].value ==  this.selectedOption){
                this.listStatusOption[i]['checked'] = true;
            }else{
                this.listStatusOption[i]['checked'] = false;
            }
            listStatusOption.push(this.listStatusOption[i]);
        }
        this.listStatusOption = listStatusOption;
       
        
    }


}