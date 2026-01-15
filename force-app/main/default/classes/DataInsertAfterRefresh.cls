public class DataInsertAfterRefresh {

	public static Id legalEntityRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('EBH_LegalEntity').getRecordTypeId();
	public static Id sellerRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('EBH_Seller').getRecordTypeId();
	public static Id brandRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('EBH_Brand').getRecordTypeId(); 
	public static Id cohortRTId = Schema.SObjectType.BOB__c.getRecordTypeInfosByDeveloperName().get('Light_Touch_Category_Cohort').getRecordTypeId();
	public static Id cohortSellerRTId = Schema.SObjectType.BoB_Seller__c.getRecordTypeInfosByDeveloperName().get('LTTM').getRecordTypeId();

	public static Map<String, String> oracleIDLegalEntityMap = new Map<String, String>{'142587081' => 'Bandel Automobiltechnik GmbH','1046392160'=> 'Entertainment Magpie Ltd','282289661'=> 'INGROTEK s.r.l.','18116485'=> 'ATP Autoteile GmbH','700143241'=> 'Folkestone Fixings Ltd','21032565'=> 'scheppach GmbH','2082770015'=>'VECOBAY SL','1025112015'=> 'Calzaretta Pasquale & C. Srl','989024507'=> 'Conrad Electronic SE','108582307'=> 'Hills Salvage and Recyling Limited','664002315'=> 'dell_australia','1255170916'=> 'sparesbox_auto','1037883721'=> 'superspares','77050681'=> 'mobileciti_estore','664002315'=> 'dell_australia','157936889'=> 'mighty_ape','96966141'=> 'mikesmapman','1698718850'=>'kea-health' ,'2216745102'=> 'lbtech-86','20181761'=> 'smokecds','1152887269'=>'Bullion Exchange LLC', '122824032'=> 'bidadoo','12359598'=> 'Liberty Coin LLC','139020616'=> 'CARPARTS.COMINC.','1123137099'=> 'BestBuy.comLLC','999497315' => 'autoshackautopartsusa','7894316' => 'north-of-7','1140364658'=>'slabsharksinc' , '1583092982'=> 'transit_auto','515913176' =>'asam96'};
	public static Map<String, String> oracleIDSellerMap = new Map<String, String>{'142587081' => 'bandel-autoteile','1046392160'=> 'musicmagpie','282289661'=> 'ingrotek','18116485'=> 'atp-autoteile','700143241'=> 'folkestonefixings','21032565'=> 'practixx-germany','2082770015'=> 'mercapool','1025112015'=> 'ricambi_smc','989024507'=> 'conrad_electronic','108582307'=> 'hillsmotors','664002315'=> 'dell_australia','1255170916'=> 'sparesbox_auto','1037883721'=> 'superspares','77050681'=> 'mobileciti_estore','664002315'=> 'dell_australia','157936889'=> 'mighty_ape','96966141'=> 'mikesmapman','1698718850'=>'kea-health' ,'2216745102'=> 'lbtech-86','20181761'=> 'smokecds','1152887269'=>'bullion.exchanges', '122824032'=> 'bidadoo_business','12359598'=> 'liberty.coin','139020616'=> 'carpartswholesale','1123137099'=> 'best_buy','999497315' => 'autoshackautopartsusa','7894316' => 'north-of-7','1140364658'=>'slabsharksinc','1583092982'=> 'transit_auto','515913176' =>'asam96'};
	public static Map<String, String> oracleIDRevRollupMap = new Map<String, String>{'142587081' => 'DE','1046392160'=> 'UK','282289661'=>  'IT','18116485'=> 'DE','700143241'=>  'UK','21032565'=>   'DE','2082770015'=> 'SP','1025112015'=> 'IT','989024507'=> 'DE','108582307'=> 'UK','664002315'=> 'AU','1255170916'=> 'AU','1037883721'=> 'AU','77050681'=> 'AU','664002315'=> 'AU','157936889'=> 'NZ','96966141'=> 'NZ','1698718850'=> 'NZ','2216745102'=> 'NZ','20181761'=> 'NZ','1152887269'=> 'US','122824032'=> 'US','12359598'=> 'US','139020616'=> 'US','1123137099'=> 'US','999497315' => 'CA','7894316' => 'CA','1140364658'=> 'CA','1583092982'=> 'CA','515913176' =>'CA'};
	public static Map<String, String> revRollupCountryMap = new Map<String, String>{'DE' => 'Germany', 'UK' => 'United Kingdom', 'IT' => 'Italy', 'US' => 'United States', 'CA' => 'Canada', 'NZ' => 'New Zealand', 'SP' => 'Spain', 'AU' => 'Australia'};
	public static Map<String, String> clinicsMap = new Map<String, String>{'1.1 Click-through rate (%)'=>'Conversion funnel','1.2 Conversion rate (SI/VI) (%)'=>'Conversion funnel','2.1 Live Listings with EAN/MPN (%)'=>'Listing health','2.2 Average number of characters in titles'=>'Listing health','2.3 Live Listings with subtitles (%)'=>'Listing health','2.4 Live Listings with multi-SKU (%)'=>'Listing health','2.5 SKU variations per Live Listing'=>'Listing health','2.6 Live Listings with quantity >1 (%)'=>'Listing health','2.7 Average photo count'=>'Listing health','3.1 Live Listings with eBay plus (%)'=>'Shipping & return policies','3.2 Live Listings with eBay guarantee (%)'=>'Shipping & return policies','3.3 Average handling time (days)'=>'Shipping & return policies','3.4 Live Listings with free shipping (%)'=>'Shipping & return policies','3.5 Average shipping cost (USD)'=>'Shipping & return policies','3.6 Live Listings with free returns (%)'=>'Shipping & return policies','3.7 Live Listings with more than 14 days return (%)'=>'Shipping & return policies','4.1 Promoted listings (%)'=>'Promotions','4.2 Live Listings with SME (%)'=>'Promotions','4.3 Live Listings with best offer (%)'=>'Promotions','5.1 Live Listings with international shipping, passive CBT (%)'=>'International metrics','5.2 Live Listings with Global Shipment Programme (%)'=>'International metrics','6.1 Live Listings'=>'Listings metrics','6.2 Live Listings that ever sold (%)'=>'Listings metrics','7.1 Live Listings GMV per SKU'=>'','7.1 Mobile Share of GMV (%)'=>'Mobile Metrics','7.2 Number of leaf categories'=>'','GMV local currency'=>'Performance overview','Impressions per live listings'=>'Conversion funnel','New condition listing'=>'','Sold items count'=>'Performance overview'};
	public static Map<String, String> clinicsDriverMap = new Map<String, String>{'1.1 Click-through rate (%)'=>'CT_RATE','1.2 Conversion rate (SI/VI) (%)'=>'CR_NUM','2.1 Live Listings with EAN/MPN (%)'=>'EAN_LL_PCT','2.2 Average number of characters in titles'=>'AVG_TITL_LGTH_NUM','2.3 Live Listings with subtitles (%)'=>'SBTTL_LL_PCT','2.4 Live Listings with multi-SKU (%)'=>'MSKU_LL_PCT','2.5 SKU variations per Live Listing'=>'AVG_SKU_CNT','2.6 Live Listings with quantity >1 (%)'=>'MQTY_LL_PCT','2.7 Average photo count'=>'AVG_PHOTO_CNT','3.1 Live Listings with eBay plus (%)'=>'eBay_PLUS_LL_PCT','3.2 Live Listings with eBay guarantee (%)'=>'eBay_GRNT_LL_PCT','3.3 Average handling time (days)'=>'AVG_HNDLG_DAY_NUM','3.4 Live Listings with free shipping (%)'=>'FREE_SHPG_LL_PCT','3.5 Average shipping cost (USD)'=>'AVG_SHPG_COST_USD_AMT','3.6 Live Listings with free returns (%)'=>'SLR_PAY_RTRN_LL_PCT','3.7 Live Listings with more than 14 days return (%)'=>'GRTR_14_DAY_RTRN_LL_PCT','4.1 Promoted listings (%)'=>'PRM_LL_PCT','4.2 Live Listings with SME (%)'=>'SME_LL_PCT','4.3 Live Listings with best offer (%)'=>'BEST_OFFER_LL_PCT','5.1 Live Listings with international shipping, passive CBT (%)'=>'PASV_CBT_LL_PCT','5.2 Live Listings with Global Shipment Programme (%)'=>'GSP_ADPTD_LL_PCT','6.1 Live Listings'=>'LL_CNT','6.2 Live Listings that ever sold (%)'=>'SOLD_LL_PCT','7.1 Live Listings GMV per SKU'=>'AVG_DLY_GMV_Per_SKU_NUM','7.1 Mobile Share of GMV (%)'=>'MBL_GMV_PCT','7.2 Number of leaf categories'=>'LEAF_CATEG_CNT','GMV local currency'=>'GMV_LC_AMT','Impressions per live listings'=>'SRP_CNT/LL_CNT','New condition listing'=>'','Sold items count'=>'SI_CNT'};
	public static Map<String,String> actionMap = new Map<String,String>{'Increase listings with free shipping'=>'3.4 Live Listings with free shipping (%)','Decrease listings with free shipping'=>'3.4 Live Listings with free shipping (%)','Decrease listings with free returns'=>'3.6 Live Listings with free returns (%)','Increase listings with free returns'=>'3.6 Live Listings with free returns (%)','Increase average photo count'=>'2.7 Average photo count','Decrease average photo count'=>'2.7 Average photo count','Provide longer than 14 days return'=>'3.7 Live Listings with more than 14 days return (%)','Provide shorter than 14 days return'=>'3.7 Live Listings with more than 14 days return (%)','Increase handling days'=>'3.3 Average handling time (days)','Decrease handling days'=>'3.3 Average handling time (days)','Increase listing title length'=>'2.2 Average number of characters in titles','Decrease listing title length'=>'2.2 Average number of characters in titles','Increase EAN listings'=>'2.1 Live Listings with EAN/MPN (%)','Decrease EAN listings'=>'2.1 Live Listings with EAN/MPN (%)','Increase multi quantity listings'=>'2.6 Live Listings with quantity >1 (%)','Decrease multi quantity listings'=>'2.6 Live Listings with quantity >1 (%)','Add subtitles to the listings'=>'2.3 Live Listings with subtitles (%)','Delete subtitles from the lsitings'=>'2.3 Live Listings with subtitles (%)','Increase live listing'=>'6.1 Live Listings','Decrease live listing'=>'6.1 Live Listings','Cover more leaf categories'=>'7.2 Number of leaf categories','Cover less leaf categories'=>'7.2 Number of leaf categories','Increase passive CBT'=>'5.1 Live Listings with international shipping, passive CBT (%)','Decrease passive CBT'=>'5.1 Live Listings with international shipping, passive CBT (%)','Increase multi SKU listings'=>'2.4 Live Listings with multi-SKU (%)','Decrease multi SKU listings'=>'2.4 Live Listings with multi-SKU (%)','Increase new condition listings'=>'New condition listing','Decrease new condition listings'=>'New condition listing','Increase involvement in global shipping program'=>'5.2 Live Listings with Global Shipment Programme (%)','Decrease involvement in global shipping program'=>'5.2 Live Listings with Global Shipment Programme (%)','Increase best offer listing'=>'4.3 Live Listings with best offer (%)','Decrease best offer listing'=>'4.3 Live Listings with best offer (%)','Increase listings with eBay plus'=>'3.1 Live Listings with eBay plus (%)','Increase number of promoted listings'=>'4.1 Promoted listings (%)','Increase number of SME listings'=>'4.2 Live Listings with SME (%)'};
	
    public static void insertData(){
		//insert Legal Entity
		List<Account> legalEntities = new List<Account>();    
		for(String entity : oracleIDLegalEntityMap.keySet()){
	    	legalEntities.add(new Account(Name = oracleIDLegalEntityMap.get(entity), RecordTypeId = legalEntityRTId, EBH_BillingCountry__c = 'UK'));
		}
		insert legalEntities;

		Map<String, Id> legalEntityMap = new Map<String, Id>();
		for (Account le: [Select Id,Name from Account where RecordTypeId =: legalEntityRTId]){
		    legalEntityMap.put(le.Name,le.Id);
		}
		//insert Sellers
		List<Account> listSellerToInsert = new List<Account>();
		for(String slrs : oracleIDSellerMap.keySet()){
		    Account seller = new Account();
		    seller.RecordTypeId = sellerRTId;
		    seller.Name = oracleIDSellerMap.get(slrs);
		    seller.EBH_OracleID__c = slrs;
		    seller.EBH_RevRollup__c = oracleIDRevRollupMap.get(slrs);
		    seller.EBH_PrimarySite__c = revRollupCountryMap.get(oracleIDRevRollupMap.get(slrs));
		    seller.EBH_SellerType__c  = 'Business';
		    seller.EBH_Segment__c = Account.EBH_Segment__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 5)].getValue();
		    seller.EBH_LifecycleStage__c = Account.EBH_LifecycleStage__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 3)].getValue();
		    seller.CSS_Segment__c = Account.CSS_Segment__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 2)].getValue();
		    seller.Managed_Type__c = Account.Managed_Type__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 3)].getValue();
		    seller.EBH_MainVertical__c = Account.EBH_MainVertical__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 7)].getValue();
		    seller.EBH_BOBSegment__c = Account.EBH_BOBSegment__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 9)].getValue();
		    seller.BoB_Subsegment__c = Account.BoB_Subsegment__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 4)].getValue();
		    seller.EBH_RegistrationCountry__c  = revRollupCountryMap.get(oracleIDRevRollupMap.get(slrs));
		    seller.EBH_BOBVertical__c = Account.EBH_BOBVertical__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 9)].getValue();
		    seller.EBH_BOBCNTRY__c = oracleIDRevRollupMap.get(slrs);
		    seller.EBH_ActualStandard__c = Account.EBH_ActualStandard__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 2)].getValue();
		    seller.EBH_PredictedStandard__c = Account.EBH_PredictedStandard__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 2)].getValue();
		    seller.ParentId  = legalEntityMap.get(oracleIDLegalEntityMap.get(slrs));
		    seller.EBH_StoreSubscription__c = Account.EBH_StoreSubscription__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 3)].getValue();
		    listSellerToInsert.add(seller);
		}
		insert listSellerToInsert;

		//insert brands
		List<String> brandList = new List<String>{'APPLE','SAMSUNG','PANINI','TOPPS','NIKE','SONY','NINTENDO','U.S. MINT','FORD','HP','DELL','ROLEX','LENOVO','LEGO','BMW','CANON','ADIDAS','HONDA','TOYOTA','MERCEDES-BENZ','BOSCH'};
		List<Account> brandsToInsert = new List<Account>();
		for(String str : brandList){
		    brandsToInsert.add(new Account(Name = str, RecordTypeId = brandRTId));
		}
		insert brandsToInsert;

		//insert seller brands
		List<Account> sellers = [Select Id from Account where Id IN: listSellerToInsert];

		//inser urgent details
		List<Urgency_Detail__c> urgencyDetails = new List<Urgency_Detail__c>();
		for (Account oAcc: sellers){
			urgencyDetails.add(new Urgency_Detail__c(Seller__c = oAcc.Id,Urgency_Details__c = Urgency_Detail__c.Urgency_Details__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 9)].getValue(),Urgency_Reason__c = Urgency_Detail__c.Urgency_Reason__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 3)].getValue()));
		}
		insert urgencyDetails;

		//insert seller brand
		List<Account> brands = [Select Id,Name from Account where RecordTypeId =: brandRTId];
		Map<Id,String> brandMap = new Map<Id,String>();
		List<EBH_SellerBrand__c> sellerBrand = new List<EBH_SellerBrand__c>();
		Integer iCount = 0;
		for (Account br : brands){
			brandMap.put(br.Id,br.Name);
			sellerBrand.add(new EBH_SellerBrand__c(EBH_Brand__c = br.Id,EBH_Seller__c = sellers[iCount].Id, Authorised_Seller_Type__c = EBH_SellerBrand__c.Authorised_Seller_Type__c.getDescribe().getPicklistValues()[Integer.valueof((Math.random() * 1))].getValue()));    
			iCount=iCount+1;
		}
		insert sellerBrand;
		
		//insert brand match
		Map<String,String> brandMatchMap = new Map<String,String>{'APPLE' => 'APPLE','APPLE INC.' => 'APPLE','APPLE COMPUTER' => 'APPLE','SAMSUNG' => 'SAMSUNG','SAMSUNG ELECTRONICS' => 'SAMSUNG','SAMSUNG GALAXY' => 'SAMSUNG','PANINI' => 'PANINI','TOPPS' => 'TOPPS','NIKE' => 'NIKE','NIKE GOLF' => 'NIKE','NIKE JORDAN' => 'NIKE','SONY' => 'SONY','SONY PLAYSTATION' => 'SONY','SONY CORPORATION' => 'SONY','NINTENDO' => 'NINTENDO','NINTENDO GAMES' => 'NINTENDO','NINTENDO ENTERTAINMENT SYSTEM' => 'NINTENDO','U.S. MINT' => 'U.S. MINT','FORD' => 'FORD','FORD MOTOR COMPANY' => 'FORD','FORD PERFORMANCE' => 'FORD','HP' => 'HP','HEWLETT PACKARD' => 'HP','HEWLETT-PACKARD' => 'HP','DELL' => 'DELL','DELL EMC' => 'DELL','DELL WYSE' => 'DELL','ROLEX' => 'ROLEX','ROLEX SUBMARINER' => 'ROLEX','LENOVO' => 'LENOVO','LENOVO YOGA' => 'LENOVO','IBM LENOVO' => 'LENOVO','LEGO' => 'LEGO','LEGO DISNEY' => 'LEGO','LEGO DUPLO' => 'LEGO','BMW' => 'BMW','BMW / MINI' => 'BMW','BMW OEM' => 'BMW','CANON' => 'CANON','REMANUFACTURED CANON' => 'CANON','VIVITAR/XIT FOR CANON EOS REB' => 'CANON','ADIDAS' => 'ADIDAS','ADIDAS PERFORMANCE' => 'ADIDAS','ADIDAS ORIGINALS' => 'ADIDAS','HONDA' => 'HONDA','HONDA ACURA' => 'HONDA','GENUINE FACTORY AMERICAN HONDA' => 'HONDA','TOYOTA' => 'TOYOTA','TOYOTA / LEXUS' => 'TOYOTA','GENUINE TOYOTA' => 'TOYOTA','MERCEDES-BENZ' => 'MERCEDES-BENZ','BOSCH' => 'BOSCH','BOSCH PROFESSIONAL' => 'BOSCH','BOSCH ELEKTROWERKZEUGE' => 'BOSCH'};
		List<Brand_Match__c> brandMatch = new List<Brand_Match__c>();
		// for (String str : brandMatchMap.keySet()){
        for(Account oAcc: brandsToInsert){
    		brandMatch.add(new Brand_Match__c(Matched_Value__c = oAcc.Name, Brand__c = oAcc.Id,GMV_Last_12_Months__c = Integer.valueof(Math.random() * 200000), SI_Last_12_Months__c = Integer.valueof(Math.random() * 100000)));
		}
		insert brandMatch;

		//insert seller management
		Map<String, String> sellerManagementMap= new Map<String, String>{'IT Other'=>'IT 2024','AU FMCG'=>'AU Key Account Management','UK Other'=>'UK Focus','UK Parts & Accessories'=>'UK Parts & Accessories','US Home & Garden'=>'Hard Home Refurbished','AU FMCG'=>'AU Key Account Management','US Parts & Accessories'=>'P&A','DE Parts & Accessories'=>'DE Parts & Accessories','AU Other'=>'AU aSelleration FebQ1','DE Parts & Accessories'=>'DE Parts & Accessories','ES Other'=>'ES 2024','DE Home & Garden'=>'DE Home & Garden - Managed BoB','IT Other'=>'IT 2024','UK Other'=>'UK Focus','AU FMCG'=>'AU Key Account Management','DE Electronics'=>'DE Electronics'};
		List<BOB__c> sellerManagement = new List<BOB__c>();
		for (String str : sellerManagementMap.keySet()){
			BoB__c cohort = new BOB__c();
			cohort.Name = str;
			cohort.RecordTypeId = cohortRTId;
			cohort.Campaign_Code__c = sellerManagementMap.get(str) +' Other';
			cohort.LTTM_Group__c = sellerManagementMap.get(str);
			cohort.Status__c = 'Cohort Active';
			cohort.EBH_BOBCNTRY__c = str.substring(0,2);
			cohort.EBH_BOBVertical__c = BOB__c.EBH_BOBVertical__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 12)].getValue();
			cohort.Managed_Type__c = BOB__c.Managed_Type__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 3)].getValue();
			cohort.Managed_Segment__c = BOB__c.Managed_Segment__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 18)].getValue();
            cohort.Registration_Start_Date__c = System.today();
            cohort.RegistrationCloseDate__c = System.today().addDays(50);
			sellerManagement.add(cohort);
		}
		insert sellerManagement;

		//insert cohort sellers
		// sellers = [Select Id from Account where RecordTypeId =: sellerRTId];
		sellerManagement = [Select Id,Name from BoB__c];
		List<BoB_Seller__c> cohortSellers = new List<BoB_Seller__c>();
		for (Account oAcc: sellers){
		    BoB_Seller__c bs = new BoB_Seller__c();
		    bs.RecordTypeId = cohortSellerRTId;
		    bs.Seller__c = oAcc.Id;
		    bs.BoB__c = sellerManagement[Integer.valueof(Math.random() * 10)].Id;
		    bs.Status__c = 'Draft';
		    bs.Call_Attempt__c = Integer.valueof(Math.random() * 3);
		    bs.Call_Outcome__c = BoB_Seller__c.Call_Outcome__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 8)].getValue();
		    bs.EBH_BOBSegment__c = BoB_Seller__c.EBH_BOBSegment__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() * 19)].getValue();
		    bs.Seller_Signed_up__c = Integer.valueof(Math.random() * 10)<6 ? true : false;
		    cohortSellers.add(bs);
		}
		insert cohortSellers;
		
		//insert action template
		List<Action_Template__c>  actionTemplate = new  List<Action_Template__c>();
		for (Schema.PicklistEntry str : Action_Template__c.Country__c.getDescribe().getPicklistValues()){
			for (Integer i=1; i<=10; i++){
				Action_Template__c at = new Action_Template__c();
				at.Name = 'Action Template '+ i + ' '+str.getValue();
				at.Description__c = 'New Action Template '+ i + ' '+str.getValue();
				at.Country__c = str.getValue() == 'IE' ? 'UK' : str.getValue();
				at.RecordTypeId = Schema.SObjectType.Action_Template__c.getRecordTypeInfosByDeveloperName().get('LTTM').getRecordTypeId();
				at.Active__c = true;
				actionTemplate.add(at);
			}
		}
		insert actionTemplate;
		
		//insert action
		List<Action__c> actions = new List<Action__c>();
        Integer countAT = 0;
		for (BoB_Seller__c bs: cohortSellers){
			Action__c action = new Action__c();
			action.Name = 'Local Shopping: Pick-Up';
			action.RecordTypeId = Schema.SObjectType.Action__c.getRecordTypeInfosByDeveloperName().get('LTTM').getRecordTypeId();
			action.Action_Template__c = actionTemplate[countAT].Id;
			action.LTTM_Seller__c = bs.Id;
			action.Action_Outcome__c = math.mod(countAT, 3) == 0 ? 'DMC Committed' : 'DMC Not Interested';
			action.Status__c = math.mod(countAT, 3) == 0 ? 'In Progress' : 'Completed';
			action.Start_Date__c = Date.today().addDays(-Integer.valueof(Math.random() * 100));
			actions.add(action);
            countAT++;
		}
		insert actions;

		//insert targeting engine
		List<EBH_Filter__c> targetingToInsert = new List<EBH_Filter__c>();
		for(String str:revRollupCountryMap.keySet()){
			EBH_Filter__c targetEngine = new EBH_Filter__c();
			targetEngine.RecordTypeId = Schema.SObjectType.EBH_Filter__c.getRecordTypeInfosByDeveloperName().get('EBH_ManualSellerList').getRecordTypeId();
			targetEngine.Name = 'Active Projects '+str;
			targetEngine.EBH_TE_Expiration_Date__c = Date.today().addDays(365+Integer.valueof(Math.random() *100));
			targetEngine.EBH_TE_Main_Purpose__c = EBH_Filter__c.EBH_TE_Main_Purpose__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() *3)].getValue();
			targetingToInsert.add(targetEngine);
		}
		insert targetingToInsert;

		// insert seller list
		List<EBH_TargetedSeller__c> sellersList = new List<EBH_TargetedSeller__c>();
		Map<String, set<Id>> sellerRevRollUpMap = new Map<String, set<Id>>();
		
		for (Account seller : [Select Id, EBH_RevRollup__c from Account where RecordTypeId =: sellerRTId AND EBH_RevRollup__c != NULL]){
			if(!sellerRevRollUpMap.containsKey(seller.EBH_RevRollup__c)){
				sellerRevRollUpMap.put(seller.EBH_RevRollup__c, new Set<Id>{seller.Id});
			}else{
				sellerRevRollUpMap.get(seller.EBH_RevRollup__c).add(seller.Id);
			}
		}

		for(EBH_Filter__c targeting : [Select Id,Name from EBH_Filter__c]){
			EBH_TargetedSeller__c sellerList = new EBH_TargetedSeller__c();
			if(sellerRevRollUpMap.get(targeting.Name.substringAfterLast(' ')) != null){
				for(Id seller : sellerRevRollUpMap.get(targeting.Name.substringAfterLast(' '))) {
		    		sellersList.add(new EBH_TargetedSeller__c(EBH_SellerList__c = targeting.Id, EBH_Seller__c  = seller));
				}
			}
		}
		insert sellersList;

		//insert badges
		List<trailheadapp__Badge__c> badges = new List<trailheadapp__Badge__c>();
		for (Integer i = 1; i<=30; i++){
			trailheadapp__Badge__c badge = new trailheadapp__Badge__c();
			badge.Name = 'Badge no '+i;
			badge.trailheadapp__Description__c = 'New Badge no '+i;
			badge.trailheadapp__Type__c = 'Module';
			badge.trailheadapp__Level__c = trailheadapp__Badge__c.trailheadapp__Level__c.getDescribe().getPicklistValues()[Integer.valueof(Math.random() *2)].getValue();
			badge.trailheadapp__Products__c = 'Product '+i;
			badge.trailheadapp__Icon__c = 'https://res.cloudinary.com/hy4kyit2a/image/upload/v1412121038/2014-TH-Coming_Soon_fqu1ot.png';
			badge.trailheadapp__Namespace__c = 'learn';
			badge.trailheadapp__API_Name__c = 'badge-no-'+i;
			badge.trailheadapp__URL__c = 'https://developer.salesforce.com/trailhead/module/badgeno' + i;
			badges.add(badge);
		}
		insert badges;

		//insert user badges
		List<trailheadapp__User_Badge__c> userBadges = new List<trailheadapp__User_Badge__c>();
		List<User> users = [Select Id from User where IsActive =: true];
		for (trailheadapp__Badge__c badge : [Select Id from trailheadapp__Badge__c]){
			Integer randomNo = Integer.valueof(Math.random() *7);
			for(Integer i = 0; i<randomNo; i++){
				trailheadapp__User_Badge__c userBadge = new trailheadapp__User_Badge__c();
				userBadge.trailheadapp__Badge__c = badge.Id;
				userBadge.trailheadapp__User__c  = users[Integer.valueof(Math.random() *users.size())].Id;
				userBadge.trailheadapp__Status__c = math.mod(i, 3) == 0 ? 'Assigned' : 'Completed';
				userBadges.add(userBadge);
			}
		}
		insert userBadges;

		//insert Clinics
		List<EBH_Clinic__c> clinics = new List<EBH_Clinic__c>();
		Integer i = 0;
		for (String str : clinicsMap.keySet()){
			EBH_Clinic__c clinic = new EBH_Clinic__c();
			clinic.Name = str;
			clinic.Group__c = clinicsMap.get(str);
			clinic.Order__c = i+1;
			clinic.EBH_Driver__c = clinicsDriverMap.get(str);
			clinics.add(clinic);
		}
		insert clinics;

		Map<String,Id> clinicIdMap = new Map<String,Id>();
		clinics = [Select Id, Name from EBH_Clinic__c];
		for(EBH_Clinic__c clnc : clinics){
			clinicIdMap.put(clnc.Name,clnc.Id);
		}
		//insert Action
		Integer j = 0;
		List<EBH_Action__c> actionToInsert = new List<EBH_Action__c>();
		for(String str : actionMap.keySet()){
			EBH_Action__c action = new EBH_Action__c();
			action.EBH_ActionID__c = String.valueOf(j+1);
			action.EBH_ActionDescription__c = str;
			action.EBH_DriverofValueDescription__c = actionMap.get(str);
			action.EBH_Clinic__c = clinicIdMap.get(str);
			actionToInsert.add(action);
			j++;
		}
		insert actionToInsert;
	}
}