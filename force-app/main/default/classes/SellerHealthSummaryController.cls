/*********************************************************************************************************************************
@ Class:          SellerHealthSummaryController
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Controller for page: SellerHealthSummary   
@                 EPH-5212 : Create "Seller Health Summary" export pdf for seller 360 V.1.0 - Functional Export Requirment	
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 03.07.2018 / Vadhanak Voun / Created the class.
@				: 05.03.2019 / Vadhanak Voun / + without sharing for: EPH-7167
@				: 15.03.2019/ Vadhanak Voun / EPH-7167 Seller Scorecard. improve user experience in Clinics data. Rename Fields & Adjust format
				: 18.10.2024 / Vimean Heng / US-0015959 - Error after clicking 'export' in seller account record
*********************************************************************************************************************************/
public without sharing class SellerHealthSummaryController {
 	public Account seller{get;set;}
 	private final static String SOQL_SELLER_HEALTH_PDF  = 'Select Id,(Select CreatedDate, EBH_SiteIDText__c, EBH_RelevancyScore__c, EBH_ActionDescription__c, EBH_SiteID__c From EBH_NBAs__r order by EBH_RelevancyScore__c desc limit 5) From Account Where Id=:sellerId';
 	public List<String> listGroup {get {return new List<String>{
					 		'Conversion funnel',
					 		'Impression-related metrics',
					 		'Conversion-related metrics',
					 		'Offer-related metrics',
					 		'International metrics',
					 		'Mobile Metrics'};
				 		} set;}
 	public Map<String,String> mapGroupToLabel {get {return new Map<String,String>{
					 		'Conversion funnel'=>'Sales funnel metrics',
					 		'Impression-related metrics'=>'Impressions and CTR-related metrics',
					 		'Conversion-related metrics'=>'Conversion-related metrics',
					 		'Offer-related metrics'=>'Offer and seller standard-related metrics',
					 		'International metrics'=>'International metrics',
					 		'Mobile Metrics'=>'Mobile Metrics'};
				 		} set;}	
 	public SellerHealthSummaryController(ApexPages.StandardController stdController)
 	{
 		seller = (Account)stdController.getRecord();
 		init();
 	}   
 	
 	private void init()
 	{
 		if(seller <> null && seller.Id <> null)
 		{
 			String sellerId = seller.Id;
			Map<String, Object> mapSeller = new Map<String, Object>{'sellerId'=> sellerId};
            List<Sobject> result = ApexSafe.query().doQuery(SOQL_SELLER_HEALTH_PDF,mapSeller);
			seller = result.isEmpty() ? null : (Account)result[0];
 			//seller = Database.query(EBH_ConstantsUtility.SOQL_SELLER_HEALTH_PDF);
 			
 		}
 	}
}