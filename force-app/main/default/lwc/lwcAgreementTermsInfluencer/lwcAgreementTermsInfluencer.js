import { LightningElement, api, track,wire } from 'lwc';
    import initAgreementTerms from '@salesforce/apex/AgreementTermsControllerInfluencer.initAgreementTerms';
    import acceptedAgreement from '@salesforce/apex/AgreementTermsControllerInfluencer.acceptedAgreement';
    import { NavigationMixin } from 'lightning/navigation';

    export default class lwcAgreementTermsInfluencer extends NavigationMixin(LightningElement) {

    @track showModal;
    @track error;
    @track isOverlay;
    @api agmtMdtName;
    @track footerContent = '';
    @track downloadContent = '';
    @track fileName = '';

    @api showSpinner = false;
    @track agreementContent;
    @track agreementContentDownload;
    @api hasLogo = false;

    agmtMdt = null;

    BUILDER_DOMAIN = 'builder.salesforce-experience.com';
    PREVIEW_DOMAIN = 'live-preview.salesforce-experience.com';
        
    // initialize component
    connectedCallback() {    

    this.isOverlay = false;
    this.showModal = true;

    initAgreementTerms({agmtMdtName: this.agmtMdtName})
    .then(result => {

        if(result.agmtMdt){  // 16.02.2023 / Sophal Noch / US-0013171 :
            this.agmtMdt = result.agmtMdt;
        }

        // 16.02.2023 / Sophal Noch / US-0013171 :
        this.hasLogo = (this.logoLink && this.logoLink != '') ? true : false;

        this.showModal = result.result;
        this.agreementContent = result.agreementContent;
        this.footerContent = result.footerContent;
        this.downloadContent = result.downloadContent;
        this.fileName = result.fileName;

    })
    .catch(error => { this.error = error; console.log('error >>>>> ', error); });

    }

    get modalTitle() {
        return (this.agmtMdt && this.agmtMdt.Modal_Title__c) ? this.agmtMdt.Modal_Title__c : null;
    }

    get labelAcceptAgreement() {
        return (this.agmtMdt && this.agmtMdt.Label_Accept_Agreement__c) ? this.agmtMdt.Label_Accept_Agreement__c : null;
    }

    get labelLeave() {
        return (this.agmtMdt && this.agmtMdt.Label_Leave__c) ? this.agmtMdt.Label_Leave__c : null;
    }


    get logoLink() {
        return (this.agmtMdt && this.agmtMdt.Logo_Link__c) ? this.agmtMdt.Logo_Link__c : null;
    }

    get region() {
        return (this.agmtMdt && this.agmtMdt.Region__c) ? this.agmtMdt.Region__c : null;
    }

    get regionDownload() {
        return (this.agmtMdt && this.agmtMdt.Region_Download__c) ? this.agmtMdt.Region_Download__c : null;
    }

    get enableTabView() {
        return (this.agmtMdt && this.agmtMdt.Enable_Tab_View__c) ? this.agmtMdt.Enable_Tab_View__c : null;
    }

    get tabItemNumber() {
        return (this.agmtMdt && this.agmtMdt.Tab_Item_Number_Per_View__c) ? this.agmtMdt.Tab_Item_Number_Per_View__c : null;
    }

    get logoutAfterDeclined() {
        return (this.agmtMdt && this.agmtMdt.Logout_After_Declined__c) ? this.agmtMdt.Logout_After_Declined__c : null;
    }

    get headerRightSideContent() {
        return (this.agmtMdt && this.agmtMdt.Header_Right_Side_Content__c) ? this.agmtMdt.Header_Right_Side_Content__c : null;
    }

    get footerRegion() {
        return (this.agmtMdt && this.agmtMdt.Footer_Region__c) ? this.agmtMdt.Footer_Region__c : null;
    }

    get enableDownloadBtn() {
        return (this.agmtMdt && this.agmtMdt.Enable_Download_Button__c) ? this.agmtMdt.Enable_Download_Button__c : null;
    }

    get downloadBtnLabel() {
        return (this.agmtMdt && this.agmtMdt.Download_Button_Label__c) ? this.agmtMdt.Download_Button_Label__c : null;
    }


    handleDownload(event){
    let link = document.createElement('a');
    link.href = 'data:application/pdf;base64,' + this.downloadContent;
    link.target = '_blank';
    link.download = this.fileName;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    }

    forceClosePopup(){
        // when open in experience builder
        let result = false;
        let url = new URL(window.location.href);
        let domain = url.host;
        if(domain.indexOf(this.BUILDER_DOMAIN) !== -1 || domain.indexOf(this.PREVIEW_DOMAIN) !== -1){
            this.showModal = true;
            result = true;
        }

        return result;
    }

    closeModal() {

        if(this.forceClosePopup()){
        return;
        }

        this.showSpinner = true;

        if(this.logoutAfterDeclined){

        let currentUrl = window.location.href;
        let hostName = currentUrl.split("/s/")[0];
        let retUrl = "?retUrl=" + encodeURIComponent((hostName+"/s/login/"));
        let logoutUrl = hostName +"/services/auth/rp/oidc/logout"+retUrl;
        window.location.href = logoutUrl;
        
        }else{
        this.showSpinner = false;
        this.showModal = true;
        this.isOverlay = true;

        // redirect to home page
        this[NavigationMixin.Navigate]({
            type: "standard__namedPage",
            attributes: {
                pageName: 'home'
            }
        });
        }


    }

    acceptAgreement() {

        console.log('agreement button clicked ');

        if(this.forceClosePopup()){
        return;
        }

        this.showSpinner = true;

        acceptedAgreement({region : this.region, regionDownload: this.regionDownload})
        .then(result => {
            this.showSpinner = false;
            // console.log('result accepted >>>>> ', result);

            // this.showModal = (result == 'success') ? true : false; // close modal
            if(result.status == 'ok'){
                this.showModal = true;
                if(result.attachmentId && result.attachmentId != ''){
                window.location.href = "https://"+window.location.hostname+"/sfc/servlet.shepherd/version/download/"+result.attachmentId+"?asPdf=false&operationContext=CHATTER";
                }
            }else{
                this.showModal = false;
                console.log('error acceptedAgreement : ',result.error);
            }


        })
        .catch(error => { this.error = error; console.log('error >>>>> ', error); this.showSpinner = false;});

    }
    }