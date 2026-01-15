/*********************************************************************************************************************************
@ Class:          LPC_KeyValuesTreeController
@ Version:        1.0
@ Author:         Mony Nou
@ Purpose:         
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.04.2021 / Mony Nou  / US-0009142 - Optimize UX to display 'tree' structure of keyvalues
@				  30.06.2021 / Mony Nou  / US-0009782 - Key not pulled from parent__c record
*********************************************************************************************************************************/
public without sharing class LPC_KeyValuesTreeController {
    
    //These variables are for dynamic soql query
	private static String keyId;
	private static String valueSearch;
	private static Set<Id> valueIds;

	/**
     * Get GAM_Key_Value__c (Record Type = Value)  records and transform into Tree Structure for Lightning:TreeGrid
     * @param kId, GAM_Key_Value__c (Record Type = Key) Id
     * @param vSearch, Search text
	 * @param isParent, Flag to indicate whether retrive Parent or Child Tree Structure
     * @return Map<String,Object> 
     */
	@AuraEnabled
    public static Map<String,Object> getGAMValueTreeStructure(String kId, String vId, String vSearch, Boolean isParent) {
		
        keyId = kId;
		valueIds = new Set<Id>();
		if (String.isNotBlank(vId)) valueIds.add(Id.valueOf(vId));

		valueSearch = '\'%' + String.escapeSingleQuotes(vSearch) + '%\'';
		
		Map<String,Object> mTree = initTreeAttribute(); //Init the default TreeGrid Attribute
		
		List<Map<String,Object>> listColumn = (List<Map<String,Object>>) mTree.get('columns'); //Column to display on TreeGrid
		
		List<String> fieldApi = (List<String>) mTree.get('fieldApi'); //Field API that need to query
		
		// String child_query = (isParent)?'':' AND Parent_Node__c IN:valueIds'; //additional criteria when get records for Child Node

		String par_child_query = (isParent)?' (Parent__c =:keyId OR Parent_Node__c =:keyId OR Parent_Node__r.Parent__c =:keyId OR Parent_Node__r.Parent_Node__c =:keyId)':' Parent_Node__c IN:valueIds'; //MN-04062021-US-0009613 

		String soql = (String) mTree.get('query'); //Dynamic SOQL 
        soql += ' WHERE' + par_child_query + ' AND (Name LIKE ' + valueSearch + ' OR Disaplay_Name__c LIKE ' + valueSearch + ') ORDER BY Disaplay_Name__c';


        Map<Id,Boolean> temp = new Map<Id,Boolean>(); // to store the GAM_Key_Value__c that is PARENT Node
		Map<Id, GAM_Key_Value__c> mapGAMValues = new Map<Id, GAM_Key_Value__c>();
		Set<Id> sTemp = new Set<Id>();
		List<GAM_Key_Value__c> lstGAMValues = new List<GAM_Key_Value__c>();

		if (isParent) {

			for(GAM_Key_Value__c val :  Database.query(soql)) {
				val.Disaplay_Name__c = val.Disaplay_Name__c + ' ( ' + val.Disaplay_Name__c + ' ) '; //Keep the old functionality structure Ex: Value1 (Value1)

				
				
				/* //MN-30062021-US-0009782
					- Since Parent_Node__c is able to populate both Key and Value => below are condition that Tree will display
						1) GAM Values that Parent__c match the selected Key on Targeting KeyValue Screen
						2) GAM Values that Parent_Node__c match the selected Key on Targeting KeyValue Screen
						3) GAM Values that has Parent_Node__r.Parent__c match the selected Key on Targeting KeyValue Screen
						4) GAM Values that has Parent_Node__r.Parent_Node__c match the selected Key on Targeting KeyValue Screen
				*/

				if(val.Parent_Node__c != null) { 
					
					//Check first if Parent_Node__c has any relation with keyId, if yes => store in temp to find a Parent Node, if no => display as 1st level
					if (val.Parent_Node__c == keyId || (val.Parent_Node__c != keyId && val.Parent_Node__r.Parent__c != keyId && val.Parent_Node__r.Parent_Node__c != keyId)) mapGAMValues.put(val.Id, val);
					else temp.put(val.Parent_Node__c ,true); 

					// temp.put(val.Parent_Node__c ,true); //original 
				}

				else { mapGAMValues.put(val.Id, val); }
	
				//This is condition for Search Feature - when we search some value and the return Result are the child Values of other
				sTemp.add(val.Id);
				if (String.isNotBlank(vSearch) && !sTemp.contains(val.Parent_Node__c) && !mapGAMValues.containsKey(val.Id)) {
					mapGAMValues.put(val.Id, val);
				}
			}

			lstGAMValues = mapGAMValues.values();

		}else {
			//Child Value
			/*
				>Value 1
				>Value 2
			*/
			lstGAMValues = Database.query(soql);
			valueIds.clear();
			for(GAM_Key_Value__c val :  lstGAMValues) { 
				val.Disaplay_Name__c = val.Disaplay_Name__c + ' ( ' + val.Disaplay_Name__c + ' ) ';
				valueIds.add(val.Id); //Collect Developer's childrend Id to its children 
			} 

			//find grand child of Value's childrens
			/*
			>Value 1.1
			>Value 2.1
			*/
			for(GAM_Key_Value__c val: Database.query(soql)){ temp.put(val.Parent_Node__c, true); }
		}
        

		List<Map<String,Object>> gridData = mapGridData(fieldApi, lstGAMValues, temp);
        Map<String,Object> mapResult = new Map<String,Object>{
            'Column'=> listColumn,
            'Griddata' => gridData,
            'Query' => soql
        };

        return mapResult;
    }
	
	/**
     * 
     */
    private static Map<String,Object> initTreeAttribute() {

        String soql='SELECT Id, Name,Disaplay_Name__c,Parent_Node__c, Parent__c, Parent_Node__r.Parent_Node__c, Parent_Node__r.Parent__c FROM GAM_Key_Value__c';

        Map<String,Object> mO =new Map<String,Object>();
        List<Map<String,Object>> listColumn = new List<Map<String,Object>>();
		List<String> fieldApi = new List<String>{'Name','Disaplay_Name__c'};
		listColumn.add(new Map<String, Object>{ 'type' => 'text', 'fieldName' => 'Disaplay_Name__c', 'label' => 'Value(s)'}); 

        mO.put('columns', listColumn);
        mO.put('fieldApi', fieldApi);
        mO.put('query', soql);
        return mO;
    }

	/**
     * Transform GAM_Key_Value__c sObject Record into Object for TreeGrid Structure
     * @param fieldApi, list with GAM_Key_Value__c's field api
	 * @param listGAMValues, list of GAM_Key_Value__c records
	 * @param hasChild, map to track whether the GAM_Key_Value__c has child records link to it
     * @return List<Map<String,Object>>
     */
	private static List<Map<String,Object>> mapGridData(List<String> fieldApi, List<GAM_Key_Value__c> listGAMValues, Map<Id,Boolean> hasChild){

        List<Map<String,Object>> gridData = new List<Map<String,Object>>();
        Map<String,Object> rec;
        for (GAM_Key_Value__c val : listGAMValues) {
            
			rec = new Map<String,Object>();
            rec.put('urlId', '/'+val.Id); // for redirect record on tree
			rec.put('Id',val.Id);
			rec.put('isAS',false);
            
            for(String col : fieldApi) { rec.put(col,val.get(col)); }                
            
			// create child node
            if(hasChild.containsKey(val.Id)) rec.put('_children',new Map<String,Object>());           

            gridData.add(rec);
        }
        return gridData;
    }

}