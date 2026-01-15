/**
 * 
 * change log: 10/10/2022 / Chetra Sarom / US-0012538 - Home Page No Portal Message amendment.
 */
import { LightningElement, api, track} from 'lwc';
import getPortalUserMessage from '@salesforce/apex/CreatePortalUserMessageController.getPortalUserMessage';
import fetchUserInfo from '@salesforce/apex/CreatePortalUserMessageController.fetchUserInfo';
import uId from '@salesforce/user/Id';
import customSR from '@salesforce/resourceUrl/customChatterStyle';
import customSRJS from '@salesforce/resourceUrl/autoScroll';
import { loadStyle, loadScript} from 'lightning/platformResourceLoader';
import noMessageToDisplay from '@salesforce/label/c.No_Message_To_Display'; // 10/10/2022 / Chetra Sarom / US-0012538 - Home Page No Portal Message amendment.

import jQuery from '@salesforce/resourceUrl/jquery36'; 

export default class LwcViewPortalUserMessage extends LightningElement {

    @api mdtName = "";
    @api profileSetting = "";
    @api numRec;

    @track isLoadRecord = false;
    @track userId = uId;
    @track userName = "";
    @track currentUserType = "";

    @track outputText = noMessageToDisplay; // 10/10/2022 / Chetra Sarom / US-0012538 - Home Page No Portal Message amendment.
    @track lstResultMessage;
    @track myIndex = 0;
    // @track todayDate;

    @track objMessageInfos = [];
    @track isShowNext = true;
    @track isShowPrevious = false;
    @track isShowLstResult = false;


    onViewNextMessage(){
        if(this.lstResultMessage){
            this.myIndex++;
            if(this.myIndex > (this.lstResultMessage.length-1)) this.myIndex = this.lstResultMessage.length-1;
            else if(this.myIndex < 0) this.myIndex = 0;
            
            // console.log('myIndexN: ',this.myIndex);
            if(this.lstResultMessage[this.myIndex].Content__c){
                this.outputText = this.lstResultMessage[this.myIndex].Content__c;
            }
        }
    }
    onViewPreviousMessage(){
        if(this.lstResultMessage){
            this.myIndex--;
            if(this.myIndex > (this.lstResultMessage.length-1)) this.myIndex = this.lstResultMessage.length-1;
            else if(this.myIndex < 0) this.myIndex = 0;
            // console.log('myIndexP: ',this.myIndex);
            if(this.lstResultMessage[this.myIndex].Content__c){
                this.outputText = this.lstResultMessage[this.myIndex].Content__c;
            }
        }
    }

    get displayLstResult(){
        return this.isShowLstResult;
    }

    get displayPrevious(){
        if(this.myIndex <= 0) this.isShowPrevious = false;
        else this.isShowPrevious = true;
        return this.isShowPrevious;
    }
    get displayNext(){
        if(this.lstResultMessage){
            if(this.myIndex >= (this.lstResultMessage.length-1)) this.isShowNext = false ;
            else this.isShowNext = true;
        }else this.isShowNext = true;
        return this.isShowNext;
    }

    connectedCallback() {


        if(this.isLoadRecord) return;
        this.isLoadRecord = true;

        this.onFetchUserInfo();
		this.loadAllRecords();

        // // Get the current date/time in UTC
        // let rightNow = new Date();
        // console.log('rightNow: ', rightNow);
        // // Adjust for the user's time zone
        // rightNow.setMinutes(
        //     new Date().getMinutes() - new Date().getTimezoneOffset()
        // );
        // // Return the date in "YYYY-MM-DD" format
        // let yyyyMmDd = rightNow.toISOString().slice(0,10);
        // console.log('yyyyMmDd: ',yyyyMmDd); // Displays the user's current date, e.g. "2020-05-15"

        // this.todayDate = yyyyMmDd;

         // for hide header part of lightning-input-rich-text
         Promise.all([
            loadStyle(this, customSR + '/customChatterStyle.css'),
            loadScript(this, customSRJS + '/autoScroll.js'),
        ]).then(() => {
            // console.log("uploadstyle",result);
            })
            .catch(error => {
                console.log("error at style: ",error);
            });

           


	}

    onFetchUserInfo() {
        fetchUserInfo({})
        .then(result => {
            // console.log(">>>>> result:", result);
            if(result){
                if(result["ContactId"]) {
                    this.userId = result["ContactId"];
                    this.userName = result["Contact"]["FirstName"];
                }else{
                    this.userId = result["Id"];
                    this.userName = result["FirstName"];
                }
                this.currentUserType = result.UserType;
            }
        })
        .catch(error => { 
            console.log(">>>>>first onFetchUserInfo:", error);
        }); 
    }

    loadAllRecords() {

        var limitRec = "2021-09-15%";
        if(this.numRec) limitRec = this.numRec;
        else limitRec = 5;

        var vProfileSetting = '';
        if(this.profileSetting && ((this.profileSetting).toLowerCase() == "na" || (this.profileSetting).toLowerCase() == "de")) vProfileSetting = this.profileSetting;
        else vProfileSetting = "na";

        // console.log("vProfileSetting: ",vProfileSetting);
        // console.log("profileSetting: ",(this.profileSetting).toLowerCase());

        getPortalUserMessage({ "limitRec" : limitRec, "profileSetting" : vProfileSetting})
        .then(result => {
            // console.log(">>>>>first load getPortalUserMessage:", result);

            if(result && result.length > 0){
                // console.log(">>>>>MyReuslt:::::", result);
                this.lstResultMessage = result;
                if(result) this.isShowLstResult = true;

                // if(result[0].Content__c) this.outputText = result[0].Content__c;

                
                // var msg = 'Hello!';
                // var objMsgInfo;
                // objMsgInfo = {className : "cls_message-info", mainMsg : "Test Portal Banner: ", detailMsg : msg};
                // this.objMessageInfos.push(objMsgInfo);

            }

        })
        .catch(error => { 
            console.log(">>>>>first load ERROR:", error);
        }); 
	}

    renderedCallback() {
      
    loadScript(this, jQuery)
    .then(()=> {
        // console.log('jQuery loaded!!!');
         // smooth scroll to bottom
       var objDiv = this.template.querySelector('.cls_message-info'); 
      
       $(this.template.querySelector('.cls_message-info')).animate({
           scrollTop: objDiv.scrollHeight - objDiv.clientHeight
       }, 4000);
        
    })
    .catch(error=>{
        console.log('Failed to load the JQuery : ' +error);
    });

   

    }



}