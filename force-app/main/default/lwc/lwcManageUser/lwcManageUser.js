/*********************************************************************************************************************************
@ Class:          LwcManageUser
@ Version:        1.0
@ Author:         vadhanak voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        US-0010903 - [Add User] Allow DE Deals Users to add others Contacts to the Seller Portal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.02.2022 / vadhanak voun / Created the class.
@                 21.02.2022/ vadhanak voun / US-0011278 - Deactivate/Delete Users by the Seller Admin
*********************************************************************************************************************************/
import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import apexGetContacts from '@salesforce/apex/ManageUserController.getContacts';
import apexSubmitContact from '@salesforce/apex/ManageUserController.apexSubmitContact';
import apexSubmitUser from '@salesforce/apex/ManageUserController.apexSubmitUser';
import apexRemoveContact from '@salesforce/apex/ManageUserController.apexRemoveContact';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

import LabelHeader from '@salesforce/label/c.MgUser_Header';
import Label_step1_Text1 from '@salesforce/label/c.MgUser_Step1_Text1';
import Label_step1_Text2 from '@salesforce/label/c.MgUser_Step1_Text2';
import Label_step1_Text3 from '@salesforce/label/c.MgUser_Step1_Text3';
import Label_step1_Text4 from '@salesforce/label/c.MgUser_Step1_Text4';
import Label_step2_Text1 from '@salesforce/label/c.MgUser_Step2_Text1';
import Label_step3_Text1 from '@salesforce/label/c.MgUser_Step3_Text1';
import Label_step3_Error1 from '@salesforce/label/c.MgUser_Step3_ErrorRequired';
import Label_cancel from '@salesforce/label/c.lwcCancelbtn';
import Label_submit from '@salesforce/label/c.MgUser_submit';
import Label_home from '@salesforce/label/c.MgUser_Home';
import Label_addUser from '@salesforce/label/c.MgUser_addUser';
//import LabelRequired from '@salesforce/label/c.LabelRequired'; //MN-16052023-US-0013623
import LabelRequired from '@salesforce/label/c.Required'; //MN-16052023-US-0013623
import LabelFirstName from '@salesforce/label/c.MgUser_firstName';
import LabelLastName from '@salesforce/label/c.MgUser_lastName';
import LabelEmail from '@salesforce/label/c.MgUser_email';
import Msg_requiredField from '@salesforce/label/c.MgUser_fieldRequired';
import Msg_emailInvalid from '@salesforce/label/c.MgUser_emailInvalid';
import LabelHeaderAddUser from '@salesforce/label/c.MgUser_HeaderAddUser';
import Msg_staticError from '@salesforce/label/c.MgUser_staticError';
import Msg_errorDuplicate from '@salesforce/label/c.MgUser_errorExistingContact';
import Msg_submitSuccess from '@salesforce/label/c.MgUser_submitSuccess';
import Label_Remove from '@salesforce/label/c.MgUser_Remove';
import Label_Confirm from '@salesforce/label/c.MgUser_Confirm';
import Label_ConfirmMSG from '@salesforce/label/c.MgUser_Confirm_MSG';
import Label_Confirm_Success from '@salesforce/label/c.MgUser_Confirm_MSG_Success';
import Label_BackButton from '@salesforce/label/c.BackButton';

export default class LwcManageUser extends LightningElement {

    @api listAllContacts = [];
    @api currentUser = {};
    @api listAllContactRelation = [];
    @api newCont = {};

    @api showStep2Error = false;
    @api submitErrorStatic = false;
    @api submitErrorDupicate = false;
    @api submitFinalError = false;
    @api submitFinalSuccess = false;
    @api currentStep = 1;
    @api selectedAccount = [];
    @api showSpinner = false;
    @api showRemoveConfirm = false;
    @api showRemoveConfirmSuccess = false;
    @api removingContact = {}; 

    Labels = {
        LabelHeader,
        Label_step1_Text1,Label_step1_Text2, Label_step1_Text3, Label_step1_Text4, Label_step2_Text1,Label_step3_Text1,Label_step3_Error1,Label_cancel,Label_submit,Label_home,
        Label_addUser,LabelRequired,LabelFirstName,LabelLastName,LabelEmail,Msg_requiredField,Msg_emailInvalid,LabelHeaderAddUser,Msg_staticError,Msg_errorDuplicate,Msg_submitSuccess,
        Label_Remove,Label_Confirm,Label_Confirm_Success,Label_ConfirmMSG,Label_BackButton
    };

    connectedCallback()
    {
        //console.log("-connectedCallback-");
        this.currentStep = 1;
        this.doGetContacts();
    }   
    
   doGetContacts()
   {
        apexGetContacts()
        .then(result => {
             //console.log("-doGetContacts-",result);
             
            this.listAllContacts = result.listUser;
            this.currentUser = result.curentUser;
            this.listAllContactRelation = result.contRelation;                
                        
        })
        .catch(error => {
        
            console.log("apexGetContacts error",error);
        });
   }
   

    get isSellerAdmin()
    {
        //NK:09/05/2022:US-0011343
        //return this.currentUser && this.currentUser.Contact && (this.currentUser.Contact.RecordType.DeveloperName == 'EBH_DWH' && this.currentUser.Federated_Login__c==false);;
        return this.currentUser && this.currentUser.Contact && (this.currentUser.Federated_Login__c==false);
    }
    get hasSomeContacts()
    {
        return this.listAllContacts != null & this.listAllContacts.length > 0;
    }
    get showCancelButton()
    {
        return (this.currentStep == -1 || this.currentStep ==2 || this.currentStep ==3) ;// || this.submitErrorStatic || this.submitErrorDupicate;
    }
    //show Back or Cancel
    get labelBackCancel()
    {
        if(this.currentStep == -1 && !this.showRemoveConfirm)
        {
            return this.Labels.Label_BackButton;
        }else{
            return this.Labels.Label_cancel;
        }
    }

    get getListContacts()
    {
        return this.listAllContacts;
    }

    get optionAccouunts() {
        let accList = [];
        for(let i=0;i<this.listAllContactRelation.length;i++)
        {           
            accList.push({label:this.listAllContactRelation[i].Account.Name,value:this.listAllContactRelation[i].AccountId});
        }
        return accList;
    }
    handleSelectAccount(event) {
        let selectedOption = event.detail.value;
        //console.log('Option selected with value: ' + selectedOption);
        this.selectedAccount = selectedOption;
        this.showStep2Error = false;
    }
    handleInputContactChange(event)
    {
        //let inputId = event.detail.value;
        let inputId = event.target.dataset.id;

        let conFirst = this.template.querySelector('[data-id="input_firstname"]');
        let contLast = this.template.querySelector('[data-id="input_lastname"]');
        let contEmail = this.template.querySelector('[data-id="input_email"]');
        this.newCont.firstName = conFirst.value;
        this.newCont.lastName = contLast.value;
        this.newCont.email = contEmail.value;

        //console.log("inputId",inputId);

        if(inputId=="input_firstname")
        {
            conFirst.reportValidity();
        }else if(inputId=="input_lastname")
        {
            contLast.reportValidity();
        }else if(inputId=="input_email")
        {
            contEmail.reportValidity();
        }
        
    }

    get isStep1()
    {
        return this.currentStep == 1;
    }
    get isStep2()
    {
        return this.currentStep == 2;
    }
    get isStep3()
    {
        return this.currentStep == 3;
    }
    //next click step1
    addUserClick()
    {
        this.currentStep = 2;
        let conFirst = this.template.querySelector('[data-id="input_firstname"]');        
        
    }
    //contact detail input step2
    addUserNextClick()
    {         
        let contactInputs = this.template.querySelectorAll('[data-name="contact_info"]');
        let hasError = false;
        for(let i=0;i<contactInputs.length;i++)
        {
            if(!contactInputs[i].reportValidity())
            {
                contactInputs[i].checkValidity();
                hasError = true;
            }
        }
        //console.log("contactInputs hasError: ",hasError,contactInputs.length);
        if(hasError)return;
        
        //ok: immediate summit or show step 3 (account selection)
         
        if(this.listAllContactRelation.length > 1)
        {
            this.currentStep = 3;   // show next step account selection
        }
        /* //MN-24042023-US-0013591-Disabled Step 3
        else { //MN-10042023-US-0012094 - Fixed missing "else" that caused problem with step-3
            // submit now
            this.handleSubmit(null);

            // this.currentStep = 3; // test
        }
        */

        this.handleSubmit(null);
    }
    //final step after account selection
    submitUserClick()
    {
        this.showStep2Error = false;        
        
        if(this.selectedAccount=="" || this.selectedAccount==null || (this.selectedAccount !=null && this.selectedAccount.length <=0))
        {
            this.showStep2Error = true;
            let accBox = this.template.querySelector('[data-id="boxAccounts"]');
            accBox.classList.add('redb-box');

            setTimeout(() => {
                accBox.classList.remove('redb-box');
            }, 2000);

            let accChks = this.template.querySelectorAll('[data-name="selectAccount"]');
             //console.log("--accChks: ",accChks.length);
            for(let i=0;i<accChks.length;i++)
            {
                if(!accChks[i].reportValidity())
                {
                    accChks[i].checkValidity();                     
                }
            }

            return;
        }

        console.log('--selectedAccount',this.selectedAccount);

        this.handleSubmit(this.selectedAccount);
    }

    gohomeClick()
    {
        window.location.href = "/s/";
        this.submitErrorStatic = false;
    }
    goCancelClick()
    {
        this.currentStep = 1;
        this.submitFinalSuccess = false;
        this.submitFinalError = false;
        this.submitErrorStatic = false;
        this.submitErrorDupicate = false;
        this.showRemoveConfirmSuccess = false;
        this.showRemoveConfirm = false;

        this.newCont.firstName = null;
        this.newCont.lastName = null;
        this.newCont.email = null;
    }
    // get hasAnyMsg()
    // {
    //     return (this.submitFinalSuccess || this.submitErrorStatic || this.submitErrorDupicate);
    // }
    get getSuccessMessage()
    {        
        return (this.Labels.Msg_submitSuccess+"").replace('[First_Name]',this.newCont.firstName+'').replace('[Last_Name]',this.newCont.lastName+'');        
    }

    handleSubmit(selectedAccounts)
    {   this.showSpinner = true;

        this.submitFinalSuccess = false;
        this.submitFinalError = false;
        this.submitErrorStatic = false;
        this.submitErrorDupicate = false;

         //console.log("--contact: ",this.newCont);
        apexSubmitContact({cont: this.newCont, listAccIds:selectedAccounts})
            .then(result => {
                // console.log("submit result",result);
                 if(result.status=="ok")
                 {
                    this.newCont.Id = result.conId+"";
                    let listAccContIds = [];
                    for(let i=0;i<result.listAccCont.length;i++)
                    {
                        listAccContIds.push(result.listAccCont[i].Id);
                    }

                    //sucess then insert User (avoid mixed-dml)
                    this.handleSecondTransaction_User(this.newCont,listAccContIds);

                    //test only here
                    // this.submitFinalSuccess= true;
                    // this.currentStep = -1;
                    // this.showSpinner = false;
                    
                 }else if(result.status=="ko" && result.error=="duplicate")
                 {                    
                    this.currentStep = -1;
                    this.submitErrorDupicate = true;
                    this.showSpinner = false;
                    console.log("submit result0",result);
                 }else
                 {
                    this.submitErrorStatic = true;
                    this.currentStep = -1;
                    this.showSpinner = false;
                    console.log("submit result1",result);
                 }
            })
            .catch(error => {
               // this.error = error;
                this.submitErrorStatic = true;
                this.currentStep = -1;
                this.showSpinner = false;
                console.log("submit error",error);
            });
    }

    handleSecondTransaction_User(cont,listAccContRelation)
    {
        apexSubmitUser({contMap: cont, listAccContId:listAccContRelation})
        .then(resultUser => {
             //console.log("-apexSubmitUser result",resultUser);
             if(resultUser.status=="ok")
             {
                console.log("--final submit ok. user created--");
                this.submitFinalSuccess= true;
                this.currentStep = -1;
                // this.newCont.firstName = null;
                // this.newCont.lastName = null;
                // this.newCont.email = null;
             }else
             {               
                console.log("apexSubmitUser error",resultUser);
                this.submitErrorStatic = true;
                this.submitFinalError = true;
                this.currentStep = -1;
             }
            
             this.showSpinner = false;
             this.doGetContacts();
        })
        .catch(error => {
           // this.error = error;
            this.submitErrorStatic = true;
            this.currentStep = -1;
            this.submitFinalError = true;
            this.showSpinner = false;
            console.log("handleSecondTransaction_User error",error);
        });
        
    }

    handleRemove(event)
    {        
        this.doRemoveContact('contact',this.removingContact.contId,this.removingContact.usrId);        
    }

    handleRemoveConfirm(event)
    {
        //console.log("event-",event);
        let usrId = event.target.dataset.usrid;
        let contId = event.target.dataset.conid;

        //console.log("usrId - contId",usrId,contId);

        this.currentStep = -1;
        this.showRemoveConfirm = true;        
        
        this.removingContact.usrId = usrId;
        this.removingContact.contId = contId;

        event.preventDefault();

    }
    
    doRemoveContact(targetObject,contId,usrId)
    {
        this.showSpinner = true;

        apexRemoveContact({targetObject: targetObject , contId:contId , usrId:usrId })
        .then(result => {
           
            if(result.status=="ok" && targetObject=="contact")
            {
                console.log("--contact-done-");
                 //then remove user
                this.doRemoveContact('user',contId,usrId);
                return;

            }else if(result.status=="ok" && targetObject=="user")
            {
                console.log("--usr-done-");
                //final success
                this.showRemoveConfirmSuccess = true;
                
            }
            else
            {               
                console.log("doRemoveContact error",targetObject,result);
                this.submitErrorStatic = true;
                //this.submitFinalError = true;
                
            }

            this.currentStep = -1;
            this.showRemoveConfirm = false; 
                        
            this.showSpinner = false;

            this.doGetContacts();
            
        })
        .catch(error => {
           // this.error = error;
            this.submitErrorStatic = true;
            this.currentStep = -1;
            this.submitFinalError = true;
            this.showSpinner = false;
            console.log("handleSecondTransaction_User error",error);
        });
    }
}