/*********************************************************************************************************************************@ Class:          CouponTriggerHandler@ Version:        1.0@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)@ Purpose:        Handler Class for trigger Coupon
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 08.04.2019 /  Sovantheany Dim / Created the class.
@				: 31.08.2021 / Mony Nou / US-0009948 - remove field Email_Adress__c from query string line 16
@				: 20.05.2022 / Loumang SENG / US-0011328 - Deprecate the function to Send BCD file via email to Finance DL after Coupon ended
@				: 23.05.2022 / SRONG TIN / US-0011375: - Add related category list to item based coupon records
@				: 27.06.2022 / Mony Nou / US-0010785 - Refactor Coupon Seller object to support standard search (AC3)
@				: 30.06.2022 / Sambath Seng / US-0011998 - Business Feedback Focus 75 AC3
@				: 25.08.2022 / Loumang SENG / US-0012338 - Auto update coupon seller stage if Coupon at Seller Negotiation (AC1)
@				: 25.11.2022 / Mony Nou/ US-0012866 - [SEP] : global search is not working with Coupon Code or coupon marketing code for Linked Account
@				: 10.01.2023 / Loumang SENG / US-0012995 - Additional safeguarding for coupon seller automation (AC1)
@				: 11.01.2023 / Mony Nou / US-0012694 - [FR] Accessibility Configurations - Cannot deploy before launch
@				: 22.02.2023 / Sophal Noch / US-0012801 - Accessibility Configurations
@				: 01.03.2023 / Sovantheany Dim / US-0013091 - Improve trigger when creating co-invest records Coupon Co-Invest records for big number of Categories
@				: 02.06.2023 / Sophal Noch / US-0012597 - [IT] Accessibility Configurations - Cannot deploy before launch
@				: 02.06.2023 / Sovantheany Dim / US-0012096 - Use Coupon Category Seller Share for Co-Invest Creation
@				: 06.06.2023 / Acmatac SEING / US-0013750 - Unable to change Stage for EFC coupon record type
@				: 07.06.2023 / Loumang SENG / US-0013029 - Streamline of coupon seller statuses & retiring coupon fields
@				: 16.06.2023 / Chetra Sarom / US-0013475 - Deactivate redundant Coupon Approval process & email
@				: 14.08.2023 / LoumAng SENG / US-0013973 - Introduce new coupon type for Long Term Coupons(AC7)
@				: 01.09.2023 / Mony Nou / US-0013979 - Long Term Coupons Visible on Portal (Seller Facing)
@				: 28.09.2023 / Loumang SENG / US-0013980 - Retire Contract Template field on Coupon
@				: 02.10.2023 / Sambath Seng / US-0012340 - Destruction of Coupon Item Object
@				: 19.02.2024 / Mony Nou / US-0014783 - Developer script exception from Hive : CouponTrigger
@				: 27.01.2025 / Mony Nou / US-0015576 - (Tech debt) Coupon update- Exceeding CPU time Limit exception & Too many DML rows: 10001
*********************************************************************************************************************************/
public without sharing class CouponTriggerHandler {
	/****************************************************************************************************************************
	* CONSTANTS DEFINITION
	*****************************************************************************************************************************/
	public final static String CAP_ROWHTML = ' <td style="text-align:left;vertical-align:top;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:black;">{!fieldValue}</td> ';
	//LA-28-09-2023: US-0013980 : Remove field Coupon__r.Contract_Language__c from query SOQL_COUPON_SELLER_2 , SOQL_COUPON_SELLER
	public final static String SOQL_COUPON_SELLER_2 = 'Select Coupon__r.Main_Coupon_Site__c, Coupon__r.Couponsite_s__c,Seller__r.Strategic_Seller_Share_w__c,Coupon__r.Seller_Co_funding_share_forecast__c, Date_4days_Sent__c, Date_34_days_Sent__c, TriggerEmailManhattan__c, Id,Seller__c,Seller__r.EBH_OracleID__c,Coupon__c,Coupon_Seller_Stage__c,Coupon__r.RecordTypeID,Coupon__r.RecordType.DeveloperName,Coupon__r.Stage__c,SellerShareHolder__c From Coupon_Seller__c' ;
	//TH:US-0012096 : move from EBH_ConstantsUtility, add new field Coupon_Category__c.Seller_Share__c
	public final static String SOQL_COUPONCATEGORY = 'select Coupon__r.Coupon_with_Co_Funding__c, Seller_Share__c, Exception_Category__c,Category__c,Category__r.Name,Category_ID__c,Category_Level__c,Coupon__c,Coupon__r.RecordTypeID,Coupon__r.RecordType.DeveloperName,Coupon__r.Stage__c from Coupon_Category__c';
	private final static String SOQL_COUPON_SELLER = 'Select Coupon__r.Main_Coupon_Site__c,Coupon__r.Coupon_Subtitle_Copy__c,RecordType.DeveloperName, Allow_reaccept_contract__c,Advertising_Promotion__c, Day_1_Alert__c, Coupon_Contract_Due_Date__c, Day34AfterCouponEnd_Trigger_DE__c,Day4AfterCouponEnd_Trigger_DE__c,CurrencyIsoCode, Additional_Terms_Override_of_Agreement__c, Ad_Spend_Date__c, Advertising_Amount__c, Contract_Accept_Date__c,Coupon_Seller_Stage__c,Contract_Language__c,GMV_LC__c,Contra_LC__c,Cost_Share_Seller_LC__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Due_Date__c,Free_Subtitles__c,Coupon__r.Max_Redemptions__c,Coupon__r.Owner.Name,EBH_CouponSellerOwner__r.Name,EBH_CouponSellerOwner__c,EBH_CouponSellerOwner__r.Email,Coupon__r.Coupon_Cap__c,Coupon_ID__c ,Coupon__r.Marketing_Coupon_Name__c,Coupon__r.OwnerId,Coupon__r.Owner.Email,Coupon__r.RecordType.DeveloperName,Coupon__r.CurrencyIsoCode,Additional_Terms__c,Coupon__r.Minimum_Transaction_Value__c,Coupon__r.Name,Legal_Entity_Name_w__c,Legal_Entity_Street_w__c,Legal_Entity_Zip_w__c,Seller__r.Parent.EBH_BillingCountry__c,Seller__r.Parent.EBH_BillingCity__c,Seller__r.EBH_VATNumber__c,Seller__r.Name,Coupon__r.Couponsite_s__c,PayPal_adress_N__c,Coupon__r.Coupon_Start_Time__c,Coupon__r.Coupon_Start_Date__c,Coupon__r.Coupon_end_Time__c,Coupon__r.Coupon_End_Date__c,Coupon__r.Coupon_Discount__c,Coupon__r.Coupon_Discount_Amount__c,Coupon__r.T_Cs_URL__c,Id,Name,Seller__c,Coupon__c,Oracle_ID__c,PayPal_adress__c From Coupon_Seller__c ' ;
	public final static String COUPON_SELLER_NEGOTIATION_STAGE = 'Seller Negotiation';
	public final static String COUPON_RUNNING_STAGE = 'Coupon Running';
	private final static String COUPON_OBJNAME = 'Coupon__c';
	private final static String COUPON_CATEGORYBASE = 'Category_Based'; //MN-27062022-US-0010785
    private final static String COUPON_ITEMBASE = 'Item_Based'; //MN-27062022-US-0010785
	private final static String CS_STAGE_TARGETED = 'Targeted'; //MN-27062022-US-0010785
	private final static String CS_STAGE_REACHED = 'Reached'; //MN-27062022-US-0010785
	//private final static String CS_STAGE_COMMITED = 'Commited'; //MN-27062022-US-0010785	//LA-06-06-2023-US-0013029
	private final static String CS_STAGE_NEGOTIATION= 'Contract Negotiation'; //MN-27062022-US-0010785
	private final static String CS_STAGE_APPROVED = 'Approved'; //MN-27062022-US-0010785
	private final static String CS_STAGE_REVIEW = 'Review'; //MN-27062022-US-0010785
	private final static String CS_STAGE_CONTRACTSEND = 'Contract Send'; //MN-27062022-US-0010785
	private final static String CS_STAGE_CONTRACTSIGNED = 'Contract Signed'; //MN-27062022-US-0010785
	private final static String COUPON_ITEMBASE_STAGE = 'Item_Based';

	private final static String COUPON_RECORDTYPE_EFC = 'eBay_Fully_Funded_Coupon';
	
	private final static String COUPON_SITE_DE = 'ebay.de'; //SB 01.06.2022 US-0011998 - Business Feedback Focus 75 AC3
	private final static String COUPON_SITE_US = 'ebay.com'; //LA 25.08.2022
	private final static String COUPON_SITE_FR = 'ebay.fr'; //LA 25.08.2022
	private final static String COUPON_SITE_AU = 'ebay.com.au'; //SP 22.02.2023 US-0012801
	private final static String COUPON_SITE_IT = 'ebay.it'; //SP 02.06.2023 US-0012597
	private final static String COUPON_SITE_UK = 'ebay.co.uk';//LA-28-09-2023: US-0013980
	
	private static final Set<String> S_MAINCOUPONSITE = new Set<String>{
        COUPON_SITE_DE,
        COUPON_SITE_US,
        COUPON_SITE_FR,
        COUPON_SITE_AU, // 22.02.2023 / Sophal Noch / US-0012801
		COUPON_SITE_IT  // 02.06.2023 / Sophal Noch / US-0012597
	};
	//LA-28-09-2023: US-0013980: Mapping by main site Main_Coupon_Site__c
    private final static Map<String,String> MAP_CPN_APPR_LOCALIZE = new Map<String,String>{
        COUPON_SITE_AU =>'AU_Coupon_Approval_Email_Notification_to_Category_Growth_Manager',
        COUPON_SITE_UK =>'UK_Coupon_Approval_Email_Notification_to_Category_Growth_Manager'
    };
	private static final INTEGER NUM_ERROR_TO_DISPLAY  = Integer.valueOf(System.Label.NUM_ERROR_TO_DISPLAY); //TH:US-0013091 
	private final static String HYPERLINK_RECORD = '<a href="{!recordURL}">{!sObjectName}</a>';
	//LA-28-09-2023: US-0013980 : removed field Contract_Language__c from SOQL_COUPON
	//Loumang:US-0010777: removed field Sellers_Targeted__c from SOQL_COUPON
	//public final static String SOQL_COUPON = 'select MC_Whitelisted__c, Trigger34DayAfterEndDate__c,Trigger4DayAfterEndDate__c,OwnerId,Contract_Language__c, Coupon_ID__c, Days_since_coupon_End_Date__c, Coupon_Source__c, Couponsite_s__c, Coupon_Start_Date__c, Coupon_End_Date__c, Sellers_Targeted__c, Owner.Name, Owner.Email, RecordTypeId, id,Seller_Co_funding_share_forecast__c from Coupon__c';
	public final static String SOQL_COUPON = 'select Main_Coupon_Site__c,Name, MC_Whitelisted__c, Trigger34DayAfterEndDate__c,Trigger4DayAfterEndDate__c,OwnerId,Coupon_ID__c, Days_since_coupon_End_Date__c, Coupon_Source__c, Couponsite_s__c, Coupon_Start_Date__c, Coupon_End_Date__c, Sellers_Targeted2__c, Owner.Name, Owner.Email, RecordTypeId, id,Seller_Co_funding_share_forecast__c from Coupon__c';
	private final static Set<Id> SET_ADMIN_PROFILE_ID = new Set<Id>{ApexUtil.ADMIN_PROFILE_ID,ApexUtil.ADMIN_LT_PRIV_PROFILE_ID};
	public static boolean isBatchProcessing = false;
	private final static String COUPON_SCMC_CATEGORYBASE = 'Single_Contract_Multi_Coupon_SCMC_Category_Based';//LA-14-08-2023-US-0013973
	//LA-28-09-2023: US-0013980 : removed EBH_ConstantsUtility.CPNSELLER_CPNCOINVSOQL 
	private final static String CPNSELLER_CPNCOINVSOQL = 'SELECT (SELECT Coupon_Name__c, Coupon_Category__r.Category__r.Name, Coupon_Seller__c, Coupon_Seller__r.Name, Coupon_Seller__r.Coupon_Seller_Stage__c, Coupon_Seller__r.Seller__r.Name, Coupon_Seller__r.EBH_CouponSellerOwner__r.Name, Coupon_Seller__r.Oracle_ID__c, Seller_Funding__c, Co_Invest__c, eBayFunding__c FROM Coupon_Co_Invests__r WHERE Coupon_Seller__r.Coupon_Seller_Stage__c =: couponStageNego), Contract_Due_Date__c, Coupon_Cap__c, Max_Redemptions__c, Coupon_ID__c, Marketing_Coupon_Name__c, Coupon_Start_Date__c, Coupon_End_Date__c, Coupon_Discount__c, Coupon_GMV_Target__c,Main_Coupon_Site__c, Owner.Email FROM Coupon__c ';
	/************************************END CONSTANTS DEFINITION*************************************************************/
    /*****************************************************************************************************************************
    @ Method:   createCoInvest
    @ Version:  1.0
    @ Author: 	Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:	EPH-7262 Adjustment to Coupon Object
    @			AC3) As any user with permission set promotions user when I create a new coupon record the stage will be set to value = DRAFT by default (can only be edited once coupon has been saved)
    @ Event:	Before Insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon__c> listNew
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.04.2019 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    public static void setDefaultStage(List<Coupon__c> listNew)
    {
    		for(Coupon__c coupon : listNew){
    			coupon.Stage__c = EBH_ConstantsUtility.COUPON_STAGE_DRAFT;
    		}
    }
    
	/*****************************************************************************************************************************
    @ Method:   createCoInvestWithRecordType
    @ Version:  1.0
    @ Author: 	Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:	EPH-7253 Object: Coupon Co-Invest
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
    @ Event:	after Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon__c> listNew,Map<Id,Coupon__c> mapOld
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 10.04.2019 / Sovantheany Dim / Created the  Method.
	@				10/02.2020 / Sovantheany Dim / updated method : US-0007175 [AU] Coupon CoInvest Record creation to happen when Coupon Seller is in stage "Targeted" for Item Based Coupons
	@				15/05/2020/ Vadhanak Voun/ US-0007195 - Coupon Co-Invest records creation is causing System.LimitException: Too many SOQL queries: 101 error
	@ 						move to @future: processCoInvestAsyn
	@				9/7/2020/ Sovantheany Dim/ updated method: US-0007761 - [AU] Update Coupon Co-Invest Records for AU Coupons
	@				28/02/2023/ Sovantheany Dim / US-0013091 - Improve trigger when creating co-invest records Coupon Co-Invest records for big number of Categories
	@				: 14.08.2023 / LoumAng SENG / US-0013973 - Introduce new coupon type for Long Term Coupons(AC7)
    *****************************************************************************************************************************/
    public static void createCoInvestWithRecordType(List<Coupon__c> listNew,Map<Id,Coupon__c> mapOld)
    {		
    	RecordType coponRecordTypeCategory = ApexUtil.getRecordTypeByName('Coupon__c',COUPON_CATEGORYBASE);
		RecordType coponRecordTypeItemBase = ApexUtil.getRecordTypeByName('Coupon__c',COUPON_ITEMBASE);
		RecordType coponRecordTypeScmcCategory = ApexUtil.getRecordTypeByName('Coupon__c',COUPON_SCMC_CATEGORYBASE);
		//LA-14-08-2023-US-0013973
		Set<Id> sValidCouponRT = new Set<Id>{coponRecordTypeCategory.Id,coponRecordTypeItemBase.Id,coponRecordTypeScmcCategory.Id};
		
		Set<String> condtStage = new Set<String>{
			COUPON_SELLER_NEGOTIATION_STAGE
		};
    	
    	Set<ID> sCoupon = new Set<ID>();	
		for(Coupon__c coupon : listNew){
			Coupon__c oldCoupon = mapOld.get(coupon.Id);
			if(coupon.Stage__c != oldCoupon.Stage__c && condtStage.contains(coupon.Stage__c)
				
				&& sValidCouponRT.contains(coupon.RecordTypeID)){
				sCoupon.add(coupon.Id);
			}
		}
		if(sCoupon.isEmpty()) return;
		Integer totalCSCount = [Select count() From Coupon_Seller__c where Coupon__c IN: sCoupon];
		//create coninvest directly from the trigger if CS <=50
		//TH:US-0013091:decrease to <=50, so >50 go to batch to avoid Too many DML rows or cpu limit
		Integer maxCouponSeller = Integer.valueOf(System.label.Max_Coupon_Seller);
		Integer maxRecordPerTransaction = Integer.valueOf(System.label.Max_CS_Per_Transaction);
		if(totalCSCount<=maxCouponSeller)
		{
			processCoInvest((Coupon_Seller__c[])Database.query(SOQL_COUPON_SELLER_2 + ' where Coupon__c IN: sCoupon'), 0 , 0);

		}else // call batch for support for >50
		{
			//US-0013091 - test case : Coupon Category 10, coupon seller 1001 , result success
			Batch_CreateCoInvest bCoInvest = new Batch_CreateCoInvest(sCoupon);
			Database.executeBatch(bCoInvest,maxRecordPerTransaction);
		}
	}

	/*********************************************************************************************************************************
	@ Method:         processCoInvest
	@ Version:       1.0
	@ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:       US-0007195 - Coupon Co-Invest records creation is causing System.LimitException: Too many SOQL queries: 101 error
	@               shared with CouponTriggerHandler.createCoInvestWithRecordType AND Batch_CreateCoInvest
	----------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 15.05.2020/ Vadhanak Voun (vadhanak.voun@gaea-sys.com) / Created the Method.
	@					27/02/2023 / Sovantheany / US-0013091 - Improve trigger when creating co-invest records Coupon Co-Invest records for big number of Categories and
	*********************************************************************************************************************************/	 
	public static Map<String,Object> processCoInvest(Coupon_Seller__c[] listCS, Integer countAllCoInvest_OK, Integer countAllCoInvest_fail)
	{
		Map<String,Object> mapResult = new Map<String,Object>();
		Map<Id, List<Coupon_Seller__c>> mapCoseller = new Map<Id,List<Coupon_Seller__c>>();
		Map<Id, Coupon_Seller__c> mapCouponSellerForItem = new Map<Id, Coupon_Seller__c>();
		Set<ID> sCoupon = new Set<ID>();
		List<Coupon_Seller__c> lstCSToUpdate = new List<Coupon_Seller__c>();
        Map<String,Set<String>> mapError = new Map<String,Set<String>>();
		//query all coupon seller related to Coupon		
		for(Coupon_Seller__c cs : listCS){
			mapCouponSellerForItem.put(cs.Id,cs);
			sCoupon.add(cs.Coupon__c);
			List<Coupon_Seller__c> lstCouponSeller = new List<Coupon_Seller__c>();
			if(mapCoseller.containsKey(cs.Coupon__c)){
				lstCouponSeller = mapCoseller.get(cs.Coupon__c);
			}
			lstCouponSeller.add(cs);
			mapCoseller.put(cs.Coupon__c,lstCouponSeller);
			//TH:US-0013091:move from method changeStage
			if(S_MAINCOUPONSITE.contains(cs.Coupon__r.Main_Coupon_Site__c) && cs.Coupon_Seller_Stage__c == CS_STAGE_TARGETED){
				cs.Coupon_Seller_Stage__c = CS_STAGE_REACHED;
				lstCSToUpdate.add(cs);
		}
			
		}
		if(!lstCSToUpdate.isEmpty()) update lstCSToUpdate;

		List<Coupon_Co_Invest__c> lstCoInvest = newListCoInvestToCreated(mapCoseller,sCoupon);
		//Th: 11/02/2020 : US-0007175 [AU] Coupon CoInvest Record creation to happen when Coupon Seller is in stage "Targeted" for Item Based Coupons
		// 2.10.2023 / Sambath Seng / US-0012340 - Destruction of Coupon Item Object
		
		List<Coupon_Co_Invest__c> lstCoInvestToCreated = checkDuplicatedCoInvest(lstCoInvest,sCoupon);
		if(!lstCoInvestToCreated.isEmpty()){
			//TH:US-0013091 - partial insert Co invest
			//insert lstCoInvestToCreated;
			Set<String> sError = new Set<String>();
			Database.SaveResult [] coInvestInsertResult = Database.insert(lstCoInvestToCreated, false);
			for(Integer i=0;i< coInvestInsertResult.size();i++){
				Database.SaveResult result = coInvestInsertResult[i];
				if(result.isSuccess()){
					countAllCoInvest_OK ++;
				}else{
					countAllCoInvest_fail ++;
					if(countAllCoInvest_fail < NUM_ERROR_TO_DISPLAY){
						String urlForCouponSeller = URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/Coupon_Seller__c/'+lstCoInvestToCreated[i].Coupon_Seller__c+'/view';
						String urlForCouponCategory = URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/Coupon_Category__c/'+lstCoInvestToCreated[i].Coupon_Category__c+'/view';
						String sellerLink = HYPERLINK_RECORD.replace('{!recordURL}', urlForCouponSeller).replace('{!sObjectName}', 'Coupon (Seller)');
						String CategoryLink = HYPERLINK_RECORD.replace('{!recordURL}', urlForCouponCategory).replace('{!sObjectName}', 'Coupon Categories');
						sError.add(sellerLink+' : '+CategoryLink+' : '+result.getErrors()[0].getMessage());
					}else{
						sError.add('...AND MORE...');
		}
	}
			}
            if(!sError.isEmpty()){
                if(mapError.containsKey('coInvest')){
                    Set<String> sErrorFromMap = mapError.get('coInvest');
					sErrorFromMap.addAll(sError);
					mapError.put('coInvest',sErrorFromMap);
                }else{
					mapError.put('coInvest',sError);
				}
            }
		}
		mapResult.put('countAllCoInvest_OK',countAllCoInvest_OK);
		mapResult.put('countAllCoInvest_fail',countAllCoInvest_fail);
		mapResult.put('mapError',mapError);
		return mapResult;
	}

    //check if match criteria , create new co invest
    public static List<Coupon_Co_Invest__c> newListCoInvestToCreated(Map<Id, List<Coupon_Seller__c>> mapCoseller, Set<ID> sCoupon){
    	List<Coupon_Co_Invest__c> lstCoInvestToCreated = new List<Coupon_Co_Invest__c>();
		RecordType coponRecordTypeItemBase = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
		Map<String,RecordType> coInvestRecordType = ApexUtil.getRecordTypeBySobjectName('Coupon_Co_Invest__c');
		String whereCS = ' where Coupon__c IN: sCoupon and Exception_Category__c = false';
		Integer i=2;
		//query all Coupon Category related to Coupon
		for(Coupon_Category__c cc : Database.query(SOQL_COUPONCATEGORY + whereCS)){
			//SRONGTIN:23.05.2022:US-0011375: - Add related category list to item based coupon records
			if(!mapCoseller.containsKey(cc.Coupon__c) || cc.Coupon__r.RecordTypeID == coponRecordTypeItemBase.Id) continue;
			if(cc.Category_Level__c == 0){
				for(Coupon_Seller__c cs : mapCoseller.get(cc.Coupon__c)){
					lstCoInvestToCreated.add(newCoInvestWithCategory(cs,cc,coInvestRecordType.get(EBH_ConstantsUtility.CO_INVEST_SELLER).id));
				}
			}else if(cc.Category_Level__c > 0){
				for(Coupon_Seller__c cs : mapCoseller.get(cc.Coupon__c)){
					lstCoInvestToCreated.add(newCoInvestWithCategory(cs,cc,coInvestRecordType.get(EBH_ConstantsUtility.CO_INVEST_CATEGORY).id));
				}
			}
			
			i++;
		}
		return lstCoInvestToCreated;
    }
    
	
	//Check to avoid duplicate co invest created, if already exist, no more create
	//NK:17/05/2020:US-0007195: use Unique_Key__c query filter instead of query all
    public static List<Coupon_Co_Invest__c> checkDuplicatedCoInvest(List<Coupon_Co_Invest__c> allCoInvest,Set<ID> sCoupon){
    	Map<String,Coupon_Co_Invest__c> mapCoInvest = new Map<String,Coupon_Co_Invest__c>();		
		Set<String> setKeyFilter = new Set<String>(); //  unique key: Coupon_Seller__c +'-'+ Coupon_Category__c +'-'+ Item_ID__c
		for(Coupon_Co_Invest__c coInvest : allCoInvest){
    		setKeyFilter.add(
				(coInvest.Coupon_Seller__c+'').subString(0,15) + (coInvest.Coupon_Category__c==null?'':'-'+(coInvest.Coupon_Category__c+'').subString(0,15)) + (coInvest.Item_ID__c==null?'':'-'+coInvest.Item_ID__c)
			);    	 
		}
		String whereCl = ' where Coupon_Name__c IN: sCoupon AND Unique_Key__c IN :setKeyFilter ';
    	//query all eixsint (+unique key) co invest realted to coupon
    	for(Coupon_Co_Invest__c coInvest : Database.query(EBH_ConstantsUtility.SOQL_COUPONCOINVEST + whereCl)){
    		String key =coInvest.Coupon_Seller__c + (coInvest.Coupon_Category__c==null?'':'-'+coInvest.Coupon_Category__c) + (coInvest.Item_ID__c==null?'':'-'+coInvest.Item_ID__c);    		 
    		mapCoInvest.put(key,coInvest);
    	}
    	//if co invest already have then remove from list to created
    	List<Coupon_Co_Invest__c> lstCoInvestToCreated = new List<Coupon_Co_Invest__c>();
    	for(Coupon_Co_Invest__c coInvest : allCoInvest){
    		String key = coInvest.Coupon_Seller__c + (coInvest.Coupon_Category__c==null?'':'-'+coInvest.Coupon_Category__c) + (coInvest.Item_ID__c==null?'':'-'+coInvest.Item_ID__c);
    		 
    		if(mapCoInvest.containsKey(key)) continue;
    		lstCoInvestToCreated.add(coInvest);
    	}
    	return lstCoInvestToCreated;
    }
    
    public static Coupon_Co_Invest__c newCoInvestWithCategory(Coupon_Seller__c cs,Coupon_Category__c cc,ID coInvestRecordTypeID){
		Set<String> sValidCouponRT = new Set<String>{COUPON_CATEGORYBASE,COUPON_SCMC_CATEGORYBASE};//LA-14-08-2023-US-0013973
    	Coupon_Co_Invest__c csNew = new Coupon_Co_Invest__c(
			Seller_Name__c = cs.Seller__c,
			Coupon_Name__c = cs.Coupon__c,
			Coupon_Seller__c = cs.ID,
			Coupon_Category__c = cc.Id,
			RecordTypeId = coInvestRecordTypeID,
			isNotManualCreated__c = true,
			//Th: US-0007761 - [AU] Update Coupon Co-Invest Records for AU Coupons 10/07/2020
			//TH: US-0012096 - Use Coupon Category Seller Share for Co-Invest Creation 05/june/2023
			//LA-14-08-2023-US-0013973: add vaid coupon recordtype in condition
			
			Co_Invest__c = (cc.Seller_Share__c != null && cc.Coupon__r.Coupon_with_Co_Funding__c == 'Yes' && sValidCouponRT.contains(cc.Coupon__r.RecordType.DeveloperName)) ? cc.Seller_Share__c : (cs.Coupon__r.Couponsite_s__c != null && cs.Coupon__r.Couponsite_s__c.contains('ebay.com.au'))?(cs.Seller__r.Strategic_Seller_Share_w__c != null?Decimal.valueOf(cs.Seller__r.Strategic_Seller_Share_w__c):cs.Coupon__r.Seller_Co_funding_share_forecast__c):cs.SellerShareHolder__c);
		return csNew;
    }
	
	
    
    /*****************************************************************************************************************************
    @ Method:   populateDateTimeAuto
    @ Version:  1.0
    @ Author: 	vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:	EPH-7209 Coupon Record Type: Category Based and Item Based set Stage rules
    @			AC1)) When a Coupon (both record types) reach Coupon Start Date and Coupon Start Time then automatically set Coupon to status "Coupon Running"
	@			AC2) When a Coupon (both record types) reach Coupon End Date and Coupon End Time then automatically set Coupon to status "Coupon Executed"
	@			** use Timebase Workflow in combination with this Trigger
    @ Event:	before insert, before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon__c> listNew,Map<Id,Coupon__c> mapOld
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 09.04.2019 / Vadhanak Voun / Created the  Method.
	@				: 12.08.2021/ vadhanak voun / US-0009100 - Hypercare bug: Coupon Seller Stage Not Updating
	@											/ moved to flow
    *****************************************************************************************************************************/
    public static void populateDateTimeAuto(List<Coupon__c> listNew,Map<Id,Coupon__c> mapOld)
    {
    	Boolean isNew = (mapOld==null);
    	for(Coupon__c c: listNew)
    	{
    		if(isNew  )
    		{
    			if(c.Coupon_Start_Date__c <> null && c.Coupon_Start_Time__c <> null)
    			{
    				c.Start_Date_Time__c = DateTime.newInstanceGmt(c.Coupon_Start_Date__c, c.Coupon_Start_Time__c).addHours(1); //minus 1h because WF 1h before new DateTime
    				c.Start_Date_Time__c = recalUserTime(c.Start_Date_Time__c);
    				
    				
    			}
    			if(c.Coupon_End_Date__c <> null && c.Coupon_end_Time__c <> null)
    			{
    				c.End_Date_Time__c = DateTime.newInstanceGmt(c.Coupon_End_Date__c, c.Coupon_end_Time__c).addHours(1);
    				c.End_Date_Time__c = recalUserTime(c.End_Date_Time__c);
    				
    				
    			}
    			
    		}else if(!isNew)
    		{
    			Set<String> setCouponId_fields = new Set<String>();
    			if(c.Coupon_Start_Date__c <> mapOld.get(c.Id).Coupon_Start_Date__c || c.Coupon_Start_Time__c <> mapOld.get(c.Id).Coupon_Start_Time__c && c.Coupon_Start_Date__c <> null && c.Coupon_Start_Time__c <> null)
    			{
    				c.Start_Date_Time__c = DateTime.newInstanceGmt(c.Coupon_Start_Date__c, c.Coupon_Start_Time__c).addHours(1);
    				c.Start_Date_Time__c = recalUserTime(c.Start_Date_Time__c);
    				
    			}
    			if(c.Coupon_End_Date__c <> mapOld.get(c.Id).Coupon_End_Date__c || c.Coupon_end_Time__c <> mapOld.get(c.Id).Coupon_end_Time__c && c.Coupon_End_Date__c <> null && c.Coupon_end_Time__c <> null)
    			{
    				c.End_Date_Time__c = DateTime.newInstanceGmt(c.Coupon_End_Date__c, c.Coupon_end_Time__c).addHours(1);
    				c.End_Date_Time__c = recalUserTime(c.End_Date_Time__c);
    				
    			}
    			
    		}
    		
    	}
    }
    
    private static DateTime recalUserTime(DateTime dt)
    {
    	TimeZone tz = UserInfo.getTimeZone();
    	Integer o = tz.getOffset(dt);
		Integer hOffset =( (o/1000) /60)/60; //set hour to current user time as he/she doing 
		return dt.addHours(-hOffset);
    }
    
    /*****************************************************************************************************************************
    @ Method:   synCurrencyValueTo_CpnSelrAndCpnCoInv
    @ Version:  1.0
    @ Author: 	Acmatac Seing (acmatac.seing@gaea-sys.com)
    @ Purpose:	EPH-7896 Coupon Seller and Coupon Co-Invest - Take the Currency value from related Coupon Object
				
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 21.08.2019 / Acmatac Seing / Method Creation
    *****************************************************************************************************************************/
    public static void synCurrencyValueTo_CpnSelrAndCpnCoInv(Map<Id, Coupon__c> mOldCpn, Map<Id, Coupon__c> mNewCpn){
    	Set<Id> sCpnId = new Set<Id>();
    	
    	// Filter only updated Coupon.CurrencyIsoCode
	    for(Id oCpnId : mOldCpn.keySet()){
	    	Coupon__c oldCpn = mOldCpn.get(oCpnId);
	    	Coupon__c newCpn = mNewCpn.get(oCpnId);
	    	if(oldCpn.CurrencyIsoCode != newCpn.CurrencyIsoCode){
	    		sCpnId.add(oCpnId);
	    	}
	    }
    	
    	List<Coupon_Co_Invest__c> lstCpnCoInv = new List<Coupon_Co_Invest__c>();
    	List<Coupon_Seller__c> lstCpnSelr = new List<Coupon_Seller__c>();
    	String cpnConInvSQL = EBH_ConstantsUtility.COUPON_COINVEST_SQL.Replace('[EXTRA_CLAUSE]','Coupon_Name__c') + ' WHERE Coupon_Name__c IN: sCpnId';
    	String cpnSellerSQL = EBH_ConstantsUtility.COUPON_SELLER_SQL.Replace('[EXTRA_CLAUSE]','Coupon__c') + ' WHERE Coupon__c IN: sCpnId';
        
    	// Select all related Coupon Co-Invest and Coupon Seller
    	for(Coupon_Co_Invest__c aCpnCoInv : Database.Query(cpnConInvSQL)){
    		aCpnCoInv.CurrencyIsoCode = mNewCpn.get(aCpnCoInv.Coupon_Name__c).CurrencyIsoCode;
    		lstCpnCoInv.add(aCpnCoInv);
    	}
    	
    	for(Coupon_Seller__c aCpnSelr : Database.Query(cpnSellerSQL)){
    		aCpnSelr.CurrencyIsoCode = mNewCpn.get(aCpnSelr.Coupon__c).CurrencyIsoCode;
    		lstCpnSelr.add(aCpnSelr);
    	}
    	
    	// Update Coupon Co-Invest
    	if(!lstCpnCoInv.isEmpty()){
    		update lstCpnCoInv;
    	}
    	// Update Coupon Seller
    	if(!lstCpnSelr.isEmpty()){
    		update lstCpnSelr;
    	}
    }
     
    public static Map<String,String> buildCSVData(Set<String> sCouponId){
        Map<String,String> mapCsv = new Map<String,String>();
        List<String> sColumn = new List<String>{'id_type','external_id','invoice','transaction_type','credit_type','reason','provider_id','currency','input amount','memo'};
        String columnHeader = String.join(sColumn,',');
        String csvData = columnHeader + '\n';
        for(String couponId : sCouponId){
        	mapCsv.put(couponId,csvData);
        }
        Set<String> sStage = EBH_ConstantsUtility.COUPON_SELLER_STAGE;
        
        String wherecl = ' where Coupon__c IN: sCouponId and Coupon_Seller_Stage__c IN: sStage and Contract_Accept_Date__c != null';
        for(Coupon_Seller__c cs : Database.query(EBH_ConstantsUtility.SOQL_COUPONSELLER_FOR_BCD + wherecl)) {
        	csvData = mapCsv.get(cs.Coupon__c);
        	
            List<String> rowData = new List<String>();
            rowData.add(getObjectValue(cs.Coupon__r.ID_Type__c));
            rowData.add(getObjectValue(cs.External_ID__c));
            rowData.add(getObjectValue(cs.Coupon__r.Invoice__c));
            rowData.add(getObjectValue(cs.Coupon__r.Transaction_Type__c));
            rowData.add(getObjectValue(cs.Coupon__r.Credit_type__c));
            rowData.add(getObjectValue(cs.Coupon__r.Reason__c));
            rowData.add(getObjectValue(cs.Provider_ID__c));
            rowData.add(getObjectValue(cs.Currency__c));
            rowData.add(cs.CurrencyIsoCode +' '+ getObjectValue(cs.Cost_Share_Seller_LC__c)); //NK:15/11/2019: US-0018904: Cost_Share_Seller__c -> Cost_Share_Seller_LC__c
            rowData.add(getObjectValue(cs.Coupon__r.Memo__c));
            csvData += String.join(rowData, ',') + '\n';
            
            mapCsv.put(cs.Coupon__c,csvData);
        }
        
        return mapCsv;
    } 
    
    private static String getObjectValue(Object obj){
        if(obj==null)return '';
        return obj + '';
    }
	

	private static set<String> sCouponStage = new Set<String>{'Coupon Running','Coupon Executed','T4 Statement Send','T34 Statement Send'};
	/*****************************************************************************************************************************
    @ Method:   blockManualSetStage
    @ Version:  1.0
    @ Author: 	Sovantheany.dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:	EPH-7880 Coupon Seller - Block any user to set stages running, executed, staements send (i.e. fields that are updated by Trigger)
    @ Trigger : before insert , before updated
	@ Param : List<Coupon__c> newCoupon,Map<Id, Coupon__c> mOldnCoupon			
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 22.08.2019 / Sovantheany Dim / Method Creation
	@					22.08.2019 / Acmatac SEING / US-0011025 - Update existing validation error message
	@					31.03.2022 / Sophal Noch / US-0011453 - Allow System Administrator Limited Priviledges to change coupon stage manually 
	@					06.06.2023 / Acmatac SEING / US-0013750 - Unable to change Stage for EFC coupon record type
						01.05.2024 / David Herrero / Adding bypass
    *****************************************************************************************************************************/
    public static void blockManualSetStage(List<Coupon__c> newCoupons,Map<Id, Coupon__c> mOldnCoupon){
		
		RecordType cpnRT_EFC = ApexUtil.getRecordTypeByName(COUPON_OBJNAME,COUPON_RECORDTYPE_EFC);
		
    	
		Boolean isAdmin = (SET_ADMIN_PROFILE_ID.contains(Userinfo.getprofileId())); // 31.03.2022 / Sophal Noch / US-0011453
		byPass__c bp = byPass__c.getInstance(UserInfo.getUserId()); // get an isntance of the bypass custom settings
       
		if (bp!=null && bp.byPass_Trigger__c && !String.isBlank(bp.triggerObjects__c)
		 && bp.triggerObjects__c.containsIgnoreCase('Coupon__c')) {return;} // Adding ByPass to this validation

		// Adding Bypass
    	for(Coupon__c newCoupon : newCoupons){
			// 06.06.2023 / Acmatac SEING / US-0013750
			if(newCoupon.RecordTypeId == cpnRT_EFC.Id) continue;

			//to avoid error on workflow Coupon Executed and Coupon Running
    		if(newCoupon.TriggerStageUpdatedDate__c != null && newCoupon.TriggerStageUpdatedDate__c != mOldnCoupon.get(newCoupon.Id).TriggerStageUpdatedDate__c) continue;
    		if(!isAdmin && newCoupon.Stage__c != null && sCouponStage.contains(newCoupon.Stage__c) && (trigger.isInsert || (trigger.isUpdate && newCoupon.Stage__c != mOldnCoupon.get(newCoupon.Id).Stage__c))){
    			newCoupon.Stage__c.adderror(Label.COUPON_STAGE_CHANGE_RULE_ERROR_MSG);
    		}
    	}
    }
    
    /*****************************************************************************************************************************
    @ Method:   setCouponCoinvestStaticOwner
    @ Version:  1.0
    @ Author: 	Sovantheany.dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:	US-0015718 Coupon - Allow Coupon Owner to add Category Exceptions
    @ set static Owner = Coupon owner so that Coupon Owner can deleted Coupon co invest
    @ Trigger : before updated
	@ Param : List<Coupon__c> newCoupon,Map<Id, Coupon__c> mOldnCoupon			
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 04.10.2019 / Sovantheany Dim / Method Creation
    *****************************************************************************************************************************/
    public static void setCouponCoinvestStaticOwner(List<Coupon__c> newCoupon,Map<Id, Coupon__c> mOldnCoupon){
    	Map<String,String> mapCouponOwner = new Map<String,String>();
    	for(Coupon__c c : newCoupon){
    		if(c.OwnerId != mOldnCoupon.get(c.Id).OwnerId){
    			mapCouponOwner.put(c.Id,c.OwnerId);
    		}
    	}
    	if(mapCouponOwner.isEmpty()) return;
    	Set<String> sCouponId = mapCouponOwner.keySet();
    	List<Coupon_Co_Invest__c> lstCoInvestUpdated = new List<Coupon_Co_Invest__c>();
    	for(Coupon_Co_Invest__c coInvest : Database.query(EBH_ConstantsUtility.SOQL_COUPONCOINVEST + ' where Coupon_Name__c IN: sCouponId')){
    		if(!mapCouponOwner.containsKey(coInvest.Coupon_Name__c)) continue;// || CouponCoInvestTriggerHandler.stage.get(coInvest.Coupon_Seller__r.Coupon_Seller_Stage__c) > 4
    		if(coInvest.OwnerId != mapCouponOwner.get(coInvest.Coupon_Name__c)){
	    		coInvest.OwnerId = mapCouponOwner.get(coInvest.Coupon_Name__c);
	    		lstCoInvestUpdated.add(coInvest);
    		}
    	}
		if(!lstCoInvestUpdated.isEmpty()) update lstCoInvestUpdated;
    }

	/*****************************************************************************************************************************
    @ Method	:   couponNegotitaionEndDateReachSendEmail
    @ Version	:   1.0
    @ Author	: 	Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose	:	US-0005984 [AU] AU Coupon Approval Email Notification to Category Growth Manager
    @ Trigger 	: 	after updated
	@ Param 	: 	Map<Id, Coupon__c> mOldnCoupon, Map<Id, Coupon__c> mNewCoupon	
    ------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 12.10.2019 / Acmatac SEING / Method Creation
					  17.02.2020 / Acmatac SEING / [US-0007104] UK Coupon Approval Process - Trading Mgr Approval
					  30.08.2021 / Acmatac SEING / US-0010176 - MC: Coupon email notifications to external users
					  16.06.2023 / Chetra Sarom / US-0013475 - Deactivate redundant Coupon Approval process & email
	 				  28.09.2023 / Loumang SENG / US-0013980 - Retire Contract Template field on Coupon
					  19.02.2024 / Mony Nou / US-0014783 - Developer script exception from Hive : CouponTrigger
    *****************************************************************************************************************************/
    public static void couponNegotitaionEndDateReachSendEmail(Map<Id, Coupon__c> mOldnCoupon, Map<Id, Coupon__c> mNewCoupon){
		//LA-28-09-2023-US-0013980: Change from  newCpn.Contract_Language__c to newCpn.Main_Coupon_Site__c
		
		Set<String> sCouponMainSite = new Set<String>{COUPON_SITE_UK}; //MN-19022024-US-0014783: remove AU because it is not used anymore since US-0013475
		Set<Id> sCpnId = new Set<Id>();
		for(Id cpnId : mOldnCoupon.keySet()){
			Coupon__c oldCpn = mOldnCoupon.get(cpnId);
			Coupon__c newCpn = mNewCoupon.get(cpnId);
			//LA-28-09-2023-US-0013980:
			
			if(newCpn.Trigger1DayAfterNegotiationEndDate__c != null && oldCpn.Trigger1DayAfterNegotiationEndDate__c != newCpn.Trigger1DayAfterNegotiationEndDate__c && sCouponMainSite.contains(newCpn.Main_Coupon_Site__c)
				&& !newCpn.MC_Whitelisted__c){ // Acmatac SEING, US-0010176 - MC: Coupon email notifications to external users
				sCpnId.add(oldCpn.Id);
			}
		}
		if(!sCpnId.isEmpty()){
			String couponStageNego = EBH_ConstantsUtility.COUPON_SELLER_STAGE_NEGO;
			
			List<Messaging.SingleEmailMessage> listEmail = new List<Messaging.SingleEmailMessage>();
			Map<String, EmailTemplate> mEmailTempl = new Map<String, EmailTemplate>();

			String emailTemplateName = '%' + EBH_ConstantsUtility.CPN_APPR_EMAILNOTIFI_TO_CAT_GROW_MANGR_EMAILTEMPLATE;
			String whereCl = ' Where DeveloperName LIKE: emailTemplateName'; 
			for(EmailTemplate emTm : Database.query(EBH_ConstantsUtility.SOQLEMAIL_TEMPLATES + whereCl)){
				mEmailTempl.put(emTm.DeveloperName, emTm);
			}
			
			Map<String, EmailByCountryWrap> mEmailAddr = new Map<String, EmailByCountryWrap>();
			

			

			List<String> lstUserEmail = new List<String>();
			List<String> lstCCEmail = new List<String>();
			for(User oneUser : ApexUtil.getUsersMemberByGroup(new Set<String>{EBH_ConstantsUtility.GROUP_UKCOUPONAPPROVER}).values()){
				lstUserEmail.add(oneUser.Email);
			}
			//LA-28-09-2023: US-0013980
			
			mEmailAddr.put(COUPON_SITE_UK, new EmailByCountryWrap(lstUserEmail, lstCCEmail));
			//LA-28-09-2023: US-0013980
			
			String couponSQL = CPNSELLER_CPNCOINVSOQL + ' WHERE Id IN: sCpnId';
			List<Coupon__c> lstCoupon = Database.query(couponSQL);
			for(Coupon__c oneCpn : lstCoupon){
				//LA-28-09-2023: US-0013980 : Replace oneCpn.Contract_Language__c to oneCpn.Main_Coupon_Site__c
				
				EmailTemplate emailTempl = mEmailTempl.get(MAP_CPN_APPR_LOCALIZE.get(oneCpn.Main_Coupon_Site__c));
				if(emailTempl == null) continue;

				String subject = emailTempl.Subject.replace('{!Coupon__c.Coupon_ID__c}', oneCpn.Coupon_ID__c).replace('{!Coupon__c.Marketing_Coupon_Name__c}', oneCpn.Marketing_Coupon_Name__c);
				
				// Prepare Email
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				String tblRows = '';
				String htmlBody = '';
				//LA-28-09-2023: US-0013980
				
				EmailByCountryWrap emWr = mEmailAddr.get(oneCpn.Main_Coupon_Site__c);

				

				// set table row
				for(Coupon_Co_Invest__c oneCpnCoInv : oneCpn.Coupon_Co_Invests__r){
					//LA-28-09-2023: US-0013980
					
					tblRows += mergeCouponCoInvRows(oneCpnCoInv, oneCpn.Main_Coupon_Site__c);
				}
				// set email body
				htmlBody = mergeCpnNegoEmailTemplateBody(emailTempl.HtmlValue, oneCpn).replace('{!RecordRows}', tblRows);
				
				mail.setToAddresses(emWr.lstUserEmail);
				if(!emWr.lstCCEmail.isEmpty()){
					mail.setCCAddresses(emWr.lstCCEmail);
				}
				
				mail.setSubject(subject);
				mail.setBccSender(false);
				mail.setUseSignature(false); 
				mail.setHtmlBody(htmlBody);
				//TH: 20/10/2020: US-0008543 - Set OrgWideDefault Address
				String replyto = oneCpn.Owner.Email;
				CouponSellerTriggerHandler.setOrgWideAddress(mail,replyto,System.label.OWD_MKT_REP);
				//End US-0008543
				listEmail.add(mail);
			}
			
			if(!listEmail.isEmpty() && !Test.isRunningTest()) Messaging.sendEmail(listEmail);
		}
    }

	/*****************************************************************************************************************************
    @ Method	:   checkNegotiationEndDateIsChange
    @ Version	:   1.0
    @ Author	: 	Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose	:	To retrigger the workflow : AU Coupon Approval Email Notification
    @ Trigger 	: 	after updated
	@ Param 	: 	Map<Id, Coupon__c> mOldnCoupon, Map<Id, Coupon__c> mNewCoupon	
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 12.10.2019 / Acmatac SEING / Method Creation
	@				  19.02.2024 / Mony Nou / US-0014783 - Developer script exception from Hive : CouponTrigger
    *****************************************************************************************************************************/
    public static void checkNegotiationEndDateIsChange(Map<Id, Coupon__c> mOldnCoupon, Map<Id, Coupon__c> mNewCoupon){
		List<Coupon__c> lstCpn = new List<Coupon__c>();
		Set<Id> sCpnId = new Set<Id>();
		for(Id cpnId : mOldnCoupon.keySet()){
			Coupon__c oldCpn = mOldnCoupon.get(cpnId);
			Coupon__c newCpn = mNewCoupon.get(cpnId);
			if(newCpn.Negotiation_End_Date__c != null && oldCpn.Negotiation_End_Date__c != newCpn.Negotiation_End_Date__c){
				lstCpn.add(new Coupon__c(Id=oldCpn.Id, CheckNegotiationEndDate__c=false));
				sCpnId.add(oldCpn.Id);
			}
		}
		if(!lstCpn.isEmpty()){
			update lstCpn;
			updateCoupon_CheckNegotiationEndDate_Asyn(sCpnId);
		}
	}

	private static String mergeCpnNegoEmailTemplateBody(String str, Coupon__c c)
 	{
		String cpnDisc = getObjectValue(c.Coupon_Discount__c) != '' ? getObjectValue(c.Coupon_Discount__c) : '0';
		String gmvTarg = getObjectValue(c.Coupon_GMV_Target__c) != '' ? getObjectValue(c.Coupon_GMV_Target__c) : '0';
		String cpnCap = getObjectValue(c.Coupon_Cap__c) != '' ? getObjectValue(c.Coupon_Cap__c) : '0';
		String cpnMaxRedeem = getObjectValue(c.Max_Redemptions__c) != '' ? getObjectValue(c.Max_Redemptions__c) : '0';
 		return str==null?'':str
			.replace('{!Coupon__c.Coupon_ID__c}',getObjectValue(c.Coupon_ID__c))
			.replace('{!Coupon__c.Marketing_Coupon_Name__c}',getObjectValue(c.Marketing_Coupon_Name__c))
			.replace('{!Coupon__c.Coupon_Start_Date__c}',(c.Coupon_Start_Date__c == null ? '':c.Coupon_Start_Date__c.format()))
			.replace('{!Coupon__c.Coupon_End_Date__c}',(c.Coupon_End_Date__c == null ? '':c.Coupon_End_Date__c.format()))
			.replace('{!Coupon__c.Contract_Due_Date__c}',(c.Contract_Due_Date__c == null ? '':c.Contract_Due_Date__c.format()))
			.replace('{!Coupon__c.Coupon_Discount__c}',cpnDisc)
			.replace('{!Coupon__c.Coupon_GMV_Target__c}',gmvTarg)
			.replace('{!Coupon__c.Coupon_Cap__c}',cpnCap)
			.replace('{!Coupon__c.Max_Redemptions__c}',cpnMaxRedeem)
 			.replace('{!Coupon__c.Link}','<a href="'+URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/Coupon__c/'+c.Id+'/view" target="_blank">'+ c.Coupon_ID__c +'</a>');
	}

	private static String mergeCouponCoInvRows(Coupon_Co_Invest__c oneCpnCoInv, String countryLang)
	{
		List<String> lstFields = new List<String>();

		String oracleId = getObjectValue(oneCpnCoInv.Coupon_Seller__r.Oracle_ID__c);
		String sellerName = getObjectValue(oneCpnCoInv.Coupon_Seller__r.Seller__r.Name);
		String categoryName = getObjectValue(oneCpnCoInv.Coupon_Category__r.Category__r.Name);
		String sellerFunding = String.isNotBlank(getObjectValue(oneCpnCoInv.Seller_Funding__c)) ? getObjectValue(oneCpnCoInv.Seller_Funding__c) : '0';
		String couponSellerRec = '<a href="'+URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/Coupon_Seller__c/'+oneCpnCoInv.Coupon_Seller__c+'/view" target="_blank">'+ oneCpnCoInv.Coupon_Seller__r.Name +'</a>';
		String couponSellerOwner = getObjectValue(oneCpnCoInv.Coupon_Seller__r.EBH_CouponSellerOwner__r.Name);
		String status = getObjectValue(oneCpnCoInv.Coupon_Seller__r.Coupon_Seller_Stage__c);
		String sellerShare = String.isNotBlank(getObjectValue(oneCpnCoInv.Co_Invest__c)) ? getObjectValue(oneCpnCoInv.Co_Invest__c) : '0';
		String ebayFunding = getObjectValue(oneCpnCoInv.eBayFunding__c);
		if(String.isBlank(ebayFunding)){
			ebayFunding = '0';
		}else{
			// to show as percentage
			ebayFunding = '' + Decimal.valueOf(ebayFunding) * 100;
		}
	
		if(countryLang == COUPON_SITE_AU){
			lstFields.add(oracleId);
			lstFields.add(sellerName);
			lstFields.add(categoryName);
			lstFields.add(sellerFunding);
			lstFields.add(ebayFunding);
			lstFields.add(sellerShare+'%');

		}else if(countryLang == COUPON_SITE_UK){
			lstFields.add(oracleId);
			lstFields.add(sellerName);
			lstFields.add(couponSellerRec);
			lstFields.add(couponSellerOwner);
			lstFields.add(status);
			lstFields.add(categoryName);
			lstFields.add(sellerShare+'%');
		}
		
		String result = '';
		for(String oneF : lstFields){
			result += CAP_ROWHTML.replace('{!fieldValue}', oneF);
		}

		return '<tr>'+ result +'</tr>\n';
	}

	

	// To retrigger the workflow timebased : AU Coupon Approval Email Notification
	@future
    private static void updateCoupon_CheckNegotiationEndDate_Asyn(Set<Id> sCpnId)
    {   
        List<Coupon__c> lstCpn = new List<Coupon__c>();
		for(Id cpnId : sCpnId){
			lstCpn.add(new Coupon__c(Id=cpnId, CheckNegotiationEndDate__c=true));
		}
		if(!lstCpn.isEmpty()){
			update lstCpn;
		}
	}
	
	private class EmailByCountryWrap{
		List<String> lstUserEmail;
		List<String> lstCCEmail;
		public EmailByCountryWrap(List<String> lstUserEmail, List<String> lstCCEmail){
			this.lstUserEmail = lstUserEmail;
			this.lstCCEmail = lstCCEmail;
		}
	}

	/*****************************************************************************************************************************
    @ Method	:   changeStage
    @ Version	:   1.0
    @ Author	: 	Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose	:	US-0011385 - External Sharing for Coupon Category/ Category Tree, And for any other stage change.
    @ Trigger 	: 	after update
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 11.03.2022 / Sophal Noch / Create Method
	                  30.06.2022 / Sambath Seng / US-0011998 - Business Feedback Focus 75 AC3
					  25.08.2022 / Loumang SENG / US-0012338 - Auto update coupon seller stage if Coupon at Seller Negotiation (AC1)
					  10.01.2023 / Loumang SENG / US-0012995 - Additional safeguarding for coupon seller automation (AC1)
					  11.01.2023 / Mony Nou / US-0012694 - [FR] Accessibility Configurations - Cannot deploy before launch
					  22.02.2023 / Sophal Noch / US-0012801 - Accessibility Configurations
					  27.02.2022 / Sovantheany dim / US-0013091 - Improve trigger when creating co-invest records Coupon Co-Invest records for big number of Categories and Sellers
    *****************************************************************************************************************************/
	public static void changeStage(List<Coupon__c> newCoupon, Map<Id, Coupon__c> mOldnCoupon){
		RecordType cpnRTypeItemBase = ApexUtil.getRecordTypeByName(COUPON_OBJNAME,COUPON_ITEMBASE_STAGE);
		Set<Id> setSellerNegoCpnItemId= new Set<Id>();
		Set<Id> setSellerNegoCpnId= new Set<Id>();

		

		for(Coupon__c cpn : newCoupon){
			if(cpn.Stage__c == COUPON_SELLER_NEGOTIATION_STAGE && cpn.Stage__c != mOldnCoupon.get(cpn.Id).Stage__c){
				if(cpn.RecordTypeId == cpnRTypeItemBase.Id) setSellerNegoCpnItemId.add(cpn.Id);
				
				
			}
		}

		if(!setSellerNegoCpnItemId.isEmpty()){
			List<Coupon_Category__c> listCpnCate = [Select Id From Coupon_Category__c Where Coupon__c In: setSellerNegoCpnItemId And Is_Visible_in_Seller_Portal__c = false];
			if(!listCpnCate.isEmpty()){
				for(Coupon_Category__c cpnCate : listCpnCate){
					cpnCate.Is_Visible_in_Seller_Portal__c = true; // Coupon_Category__c criteria-sharing rule will share the record to public group "DE - Seller Portal".
				}
				update listCpnCate;
			}
		}
		

	}

	

}