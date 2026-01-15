/*********************************************************************************************************************************
@ Component:      dynamicInvokeFlowModal
@ Version:        1.0
@ Author:         Sothea Horn (sothea.horn@gaea-sys.com)
@ Purpose:        Dynamically invoke screen flow as modal in LWC
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 27.11.2025 / Sothea Horn / Create the component / US-0033849 - Step 1 - Seller Overview
*********************************************************************************************************************************/
import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class DynamicInvokeFlowModal extends LightningModal {
    @api header;
    @api flowName;
    @api inputVariables;

    handleStatusChange(event) {
        if (event?.detail?.status === 'FINISHED') {
            this.close();
        }
    }

    handleClose() {
        this.close('return value');
    }
}