import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';


export default class SupportTicketConfirmation extends NavigationMixin(LightningElement)  {
    @api selectedProduct;
    @api isIssueResolved = false;

    handleRedirectToCaseList() {
        console.log('Redirect to Case List');
        this.isIssueResolved = true;
        console.log('Issue Resolved: ' + this.isIssueResolved);
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }

    handleStartScreenFlow() {
        console.log('Redirect to Start Screen Flow');
        this.isIssueResolved = false;
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }
}