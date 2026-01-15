/*********************************************************************************************************************************
@ Component:    projectManageActionOutcome
@ Author:       Acmatac Seing
@ Purpose:      Component focused on managing project action outcomes - extracted from initiateCall component
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 18.08.2025 / Acmatac Seing / Created - Extracted project-specific logic from initiateCall component
@ Change history: 29.09.2025 / Vimean Heng / US-0033462 - Genesys - Update Comments from the flow for Projects(RT - EU Onboarding and One off Account Management)
*********************************************************************************************************************************/
import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { loadStyle } from "lightning/platformResourceLoader";
import ModalCustomSize from "@salesforce/resourceUrl/ModalCustomSize";
import customLabel from 'c/customLabels';
import PROJECT_OBJ from '@salesforce/schema/EBH_Project__c';
import apexInit from '@salesforce/apex/ProjectToActionRecordEditorController.apexInit';
import apexSave from '@salesforce/apex/ProjectToActionRecordEditorController.apexSave';
import { showToastMessage } from "c/hiveUtils";

const STATUS_OK = 'ok';
const STATUS_KO = 'ko';

export default class ProjectManageActionOutcome extends NavigationMixin(LightningElement) {

    @api recordId;
    
    @track listActions = [];
    @track columnActions = [];
    @track selectedActions = [];
    @track currentAction = {};
    @track currentParentObj = {};

    label = customLabel;
    showSpinner = false;
    isInit = false;

    // Modal states
    showEditSchedule = false;
    showEditParentObj = false;
    showEditAction = false;
    isMassEdit = false;

    // Sorting
    defaultSortDirectionAction = 'asc';
    sortDirectionAction = 'asc';
    sortedByAction = '';

    connectedCallback() {
        Promise.all([
            loadStyle(this, ModalCustomSize),
        ]).then(() => {
            this.componentInit();
        })
        .catch(error => {
            console.log("error at style: ",error);
        });
    }

    /** 
     * Name: getObjectInfo
     * Purpose: get object detail like label, api name from project object
     * @param PROJECT_OBJ
    */
    @wire(getObjectInfo, { objectApiName: PROJECT_OBJ })
    parentObjInfo;

    /**
     * Name: componentInit
     * Purpose: init method for this component, it calls apex method to get the list of action and parent record
    */
    @api
    componentInit(){
        this.showSpinner = true;
        apexInit({ recordId: this.recordId})
        .then((result) => {
            let payload = {};
            if(result.status == STATUS_OK){
                payload.parentObj = result?.project;
            }
            this.apexInit(result, null, payload);
        })
        .catch((error) => {
            this.apexInit(null, error, null);
            console.log('error ',error);
        });
    }

    /**
     * Name: apexInit
     * Purpose: method is called from parent when parent component has completed its request from apex method
     * @param result
     * @param error
     * @param payload
    */
    @api
    apexInit(result, error, payload){
        this.isInit = true;
        if(result){
            if(result.status==STATUS_OK) {
                
                result.listActions = result.listActions.map(record => { 
                    record['link_Name'] = '/'+record.Id;
                    if(record.OwnerId){
                        record['link_OwnerId'] = '/'+record.OwnerId;
                        record['OwnerId'] = record.Owner?.Name;
                    }
                    return record;
                });

                result.listColNameAction = result.listColNameAction.map(function(column){
                    if(column.fieldName == 'link_Name'){
                        column.initialWidth = 150;
                    }
                    //Move Action Outcome to Custom Picklist because action outcome return API text in data table
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
                //set picklist options to action outcome column
                this.listActions.forEach(ele => {
                    ele.pickListOptions=result.actionOutComePicklists;
                })
                this.currentParentObj = payload?.parentObj;

            }else if(result.status==STATUS_KO)
            {
                this.error = result.error;
                console.log('Error ::: ',result.error);
            }
            this.error = undefined;

        }else if(error){
            console.log('Error ::: componentInit ',error);
            this.message = undefined;
            this.error = error;
        }
        this.showSpinner = false;
    }

    /**
     * Name: msgActionSelected
     * Purpose: message on how many action record is selected in the action list 
    */
    get msgActionSelected(){
        const datatable = this.template.querySelector('c-lwc-custom-datatable');
        const selectedRows = datatable.getSelectedRows();
        return this.label.InitiateCall_Action_Selected.replace('{0}', selectedRows.length);
    }

    /**
     * Name: parentObjApiName
     * Purpose: get api name of parent object
     * @return PROJECT_OBJ.objectApiName
    */
    get parentObjApiName(){
        return PROJECT_OBJ.objectApiName;
    }

    get updateParentObj(){
        return this.parentObjInfo.data?.label ? this.label.InitiateCall_Update_Parent.replace('{0}', this.parentObjInfo.data?.label) : this.label.InitiateCall_Update_Parent;
    }
    
    get saveUpdateParentObj(){
        return this.parentObjInfo.data?.label ? this.label.InitiateCall_Save_Update_Parent.replace('{0}', this.parentObjInfo.data?.label) : this.label.InitiateCall_Save_Update_Parent;
    }

    // Returns the title for the action modal based on whether it is a mass edit or individual edit
    get actionModalTitle(){
        return this.isMassEdit ? this.label.InitiateCall_Mass_Update_Action : this.label.InitiateCall_Edit_Action;
    }

    // Returns the title for the update project button based on whether there is a related record or not
    get updateParentObjButtonTitle(){
        return this.noRelatedRecord ? this.updateParentObj : this.saveUpdateParentObj;
    }

    // Returns the title for the schedule next call button based on whether there is a related record or not
    get scheduleNextCallButtonTitle(){
        return this.noRelatedRecord ? this.label.InitiateCall_Schedule_Next_Call : this.label.InitiateCall_Save_Schedule_Next_Call;
    }

    // Returns true if there are no related records, false otherwise
    get noRelatedRecord(){
        return this.isInit && this.listActions.length > 0 ? false : true;
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
     * Purpose: show popup to edit action record page when user click on single edit
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
        this.showEditAction = false;
    }

    /**
     * Name: populateActionFields
     * Purpose: action to populate the action record with new values for project
     * @param item 
     * @param actionItem
     * @param isToUpdate
     * @return action record to update
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
        
        return actionToUpdate;      
    }

    closeActionModal() {
        this.showEditAction = false;
    }
    closeScheduleNextCallModal() {
        this.showEditSchedule = false;
        this.showEditParentObj = true;
    }
    closeEditParentObjModal() {
        this.showEditParentObj = false;
    }

    /**
     * Name: handleScheduleNextCall
     * Purpose: when user click on schedule next call button after they save or populate new value to action record, show the schedule next call page
     * @param event
    */
    handleScheduleNextCall(event) {
        this.showEditParentObj = false;
        this.showEditSchedule = true;
    }

    handleEditParentObj(event) {
        this.showEditParentObj = true;
    }
    
    handleActionFieldChange(event) {
        this.currentAction[event.target.name] = event.target.value;
    }
    
    handleParentObjFieldChange(event) {
        this.currentParentObj[event.target.name] = event.target.value;
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
     * Purpose: when user click save, update action or parent object (project) to database
     * @param event
    */
    handleSaveExit() {
        this.showSpinner = true;

        const listActionsToUpdate = this.listActions.map(action => this.populateActionFields(action, action, true));
    
        let parentObjToUpdate = {
            Id: this.recordId
        };

        // Project-specific logic
        parentObjToUpdate.Call_Outcome__c = this.currentParentObj.Call_Outcome__c;

        let callAttempt = this.currentParentObj.Call_Attempt__c;
        callAttempt = callAttempt == 0 || callAttempt == null? 1: callAttempt + 1;

        parentObjToUpdate.Comments__c = this.currentParentObj.Comments__c;
        parentObjToUpdate.Call_Attempt__c = callAttempt;
        parentObjToUpdate.EBH_Stage__c =  this.currentParentObj.EBH_Stage__c;

        if (this.showEditSchedule) {
            parentObjToUpdate.Next_Call_Schedule_Date__c = this.currentParentObj.Next_Call_Schedule_Date__c;
            parentObjToUpdate.Next_Call_Time__c = this.currentParentObj.Next_Call_Time__c;
            parentObjToUpdate.Call_Outcome__c = this.label.InitiateCall_Next_Call_Scheduled;
        }

        apexSave({listActions: listActionsToUpdate, project: parentObjToUpdate })
        .then((result) => {
            this.apexSave(result, null);
        })
        .catch((error) => {
            this.apexSave(null, error);
            console.log('error ',error);
        });
    }

    /**
     * Name: apexSave
     * Purpose: after parent component save the record, the parent call this child method to do the next action
     * @param result
     * @param error
    */
    @api
    apexSave(result, error){
        if(result){
            if (result.status === STATUS_OK) {
                showToastMessage(this, {variant: 'success', title: 'Update Complete', message: this.label.InitiateCall_Record_Updated});
                if(!this.showEditSchedule){
                    this.backToRecord();
                }
            } else {
                showToastMessage(this, {variant: 'error', title: 'Update Error', message: 'Apex: ' + result.error});
            }
            this.showEditSchedule = false;
        }else if (error){
            console.log('Error: ', error);
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
}