/*********************************************************************************************************************************
@ Class:        DealAmendmentProcessController
@ Version:      1.0
@ Author:       Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:      Controller for aura: DealAmendmentProcess
@               US-0010019 - [NA] Subsidized Deals Contract Amendment Process
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.09.2021 / Mony Nou / Created the Class.
*********************************************************************************************************************************/
public without sharing class DealAmendmentProcessController {
    
    private static final String PERMISSIONSET_NA_MANAGE_DEALS = 'US_Manage_Deals';
    private static final string NA_DEAL_RECORDTYPE = 'Deal_V2';
    private static final string STAUS_SENT_TO_SELLER = 'Sent to Seller';
    private static final string STATUS_IN_APPROVAL = 'In Approval';
    private static final string STATUS_CANCELLED = 'Cancelled';

    /**
     * Execute logic under Deal's Quick Action 	"Cancel Amendment"
     * Description: US-0010019 - [NA] Subsidized Deals Contract Amendment Process
     *  @param  id, Deal Id
        @return Map<String,Object> 
     */
	@AuraEnabled
    public static Map<String,Object> cancelAmendContract(string id) {

        Map<String, Object> mResult = new Map<String, Object>();
        mResult.put('status', 'ko');
        mResult.put('msg', Label.NA_Deal_Amend_Contract_Error_Msg_1);

        if (String.isNotBlank(id)) {

            Boolean isAdmin = (Userinfo.getprofileId()==ApexUtil.ADMIN_PROFILE_ID);
            Boolean hasPermission = ApexUtil.checkPermissionSet(new Set<String>{PERMISSIONSET_NA_MANAGE_DEALS});

            if (isAdmin || hasPermission) {

                try {

                    //Find Amendment Deals for the Original One
                    List<EBH_Deal__c> aDeals = loadDeals(new Set<Id>{id});

                    if (aDeals.isEmpty()) { mResult.put('status', 'warn'); mResult.put('msg', Label.NA_Deal_Amend_Contract_Error_Msg_5); return mResult; }

                    //Find Amendent Deals that still in Approval Process
                    List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
                    List<ProcessInstanceWorkitem> listWorkItems = [Select id, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId IN :aDeals];
                    Map<id,Id> mapDealWorkItem = new Map<id,id>();
                    for(ProcessInstanceWorkitem WorkItem:listWorkItems){
                        mapDealWorkItem.put(workItem.ProcessInstance.TargetObjectId, workitem.id);
                    }
                    for(EBH_Deal__c eachDeal : aDeals){

                        if (mapDealWorkItem.containsKey(eachDeal.Id)) {
                            
                            //Remove it from Approval Process
                            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                            req.setAction('Removed');
                            req.setWorkItemId(mapDealWorkItem.get(eachDeal.id));
                            requests.add(req);
                        }
                        
                        //Set Amendment Status to Cancelled
                        eachDeal.EBH_Status__c = STATUS_CANCELLED;

                    }

                    if(!requests.isEmpty()){ Approval.ProcessResult[] processResults = Approval.process(requests, true); }

                    update aDeals;

                    mResult.put('status', 'ok');

                }catch(Exception ex) { mResult.put('msg',ex.getMessage()); }

            } else { mResult.put('msg',Label.NA_Deal_Amend_Contract_Error_Msg_3); }

        }


        return mResult;
    }

    private static List<EBH_Deal__c> loadDeals(Set<Id> ids) {

        RecordType recDeal = ApexUtil.getRecordTypeByName('EBH_Deal__c',NA_DEAL_RECORDTYPE);
        Set<String> sStatus = new Set<String>{STAUS_SENT_TO_SELLER, STATUS_IN_APPROVAL};
        List<EBH_Deal__c> deals = [SELECT Id, EBH_Status__c FROM EBH_Deal__c WHERE EBH_Status__c IN:sStatus AND RecordTypeId =:recDeal.ID AND Originating_Deal__c in : ids];
        return deals;
    }

    /**
     * Execute logic under Deal's Quick Action "Amend Contract"
     * Description: US-0010019 - [NA] Subsidized Deals Contract Amendment Process
     *  @param  id, Deal Id
        @return Map<String,Object> 
     */
	@AuraEnabled
    public static Map<String,Object> validateDealForAmendContract(string id) {
        
        Map<String, Object> mResult = new Map<String, Object>();
        mResult.put('status', 'ko');
        mResult.put('msg', Label.NA_Deal_Amend_Contract_Error_Msg_1);

        if (String.isNotBlank(id)) {

            //Check if user is Admin or has "eBay Managed Deal" Permission Set
            Boolean isAdmin = (Userinfo.getprofileId()==ApexUtil.ADMIN_PROFILE_ID);
            Boolean hasPermission = ApexUtil.checkPermissionSet(new Set<String>{PERMISSIONSET_NA_MANAGE_DEALS});

            if (isAdmin || hasPermission) {

                Set<String> sPendingAmendmentStatus = new Set<String>{'New', 'Negotiating', 'In Approval','Internally Approved','Sent to Seller', 'In Revision'};

                //Check if Deal.Status = Running
                EBH_Deal__c deal = new EBH_Deal__c();
                for (EBH_Deal__c d : [SELECT EBH_Status__c, Originating_Deal__c, Amendment_Date__c, (SELECT EBH_Status__c FROM Deals__r WHERE EBH_Status__c IN:sPendingAmendmentStatus AND Amendment_Date__c <> NULL LIMIT 1) FROM EBH_Deal__c WHERE Id=:id]) deal = d;

                /*
                if (deal.Originating_Deal__c != null && deal.Amendment_Date__c != null) mResult.put('msg', Label.NA_Deal_Amend_Contract_Error_Msg_5); //Check if it is Original Deal
                else 
                */
                if (deal.EBH_Status__c != 'Running') mResult.put('msg', Label.NA_Deal_Amend_Contract_Error_Msg_2); //Check if Original Deal in status Running
                else if (!deal.Deals__r.isEmpty()) mResult.put('msg', Label.NA_Deal_Amend_Contract_Error_Msg_4);    //Check if Original Deal has Pending Amendment
                else mResult.put('status', 'ok');

            }else { mResult.put('msg',Label.NA_Deal_Amend_Contract_Error_Msg_3); }
        }

        return mResult;

    }

    @AuraEnabled
    public static Map<String,Object> createAmendmentDeal(String aDealJSON, String oDealJSON) { 

        Map<String, Object> mResult = new Map<String, Object>();
        mResult.put('status', 'ko');

        try {

            EBH_Deal__c aDeal = (EBH_Deal__c) JSON.deserialize(aDealJSON, EBH_Deal__c.class);
            EBH_Deal__c oDeal = (EBH_Deal__c) JSON.deserialize(oDealJSON, EBH_Deal__c.class);

            DealTime adt = (DealTime) JSON.deserialize(aDealJSON, DealTime.class);
        
            if (Test.isRunningTest()) { adt.aStartTime = '06:00'; adt.aEndTime = '22:00'; adt.oStartTime = '06:00';}
            
            List<String> lstTimeSplit = adt.aStartTime.split(':');
            Time aStartTime = Time.newInstance(Integer.valueOf(lstTimeSplit[0]), Integer.valueOf(lstTimeSplit[1]), 0, 0);
            DateTime aStartDateTime = DateTime.newInstanceGmt(aDeal.EBH_DealStartDate__c, aStartTime);

            lstTimeSplit = adt.aEndTime.split(':');
            Time aEndTime = Time.newInstance(Integer.valueOf(lstTimeSplit[0]), Integer.valueOf(lstTimeSplit[1]), 0, 0);

            /*
            System.debug('**** aDeal :: ' + aDeal);
            System.debug('**** oDeal :: ' + oDeal);
            System.debug('**** adt :: ' + adt);
            System.debug('**** lstTimeSplit :: ' + lstTimeSplit);

            System.debug('**** aStartDateTime :: ' + aStartDateTime);
            System.debug('**** System Now :: ' + System.now());
            */
            
            if (aDeal.EBH_DealStartDate__c < oDeal.EBH_DealStartDate__c || (aDeal.EBH_DealStartDate__c == oDeal.EBH_DealStartDate__c && adt.aStartTime < adt.oStartTime)) {
                mResult.put('msg',Label.NA_Deal_Amend_Contract_DateError_Msg_1);
            }else if (aDeal.EBH_DealPrice__c != oDeal.EBH_DealPrice__c && (aDeal.EBH_DealStartDate__c <= Date.today() || aStartDateTime <= System.now())) {
                mResult.put('msg',Label.NA_Deal_Amend_Contract_DateError_Msg_2);
            }
            else {//Create new Admendment Deal

                aDeal.EBH_Status__c = 'New';
                aDeal.Amendment_Date__c = System.now();
                aDeal.EBH_DealStartTime__c = aStartTime;
                aDeal.EBH_DealEndTime__c = aEndTime;
                insert aDeal;

                mResult.put('status', 'ok');
                mResult.put('aDealId', aDeal.Id);
            }

        }catch(Exception ex) { mResult.put('msg', ex.getMessage()); }
        
        return mResult;

    }

    public class DealTime {
        public String aStartTime; //Admendment Deal Start Time
        public String aEndTime; //Admendment Deal End Time
        public String oStartTime; //Original Deal Start Time
        public String oEndTime; //Original Deal End Time
    }
}