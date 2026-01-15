/*********************************************************************************************************************************
@ Component:    InitiateCall
@ Author:       Sophal Noch
@ Purpose:      09.04.2024 / Sophal Noch / US-0014987 - Convert Initiate Call button screen from Aura to LWC
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09.04.2024 / Sophal Noch / Create Component
@               : 21.10.2024 / Sophal Noch / US-0015818 - LWS - Seller Portal Initiate component
@               : 05.11.2024 / Sovantheany Dim / US-0016104: Initiate call does not allow to track DMC not committed
                : 29.07.2025 / Davy Sorn / US-0033116 - Genesys - Pro-Trader Cohort Seller Initiate Call seamless flow
*********************************************************************************************************************************/
import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import customLabel from 'c/customLabels';
import PROJECT_OBJ from '@salesforce/schema/EBH_Project__c';
import COHORT_SELLER_OBJ from '@salesforce/schema/BoB_Seller__c';
import { showToastMessage } from "c/hiveUtils";

const PKL_VAL_DMC_NOT_CALL_COMMITTED = 'DMC Not Committed';
const PKL_VAL_DMC_NOT_INTERESTED = 'DMC Not Interested';

const FLOW_BOOK_A_CALL_SCREEN = 'Book_A_Call_Screen_Flow';

const STATUS_OK = 'ok';
const STATUS_KO = 'ko';
const FLOW_NAME_STATUS_FINISHED = 'FINISHED';
const FLOW_NAME_STATUS_FINISHED_SCREEN = 'FINISHED_SCREEN';

export default class InitiateCall extends  NavigationMixin(LightningElement) {

    @api recordId;
    @api parentObjInfo = {};
    @api useCalendly = false
    @api listActionField = [];
    @api selectedContacts = [];
    @api hasPreviousStep = false;
    @api isFromRecordInboundCall = false;

    @track listActions = [];
    @track columnActions = [];
    @track selectedActions = [];
    @track currentAction = {};
    @track mapResult = {};
    @track currentParentObj = {};

    label = customLabel;
    recordInboundCallParentObj  = {};
    showSpinner = false;
    isInit = false
    saveBSOnly = true;
    additionalParam = {}
    finishUpdateBeforeCalendly = false;
    actionRecordTypeId = ''; // must not set it to null, it will cause error when update picklist value like status, so keep it as empty string

    showEditSchedule = false;
    showEditParentObj = false;
    showMassEdit = false;
    isMassEdit = false;
    showEditAction = false;
    defaultSortDirectionAction = 'asc';
    sortDirectionAction = 'asc';
    sortedByAction = '';

    connectedCallback() {
        this.componentInit();
    }

    /**
     * Name: msgActionSelected
     * Purpose: message on how many action record is selected in the action list 
    */
    get msgActionSelected(){
        //TH:US-0016104: replace lightning-datatable with custom datatable
        //const datatable = this.template.querySelector('lightning-datatable');
        const datatable = this.template.querySelector('c-lwc-custom-datatable');
        const selectedRows = datatable.getSelectedRows();
        return this.label.InitiateCall_Action_Selected.replace('{0}', selectedRows.length);
    }

    get flowBookACallScreen(){
        return FLOW_BOOK_A_CALL_SCREEN;
    }
    
    /**
     * Name: inputVariables
     * Purpose: to input variable to the flow so the flow can pre-select the contact
     * @return mapping of record Id and contact Id
    */
    get inputVariables(){
        let contactId;
        if(this.selectedContacts.length > 0){
            contactId = this.selectedContacts[0].Id;
        }
        const flowParams = [
            {
                name : "recordId", type : "String", value: this.recordId
            },
			{
                name : "selectedContactID", type : "String", value: contactId
            }
        ];
        return flowParams;
    }

    get isNotFromRecordInboundCall(){
        return !this.isFromRecordInboundCall;
    }

    get notUsingCalendly(){
        return !this.useCalendly;
    }

    get isNotAUProfileOnly(){
        return !this.isAUProfileOnly;
    }

    /**
     * Name: parentObjApiName
     * Purpose: get api name of parent object like BoB_Seller__c or EBH_Project__c
     * @return mapping of record Id and contact Id
    */
    get parentObjApiName(){
        return (this.parentObjInfo.data?.apiName) ? this.parentObjInfo.data.apiName : '';
    }

    get isProject(){
        return this.parentObjApiName == PROJECT_OBJ.objectApiName;
    }
    get isCohortSeller(){
        return this.parentObjApiName == COHORT_SELLER_OBJ.objectApiName;
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
     * Name: componentInit
     * Purpose: init method for this component, it send event to parent component to call apex method to get the list of action and parent record
    */
    componentInit(){
        this.showSpinner = true;
        const payload = new CustomEvent('initiatecallapexinit', {
            detail: {recordId : this.recordId}
        });
        this.dispatchEvent(payload);
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
                     //TH:US-0016104: Move Action Outcome to  Custom Picklist beause action outcome return API text in data table
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
                //TH:US-0016104: set picklist options to action outcome column
                this.listActions.forEach(ele => {
                    ele.pickListOptions=result.actionOutComePicklists;
                })
                this.currentParentObj = payload?.parentObj;
                if(this.isCohortSeller){
                    this.apexCohortSellerInit(payload);
                }

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
     * Name: apexCohortSellerInit
     * Purpose: populate some properties when this child component is used by cohort seller
     * @param payload
    */
    apexCohortSellerInit(payload){

        if(payload?.isAUProfile){
            this.isAUProfile = payload.isAUProfile;
        }
        if(payload?.isAUProfileOnly){
            this.isAUProfileOnly = payload.isAUProfileOnly;
        }
        if(payload?.selectedContacts){
            this.selectedContacts = payload.selectedContacts;
        }
        if(payload?.recordTypeActionId){ 
            // must not set it to null, it will cause error when update picklist value like status, 
            // so keep it as empty string if there is no recordtypeid return from parent component
            this.actionRecordTypeId = payload.recordTypeActionId; 
        }
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
            //TH:US-0016104: replace lightning-datatable with custom datatable
            //const datatable = this.template.querySelector('lightning-datatable');
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
        //TH:US-0016104: Comment Out
        //actionToUpdate.Action_Outcome__c = this.getCohortSellerCallOutcomeVal(actionToUpdate.Action_Outcome__c);
        actionToUpdate.Status__c = actionItem.Status__c;
        actionToUpdate.Completed_Date__c = actionItem.Completed_Date__c;
        actionToUpdate.Comments__c = actionItem.Comments__c;
        
        if(this.isCohortSeller){
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
        }
        return actionToUpdate;      
    }

    /**
     * Name: getCohortSellerCallOutcomeVal
     * Purpose: when user pick DMC Not Committed on action or project,  automatically change to DMC Not Interested
     * @param defaultCallOutComeVal
     *  //TH:US-0016104: Comment Out
    */
    /*getCohortSellerCallOutcomeVal(defaultCallOutComeVal){
       
        if(this.isCohortSeller && defaultCallOutComeVal == PKL_VAL_DMC_NOT_CALL_COMMITTED){
            defaultCallOutComeVal = PKL_VAL_DMC_NOT_INTERESTED;
        }
        return defaultCallOutComeVal;
    }*/

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
     * Purpose: when user click on schedule next call button after they save or populate new value to action record, show the schedule next call page or calendly based on variable useCalendly
     * @param event
    */
    handleScheduleNextCall(event) {
        if(!this.isFromRecordInboundCall){
            this.showEditParentObj = false;
            this.showEditSchedule = true;
            if(this.useCalendly){
                this.handleSaveExit();
            }
        }
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
        //TH:US-0016104: replace lightning-datatable with custom datatable
        //const selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
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

        let attr = {};
        if(this.isProject){
            attr = this.handleProjectCase(parentObjToUpdate, listActionsToUpdate);
        }else if(this.isCohortSeller){
            attr = this.handleCohortSellerCase(parentObjToUpdate, listActionsToUpdate);
        }

        if(attr){
            const payload = new CustomEvent('initiatecallapexsave', attr);
            this.dispatchEvent(payload);
        }

    }

    handleProjectCase(parentObjToUpdate, listActionsToUpdate){
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
        return {detail: {listActions : listActionsToUpdate, parentObj: parentObjToUpdate}};
    }

    handleCohortSellerCase(parentObjToUpdate, listActionsToUpdate){

        parentObjToUpdate.Call_Attempt__c = this.currentParentObj.Call_Attempt__c;

        if(this.isFromRecordInboundCall){
            //TH:US-0016104: comment out
            //parentObjToUpdate.Call_Outcome__c = this.getCohortSellerCallOutcomeVal(this.recordInboundCallParentObj.Action_Outcome__c);
            parentObjToUpdate.Call_Outcome__c = this.recordInboundCallParentObj.Action_Outcome__c == PKL_VAL_DMC_NOT_INTERESTED ? PKL_VAL_DMC_NOT_CALL_COMMITTED : this.recordInboundCallParentObj.Action_Outcome__c;
        }else{
            //TH:US-0016104: comment out
            //parentObjToUpdate.Call_Outcome__c = this.getCohortSellerCallOutcomeVal(this.currentParentObj.Call_Outcome__c);
            parentObjToUpdate.Call_Outcome__c = this.currentParentObj.Call_Outcome__c;
        }
        if(this.isParentObjCallOutcomeReq(parentObjToUpdate)){
            return null;
        }
        parentObjToUpdate.BoB__r = this.currentParentObj.BoB__r;
        parentObjToUpdate.Advisor_Comments__c = this.currentParentObj.Advisor_Comments__c;
        let addParam = {};
        if(this.isNotAUProfileOnly){
            addParam = this.additionalParam;
        }
        return {detail: {listActions : listActionsToUpdate, parentObj: parentObjToUpdate, isFromSeller: this.isFromRecordInboundCall, saveBSOnly:this.saveBSOnly, selectedContacts : this.selectedContacts, addParam : addParam, isMassEdit: this.isMassEdit}};
    }

    /**
     * Name: isParentObjCallOutcomeReq
     * Purpose: make sure cohort seller has Call Outcome before they can save
     * @param parentObjToUpdate
     * @return true if Call Outcome is still required, false otherwise
    */
    isParentObjCallOutcomeReq(parentObjToUpdate){
        if(this.isCohortSeller && !parentObjToUpdate.Call_Outcome__c){
            this.showSpinner = false;
            showToastMessage(this, {variant: 'warning', title: 'Require', message: this.label.InitiateCall_Enter_Overall_Call_Outcome});
            this.closeScheduleNextCallModal();
            return true;
        }
        return false;
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
                this.finishUpdateBeforeCalendly = true;
                showToastMessage(this, {variant: 'success', title: 'Update Complete', message: this.label.InitiateCall_Record_Updated});
                if(!this.showEditSchedule || (this.showEditSchedule && this.notUsingCalendly)){
                    this.backToRecord();
                }
            } else {
                showToastMessage(this, {variant: 'error', title: 'Update Error', message: 'Apex: ' + result.error});
            }

            if(this.notUsingCalendly){
                this.showEditSchedule = false;
            }

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
        // 21.10.2024 / Sophal Noch / US-0015818 : use function below instead of NavigationMixin.Navigate because it can refresh record detail page after redirect
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
    /**
     * Name: handleGoPreviousStep
     * Purpose: when componet is used in cohort seller, user click on back button it will go back to previous step which is the contact list
    */
    handleGoPreviousStep() {
        const payload = new CustomEvent('gopreviousstep', {
            detail: true
        });
        this.dispatchEvent(payload);
    }

    handleFlowStatusChange(event){
        if (event?.detail?.status === FLOW_NAME_STATUS_FINISHED || event?.detail?.status === FLOW_NAME_STATUS_FINISHED_SCREEN) {
            this.backToRecord();
        }
    }

}