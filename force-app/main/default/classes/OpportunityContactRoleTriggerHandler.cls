/*********************************************************************************************************************************
@ Class:         OpportunityContactRoleTriggerHandler
@ Version:       1.0
@ Author:        Vahanak Voun (vahanak.voun@gaea-sys.com)
@ Purpose:       handler for trigger: OpportunityContactRoleTrigger
@				  
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 01.09.2021 / Vahanak Voun (vahanak.voun@gaea-sys.com) / Created the class.
@               : 19.09.2024 / SRONG TIN (srong.tin@gaea-sys.com) US-0015739 - Lead conversion fix and MIS app layout assignment
*********************************************************************************************************************************/
public with sharing class OpportunityContactRoleTriggerHandler {
     
    public final static String ROLE_INVOICE_RECIPIENT = 'Invoice Receiver';//'Invoice recipient'; old EU uses Invoice recipient, story uses: Invoice Receiver

    /*****************************************************************************************************************************
    @ Method:   updatePrimaryContactAndSAP
    @ Version:  1.0
    @ Author: 	Vahanak Voun (vahanak.voun@gaea-sys.com)
    @ Purpose:	US-0010238 - Migrate class "ContactRoleOnOpportunity" into Hive				
    @ Event:	after insert, after Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<OpportunityContactRole>listNew, Map<Id,OpportunityContactRole> mapOld
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 01.09.2021 / Vahanak Voun / Created the Method
    @               : 19.09.2024 / SRONG TIN (srong.tin@gaea-sys.com) US-0015739 - Lead conversion fix and MIS app layout assignment
    *****************************************************************************************************************************/
    public static void updatePrimaryContactAndSAP(List<OpportunityContactRole> listNew, Map<Id,OpportunityContactRole> mapOld){
        Boolean isNew = (mapOld == null);
        //Boolean isDelete = Trigger.isDelete;

        List<OpportunityContactRole> listInvRec = new List<OpportunityContactRole>();
        List<OpportunityContactRole> listPrimary = new List<OpportunityContactRole>();
        Set<Id> setContId = new Set<Id>();
        Set<Id> setOppId = new Set<Id>();
        for(OpportunityContactRole oppCR: listNew)
        {
            if(oppCR.IsPrimary && ( isNew || (!isNew && oppCR.IsPrimary <> mapOld.get(oppCR.Id).IsPrimary)) )
            {
                listPrimary.add(oppCR);
            }
            if(ROLE_INVOICE_RECIPIENT.equalsIgnoreCase(oppCR.Role) && (isNew || (!isNew && oppCR.Role <> mapOld.get(oppCR.Id).Role)) )
            {
                listInvRec.add(oppCR);
            }
            setContId.add(oppCR.ContactId);
            setOppId.add(oppCR.OpportunityId);
        }
        if(listInvRec.isEmpty() && listPrimary.isEmpty())
        {
            return;
        }

        // 19.09.2024/SRONG TIN/US-0015739
        String soqlContact = 'Select Id,AccountId,Account.SAP_ID__c From Contact Where Id IN :setContId';
        // 22.09.2024/SRONG TIN/ ApexSafe.query().secCheck(false) - to avoid security check because field SAP_ID__c is not accessible
        List<Contact> contactsList = (List<Contact>) ApexSafe.query().secCheck(false).doQuery(soqlContact,new Map<String, Object> {'setContId' => setContId});
        String soqlOpp = 'Select Id,Primary_Contact__c,SAP_ID_Overwrite__c From Opportunity Where Id IN :setOppId';
        List<Opportunity> opportunityList = (List<Opportunity>) ApexSafe.query().secCheck(false).doQuery(soqlOpp,new Map<String, Object> {'setOppId' => setOppId});
        Map<Id,Contact> mapContact = new Map<Id,Contact>();
        if(!contactsList.isEmpty()){
            mapContact = new Map<Id,Contact>(contactsList);
        }
        Map<Id,Opportunity> mapOpp = new Map<Id,Opportunity>();
        if(!opportunityList.isEmpty()){
            mapOpp = new Map<Id,Opportunity>(opportunityList);
        }
        
        //to update sap override or primary contact
        Map<Id,Opportunity> mapOppToUpdate = new Map<Id,Opportunity>();
        // 19.09.2024/SRONG TIN/US-0015739
        if (mapOpp != null && !mapOpp.isEmpty()) {
            for(OpportunityContactRole oppCR: listPrimary)
            {
                Opportunity opp = mapOpp.get(oppCR.OpportunityId);
                if(opp != null && (oppCR.ContactId <> opp.Primary_Contact__c))
                {
                    opp.Primary_Contact__c = oppCR.ContactId;
                    mapOppToUpdate.put(opp.Id,opp);
                }
            }
            for(OpportunityContactRole oppCR: listInvRec)
            {
                Opportunity opp = mapOpp.get(oppCR.OpportunityId);
                Contact cont = mapContact.get(oppCR.ContactId);
                if(opp != null && (opp.SAP_ID_Overwrite__c <> cont.Account.SAP_ID__c))
                {
                    opp.SAP_ID_Overwrite__c = cont.Account.SAP_ID__c;
                    mapOppToUpdate.put(opp.Id,opp);
                }
            }
        }
        

        if(!mapOppToUpdate.isEmpty())
        {
            ApexSafe.dml().secCheck(false).doUpdate(mapOppToUpdate.values(), true);// 19.09.2024/SRONG TIN/US-0015739
            //update mapOppToUpdate.values();
        }

    } 
    /*****************************************************************************************************************************
    @ Method:   reassignPrimaryContact
    @ Version:  1.0
    @ Author: 	Vahanak Voun (vahanak.voun@gaea-sys.com)
    @ Purpose:	US-0010238 - Migrate class "ContactRoleOnOpportunity" into Hive				
    @ Event:	after delete
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<OpportunityContactRole>listOld
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 01.09.2021 / Vahanak Voun / Created the Method
    @               : 19.09.2024 / SRONG TIN (srong.tin@gaea-sys.com) US-0015739 - Lead conversion fix and MIS app layout assignment
    *****************************************************************************************************************************/
    public static void reassignPrimaryContact(List<OpportunityContactRole> listCR){
        Set<Id> setOppIds = new Set<Id>();
        Set<Id> setCRIds = new Set<Id>();
        for(OpportunityContactRole oppCR: listCR)
        {
            setOppIds.add(oppCR.OpportunityId);
            setCRIds.add(oppCR.Id);
        }
        // 19.09.2024/SRONG TIN/US-0015739
        List<Opportunity> listOppToUpdate = new List<Opportunity>();
        String soql = 'Select Id,Primary_Contact__c,(Select Id,ContactId,OpportunityId,IsPrimary From OpportunityContactRoles Where IsPrimary=True AND Id NOT IN :setCRIds) From Opportunity Where Id IN :setOppIds';
        List<Opportunity> lstOpps = (List<Opportunity>) ApexSafe.query().doQuery(soql,new Map<String, Object> {'setCRIds' => setCRIds, 'setOppIds' => setOppIds});
        //[Select Id,Primary_Contact__c,(Select Id,ContactId,OpportunityId,IsPrimary From OpportunityContactRoles Where IsPrimary=True AND Id NOT IN :setCRIds) From Opportunity Where Id IN :setOppIds]
        for(Opportunity opp: lstOpps)
        {            
            //in case 2+ primary contact roles and 1 is being deleted, reassign another one
            if(!opp.OpportunityContactRoles.isEmpty() && opp.OpportunityContactRoles[0].ContactId <> opp.Primary_Contact__c)
            {
                opp.Primary_Contact__c = opp.OpportunityContactRoles[0].ContactId;
                listOppToUpdate.add(opp);

            }else if(opp.OpportunityContactRoles.isEmpty()) //no more primary contact role
            {
                opp.Primary_Contact__c = null;  
                listOppToUpdate.add(opp);
            }
        }
        
        if(!listOppToUpdate.isEmpty())
        {
            ApexSafe.dml().secCheck(false).doUpdate(listOppToUpdate, true);// 19.09.2024/SRONG TIN/US-0015739
           // update listOppToUpdate;
        }

    }
}