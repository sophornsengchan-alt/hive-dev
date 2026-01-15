import { LightningElement, api} from 'lwc';
import { subscribe} from 'lightning/empApi';
import USER_ID from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';

export default class CohortAction extends NavigationMixin(LightningElement){


    @api cohortId;
    @api fromCohort = false;
    isReady = false;

    channelName = '/event/CohortAction_Event__e';
    subscription = {};
    userId = USER_ID;

    mapActionNameIndexToAction = {};


    initAction = 'Lwc_Cohort_Action_Init_Action';

    listAction = [
        {
            'key' : this.initAction,
            'label': '',
            'isLoading' : true,
            'isError' : false,
            'listError' : [],
            'isFinish' : false
        }
    ];


    connectedCallback(){
        if(this.isReady) { return;}
        this.handleSubscribe();
        
    }
 
    handleSubscribe() {
        this.isReady = true;
        const self = this;
        const messageCallback = function (response) {
            self.handleSetupListAction(response);

        };

        subscribe(this.channelName, -1, messageCallback).then(response => {
            this.subscription = response;
        });
    }

    handleSetupListAction(eventReceived){
       

        if(eventReceived && eventReceived.data && eventReceived.data.payload && eventReceived.data.payload.Action_Name__c && this.userId == eventReceived.data.payload.CreatedById){

            // fields from event CohortAction_Event__e published :
            let actionName = eventReceived.data.payload.Action_Name__c;
            let actionIndex = eventReceived.data.payload.Action_Index__c;
            let actionLabel= eventReceived.data.payload.Action_Label__c;
            let isError = eventReceived.data.payload.Is_Error__c;
            let errorMsg = eventReceived.data.payload.Error_Message__c;
            let isFinish = eventReceived.data.payload.Is_Finish__c;


            let actionNameIndex = actionName + '_' + actionIndex; // same action but different index/step so conbine to make unique key

            this.initMapAction(actionNameIndex, actionLabel); // init mapActionNameIndexToAction of specific ActionName and Index, Reuse the same Map if it already exists

            this.populateError(actionNameIndex, isError, errorMsg); // populate error on the map if there is any

            this.mapActionNameIndexToAction[actionNameIndex]['isFinish'] = isFinish; // to show tick icon for finished action
            
            let listAction = [];
            for (let nameIndex in this.mapActionNameIndexToAction) { // add action to listAction from mapActionNameIndexToAction to render on UI
                if(this.mapActionNameIndexToAction.hasOwnProperty(nameIndex)) {
                    let actionToAdd = this.mapActionNameIndexToAction[nameIndex];
                    actionToAdd['key'] = nameIndex;
                    actionToAdd['isLoading'] = false;
                    listAction.push(actionToAdd);
                }
            }

            if(listAction.length > 0){ // to show loading icon for latest action
                if(!listAction[listAction.length -1]['isFinish']){
                    listAction[listAction.length -1]['isLoading'] = true;
                }else{

                    let payload = {
                        isFinish : true
                    }
                    const custEvent = new CustomEvent(
                        "cohortactionfinish", {
                            detail : payload
                        });
                    this.dispatchEvent(custEvent);

                }
            }

           this.listAction = listAction;

        }
    }

    initMapAction(actionNameIndex, actionLabel){
        if(!this.mapActionNameIndexToAction[actionNameIndex]){
            this.mapActionNameIndexToAction[actionNameIndex] = {};
            this.mapActionNameIndexToAction[actionNameIndex]['listError'] = [];
        }
        this.mapActionNameIndexToAction[actionNameIndex]['label'] = actionLabel;
        this.mapActionNameIndexToAction[actionNameIndex]['isLoading'] = false;
    }

    populateError(actionNameIndex, isError, errorMsg){

        if(!this.mapActionNameIndexToAction[actionNameIndex]['isError']){
            this.mapActionNameIndexToAction[actionNameIndex]['isError'] = isError;
        }
        if(isError && errorMsg){
            let errorKey = actionNameIndex + '_error_' + this.mapActionNameIndexToAction[actionNameIndex]['listError'].length;
            let errorObj = {};
            errorObj['errorKey'] = errorKey;
            errorObj['errorMsg'] = errorMsg;
            this.mapActionNameIndexToAction[actionNameIndex]['listError'].push(errorObj);
        }
    }

}