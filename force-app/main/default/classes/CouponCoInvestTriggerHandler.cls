/*********************************************************************************************************************************
@ Class:          CouponCoInvestTriggerHandler
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        Handler Class for trigger CouponCoInvest
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.06.2019 /  Sovantheany Dim / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.05.2022 /  Mony Nou / US-0010656  - Adjust Deletion Rule for Coupon Co-Invest Record
                : 06.06.2021 / SRONG TIN / US-0011872 - Validation rule for Co-Invest deletion
                : 22.07.2022 /  Mony Nou / US-0012059 - Amend error message or mass update co-invest records
                : 19.09.2022 /  Mony Nou / US-0012059 - US-0010910 - Amend Bulk Upload Logic to ignore Coupon Item Object
                : 05.06.2023 / Loumang SENG / US-0013029 - Streamline of coupon seller statuses & retiring coupon fields
                : 13.06.2023 / Acmatac Seing / US-0013714 - Checking Custom Permission Set instead of Permission Set
@ 				: 28.09.2023 / Loumang SENG / US-0013980 - Retire Contract Template field on Coupon
                : 29.09.2023 / Sambath Seng / US-0012340 - Destruction of Coupon Item Object
*********************************************************************************************************************************/
public without sharing class CouponCoInvestTriggerHandler {
	

    private static String NEGOTIATION_STAGE = 'Contract Negotiation';

    private final static String SOQL_COUPON_COINVEST = 'select Item_ID__c, Coupon_Name__c,Unique_Item__c from Coupon_Co_Invest__c'; //MN-19092022-US-0010910
    private final static String CO_INVEST_ITEM = 'Coupon_Co_Invest_Item'; //MN-28092022-US-0010910
    private final static String COUPON_SITE_AU = 'ebay.com.au';
    private final static String COUPON_SITE_UK = 'ebay.co.uk';
	
    public static Id RTID_COUPONCOINVESTITEM = ApexUtil.getRecordTypeByName('Coupon_Co_Invest__c',CO_INVEST_ITEM).Id; //MN-28092022-US-0010910
    private final static String SOQL_COUPON_SELLER = 'Select EBH_CouponSellerOwner__c,Seller__r.EBH_RevRollup__c,Additional_Terms_Override_of_Agreement__c,Coupon__r.Main_Coupon_Site__c,Coupon_Code__c, Name, Coupon_ID__c, Coupon_Start_Date__c, Coupon_End_Date__c, Legal_Entity_Name_w__c, Legal_Entity_Street_w__c, Legal_Entity_Zip_w__c, Seller__r.Parent.EBH_BillingCity__c, Seller__r.Name, Coupon_Start_Time__c, Coupon_End_Time__c, Additional_Terms__c, Seller__r.Parent.EBH_BillingCountry__c, Coupon__r.Couponsite_s__c, Marketing_Coupon_Name__c, Contract_Language__c, CurrencyIsoCode, Min_Transaction_Value__c, SP_Coupon_Discount_Rate__c, Coupon_Site__c, Max_Redemptions__c, Coupon_Discount_Amount__c, Legal_Entity_City__c, Maximum_Discount_Value__c, Coupon_Contract_Due_Date__c, Coupon_Seller_Stage__c, Contract_Accept_Date__c, Contract_Accepted_From__c, Contract_Signed_Declined_By__c, Legal_Entity_Country__c, Coupon_Type__c, Allow_reaccept_contract__c, Coupon_Seller_Stage_Portal__c, SellerShareHolder__c,eBay_Co_fund_Max__c,Negotiation_End_Date__c,Seller__r.Primary_Contact__c,Seller_Contact__r.Community_User__c,Seller__r.Seller_Portal_Group__c,Seller__r.Seller_Portal_Group__r.SP_Main_Domain__c,Seller__r.SP_Main_Domain__c From Coupon_Seller__c ' ;

	/*****************************************************************************************************************************
    @ Method:   checkIsAllowAddCategoryExceptions
    @ Version:  1.0
    @ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  US-0015718 Coupon - Allow Coupon Owner to add Category Exceptions
    @ AC2) The new field +will not b+e considered as the other coupon categories when the Coupon-Coinvest Records are being created via Trigger by user (clicking on button "SELLER NEGOTIATION)
    @ AC3) Only as a Coupon Owner and System Admin I am able to create and delete Coupon Co-Invest Records
    @ AC4) We only allow manual creation of CO-Invest Records for Coupon Categories where field Exception Category = True  
    @ Event:    Before Insert/Deleted
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon_Co_Invest__c> listNew, List<Coupon_Co_Invest__c> listOld
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 03.10.2019 / Sovantheany Dim / Created the  Method.
    @               26.05.2022 / Acmatac SEING / US-0010660 - Items upload validations - This blocked the SEP Coinvest creation
    @               30.05.2022 / Mony Nou / US-0010656- Asked discussed in team we will remove the owner assignment from trigger
    *****************************************************************************************************************************/
    public static void checkIsAllowAddCategoryExceptions(List<Coupon_Co_Invest__c> listNew,List<Coupon_Co_Invest__c> listOld)
    {
    	List<Coupon_Co_Invest__c> lstcouponCoInvest = trigger.isInsert ? listNew : listOld;
    	Set<Id> sCouponIds = new Set<Id>();
    	Set<Id> sCategoryIds = new Set<Id>();
		for(Coupon_Co_Invest__c coInVest : lstcouponCoInvest){
			// if(coInVest.Coupon_Name__c != null) sCouponIds.add(coInVest.Coupon_Name__c); //MN-30052022-US-0010656
			if(coInVest.Coupon_Category__c != null) sCategoryIds.add(coInVest.Coupon_Category__c);
		}
		// if(sCouponIds.isEmpty()) return; //MN-30052022-US-0010656
    	// Map<ID,Coupon__c> mapCoupon = new Map<ID,Coupon__c>((List<Coupon__c>) Database.query(EBH_ConstantsUtility.SOQL_COUPON + ' where id IN: sCouponIds')); //MN-30052022-US-0010656
    	
        if (sCategoryIds.isEmpty()) return; //MN-30052022-US-0010656
        Map<ID,Coupon_Category__c> mapCategory = new Map<ID,Coupon_Category__c>((List<Coupon_Category__c>) Database.query(EBH_ConstantsUtility.SOQL_COUPONCATEGORY + ' where id IN: sCategoryIds'));
    	
    	//set static Owner = Coupon owner so that Coupon Owner can deleted Coupon co invest
    	/* //MN-30052022-US-0010656
        if(trigger.isInsert){
    		for(Coupon_Co_Invest__c coInVest : listNew){
    			if(!mapCoupon.containskey(coInVest.Coupon_Name__c)) continue;
    			coInVest.OwnerId = mapCoupon.get(coInVest.Coupon_Name__c).OwnerId;
    		}
    	}
    	*/

    	Boolean isAdmin = (Userinfo.getprofileId()==EBH_ConstantsUtility.ADMIN_PROFILE_ID);
    	String currentUser = UserInfo.getUserId();
    	
    	for(Coupon_Co_Invest__c coInVest : lstcouponCoInvest){
    		Boolean isNotManual = coInVest.isNotManualCreated__c;
    		if(isNotManual) continue;
    		//AC3)
            // US-0010660 - Acmatac SEING - Items upload validations - This blocked the SEP Coinvest creation
    		// if(mapCoupon.containsKey(coInVest.Coupon_Name__c)){
    		// 	Coupon__c c = mapCoupon.get(coInVest.Coupon_Name__c);
    		// 	if(!isAdmin && currentUser != c.OwnerId){
			// 		coInVest.addError(system.label.Coupon_Owner_Exception_Error_Message);
    		// 	}
    		// }
    		//AC4)
    		
    		if(trigger.isInsert && mapCategory.containsKey(coInVest.Coupon_Category__c)){
    			Coupon_Category__c cat = mapCategory.get(coInVest.Coupon_Category__c);
    			if(!cat.Exception_Category__c){
		    		lstcouponCoInvest[0].addError(system.label.Coupon_Owner_Exception_Error_Message_2);
		    	}
    		}
    	}
    }
    
    /*****************************************************************************************************************************
    @ Method:   setDefaultSellerShare
    @ Version:  1.0
    @ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:  EPH-7451 When creating coupon coinvest record then set seller share will take global value from related coupon object
    @           AC) As a user with promotions user permission set when I create any record type of coupon co-invest (Seller, catehory or item based) 
    @           then the field Seller share % Co_Invest_c on object coupon co-invest should take default value from the related coupon obect field Seller_Co_funding_share_forecast_c and populate all co-invest records with that value **
    @ Event:    Before Insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon_Co_Invest__c> listNew
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.06.2019 / Sovantheany Dim / Created the  Method.
    @ Change history: 12.12.2019 / Sreymeas Nao / US-0006480 Coupon Items - Ability to bulk upload seller share with items (added seller share).
    @ Change history: 18.02.2020 / Sreymeas Nao / US-0007139: Coupon : Give a possibility to upload Coupon Sellers, Share & subtitle indication in right format
    @ Change history: 05.05.2020 / Vadhanak Voun /  07195 - Coupon Co-Invest records creation is causing System.LimitException: Too many SOQL queries: 101 error
    @                                           / use formula field to save a SOQL: Coupon_Co_Invest__c.Seller_Share_P_h__c
    *****************************************************************************************************************************/
    public static void setDefaultSellerShare(List<Coupon_Co_Invest__c> listNew)
    {
        Set<Id> sCouponSellerId = new Set<Id>();
        for(Coupon_Co_Invest__c coInvest : listNew){
            if(coInvest.Coupon_Seller__c == null) continue;
            
            coInvest.Co_Invest__c =  (coInvest.Co_Invest__c==null)?coInvest.Seller_Share_P_h__c:coInvest.Co_Invest__c;
        }
        
    }

    /*****************************************************************************************************************************
    @ Method:   synCurrencyValueFrom_Coupon
    @ Version:  1.0
    @ Author:   Acmatac Seing (acmatac.seing@gaea-sys.com)
    @ Purpose:  EPH-7896 Coupon Seller and Coupon Co-Invest - Take the Currency value from related Coupon Object
    @ Params :  Map<Id, Coupon_Co_Invest__c> mOldCpnCoInv, List<Coupon_Co_Invest__c> lstNew
    @ Event:    Before Insert, Before Update           
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.08.2019 / Acmatac Seing / Method Creation
    @ Change history: 05.05.2020 / Vadhanak Voun /  07195 - Coupon Co-Invest records creation is causing System.LimitException: Too many SOQL queries: 101 error
    @                                           / use formula field to save a SOQL: Coupon_Co_Invest__c.Coupon_Currency_Code_h__c
    *****************************************************************************************************************************/
    public static void synCurrencyValueFrom_Coupon(Map<Id, Coupon_Co_Invest__c> mOldCpnCoInv, List<Coupon_Co_Invest__c> lstNew){
       
        for(Coupon_Co_Invest__c aCpnCoInv : lstNew){
            if(String.isNotBlank(aCpnCoInv.Coupon_Name__c))
            {
                aCpnCoInv.CurrencyIsoCode = aCpnCoInv.Coupon_Currency_Code_h__c;
            }
        }      
    }

    /*****************************************************************************************************************************
    @ Method:   deleteUpdateCouponCoInvest
    @ Version:  1.0
    @ Author:   Sreymeas Nao (sreymeas.nao@gaea-sys.com)
    @ Purpose:  EPH-7937 AC3,AC4) As any user with permission set = promotions user I want to delete OR update a coupon co-invest record. I can only delete a coupon item (validation rule )if the following criteria apply:
    @           I am the owner of of the related coupon seller record 
    @           when Coupon seller stage <= Contract send (i.e. all stages after contract send I am not able to delete or update)
    @ Event:    Before Delete and Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon_Co_Invest__c> listRec
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.23.2019 / Sreymeas Nao / Created the  Method.
                      12.25.2019 / Acmatac SEING / US-0006997: [AU] Existing Coupon Validations to include AU - Coupon Item and Coupon Co-Invest .- Validation Rule (Delete and edit)
    				  02/11/2021 / Sovantheany Dim / US-0010414 - Users should be able to change Coupon Owner regardless of the Coupon Seller Changes
    *****************************************************************************************************************************/
    public static void deleteUpdateCouponCoInvest(List<Coupon_Co_Invest__c> listRec){
    	//TH: 02/11/2021: US-0010414 - check if Coupon_Co_Invest__c.OwnerId changed, skip validation rule
    	if(trigger.isUpdate){
    		List<Coupon_Co_Invest__c> lstNewConvest = new List<Coupon_Co_Invest__c>();
    		Map<Id, Coupon_Co_Invest__c> mapCoinvest = (Map<Id, Coupon_Co_Invest__c>) trigger.oldMap;
			for(Coupon_Co_Invest__c coInvest : listRec){
				if(coInvest.OwnerId != mapCoinvest.get(coInvest.Id).OwnerId) continue;
				lstNewConvest.add(coInvest);
			}
			listRec = lstNewConvest;
    	}
    	//end US-0010414
        if(!listRec.isEmpty()) deleteUpdateCpnCoInvAndCpnItem(listRec);
    }

    /*****************************************************************************************************************************
    @ Method:   deleteCouponCoInvest
    @ Version:  1.0
    @ Author:   STRONG TIN (srong.tin@gaea-sys.com)
    @ Purpose:  US-0011872 - Validation rule for Co-Invest deletion
    @ Event:    Before Delete
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon_Co_Invest__c> listRec
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.06.2021 / SRONG TIN / Created the  Method.
    *****************************************************************************************************************************/
    /* MN-22072022 - Comment because this story is duplicated. I saw comment that the code need to rollback but for some reaosn the codes still there. so I comment it out.
    public static void deleteCouponCoInvest(List<Coupon_Co_Invest__c> listRec){
       Boolean isAdmin = (Userinfo.getprofileId()==ApexUtil.ADMIN_PROFILE_ID || Userinfo.getprofileId()==ApexUtil.ADMIN_LT_PRIV_PROFILE_ID);
        if(!isAdmin){
            for(Coupon_Co_Invest__c coInvest : listRec){
                if(coInvest.Coupon_Seller_Stage__c != NEGOTIATION_STAGE){
                     coInvest.addError(Label.ERROR_MESSAGE_DELETING_COUPON_CO_INVEST);
                }
            }
        }
    }
    */

    /*****************************************************************************************************************************
    @ Method	:   couponCoInvestAccessibility
    @ Version	:   1.0
    @ Author	: 	Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose	:	US-0005984: "Coupon Special Permission"
					Only users with this Permission set can edit these fields "Coupon Coinvest.Seller Share %" and "Coupon.Coupon Discount %"
					Only users with this Permission can move the Coupon Sellers to stage "Approved" 
    @ Trigger 	: before updated
	@ Param 	: Map<Id, Coupon_Co_Invest__c> mOldnCouponCoInv, Map<Id, Coupon_Co_Invest__c> newCouponCoInv
    ------------------------------------------------------------------------------------------------------------------------------
       @ Change history: 11.10.2019 / Acmatac SEING / Method Creation
                         18.Feb.2020 / Acmatac SEING / [US-0007104] UK Coupon Approval Process - Trading Mgr Approval,
                                                        Work with
    *****************************************************************************************************************************/
    public static void couponCoInvestAccessibility(Map<Id, Coupon_Co_Invest__c> mOldnCouponCoInv, Map<Id, Coupon_Co_Invest__c> newCouponCoInv){
        Boolean isAUProfile = Userinfo.getprofileId() == ApexUtil.getProfileByName(EBH_ConstantsUtility.TICKET_AU_PROFILE).Id;

        // Editable for users with "Coupon Special Permission"
        String couponSpecailPermission = EBH_ConstantsUtility.PERMISSION_COUPONSPECIALPERMISSION;
        String CouponSellerStage_Negotiation = EBH_ConstantsUtility.COUPON_SELLER_STAGE_NEGO;
        String CouponSellerStage_Approved = EBH_ConstantsUtility.COUPONSELLER_STAGE_APPROVED;

        Boolean hasPermis = ApexUtil.checkPermissionSet(new Set<String>{couponSpecailPermission});

        Map<Id, Set<Id>> mCpnSlr_CpnCoInv = new Map<Id, Set<Id>>();
        for(Id cpnId : mOldnCouponCoInv.keySet()){
            Coupon_Co_Invest__c oldCpnCoInv = mOldnCouponCoInv.get(cpnId);
            Coupon_Co_Invest__c newCpnCoInv = newCouponCoInv.get(cpnId);

            if(oldCpnCoInv.Co_Invest__c != newCpnCoInv.Co_Invest__c){
                if(mCpnSlr_CpnCoInv.containsKey(newCpnCoInv.Coupon_Seller__c)){
                    mCpnSlr_CpnCoInv.get(newCpnCoInv.Coupon_Seller__c).add(newCpnCoInv.Id);
                }else{
                    mCpnSlr_CpnCoInv.put(newCpnCoInv.Coupon_Seller__c, new Set<Id>{newCpnCoInv.Id});
                }
            }
        }
        Set<Id> cpnSlrId = mCpnSlr_CpnCoInv.isEmpty() ? new Set<Id>() : mCpnSlr_CpnCoInv.keySet();
        if(!cpnSlrId.isEmpty()){
            //LA-28-09-2023: US-0013980 : Replace EBH_ConstantsUtility.COUPONSELLER_SOQL to SOQL_COUPON_SELLER
            String cpnSlrSQL = SOQL_COUPON_SELLER + ' WHERE Id IN: cpnSlrId AND (Coupon_Seller_Stage__c !=: CouponSellerStage_Negotiation OR Negotiation_End_Date__c = LAST_N_DAYS:1)';
            for(Coupon_Seller__c oneCpnSlr : Database.query(cpnSlrSQL)){
                for(Id cpnCoInv : mCpnSlr_CpnCoInv.get(oneCpnSlr.Id)){
                    // Stage is Approved
                    if(oneCpnSlr.Coupon_Seller_Stage__c == CouponSellerStage_Approved && !hasPermis){
                        // Coupon_Discount__c is locked from editing when stage is set to "Approved. But they are editable for users with "Coupon Special Permission" .
                        newCouponCoInv.get(cpnCoInv).addError(EBH_ConstantsUtility.MSG_SELLERFUNDINGLOCKED);
                    }else{
                        // Coupon_Discount__c is locked from editing 1 day after the Negotiation End Date is reached. But they are editable for users with "Coupon Special Permission" .
                        Boolean is1dayAfterNego = oneCpnSlr.Negotiation_End_Date__c != null ? Date.today().addDays(-1).isSameDay(oneCpnSlr.Negotiation_End_Date__c.date()) : false;
                        if(is1dayAfterNego && !hasPermis){
                            newCouponCoInv.get(cpnCoInv).addError(EBH_ConstantsUtility.MSG_SELLERFUNDINGLOCKED_SENTAPPROVAL);
                        }
                    }
                }
            }
        }

    }
    //LA-05-06-2023-US-0013029- Retired picklist value 'Commited' , 'T4 Statement Send', 'Invoice paid'
    //MN-22072022-US-0012059 - Moved from EBH_ConstantsUtility
    public final static Map<String, Integer> COUPONSELLER_STAGE_ORDER = new Map<String, Integer>{
        'Targeted' => 1,
        'Reached' => 2,
        //'Commited' => 3,
        'Contract Negotiation' => 4,
        'Review' => 5, 
        'Approved' => 6,
        'Contract Send' => 7,
        'Contract Signed' => 8,
        'Coupon Running' => 9,
        'Coupon executed' => 10,
        //'T4 Statement Send' => 11,
        'T34 Statement Send' => 12,
        //'Invoice paid' => 13,
        'Seller Declined' => 14
    };

    // 25-Dec-19, AMT
    // This will use in both CouponCoinvest and CouponItem
    // 3.April.2020 / Acmatac SEING / [US-0007359] UK Coupon Cofund share not working as expected
    // 22.July.2022 / Mony Nou / US-0012059 - Amend error message or mass update co-invest records
    // 13.06.2023 / Acmatac Seing / US-0013714 - Checking Custom Permission Set instead of Permission Set
    // 29.09.2023 / Sambath Seng / US-0012340 - Destruction of Coupon Item Object
    public static void deleteUpdateCpnCoInvAndCpnItem(List<sObject> listRec){
        // skip for Admin
        Boolean isAdmin = UserInfo.getProfileId().equals(EBH_ConstantsUtility.ADMIN_PROFILE_ID);
        byPass__c bp = byPass__c.getInstance(UserInfo.getUserId()); //initiate bypass trigger
        Boolean isBypassed = bp != null && bp.byPass_Trigger__c && !String.isBlank(bp.triggerObjects__c)
        && bp.triggerObjects__c.containsIgnoreCase('Coupon_Co_Invest__c');
        
        if(!isAdmin && !isBypassed){
            String userId = UserInfo.getUserId();
            Schema.sObjectType entityType = listRec.get(0).getSObjectType();
            // SB 29.09.2023 US-0012340 - Destruction of Coupon Item Object
            // String cpnSlrIdAPI = entityType == Coupon_Co_Invest__c.sObjectType ? 'Coupon_Seller__c' : entityType == Coupon_Item__c.sObjectType ? 'Coupon_Seller_ID__c' : '';
            String cpnSlrIdAPI = entityType == Coupon_Co_Invest__c.sObjectType ? 'Coupon_Seller__c' : '';
            Set<Id> couponSeller = new Set<Id>();

            Boolean isAUProfile = Userinfo.getprofileId() == ApexUtil.getProfileByName(EBH_ConstantsUtility.TICKET_AU_PROFILE).Id;

            // 13.06.2023 / Acmatac Seing / US-0013714 - Checking Custom Permission Set instead of Permission Set
            // Boolean hasPromoPermis = ApexUtil.checkPermissionSet(new Set<String>{EBH_ConstantsUtility.PERMISSION_SET_PROMO});
            Boolean hasPromoPermis = FeatureManagement.checkPermission(ApexUtil.COUPON_BULK_EDITS_CUSTOM_PERMISSION);
            Boolean hasSpecialPermis = ApexUtil.checkPermissionSet(new Set<String>{EBH_ConstantsUtility.PERMISSION_COUPONSPECIALPERMISSION});

            for(sObject oneListRec : listRec){
                couponSeller.add(String.valueOf(oneListRec.get(cpnSlrIdAPI)));
            }
            //LA-28-09-2023: US-0013980 : Replace EBH_ConstantsUtility.COUPONSELLER_SOQL to SOQL_COUPON_SELLER
            String cpnSlrQuery = SOQL_COUPON_SELLER + ' WHERE Id IN :couponSeller';
            Map<String, Coupon_Seller__c> mapCS = new Map<String, Coupon_Seller__c>((List<Coupon_Seller__c>) Database.query(cpnSlrQuery));

            for(sObject oneRec : listRec){
                String cpnSlrId = String.valueOf(oneRec.get(cpnSlrIdAPI));
                if(mapCS.containsKey(cpnSlrId)){
                    Coupon_Seller__c oneCpnSlr = mapCS.get(cpnSlrId);
                    Integer stageOrder = COUPONSELLER_STAGE_ORDER.get(oneCpnSlr.Coupon_Seller_Stage__c);
                    //US-0006997 - AC2, AMT
                    //LA-28-09-2023: US-0013980 : Replace Coupon__r.Contract_Language__c to Coupon__r.Main_Coupon_Site__c
                    //if((isAUProfile && oneCpnSlr.Coupon__r.Contract_Language__c == 'AU') || oneCpnSlr.Coupon__r.Contract_Language__c == 'UK'){
                    if((isAUProfile && oneCpnSlr.Coupon__r.Main_Coupon_Site__c == COUPON_SITE_AU) || oneCpnSlr.Coupon__r.Main_Coupon_Site__c == COUPON_SITE_UK){
                        // stageOrder < 5, User is Owner or hasSpecialPermis CAN EDIT  
                        //MN-22072022-US-0012059 - Only stage under 6 able to update/delete coupon co-invest
                        Boolean checkAUConditionOK = stageOrder < 6 && (userId == oneCpnSlr.EBH_CouponSellerOwner__c || hasSpecialPermis);
                        // stageOrder >= 5, Only hasSpecialPermis CAN EDIT
                        checkAUConditionOK = checkAUConditionOK || stageOrder >= 5 && hasSpecialPermis;
                        // ONLY System.today() <= oneCpnSlr.Negotiation_End_Date__c CAN EDIT
                        checkAUConditionOK = checkAUConditionOK && System.today() <= oneCpnSlr.Negotiation_End_Date__c;
                        if(!checkAUConditionOK){
                            oneRec.addError(Label.Stage_Validation_You_cannot_delete_or_edit_this_record);
                        }
                    }else{
                        /*MN-19052022-US-0010656-As discuss with Team, we no longer check condition with EBH_CouponSellerOwner__c & Promotion User Permission Set 
                        Boolean checkConditionOK = userId == oneCpnSlr.EBH_CouponSellerOwner__c && hasPromoPermis;
                        checkConditionOK = checkConditionOK && stageOrder < 5;
                        */
                        //MN-22072022-US-0012059 - Only stage under 6 able to update/delete coupon co-invest
                        Boolean checkConditionOK = stageOrder < 6; //MN-19052022-US-0010656-Change deletion rule to only check the Coupon Seller Stage

                        if(!checkConditionOK){
                            oneRec.addError(Label.Stage_Validation_You_cannot_delete_or_edit_this_record);
                        }
                    } 
                }
            }
        }
    }

    /*****************************************************************************************************************************
    @ Method:   validateCouponCoInvest
    @ Version:  1.0
    @ Author: 	Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:  US-0010910 - Amend Bulk Upload Logic to ignore Coupon Item Object
    @ Description : when I go to Coupon Object record type Item based and upload (manual or bulk) item ids 
	@ System should look through all coupon co-invests relate to all coupon seller records for this specific coupon
	@ If the item ids already exist, system must block the upload of the item ids and display error message below
    @ Event:	Before Insert and Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon_Co_Invest__c> listNewRec
    				 Map<ID,Coupon_Co_Invest__c> mapOldRec
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.09.2022 / Mony Nou / Created the  Method.
    @               : 14.11.2022/vadhanak voun/US-0012934 - Fail to upload coupon item due to big amount of coupon co-invest record in Prod
    *****************************************************************************************************************************/
    public static void validateCouponCoInvest(List<Coupon_Co_Invest__c> listNewRec, Map<ID,Coupon_Co_Invest__c> mapOldRec){

        if (!isCouponCoInvestItem(listNewRec)) return;


		Boolean isNew = (mapOldRec==null);
		set<String> sDuplicateInfile = new set<String>();
		Map<String,Coupon_Co_Invest__c> mapCouponCoInvest = new Map<String,Coupon_Co_Invest__c>();
		set<String> sItem = new Set<String>();
		Set<String> setCS = new Set<String>();
        Set<String> setCPN = new Set<String>();
        for(Coupon_Co_Invest__c newItem : listNewRec){

			if(isNew || !isNew && (newItem.Coupon_Name__c != mapOldRec.get(newItem.Id).Coupon_Name__c || newItem.Item_ID__c != mapOldRec.get(newItem.Id).Item_ID__c)){
				String key = newItem.Coupon_Name__c +'_'+newItem.Item_ID__c;
				if(mapCouponCoInvest.containsKey(key)) {
					sDuplicateInfile.add(key);
					continue;
				}
				mapCouponCoInvest.put(key,newItem);
				sItem.add(newItem.Item_ID__c);
                //NK:14/11/2022/US-0012934
                setCS.add(newItem.Coupon_Seller__c);
                setCPN.add(newItem.Coupon_Name__c);
			}
		}

		if(mapCouponCoInvest.isEmpty()) return;
		
        //remove record that duplciate in file
		for(String key : sDuplicateInfile){
			Coupon_Co_Invest__c newItem = mapCouponCoInvest.get(key);
			newItem.addError(System.label.Error_Duplicate_Coupon_Item_In_File+newItem.Item_ID__c);
			mapCouponCoInvest.remove(key);
		}
		set<String> uniqueCouponItems = mapCouponCoInvest.keySet();
		String wherecl = ' where Unique_Item__c IN: uniqueCouponItems and Item_ID__c IN: sItem AND Coupon_Seller__c IN:setCS AND Coupon_Name__c IN:setCPN ';//NK:14/11/2022/US-0012934
		for(Coupon_Co_Invest__c existingItem : Database.query(SOQL_COUPON_COINVEST + wherecl)){
			
			if(mapCouponCoInvest.containsKey(existingItem.Unique_Item__c)){
				Coupon_Co_Invest__c item = mapCouponCoInvest.get(existingItem.Unique_Item__c);
				item.addError(System.label.Error_Duplicate_Coupon_Item+item.Item_ID__c);
			}
		}
	}

    //MN-28092022-US-0010910 - Check if Coupon Co-Invest is ITEM record type
    public static Boolean isCouponCoInvestItem(List<Coupon_Co_Invest__c> lstCCI){
        return lstCCI.isEmpty() ? false : lstCCI[0].RecordTypeId == RTID_COUPONCOINVESTITEM ? true : false;
    }


}