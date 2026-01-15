/**
 * Name: seekSurveyModalAds
 * Create: Sovantheany Dim - 09.01.2025 - US-0016501 - ADS - Satisfaction Survey on Bookings
*/
import { LightningElement } from 'lwc';
import getSellerData from '@salesforce/apex/SeekSurveyController.getSellerData';
import customLabels from 'c/customLabels';
import hasCustomPermission from '@salesforce/customPermission/Seek_Access';

export default class SeekSurveyModal extends LightningElement {

    labels = customLabels;
    surveyHost = this.labels.Seek_Survey_Ads_Host_Url;
    isOpen = false;
    hasSeekAccess = hasCustomPermission;
    sellerName = '';
    surveyUrl = '';
    loading = false;
    
    connectedCallback() {
        this.loading = true;
        this.getSellerData();
    }
    
    renderedCallback() {
                
        if(this.isOpen){
            const spinnerContainer = this.template.querySelector('.slds-spinner_container');
            const containerElem = this.template.querySelector('.iframe-container');
            const iframe = document.createElement('iframe');

            // onload() before setting 'src'
            iframe.onload = function() {
                spinnerContainer.classList.add("slds-hide"); // hide 
            };
            iframe.src = this.surveyUrl; // iFrame src; add this URL to CSP
            iframe.width = '100%';
            iframe.height = '100%';
            iframe.setAttribute('frameborder', '0');

            containerElem.appendChild(iframe); // add iFrame to DOM
        }

    }
    
    /**
    * Name: getSellerData
    */
    getSellerData(){
        getSellerData()
        .then(result => {
            this.sellerName = result.sellerName;
        })
        .catch(error => { 
             console.log("ERROR:::", error);
        }); 
    }

    /**
    * Name: generateSurveyUrl
    */
    generateSurveyUrl() {
        //this.getSellerData();
        const params = {
            ctx_sellerName: this.sellerName,
            ctx_pageUrl: window.location.href
        };
        const queryString = Object.keys(params)
            .filter(key => params[key] !== null && params[key] !== '' && params[key] !== undefined)
            .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`)
            .join('&');
        this.surveyUrl = `${this.surveyHost}?${queryString}`;
        console.log('this.surveyUrl ::'+this.surveyUrl );
    }

    openSurvey(){
        this.isOpen = !this.isOpen;
        this.generateSurveyUrl();
    }

    closeSurvey(){
        this.isOpen = false;
    }

}