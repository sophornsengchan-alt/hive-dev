import { LightningElement,api,track} from 'lwc';
import customLabel from 'c/customLabels';
import LOCALE from "@salesforce/i18n/locale";
import CURRENCY from "@salesforce/i18n/currency";
import LANGUAGE from '@salesforce/i18n/lang';
import { getPreviousMonth,getCurrentMonth,isNullorUndefinedorZero,displayPositiveorNegativeSign,formatLabel } from "c/hiveUtils";



const subCategoryColumn = [
    { label: 'SubCategory*', apiname:'Category_Tree__c'},
    { label: 'share of total Sales', apiname:'Categ_Share_Sales__c'},
    { label: 'Comparison with previous month', apiname:'Categ_Share_Sales_Prev_MOM__c'},
    { label: 'Your total sales', apiname:'Categ_Total_Sales__c'},
    { label: 'Comparison with previous month', apiname:'Categ_Total_sales_Prev_MOM__c'},
    { label: 'Your ranking', apiname:'Categ_Ranking__c'},
    { label: 'Comparison with previous month', apiname:'Categ_Ranking_Prev_Month__c'},
];

export default class ProTraderStorePerformanceCmp extends LightningElement {

    label = customLabel;
    iconName = '';
    month = ["January","February","March","April","May","June","July","August","September","October","November","December"];
    title = this.label.Pro_Trader_View_detailed_report;
    locale = LOCALE;
    currency = CURRENCY;
    language = LANGUAGE;
    isLoading = false;
    subCategoryColumn = subCategoryColumn;
    isCurrencyUSD = false;
    
    @track newsubCategoryColumn = [];
    @track subCategoryData = [];
    _cohortSellerandCategoryPerformanceData = [];
    translatedLabels = {};
    

    /**
     * @description - updates the subcategory column label with previous month
     */
    subcategoryColumnLabelUpdated(){
        this.newsubCategoryColumn = subCategoryColumn.map(obj => {
            if (['share of total Sales'].includes(obj.label)) {
                obj = {...obj, label: this.monthTranslation(getPreviousMonth()) +' '+obj.label ,translatedLabel:formatLabel(this.label.Pro_Trader_share_of_total_Sales,this.monthTranslation(getPreviousMonth()))};
            }
            if (['Your total sales'].includes(obj.label)) {
                obj= {...obj, label: 'Your total '+ this.monthTranslation(getPreviousMonth()) +' sales',translatedLabel:formatLabel(this.label.Protrader_yourTotal_Sales,this.monthTranslation(getPreviousMonth()))};
            }
            if (['Your ranking'].includes(obj.label)) {
                obj= {...obj, label: 'Your '+ this.monthTranslation(getPreviousMonth()) +' ranking', translatedLabel:formatLabel(this.label.Protrader_Your_ranking,this.monthTranslation(getPreviousMonth()))};
            }
            if (['SubCategory*'].includes(obj.label)) {
                obj= {...obj, label: obj.label, translatedLabel: this.label.Pro_Trader_SubCategory};
            }
            if (['Comparison with previous month'].includes(obj.label)) {
                obj= {...obj, label: obj.label, translatedLabel: this.label.Pro_trader_omparison_with_previous_month};
            }

            return obj;
        });
    }

    monthTranslation(monthName){
        const monthMap = new Map();

        monthMap.set(this.month[0], this.label.Pro_Trader_January);
        monthMap.set(this.month[1], this.label.Pro_trader_February);
        monthMap.set(this.month[2], this.label.Pro_trader_March);
        monthMap.set(this.month[3], this.label.Pro_Trader_April);
        monthMap.set(this.month[4], this.label.Pro_trader_May);
        monthMap.set(this.month[5], this.label.Pro_trader_June);
        monthMap.set(this.month[6], this.label.Pro_trader_July);
        monthMap.set(this.month[7], this.label.Pro_trader_August);
        monthMap.set(this.month[8], this.label.Pro_Trader_September);
        monthMap.set(this.month[9], this.label.Pro_Trader_October);
        monthMap.set(this.month[10], this.label.Pro_Trader_November);
        monthMap.set(this.month[11], this.label.Pro_Trader_December);

        return monthMap.get(monthName);
    }

    /**
     * @description - returns the cohort seller and category performance data
     */
    @api
    get cohortSellerandCategoryPerformanceData(){
        return this._cohortSellerandCategoryPerformanceData;
    }

    set cohortSellerandCategoryPerformanceData(value){
        this.isLoading = true;
        this._cohortSellerandCategoryPerformanceData = value;    
        this.formTranslatedLabels();
        if(!isNullorUndefinedorZero(this._cohortSellerandCategoryPerformanceData)){
            this.subcategoryColumnLabelUpdated();

            this.checkNumberandAssignColor(this._cohortSellerandCategoryPerformanceData?.shareofSales,'share-sales-block','text');
            this.checkNumberandAssignColor(this._cohortSellerandCategoryPerformanceData?.totalSalesCohort,'total-sales-block','text');
            this.checkNumberandAssignColor(this._cohortSellerandCategoryPerformanceData?.cohortRanking,'ranking-block','text');
            this.checkNumberandAssignColor(this._cohortSellerandCategoryPerformanceData?.shareofSalesPreviousMonth,'share-sales-prev-month','icon');
            this.checkNumberandAssignColor(this._cohortSellerandCategoryPerformanceData?.shareofSalesPreviousYear,'share-sales-prev-year','icon');
            this.checkNumberandAssignColor(this._cohortSellerandCategoryPerformanceData?.totalSalesPreviousMonth,'total-sales-prev-month','icon');
            this.checkNumberandAssignColor(this._cohortSellerandCategoryPerformanceData?.totalSalesPreviousYear,'total-sales-prev-year','icon');
            this.checkNumberandAssignColor(this._cohortSellerandCategoryPerformanceData?.rankingPreviousMonth,'ranking-prev-month','icon');
            this.checkNumberandAssignColor(this._cohortSellerandCategoryPerformanceData?.rankingPreviousYear,'ranking-prev-year','icon');
                     
            this.formDetailedReportTable(this._cohortSellerandCategoryPerformanceData);
            this.isLoading = false;  
            this.isCurrencyUSD = this._cohortSellerandCategoryPerformanceData.cohortSellerCurrency === 'USD';
        }         
    }

    /**
     * returns the updated cateory info label
     */
    get updateCategoryInfoLabel(){
        return formatLabel(this.label.ProTrader_SubCategory_Info,this.currency.toString(),this._cohortSellerandCategoryPerformanceData?.conversionRate);
    }


    get updatedShareOfSalesLabel(){
        return formatLabel(this.label.Pro_trader_Collectables_as_a_share_of_your_total_eBay_sales,this._cohortSellerandCategoryPerformanceData?.cohortName);
    }

    get updatedTotalSalesLabel(){
        return formatLabel(this.label.Pro_trader_our_total_sales_from_Pro_Trader_Collectables,this._cohortSellerandCategoryPerformanceData?.cohortName);
    }

    get updatedRankingLabel(){
        return formatLabel(this.label.Pro_trader_Your_Pro_Trader_Collectables_ranking,this._cohortSellerandCategoryPerformanceData?.cohortName);
    }

    /**
     * @description - returns the updated category info label
     */
   formTranslatedLabels(){
        this.translatedLabels.shareSalesHelpText = formatLabel(this.label.Pro_trader_share_of_sales_helptext,this._cohortSellerandCategoryPerformanceData?.cohortName,this.monthTranslation(getCurrentMonth()),this.monthTranslation(getCurrentMonth()));
        this.translatedLabels.totalSalesHelpText = formatLabel(this.label.Pro_Trader_Total_sales_helptext, this.language == 'it' 
                                                    ? this.monthTranslation(getCurrentMonth()) 
                                                    : this._cohortSellerandCategoryPerformanceData?.cohortName,
                                                    this.monthTranslation(getCurrentMonth()),this.monthTranslation(getCurrentMonth()));
        this.translatedLabels.totalRankingHelpText = formatLabel(this.label.Pro_trader_Ranking_helptext, this.language == 'it' 
                                                    ? this.monthTranslation(getCurrentMonth()) 
                                                    : this._cohortSellerandCategoryPerformanceData?.cohortName,
                                                    this.monthTranslation(getCurrentMonth()),this.monthTranslation(getCurrentMonth()));                                                      
   }

    /**
     * 
     * @param cohortSellerandCategoryPerfData 
     * description - forms the detailed report table
     */
    formDetailedReportTable(cohortSellerandCategoryPerfData){
        
        let subCategoryData = [];
        cohortSellerandCategoryPerfData?.subCategoryList?.forEach(eachSellerCategory =>{
            let cohortSellerCatergory;
            cohortSellerCatergory = [{subCategoryName:eachSellerCategory.subCategoryName},
                                    {categoryShareSales:eachSellerCategory.categoryShareSales},
                                    {categoryShareSalesPreviousMonth: !isNullorUndefinedorZero(eachSellerCategory.categoryShareSalesPreviousMonth) ? displayPositiveorNegativeSign(eachSellerCategory.categoryShareSalesPreviousMonth) :''},
                                    {categoryTotalSales:eachSellerCategory.categoryTotalSales},
                                    {categoryTotalSalesPreviousMonth: !isNullorUndefinedorZero(eachSellerCategory.categoryTotalSalesPreviousMonth) ? displayPositiveorNegativeSign(eachSellerCategory.categoryTotalSalesPreviousMonth) :''},
                                    {categoryRanking:eachSellerCategory.categoryRanking},
                                    {categoryRankingPreviousMonth: !isNullorUndefinedorZero(eachSellerCategory.categoryRankingPreviousMonth) ? displayPositiveorNegativeSign(eachSellerCategory.categoryRankingPreviousMonth) :''}];

            subCategoryData.push(cohortSellerCatergory.filter(value => JSON.stringify(value) !== '{}'));
        })
        this.subCategoryData = subCategoryData.filter(value => JSON.stringify(value) !== '{}');

        this.isLoading = false;
    }

    /**
     * description - checks if the value and assign color
     * @param value 
     * @param dataId 
     * @param variant 
     */
    checkNumberandAssignColor(value,dataId,variant){ //https://www.avirai.com/post/dynamic-styling-lwc-using-data-attributes .can check to do this way
        setTimeout(() => {
            if(value < 0 && variant === 'text'){
                this.template.querySelector(`[data-name="${dataId}"]`).classList.add('color-red');
            }else if(value < 0 && variant === 'icon'){
                this.template.querySelector(`[data-name="${dataId}"]`).classList.add('red-down-icon');
                this.template.querySelector(`[data-name="${dataId}"]`).iconName = 'utility:down';
            }else if(value > 0 && variant === 'text'){
                this.template.querySelector(`[data-name="${dataId}"]`).classList.add('color-blue');
            }else if(value > 0 && variant === 'icon'){
                this.template.querySelector(`[data-name="${dataId}"]`).classList.add('green-up-icon');
                this.template.querySelector(`[data-name="${dataId}"]`).iconName = 'utility:up';   
            }else if(value == 0 && variant === 'icon'){
                this.template.querySelector(`[data-name="${dataId}"]`).classList.add('zero-box');
                //dataId += '-value';
                //this.template.querySelector(`[data-name="${dataId}"]`).classList.add('slds-m-top_x-small'); 
            } 

            this.isLoading = false;
            //this.formTranslatedLabels();

        }, 1000);
        
    }

    viewDetailReport(){
        let sectionCmp = this.template.querySelector('c-section-cmp');
        if (sectionCmp) {
            sectionCmp.handleSummaryClick();
        }
    }
    
}