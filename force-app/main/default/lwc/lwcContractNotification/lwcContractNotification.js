import { LightningElement, api, wire, track } from 'lwc';
import getExecutedContract from '@salesforce/apex/ContractNotificationController.checkAccountExistingExecutedContract';

export default class LwcSEPToDoList extends LightningElement {

    
    @api recordId;
    @track doShow = false;
    @track contractSellers = [];

    connectedCallback()
    {
        this.getExecutedContract();
    }

    getExecutedContract()
    {
        getExecutedContract({contractId : this.recordId})
        .then(result => {
            console.log('log');
            if(result.data != ""){
                for(let i= 0; i< result.data.length; i++){
                    result.data[i].url = '/'+ result.data[i].EBH_ContractNumber__c;
                }
                this.contractSellers = result.data;
                this.doShow = true;
            }

        })
        .catch(error => {

           console.log('error = ',error);
        });
    }
     
    
}