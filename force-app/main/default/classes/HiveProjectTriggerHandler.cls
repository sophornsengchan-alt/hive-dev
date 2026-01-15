/*********************************************************************************************************************************
 @ Class:          HiveProjectTriggerHandler
 @ Version:        1.0
 @ Author:         David Herrero
 @ Purpose:        handler for trigger/ object Hive_Project
 ----------------------------------------------------------------------------------------------------------------------------------
 @ Change history: 2.08.2021 / David Herrero / Created the class.
 @				 : 06.7.2023/vadhanak voun/ US-0012701 - Auto Populate Project end date when status changed to completed
 @				 : 14.09.2023/ David Herrero / 
 @				 : 18.09.2023/ David Herrero / Moving excluded statusses to Custom Label
 *********************************************************************************************************************************/
public without sharing class HiveProjectTriggerHandler{
	public static final String COMPLETED_STATUS = 'Completed';
	public static final String QUERY_USER_STORIES = 'select id,hive_project__c from copado__user_story__c where Hive_Project__c in :completedProjectsToValidate and copado__status__c not in :EXCLUDED_US_STATUS';
	public static final String QUERY_REQUIREMENT_REQUESTS = 'select id,hive_project__c from Requirement_Request__c where Hive_Project__c in :completedProjectsToValidate and Status__c not in :EXCLUDED_FR_STATUS';
	public static final String ERROR_MESSAGE = 'You can not close a project with open feature requests or user stories. Please, progress before closing project.';

    public static final String[] EXCLUDED_US_STATUS=  Label.EXCLUDED_US_STATUS.split(',');// DHE 2023-09-14 
    //public static final String[] EXCLUDED_FR_STATUS= new String[] {'Delivered','Completed' ,'Rejected' ,'On-hold' };
	public static final String[] EXCLUDED_FR_STATUS= Label.EXCLUDED_FR_STATUS.split(',');


	/*****************************************************************************************************************************
	@ Method:   validateCompletedStatus
	@ Version:  1.0
	@ Author:   David Herrero	
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      newList, newMap, oldMap
	@ Event: 	before update
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 2.08.2021 / David Herrero / Created the Method.
	@				: 06.7.2023/vadhanak voun/ US-0012701 - Auto Populate Project end date when status changed to completed
	@										/When Hive Project.Status is changed to stage = "Completed" and End Date=null then auto populate Hive Project.End Date= {current date}
	*****************************************************************************************************************************/
	public static void validateCompletedStatus(Hive_Project__c[] newList, Map<Id, Hive_Project__c> newMap,Map<Id, Hive_Project__c> oldMap){
        
		List<copado__User_Story__c> lus;
		List<Requirement_Request__c> lfr;
		set<id> addedError = new set<id>();

		byPass__c bp = byPass__c.getInstance(UserInfo.getUserId());
		Boolean bypassvalidation = (bp==null || (bp!=null && !bp.byPass_Trigger__c)?false:true);
		if (bypassvalidation){return; // if the user has bypassvalidation then we don't need to validate anything 2023-09-19 DHE
	}
		set<id> completedProjectsToValidate = new set<id>();
		for (Hive_Project__c p : newList){
			if ((oldMap.get(p.Id).Status__c <>  p.Status__c) && p.Status__c== COMPLETED_STATUS){	//NK:06/07/2023:US-0012701 added check change
				completedProjectsToValidate.add(p.ID);
				p.End_Date__c = p.End_Date__c==null?System.today():p.End_Date__c;	//NK:06/07/2023:US-0012701 
			}
		}

		if (!completedProjectsToValidate.isEmpty()){
			lus = Database.query(QUERY_USER_STORIES);
            lfr = Database.query(QUERY_REQUIREMENT_REQUESTS);


			if (lus != null && lus.size()>0){
                //System.debug('size of lus = ' + lus);

				for (copado__User_Story__c cus : lus){
					newMap.get(cus.hive_project__c).addError(ERROR_MESSAGE);
					addedError.ADD(cus.hive_project__c);
				}
			} 
				
                //System.debug('size of lfr = ' + lfr);

				if (lfr != null){
                    //System.debug('lfr not null ' + lfr);

					for (Requirement_Request__c rr : lfr){
                        //System.debug('Requirement_Request__c ' + rr);
                        //System.debug('addedError ' + addedError);

						if (!addedError.contains(rr.Hive_Project__c)){
                            //System.debug('addedError ' + addedError);

							newMap.get(rr.Hive_Project__c).addError(ERROR_MESSAGE);
							addedError.ADD(rr.hive_project__c);


				
				}
			}
		}
        System.debug('addedError ' + addedError);

        }
    }
}