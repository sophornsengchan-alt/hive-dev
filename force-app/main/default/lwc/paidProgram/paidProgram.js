/*********************************************************************************************************************************
@ Component:    PaidProgram
@ Version:      1.0
@ Author:       Sophal Noch
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 07.01.2026 / Sophal Noch US-0033990 - Paid Program Component
*********************************************************************************************************************************/
import { wire, api, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import initData from '@salesforce/apex/PaidProgramController.initData';

export default class PaidProgram extends NavigationMixin(LightningElement) {
    @api sellerId;

    showSpinner = true;
    subscription = null;
    showPageContent = false;

    _wireInitData;
    @wire(initData, {
        sellerId: '$sellerId'
    })
    wireInitData(result) {
        console.log('nsp: result.data ', result.data);
        if (result?.data?.status === 'ok') {
            this._wireInitData = result;
            this.showPageContent = true
            this.showSpinner = false;
        }else if(result?.data?.status === 'ko'){
             this.showSpinner = false;
        }
    }
}