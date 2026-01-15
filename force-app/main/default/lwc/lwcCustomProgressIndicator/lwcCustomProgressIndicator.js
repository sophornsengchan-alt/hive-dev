/*********************************************************************************************************************************
@ Component:      CustomProgressIndicator
@ Version:        1.0
@ Author:         Sothea Horn (sohorn@ebay.com)
@ Created Date:   30 Jan 2025
@ Purpose:        US-0016302 - [Tech Debt] Convert CustomProgressIndicator to lwc
----------------------------------------------------------------------------------------------------------------------------------
*********************************************************************************************************************************/
import { LightningElement, api } from 'lwc';

export default class CustomProgressIndicator extends LightningElement {
    @api stages;
    @api currentStage;
    isShowProgress = false;
    connectedCallback() {
        this.showProgress(true);
    }
    showProgress(isShow){
        this.isShowProgress = isShow;
    }
}