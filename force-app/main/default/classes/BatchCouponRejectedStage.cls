/*********************************************************************************************************************************
@ Class         : BatchCouponRejectedStage
@ Version       : 1.0
@ Author        : Loumang SENG (loumang.seng@gaea-sys.com)
@ Purpose       : US-0014834 - Void Coupon Sellers for Rejected Coupons
@                   - All coupon sellers that have a coupon with stage "Coupon rejected" are automatically updated Stage to "Seller Declined" with Seller Declined Reasons = "Contract Voided".
@                   - Seller communications are Automatically created When related coupon sellers contain stage "Contract Send" or "Contract Signed"
@                   - Batch schedule twice per day
@ Change history: 01.04.2024 / Loumang SENG / Created the class
*********************************************************************************************************************************/
global with sharing class BatchCouponRejectedStage implements Database.Batchable<SObject>, Schedulable{
    
    private final String STAGE_COUPON_CANCEL = 'Coupon rejected';
    private final String STAGE_DECLINED = 'Seller Declined';
    private final String DECLINED_REASON_VOID = 'Contract Voided';
    private final Set<String> SET_STAGE_TO_INCLUDE = new Set<String>{'Contract Send','Contract Signed'};
    private final String RECORDTYPE_DWH = 'EBH_DWH';
    private final String SP_FULL_ACCESS = 'Full Access';
    private final String SP_ALLOWED = 'Allowed'; //MN-10042024
    private final String SELLER_PORTAL = 'Seller Portal';
    private final String SELLER_COM_TEMPLATE = 'Cancelled Coupon Notification';
    private final RecordType COUPON_RECORDTYPE = ApexUtil.getRecordTypeByName('Seller_Communication__c','Coupons');
    private String sQuery = 'SELECT Id,Coupon__r.Main_Coupon_Site__c,Coupon_Seller_Stage__c,Seller_Declined_Reasons__c,Coupon__r.Stage__c,Seller__c,Seller__r.Seller_Portal_Group__c FROM Coupon_Seller__c';
    private String sWhere = ' WHERE Coupon_Seller_Stage__c !=:STAGE_DECLINED AND Coupon__r.Stage__c =: STAGE_COUPON_CANCEL';
    private String contactSoql = 'SELECT Id, AccountId,RecordType.DeveloperName,Active_Community_User__c,Account.SP_Coupons__c, Account.Seller_Portal_Group__c FROM Contact'; //MN-10042024
    private String sWhereCont = ' WHERE ((email != null AND RecordType.DeveloperName =:RECORDTYPE_DWH AND AccountId IN: accIds) OR (Active_Community_User__c = true AND (AccountId IN: accIds OR AccountId IN: groupIds))) AND (Account.SP_Coupons__c =:SP_FULL_ACCESS OR Account.SP_Coupons__c =:SP_ALLOWED) AND AccountId != null'; //MN-10042024:Added Allowed for Linked Account
    //private String sWhereCont = ' WHERE ((email != null AND (RecordType.DeveloperName =:RECORDTYPE_DWH OR RecordType.DeveloperName =:SELLER_PORTAL) AND AccountId IN: accIds) OR (Active_Community_User__c = true AND (AccountId IN: accIds OR AccountId IN: groupIds))) AND Account.SP_Coupons__c =:SP_FULL_ACCESS AND AccountId != null';
	private Set<String> couponIds;
    private final Set<String> SET_COUPON_MAINSITE = new Set<String> {'ebay.de','ebay.co.uk','ebay.it','ebay.com.au','ebay.com'};
    
    public BatchCouponRejectedStage(){}
    
    //testing purpose
	public BatchCouponRejectedStage(Set<String> couponIds)
    {
    	this.couponIds = couponIds;
    	this.sWhere += ' AND Coupon__c=:couponIds';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(sQuery+sWhere);
    }
    
    global void execute(Database.BatchableContext pBc, List<SObject> scope){

        List<Coupon_Seller__c> listCsToUpdate = new List<Coupon_Seller__c>();
        List<Coupon_Seller__c> listCsToSendEmail = new List<Coupon_Seller__c>();
        //Map<Id,Seller_Communication__c> mapSellerCom = new Map<Id,Seller_Communication__c>(); //MN-10042024
        Map<Id,List<Seller_Communication__c>> mapSellerCom = new Map<Id,List<Seller_Communication__c>>(); //MN-10042024
        for(Coupon_Seller__c cs: (List<Coupon_Seller__c>) scope)
        {

            if(SET_COUPON_MAINSITE.contains(cs.Coupon__r.Main_Coupon_Site__c) && SET_STAGE_TO_INCLUDE.contains(cs.Coupon_Seller_Stage__c) && (cs.Seller__c != null || cs.Seller__r.Seller_Portal_Group__c != null)){
                listCsToSendEmail.add(cs);// list coupon sellers that contain stage Contract send or Contract Signed to send email
            }
			cs.Coupon_Seller_Stage__c = STAGE_DECLINED;
            cs.Seller_Declined_Reasons__c= DECLINED_REASON_VOID;
            listCsToUpdate.add(cs);
        }
        if(!listCsToSendEmail.isEmpty()){

            //Map<Id, Coupon_Seller__c> mapSellerToCS = new Map<Id, Coupon_Seller__c>(); //MN-10042024
            //Map<Id, Coupon_Seller__c> mapSellerGroupToCS = new Map<Id, Coupon_Seller__c>(); //MN-10042024
            Map<Id, List<Coupon_Seller__c>> mapSeller2CS = new Map<Id, List<Coupon_Seller__c>>(); //MN-10042024
            Set<Id> accIds = new Set<Id>(); //MN-10042024
            for(Coupon_Seller__c cs : listCsToSendEmail){

                //if(cs.Seller__c != null) mapSellerToCS.put(cs.Seller__c, cs); //MN-10042024
                //if(cs.Seller__r.Seller_Portal_Group__c != null) mapSellerGroupToCS.put(cs.Seller__r.Seller_Portal_Group__c, cs); //MN-10042024

                Id key = (cs.Seller__r.Seller_Portal_Group__c != null)? cs.Seller__r.Seller_Portal_Group__c : cs.Seller__c;
                if (!mapSeller2CS.containsKey(key)) mapSeller2CS.put(key, new List<Coupon_Seller__c>());
                mapSeller2CS.get(key).add(cs);

                accIds.add(cs.Seller__c); //MN-10042024

            }
            //if (!mapSellerToCS.isEmpty() || !mapSellerGroupToCS.isEmpty()){ //MN-10042024
            if (!mapSeller2CS.isEmpty()) {

                //Set<Id> accIds = mapSellerToCS.keySet(); //MN-10042024
                //Set<Id> groupIds = mapSellerGroupToCS.keySet(); //MN-10042024

                Set<Id> groupIds = mapSeller2CS.keySet(); //MN-10042024

                List<Contact> listCont = ApexSafe.query().secCheck(false).doQuery(contactSoql+sWhereCont, new Map<String, Object> {'RECORDTYPE_DWH' => RECORDTYPE_DWH,'accIds' => accIds,'groupIds' => groupIds,'SP_FULL_ACCESS' => SP_FULL_ACCESS, 'SP_ALLOWED' => SP_ALLOWED});
                //List<Contact> listCont = ApexSafe.query().secCheck(false).doQuery(contactSoql+sWhereCont, new Map<String, Object> {'RECORDTYPE_DWH' => RECORDTYPE_DWH,'SELLER_PORTAL' => SELLER_PORTAL,'accIds' => accIds,'groupIds' => groupIds,'SP_FULL_ACCESS' => SP_FULL_ACCESS});
                for(Contact cont : listCont){


                    //MN-10042024--START
                    if (mapSeller2CS.containsKey(cont.AccountId) || (cont.Account.Seller_Portal_Group__c != null && mapSeller2CS.containsKey(cont.Account.Seller_Portal_Group__c))) {

                        Id key = (cont.Account.Seller_Portal_Group__c != null)? cont.Account.Seller_Portal_Group__c : cont.AccountId; 

                        for (Coupon_Seller__c cs : mapSeller2CS.get(key)) {

                            Seller_Communication__c sellerCom = new Seller_Communication__c();
                            sellerCom.RecordTypeId = COUPON_RECORDTYPE.Id;
                            sellerCom.Account__c = cont.AccountId;
                            sellerCom.Contact__c = cont.Id;
                            sellerCom.Coupon_Seller__c = cs.Id;
                            sellerCom.Email_Template__c = SELLER_COM_TEMPLATE;
                            sellerCom.Name = SELLER_COM_TEMPLATE;
                            sellerCom.Platform__c = SELLER_PORTAL;
                            
                            if (!mapSellerCom.containsKey(cs.Id)) mapSellerCom.put(cs.Id, new List<Seller_Communication__c>());
                            mapSellerCom.get(cs.Id).add(sellerCom);
                            
                        }
                    }

                    //MN-10042024--STOP

                    /* MN-10042024-COMMENT CODE
                    Coupon_Seller__c cs = cont.RecordType.DeveloperName == RECORDTYPE_DWH ? mapSellerToCS.get(cont.AccountId): mapSellerGroupToCS.get(cont.AccountId);
                    // Coupon_Seller__c cs = new  Coupon_Seller__c();
                    // if(cont.RecordType.DeveloperName == RECORDTYPE_DWH){
                    //     cs = mapSellerToCS.get(cont.AccountId);
                    // }else{
                        
                    //     if(mapSellerToCS.get(cont.AccountId) != null){
                    //         cs = mapSellerToCS.get(cont.AccountId);
                    //     }else{
                    //         cs = mapSellerGroupToCS.get(cont.AccountId);
                    //     }
                    //}
                    
                    if(cs == null) continue;
                    
                    Seller_Communication__c sellerCom = new Seller_Communication__c();
                    sellerCom.RecordTypeId = COUPON_RECORDTYPE.Id;
                    sellerCom.Account__c = cont.AccountId;
                    sellerCom.Contact__c = cont.Id;
                    sellerCom.Coupon_Seller__c = cs.Id;
                    sellerCom.Email_Template__c = SELLER_COM_TEMPLATE;
                    sellerCom.Name = SELLER_COM_TEMPLATE;
                    sellerCom.Platform__c = SELLER_PORTAL;
                    mapSellerCom.put(cs.Id, sellerCom);
                    */
                }

            }

        }
        
        if(!listCsToUpdate.isEmpty()){ // Update Coupon Sellers

            Database.SaveResult[] results = ApexSafe.dml().secCheck(false).doUpdate(listCsToUpdate, false);
            List<Database.Error> dbError = new List<Database.Error>();
            for (Database.SaveResult result : results) {
                if (!result.isSuccess() && !Test.isRunningTest()){
                    // Remove coupon seller that updated false
                    if(mapSellerCom.containsKey(result.getId())){ mapSellerCom.remove(result.getId()); }   
                    dbError.addAll(result.getErrors()); 
                }
            }
            if (!dbError.isEmpty()) EBH_ApexLogger.logError(dbError, 'BatchCouponRejectedStage','execute (batch)');
   
        }

        if(!mapSellerCom.isEmpty()){ // Create Seller Com

            //MN-10042024--START
            List<Seller_Communication__c> lst2Create = new List<Seller_Communication__c>();
            for (List<Seller_Communication__c> lstSellerCom : mapSellerCom.values()) {
                lst2Create.addAll(lstSellerCom);
            }
            //MN-10042024--END
            
            //Database.SaveResult[] results = ApexSafe.dml().secCheck(false).doInsert(mapSellerCom.values(), false); //MN-10042024
            Database.SaveResult[] results = ApexSafe.dml().secCheck(false).doInsert(lst2Create, false); //MN-10042024

            List<Database.Error> dbError = new List<Database.Error>();
            for (Database.SaveResult result : results) {
                if (!result.isSuccess() && !Test.isRunningTest()){ dbError.addAll(result.getErrors()); }
            }
            if (!dbError.isEmpty()) EBH_ApexLogger.logError(dbError, 'BatchCouponRejectedStage','execute (batch)');

        }
        
        
    }
    
    global void finish(Database.BatchableContext pBc){}

    global void execute(SchedulableContext sc) { 
        BatchCouponRejectedStage b = new BatchCouponRejectedStage();
        Database.executeBatch(b);
    }

}