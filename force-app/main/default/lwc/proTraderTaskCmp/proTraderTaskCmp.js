import { LightningElement,api } from 'lwc';
import ProTrader_TaskItem_Gear_Icon from '@salesforce/resourceUrl/ProTrader_TaskItem_Gear_Icon';
import customLabel from 'c/customLabels';
import { isNullorUndefinedorZero } from "c/hiveUtils";
import CreatedDate from '@salesforce/schema/Account.CreatedDate';


export default class ProTraderTaskCmp extends LightningElement {

    cohortSellertask = [];
    taskStatus = ['In Progress','Completed'];
    filteredCohortSellerTaskList = [];

    proTrader_TaskItem_Gear_Icon = ProTrader_TaskItem_Gear_Icon;
    noCohortTaskFound = false;
    openTaskCount = 0;
    closedTaskCount = 0;
    label = customLabel;
    

    /**
     * description - returns the cohort seller and category performance data
     */
    @api
    get cohortSellerandCategoryPerformanceData(){
        return this.cohortSellertask;
    }

    set cohortSellerandCategoryPerformanceData(value){
        if(!isNullorUndefinedorZero(value?.cohortTaskList)){
            this.cohortSellertask = value?.cohortTaskList;
            if(this.cohortSellertask && this.cohortSellertask.length>0){
                this.formActionTaskTable(this.cohortSellertask);
            }else{
                this.noCohortTaskFound = true;
            }
        }
    }

    /**
     * 
     * @param {*} actionTaskList 
     * description - forms the action task table
     */
    formActionTaskTable(actionTaskList){
        this.cohortSellertask = [];
        this.openTaskCount = 0;
        this.closedTaskCount = 0;
        actionTaskList?.forEach(eachAction =>{
            let cohortSellerTask;
            cohortSellerTask = [{description :eachAction.description,sellerFacingMessage :eachAction.sellerFacingMessage,
                                    status:eachAction.status,comments:eachAction.comments,
                                    actionTemplateId:eachAction.actionTemplateId,helpText:eachAction.helptext,
                                    documentLink:eachAction.documentLink,dueDate:eachAction.dueDate}];

            this.cohortSellertask.push(cohortSellerTask);
            this.filteredCohortSellerTaskList.push(cohortSellerTask);
            this.createFilteredTaskList(this.taskStatus[0]);
            //get the count of open and completed task
            if(eachAction.status == this.taskStatus[0]){
                this.openTaskCount++;
            }
            if(eachAction.status == this.taskStatus[1]){
                this.closedTaskCount++;
            }
        })
    }

    /**
     * 
     * @param {*} event 
     * description - handles the task action click
     */
    handleTaskAction(event){
        const taskButtonName = event.target.dataset.name;
        if(taskButtonName == 'completedTask'){
            if(this.closedTaskCount == 0){
                console.log('closedTaskCount = '+ this.closedTaskCount);
                this.template.querySelector(`[data-name="noteCategory"]`).classList.add('slds-hidden');
            } else {
                this.template.querySelector(`[data-name="noteCategory"]`).classList.remove('slds-hidden');
            }
            this.template.querySelector(`[data-name="completedTask"]`).classList.add('active-button');
            this.template.querySelector(`[data-name="openTask"]`).classList.remove('active-button');
            this.createFilteredTaskList(this.taskStatus[1]);

        } 
        if(taskButtonName == 'openTask'){
            if(this.openTaskCount == 0){
                console.log('openTask = '+ this.openTaskCount);
                this.template.querySelector(`[data-name="noteCategory"]`).classList.add('slds-hidden');
            } else {
                this.template.querySelector(`[data-name="noteCategory"]`).classList.remove('slds-hidden');
            }
            this.template.querySelector(`[data-name="openTask"]`).classList.add('active-button');
            this.template.querySelector(`[data-name="completedTask"]`).classList.remove('active-button');
            this.createFilteredTaskList(this.taskStatus[0]);
        }                            
    }

    
    createFilteredTaskList(tabName){
        let taskList = this.cohortSellertask;
        this.filteredCohortSellerTaskList = [];      
        taskList?.forEach(eachAction =>{
            const filteredTaskList = eachAction.filter((obj) => obj.status == tabName);
            this.filteredCohortSellerTaskList.push(filteredTaskList);
        }) 
        if(this.filteredCohortSellerTaskList.length == 0){
            this.noCohortTaskFound = true;
        }
    }

    
}