/*********************************************************************************************************************************
@ Class:         Batch_CouponSellerPackPromotions
@ Version:       1.0
@ Author:        SRONG TIN (srong.tin@gaea-sys.com)
@ Purpose:       US-0013713 - Migrate coupon seller pack to seller communication record	 
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.12.2023 / SRONG TIN / Created the class.
*********************************************************************************************************************************/
global with sharing class Batch_CouponSellerPackPromotions implements Database.Batchable<SObject>, Schedulable{	
    
	private String soqlCS = 'Select Id,Coupon_Seller_Stage__c, Coupon__c,Seller__c,Coupon_Start_Date__c,Coupon_Site__c,Contract_Signed_Declined_By__c,Contract_Signed_Declined_By__r.Email From Coupon_Seller__c';
    private String SITE = 'ebay.com.au';
    private String STAGE = 'Contract Signed';
    private String sWhere = ' Where Coupon_Seller_Stage__c =:STAGE AND Coupon__r.Main_Coupon_Site__c =:SITE AND Coupon_Start_Date__c = NEXT_N_DAYS:3';
    private List<Id> CouponSellerIds= new List<Id>();

	public Batch_CouponSellerPackPromotions(){}
    public Batch_CouponSellerPackPromotions(List<Id> CouponSellerIds)
    {
        this.CouponSellerIds = CouponSellerIds;
        sWhere = ' Where Id in:CouponSellerIds';
    }
	
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(soqlCS+sWhere);
    }

    global void execute(Database.BatchableContext BC, List<Coupon_Seller__c> scope) {

        List<Seller_Communication__c> lstSellerCom = new List<Seller_Communication__c>();
        RecordType sellerComRecordType = ApexUtil.getRecordTypeByName('Seller_Communication__c','Coupons');
        if(!scope.isEmpty()){
            for (Coupon_Seller__c oneCouponSeller : scope){
                if( oneCouponSeller.Contract_Signed_Declined_By__c != null && 
                    oneCouponSeller.Contract_Signed_Declined_By__r.Email != null &&
                    oneCouponSeller.Coupon_Start_Date__c == Date.today().addDays(3)
                ){
                    Seller_Communication__c sellerCom = new Seller_Communication__c();
                    sellerCom.RecordTypeId = sellerComRecordType.Id;
                    sellerCom.Region__c = 'AU';
                    sellerCom.Email_Template__c = 'Coupons Seller Pack Promotions';
                    sellerCom.Name = 'Coupons Seller Pack Promotions';
                    sellerCom.Coupon_Seller__c = oneCouponSeller.Id;
                    sellerCom.Platform__c = 'Seller Portal';
                    sellerCom.Account__c = oneCouponSeller.Seller__c;
                    sellerCom.Contact__c = oneCouponSeller.Contract_Signed_Declined_By__c;
                    lstSellerCom.add(sellerCom);
                }
                
            }
        }
        
        if (!lstSellerCom.isEmpty()) {
            insert lstSellerCom;
        }
    }

    global void finish(Database.BatchableContext pBc){

    }
    global void execute(SchedulableContext sc) { 
        Batch_CouponSellerPackPromotions b = new Batch_CouponSellerPackPromotions();
        Database.executeBatch(b);
    }

}