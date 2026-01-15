/*********************************************************************************************************************************
@ Class:          LwcMySurvey
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        US-0014928 - Introduce new User CSAT Survey - Email Notification and My Assigned Task
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 14.03.2024 / Vadhanak Voun / Created the class. 
*********************************************************************************************************************************/
import { LightningElement } from 'lwc'; 
import apexGetMySurveys from '@salesforce/apex/MySurveyController.apexGetMySurveys';

export default class LwcMySurvey extends LightningElement{

    surveyId = "";
    surveyStatsus = "";
    listSurvey = [];
    mapTypes = {};
    listFields = [];
    showProgress = true;
    progressMsg = "Please wait...";
    columns = [];

    connectedCallback() 
    {
        this.checkAssigneeParam();
        this.handleGetMySurveys();
    }

    handleGetMySurveys()
    {
        apexGetMySurveys({surveyId: this.surveyId,orStatus: this.surveyStatsus})
        .then(result => {
            //console.log('result: ', result);
            this.listSurvey = result.listCSAT;
            this.mapTypes = result.MAP_FIELD_TYPES
            this.listFields = result.listFields;

            this.generateColumns();
            this.showHideSpinner(false);
        })
        .catch(error => {
            console.log('error: ', error);
            this.showHideSpinner(false);
        });

    }
    checkAssigneeParam()
    {
        const svIds = this.getParamHash('surveyId');
        const svStatus = this.getParamHash('surveyStatsus');
        //console.log('svIds',svIds+"  - svStatus: "+svStatus);
        if(!this.isBlank(svIds))
        {
            this.surveyId = svIds;
        }
        if(!this.isBlank(svStatus))
        {
            this.surveyStatsus = svStatus;
        }
    }

    generateColumns()
    {
        let columns = [
            {   label: 'Action',
                type: 'button-icon',
                fixedWidth: 70,
                typeAttributes: {
                    iconName: 'utility:edit',
                    name: 'edit_record',
                    title: 'Respond',
                    variant: 'border-filled',
                    alternativeText: 'Respond'
                }
            }
        ];
    
        // Add your existing columns to the columns array.
        // This code assumes that this.listFields is an array of field names.
        this.listFields.forEach(field => {
            let prop = { 
                fieldName: field.value, 
                label: field.label, 
                type: this.mapTypes[field.type]
            };
            if(field.type==="PERCENT")
            {
                prop.typeAttributes = {
                    step: '1',
                    minimumFractionDigits: '0',
                    maximumFractionDigits: '0',
                }
                // Divide percent values by 100.
                this.listSurvey = this.listSurvey.map(row => ({
                    ...row,
                    [field.value]: row[field.value] / 100
                }));
            }
            columns.push(prop);
        });
    
        this.columns = columns;

    }

    showHideSpinner(isShow)
    {
        this.showProgress = isShow;
    }

    handleRefresh(event)
    {
        this.showHideSpinner(true);
        this.handleGetMySurveys();
    }
     
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        //console.log('actionName: ', actionName);
        //console.log('row: ', JSON.stringify(row));
        switch (actionName) {
            case 'edit_record':
               
                window.open(row.ArdiraSurvey__Response_URL__c);                   

                break;
            // Add other case blocks here for other buttons, if needed.
            default:
                break;
        }
    }

    getParamHash(name) 
    {        
        var url = window.location.href;        
        //console.log('url',url);
        name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
        // let regexS = "[\\?&]"+name+"=([^&#]*)";  //lightning tab does not support parameter. use hash instead
        let regexS = "[\\?&#]"+name+"=([^&#]*)";
        let regex = new RegExp( regexS );
        let results = regex.exec( url );
        
        return results == null ? null : results[1];
    }
    isBlank(value) 
    {
        return (value === undefined || value === null )|| (value !=null && value.trim() === '');
    }
}