/*********************************************************************************************************************************
@ Component:    ProjectToActionRecordEditorLWC
@ Author:       Acmatac Seing
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 07.02.2024 / Acmatac Seing / US-0014470 - Ability to update project stage from Initiate call flow
                : 09.04.2024 / Sophal Noch / US-0014987 - Convert Initiate Call button screen from Aura to LWC
*********************************************************************************************************************************/
import { LightningElement, api, wire  } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from "lightning/platformResourceLoader";
import ModalCustomSize from "@salesforce/resourceUrl/ModalCustomSize";
import PROJECT_OBJ from '@salesforce/schema/EBH_Project__c';
import apexInit from '@salesforce/apex/ProjectToActionRecordEditorController.apexInit';
import apexSave from '@salesforce/apex/ProjectToActionRecordEditorController.apexSave';

const STATUS_OK = 'ok';
const CMP_INITIATE_CALL = 'c-initiate-call';

export default class ProjectToActionRecordEditorLWC extends NavigationMixin(LightningElement) {

    @api recordId;
    FIELDS = ['EBH_Project__c.Id'];
    isReady = false;
    projectObjInfo = {};

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
     * Purpose: this method to make sure recordId exist first before render the component
     * @param recordId 
     * @param FIELDS
    */
    @wire(getRecord, { recordId: '$recordId', fields: '$FIELDS'} )
    wiredRecord({ error, data }) 
    {
        if(this.isReady){return;}

        if (data) {
            this.isReady = true;
        }
       
    }

    /** 
     * Name: getObjectInfo
     * Purpose: get object detail like label, api name from project object
     * @param PROJECT_OBJ
    */
    @wire(getObjectInfo, { objectApiName: PROJECT_OBJ })
    parentObjInfo;

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
            apexInit({ recordId: event?.detail?.recordId})
            .then((result) => {
                let payload = {};
                if(result.status == STATUS_OK){
                    payload.parentObj = result?.project;
                }
                childCmp.apexInit(result, null, payload);
            })
            .catch((error) => {
                childCmp.apexInit(null, error, null);
                console.log('error ',error);
            });
        }
    }

    /**
     * Name: handleApexSave
     * Purpose: this event is recieved from child when it need to save the data
     *          when recieve the event, call the apex method to save the cohort seller and action record
     *          and pass to the child component
     * @param event
    */
    handleApexSave(event){

        if(event?.detail){
            const childCmp = this.template.querySelector(CMP_INITIATE_CALL);
            apexSave({listActions: event?.detail?.listActions, project: event?.detail?.parentObj })
            .then((result) => {
                childCmp.apexSave(result, null);
            })
            .catch((error) => {
                childCmp.apexSave(null, error);
                console.log('error ',error);
            });
        }
    }
}