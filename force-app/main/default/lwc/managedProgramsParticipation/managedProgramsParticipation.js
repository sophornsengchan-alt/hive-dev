/*********************************************************************************************************************************@ Component:    managedProgramsParticipation@ Version:      1.0@ Author:       Sovantheany dim
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.04.2024 / Sovantheany dim / US-0014954 - Display Program Participation on Seller Growth Center page
@                 02.07.2024 / Sovantheany dim / US-0015399 - Amendments for AU Kickstater (Durchstarter) Program
@                 19/09/2024 / Sovantheany dim / US-0015823 - 1.2 Customer Page should show the Managed Program participation
@                 11.12.2024 / Sothea Horn / US-0015300 - Generic LWC Exception handling & Application to program participation component
@                 11.07.2025 / Seng Chan Sophorn / US-0033289 - eBay Live: Account Team and Program Participation on Seller Growth Center Page
@                 27.11.2025 / Sothea Horn / US-0033849 - Step 1 - Seller Overview
*********************************************************************************************************************************/
import { LightningElement, track, wire, api } from 'lwc';
import { gql, graphql } from "lightning/uiGraphQLApi";
import { NavigationMixin } from 'lightning/navigation';

//27.11.2025 / Sothea Horn / US-0033849 - Step 1 - Seller Overview
import dynamicInvokeFlowModal from 'c/dynamicInvokeFlowModal';

import AdsGTMSegmentProgram from '@salesforce/resourceUrl/AdsGTMSegmentProgram';
import ConciergeSellerProgram from '@salesforce/resourceUrl/ConciergeSellerProgram';
import OnboardingProgram from '@salesforce/resourceUrl/OnboardingProgram';
import ManagedSegmentProgram from '@salesforce/resourceUrl/ManagedSegmentProgram';
import OneOffAccountManagementProgram from '@salesforce/resourceUrl/OneOffAccountManagementProgram';
import customLabels from 'c/customLabels';
//27.11.2025 / Sothea Horn / US-0033849 - Step 1 - Seller Overview
import hasPermissionSubmitChangeRequest from '@salesforce/apex/ManagedProgramsParticipationController.hasPermissionSubmitChangeRequest';

export default class managedProgramsParticipation extends NavigationMixin(LightningElement) {
    @api recordId;

    @track results;
    @track error;
    @track hasRecord = false;
    @track segment;
    @track hasPermissionSubmitChangeRequest = false;
   

    label = customLabels;

    sectionMessage = '';

    setBobSellerRecordType = [this.label.lwc_BobSeller_Record_Type_1, this.label.lwc_BobSeller_Record_Type_2]; // 'Advertising', 'LTTM'
    setProjectStage = [this.label.Program_Project_Stage_1, this.label.Program_Project_Stage_2]; //Program_Project_Stage_1 = Completed , Program_Project_Stage_2 = Cancelled
    setCountry = [this.label.Project_Program_Country_1, this.label.Project_Program_Country_2]; // 'DE', 'UK'
    setLeadSource = [this.label.Project_Lead_Source_1, this.label.Project_Lead_Source_2]; // 'Kickstarter - Acquisition', 'Kickstarter - Organic signup'
    setOneOffProjectStage = [this.label.Initial_Project_Stage,this.label.Second_Project_Stage,this.label.Final_Project_Stage];// 'Initial','Second','Final'
    AdsGTMSegmentProgram = AdsGTMSegmentProgram;
    ConciergeSellerProgram = ConciergeSellerProgram;
    OnboardingProgram = OnboardingProgram;
    ManagedSegmentProgram = ManagedSegmentProgram;
    OneOffAccountManagementProgram = OneOffAccountManagementProgram;
    //CSP:11072025:US-0033289 Start
    setEBayLiveStage = [this.label.Closed_Lost_Stage, this.label.Onboarding_Stage]; // Closed Lost
    setEBayLiveCountries = this.label.eBay_Live_Countries?.split(",") || [] // US,CA,NA,DE,UK
    //CSP:11072025:US-0033289 End

    get lttmBobSellers(){
        if(this.hasRecord){
            var lstLttmSellers = [];
            for(let i = 0; i < this.results[0]?.node.BoB_Sellers__r.edges.length; i++){
                if(this.results[0]?.node.BoB_Sellers__r.edges[i]?.node.RecordType.DeveloperName.value == this.label.lwc_BobSeller_Record_Type_2){
                    lstLttmSellers.push(this.results[0]?.node.BoB_Sellers__r.edges[i]);
                }
            }
          }
        return lstLttmSellers;
    }
    get adsBobSellers(){
        if(this.hasRecord){
            var lstAdsBobSellers = [];
            for(let i = 0; i < this.results[0]?.node.BoB_Sellers__r.edges.length; i++){
                if(this.results[0]?.node.BoB_Sellers__r.edges[i]?.node.RecordType.DeveloperName.value == this.label.lwc_BobSeller_Record_Type_1){
                    lstAdsBobSellers.push(this.results[0]?.node.BoB_Sellers__r.edges[i]);
                }
            }
        }
        return lstAdsBobSellers;
    }

    get onboardingProjectsDE(){
        if(this.hasRecord){
            var lstOnboarding = [];
            for(let i = 0; i < this.results[0]?.node.Projects__r.edges.length; i++){
                //if not EuOnboarding, continue to the next record
                if(this.results[0]?.node.Projects__r.edges[i]?.node.RecordType.DeveloperName.value != this.label.lwc_Project_Record_Type){continue;}
                if(this.results[0]?.node.Projects__r.edges[i]?.node.Site__c.value == this.label.Project_Program_Country_1){
                    lstOnboarding.push(this.results[0]?.node.Projects__r.edges[i]);
                }
            }
        }
        return lstOnboarding;
    }

    get onboardingProjectsUK(){
        if(this.hasRecord){
            var lstOnboarding = [];
            for(let i = 0; i < this.results[0]?.node.Projects__r.edges.length; i++){
                //if not EuOnboarding, continue to the next record
                if(this.results[0]?.node.Projects__r.edges[i]?.node.RecordType.DeveloperName.value != this.label.lwc_Project_Record_Type){continue;}
                if(this.results[0]?.node.Projects__r.edges[i]?.node.Site__c.value == this.label.Project_Program_Country_2){
                    lstOnboarding.push(this.results[0]?.node.Projects__r.edges[i]);
                }
            }
        }
        return lstOnboarding;
    }
    /*US-0015399 - Amendments for AU Kickstater (Durchstarter) Program*/
    get onboardingProjectsAU(){
        if(this.hasRecord){
            var lstOnboarding = [];
            for(let i = 0; i < this.results[0]?.node.Projects__r.edges.length; i++){
                //if not EuOnboarding, continue to the next record
                if(this.results[0]?.node.Projects__r.edges[i]?.node.RecordType.DeveloperName.value != this.label.lwc_Project_Record_Type){continue;}
                if(this.results[0]?.node.Projects__r.edges[i]?.node.Site__c.value == this.label.Project_Program_Country_3){
                    lstOnboarding.push(this.results[0]?.node.Projects__r.edges[i]);
                }
            }
        }
        return lstOnboarding;
    }
    /*US-0015823 - get one-Off Account management*/
    get oneOffProjects(){
        if(this.hasRecord){
            var lstOnboarding = [];
            for(let i = 0; i < this.results[0]?.node.Projects__r.edges.length; i++){
                if(this.results[0]?.node.Projects__r.edges[i]?.node.RecordType.DeveloperName.value == this.label.OneOffRecordType){
                    lstOnboarding.push(this.results[0]?.node.Projects__r.edges[i]);
                }
            }
        }
        return lstOnboarding;
    }

    /*CSP:11072025:US-0033289 Start - get eBay Live Onboarding Project*/
    get eBayLiveOnboardingProjects(){
        if(this.hasRecord){
            var lstOnboarding = [];
            for(let i = 0; i < this.results[0]?.node.Projects__r.edges.length; i++){
                if(this.results[0]?.node.Projects__r.edges[i]?.node.RecordType.DeveloperName.value == this.label.eBayLiveOnboardingType){
                    lstOnboarding.push(this.results[0]?.node.Projects__r.edges[i]);
                }
            }
        }
        return lstOnboarding;
    }

    //CSP:11072025:US-0033289
    get variables(){                
        return {
            currentRecordid: this.recordId,
            setBobSellerRecordType : this.setBobSellerRecordType,
            bobSellerStatus : this.label.lwc_Bob_Seller_Status, //Draft
            bobStatus : this.label.lwc_Bob_Status, //BoB Active
            projectRecordType : this.label.lwc_Project_Record_Type, //EUOnboarding
            setProjectStage : this.setProjectStage,
            setCountry : this.setCountry,
            auCountry : this.label.Project_Program_Country_3,//AU
            smbLeadSegment : this.label.SMB_Project_LeadSegment, //SMB
            leadSources : this.setLeadSource,
            OneOffRecordType : this.label.OneOffRecordType, //One_Off_Account_Management
            setOneOffStage: this.setOneOffProjectStage,
            setEBayLiveOnboardingType: this.label.eBayLiveOnboardingType, // eBay_Live_Onboarding
            setEBayLiveStage: this.setEBayLiveStage, 
            setEBayLiveCountries: this.setEBayLiveCountries
        }
    }
    /**
    * Name: wire
    * Purpose: To get the data from the server using the graphQl query
    * 1. If there is a cohort seller record against the seller, and record type = Advertising, and the Status = Active
    * =>Then, display the title and the value from the 'Ads GTM Segment' field
    * 2. When the Concierge Seller (RSV) (EBH_RVSSeller__c) = true on the seller record
    * =>Then display the Concierge title with the label 'Concierge'
    * 3. If there is a project record against the seller record, and the record type = EU Onboarding, and the status is not Completed or Cancelled, and the country = UK
    * =>Then display the tile and the text 'Start Up Scale Up'
    * 4.If there is a project record against the seller record, and the record type = EU Onboarding, and the status is not Completed or Cancelled, and the country = DE
    * =>Then display the tile and the text 'Durchstarter'
    * 5. If there is a cohort seller record against the seller, and record type = LTTM or Managed, and the Status = Cohort Active
    * =>Then, display the tile for each active cohort seller record and the value from the 'Managed Segment' field
    */
    @wire(graphql, {
        query: gql`query getAccount(
                $currentRecordid : ID!, 
                $setBobSellerRecordType : [String], 
                $bobSellerStatus : Picklist, 
                $bobStatus : Picklist,
                $projectRecordType : String,
                $setProjectStage : [Picklist],
                $setCountry : [Picklist],
                $auCountry : Picklist,
                $smbLeadSegment : Picklist,
                $leadSources : [Picklist],
                $OneOffRecordType : String,
                $setOneOffStage: [Picklist],
                $setEBayLiveOnboardingType: String,
                $setEBayLiveStage: [Picklist],
                $setEBayLiveCountries: [Picklist]
            ), 
        {
            uiapi {
                query 
                {
                    Account(first : 1,
                    where: { Id: { eq: $currentRecordid} }) 
                    {
                        edges {
                            node {
                                Id
                                Name {
                                    value
                                    displayValue
                                }
                                EBH_RVSSeller__c{
                                    value
                                }
                                BoB_Sellers__r(
                                where:{
                                    RecordType : {DeveloperName : {in : $setBobSellerRecordType}},
                                    Status__c : {eq : $bobSellerStatus}
                                    BoB__r:{Status__c:{eq: $bobStatus}}
                                }
                                ){
                                    edges{
                                        node{
                                            Id
                                            Name{
                                                value
                                            }
                                            RecordType{
                                                DeveloperName{
                                                    value
                                                }
                                            }
                                            Ads_GTM_Segment__c{
                                                value
                                            }
                                            EBH_BOBSegment__c{
                                                value
                                            }
                                            BoB__r {
                                                Name {
                                                    value
                                                }
                                            }
                                        }
                                    }
                                }
                                Projects__r(
                                where:{
                                    or : [
                                        {
                                            and : [
                                                {RecordType : {DeveloperName : {eq : $projectRecordType}}},
                                                {EBH_Stage__c : {nin : $setProjectStage}},
                                                {
                                                    or : [
                                                        {Site__c : {in: $setCountry}},
                                                        {
                                                            and : [
                                                                {Site__c : {eq: $auCountry}},
                                                                {LeadSegment__c : {eq : $smbLeadSegment}},
                                                                {LeadSource__c : {in : $leadSources}}
                                                            ]
                                                        }
                                                    ]
                                                }
                                            ]
                                        },
                                        {
                                            and : [
                                                {RecordType : {DeveloperName : {eq : $OneOffRecordType}}},
                                                {EBH_Stage__c : {in : $setOneOffStage}}
                                            ]
                                        },
                                        {
                                            and : [
                                                {RecordType : {DeveloperName : {eq : $setEBayLiveOnboardingType}}},
                                                {EBH_Stage__c : {nin : $setEBayLiveStage}},
                                                {Site__c : {in: $setEBayLiveCountries}}
                                            ]
                                        }
                                    ]
                                }
                                ){
                                    edges{
                                        node{
                                            Id
                                            Name{
                                                value
                                            }
                                            EBH_Stage__c{
                                                value
                                            }
                                            Site__c{
                                                value
                                            }
                                            Project_Type__c{
                                                value
                                            }
                                            RecordType{
                                                DeveloperName{
                                                    value
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }`,
          variables: '$variables'    
      })
      wiredResult({ data, error }) {
        if (data) {
          this.results = data.uiapi.query.Account.edges;
        //   console.log('this.results:', JSON.stringify(this.results));
          this.hasRecord = (this.results.length > 0 && (this.results[0]?.node.BoB_Sellers__r.edges.length > 0 || this.results[0]?.node.Projects__r.edges.length > 0)) ? true : false;
          if(this.hasRecord){
            this.sectionMessage = this.label.Click_on_the_icon_to_open_the_related_record;
          }
        } else if (error) {
           // 11.12.2024 / Sothea Horn / US-0015300 / show and log error in event mornitoring and apex error log object
           this.showHideErrorOnly(error, 'managedProgramsParticipation', 'wiredResult', true, true);
        }
        
        

      }

    connectedCallback() {
        // Check if user has permission: Action - Change Request Submitter
        hasPermissionSubmitChangeRequest()
            .then((result) => {
                this.hasPermissionSubmitChangeRequest = result;
            })
            .catch(error => {
                console.log(error);
            });
    }
    
    /**
     * Name :  navigateToRecord
     * Purpose : To navigate to the record detail page page
     * @param {*} sObject 
     * @param {*} currentId 
    */
    navigateToRecord(sObject, currentId) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: currentId,
                objectApiName: sObject,
                actionName: 'view'
        }}).then((url) => {
            window.open(url, '_blank');
        });
    }

    /**
     * Name : navigateToBobSeller
     * Purpose : To navigate to BoB Seller record detail page
     * @param {*} event : Bob Seller record Id
     */
    navigateToBobSeller(event){
        this.navigateToRecord('BoB_Seller__c', event.currentTarget.dataset.id);
    }

    /**
     * Name : navigateToProject
     * Purpose : To navigate to Project record detail page
     * @param {*} event : Project record Id
     */
    navigateToProject(event){
        this.navigateToRecord('EBH_Project__c', event.currentTarget.dataset.id);
    }

    
    /**
     * 
     * Name : handleToggleSection
     * Purpose : To toggle the section message
     * @param {*} event : On click event
     */
    handleToggleSection(event) {
        const openSections = event.detail.openSections;

        if (openSections.length === 0 && this.hasRecord) {
            this.sectionMessage = '';
        } else if(openSections.length > 0 && this.hasRecord){
            this.sectionMessage = this.label.Click_on_the_icon_to_open_the_related_record;
        }
    }

    /*
     * Show or Hide only error message and optionally log error message in event monitoring and Apex error log object
     * @param errors             Error object
     * @param lwcName            Name of LWC that cause error
     * @param lwcMethodName      Name of LWC method that cause error  
     * @param state              Flag to show message
     * @param isLog              Flage to log message in event monitoring and Apex error log object
     * @param timeOut            Duration to show message
     * 
     ------------------------------------------------------------------------------------------------------------------------------
     * @ Change history: 11.12.2024 / Sothea Horn / Create method
     *                   US-0015300 - Generic LWC Exception handling & Application to program participation component
     ------------------------------------------------------------------------------------------------------------------------------*/
    showHideErrorOnly(error, lwcName, lwcMethodName, state, isLog, timeOut) {
        let msgBlock = this.template.querySelector('c-lwc-message');
        if (msgBlock) {
            msgBlock.showErrorOnly(error, lwcName, lwcMethodName, state, isLog, timeOut);
        }
    }

    /*
     * Show seller's managed status change request flow
     ------------------------------------------------------------------------------------------------------------------------------
     * @ Change history: 27.11.2025 / Sothea Horn / Create method
     *                   US-0033849 - Step 1 - Seller Overview
     ------------------------------------------------------------------------------------------------------------------------------*/
    async handleShowChangeRequestFlow() {
        this.result = await dynamicInvokeFlowModal.open({
            size: 'small',
            description: 'Show Seller Managed Status Change Request',
            header: this.label.Header_NewManagedStatusChangeRequest,
            flowName: 'Account_Screen_SellerManagedStatusChangeRequestSubmission',
            inputVariables: [
                {
                    // Match with the input variable name declared in the flow.
                    name: "recordId",
                    type: "String",
                    // Initial value to send to the flow input.
                    value: this.recordId,
                }
            ]
        });
    }
}