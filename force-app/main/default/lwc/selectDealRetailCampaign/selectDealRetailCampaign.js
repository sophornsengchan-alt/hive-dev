import { LightningElement, wire, api, track } from 'lwc';
//import fetchDealRetailCampaign from '@salesforce/apex/DealRetailCampaignCtrl.fetchDealRetailCampaign';
import fetchDealRetailCampaignBySite from '@salesforce/apex/DealRetailCampaignCtrl.fetchDealRetailCampaignBySite';
import fetchSEPGlobalVarWithPrefix from "@salesforce/apex/SEP_ItemSearchController.fetchSEPGlobalVarWithPrefix"; //MN-23112021-US-0010805
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import LWCCreateSingleDeal23 from '@salesforce/label/c.LWCCreateSingleDeal23';//SRO-04-02-2022:US-0011151
import Deal_Object from '@salesforce/schema/EBH_Deal__c';
import LWC_Default_Picklist_Placeholder from '@salesforce/label/c.LWC_Default_Picklist_Placeholder'; //MN-06012022-US-0010947 

export default class SelectDealRetailCampaign extends LightningElement {

    @api siteNumber;
    @api placeholder;
    @api placeholderSite;
    @api inputLabel;
    @api selectedValue;
    @api inputLabelSite;
    @api defaultDrcId;//SB 25-2-2022 US-0011351 - Deal creation button on the DRC view page

    siteOptions = [];
 
     @track records;
     @track error;
     @track mRecords = {};
     @track isFirstLoad = true;
    
    label = { 
        LWC_Default_Picklist_Placeholder,
        LWCCreateSingleDeal23,//SRO-04-02-2022:US-0011151
    
    }; //MN-06012022-US-0010947 

    connectedCallback() {
        if(this.isFirstLoad == false) return;
        this.isFirstLoad = false;
        this.fetchDealRetailCampaign(this.siteNumber);
        this.onAssignSiteNumberDef(this.siteNumber);
    }
    //Start SB 25-2-2022 US-0011351 - Deal creation button on the DRC view page
    get drcId(){
        return this.defaultDrcId;
    }
    //End SB 25-2-2022 US-0011351 - Deal creation button on the DRC view page
    //  @wire (fetchDealRetailCampaign, {siteNumber: '$siteNumber'})  
    //  dealRetCams({error, data}) {
    //     console.log('>>>>> siteNumber:::: ', this.siteNumber);
    //     console.log('>>>>> placeholder:::: ', this.placeholder);
    //     console.log('>>>>> inputLabel:::: ', this.inputLabel);
    //      console.log('>>>>> select data:::: ', data);
    //      console.log('>>>>> select data error:::: ', error);
    //      if (data) {
    //          console.log('result select ...', data);
    //          this.records = data;
    //          this.error = undefined;
    //      } else if (error) {
    //          this.error = error; 
    //          this.record = undefined;
    //      }
    //  }
    //to call the CDR based on the site number
    fetchDealRetailCampaign(siteNumber){
        // console.log(">>>>siteNumber ", siteNumber);
        fetchDealRetailCampaignBySite({siteNumber : siteNumber})
        .then(result => {
            // console.log(">>>>resultxxx ", result);
                if(result){
                    this.placeholder = this.label.LWC_Default_Picklist_Placeholder; //MN-06012022-US-0010947 
                    this.records = result;
                    this.error = undefined;
                }
            })
            .catch(error => { 
                console.log(">>>>>DRC fetch error:", error);
            }); 
    }  

// to get the default record type id, if you dont' have any recordtypes then it will get master
   @wire(getObjectInfo, {
    objectApiName: Deal_Object
 })
 dealsMetadata;

//MN-23112021-US-0010805 - Deal Site will be get from SEP Global Variable Metadata with prefix "DealSite" in field DeveloperName
@wire(fetchSEPGlobalVarWithPrefix, {
    prefix: 'DealSite'
})
dealSiteRecs ( {error, data} ) {
    
    if ( data ) {

        let dealSiteData = [];

        data.forEach(element => {
            
            dealSiteData.push({
                label: element.Label, 
                value: element.Value__c
            });

        });

        this.siteOptions = dealSiteData;
    }else if (error) {
        console.log('*** MN - metadata - ERROR :: ', error.body.message);
    }
}

/* MN-23112021-US-0010805 - No longer get Deal Site based on Profile's Deal Default Record Type 
 @wire(getPicklistValuesByRecordType, {
        objectApiName: Deal_Object,
        recordTypeId: '$dealsMetadata.data.defaultRecordTypeId'
    })
    picklistValues({
        error,
        data
    }) {
        if (data) {
            console.log(data);

            let statusData = [];
            //fetch status option data
            if (data.picklistFieldValues.EBH_DealSiteId__c) {
                data.picklistFieldValues.EBH_DealSiteId__c.values.forEach(element => {
                    //MN-22112021-US-0010805 - Change label "ES" => "SP" for Spain
                    var elemLabel = element.label;
                    if (elemLabel == "ES") elemLabel = "SP";

                    statusData.push({
                        //label: element.label,
                        label: elemLabel, //MN-22112021-US-0010805 
                        value: element.value
                    });
                });
                this.siteOptions = statusData;
            }
        } else if (error) {
        console.log(error);
        }
    }
    */
 
     get options() {
         let opts = [];
         if (this.records) {
            var objRec = {};
            // opts.push({ label: ' --- ', value : ''}); //MN-06012022-US-0010947 - No need to assign empty list but instead display Placeholder text
            opts.push({ label: this.label.LWCCreateSingleDeal23 , value : ''}); //SRO-04-02-2022:US-0011151
            this.records.forEach(function(drc){     
                var startDate = new Date(drc.EBH_Date__c).toLocaleDateString('en-GB'); //Sambath Seng - 07.12.2021 - US-0010837 - Store start date field value //TH:14/03/2022:US-0011444 - Date format change needed on DRC ()
                var endDate = new Date(drc.EPH_EndDate__c).toLocaleDateString('en-GB'); //Sambath Seng - 07.12.2021 - US-0010837 - Store end date field value //TH:14/03/2022:US-0011444 - Date format change needed on DRC ()
                opts.push({ label: drc.EBH_DealTitle__c+' ('+startDate+' - '+endDate+')', value :drc.Id}); //Sambath Seng - 07.12.2021 - US-0010837 - [SP - EU Deals] Include start and end date in DRC picklist
                objRec[drc.Id] = drc;
            });
            // console.log('>>>>> objRec:::: ', objRec);
            this.mRecords = objRec;
         }
 
         return opts;
     }
 
     handleChange(event) {
         this.selectedValue = event.detail.value; 
         let selectedVal = event.detail.value;
         let obj = {selectedVal : selectedVal, record : (selectedVal == ''? '' : this.mRecords[selectedVal])};
        //  console.log('>>>>> obj:::: ', obj);
         this.dispatchEvent(new CustomEvent('selectedchange', {
             detail: obj
         }));
     }

    handleSiteChange(event) {
         this.selectedValue = event.detail.value; 
         this.siteNumber = event.detail.value;
         let selectedVal = event.detail.value;
         this.fetchDealRetailCampaign(event.detail.value);
         let obj = {selectedVal : selectedVal};
        //  console.log('>>>>> obj:::: in site>> ', obj);
         this.dispatchEvent(new CustomEvent('siteselectedchange', {
             detail: obj
         }));
    }
     
    onAssignSiteNumberDef(selectedVal){
        let obj = {selectedVal : selectedVal};
        // console.log('>>>>> obj:::: in site>> ', obj);
        this.dispatchEvent(new CustomEvent('siteselectedchange', {
            detail: obj
        }));
    }
}