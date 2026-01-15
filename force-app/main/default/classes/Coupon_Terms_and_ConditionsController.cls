/*********************************************************************************************************************************
@ Class:          Coupon_Terms_and_ConditionsController
@ Version:        1.0
@ Author:         Sovantheany Dim
@ Purpose:        Controller Class for Coupon_Terms_and_Conditions page
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 14.11.2019 / Sovantheany Dim / Created the class.
@				: 31.08.2021/ Mony/ US-0009948 - remove field Email_Adress__c from query string line 14
@				: 28.09.2023 / Loumang SENG / US-0013980 - Remove field Coupon__r.Contract_Language__c from query
*********************************************************************************************************************************/
public without sharing class Coupon_Terms_and_ConditionsController {
	/****************************************************************************************************************************
	* CONSTANTS DEFINITION
	*****************************************************************************************************************************/
	private final static String SOQL_COUPON_SELLER = 'Select Coupon__r.Coupon_Subtitle_Copy__c,RecordType.DeveloperName, Allow_reaccept_contract__c,Advertising_Promotion__c, Day_1_Alert__c, Coupon_Contract_Due_Date__c, Day34AfterCouponEnd_Trigger_DE__c,Day4AfterCouponEnd_Trigger_DE__c,CurrencyIsoCode, Additional_Terms_Override_of_Agreement__c, Ad_Spend_Date__c, Advertising_Amount__c, Contract_Accept_Date__c,Coupon_Seller_Stage__c,Contract_Language__c,GMV_LC__c,Contra_LC__c,Cost_Share_Seller_LC__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Due_Date__c,Free_Subtitles__c,Coupon__r.Max_Redemptions__c,Coupon__r.Owner.Name,EBH_CouponSellerOwner__r.Name,EBH_CouponSellerOwner__c,EBH_CouponSellerOwner__r.Email,Coupon__r.Coupon_Cap__c,Coupon_ID__c ,Coupon__r.Marketing_Coupon_Name__c,Coupon__r.OwnerId,Coupon__r.Owner.Email,Coupon__r.RecordType.DeveloperName,Coupon__r.CurrencyIsoCode,Additional_Terms__c,Coupon__r.Minimum_Transaction_Value__c,Coupon__r.Name,Legal_Entity_Name_w__c,Legal_Entity_Street_w__c,Legal_Entity_Zip_w__c,Seller__r.Parent.EBH_BillingCountry__c,Seller__r.Parent.EBH_BillingCity__c,Seller__r.EBH_VATNumber__c,Seller__r.Name,Coupon__r.Couponsite_s__c,PayPal_adress_N__c,Coupon__r.Coupon_Start_Time__c,Coupon__r.Coupon_Start_Date__c,Coupon__r.Coupon_end_Time__c,Coupon__r.Coupon_End_Date__c,Coupon__r.Coupon_Discount__c,Coupon__r.Coupon_Discount_Amount__c,Coupon__r.T_Cs_URL__c,Id,Name,Seller__c,Coupon__c,Oracle_ID__c,PayPal_adress__c From Coupon_Seller__c ' ;
	/************************************END CONSTANTS DEFINITION*************************************************************/
	public String legalEntityName {get;set;}
	public String abn {get;set;}
	public String legalEntityStreet {get;set;}
	public String legalEntityCity {get;set;}
	public String legalEntityZip {get;set;}
	public String legalEntityCountry {get;set;}
	
	/*****************************************************************************************************************************
    @ Method:         handleCouponTermsAndCondition
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        US-0018713 : [AU] Coupon Click Contract Templates to be sent to AU Sellers
    @              	  	AC4 : Create a New VF Page to show the "Coupon Terms and Conditions" Link within the Contract
    @              		Attached "Promotions T&Cs for AU (HIVE) - v7 - draft" is the content that needs to be shown 
    @           		when the link "Coupon Terms and Condition" is clicked within the Contract sent
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        void
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  14.11.2019 / Sovantheany Dim /Created the Method. 
    *****************************************************************************************************************************/
 	public void handleCouponTermsAndCondition(){
 		try
 		{
 		String couponSellerId = ApexPages.currentPage().getParameters().get('csid');
 		couponSellerId = couponSellerId==null?null:String.escapeSingleQuotes(couponSellerId);
	 		if(couponSellerId <> null)
	 		{
	 			String sWhere = ' Where Id =:couponSellerId';
	 			List<Coupon_Seller__c> listCS = Database.query(SOQL_COUPON_SELLER+sWhere);
	 			if(!listCS.isEmpty())
	 			{
	 				Coupon_Seller__c couponSeller = listCS[0];
	 				legalEntityName = couponSeller.Legal_Entity_Name_w__c;
	 				abn = couponSeller.Seller__r.EBH_VATNumber__c;
	 				legalEntityStreet = couponSeller.Legal_Entity_Street_w__c;
	 				legalEntityCity = couponSeller.Seller__r.Parent.EBH_BillingCity__c;
	 				legalEntityZip = couponSeller.Legal_Entity_Zip_w__c;
	 				legalEntityCountry = couponSeller.Seller__r.Parent.EBH_BillingCountry__c;
	 			}
	 		}
 		}catch(Exception ex) 
        {
        	EBH_ApexLogger.logError(new List<Exception> { ex }, 'Coupon_Terms_and_ConditionsController','handleCouponTermsAndCondition');
        }
 	}
 	
}