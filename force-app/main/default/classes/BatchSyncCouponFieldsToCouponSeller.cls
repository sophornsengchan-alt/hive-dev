/*********************************************************************************************************************************
@ Class     :       BatchSyncCouponFieldsToCouponSeller
@ Version   :       1.0
@ Author    : 	    Mony Nou (mony.nou@gaea-sys.com)
@ Purpose	:	    US-0010785 - Refactor Coupon Seller object to support standard search (AC3)
@					 - In case the sync logic inside CouponTriggerHandler.syncCouponInfo2CouponSellers() fail due to SF Govern limit
                    When there are heap records of coupon seller => we using this batch + schedule daily to update those failed records
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 27.06.2022 / Mony Nou/ Create Method
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.11.2022 / Mony Nou / US-0012866 - [SEP] : global search is not working with Coupon Code or coupon marketing code for Linked Account
@               : 14.03.2023 / vadhanak voun / US-0013330 - Marketing coupon name not populated on coupon seller records
@               : 05.06.2023 / Loumang SENG / US-0013029 - Streamline of coupon seller statuses & retiring coupon fields
@				: 01.09.2023 / Mony Nou / US-0013979 - Long Term Coupons Visible on Portal (Seller Facing): AC4
@               : 27.01.2025 / Mony Nou / US-0015576 - (Tech debt) Coupon update- Exceeding CPU time Limit exception & Too many DML rows: 10001
*********************************************************************************************************************************/
global with sharing class BatchSyncCouponFieldsToCouponSeller implements Database.Batchable<SObject>, Schedulable {
    
    private final static String COUPON_OBJNAME = 'Coupon__c';
	private final static String COUPON_CATEGORYBASE = 'Category_Based'; 
    private final static String COUPON_ITEMBASE = 'Item_Based'; 
    private final static String COUPON_SCMC_CATEGORYBASE = 'Single_Contract_Multi_Coupon_SCMC_Category_Based'; //MN-01092023-US-0013979
    private static final String COUPONTYPE_ITEMBASED = 'Item Based'; //MN-27012025-US-0015576
    
    private static RecordType cpnRTypeItemBase = ApexUtil.getRecordTypeByName(COUPON_OBJNAME,COUPON_ITEMBASE);
    private static RecordType cpnRTypeCateBase = ApexUtil.getRecordTypeByName(COUPON_OBJNAME,COUPON_CATEGORYBASE);
    private static RecordType cpnRTypeSCMC 	= ApexUtil.getRecordTypeByName(COUPON_OBJNAME,COUPON_SCMC_CATEGORYBASE); //MN-01092023-US-0013979

    global Database.QueryLocator start(Database.BatchableContext BC){

        
        Set<Id> sValidRT = new Set<Id> {cpnRTypeCateBase.Id, cpnRTypeItemBase.Id, cpnRTypeSCMC.Id}; 
        
        Set<String> sValidStage = new Set<String> {'Targeted','Reached','Contract Negotiation','Approved','Review','Contract Send','Contract Signed'};//LA-05-06-2023-US-0013029: Retire picklist value 'Commited'
    
        //MN-27012025-US-0015576--START

        Id cpnRTypeItemBaseId = cpnRTypeItemBase.Id;

        String query = 'SELECT Id, Coupon_Marketing_Name__c,Coupon_Code__c, Coupon__r.Marketing_Coupon_Name__c, Coupon__r.Coupon_ID__c, Coupon_Type__c, Coupon__r.Main_Coupon_Site__c, Coupon__r.RecordTypeId, Coupon__r.Stage__c, Coupon__c  FROM Coupon_Seller__c WHERE ';
        
        //1st condition: Sync Coupon Marketing Name and Coupon Code from Coupon to Coupon Seller 
        query += '(Coupon__r.RecordTypeId IN:sValidRT AND Coupon_Seller_Stage__c IN:sValidStage AND (Marketing_Coupon_Name_Diff__c=true OR Coupon_Code_Diff__c=true))';
        
        //2nd Condition: From flow "Coupon_Update_Record_Type_After_Create_Update", where we need to update Coupon Type when Coupon's record type is change to Item Based
        query += ' OR (Coupon__r.RecordTypeId=:cpnRTypeItemBaseId AND Coupon_Type__c <>:COUPONTYPE_ITEMBASED)';

        //MN-27012025-US-0015576--END

        return Database.getQueryLocator(query);

    }

    global void execute(Database.BatchableContext bc, List<Coupon_Seller__c> scope) {

        List<Coupon_Seller__c> lstCS2Update = new List<Coupon_Seller__c>();
        
        for (Coupon_Seller__c cs : scope) {

            Coupon__c cp = (Coupon__c) cs.getSobject('Coupon__r');

            //MN-27012025-US-0015576--START
            Boolean isUpdate = false;
            Coupon_Seller__c tmp = new Coupon_Seller__c(Id = cs.Id);

            //1st condition: Sync Coupon Marketing Name and Coupon Code from Coupon to Coupon Seller
            if (cs.Coupon_Marketing_Name__c != cp.Marketing_Coupon_Name__c || cs.Coupon_Code__c != cp.Coupon_ID__c) {
                
                if (cs.Coupon_Marketing_Name__c != cp.Marketing_Coupon_Name__c) { tmp.Coupon_Marketing_Name__c = cp.Marketing_Coupon_Name__c; }
                if (cs.Coupon_Code__c != cp.Coupon_ID__c) { tmp.Coupon_Code__c = cp.Coupon_ID__c; }
                
                isUpdate = true;
            } 
            
            //2nd condition: Update Coupon Type when Coupon's record type is change to Item Based
            if (cp.RecordTypeId == cpnRTypeItemBase.Id && cs.Coupon_Type__c != COUPONTYPE_ITEMBASED) {
                tmp.Coupon_Type__c = COUPONTYPE_ITEMBASED;
                isUpdate = true;
            }

            if (isUpdate) {
                lstCS2Update.add(tmp);
            }

            //MN-27012025-US-0015576--END
        }
        
        //MN-27012025-US-0015576--START
        try {

            Database.SaveResult[] results = ApexSafe.dml().doUpdate(lstCS2Update, false);

            List<Database.Error> listException = new List<Database.Error>();
            for (Database.SaveResult res : results) {
                if (!res.isSuccess()) {
                    listException.addAll(res.getErrors());
                }
            }

            if (!listException.isEmpty()) { EBH_ApexLogger.logError(listException, 'BatchSyncCouponFieldsToCouponSeller','execute (batch)'); }

        } catch(Exception ex) {
            EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchSyncCouponFieldsToCouponSeller','execute (batch)');
        }

        //MN-27012025-US-0015576--END

        
    }

    global void finish(Database.BatchableContext bc) {}

    global void execute(SchedulableContext sc) 
    {
        BatchSyncCouponFieldsToCouponSeller bat = new BatchSyncCouponFieldsToCouponSeller();
        Database.executeBatch(bat,200);
    }
}