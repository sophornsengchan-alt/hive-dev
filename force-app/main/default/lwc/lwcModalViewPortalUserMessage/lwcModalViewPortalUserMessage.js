import { LightningElement, api, track } from 'lwc';
import initAgreementTerms from '@salesforce/apex/CreatePortalUserMessageController.initAgreementTerms';
import acceptedAgreement from '@salesforce/apex/CreatePortalUserMessageController.acceptedAgreement';
import getPortalUserMessageModal from '@salesforce/apex/CreatePortalUserMessageController.getPortalUserMessageModal';
import updateModalRead from '@salesforce/apex/CreatePortalUserMessageController.updateModalRead';


import { NavigationMixin } from 'lightning/navigation';

export default class LwcModalViewPortalUserMessage extends NavigationMixin(LightningElement) {

    @track showModal;
    @track portalUserMessageId;
    @track error;
    @track isOverlay;
    @api modalTitle;
    @api labelAcceptAgreement;
    @api labelLeave;   
    @track outputText;

      //
      
    // initialize component
  connectedCallback() {
    this.isOverlay = false;
    this.showModal = false;
    this.loadAllRecords();
       
  }

    acceptAgreement() {       

      // console.log('agreement button clicked ');
      
        // acceptedAgreement()
        // .then(result => {
        //     console.log('result accepted >>>>> ', result);
        //     this.showModal = (result == 'success') ? false : true; // close modal
        //     this.isOverlay = (result == 'success') ? false : true; 
        // })
        // .catch(error => { this.error = error; });

        updateModalRead({"portalUserMessageId" : this.portalUserMessageId})
        .then(result => {
          this.showModal = false;
          this.isOverlay = false;
        })
        .catch(error => {
          this.error = error; });
    }

    loadAllRecords() {       

      // console.log('loadAllRecords ');

      getPortalUserMessageModal()
      .then(result => {
        // console.log(">>>>>MyReuslt:::::", result);

          if(result && result.length > 0){
              this.showModal = true;
              this.isOverlay = true;
              // console.log(">>>>>MyReuslt:::::", result);
              if(result[0].Name) this.modalTitle = result[0].Name;
              if(result[0].Content__c) this.outputText = result[0].Content__c;
              this.portalUserMessageId = result[0].Id;  
          }

      })
      .catch(error => { 
          console.log(">>>>>first load ERROR:", error);
      }); 

    }
}