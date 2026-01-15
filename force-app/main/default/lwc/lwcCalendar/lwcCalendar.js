/** *  * change log: 18/05/2022: vadhanak voun / US-0010786 - Display Coupon Seller records in Calendar on Homepage
 *            21/09/2022/vadhanak voun/US-0012539
 *            07/10/2022/ Chetra Sarom/ US-0012099 - Fix calendar hover card falling out of screen
 *            30/11/2022/vadhanak voun/US-0012917 - [UK] Homepage
 *            24/04/2023/ SRONG TIN / US-0013353 - IT Deals SP Home Page
 *            06/06/2023/ vadhanak / US-0013725 - AU Seller portal, Beta Testing Seller, reported issue on Calendar not being loaded and Legend is showing Deal Campaign instead if Deal Window
 *            15/08/2024/ vadhanak / US-0015737 - Calendar Component not working due to LWS
 */           
import { LightningElement, api, track } from 'lwc';
import AnyEventCal from '@salesforce/resourceUrl/AnyEventCal';
import { NavigationMixin } from 'lightning/navigation';
import initLocalCode from '@salesforce/apex/AnyEventCalCtrl.initLocalCode';
import getAccounts from '@salesforce/apex/AnyEventCalCtrl.getAccounts';//SRONG-25.05.2022-US-0010814
import getCalendarItems from '@salesforce/apex/AnyEventCalCtrl.getCalendarItems';
import fetchStatusFilterMetadata from "@salesforce/apex/AnyEventCalCtrl.fetchStatusFilterMetadata"; //MN-20012021-US-0010642
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import MCName from '@salesforce/label/c.Marketing_Coupon_Name';
import CouponType from '@salesforce/label/c.Coupon_Type';
import SCFShare from '@salesforce/label/c.Seller_Co_Funding_Share';
import CCDueDate from '@salesforce/label/c.Coupon_Contract_Due_Date';
import Apply from '@salesforce/label/c.Apply'; //MN-20012021-US-0010642
import Clear from '@salesforce/label/c.Clear'; //MN-20012021-US-0010642
import LWC_Default_Picklist_Placeholder from '@salesforce/label/c.LWC_Default_Picklist_Placeholder'; //MN-20012021-US-0010642
import LANG from '@salesforce/i18n/lang'; //MN-20012021-US-0010642
import FutureCampaigns from '@salesforce/label/c.FutureCampaigns'; //MN-04042022-US-0011450
import CampaignEnded from '@salesforce/label/c.CampaignEnded'; //MN-04042022-US-0011450
import ProductFilter from '@salesforce/label/c.ProductFilter';
import SellerFilter from '@salesforce/label/c.SellerFilter';
import CampaignOpenforSubmission from '@salesforce/label/c.CampaignOpenforSubmission'; //MN-04042022-US-0011450
import CampaignRunning from '@salesforce/label/c.CampaignRunning'; //MN-04042022-US-0011450
import Label_Legend_CS_Comming from '@salesforce/label/c.SEP_Calendar_Legend_CS_Upcoming';
import Label_Legend_CS_Open from '@salesforce/label/c.SEP_Calendar_Legend_CS_Open';
import Label_Legend_CS_Past from '@salesforce/label/c.SEP_Calendar_Legend_CS_Past';
import CampaignEnded_NA from '@salesforce/label/c.CampaignEnded_NA'; //TH-19/08/2022-US-0012012 
import CampaignRunning_NA from '@salesforce/label/c.CampaignRunning_NA'; //TH-19/08/2022-US-0012012 
import CampaignOpenforSubmission_NA from '@salesforce/label/c.CampaignOpenforSubmission_NA'; //TH-19/08/2022-US-0012012 
import FutureCampaigns_NA from '@salesforce/label/c.FutureCampaigns_NA'; //TH-19/08/2022-US-0012012 
import lblFilterText from '@salesforce/label/c.Filter_Deal';//TH:12/10/2022:US-0012523
import StatusFilter from '@salesforce/label/c.Status'; //MN-10012023-US-0012915
import Open_for_Submissions_Status from '@salesforce/label/c.Open_for_Submissions_Status';//SRONG-24/04/2023-US-0013353
import Closed_for_Submissions_Status from '@salesforce/label/c.Closed_for_Submissions_Status';//SRONG-24/04/2023-US-0013353
import Running_Status from '@salesforce/label/c.Running_Status';//SRONG-24/04/2023-US-0013353
import Pending_Status from '@salesforce/label/c.Pending_Status';//SRONG-24/04/2023-US-0013353
//import { RefreshEvent } from 'lightning/refresh';  //NK:06/06/2023:US-0013725

export default class LwcCalendar extends NavigationMixin(LightningElement) {
    
  label = {
      MCName,
      CouponType,
      SCFShare,
      CCDueDate,
      LWC_Default_Picklist_Placeholder, //MN-20012021-US-0010642
      Apply, //MN-20012021-US-0010642
      Clear, //MN-20012021-US-0010642
      FutureCampaigns, //MN-04042022-US-0011450
      CampaignEnded, //MN-04042022-US-0011450
      CampaignOpenforSubmission, //MN-04042022-US-0011450
      CampaignRunning, //MN-04042022-US-0011450
      Label_Legend_CS_Comming,Label_Legend_CS_Open,Label_Legend_CS_Past,
      ProductFilter,
      SellerFilter,
      CampaignEnded_NA,//TH-19/08/2022-US-0012012
      CampaignRunning_NA,//TH-19/08/2022-US-0012012
      CampaignOpenforSubmission_NA,//TH-19/08/2022-US-0012012
      FutureCampaigns_NA,//TH-19/08/2022-US-0012012
      lblFilterText,//TH:12/10/2022:US-0012523
      StatusFilter, //MN-10012023-US-0012915
      Open_for_Submissions_Status,//SRONG-24/04/2023-US-0013353
      Closed_for_Submissions_Status,//SRONG-24/04/2023-US-0013353
      Running_Status,//SRONG-24/04/2023-US-0013353
      Pending_Status//SRONG-24/04/2023-US-0013353
    };

    error;
    fullCalendarJsInitialised = false;
    //@track allEvents = [];
    @track selectedEvent = undefined;
    createRecord = false;
  
    // @api couponsobjectlabel;
    // @api couponsobjectapiname;
    // @api couponstartdate;
    // @api couponenddate;
    // @api couponfilter;
    @api buttonsshowncalendar;
    // @api dealretailcampsobjectlabel;
    // @api couponsdealretailcampobjectapiname;
    // @api dealretailcampstartdate;
    // @api dealretailcampddate;
    // @api dealretailcampfilter;
    @api initLocalLangCode = 'en';

    @api dateFrom = new Date();
    @api dateTo = new Date();
    @api objectSettings = {};
    @api dateFORMAT8601 = "YYYY-MM-DD";
    
    //NK:30/11/2022:US-0012917
    @api metadata; 
    @api enableProductFilter;
    @api statusMetadata;
    @api legendsFor;


    //MN-20012021-US-0010642===
    @track showFilter = false; 
    @track mapStatusFilter= [];
    @track statusCriteria = [];
    @track searchingObj = ['EBH_DealRetailCampaign__c','Coupon_Seller__c'];
    @track isLoading = false;
    statusOptions = [];
    statusAllOptions = [];
    selectedStatus = ''; 
    //SRONG-25.05.2022-US-0010814
    productOptions = [];
    sellerOptions = [];
    selectedProduct = [];//'0','1','2'
    prior_selectedProduct = [];//'0','1','2'
    selectedSeller = [];
    accounts = [];
    isMuliAccount = false;
    
    lang = LANG; 

    //MN-14072022-US-0012057 - Set default of isCouponNoAccess & isDealNoAccess to TRUE instead.
    @track isCouponNoAccess = true;
    @track isDealNoAccess = true; //MN-14072022-US-0012057

    @track hasCouppon = false;

    //====MN-20012021-US-0010642


    @track hasLinkedAccCouponAccess = false;
    @track hasCouponAndDealAccess = false;
    dateSelectedFromRowCalender;

    /**
     * @description Standard lifecyle method 'renderedCallback'
     *              Ensures that the page loads and renders the 
     *              container before doing anything else
     */
    renderedCallback() {

      if (this.fullCalendarJsInitialised) {
        return;
      }
      this.fullCalendarJsInitialised = true;
 
      //MN-14072023-US-0013812: Re-loading script at the LWC side for double safe
      Promise.all(
        [
            loadStyle(this, AnyEventCal + '/fullcalendar.min.css'), 
            loadScript(this, AnyEventCal + '/jquery.min.js'),
            loadScript(this, AnyEventCal + '/moment-with-locales.js')            
        ])
        .then(() => {
          // console.log("--loadScript done--------");    
          console.log("$ version: "+ $().jquery );

          this.loadCalendarScript();          
        })
        .catch(error => {
          console.error({
            message: 'Error occured on renderedCallback',
            error
          });
        });

    }
    //NK:15/08/2024/US-0015737
    calscriptLoadTryCount = 0;
    loadCalendarScript()
    {      
      Promise.all(
        [
          loadScript(this, AnyEventCal + '/fullcalendar.min.js')
        ]).then(() => {
          //calendar script still not load?
          try{
            //if version can't be read, it means the script is not loaded
            console.log("fc version: "+ $.fullCalendar.version );  
          }catch(err)
          {
            this.calscriptLoadTryCount++;
            //retry 3 times
            if(this.calscriptLoadTryCount < 3)
            {
              this.loadCalendarScript();
            }
            
          }
               
          if(this.accounts.length == 0 ){
            this.getInitAccounts();
          }
          //MN-21022022-US-0011339
          this.getInitLocalCode();

        }).catch(error => {
            console.error("loadCalendarScript",error.message);
        });
    }
    // Sambath Seng 10.10.2022 US-0012581 - Status filter display blank value On Calendar ( DE SEP ) / Change from wire to normal method
    //MN-20012022-US-0010642
    // @wire(fetchStatusFilterMetadata, {
    //   prefix: 'DECalendarFilter_Status'
    // })
    // statusFilterRecs (result) {
    getStatusFilterPicklist(){
       
      fetchStatusFilterMetadata({prefix : 'DECalendarFilter_Status',specificMeta:this.statusMetadata}) //NK:30/11/2022:US-0012917
        .then(result => {
        if(result){
          let statusData = [];

          let tmpMap = new Map();

          for(var key in result){
            //this.mapStatusFilter.push({value:result.data[key], key:key}); 

            tmpMap.set(key, result[key]);

            var meta = result[key];    
            //MN-10012023-US-0012915
            var _label = meta.Value__c;
            if (this.lang == 'de') {
               _label = meta.Value_in_German__c;
            }
            else if (this.lang == 'fr') {
               _label = meta.Value_in_French__c;
            }
            //BR-04042023-US-0012916
            else if (this.lang == 'it') {
               _label = meta.Value_in_Italian__c;
            }
            //MN-10012023-US-0012915==END
            //SRONG-21.04.2023-US-0013353 
            if(this.lang == 'de' && typeof meta.Value_in_German__c =="undefined")continue;
            if(this.lang == 'fr' && typeof meta.Value_in_French__c =="undefined")continue;
            if(this.lang == 'it' && typeof meta.Value_in_Italian__c =="undefined")continue;
            statusData.push({
                //label: this.lang=='de'?meta.Value_in_German__c:meta.Value__c, //TH:20/07/2022:US-0012042 - Feedback Sprint 76:AC6 //MN-10012023-US-0012915
                label : _label, //MN-10012023-US-0012915
                value: key,
                developerName:meta.DeveloperName //SRONG-25.05.2022-US-0010814
            });

          }
          this.mapStatusFilter = tmpMap;
          this.statusAllOptions = statusData;
          //SRONG-25.05.2022-US-0010814
          // if(this.accounts.length == 1){ // 01.09.2022 / Sophal Noch / US-0012311
            if(this.accounts.length == 1 &&
              !this.accounts[0].Seller_Portal_Group__c && 
              this.accounts[0].SP_Coupons__c != null &&
              this.accounts[0].SP_Deals__c != null
            ){
              this.statusOptions = this.statusAllOptions;
            }else{
             this.statusOptions = [];
             var existOptionVal = {}; // 01.09.2022 / Sophal Noch / US-0012311
             this.statusAllOptions.forEach((val)=>{
              //  if(this.accounts[0].SP_Coupons__c != null){
              //   if(val.developerName.indexOf('Coupon') != -1 || val.developerName.indexOf('0') != -1){
              //     this.statusOptions.push(val);
              //   }
              //  }else if(this.accounts[0].SP_Deals__c != null){
              //     if(val.developerName.indexOf('Coupon') == -1){
              //       this.statusOptions.push(val);
              //     }
              //  }
              // 01.09.2022 / Sophal Noch / US-0012311
              for(var i = 0; i < this.accounts.length; i++){
               if(this.accounts[i].SP_Coupons__c != null && !existOptionVal[val.developerName]){
                if(val.developerName.indexOf('Coupon') != -1 || val.developerName.indexOf('0') != -1){
                  this.statusOptions.push(val);
                  existOptionVal[val.developerName] = true;
                }
               }
               if(this.accounts[i].SP_Deals__c != null && !existOptionVal[val.developerName]){
                  if(val.developerName.indexOf('Coupon') == -1){
                    this.statusOptions.push(val);
                    existOptionVal[val.developerName] = true;
                  }
               }
              }

             });
            }
          // }else{
          //   this.statusOptions = this.statusAllOptions;
          // }
        }
        //SRONG-25.05.2022-US-0010814
        this.getProductOptionPicklist();
      }).catch(error => {
        console.log('log error:'+JSON.stringify(error));
      });

    }
    //NK:30/11/2022:US-0012917
    //enable this option from Community Builder: YES or NO. Default YES
    get isEnableProductFilter()
    {
     return (this.enableProductFilter+"").toUpperCase() == "YES";
    }
    //enable from builder
    //more object? add more getter as well as in comm builder
    get legendForCS() //ledgend for Coupon Seller
    {
       return (this.legendsFor+"").includes("cs") || (this.legendsFor=="" || this.legendsFor==null || this.legendsFor==undefined);
    }
    get legendForDRC() //legend for Deal Retail Campaign
    {
       return (this.legendsFor+"").includes("drc") || (this.legendsFor=="" || this.legendsFor==null || this.legendsFor==undefined);
    }
    //SRONG-25.05.2022-US-0010814
    getProductOptionPicklist(){
      fetchStatusFilterMetadata({prefix : 'DECalendarFilter_Product'})
        .then(result => {
          if(result != null && result.length>0){
            let productData = [];
            let tmpMap = new Map();
            for(var key in result){
              tmpMap.set(key, result[key]);
              var meta = result[key];  
              //SRONG-21.04.2023-US-0013353   
              let productLabel = this.lang=='de'?meta.Value_in_German__c:meta.Value__c;
                  productLabel = this.lang=='it'?meta.Value_in_Italian__c:productLabel;
              productData.push({
                  label: productLabel,//this.lang=='de'?meta.Value_in_German__c:meta.Value__c, //TH:20/07/2022:US-0012042 - Feedback Sprint 76:AC6
                  value: key
              });
            }
          // this.mapStatusFilter = tmpMap;
            this.productOptions = productData;
          }
          
        })
        .catch(error => {
            console.log('log error:'+JSON.stringify(error));
        });
    }
  
    getInitLocalCode(){
      //initLocalCode
      initLocalCode()
        .then((resposne) => {
            this.initLocalLangCode = resposne;
          //console.log("..initLocalLangCode",this.initLocalLangCode );
          // console.log("--getInitLocalCode -- done");
            
          this.initialiseFullCalendarJs();

            // setTimeout(()=>{  
            //   this.template.querySelector('div.fc-right').classList.add("custom-fc-right"); //MN-20012021-US-0010642
            //   console.log("--getInitLocalCode fc -- done");
            // }, 100);  
        })
        .catch(error => {
            this.error = error;
            this.outputResult = undefined;
            console.error(error);
        });

        
    }

    initialiseFullCalendarJs() {
      //await this.delay(500);
      try
      {
        const ele = this.template.querySelector('div.fullcalendarjs');
        // eslint-disable-next-line no-undef
        $(ele).fullCalendar({
          timeZone: 'local',
          locale: this.initLocalLangCode,
          header: {
              left: '',
               center: 'prev title next',
              //center: 'prev title next',
              right: this.buttonsshowncalendar + ', filterbtn'
          },
          
          nextDayThreshold: '00:00:00',
          displayEventTime: false,
          themeSystem : 'standard',
          defaultDate: new Date(), 
          navLinks: true,
          editable: true,
          eventLimit: true,
         // events: resposne,
          dragScroll : true,
          droppable: true,
          weekNumbers : true,
          eventDrop: this.eventDropHandler.bind(this),
          eventClick: this.eventClickHandler.bind(this),
          dayClick : this.dayClickHandler.bind(this),
          eventAfterRender: this.eventAfterRenderHandler.bind(this),
          eventMouseover : this.eventMouseoverHandler.bind(this),
          eventMouseout:this.eventMouseoutHandler.bind(this),
          events : this.refreshEvent.bind(this),
         
        });
        
        this.delay(100); 
        this.template.querySelector('div.fc-right').classList.add("custom-fc-right"); //MN-20012021-US-0010642
        
        console.log("--fc-- done");

      }catch(e)
      {
        console.error("ERROR initialiseFullCalendarJs",e);
        if(e.message)
        {
          console.error("message",(e.message));
          console.error("stack",(e.stack));
        }
      }
      
    }

  delay(ms) {
      return new Promise(resolve => setTimeout(resolve, ms));
  }

    getInitAccounts(){
      //initLocalCode
      getAccounts()
        .then((resposne) => {
          this.accounts =  resposne;

          if(this.accounts.length == 1 && !this.accounts[0].Seller_Portal_Group__c){  // 29.08.2022 / Sophal Noch / US-0012311
            if(this.accounts[0].SP_Coupons__c != null){
                this.isCouponNoAccess = false;
            }
            //MN-14072022-US-0012057
            if(this.accounts[0].SP_Deals__c != null) {
                this.isDealNoAccess = false;
            }
          }else{
            
            var sellerData = [];
            for(var index = 0;index < this.accounts.length;index++){
              var oneAcc = this.accounts[index];
              sellerData.push({
                  label: oneAcc.Name, 
                  value: oneAcc.Id
              });

            
               if(oneAcc.Seller_Portal_Group__c && oneAcc.SP_Coupons__c != null){
                this.isCouponNoAccess = false;
              }
              
              if(oneAcc.Seller_Portal_Group__c && oneAcc.SP_Deals__c != null) {
                  this.isDealNoAccess = false;
              }

              // ------ 29.08.2022 / Sophal Noch / US-0012311

            }
            // set default value for current account...
            this.selectedSeller = sellerData[0].value;
            this.sellerOptions = sellerData;
            this.isMuliAccount = true;

          }

          if(this.isCouponNoAccess == false && this.isDealNoAccess == false){ // 29.08.2022 / Sophal Noch / US-0012311
            this.hasCouponAndDealAccess = true;
          }
          if(this.isCouponNoAccess == false && this.accounts.length > 1){ // 01.09.2022 / Sophal Noch / US-0012311
            this.hasLinkedAccCouponAccess = true;
          }  
          this.getStatusFilterPicklist();// Sambath Seng 10.10.2022 US-0012581 - Status filter display blank value On Calendar ( DE SEP )   

          console.log("--init acc -- done");
        })
        .catch(error => {
            this.error = error;
            console.error("ERROR getInitAccounts",error);
        });

        
    }

    

  createEachEvent(eventITem,setting)
  {    
    
    let dStart = new Date(Date.parse(eventITem.startDateTime));
    let dEnd = new Date(Date.parse(eventITem.endDateTime));
    

    let listEvent = [];
    let numDay = this.countDay(dStart,dEnd);
    let nextD = new Date(Date.parse(eventITem.startDateTime));
    
    //MN-04022022-US-0011105-AC3 
   
    let ev_start = dStart.toISOString(); 
    let ev_end = dEnd.toISOString();
    let color = this.getColor(setting,eventITem.record,ev_start,ev_end);

    listEvent.push(
      {
        
        id: eventITem.Id,
        start: ev_start,
        end:  ev_end,
        editable:false,
        allDay: false, //MN-04022022-US-0011105-AC4
        title: eventITem.title,
        objName:setting.Object_Name__c,
        record:eventITem.record,
        backgroundColor:color.bg_color,
        borderColor:color.border_color,//SB 24.6.2022 US-0011958 - Change Requests Focus 75 - AC6
        textColor:color.text_color,
        borderStyle:color.border_style,//SB 24.6.2022 US-0011958 - Change Requests Focus 75 - AC6
        borderWidth:color.border_width//SB 24.6.2022 US-0011958 - Change Requests Focus 75 - AC6
        
      }
    );

    //console.log('...createEachEvent...',listEvent);
    return listEvent;
  }

  //specific color for DRC only
  //Today > End Date of DRC
  //Today < Accept Proposal Start Date
  //Today => Accept Proposal Start Date and today =< Accept Proposal End Date
  //NK:18/05/2022US-0010786
  //SB 24.6.2022 US-0011958 - Change Requests Focus 75 - AC6
  getColor(setting,record,ev_start,ev_end)
  {
    let color = {};
    //let today = new Date();
    if(setting.Object_Name__c == "EBH_DealRetailCampaign__c")
    {
      //TH:US-0012012:17/08/2022: check by status for NA
      //SRONG TIN : 02/05/2023 : US-0013353 - IT Deals SP Home Page
      if(this.isNA || this.isAU || this.isIT){
        let dw_Status = record.Status_Seller_Portal__c;
        //NK:21/09/2022:US-0012539 - switched color between "Open for Submissions" with "Pending"
        if(dw_Status == this.label.Closed_for_Submissions_Status){
            /* TH:US-0012012:10/08/2022:*/
            color.bg_color = "#FFFFFF";
            color.text_color = "#592E13";
            color.border_color = "#FBCD25";
            color.border_style = "solid";
            color.border_width = "2px";
        }else if(dw_Status == this.label.Running_Status){
            /* TH:US-0012012:10/08/2022:*/
            color.bg_color = "#FDEBA8";
            color.border_color = "#FDEBA8";
            color.text_color = "#592E13";

        }else if(dw_Status == this.label.Open_for_Submissions_Status){           
          /* TH:US-0012012:10/08/2022:*/
          color.bg_color = "#FBCD25"; 
          color.border_color = "#FBCD25"; 
          color.text_color = "#592E13";
        }else if(dw_Status == this.label.Pending_Status){
             /* TH:US-0012012:10/08/2022:*/
             color.bg_color = "#FFF8D6";
             color.border_color = "#FFF8D6";
             color.text_color = "#592E13";
        }
      }else{//DE - Seller Porta
        let drc_accept_start1 = moment.utc(record.EBH_AcceptProposalsStart__c);//.format(this.dateFORMAT8601);
        let drc_accept_end1 = moment.utc(record.EBH_AcceptProposalsEnd__c);//.format(this.dateFORMAT8601);
        let eventItemEnd1 = moment.utc(ev_end);//.format(this.dateFORMAT8601);
  
        let drc_end = moment.utc(record.EPH_EndDate__c); //MN-04022022-US-0011105-AC2
        let drc_start = moment.utc(record.EBH_Date__c); //MN-08022022-US-0011105-AC2
  
        let today1 = moment.utc(new Date());//.format(this.dateFORMAT8601);
        let todayDateOnly = moment.utc(moment.utc(today1).format(this.dateFORMAT8601));//.format(this.dateFORMAT8601);
  
        //console.log("--getColor: ",record,"today: "+today1,"todayDateOnly: "+todayDateOnly,"ev_end: "+eventItemEnd1,"drc_accept_start: "+drc_accept_start1,"drc_accept_end: "+drc_accept_end1);
        // if(today1>eventItemEnd1) //MN-04022022-US-0011105-AC2
        if(todayDateOnly>drc_end) //MN-04022022-US-0011105-AC2
        {
          // color.bg_color = "#FFC300"; //bright orange
          // color.text_color = "black";
          // CampaginEnded
          /*color.bg_color = "#FFF8D6";
          color.border_color = "#FFF8D6";
          color.text_color = "#592E13";*/
          /* TH:US-0012012:10/08/2022:*/
          color.bg_color = "#FFFFFF";
          color.text_color = "#592E13";
          color.border_color = "#FBCD25";
          color.border_style = "solid";
          color.border_width = "2px";
  
        }
        else if (todayDateOnly >= drc_start && todayDateOnly <= drc_end) {
          // color.bg_color = "#9FFEEC"; //blue
          // color.text_color = "black";
          // CampaginRunning          
          /* TH:US-0012012:10/08/2022:*/
          color.bg_color = "#FDEBA8";
          color.border_color = "#FDEBA8";
          color.text_color = "#592E13";
        }
        else if(todayDateOnly < drc_accept_start1) {
          // color.bg_color = "#FDFF7E"; //Yellow
          // color.text_color = "black";
          // FutureCampaigns
        
          /* TH:US-0012012:10/08/2022:*/
          color.bg_color = "#FFF8D6";
          color.border_color = "#FFF8D6";
          color.text_color = "#592E13";
        }
        else if(todayDateOnly >= drc_accept_start1 && todayDateOnly <= drc_accept_end1) {
          // color.bg_color = "#D2FF7E"; //Green
          // color.text_color = "black";
          // CampaignOpenForSubmission       
          /* TH:US-0012012:10/08/2022:*/
          color.bg_color = "#FBCD25"; 
          color.border_color = "#FBCD25"; 
          color.text_color = "#592E13";
        }
        else{//TH:10/10/2022:US-0012245 - DRC default color on calendar needs to change
          color.bg_color = "#FFFFFF";
          color.text_color = "#592E13";
          color.border_color = "#FBCD25";
          color.border_style = "solid";
          color.border_width = "2px";
        }
      }
      
    }else
    if(setting.Object_Name__c == "Coupon_Seller__c")
    {
      //NK:18/05/2022US-0010786
      // The Coupon Seller records need to be displayed in different colours based on the following:
      // Today > End Date of Coupon Seller: light blue with black text (#AED5F5) (past coupons)
      // Today < Start Date: medium blue with white text (#67B5F5) (future coupons)
      // Today => Start Date and today <= End Date: display in bright blue with white text (#2095F5) (ongoing coupons)
      let today1 = moment.utc(new Date());
      let cp_start = moment.utc(record.Coupon_Start_Date__c);
      cp_start.add(record.Coupon_Start_Time__c,"ms");
      let cp_end = moment.utc(record.Coupon_End_Date__c);
      cp_end.add(record.Coupon_End_Time__c,"ms");
      //let cp_due = moment.utc(record.Coupon_Contract_Due_Date__c);
      //console.log("record, today1 cp_start cp_end",record, today1,cp_start,cp_end);
      if(today1 >= cp_start && today1 <= cp_end ) //3
      {
        // color.bg_color = "#2095F5";  
        // color.text_color = "white";
        // CouponSeller Open
        color.bg_color = "#01718F";  
        color.border_color = "#01718F";  
        color.text_color = "#FFFFFF";

      }else if(today1 > cp_end) //1
      {
        // color.bg_color = "#AED5F5";  
        // color.text_color = "black";
        // CouponSeller Past
        color.bg_color = "#E6F5F4";  
        color.border_color = "#E6F5F4";  
        color.text_color = "#01718F";

      }else if(today1 < cp_start) //2
      {
        // color.bg_color = "#67B5F5";  
        // color.text_color = "white";
        // CouponSeller Upcomming
        color.bg_color = "#71E3E2";  
        color.border_color = "#71E3E2";  
        color.text_color = "#01718F";
      } 

    }

    return color;
  }
 
  toDateWithStartHour(d)
  {     
    let myDate = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0));
    //console.log('...myDate...',myDate,myDate.toISOString());
    return myDate;    
  }
  toDateWithEndHour(d)
  {     
    let myDate = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59));
    //console.log('...myDate...',myDate,myDate.toISOString());
    return myDate;    
  }
  //return number of day in between
  countDay(d1,d2)
  {
    return Math.round(Math.abs((d1 - d2) / 8.64e7)); //8.64e7 is the number of milliseconds in a day.
  }

  isSameDay(d1,d2)
  {
    return d1.getFullYear() === d2.getFullYear() &&
    d1.getMonth() === d2.getMonth() &&
    d1.getDate() === d2.getDate();
  }
  
  addDays(d, numDay) {
    var result = new Date(d);
    result.setDate(result.getDate() + numDay);
    return result;
  }
  // ISO 8601 format: yyyy-MM-dd
  dateToString(myDate)
  {
    const offset = myDate.getTimezoneOffset();
    myDate = new Date(myDate.getTime() - (offset*60*1000));
    return myDate.toISOString().split('T')[0];

  }
  dateTimeToString(myDate)
  {
    const offset = myDate.getTimezoneOffset();
    myDate = new Date(myDate.getTime() - (offset*60*1000));
    return myDate.toISOString();

  }
  isWhatPercentOf(numA, numB) {
    return (numA / numB) * 100;
  }
  eventMouseoverHandler = (event, jsEvent, view)=>{
    this.selectedEvent =  event;
 
      const toolTipDiv = this.template.querySelector('div.ModelTooltip');
      toolTipDiv.style.opacity = 1;
      toolTipDiv.style.display = "block";
      toolTipDiv.style.top = (jsEvent.pageY - toolTipDiv.clientHeight) - 115 +"px";

      var widthPer = this.isWhatPercentOf(jsEvent.clientX,jsEvent.delegateTarget.offsetWidth);
      //console.log(this.dayNumber);
      if (jsEvent.delegateTarget.offsetWidth < 300) {
        var calenderViewContainer = this.template.querySelector('.fc-view-container');
        var contentWidthPer = this.isWhatPercentOf(jsEvent.clientX,calenderViewContainer.clientWidth);
        if (contentWidthPer>70) {
          this.template.querySelector('.cls-tooltip-article').className='slds-card slds-card_narrow cls-tooltip-article slds-nubbin_bottom-right';
          toolTipDiv.style.left = jsEvent.clientX - (toolTipDiv.clientWidth-30) +"px"; 
        }else {
          this.template.querySelector('.cls-tooltip-article').className='slds-card slds-card_narrow cls-tooltip-article slds-nubbin_bottom-left';
          toolTipDiv.style.left = jsEvent.clientX - 20 +"px";  
        }
      }else {
        if (widthPer > 85) {
          //this.template.querySelector('.slds-popover_panel').className ='slds-popover slds-popover_panel hidden-small-hover-right';
          this.template.querySelector('.cls-tooltip-article').className='slds-card slds-card_narrow cls-tooltip-article slds-nubbin_bottom-right';
          toolTipDiv.style.left = jsEvent.clientX - (toolTipDiv.clientWidth-30) +"px"; 
        }
        else if(widthPer < 17){
          //this.template.querySelector('.slds-popover_panel').className ='slds-popover slds-popover_panel hidden-small-hover-left';
          this.template.querySelector('.cls-tooltip-article').className='slds-card slds-card_narrow cls-tooltip-article slds-nubbin_bottom-left';
          toolTipDiv.style.left = jsEvent.clientX - 20 +"px";  }
        else{
          //this.template.querySelector('.slds-popover_panel').className ='slds-popover slds-popover_panel hidden-small-hover-mid';
          this.template.querySelector('.cls-tooltip-article').className='slds-card slds-card_narrow cls-tooltip-article slds-nubbin_bottom';
          toolTipDiv.style.left = (jsEvent.clientX - (toolTipDiv.clientWidth/2)) +"px"; 
        }
      }
     
    }
    
    /* Handle Mouse Out*/
    eventMouseoutHandler= (event, delta, revertFunc)=>{

      const toolTipDiv = this.template.querySelector('div.ModelTooltip');
      toolTipDiv.style.opacity = 0; 
      toolTipDiv.style.display = "none";
    }

    eventAfterRenderHandler = (event, element, view) => {

    
    }

    get currentFieldsDisplay()
    {
      if(this.selectedEvent)
      {        
        let setting = this.objectSettings[this.selectedEvent.objName];
        //console.log("--currentFieldsDisplay ",setting);
        if(setting.List_Field_Popup__c !=null && setting.List_Field_Popup__c.length > 0)
        {
          let listToDisplay = [];
          let mapApiLabel = setting.mapFieldApiLabel;
          setting.List_Field_Popup__c.split(",").forEach(fieldApi => {
            let fType = mapApiLabel[fieldApi].type;
            listToDisplay.push(
              {
                flabel: mapApiLabel[fieldApi].label,
                fapi: fieldApi,
                fval: this.selectedEvent.record[fieldApi],
                ftype: fType,
                isdate: (fType=='date' || fType=='datetime'),
                isnumber: (fType=='double' || fType=='integer'),
                iscurrency: (fType=='currency'),
                istext: (fType !='date' && fType !='datetime' && fType !='double' && fType !='integer' && fType !='currency'),
              }
            );
          });   
         // console.log("--listToDisplay: ",listToDisplay);
          return listToDisplay;      
        }       
      }
      //NK:15/08/2024:US-0015737
      return new Array();
    }

     

    @track curStart;
    @track curEnd;
    @track isNA;
    @track isAU;
    @track isIT;
    @track isNA_AU;

    refreshEvent= (start, end, timezone, callback)=>{
          let dateF = moment.utc(start._d).format(this.dateFORMAT8601);
          let dateT = moment.utc(end._d).format(this.dateFORMAT8601); 
          this.curStart = dateF;
          this.curEnd = dateT;
          let staFil = this.statusCriteria;
              //SRONG-25.05.2022-US-0010814
              //NK:30/11/2022:US-0012917: metadata:this.metadata
              getCalendarItems({dateFrom:dateF ,dateTo:dateT, statusFilter:staFil,searchingObj:this.searchingObj,sellers:this.selectedSeller,metadata:this.metadata}) //MN-21012021-US-0010642-add 3rd param for Status Filtering
              .then((resposne) => {
                   //console.log('log '+ resposne);
                  //console.log('getCalendarItems res--',resposne);
                  let eventList = [];      

                  resposne.forEach((objItem) => {
                  
                    objItem.setting.mapFieldApiLabel = objItem.mapFieldApiLabel;
                    //console.log('..objItem',objItem);

                    this.objectSettings[objItem.setting.Object_Name__c] = objItem.setting;
                    this.isNA = objItem.isNA;//TH:US-0012012:18/08/2022
                    this.isAU = objItem.isAU;//TH:US-0012012:18/08/2022
                    this.isIT = objItem.isIT;//SRONG:US-0013353:02/05/2023
                    this.isNA_AU = (this.isNA || this.isAU);
                    objItem.listEvent.forEach(eventITem => 
                    {
                      let groupEvent = this.createEachEvent(eventITem,objItem.setting); //1 records spread to multiple event base on number of days
                      eventList.push.apply(eventList, groupEvent);
                      
                    });
                      
                  });

                  this.error = undefined;
                  this.isLoading = false;  //MN-21012021-US-0010642

                  callback(eventList);                 
                  
                  
                  
                  })
                  .catch(error => {
                      this.error = error;
                      this.outputResult = undefined;
                      console.log("-----error on refreshEvent------",error);
                  });

    }
  
     /* Handle Mouse Out*/
   
    eventDropHandler = (event, delta, revertFunc)=>{
      alert(event.title + " was dropped on " + event.start.format());
      if (!confirm("Are you sure about this change? ")) {
        revertFunc();
      }
    }
  
    eventClickHandler = (event, jsEvent, view) => {
       // console.log('---click',event);
      // /s/coupon-seller/id	
      // /s/ebh-dealretailcampaign/id
      let targetUrl = "";
      if(event.objName=="EBH_DealRetailCampaign__c")
      {
        targetUrl = "/s/ebh-dealretailcampaign/"+event.id;
      }else if(event.objName=="Coupon_Seller__c")
      {
        targetUrl = "/s/coupon-seller/"+event.id;
      }
        this[NavigationMixin.Navigate]({
          // type: 'standard__recordPage',
          type: 'standard__webPage',
          attributes: {
              // recordId: event.id,
              // objectApiName: 'Coupon_Seller__c',
              // actionName: 'view'
              url:targetUrl
          }
      });
      //  this.selectedEvent = undefined;
      

    }
  
    dayClickHandler = (date, jsEvent, view)=>{
      jsEvent.preventDefault();
      this.createRecord = true;
    }
  
    createCancel() {
      this.createRecord = false;
    }
  
    closeModal(){
      this.selectedEvent = undefined;
    }

    filterHandler () { //MN-20012021-US-0010642
        this.showFilter = !this.showFilter;
        if (this.showFilter) {
          this.template.querySelector('div.fc-view-container').classList.add("custom-fc-view-container"); //MN-20012021-US-0010642
        }else {
          this.template.querySelector('div.fc-view-container').classList.remove("custom-fc-view-container"); //MN-20012021-US-0010642
        }
    }

    clearHandler (e) { //MN-21012021-US-0010642
        
      this.isLoading = true;
      var clearArray = [];
      this.selectedStatus = clearArray;
      this.prior_selectedStatus = clearArray;
      this.statusCriteria = clearArray;
      this.searchingObj = ['EBH_DealRetailCampaign__c','Coupon_Seller__c'];
      //SRONG-25.05.2022-US-0010814
      this.selectedProduct = [];//'0','1','2'
      this.prior_selectedProduct = [];//'0','1','2'
      if(this.sellerOptions.length>0){
        this.selectedSeller = this.sellerOptions[0].value;
      }
      
      const ele = this.template.querySelector('div.fullcalendarjs');
      $(ele).fullCalendar('refetchEvents');
    
    }
  
    @track prior_selectedStatus = [];
    handleStatusChange(e) { //MN-20012021-US-0010642
 
        var sel_val = e.detail.value;
        var pri_val = this.prior_selectedStatus;

        if ((!pri_val || pri_val.length == 0 || pri_val[0]!='0') && sel_val[0] == '0') { //This mean user tick Select All
          var tmp = this.statusOptions;
          
          sel_val = [];

          tmp.forEach((val)=>{
            sel_val.push(val.value);
          });

          // this.selectedStatus = sel_val;
        }else if (sel_val.length != pri_val.length && sel_val[0] != '0' && pri_val[0]=='0') { //This mean user untick Select All
          sel_val = [];
          // this.selectedStatus = sel_val;
        }else if (sel_val.length != pri_val.length && sel_val[0] == '0' && pri_val[0]=='0') { //This mean user tick select all then unselect other option => remove tick on Select All
          sel_val.splice(0,1);
          // this.selectedStatus = sel_val;
        }

        this.selectedStatus = sel_val;
        this.prior_selectedStatus = sel_val;
    }
    //SRONG-25.05.2022-US-0010814
    handleProductChange(e) {
        var sel_val = e.detail.value;
        var pri_val = this.prior_selectedProduct;
        if ((!pri_val || pri_val.length == 0 || pri_val[0]!='0') && sel_val[0] == '0') { //This mean user tick Select All
          var tmp = this.productOptions;
          
          sel_val = [];

          tmp.forEach((val)=>{
            sel_val.push(val.value);
          });
        }else if (sel_val.length != pri_val.length && sel_val[0] != '0' && pri_val[0]=='0') { //This mean user untick Select All
          sel_val = [];
        }else if (sel_val.length != pri_val.length && sel_val[0] == '0' && pri_val[0]=='0') { //This mean user tick select all then unselect other option => remove tick on Select All
          sel_val.splice(0,1);
        }
        this.selectedProduct = sel_val;
        this.prior_selectedProduct = sel_val;
        
        // change status option by selected product...
         if(this.selectedProduct.length != 1){
           this.statusOptions = this.statusAllOptions;
         }else{
          this.statusOptions = [];
          this.selectedStatus = '';
          this.statusAllOptions.forEach((val)=>{
            if(this.selectedProduct[0] == 1){
              if(val.developerName.indexOf('Coupon') == -1){
                this.statusOptions.push(val);
              }
            }else{
              if(val.developerName.indexOf('Coupon') != -1 || val.developerName.indexOf('0') != -1){
                this.statusOptions.push(val);
              }
            }
          });
         }
        
    }
    //SRONG-25.05.2022-US-0010814
    handleSellerChange(e) {
      this.selectedSeller = e.detail.value;
    }

  

    handleSearch(e) { //MN-21012021-US-0010642

      this.isLoading = true;
      ////SRONG-25.05.2022-US-0010814
      // check if coupon seller or Deal retail campaign
      let listSearchObj = [];
      if(this.selectedProduct.length != 1 || this.selectedProduct == ''){
        listSearchObj.push('EBH_DealRetailCampaign__c');
        listSearchObj.push('Coupon_Seller__c');
      }else{
        if(this.selectedProduct[0] == 1){
          listSearchObj.push('EBH_DealRetailCampaign__c');
        }else{
          listSearchObj.push('Coupon_Seller__c');
        }
      }
      this.searchingObj = listSearchObj;//'EBH_DealRetailCampaign__c'; //NK:20/05/2022:US-0010786 default for now. no filter for CS
      var sel_status = this.selectedStatus;
      var tmp = [];
      if (sel_status.length > 0) {

        var st_index = (sel_status[0]==0)?1:0;
        for (var i=st_index; i<sel_status.length; i++) {

          //var criteria = this.mapStatusFilter[sel_status[i]].Value_Big__c;
          var criteria = this.mapStatusFilter.get(sel_status[i]).Value_Big__c;
          tmp.push(criteria);
          
        }
      }
      this.statusCriteria = tmp;
      const ele = this.template.querySelector('div.fullcalendarjs');
      $(ele).fullCalendar('refetchEvents');
      
    }
  }