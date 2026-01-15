public with sharing class QueryUtil {
    public static List<sObject> queryRecords(String sObjectName, String whereClause, Set<String> additionalFields, Set<String> ids, Map<String,Object> biddingValues, String queryPostfix ){
    	// Use set to avoid duplicate field
        Set<String> fields =  new Set<string>();
    	
    	try {
            for(String field:getSObjectFields(sObjectName)){
                // avoid duplicate field with unmanage package, remove namespace and add to Set
                fields.add(field.replaceAll('(?i)^'+Util.NS,'').toLowerCase());
            }
    	} catch(NullPointerException ex) {
    		throw new Exceptiongroup.CustomException('Invalid sObject name: ' + sObjectName);
    	}
    	if( additionalFields!=null ) fields.addAll(additionalFields);

    	if( ids!=null && !ids.isEmpty()) {
    		whereClause = String.isBlank(whereClause) ? ' Id in :ids' : ' AND Id in :ids'; 
    	}
    	whereClause = String.isBlank(whereClause)? '' : ' WHERE ' + whereClause;

    	whereClause += String.isBlank(queryPostfix) ? '': ' ' + queryPostfix;
    	//In case we need a query with value binding, please specific in where clause, ConditionObject can be list or simple value
    	// ex: queryRecords('Opportunity', 'Name in: value1', null, null, new Map<String,Object>{'value1'=>ConditionObject})
    	Object value1 = biddingValues != null ? biddingValues.get('value1') : null;
        Object value2 = biddingValues != null ? biddingValues.get('value2') : null;
        Object value3 = biddingValues != null ? biddingValues.get('value3') : null;

    	String body =  String.join(new List<String>(fields), ',') ;
    	//if( String.isNotBlank(childQuery) ) body += ', ' + childQuery;
    	String query = 'SELECT ' + body + ' FROM ' + sObjectName + whereClause;
    	return Database.query(query);
    }

    public static List<sObject> queryRecords(String sObjectName, String whereClause, Set<String> additionalFields, Set<String> ids ){
    	return queryRecords(sObjectName, whereClause, additionalFields, ids,null,null);
    }
    
    public static List<sObject> queryRecords(String sObjectName, String whereClause, Set<String> additionalField , Map<String,Object> biddingValues, String queryPostfix){
    	return queryRecords(sObjectName, whereClause, additionalField, null,biddingValues, queryPostfix);
    }

    public static List<sObject> queryRecords(String sObjectName, String whereClause, Set<String> additionalField , Map<String,Object> biddingValues){
    	return queryRecords(sObjectName, whereClause, additionalField, null,biddingValues, null);
    }

    public static List<sObject> queryRecords(String sObjectName, Set<String> additionalField, Set<String> ids){
    	return queryRecords(sObjectName, null, additionalField, ids);
    }

    public static List<sObject> queryRecords(String sObjectName, String whereClause, Map<String,Object> biddingValues){
    	return queryRecords(sObjectName, whereClause, null, null,biddingValues, null);
    }

	public static List<sObject> queryRecords(String sObjectName, String whereClause){
    	return queryRecords(sObjectName, whereClause, null, null,null,null);
    }

    public static List<sObject> queryRecords(String sObjectName, Set<String> ids){
    	return queryRecords(sObjectName, null, null, ids);
    }

    public static List<sObject> queryRecords(String sObjectName){
    	return queryRecords(sObjectName, null, null, null,null,null);
    }
    
    public static sObject queryRecord(Id sObjecId, Set<String> additionalFields){
        String sObjectName = QueryUtil.getObjectNameById(sObjecId);
        if( sObjectName ==null ) return null;
    	List<sObject> records = queryRecords(sObjectName, additionalFields , new Set<String>{sObjecId});
    	return records.isEmpty()? null : records.get(0);
    }

    public static sObject queryRecord(Id sObjecId){
    	return queryRecord(sObjecId, null);
    }

    public static List<sObject> queryRecordsWithChildren(String sObjectName, String whereClause, String childRelationshipName, Set<String> ids){
    	String childSOType;
    	try {
    		for(Schema.ChildRelationship childRelationship: Schema.getGlobalDescribe().get(sObjectName).getDescribe().getChildRelationships()){
	    		if (childRelationship.getrelationshipname() == childRelationshipName){
	                childSOType = childRelationship.getChildSObject().getDescribe().getName();
	                break;
	    		}
	    	}
    	} catch(NullPointerException ex) {
    		throw new Exceptiongroup.CustomException('Invalid child relationship name: ' + childRelationshipName);
    	}
    	
    	Set<String> childFields = new Set<String>();
        for(String field:getSObjectFields(childSOType)){
            // avoid duplicate field with unmanage package, remove namespace and add to Set
            childFields.add(field.replaceAll('(?i)^'+Util.NS,'').toLowerCase());
        }
    	String childQuery  = ' (SELECT ' + String.join(new List<String>(childFields), ',') + ' FROM ' + childRelationshipName + ') ';

    	return queryRecords(sObjectName, whereClause, new Set<String>{childQuery}, ids, null, null  );
    }

    /*
		Get all fields of sObject by sObject name
    */
    public static Set<String> getSObjectFields(String sObjectName){
    	return Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().keyset();
    }

    public static String getQueryFieldString(String sObjectName){
        Set<String> fields =  new Set<string>();
        try {
            for(String field:getSObjectFields(sObjectName)){
                // avoid duplicate field with unmanage package, remove namespace and add to Set
                fields.add(field.replaceAll('(?i)^'+Util.NS,'').toLowerCase());
            }
        } catch(NullPointerException ex) {
            throw new Exceptiongroup.CustomException('Invalid sObject name: ' + sObjectName);
        }
        return String.join(new List<String>(fields), ',');
    }

    public static String getObjectNameById(Id sObjecId){
        String objectName;
        try {
            objectName = sObjecId.getSObjectType().getDescribe().getName();
        } catch(Exception ex) {
            return null;
        }
    	return objectName;
    }

    public static Set<String> toStringSet(Set<Id> ids){
        Set<String> strings = new Set<String>();
        for(Id i: ids){
            strings.add(i);
        }
        return strings;
    }
}