/*********************************************************************************************************************************
@ Class:         CKEditorController
@ Version:       1.0
@ Author:        vadhanak voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       controller for CKEditorPage
@				US-0007338 - BA needs to create tables in user story
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.04.2020 / vadhanak voun (vadhanak.voun@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
public without sharing class CKEditorController{	
	public String id{get;set;}
	
	public copado__User_Story__c story {get;set;}
	
	String soqlStory = 'Select Id,Name,Description__c From copado__User_Story__c Where id=:id';
	 
	public CKEditorController()
	{
		
		id = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('id')+'');
		//system.debug('>>>id: '+id);
		init();
	}
	
	private void init()
	{
		story = (copado__User_Story__c)Database.query(soqlStory)[0];
		//system.debug('>>>id: '+story.Description__c);
	}
	
	public PageReference reset()
	{
		init();
		
		return null;
	}
	
	/*****************************************************************************************************************************
	@ Method:   apexDoSave
	@ Version:  1.0
	@ Author:   vadhanak voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  EPH-7680 Clone function on FVF promo clones Nominated Items
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      storyId:  story id currently edit
	@			: 		vfData : data editted by CKEditor from vf page (ifram)
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 03.04.2020 / vadhanak voun (vadhanak.voun@gaea-sys.com) / Created the  Method.
	*****************************************************************************************************************************/
	@AuraEnabled
	public static Map<String,Object> apexDoSave(String storyId,String vfData)
	{
		Map<String,Object> mapResult = new  Map<String,Object>();
		 try
		 {
		 	copado__User_Story__c story = new copado__User_Story__c(Id=storyId,Description__c=vfData);
		 	update story;
		 	mapResult.put('status','ok');
		 	
		 }catch(DMLException dex)
    	{
    		mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
    	}
    	catch(Exception ex)
    	{
    		mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
    	}
		 
		return mapResult;
	}
}