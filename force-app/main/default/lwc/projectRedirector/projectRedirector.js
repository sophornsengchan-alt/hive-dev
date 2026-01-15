/*********************************************************************************************************************************
@ Component:      ProjectRedirector
@ Version:        1.0
@ Author:         Sothea Horn (sohorn@ebay.com)
@ Created Date:   25 Nov 2024
@ Purpose:        US-0015912 - Remove ability to create new project for BD and MIS
----------------------------------------------------------------------------------------------------------------------------------
*********************************************************************************************************************************/
import { LightningElement, wire, track} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import validateProject from '@salesforce/apex/ProjectRedirectorController.validateProject';
import PROJECT_OBJECT from '@salesforce/schema/EBH_Project__c';

export default class LwcProjectRedirector extends NavigationMixin(LightningElement) { 
    @track selectedRecordTypeId;

    // Get current page reference to get selected record type ID
    @wire(CurrentPageReference)
    wiredCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.selectedRecordTypeId = currentPageReference.state?.recordTypeId;
        }
        //Show recent list view to advoid blank page when open standard new project page
        this.navigateToProjectRecentListView();
     }
    
    // Check if the invoke user has permission to create eBay Business Developmen project manually (clicking New butoon from project object list view)
    //If yes, retrict user from creating a project and show error message.
    @wire(validateProject, { recordTypeId: '$selectedRecordTypeId'})
    wiredValidateProject({data, error}) {
        if (data) {
            if (data.isSuccess) {
                this.navigateToNewProjectPage();
            } else {
                console.log('Error message: ', data.msg);
                const event = new ShowToastEvent({
                    title: data.msgTitle,
                    message: data.msg,
                    variant: 'Error', 
                    mode: 'dismissible',
                    duration: '5000'
                });
                // Dispatch the event to show the toast
                this.dispatchEvent(event);
            }
        } else if (error) {
            console.log('Error:', error);
        } 
    };

    // Method for navigating to standard new project page with selected record type
    navigateToNewProjectPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: PROJECT_OBJECT.objectApiName,
                actionName: 'new'
            },
            state: {
                recordTypeId: this.selectedRecordTypeId,
                nooverride: '1'
            }
        });
    };

    // Method for navigating to project recent list view
    navigateToProjectRecentListView() {
        this[NavigationMixin.Navigate]({
          type: "standard__objectPage",
          attributes: {
            objectApiName: PROJECT_OBJECT.objectApiName,
            actionName: "list",
          },
          state: {
            filterName: "Recent",
          },
        });
    }

}