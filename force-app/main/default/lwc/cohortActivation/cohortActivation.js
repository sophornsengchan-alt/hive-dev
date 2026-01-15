import { LightningElement, api} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getBobSellerToActivate from '@salesforce/apex/CohortActionController.getBobSellerToActivate';
import activateCohort from '@salesforce/apex/CohortActionController.activateCohort';
import activateCohortSeller from '@salesforce/apex/CohortActionController.activateCohortSeller';
import runActivateCohortSellerBatch from '@salesforce/apex/CohortActionController.runActivateCohortSellerBatch';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from "lightning/refresh";
import getBobSellerId from '@salesforce/apex/CohortActionController.getBobSellerId';
import validateBeforeActivate from '@salesforce/apex/CohortActionController.validateBeforeActivate';


import Previous from '@salesforce/label/c.Previous';
import Cancel from '@salesforce/label/c.Cancel';
import Close from '@salesforce/label/c.Close';
import Yes from '@salesforce/label/c.Yes';
import No from '@salesforce/label/c.No';
import MgUser_Confirm from '@salesforce/label/c.MgUser_Confirm';

import Invite_Sellers from '@salesforce/label/c.Invite_Sellers';
import Invite_Eligible_Sellers from '@salesforce/label/c.Invite_Eligible_Sellers';
import Activate_Sellers from '@salesforce/label/c.Activate_Sellers';
import Activate_Eligible_Sellers from '@salesforce/label/c.Activate_Eligible_Sellers';
import CohortSeller_To_Be_Invited from '@salesforce/label/c.CohortSeller_To_Be_Invited';
import Cohort_Sellers_to_be_Activated from '@salesforce/label/c.Cohort_Sellers_to_be_Activated';
import Success_Cohort_Sellers from '@salesforce/label/c.Success_Cohort_Sellers';
import ErrorOrConflicted_Cohort_Sellers from '@salesforce/label/c.ErrorOrConflicted_Cohort_Sellers';
import All_Cohort_Seller_Are_Eligible from '@salesforce/label/c.All_Cohort_Seller_Are_Eligible';
import CohortSeller_Activation_Error_Limit from '@salesforce/label/c.CohortSeller_Activation_Error_Limit';
import Confirm_Activate_Cohort_Seller from '@salesforce/label/c.Confirm_Activate_Cohort_Seller';
import Confirm_Activate_Eligible_Cohort_Seller from '@salesforce/label/c.Confirm_Activate_Eligible_Cohort_Seller';
import Confirm_Invite_Cohort_Seller from '@salesforce/label/c.Confirm_Invite_Cohort_Seller';
import Confirm_Invite_Eligible_Cohort_Seller from '@salesforce/label/c.Confirm_Invite_Eligible_Cohort_Seller';
import Using_Activate_Seller_Button from '@salesforce/label/c.Using_Activate_Seller_Button';
import Using_Invite_Seller_Button from '@salesforce/label/c.Using_Invite_Seller_Button';
import CohortSeller_Activation_Error_Limit_Msg from '@salesforce/label/c.CohortSeller_Activation_Error_Limit_Msg';
import Number_Of_Record_Load_Increment from '@salesforce/label/c.Number_Of_Record_Load_Increment';
import Add_CohortSellers_Before_Activating_Cohort from '@salesforce/label/c.Add_CohortSellers_Before_Activating_Cohort';
import Invite_CohortSellers_Before_Activating_Cohort from '@salesforce/label/c.Invite_CohortSellers_Before_Activating_Cohort';
import Select_CohortSeller_Before_Activating_Cohort from '@salesforce/label/c.Select_CohortSeller_Before_Activating_Cohort';
import Close_Modal_When_BatchCohortAction_Running from '@salesforce/label/c.Close_Modal_When_BatchCohortAction_Running';
import error_before_activate from '@salesforce/label/c.error_before_activate';
import Error_Before_Active_Cohort_LTTMManaged from '@salesforce/label/c.Error_Before_Active_Cohort_LTTMManaged';
import Error_Invite_Active_Cohort_Seller_When_Cohort_Not_Active from '@salesforce/label/c.Error_Invite_Active_Cohort_Seller_When_Cohort_Not_Active';
import Update_Cohort_Seller_Status_Progress_Msg from '@salesforce/label/c.Update_Cohort_Seller_Status_Progress_Msg';
export default class CohortActivation extends NavigationMixin(LightningElement){
    @api recordId;
    @api listBsId = [];
    @api chunkListBsId = [];
    @api step = 0;
    @api bob = {};
    @api fromActivateCohort = false;
    @api showSpinner = false;
    @api isProTrader = false;
    @api isActivateSellerPage = false;
    @api isActivateCohortSeller = false;
    @api retUrl;// CSP:02092025: US-0033165 
    
    isReady = false;
    isErrorBeforeActivate = false;
    isErrorCohortNotActiveYet = false;
    showProTraderPage = false;

    Labels = { 
        Previous,
        Cancel,
        Close,
        Yes,
        No,
        MgUser_Confirm,
        Invite_Sellers,
        Invite_Eligible_Sellers,
        Activate_Sellers,
        Activate_Eligible_Sellers,
        CohortSeller_To_Be_Invited,
        Cohort_Sellers_to_be_Activated,
        Success_Cohort_Sellers,
        ErrorOrConflicted_Cohort_Sellers,
        All_Cohort_Seller_Are_Eligible,
        CohortSeller_Activation_Error_Limit,
        Confirm_Activate_Cohort_Seller,
        Confirm_Activate_Eligible_Cohort_Seller,
        Confirm_Invite_Cohort_Seller,
        Confirm_Invite_Eligible_Cohort_Seller,
        Using_Activate_Seller_Button,
        Using_Invite_Seller_Button,
        CohortSeller_Activation_Error_Limit_Msg,
        Number_Of_Record_Load_Increment,
        Add_CohortSellers_Before_Activating_Cohort,
        Invite_CohortSellers_Before_Activating_Cohort,
        Select_CohortSeller_Before_Activating_Cohort,
        Close_Modal_When_BatchCohortAction_Running,
        error_before_activate,
        Error_Before_Active_Cohort_LTTMManaged,
        Error_Invite_Active_Cohort_Seller_When_Cohort_Not_Active,
        Update_Cohort_Seller_Status_Progress_Msg
    };

    listToActivateColumn = [];
    listBsToActivateRow = [];
    listBsErrorRow = [];
    listBsErrorRowToDisplay = [];

    numberOfRecord = 0;
    numberOfSuccess = 0;
    numberOfConflicted = 0;
    numberOfError = 0;
    numberOfErrorOrConflicted = 0;

    numberOfRecordLoad = 0;

    confirmOptions = [
        { label: Yes, value: Yes, key : Yes, checked : true },
        { label: No,  value: No,  key : No,  checked : false },
    ];
    confirmValue = Yes;

    isAsync = false;

    updateCohortError = null;

    isUpdatingCohortSeller = false;

    chunkRowLimit = 0;
    chunkIndex = 0;
    totalChunkSize = 0;
    completedRowOfChunk = 0;
    totalRowOfChunk = 0;

    connectedCallback(){
        if(this.isReady){return;}
        if(this.fromActivateCohort){
            if(this.isProTrader){ this.showProTraderPage = true; }
            this.doValidateBeforeActivate();
        }else{
            this.doGetBobSellerId();
        }
    }

    doGetBobSellerId(){
        this.showSpinner = true;
        getBobSellerId({bobId : this.recordId, fromCohort : this.fromActivateCohort})
        .then(result =>{
            this.isReady = true;
            if(result.status == 'ok'){
                if(result.isBatchRunning){
                    this.showSpinner = false;
                    this.step = 3;
                    this.isActivateCohortSeller = true;
                    this.isAsync = true;
                    return;
                }

                if(!result.isCohortActive){
                    this.showSpinner = false;
                    this.isErrorCohortNotActiveYet = true;
                    this.step = 1;
                }

                this.bob = result.bob;
                this.isProTrader = result.isProTrader;
                if((this.fromActivateCohort && this.isProTrader) || (!this.isActivateSellerPage && this.isProTrader)){ 
                    this.showProTraderPage = true; 
                }
                this.getBsToActivate();

            }else{
                this.showSpinner = false;
                console.log('error ',result.error);
            }

        })
        .catch(error => {  this.showSpinner = false;  console.log('error ', error); });

        
    }

    doValidateBeforeActivate(){

        this.showSpinner = true;
        validateBeforeActivate({bobId : this.recordId})
        .then(result =>{
            this.isReady = true;
            if(result.status == 'ok'){
                this.isErrorBeforeActivate = result.isErrorBeforeActivate;
                if(!this.isErrorBeforeActivate){
                    this.getBsToActivate();
                }else{
                    this.showSpinner = false;
                    this.step = 1;
                }
            }else{
                this.showSpinner = false;
                console.log('error ',result.error);
            }

        })
        .catch(error => {  this.showSpinner = false; console.log('error ', error); });
        
    }

    getBsToActivate(){

        this.showSpinner = true;

        this.listToActivateColumn = [];
        this.listBsToActivateRow = [];
        this.listBsErrorRow = [];
        this.listBsErrorRowToDisplay = [];
        this.updateCohortError = null;

        let bobId = null;
        let listBsId = null;

        if(this.fromActivateCohort){
            bobId = this.recordId;
        }else{
            listBsId = this.listBsId;
        }

        getBobSellerToActivate({bobId : bobId, listBsId : listBsId, isInvitedToActive : this.isInvitedToActive})
        .then(result =>{
            this.step = 1;
            this.showSpinner = false;
            this.numberOfConflicted = 0;
            this.numberOfError = 0;
            this.numberOfRecord = 0;
            this.numberOfSuccess = 0;
            this.numberOfErrorOrConflicted = 0;
            if(result.status == 'ok'){

                this.chunkListBsId = result.chunkListBsId;
                this.chunkRowLimit = result.chunkRowLimit;
                this.numberOfRecord = result.listBsToActivate.length;
                let mapLookUpFieldToLookUpObj = {};
                this.setUpTableColumn(result.listToActivateColumn, mapLookUpFieldToLookUpObj, true);
                this.setUpTableRow(result.listBsToActivate, mapLookUpFieldToLookUpObj, result.mapBsIdToConflicted, result.mapBsIdToError);
                this.handlerLoadMoreRow();
            }else{
                console.log('error ', result.error);
            }
            

        })
        .catch(error => {  this.showSpinner = false;  console.log('error ', error); });
        

    }

    setUpTableColumn(listTableColumn, mapLookUpFieldToLookUpObj, hasColumnResult){

        for(let i = 0; i < listTableColumn.length; i++){
            if(listTableColumn[i].type == 'url' &&  listTableColumn[i].fieldName.substring(0,5) && listTableColumn[i].fieldName.substring(0,5) == 'link_' && listTableColumn[i].typeAttributes && listTableColumn[i].typeAttributes.label){
                let lookupFApiName = listTableColumn[i].fieldName.substring(5);
                mapLookUpFieldToLookUpObj[lookupFApiName] = listTableColumn[i].typeAttributes.label.fieldName.split('.')[0];
            }
        }
        if(hasColumnResult){
            listTableColumn.push({label: 'Result', fieldName: 'RESULT_LWC',initialWidth: 200, type: "richText",wrapText: true , cellAttributes: {class: {fieldName: 'columnTextColor'}}});
        }
        this.listToActivateColumn = listTableColumn;
    }
    setUpTableRow(listTableRecord, mapLookUpFieldToLookUpObj, mapBsIdToConflicted, mapBsIdToError){

        let listBsId = [];
        for(let i = 0; i < listTableRecord.length; i++){
            
            if(!this.fromActivateCohort){
                listBsId.push(listTableRecord[i].Id);
            }

            for (let key in listTableRecord[i]) {
                if(listTableRecord[i].hasOwnProperty(key) && mapLookUpFieldToLookUpObj[key]) {
                    listTableRecord[i]['link_'+key] = '/' + listTableRecord[i][key];
                    let lookUpObj = mapLookUpFieldToLookUpObj[key];
                    if(lookUpObj != 'Name'){
                        listTableRecord[i][lookUpObj+'.Name'] = listTableRecord[i][lookUpObj].Name;
                    }
                    
                }

            }
            
            let isSuccess = true

            if(mapBsIdToConflicted != null && listTableRecord[i].Id && mapBsIdToConflicted[listTableRecord[i].Id]){

                this.numberOfConflicted ++;

                if(!listTableRecord[i]['RESULT_LWC']){
                    listTableRecord[i]['RESULT_LWC'] =  mapBsIdToConflicted[listTableRecord[i].Id +'_Link'];
                }else{
                    listTableRecord[i]['RESULT_LWC'] = listTableRecord[i]['RESULT_LWC'] + ("\n" + mapBsIdToConflicted[listTableRecord[i].Id +'_Link']);
                }
                listTableRecord[i]['columnTextColor'] = 'slds-text-color_error tableRowCellError';
                //listTableRecord[i]['OPEN_RESULT_LWC'] = mapBsIdToConflicted[listTableRecord[i].Id +'_Link'];
                isSuccess = false;
            }

            if(mapBsIdToError != null && listTableRecord[i].Id && mapBsIdToError[listTableRecord[i].Id]){

                this.numberOfError ++;

                if(!listTableRecord[i]['RESULT_LWC']){
                    listTableRecord[i]['RESULT_LWC'] =  "- " + mapBsIdToError[listTableRecord[i].Id];
                }else{
                    listTableRecord[i]['RESULT_LWC'] = listTableRecord[i]['RESULT_LWC'] + ("\n" + "- " + mapBsIdToError[listTableRecord[i].Id]);
                }
                listTableRecord[i]['columnTextColor'] = 'slds-text-color_error';
                isSuccess = false;
            }

            if(isSuccess){
                this.numberOfSuccess ++;
            }else{
                this.listBsErrorRow.push(listTableRecord[i]);
                this.numberOfErrorOrConflicted ++;
            }
        }
        if(!this.fromActivateCohort){
            this.listBsId = listBsId;
        }
        this.listBsToActivateRow = listTableRecord;
    }

    handlePrevious(event) {
        this.step --;
        if(this.step <=0){
            event.preventDefault();
            const chooseStatus = new CustomEvent('choosestatus', {
               detail: 'prev'
            });
            this.dispatchEvent(chooseStatus);

        }else if(this.step == 1){
            this.getBsToActivate();
        }
        
    }

    handleConfirmActivateSeller() {
        if(this.fromActivateCohort){
            this.step = 2;
        }else{
            this.handleActivateCohort();
        }
        
    }
        
    handleActivateCohort() {

        this.showSpinner = true;

        if(this.fromActivateCohort){

            if(this.confirmValue == this.Labels.Yes){
                this.isActivateCohortSeller = true;
            }else{
                this.isActivateCohortSeller = false;
            }
          
            // activateCohort({bobId: this.recordId, isActivateBs : this.isActivateCohortSeller, numberOfBs : this.numberOfRecord})
            activateCohort({bobId: this.recordId})
            .then(result =>{
               
                if(result.status == 'ok'){

                    if(this.isActivateCohortSeller){
                        this.handleActivateChunkCohortSeller(0);
                    }else{
                        this.showSpinner = false;
                        this.step = 3;
                    }
                }else{
                    this.showSpinner = false;
                    this.updateCohortError = result.error;
                    console.log('error ', result.error);
                }
            })
            .catch(error => {  
                this.showSpinner = false;  
                this.updateCohortError = error;
                console.log('error ', error); 
            });

        }else{
            this.isActivateCohortSeller = true;
            this.handleActivateChunkCohortSeller(0);
        }

    }

    handleActivateChunkCohortSeller(index) {
        this.showSpinner = false;

        this.chunkIndex = index;
        this.totalChunkSize = this.chunkListBsId.chunkSize;
        this.totalRowOfChunk = this.chunkListBsId.totalRow;

        this.completedRowOfChunk = this.chunkIndex * this.chunkRowLimit;
        if(this.totalRowOfChunk < this.completedRowOfChunk){
            this.completedRowOfChunk = this.totalRowOfChunk;
        }

        if(this.chunkIndex < this.totalChunkSize){

            this.step = 2;
            this.isUpdatingCohortSeller = true;

            activateCohortSeller({bobId: this.recordId, listBsId : this.chunkListBsId.listAllChunk[this.chunkIndex], isInvitedToActive: this.isInvitedToActive})
            .then(result =>{
                
                if(result.status == 'ok'){
                    this.handleActivateChunkCohortSeller(index + 1)
                    
                }else{
                    this.showSpinner = false;
                    console.log('error ', result.error);
                    this.handleActivateChunkCohortSeller(index + 1)
                    
                }
            })
            .catch(error => {  
                this.showSpinner = false; 
                console.log('error ', error); 
                this.handleActivateChunkCohortSeller(index + 1)
            });
        }else{

            this.showSpinner = true;

            let bobId = null;
            let listBsId = null;
            if(this.fromActivateCohort){
                bobId = this.recordId;
            }else{
                listBsId = this.listBsId;
            }

            runActivateCohortSellerBatch({bobId : bobId, listBsId : listBsId})
            .then(result =>{
                this.showSpinner = false;
                if(result.status == 'ok'){
                    this.step = 3;
                    this.isAsync = true;
                }else{
                    this.updateCohortError = result.error;
                    console.log('error ', result.error);
                }
            })
            .catch(error => { this.showSpinner = false;  this.updateCohortError = result.error; console.log('error ', error); });
        }



    }

    onCohortActionFinish(event) {
        if(event && event.detail && event.detail.isFinish){
            this.handleRedirect();
        }
    }

     handleClose() {

        if(this.fromActivateCohort){
            this.dispatchEvent(new CloseActionScreenEvent({ bubbles: true, composed: true }));
            this.handleRedirect();
        }else if(this.retUrl){
            // CSP:02092025: US-0033165 
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: this.retUrl
                }
            }, true);
        }else{
            this[ NavigationMixin.GenerateUrl ]( {
                type: 'standard__recordRelationshipPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'BoB__c',
                    relationshipApiName: 'BoB_Sellers__r',
                    actionName: 'view'
                }
            } ).then((url) => {
                window.open(url, '_self');
            });
        }
            
        // this.dispatchEvent(new RefreshEvent());
        //eval("$A.get('e.force:refreshView').fire();");
    
    }

    handleRedirect() {

        if(this.fromActivateCohort){
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'BoB__c',
                    actionName: 'view'
            }}).then((url) => {
                window.location.href = url;
            });

        }
        
    }

    handlerLoadMoreRow(){
        if(this.listBsErrorRow.length > 0 && this.listBsErrorRowToDisplay.length < this.listBsErrorRow.length){
            this.numberOfRecordLoad = this.numberOfRecordLoad + this.numberOfRecordIncrement;
            let numberOfRecordLoad = this.numberOfRecordLoad < this.listBsErrorRow.length ? this.numberOfRecordLoad : this.listBsErrorRow.length;
            this.listBsErrorRowToDisplay = this.listBsErrorRow.slice(0, numberOfRecordLoad);
        }
    }

    handleChangeConfirmOption(event){
        
        this.confirmValue = event.target.value;
        let confirmOptions = [];
        for(let i = 0; i < this.confirmOptions.length; i++){
            if(this.confirmOptions[i].value ==  this.confirmValue){
                this.confirmOptions[i]['checked'] = true;
            }else{
                this.confirmOptions[i]['checked'] = false;
            }
            confirmOptions.push(this.confirmOptions[i]);
        }
        this.confirmOptions = confirmOptions;

    }

    get isInvitedToActive(){
        return (this.isActivateSellerPage && this.isProTrader);
    }

    get lbSuccessCohortSeller(){
        return ('- ' + this.Labels.Success_Cohort_Sellers.replace('{0}', this.numberOfSuccess));
    }

    get activateButtonLabel(){
        if(this.isAllSuccess){
            return this.showProTraderPage ? this.Labels.Invite_Sellers : this.Labels.Activate_Sellers;
        }else{
            return this.showProTraderPage ? this.Labels.Invite_Eligible_Sellers : this.Labels.Activate_Eligible_Sellers;
        }
       
    }

    get lbConfirmActivateCohortSeller(){
        if(this.isAllSuccess){
            return this.showProTraderPage ? this.Labels.Confirm_Invite_Cohort_Seller : this.Labels.Confirm_Activate_Cohort_Seller;
        }else{
            return this.showProTraderPage ? this.Labels.Confirm_Invite_Eligible_Cohort_Seller : this.Labels.Confirm_Activate_Eligible_Cohort_Seller;
        }
    }

    get hasCohortSeller(){
        return this.numberOfRecord > 0 ? true : false;
    }

    get hasConflicted(){
        return this.numberOfConflicted > 0 ? true : false;
    }

    get hasError(){
        return this.numberOfError > 0 ? true : false;
    }

    get hasSuccess(){
        return this.numberOfSuccess > 0 ? true : false;
    }

    get hasErrorOrConflicted(){
        return this.numberOfErrorOrConflicted > 0 ? true : false;
    }

    get lbErrorOrConflictedCohortSeller(){
        return ('- ' + this.Labels.ErrorOrConflicted_Cohort_Sellers.replace('{0}', this.numberOfErrorOrConflicted));
    }

    get hasErrorOrConflictedMoreThanLimit(){
        let limit = this.Labels.CohortSeller_Activation_Error_Limit ? parseInt(this.Labels.CohortSeller_Activation_Error_Limit) : 0;
        return this.numberOfErrorOrConflicted >= limit ? true : false;
    }

    get lbAllSuccessCohortSeller(){
        return this.Labels.Success_Cohort_Sellers.replace('{0}', this.numberOfSuccess);
    }

    get lbUpdateCohortSellerStatusProgressMsg(){
        return this.Labels.Update_Cohort_Seller_Status_Progress_Msg.replace('{0}', this.completedRowOfChunk).replace('{1}', this.totalRowOfChunk);
    }

    get hasUpdateCohortError(){
        return this.updateCohortError != null ? true : false;
    }

    get step1BlockingErrorMsg(){
        let step1ErrMsg;
        if(this.isReady){
            if(this.isErrorBeforeActivate){
                if(this.isProTrader){
                    step1ErrMsg = this.Labels.error_before_activate;
                }else{
                    step1ErrMsg = this.Labels.Error_Before_Active_Cohort_LTTMManaged;
                }
            }else if(this.isErrorCohortNotActiveYet){
                step1ErrMsg = this.Labels.Error_Invite_Active_Cohort_Seller_When_Cohort_Not_Active;
            }else if(this.hasErrorOrConflictedMoreThanLimit){
                step1ErrMsg = this.Labels.CohortSeller_Activation_Error_Limit_Msg;
            }else if(!this.hasCohortSeller){
                step1ErrMsg = !this.isInvitedToActive ? (this.fromActivateCohort ? this.Labels.Add_CohortSellers_Before_Activating_Cohort : this.Labels.Select_CohortSeller_Before_Activating_Cohort) : this.Labels.Invite_CohortSellers_Before_Activating_Cohort;
            }
        }
        return step1ErrMsg;

    }

    get isStep1BlockingError(){
        return this.step1BlockingErrorMsg != null ? true : false;
    }

    get step2IsBtnDisabled(){
        return this.step2 && this.isUpdatingCohortSeller;
    }

    get enableActivateButton(){
        return this.hasSuccess == true && !this.isStep1BlockingError && this.hasUpdateCohortError == false;
    }

    get isAllSuccess(){
        return (this.listBsToActivateRow.length > 0 && this.listBsToActivateRow.length == this.numberOfSuccess && this.numberOfErrorOrConflicted <= 0 && !this.isStep1BlockingError) ? true : false;
    }

    get showTable(){
        return this.hasCohortSeller && this.hasErrorOrConflicted && this.isErrorCohortNotActiveYet == false; 
    }

    get header(){
        let name = this.showProTraderPage ? this.Labels.CohortSeller_To_Be_Invited : this.Labels.Cohort_Sellers_to_be_Activated;
        return name;
    }

    get step1(){
        return this.step == 1;
    }

    get step2(){
        return this.step == 2;
    }

    get step3(){
        return this.step == 3;
    }

    get numberOfRecordIncrement() {
        return this.Labels.Number_Of_Record_Load_Increment ? parseInt(this.Labels.Number_Of_Record_Load_Increment) : 0;
    }

    get closeBtnVariant(){
        return !this.enableActivateButton || this.step3 ? 'brand' : 'neutral';
    }

    get closeBtnLabel(){
        return (this.step3 || (!this.fromActivateCohort && this.step1 && this.isStep1BlockingError)) ? this.Labels.Close : this.Labels.Cancel;
    }

}