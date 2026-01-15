/*********************************************************************************************************************************
@ Class:          CloneFVFController
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        EPH-7680 Clone function on FVF promo clones Nominated Items
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.08.2019 / Sovantheany Dim / Created the class.
*********************************************************************************************************************************/
public without sharing class CloneFVFController {
    /*****************************************************************************************************************************
	@ Method:   apexCloneFVF
	@ Version:  1.0
	@ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
	@ Purpose:  EPH-7680 Clone function on FVF promo clones Nominated Items
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      parentId:  fvfId
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 20.08.2019 / Sovantheany Dim / Created the  Method.
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexCloneFVF(String parentId)
    {
    	Map<String,Object> mapResult = new Map<String,Object>();
		try
		{
			String soqlFVF  = 'Select RecordTypeId,Campaign_Name__c, Requestor__c,final_Value_Fee_Stage__c,Seller_Name__c,Discount_FVF__c,Free_shipping__c,Start_Date_w__c,End_Date_w__c,Start_Time__c,End_Time__c,Contact_Person__c,Seller_Email__c From Final_Value_Fee_FVF__c Where Id=:parentId';
			String soqlNominateItem  = 'Select Listing_ID_w__c,Price_target_w__c From Nominated_Item__c Where Final_Value_Fee_FVF__c =: parentId';
			List<Final_Value_Fee_FVF__c> fvfs = Database.query(soqlFVF);
    		Final_Value_Fee_FVF__c clonefvf = fvfs[0].clone(false,true,false,false);
    		clonefvf.Campaign_Name__c = (fvfs[0].Campaign_Name__c == null ? '': fvfs[0].Campaign_Name__c) + '_Clone';
    		clonefvf.final_Value_Fee_Stage__c = 'Draft';
    		insert clonefvf;
    		List<Nominated_Item__c> lstNominateToClone = new List<Nominated_Item__c>();
    		for(Nominated_Item__c nominateItem : Database.query(soqlNominateItem)){
    			Nominated_Item__c nominatedClone = nominateItem.clone(false,true,false,false);
    			nominatedClone.Final_Value_Fee_FVF__c = clonefvf.Id;
    			lstNominateToClone.add(nominatedClone);  
    		}
    		if(!lstNominateToClone.isEmpty()){
    			insert lstNominateToClone;
    		}
			mapResult.put('status','ok');
			mapResult.put('fvfID',clonefvf.Id+'');
		}
		catch(DmlException ex)
		{
			mapResult.put('status','ko');
			mapResult.put('error',ex.getDmlMessage(0));
			System.debug(ex);
		}catch(Exception ex2)
		{
			mapResult.put('status','ko');
			mapResult.put('error',ex2.getMessage());
			System.debug(ex2);
		}
    	
    	return mapResult;
    }
}