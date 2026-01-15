/*********************************************************************************************************************************
@ Class:          lwcProgressIndicator
@ Version:        1.0
@ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:        US-0012877
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 03-11-2022 / Sambath Seng / Created the class.
*********************************************************************************************************************************/
import { LightningElement,api } from 'lwc';

import upload from '@salesforce/label/c.Upload_btn';
import preview from '@salesforce/label/c.Preview_btn';
import submit from '@salesforce/label/c.Submit_btn';

//MN-23112023-US-0014106-For ExcelImporterV2
import lblStep1 from '@salesforce/label/c.ExcelImporter_V2_Step1';
import lblStep2 from '@salesforce/label/c.ExcelImporter_V2_Step2';
import lblStep3 from '@salesforce/label/c.ExcelImporter_V2_Step3';
import lblStep4 from '@salesforce/label/c.ExcelImporter_V2_Step4';

export default class LwcProgressIndicator extends LightningElement {

    Labels = {upload,preview,submit, lblStep1, lblStep2, lblStep3, lblStep4};

    currentActive;

    @api
    isExcelImporterV2 = false;

    @api
    get currentStep() {
    return this._currentStep;
    }
    
    set currentStep(value) {
        this.setAttribute('currentStep', value);
        this.currentActive = value;
        this.setCurrentStep();
    }

    setCurrentStep(){
        var steps = this.template.querySelectorAll('.stepper-item');

        if (this.isExcelImporterV2) { //For ExcelImporterV2

            steps.forEach((step,idx) => {


                var cur_step = idx + 1;

                if (cur_step == this.currentActive) {
                    step.classList.add('current-step');
                    step.classList.add('active-half');
                    step.classList.remove('active-notrans');
                }
                else if (cur_step < this.currentActive) {
                    if(step.classList.contains('current-step')) {
                        step.classList.remove('current-step');
                    }
                    if(step.classList.contains('active-half')) {
                        step.classList.remove('active-half');
                    }
                    step.classList.add('active-notrans');
                } else {
                    step.classList.remove('active-notrans');
                    if(step.classList.contains('current-step')) {
                        step.classList.remove('current-step');
                    }
                    if(step.classList.contains('active-half')) {
                        step.classList.remove('active-half');
                    }
                }
 
            });

        }else {

            steps.forEach((step,idx) => {
                if(idx < this.currentActive){
                    step.classList.add('active');
                } else {
                    step.classList.remove('active');
                }
            });

        }
        
    }
}