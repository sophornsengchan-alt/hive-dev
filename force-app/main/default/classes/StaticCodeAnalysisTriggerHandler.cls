/*********************************************************************************************************************************
@ Class:          StaticCodeAnalysisTriggerHandler
@ Version:        1.0
@ Author:         vadhanak.voun(vadhanak.voun@gaea-sys.com)
@ Purpose:        Handler Class for copado__Static_Code_Analysis_Result__c 
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.07.2024 / Vadhanak Voun / Created the class.
@               : 25.07.2024/ vadhanak voun / US-0015564 - Implement PMD Static Code Analysis Checks for Salesforce Development
@               : 12.08.2024 / vadhanak voun / US-0015723 - PMD - Code scan too clean that keep CSA Score -1          
@               : 10.10.2024 / vadhanak voun / US-0016024 - Fix Static Code Analisys trigger  
*********************************************************************************************************************************/
public with sharing class StaticCodeAnalysisTriggerHandler {
     
    
    
    /*****************************************************************************************************************************
    @ Method:   assignCSAScoreToUserStory
    @ Author:   vadhanak.voun(vadhanak.voun@gaea-sys.com)
    @ Event :   After Insert,After Update
    @ Param:    List<copado__Static_Code_Analysis_Result__c> listNew,Map<Id,copado__Static_Code_Analysis_Result__c> mapOld
    @ Purpose:  25.07.2024/ vadhanak voun / US-0015564 - Implement PMD Static Code Analysis Checks for Salesforce Development            
    ----------------------------------------------------------------------------------------------------------------
    @ Change history: 12.08.2024 / vadhanak voun / US-0015723 - PMD - Code scan too clean that keep CSA Score -1        
    @               : 10.10.2024 / vadhanak voun / US-0016024 - Fix Static Code Analisys trigger
    @*****************************************************************************************************************************/
    public static void assignCSAScoreToUserStory(List<copado__Static_Code_Analysis_Result__c> listNew,Map<Id,copado__Static_Code_Analysis_Result__c> mapOld)
    {
        List<copado__User_Story__c> listStory = new List<copado__User_Story__c>();
        Boolean isNew = (mapOld==null);
        for(copado__Static_Code_Analysis_Result__c sca : listNew)
        {
            //When SCA is executed from somewhere else rather than US, skip it. (e.g. from Credential)
            if(sca.copado__User_Story__c == NULL)
            {
                continue;
            }
            if(isNew)
            {
                //set score on userstory to Zero when SCA executed. So userstory can have Zero instead of -1 (which is not executed SCA)
                listStory.add(new copado__User_Story__c(Id=sca.copado__User_Story__c,Static_Code_Analysis_score__c=0));

            }else if(!isNew && sca.copado__Score_v11__c <> mapOld.get(sca.Id).copado__Score_v11__c)
            {
                //when score updated, upate it to US
                listStory.add(new copado__User_Story__c(Id=sca.copado__User_Story__c,Static_Code_Analysis_score__c=sca.copado__Score_v11__c));
            }
            
        }
        if(!listStory.isEmpty())
        {
            ApexSafe.dml().secCheck(false).doUpdate(listStory, true);
        } 
        
    }
}