import { LightningElement, api, track,wire } from 'lwc';
  import initAgreementTerms from '@salesforce/apex/AgreementTermsControllerSEP.initAgreementTerms';
  import acceptedAgreement from '@salesforce/apex/AgreementTermsControllerSEP.acceptedAgreement';
  import { NavigationMixin } from 'lightning/navigation';

  export default class lwcAgreementTermsSEP extends NavigationMixin(LightningElement) {

    @track showModal;
    @track error;
    @track isOverlay;
    @api agmtMdtName;
    @api modalTitle;
    @api labelAcceptAgreement;
    @api labelLeave;
    @api headerRightSideContent;
    @track hasRightSideContent = false;
    @api enableDownloadBtn;
    @track fileName = '';

    @api showSpinner = false;
    @track agreementContent;
    @track agreementContentDownload;
    @api logoLink;
    @api hasLogo = false;
    @api enableTabView;
    @api tabItemNumber;
    countItemHasTab = 0
    finishConfigureScroll = false;
    @api logoutAfterDeclined;
    @track listAgreementObj = [];
    @track agreementBodyClientWidth = -1;

    @api mapArgs; // 16.03.2023 / Sophal Noch / US-0012238

    hasItemOnTop = false;
    hasItemOnBottom = false;

    BUILDER_DOMAIN = 'builder.salesforce-experience.com';
    PREVIEW_DOMAIN = 'live-preview.salesforce-experience.com';

    storeDetail = false;

    TXT_TAB_VIEW_MODAL_CONTAINER_CLASS = 'slds-modal__container slds-is-relative tabViewModalContainer';

    @track tabViewModalContainerClass = '';

    TXT_TAB_CLASS = 'tabItem';
    TXT_TAB_HIDE_CLASS = 'tabItem hide';
    TXT_TAB_HIGHLIGHT_CLASS = 'tabItem active';

    TXT_TOP_ITEM_PADDING = ' topItemPadding';
    TXT_BOTTOM_ITEM_PADDING = ' bottomItemPadding';

    TXT_TABVIEW_AGMBODY_CLASS = '.tabViewAgmBody';
    TXT_TABVIEW_AGMSECTION_CLASS = '.tabViewAgmSection';

    TXT_START_HEIGHT = 'startHeight';
    TXT_END_HEIGHT = 'endHeight';

    DEFAULT_TAB_ITEM_NUMBER = 10;

    tabFirstIndex = -1;
    tabLastIndex = -1;

    agmtMdt = null;

    renderedCallback(){
      
        this.initScrollConfig();
      
    }
    
    initScrollConfig(){

      // logic is copied from lwcAgreementTerms

      // 20.01.2023 / Sophal Noch / US-0012730

      if(!this.enableTabView || this.finishConfigureScroll) return;

      let atBody = this.template.querySelector(this.TXT_TABVIEW_AGMBODY_CLASS);
      if(!atBody) return;
      let atSections = atBody.querySelectorAll(this.TXT_TABVIEW_AGMSECTION_CLASS);
      if(!atSections || !atSections.length) return;

      this.finishConfigureScroll = true;
      if(this.listAgreementObj.length != atSections.length){
        console.log('this.listAgreementObj.length == ',this.listAgreementObj.length);
        console.log('atSections.length == ',atSections.length);
        return;
      }
      
      let elemHeigh = 0;
      for(let i = 0; i < atSections.length; i++){


        this.listAgreementObj[i][this.TXT_START_HEIGHT] = elemHeigh;
        this.listAgreementObj[i][this.TXT_START_HEIGHT] -= this.listAgreementObj[i].offsetTopNumber;

        elemHeigh +=  atSections[i].scrollHeight;
        

        elemHeigh += this.listAgreementObj[i].offsetBottomNumber;
        this.listAgreementObj[i][this.TXT_END_HEIGHT] = elemHeigh;


      }

      this.agreementBodyClientWidth = atBody.clientWidth;

    }

      //
      
    // initialize component
  connectedCallback() {

    this.tabViewModalContainerClass = 'slds-modal__container slds-is-relative';

    this.isOverlay = false;
    this.showModal = true;

    initAgreementTerms({agmtMdtName: this.agmtMdtName})
    .then(result => {

      // 15.03.2023 / Sophal Noch / US-0012238 : trigger event when agreement is inititialized.
        let payload = {
          agmtMdtName : this.agmtMdtName,
          init : true,
          status : result.status ? result.status : null
        }
        const custEvent = new CustomEvent(
            "agreementtermssepinit", {
                detail : payload
            });
        this.dispatchEvent(custEvent);


        if(result.status == 'ok'){ // 15.03.2023 / Sophal Noch / US-0012238 : use mapResult.status to check error or not

          if(result.agmtMdt && !result.agmtMdt.Always_Need_To_Agree__c && result.isRTSellerPortal){ // 23.03.2023 / Sophal Noch / US-0012238  : add !result.agmtMdt.Always_Need_To_Agree__c to the condition

            let payload = { // 23.03.2023 / Sophal Noch / US-0012238 
              agmtMdtName : this.agmtMdtName,
              accepted : true // no need TC agreement to show for ferderated user.
            }
            const custEvent = new CustomEvent(
                "agreementtermssepaccepted", {
                    detail : payload
                });
            this.dispatchEvent(custEvent);

            return;
          }
  
          if(result.agmtMdt){  // 16.02.2023 / Sophal Noch / US-0013171 :
  
            this.agmtMdt = result.agmtMdt;
  
          }
  
            // 16.02.2023 / Sophal Noch / US-0013171 :
          this.hasLogo = (this.logoLink && this.logoLink != '') ? true : false;
          this.tabItemNumber = !this.tabItemNumber ? this.DEFAULT_TAB_ITEM_NUMBER : this.tabItemNumber;
          if(this.enableTabView){
            this.tabViewModalContainerClass = this.TXT_TAB_VIEW_MODAL_CONTAINER_CLASS;
          }
  
  
          if(this.enableTabView){
            
            if(result.agreementContent){
              
              let agreementParts = result.agreementContent.split('<!--section-->');
  
              let agreementLength = agreementParts.length;
  
              let activeTabIndex = 0
  
              for(let i = 0; i < agreementLength; i++){
                
                if(agreementParts[i]){
  
                  let matchResult = agreementParts[i].match(/<!--tab=(.+?)-->/);
                  let tabName = (matchResult && matchResult.length > 1) ? matchResult[1] : '';
                  let hasTab = (matchResult && matchResult.length > 1) ? true : false;
  
                  if(hasTab && activeTabIndex == 0) {this.tabFirstIndex = i;}
  
  
                  this.countItemHasTab = this.countItemHasTab + (hasTab ? 1 : 0);
                  let tabClassName = hasTab ? this.TXT_TAB_CLASS : this.TXT_TAB_HIDE_CLASS;
  
                  let offsetTopNumber = 0
                  let matchOffsetTopResult = agreementParts[i].match(/<!--offsetTop=(.+?)-->/);
                  let hasOffsetTop = (matchOffsetTopResult && matchOffsetTopResult.length > 1) ? true : false;
                  if(hasOffsetTop) offsetTopNumber = parseInt(matchOffsetTopResult[1]);
  
                  let offsetBottomNumber = 0
                  let matchOffsetBottomResult = agreementParts[i].match(/<!--offsetBottom=(.+?)-->/);
                  let hasOffsetBottom = (matchOffsetBottomResult && matchOffsetBottomResult.length > 1) ? true : false;
                  if(hasOffsetBottom) offsetBottomNumber = parseInt(matchOffsetBottomResult[1]);
  
                  this.listAgreementObj.push({
                    key: i,
                    tabName : tabName,
                    hasTab : hasTab,
                    content : agreementParts[i],
                    tabClass : tabClassName,
                    offsetTopNumber : offsetTopNumber,
                    offsetBottomNumber : offsetBottomNumber
                  });
  
                  if(hasTab){ 
                    this.tabLastIndex = i;
                    activeTabIndex++;
                  }
  
                }
  
              }
  
              if(this.tabItemNumber > 0 && this.countItemHasTab > 0 && this.countItemHasTab > this.tabItemNumber){
                this.hideTabItemNotInView(0);
              }else{
                this.removeTopAndBottomPaddingTabItem(this.tabFirstIndex, this.tabLastIndex);
              }
              
  
              this.showModal = result.result;
  
            }
          }else{
            this.showModal = result.result;
            this.agreementContent = result.agreementContent;
          } 
        }else{
          console.log('error >>>>> ', result.error);
        }

 

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

  get redirectUrlAterDeclined() {  // 15.03.2023 / Sophal Noch / US-0012238
    return (this.agmtMdt && this.agmtMdt.Redirect_Url_After_Declined__c) ? this.agmtMdt.Redirect_Url_After_Declined__c : null;
  }

  get closeAgmtAterDeclined() {  // 15.03.2023 / Sophal Noch / US-0012238
    return (this.agmtMdt && this.agmtMdt.Close_Agreement_After_Declined__c) ? this.agmtMdt.Close_Agreement_After_Declined__c : null;
  }

  get hideLeaveBtn() { // 03.04.2023 / Sophal Noch / US-0012899
    return (this.agmtMdt && !this.agmtMdt.Label_Leave__c) ? true : false;
  }

  get hideAcceptBtn() { // 03.04.2023 / Sophal Noch / US-0012899
    return (this.agmtMdt && !this.agmtMdt.Label_Accept_Agreement__c) ? true : false;
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

    if(this.closeAgmtAterDeclined){ // 15.03.2023 / Sophal Noch / US-0012238

      let payload = { // 15.03.2023 / Sophal Noch / US-0012238 : trigger event when agreement is declined
        agmtMdtName : this.agmtMdtName,
        accepted : false
      }
      const custEvent = new CustomEvent(
          "agreementtermssepaccepted", {
              detail : payload
          });
      this.dispatchEvent(custEvent);

      this.showModal = false;
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

      if(this.redirectUrlAterDeclined && this.redirectUrlAterDeclined != ''){  // 15.03.2023 / Sophal Noch / US-0012238

        this[NavigationMixin.Navigate]({
          type: "standard__webPage",
          attributes: {
              url: this.redirectUrlAterDeclined
          }
        });

      }else{
        // redirect to home page
        this[NavigationMixin.Navigate]({
          type: "standard__namedPage",
          attributes: {
              pageName: 'home'
          }
        });
      }


    }


  }

  acceptAgreement() {

    console.log('agreement button clicked ');

    if(this.forceClosePopup()){
      return;
    }

    this.showSpinner = true;
      // 16.03.2023 / Sophal Noch / US-0012238 : add mapArgs param
      acceptedAgreement({agmtMdtName: this.agmtMdtName, mapArgs : this.mapArgs})
      .then(result => {
          this.showSpinner = false;
          // console.log('result accepted >>>>> ', result);

          // this.showModal = (result == 'success') ? true : false; // close modal
          if(result.status == 'ok'){
            this.showModal = true;
            if(result.attachmentId && result.attachmentId != ''){
              window.location.href = "https://"+window.location.hostname+"/sfc/servlet.shepherd/version/download/"+result.attachmentId+"?asPdf=false&operationContext=CHATTER";
            }

            // 15.03.2023 / Sophal Noch / US-0012238 :
            if(result.attachmentContent){
              let link = document.createElement('a');
              link.href = 'data:application/pdf;base64,' + result.attachmentContent;
              link.target = '_blank';
              link.download = result.attachmentTitle;
              document.body.appendChild(link);
              link.click();
              document.body.removeChild(link);
            }

            let payload = {  // 15.03.2023 / Sophal Noch / US-0012238 : trigger event when agreement is accepted
              agmtMdtName : this.agmtMdtName,
              accepted : true
            }
            const custEvent = new CustomEvent(
                "agreementtermssepaccepted", {
                    detail : payload
                });
            this.dispatchEvent(custEvent);

          }else{
            this.showModal = false;
            console.log('error acceptedAgreement : ',result.error);
          }
      })
      .catch(error => { this.error = error; console.log('error >>>>> ', error); this.showSpinner = false;});

  }

  onAgreementTermScroll(event){

    // 20.01.2023 / Sophal Noch / US-0012730

    if(this.enableTabView){

      if(event && event.target && (event.target.scrollTop || event.target.scrollTop === 0)){

        let scrollTop = event.target.scrollTop;

        let atBody = this.template.querySelector(this.TXT_TABVIEW_AGMBODY_CLASS);

        if(this.finishConfigureScroll && this.agreementBodyClientWidth != atBody.clientWidth){
          this.finishConfigureScroll = false;
          this.initScrollConfig();
        }


        let needPagination = false;
        let activeItemPageIndex = 0;
      

        let trackLength =  atBody.scrollHeight - atBody.clientHeight;

        let scrolledPercentage = Math.floor((scrollTop/trackLength) * 100);

        let scrolledHeight =  atBody.scrollHeight * (scrolledPercentage / 100);

        let agreementLength = this.listAgreementObj.length;
        
        let foundActiveTabBefore = false;
        let existTabIndex = 0;
        for(let i = 0; i < agreementLength; i++){

          this.listAgreementObj[i].tabClass = this.TXT_TAB_CLASS;

          if(!this.listAgreementObj[i].hasTab){
            this.listAgreementObj[i].tabClass = this.TXT_TAB_HIDE_CLASS;
          }

          if(scrolledHeight >= this.listAgreementObj[i][this.TXT_START_HEIGHT] && scrolledHeight < this.listAgreementObj[i][this.TXT_END_HEIGHT]){

            if(foundActiveTabBefore){
              // in case overlap active tap happen, remove active from previous tab :
              for(let j = 0; j < i; j++){
                if(this.listAgreementObj[j].hasTab){
                  this.listAgreementObj[j].tabClass = this.TXT_TAB_CLASS;
                }
              }
              foundActiveTabBefore = false;
            }

            if(this.listAgreementObj[i].hasTab){
              foundActiveTabBefore = true;
              this.listAgreementObj[i].tabClass = this.TXT_TAB_HIGHLIGHT_CLASS;
            }

            if(this.tabItemNumber > 0 && this.countItemHasTab > 0 && this.countItemHasTab > this.tabItemNumber){
              needPagination = true;
              activeItemPageIndex = Math.floor(existTabIndex /  this.tabItemNumber);
            }

          }

          if(this.listAgreementObj[i].hasTab){
            existTabIndex++;
          }

        }

        if(needPagination){
          this.hideTabItemNotInView(activeItemPageIndex);
        }else{
          this.removeTopAndBottomPaddingTabItem(this.tabFirstIndex, this.tabLastIndex);
        }
      
      }  
  
    }


  }

  removeTopAndBottomPaddingTabItem(firstIndexOfThePage, lastIndexOfThePage){
    if(firstIndexOfThePage > -1){
      this.listAgreementObj[firstIndexOfThePage].tabClass = this.listAgreementObj[firstIndexOfThePage].tabClass + this.TXT_TOP_ITEM_PADDING;
    }

    if(firstIndexOfThePage > -1 && lastIndexOfThePage != firstIndexOfThePage){
      this.listAgreementObj[lastIndexOfThePage].tabClass = this.listAgreementObj[lastIndexOfThePage].tabClass + this.TXT_BOTTOM_ITEM_PADDING;
    }
  }

  hideTabItemNotInView(activeItemPageIndex){
    let startIndex = 0;
    let firstIndexOfThePage = -1;
    let lastIndexOfThePage = -1;
    for(let i = 0; i < this.listAgreementObj.length; i++){
      if(this.listAgreementObj[i].hasTab){
        let itemPageIndex = Math.floor((startIndex) / this.tabItemNumber);
        if(itemPageIndex != activeItemPageIndex){
          this.listAgreementObj[i].tabClass = this.TXT_TAB_HIDE_CLASS;
        }else{
          if(firstIndexOfThePage == -1){
            firstIndexOfThePage = i;
          }
          lastIndexOfThePage = i;
        }
        startIndex++;
      }
    }

    this.removeTopAndBottomPaddingTabItem(firstIndexOfThePage, lastIndexOfThePage);


    let totalPage = Math.floor(this.countItemHasTab / this.tabItemNumber);
    if(totalPage > 0){

      this.hasItemOnBottom = ((activeItemPageIndex == 0 && totalPage > 0) || (activeItemPageIndex < totalPage && activeItemPageIndex > 0)) ? true : false;

      this.hasItemOnTop = (totalPage == activeItemPageIndex) ? true : false;

    }

  }
  }