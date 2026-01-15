public with sharing class GW_sObject {
	private static Map<String, Schema.SObjectType> globalDescMapBacking;
    public static Map<String, Schema.SObjectType> globalDescMap { 
        get { 
            if (globalDescMapBacking == null) {
                globalDescMapBacking = Schema.getGlobalDescribe();
            }
            return globalDescMapBacking;  
        } 
    }
    static Map<String, Schema.DescribeFieldResult> mapFieldResult = new Map<String, Schema.DescribeFieldResult>();
    
    public static Boolean isFieldChanged(sObject so, sObject oldSo, String field) {
        return GW_sObject.oneOrMoreFieldsChanged(so, oldSo, new Set<String>{field});
    }

    public static Boolean oneOrMoreFieldsChanged(sObject so, sObject oldSo, Set<String> fields) {
        String sObjName = so.getSObjectType().getDescribe().getName();
        for (String field : fields) {
            if ( !GW_sObject.fieldExists( sObjName, field) ) throw new Util.CustomException('Invalid field specified: ['+sObjName+'.'+field+']');
            if (oldSo == null){
                return so.get(field) != null && !String.isEmpty(String.valueOf(so.get(field)));
            }
            else {
                Object fieldValue = (String.valueOf(so.get(field)) == '') ? null : so.get(field);
                Object oldFieldValue = (String.valueOf(oldSo.get(field)) == '') ? null : oldSo.get(field);
                if ( fieldValue <> oldFieldValue ) return true;
            }
        }
        return false;
    }
    
    public static Boolean fieldExists(String objectName, String fieldName) {
        String mapObjectFieldKey = objectName + fieldName;
        if ( mapFieldResult.containsKey(mapObjectFieldKey) ) return true;
        else {
            Schema.DescribeSObjectResult r = getSObjectDescribe(objectName);
            Map<String, Schema.SObjectField> fields = r.fields.getMap();
            Schema.SObjectField sfield = fields.get(fieldName);
            if (sfield == null) return false;
            return true;
        }
    }


    /**
     * @param sObjs: a list of record contains parent id
     * @param parentFieldName : field name of parent id
     * @return : a map contains parent mapping to its children 
     */
    public static Map<Id, List<SObject>> getMapChildren(List<sObject> sObjs, String parentFieldName){
        Map<Id, List<SObject>> mapChildren = new Map<Id, List<SObject>>();
        for(sObject sObj: sObjs){
            Id parentId = (Id) sObj.get(parentFieldName);
            // skip record if there is not parent id
            if( parentId==null ) continue;
            
            if( !mapChildren.containsKey(parentId) ) mapChildren.put( parentId, new List<sObject>());

            mapChildren.get(parentId).add(sObj);
        }
        return mapChildren;
    }

    /**
     * @param sObjs: a list of record 
     * @param fieldName : field to get value
     * @return : values from field of sObjs list, exclude null
     */
    public static Set<String> getIds(List<sObject> sObjs, String fieldName){
        Set<String> values = new Set<String>();
        for(sObject sObj: sObjs){
            String value = (String) sObj.get(fieldName);
            if( value!=null)
                values.add(fieldName);
        }
        return values;
    }

    
    // describe methods
    public static Schema.DescribeSObjectResult getSObjectDescribe(String objectName) {
        Schema.SObjectType SObjectTypeObj = globalDescMap.get(objectName);
        if (SObjectTypeObj == null) throw new Util.CustomException('Exception in GW_sObject: getSObjectDescribe() - ObjectName: \'' + objectName + '\' does not exist');
        return SObjectTypeObj.getDescribe();
    }
    
    public static Object getFieldValueAsObject(Sobject sobj, String fieldName) {
        if (fieldName.contains('.')) {
            List<String> fieldNames = fieldName.split('\\.');
            Sobject sobjectRelation = sobj;
            for (Integer i = 0; i < fieldNames.size() - 1; i++) {
                sobjectRelation = sobjectRelation.getSObject(fieldNames[i]);
                if (sobjectRelation == null) return null; 
            }
            return sobjectRelation.get(fieldNames[fieldNames.size() - 1]);
        }
        return sobj.get(fieldName);
    }
    
    public static SObject getFieldSObject(SObject sobj, String fieldName) {
        if (fieldName.contains('.')) {
            List<String> fieldNames = fieldName.split('\\.');
            return sobj.getSObject(fieldNames[0]) == null ? null : sobj.getSObject(fieldNames[0]).getSObject(fieldNames[1]);
        }
        return sobj.getSObject(fieldName);
    }
}