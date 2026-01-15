/*********************************************************************************************************************************
@ Class:         LC_LandingController
@ Version:       1.0
@ Author:        Sreymeas Nao (sreymeas.nao@gaea-sys.com)
@ Purpose:       US-0007769 - [AU] Coupon Sellers have to accept MSA and Coupon Term Sheet on every single Coupon
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 31.07.2020 / Sreymeas Nao (sreymeas.nao@gaea-sys.com) / Created the class.
				  21.04.2021 / Mony Nou (mony.nou@gaea-sys.com) /US-0009432 - {Hypercare} - [AU Coupons] - Coupons T's & C's sent to seller are blank
				  20.07.2021/ Sovantheany Dim (sovantheany.dim@gaea-sys.com) / US-0009570 - [AU] [Coupon] Update AU Coupons Master Agreement
				  06/12/2021 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / US-0010770 - AU Coupon Term sheet update
@				 : 28.09.2023 / Loumang SENG / US-0013980 - Retire Contract Template field on Coupon
				: 02.10.2023 / Sambath Seng / US-0012340 - Destruction of Coupon Item Object
*********************************************************************************************************************************/
public without sharing class TC_LandingController {
    public String cpnSellerId 							{get;set;} 
	public Coupon_Seller__c cpnSellerRec 				{get;set;}
	//public ApexPages.StandardController stdCntrlr 		{get;set;}
	public String ncouponContractClickMeUrl 			{get;set;}
	public static String retUrl							{get;set;}
	public Boolean isSelect								{get;set;}
	public String sDate									{get;set;}
	public String eDate 								{get;set;}
	public Datetime sDateTime							{get;set;}
	public Datetime eDateTime							{get;set;}
	public List<Coupon_Co_Invest__c> cCInvestList		{get;set;}
	public String legEntity								{get;set;}
	public String msg									{get;set;} 
	public String sellerFunding							{get;set;}

    public static String couponContractClickMeUrl = ApexUtil.getSiteUrl('Deal_Acceptance')+'?restype='+EBH_TrackingResponseController.CONRACT_COUPON_URL_TYPE+'&csid=%csid%&'+'&uid=%uid%&';//+EBH_TrackingResponseController.REDIRECT_URL;  
	private final static Map<String, String> COUPON_MAINSITE_MAPPING = new Map<String, String> {
			'ebay.de'       => 'DE',
			'ebay.co.uk'    => 'UK',
			'ebay.fr'       => 'FR',
			'ebay.it'       => 'IT',
			'ebay.com.au'   => 'AU',
			'ebay.es'       => 'ES',
			'ebay.com'      => 'US'
			
	};
    private static Map<String,String> mapRetURL = new Map<String,String>{'DE'=>'reURL=www.ebay.de','UK'=>'reURL=www.ebay.co.uk','FR'=>'reURL=www.ebay.fr','US'=>'reURL=www.ebay.com'};
	private final static String COUPON_SELLER_STAGE_CONTRACT_SIGNED = 'Contract Signed';
	//LA-28-09-2023-US-0013980: Replace Coupon__r.Contract_Language__c to Seller__r.EBH_RevRollup__c
	private final static String sqlCpn = 'select Id,Seller__r.EBH_RevRollup__c,Coupon__r.Main_Coupon_Site__c,Coupon_ID__c,Coupon__r.Coupon_ID__c,Coupon_Discount_Rate__c,Coupon__r.RecordType.DeveloperName,Coupon_Seller_Stage__c,Seller__r.Name, Coupon__r.Coupon_Start_Time__c, Coupon__r.Coupon_Start_Date__c, Coupon__r.Coupon_end_Time__c, Coupon__r.Coupon_End_Date__c, Coupon__r.Coupon_Discount__c, Additional_Terms_Override_of_Agreement__c,Legal_Entity_Name_w__c,Co_funding__c ,Advertising_Promotion__c,Free_Subtitles__c,Advertising_Amount__c,Ad_Spend_Date__c from Coupon_Seller__c';
	private final static String SOQL_COUPONCOINVEST = 'select Seller_Funding__c, Coupon_Name__c,OwnerId, Coupon_Seller__r.Coupon_Seller_Stage__c,Coupon_Seller__r.Seller__r.EBH_RevRollup__c,id,Site__c,Category__c,Category_ID__c,Co_Invest__c, Item_ID__c, Coupon_Seller__c, Coupon_Category__c from Coupon_Co_Invest__c';
	Map<Integer,String> mapCategories = new Map<Integer,String>();
	public String categories {get;set;}

	public Coupon cp {get;set;} //MN-21042021-US-0009432
	
    public TC_LandingController(ApexPages.StandardController controller) {
			isSelect = false;
		//stdCntrlr = controller;
			cpnSellerId = ApexPages.currentPage().getParameters().get('id');
			//System.debug('cpnSellerId>>>>'+cpnSellerId);
			cpnSellerRec = Database.query(sqlCpn + ' where Id = :cpnSellerId');
			//System.debug('cpnSellerRec>>>>'+cpnSellerRec);
			//System.debug('cSELLER>>>>'+cpnSellerRec.Seller__r.Name);
			legEntity = cpnSellerRec.Legal_Entity_Name_w__c;

			this.cp = new Coupon(); //MN-21042021-US-0009432
			if (cpnSellerRec != null) this.cp = new Coupon(cpnSellerRec); //MN-21042021-US-0009432
			

			Datetime SDateTime =  DateTime.valueOf(string.valueOf(cpnSellerRec.Coupon__r.Coupon_Start_Date__c) + ' ' + string.valueOf(cpnSellerRec.Coupon__r.Coupon_Start_Time__c) );
			Datetime eDateTime =  DateTime.valueOf(string.valueOf(cpnSellerRec.Coupon__r.Coupon_End_Date__c) + ' ' + string.valueOf(cpnSellerRec.Coupon__r.Coupon_end_Time__c) );
			sDate = sDateTime.format('h:mm a');
			eDate = eDateTime.format('h:mm a');
			//LA-28-09-2023-US-0013980: Replace cpnSellerRec.Coupon__r.Contract_Language__c to cpnSellerRec.Coupon__r.Main_Coupon_Site__c
			String couponMainSite = COUPON_MAINSITE_MAPPING.get(cpnSellerRec.Coupon__r.Main_Coupon_Site__c);
			//retUrl = mapRetURL.containsKey(cpnSellerRec.Coupon__r.Contract_Language__c)?mapRetURL.get(cpnSellerRec.Coupon__r.Contract_Language__c):mapRetURL.get('US'); 
			retUrl = mapRetURL.containsKey(couponMainSite)?mapRetURL.get(couponMainSite):mapRetURL.get('US'); 

			ncouponContractClickMeUrl = couponContractClickMeUrl.replace('%csid%',cpnSellerId+'').replace('%uid%',UserInfo.getUserId()+'')+retUrl;


			cCInvestList = Database.query(EBH_ConstantsUtility.SOQL_COUPONCOINVEST +' Where Coupon_Seller__c =: cpnSellerId');
			//TH:06/12/2021:US-0010770
			sellerFunding = cCInvestList.isEmpty()?'':cCInvestList[0].Seller_Funding__c+'';

			categories = '';
			for(Coupon_Co_Invest__c coInvest : cCInvestList){
				
				if(coInvest.Category__c == null) continue;
				if(coInvest.Category__c == 'Australia (Site Level)'){
				mapCategories.put(1,System.Label.AU_Category + '<br>');
				}else{
					mapCategories.put(2,System.Label.Not_AU_Category + '<br>');
				}

				cp.lstCCI.add(new CouponCoInvest(coInvest)); //MN-21042021-US-0009432
			}
			if(!mapCategories.isEmpty()){
				List<Integer> listOrder = new List<Integer>();
				listOrder.addAll(mapCategories.keySet());
				listOrder.sort();
				for(Integer i : listOrder){
					categories += mapCategories.get(i);
				}
			}
			//TH : US-0009570 : get couon item
			// 2.10.2023 / Sambath Seng / US-0012340 - Destruction of Coupon Item Object
			/* set<String> sCouponItemIds = new set<String>();
			for(Coupon_Item__c coItem : Database.query(EBH_ConstantsUtility.SOQL_COUPONITEM +' Where Coupon_Seller_ID__c =: cpnSellerId order by Name')){
				sCouponItemIds.add(coItem.Item_ID__c);
			}
			cp.couponItemIds = String.join(new List<String>(sCouponItemIds), ', ');
			cp.couponItemIds.removeEnd(', '); */
			//end US-0009570
    }

    /*****************************************************************************************************************************
    @ Method:   validateCheckBox
    @ Version:  1.0
    @ Author: 	Sreymeas Nao (sreymeas.nao@gaea-sys.com)
    @ Purpose:	US-0007769 - [AU] Coupon Sellers have to accept MSA and Coupon Term Sheet on every single Coupon
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 30.07.2020 / Sreymeas Nao / Created the  Method.
    *****************************************************************************************************************************/
	public Pagereference validateCheckBox(){
		if (!isSelect) {
			msg=System.Label.ERR_MSG_TC;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,msg));
			return null;
		}else if(cpnSellerRec.Coupon_Seller_Stage__c==COUPON_SELLER_STAGE_CONTRACT_SIGNED){
			msg=System.Label.CP_MSG_ACCPETED;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,msg));
			return null;
		}else{
			pagereference returnPage= new pagereference(ncouponContractClickMeUrl);
			return returnPage;
		}
	}

	//MN-21042021-US-0009432 - Use Wrapper Class instead of access to sObject Record directly
	public class Coupon {

		public String 	cpnSellerName 	{get;set;}
		public Date 	cpnStartDate 	{get;set;}
		public Date 	cpnEndDate 		{get;set;}
		public Decimal  cpnDiscount 	{get;set;}
		public String   cpnCode 		{get;set;}
		public Decimal  cpnCoFunding 	{get;set;}
		public String 	cpnRTDevName 	{get;set;}
		public String 	cpnAdPromotion 	{get;set;}
		public Decimal  cpnAdAmount 	{get;set;}
		public Date 	cpnAdSpentDate 	{get;set;}

		public String 	cpnAdditionalAgreement 	{get;set;}
		public List<CouponCoInvest> lstCCI 		{get;set;}
		public String 	couponItemIds	{get;set;}

		public Coupon () { lstCCI = new List<CouponCoInvest>(); }
		
		public Coupon (Coupon_Seller__c cpnSeller) {

			cpnSellerName 	= cpnSeller.Seller__r.Name;
			cpnStartDate 	= cpnSeller.Coupon__r.Coupon_Start_Date__c;
			cpnEndDate 		= cpnSeller.Coupon__r.Coupon_End_Date__c;
			cpnDiscount 	= cpnSeller.Coupon__r.Coupon_Discount__c;
			cpnCode 		= cpnSeller.Coupon__r.Coupon_ID__c;
			cpnCoFunding 	= cpnSeller.Co_funding__c;
			cpnRTDevName 	= cpnSeller.Coupon__r.RecordType.DeveloperName;
			cpnAdPromotion	= cpnSeller.Advertising_Promotion__c;
			cpnAdAmount 	= cpnSeller.Advertising_Amount__c;
			cpnAdSpentDate  = cpnSeller.Ad_Spend_Date__c;
			cpnAdditionalAgreement = cpnSeller.Additional_Terms_Override_of_Agreement__c;

			lstCCI 			= new List<CouponCoInvest>();
			couponItemIds	= '';
		}
	}

	public class CouponCoInvest {
		public String cciCategory 		{get;set;}
		public String cciCategoryId 	{get;set;}
		public Decimal cciSellerFunding {get;set;}
		public CouponCoInvest (Coupon_Co_Invest__c cci) {
			cciCategory 		= cci.Category__c;
			cciCategoryId 		= cci.Category_ID__c;
			cciSellerFunding 	= cci.Seller_Funding__c;
		}
	}
}