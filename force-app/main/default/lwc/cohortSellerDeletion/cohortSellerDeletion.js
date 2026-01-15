import { LightningElement, api} from 'lwc';
import getBobSellerToDeactivate from '@salesforce/apex/CohortActionController.getBobSellerToDeactivate';
import deactivateCohort from '@salesforce/apex/CohortActionController.deactivateCohort';
import deleteCohortSeller from '@salesforce/apex/CohortActionController.deleteCohortSeller';
import runDeactivateCohortSellerBatch from '@salesforce/apex/CohortActionController.runDeactivateCohortSellerBatch';
import { NavigationMixin } from 'lightning/navigation';
import { RefreshEvent } from "lightning/refresh";
import getBobSellerId from '@salesforce/apex/CohortActionController.getBobSellerId';

import Previous from '@salesforce/label/c.Previous';
import Cancel from '@salesforce/label/c.Cancel';
import Close from '@salesforce/label/c.Close';
import Yes from '@salesforce/label/c.Yes';
import No from '@salesforce/label/c.No';
import MgUser_Confirm from '@salesforce/label/c.MgUser_Confirm';

import CohortSeller_To_Be_Deactivated from '@salesforce/label/c.CohortSeller_To_Be_Deactivated';
import Success_Cohort_Sellers_To_Remove from '@salesforce/label/c.Success_Cohort_Sellers_To_Remove';
import Success_Cohort_Sellers_To_Delete from '@salesforce/label/c.Success_Cohort_Sellers_To_Delete';
import ErrorOrConflicted_Cohort_Sellers_To_Deactivate from '@salesforce/label/c.ErrorOrConflicted_Cohort_Sellers_To_Deactivate';
import CohortSeller_Activation_Error_Limit from '@salesforce/label/c.CohortSeller_Activation_Error_Limit';
import Number_Of_Record_Load_Increment from '@salesforce/label/c.Number_Of_Record_Load_Increment';
import Close_Modal_When_BatchCohortAction_Running from '@salesforce/label/c.Close_Modal_When_BatchCohortAction_Running';
import Update_Cohort_Seller_Status_Progress_Msg from '@salesforce/label/c.Update_Cohort_Seller_Status_Progress_Msg';
import Delete_Cohort_Seller_Progress_Msg from '@salesforce/label/c.Delete_Cohort_Seller_Progress_Msg';


export default class CohortSellerDeletion extends NavigationMixin(LightningElement){

    @api recordId;
    @api listBsId = [];
    @api chunkListBsId = [];
    @api step = 0;
    @api bob = {};
    @api showSpinner = false;
    @api isProTrader = false;
    @api isAds = false;
    @api isLttm = false;


    Labels = { 
        Previous,
        Cancel,
        Close,
        Yes,
        No,
        MgUser_Confirm,
        CohortSeller_To_Be_Deactivated,
        Success_Cohort_Sellers_To_Remove,
        Success_Cohort_Sellers_To_Delete,
        ErrorOrConflicted_Cohort_Sellers_To_Deactivate,
        CohortSeller_Activation_Error_Limit,
        Number_Of_Record_Load_Increment,
        Close_Modal_When_BatchCohortAction_Running,
        Update_Cohort_Seller_Status_Progress_Msg,
        Delete_Cohort_Seller_Progress_Msg
    };

    listToDeactivateColumn = [];
    listBsToDeactivateRow = [];
    listBsErrorRow = [];
    listBsErrorRowToDisplay = [];

    listBsIdToBeDeleted = [];

    isBatchRunning = false;
    hasFinishEvent = false
    isToDelete = false;
    hasDoneDeleted = false;

    numberOfRecord = 0;
    numberOfSuccess = 0;
    numberOfErrorOrConflicted = 0;

    numberOfRecordLoad = 0;

    confirmOptions = [
        { label: Yes, value: Yes, key : Yes, checked : true },
        { label: No,  value: No,  key : No,  checked : false },
    ];
    confirmValue = Yes;
    isAsync = false;

    updateCohortError = null;

    isReady = false;

    isUpdatingCohortSeller = false;
    

    chunkRowLimit = 0;
    chunkIndex = 0;
    totalChunkSize = 0;
    completedRowOfChunk = 0;
    totalRowOfChunk = 0;

    connectedCallback(){
        
        if(this.isReady){ return;}

        this.doGetBobSellerId();
    }

    doGetBobSellerId(){
        this.showSpinner = true;
        getBobSellerId({bobId : this.recordId, fromCohort : false})
        .then(result =>{
            this.isReady = true;
            if(result.status == 'ok'){
                if(result.isBatchRunning){
                    this.isBatchRunning = true;
                    this.showSpinner = false;
                    this.step = 3;
                    this.isAsync = true;
                    return;
                }

                this.bob = result.bob;
                this.isProTrader = result.isProTrader;
                this.getBsToDeactivate();

            }else{
                this.showSpinner = false;
                console.log('error ',result.error);
            }

        })
        .catch(error => {  this.showSpinner = false;  console.log('error ', error); });
    }

    getBsToDeactivate(){

        this.showSpinner = true;

        this.listToDeactivateColumn = [];
        this.listBsToDeactivateRow = [];
        this.listBsErrorRow = [];
        this.listBsErrorRowToDisplay = [];
        this.updateCohortError = null;

        getBobSellerToDeactivate({bobId : null, listBsId: this.listBsId, isToDelete : this.isToDelete})
        .then(result =>{

            this.isReady = true;

            this.step = 1;
            this.showSpinner = false;
            this.numberOfRecord = 0;
            this.numberOfSuccess = 0;
            this.numberOfErrorOrConflicted = 0;
            if(result.status == 'ok'){

                this.chunkListBsId = result.chunkListBsId;
                this.chunkRowLimit = result.chunkRowLimit;
                this.numberOfRecord = result.listBsToDeactivate.length;
                if(this.numberOfRecord > 0){
                    let mapLookUpFieldToLookUpObj = {};
                    this.setUpTableColumn(result.listToDeactivateColumn, mapLookUpFieldToLookUpObj, true);
                    this.setUpTableRow(result.listBsToDeactivate, mapLookUpFieldToLookUpObj, result.mapBsIdToError);
                    this.handlerLoadMoreRow();
                }else{

                    if(!this.isToDelete){
                        this.isToDelete = true;
                        this.getBsToDeactivate();
                    }else{
                        this.handleClose();
                    }
                    
                }

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
            listTableColumn.push({label: 'Result', fieldName: 'RESULT_LWC',type: "richText" , wrapText: true , cellAttributes: {class: {fieldName: 'columnTextColor'}}});
        }
        this.listToDeactivateColumn = listTableColumn;
    }
    setUpTableRow(listTableRecord, mapLookUpFieldToLookUpObj, mapBsIdToError){

        // let listBsIdToBeDeleted = [];
        this.listBsIdToBeDeleted = [];
        for(let i = 0; i < listTableRecord.length; i++){

            this.listBsIdToBeDeleted.push(listTableRecord[i].Id);

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

            if(mapBsIdToError != null && listTableRecord[i].Id && mapBsIdToError[listTableRecord[i].Id]){
                let listError = mapBsIdToError[listTableRecord[i].Id].split('. ');
                for(let j = 0; j < listError.length; j++){
                    if(listTableRecord[i]['RESULT_LWC']){
                        listTableRecord[i]['RESULT_LWC'] = listTableRecord[i]['RESULT_LWC'] + '\n- ' + listError[j];
                    }else{
                        listTableRecord[i]['RESULT_LWC'] = '- ' + listError[j];
                    }
                    
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
        
        this.listBsToDeactivateRow = listTableRecord;
        
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
            this.getBsToDeactivate();
        }
        
    }

    handleConfirmDeactivateSeller() {
        this.showSpinner = true;
        if(!this.isToDelete){
            this.handleDeactivateChunkCohortSeller(0);
        }else{
            this.handleDeleteChunkCohortSeller(0);
        }

    }

    handleDeactivateChunkCohortSeller(index){

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

            deactivateCohort({bobId: this.recordId, listBsId : this.chunkListBsId.listAllChunk[this.chunkIndex]})
            .then(result =>{
                this.showSpinner = false;
                if(result.status == 'ok'){
                    this.handleDeactivateChunkCohortSeller(index + 1);
                }else{
                    this.showSpinner = false;
                    this.step = 2;
                    console.log('error ', result.error);
                    this.handleDeactivateChunkCohortSeller(index + 1);
                }
            })
            .catch(error => {  this.showSpinner = false; this.step = 2; console.log('error ', error); this.handleDeactivateChunkCohortSeller(index + 1);});
           

        }else{

            this.showSpinner = true;

            this.hasFinishEvent = true;

            runDeactivateCohortSellerBatch({bobId : null, listBsId : this.listBsIdToBeDeleted})
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

    handleDeleteChunkCohortSeller(index){

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

            deleteCohortSeller({listBsId : this.chunkListBsId.listAllChunk[this.chunkIndex]})
            .then(result =>{
                this.showSpinner = false;
                if(result.status == 'ok'){
                    this.handleDeleteChunkCohortSeller(index + 1);
                }else{
                    this.showSpinner = false;
                    this.step = 2;
                    console.log('error ', result.error);
                    this.handleDeleteChunkCohortSeller(index + 1);
                }
            })
            .catch(error => {  this.showSpinner = false; this.step = 2; console.log('error ', error); this.handleDeleteChunkCohortSeller(index + 1);});
           

        }else{
                // to do list
            this.hasDoneDeleted = true;
            this.handleClose();
        }
    }

    handleClose() {

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

        // // this.dispatchEvent(new RefreshEvent());
        //eval("$A.get('e.force:refreshView').fire();");

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

    onCohortActionFinish(event){

        if(!this.isToDelete){
            if(event && event.detail && event.detail.isFinish){
                this.isToDelete = true;
                this.step = 1;
                this.getBsToDeactivate();
            }
        }
    }

    get deactivateButtonLabel(){
        return this.Labels.Yes;
       
    }

    get hasCohortSeller(){
        return this.numberOfRecord > 0 ? true : false;
    }

    get hasSuccess(){
        return this.numberOfSuccess > 0 ? true : false;
    }

    get hasErrorOrConflicted(){
        return this.numberOfErrorOrConflicted > 0 ? true : false;
    }

    get hasErrorOrConflictedMoreThanLimit(){
        let limit = this.Labels.CohortSeller_Activation_Error_Limit ? parseInt(this.Labels.CohortSeller_Activation_Error_Limit) : 0;
        return this.numberOfErrorOrConflicted >= limit ? true : false;
    }

    get isAllSuccess(){
        return (this.listBsToDeactivateRow.length > 0 && this.listBsToDeactivateRow.length == this.numberOfSuccess && this.numberOfErrorOrConflicted <= 0) ? true : false;
    }

    get lbAllSuccessCohortSeller(){
        let successMsg = '';
        if(!this.isToDelete){
            successMsg =  this.Labels.Success_Cohort_Sellers_To_Remove.replace('{0}', this.numberOfSuccess);
        }else{
            successMsg = this.Labels.Success_Cohort_Sellers_To_Delete.replace('{0}', this.numberOfSuccess);
        }
        return successMsg;
    }

    get lbUpdateCohortSellerStatusProgressMsg(){
        let progressMsg = '';
        if(!this.isToDelete){
            progressMsg = this.Labels.Update_Cohort_Seller_Status_Progress_Msg.replace('{0}', this.completedRowOfChunk).replace('{1}', this.totalRowOfChunk);
        }else{
            progressMsg = this.Labels.Delete_Cohort_Seller_Progress_Msg.replace('{0}', this.completedRowOfChunk).replace('{1}', this.totalRowOfChunk);
        }
        return progressMsg;
    }

    get hasUpdateCohortError(){
        return this.updateCohortError != null ? true : false;
    }

    get enableDeactivateButton(){
        return this.hasCohortSeller == true && this.hasSuccess == true && this.hasErrorOrConflictedMoreThanLimit == false && this.numberOfErrorOrConflicted <= 0 && this.hasUpdateCohortError == false;
    }

    get step1BlockingErrorMsg(){
        let step1ErrMsg;
        if(this.isReady){
            if(this.hasErrorOrConflictedMoreThanLimit){
                step1ErrMsg = this.Labels.ErrorOrConflicted_Cohort_Sellers_To_Deactivate;
            }
        }
        return step1ErrMsg;

    }

    get isStep1BlockingError(){
        return this.step1BlockingErrorMsg != null ? true : false;
    }

    get step2IsBtnDisabled(){
        return this.step2 && this.isUpdatingCohortSeller && !this.hasDoneDeleted;
    }

    get step3IsBtnDisabled(){
        return this.step3 && !this.isBatchRunning;
    }


    get header(){
        return this.Labels.CohortSeller_To_Be_Deactivated;
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
        return !this.enableDeactivateButton || this.step2 || this.step3 ? 'brand' : 'neutral';
    }

    get closeBtnLabel(){
        return (this.step3 || this.step2 || (this.step1 && (this.isStep1BlockingError || this.hasErrorOrConflicted))) ? this.Labels.Close : this.Labels.Cancel;
    }



}