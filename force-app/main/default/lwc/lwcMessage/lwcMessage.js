/*******************************************************************************************************************************************
@ Class:          LwcMessage
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        US-0014270 - HoneyComb Work Manager
---------------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.06.2023 / Vadhanak Voun / Created the class. 
                  11.12.2024 / Sothea Horn / US-0015300 - Generic LWC Exception handling & Application to program participation component
**********************************************************************************************************************************************/
import { LightningElement,api } from 'lwc';
import Toast from 'lightning/toast';
import { reduceErrors } from "c/hiveUtils";
import { log } from 'lightning/logger';
import logErrorLWC from '@salesforce/apex/EBH_ApexLogger.logErrorLWC';

export default class LwcMessage extends LightningElement {

    @api message = {};
    
    state = false;
    timeOut = 0; //how long to show message; zero means no timeout
    /**
     * @param {*} msg object message {type:'error',msg:'message',msgDetail:'message detail'}
     * @param {*} state true: show message, false: hide message
     * @param {*} tm time out in millis. how long to show message; zero means no timeout
     */
    @api setMessage(msg,state,tm)
    {
        this.message = msg;
        this.state = state;
        //console.log(JSON.stringify(this.message));
        if(tm === 0 || tm === undefined || tm === null)
        {
            this.timeOut = 0;
        }else
        {
            this.timeOut = tm;
            setTimeout(() => {
                this.state = false;
            }, tm);
        }
    }
    get showMessage()
    {
        return this.state;
    }
    get isErro()
    {
        return this.message.type === 'error';
    }
    get isWarning()
    {
        return this.message.type === 'warning';
    }
    get isSuccess()
    {
        return this.message.type === 'success';
    }

    showDetail(event)
    {
        Toast.show({
            label: 'Error Details',            
            message: this.message.msgDetail,
            mode: 'sticky',
            variant: 'error'
        }, this);
    }

    /*
     * Displaying only error message and optionally log error message in event monitoring and Apex error log object
     * @param errors             Error object
     * @param lwcName            Name of LWC that cause error
     * @param lwcMethodName      Name of LWC method that cause error  
     * @param state              Flag to show message
     * @param isLog              Flage to log message in event monitoring and Apex error log object
     * @param timeOut            Duration to show message
     * 
     ------------------------------------------------------------------------------------------------------------------------------
     * @ Change history: 11.12.2024 / Sothea Horn / Create method
     *                   US-0015300 - Generic LWC Exception handling & Application to program participation component
     ------------------------------------------------------------------------------------------------------------------------------*/
    @api showErrorOnly(error, lwcName, lwcMethodName, state, isLog, timeOut) {
        const arrErrors = reduceErrors(error);
        let errMsg = arrErrors.join(", ");
        if (isLog) {
            // Logging error messages in event monitoring for comprehensive tracking
            log (errMsg);
            // Logging exceptions and errors to an Apex error log object with a unique alpha-numeric identifier for each incident
            logErrorLWC({ errorMsg: errMsg, stackTrace:'',  lwcName: lwcName, lwcMethodName: lwcMethodName})
            .then((result) => {
                if (result) {
                    errMsg = errMsg + '(' + result + ')';
                }
                //Display error to user
                this.setMessage({
                    showMessage: state,
                    type: 'error',
                    msg: errMsg,
                    msgDetail: errMsg
                }, state, timeOut);
            })
            .catch(error => {
                console.log('Failed to log error to apex log:' , error);
            });
        } else {
            //Display error to user
            this.setMessage({
                showMessage: state,
                type: 'error',
                msg: errMsg,
                msgDetail: errMsg
            }, state, timeOut);
        }
    }
    
}