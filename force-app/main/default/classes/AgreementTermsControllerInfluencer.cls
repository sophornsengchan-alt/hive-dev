/*********************************************************************************************************************************
@ Class:         AgreementTermsControllerInfluencer
@ Version:       1.0
@ Author:        Sophal Noch
@ Purpose:       Controller for lwcAgreementTermsInfluencer, logic is copied from lwcAgreementTermsController.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
public with sharing class AgreementTermsControllerInfluencer extends AbstractAgreementTermsController{


    /*****************************************************************************************************************************
    @ Method:         AgreementTermsControllerInfluencer
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013171 - Make agreement component more scalable
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / create method
    *****************************************************************************************************************************/
    public AgreementTermsControllerInfluencer(){
        if(ApexPages.currentPage() != null){
            // controller for visual force page AgreementTermsDownloadSEPPage.page
            String regionDownload = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(AbstractAgreementTermsController.PARAM_REGION_DOWNLOAD)==null?'':ApexPages.currentPage().getParameters().get(AbstractAgreementTermsController.PARAM_REGION_DOWNLOAD));
            htmlContent = [Select Id, HtmlValue From EmailTemplate Where DeveloperName =: regionDownload]?.HtmlValue;
        }
    }

    /*****************************************************************************************************************************
    @ Method:         getAgmtState
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013171 - Make agreement component more scalable
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / create method
    *****************************************************************************************************************************/
    public override Boolean getAgmtState(){ 
        // get state of NDA influencer agreement whether it is agreed or not yet agreed.
        // it overwrites parent class method AbstractAgreementTermsController.
        return currentUser.Contact.Agreed_to_Portal_Usage_Conditions__c;
    }

    /*****************************************************************************************************************************
    @ Method:         updateAgmtState
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013171 - Make agreement component more scalable
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / create method
    *****************************************************************************************************************************/
    public override void updateAgmtState(){ 
        // agree the NDA influencer agreement
        // it overwrites parent class method AbstractAgreementTermsController.
        Contact contactToUpdate = new Contact(Id=currentUser.ContactId, Agreed_to_Portal_Usage_Conditions__c = true, Agreed_to_Portal_Usage_Conditions_Date__c = todayDate); 
        WithoutSharing.doUpdate(new List<Contact>{contactToUpdate});
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
            AgreementTermsControllerInfluencer contr = new AgreementTermsControllerInfluencer(); // orginiated from user story US-0013069
            contr.doInitAgmt(agmtMdtName);
            mapResult.put('agmtMdt', contr.agmtMdt);
            mapResult.put('agreementContent', contr.agreementContent);
            mapResult.put('result', contr.getAgmtState());

            mapResult.put('footerContent',[Select Id, HtmlValue From EmailTemplate Where DeveloperName =: contr.agmtMdt.Footer_Region__c Limit 1]?.HtmlValue); // get content of footer

            Pagereference pdfPage = Page.AgreementTermsDownloadInfluencerPage; // get NDA pdf content for download,
            pdfPage.getParameters().put(AbstractAgreementTermsController.PARAM_REGION_DOWNLOAD, contr.agmtMdt.Region_Download__c);
            mapResult.put('downloadContent', EncodingUtil.base64encode(!Test.isRunningTest() ? pdfPage.getContentAsPdf() : Blob.valueOf('test'))); 
            mapResult.put('fileName', (AbstractAgreementTermsController.PDF_NAME + '.pdf'));

            mapResult.put('status','ok');

        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }

        return mapResult;
    }

    /*****************************************************************************************************************************
    @ Method:         acceptedAgreement
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013171 - Make agreement component more scalable
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / create method
    *****************************************************************************************************************************/    
    @AuraEnabled(cacheable=false)   
    public static Map<String,Object> acceptedAgreement(String agmtMdtName) {
        Savepoint sp = Database.setSavepoint();
        Map<String,Object> mapResult = new Map<String,Object>();
        try {
            AgreementTermsControllerInfluencer contr = new AgreementTermsControllerInfluencer(); // orginiated from user story US-0013069
            contr.doAcceptAgmt(agmtMdtName);
            mapResult.put('status','ok');
        }catch (Exception e) { mapResult.put('status','ko'); mapResult.put('error',e.getMessage()); Database.rollback(sp); } 
       return mapResult;
    }

}