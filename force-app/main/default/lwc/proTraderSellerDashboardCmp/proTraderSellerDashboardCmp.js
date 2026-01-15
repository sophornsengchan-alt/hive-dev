import { LightningElement,track,wire ,api} from 'lwc';
import eBayProtraderLogo from '@salesforce/resourceUrl/ebayProtraderLogo';
import fetchCohortSellerandCategoryPerformanceData from '@salesforce/apex/ProTraderSellerDashboardController.getCohortSellerandCategoryPerformanceData';
import { isNullorUndefinedorZero } from "c/hiveUtils";
import customLabel from 'c/customLabels';
import { CurrentPageReference } from 'lightning/navigation';

export default class ProTraderSellerDashboardCmp extends LightningElement {

    eBayProtraderLogo = eBayProtraderLogo;
    cohortSellerandCategoryPerformanceData = [];
    isDataLoaded = false;
    isLoading = false;
    noDataAvaialble = false;
    label = customLabel;
    cohortSellerId = null;
    currentPageReference;
    isRegistrationPage = false;
    paddingInternalPage = '';
    

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) {
        this.currentPageReference = currentPageReference;
        this.isLoading = true;
        this.cohortSellerId = currentPageReference.state?.c__cohSelId;
        this.paddingInternalPage = (currentPageReference?.attributes?.apiName == 'Seller_Performance_Dashboard') ? 'page-padding' : 'page-padding-portal';
        this.fetchCohortSellerandCategoryPerformanceData();
       }
    }

    /**
     * @description - fetches the cohort seller and category performance data
     */
    fetchCohortSellerandCategoryPerformanceData(){
         //  0017A000010x8GpQAI sellerId : '0017A000011CveMQAS'
         console.log('this.cohortSellerId='+this.cohortSellerId)
        fetchCohortSellerandCategoryPerformanceData({cohortSellerId:this.cohortSellerId})
        .then(result => {
            console.log(">>>>resultxxx "+JSON.stringify(result)+'--len---'+result.cohortName)
                if(isNullorUndefinedorZero(result.cohortName)){
                    this.isDataLoaded = false;
                    this.isLoading = false;
                    this.noDataAvaialble = true;
                    return;
                }
                if(result){
                    this.cohortSellerandCategoryPerformanceData = result;
                    this.error = undefined;
                    this.isDataLoaded = true;
                    this.isLoading = false;                  
                }
            })
            .catch(error => { 
                this.error = error;
                this.isLoading = false;
                this.isDataLoaded = false;
                console.log("Error while fetching seller data:", error);
            }); 
    }
}