/*********************************************************************************************************************************
@ Class:          LookupController
@ Version:        1.0
@ Author:         vadhanak voun  (vadhanak.voun@gaea-sys.com)
@ Purpose:         
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: xx.xx.xxxx / vadhanak voun / Created the class.
				: 15.10.2023/ vadhanak voun / US-0014270 - HoneyComb Work Manager
				: 04.11.2023/ vadhanak voun / US-0014370 - HoneyComb Work Manager - part2
*********************************************************************************************************************************/
public without sharing class LookupController {
	
	private final static String MAIN_SOQL = 'Select Id,$e1,$e2,$e3 From $sobjType';

    @AuraEnabled
    public static List<DisplayEntity> doSearch(String sobjType,String key,String displayEntity1,String displayEntity2,String displayEntity3)
    {

			// Acmatac SEING, 17/03/2022 US-0011204 - Add String.escapeSingleQuotes
			sobjType = String.escapeSingleQuotes(sobjType);
			displayEntity1 = String.escapeSingleQuotes(displayEntity1);
			displayEntity2 = String.escapeSingleQuotes(displayEntity2);
			displayEntity3 = String.escapeSingleQuotes(displayEntity3);

	       List<DisplayEntity> result = new List<DisplayEntity>();
	       //first row on the result to go to search
	       DisplayEntity searchItem = new DisplayEntity();
	       searchItem.entityId = 'search'; 
	       searchItem.displayEntity2 = key.replace('%','');
	       result.add(searchItem);
	       //system.debug('>>key:'+key);

		   //NK:15/10/2023:US-0014270
	       String soql = String.isBlank(searchItem.displayEntity2)?MAIN_SOQL+' WHERE LastViewedDate !=null ORDER BY LastViewedDate DESC LIMIT 5':MAIN_SOQL+ ' Where Name LIKE :key LIMIT 10';
		
	       //soql = soql.replace('$e1',displayEntity1).replace('$e2',displayEntity2).replace('$e3', (String.isNotBlank(displayEntity3)?','+displayEntity3:'') ).replace('$sobjType',sobjType);
		   soql = soql.replace('$e1',displayEntity1)
		   .replace(',$e2',String.isNotBlank(displayEntity2)?','+displayEntity2:'')
		   .replace(',$e3', (String.isNotBlank(displayEntity3)?','+displayEntity3:'') )
		   .replace('$sobjType',sobjType);

	       system.debug('>>soql:'+soql);
	       for(SObject obj:Database.query(soql))
	       {
	       		DisplayEntity item = new DisplayEntity();
	   			item.entityId = obj.Id;
				//NK:15/10/2023:US-0014270
	   			item.displayEntity1 = String.isBlank(displayEntity1)?'':ApexUtil.getValue(displayEntity1,obj)+''.replace('null',''); 
				item.displayEntity2 = String.isBlank(displayEntity2)?'':ApexUtil.getValue(displayEntity2,obj)+''.replace('null','');  
				item.displayEntity3 = String.isBlank(displayEntity3)?'': String.isNotBlank(displayEntity3)?ApexUtil.getValue(displayEntity3,obj)+''.replace('null',''):'';  
	       		result.add(item);	 
	       }
	       
	       return result;
      }
      
	@AuraEnabled
    public static  List<DisplayEntity> doFullSearch(String sobjectType,String key,String fullSearchFields,String sortClause)
    {	
    	//system.debug('>>>>>>>:fullSearchFields0: '+fullSearchFields);
    	//system.debug('>>>>>>>:fullSearchFields1: '+fullSearchFields[0]);
    	List<MyField> fieldList = (List<MyField>) JSON.deserialize(fullSearchFields, List<MyField>.class);

    	//system.debug('>>>>>>>:m: '+m);
    	
    	List<DisplayEntity> result = new List<DisplayEntity>();
    	String soql = 'Select Id,Name,';
    	
    	 
		for(MyField f: fieldList)
		{
			if(f.name=='Id' || f.name=='Name')continue;
			soql+=f.name+',';
		}
		
		//key = '%'+key.trim()+'%';
		key = '%'+key.trim()+'%';

		// Acmatac SEING, 17/03/2022 US-0011204 - Add String.escapeSingleQuotes
		// soql = soql.removeEnd(',') + ' From '+sobjectType + ' WHERE Name LIKE :key '+sortClause;
		soql = soql.removeEnd(',') + ' From '+ String.escapeSingleQuotes(sobjectType) + ' WHERE Name LIKE :key '+String.escapeSingleQuotes(sortClause);
		
		//system.debug('>>>>>>>:soql: '+soql);
		
        for(SObject obj:Database.query(soql +' LIMIT 100'))
        {
        	DisplayEntity item = new DisplayEntity();
        	item.entityId = obj.Id;
        	item.entityName = ApexUtil.getValue('Name', obj)+''.replace('null','');
        	item.listValues = new List<String>();
        	 
        	for(MyField f : fieldList)
			{
				item.listValues.add((ApexUtil.getValue(f.pname,obj)+'').replace('null',''));
			}
       		result.add(item); 
        }
        
        //system.debug('>>>>>>>:result: '+result);
        
         
    	return result;
    	
    }	   
    
    @AuraEnabled
    public static  List<Map<String,String>> describeFieldsType(String sobjectType,String strFullSearchFields)
    {
    	//System.debug('>>>>str:'+strFullSearchFields);
    	//TEXTAREA is not sortable
		List<Map<String,String>> deserializedList = (List<Map<String,String>>)JSON.deserialize(strFullSearchFields, List<Map<String,String>>.class);
		
		//System.debug(deserializedList);
		
		List<Map<String,String>> listResult = new List<Map<String,String>>();
		
		Map<String, Schema.SObjectField> ff = Schema.getGlobalDescribe().get(sobjectType).getDescribe().fields.getMap();
		
		Map<String,String> mapFieldType = new Map<String,String>();
		for(Schema.SObjectField f : ff.values()){
		    mapFieldType.put(f.getDescribe().getName(),f.getDescribe().getType()+'');
		}
		
		for(Map<String,String> m:deserializedList)
		{
			//System.debug(m);
			m.put('type',mapFieldType.get(m.get('pname')));
			 
			listResult.add(m);
		}
		
		  //System.debug('>>>listResult:'+listResult);
		  
		return listResult;
    }
    
	  public class DisplayEntity{
		@AuraEnabled
		public String displayEntity1;
		
		@AuraEnabled
		public String displayEntity2;

		@AuraEnabled
		public String displayEntity3;
		
		@AuraEnabled
		public String entityId;
		@AuraEnabled
		public String entityName;
		
		@AuraEnabled
		public String[] listValues; 
	  
	  }
	  
	   public class MyField{
		@AuraEnabled
		public String name;
		
		@AuraEnabled
		public String pname; //pure name without toLabe() for picklist field
		
		@AuraEnabled
		public String label;
		
	   }
}