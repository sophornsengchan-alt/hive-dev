import { LightningElement,api,track,wire } from 'lwc';
import ProtraderSalesEventCalendar from '@salesforce/resourceUrl/ProtraderSalesEventCalendar';
import customLabel from 'c/customLabels';
import { getPreviousMonth,getCurrentMonth,isNullorUndefinedorZero,displayPositiveorNegativeSign,formatLabel } from "c/hiveUtils";
import getObjectsHelpTexts from '@salesforce/apex/ProTraderSellerDashboardController.getObjectsHelpTexts';
import LANGUAGE from '@salesforce/i18n/lang';

export default class ProTraderBenchMarkCmp extends LightningElement {
    
    prodValue = '';
    benchMarkButtonName = 'Retail';
    protraderSalesEventCalendar = ProtraderSalesEventCalendar;
    options ;
    isLoading = false;

    @track fieldsInfo;
    @track progressBarList=[];
    _cohortSellerandCategoryPerformanceData = [];
    sellerBenchMarkData = [];
    updatedprogressBarDataList = [];
    label = customLabel;
    language = LANGUAGE;
    
    /**
     * @description - returns the cohort seller and category performance data
     */
    @api
    get cohortSellerandCategoryPerformanceData(){
        return this._cohortSellerandCategoryPerformanceData;
    }

    set cohortSellerandCategoryPerformanceData(value){
        this._cohortSellerandCategoryPerformanceData = value;
        if(!isNullorUndefinedorZero(this._cohortSellerandCategoryPerformanceData?.subCategoryList)){
            this.formDetailedReportTable(this._cohortSellerandCategoryPerformanceData);
            this.formProgressBarBenchMarkData(this._cohortSellerandCategoryPerformanceData);
        }
        
    }

    /**
     * 
     * @param {*} cohortSellerandCategoryPerfData 
     * @description - forms the detailed report table
     */
    formDetailedReportTable(cohortSellerandCategoryPerfData) {
        let prodOptions = [];
        let sellerBenchMarkData = [];
        cohortSellerandCategoryPerfData?.subCategoryList?.forEach(eachSellerCategory => {
            let cohortSellerBenchMarkData;
            prodOptions.push({ label: eachSellerCategory.subCategoryName, value: eachSellerCategory.subCategoryName });
            
            cohortSellerBenchMarkData = [
                { subCategoryName: eachSellerCategory.subCategoryName },
                { itemsSepcificYourListingCount: eachSellerCategory.itemsSepcificYourListingCount,itemSpecificEbayAverageCount: eachSellerCategory.itemSpecificEbayAverageCount },
                { photosYourListingCount: eachSellerCategory.photosYourListingCount , photosEbaysAverageCount: eachSellerCategory.photosEbaysAverageCount },
                { titleLengthYourListingCount: eachSellerCategory.titleLengthYourListingCount ,titleLengthEbaysAverageCount: eachSellerCategory.titleLengthEbaysAverageCount },
                { sponsoredListingYourCategoryCoverageCount: eachSellerCategory.sponsoredListingYourCategoryCoverageCount, sponsoredListingEbayCategoryCoverageCount: eachSellerCategory.sponsoredListingEbayCategoryCoverageCount }            
            ];
    
            sellerBenchMarkData.push(cohortSellerBenchMarkData?.filter(value => JSON.stringify(value) !== '{}'));
        });
    
        this.options = prodOptions?.filter(value => JSON.stringify(value) !== '{}');
        this.sellerBenchMarkData = sellerBenchMarkData?.filter(value => value.length > 0);

        /*this.sellerBenchMarkData = sellerBenchMarkData.map(subCategory => {
            let combinedSubCategory = {};
            subCategory.forEach(property => {
              Object.assign(combinedSubCategory, property);
            });
            return combinedSubCategory;
          });*/
          
    }

    /**
     * 
     * @param {*} cohortSellerandCategoryPerfData 
     * description - forms the progress bar data
     */
    formProgressBarBenchMarkData(cohortSellerandCategoryPerfData){
        
        let progressBarDataList = [];

        cohortSellerandCategoryPerfData?.subCategoryList?.forEach(eachSellerCategory => {
            let progressBarData;
            progressBarData = [
                                { subCategoryName: eachSellerCategory.subCategoryName,
                                clickAndCollectCount: !isNullorUndefinedorZero(eachSellerCategory.clickAndCollectCount) ? eachSellerCategory.clickAndCollectCount+'%':'0%',
                                fastAndFreeCount:!isNullorUndefinedorZero(eachSellerCategory.fastAndFreeCount) ? eachSellerCategory.fastAndFreeCount+'%':'0%',
                                multiBuyCount: !isNullorUndefinedorZero(eachSellerCategory.multiBuyCount) ? eachSellerCategory.multiBuyCount+'%':'0%',
                                nextDayDeliveryCount: !isNullorUndefinedorZero(eachSellerCategory.nextDayDeliveryCount) ? eachSellerCategory.nextDayDeliveryCount+'%':'0%',
                                orderDiscountCount: !isNullorUndefinedorZero(eachSellerCategory.orderDiscountCount) ? eachSellerCategory.orderDiscountCount+'%':'0%',
                                returnOfThirtyDaysCount: !isNullorUndefinedorZero(eachSellerCategory.returnOfThirtyDaysCount) ? eachSellerCategory.returnOfThirtyDaysCount+'%':'0%',
                                salesEvent: eachSellerCategory.salesEvent }
                            ];
    
            progressBarDataList.push(progressBarData.filter(value => JSON.stringify(value) !== '{}'));
        });
        this.prodValue = this.options[0]?.value;
        this.updatedprogressBarDataList = progressBarDataList?.filter(value => value.length > 0);
        console.log('progressBarDataList='+JSON.stringify(this.updatedprogressBarDataList)+this.prodValue)
        //by default 1st category value to be shown
        this.fetchObjectHelpTexts('Bob_Seller_Category__c');
    }

    /**
     * 
     * @param {*} updatedprogressBarDataList 
     * @param {*} prodValue 
     * @param {*} buttonName 
     * description - forms the filtered progress bar data
     */
    findFilteredProgressData(updatedprogressBarDataList,prodValue,buttonName){
        this.progressBarList = [];
        let filteredCohortProgressData = [];
        updatedprogressBarDataList?.forEach(eachData => {
            let filteredTaskList = eachData.filter((obj) => obj.subCategoryName == prodValue);
            filteredCohortProgressData.push(filteredTaskList);
        });

        let updatedFilteredCohortProgressData = filteredCohortProgressData?.filter(value => value.length > 0);
        console.log('filteredCohortProgressData='+JSON.stringify(updatedFilteredCohortProgressData))
        updatedFilteredCohortProgressData?.forEach(eachRowData => {
            eachRowData?.forEach(eachData => {
                console.log('eachData='+JSON.stringify(eachData))
                if(buttonName == 'Retail'){
                    this.progressBarList.push({label: this.label.pro_trader_Fast_and_Free,valuePercentage:'width:'+eachData.fastAndFreeCount,
                                                value:eachData.fastAndFreeCount,showProgressBar:true,helpText: this.language == 'en' 
                                                ? this.fieldsInfo.Fast_Free_Ship__c
                                                :formatLabel(this.fieldsInfo.Fast_Free_Ship__c,this.prodValue)},
                                                {label: this.label.Pro_trader_Click_and_collect,valuePercentage:'width:'+eachData.clickAndCollectCount,
                                                value:eachData.clickAndCollectCount,showProgressBar:true,
                                                helpText: this.language == 'en' 
                                                ? this.fieldsInfo.Click_Collect__c
                                                :formatLabel(this.fieldsInfo.Click_Collect__c,this.prodValue)},
                                                {label: this.label.Por_trader_return_30days,valuePercentage:'width:'+eachData.returnOfThirtyDaysCount,
                                                value:eachData.returnOfThirtyDaysCount,showProgressBar:true,
                                                helpText: this.language == 'en' 
                                                ? this.fieldsInfo.Returns_30days_Or_Longer__c
                                                :formatLabel(this.fieldsInfo.Returns_30days_Or_Longer__c,this.prodValue)},
                                                {label: this.label.Pro_trader_Next_day_delivery,valuePercentage:'width:'+eachData.nextDayDeliveryCount,
                                                value:eachData.nextDayDeliveryCount,showProgressBar:true,
                                                helpText: this.language == 'en' 
                                                ? this.fieldsInfo.Nextday_Delivery__c
                                                :formatLabel(this.fieldsInfo.Nextday_Delivery__c,this.prodValue)});
                }else if(buttonName == 'Promotions'){
                    this.progressBarList.push({label: this.label.Pro_trader_Multi_Buy,valuePercentage:'width:'+eachData.multiBuyCount,
                                                value:eachData.multiBuyCount,showProgressBar:true,helpText:this.fieldsInfo.MultiBuy__c},
                                                {label: this.label.Pro_Trader_Order_discount,valuePercentage:'width:'+eachData.orderDiscountCount,
                                                value:eachData.orderDiscountCount,showProgressBar:true,helpText:this.fieldsInfo.Order_Discount__c},
                                                {label: this.label.Pro_trader_Sale_event,value:eachData.salesEvent,showProgressBar:false,
                                                helpText:this.fieldsInfo.Sale_Event__c}); 
                }
            });
        });    
        this.isLoading = false;
    }

    /**
     * description - show if retail or promotions tab is selected
     */
    get showProgressBar(){
        return this.benchMarkButtonName == 'Retail' || this.benchMarkButtonName == 'Promotions';
    }

    /**
     * 
     * @param {*} event 
     * description - handles the picklist change
     */
    handlePicklistChange(event){
        this.prodValue = event.detail.value;
        this.isLoading = true;
        this.findFilteredProgressData(this.updatedprogressBarDataList, this.prodValue,this.benchMarkButtonName);
    }

    /**
     * description - handles the tab change
     * @param {*} event 
     */
    handleTabChange(event){
        this.isLoading = true;
        this.progressBarList = [];
        this.benchMarkButtonName = event.target.dataset.name;
        this.findFilteredProgressData(this.updatedprogressBarDataList, this.prodValue,this.benchMarkButtonName);
       
        if(this.benchMarkButtonName == 'Retail'){
            this.template.querySelector(`[data-name="RetailLi"]`).classList.add('active-li');
            this.template.querySelector(`[data-name="RetailLi"]`).classList.remove('inactive-li');
            this.template.querySelector(`[data-name="PromotionsLi"]`).classList.remove('active-li');
            this.template.querySelector(`[data-name="PromotionsLi"]`).classList.add('inactive-li');
            this.template.querySelector(`[data-name="HealthLi"]`).classList.add('inactive-li');
            this.template.querySelector(`[data-name="HealthLi"]`).classList.remove('active-li');

        }else if(this.benchMarkButtonName == 'Promotions'){
            this.template.querySelector(`[data-name="RetailLi"]`).classList.add('inactive-li');
            this.template.querySelector(`[data-name="RetailLi"]`).classList.remove('active-li');
            this.template.querySelector(`[data-name="PromotionsLi"]`).classList.add('active-li');
            this.template.querySelector(`[data-name="PromotionsLi"]`).classList.remove('inactive-li');
            this.template.querySelector(`[data-name="HealthLi"]`).classList.add('inactive-li');
            this.template.querySelector(`[data-name="HealthLi"]`).classList.remove('active-li');
            

        }else if(this.benchMarkButtonName == 'Health'){
            this.template.querySelector(`[data-name="RetailLi"]`).classList.add('inactive-li');
            this.template.querySelector(`[data-name="RetailLi"]`).classList.remove('active-li');
            this.template.querySelector(`[data-name="PromotionsLi"]`).classList.remove('active-li');
            this.template.querySelector(`[data-name="PromotionsLi"]`).classList.add('inactive-li');
            this.template.querySelector(`[data-name="HealthLi"]`).classList.remove('inactive-li');
            this.template.querySelector(`[data-name="HealthLi"]`).classList.add('active-li');

        }
        this.isLoading = false;
    }   

    /**
     * description - fetches the object help texts
     */
    fetchObjectHelpTexts(objectName){
        this.isLoading = true;
        getObjectsHelpTexts({ objectName: objectName })
       .then(result => {
           console.log('fieldinfo==='+JSON.stringify(result));
           if (result){
            this.fieldsInfo = result;
            this.findFilteredProgressData(this.updatedprogressBarDataList, this.prodValue,this.benchMarkButtonName);
           }
           this.isLoading = false;
        })
        .catch(error => { 
            this.error = error;
            this.isLoading = false;
            console.log("Error while fetching seller data:", error);
        }); 
   }

   get isItalianLanguage(){
    return this.language == 'it' ;
   }
}