import { LightningElement, api, track,wire } from 'lwc';
import initAgreementTerms from '@salesforce/apex/lwcAgreementTermsController.initAgreementTerms';
import acceptedAgreement from '@salesforce/apex/lwcAgreementTermsController.acceptedAgreement';
import getFooterContent from '@salesforce/apex/lwcAgreementTermsController.getFooterContent';
import { NavigationMixin } from 'lightning/navigation';

export default class LwcAgreementTerms extends NavigationMixin(LightningElement) {

    @track showModal;
    @track error;
    @track isOverlay;
    @api modalTitle;
    @api labelAcceptAgreement;
    @api labelLeave;
    @api headerRightSideContent;
    @track hasRightSideContent = false;
    @api footerRegion;
    @track hasFooterContent = false;
    @track footerContent = '';
    @api enableDownloadBtn;
    @track hasDownloadContent = false;
    @track downloadContent = '';
    @api downloadBtnLabel;
    @track fileName = '';

    @track isNA = false;
    @track isAU = false;
    @track useOldVersion = false;
    @api showSpinner = false;
    @api region;
    @api regionDownload;
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


    renderedCallback(){
     
        this.initScrollConfig();
      
    }
    
    initScrollConfig(){

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
    if(this.enableTabView){
      this.tabViewModalContainerClass = this.TXT_TAB_VIEW_MODAL_CONTAINER_CLASS;
    }

    this.isOverlay = false;
    this.showModal = true;

    this.hasLogo = (this.logoLink && this.logoLink != '') ? true : false;

    this.hasRightSideContent = (this.headerRightSideContent && this.headerRightSideContent != '') ? true : false;

    this.tabItemNumber = !this.tabItemNumber ? this.DEFAULT_TAB_ITEM_NUMBER : this.tabItemNumber;

    initAgreementTerms({region: this.region})
    .then(result => {
        // console.log('result >>>>> ', result);
        // this.showModal = result;

        // 16.08.2022 / Sophal Noch / US-0011795 - AU T&C for Seller Portal
        // this.showModal = result.result;

        if(result.isRTSellerPortal){
          return;
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
        this.isNA = (result && result.isNA) ? result.isNA : false;
        this.isAU = (result && result.isAU) ? result.isAU : false;

        this.useOldVersion = (result && result.useOldVersion) ? true : false;

        if(this.useOldVersion){
          
        }

    })
    .catch(error => { this.error = error; console.log('error >>>>> ', error); });

    if((this.footerRegion && this.footerRegion != '') || (this.enableDownloadBtn && (this.regionDownload && this.regionDownload != ''))){
      
      getFooterContent({footerRegion: this.footerRegion, enableDownload : this.enableDownloadBtn ,regionDownload: this.regionDownload})
      .then(result => {
        if(result.status == 'ok'){
          this.hasFooterContent = result.hasFooterContent;
          this.footerContent = result.footerContent;
          

          this.hasDownloadContent = result.hasDownloadContent;
          this.downloadContent = result.downloadContent;
          this.fileName = result.fileName ? result.fileName : '';

        }else if(result.status == 'ko'){
          console.log('getFooterContent error 1 ', result.error);
        }

      })
      .catch(error => { this.error = error; console.log('getFooterContent error 2 ', error); });

    }
       
  }



  handlDownload(event){
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