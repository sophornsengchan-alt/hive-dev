import { LightningElement, api,track,wire} from 'lwc';
import getCategories from '@salesforce/apex/NewPricingRequestController.getCategories';
import getCategoryTree from '@salesforce/apex/NewPricingRequestController.getCategoryTree';
import { getPicklistValues,getPicklistValuesByRecordType} from 'lightning/uiObjectInfoApi';
import LISTING_FROMAT_FIELD from '@salesforce/schema/FeeType__c.ListingFormat__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import FEETYPE_OBJECT from '@salesforce/schema/FeeType__c'; 
import CONTRACT_OBJECT from '@salesforce/schema/Contract'; 
import customLabels from 'c/customLabels';


export default class LwcCreateNewPricingUI extends LightningElement {
    @api outputVariable;
    @api mode;
    @api currentStep;
    @api isETRS = false;
    @api isStoreSubscription = false;
    @api typeFeeData = [];
    @api pricingData = [];
    @api contractPricingMatrixData = [];
    @api isShowETRSField = false;
    @api isEdit = false; //MN-17062025-US-0032850
    @api isEditFromPricing = false; //MN-14102025-US-0033639
    @api isFromContractAmendment; //LA-01-10-2025:US-0033241
    
    @api contractData = {
        Id:'',
        EBH_StoreSubscription__c:'',
        EBH_Site__c:'',
        StartDate:'',
        EndDate:'',
        TargetType__c:'',
        EBH_AcceleratorThreshold__c:0,
        EBH_AcceleratorTierrebate__c:0,
        EBH_MainTierThresholdofTarget__c:0,
        EBH_RebateTierrebate__c:0,
        EBH_DeceleratorThreshold__c:0,
        EBH_DeceleratorTierrebate__c:0,
    };
    @api headerTitle='Category Name';
    @api headerIcon='standard:table';
    @track selectPricingCategoryList = [];
    @track picklistValues = [];
    @track storSubScriptPicklistValues = [];
    @track selectedRowIds = [];
    @track isTargetTypePercentage = false;
    discountPerOrderFeeType = [];
    isCurrentStep1 = false;
    isCurrentStep2 = false;
    isCurrentStep3 = false;
    isCurrentMode3 = false;
    isCurrentMode4 = false;
    isFeeTypeSection = false;
    isLoading = false;
    searchCategory = '';
    pricingSite = '';

    siteObj = {
        'DE': '77',
        'UK': '3',
        'FR': '71',
        'IT': '101',
        'ES': '186',
        'AU': '15',
        'US': '0',
        'CA': '2',
        'AT': '16',
        'BE': '23',
        'NL': '146',
        'CH': '193',
        'CZ': '197',
        'DK': '198',
        'FI': '199',
        'HU': '202',
        'IE': '205',
        'NZ': '208',
        'NO': '209',
        'PL': '212',
        'SE': '218',
        'US Motors': '100',//LA-01-04-2025: US-0015677
        'CAFR': '210',//LA-01-04-2025: US-0015677
    }
    
    //MN-21042025-US-0017124: Currency ISO Code based on Site Code
    mapSiteCurrency = {
        '77': 'EUR',
        '3': 'GBP',
        '71': 'EUR',
        '101': 'EUR',
        '186': 'EUR',
        '15': 'AUD',
        '0': 'USD',
        '2': 'CAD',
        '16': 'EUR',
        '23': 'EUR',
        '146': 'EUR',
        '193': 'CHF',
        '197': 'CZK',
        '198': 'DKK',
        '199': 'EUR',
        '202': 'HUF',
        '205': 'EUR',
        '208': 'NZD',
        '209': 'NOK',
        '212': 'PLN',
        '218': 'SEK',
        '100': 'USD',
        '210': 'CAD'
    }

    //MN-21042025-US-0017124: Currency symbol based on Currency ISO Code
    mapCurrencySymbol = {
        
        'EUR': '€',    // EUR
        'GBP': '£',     // GBP
        'AUD': 'A$',   // AUD
        'USD': '$',     // USD
        'CAD': 'CA$',   // CAD
        'CHF': 'CHF', // CHF (Swiss Franc has no special symbol)
        '197': 'Kč',  // CZK
        'DKK': 'kr',  // DKK
        'HUF': 'Ft',  // HUF
        'NZD': 'NZ$', // NZD
        'NOK': 'kr',  // NOK
        'PLN': 'zł',  // PLN
        'SEK': 'kr'  // SEK          
    }

    listingFormatObj = {
        'Auction':'AUCTION',
        'Fixed Price':'FIXED',
        'Fixed Price and Auction':'DEFAULT'
    }
    Labels = customLabels; 
    columns = [
        { label: 'Store', fieldName: 'Store__c' },
        { label: 'Name', fieldName: 'Name' },
        { label: 'Category Name', fieldName: 'Category_Name__c' },
        { label: 'Category ID', fieldName: 'Category_Id__c' },
        { label: 'Listing format', fieldName: 'EBH_ListingFormat__c' },
        { label: 'Category Level', fieldName: 'Category_Level__c' }
    ];

    get options() {
        return [
            { label: 'Insertion Fees', value: 'INSERTION_FEE' },
            { label: 'Subtitle', value: 'SUBTITLE_FEE' },
            { label: 'International Site Visibility', value: 'INTERNATIONAL_VISIBILITY_FEE'},
            { label: 'Picture Pack', value: 'PICTURE_PACK_FEE' },
            { label: 'Picture Pack Plus', value: 'PICTURE_PACK_PLUS_FEE' },
            { label: 'Gallery Plus', value: 'GALLERY_PLUS_FEE' },
            { label: 'Bold Title', value: 'BOLD_TITLE_FEE' },
        ];
    }

    get optionsFormat() {
        return [
            { label: 'Auction', value: 'AUCTION' },
            { label: 'Fixed Price', value: 'FIXED' },
            { label: 'Default (Fixed Price and Auction)', value: 'DEFAULT' }
        ];
    }
    // get type fee fields piclist Value
    @wire(getObjectInfo, { objectApiName: FEETYPE_OBJECT })     
    typeFeeInfo;      
    @wire(getPicklistValues, { recordTypeId: '$typeFeeInfo.data.defaultRecordTypeId', fieldApiName: LISTING_FROMAT_FIELD })
    wiredPicklistValues({error,data}) {
        if (data) {
            this.picklistValues = data.values;
        } else if (error) {
        }   
    };
    // get Contract fields piclist Value base on Site      
    @wire(getPicklistValuesByRecordType, {
        objectApiName: CONTRACT_OBJECT,
        recordTypeId: '0126A000000M9xVQAS'
    })
    picklistValues({error,data}) {
        if (data) {
            let storeSub = data.picklistFieldValues.EBH_StoreSubscription__c;
            if (storeSub) {
                let picklistOptions = [];
                let site = this.contractData.EBH_Site__c;
                if(site == ''){ return;}
                storeSub.values.forEach(element => {
                    if(element.validFor.includes(storeSub.controllerValues[site])){
                        picklistOptions.push({
                            label: element.label,
                            value: element.value
                         });
                    }

                 });
                 this.storSubScriptPicklistValues = picklistOptions;
            }  
        }else if (error) {             
        }   
    };
    // startup function connectedCallback
    connectedCallback() { 
        this.isCurrentStep1 = this.currentStep == 1;
        this.isCurrentStep2 = this.currentStep == 2;
        this.isCurrentStep3 = this.currentStep == 3;
        this.isCurrentMode3 = this.mode == 3;
        this.isCurrentMode4 = this.mode == 4;
        if(this.contractData.EBH_Site__c == 'US'){ //LA-07-04-2025: US-0016860 (AC7) | US-0033534 - Remove eTRS eligible? Checkbox from Guided Pricing Flow - UK Only
            this.isShowETRSField = true;
        }
        if(( this.isCurrentStep3 && this.isCurrentMode3) || (this.isCurrentStep2 && this.isCurrentMode4)){
            this.isFeeTypeSection = true;
        }
        this.isTargetTypePercentage = this.contractData.TargetType__c == 'Percentage';
        this.template.addEventListener('keydown', this.handleKeyDown.bind(this));
        //Step 1 or Step 2
        if(this.isCurrentStep1 && this.isCurrentMode3){
            this.handleDataStep1();
        }
        if(this.isCurrentStep1 && this.isCurrentMode4){
            this.handleACPDataStep1();
        }
        //Step 2
        if(this.isCurrentStep2 && this.isCurrentMode3){ 
            this.handleDataStep2();
        }
        //Step 3
        if(this.isFeeTypeSection){
            this.handleDataStep3();
        }
    }

    // .................... Step 1 .....................
    // for ACP.............
    handleACPDataStep1(){


        if (this.isEdit) { //MN-19062025-US-0032850

            let contractData = JSON.parse(JSON.stringify(this.contractData));
            
            let pricingData = JSON.parse(JSON.stringify(this.pricingData));
            pricingData.forEach((item, index) => {
                item.GMV_Target_Label = 'GMV Target (Amount)';
                item.isFirstIndex = index == 0;
            });

            this.pricingData = pricingData;

        }
        else if(this.pricingData.length == 0){
            for(let i = 0; i< 4 ;i++){
                let count = i+1;
                let data = {
                    Id:'',
                    GMV_Target_Label:'GMV Target '+count+' (Amount)',
                    EBH_GMVTarget__c: i == 0?0:null,
                    isFirstIndex: i == 0,
                    EBH_PeriodStartDate__c:null,
                    EBH_AcceleratorThreshold__c:this.contractData.EBH_AcceleratorThreshold__c,
                    EBH_AcceleratorTierrebate__c:this.contractData.EBH_AcceleratorTierrebate__c,
                    EBH_MainThreshold__c:this.contractData.EBH_MainTierThresholdofTarget__c,
                    EBH_RebateTier__c:this.contractData.EBH_RebateTierrebate__c,
                    EBH_DeceleratorThreshold__c:this.contractData.EBH_DeceleratorThreshold__c,
                    EBH_DeceleratorTier__c:this.contractData.EBH_DeceleratorTierrebate__c,
                    Pricing_Accelerator_Tier_Threshold__c: i == 0?0:null,
                    Pricing_Accelerator_Tier_rebate__c: i == 0?0:null,
                    Pricing_Main_Tier_Threshold__c: i == 0?0:null,
                    Pricing_Main_Tier_rebate__c: i == 0?0:null,
                    Pricing_Decelerator_Tier_Threshold__c: i == 0?0:null,
                    Pricing_Main_Tier_Threshold_of_Target__c: i == 0?0:null  
                }
                this.pricingData.push(data);
            }
            
        }
    }

    handleChangePricingFields(event) {
        let data = JSON.parse(JSON.stringify(this.pricingData));
        let idx = parseInt(event.target.dataset.id);
        let name = event.target.dataset.name;
        if(name != 'EBH_PeriodStartDate__c'){
            data[idx][name] = parseFloat(event.target.value);
            if(parseFloat(event.target.value) < 0){
                data[idx][name] = 0;
            }
        }else{
            data[idx][name] = event.target.value;
        }
        this.pricingData = data;
    }

    cascade(){
        let data = JSON.parse(JSON.stringify(this.pricingData));
        for( let i = 0; i < data.length; i++){
            data[i].EBH_GMVTarget__c = data[0].EBH_GMVTarget__c;
            if(this.contractData.TargetType__c == 'Amount'){
                data[i].Pricing_Accelerator_Tier_Threshold__c = data[0].Pricing_Accelerator_Tier_Threshold__c;
                data[i].Pricing_Accelerator_Tier_rebate__c = data[0].Pricing_Accelerator_Tier_rebate__c;
                data[i].Pricing_Main_Tier_Threshold__c = data[0].Pricing_Main_Tier_Threshold__c;
                data[i].Pricing_Main_Tier_rebate__c = data[0].Pricing_Main_Tier_rebate__c;
                data[i].Pricing_Decelerator_Tier_Threshold__c = data[0].Pricing_Decelerator_Tier_Threshold__c;
                data[i].Pricing_Main_Tier_Threshold_of_Target__c = data[0].Pricing_Main_Tier_Threshold_of_Target__c;
            }
        }
        this.pricingData = data;
    }

    //MN-21042025-US-0017124
    /**
     * Name: getCurrencyISOCodePerSite
     * Purpose: Get Currency ISO Code based on Site Code
     * @param {string} siteCode - Site Code
    */
    getCurrencyISOCodePerSite (siteCode){
        return (siteCode && this.mapSiteCurrency[siteCode]) ? this.mapSiteCurrency[siteCode] : '';
    }

    // handleDataStep1 function from connectedCallback to get data for Step 1 at startup
    handleDataStep1(){
        // 
        if(this.pricingData.length > 0){
            this.selectPricingCategoryList = [];
             
            for(let i = 0; i< this.pricingData.length; i++){
                let item = this.pricingData[i];
                let cpmSelectedIds = item.selectedCategory.map(row => row.Id);
                this.selectedRowIds = this.selectedRowIds.concat(cpmSelectedIds);
                let data = {
                    Id:item.Id,
                    isFirstIndex: i == 0,
                    EBH_Site__c:item.EBH_Site__c,
                    T2Amount__c:1,
                    allCategories:item.selectedCategory,
                    selectedCategory:item.selectedCategory,
                    ASP_threshold__c:null,
                    Variable_FVF__c:null,
                    T2DiscountAmount__c:null,
                    Variable_FVF_above_ASP_threshold__c:null,
                    T3DiscountAmount__c:null,
                    T3DiscountFVF__c:null,
                    Fixed_FVF__c:null
                }
                
                this.selectPricingCategoryList.push(data);
            }
        }else{
            this.selectPricingCategoryList = [{
                //for step 1
                Id:'',
                EBH_Site__c:this.contractData.EBH_Site__c,
                T2Amount__c:0,
                allCategories:[],
                selectedCategory:[],
                isFirstIndex:true,
                // for step 2
                ASP_threshold__c:null,
                Variable_FVF__c:null,
                T2DiscountAmount__c:null,
                Variable_FVF_above_ASP_threshold__c:null,
                T3DiscountAmount__c:null,
                T3DiscountFVF__c:null,
                Fixed_FVF__c:null
            }];

            this.pricingData = this.selectPricingCategoryList;
            // get CPM Categories based on Contract Site first startup
            this.getCPMCategories(0,this.contractData.EBH_Site__c,true);
        }
    }

    // handleChangeSite function to handle change site
    handleChangeSite(event) {
        let idx = parseInt(event.target.dataset.id);
        let site = event.target.value;
        this.selectPricingCategoryList[idx].EBH_Site__c = site;
        this.selectPricingCategoryList[idx].selectedCategory = [];
        if(site == ''){return;}
        this.getCPMCategories(idx,site,true);
        
    }

    // handleSearchKeyUp function to handle search CPM data key up
    handleSearchKeyUp(event) {
        if (event.key === 'Enter' && event.target.name === 'search-category') {
            let idx = parseInt(event.target.dataset.id);
            let selectPricingCategoryList = JSON.parse(JSON.stringify(this.selectPricingCategoryList));
            this.searchCategory = event.target.value.toLowerCase();
            let site = selectPricingCategoryList[idx].EBH_Site__c;
            if(site == ''){
                return;
            }
            //get search Category
            this.getCPMCategories(idx,site,false);
        }
    }

    // handleRemoveSite function to remove site
    removeSite(event){
        let data = JSON.parse(JSON.stringify(this.selectPricingCategoryList));
        let idx = parseInt(event.target.dataset.id);
        if(data.length >1){
           // data.splice(idx,1);
           data = data.filter((row,index) => index != idx);
        }else{
            data = [{
                Id:'',
                EBH_Site__c:'',
                allCategories:[],
                selectedCategory:[],
                T2Amount__c:0,
                isFirstIndex:true,
                ASP_threshold__c:null,
                Variable_FVF__c:null,
                T2DiscountAmount__c:null,
                Variable_FVF_above_ASP_threshold__c:null,
                T3DiscountAmount__c:null,
                T3DiscountFVF__c:null,
                Fixed_FVF__c:null
            }];
        }
        this.selectPricingCategoryList = data;
        this.pricingData = this.selectPricingCategoryList;
        this.getSelectedRowIds();
    }

    // handleAddNewSite function to add new default data site
    addNewSite(){
        let data = JSON.parse(JSON.stringify(this.selectPricingCategoryList));
        data.push({
            Id:'',
            EBH_Site__c:'',
            allCategories:[],
            selectedCategory:[],
            T2Amount__c:0,
            isFirstIndex:false,
            ASP_threshold__c:null,
            Variable_FVF__c:null,
            T2DiscountAmount__c:null,
            Variable_FVF_above_ASP_threshold__c:null,
            T3DiscountAmount__c:null,
            T3DiscountFVF__c:null,
            Fixed_FVF__c:null
            
        });
        this.selectPricingCategoryList = data;
        this.pricingData = this.selectPricingCategoryList;
    }

    // handleRowSelection function to handle row selection for CPM data
    handleRowSelection(event){
        let data = JSON.parse(JSON.stringify(this.selectPricingCategoryList));
        let idx = parseInt(event.target.dataset.id);
        let selectedCpmIds = [];
        
        if(event?.detail?.selectedRows && event.detail.selectedRows.length > 0){
            // set selected category
            data[idx].selectedCategory = event.detail.selectedRows;
            data[idx].T2Amount__c = 1;
            selectedCpmIds = data[idx].selectedCategory.map(row => row.Id);
            for(let i = 0; i< data.length; i++){
                let item = data[i];
                if(i == idx) continue;
                if(item.allCategories.length > 0){
                    let allCategories = item.allCategories.filter(row => !selectedCpmIds.includes(row.Id));
                    item.allCategories = allCategories;
                }
            }
        }else{
            data[idx].selectedCategory = [];
            data[idx].T2Amount__c = 0;
        }
        this.selectPricingCategoryList = data;
        this.pricingData = this.selectPricingCategoryList;
        this.getSelectedRowIds();
    }

    // getSelectedRowIds function to handle all selected CPM Ids to avoid duplicate
    getSelectedRowIds(){
        let data = JSON.parse(JSON.stringify(this.selectPricingCategoryList));
        let allSelectedCPMs = [];
        for(let i = 0; i< data.length; i++){
            let item = data[i];
            allSelectedCPMs = allSelectedCPMs.concat(item.selectedCategory);
        }
        let cpmSelectedIds = allSelectedCPMs.map(row => row.Id);
        this.selectedRowIds = cpmSelectedIds;
    }
    // getCPMCategories function to get CPM Categories based on Contract Site
    getCPMCategories(idx,site,isChangeSite){
        let selectPricingCategoryList = JSON.parse(JSON.stringify(this.selectPricingCategoryList));
        if(
            selectPricingCategoryList.length == 1 && 
            selectPricingCategoryList[0].isFirstIndex && 
            selectPricingCategoryList[0].EBH_Site__c == ''
        ){return;}
        this.isLoading = true;
        getCategories({ searchKey: this.searchCategory,site:site, isChangeSite:isChangeSite }).then(result => {
            if(result.length > 0){
                let filterResult = [];
                if(this.selectedRowIds.length == 0){
                    filterResult = result;
                }else{
                    let cmpToView = [];
                    for(let i=0; i<result.length; i++){
                        let item = result[i];
                        if(!this.selectedRowIds.includes(item.Id)){
                            cmpToView.push(item);
                        }
                    }
                    filterResult = cmpToView;
                    if(selectPricingCategoryList[idx].selectedCategory.length > 0){
                        let cpms = selectPricingCategoryList[idx].selectedCategory;
                        filterResult = cpms.concat(filterResult);
                    }
                    
                }
                selectPricingCategoryList[idx].allCategories = filterResult;
                this.isLoading = false;
            }else{
                selectPricingCategoryList[idx].allCategories = [];
                selectPricingCategoryList[idx].selectedCategory = [];
                this.isLoading = false;
            }
            this.selectPricingCategoryList = selectPricingCategoryList;
        }).catch(error => {
            this.isLoading = false;
        });
    }

    // ACP
    handleChangeACPSite(event){
        this.pricingSite = event.target.value;
    }

    // .......................End Step 1 .......................

    // .................... Step 2 .....................
    // handleChangeFields function to handle change fields for Step 2
    handleChangeFields(event) {
        let data = JSON.parse(JSON.stringify(this.selectPricingCategoryList));
        let idx = parseInt(event.target.dataset.id);
        let name = event.target.dataset.name;
        data[idx][name] = parseFloat(event.target.value);
        if(parseFloat(event.target.value) < 0){
            data[idx][name] = 0;
        }
        this.selectPricingCategoryList = data;
        this.handleMappingData2();
    }

    // handleMappingData2 function to handle mapping data
    handleMappingData2(){
        let data = [];
        let cpmData = [];
        let selectPricingCategoryList = JSON.parse(JSON.stringify(this.selectPricingCategoryList));
        //loop dataList
        for(let i=0; i<selectPricingCategoryList.length; i++){
            let item = selectPricingCategoryList[i];
            let oneCPM = {
                Id:item.selectedCategory.Id,
                Name:item.selectedCategory.Name,
                GMVThreshold2__c:item.selectedCategory.GMVThreshold2__c != undefined?item.selectedCategory.GMVThreshold2__c:null,
                GMVThreshold3__c:item.selectedCategory.GMVThreshold3__c != undefined?item.selectedCategory.GMVThreshold3__c:null,
                Tier_2_bps_Discount__c:item.selectedCategory.Tier_2_bps_Discount__c != undefined?item.selectedCategory.Tier_2_bps_Discount__c:null,
                CurrencyIsoCode:item.selectedCategory.CurrencyIsoCode?item.selectedCategory.CurrencyIsoCode:null,
                ASPThreshold__c:item.selectedCategory.ASPThreshold__c != undefined?item.selectedCategory.ASPThreshold__c:null,
                FixedFVF__c:item.selectedCategory.FixedFVF__c != undefined?item.selectedCategory.FixedFVF__c:null,
                VariableFVF__c:item.selectedCategory.VariableFVF__c != undefined?item.selectedCategory.VariableFVF__c:null,
                VariableFVFaboveASPThreshold__c:item.selectedCategory.VariableFVFaboveASPThreshold__c != undefined?item.selectedCategory.VariableFVFaboveASPThreshold__c:null,
                EBH_Site__c:item.EBH_Site__c?item.EBH_Site__c:null,
                Category_Level__c:item.selectedCategory.Category_Level__c?item.selectedCategory.Category_Level__c:null,
                Category_Name__c:item.selectedCategory.Category_Name__c?item.selectedCategory.Category_Name__c:null,
                Category_Id__c:item.selectedCategory.Category_Id__c?item.selectedCategory.Category_Id__c:null,
                EBH_ListingFormat__c:item.selectedCategory.EBH_ListingFormat__c?item.selectedCategory.EBH_ListingFormat__c:null
            }

            let isStandardFVF = true;
            let isStandardPerOrderFee = true;
            if( item.selectedCategory.ASPThreshold__c != item.ASP_threshold__c || item.selectedCategory.VariableFVF__c != item.Variable_FVF__c ||
                item.selectedCategory.GMVThreshold2__c != item.T2DiscountAmount__c || item.selectedCategory.VariableFVFaboveASPThreshold__c != item.Variable_FVF_above_ASP_threshold__c ||
                item.selectedCategory.GMVThreshold3__c != item.T3DiscountAmount__c || item.selectedCategory.Tier_2_bps_Discount__c != item.T3DiscountFVF__c
            ){
                isStandardFVF = false;
            }
            if(item.selectedCategory.FixedFVF__c != item.Fixed_FVF__c){
                isStandardPerOrderFee = false;
            }

            let onePricing = {
                Id:(this.isEdit)?item.Id:oneCPM.Id, //MN-17062025-US-0032850
                selectedCategory:oneCPM,
                //allCategories:[oneCPM],
                EBH_Site__c: item.EBH_Site__c,
                isT3Show:item.isT3Show,
                isT2Show:item.isT2Show,
                Standard_FVF__c:isStandardFVF,
                Standard_Per_per_Order_Fee__c:isStandardPerOrderFee,
                ListingItemFormat__c:oneCPM.EBH_ListingFormat__c,
                T2Amount__c:item.T2Amount__c,
                T3Amount__c:item.T3Amount__c,
                T3DefaultFVF__c:item.T3DefaultFVF__c,
                CurrencyIsoCode:(this.isEdit)?item.CurrencyIsoCode:oneCPM.CurrencyIsoCode, //MN-17062025-US-0032850
                Default_ASP_Threshold__c:oneCPM.ASPThreshold__c,
                Default_Variable_FVF__c:oneCPM.VariableFVF__c,
                Default_Fixed_FVF__c:oneCPM.FixedFVF__c,
                EBH_Projected12MGMV__c:item.EBH_Projected12MGMV__c,
                Orders__c:item.Orders__c,
                EBH_ASP__c:item.EBH_ASP__c,
                ASP_threshold__c:item.ASP_threshold__c,
                Variable_FVF__c:item.Variable_FVF__c,
                T2DiscountAmount__c:item.T2DiscountAmount__c,
                Variable_FVF_above_ASP_threshold__c:item.Variable_FVF_above_ASP_threshold__c,
                T3DiscountAmount__c:item.T3DiscountAmount__c,
                T3DiscountFVF__c:item.T3DiscountFVF__c,
                Fixed_FVF__c:item.Fixed_FVF__c,
                GMVThreshold1__c:item.ASP_threshold__c
            }
            // Contract Pricing Matrix Data
            cpmData.push(oneCPM);
            //Pricing Data
            data.push(onePricing);
        }
        this.contractPricingMatrixData = cpmData;
        this.pricingData = data;
        this.selectedRowIds = this.pricingData.map(row => row.Id);
    }

    // handleDataStep2 function from connectedCallback to get data for Step 2 at startup
    handleDataStep2(){

        if (this.isEdit) { //MN-17062025-US-0032850

            let pricingData = JSON.parse(JSON.stringify(this.pricingData));
            let contractPricingMatrix = JSON.parse(JSON.stringify(this.contractPricingMatrixData));
            let cpmMap = new Map();

            contractPricingMatrix.forEach(record => {
                cpmMap.set(record.Id, record);
            });
            
            let tmpData = [];

            for (let i=0; i<pricingData.length; i++) {

                let item = pricingData[i];
                let isT3Show = true;
                if(item.GMVThreshold3__c < 0){
                    isT3Show = false;
                }
                let isT2Show = true;
                if(item.GMVThreshold2__c < 0){
                    isT2Show = false;
                }
                let GMVThreshold2__c = item.GMVThreshold2__c < 0 ? null : item.GMVThreshold2__c;
                let GMVThreshold3__c = item.GMVThreshold3__c < 0 ? null : item.GMVThreshold3__c;
                let Tier_2_bps_Discount__c = item.Tier_2_bps_Discount__c < 0 ? null : item.Tier_2_bps_Discount__c;
                let ASPThreshold__c = item.ASP_threshold__c < 0 ? null : item.ASP_threshold__c;
                let FixedFVF__c = item.Fixed_FVF__c < 0 ? null : item.Fixed_FVF__c;
                let VariableFVF__c = item.Variable_FVF__c < 0 ? null : item.Variable_FVF__c;
                let VariableFVFaboveASPThreshold__c = item.Variable_FVF_above_ASP_threshold__c < 0 ? null : item.Variable_FVF_above_ASP_threshold__c;

                let cpm = cpmMap.get(item.EBH_ContractPricingMatrix__c);
                
                let oneCPM = {
                    Id:cpm.Id,
                    Name:cpm.Name,
                    GMVThreshold2__c:cpm.GMVThreshold2__c,
                    GMVThreshold3__c:cpm.GMVThreshold3__c,
                    Tier_2_bps_Discount__c:cpm.Tier_2_bps_Discount__c,
                    CurrencyIsoCode:cpm.CurrencyIsoCode,
                    ASPThreshold__c:cpm.ASPThreshold__c,
                    FixedFVF__c:cpm.FixedFVF__c,
                    VariableFVF__c:cpm.VariableFVF__c,
                    VariableFVFaboveASPThreshold__c:cpm.VariableFVFaboveASPThreshold__c,
                    EBH_Site__c:cpm.EBH_Site__c,
                    Category_Level__c:cpm.Category_Level__c,
                    Category_Name__c:cpm.Category_Name__c,
                    Category_Id__c:cpm.Category_Id__c,
                    EBH_ListingFormat__c:cpm.EBH_ListingFormat__c
                }

                let dataObj = {
                    Id:item.Id,
                    isFirstIndex: i == 0,
                    EBH_Site__c:item.EBH_Site__c,
                    Standard_FVF__c:true,
                    Standard_Per_per_Order_Fee__c:true,
                    selectedCategory:oneCPM,
                    isT3Show:isT3Show,
                    isT2Show:isT2Show,
                    ASP_threshold__c:ASPThreshold__c,
                    Variable_FVF__c:VariableFVF__c,
                    T2DiscountAmount__c:GMVThreshold2__c,
                    Variable_FVF_above_ASP_threshold__c:VariableFVFaboveASPThreshold__c,
                    T3DiscountAmount__c:GMVThreshold3__c,
                    T3DiscountFVF__c:Tier_2_bps_Discount__c,
                    Fixed_FVF__c:FixedFVF__c,
                    ListingItemFormat__c:item.EBH_ListingFormat__c,
                    T2Amount__c:item.GMVThreshold2__c,
                    T3Amount__c:item.GMVThreshold3__c,
                    T3DefaultFVF__c:item.Tier_2_bps_Discount__c,
                    GMVThreshold1__c:ASPThreshold__c,
                    CurrencyIsoCode:item.CurrencyIsoCode,
                    Default_ASP_Threshold__c:ASPThreshold__c,
                    Default_Variable_FVF__c:VariableFVF__c,
                    Default_Fixed_FVF__c:FixedFVF__c,
                    EBH_Projected12MGMV__c:item.EBH_Projected12MGMV__c,
                    Orders__c:item.Orders__c,
                    EBH_ASP__c:item.EBH_ASP__c,
                    EBH_ContractPricingMatrix__c:item.EBH_ContractPricingMatrix__c //MN-10102025-US-0033639
               }
               
                let siteCode = this.siteObj[item.EBH_Site__c];
                dataObj.Label1 = 'Projected 12M GMV';
                dataObj.Label2 = 'ASP';
                dataObj.Label3 = 'Default Threshold Amount';
                dataObj.Label4 = 'Discount Threshold Amount (up to)';
                dataObj.Label5 = 'Default Per Order Fee';
                dataObj.Label6 = 'Discount Per Order Fee';
                let currencyISOCode = this.getCurrencyISOCodePerSite(siteCode);
                if(currencyISOCode && currencyISOCode !== '') {
                        dataObj.CurrencyIsoCode = currencyISOCode;

                        let currencySymbol = this.mapCurrencySymbol[currencyISOCode];
                        if (currencySymbol) {
                            dataObj.Label1 = `${dataObj.Label1} (${currencySymbol})`;
                            dataObj.Label2 = `${dataObj.Label2} (${currencySymbol})`;
                            dataObj.Label3 = `${dataObj.Label3} (${currencySymbol})`;
                            dataObj.Label4 = `${dataObj.Label4} (${currencySymbol})`;
                            dataObj.Label5 = `${dataObj.Label5} (${currencySymbol})`;
                            dataObj.Label6 = `${dataObj.Label6} (${currencySymbol})`;
                        }
                }
                //--END
                
                tmpData.push(dataObj);
                
            }

            this.selectPricingCategoryList = tmpData;
            this.pricingData = tmpData;
            this.contractPricingMatrixData = contractPricingMatrix;

        }
        else if(this.pricingData.length > 0){

            this.selectPricingCategoryList = [];
            let cpmData = [];
            //loop site to collect all CPM data
            for(let i = 0; i< this.pricingData.length; i++){
                let item = this.pricingData[i];
                cpmData = cpmData.concat(item.selectedCategory);
                
            }
            // loop CPM data to get all pricing data
            let pricingData = [];
            let contractPricingMatrix = [];
            for(let i = 0; i<cpmData.length; i++){
                
                let item = cpmData[i];
                let isT3Show = true;
                if(item.GMVThreshold3__c < 0){
                    isT3Show = false;
                }
                let isT2Show = true;
                if(item.GMVThreshold2__c < 0){
                    isT2Show = false;
                }
                let GMVThreshold2__c = item.GMVThreshold2__c < 0 ? null : item.GMVThreshold2__c;
                let GMVThreshold3__c = item.GMVThreshold3__c < 0 ? null : item.GMVThreshold3__c;
                let Tier_2_bps_Discount__c = item.Tier_2_bps_Discount__c < 0 ? null : item.Tier_2_bps_Discount__c;
                let ASPThreshold__c = item.ASPThreshold__c < 0 ? null : item.ASPThreshold__c;
                let FixedFVF__c = item.FixedFVF__c < 0 ? null : item.FixedFVF__c;
                let VariableFVF__c = item.VariableFVF__c < 0 ? null : item.VariableFVF__c;
                let VariableFVFaboveASPThreshold__c = item.VariableFVFaboveASPThreshold__c < 0 ? null : item.VariableFVFaboveASPThreshold__c;
                let oneCPM = {
                    Id:item.Id,
                    Name:item.Name,
                    GMVThreshold2__c:GMVThreshold2__c != undefined?GMVThreshold2__c:null,
                    GMVThreshold3__c:GMVThreshold3__c != undefined?GMVThreshold3__c:null,
                    Tier_2_bps_Discount__c:Tier_2_bps_Discount__c != undefined?Tier_2_bps_Discount__c:null,
                    CurrencyIsoCode:item.CurrencyIsoCode != undefined?item.CurrencyIsoCode:null,
                    ASPThreshold__c:ASPThreshold__c != undefined?ASPThreshold__c:null,
                    FixedFVF__c:FixedFVF__c != undefined?FixedFVF__c:null,
                    VariableFVF__c:VariableFVF__c != undefined?VariableFVF__c:null,
                    VariableFVFaboveASPThreshold__c:VariableFVFaboveASPThreshold__c != undefined?VariableFVFaboveASPThreshold__c:null,
                    EBH_Site__c:item.EBH_Site__c?item.EBH_Site__c:null,
                    Category_Level__c:item.Category_Level__c?item.Category_Level__c:null,
                    Category_Name__c:item.Category_Name__c?item.Category_Name__c:null,
                    Category_Id__c:item.Category_Id__c?item.Category_Id__c:null,
                    EBH_ListingFormat__c:item.EBH_ListingFormat__c?item.EBH_ListingFormat__c:null
                }

                let dataObj = {
                    Id:item.Id,
                    isFirstIndex: i == 0,
                    EBH_Site__c:item.EBH_Site__c,
                    Standard_FVF__c:true,
                    Standard_Per_per_Order_Fee__c:true,
                    selectedCategory:oneCPM,
                    isT3Show:isT3Show,
                    isT2Show:isT2Show,
                    ASP_threshold__c:oneCPM.ASPThreshold__c,
                    Variable_FVF__c:oneCPM.VariableFVF__c,
                    T2DiscountAmount__c:oneCPM.GMVThreshold2__c,
                    Variable_FVF_above_ASP_threshold__c:oneCPM.VariableFVFaboveASPThreshold__c,
                    T3DiscountAmount__c:oneCPM.GMVThreshold3__c,
                    T3DiscountFVF__c:oneCPM.Tier_2_bps_Discount__c,
                    Fixed_FVF__c:oneCPM.FixedFVF__c,
                    ListingItemFormat__c:item.EBH_ListingFormat__c,
                    T2Amount__c:item.GMVThreshold2__c,
                    T3Amount__c:item.GMVThreshold3__c,
                    T3DefaultFVF__c:item.Tier_2_bps_Discount__c,
                    GMVThreshold1__c:oneCPM.ASPThreshold__c,
                    CurrencyIsoCode:oneCPM.CurrencyIsoCode,
                    Default_ASP_Threshold__c:oneCPM.ASPThreshold__c,
                    Default_Variable_FVF__c:oneCPM.VariableFVF__c,
                    Default_Fixed_FVF__c:oneCPM.FixedFVF__c,
                    EBH_Projected12MGMV__c:item.EBH_Projected12MGMV__c,
                    Orders__c:item.Orders__c,
                    EBH_ASP__c:item.EBH_ASP__c
               }
               
               //MN-21042025-US-0017124: Get Currency ISO Code based on Site Code--START:
               let siteCode = this.siteObj[item.EBH_Site__c];
               dataObj.Label1 = 'Projected 12M GMV';
               dataObj.Label2 = 'ASP';
               dataObj.Label3 = 'Default Threshold Amount';
               dataObj.Label4 = 'Discount Threshold Amount (up to)';
               dataObj.Label5 = 'Default Per Order Fee';
               dataObj.Label6 = 'Discount Per Order Fee';
               let currencyISOCode = this.getCurrencyISOCodePerSite(siteCode);
               if(currencyISOCode && currencyISOCode !== '') {
                    dataObj.CurrencyIsoCode = currencyISOCode;

                    let currencySymbol = this.mapCurrencySymbol[currencyISOCode];
                    if (currencySymbol) {
                        dataObj.Label1 = `${dataObj.Label1} (${currencySymbol})`;
                        dataObj.Label2 = `${dataObj.Label2} (${currencySymbol})`;
                        dataObj.Label3 = `${dataObj.Label3} (${currencySymbol})`;
                        dataObj.Label4 = `${dataObj.Label4} (${currencySymbol})`;
                        dataObj.Label5 = `${dataObj.Label5} (${currencySymbol})`;
                        dataObj.Label6 = `${dataObj.Label6} (${currencySymbol})`;
                    }
               }
               //--END
               
               pricingData.push(dataObj);
               contractPricingMatrix.push(oneCPM);
            }
            this.selectPricingCategoryList = pricingData;
            this.pricingData = pricingData;
            this.contractPricingMatrixData = contractPricingMatrix;
            
        }
    }
    
    // .......................End Step 2 .......................
    
    // .................... Step 3 .....................

    // handleChangeeTRS function to handle change ETRS
    handleChangeeTRS(event){
        this.isETRS = event.target.checked;
    }

    // handleChangeStoreSubscription function to handle change Store Subscription
    handleChangeStoreSubscription(event){
        this.isStoreSubscription = event.target.checked;
    }

    // handleChangeContractFields function to handle change Contract Fields
    handleChangeContractFields(event) {
        let data = JSON.parse(JSON.stringify(this.contractData));
        let name = event.target.dataset.name;
        data[name] = event.target.value;
        this.contractData = data;
        if(this.contractData.TargetType__c == 'Percentage'){
            this.isTargetTypePercentage = true;
        }else{
            this.isTargetTypePercentage = false;
        }
    }

    // removeFeeType function to remove Fee Type
    removeFeeType(event){
        let idx = parseInt(event.target.dataset.parent);
        let index = parseInt(event.target.dataset.id);
        let data = JSON.parse(JSON.stringify(this.selectPricingCategoryList));
        if(data[idx].feeType.length >1){
            data[idx].feeType.splice(index,1);
        }else{
            
            let inclusionCategoryName = '';
            let inclusionCategoryCode = '';
            if(data[idx].contractPricingMatrix){
                 inclusionCategoryName = data[idx].contractPricingMatrix.EBH_MetaCategoryL2__c;
                 inclusionCategoryCode = data[idx].contractPricingMatrix.Category_Id__c;  
            }
            data[idx].feeType = [{
                TypeofFee__c:'',
                FeeValue__c:0,
                ListingFormat__c:this.isCurrentMode4?'DEFAULT':'', //SB 13.06.2025 US-0026098
                ExclusionCategories__c:'',
                ExclusionCategoryName__c:'',
                InclusionCategories__c:inclusionCategoryCode,
                InclusionCategoryName__c:inclusionCategoryName,
                //MainSite__c:this.siteObj[data[idx].EBH_Site__c], //LA-01-04-2025: US-0015677- no longer use
                PrimarySite__c:data[idx].EBH_Site__c,
                RelatedContract__c:data[idx].EBH_ContractId__c,
                RelatedPricing__c: this.isCurrentMode4?null:data[idx].Id, //SB 13.06.2025 US-0026098 ACP not populate RelatedPricing__c
                isFeatureFeeSubtitle:false,
                allCategories:data[idx].feeType[index].allCategories,
                selectedCategories:[],
            }];
        }
        this.selectPricingCategoryList = data;
        this.handleMappingDataStep3();
        this.getSelectedCategoryTreeRowIds();
    }

    // handleChangeFeatureFee function to handle change Feature Fee
    handleChangeFeatureFee(event){
        let data = JSON.parse(JSON.stringify(this.selectPricingCategoryList));
        let idx = parseInt(event.target.dataset.parent);
        let index = parseInt(event.target.dataset.id);
        let name = event.target.dataset.name;
        data[idx].feeType[index][name] = event.target.value;
        if(data[idx].feeType[index].TypeofFee__c == 'SUBTITLE_FEE'){
            data[idx].feeType[index].isFeatureFeeSubtitle = true;
        }else{
            data[idx].feeType[index].isFeatureFeeSubtitle = false;
            //TH:US-0033533:Comment Out to set default FeeValue__c = 0 when not SUBTITLE_FEE
            //data[idx].feeType[index].FeeValue__c = null; //MN-19062025-US-0032850: reset FeeValue__c when not SUBTITLE_FEE
        }
        this.selectPricingCategoryList = data;
        this.handleMappingDataStep3();
    }

    // handleDataStep3 function from connectedCallback to get data for Step 3 at startup
    handleDataStep3(){

        
        let feeTypeMap = new Map();

        if (this.isEdit && this.isCurrentMode3) { //MN-17062025-US-0032850
            let feeTypeData = JSON.parse(JSON.stringify(this.typeFeeData));
            feeTypeData.forEach(feetype => {
                if (!feeTypeMap.has(feetype.RelatedPricing__c)) {
                    feeTypeMap.set(feetype.RelatedPricing__c, []);
                }
                feeTypeMap.get(feetype.RelatedPricing__c).push(feetype);
            });
        }

        this.selectPricingCategoryList = [];
        if (!this.isEdit || this.isCurrentMode3) { //MN-19062025-US-0032850: Do not reset feeTypeData when editing in mode 4
            this.typeFeeData = [];
        } 

        this.headerTitle = 'Exclusion Categories List';
        this.columns = [
            { label: 'Category Name', fieldName: 'Name' },
            { label: 'Category ID', fieldName: 'Category_ID__c' },
            { label: 'Category Level', fieldName: 'Level__c'},
            { label: 'Category Site ID', fieldName: 'Site__c'}
        ];
        let sitIds = [];
        let pricingArr = [];
        let pricingData = JSON.parse(JSON.stringify(this.pricingData));
        let levels = 0;
        
        for(let i = 0; i< pricingData.length; i++){
            let item = pricingData[i];
            let data = {};
            
            if(this.isCurrentMode3){

                let cpmItem = this.contractPricingMatrixData.filter(row => row.Id == item.EBH_ContractPricingMatrix__c);
                let inclusionCategoryName = cpmItem[0].EBH_MetaCategoryL2__c;
                let inclusionCategoryCode = cpmItem[0].Category_Id__c;
                item.InclusionCategoryName__c = inclusionCategoryName;
                item.InclusionCategories__c = inclusionCategoryCode;

                if(i == 0){ //LA-22-05-2025-US-0026099-the first categorytree table to display
                    sitIds.push(this.siteObj[item.EBH_Site__c]);     
                }
                levels = cpmItem[0].Category_Level__c;
                let isNoLevelToSelect = levels > 4? true : false;
                
                let listingFormat = this.listingFormatObj[cpmItem[0].EBH_ListingFormat__c];
                data = {
                    Id:item.Id,
                    isActivedIndex:'ExpandIndex'+i,//LA-22-05-2025-US-0026099
                    EBH_Site__c:item.EBH_Site__c,
                    EBH_ContractPricingMatrix__c:item.EBH_ContractPricingMatrix__c,
                    EBH_ContractId__c:item.EBH_ContractId__c,
                    feeType:[{
                        TypeofFee__c:'',
                        isNoLevelToSelect: isNoLevelToSelect,
                        FeeValue__c:0,
                        ListingFormat__c:listingFormat,
                        ExclusionCategories__c:'',
                        ExclusionCategoryName__c:'',
                        InclusionCategories__c:inclusionCategoryCode,
                        InclusionCategoryName__c:inclusionCategoryName,
                        isFirstIndex:true,
                        //MainSite__c:this.siteObj[item.EBH_Site__c],//LA-01-04-2025: US-0015677- no longer use
                        PrimarySite__c:item.EBH_Site__c,
                        RelatedContract__c:item.EBH_ContractId__c,
                        StartDate__c:this.contractData.StartDate,
                        EndDate__c:this.contractData.EndDate,
                        RelatedPricing__c:item.Id,
                        isFeatureFeeSubtitle:false,
                        allCategories:item.allCategories?item.allCategories:[],
                        selectedCategories:item.selectedCategories?item.selectedCategories:[],
                        selectedRows:[]
                        
                    }],
                    contractPricingMatrix:{
                        Category_Name__c:cpmItem[0].Category_Name__c,
                        Category_Id__c:cpmItem[0].Category_Id__c,
                        EBH_MetaCategoryL2__c:cpmItem[0].EBH_MetaCategoryL2__c,
                        EBH_ListingFormat__c:cpmItem[0].EBH_ListingFormat__c,
                        Category_Level__c:cpmItem[0].Category_Level__c ////LA-22-05-2025-US-0026099
                    },
                }

                if (this.isEdit && feeTypeMap.has(item.Id)) { //MN-17062025-US-0032850
                    data.feeType = feeTypeMap.get(item.Id);
                    data.feeType.forEach(fee => {
                        fee.isNoLevelToSelect = isNoLevelToSelect;
                        fee.isFirstIndex = false;
                        fee.selectedRows = [];
                    });
                    data.feeType[0].isFirstIndex = true; // Ensure the first fee type is marked as first index
                    
                }

                if(!this.isEdit && cpmItem[0].FixedFVF__c != item.Fixed_FVF__c){ //MN-17062025-US-0032850
                    let onefeeType = {
                        TypeofFee__c:'FINAL_VALUE_FEE_ORDER_LEVEL_FIXED_FEE',
                        FeeValue__c:item.Fixed_FVF__c,
                        ListingFormat__c:listingFormat,
                        InclusionCategories__c:inclusionCategoryCode,
                        InclusionCategoryName__c:inclusionCategoryName,
                        StoreName__c:this.contractData.EBH_StoreSubscription__c,
                        //MainSite__c:this.siteObj[item.EBH_Site__c], //LA-01-04-2025: US-0015677- no longer use
                        PrimarySite__c:item.EBH_Site__c,
                        RelatedContract__c:item.EBH_ContractId__c,
                        StartDate__c:this.contractData.StartDate,
                        EndDate__c:this.contractData.EndDate,
                        RelatedPricing__c:item.Id,
                    };
                    this.typeFeeData.push(onefeeType);
                    this.discountPerOrderFeeType.push(onefeeType);
                }

            }else if(this.isCurrentMode4){
                
                if(i == 0){ sitIds.push(this.siteObj[item.EBH_Site__c]); } //LA-22-05-2025-US-0026099
                //sitIds.push(this.siteObj[item.EBH_Site__c]);
                data = {
                    Id:'',
                    isActivedIndex:'ExpandIndex'+i,//LA-22-05-2025-US-0026099
                    EBH_Site__c:item.EBH_Site__c,
                    EBH_ContractId__c:item.EBH_ContractId__c,
                    // label: 'GMV Target '+(i+1),
                    feeType:[{
                        TypeofFee__c:'',
                        FeeValue__c:0,
                        ListingFormat__c:'DEFAULT', //SB 13.06.2025 US-0026098
                        ExclusionCategories__c:'',
                        ExclusionCategoryName__c:'',
                        InclusionCategories__c:'',
                        InclusionCategoryName__c:'',
                        StoreName__c:this.contractData.EBH_StoreSubscription__c,
                        isFirstIndex:true,
                        //MainSite__c:this.siteObj[item.EBH_Site__c],//LA-01-04-2025: US-0015677- no longer use
                        PrimarySite__c:item.EBH_Site__c,
                        RelatedContract__c:item.EBH_ContractId__c,
                        StartDate__c:this.contractData.StartDate,
                        EndDate__c:this.contractData.EndDate,
                        // RelatedPricing__c:item.Id, //SB 13.06.2025 US-0026098
                        isFeatureFeeSubtitle:false,
                        allCategories:item.allCategories?item.allCategories:[],
                        selectedCategories:item.selectedCategories?item.selectedCategories:[],
                    }],
                }

                if (!this.isEditFromPricing) { //MN-14102025-US-0033639: This block will be executed only when not edit from pricing
                //SB 13.06.2025 US-0026098 ACP show only 1 set of Fee Type
                this.typeFeeData = this.typeFeeData.concat(data.feeType);
                this.selectPricingCategoryList.push(data);
                pricingArr.push(item);
                break;
                
            }
                
            }
            this.typeFeeData = this.typeFeeData.concat(data.feeType);
            this.selectPricingCategoryList.push(data);
            pricingArr.push(item);   
        }
        //get Contract Category list
        //this.getContractCategory(sitIds);
        if (!this.isEdit || this.isEditFromPricing) { //MN-17062025-US-0032850 //MN-14102025-US-0033639: only get category tree when not edit or edit from pricing
            this.getContractCategory(sitIds,levels);
        }
        else if (this.isCurrentMode4){ //MN-19062025-US-0032850: From US-0026098, ACP FeeType won't have relation with Pricing anymore

            sitIds.push(this.siteObj[this.contractData.EBH_Site__c]); 

            let feeTypeData = JSON.parse(JSON.stringify(this.typeFeeData));
            
            let data = {
                Id:'',
                // isActivedIndex:'ExpandIndex'+0,
                feeType:[]
            };

            data.feeType = feeTypeData;
            feeTypeData.forEach((feetype, i) => {

                feetype.isActivedIndex = 'ExpandIndex'+i;

                if (i === 0) {
                    data.EBH_Site__c = feetype.PrimarySite__c;
                    data.EBH_ContractId__c = feetype.RelatedContract__c;
                }

                if (feetype.TypeofFee__c === 'SUBTITLE_FEE') {
                    feetype.isFeatureFeeSubtitle = true;
                }

                feetype.allCategories = [];
                feetype.selectedCategories = [];
                feetype.selectedRows = [];

            });

            // this.typeFeeData = this.typeFeeData.concat(data.feeType);
            this.typeFeeData = feeTypeData; 
            this.selectPricingCategoryList.push(data);

        }

        this.pricingData = pricingArr;

        

    }

    // addNewFeeType function to add new Fee Type
    addNewFeeType(event){
        let idx = parseInt(event.target.dataset.parent);
        let data = JSON.parse(JSON.stringify(this.selectPricingCategoryList));
        let level = (this.isCurrentMode3) ? parseInt(event.target.dataset.level) : 0;
        let inclusionCategoryName = '';
        let inclusionCategoryCode = '';
        let listingFormat = '';
        if(data[idx].contractPricingMatrix != null){
             inclusionCategoryName = data[idx].contractPricingMatrix.EBH_MetaCategoryL2__c;
             inclusionCategoryCode = data[idx].contractPricingMatrix.Category_Id__c;
             listingFormat = this.listingFormatObj[data[idx].contractPricingMatrix.EBH_ListingFormat__c];
             
        }
        
        data[idx].feeType.push({
            TypeofFee__c:'',
            FeeValue__c:0,
            ListingFormat__c:this.isCurrentMode4?'DEFAULT':listingFormat, //SB 13.06.2025 US-0026098
            isFirstIndex:false,
            ExclusionCategories__c:'',
            ExclusionCategoryName__c:'',
            InclusionCategories__c:inclusionCategoryCode,
            InclusionCategoryName__c:inclusionCategoryName,
            //MainSite__c:this.siteObj[data[idx].EBH_Site__c], //LA-01-04-2025: US-0015677- no longer use
            PrimarySite__c:data[idx].EBH_Site__c,
            RelatedContract__c:data[idx].EBH_ContractId__c,
            StartDate__c:this.contractData.StartDate,
            EndDate__c:this.contractData.EndDate,
            RelatedPricing__c: this.isCurrentMode4?null:data[idx].Id, //SB 13.06.2025 US-0026098 ACP not populate RelatedPricing__c
            isFeatureFeeSubtitle:false,
            allCategories:[],
            selectedCategories:[],
        });
        this.selectPricingCategoryList = data;
        this.handleMappingDataStep3();
        let index = data[idx].feeType.length-1;
        this.getContractCategoryBySingleFeeType(idx,index,'',level);
    }

    // handleContractCategoriesRowSelection function to handle Contract Categories Row Selection
    handleContractCategoriesRowSelection(event){
        
        let data = JSON.parse(JSON.stringify(this.selectPricingCategoryList));
        let pricingData = JSON.parse(JSON.stringify(this.pricingData));
        
        let index = parseInt(event.target.dataset.id);
        let idx = parseInt(event.target.dataset.parent);
        let selectedCateName = [];
        let selectedCateCode = [];

        if(event?.detail?.selectedRows && event.detail.selectedRows.length > 0){
            // set selected category
            data[idx].feeType[index].selectedCategories = event.detail.selectedRows;

            selectedCateName = data[idx].feeType[index].selectedCategories.map(row => row.Name_with_Id__c);
            selectedCateCode = data[idx].feeType[index].selectedCategories.map(row => row.Category_ID__c);
            
            data[idx].feeType[index].ExclusionCategories__c = selectedCateCode.join(';');
            data[idx].feeType[index].ExclusionCategoryName__c = selectedCateName.join(';');
           
            data[idx].feeType[index].selectedRows = data[idx].feeType[index].selectedCategories.map(row => row.Id); //MN-19062025-US-0032850 
           
        }else{

            data[idx].feeType[index].selectedCategories = [];
            data[idx].feeType[index].ExclusionCategories__c = '';
            data[idx].feeType[index].ExclusionCategoryName__c = '';

            if (pricingData && pricingData.length > 0 && pricingData[idx]) {
            pricingData[idx].ExclusionCategories__c = '';
            pricingData[idx].ExclusionCategoryName__c = '';
        }
            

            data[idx].feeType[index].selectedRows = [];
        }


        this.selectPricingCategoryList = data;
        this.pricingData = pricingData;
        this.handleMappingDataStep3();
        this.getSelectedCategoryTreeRowIds();
        
    }
    
    // handleMappingDataStep3 function to handle mapping data for Step 3
    handleMappingDataStep3(){
        let feeType = [];
        let selectPricingCategoryList = JSON.parse(JSON.stringify(this.selectPricingCategoryList));
        for(let i = 0; i< selectPricingCategoryList.length; i++){
            let item = selectPricingCategoryList[i].feeType;
            feeType = feeType.concat(item);
        }
        if(this.discountPerOrderFeeType.length > 0){
            feeType = feeType.concat(this.discountPerOrderFeeType);
        }

        this.typeFeeData = feeType;

    }

    // getContractCategory function to get Contract Category Ids
    getContractCategory(sitIds,levels){ //LA-22-05-2025-US-0026099-add parameter levels
        this.isLoading = true;
        let selectPricingCategoryList = JSON.parse(JSON.stringify(this.selectPricingCategoryList));
        //get search Category
        getCategoryTree({ siteList:sitIds,searchKey:'',isSearchCategory:false,isContractLA:this.isCurrentMode3,cateLevel:levels, cateList:[]}).then(result => {
            
            this.isLoading = false;
            
            if(result.length > 0){
                for(let i = 0; i< selectPricingCategoryList.length; i++){
                    let item = selectPricingCategoryList[i];
                    let site = this.siteObj[item.EBH_Site__c];
                    let contractCategoryList = result.filter(row => row.Site__c == site);
                    item.feeType[0].allCategories = contractCategoryList;
                }
                
            }
            this.selectPricingCategoryList = selectPricingCategoryList;
        }).catch(error => {
            this.isLoading = false;
        });
    }
    //getContractCategoryBySingleFeeType function to get Contract Category Ids by single fee type
    getContractCategoryBySingleFeeType(idx,index,searchCategory,level){//LA-22-05-2025-US-0026099-add parameter level
        let selectPricingCategoryList = JSON.parse(JSON.stringify(this.selectPricingCategoryList));
        let site = this.siteObj[selectPricingCategoryList[idx].EBH_Site__c];
        let siteIds = [site];
        //get search Category
        this.isLoading = true;
        let cateList = [];
        if (this.isEdit) {
            let exclusionCategories = selectPricingCategoryList[idx].feeType[index].ExclusionCategories__c;
            if (exclusionCategories && exclusionCategories !== '') {

                cateList = exclusionCategories.split(';');
               
            }
        }
        
        getCategoryTree({ siteList:siteIds,searchKey:searchCategory,isSearchCategory:true,isContractLA:this.isCurrentMode3,cateLevel:level, cateList: cateList}).then(result => {
            
            this.isLoading = false;
            if(result.length > 0){

                let filterResult = [];

                
                if (this.isEdit) { //MN-17062025-US-0032850

                    let exclusionCategories = selectPricingCategoryList[idx].feeType[index].ExclusionCategories__c;
                    
                    selectPricingCategoryList[idx].feeType[index].selectedRows = [];
                    if (exclusionCategories && exclusionCategories !== '') {
                        let selectedCategories = exclusionCategories.split(';');
                        let selectedRows = result.filter(row => selectedCategories.includes(row.Category_ID__c));
                        
                        //Check if selectedCategories & selectedRows has values
                        let existingSelectedCategories = selectPricingCategoryList[idx].feeType[index].selectedCategories || [];
                        let combinedSelectedCategories = [...existingSelectedCategories, ...selectedRows];

                        // Optional: Remove duplicates by unique Category_ID__c
                        let unique = [];
                        let seen = new Set();

                        for (let row of combinedSelectedCategories) {
                            if (!seen.has(row.Category_ID__c)) {
                                seen.add(row.Category_ID__c);
                                unique.push(row);
                            }
                        }

                        //Store only selected id 
                        let selectedIds = unique.map(row => row.Id);
                        
                        this.selectedRowIds = selectedIds;
                        //selectPricingCategoryList[idx].feeType[index].selectedCategories = selectedRows;
                        selectPricingCategoryList[idx].feeType[index].selectedCategories = unique;
                        selectPricingCategoryList[idx].feeType[index].selectedRows = selectedIds;

                    }

                    
    
                }
                
                if((!this.isEdit && this.selectedRowIds.length == 0) || (this.isEdit && (!selectPricingCategoryList[idx].feeType[index].selectedCategories || selectPricingCategoryList[idx].feeType[index].selectedCategories.length == 0))){//MN-17062025-US-0032850
                    filterResult = result;
                }else{
                    
                    let cateToView = []; 
                    let selectedId = selectPricingCategoryList[idx].feeType[index].selectedCategories.map(row => row.Id);
                    // let selectedId = (selectPricingCategoryList[idx]?.feeType[index]?.selectedCategories || [])
                    //             .filter(row => row && row.Id)   // keep only rows that exist *and* have an Id
                    //             .map    (row => row.Id);        // pull out the Id values
                    for(let i=0; i<result.length; i++){
                        let item = result[i];
                        if(!selectedId.includes(item.Id)){
                            cateToView.push(item);
                        }
                    }
                    filterResult = cateToView;
                    if(selectPricingCategoryList[idx].feeType[index].selectedCategories.length > 0){
                        let cpms = selectPricingCategoryList[idx].feeType[index].selectedCategories;
                        filterResult = cpms.concat(filterResult);
                    }
                    
                }

                selectPricingCategoryList[idx].feeType[index].allCategories = filterResult;
   
            }
            
            this.selectPricingCategoryList = selectPricingCategoryList;
            

        }).catch(error => {
            console.error('Error:', error);
            this.isLoading = false;
        });
    }

    // handleSearchCategoryKeyUp function to handle search category key up
    handleSearchCategoryKeyUp(event) {
        if (event.key === 'Enter' && event.target.name === 'search-contract-category') {
            let idx = parseInt(event.target.dataset.parent);
            let index = parseInt(event.target.dataset.id);
            let searchCategory = event.target.value.toLowerCase();
            let level = (this.isCurrentMode3) ? parseInt(event.target.dataset.level) : 0;//LA-22-05-2025-US-0026099
            this.getContractCategoryBySingleFeeType(idx,index,searchCategory,level);
        }
       
    }
    // getSelectedCategoryTreeRowIds function to get selected category tree row ids
    getSelectedCategoryTreeRowIds(){
        
        let data = JSON.parse(JSON.stringify(this.selectPricingCategoryList));
        
        let allFeeType = []; 
        for(let i = 0; i< data.length; i++){
            let item = data[i];
            allFeeType = allFeeType.concat(item.feeType);
        }
        let allSelectedCategoryTree = [];
        for(let i = 0; i< allFeeType.length; i++){
            let item = allFeeType[i];
            
            allSelectedCategoryTree = allSelectedCategoryTree.concat(item.selectedCategories);
        }

        let cateSelectedIds = allSelectedCategoryTree.filter(row => row && row.Id).map(row => row.Id);

        this.selectedRowIds = cateSelectedIds;
    }
    
    // handleKeyDown function to handle key down event for preventDefault
    handleKeyDown(event) {
        if (event.key === 'Enter' && event.target.name === 'search-category') {
            event.preventDefault();
        }
    }

    // handleSectionToggle function to handle expand table
    handleSectionToggle(event) {//LA-22-05-2025-US-0026099
        
        let openSections = event.detail.openSections;
        let idx = parseInt(event.target.dataset.parent);
        let index = parseInt(event.target.dataset.id);
        let level = (this.isCurrentMode3) ? parseInt(event.target.dataset.level) : 0;
        
        if(openSections.length > 0){
            this.getContractCategoryBySingleFeeType(idx,index,'',level);
        }
    }
}