/*********************************************************************************************************************************
@ Class:          SendWithDocuSignController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Controller Class for EBH_SendWithDocuSign
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  23.07.2021 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
public without sharing class SendWithDocuSignController {

    public String docuSignUrl {get;set;}
    public Boolean isError {get;set;}
    
    public SendWithDocuSignController(ApexPages.StandardController controller){
        isError = !ApexUtil.checkPermissionSet(new Set<String>{'DocuSign_User'});
    }

    /*****************************************************************************************************************************************************************
    @ Method:         sendWithDocuSign
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0009886 - [Docusign] Automation to autopopulate Contract.Business  Contact as Recipient 2 in Docusign 
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  23.07.2021 / Sophal Noch / Created the method.
    ***********************************************************************************************************************************************************/
    public PageReference sendWithDocuSign(){
        PageReference newPage = new PageReference(docuSignUrl);
        newPage.setRedirect(true);
        return newPage;
    }

}