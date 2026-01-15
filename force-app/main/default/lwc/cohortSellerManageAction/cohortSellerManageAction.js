/*********************************************************************************************************************************
@ Component:    CohortSellerManageAction
@ Author:       Acmatac Seing
@ Purpose: Direct implementation of cohort seller call initiation process. 
@          Handles action management, seller record validation, and call outcome tracking.
@          Moved cohort seller specific code from initiateCall component.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.08.2025 / Acmatac Seing : Initial cloned.
@               : 18.08.2025 / Acmatac Seing : Moved cohort seller code from initiateCall component.
@               : 18.08.2025 / Acmatac Seing : Removed ContactVerification flow and Genesys interaction components.
*********************************************************************************************************************************/
import { LightningElement, api, wire, track  } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { loadStyle } from "lightning/platformResourceLoader";
import { NavigationMixin } from 'lightning/navigation';
import ModalCustomSize from "@salesforce/resourceUrl/ModalCustomSize";
import COHORT_SELLER_OBJ from '@salesforce/schema/BoB_Seller__c';
import customLabel from 'c/customLabels';
import apexInit from '@salesforce/apex/ManageSellerInitiateCallController.apexInit';
import apexSave from '@salesforce/apex/ManageSellerInitiateCallController.apexSave';
import { showToastMessage } from "c/hiveUtils";

const PKL_VAL_DMC_NOT_CALL_COMMITTED = 'DMC Not Committed';
const PKL_VAL_DMC_NOT_INTERESTED = 'DMC Not Interested';
const FLOW_BOOK_A_CALL_SCREEN = 'Book_A_Call_Screen_Flow';
const STATUS_OK = 'ok';
const STATUS_KO = 'ko';
const FLOW_NAME_STATUS_FINISHED = 'FINISHED';
const FLOW_NAME_STATUS_FINISHED_SCREEN = 'FINISHED_SCREEN';

export default class CohortSellerManageAction extends NavigationMixin(LightningElement){
    
    @api recordId;
    @api showSpinner = false;
    @api isFromRecordInboundCall = false;

    label = customLabel;
    FIELDS = ['BoB_Seller__c.Id'];
    isReady = false;
    useCalendly = false;
    hasPreviousStep = false;
    errorMessage = null;

    // Cohort Seller specific properties
    @track listActions = [];
    @track columnActions = [];
    @track selectedActions = [];
    @track currentAction = {};
    @track currentParentObj = {};
    @track isAccessGenesysPS = false;
    
    cohortSellerObjInfo = {};
    recordInboundCallParentObj = {};
    isInit = false;
    saveBSOnly = true;
    additionalParam = {};
    finishUpdateBeforeCalendly = false;
    actionRecordTypeId = '';
    isAUProfile = false;
    isAUProfileOnly = false;

    // Modal states
    showEditSchedule = false;
    showEditAction = false;
    isMassEdit = false;
    defaultSortDirectionAction = 'asc';
    sortDirectionAction = 'asc';
    sortedByAction = '';

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

    // Getters for UI logic
    get hasErrorMessage(){
        return this.errorMessage ? true : false;
    }

    get parentObjApiName(){
        return this.cohortSellerObjInfo?.data?.apiName || COHORT_SELLER_OBJ.objectApiName;
    }

    get msgActionSelected(){
        const datatable = this.template.querySelector('c-lwc-custom-datatable');
        if(datatable) {
            const selectedRows = datatable.getSelectedRows();
            return this.label.InitiateCall_Action_Selected.replace('{0}', selectedRows.length);
        }
        return '';
    }

    get flowBookACallScreen(){
        return FLOW_BOOK_A_CALL_SCREEN;
    }
    
    get inputVariables(){
        const flowParams = [
            {
                name : "recordId", type : "String", value: this.recordId
            }
        ];
        return flowParams;
    }

    get isNotFromRecordInboundCall(){
        return !this.isFromRecordInboundCall;
    }

    get isNotAUProfileOnly(){
        return !this.isAUProfileOnly;
    }

    get actionModalTitle(){
        return this.isMassEdit ? this.label.InitiateCall_Mass_Update_Action : this.label.InitiateCall_Edit_Action;
    }

    get scheduleNextCallButtonTitle(){
        return this.noRelatedRecord ? this.label.InitiateCall_Schedule_Next_Call : this.label.InitiateCall_Save_Schedule_Next_Call;
    }

    get noRelatedRecord(){
        return this.isInit && this.listActions.length > 0 ? false : true;
    }

    get currentActionId(){
        return this.currentAction?.Id;
    }

    componentInit(){
        this.showSpinner = true;
        apexInit({ recordId: this.recordId})
            .then((result) => {
                if(result.status==STATUS_OK){
                    this.processApexInitResult(result);
                }else if(result.status==STATUS_KO){
                    this.errorMessage = result.error;
                }
            })
            .catch((error) => {
                console.log('error ',error);
                this.errorMessage = 'An error occurred while initializing the component.';
            }).finally(() => {
                this.isReady = true;
                this.showSpinner = false;
            });
    }

    processApexInitResult(result) {
        this.isInit = true;
        
        // Process actions list
        result.listActions = result.listActions.map(record => { 
            record['link_Name'] = '/'+record.Id;
            if(record.OwnerId){
                record['link_OwnerId'] = '/'+record.OwnerId;
                record['OwnerId'] = record.Owner?.Name;
            }
            return record;
        });

        // Process columns
        result.listColNameAction = result.listColNameAction.map(function(column){
            if(column.fieldName == 'link_Name'){
                column.initialWidth = 150;
            }
            if(column.fieldName == 'Action_Outcome__c'){
                column.type = 'customPicklist';
                column.typeAttributes = {
                    options: { fieldName: 'pickListOptions' },
                    value: { fieldName: 'Action_Outcome__c' },
                    disabled: true
                };
            }
            return column
        });
        
        const actionEdit = {type: 'button-icon', initialWidth: 50, typeAttributes:{name: 'edit', iconName: 'utility:edit'}};
        result.listColNameAction.push(actionEdit);  

        this.columnActions = result.listColNameAction;
        this.listActions = result.listActions;
        
        // Set picklist options
        this.listActions.forEach(ele => {
            ele.pickListOptions = result.actionOutComePicklists;
        });

        // Set additional properties
        this.currentParentObj = result?.bobSeller || {};
        this.isAccessGenesysPS = result?.isAccessGenesysPS || false;
        this.isAUProfile = result?.isAUProfile || false;
        this.isAUProfileOnly = result?.isAUProfileOnly || false;
        this.actionRecordTypeId = result?.recordTypeActionId || '';
    }

    /**
     * Name: handleGoPreviousStep
     * Purpose: Handle go to previous step event from child component
     * @param event
    */    
    handleGoPreviousStep(event){
        // Handle previous step logic if needed
        console.log('Go to previous step', event?.detail);
    }

    /**
     * Name: handleSortAction
     * Purpose: sort by click on the column header
     * @param event
    */
    handleSortAction(event) {
        this.showSpinner = true;
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.listActions];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        
        this.sortDirectionAction = sortDirection;
        this.sortedByAction = sortedBy;
        this.listActions = cloneData;
        this.showSpinner = false;
    }

    // Used to sort the column
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    /**
     * Name: handleRowAction
     * Purpose: show populate to edit action record page when user click on single edit or mass edit
     * @param event
    */
    handleRowAction(event) {
        const action = event.detail.action;
        switch (action.name) {
            case 'edit':
                const row = event.detail.row;
                let i = -1;
                this.listActions.forEach((item, index) => {
                    if(item.Id === row.Id) {
                        i = index;
                    }
                });
                this.isMassEdit = false;
                this.currentAction = this.listActions[i];
                this.showEditAction = true;
                break;
        }
    }

    /**
     * Name: handleDone
     * Purpose: action when user click on done button after user populate new values on action edit page
     * @param event
    */
    handleDone(event) {
        if(this.isMassEdit) {
            const datatable = this.template.querySelector('c-lwc-custom-datatable');
            const selectedRows = datatable.getSelectedRows();

            const updatedRows = selectedRows.map(row => this.populateActionFields(row, this.currentAction, false));

            // Now you need to update the data in your datatable
            this.listActions = this.listActions.map(row => 
                updatedRows.find(updatedRow => updatedRow.Id === row.Id) || row
            );

        } else {
            this.listActions = this.listActions.map(item => 
                item.Id === this.currentAction.Id ? this.currentAction : item
            );
        }
        this.saveBSOnly = false;
        this.showEditAction = false;
    }

    /**
     * Name: populateActionFields
     * Purpose: action to populate the action record with new values
     * @param item 
     * @param actionItem
     * @param isToUpdate
     * @return list action record to update
    */
    populateActionFields(item, actionItem, isToUpdate) {
        let actionToUpdate = {};
        if(isToUpdate){
            actionToUpdate.Id = item.Id;
        }else{
            actionToUpdate = item;
        }
        actionToUpdate.Action_Outcome__c = actionItem.Action_Outcome__c;
        actionToUpdate.Status__c = actionItem.Status__c;
        actionToUpdate.Completed_Date__c = actionItem.Completed_Date__c;
        actionToUpdate.Comments__c = actionItem.Comments__c;
        actionToUpdate.Start_Date__c = actionItem.Start_Date__c;
        actionToUpdate.Due_Date__c = actionItem.Due_Date__c;
        actionToUpdate.Seller_facing_Dashboard_message__c = actionItem.Seller_facing_Dashboard_message__c;
        
        if(this.isAUProfile){
            actionToUpdate.LastCallDate__c = actionItem.LastCallDate__c;
            actionToUpdate.SRNumber__c = actionItem.SRNumber__c;
        }
        if(this.isNotAUProfileOnly){
            actionToUpdate.Detailed_Description__c = actionItem.Detailed_Description__c;
        }  
        
        return actionToUpdate;      
    }

    // Modal close handlers
    closeActionModal() {
        this.showEditAction = false;
    }
    
    closeScheduleNextCallModal() {
        this.showEditSchedule = false;
    }

    /**
     * Name: handleScheduleNextCall
     * Purpose: when user click on schedule next call button after they save or populate new value to action record, show the schedule next call page or calendly based on variable useCalendly
     * @param event
    */
    handleScheduleNextCall(event) {
        if(!this.isFromRecordInboundCall){
            this.showEditSchedule = true;
            if(this.useCalendly){
                this.handleSaveExit();
            }
        }
    }

    // Field change handlers
    handleActionFieldChange(event) {
        this.currentAction[event.target.name] = event.target.value;
    }
    
    handleParentObjFieldChange(event) {
        this.currentParentObj[event.target.name] = event.target.value;
    }
    
    handleRecordInboundCallParentObj(event) {
        this.recordInboundCallParentObj[event.target.name] = event.target.value;
    }
    
    handleAdditionAllParamChange(event){
        this.additionalParam[event.target.name] = event.target.value;
    }

    /**
     * Name: handleMassEdit
     * Purpose: when user click MassEdit button, it will show the action edit page for all selected action record
     * @param event
    */
    handleMassEdit(event) {
        const selectedRows = this.template.querySelector('c-lwc-custom-datatable').getSelectedRows();
        if (selectedRows.length > 0) {
            this.isMassEdit = true;
            this.currentAction = {};
            this.showEditAction = true;
        } else {
            showToastMessage(this, {variant: 'warning', title: 'No Selection', message: this.label.InitiateCall_Select_Action_Mass_Editing});
        }
    }

    /**
     * Name: handleSaveExit
     * Purpose: when user click save, update action or parent object like cohort seller or project to database
     * @param event
    */
    handleSaveExit() {
        this.finishUpdateBeforeCalendly = false;
        this.showSpinner = true;

        const listActionsToUpdate = this.listActions.map(action => this.populateActionFields(action, action, true));
    
        let parentObjToUpdate = {
            Id: this.recordId
        };

        parentObjToUpdate.Call_Attempt__c = this.currentParentObj.Call_Attempt__c;

        if(this.isFromRecordInboundCall){
            parentObjToUpdate.Call_Outcome__c = this.recordInboundCallParentObj.Action_Outcome__c == PKL_VAL_DMC_NOT_INTERESTED ? PKL_VAL_DMC_NOT_CALL_COMMITTED : this.recordInboundCallParentObj.Action_Outcome__c;
        }else{
            parentObjToUpdate.Call_Outcome__c = this.currentParentObj.Call_Outcome__c;
        }
        
        if(this.isParentObjCallOutcomeReq(parentObjToUpdate)){
            return;
        }
        
        parentObjToUpdate.BoB__r = this.currentParentObj.BoB__r;
        parentObjToUpdate.Advisor_Comments__c = this.currentParentObj.Advisor_Comments__c;
        
        let addParam = {};
        if(this.isNotAUProfileOnly){
            addParam = this.additionalParam;
        }

        // Call apex to save
        apexSave({
            bs: parentObjToUpdate, 
            listActions: listActionsToUpdate, 
            bsOnly: this.saveBSOnly, 
            isFromSeller: this.isFromRecordInboundCall, 
            addParam: addParam
        })
        .then((result) => {
            this.handleApexSaveResult(result);
        })
        .catch((error) => {
            console.log('save error ',error);
            showToastMessage(this, {variant: 'error', title: 'Update Error', message: 'Error: ' + error.body?.message || error.message});
            this.showSpinner = false;
        });
    }

    /**
     * Name: isParentObjCallOutcomeReq
     * Purpose: make sure cohort seller has Call Outcome before they can save
     * @param parentObjToUpdate
     * @return true if Call Outcome is still required, false otherwise
    */
    isParentObjCallOutcomeReq(parentObjToUpdate){
        if(!parentObjToUpdate.Call_Outcome__c){
            this.showSpinner = false;
            showToastMessage(this, {variant: 'warning', title: 'Require', message: this.label.InitiateCall_Enter_Overall_Call_Outcome});
            this.closeScheduleNextCallModal();
            return true;
        }
        return false;
    }

    /**
     * Name: handleApexSaveResult
     * Purpose: handle the result from apex save method
     * @param result
    */
    handleApexSaveResult(result) {
        if(result){
            if (result.status === STATUS_OK) {
                this.finishUpdateBeforeCalendly = true;
                showToastMessage(this, {variant: 'success', title: 'Update Complete', message: this.label.InitiateCall_Record_Updated});
                if(!this.showEditSchedule){
                    this.backToRecord();
                }
            } else {
                showToastMessage(this, {variant: 'error', title: 'Update Error', message: 'Apex: ' + result.error});
            }
            this.showEditSchedule = false;
        }
        this.showSpinner = false;
    }

    handleSaveExitMainScreen() {
        if(this.noRelatedRecord){
            this.backToRecord();
        }else{
            this.handleSaveExit();
        }
    }
    
    backToRecord() {
        // Use function below instead of NavigationMixin.Navigate because it can refresh record detail page after redirect
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        }).then((url) => {
            window.open(url, '_self');
        });
    }

    handleFlowStatusChange(event){
        if (event?.detail?.status === FLOW_NAME_STATUS_FINISHED || event?.detail?.status === FLOW_NAME_STATUS_FINISHED_SCREEN) {
            this.backToRecord();
        }
    }

}