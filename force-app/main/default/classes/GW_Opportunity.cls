/**
 * Author : Gaeasys
 * CreatedDate: 31-May-2018
 * Description:
 * 22.12.2020 / Acmatac SEING: Deprecate not used component
 */
public with sharing class GW_Opportunity {

    /*
		convert Opportunity to Media_Plan__c from field mapping metadata O2M_Mapping__mdt
    */
    // public static Media_Plan__c convertOppToMediaPlan (Opportunity opp){
    // 	Media_Plan__c mediaPlan = new Media_Plan__c( Opportunity__c= opp.id );
	// 	for( O2M_Mapping__mdt o2mMapping :(List<O2M_Mapping__mdt>) QueryUtil.queryRecords(Util.NS+'O2M_Mapping__mdt') ){
	// 	    Object val =  o2mMapping.Default__c ? o2mMapping.Default_Value__c : opp.get(o2mMapping.Opportunity_Field__c);
	// 	    mediaPlan.put(o2mMapping.Media_Plan_Field__c, val);
	// 	}
	// 	return mediaPlan;
    // }

    /*
        @Vengleab: Task #16010, create and link media plan to opp after Opportunity stage change to Qualified Meeting
    */
    // public static List<Media_Plan__c> createMediaPlan (Set<String> oppIDs){
    // 	if(!oppIDs.isEmpty()) {
	//     	List<Media_Plan__c> mediaPlans = new List<Media_Plan__c>();
	//     	for(Opportunity opp : (List<Opportunity>) QueryUtil.queryRecords('Opportunity', oppIDs)){
	//     		Media_Plan__c mediaPlan = GW_Opportunity.convertOppToMediaPlan(opp);
	// 	    	mediaPlans.add(mediaPlan);
	//     	}
	//     	insert mediaPlans;
	
	//     	Opportunity[] updateOpps = new List<Opportunity>();
	//     	for(Media_Plan__c m: mediaPlans){
	//     		updateOpps.add(new Opportunity(Id=m.Opportunity__c, Media_Plan__c = m.Id));
	//     	}
	//     	update updateOpps;
	//     	return mediaPlans;
    // 	}
    // 	return null;
    // }
    
	//change history : AMT, Deprecated, Task #21557, change inside logic.
	/*public static Map<String,Object> createMediaPlan (String oppId){
    	Map<String,Object> results = new Map<String, Object>();
    	Map<Id, Integer> mMPVersion = new Map<Id, Integer>();
    	Integer countMP = Database.countQuery('SELECT Count() FROM Media_Plan__c WHERE Opportunity__c =: oppId');
    	if(countMP == 0){
			mMPVersion.put(oppId, null);
		}else{
			mMPVersion.put(oppId, countMP); 
		}
    		
    	for(Opportunity opp : (List<Opportunity>) QueryUtil.queryRecords('Opportunity', new Set<String>{oppId})) {
    		if(opp.StageName != Label.OPP_STATUS_QM && opp.Customer_Type__c != Label.OPP_CUS_TYPE_1P){
    			results.put('Message', 'Only Opportunity stage ' + Label.OPP_STATUS_QM + ' is allow to create media plan');
    			return results;
    		}

    		Media_Plan__c mediaPlan = GW_Opportunity.convertOppToMediaPlan(opp);
    		mediaPlan.Name = mMPVersion.get(oppId) == null ? mediaPlan.Name : mediaPlan.Name + '. V' + (mMPVersion.get(oppId)+1);
    		insert mediaPlan;
    		results.put('Id',mediaPlan.Id);
    		update new Opportunity(Id=oppId, Media_Plan__c = mediaPlan.Id);
    	}
    	return results;
    }*/
	
	/*
	@ Change history: 
	*	26-June-2019 : AMT, Task #21556, 2- Update "Create Media Plan Request" Button on Opportunity
	*						Task #21557, 3- Auto create Revision Quote whenever Revision MPR is created
	*/
    // public static Map<String,Object> createMediaPlan (String oppId){
    // 	Map<String,Object> results = new Map<String, Object>();
    // 	List<Opportunity> lstopp = (List<Opportunity>) QueryUtil.queryRecords('Opportunity', new Set<String> {'RecordType.DeveloperName'}, new Set<String>{oppId});
	// 	if(!lstopp.isEmpty()){
	// 		Opportunity opp = lstopp.get(0);
	// 		if(opp.StageName != Label.OPP_STATUS_QM && opp.StageName != Label.OPP_STATUS_CW) {
	// 			results.put('Message', 'Only Opportunity stage ' + Label.OPP_STATUS_QM + ' is allow to create media plan');
	// 			return results;
	// 		}
	// 		Integer countMP = Database.countQuery('SELECT Count() FROM '+ Util.NS +'Media_Plan__c WHERE Opportunity__c =: oppId');
	//     	// First Media_Plan
	//     	if(countMP == 0){
	// 			Media_Plan__c mediaPlan = GW_Opportunity.convertOppToMediaPlan(opp);
	// 			insert mediaPlan;
	// 			results.put('Id',mediaPlan.Id);
	// 			update new Opportunity(Id=oppId, Media_Plan__c = mediaPlan.Id);
	// 		}
	// 		// Revision Media_Plan
	// 		else {
	// 			Map<String,Object> mpresult = new Map<String,Object>();
	// 			if (opp.RecordType.DeveloperName == Label.OPP_RECORDTYPEDEVNAME_DIRECT) {
	// 				mpresult = GW_IO.revisionIO(opp.IO__c, oppId);
	// 			} else if (opp.RecordType.DeveloperName == Label.OPP_RECORDTYPEDEVNAME_PMP || opp.RecordType.DeveloperName == Label.OPP_RECORDTYPEDEVNAME_PROGRAMMATIC) {
	// 				mpresult = GW_Quote.revisionQuote(oppId);
	// 			}
	// 			results.put('Id',mpresult.get('mpid'));
	// 		}
	// 	} 

    // 	return results;
    // }
    

    // public static void syncRec(List<Opportunity> requiredSyncRecs){
    //     if(requiredSyncRecs.isEmpty()) return;

    //     Map<String, Opportunity> mapRequiredSyncOpp = new Map<String, Opportunity>(requiredSyncRecs);
    //     List<IO__c> ioToSyncs = new List<IO__c>();
    //     List<Media_Plan__c> mpToSync = new List<Media_Plan__c>();
    //     for( Opportunity srcOpp : (List<Opportunity>) QueryUtil.queryRecords('Opportunity', new Set<String>{ Util.NS+'IO__r.'+Util.NS+'Dually_Signed_IO__c'}, mapRequiredSyncOpp.keySet() ) ) {
    //         if(srcOpp.IO__r.Dually_Signed_IO__c) {
    //             mapRequiredSyncOpp.get(srcOpp.Id).IO_Paper__c.addError(Label.ERR_UPDATE_TERMS);
    //             continue;
    //         }
    //         String field = Util.NS +'IO_Paper__c';

    //         if(srcOpp.Media_Plan__c!=null){
    //             Media_Plan__c mp = new Media_Plan__c(Id=srcOpp.Media_Plan__c);
    //             mp.put(field, srcOpp.get(field));
    //             mpToSync.add(mp);
    //         }

    //         if(srcOpp.IO__c!=null){
    //             IO__c io = new IO__c ( Id=srcOpp.IO__c);
    //             io.put(field, srcOpp.get(field));
    //             ioToSyncs.add(io);
    //         }

    //     }
    //     update ioToSyncs;
    //     update mpToSync;
	// }
	
	/*****************************************************************************************************************************
    @ Method:   convertOppToQuote
    @ Version:  1.0
    @ Author: 	Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:	US-0007876 Be able to create one or many quotes on an Opportunity, without needing to create a Media Plan
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     Id oppId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 31.07.2020 / Acmatac SEING / Created the  Method.
    *****************************************************************************************************************************/
	public static Quote convertOppToQuote(Id oppId){
    	//Get from Cache, avoid requery
		Opportunity opp = (Opportunity) Util.getCache( oppId);
		Quote quote = new Quote(OpportunityId = oppId);
		for(O2Q_Mapping__mdt fieldMapper: (List<O2Q_Mapping__mdt>)QueryUtil.queryRecords(Util.NS+'O2Q_Mapping__mdt')) {
			if( fieldMapper.Default__c ) {
				quote.put(fieldMapper.Quote_Field__c, fieldMapper.Default_value__c);
			}else if ( String.isNotBlank(fieldMapper.Opportunity_Field__c)){
				quote.put( fieldMapper.Quote_Field__c , opp.get(fieldMapper.Opportunity_Field__c) );
			}
		}
		return quote;
	}

    
}