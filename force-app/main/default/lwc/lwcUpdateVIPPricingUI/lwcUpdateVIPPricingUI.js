import { LightningElement, api,track,wire} from 'lwc';
import getContractCategoriesApex from '@salesforce/apex/NewPricingRequestController.getContractCategories';
import { getPicklistValues} from 'lightning/uiObjectInfoApi';
import LISTING_FROMAT_FIELD from '@salesforce/schema/FeeType__c.ListingFormat__c';
import MAINSITE_FIELD from '@salesforce/schema/FeeType__c.MainSite__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import FEETYPE_OBJECT from '@salesforce/schema/FeeType__c'; 
import customLabels from 'c/customLabels';

export default class LwcUpdateVIPPricingUI extends LightningElement {

    @api mode;
    @api currentStep;
    @api typeFeeData = [];
    @api pricingData = [];
    @api contractPricingMatrixData = [];
    @api isEdit = false; //MN-17062025-US-0032850
    @api errorPricingId = []; //MN-23072025-US-0033150
    @api contractCategory2create = []; //MN-25072025-US-0033150
    @api contractCategory2delete = []; //MN-25072025-US-0033150
    @api DefaultExclusionCategory = [];
    @api isEmptyInclusionCategory = false;
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
    
    @api headerIcon='standard:table';
    @api isStandardVIP = false;

    
    recordTypeId;
    @track picklistValues = [];
    @track siteOptions = [];
    
    allCategoryTree = []; 
    
    isCurrentStep1 = false;
    isCurrentMode1 = false; //For VIP - Update existing pricing/category
    isCurrentMode2 = false; //For VIP - Create New Fee Type
    
    isLoading = false;
    defSection = 'Section0';
    rtCCPricing = '';
    isProcessError = false;
    
    /*Site Object to map Site ID to Site Name */
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
        'US Motors': '100',
        'CAFR': '210'
    }

    // Reverse mapping for siteObj to map Site Name to Site ID
    mapSite = Object.fromEntries(
        Object.entries(this.siteObj).map(([key, value]) => [value, key])
    );
    
    // Mapping for site currency based on Site ID
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

    Labels = customLabels; 
    columns = [
        { label: 'Store', fieldName: 'Store__c' },
        { label: 'Name', fieldName: 'Name' },
        { label: 'Category Name', fieldName: 'Category_Name__c' },
        { label: 'Category ID', fieldName: 'Category_Id__c' },
        { label: 'Listing format', fieldName: 'EBH_ListingFormat__c' },
        { label: 'Category Level', fieldName: 'Category_Level__c' }
    ];

    // Picklist options for Type of Fee
    get options() {
        return [
            { label: 'Final Value Fee Order Level Fixed', value: 'FINAL_VALUE_FEE_ORDER_LEVEL_FIXED_FEE' },
            { label: 'Insertion Fees', value: 'INSERTION_FEE' },
            { label: 'Subtitle', value: 'SUBTITLE_FEE' },
            { label: 'Gallery Plus', value: 'GALLERY_PLUS_FEE' },
            { label: 'International Site Visibility', value: 'INTERNATIONAL_VISIBILITY_FEE'},
            { label: 'Picture Pack', value: 'PICTURE_PACK_FEE' },
            { label: 'Picture Pack Plus', value: 'PICTURE_PACK_PLUS_FEE' },
            { label: 'Bold Title', value: 'BOLD_TITLE_FEE' },
        ];
    }

    // Picklist options for Additional Site
    get addSiteOptions() {
        return [
            { label: 'US-Motors', value: 'US-Motors' },
            { label: 'CA-FR', value: 'CA-FR' }
        ];
    }

    // Check if the contract is a FVF
    get isFVF() {
        return this.contractData.DiscountType__c == 'Flat rate';
    }

    // Check if the contract is a BPS
    get isBps() {
        return !this.isFVF;
    }

    // Step 1: Get record type info
    @wire(getObjectInfo, { objectApiName: FEETYPE_OBJECT })
    typeFeeInfo({ data, error }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;
        }
    }

    // Step 2: Get listing format picklist
    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: LISTING_FROMAT_FIELD
    })
    listingFormatPicklist({ data, error }) {
        if (data) {
            this.picklistValues = data.values;
        }
    }

    // Step 3: Get main site picklist
    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: MAINSITE_FIELD
    })
    sitePicklist({ data, error }) {
        if (data) {
            this.siteOptions = data.values;
        } 
    }
    
    
    // startup function connectedCallback
    connectedCallback() { 

        this.isCurrentStep1 = this.currentStep == 1;
        
        this.isCurrentMode1 = this.mode == 1; //For VIP - Update existing pricing
        this.isCurrentMode2 = this.mode == 2; //For VIP - Update existing fee type

        //MN-21072025-US-0033150: For VIP - Update existing pricing
        if (this.isCurrentMode1) {    
            this.handleUpdatePricingData();
        }else if (this.isCurrentMode2) { 
            this.handleCreateNewFeeType();
        }

    }

    
    rendered = false; // Flag to track if the component has been rendered
    renderedCallback() {
        if (this.rendered) {
            return;
        }
        this.rendered = true;

        // Process error pricing if in Step 1 and Mode 1
        if (this.isCurrentStep1 && this.isCurrentMode1) {    
            let errorPricingId = JSON.parse(JSON.stringify(this.errorPricingId));
        
            if (errorPricingId.length > 0) {
                this.processErrorPricing(errorPricingId);
            }
        }
        
    }

    // .................... Step 1 .....................
    // for VIP - Create New FeeType
    handleCreateNewFeeType() {

        let pricingData = JSON.parse(JSON.stringify(this.pricingData));
        pricingData.forEach((item,index) => {
            item.link = '/' + item.Id;
            item.secIdx = 'Section' + index;
            item.feeType = [{
                TypeofFee__c:'',
                FeeValue__c:0,
                ListingFormat__c:'DEFAULT',
                ExclusionCategories__c:item.ExclusionCategories__c,
                ExclusionCategoryName__c:item.ExclusionCategoryName__c,
                InclusionCategories__c:item.InclusionCategories__c,
                InclusionCategoryName__c:item.InclusionCategoryName__c,
                isFirstIndex:true,
                PrimarySite__c:'',
                TargetType__c : this.contractData.TargetType__c,
                RelatedContract__c:item.EBH_ContractId__c,
                StartDate__c:this.contractData.StartDate,
                EndDate__c:this.contractData.EndDate,
                RelatedPricing__c:item.Id, 
                CurrencyIsoCode : this.mapSiteCurrency[this.siteObj[item.EBH_Site__c]],
                isFeatureFeeSubtitle:false,
                isUS : false
            }];

        });

        this.pricingData = pricingData;
    }

    // handleChangeFeatureFee function to handle change Feature Fee
    handleChangeFeatureFee(event){
        let data = JSON.parse(JSON.stringify(this.pricingData));
        let idx = parseInt(event.target.dataset.parent);
        let index = parseInt(event.target.dataset.id);
        let name = event.target.dataset.name;
        data[idx].feeType[index][name] = event.target.value;
        if(data[idx].feeType[index].TypeofFee__c == 'SUBTITLE_FEE'){
            data[idx].feeType[index].isFeatureFeeSubtitle = true;
        }else{
            data[idx].feeType[index].isFeatureFeeSubtitle = false;
            data[idx].feeType[index].FeeValue__c = 0; 
        }
        
        if (name === 'PrimarySite__c') {
            data[idx].feeType[index].isUS = event.target.value === '0'; // Check if the selected site is 'US'
        }

        this.pricingData = data;
        this.handleMappingFeeData();
    }

    // handleMappingFeeData function to map fee type data
    handleMappingFeeData(){

        let feeType = [];
        let pricingData = JSON.parse(JSON.stringify(this.pricingData));
        for(let i = 0; i< pricingData.length; i++){
            let item = pricingData[i].feeType;
            feeType = feeType.concat(item);
        }

        feeType.forEach((item, index) => {
            
            if (this.isStandardVIP) {
                item.DiscountType__c = 'PERCENTAGE';
                item.PrimarySite__c = item.PrimarySite__c ? this.mapSite[item.PrimarySite__c] : '';
                item.AdditionalSite__c = (item.PrimarySite__c == 'US')?item.AdditionalSite__c:'';
            }
        });
        
        this.typeFeeData = feeType;

    }

    // removeFeeType function to remove Fee Type
    removeFeeType(event){

        let idx = parseInt(event.target.dataset.parent);
        let index = parseInt(event.target.dataset.id);
        let data = JSON.parse(JSON.stringify(this.pricingData));
        if(data[idx].feeType.length >1){
            data[idx].feeType.splice(index,1);
        }else{
            
            data[idx].feeType = [{
                TypeofFee__c:'',
                FeeValue__c:0,
                ListingFormat__c:'',
                ExclusionCategories__c:data[idx].ExclusionCategories__c,
                ExclusionCategoryName__c:data[idx].ExclusionCategoryName__c,
                InclusionCategories__c:data[idx].InclusionCategories__c,
                InclusionCategoryName__c:data[idx].InclusionCategoryName__c,
                isFirstIndex:true,
                PrimarySite__c:'',
                RelatedContract__c:data[idx].EBH_ContractId__c,
                StartDate__c:this.contractData.StartDate,
                EndDate__c:this.contractData.EndDate,
                RelatedPricing__c:data[idx].Id, 
                TargetType__c : this.contractData.TargetType__c,
                CurrencyIsoCode : this.mapSiteCurrency[this.siteObj[data[idx].EBH_Site__c]],
                isFeatureFeeSubtitle:false,
                isUS : false
            }];
        }
        this.pricingData = data;
        this.handleMappingFeeData();
    }

    // addNewFeeType function to add new Fee Type
    addNewFeeType(event){

        let idx = parseInt(event.target.dataset.parent);
        let data = JSON.parse(JSON.stringify(this.pricingData));
        
        data[idx].feeType.push({
            TypeofFee__c:'',
            FeeValue__c:0,
            ListingFormat__c:'',
            ExclusionCategories__c:data[idx].ExclusionCategories__c,
            ExclusionCategoryName__c:data[idx].ExclusionCategoryName__c,
            InclusionCategories__c:data[idx].InclusionCategories__c,
            InclusionCategoryName__c:data[idx].InclusionCategoryName__c,
            isFirstIndex:false,
            PrimarySite__c:'',
            RelatedContract__c:data[idx].EBH_ContractId__c,
            StartDate__c:this.contractData.StartDate,
            EndDate__c:this.contractData.EndDate,
            RelatedPricing__c:data[idx].Id, 
            TargetType__c : this.contractData.TargetType__c,
            CurrencyIsoCode : this.mapSiteCurrency[this.siteObj[data[idx].EBH_Site__c]],
            isFeatureFeeSubtitle:false,
            isUS : false
        });

        this.pricingData = data;
        this.handleMappingFeeData();
        
    }

    // for VIP - Update Existing Pricing
    handleUpdatePricingData() {

        let errorPricingId = JSON.parse(JSON.stringify(this.errorPricingId));
        
        let pricingData = JSON.parse(JSON.stringify(this.pricingData));
        pricingData.forEach((item,index) => {
            item.link = '/' + item.Id;
            item.secIdx = 'Section' + index;
            
            if (errorPricingId.length == 0 && !this.isEmptyInclusionCategory) {

                item.inc_cate_in_db = [];
                item.exc_cate_in_db = [];
                item.inc_cate_selected = [];
                item.exc_cate_selected = [];
                item.allCategoryTreeIncl = [];
                item.allCategoryTreeExcl = [];
                item.SelectedCategory = [];
                item.isInit = false;
            }

            item.isEmptyInclusionCategory = (item.InclusionCategories__c == null || item.InclusionCategories__c == '');

        });
        this.pricingData = pricingData;

        this.columns = [
            { label: 'Category Name', fieldName: 'Name' },
            { label: 'Category ID', fieldName: 'Category_ID__c' },
            { label: 'Category Level', fieldName: 'Level__c'},
            { label: 'Category Site ID', fieldName: 'Site__c'}
        ];
   
    }

    /** 
     * Processes error pricing IDs and validates corresponding pricing records.
     */
    processErrorPricing(errorPricingId) {
        
        let errorIdSet = new Set(errorPricingId);
        let pricingData = JSON.parse(JSON.stringify(this.pricingData));
        pricingData.forEach((pricing, index) => {
            if (errorIdSet.has(pricing.Id)) {
                this.validateSequentialGmv(index);
                this.validateTierDiscountLogic(index);
            }
        });

    }

    /**
     * Handles changes in pricing fields.
     * @param {Event} event - The change event from the input field.
     */
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

        //MN-23072025-US-0033150--START
        if (this.isCurrentStep1 && this.isCurrentMode1) {

            //Validate sequential GMV logic for the current record
            this.validateSequentialGmv(idx);

            //Validate the "at least one pair" logic for the current record
            this.validateTierDiscountLogic(idx);

            // Check if there are any errors in the pricing data
            this.findingPricingWithError();
        }
        //MN-23072025-US-0033150--END
        
    }

    /**
     * Finds all pricing records that have an error and updates the errorPricingId property.
     */
    findingPricingWithError() {

        let data = JSON.parse(JSON.stringify(this.pricingData));
        let dataError = data.filter(pricing => pricing.isError === true).map(pricing => pricing.Id);
        this.errorPricingId = dataError;
    }

    /**
     * Implements the "at least one GMV/Discount pair" rule from the Flow formula.
     * Sets custom validity on GMVThreshold0__c input for the record if invalid.
     * @param {number} recordIdx - The index of the pricing record to validate.
     */
    validateTierDiscountLogic(recordIdx) {
        const pricing = this.pricingData[recordIdx];
        let isValidForRecord = false;
        
        // Determine which discount fields to check based on discountType
        const discountFieldsToCheck = [];
        // Important: check if discountType is explicitly 'Flat rate' (case-sensitive)
        if (this.isFVF) {
            for (let i = 0; i <= 5; i++) {
                discountFieldsToCheck.push({ gmv: `GMVThreshold${i}__c`, discount: `Tier${i}FVFdiscount__c` });
            }
        } else { 
            for (let i = 0; i <= 5; i++) {
                discountFieldsToCheck.push({ gmv: `GMVThreshold${i}__c`, discount: `Tier_` + i + `_bps_Discount__c` });
            }
        } 

        // Check if at least one GMV Threshold AND its corresponding Discount field is not null/empty
        for (const fieldPair of discountFieldsToCheck) {
            const gmvValue = pricing[fieldPair.gmv];
            const discountValue = pricing[fieldPair.discount];

            const isGmvValueValidAndFilled = (gmvValue !== null && gmvValue !== '' && gmvValue !== undefined && !Number.isNaN(gmvValue));
            const isDiscountValueValidAndFilled = (discountValue !== null && discountValue !== '' && discountValue !== undefined && !Number.isNaN(discountValue));

            if (isGmvValueValidAndFilled && isDiscountValueValidAndFilled) {
                isValidForRecord = true;
                break; // Found a valid pair, no need to check further for this record
            }
        }
        
        // Apply error messages if the record is not valid for this rule
        let data = JSON.parse(JSON.stringify(this.pricingData));

        data[recordIdx].errorMessage = isValidForRecord ? '' : 'Please provide GMV Threshold and Discounts for at least one Tier to proceed';
        data[recordIdx].hasErrMsg = !isValidForRecord;
        data[recordIdx].isError ||=  !isValidForRecord; 

        this.pricingData = data;
        
    }

    /**
     * Validates sequential GMV Threshold entry (Rule 2).
     * @param {number} recordIdx - The index of the pricing record to validate.
     */
    validateSequentialGmv(recordIdx) {
        
        let isValid = true;
        const pricing = this.pricingData[recordIdx];
        const inputs = Array.from(this.template.querySelectorAll(`[data-id="${recordIdx}"]`));

        for (let tier = 1; tier <= 5; tier++) {
            const prevTier = tier - 1;
            const gmvField = `GMVThreshold${tier}__c`;
            const prevGmvField = `GMVThreshold${prevTier}__c`;

            const currentGmv = pricing[gmvField];
            const previousGmv = pricing[prevGmvField];

            const inputCmp = inputs.find(input => input.dataset.name === prevGmvField);

            // Clear previous custom error for this input first
            if (inputCmp) {
                inputCmp.setCustomValidity('');
                inputCmp.reportValidity(); // Re-report to clear if was invalid
            }

            let isCurrentGmvValueValidAndFilled = (currentGmv !== null && currentGmv !== '' && currentGmv !== undefined && !Number.isNaN(currentGmv));
            let isPrevGmvValueEmpty = (previousGmv == null || previousGmv === '' || previousGmv === undefined || Number.isNaN(previousGmv));
            
            // Rule 2: if GMV Target X have value but GMV Target X-1 blank => show error
            // Check for explicit null or empty string to consider a field "blank"
            if (isCurrentGmvValueValidAndFilled && isPrevGmvValueEmpty) {
                if (inputCmp) {
                    inputCmp.setCustomValidity(`Please input GMV Threshold ${prevTier}.`);
                    inputCmp.reportValidity();
                    isValid = false;
                }
            } else {
                // If current GMV is empty and previous GMV is also empty, we don't need to show an error
                let curInputCmp = inputs.find(input => input.dataset.name === gmvField);
                if (curInputCmp) {
                    curInputCmp.setCustomValidity('');
                    curInputCmp.reportValidity(); // Re-report to clear if was invalid
                } 
            }
            
            let data = JSON.parse(JSON.stringify(this.pricingData));
            data[recordIdx].isError = !isValid;
            

            this.pricingData = data;
        }
        
    }

    // handleSearchCategoryKeyUp function to handle search category key up
    handleSearchCategoryKeyUp(event) {

        if (event.key === 'Enter' && event.target.name === 'search-contract-category') {
            let idx = parseInt(event.target.dataset.parent);
            let index = parseInt(event.target.dataset.id);
            let type = event.target.dataset.type;
            let searchKey = event.target.value.toLowerCase();
            
            if (this.isCurrentMode1) {
                
                this.getContractCategories(index, true, searchKey, type);
            }
            
        }
       
    }
    
    // handleSectionToggle function to handle expand table
    handleSectionToggle(event) {//LA-22-05-2025-US-0026099
        
        let openSections = event.detail.openSections;
        let idx = parseInt(event.target.dataset.parent);
        let index = parseInt(event.target.dataset.id);
        
        if(openSections.length > 0){
            if (this.isCurrentMode1) {
                this.getContractCategories(index, false, '', '');
            }
        }

    }

    // handleIncExcRowSelection function to handle inclusion/exclusion row selection
    handleIncExcRowSelection(event){

        let index = parseInt(event.target.dataset.id);
        let type = event.target.dataset.type;

        let pricingData = JSON.parse(JSON.stringify(this.pricingData));
        let contractCategory2delete = JSON.parse(JSON.stringify(this.contractCategory2delete));
        let contractCategory2create = JSON.parse(JSON.stringify(this.contractCategory2create));

        if(event?.detail?.selectedRows && event.detail.selectedRows.length > 0){
           
            let selectedRows = event.detail.selectedRows.map(row => row.Id); // Newly selected Category Ids

            if (type === 'incl') {

                let concatIndb = pricingData[index].inc_cate_in_db || []; // Existing Contract Category Records in database
                
                // Update the current selected
                pricingData[index].inc_cate_selected = selectedRows;

                // Convert to Sets for easier comparison
                let selectedSet = new Set(selectedRows);
                let dbIdSet = new Set(concatIndb.map(cc => cc.Category__c)); // extract Category__c values

                contractCategory2create = this.clearRecordForPricing(contractCategory2create, pricingData[index].Id, '1'); // clear the list first and if there is any record to create then logic will add after

                // New selections not in DB → need to create
                let toCreate = [...selectedSet].filter(id => !dbIdSet.has(id));
                toCreate.forEach(id => {

                    let newContCate = {
                        Category__c : id,
                        Contract__c : pricingData[index].EBH_ContractId__c,
                        Contratc_Category_Type__c : '1', // Inclusion
                        Contract_Pricing_Matrix__c : pricingData[index].EBH_ContractPricingMatrix__c,
                        ContractPricing__c : pricingData[index].Id,
                        RecordTypeId : this.rtCCPricing
                    };
                    contractCategory2create.push(newContCate);
                });

                
                contractCategory2delete = this.clearRecordForPricing(contractCategory2delete, pricingData[index].Id, '1'); // clear the list first and if there is any record to delete then logic will add after

                // Old DB records not selected anymore → need to delete
                let toDelete = concatIndb.filter(cc => !selectedSet.has(cc.Category__c));
                if (toDelete.length > 0) {
                    contractCategory2delete = contractCategory2delete.concat(toDelete);
                }

                this.contractCategory2create = contractCategory2create;
                this.contractCategory2delete = contractCategory2delete;

                // this.isEmptyInclusionCategory = false;
                pricingData[index].isEmptyInclusionCategory = false;

            }else {

                let concatIndb = pricingData[index].exc_cate_in_db || []; // Existing Contract Category Records in database
                
                // Update the current selected
                pricingData[index].exc_cate_selected = selectedRows;

                // Convert to Sets for easier comparison
                let selectedSet = new Set(selectedRows);
                let dbIdSet = new Set(concatIndb.map(cc => cc.Category__c)); // extract Category__c values

                contractCategory2create = this.clearRecordForPricing(contractCategory2create, pricingData[index].Id, '0'); // clear the list first and if there is any record to create then logic will add after

                // New selections not in DB → need to create
                let toCreate = [...selectedSet].filter(id => !dbIdSet.has(id));
                toCreate.forEach(id => {

                    let newContCate = {
                        Category__c : id,
                        Contract__c : pricingData[index].EBH_ContractId__c,
                        Contratc_Category_Type__c : '0', // Inclusion
                        Contract_Pricing_Matrix__c : pricingData[index].EBH_ContractPricingMatrix__c,
                        ContractPricing__c : pricingData[index].Id,
                        RecordTypeId : this.rtCCPricing
                    };
                    contractCategory2create.push(newContCate);
                });

                
                contractCategory2delete = this.clearRecordForPricing(contractCategory2delete, pricingData[index].Id, '0'); // clear the list first and if there is any record to delete then logic will add after

                // Old DB records not selected anymore → need to delete
                let toDelete = concatIndb.filter(cc => !selectedSet.has(cc.Category__c));
                if (toDelete.length > 0) {
                    contractCategory2delete = contractCategory2delete.concat(toDelete);
                }

                this.contractCategory2create = contractCategory2create;
                this.contractCategory2delete = contractCategory2delete;

                
            }

        }else {

            try {

                if (type === 'incl') {

                    pricingData[index].inc_cate_selected = [];
                    // this.isEmptyInclusionCategory = true;
                    pricingData[index].isEmptyInclusionCategory = true;
                    let selectedSet = new Set();
                    let concatIndb = pricingData[index].inc_cate_in_db || []; // Existing Contract Category Records in database
    
                    contractCategory2create = this.clearRecordForPricing(contractCategory2create, pricingData[index].Id, '1');
    
                    // Old DB records not selected anymore → need to delete
                    let toDelete = concatIndb.filter(cc => !selectedSet.has(cc.Category__c));
                    contractCategory2delete = this.clearRecordForPricing(contractCategory2delete, pricingData[index].Id, '1');
                    if (toDelete.length > 0) {
                        contractCategory2delete = contractCategory2delete.concat(toDelete);
                    }
    
                    this.contractCategory2create = contractCategory2create;
                    this.contractCategory2delete = contractCategory2delete;

                } else {
    
                    pricingData[index].exc_cate_selected = [];
    
                    let selectedSet = new Set();
                    let concatIndb = pricingData[index].exc_cate_in_db || []; // Existing Contract Category Records in database
    
                    contractCategory2create = this.clearRecordForPricing(contractCategory2create, pricingData[index].Id, '0');
    
                    // Old DB records not selected anymore → need to delete
                    let toDelete = concatIndb.filter(cc => !selectedSet.has(cc.Category__c));
                    contractCategory2delete = this.clearRecordForPricing(contractCategory2delete, pricingData[index].Id, '0');
                    if (toDelete.length > 0) {
                        contractCategory2delete = contractCategory2delete.concat(toDelete);
                    }
    
                    this.contractCategory2create = contractCategory2create;
                    this.contractCategory2delete = contractCategory2delete;
                }

            }catch(error) {
                console.error('Error in handleIncExcRowSelection: ', error);
            }

        }

        pricingData[index] = this.mappingSelectedInclExcluToPricing(type, event.detail.selectedRows, pricingData[index]); //Mapping selected categories to pricing data

        // Loop through all pricingData to see if all of pricing has isEmptyInclusionCategory = false then set this.isEmptyInclusionCategory = false, otherwise set to true
        this.isEmptyInclusionCategory = pricingData.some(pricing => pricing.isEmptyInclusionCategory);

        this.pricingData = pricingData;
    }

    // Mapping selected categories to pricing data
    mappingSelectedInclExcluToPricing(type, selectedCategory, pricing) {

        let selectedCateName = '';
        let selectedCateCode = '';

        if (Array.isArray(selectedCategory) && selectedCategory.length > 0) {
            selectedCateName = selectedCategory.map(cate => cate.Name_with_Id__c).join(';');
            selectedCateCode = selectedCategory.map(cate => cate.Category_ID__c).join(';');
        }

        if (type === 'incl') { //Inclusion
            
            pricing.InclusionCategoryName__c = selectedCateName;
            pricing.InclusionCategories__c = selectedCateCode;

        }else if (type === 'excl') { //Exclusion   

            pricing.ExclusionCategoryName__c = selectedCateName;
            pricing.ExclusionCategories__c = selectedCateCode;
        }

        return pricing;
    }

    // Function to clear contract category records for pricing
    // This function filters out contract categories that match the given pricingId and type
    clearRecordForPricing(contCateList, pricingId, type) {

        return [...contCateList].filter(cc => !(cc.ContractPricing__c === pricingId && cc.Contratc_Category_Type__c === type));
    }

    // Function to get contract categories based on pricingId and site
    // This function fetches contract categories from the server
    getContractCategories(index, isSearch, searchKey, type) {

        let pricingData = JSON.parse(JSON.stringify(this.pricingData));
        let defExclCateId = this.DefaultExclusionCategory.map(cate => cate.Id); // Get default exclusion category Ids
        if ((!isSearch && pricingData[index].isInit)) return; // Only fetch if not already initialized

        let loadAllCategory = (!this.allCategoryTree || this.allCategoryTree.length === 0 || isSearch);

        let selectedCats = (!isSearch)?[]:(type === 'incl')?pricingData[index].inc_cate_selected:pricingData[index].exc_cate_selected;

        this.isLoading = true;

        getContractCategoriesApex({ pricingId:pricingData[index].Id, 
                                    site:pricingData[index].EBH_Site__c, 
                                    queryAllCategoryTree:loadAllCategory, 
                                    searchKey:searchKey,
                                    isSearch: isSearch,
                                    cateList: selectedCats,
                                    defExclCate: defExclCateId}).then(result => {
            
            // console.log('**** result :: ', result);
            

            if (loadAllCategory) {
                this.allCategoryTree = result.AllCategories;
                this.rtCCPricing = result.ccPricingRT;
            }

            if (!isSearch) {

                let inclusionCategory = result.ContractCategory.filter(
                    category => category.Contratc_Category_Type__c === '1'
                );
                
                let exclusionCategory = result.ContractCategory.filter(
                    category => category.Contratc_Category_Type__c === '0'
                ); 
                
                pricingData[index].inc_cate_in_db = inclusionCategory;
                pricingData[index].inc_cate_selected = inclusionCategory.map(cate => cate.Category__c);
                pricingData[index].exc_cate_in_db = exclusionCategory;
                pricingData[index].exc_cate_selected = exclusionCategory.map(cate => cate.Category__c);

                pricingData[index].SelectedCategory = result.SelectedCategory;

            }
            
            // Now merge with full category tree and prioritize selected
            if (!isSearch || (isSearch && type === 'incl')) { pricingData[index].allCategoryTreeIncl = this.mergeAndPrioritize(pricingData[index].inc_cate_selected, pricingData[index].SelectedCategory, this.allCategoryTree); }
            if (!isSearch || (isSearch && type === 'excl')) { 
                // let allExclCategoryTree = [...this.allCategoryTree].filter(cat => !defExclCate.includes(cat.Id)); // Filter out default exclusion categories
                let allExclCategoryTree = [...this.allCategoryTree].filter(cat => !this.DefaultExclusionCategory.some(def => def.Id === cat.Id));
                pricingData[index].allCategoryTreeExcl = this.mergeAndPrioritize(pricingData[index].exc_cate_selected, pricingData[index].SelectedCategory, allExclCategoryTree); 
            }

            pricingData[index].isInit = true;

            this.pricingData = pricingData;

            

            


        }).catch(error => {
            console.error('Error:', error);
        }).finally(() => {
            this.isLoading = false;
        });
    }

    // Helper function to merge selected + all and keep unique by Id, with selected on top
    mergeAndPrioritize(selectedId, selectedCategory, fullList) {

        // Create a Map to store unique categories by Id
        let uniqueMap = new Map();
        let setId = new Set(selectedId);

        // First, add selectedCategory items (these will be on top)
        selectedCategory.forEach(cat => {
            if (setId.has(cat.Id)) {
                // Only add if the Id is in the selectedId set
                if (!uniqueMap.has(cat.Id)) {
                    uniqueMap.set(cat.Id, cat);
                }
            }
        });

        setId.forEach(id => {
            // Ensure selectedId items are added first
            if (!uniqueMap.has(id)) {
                let foundCat = fullList.find(cat => cat.Id === id);
                if (foundCat) {
                    uniqueMap.set(id, foundCat);
                }
            }
        });

        // Then, add allCategoryTree items (only if Id not already in the Map)
        fullList.forEach(cat => {
            if (!uniqueMap.has(cat.Id)) {
                uniqueMap.set(cat.Id, cat);
            }
        });

        // Convert back to array — selectedCategory will be on top
        return Array.from(uniqueMap.values());
        
    }
}