public with sharing class GoToUserStoryController {
	public  String UserStoryName { get; Set; }
	public Boolean error { get; set; }
	public GoToUserStoryController() {
		Map<String, String> params = ApexPages.currentPage().getParameters();
		set<string> setParams = params.keySet();
		error= false;
		for (String s :setParams) {
			UserStoryName= s;
			break;
		}
		//   System.debug('Parámetro recibido=' + UserStoryName);


	}

	public PageReference redirect() {

		PageReference pageRef = ApexPages.currentPage();
		if(UserStoryName != null) {
			List<Copado__User_Story__c> lcus = [select id from Copado__User_Story__c where name = :UserStoryName or Old_Copado_Reference__c = :UserStoryName];
			System.debug(lcus);
			if(lcus != null && !lcus.isEmpty()) {
System.debug(lcus);
				pageRef= new PageReference('/lightning/r/copado__User_Story__c/' + lcus [0].id + '/view');
                
			}else{
			error= true;
                pageRef=null;
            } 
		}

		return pageRef;

	}

}