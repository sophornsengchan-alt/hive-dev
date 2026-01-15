/*********************************************************************************************************************************
@ Class:         AgreementTermsControllerSEP
@ Version:       1.0
@ Author:        Sophal Noch
@ Purpose:       Controller for lwcAgreementTermsSEP,  logic is copied from lwcAgreementTermsController.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / Created the class.
@               : 21.02.2023/vadhanak voun (vadhanak.voun@gaea-sys.com)/ US-0013150 - FR Champion Testing Fixes
@               : 15.03.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0012238 - Seller T&C notification on Deal Window prior to Deal Submission
@               : 17.03.2023/vadhanak voun (vadhanak.voun@gaea-sys.com)/ US-0013108 - Prevent users from accessing deep links if not agreed to master agreement
@               : 03.04.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0012899 - [IT] Mandatory agreement when using promotions in portal
@               : 24.04.2023 / Mony Nou (mony.nou@gaea-sys.com) / US-0013535 - The Term and Agreement page shouldn't be shown when the Seller Contact is moved to the Seller Portal Group Level
@               : 15.02.2024 / Mony Nou (mony.nou@gaea-sys.com) / US-0014491 - [Tech Debt] Remove dependency from URL Domain and replace with SP Main Domain Field in SEP Features
*********************************************************************************************************************************/
public with sharing class AgreementTermsControllerSEP extends AbstractAgreementTermsController{


    private static final String MFLD_ACCOUNT_NAME = '{!Account.Name}';
    private static final String MFLD_SPG_TC_AGREEDDATE = '{!Account.SP_Promotion_General_T_Cs_Agreed_Date__c}';

    private static final String TXT_ADDRESS = '{0}, {1}, {2}, {3}';

    private static final String MFLD_VAT_STATUS = '{!Account.EBH_VATStatus__c}';
    private static final String MFLD_LGE_NAME = '{!EBH_LegalEntity__c.Name}';
    private static final String MFLD_LGE_FBADDRESS = '{!EBH_LegalEntity__c.EBH_FullBillingAddress__c}';

    private static final String MFLD_DRC_DEAL_TITLE = '{!EBH_DealRetailCampaign__c.EBH_DealTitle__c}';
    private static final String MFLD_DRC_START_DATE = '{!EBH_DealRetailCampaign__c.EBH_Date__c}';
    private static final String MFLD_DRC_END_DATE = '{!EBH_DealRetailCampaign__c.EPH_EndDate__c}';

    private static final String ARG_DRC_ID = 'drcId';
    private static final String ARG_ACCOUNT_ID = 'accountId';
    
    private static final String RT_ACCOUNT_SELLERPORTALGROUP = 'Seller_Portal_Group'; //MN-25042023-US-0013535

    private static final RecordType RT_SELLER_PORTAL = ApexUtil.getRecordTypeByName('Contact','Seller_Portal');

    


    /*****************************************************************************************************************************
    @ Method:         AgreementTermsControllerSEP
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013171 - Make agreement component more scalable
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / create method
    *****************************************************************************************************************************/
    public AgreementTermsControllerSEP(){

        if(ApexPages.currentPage() != null){
            // controller for visual force page AgreementTermsDownloadSEPPage.page
            
            String agmtMdtName = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(AbstractAgreementTermsController.PARAM_AGMT_MDT_NAME)==null?'':ApexPages.currentPage().getParameters().get(AbstractAgreementTermsController.PARAM_AGMT_MDT_NAME));
            AgreementTerm_Setting__mdt agmtMdt = new AgreementTerm_Setting__mdt();
            for(AgreementTerm_Setting__mdt mdt : [SELECT Region_Download__c, Is_SP_Promotion_General_TC__c FROM AgreementTerm_Setting__mdt WHERE DeveloperName =: agmtMdtName Limit 1]){ agmtMdt = mdt;}
            htmlContent = [Select Id, HtmlValue From EmailTemplate Where DeveloperName =: agmtMdt.Region_Download__c]?.HtmlValue;
            if(agmtMdt.Is_SP_Promotion_General_TC__c){ htmlContent = mergeFieldsAgreement(null, htmlContent, agmtMdt); }
        }
       
    }

    /*****************************************************************************************************************************
    @ Method:         getAgmtState
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013171 - Make agreement component more scalable
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / create method
    @               :  15.03.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0012238 - Seller T&C notification on Deal Window prior to Deal Submission
    @               :  24.04.2023 / Mony Nou (mony.nou@gaea-sys.com) / US-0013535 - The Term and Agreement page shouldn't be shown when the Seller Contact is moved to the Seller Portal Group Level
    *****************************************************************************************************************************/
    public override Boolean getAgmtState(){ 
        // get state of agreement whether it is agreed or not yet agreed.
        // it overwrites parent class method AbstractAgreementTermsController.
        // return agmtMdt.Is_SP_Promotion_General_TC__c ? currentUser.Contact.Account.SP_Promotion_General_T_Cs_Agreed__c : currentUser.Contact.Accepted_Current_Deals_Agreement__c;
        Boolean state = agmtMdt.Is_SP_Promotion_General_TC__c ? currentUser.Contact.Account.SP_Promotion_General_T_Cs_Agreed__c : currentUser.Contact.Accepted_Current_Deals_Agreement__c;
        state = isRTSellerPortal() ? true : state; //Federation user not require to accept agreement

        //MN-24042023-US-0013535 ====
        if((state == null || !state) && agmtMdt.Is_SP_Promotion_General_TC__c && currentUser.Contact.Account.RecordType.DeveloperName == RT_ACCOUNT_SELLERPORTALGROUP){

            Boolean linkedAccAgreedState = [Select Id, SP_Promotion_General_T_Cs_Agreed__c From Account Where Seller_Portal_Group__c =: currentUser.Contact.AccountId And SP_Promotion_General_T_Cs_Agreed__c = true Limit 1]?.SP_Promotion_General_T_Cs_Agreed__c;
            
            state = linkedAccAgreedState != null ? linkedAccAgreedState : state;
            
        }
        //==== MN-24042023-US-0013535 

        if(agmtMdt.Always_Need_To_Agree__c) state = false;  // 15.03.2023 / Sophal Noch / US-0012238 : Always_Need_To_Agree__c is true, the state will always false
        return state;
    }

    /*****************************************************************************************************************************
    @ Method:         updateAgmtState
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013171 - Make agreement component more scalable
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / create method
    @               :  15.03.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0012238 - Seller T&C notification on Deal Window prior to Deal Submission
    *****************************************************************************************************************************/
    public override void updateAgmtState(){ 

        if(agmtMdt.Always_Need_To_Agree__c) return; // 15.03.2023 / Sophal Noch / US-0012238 : when Always_Need_To_Agree__c = true, no need to update any field

        // agree the agreement.
        // it overwrites parent class method AbstractAgreementTermsController.
       if(agmtMdt.Is_SP_Promotion_General_TC__c){ // for FR site 
            Account accToUpdate = new Account(Id = currentUser.Contact.AccountId, SP_Promotion_General_T_Cs_Agreed_by__c = currentUser.Id, SP_Promotion_General_T_Cs_Agreed_Date__c = todayDate, SP_Promotion_General_T_Cs_Agreed__c = true);
            WithoutSharing.doUpdate(new List<Account>{accToUpdate});
       }else{ // for other site
            Contact contactToUpdate = new Contact(Id=currentUser.ContactId, Accepted_Current_Deals_Agreement__c=true); 
            WithoutSharing.doUpdate(new List<Contact>{contactToUpdate});
       }
    }

    /*****************************************************************************************************************************
    @ Method:         initAgreementTerms
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013171 - Make agreement component more scalable
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / create method
    *****************************************************************************************************************************/
    @AuraEnabled(cacheable=false)   
    public static Map<String,Object> initAgreementTerms(String agmtMdtName) {     
        Map<String,Object> mapResult = new Map<String,Object>();
        try {
            AgreementTermsControllerSEP contr = new AgreementTermsControllerSEP();
            contr.doInitAgmt(agmtMdtName);
            if(contr.agmtMdt.Is_SP_Promotion_General_TC__c){ // orginiated from user story US-0012730
                mapResult.put('agreementContent', contr.mergeFieldsAgreement(contr.currentUser, contr.agreementContent, contr.agmtMdt)); // merge field for FR, 
            }else{
                mapResult.put('agreementContent', contr.agreementContent); 
            }
            mapResult.put('isRTSellerPortal', contr.isRTSellerPortal()); // check user is managed user
            mapResult.put('agmtMdt', contr.agmtMdt);
            mapResult.put('result', contr.getAgmtState());
            mapResult.put('status','ok');
        // } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
        } catch (Exception e) { mapResult.put('status','ko'); mapResult.put('error', e.getMessage());} // 15.03.2023 / Sophal Noch / US-0012238 : fix issue error not show correct message by return error using mapResult instead

        return mapResult;
    }

    /*****************************************************************************************************************************
    @ Method:         acceptedAgreement
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013171 - Make agreement component more scalable
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / create method
    @               :  15.03.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0012238 - Seller T&C notification on Deal Window prior to Deal Submission
    *****************************************************************************************************************************/    
    @AuraEnabled(cacheable=false)   
    public static Map<String,Object> acceptedAgreement(String agmtMdtName, Map<String,Object> mapArgs) {
        Savepoint sp = Database.setSavepoint();
        Map<String,Object> mapResult = new Map<String,Object>();
        try {
            AgreementTermsControllerSEP contr = new AgreementTermsControllerSEP();
            contr.doAcceptAgmt(agmtMdtName);
           if(!contr.alreadyAgreed && contr.agmtMdt.Is_SP_Promotion_General_TC__c) mapResult.put('attachmentId',contr.dlAgmtAfterAgreed()); // after accept agreement, auto-download the pdf
           if(!contr.alreadyAgreed && contr.agmtMdt.Is_Deal_Window_TC__c) contr.dlDealWindowAgmtAfterAgreed(mapResult, mapArgs); // 16.03.2023 / Sophal Noch / US-0012238 : mapArgs contains multiple argument form lwc, after accept agreement for deal window, merge fields and auto-download the pdf
            mapResult.put('status','ok');
           
        }catch (Exception e) { mapResult.put('status','ko'); mapResult.put('error',e.getMessage()); Database.rollback(sp); } 
       return mapResult;
    }


    private String mergeFieldsAgreement(User user, String content, AgreementTerm_Setting__mdt agmtMdt){

        // do merge field on FRregion and FR region download email content before show to seller
        if(String.isBlank(content)) return content;

            String vatStatus = '';
            String lgeName = '';
            String lgeFbAddress ='';
            if(user == null){
                //NK:21/02/2023:US-0013150 - added: Contact.Account.EBH_VATNumber__c
                List<User> listUser =  WithoutSharing.doQuery('Select Id, Contact.AccountId,Contact.Account.EBH_VATNumber__c, Contact.Account.EBH_VATStatus__c, Contact.Account.ParentId, Contact.Account.Parent.Name, Contact.Account.Parent.EBH_BillingStreet__c, Contact.Account.Parent.EBH_BillingCity__c, Contact.Account.Parent.EBH_BillingPostalCode__c, Contact.Account.Parent.EBH_BillingCountry__c From User Where Id = ' + ApexUtil.closeSQoute(UserInfo.getUserId()) + ' And Contact.AccountId != null Limit 1', '' , '');
                if(!listUser.isEmpty()) user = listUser[0];
            }
            if(user != null && user.Contact.AccountId != null){
            //vatStatus = String.isNotBlank(user.Contact.Account.EBH_VATStatus__c) ? user.Contact.Account.EBH_VATStatus__c : vatStatus;
            //NK:21/02/2023:US-0013150
            vatStatus = String.isNotBlank(user.Contact.Account.EBH_VATNumber__c) ? user.Contact.Account.EBH_VATNumber__c : vatStatus;
            lgeName =  (user.Contact.Account.Parent.Name != null) ? user.Contact.Account.Parent.Name : lgeName;

                lgeFbAddress = String.format(TXT_ADDRESS,new String[]{
                String.isNotBlank(user.Contact.Account.Parent.EBH_BillingStreet__c) ? user.Contact.Account.Parent.EBH_BillingStreet__c : '',
                String.isNotBlank(user.Contact.Account.Parent.EBH_BillingCity__c) ? user.Contact.Account.Parent.EBH_BillingCity__c : '',
                String.isNotBlank(user.Contact.Account.Parent.EBH_BillingPostalCode__c) ? user.Contact.Account.Parent.EBH_BillingPostalCode__c : '',
                String.isNotBlank(user.Contact.Account.Parent.EBH_BillingCountry__c) ? user.Contact.Account.Parent.EBH_BillingCountry__c : ''});

            }
            content = content.replace(MFLD_VAT_STATUS, vatStatus);
            content = content.replace(MFLD_LGE_NAME, lgeName);
            content = content.replace(MFLD_LGE_FBADDRESS,lgeFbAddress);

        return content;
    }

    private Boolean isRTSellerPortal(){ // check user is managed user
        return currentUser.Federated_Login__c && currentUser.Contact.RecordTypeId == RT_SELLER_PORTAL.Id;
    }

    private Id dlAgmtAfterAgreed(){ 
        // orginiated from user story US-0012730
        Id attId;

        if(agmtMdt.Is_SP_Promotion_General_TC__c && String.isNotBlank(agmtMdt.Region_Download__c) && currentUser.Contact.AccountId != null){
            // after agreement is agreed and then auto download the pdf

            Pagereference pdfPage = Page.AgreementTermsDownloadSEPPage;
            pdfPage.getParameters().put(AbstractAgreementTermsController.PARAM_AGMT_MDT_NAME,agmtMdt.DeveloperName);

            Blob pdfContent = !Test.isRunningTest()?pdfPage.getContentAsPdf():Blob.valueOf('test');

            //Insert ContentVersion

            String pdfName = AbstractAgreementTermsController.PDF_NAME;
            List<EmailTemplate> emTpt = [Select Id,Subject From EmailTemplate Where DeveloperName =: agmtMdt.Region_Download__c Limit 1];
            if(!emTpt.isEmpty()){
                pdfName = emTpt[0].Subject;
                pdfName = pdfName.replace(MFLD_ACCOUNT_NAME, currentUser.Contact.Account.Name);
                pdfName = pdfName.replace(MFLD_SPG_TC_AGREEDDATE, todayDate.format());
            }

            ContentVersion cVersion = new ContentVersion();
            cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
            cVersion.PathOnClient = pdfName + '.pdf';//File name with extention
            cVersion.Origin = 'C';//C-Content Origin. H-Chatter Origin.
            cVersion.OwnerId = ApexUtil.getCurrentUser().Id;//Owner of the file
            cVersion.Title = pdfName;//Name of the file
            cVersion.VersionData = pdfContent;//File content
    
            //Error: INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.: [NetworkId]
            if (Test.isRunningTest()) {
                Id networkId = [SELECT Id FROM Network LIMIT 1].Id;
                cVersion.NetworkId = networkId;
            }

            WithoutSharing.doInsert(new ContentVersion[]{cVersion});
            Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
            
            ContentDocumentLink cDocLink = new ContentDocumentLink();
            cDocLink.ContentDocumentId = conDocument;//Add ContentDocumentId
            cDocLink.LinkedEntityId = currentUser.Contact.AccountId;//Add attachment parentId
            cDocLink.ShareType = 'V';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
            
            WithoutSharing.doInsert(new ContentDocumentLink[]{cDocLink});

            attId = cVersion.Id;
            
        }
        return attId;
    }

    private void dlDealWindowAgmtAfterAgreed(Map<String,Object> mapResult, Map<String,Object> mapArgs){
        // 15.03.2023 / Sophal Noch / US-0012238 : merge fields and auto-download pdf
        String content;
        String title = AbstractAgreementTermsController.PDF_NAME;
        if(agmtMdt.Is_Deal_Window_TC__c && String.isNotBlank(agmtMdt.Region_Download__c)){

            List<EmailTemplate> emTpt = [Select Id,Subject From EmailTemplate Where DeveloperName =: agmtMdt.Region_Download__c Limit 1];
            if(!emTpt.isEmpty()){

                title = emTpt[0].Subject; // use email template Subject for PDF name

                // 16.03.2023 / Sophal Noch / US-0012238 : use mapArgs to handle multiple arguments sent by lwc
                String accountId = (mapArgs != null && mapArgs.containsKey(ARG_ACCOUNT_ID)) ? String.valueOf(mapArgs.get(ARG_ACCOUNT_ID)) : '';
                String drcId = (mapArgs != null && mapArgs.containsKey(ARG_DRC_ID)) ? String.valueOf(mapArgs.get(ARG_DRC_ID)) : '';

                if(String.isNotBlank(accountId)){ // 16.03.2023 / Sophal Noch / US-0012238 : accountId is selected from Linked Account Picklist in lwc
                    String accName =  [Select Id, Name From Account Where Id =: accountId Limit 1]?.Name;
                    title = title.replace(MFLD_ACCOUNT_NAME, String.isNotBlank(accName) ? accName : '');
                }

                if(String.isNotBlank(drcId)){

                    List<EBH_DealRetailCampaign__c> listDrc = [Select Id, EBH_DealTitle__c, EBH_Date__c, EPH_EndDate__c From EBH_DealRetailCampaign__c Where Id =: drcId Limit 1];
                    if(!listDrc.isEmpty()){
                        title = title.replace(MFLD_DRC_DEAL_TITLE, listDrc[0].EBH_DealTitle__c != null ? listDrc[0].EBH_DealTitle__c : '');
                        title = title.replace(MFLD_DRC_START_DATE, listDrc[0].EBH_Date__c != null ? listDrc[0].EBH_Date__c.format() : '');
                        title = title.replace(MFLD_DRC_END_DATE, listDrc[0].EPH_EndDate__c != null ? listDrc[0].EPH_EndDate__c.format() : '');
                    }
                }
                

                
            }

            Pagereference pdfPage = Page.AgreementTermsDownloadSEPPage;
            pdfPage.getParameters().put(AbstractAgreementTermsController.PARAM_AGMT_MDT_NAME,agmtMdt.DeveloperName);
            content = EncodingUtil.base64encode(!Test.isRunningTest()?pdfPage.getContentAsPdf():Blob.valueOf('test'));
        }
        mapResult.put('attachmentContent', content);
        mapResult.put('attachmentTitle', title);
    }

    /*****************************************************************************************************************************
    @ Method:         apexInitAgreementTheme
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        US-0013108 - Prevent users from accessing deep links if not agreed to master agreement
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  17.03.2023 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / create method
    @               :  03.04.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0012899 - [IT] Mandatory agreement when using promotions in portal
    @               :  15.02.2024 / Mony Nou (mony.nou@gaea-sys.com) / US-0014491 - [Tech Debt] Remove dependency from URL Domain and replace with SP Main Domain Field in SEP Features
    *****************************************************************************************************************************/    
    @AuraEnabled(cacheable=false)   
    public static Map<String,Object> apexInitAgreementTheme() 
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        Map<String,String> mapAgreementSiteMeta = new Map<String,String>{
            SEP_Helper.SEP_Domain_FR=>'FR_Agreement_Terms',
            SEP_Helper.SEP_Domain_IT=>'IT_Agreement_Terms' // 03.04.2023 / Sophal Noch / US-0012899
        };

        //String curDomain = !Test.isRunningTest()? ((ApexUtil.runningInASandbox())?System.Label.SEP_Current_Sandbox_Domain:ApexUtil.getDomain()):SEP_Helper.SEP_Domain_FR; //MN-15022024-US-0014491
        String curDomain = !Test.isRunningTest()? SEP_Helper.getSPMainDomain():SEP_Helper.SEP_Domain_FR; //MN-15022024-US-0014491

        Boolean showAgreement = false;
        if(mapAgreementSiteMeta.containsKey(curDomain))
        {
            AgreementTermsControllerSEP contr = new AgreementTermsControllerSEP();
            contr.doInitAgmt(mapAgreementSiteMeta.get(curDomain));

            showAgreement = (!contr.getAgmtState() && (Userinfo.getprofileId() <> ApexUtil.ADMIN_PROFILE_ID));

            mapResult.put('agmtMdtName',mapAgreementSiteMeta.get(curDomain));
        }
        
        mapResult.put('showAgreement',showAgreement);
        
        return mapResult;
    }

}