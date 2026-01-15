/*********************************************************************************************************************************
@ Component:    CreateProject
@ Author:       Sovantheany Dim
@ Purpose:      03.09.2024 / Sovantheany Dim / US-0015820 - Create Project Quick Action button
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 03.09.2024 / Sovantheany Dim / Create Component
@ Change history: 19.09.2024 / Vimean Heng / createProject method : US-0015879 - move from lwc function to apex
*********************************************************************************************************************************/

import { LightningElement, api, wire  } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { createRecord,updateRecord } from 'lightning/uiRecordApi';
import { loadStyle } from "lightning/platformResourceLoader";
import ModalCustomSize from "@salesforce/resourceUrl/ModalCustomSize";
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import customLabel from 'c/customLabels';
import { showToastMessage } from "c/hiveUtils";
import apexInit from '@salesforce/apex/CreateProjectController.apexInit';
import createProject from '@salesforce/apex/CreateProjectController.createProject';

const STATUS_OK = 'ok';
const STATUS_KO = 'ko';

export default class CreateProject extends NavigationMixin(LightningElement) {
    @api recordId;
    showSpinner = false;
    FIELDS = ['Account.Id','Account.EBH_RevRollup__c','Account.Name','Account.EBH_MainVertical__c'];
    label = customLabel;
    isReady = false;
    listContact = [];
    columnContacts = [];
    selectedContacts = [];
    sitePrefix;
    step = 0;
    revRollup;
    accName;
    mainVertical;
    projectRecordTypeID;
    projectId;
    stagetoUpdate;
    blockMessage = {showMessage:false,type:"",msg:"",msgDetail:""};  
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
            this.revRollup =  data.fields["EBH_RevRollup__c"].value;
            this.accName = data.fields["Name"].value;
            this.mainVertical = data.fields["EBH_MainVertical__c"].value;
            this.componentInit();
        }
       
    }

    componentInit(){
        this.showSpinner = true;
        apexInit({ recordId: this.recordId})
            .then((result) => {
                if(result.status==STATUS_OK){
                    if(result?.listProject.length > 0){//Updated project 
                        this.projectId = result?.listProject[0]?.Id;
                        this.stagetoUpdate = result?.stagetoUpdate;
                        if(this.stagetoUpdate){
                            this.updateProject();
                        }else{
                            this.redirectToProject();
                        }
                    }else{//Create new Project
                        this.listContact = result?.listContact;
                        this.columnContacts = result?.listColNameContact;
                        this.sitePrefix = result?.sitePrefix;
                        this.projectRecordTypeID = result?.oneOffRecordTypeID;
                        this.step = 1;
                    }
                }else if(result.status==STATUS_KO){
                    this.showHideMessage(true,"error",result.error,result.error);//error warning success 
                }
            })
            .catch((error) => {
                console.log('error ',error);
            })
            .finally(() => {
                this.isReady = true;
                this.showSpinner = false;
            });
    }
    get hasContactList(){
        return this.listContact.length > 0 ? true : false;
    }
    get step1(){
        return this.step === 1;
    }

    backToRecord() {
        this.dispatchEvent(new CloseActionScreenEvent()); 
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
    /**
     * Name: create project
     * Purpose: after selected the contact, when user click button Create, then create New Project
    */    
    createProject(){
        this.showSpinner = true;
        if(this.selectedContacts.length > 0 ){
            const fields = {};
            fields['RecordTypeId'] = this.projectRecordTypeID;
            fields['EBH_Seller__c'] = this.recordId;
            fields['EBH_Contact__c'] = this.selectedContacts[0].Id;
            fields['Project_Type__c'] = this.label.One_Off_Account_Management;
            fields['EBH_Stage__c'] = this.label.Initial_Project_Stage;
            fields['Site__c'] = this.revRollup;
            fields['Name'] = this.label.One_Off_Account_Management + ' - ' + this.accName;
            fields['Vertical__c'] = this.mainVertical;

            //const recordInput = { apiName: 'EBH_Project__c', fields};
            createProject({project:fields})
            .then((record) => {
                this.showSpinner = false;
                if(record.status=='ok'){
                    showToastMessage(this, {title: 'Success', variant: 'success', message: 'Project created'});
                    this.projectId = record.id;
                    this.redirectToProject();
                }else{
                    this.showHideMessage(true,"error",record.error,record.errorDetail);//error warning success 
                }
            })
            .catch(error => {
                var msError = ''; 
                if (Array.isArray(error.body)) {
                    msError = error.body.map((e) => e.message).join(", ");
                } else if (typeof error.message === "string") {
                    msError = error.message;
                } else if (typeof error.body.message === "string") {
                    msError = error.body.message;
                }
                this.showHideMessage(true,"error",msError,msError);//error warning success 
                this.showSpinner = false;
            });

        }else{
            // throw error when no contact selected
            showToastMessage(this, {title: 'No Selection', variant: 'warning', message: this.label.InitiateCall_Select_One_Contact});
            this.showSpinner = false;
        }
    }

    updateProject(){
        this.showSpinner = true;
        const fields = {};
        fields['Id'] = this.projectId;
        fields['EBH_Stage__c'] = this.stagetoUpdate;
        const recordInput = {fields};
        updateRecord(recordInput)
            .then(record => {
                showToastMessage(this, {title: 'Success', variant: 'success', message: 'Project stage was updated to '+this.stagetoUpdate+'.'});
                this.showSpinner = false;
                this.redirectToProject();
            })
            .catch(error => {
                console.log('error ',error);
                var msError = '';
                var msErrorDetail = '';
                if (Array.isArray(error.body)) {
                    msError = error.body.map((e) => e.message).join(", ");
                    msErrorDetail = msError;
                } else if (typeof error.body.message === "string") {
                    msError = error.body.message;
                    if(error.body.output != null && error.body.output.fieldErrors != null){
                        msErrorDetail = JSON.stringify(error.body.output.fieldErrors);
                    }
                }
                this.showHideMessage(true,"error",msError,msErrorDetail);//error warning success 
                this.showSpinner = false;
            });

    }

    redirectToProject() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.projectId,
                objectApiName: 'EBH_Project__c',
                actionName: 'view'
            }
        });  
    }
    showHideMessage(state,type,msg,detail,timeOut)
    {
        this.blockMessage.showMessage = state;
        this.blockMessage.type =  type
        this.blockMessage.msg = msg;
        this.blockMessage.msgDetail = detail;
        
        this.showMsg = state;

        let msgBlock = this.template.querySelector('c-lwc-message');
        
        if(msgBlock)
        {
            msgBlock.setMessage(this.blockMessage,state,timeOut);
        }
    }
}