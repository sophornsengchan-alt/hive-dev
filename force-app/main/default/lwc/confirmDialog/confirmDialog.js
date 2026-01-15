import { LightningElement, api } from 'lwc';

export default class ConfirmDialog extends LightningElement {
    //isShow is a property to show or hide the dialog,must be changed by the parent component
    @api isShow = false;
    //title is a header of the dialog,can be changed by the parent component
    @api title = 'Confirmation';
    //message is a body of the dialog,can be changed by the parent component
    @api message = 'Are you sure?';
    //cancelLabel is a label of the cancel button,can be changed by the parent component
    @api cancelLabel = 'Cancel';
    //confirmLabel is a label of the confirm button,can be changed by the parent component
    @api confirmLabel = 'Confirm';
    //TH:US-0016358
    @api isShowConfirm = false;

    handleClose(e){
        this.fireAction('cancel');
    }
    handleConfirm(e){
        this.fireAction('confirm');
    }
    fireAction(act){
        //if we don't use dispatchEvent the component won't be able to rerender
        const event = new CustomEvent(act, {
            detail: { 'status': act},
            bubbles: true,
            composed: true
        });
        // Dispatch the event
        this.dispatchEvent(event);
    }
}