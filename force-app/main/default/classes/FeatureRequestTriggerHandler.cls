/*********************************************************************************************************************************
 @ Class:          FeatureRequestTriggerHandler
 @ Version:        1.0
 @ Author:         Loumang SENG (loumang.seng@gaea-sys.com)
 @ Purpose:        Handler for trigger FeatureRequestTrigger/ object Feature Request(Requirement_Request__c)
 ----------------------------------------------------------------------------------------------------------------------------------
 @ Change history: 12.07.2022 / Loumang SENG / Created the class./US-0011982 - Feature request & Project object Technical estimation fields
 *********************************************************************************************************************************/
public without sharing class FeatureRequestTriggerHandler{
    /*****************************************************************************************************************************
    @ Method:   calculateComplexityEstimation
    @ Version:  1.0
    @ Author: 	Loumang SENG (loumang.seng@gaea-sys.com)
    @ Purpose:	US-0011982 - Feature request & Project object Technical estimation fields
	@ Event:	After Insert, After Update, After Delete
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter: List<Requirement_Request__c> listNew,Map<Id,Requirement_Request__c>mapOld 
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 13.07.2022 / Loumang SENG / Method Creation
	*****************************************************************************************************************************/
    public static void calculateComplexityEstimation(List<Requirement_Request__c> listNew,Map<Id,Requirement_Request__c>mapOld)
    {
		Boolean isNew = (mapOld==null);
        Set<Id> hpId = new Set<Id>();

		for(Requirement_Request__c rr : listNew){
            if(rr.Hive_Project__c != null && (isNew || (!isNew && rr.Complexity_Estimation_story_points__c != mapOld.get(rr.Id).Complexity_Estimation_story_points__c))){
                hpId.add(rr.Hive_Project__c);
            }
		}
        if(hpId.isEmpty()) return;
        
        List<Hive_Project__c> listProject = new List<Hive_Project__c>(); 
		for(Aggregateresult arr : [SELECT Hive_Project__c projectId, sum(Complexity_Estimation_story_points__c) totalPoint FROM Requirement_Request__c WHERE Hive_Project__c =:hpId AND Complexity_Estimation_story_points__c != null Group By Hive_Project__c])
		{
			listProject.add(new Hive_Project__c(
				Id= (Id)arr.get('projectId'),
				ComplexityEstimationDevStoryPoints__c = (Decimal)arr.get('totalPoint')
            ));
		}
		if(!listProject.isEmpty()) update listProject;
    }

}