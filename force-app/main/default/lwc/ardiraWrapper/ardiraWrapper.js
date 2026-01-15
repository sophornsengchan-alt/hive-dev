/*********************************************************************************************************************************
@ Class:        ArdiraWrapper
@ Author:       vadhanak voun 
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 26.06.2025 / vadhanak voun / US-0012289 - Prologue flow does not open in Partner Community (GCX)
*********************************************************************************************************************************/
import { LightningElement,api } from 'lwc';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';
import { RefreshEvent } from 'lightning/refresh';
export default class ArdiraWrapper extends LightningElement {

 @api surveyId;
 @api logicalId;
 @api targetId

    onSubmitButtonClick(event) 
    {
        // Handle the submit button click event
        // console.log('Submit button clicked:', event.detail);
        // You can add additional logic here, such as navigating to a different page or showing a success message
         
       
        this.dispatchEvent( new FlowNavigationFinishEvent());
        setTimeout(() => {
            this.dispatchEvent(new RefreshEvent());
        }, 500);
    }
}