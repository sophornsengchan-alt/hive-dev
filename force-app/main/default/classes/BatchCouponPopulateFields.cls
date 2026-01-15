/*********************************************************************************************************************************
@ Class         : BatchCouponPopulateFields
@ Version       : 1.0
@ Author        : Loumang SENG (srong.tin@gaea-sys.com)
@ Purpose       : US-0010777 - External Sharing for Coupon Seller Object
@ Change history: 07.02.2022 / Loumang SENG / Created the class
@               : run once at post deployment populate existing data(from deleted-rollup fields into number fields)
*********************************************************************************************************************************/
global with sharing class BatchCouponPopulateFields implements Database.Batchable<sObject> {
    private final static String SOQL_COUPON_SELLER = 'SELECT Id,Sellers_Targeted2__c,Sellers_Contract_Send2__c,Sellers_Contract_Signed2__c FROM Coupon__c';
    Set<Id> cId = new Set<Id>();
    public BatchCouponPopulateFields(){}
    public BatchCouponPopulateFields(Set<Id> cId) {
        this.cId = cId;
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        String finalQuery = SOQL_COUPON_SELLER;
        if(!cId.isEmpty()) finalQuery += ' WHERE Id IN: cId';
        return Database.getQueryLocator(finalQuery);

    }
    global void execute(Database.BatchableContext pBc, List<Coupon__c> scope) {

        
        Map<Id, Coupon__c> mapCoupon = new Map<Id, Coupon__c>();
        for(Coupon__c coupon : scope){
            coupon.Sellers_Targeted2__c = 0;
            coupon.Sellers_Contract_Send2__c = 0;
            coupon.Sellers_Contract_Signed2__c = 0;
            mapCoupon.put(coupon.Id,coupon);
        }

        List<AggregateResult> listCountCoupon = [SELECT coupon__c cId , count(Id) csCountSeller FROM Coupon_Seller__c WHERE coupon__c =: mapCoupon.keySet() Group by coupon__c];
        CouponSellerTriggerHandler.populateCouponCounts(listCountCoupon,mapCoupon,CouponSellerTriggerHandler.COUNT_COUPON_SELLER);

        List<AggregateResult> listCountSellerStage = [SELECT coupon__c cId, count(Coupon_Seller_Stage__c) csCountStage FROM Coupon_Seller__c WHERE coupon__c =: mapCoupon.keySet() AND Coupon_Seller_Stage__c IN:CouponSellerTriggerHandler.SET_COUPONSELLER_STAGE Group by coupon__c];
        CouponSellerTriggerHandler.populateCouponCounts(listCountSellerStage,mapCoupon,CouponSellerTriggerHandler.COUNT_COUPON_SELLER_STAGE);

        List<AggregateResult> listCountSellerAcceptDate = [SELECT coupon__c cId, count(Contract_Accept_Date__c) csCountDate FROM Coupon_Seller__c WHERE coupon__c =: mapCoupon.keySet() AND Contract_Accept_Date__c <> null Group by coupon__c];
        CouponSellerTriggerHandler.populateCouponCounts(listCountSellerAcceptDate,mapCoupon,CouponSellerTriggerHandler.COUNT_COUPON_SELLER_ACCEPT_DATE);
        Database.update(mapCoupon.values(), false);
 
    }

    global void finish(Database.BatchableContext pBc) {}
}