/*********************************************************************************************************************************
@ Class:          InviteSellerSubDealDCADetailController
@ Version:        1.0
@ Author:         vadhanak (vadhanak.voun@gaea-sys.com)
@ Purpose:        US-0016449 - 9 - Notify seller when DCA is created
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.02.2025 / vadhanak/ Created the class.
*********************************************************************************************************************************/
public with sharing class InviteSellerSubDealDCADetailController {

    @testVisible private final static String DCA_STATUS_WAITING_FOR_SUBMISSION = 'Waiting for Submissions';
     /*****************************************************************************************************************************
	@ Method:   apexInviteSeller
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  US-0016449 - 9 - Notify seller when DCA is created
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:     dcaId: String
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 05.02.2025 / vadhanak/ Created the method
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexInviteSeller(String dcaId,Map<String,Object> moreParam)
    {  
        Boolean dontSendToSeller = (Boolean)moreParam.get('dontSendToSeller');
        Map<String,Object> mapResult = new Map<String,Object>{'status'=>'ok'};
        String soqlDCA = 'SELECT Id,Status__c,eBay_Seller__c FROM Deal_Contract_Agreement__c WHERE Id = :dcaId';
        System.SavePoint sp = Database.setSavepoint();

        try 
        {
            List<Deal_Contract_Agreement__c> listDCA = (List<Deal_Contract_Agreement__c>)ApexSafe.query().secCheck(false).doQuery(soqlDCA,new Map<String, Object> {'dcaId' => dcaId});
            listDCA[0].Status__c = DCA_STATUS_WAITING_FOR_SUBMISSION;

            ApexSafe.dml().secCheck(false).doUpdate(listDCA,true);
            
            if(!dontSendToSeller)
            {
                DealContractAgreementTriggerHandler.createSellerComsByDCA('Deals',new Map<String,String>{dcaId=>listDCA[0].eBay_Seller__c},'Deal Contract initiation notification to seller - US', 'Deal Contract initiation notification to seller - US');
            }
            
        } catch (DMLException dx) 
        {System.debug(dx);mapResult.put('status','ko');mapResult.put('error',dx.getMessage());mapResult.put('errorDetail',dx.getStackTraceString());Database.rollback(sp);}
        

        return mapResult;
    }
     
}