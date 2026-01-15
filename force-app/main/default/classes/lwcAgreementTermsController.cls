/**
 * @description 
 * @date        19-July-2021
 * @author      Samnang MUONG
 */
/*********************************************************************************************************************************
@ Change history: 17.08.2022 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0011795 - AU T&C for Seller Portal
@ Change history: 11.01.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0012730 - [FR] Mandatory agreement when using promotions in portal
@               : 06/06/2024 / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c 
*********************************************************************************************************************************/
public without sharing class lwcAgreementTermsController {

    private static final RecordType RT_SELLER_PORTAL = ApexUtil.getRecordTypeByName('Contact','Seller_Portal');
    private final static String PROFILE_NA = 'NA - Seller Portal';
    private final static String PROFILE_AU = 'AU - Seller Portal';
    private static final String PDF_NAME = 'Agreement';

    private static final String TXT_ADDRESS = '{0}, {1}, {2}, {3}';

    private static final String MFLD_ACCOUNT_NAME = '{!Account.Name}';
    private static final String MFLD_SPG_TC_AGREEDDATE = '{!Account.SP_Promotion_General_T_Cs_Agreed_Date__c}';
    private static final String MFLD_VAT_STATUS = '{!Account.EBH_VATStatus__c}';
    private static final String MFLD_LGE_NAME = '{!EBH_LegalEntity__c.Name}';
    private static final String MFLD_LGE_FBADDRESS = '{!EBH_LegalEntity__c.EBH_FullBillingAddress__c}';


    // 16.01.2023 / Sophal Noch / US-0012730 : to identify which region need to update details to account fields
    private static final Set<String> SPPROMOTION_GENERAL_REGIONS{
        get{
            if(SPPROMOTION_GENERAL_REGIONS == null){
                Set<String> spPromoRegions = new Set<String>();
                for(String promo : Label.AgreementTerms_SPPromotionGeneral_Regions.split(';')){
                    spPromoRegions.add(promo);
                }
                SPPROMOTION_GENERAL_REGIONS = spPromoRegions;
            }
            return SPPROMOTION_GENERAL_REGIONS;
        }
        set;
    }

    // 16.01.2023 / Sophal Noch / US-0012730 : to identify which region need to auto-download field when agreement is accepted
    private static final Set<String> AUTODOWNLOADFILE_REGIONS{
        get{
            if(AUTODOWNLOADFILE_REGIONS == null){
                Set<String> autoDownloadRegions = new Set<String>();
                for(String promo : Label.AgreementTerms_AutoDownloadFile_Regions.split(';')){
                    autoDownloadRegions.add(promo);
                }
                AUTODOWNLOADFILE_REGIONS = autoDownloadRegions;
            }
            return AUTODOWNLOADFILE_REGIONS;
        }
        set;
    }

    // 20.01.2023 / Sophal Noch / US-0012730 : to identify which FR region  or FR region download that need to do merge field on email content
    private static final Set<String> FR_AGM_MERGE_FIELD_CONTENTS{
        get{
            if(FR_AGM_MERGE_FIELD_CONTENTS == null){
                Set<String> contents = new Set<String>();
                for(String content : Label.FR_Agreement_Merge_Field_Contents.split(';')){
                    contents.add(content);
                }
                FR_AGM_MERGE_FIELD_CONTENTS = contents;
            }
            return FR_AGM_MERGE_FIELD_CONTENTS;
        }
        set;
    }    


    // 17.01.2023 / Sophal Noch / US-0013069 : to identify which region need to update details to contact fields
    private static final Set<String> NDA_ACCEPTANCE_REGIONS{
        get{
            if(NDA_ACCEPTANCE_REGIONS == null){
                Set<String> ndaAcceptRegions = new Set<String>();
                for(String ndaRegion : Label.AgreementTerms_NDA_Acceptance_Regions.split(';')){
                    ndaAcceptRegions.add(ndaRegion);
                }
                NDA_ACCEPTANCE_REGIONS = ndaAcceptRegions;
            }
            return NDA_ACCEPTANCE_REGIONS;
        }
        set;
    }


    /*****************************************************************************************************************************
    @ Method:         lwcAgreementTermsController
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0012730 - [FR] Mandatory agreement when using promotions in portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  11.01.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0012730 : create method for visual force page
    *****************************************************************************************************************************/
    public String htmlContent {get;set;}
    public lwcAgreementTermsController(){
        // controller for visual force page AgreementTermsDownloadPage.page
        String template = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('template')==null?'':ApexPages.currentPage().getParameters().get('template'));
        htmlContent = [Select Id, HtmlValue From EmailTemplate Where DeveloperName =: template]?.HtmlValue;
        htmlContent = mergeFieldsAgreement(null, htmlContent, template);
    }


    /*****************************************************************************************************************************
    @ Method:         initAgreementTerms
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0011795 - AU T&C for Seller Portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.08.2022 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0011795 : update method
    @ Change history: 11.01.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0012730 : update method
    @ Change history: 17.01.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013069 : update method
    *****************************************************************************************************************************/
    @AuraEnabled(cacheable=false)   
    public static Map<String,Object> initAgreementTerms(String region) {     

        try {

            Map<String,Object> mapResult = new Map<String,Object>();

            Boolean result = false;

            // List<User> lstUsers = [SELECT Id, ContactId, Contact.Accepted_Current_Deals_Agreement__c, Profile.Name FROM User WHERE Id=:UserInfo.getUserId()];           
            List<User> lstUsers = [SELECT Id, Federated_Login__c, Contact.Accepted_Current_Deals_Agreement__c, Contact.Agreed_to_Portal_Usage_Conditions__c,Profile.Name, Contact.RecordTypeId,
                                Contact.AccountId, Contact.Account.SP_Promotion_General_T_Cs_Agreed__c, Contact.Account.EBH_VATStatus__c, Contact.Account.ParentId, Contact.Account.Parent.Name, Contact.Account.Parent.EBH_BillingStreet__c, Contact.Account.Parent.EBH_BillingCity__c, Contact.Account.Parent.EBH_BillingPostalCode__c, Contact.Account.Parent.EBH_BillingCountry__c
                                FROM User WHERE Id=:UserInfo.getUserId()];           

            if (!lstUsers.isEmpty()) {

                // 11.01.2023 / Sophal Noch / US-0012730 : store agreement content in email template
                String agreementContent = String.isBlank(region) ? null : [Select Id, HtmlValue From EmailTemplate Where DeveloperName =: region Limit 1]?.HtmlValue;
                agreementContent = mergeFieldsAgreement(lstUsers[0], agreementContent, region);
                mapResult.put('agreementContent',agreementContent);
                mapResult.put('isRTSellerPortal', ((String.isBlank(region) || !NDA_ACCEPTANCE_REGIONS.contains(region)) && lstUsers[0].Federated_Login__c && lstUsers[0].Contact.RecordTypeId == RT_SELLER_PORTAL.Id));

                // result = lstUsers[0].Contact.Accepted_Current_Deals_Agreement__c;
                 // 17.01.2023 / Sophal Noch / US-0013069 :
                result = (String.isNotBlank(region) && NDA_ACCEPTANCE_REGIONS.contains(region)) ? lstUsers[0].Contact.Agreed_to_Portal_Usage_Conditions__c : lstUsers[0].Contact.Accepted_Current_Deals_Agreement__c; // 17.01.2023 / Sophal Noch / US-0013069
                result = (String.isNotBlank(region) && lstUsers[0].Contact.AccountId != null && AUTODOWNLOADFILE_REGIONS.contains(region)) ? lstUsers[0].Contact.Account.SP_Promotion_General_T_Cs_Agreed__c : result;
                
                /* MN-06062024-US-0015298: No longer use profile name
                // 17.08.2022 / Sophal Noch / US-0011795 :
                mapResult.put('isNA',lstUsers[0].Profile.Name == PROFILE_NA);
                mapResult.put('isAU',lstUsers[0].Profile.Name == PROFILE_AU);
                */

                mapResult.put('isNA',SEP_Helper.sepUser.isNA()); //MN-06062024-US-0015298: Use SP Main Domain instead of Profile Name
                mapResult.put('isAU',SEP_Helper.sepUser.isAU()); //MN-06062024-US-0015298: Use SP Main Domain instead of Profile Name

                mapResult.put('useOldVersion', false);
                if(String.isBlank(agreementContent)){mapResult.put('useOldVersion', true);}
            }
            

         // return result;
         mapResult.put('result',result); // 17.08.2022 / Sophal Noch / US-0011795
         
         return mapResult;
            
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }


    }

    private static String mergeFieldsAgreement(User user, String content , String template){

        // do merge field on FRregion and FR region download email content before show to seller
        if(String.isBlank(content)) return content;

        if(String.isNotBlank(template) && FR_AGM_MERGE_FIELD_CONTENTS.contains(template)){
            String vatStatus = '';
            String lgeName = '';
            String lgeFbAddress ='';
            if(user == null){
                List<User> listUser = [Select Id, Contact.AccountId, Contact.Account.EBH_VATStatus__c, Contact.Account.ParentId, Contact.Account.Parent.Name, Contact.Account.Parent.EBH_BillingStreet__c, Contact.Account.Parent.EBH_BillingCity__c, Contact.Account.Parent.EBH_BillingPostalCode__c, Contact.Account.Parent.EBH_BillingCountry__c From User Where Id =: ApexUtil.getCurrentUser().Id And Contact.AccountId != null Limit 1];
                if(!listUser.isEmpty()) user = listUser[0];
            }
            if(user != null && user.Contact.AccountId != null){
               vatStatus = String.isNotBlank(user.Contact.Account.EBH_VATStatus__c) ? user.Contact.Account.EBH_VATStatus__c : vatStatus;
               lgeName =  (user.Contact.Account.ParentId != null) ? user.Contact.Account.Parent.Name : lgeName;

                lgeFbAddress = String.format(TXT_ADDRESS,new String[]{
                String.isNotBlank(user.Contact.Account.Parent.EBH_BillingStreet__c) ? user.Contact.Account.Parent.EBH_BillingStreet__c : '',
                String.isNotBlank(user.Contact.Account.Parent.EBH_BillingCity__c) ? user.Contact.Account.Parent.EBH_BillingCity__c : '',
                String.isNotBlank(user.Contact.Account.Parent.EBH_BillingPostalCode__c) ? user.Contact.Account.Parent.EBH_BillingPostalCode__c : '',
                String.isNotBlank(user.Contact.Account.Parent.EBH_BillingCountry__c) ? user.Contact.Account.Parent.EBH_BillingCountry__c : ''});

            }
            content = content.replace(MFLD_VAT_STATUS, vatStatus);
            content = content.replace(MFLD_LGE_NAME, lgeName);
            content = content.replace(MFLD_LGE_FBADDRESS,lgeFbAddress);
        }

        return content;
    }


    /*****************************************************************************************************************************
    @ Method:         acceptedAgreement
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0011795 - AU T&C for Seller Portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.08.2022 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0011795 : update method
    @ Change history: 11.01.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0012730 : update method
    @ Change history: 17.01.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013069 : update method
    *****************************************************************************************************************************/
    @AuraEnabled(cacheable=false)   
    public static Map<String,Object> acceptedAgreement(String region, String regionDownload) {

        // String message = 'success';
        Savepoint sp = Database.setSavepoint();
        Map<String,Object> mapResult = new Map<String,Object>();
        try {
            // List<User> lstUsers = [SELECT Id, ContactId, Contact.Accepted_Current_Deals_Agreement__c FROM User WHERE Id=:UserInfo.getUserId()];         
            List<User> lstUsers = [SELECT Id, ContactId, Contact.Accepted_Current_Deals_Agreement__c,Contact.Agreed_to_Portal_Usage_Conditions__c, Contact.AccountId,  Contact.Account.SP_Promotion_General_T_Cs_Agreed__c, Contact.Account.Name FROM User WHERE Id=:UserInfo.getUserId()];
            
            // if (!lstUsers.isEmpty() && String.isNotBlank(lstUsers[0].ContactId)) {
            // if (!lstUsers.isEmpty() && String.isNotBlank(lstUsers[0].ContactId) && !lstUsers[0].Contact.Accepted_Current_Deals_Agreement__c) { // 17.08.2022 / Sophal Noch / US-0011795
            if (!lstUsers.isEmpty() && String.isNotBlank(lstUsers[0].ContactId)) {     
            
                // 17.01.2023 / Sophal Noch / US-0013069 : if already agreed, skip the process.
                if((NDA_ACCEPTANCE_REGIONS.contains(region) && lstUsers[0].Contact.Agreed_to_Portal_Usage_Conditions__c)
                    || (SPPROMOTION_GENERAL_REGIONS.contains(region) && lstUsers[0].Contact.AccountId != null && lstUsers[0].Contact.Account.SP_Promotion_General_T_Cs_Agreed__c)
                    || (!NDA_ACCEPTANCE_REGIONS.contains(region) && !SPPROMOTION_GENERAL_REGIONS.contains(region) && lstUsers[0].Contact.Accepted_Current_Deals_Agreement__c)
                ){
                    mapResult.put('status','ok'); return mapResult;
                }

                Date todayDate = Date.today();

                //if(!Test.isRunningTest()) update new Contact(Id=lstUsers[0].ContactId, Accepted_Current_Deals_Agreement__c=true); // The reason ignore update contact: User Portal in test class cannot update Contact INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY
                Contact contactToUpdate = new Contact(Id=lstUsers[0].ContactId); 
                // 17.01.2023 / Sophal Noch / US-0013069 : update contact fields depending on agreement
                if(NDA_ACCEPTANCE_REGIONS.contains(region)){
                    contactToUpdate.Agreed_to_Portal_Usage_Conditions__c = true;
                    contactToUpdate.Agreed_to_Portal_Usage_Conditions_Date__c = todayDate;
                }else if(!NDA_ACCEPTANCE_REGIONS.contains(region) && !SPPROMOTION_GENERAL_REGIONS.contains(region)){
                    contactToUpdate.Accepted_Current_Deals_Agreement__c=true;
                }

                if(!SPPROMOTION_GENERAL_REGIONS.contains(region)) update contactToUpdate;
                
                // 11.01.2023 / Sophal Noch / US-0012730 : store date and approver in account for FR agreement
                if(SPPROMOTION_GENERAL_REGIONS.contains(region) && lstUsers[0].Contact.AccountId != null){

                    Account accToUpdate = new Account(
                        Id = lstUsers[0].Contact.AccountId,
                        SP_Promotion_General_T_Cs_Agreed_by__c = ApexUtil.getCurrentUser().Id,
                        SP_Promotion_General_T_Cs_Agreed_Date__c = todayDate,
                        SP_Promotion_General_T_Cs_Agreed__c = true
                        
                    );
    
                    update accToUpdate;
                }

                 // 11.01.2023 / Sophal Noch / US-0012730 : gemerate pdf and attach it to account
                if(AUTODOWNLOADFILE_REGIONS.contains(region) && String.isNotBlank(regionDownload) && lstUsers[0].Contact.AccountId != null){

                    Pagereference pdfPage = Page.AgreementTermsDownloadPage;
                    pdfPage.getParameters().put('template',regionDownload);

                    Blob pdfContent = !Test.isRunningTest()?pdfPage.getContent():Blob.valueOf('test');

                    //Insert ContentVersion

                    String pdfName = PDF_NAME;
                    if(FR_AGM_MERGE_FIELD_CONTENTS.contains(regionDownload)){ // use email template subject as PDF name
                        List<EmailTemplate> emTpt = [Select Id,Subject From EmailTemplate Where DeveloperName =: regionDownload Limit 1];
                        if(!emTpt.isEmpty()){
                            pdfName = emTpt[0].Subject;
                            pdfName = pdfName.replace(MFLD_ACCOUNT_NAME, lstUsers[0].Contact.Account.Name);
                            pdfName = pdfName.replace(MFLD_SPG_TC_AGREEDDATE, todayDate.format());
                        }
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
                    cDocLink.LinkedEntityId = lstUsers[0].Contact.AccountId;//Add attachment parentId
                    cDocLink.ShareType = 'V';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                    
                    WithoutSharing.doInsert(new ContentDocumentLink[]{cDocLink});

                    mapResult.put('attachmentId',cVersion.Id);
                }

                mapResult.put('status','ok');
            }
            
        // } catch (Exception e) { message = e.getMessage();Database.rollback(sp); } 
    } catch (Exception e) { mapResult.put('status','ko'); mapResult.put('error',e.getMessage()); Database.rollback(sp); } 

        // return message; 
       return mapResult;

    }

/*****************************************************************************************************************************
    @ Method:         getFooterContent
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0013069 - Mandatory NDA for Influencer Portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.01.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013069 : create method
    *****************************************************************************************************************************/
    @AuraEnabled(cacheable=false)   
    public static Map<String,Object> getFooterContent(String footerRegion, Boolean enableDownload, String regionDownload) {
        Map<String,Object> mapResult = new Map<String,Object>();
        try {
            
            mapResult.put('hasFooterContent', false);
            mapResult.put('hasDownloadContent', false);

            String footerContent;
            if(String.isNotBlank(footerRegion)){
                footerContent =[Select Id, HtmlValue From EmailTemplate Where DeveloperName =: footerRegion Limit 1]?.HtmlValue;
            }
            if(String.isNotBlank(footerContent)){
                mapResult.put('hasFooterContent', true);
                mapResult.put('footerContent',[Select Id, HtmlValue From EmailTemplate Where DeveloperName =: footerRegion Limit 1]?.HtmlValue);
            }

            String downloadContent;
            if(enableDownload && String.isNotBlank(regionDownload)){
                Pagereference pdfPage = Page.AgreementTermsDownloadPage;
                pdfPage.getParameters().put('template',regionDownload);
                downloadContent = EncodingUtil.base64encode(!Test.isRunningTest() ? pdfPage.getContentAsPdf() : Blob.valueOf('test'));
                mapResult.put('hasDownloadContent', true);
                mapResult.put('downloadContent', downloadContent);
                mapResult.put('fileName', (PDF_NAME + '.pdf'));
            }

            mapResult.put('status','ok');
        } catch (Exception e) { mapResult.put('status','ko'); mapResult.put('error',e.getMessage());}
        return mapResult;
    }
    
}