/*********************************************************************************************************************************
@ Class:          Action_TemplateHandler
@ Version:        1.0
@ Author:         vadhanak voun
@ Purpose:        Handler Class for Trigger Action_TemplateTrigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.10.2021 / vadhanak voun / Created the class.
*********************************************************************************************************************************/
public with sharing class Action_TemplateHandler {
   
    /*****************************************************************************************************************************
    @ Method:         updateDescriptionToActions
    @ Version:        1.0
    @ Author:         Vadhanak Voun
    @ Purpose:        US-0010583 - [PT ]Action.Detailed Description is not updated when Action Template.Detailed Description is manually updated
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    list new, map old
    @ Event:        after update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        null
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.10.2021 / Vadhanak Voun / Created the  Method. US-0010583
    *****************************************************************************************************************************/
    public static void updateDescriptionToActions(List<Action_Template__c> listNew, Map<Id,Action_Template__c> mapOld)
    {
        Set<String> setTemplateIds = new Set<String>();
        for(Action_Template__c at: listNew)
        {
            if(at.Detailed_Description__c <> mapOld.get(at.Id).Detailed_Description__c)
            {
                setTemplateIds.add(at.Id);
            }
        }
        
        if(!setTemplateIds.isEmpty())
        {
            updateActions_asyn(setTemplateIds);
        }
    }

    @future
    private static void updateActions_asyn(Set<String> setTemplateIds)
    {
        List<Action__c> toupdate = new List<Action__c>();
        for(Action__c ac: [Select Id,Detailed_Description__c,Action_Template__r.Detailed_Description__c From Action__c Where Action_Template__c IN:setTemplateIds AND TemplateUniqueId__c <> null ] )
        {
            ac.Detailed_Description__c = ac.Action_Template__r.Detailed_Description__c;
            toupdate.add(ac);
        }
        update toupdate;

    }
}