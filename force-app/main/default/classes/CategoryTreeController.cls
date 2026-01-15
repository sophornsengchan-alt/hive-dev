/*********************************************************************************************************************************
@ Class:        CategoryTreeController
@ Version:      1.0
@ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:      US-0007356 - LTTM - Select the BoB Category for the Cohort
@				Controller for Aura: CategoryTree
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.03.2020 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / Created the class.
				: 29.11.2022 / Bora Chhorn (bora.chhorn@gaea-sys.com) / US-0012663 - Remove "create action" "create category" "bulk upload cohort seller" from permission set "Growth Coaching"
				: 14.06.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013712 - Add filter on coupon category component
				: 27.07.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013906 - Ensure L4 and L5 categories are visible in component & displayed on portal
				: 31.05.2024 / Sambath Seng / US-0015241 - Create new Contract Category object
*********************************************************************************************************************************/
public with sharing virtual class CategoryTreeController{	// 14.06.2023 / Sophal Noch / US-0013712 : make class virtual class so it can be extended. 
	
	// 27.07.2023 / Sophal Noch / US-0013906 : make static variable mapFieldPathLevel public so it can be reused in other class.
	public static Map<Integer,List<PathItem>> mapFieldPathLevel = new Map<Integer,List<PathItem>>{
			0 => new List<PathItem>{new PathItem('Name','Id',0)},
			1 => new List<PathItem>{new PathItem('Note_ID__r.Name','Note_ID__c',0),new PathItem('Name','Id',1)},
			2 => new List<PathItem>{new PathItem('Note_ID__r.Note_ID__r.Name','Note_ID__r.Note_ID__r.Id',0),new PathItem('Note_ID__r.Name','Note_ID__r.Id',1),new PathItem('Name','Id',2)},
			3 => new List<PathItem>{new PathItem('Note_ID__r.Note_ID__r.Note_ID__r.Name','Note_ID__r.Note_ID__r.Note_ID__r.Id',0),new PathItem('Note_ID__r.Note_ID__r.Name','Note_ID__r.Note_ID__r.Id',1),new PathItem('Note_ID__r.Name','Note_ID__r.Id',2),new PathItem('Name','Id',3)} 			
	};
		 
	public final static String SOQL_BOB = 'Select (Select Id From BOBs__r limit 1),BoB_New_In_Confirm_Date__c,BoB_Removal_Confirm_Date__c,Id,Name,Status__c,EBH_BOBVertical__c,EBH_BOBCNTRY__c,Date_Activated__c,BoB_Cohort__c,OwnerId,Owner.Name,Owner.Email,Managed_Type__c From BoB__c Where Id=:parentId';	
	/*****************************************************************************************************************************
	@ Method:   apexQueryCat
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  US-0007356 - LTTM - Select the BoB Category for the Cohort
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      country,   parentId, level
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 23.03.2020 / Vadhanak Voun / Created the  Method.
	*****************************************************************************************************************************/
	 @AuraEnabled
	 public static Map<String,Object> apexQueryCat(String country,String parentBoBId,String parentCatId,String textSearch)
	 {
		
		Map<String,Object> mapResult = new Map<String,Object>();
		String parentId = parentBoBId;
		//List<BoB__c> bobs = Database.query(EBH_ConstantsUtility.SOQL_BOB);
		List<BoB__c> bobs = Database.query(SOQL_BOB);
		String VAL_SMALL_SITE = '23';
		String VAL_OTHERS_MANAGED = 'Others Managed';

		//LA:06/10/2020:US-0008216:Block Category Selection when Managed Country = Small Site && Managed Type = Others Managed
		If(bobs[0].EBH_BOBCNTRY__c==VAL_SMALL_SITE && bobs[0].Managed_Type__c==VAL_OTHERS_MANAGED){
			mapResult.put('status','ko');
			mapResult.put('error', System.Label.ErrorForBlockingCategorySection);
            return mapResult;
		}
	  	if(String.isBlank(country))
	  	{
	  		country = bobs[0].EBH_BOBCNTRY__c;
	  		mapResult.put('setSite',true);
	  		mapResult.put('site',country);
	  	}
	  	
	  	List<PathItem> listPath = generatePath(parentCatId); 
	 	
	 	mapResult.put('listPath',listPath);
	 	
	 	List<CatItem> listCat = doQueryCat(parentCatId,country,textSearch); 
	 	 
	 	mapResult.put('listResult',listCat);
	 	mapResult.put('status','ok');
	 	return mapResult;
	 }
	 
	 private static List<CatItem> doQueryCat(String parentCatId,String country,String textSearch)
	 {
	 	List<CatItem> listCat = new List<CatItem>(); 
	 	String sWhere = ' Where Active__c=true and Site_auto__c=:country ';
	 	
	 	if(String.isNotBlank(textSearch))
	 	{
	 		textSearch = '%'+textSearch+'%';
	 		sWhere+= ' AND Level_auto__c=3 AND NAME LIKE :textSearch ';
	 	}else if(String.isNotBlank(parentCatId))
	 	{
	 		sWhere+= ' AND Note_ID__c=:parentCatId ';
	 	}else
	 	{
	 		sWhere+= ' AND Level_auto__c=0 ';
	 	}
	 	String sOrder = ' Order By Name';
	 	
	 	for(Category_Tree__c cat: Database.query(EBH_ConstantsUtility.SOQL_CAT_TREE + sWhere + sOrder))
	 	{
	 		listCat.add(
	 			populateItem(cat)
	 		);
	 	}
	 	
	 	return listCat;	
	 }
	 
	 public static List<PathItem> generatePath(String parentCatId) // 14.06.2023 / Sophal Noch / US-0013712 : make method public for reusability in child class CouponCategoryController
	 {
	 	List<PathItem> listPath = new List<PathItem>(); 
	  	PathItem ptRoot = new PathItem('All','',-1);
	  	ptRoot.name = 'All';
	  	ptRoot.id = '';
	  	listPath.add(ptRoot);
	  	if(String.isNotBlank(parentCatId))
	 	{
	 		Category_Tree__c parentCat =  Database.query(EBH_ConstantsUtility.SOQL_CAT_TREE + ' Where Id=:parentCatId');
	 		Integer currentCatLevel = parentCat.Level_auto__c >3 ? 3 : Integer.valueOf(parentCat.Level_auto__c);
	 		
		 	for(PathItem f : mapFieldPathLevel.get(currentCatLevel))
		 	{
		 		f.name = ApexUtil.getValue(f.fname,parentCat)+'';
		 		f.id = ApexUtil.getValue(f.fId,parentCat)+'';
		 		listPath.add(f);
		 	}
	 	} 
	 	
	 	return listPath;
	 }
	 
	private static CatItem populateItem(Category_Tree__c cat)
	{
		
		if(cat.Level_auto__c<3)
		{
			return new CatItem(cat.Id,cat.Name,null,Integer.valueOf(cat.Level_auto__c));
		}
		//else
		CatItem parent0 = new CatItem(cat.Note_ID__r.Note_ID__r.Note_ID__c,cat.Note_ID__r.Note_ID__r.Note_ID__r.Name,null,Integer.valueOf(cat.Note_ID__r.Note_ID__r.Note_ID__r.Level_auto__c));
		CatItem parent1 = new CatItem(cat.Note_ID__r.Note_ID__c,cat.Note_ID__r.Note_ID__r.Name,null,Integer.valueOf(cat.Note_ID__r.Note_ID__r.Level_auto__c));
		CatItem parent2 = new CatItem(cat.Note_ID__c,cat.Note_ID__r.Name,parent0,Integer.valueOf(cat.Note_ID__r.Level_auto__c));
		//system.debug('>>>parent0: '+parent0);
		//system.debug('>>>parent1: '+parent1);
		
		return new CatItem(cat.Id,cat.Name,parent2,Integer.valueOf(cat.Level_auto__c));
	}
	
	/*****************************************************************************************************************************
	@ Method:   apexSaveCat
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  US-0007356 - LTTM - Select the BoB Category for the Cohort
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      parentBoBId,   listSelectedCat
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 29.03.2020 / Vadhanak Voun / Created the  Method.
	*****************************************************************************************************************************/
	 @AuraEnabled
	 public static Map<String,Object> apexSaveCat(String parentBoBId,List<String> listSelectedCat)
	 {
	 	Map<String,Object> mapResult = new Map<String,Object>();
	 	 
	 	try
	 	{	
	 		List<BoB_Category__c> listToUpsert = new List<BoB_Category__c>();
	 		for(String itemId:  listSelectedCat)
	 		{
	 			listToUpsert.add( new BoB_Category__c(BoB__c=parentBoBId,Category__c=itemId,External_Id__c=parentBoBId+'_'+itemId));
	 		}
	 		
			upsert listToUpsert External_Id__c;
			
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
	
	@testVisible 
	public class CatItem{ // 14.06.2023 / Sophal Noch / US-0013712 : make inner class public for reusability in child class CouponCategoryController
		
		@AuraEnabled
		public String catId;
		
		@AuraEnabled
		public String catName;
		
		@AuraEnabled
		public CatItem parent;
		
		@AuraEnabled
		public Integer level;
		
		@AuraEnabled
		public Boolean checked = false; // checkbox checked (maybe still on the left) 
		
		@AuraEnabled
		public Boolean selected = false; //already moved to the right

		@AuraEnabled
		public Coupon_Category__c couponCat; // 14.06.2023 / Sophal Noch / US-0013712 : create property for child class CouponCategoryController
		
		@AuraEnabled
		public Contract_Category__c contractCat; // SB 31.05.2024 US-0015241

		public CatItem(){}
		
		public CatItem(String catId,String catName,CatItem parent,Integer level)
		{
			this.catId = catId;
			this.catName = catName;
			this.parent = parent;
			this.level = level;
		}
	}	
	
	@testVisible
	public class PathItem{ // 14.06.2023 / Sophal Noch / US-0013712 : make inner class public for reusability in child class CouponCategoryController
		@AuraEnabled
		public String name; //value
		
		public String fname; //field name
		
		@AuraEnabled
		public String id;
		
		public String fId; //field id
		
		@AuraEnabled
		public Integer level;
		
		public PathItem(){}
		
		public PathItem(String fname,String fId,Integer level)
		{
			this.fname = fname;
			this.fId = fId;
			this.level = level;
		}
	}
}