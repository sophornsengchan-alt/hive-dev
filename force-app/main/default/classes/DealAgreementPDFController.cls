/*
    /*************************************************************************************************************************************
    @ Class:          DealAgreementPDFController
    @ Version:        1.0
    @ Description:    Controller class for APEX Page DealAgreementPDF.page
    @ Author:         Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:        US-0009152 - [NA] Include Full Deals Agreement in Contract PDF sent to Seller
                      US-0009153 - [NA] Attach copy of accepted Deals Agreement to 'Deal Contract Agreement'
                      US-0009333 - [NA] Update Contracts content for Seller Approval Microsite Page
    --------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.03.2021 / Mony Nou / code creation
                       02.04.2021 / Mony Nou / US-0009333 - [NA] Update Contracts content for Seller Approval Microsite Page
                            - AC1) There is no longer a need for the additional Canadian agreement. There will only be US-Standard and Canada-Standard.
    ----------------------------------------------------------------------------------------------------------------------------------
*/
public Without Sharing class DealAgreementPDFController {

    // public Static String VFCMP_Deal_Agreement_CA_Quebec   = 'Deal_Agreement_CA_Quebec'; //MN-02042021 - US-0009333 - No longer use this one
    public Static String VFCMP_Deal_Agreement_CA_Standard = 'Deal_Agreement_CA_Standard'; //DEFAULT ONE
    public Static String VFCMP_Deal_Agreement_US_Standard = 'Deal_Agreement_US_Standard';

    private String vfcmp;
    private String accid;

    public DocumentApprovalController documentApprovalCont {get;set;}

    public DealAgreementPDFController() {

        documentApprovalCont = new DocumentApprovalController();
        documentApprovalCont.isPDF = true;

        // MN-05042021 - US-0009333
        vfcmp = getParamValue('vfcmp');
        if (String.isBlank(vfcmp)) vfcmp = VFCMP_Deal_Agreement_CA_Standard;
        
        accid = getParamValue('accid');
        
        if (String.isNotBlank(accid)) { //Need to display infor from Deal into PDF
            for (Account acc : [SELECT Agreement_Addendum__c FROM Account WHERE Id=:accid]) { 
                documentApprovalCont.sellerAgreementAddendum = acc.Agreement_Addendum__c;
            }
        }
        // END - MN-05042021 - US-0009333
        
        /* MN-05042021 moved it to use with function getParamValue()
        vfcmp = VFCMP_Deal_Agreement_CA_Standard; //MN-02042021 - US-0009333 - Change default one to CA Standard
        if (ApexPages.currentPage().getParameters().containsKey('vfcmp')) {
            String tmp = ApexPages.currentPage().getParameters().get('vfcmp'); 
            if (String.isNotBlank(tmp)) vfcmp = String.escapeSingleQuotes(tmp);
        }
        */

    }

    private String getParamValue(String urlparam) {
        String val = '';
        if (ApexPages.currentPage().getParameters().containsKey(urlparam)) {
            String tmp = ApexPages.currentPage().getParameters().get(urlparam);
            if (String.isNotBlank(tmp)) val = String.escapeSingleQuotes(tmp); 
        }
        
        return val;
    }

    //Return the correct VF Component to VF Page
    public ApexPages.Component getCustomComponent() {
        
        // if (vfcmp==VFCMP_Deal_Agreement_CA_Quebec) return new Component.c.Deal_Agreement_CA_Quebec(); //MN-02042021 - US-0009333 - No longer use this one
        if (vfcmp==VFCMP_Deal_Agreement_CA_Standard) return new Component.c.Deal_Agreement_CA_Standard(documentApprovalCont=documentApprovalCont); // MN-05042021 - US-0009333 - Pass value into VF Component's attribute
        else if (vfcmp==VFCMP_Deal_Agreement_US_Standard) return new Component.c.Deal_Agreement_US_Standard(documentApprovalCont=documentApprovalCont); // MN-05042021 - US-0009333 - Pass value into VF Component's attribute
        return new Component.c.Deal_Agreement_CA_Standard(); //Default one  //MN-02042021 - US-0009333 - Change default one to CA Standard
    }
}