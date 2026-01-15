/*********************************************************************************************************************************
@ Component:    manageSellerInitiateCallLWC
@ Author:       Sophal Noch
@ Purpose:      09.04.2024 / Sophal Noch / US-0014987 - Convert Initiate Call button screen from Aura to LWC
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09.04.2024 / Sophal Noch / Create Component
@               : 21.10.2024 / Sophal Noch / US-0015818 - LWS - Seller Portal Initiate component
                : 29.07.2025 / Davy Sorn / US-0033116 - Genesys - Pro-Trader Cohort Seller Initiate Call seamless flow
*********************************************************************************************************************************/
import { LightningElement, api, wire  } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { loadStyle } from "lightning/platformResourceLoader";
import { NavigationMixin } from 'lightning/navigation';
import ModalCustomSize from "@salesforce/resourceUrl/ModalCustomSize";
import COHORT_SELLER_OBJ from '@salesforce/schema/BoB_Seller__c';
import customLabel from 'c/customLabels';
import apexInit from '@salesforce/apex/ManageSellerInitiateCallController.apexInit';
import apexSave from '@salesforce/apex/ManageSellerInitiateCallController.apexSave';
import apexSaveBulkEditOnly from '@salesforce/apex/ManageSellerInitiateCallController.apexSaveBulkEditOnly';

import { showToastMessage } from "c/hiveUtils";

const STATUS_OK = 'ok';
const STATUS_KO = 'ko';
const CMP_INITIATE_CALL = 'c-initiate-call';

export default class ManageSellerInitiateCallLWC extends NavigationMixin(LightningElement){
    
    @api recordId;
    @api showSpinner = false;
    @api isFromRecordInboundCall = false;
    label = customLabel;
    FIELDS = ['BoB_Seller__c.Id'];
    step = 0;
    isReady = false;
    useCalendly = true;
    hasPreviousStep = true;
    errorMessage = null;

    cohortSellerObjInfo = {};

    listContact = [];
    columnContacts = [];
    selectedContacts = [];
    sitePrefix;

    connectedCallback() {
        Promise.all([
            loadStyle(this, ModalCustomSize),
        ]).then(() => {
             
        })
        .catch(error => {
            console.log("error at style: ",error);
        });
    }

    /**
     * Name: wiredRecord
     * Purpose: use this method to make sure recordId exist first before render the component
     * @param recordId 
     * @param FIELDS
    */
    @wire(getRecord, { recordId: '$recordId', fields: '$FIELDS'} )
    wiredRecord({ error, data }) 
    {
        
        if(this.isReady){return;}
        if (data) {
            this.componentInit();
        }
       
    }

    /**
     * Name: getObjectInfo
     * Purpose: init method to get all neccessary data like contact list, ... etc
     * @param recordId 
     * @param FIELDS
    */    
    @wire(getObjectInfo, { objectApiName: COHORT_SELLER_OBJ }) 
    cohortSellerObjInfo;

    componentInit(){
        this.showSpinner = true;
        apexInit({ recordId: this.recordId})
            .then((result) => {
                if(result.status==STATUS_OK){
                    this.listContact = result?.listContact;
                    this.columnContacts = result?.listColNameContact;
                    this.sitePrefix = result?.sitePrefix;
                    this.step = 1;
                }else if(result.status==STATUS_KO){
                    this.errorMessage = result.error;
                }
            })
            .catch((error) => {
                console.log('error ',error);
            }).finally(() => {
                this.isReady = true;
                this.showSpinner = false;
            });
    }

    get hasContactList(){
        return this.listContact.length > 0 ? true : false;
    }

    get hasErrorMessage(){
        return this.errorMessage ? true : false;
    }

    /**
     * Name: handleNextStep
     * Purpose: after selected the contact, bring user to next page that is action list page
    */    
    handleNextStep(){
        if(this.selectedContacts.length > 0 || this.isFromRecordInboundCall){ // if the componnet is called from seller, no need for contact selection
            this.step = 2;
        }else{
            // throw error when no contact selected
            showToastMessage(this, {title: 'No Selection', variant: 'warning', message: this.label.InitiateCall_Select_One_Contact});
        }
    }

    backToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
	}

    /**
     * Name: handleGoPreviousStep
     * Purpose: go back to previous step, the contact selection page
     * @param event
    */    
    handleGoPreviousStep(event){
        if(event?.detail){            
            this.step = 1;
        }
    }

    /**
     * Name: handleContactSelected
     * Purpose: get the selected contact from child contact selected component, store it and pass it to another child component
     * @param event
    */    
    handleContactSelected(event){
        this.selectedContacts = [];
        if(event?.detail?.selectedContacts){
            this.selectedContacts = event.detail.selectedContacts;
        }
    }

    get step1(){
        return this.step === 1;
    }
    get step2(){
        return this.step === 2;
    }

    /**
     * Name: handleApexInit
     * Purpose: this event is recieved from child when it is initialized
     *          when recieve the event, call the apex method to get the cohort seller, profile
     *          and pass to the child component
     * @param event
    */    
    handleApexInit(event){

        if(event?.detail?.recordId){
            const childCmp = this.template.querySelector(CMP_INITIATE_CALL);
            apexInit({ recordId: event.detail.recordId})
            .then((result) => {
                let payload = {};
                if(result.status==STATUS_OK){
                    payload = {
                        parentObj : result?.bobSeller,
                        isAUProfile : result?.isAUProfile,
                        isAUProfileOnly : result?.isAUProfileOnly,
                        selectedContacts : this.selectedContacts,
                        recordTypeActionId : result?.recordTypeActionId,
                        isAccessGenesysPS: result?.isAccessGenesysPS
                    }
                }
                childCmp.apexInit(result, null, payload);
            })
            .catch((error) => {
                childCmp.apexInit(null, error, null);
            });
        }
    }

    /**
     * Name: handleApexSave
     * Purpose: this event is recieved from child when it is initialized
     *          when recieve the event, call the apex method to get the cohort seller, profile
     *          and pass to the child component
     * @param event
    */    
    handleApexSave(event){
        if(event?.detail){
            const childCmp = this.template.querySelector(CMP_INITIATE_CALL);
            
            // Always use bulk edit method to prevent call attempt increment for action updates
            // Call attempts should only be incremented during actual phone call logging, not action management
            const saveMethod = apexSaveBulkEditOnly;
            
            saveMethod({bs : event?.detail?.parentObj, listActions: event?.detail?.listActions, bsOnly : event?.detail?.saveBSOnly, isFromSeller : event?.detail?.isFromSeller, listContacts: event?.detail?.selectedContacts, addParam : event?.detail?.addParam})
            .then((result) => {
                childCmp.apexSave(result, null);
            })
            .catch((error) => {
                childCmp.apexSave(null, error);
                console.log('save error ',error);
            });
        }
    }




}