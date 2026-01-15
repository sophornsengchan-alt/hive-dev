/*********************************************************************************************************************************
@ Class:          GleanAssistant Component
@ Version:        1.0
@ Author:         Sovantheany Dim
@ Purpose:        US-0016843 - Integration of Glean with Seller CRM via Salesforce Chat Component
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 10.04.2025 / Sovantheany Dim / Created the class.
*********************************************************************************************************************************/
import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import fetchGleanAssistantMetadata from '@salesforce/apex/GleanAssistantController.fetchGleanAssistantMetadata';
import { NavigationMixin } from 'lightning/navigation';
import hasPermission from '@salesforce/customPermission/Glean_Assistant_Standard_User';
import customLabels from 'c/customLabels';

export default class GleanAssistant extends NavigationMixin(LightningElement) {
    applicationId;
    @api userToken = ''; // If authentication is needed
    objectApiName;
    pageChangedDone;
    noPermissionMsg = '';
    isHasPermission = false;
    get gleanVFpageUrl(){
        return '/apex/GleanAssistant?applicationID='+this.applicationId;
    }

    labels = customLabels;

    connectedCallback(){
        this.init();
    }

    init(){
        
        if(hasPermission){
            this.isHasPermission = true;
        }else{
            this.isHasPermission  = false;
            this.noPermissionMsg = this.labels.gleanAssistantNoPermissionMsg;
        }
    }
       
    
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {       
        if (currentPageReference) {
            let urlAtt = currentPageReference.attributes;
            let tmpPage = null;
            if (urlAtt && urlAtt.objectApiName) {
                tmpPage = urlAtt.objectApiName;
            }else{
                tmpPage = 'Default';
            } 
            this.objectApiName = tmpPage;          
        }
    }
        
    @wire(fetchGleanAssistantMetadata, { objectAPIName: '$objectApiName'})
    fetchGleanAssistantMetadata({ error, data }) {
        this.pageChangedDone = false;
        if (data) {
            
            this.applicationId = data;
            
            setTimeout(() => {
                this.pageChangedDone = true;
            }, 100);
        } else if (error) {
           
            console.error('error', error);
            this.pageChangedDone = true;
        }
    }
}