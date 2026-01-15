/*********************************************************************************************************************************
@ Class:         BatchUpdateCouponStage
@ Version:       1.0
@ Author:        Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:       US-0014688 - Coupon Date timezone Issue	 
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16.2.2024 / Sambath Seng / Created the class.
@               : 24.04.2024 / Sambath Seng / US-0014947 - Reduce the scope of the batch job for the Coupon Stage update
*********************************************************************************************************************************/
global with sharing class BatchUpdateCouponStage implements Database.Batchable<SObject>, Schedulable{	
    
    private String STAGE_SELLER_NEGOTIATION = 'Seller Negotiation';
    private String STAGE_COUPON_RUNNING = 'Coupon Running';
    private String STAGE_COUPON_EXECUTED = 'Coupon Executed';
	private String soqlCoupon = 'SELECT Coupon_Start_Date__c,Coupon_Start_Time__c,Coupon_End_Date__c,Coupon_end_Time__c,Stage__c,Days_since_coupon_End_Date__c,Main_Coupon_Site__c From Coupon__c';
    // 24.04.2024 / Sambath Seng / US-0014947 add the condition to reduce the scope of the batch job
    private String sWhere = ' WHERE ((Coupon_Start_Date__c != NULL AND Coupon_Start_Time__c != NULL AND Stage__c != :STAGE_COUPON_RUNNING) OR (Coupon_End_Date__c != NULL AND Coupon_end_Time__c != NULL AND Stage__c != :STAGE_COUPON_EXECUTED)) AND Main_Coupon_Site__c != NULL AND Coupon_End_Date__c >= LAST_N_DAYS:365';
    private String couponId;
    private Map<String,String> mapSiteTimezone = new Map<String,String>{
        'ebay.de' => 'Europe/Berlin',
        'ebay.co.uk' => 'Europe/London',
        'ebay.es' => 'Europe/Madrid',
        'ebay.fr' => 'Europe/Paris',
        'ebay.it' => 'Europe/Rome',
        'ebay.ch' => 'Europe/Zurich',
        'ebay.at' => 'Europe/Vienna',
        'ebay.pl' => 'Europe/Warsaw',
        'ebay.nl' => 'Europe/Amsterdam',
        'ebay.com' => 'America/Los_Angeles',
        'ebay.com.au' => 'Australia/Sydney',
        'ebay.ca' => 'America/Toronto'
    };

    private Datetime convertSystemDateTimeByTimeZone(String siteName){
        // Get the timezone dynamically
        TimeZone tz = TimeZone.getTimeZone(mapSiteTimezone.get(siteName));
        // Datetime.now() returns the current system time in GMT
        Datetime dt = Datetime.now();

        return dt.addSeconds(tz.getOffset(dt) / 1000);
    }

    public BatchUpdateCouponStage()
    {
    }
    
	public BatchUpdateCouponStage(String couponId)
    {
    	this.couponId = couponId;
    	this.sWhere = ' WHERE Id = :couponId';
    }
	
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(soqlCoupon+sWhere);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {

        List<Coupon__c> lstCouponToUpdate = new List<Coupon__c>();

        for (Coupon__c oCoupon : (List<Coupon__c>)scope) {

            DateTime cpStartDateTime = Datetime.newInstanceGMT(oCoupon.Coupon_Start_Date__c,oCoupon.Coupon_Start_Time__c);
            DateTime cpEndDateTime = Datetime.newInstanceGMT(oCoupon.Coupon_End_Date__c,oCoupon.Coupon_End_Time__c);
            Datetime systemDateTime = convertSystemDateTimeByTimeZone(oCoupon.Main_Coupon_Site__c);

            if(cpStartDateTime <= systemDateTime && oCoupon.Stage__c == STAGE_SELLER_NEGOTIATION){
                oCoupon.Stage__c = STAGE_COUPON_RUNNING;
            } else if(cpEndDateTime <= systemDateTime && oCoupon.Stage__c == STAGE_COUPON_RUNNING && oCoupon.Days_since_coupon_End_Date__c >= 0){
                oCoupon.Stage__c = STAGE_COUPON_EXECUTED;
            }
            
            oCoupon.TriggerStageUpdatedDate__c = Datetime.now();
            lstCouponToUpdate.add(oCoupon);

        }
        
        if (!lstCouponToUpdate.isEmpty()) {
            
            Database.SaveResult[] results = ApexSafe.dml().secCheck(false).doUpdate(lstCouponToUpdate, true);
            List<Database.Error> dbError = new List<Database.Error>();

            for (Database.SaveResult result : results) {
                if (!result.isSuccess() && !Test.isRunningTest()){ dbError.addAll(result.getErrors()); }
            }

            if (!dbError.isEmpty()) EBH_ApexLogger.logError(dbError, 'BatchUpdateCouponStage','execute (batch)');
            
        }
        

    }

    global void finish(Database.BatchableContext pBc){

    }

    global void execute(SchedulableContext sc) { 
        BatchUpdateCouponStage b = new BatchUpdateCouponStage();
        Database.executeBatch(b);
    }

}