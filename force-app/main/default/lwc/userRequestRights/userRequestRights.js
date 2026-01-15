/*********************************************************************************************************************************
@ Component:    UserRequestRights
@ Version:      1.0
@ Author:       vadhanak voun
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.05.2025 / US-0012480 - 2 Request Elevated Privileges Process - UI
@               : 23.07.2025 /  US-0033166 - "Ad Hoc Elevated Access" Fixes
*********************************************************************************************************************************/
import { LightningElement,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { CurrentPageReference } from 'lightning/navigation';
// import userHasBypassRule from '@salesforce/customPermission/Bypass_Validation_Rule';
import apexInit from '@salesforce/apex/UserRequestRightsController.apexInit';
import submitRequest from '@salesforce/apex/UserRequestRightsController.submitRequest';
import CustomLabels from 'c/customLabels';

export default class UserRequestRights extends LightningElement {
    @api recordId;
    showModal;
    BYPASS_TYPE_FULL ="Full System Admin";
    BYPASS_TYPE_VR = "Enable Bypass";
    // hasPermissionBypass = false;
    bypassVRVisible = false;
    bypassFullAccessVisible = false;
    selectedObject = [];
    txtReason = '';
    metadata = null;
    objectList = [];
    toggleBypassVR = false  ;
    toggleBypassFlow = false  ;
    // toggleBypassWF = false  ;
    toggleBypassTrigger = false  ;
    selectedDuration = null;

    toggleBypassBoxClass ="my-box";
    durationClass = "my-box";

    userByPass ={userId:"",byPassType:"",objects:"",duration:"",reason:"",bypassFlow:false,bypassVR:false,bypassTrigger:false};

    usrHasFullHiveAdminAccess = false;
    usrHasHiveBypassAccess = false;
    usrIsFullAdmin = false;
    isSpinning = false;
    labels = {UserRights_Bypass_Info: CustomLabels.UserRights_Bypass_Info,
             UserRights_FullAdmin_Info: CustomLabels.UserRights_FullAdmin_Info,
            UserRights_Option_Info: CustomLabels.UserRights_Option_Info,
            UserRights_Err_No_Permission: CustomLabels.UserRights_Err_No_Permission};

    connectedCallback() 
    {
        // this.hasPermissionBypass = userHasBypassRule;
        this.recordId = this.getParamValue(window.location.href,'User');
       
        // console.log('recordId:', this.recordId);
        // console.log('hasPermissionBypass:', this.hasPermissionBypass);
        this.doInit();
    }
    

    doInit()
    {
        apexInit()
        .then(result => {
            // console.log('init result:', result);
            this.metadata = result.listMeta && result.listMeta.length > 0 ? result.listMeta[0] : null;
            this.userByPass.userId = this.recordId;

            //NK:23/07/2025:US-0033166
            this.usrHasFullHiveAdminAccess =  result.hasFullHiveAdminAccess;
            this.usrHasHiveBypassAccess =  result.hasHiveBypassAccess;
            this.usrIsFullAdmin =  result.isFullAdmin;

            this.processMetadata();
        })
        .catch(error => {
            console.error('Init Error:', error);
        });
    }
    processMetadata()
    {
        if(this.metadata && this.metadata.Available_Bypass_Objects__c)
        {
             this.objectList = JSON.parse(this.metadata.Available_Bypass_Objects__c);
        }
    }

    handleRequestAccessClick() 
    {
        // console.log("clicked!",this.recordId);
        this.openModal();
    }
    //const url = "https://hive--dev.sandbox.lightning.force.com/lightning/r/User/0053u000002puEBAAY/view";
    //console.log(getParamValue(url, "User")); // Output: 0053u000002puEBAAY
    getParamValue(url, paramName)
    {
        const urlObj = new URL(url);
        const params = urlObj.pathname.split('/');
        return params.includes(paramName) ? params[params.indexOf(paramName) + 1] : null;
    }

    openModal()
    {
        this.showModal = true;
        // console.log("this.bypassFullAccessVisible: ",this.bypassFullAccessVisible);

        setTimeout(() => {
            this.template.querySelector('lightning-input[data-id="toggleFull"]').checked  = this.bypassFullAccessVisible;
            this.template.querySelector('lightning-input[data-id="toggleBypass"]').checked  = this.bypassVRVisible;
        }, 100);

        
    }
    closeModal()
    {
        this.showModal = false;
    }

    toogleClick(event)
    {
        const target = event.target;
        const isChecked = target.checked;
        const name = target.name;
        // console.log('isChecked:', isChecked);
        // console.log('name:', name);
        if (name === 'toggleBypass') 
        {
            this.userByPass.byPassType = this.BYPASS_TYPE_VR;
            this.bypassVRVisible = isChecked;
            this.bypassFullAccessVisible = false;
            this.template.querySelector('lightning-input[data-id="toggleFull"]').checked  = false;

        } 
        else if (name === 'toggleFull') 
        {
            this.userByPass.byPassType = this.BYPASS_TYPE_FULL;
            this.bypassFullAccessVisible = isChecked;
            this.bypassVRVisible = false;
            this.template.querySelector('lightning-input[data-id="toggleBypass"]').checked  = false;
            
        }
    }     
 
    // get selected() {
    //     return this._selected.length ? this._selected : 'none';
    // }

    handleObjectChange(e) {
        // console.log('e.detail.value:', e.detail.value);
        // console.log('json:', JSON.stringify(e.detail.value));
        this.selectedObject = e.detail.value;
    }

    get durationBypassVR() {
        return [
            { label: '30minutes', value: '30' },
            { label: '1hour', value: '60' },
            { label: '3hour', value: '180' },
            { label: '8hour', value: '480' }
        ];
    }

    assignAllValues()
    {  
        this.userByPass.byPassType  = null;
        if(this.bypassFullAccessVisible)
        {
           this.userByPass.byPassType = this.BYPASS_TYPE_FULL;

        }else if(this.bypassVRVisible)
        {
            this.userByPass.byPassType = this.BYPASS_TYPE_VR;
            this.userByPass.objects = this.selectedObject? this.selectedObject.join(',') : "";        
            // this.userByPass.bypassVR = this.template.querySelector('lightning-input[data-id="bypassVR"]').checked;
            // this.userByPass.bypassFlow = this.template.querySelector('lightning-input[data-id="bypassFlow"]').checked;
            // this.userByPass.bypassWF = this.template.querySelector('lightning-input[data-id="bypassWF"]').checked;
            // this.userByPass.bypassTrigger = this.template.querySelector('lightning-input[data-id="bypassTrigger"]').checked;
        }

        if(this.userByPass.byPassType===null)
        {
            return;
        }

        this.userByPass.duration = this.template.querySelector('lightning-radio-group[data-id="duration"]').value;
        this.userByPass.reason = this.template.querySelector('lightning-textarea[data-id="reason"]').value;

       
    }
    validatePreSumit()
    {
        this.assignAllValues();
        if(this.userByPass.byPassType===null)
        {
            return false;
        }
        let allValid = true;
        if(this.userByPass.byPassType === this.BYPASS_TYPE_VR)
        {
            if(this.userByPass.objects === null || this.userByPass.objects === "" ||  this.userByPass.objects ===undefined)
            {
                allValid = false;
                this.template.querySelector('lightning-dual-listbox[data-id="dlbObject"]').reportValidity();
            }
            if(this.userByPass.bypassFlow === false && this.userByPass.bypassTrigger === false && this.userByPass.bypassVR === false)
            {
                allValid = false;
            }
        }
        
    
        if(this.userByPass.reason === null || this.userByPass.reason === "" || this.userByPass.reason === undefined)
        {
            allValid = false;
            this.template.querySelector('lightning-textarea[data-id="reason"]').reportValidity();
                
        }
        if(this.userByPass.duration === null || this.userByPass.duration === "" || this.userByPass.duration === undefined)
        {
            allValid = false;
            this.template.querySelector('lightning-radio-group[data-id="duration"]').reportValidity();
        }

        this.resetToggleBypassBoxClass();
        // this.resetDurationClass();


        return allValid;
    }

    handleSubmit()
    {
         console.log('userByPass:',this.userByPass);

        if(!this.validatePreSumit())
        {
            console.log('validation failed - exiting');
            return; 
        }

        this.setSpinner(true);
        submitRequest({requestData:this.userByPass})
        .then(result => {
            // console.log('submitRequest result:', result);
            if(result.status==="ok")
            {
                console.log('ticketId:', result.ticketId); 
                this.closeModal();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Request submitted successfully',
                        variant: 'success',
                    }),
                );
            }else
            {
                console.error('submitRequest Error:', result);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: this.labels.UserRights_Err_No_Permission,
                        variant: 'error',
                    }),
                );
            }
            this.setSpinner(false);

        })
        .catch(error => {
            this.setSpinner(false);
            console.error('submitRequest Error:', error);
           this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error SubmitRequest',
                    message: this.labels.UserRights_Err_No_Permission,
                    variant: 'error',
                }),
            );
        });

    }
 

    handleToggleBypassChange(event)
    {
         
        const target = event.target;
        // console.log('target:',target);
         const name = target.name;
        // console.log('name:',name);
        const isChecked = target.checked;
       
        // console.log('isChecked:', isChecked +" "+ name);

        if(name==="tbp_flow") 
        { 
            this.toggleBypassFlow = isChecked;
            this.userByPass.bypassFlow = isChecked; 
        }else if(name==="tbp_tgr")
        {
            this.toggleBypassTrigger = isChecked;
            this.userByPass.bypassTrigger = isChecked;
        }else if(name==="tbp_vr")
        {
            this.toggleBypassVR = isChecked;
            this.userByPass.bypassVR = isChecked;
        }
       
        
        this.resetToggleBypassBoxClass();

        // console.log('userByPass00:',this.userByPass);
    }

    resetToggleBypassBoxClass()
    {
        if(!this.toggleBypassVR && !this.toggleBypassFlow &&   !this.toggleBypassTrigger)
        {
            this.toggleBypassBoxClass= "my-error-box";
        }else
        {
            this.toggleBypassBoxClass= "my-box";
        }
         
    }

    //if one of th e toggle is checked, then show the toggle box
    get usrToggle()
    {
        return this.bypassVRVisible || this.bypassFullAccessVisible;
    }

    get hasBoth()
    {
        return (this.usrHasFullHiveAdminAccess && this.usrHasHiveBypassAccess) ||   this.usrIsFullAdmin;
    }

    get layoutSizeTop()
    {
        if(this.hasNoAccess || (!(this.usrHasFullHiveAdminAccess && this.usrHasHiveBypassAccess) && !this.usrIsFullAdmin))
        {
            return "12";
        }
        return  "6";
    }

    get hasNoAccess()
    {
        return !this.usrHasFullHiveAdminAccess && !this.usrHasHiveBypassAccess && !this.usrIsFullAdmin;
    }

    get hasFullHiveAdminAccess(){
        return this.usrHasFullHiveAdminAccess  ||   this.usrIsFullAdmin;
    }
    
    get hasHiveBypassAccess(){
        return this.usrHasHiveBypassAccess ||   this.usrIsFullAdmin;
    }
    
    setSpinner(isSpinning)
    {
        this.isSpinning = isSpinning;       
    }
}