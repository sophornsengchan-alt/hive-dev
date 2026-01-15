/**
 * Name: seekSurveyModal
 * Change: Sambath Seng - 18.04.2024 - US-0015110 Create a new LWC component to display the survey modal
 *       : Sambath Seng - 14.05.2024 - US-0015111 - User Feedback Survey for US, AU, UK (Launch)
*/
import { LightningElement } from 'lwc';
import getSellerData from '@salesforce/apex/SeekSurveyController.getSellerData';
import customLabels from 'c/customLabels';
import hasCustomPermission from '@salesforce/customPermission/Seek_Access';

export default class SeekSurveyModal extends LightningElement {

    labels = customLabels;
    surveyHost = this.labels.Seek_Survey_Host_Url;
    isOpen = false;
    hasSeekAccess = hasCustomPermission;
    sellerName = '';
    surveyUrl = '';
    loading = false;
    
    connectedCallback() {
        this.loading = true;
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
    * Purpose: US-0015110 get seller name from current user
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
    * Purpose: US-0015110 generate survey url with survey host from custom label and seller name
    */
    generateSurveyUrl() {
        this.getSellerData();
        const params = {
            ctx_sellerName: this.sellerName,
            ctx_pageUrl: window.location.href
        };
        const queryString = Object.keys(params)
            .filter(key => params[key] !== null && params[key] !== '' && params[key] !== undefined)
            .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`)
            .join('&');
        this.surveyUrl = `${this.surveyHost}?${queryString}`;
    }

    openSurvey(){
        this.isOpen = !this.isOpen;
        this.generateSurveyUrl();
    }

    closeSurvey(){
        this.isOpen = false;
    }

}