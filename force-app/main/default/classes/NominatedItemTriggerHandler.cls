/*********************************************************************************************************************************
@ Class:          NominatedItemTriggerHandler
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        Handler Class for trigger NominatedItem
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 29.05.2019 / Sovantheany Dim / Created the class.
@				  17.08.2023 / SRONG TIN / 0013664 - Block FVF records for Change after submission
@				: 06/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
*********************************************************************************************************************************/
public without sharing class NominatedItemTriggerHandler {
	// SRONG: 17.08.2023: US-0013664 - Block FVF records for Change after submission
	public final static String SOQL_FINAL_VALUE_FEE = 'SELECT Id, RecordTypeId,Final_Value_Fee_Stage__c from Final_Value_Fee_FVF__c';


    /*****************************************************************************************************************************
    @ Method:   createNorminatedItem
    @ Version:  1.0
    @ Author: 	Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:	EPH-7549
Nominated items object. Fields should be populated by trigger not by formula
 the following fields in the nominated items object should be populated by trigger not by formula fields:

EPID
EAN
eBay Link/
Listing Name
Take rate
Price(seller)
Product ID
    @ Event:	Before Insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Nominated_Item__c> listNewNominatedItem
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 29.05.2019 / Sovantheany Dim / Created the  Method
	@  				: 06/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
    *****************************************************************************************************************************/
    /*public static void updatedNorminatedItem(List<Nominated_Item__c> listNewNominatedItem)
    {
    	Set<String> setSellerToProd = new Set<String>();
    	for(Nominated_Item__c item : listNewNominatedItem){
    		if(item.Inventory_Diagnostic__c == null) continue;
    		setSellerToProd.add(item.Inventory_Diagnostic__c);
    	}
    	
    	if(setSellerToProd.isEmpty()) return;
    	
    	Map<String,Seller_to_Product__c> mapSellertoProd = new Map<String, Seller_to_Product__c>();
    	for(Seller_to_Product__c s : Database.query(EBH_ConstantsUtility.SOQL_SELLER_TO_PRODUCT + ' Where Id IN: setSellerToProd')){
    		mapSellertoProd.put(s.Id,s);
    	}
    	for(Nominated_Item__c item : listNewNominatedItem){
    		if(item.Inventory_Diagnostic__c == null) continue;
    		if(!mapSellertoProd.containsKey(item.Inventory_Diagnostic__c)) continue;
    		Seller_to_Product__c sellerToProduct = mapSellertoProd.get(item.Inventory_Diagnostic__c);
    		item.EPID_w__c = sellerToProduct.EPID__c;
    		item.EAN_w__c = sellerToProduct.Product__r.EAN__c;
    		item.eBay_Link_w__c=sellerToProduct.eBay_Link__c;
    		item.Listing_Name_w__c=sellerToProduct.Listing_Title__c;
			item.Take_Rate_w__c=sellerToProduct.Take_Rate__c;
			item.Price_seller_w__c=sellerToProduct.Price_seller__c;
    		item.Product_ID_w__c = sellerToProduct.Product__r.Product_ID__c;
    	}
    }
	*/

	/*****************************************************************************************************************************
    @ Method:   lockRecordIsFVFStageNotDraft
    @ Version:  1.0
    @ Author: 	SRONG TIN (srong.tin@gaea-sys.com)
    @ Purpose:	US-0013664 - Block FVF records for Change after submission
    @ Event:	Before Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Nominated_Item__c> listNewNominatedItem
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 17.08.2023 / Srong Tin / Created the  Method
    *****************************************************************************************************************************/
	public static void lockRecords(List<Nominated_Item__c> listNewNominatedItem)
    {
		Boolean isAdmin = (Userinfo.getprofileId()==ApexUtil.ADMIN_PROFILE_ID);
		Boolean isAdminPriv = (Userinfo.getprofileId()==ApexUtil.ADMIN_LT_PRIV_PROFILE_ID);
		RecordType fvfRecordTypeListing = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c',FinalValueFee_FVF_Handler.FVF_LISTING_RECORDTYPE);
		RecordType fvfRecordTypeSeller = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c',FinalValueFee_FVF_Handler.FVF_SELLER_RECORDTYPE);
		Set<Id> fvfId = new Set<Id>();
		if(!isAdmin && !isAdminPriv){
			for(Nominated_Item__c onefvf : listNewNominatedItem){
				fvfId.add(onefvf.Final_Value_Fee_FVF__c);
			}
			Map<ID,Final_Value_Fee_FVF__c> fvf = new Map<ID,Final_Value_Fee_FVF__c>((List<Final_Value_Fee_FVF__c>)Database.query(SOQL_FINAL_VALUE_FEE + ' Where Id IN :fvfId'));
			for(Nominated_Item__c oneNom : listNewNominatedItem){
				if((fvf.get(oneNom.Final_Value_Fee_FVF__c).RecordTypeId == fvfRecordTypeListing.Id || fvf.get(oneNom.Final_Value_Fee_FVF__c).RecordTypeId == fvfRecordTypeSeller.Id) && fvf.get(oneNom.Final_Value_Fee_FVF__c).Final_Value_Fee_Stage__c != FinalValueFee_FVF_Handler.FVF_STAGE_DRAFT){
					oneNom.addError(Label.Error_Update_Record_FVF_Not_Stage_Draft);
				}
			}
			
		}

    }

	
	/*****************************************************************************************************************************
    @ Method:   populatedListinIDAndPriceTargetField
    @ Version:  1.0
    @ Author: 	Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:	EPH-7367 New Object: Nominated Items & Bulk Upload
    @ Event:	Before Insert , before updated
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Nominated_Item__c> listNewNominatedItem, Map<ID,Nominated_Item__c> mapOld
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 04.06.2019 / Sovantheany Dim / Created the  Method
	@				: 06/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects	
    *****************************************************************************************************************************/
    /*
    public static void populatedListinIDAndPriceTargetField(List<Nominated_Item__c> listNewNominatedItem, Map<ID,Nominated_Item__c> mapOld)
    {
    	Set<String> setSellerToProd = new Set<String>();
    	Boolean isNew = (mapOld==null);
    	for(Nominated_Item__c item : listNewNominatedItem){
    		if(item.Inventory_Diagnostic__c == null) continue;
    		if((isNew && !item.From_Upload__c) || (!isNew && item.Inventory_Diagnostic__c != mapOld.get(item.Id).Inventory_Diagnostic__c)){
    			setSellerToProd.add(item.Inventory_Diagnostic__c);
    		}
    	}
    	if(setSellerToProd.isEmpty()) return;
    	
    	Map<String,Seller_to_Product__c> mapSellertoProd = new Map<String, Seller_to_Product__c>();
    	for(Seller_to_Product__c s : Database.query(EBH_ConstantsUtility.SOQL_SELLER_TO_PRODUCT + ' Where Id IN: setSellerToProd')){
    		mapSellertoProd.put(s.Id,s);
    	}
    	
    	for(Nominated_Item__c item : listNewNominatedItem){
    		if(item.Inventory_Diagnostic__c == null) continue;
    		if(!mapSellertoProd.containsKey(item.Inventory_Diagnostic__c)) continue;
    		Seller_to_Product__c sellerToProduct = mapSellertoProd.get(item.Inventory_Diagnostic__c);
    		item.Listing_ID_w__c = sellerToProduct.Listing_ID__c;
    		item.Price_target_w__c = sellerToProduct.Product__r.Price_competitor__c;
    	}
    }
    */
    /*****************************************************************************************************************************
    @ Method:   updateNominatedByOwnerAndRequestor
    @ Version:  1.0
    @ Author: 	Sreymeas Nao (sreymeas.nao@gaea-sys.com)
    @ Purpose:	US-0015722 Enable Users to edit fields in Nominated Items
	@		    AC: Given that I am either Owner or Requestor of the FVF record
	@		    Then I  can edit the following fields in the related Nominated Items records: 
    @ Event:	After Insert, After Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Nominated_Item__c> listNewNominatedItem
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 04.10.2019 / Sreymeas Nao / Created the  Method
	@				: 10/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
	@				: this method is not used since US-0007212  (commeted from the trigger). Now completely commented the method
    *****************************************************************************************************************************/
	/*
    public static void updateNominatedByOwnerAndRequestor(List<Nominated_Item__c> listNewNominatedItem){
		Set<Id> fvfId = new Set<Id>();
		Boolean isAdmin = Userinfo.getprofileId() == ApexUtil.getProfileByName('System Administrator').Id;
		RecordType fvfRecordTypeSellerCommunication = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c','Seller_Communication');
        for(Nominated_Item__c onefvf : listNewNominatedItem){
			fvfId.add(onefvf.Final_Value_Fee_FVF__c);
        }
        
        Map<ID,Final_Value_Fee_FVF__c> fvf = new Map<ID,Final_Value_Fee_FVF__c>((List<Final_Value_Fee_FVF__c>)Database.query(EBH_ConstantsUtility.SOQL_FINAL_VALUE_FEE + ' Where Id IN :fvfId'));
        
        for(Nominated_Item__c oneNom : listNewNominatedItem){
          if(!isAdmin){
              if(UserInfo.getUserId() <> fvf.get(oneNom.Final_Value_Fee_FVF__c).Requestor__c && UserInfo.getUserId() <> fvf.get(oneNom.Final_Value_Fee_FVF__c).OwnerId && fvf.get(oneNom.Final_Value_Fee_FVF__c).RecordTypeId <> fvfRecordTypeSellerCommunication.Id){
                  oneNom.addError(label.ERR_MSG_NOMINATED);
              }
            }
        }
    }
    */
    /*****************************************************************************************************************************
    @ Method:   populateDiscountFVF
    @ Version:  1.0
    @ Author: 	Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:	US-0007060 Possibility to adjust FVF discount
	@		    Adjust a trigger so that it copies values from FVF. Discount_FVF__c to Nominated_Item__c.Discount_FVF__c once new Nominated items are created
    @ Event:	Before Insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Nominated_Item__c> listNewNominatedItem
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 11.02.2020 / Sovantheany Dim / Created the  Method
    *****************************************************************************************************************************/
    public static void populateDiscountFVF(List<Nominated_Item__c> listNewNominatedItem){
    	Set<Id> fvfId = new Set<Id>();
    	for(Nominated_Item__c item : listNewNominatedItem){
    		if(item.Final_Value_Fee_FVF__c == null) continue;
    		fvfId.add(item.Final_Value_Fee_FVF__c);
    	}
    	Map<ID,Final_Value_Fee_FVF__c> mapfvf = new Map<ID,Final_Value_Fee_FVF__c>((List<Final_Value_Fee_FVF__c>)Database.query(EBH_ConstantsUtility.SOQL_FINAL_VALUE_FEE + ' Where Id IN :fvfId'));
    	for(Nominated_Item__c item : listNewNominatedItem){
    		if(!mapfvf.containsKey(item.Final_Value_Fee_FVF__c)) continue;
    		Final_Value_Fee_FVF__c fvf = mapfvf.get(item.Final_Value_Fee_FVF__c);
    		item.Discount_FVF_w__c = fvf.Discount_FVF__c;
    	}
	}
}