/*

  change log
    - 15/05/2023/vadhanak voun (vadhanak.voun@gaea-sys.com) / US-0013471 - 4. Seller should be able to download the contract on the Deal Overview page
    - 15/01/2024/Sambath Seng/US-0013136 - Seller_Portal_Status__c - Deprecate
    - 01/04/2025/Sovantheany Dim/US-0016979 - Business Testing feedback - Subsidy per sold item is required in DCA related list
*/
import { LightningElement, api,track,wire  } from 'lwc';
import { getRecord} from 'lightning/uiRecordApi';
import lblResubmit from '@salesforce/label/c.Re_Submit';
import lwcCancelButton from '@salesforce/label/c.lwcCancelbtn';//Loumang:12-01-2022:US-0010747
import lblReadjust from '@salesforce/label/c.Re_Adjust';//Sophal:17-03-2022:US-0011032
import lblCancellation from '@salesforce/label/c.Seller_Deal_Cancellation'; //MN-13032023-US-0012628
import lblBackButton from '@salesforce/label/c.SEP_BACK_BUTTON'; //MN-15032023-US-0012628
import lblDCADownloadButton from '@salesforce/label/c.SEP_Label_DownlaodDCA'; //NKL15/05/2023:US-0013471
import checkDCA from '@salesforce/apex/SEPDealContractAgreementController.checkDCA';

import { NavigationMixin,CurrentPageReference } from 'lightning/navigation';//Loumang:12-01-2022:US-0010747

export default class LwcButtonsHorizon extends  NavigationMixin(LightningElement)  {

    labels = {     
      lblResubmit,
      lwcCancelButton,
      lblReadjust,
      lblBackButton,//MN-15032023-US-0012628
      lblCancellation, //MN-13032023-US-0012628
      lblDCADownloadButton//NKL15/05/2023:US-0013471
    };

    @api resubmit_deal; //button visiblity from ui config
    @api recordId;
    @track canResubmit;
    @track canReadjust;
    @track canResubmitOrCanReadjust;
    @track canCancel; //MN-13032023-US-0012628

    @track showModal;
    @track showDownloadDCA = false; //NKL15/05/2023:US-0013471
    @track att_id;
    @track att_title;

    // cancellationStatus = ["New Deal proposed to eBay","Editable"]; //MN-15032023-US-0012628
    cancellationStatus = ["New","Processing","Ops Review"]; //Sambath Seng - 15/01/2024 - US-0013136

    backURL = ''; //TH:US-0016979:01/04/2025
    cancelURLDefault = '/my-deal-lists';
    @wire(getRecord, { recordId: '$recordId', fields: ['EBH_Deal__c.Can_ReSubmit__c','EBH_Deal__c.Can_ReAdjust__c', 'EBH_Deal__c.EBH_Status__c'] })
    wiredDeal({ error, data }) 
    {
      // console.log("--currentDeal data : "+JSON.stringify(data) +" - recordId: "+ this.recordId);
      
      if(data != undefined)
      {         
        this.canResubmit = data.fields.Can_ReSubmit__c.value;
        this.canReadjust = data.fields.Can_ReAdjust__c.value; //Sophal:18-03-2022:US-0011032
        // this.canCancel = this.cancellationStatus.includes(data.fields.Seller_Portal_Status__c.value); //MN-13032023-US-0012628
        this.canCancel = this.cancellationStatus.includes(data.fields.EBH_Status__c.value); //Sambath Seng - 15/01/2024 - US-0013136
        this.canResubmitOrCanReadjust = ((this.canResubmit || this.canReadjust) && !this.canCancel) ? true : false; //Sophal:18-03-2022:US-0011032 //MN-13032023-US-0012628

      }
       
      // console.log("--  wire canResubmit: " ,this.canResubmit);
      
      
    }

    //TH:US-0016979:01/04/2025
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) {
            this.currentPageReference = currentPageReference;
            this.backURL = currentPageReference.state?.retURL;
       }
    }

    //init
    connectedCallback() {
 
      console.log("-init-");
      this.initDCACheck();
     
    }
     
    showModalResubmit()
    {
       let child_lwc = this.template.querySelector('c-lwc-modal-resubmit-deal');
        console.log(child_lwc);

      child_lwc.doShowModal();

    
    }

    showModalReadjust()
    {
      //Sophal:18-03-2022:US-0011032
      let child_lwc = this.template.querySelector('c-lwc-modal-readjust-deal');
      child_lwc.doShowModal();
    }
    
    //MN-13032023-US-0012628
    showModalCancellation () {
      let child_lwc = this.template.querySelector('c-lwc-deal-cancellation');
      child_lwc.doShowModal();
    }

    cancelhandler() { //Loumang:12-01-2022:US-0010747
      //TH:01.04.2025:US-0016979 : onClick back to retURL
      let sepUrl = this.backURL != null && this.backURL != '' ? this.backURL : this.cancelURLDefault;
      let url = '';
      if(sepUrl.indexOf('/') === -1){
        url = '/' + sepUrl;
      }
      this[NavigationMixin.Navigate]({
          type: "standard__webPage",
          attributes: {
            // SB 16-3-2022 US-0011312
            url: url
          }
      });
      
    } 
   

    initDCACheck()
    {
      checkDCA({dealId: this.recordId})
      .then(result => {
         
           console.log('result checkDCA .. ', result);
          if(result.status == 'ok' && result.showBtn)
          {
              this.att_id =  result.att_id;
              this.att_title = result.att_title;
              this.showDownloadDCA = result.hasContract;
          }
      })
      .catch(error => {console.log('error checkDCA.. ', error); });

    }

    handleDownloadDCAClick()
    {
      console.log("download dca");
      window.location.href = "https://"+window.location.hostname+"/sfc/servlet.shepherd/version/download/"+this.att_id +"?asPdf=false&operationContext=CHATTER";
    }
}