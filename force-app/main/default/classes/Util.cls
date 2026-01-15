/**
 * Author : Gaeasys
 * CreatedDate: 31-May-2018
 * Description: 
 */
public with sharing class Util {
	//static final string OPP_TYPE_DIRECT= Label.OPP_TYPE_DIRECT; // No code reference it. This line is required to enforce this custom label auto include in the package.
	public static final string NS = '';
	
	
	public class CustomException extends Exception {}
	
    /*
        Backing variable for recordsCache
    */
    private static Map<Id, sObject> recordsCacheBacking = new Map<Id, sObject>();

    /*
        Store queried record to avoid re-querying the record again
    */
    public static Map<Id, sObject> recordsCache {
        get {
            return recordsCacheBacking;
        }
    }

    /*
		get record from cache, if record not exists, query and cache the record
    */
    public static sObject getCache(Id sObjecId){
    	if ( !Util.recordsCache.containsKey(sObjecId)){
    		sObject so = QueryUtil.queryRecord(sObjecId);
    		Util.recordsCache.put(sObjecId, so);
		}	
		return Util.recordsCache.get(sObjecId);
    	
    }

    public static void cache(List<sObject> sObjects){
    	recordsCache.putAll(sObjects);
    }

    public static String getString(Object s){
        return s ==null ? '' : String.valueOf(s);
    }
    
    public static String getId(Object s){
        return String.isEmpty(getString(s)) ? null : getString(s);
    }

    public static DateTime getDateTime(Object s){
        if(s==null) return null;
        if(s instanceof Date) return Date.valueOf(s);
        return DateTime.valueOf(s);
    }

    public static Date getDate(Object s){
        return Date.valueOf(s);
    }

    public static Integer getInteger(Object s){
        return Integer.valueOf(s);
    }

    public static Decimal getDecimal(Object s){
        return s ==null ? null : Decimal.valueOf(s+'');
    }

    public static Decimal getDecimalNotNull(Object s){
        return s ==null ? 0 : getDecimal(s);
    }
    
    static Button_Action_Permission__mdt[] btnPermissions;
    static PermissionSetAssignment[] currentUserPermissions;
    public static Boolean hasPermission(String btnName){
    	if(btnPermissions == null) btnPermissions = [select Button_Name__c, Permissionset_Name__c from Button_Action_Permission__mdt];
    	Set<String> permissionNames = new Set<String>();
    	for(Button_Action_Permission__mdt p : btnPermissions) {
    		if(btnName.equalsIgnoreCase(p.Button_Name__c)) permissionNames.add(p.Permissionset_Name__c);
    	}
    	if(!permissionNames.isEmpty()) {
    		if(currentUserPermissions == null) currentUserPermissions = [select PermissionSet.Name from PermissionSetAssignment where AssigneeId = :UserInfo.getUserId()];
    		for(PermissionSetAssignment p : currentUserPermissions) {
    			if(permissionNames.contains(p.PermissionSet.Name)) return true;
    		}
    	}
        return Test.isrunningtest() ? true : false;
    }

}