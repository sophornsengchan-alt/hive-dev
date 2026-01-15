import { LightningElement,api } from 'lwc';

export default class LwcLoading extends LightningElement {

    // showProgress;
    @api message;

    // @api setMessage(msg)
    // {
    //     this.message = msg;
    //     // this.showProgress=true;
    // }
    // @api hideSpinner()
    // {
    //     this.showProgress=false;
    // }

    get msg()
    {
        return this.message;
    }
}