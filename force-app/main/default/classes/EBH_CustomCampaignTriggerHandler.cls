/*********************************************************************************************************************************
@ Class:          EBH_CustomCampaignTriggerHandler
@ Version:        1.0
@ Author:         NEHA LUND (nalund@deloitte.co.uk)
@ Purpose:        Handler Class for Custom Campaign Member Trigger
                  EPH-2201 : Custom Campaign member upsert for ETL
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.07.2017 / NEHA LUND / Created the class.
*********************************************************************************************************************************/

public with sharing class EBH_CustomCampaignTriggerHandler {
    
    /*****************************************************************************************************************************
    @ Method:         upsertCampaignMembers
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        Updates custom roll ups on account (record type: Legal Entity) from all child accounts across one level of
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      campaignMembers:      Campaign Member from the trigger scope
                      campaignOldMembers : Campaign Member old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.07.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static void upsertCampaignMembers(List<EBH_CampaignMember__c> campaignMembers) {
        
        List<CampaignMember> updateMembers = new List<CampaignMember>();
        List<CampaignMember> insertMembers = new List<CampaignMember>();
        CampaignMember member;
        List<Schema.FieldSetMember> campaignMemberFields = SObjectType.CampaignMember.FieldSets.EBH_MemberClone.getFields();
        List<Schema.FieldSetMember> customCampaignMemberFields = 
                                    SObjectType.EBH_CampaignMember__c.FieldSets.EBH_MemberClone.getFields();
        Set<ID> cMemberIds = new Set<ID>();
        Set<ID> campaignIds = new SET<ID>();
        Set<String> cockpitIds = new Set<String>();
        Map<String, Id> existingCockPitIds = new map<String, Id>();
            
        for(EBH_CampaignMember__c cm: campaignMembers) {
            if( cm.EBH_CockpitResultId__c != null) {
                cockpitIds.add( cm.EBH_CockpitResultId__c);
                campaignIds.add(cm.EBH_campaign__c);
            }
        }
        
        if(!cockpitIds.isEmpty()) {
            for(CampaignMember cm : Database.query(EBH_ConstantsUtility.CCTH_CAMPAIGNMEMBERQUERY)){
                existingCockPitIds.put( cm.EBH_CockpitResultId__c, cm.Id );
            }
        }
        
        for(EBH_CampaignMember__c cMember : campaignMembers){
            member = new CampaignMember();
            
            for(integer i=0; i<customCampaignMemberFields.size(); i++) {
                  member.put( campaignMemberFields[i].getFieldPath() , cMember.get(customCampaignMemberFields[i].getFieldPath()));
              
            }
            
            cMemberIds.add(cMember.id);
            if( cMember.EBH_CockpitResultId__c != null  && existingCockPitIds.containsKey(cMember.EBH_CockpitResultId__c)) {
                member.Id = existingCockPitIds.get(cMember.EBH_CockpitResultId__c);
                updateMembers.add(member);  
            } else{
                insertMembers.add(member);
            }
        }
       
        if(!insertMembers.isEmpty()) {
            try {
                Database.insert(insertMembers, true);
            } catch(Exception ex) {
                //log error on exception to apex logger object
                EBH_ApexLogger.logError(new List<Exception> { ex }, 
                                        EBH_ConstantsUtility.CCTH_CLASSNAME, EBH_ConstantsUtility.CCTH_METHODUPSERT);
            }
        }
        
        if(!updateMembers.isEmpty()) {
            try {
                Database.update(updateMembers, true);
            } catch(Exception ex) {
                //log error on exception to apex logger object
                EBH_ApexLogger.logError(new List<Exception> { ex }, 
                                        EBH_ConstantsUtility.CCTH_CLASSNAME, EBH_ConstantsUtility.CCTH_METHODUPSERT);
            }
        }
        
        deleteCustomMembers(cmemberIds);
    }
    
    /*****************************************************************************************************************************
    @ Method:         deleteCustomMembers
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        Updates custom roll ups on account (record type: Legal Entity) from all child accounts across one level of
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      campaignMembers:      Campaign Member from the trigger scope
                      campaignOldMembers : Campaign Member old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.07.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    @future
    public static void deleteCustomMembers(Set<ID> memberIds){
        
        List<EBH_CampaignMember__c> customMembers = new List<EBH_CampaignMember__c>();
        EBH_CampaignMember__c member = new EBH_CampaignMember__c();
        
        for(Id memberId : memberIds ){
           customMembers.add(new  EBH_CampaignMember__c(Id = memberId)); 
        }
        if(!customMembers.isEmpty()) {
            try {
                Database.delete(customMembers);
            } catch(Exception ex) {
                //log error on exception to apex logger object
                EBH_ApexLogger.logError(new List<Exception> { ex }, 
                                        EBH_ConstantsUtility.CCTH_CLASSNAME, EBH_ConstantsUtility.CCTH_METHODDELETE);
            }
        }       
    }   
}