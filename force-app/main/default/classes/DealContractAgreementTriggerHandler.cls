/*********************************************************************************************************************************
@ Class:          DealContractAgreementTriggerHandler
@ Version:        1.0
@ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:        US-0012299 - Contract - Start, end and running status changes
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.09.2022 / Sambath Seng / Create class
@               : 21.09.2023 / Sambath Seng / US-0013982 - PM Deal Items to reflect changes made on record
@               : 28.01.2025 / vadhanak voun / US-0016364 - 7 - Internal Approval Process (Bond Team)
@               : 30.01.2025 / Vimean Heng / US-0016411 - 6 - Submit Sub Deals for Internal Approval
@               : 17.03.2025 / Vimean Heng / US-0016717 - Contract Amendment Process - No Change in Subsidy
@               : 08.04.2025 / Vimean Heng / US-0017027 - Amended Contract - Trigger Approval Process
*********************************************************************************************************************************/
public with sharing class DealContractAgreementTriggerHandler {
    private static string DCA_SELLER_APPROVED = 'Seller Approved';
    private static string DCA_RUNNING = 'Running';
    private static Integer BATCH_SIZE = Integer.valueof(System.Label.BatchSyncPMDealFieldsToChild_BatchSize);

    //NK:23/01/2025:US-0016364
    private static string DCA_SENT_TO_SELLER = 'Sent to Seller';  
    private static string DCA_INTERNAL_REJECTED = 'Internally Rejected';    
    private static string DEAL_SENT_TO_SELLER = 'Sent to Seller';
    private static string DEAL_IN_APPROVAL = 'In Approval';
    private static string DEAL_INTERNAL_REJECTEDL = 'Internally Rejected';
    private static string DEAL_NEW = 'New';
    private static string DEAL_IN_AMENDMENT = 'In Amendment';
    
	/*****************************************************************************************************************************
    @ Method:   autoPopulateStartEndDateTime
    @ Version:  1.0
    @ Author: 	Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:	US-0012299 - Contract - Start, end and running status changes
    @ Event:	before insert, before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Deal_Contract_Agreement__c> listNew
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.09.2022 / Sambath Seng / Create method
    *****************************************************************************************************************************/
    public static void autoPopulateStartEndDateTime(List<Deal_Contract_Agreement__c> listNew, Map<Id,Deal_Contract_Agreement__c> mapOld)
    {
        Boolean isNew = (mapOld==null);
        DateTime currentDateTime = System.Now();
        for(Deal_Contract_Agreement__c newDCA : listNew){
            Deal_Contract_Agreement__c oldDCA = isNew ? new Deal_Contract_Agreement__c() : mapOld.get(newDCA.Id);
            if(
                (isNew && newDCA.Deal_Start_Date__c <> null)
                || (!isNew && newDCA.Deal_Start_Date__c <> null && ((newDCA.Deal_Start_Date__c <> oldDCA.Deal_Start_Date__c || newDCA.Deal_Start_Time__c <> oldDCA.Deal_Start_Time__c) || (newDCA.Deal_Start_Date_and_Time__c == null && newDCA.Deal_Start_Date__c <> null)))
            ){
                newDCA.Deal_Start_Date_and_Time__c = DateTime.newInstanceGMT(newDCA.Deal_Start_Date__c,newDCA.Deal_Start_Time__c == null ? Time.newInstance(0,0,0,0) : newDCA.Deal_Start_Time__c);
            }
            if(
                (isNew && newDCA.Deal_End_Date__c <> null)
                || (!isNew && newDCA.Deal_End_Date__c <> null && ((newDCA.Deal_End_Date__c <> oldDCA.Deal_End_Date__c || newDCA.Deal_End_Time__c <> oldDCA.Deal_End_Time__c) || (newDCA.Deal_End_Date_and_Time__c == null && newDCA.Deal_End_Date__c <> null)))
            ){
                newDCA.Deal_End_Date_and_Time__c = DateTime.newInstanceGMT(newDCA.Deal_End_Date__c,newDCA.Deal_End_Time__c == null ? Time.newInstance(0,0,0,0) : newDCA.Deal_End_Time__c);
            }
        }
    }

    /*****************************************************************************************************************************
    @ Method:   syncAttachedDealFieldValue
    @ Version:  1.0
    @ Author: 	Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:	US-0013982 - PM Deal Items to reflect changes made on record
    @ Event:	after update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Deal_Contract_Agreement__c> listNew, Map<Id,Deal_Contract_Agreement__c> oldMap
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.09.2023 / Sambath Seng / Create method
    *****************************************************************************************************************************/
    public static void syncAttachedDeals(List<Deal_Contract_Agreement__c> listNew, Map<Id,Deal_Contract_Agreement__c> oldMap)
    {
        Map<Id,Deal_Contract_Agreement__c> mIdDCA = new Map<Id,Deal_Contract_Agreement__c>();
        Set<Id> dcaIds = new Set<Id>();
        List<EBH_Deal__c> dealsToUpdate = new List<EBH_Deal__c>();
        List<String> fieldNamesToCheck = new List<String>{'Deal_Start_Date__c','Deal_Start_Time__c','Deal_End_Date__c','Deal_End_Time__c','Category__c'};
        RecordType pmDealRecType = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Promotions_Manager_Deals');
    
        for (Deal_Contract_Agreement__c newDCA : listNew) {
            Deal_Contract_Agreement__c oldDCA = oldMap.get(newDCA.Id);
            if(newDCA.RecordTypeId == pmDealRecType.Id && hasAnyFieldChanged(newDCA,oldDCA,fieldNamesToCheck)){
                mIdDCA.put(newDCA.Id,newDCA);
                dcaIds.add(newDCA.Id);
            }
        }

        List<EBH_Deal__c> lstRelatedDeals = [SELECT Id,EBH_DealStartDate__c,EBH_DealStartTime__c,EBH_DealEndDate__c,EBH_DealEndTime__c,EBH_Category__c,Deal_Contract_Agreement__c,dcaSyncStartDate__c,dcaSyncStartTime__c,dcaSyncEndDate__c,dcaSyncEndTime__c ,dcaSyncCategory__c FROM EBH_Deal__c WHERE Deal_Contract_Agreement__c IN :mIdDCA.keyset() LIMIT 201];

        if(!lstRelatedDeals.isEmpty()){
            if(lstRelatedDeals.size() > 200){
                BatchSyncPMDealFieldsToChild batchable = new BatchSyncPMDealFieldsToChild(dcaIds);
                Database.executeBatch(batchable,BATCH_SIZE);
            } else {
                for(EBH_Deal__c oDeal : lstRelatedDeals){
                    Deal_Contract_Agreement__c dca = mIdDCA.get(oDeal.Deal_Contract_Agreement__c);
                    dealsToUpdate.add(BatchSyncPMDealFieldsToChild.assignValues(dca,oDeal));
                }

                if(!dealsToUpdate.isEmpty()){
                    update dealsToUpdate;
                }
            }
        }
    }

    /*****************************************************************************************************************************
    @ Method:   hasAnyFieldChanged
    @ Version:  1.0
    @ Author: 	Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:	US-0013982 - PM Deal Items to reflect changes made on record
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     SObject newRecord, SObject oldRecord, List<String> fieldNames
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.09.2023 / Sambath Seng / Create method
    *****************************************************************************************************************************/
    private static Boolean hasAnyFieldChanged(SObject newRecord, SObject oldRecord, List<String> fieldNames) {
        if (newRecord == null || oldRecord == null || fieldNames == null || fieldNames.isEmpty()) {
            return false;
        }

        for (String fieldName : fieldNames) {
            if (newRecord.get(fieldName) != oldRecord.get(fieldName)) {
                return true; // At least one field has changed
            }
        }

        return false;
    }

    /*****************************************************************************************************************************
    @ Method:   checkStatusChanged
    @ Version:  1.0
    @ Author: 	vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:	US-0016364 - 7 - Internal Approval Process (Bond Team)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Deal_Contract_Agreement__c> listNew,Map<Id,Deal_Contract_Agreement__c> mapOld
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 28.01.2025 / vadhanak voun / Create method
    @                            /US-0016364 Update related deals when status changed to "Sent to Seller"
    @               : 30.01.2025 / Vimean Heng / US-0016411 - 6 - Submit Sub Deals for Internal Approval
    @               : 17.03.2025 / Vimean Heng / US-0016717 - Contract Amendment Process - No Change in Subsidy
    @               : 08.04.2025 / Vimean Heng / US-0017027 - Amended Contract - Trigger Approval Process
    *****************************************************************************************************************************/
    public static void checkStatusChanged(List<Deal_Contract_Agreement__c> listNew,Map<Id,Deal_Contract_Agreement__c> mapOld)
    {
        RecordType rtDCASub = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals');
        Set<Id> setDCASentToSeller = new Set<Id>();
        Set<Id> setDCARejected = new Set<Id>();
        Set<Id> setDCAInApproval = new Set<Id>();
        Map<String,String> mapDCASellerId = new Map<String,String>();
        for(Deal_Contract_Agreement__c dca : listNew)
        {
            if(dca.RecordTypeId==rtDCASub.Id)
            {
                Deal_Contract_Agreement__c oldDCA = mapOld.get(dca.Id);
                if(isChangedToSentToSeller(oldDCA,dca)){
                    setDCASentToSeller.add(dca.Id);
                    mapDCASellerId.put(dca.Id,dca.eBay_Seller__c);
    
                }else if(isChangedToRejected(oldDCA,dca))
                {
                    setDCARejected.add(dca.Id);
                }else if(isChangedToInApproval(oldDCA,dca))
                {
                    setDCAInApproval.add(dca.Id);
                }
            }
        }

        if(!setDCASentToSeller.isEmpty())
        {
            createSellerComsByDCA('Deals',mapDCASellerId,'Sub Deals Contract Sign off', 'Subsidized Deal Contract Agreement - Contract Sign Off - US');
            updateRelatedDeals(setDCASentToSeller,DEAL_SENT_TO_SELLER,new Set<String>{DEAL_IN_APPROVAL,DEAL_IN_AMENDMENT});
        }
        if(!setDCARejected.isEmpty())
        {
            updateRelatedDeals(setDCARejected,DEAL_INTERNAL_REJECTEDL,null);
        }
        if(!setDCAInApproval.isEmpty())
        {
            updateRelatedDeals(setDCAInApproval,DEAL_IN_APPROVAL,new Set<String>{DEAL_NEW,DEAL_INTERNAL_REJECTEDL});
        }
     
    }
    private static Boolean isChangedToInApproval(Deal_Contract_Agreement__c dcaOld, Deal_Contract_Agreement__c dcaNew){
        return (dcaNew.Status__c <> dcaOld.Status__c && dcaNew.Status__c== DEAL_IN_APPROVAL);
    }
    private static Boolean isChangedToSentToSeller(Deal_Contract_Agreement__c dcaOld, Deal_Contract_Agreement__c dcaNew){
        return (dcaNew.Status__c <> dcaOld.Status__c && dcaNew.Status__c== DCA_SENT_TO_SELLER);
    }
    private static Boolean isChangedToRejected(Deal_Contract_Agreement__c dcaOld, Deal_Contract_Agreement__c dcaNew){
        return (dcaNew.Status__c <> dcaOld.Status__c && dcaNew.Status__c== DCA_INTERNAL_REJECTED);
    }


    private static void updateRelatedDeals(Set<Id> setDCA,String statusToUpdate,Set<String> setFilterStatus)
    {

        System.enqueueJob(new ChunkDealUpdate(setDCA,statusToUpdate,setFilterStatus,400,true));

    }
    /*****************************************************************************************************************************
    @ Method:   createSellerComsByDCA
    @ Version:  1.0
    @ Author: 	vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:	US-0016364 - 7 - Internal Approval Process (Bond Team)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     Map<String,String> mapDCASellerId,String scName,String scEmailTemplate
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 28.01.2025 / vadhanak voun / Create method
    @                            /US-0016364 Update related deals when status changed to "Sent to Seller"
    *****************************************************************************************************************************/
    public static void createSellerComsByDCA(String scRT,Map<String,String> mapDCASellerId,String scName,String scEmailTemplate)
    {
        RecordType rtSCDeal = ApexUtil.getRecordTypeByName('Seller_Communication__c', scRT);
        Map<String,String> mapSellerDCA = new Map<String,String>();
        for(String dcaId : mapDCASellerId.keySet())
        {
            mapSellerDCA.put(mapDCASellerId.get(dcaId),dcaId);
        }
        Set<String> setRTCons = new Set<String>{ ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH').Id, ApexUtil.getRecordTypeByName('Contact', 'Seller_Portal').Id};
        String soqlConts = 'Select Id,AccountId from Contact where AccountId IN :listSellerId AND RecordTypeId IN:setRTCons';
        List<Contact> listContacts = (List<Contact>)ApexSafe.query().doQuery(soqlConts,new Map<String, Object> {'listSellerId' => mapDCASellerId.values(),'setRTCons'=>setRTCons});
        List<Seller_Communication__c> listSC = new List<Seller_Communication__c>();
        for(Contact cont : listContacts)
        {
            String dcaId = mapSellerDCA.get(cont.AccountId);            
            listSC.add(
                new Seller_Communication__c(
                    Name = scName,
                    RecordTypeId = rtSCDeal.Id,
                    Contact__c = cont.Id,
                    Email_Template__c = scEmailTemplate,
                    Account__c = cont.AccountId,
                    PM_Deal__c = dcaId
                )
            );
        }
        ApexSafe.dml().secCheck(false).doInsert(listSC,true);
    }

    //chunk dml of related records by query with filter until the query return empty
class ChunkDealUpdate implements Queueable{
	private Integer chunkSize = 1;
	private Set<Id> setDCA;
	String statusToUpdate;
	Set<String> setFilterStatus;
	Boolean firstChunk;
	
	public ChunkDealUpdate(Set<Id> setDCA,String statusToUpdate,Set<String> setFilterStatus,Integer chunkSize,Boolean firstChunk)
	{
		this.setDCA = setDCA;
		this.statusToUpdate = statusToUpdate;
		this.setFilterStatus = setFilterStatus;
		this.chunkSize = chunkSize;
		this.firstChunk  = firstChunk;
		
		//next chunk process from enqueueJob
		if(firstChunk)
		{
			doUpdate();
		}
	}
	
	public void execute(QueueableContext context) 
    {
		doUpdate();
	}
	private void doUpdate()
	{
		if(setFilterStatus <> NULL && setFilterStatus.contains(statusToUpdate))
		{
			return; //avoid query the same status to then update to the same status will infinite query/dml/crash
		}
		List<EBH_Deal__c> dealsToUpdate = getListDealsToUpdate();
	
        if(!dealsToUpdate.isEmpty())
        {
            for(EBH_Deal__c oDeal : dealsToUpdate)
            {
                oDeal.EBH_Status__c =   statusToUpdate;
            }
			
            Database.SaveResult[]  updateResult = ApexSafe.dml().secCheck(false).doUpdate(dealsToUpdate,false);
			handleError(updateResult);
			
			if(dealsToUpdate.size()==chunkSize) //should be more remain in DB
			{
				System.enqueueJob(new ChunkDealUpdate(setDCA,statusToUpdate,setFilterStatus,chunkSize,false)); 
			}
        }
	}
	
	private List<EBH_Deal__c> getListDealsToUpdate()
	{
		String soqlDeal = 'SELECT Id,Deal_Contract_Agreement__c FROM EBH_Deal__c WHERE Deal_Contract_Agreement__c IN :setDCA';
        soqlDeal += (setFilterStatus==null?' AND EBH_Status__c <> :statusToUpdate ':' AND EBH_Status__c IN :setFilterStatus ');   
		soqlDeal += ' LIMIT :chunkSize';
        List<EBH_Deal__c> dealsToUpdate = (List<EBH_Deal__c>)ApexSafe.query().secCheck(false).doQuery(soqlDeal,new Map<String, Object> {'setDCA' => setDCA,'setFilterStatus'=>setFilterStatus,'statusToUpdate'=>statusToUpdate,'chunkSize'=>chunkSize});
		return dealsToUpdate;
	}
	
	private void handleError(Database.SaveResult[]  updateResult)
	{
		List<Database.Error> listError = new List<Database.Error>();
		for(Database.SaveResult sr : updateResult)
		{
			if(!sr.isSuccess())
			{
				for(Database.Error err : sr.getErrors())
				{
					//System.debug(err);
					listError.add(err);
				}
			} 
		}
		if(!listError.isEmpty())
		{
			EBH_ApexLogger.logError(listError, 'ChunkDealUpdate', 'execute');
		}
	}	
}
}