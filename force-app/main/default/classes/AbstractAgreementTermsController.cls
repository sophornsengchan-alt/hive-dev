/*********************************************************************************************************************************
@ Class:        AbstractAgreementTermsController
@ Version:      1.0
@ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:      Parent Controller for class AgreementTermsControllerSEP and AgreementTermsControllerInfluencer
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / Created the class.
@                 15.03.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0012238 - Seller T&C notification on Deal Window prior to Deal Submission
@                 24.04.2023 / Mony Nou (mony.nou@gaea-sys.com) / US-0013535 - The Term and Agreement page shouldn't be shown when the Seller Contact is moved to the Seller Portal Group Level
*********************************************************************************************************************************/
public abstract class AbstractAgreementTermsController {

    public static final String PDF_NAME = 'Agreement';

    public static final String PARAM_AGMT_MDT_NAME = 'agmtMdtName';
    public static final String PARAM_REGION_DOWNLOAD = 'regionDownload';

    protected User currentUser;
    protected AgreementTerm_Setting__mdt agmtMdt;
    protected Date todayDate = Date.today();
    protected String agreementContent;
    protected Boolean agmtState = false;
    protected Boolean alreadyAgreed = false;

    public String htmlContent {get;set;}

    /*********************************************************************************************************************************************************************
    @ Method:         getAgmtState
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013171 - Make agreement component more scalable
    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / create method
    ***********************************************************************************************************************************************************************/
    public abstract Boolean getAgmtState(); // abstract method that child classes AgreementTermsControllerSEP and AgreementTermsControllerInfluencer need to overwrite


    /*********************************************************************************************************************************************************************
    @ Method:         updateAgmtState
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013171 - Make agreement component more scalable
    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / create method
    ***********************************************************************************************************************************************************************/
    public abstract void updateAgmtState(); // abstract method that child classes AgreementTermsControllerSEP and AgreementTermsControllerInfluencer need to overwrite


    /************************************************************************************************************************************************************************
    @ Method:         doInitAgmt
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013171 - Make agreement component more scalable
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / create method
    @               : 21.02.2023/vadhanak voun (vadhanak.voun@gaea-sys.com)/ US-0013150 - FR Champion Testing Fixes
    @               : 15.03.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0012238 - Seller T&C notification on Deal Window prior to Deal Submission
    @               : 24.04.2023 / Mony Nou (mony.nou@gaea-sys.com) / US-0013535 - The Term and Agreement page shouldn't be shown when the Seller Contact is moved to the Seller Portal Group Level
    *************************************************************************************************************************************************************************/
    @testVisible
    protected void doInitAgmt(String agmtMdtName) {

        // method that handle initialize TC agreement for both AgreementTermsControllerSEP and AgreementTermsControllerInfluencer
        //NK:21/02/2023:US-0013150 - added: Contact.Account.EBH_VATNumber__c
        //MN-24042023-US-0013535- Added: Contact.Account.RecordType.DeveloperName
        List<User> lstUsers = WithoutSharing.doQuery('SELECT Id, Federated_Login__c, Contact.Accepted_Current_Deals_Agreement__c, Contact.Agreed_to_Portal_Usage_Conditions__c,Profile.Name, Contact.RecordTypeId'
                            + ',Contact.AccountId, Contact.Account.SP_Promotion_General_T_Cs_Agreed__c,Contact.Account.EBH_VATNumber__c, Contact.Account.EBH_VATStatus__c'
                            + ',Contact.Account.ParentId, Contact.Account.Parent.Name, Contact.Account.Parent.EBH_BillingStreet__c, Contact.Account.Parent.EBH_BillingCity__c, Contact.Account.Parent.EBH_BillingPostalCode__c, Contact.Account.Parent.EBH_BillingCountry__c, Contact.Account.RecordType.DeveloperName'
                            + ' FROM User WHERE Id=' + ApexUtil.closeSQoute(UserInfo.getUserId()) + ' Limit 1', '', '');           

        if (!lstUsers.isEmpty()) {
            currentUser = lstUsers[0];
            agmtMdt = new AgreementTerm_Setting__mdt();
            for(AgreementTerm_Setting__mdt mdt : [SELECT DeveloperName, Download_Button_Label__c, Enable_Download_Button__c, Enable_Tab_View__c, Footer_Region__c, Header_Right_Side_Content__c, Label_Accept_Agreement__c, Label_Leave__c, Logo_Link__c, Logout_After_Declined__c, Modal_Title__c, 
                Region__c, Region_Download__c, Tab_Item_Number_Per_View__c, Is_SP_Promotion_General_TC__c, Always_Need_To_Agree__c, Redirect_Url_After_Declined__c, Close_Agreement_After_Declined__c // 15.03.2023 / Sophal Noch / US-0012238 : add field Always_Need_To_Agree__c, Redirect_Url_After_Declined__c, Close_Agreement_After_Declined__c to AgreementTerm_Setting__mdt query
                FROM AgreementTerm_Setting__mdt WHERE DeveloperName =: agmtMdtName Limit 1]){ 
                agmtMdt = mdt;
            }
            agreementContent = String.isBlank(agmtMdt.Region__c) ? null : [Select Id, HtmlValue From EmailTemplate Where DeveloperName =: agmtMdt.Region__c Limit 1]?.HtmlValue;
            agmtState = getAgmtState();
        }
            
    }

    /***************************************************************************************************************************************************************************
    @ Method:         doAcceptAgmt
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013171 - Make agreement component more scalable
    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / create method
    @               : 15.03.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0012238 - Seller T&C notification on Deal Window prior to Deal Submission
    @               : 24.04.2023 / Mony Nou (mony.nou@gaea-sys.com) / US-0013535 - The Term and Agreement page shouldn't be shown when the Seller Contact is moved to the Seller Portal Group Level
    *****************************************************************************************************************************************************************************/
    @testVisible
    protected void doAcceptAgmt(String agmtMdtName) {

         // method that handle accept TC agreement for both AgreementTermsControllerSEP and AgreementTermsControllerInfluencer

        // 24.03.2023 / Sophal Noch / US-0012238 : add Federated_Login__c, Contact.RecordTypeId field to user query below
        //MN-24042023-US-0013535- Added: Contact.Account.RecordType.DeveloperName
        List<User> lstUsers = [SELECT Id, Contact.Account.RecordType.DeveloperName, ContactId,Federated_Login__c, Contact.RecordTypeId, Contact.Accepted_Current_Deals_Agreement__c, Contact.Agreed_to_Portal_Usage_Conditions__c, Contact.AccountId,  Contact.Account.SP_Promotion_General_T_Cs_Agreed__c, Contact.Account.Name FROM User WHERE Id=:UserInfo.getUserId()];
            
        if (!lstUsers.isEmpty() && String.isNotBlank(lstUsers[0].ContactId)) {    
            
            currentUser = lstUsers[0];
            todayDate = Date.today();
            agmtMdt = new AgreementTerm_Setting__mdt();
            // 15.03.2023 / Sophal Noch / US-0012238 : add field Always_Need_To_Agree__c, Is_Deal_Window_TC__c to AgreementTerm_Setting__mdt query
            for(AgreementTerm_Setting__mdt mdt : [SELECT DeveloperName, Region__c, Region_Download__c, Is_SP_Promotion_General_TC__c, Always_Need_To_Agree__c, Is_Deal_Window_TC__c FROM AgreementTerm_Setting__mdt WHERE DeveloperName =: agmtMdtName Limit 1]){ agmtMdt = mdt;}
            if(getAgmtState()){alreadyAgreed = true; return;}
            updateAgmtState();

        }

    }





}