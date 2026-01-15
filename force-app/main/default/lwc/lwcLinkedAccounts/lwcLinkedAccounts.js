/*********************************************************************************************************************************
@ Class:          lwcLinkedAccounts
@ Version:        1.0
@ Author:         mony nou (mony.nou@gaea-sys.com)
@ Purpose:        US-0011080 - Linked Accounts Landing Page
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.04.2022 / mony nou / Created the class.
*********************************************************************************************************************************/

import { LightningElement, api, track, wire } from 'lwc';
import apexGetContacts from '@salesforce/apex/ManageUserController.getContacts';
import apexGetAccounts from '@salesforce/apex/LinkedAccountsController.getAccounts';
import apexGetEbaySessionId from '@salesforce/apex/LinkedAccountsController.apexGetEbaySessionId';
import apexEbayConfirmIdentity from '@salesforce/apex/LinkedAccountsController.apexEbayConfirmIdentity';
import apexManageGroup from '@salesforce/apex/LinkedAccountsController.apexManageGroup';

import LabelHeader from '@salesforce/label/c.LinkedAccounts_Header';
import Label_Text1 from '@salesforce/label/c.LinkedAccounts_Text1';
import Label_Text2 from '@salesforce/label/c.LinkedAccounts_Text2';
import Label_Text3 from '@salesforce/label/c.LinkedAccounts_Text3';
import Label_Unlink from '@salesforce/label/c.LinkedAccounts_Unlink';
import Label_Back from '@salesforce/label/c.LinkedAccounts_Back';
import Label_AddAcc from '@salesforce/label/c.LinkedAccounts_AddAccount';
import Label_AccountNotExist_MSG from '@salesforce/label/c.AccountNotExist_MSG';
import Label_Cancel from '@salesforce/label/c.lwcCancelbtn';
import Label_BackButton from '@salesforce/label/c.BackButton';
import Text_Step1_text1 from '@salesforce/label/c.LinkedAccounts_Step1_text1';
import Text_Step1_text2 from '@salesforce/label/c.LinkedAccounts_Step1_text2';
import Msg_requiredField from '@salesforce/label/c.MgUser_fieldRequired';
import Label_GroupName from '@salesforce/label/c.LinkedAccounts_Step1_lblGroupName';
//import LabelRequired from '@salesforce/label/c.LabelRequired'; //MN-16052023-US-0013623
import LabelRequired from '@salesforce/label/c.Required'; //MN-16052023-US-0013623
import LabelConfirm from '@salesforce/label/c.LinkedAccounts_Confirm';
import Text_Step2_Success from '@salesforce/label/c.LinkedAccounts_Success_msg';
import Text_Error_static from '@salesforce/label/c.LinkedAccounts_Error_static';
import Text_Step3_text2 from '@salesforce/label/c.LinkedAccounts_step3_text2';
import LabelConfirm_short from '@salesforce/label/c.MgUser_Confirm';
import Text_Step4_text1 from '@salesforce/label/c.LinkedAccounts_Step4_text1';
import Text_Step5_text1 from '@salesforce/label/c.LinkedAccounts_Step5_text1';
import Text_Step51_text1 from '@salesforce/label/c.LinkedAccounts_Step51_text1';
import Label_AdminAccount from '@salesforce/label/c.LinkedAccounts_Label_AdminAccount';
import LinkedAccounts_Label_SPGroup_Name from '@salesforce/label/c.LinkedAccounts_Label_SPGroup_Name';
import SEP_Domain_DE from '@salesforce/label/c.SEP_Domain_DE'; //MN-05062024-US-0015298

import Label_Text4 from '@salesforce/label/c.LinkedAccounts_Text4';
import Label_Text5 from '@salesforce/label/c.LinkedAccounts_Text5';
import Label_Text6 from '@salesforce/label/c.LinkedAccounts_Text6';
import Label_Text7 from '@salesforce/label/c.LinkedAccounts_Text7';

import apexRemoveLinkedAccount from '@salesforce/apex/LinkedAccountsController.removeLinkedAccount';
import apexSidebarMetadata from '@salesforce/apex/dynamicCardBannerController.sidebarMetadata';
import userId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import SPMAINDOMAIN_FIELD from '@salesforce/schema/User.SPMainDomain__c'; //MN-05062024-US-0015298
import {getFieldValue, getRecord} from 'lightning/uiRecordApi';

export default class LwcLinkedAccounts extends LightningElement {

    // @api listAllContacts = [];
    @api listAllContactRelation = [];
    @api currentUser = {};
    
    @api ebayLinkingSellerName;
    @api hiveExist = false;
    @api newGroupName="";
    @api slaveAccountId;

    @api selectedAccount = [];
    @api showSpinner = false;
    @api showUnlinkConfirm = false;
    @api unlinkAccount = {};
    @api enableUnlink = false;

    @api mainGroupId="";
    @api mainGroupName="";
    @api mainAccName="";
    @api mainAccId="";
    @api slaveHasGroup = "";
    @api slaveGroupName="";
    @api slaveGroupId="";
 
    @api step = -1;

    @api errorUnlinkRedirectUrl = "";

    Labels = {
        LabelHeader, Label_Text1, Label_Unlink, Label_Text2, Label_Text3, Label_Back, Label_AddAcc,Label_AccountNotExist_MSG,Label_Cancel,Label_BackButton,
        Text_Step1_text1,Text_Step1_text2,Msg_requiredField,Label_GroupName,LabelRequired,LabelConfirm,Text_Step2_Success,Text_Error_static,Text_Step3_text2,
        LabelConfirm_short,Text_Step4_text1,Text_Step5_text1,Label_AdminAccount,LinkedAccounts_Label_SPGroup_Name,
        Label_Text4, Label_Text5, Label_Text6, Label_Text7,Text_Step51_text1, SEP_Domain_DE
        
    };

    connectedCallback() {
        this.validateLinkAccountCallback();
        // this.doGetContacts();
        this.doGetAccounts();
    } 

    doGetContacts() {

        apexGetContacts()
        .then(result => {
            //  console.log("-doGetContacts-",result);
             
            // this.listAllContacts = result.listUser;
            this.currentUser = result.curentUser;
            this.listAllContactRelation = result.contRelation;            
                        
        })
        .catch(error => {
        
            console.log("apexGetContacts error",error);
        });
   }

   @wire(getRecord, {recordId: userId, fields: [PROFILE_NAME_FIELD, SPMAINDOMAIN_FIELD]}) //MN-05062024-US-0015298: Added SPMainDomain__c
   getUser({error, data}){
       if(data){
           
            //var profileName = getFieldValue(data, PROFILE_NAME_FIELD); //MN-05062024-US-0015298: No longer use Profile Name
           //var region = profileName == 'DE - Seller Portal' ? 'DE' : ''; //MN-05062024-US-0015298: No longer use Profile Name

           var domain = getFieldValue(data, SPMAINDOMAIN_FIELD); //MN-05062024-US-0015298: Use SP Main Domain instead of Profile Name
           var region = domain == this.Labels.SEP_Domain_DE ? 'DE' : ''; //MN-05062024-US-0015298: Use SP Main Domain instead of Profile Name

           apexSidebarMetadata({region: region, feature: 'Linked Accounts'})
           .then(result => {
               if(result && result.length > 0) {
                    this.errorUnlinkRedirectUrl = result[0].redirect_url__c;
               }
           })
           .catch(error => {
               console.log("apexSidebarMetadata error",error);
           });
       }
   }

   doGetAccounts() {

        apexGetAccounts()
        .then(result => {
            //console.log("-doGetAccounts-",result);
            this.currentUser = result.curentUser;
            this.listAllContactRelation = result.accRelation;
            this.enableUnlink = (this.listAllContactRelation && this.listAllContactRelation.length > 1); //Sophal 10-05-2022 US-0011156
            this.mainGroupId = result.mainGroupId;
            this.mainGroupName = result.mainGroupName;         
                        
        })
        .catch(error => {
        
            console.log("apexGetAccounts error",error);
        });
    }

    get getListAccounts() {
        return this.listAllContactRelation;
        /*
        let accList = [];
        for(let i=0;i<this.listAllContactRelation.length;i++)
        {           
            accList.push({label:this.listAllContactRelation[i].Account.Name,value:this.listAllContactRelation[i].AccountId});
        }
        return accList;
        */
    }
    get mainHasGroup()
    {
        return this.mainGroupId != "" && this.mainGroupId !=null;
    }
    get text_Step1_text2()
    {
        return this.Labels.Text_Step1_text2.replaceAll("{!Account_B}",this.ebayLinkingSellerName).replaceAll("{!Account_A}",this.mainAccName);
    }
    get text_label_group_main_name()
    {
        return this.Labels.LinkedAccounts_Label_SPGroup_Name.replaceAll("{!Group_A}",this.mainGroupName);
    }
    get text_Step1_text1()
    { 
        return this.Labels.Text_Step1_text1.replaceAll("{!Account_B}",this.ebayLinkingSellerName).replaceAll("{!Account_A}",this.mainAccName);
    }
    get text_Step5_text1()
    {
        return this.Labels.Text_Step5_text1.replaceAll("{!Account_B}",this.ebayLinkingSellerName).replaceAll("{!Group_A}",this.mainGroupName);
    }
    get text_Step51_text1()
    {
        return this.Labels.Text_Step51_text1.replaceAll("{!Account_B}",this.ebayLinkingSellerName);
    }
    
    //NK:21/12/2022:US-0012914: added: {!Account_A} 
    get text_Step4_text1()
    {
        return this.Labels.Text_Step4_text1.replaceAll("{!Account_B}",this.ebayLinkingSellerName).replaceAll("{!Group_A}",this.mainGroupName).replaceAll("{!Account_A}",this.mainAccName); 
    }
    get text_Step3_text2()
    {
        return this.Labels.Text_Step3_text2.replaceAll("{!Account_B}",this.ebayLinkingSellerName).replaceAll("{!Group_A}",this.mainGroupName);
    }
    get hasSomeAccounts()
    {
        return this.listAllContactRelation != null & this.listAllContactRelation.length > 0;
    }
    get label_text7()
    {
        return this.Labels.Label_Text7.replace("href=\"#\"", "href=\""+this.errorUnlinkRedirectUrl+"\"");
    }
    get label_text4()
    {
        return this.Labels.Label_Text4.replaceAll("{!Group_A}",this.mainGroupName);
    }

    handleUnlinkConfirm(event)
    {
        //Sophal 10-05-2022 US-0011156
        event.preventDefault();
        let accContId = event.target.dataset.acccontid;
        let accId = event.target.dataset.accid;
        let accName = event.target.dataset.accname;

        this.unlinkAccount.accContId = accContId;
        this.unlinkAccount.accId = accId;
        this.unlinkAccount.accName = accName;

        this.step = 6;

    }

    gohomeClick() {
        window.location.href = "/s/";
    }

    backClick() {
         //this.step = 0;
         window.location.href = "/s/linked-accounts";
    }
    handleInputGroupChange(event)
    {
       // let inputId = event.target.dataset.id;

        let inputGroup = this.template.querySelector('[data-id="input_groupname"]');
        
        this.newGroupName = inputGroup.value;
        inputGroup.reportValidity();
      
    }

    addAccountClick()
    {
        this.showSpinner =  true;
        apexGetEbaySessionId()
        .then(result => {
            //console.log("-doGetAccounts-",result);
            if(result.status=="ok")
            {
                let urlEbay = result.endpoint + "/ws/eBayISAPI.dll?SignIn&runame=" + result.ebayRuName + "&SessID=" + result.ebaySessionId;
                window.location.href=urlEbay;

            }else
            {
                this.showSpinner =  false;
                console.log("apexGetEbaySessionId error0",result);
            }           
                      
        })
        .catch(error => {        
            console.log("apexGetEbaySessionId error",error);
            this.showSpinner =  false;
        });         
    }
    
    removeAccountClick(event){ 
        //Sophal 10-05-2022 US-0011156
        event.preventDefault();
        this.showSpinner = true;

        let removedIndex = null;
        for(let i = 0; i< this.listAllContactRelation.length; i++){
            if(this.unlinkAccount.accId == this.listAllContactRelation[i].Account.Id){
                removedIndex = i;
                break;
            }
        }

        if(removedIndex != null){

            apexRemoveLinkedAccount({accId:this.unlinkAccount.accId})
            .then(result => {
                // console.log("apexRemoveLinkedAccount result",result);
                if(result.status == 'ok'){
                    
                        this.listAllContactRelation.splice(removedIndex, 1);
                        this.enableUnlink = this.listAllContactRelation.length > 1;
                        this.step = 8;
                        this.showSpinner = false;
                        var self = this;
                        setTimeout(function(){
                            if(self.step == 8){
                                self.backClick();
                            }
                        }, 10000);
                          
                    
                }else if(result.status == 'ko'){
                    console.log("apexRemoveLinkedAccount error 1",result.error);
                    this.step = 7;
                    this.showSpinner = false; 
                }
             
            })
            .catch(error => {
                console.log("apexRemoveLinkedAccount error 2",error);
                this.step = 7;
                this.showSpinner = false;
            });
              
        }else{
            this.showSpinner = false;
        }
   

   }


    //after authentication success, redirect url back and process idendtity
    validateLinkAccountCallback()
    {  
        
        //page returns from ebay callback auth 'n' auth ...&username=testuser_vadhanak_test
        let paramUser = this.getParameterByName("username");
        //console.log("paramUser",paramUser);

        if(paramUser != "" && paramUser != null)
        {
            //this.showAddAccButton = false;
            this.showSpinner = true;
            apexEbayConfirmIdentity()
            .then(result => {
                
                //console.log(result);

                if(result.status=="ok" && result.hasSession && result.userID==paramUser && result.ack=="ok")
                {
                    this.ebayLinkingSellerName = result.userID;
                    this.slaveAccountId = result.slaveAccountId;
                    this.hiveExist = result.hiveExist; //seller being linked exists in HIVE?
                    this.mainGroupId = result.mainGroupId;
                    this.mainGroupName = result.mainGroupName;
                    this.mainAccId = result.mainAccId;
                    this.mainAccName = result.mainAccName;
                    this.slaveHasGroup = result.slaveHasGroup;
                    this.slaveGroupName = result.slaveGroupName;
                    this.slaveGroupId = result.slaveGroupId;

                    //When they successfully authenticate into Account B,
                    //And Account B does exist within Hive,
                    //And Account A Record Type is not Seller Portal Group,
                    //And Seller Portal Group is empty on Account A and Account B,
                    if(this.hiveExist  && !result.hasGroup && !result.slaveHasGroup)
                    {
                        this.step = 1; //next step - create group
                        console.log("step 1");
                    }else if(!this.hiveExist)
                    {
                        this.step =  11;   //error of step 1. seller not exists in hive
                         console.log("step 11");
                    }else //AC1: Seller linking accounts together by adding Account B into existing Seller Portal Group from Account A
                        //AC2: Seller linking Account A of record type Seller Portal Group and Account B which does not have a Seller Portal Group identified 
                    if(this.hiveExist && result.hasGroup && !result.slaveHasGroup)//US-0011343:vadhanak/03/05/2022.AC1 
                    {
                        this.step = 3;
                        //console.log("apexGetEbaySessionIdFromTmp warning1",result);
                        console.log("step 3");

                    }else//AC6: Seller linking Account A with no Seller Portal Group to Account B which has a Seller Portal Group 
                    if(this.hiveExist && result.slaveHasGroup  && !result.hasGroup)  
                    {
                        this.step = 4; 
                        console.log("step 4");
                    }else//When Seller by mistake try to link to the current group
                    if(this.hiveExist && result.slaveHasGroup  && result.hasGroup && result.mainGroupId==result.slaveGroupId)  
                    {
                        this.step = 51; 
                        console.log("step 51");
                    }else//AC7: Seller trying to link accounts with already defined different Seller Portal Groups 
                    if(this.hiveExist && result.slaveHasGroup  && result.hasGroup) //both have grooup AC7
                    {
                        this.step = 5; 
                        console.log("step 5");
                    }
                    else{
                        console.log("anthing else",result);
                    }

                }else if(result.status=="ok" && result.hasSession && result.userID==paramUser && result.ack=="ko")
                {
                    // case. e.g. user click next to ebay page, then click back. session saved
                    //this.step = 33; //static error
                    //for now
                    this.step = 0;  //landing page
                    //this.showAddAccButton = true;
                    console.log("apexGetEbaySessionIdFromTmp warning0 ack_error",result.ack_error);
                    
                }else 
                {
                    this.step = 0;  //landing page
                    //this.showAddAccButton = true;
                    console.log("apexGetEbaySessionIdFromTmp warning",result);
                }    
                this.showSpinner = false;
                
            })
            .catch(error => {        
                console.log("apexEbayConfirmIdentity unkown error",error);
                this.showSpinner = false;
                this.step = 0;
            });         
        }else
        {
            //landing page
            this.step = 0;
            //this.showAddAccButton = true;
        }
        
    }

    startCreateGroup()
    {         
        if(this.newGroupName.trim()=="")
        {
            return;
        }
         
        this.doManageGroup();

    }
    addAccountToExistingGroup()
    {
        this.doManageGroup();

    }
    doManageGroup()
    {
        this.showSpinner = true;
        let groupToLink = (this.step == 3 ? this.mainGroupId : this.slaveGroupId) ;
        let grpAt =  (this.step == 3 ? 'a' : 'b') ;
        apexManageGroup({groupName:this.newGroupName,groupId:groupToLink ,mainAccId:this.mainAccId,newLinkAccountId:this.slaveAccountId,groupAt:grpAt})
            .then(result => {
                //console.log("apexManageGroup result",result);
                if(result.status=="ok")
                {
                    this.step = 21; //sucess
                    setTimeout(() => {
                         window.location.href = "/s/linked-accounts";
                      }, "10000");
                }else
                {
                    console.log("doManageGroup error",result);
                    this.step = 22;
                }
                this.showSpinner = false;
            })
            .catch(error => {        
                console.log("doManageGroup unkown error",error);
                this.showSpinner = false;
                this.step = 22;
            }); 
    }
    
    get showBackButton()
    {
        return (this.step==11 || this.step==21 || this.step==22);
    }
    
    get isStep_1()
    {
        return this.step==-1; //before landing page
    }
    get isStep0()
    {
        return this.step==0; //landing page
    }
    get isStep1()
    {
        return this.step==1;
    }
    get isStep2()
    {
        return this.step==2;
    }
    get isStep11()
    {
        return this.step==11; //error of step 1
    }
    get isStep21()
    {
        return this.step==21;   // step 2 success
    }
    get isStep22()
    {
        return this.step==22;   // error of step 2
    }
    get isStep3() 
    {
        return this.step==3;
    }
    get isStep4() 
    {
        return this.step==4;
    }
    get isStep5() 
    {
        return this.step==5;
    }
    get isStep51() 
    {
        return this.step==51;
    }
    get isStep6() 
    {
        return this.step==6;
    }
    get isStep7() 
    {
        return this.step==7;
    }
    get isStep8() 
    {
        return this.step==8;
    }
    getParameterByName(name) 
    { 
        var url = window.location.href;        

        name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
        var regexS = "[\\?&]"+name+"=([^&#]*)";
        var regex = new RegExp( regexS );
        var results = regex.exec( url );
        
        return results == null ? null : results[1];
    }

}