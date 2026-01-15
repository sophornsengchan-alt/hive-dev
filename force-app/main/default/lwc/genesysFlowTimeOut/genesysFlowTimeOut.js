/*********************************************************************************************************************************
@Name:         GenesysFlowTimeOut
@Version:      1.0
@Author:       ....
@Purpose:      Delay Genesys Flow Move Before Task Creation  
@date 2025-01-12
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: ../../../???/created the lwc
@               : 01/12/2025 / Vimean Heng / US-0033809 - Genesys - "Contact Verification Process" flow Error
*********************************************************************************************************************************/
import { LightningElement } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import customLabel from 'c/customLabels';

export default class GenesysFlowTimeOut extends LightningElement {

    label = customLabel;
    defaultTimeout = 3000; // Default timeout in milliseconds
    connectedCallback() {
        this.doDelay();
    }
    
    /************************************
    @change history 01/12/2025 / Vimean Heng / US-0033809 - Genesys - "Contact Verification Process" flow Error
    ************************************/
    get timeOut(){
        const timeout = parseInt(this.label.Genesys_Task_TimeOut);
        return !isNaN(timeout) && timeout > 0 ? timeout : this.defaultTimeout;
    }
    /************************************
    @change history 01/12/2025 / Vimean Heng / US-0033809 - Genesys - "Contact Verification Process" flow Error
    ************************************/
    doDelay(){
        setTimeout(() => {
            this.moveToNext();
        }, this.timeOut);
    }
    moveToNext(){
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
}