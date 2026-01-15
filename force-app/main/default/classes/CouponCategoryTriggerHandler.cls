/*********************************************************************************************************************************
@ Class:          CouponSellerTriggerHandler
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        Handler Class for trigger Coupon Seller
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 10.04.2019 / Sovantheany Dim / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.08.2021 / Mony Nou  / US-0009746 - Coupon - enable deletion of coupon related records
@				: 14.08.2023 / LoumAng SENG / US-0013973 - Introduce new coupon type for Long Term Coupons(AC7)
*********************************************************************************************************************************/
public without sharing class CouponCategoryTriggerHandler {
   /****************************************************************************************************************************
	* CONSTANTS DEFINITION
	*****************************************************************************************************************************/
	private final static String SOQL_COUPON_SELLER_2 = 'Select Coupon__r.Couponsite_s__c,Seller__r.Strategic_Seller_Share_w__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Language__c, Date_4days_Sent__c, Date_34_days_Sent__c, TriggerEmailManhattan__c, Id,Seller__c,Seller__r.EBH_OracleID__c,Coupon__c,Coupon_Seller_Stage__c,Coupon__r.RecordTypeID,Coupon__r.RecordType.DeveloperName,Coupon__r.Stage__c,SellerShareHolder__c From Coupon_Seller__c' ;

	private static String COUPON_STAGE_DRAFT 				= 'Draft'; //MN-06082021-US-0009746
	private static String COUPON_STAGE_SELLERNEGOTIATION 	= 'Seller Negotiation'; //MN-06082021-US-0009746
	private static String SOQL_COUPON = 'Select Id, Main_Coupon_Site__c from Coupon__c';
	private final static String COUPON_SCMC_CATEGORYBASE = 'Single_Contract_Multi_Coupon_SCMC_Category_Based';
	private final static String COUPON_CATEGORYBASE = 'Category_Based';
	/************************************END CONSTANTS DEFINITION*************************************************************/
    
	
	/*****************************************************************************************************************************
    @ Method:   preventRecordDeletion
    @ Version:  1.0
    @ Author: 	Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:	US-0009746 - Coupon - enable deletion of coupon related records
	@ Event:	Before Delete
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: Map<Id, Coupon_Category__c> oldMap  
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 06.08.2021 / Mony / Created the  Method
					  01.05.2024 / David Herrero / Added bypass 
	*****************************************************************************************************************************/
	public static void preventRecordDeletion(Map<Id, Coupon_Category__c> oldMap) {

		//1st Filtering - By checking Current User
		Set<String> validDeleteCouponStage = new Set<String>{ COUPON_STAGE_DRAFT, COUPON_STAGE_SELLERNEGOTIATION };
		Boolean isAdmin = (Userinfo.getprofileId()==ApexUtil.ADMIN_PROFILE_ID);

		Map<Integer, String> mErrorMsg = new Map<Integer,String> {
			1 => System.Label.Prevent_Deletion_of_Coupon_Seller_Item_Category,
			2 => System.Label.Prevent_Deletion_of_Coupon_Category
		};

		Set<Id> sCCIds = new Set<Id>();
		byPass__c bp = byPass__c.getInstance(UserInfo.getUserId()); //initiate bypass trigger
       
		if (bp!=null && bp.byPass_Trigger__c && !String.isBlank(bp.triggerObjects__c)
		 && bp.triggerObjects__c.containsIgnoreCase('Coupon_Category__c')) {return;} //bypass trigger

		for (Coupon_Category__c cc : [SELECT Coupon__r.Stage__c FROM Coupon_Category__c WHERE Id IN:oldMap.keySet()]) {
			Integer msg_idx = ((!isAdmin && Userinfo.getUserId() != oldMap.get(cc.Id).OwnerId)?1:(!validDeleteCouponStage.contains(cc.Coupon__r.Stage__c)?2:0));
			if (mErrorMsg.containsKey(msg_idx)) oldMap.get(cc.Id).addError(mErrorMsg.get(msg_idx));
			else sCCIds.add(cc.Id);

		}

		if (sCCIds.isEmpty()) return;

		//Find all Coupon_Co_Invest__c related to those deleting Coupon Category then delete it
		delete [SELECT Id FROM Coupon_Co_Invest__c WHERE Coupon_Category__c IN:sCCIds];

	}
	
	/*****************************************************************************************************************************
    @ Method:   createCoInvestOnceCouponCategoryCreated
    @ Version:  1.0
    @ Author: 	Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:	
    			[#EPH-7253] Object_ Coupon Co-Invest
    			
    			i)Pagelayout Coupon Co-Invest Seller (Record Type)

				Automatically create Coupon co-invest record type = Coupon Co-Invest Seller if:
				Coupon type = Seller / Category Based (From Object Coupon__C)
				Coupon Category is added with category level = 0 (From Object Coupon_Category_c) 
				Coupon Seller is created and linked to Coupon
				User update Coupon stage to = Seller Negotiation (From Object Coupon__C)
				Once user changed the status, Co-invest type Coupon Co-Invest Seller will be created automatically with all fields populated and read only except field Co-Invest % which is editable
				
				ii)Pagelayout Coupon Co-Invest Category (Record type)
				
				Automatically create Coupon co-invest record type = Coupon Co-Invest Category if:
				
				Coupon type = Seller / Category Based  (From Object Coupon__C)
				Coupon Category is added with category level > 0  (From Object Coupon_Category_c) 
				Coupon Seller is created and linked to Coupon
				User update Coupon stage to = Seller Negotiation (From Object Coupon__C)
				Once user changed the status, Co-invest type Coupon Co-Invest Category will be created automatically with all fields populated and read only except field Co-Invest % which is editable
				
    @ Event:	After Insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon_Category__c> listNewCategory
    ------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 18.04.2019 / Sovantheany Dim / Created the  Method
						22/10/2020/ Acmatac SEING / US-0007666 include 1 more status into the trigger (Coupon Running).  
	@				: 14.08.2023 / LoumAng SENG / US-0013973 - Introduce new coupon type for Long Term Coupons(AC7)  
    *****************************************************************************************************************************/
    public static void createCoInvestOnceCouponCategoryCreated(List<Coupon_Category__c> listNewCategory)
    {
    	String whereCl = ' where ID IN: listNewCategory and Exception_Category__c = false';
		Map<ID,List<Coupon_Category__c>> mapCouponCategory = new Map<ID,List<Coupon_Category__c>>();
		//LA-14-08-2023-US-0013973: add new recordtype SCMC-Category Based
		Set<String> sValidCouponRT = new Set<String>{COUPON_CATEGORYBASE,COUPON_SCMC_CATEGORYBASE};
		//TH:US-0012096 : USE CouponTriggerHandler.SOQL_COUPONCATEGORY instead of EBH_ConstantsUtility.SOQL_COUPONCATEGORY
    	for(Coupon_Category__c cc : Database.query(CouponTriggerHandler.SOQL_COUPONCATEGORY + whereCl)){
			//LA-14-08-2023-US-0013973: add new recordtype SCMC-Category Based
    		//if(cc.Coupon__c != null && (cc.Coupon__r.RecordType.DeveloperName == EBH_ConstantsUtility.COUPON_CATEGORYBASE) && (cc.Coupon__r.Stage__c == CouponTriggerHandler.COUPON_SELLER_NEGOTIATION_STAGE || cc.Coupon__r.Stage__c == CouponTriggerHandler.COUPON_RUNNING_STAGE)){
				if(cc.Coupon__c != null && sValidCouponRT.contains(cc.Coupon__r.RecordType.DeveloperName) && (cc.Coupon__r.Stage__c == CouponTriggerHandler.COUPON_SELLER_NEGOTIATION_STAGE || cc.Coupon__r.Stage__c == CouponTriggerHandler.COUPON_RUNNING_STAGE)){
    			List<Coupon_Category__c> lstCategory = new List<Coupon_Category__c>();
    			if(mapCouponCategory.containskey(cc.Coupon__c)) lstCategory = mapCouponCategory.get(cc.Coupon__c);
    			lstCategory.add(cc);
    			mapCouponCategory.put(cc.Coupon__c,lstCategory);
    		}
    	}
    	
    	if(mapCouponCategory.isEmpty()) return;
    	
    	Set<ID> sCoupon = mapCouponCategory.keySet();
    	Map<String,RecordType> coInvestRecordType = ApexUtil.getRecordTypeBySobjectName('Coupon_Co_Invest__c');
    	List<Coupon_Co_Invest__c> lstCoInvestToCreated = new List<Coupon_Co_Invest__c>();
    	String whereSellerCl = ' where Coupon__c IN: sCoupon';
    	for(Coupon_Seller__c coSeller : Database.query(SOQL_COUPON_SELLER_2 + whereSellerCl)){
    		if(!mapCouponCategory.containskey(coSeller.Coupon__c)) continue;
    		List<Coupon_Category__c> lstCategory = mapCouponCategory.get(coSeller.Coupon__c);
    		for(Coupon_Category__c cc : lstCategory){
    			if(cc.Category_Level__c == 0){
					lstCoInvestToCreated.add(CouponTriggerHandler.newCoInvestWithCategory(coSeller,cc,coInvestRecordType.get(EBH_ConstantsUtility.CO_INVEST_SELLER).id));
				}else if(cc.Category_Level__c > 0){
					lstCoInvestToCreated.add(CouponTriggerHandler.newCoInvestWithCategory(coSeller,cc,coInvestRecordType.get(EBH_ConstantsUtility.CO_INVEST_CATEGORY).id));
				}
    		}
    	}
    	
    	if(!lstCoInvestToCreated.isEmpty()){
    		insert lstCoInvestToCreated;
    	}
    }

	/*********************************************************************************************************************************
	@ Method:         blockDuplicatedCategory
	@ Version:        1.0
	@ Author:         Sreymeas Nao (sreymeas.nao@gaea-sys.com)
	@ Purpose:        US-0018752: Coupon - Validation Rule for Coupon Categories, block duplication Category
	@ Parameter:      Map<Id, Coupon_Category__c> mOldCouponCategory, List<Coupon_Category__c> newCouponCategory
	@ Event:          before insert, before update
	----------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 24.10.2019 / Sreymeas Nao / Created the method.
	*********************************************************************************************************************************/
	public static void blockDuplicatedCategory(Map<Id, Coupon_Category__c> mOldCouponCategory, List<Coupon_Category__c> newCouponCategory){
		Set<Id> sCnpId = new Set<Id>();
		Set<Id> sCnpCtgId = new Set<Id>();
		Map<String,Coupon_Category__c> mapCnpCgt = new Map<String,Coupon_Category__c>();
		String whereCl = ' where Category__c IN: sCnpCtgId AND Coupon__c IN: sCnpId';
		String sCnpNew, sCnpOld, sCnpCgtNew, sCnpCgtOld;

		if (mOldCouponCategory == null) {
			for(Coupon_Category__c oneCnpCgt : newCouponCategory){
				sCnpCtgId.add(oneCnpCgt.Category__c);
				sCnpId.add(oneCnpCgt.Coupon__c);
			}
			for(Coupon_Category__c oneCnpCgt : Database.query(EBH_ConstantsUtility.SOQL_COUPONCATEGORY + whereCl)){
				mapCnpCgt.put(oneCnpCgt.Category__c+'#'+oneCnpCgt.Coupon__c,oneCnpCgt);
			}
		}else{
			for (Coupon_Category__c oneCnpCgt : newCouponCategory) {
				Coupon_Category__c oldCnpCtg = mOldCouponCategory.get(oneCnpCgt.Id);
				sCnpOld = oldCnpCtg.Coupon__c;
				sCnpNew = oneCnpCgt.Coupon__c;
				sCnpCgtOld = oldCnpCtg.Category__c;
				sCnpCgtNew = oneCnpCgt.Category__c;
				sCnpCtgId.add(oneCnpCgt.Category__c);
				sCnpId.add(oneCnpCgt.Coupon__c);
			}
			
			if (sCnpOld != sCnpNew || sCnpCgtOld != sCnpCgtNew) {
				for(Coupon_Category__c oneCnpCgt : Database.query(EBH_ConstantsUtility.SOQL_COUPONCATEGORY + whereCl)){
					mapCnpCgt.put(oneCnpCgt.Category__c+'#'+oneCnpCgt.Coupon__c,oneCnpCgt);
				}
			}
			
		}

		for(Coupon_Category__c oneCnpCgt : newCouponCategory){
			if(mapCnpCgt.containsKey(oneCnpCgt.Category__c+'#'+oneCnpCgt.Coupon__c)){
				if(oneCnpCgt.Id!=mapCnpCgt.get(oneCnpCgt.Category__c+'#'+oneCnpCgt.Coupon__c).Id){
					oneCnpCgt.addError(Label.ErrMsg_duplicateCategory);
				}
			}
		}
	}

	/*********************************************************************************************************************************
	@ Method:         visibleCouponCategoryInSellerPortal
	@ Version:        1.0
	@ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
	@ Purpose:        US-0011958 - Change Requests Focus 75
	@ Parameter:      List<Coupon_Category__c> newCouponCategory
	@ Event:          before insert
	----------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 24.6.2022 / Sambath Seng / Created the method.
	*********************************************************************************************************************************/
	public static void visibleCouponCategoryInSellerPortal(List<Coupon_Category__c> newCouponCategory){
		for(Coupon_Category__c cc : newCouponCategory){
			if(cc.Coupon_Item_Negotiation__c){
				cc.Is_Visible_in_Seller_Portal__c = true;
			}
		}
	}

	/*********************************************************************************************************************************
	@ Method:         populateCouponMainSite
	@ Version:        1.0
	@ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
	@ Purpose:        US-0011958 - Change Requests Focus 75
	@ Parameter:      List<Coupon_Category__c> newCouponCategory
	@ Event:          before insert
	----------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 05.07.2022 / Sambath Seng / Created the method.
	*********************************************************************************************************************************/
	public static void populateCouponMainSite(List<Coupon_Category__c> newCouponCategory){
		Set<Id> couponIds = new Set<Id>();
		Map<String,String> mapCouponIdCouponMainSite = new Map<String,String>();
		for(Coupon_Category__c oCC : newCouponCategory){
			couponIds.add(oCC.Coupon__c);
		}
		if(!couponIds.isEmpty()){
			for(Coupon__c oCP : Database.query(SOQL_COUPON + ' Where Id IN: couponIds')){
				if(String.isNotBlank(oCP.Main_Coupon_Site__c))mapCouponIdCouponMainSite.put(oCP.Id,oCP.Main_Coupon_Site__c);
			}
			for(Coupon_Category__c oCC : newCouponCategory){
				oCC.Coupon_Main_Site__c = mapCouponIdCouponMainSite.get(oCC.Coupon__c);
			}
		}
	}
		
}