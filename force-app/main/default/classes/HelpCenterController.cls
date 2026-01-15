/*********************************************************************************************************************************
@ Class:         HelpCenterController
@ Version:       1.0

----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.12.2024 / Vimean Heng / US-0016088 - Help Center Page Layout and Quick Links and FAQ Section - Part 2

*********************************************************************************************************************************/
public with sharing class HelpCenterController {

    private static String sqlKnowledge = 'SELECT UrlName,IconURL__c,Title,Summary, Icon__c,PublishStatus  FROM Knowledge__kav where Added_In_Help_Page__c = true AND PublishStatus =:status AND RecordType.DeveloperName =:recordType';
    private static String sqlHCConfig = 'SELECT Field_Order__c, Limit__c,Icon_Url__c,Use_Standard_Icon__c,Icon_Name__c,Link__c,Priority__c,Description__c,Title__c FROM Help_Center_Config__mdt';
    private static String recTypeFAQ = 'FAQ';
    private static String recTypeRegularRequest = 'Regular_Request';
    private static String lblDefault = 'Default';

    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getAllKnowledge()
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        try {
            mapResult.put(recTypeFAQ, getAllKnowledgeByRecordType(recTypeFAQ));
            mapResult.put(recTypeRegularRequest, getAllKnowledgeByRecordType(recTypeRegularRequest));
            mapResult.put('status','ok');
        } catch (Exception e) {
            mapResult.put('status','ko');
            mapResult.put('error',e.getMessage());
            mapResult.put('errorDetail',e.getStackTraceString());
        }
        return mapResult;
    }
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getHelpCenterConfigByDeveloperName(String name){
        Map<String,Object> mapResult = new Map<String,Object>();
        try{
            mapResult.put('result', getHelpCenterConfig(getSqlHCCByName(),name));
            mapResult.put('status','ok');
        } catch (Exception e) {
            mapResult.put('status','ko');
            mapResult.put('error',e.getMessage());
            mapResult.put('errorDetail',e.getStackTraceString());
        }
        return mapResult;
    }
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getHelpCenterConfigByLabel(String name){
        Map<String,Object> mapResult = new Map<String,Object>();
        try{
            mapResult.put('result', getHelpCenterConfig(getSqlHCCByLabel(),name));
            mapResult.put('status','ok');
        } catch (Exception e) {
            mapResult.put('status','ko');
            mapResult.put('error',e.getMessage());
            mapResult.put('errorDetail',e.getStackTraceString());
        }
        return mapResult;
    }
    private static List<Help_Center_Config__mdt>  getHelpCenterConfig(String sql ,String name){
        List<Help_Center_Config__mdt> lsAllKnowledge = (List<Help_Center_Config__mdt>) ApexSafe.query().doQuery(sql,new Map<String, Object> {'name' => name});
        return lsAllKnowledge;
    }
    private static List<Knowledge__kav>  getAllKnowledgeByRecordType(String recordType){
        String orderBy = getOrderAndLimit();
        List<Knowledge__kav> lsAllKnowledge = (List<Knowledge__kav>) ApexSafe.query().doQuery(sqlKnowledge + orderBy,new Map<String, Object> {'status' => 'Online','recordType' => recordType});
        return lsAllKnowledge;
    }
    private static Help_Center_Config__mdt getDefaultHelpCenterConfig(){
        List<Help_Center_Config__mdt> lsAllHCC = getHelpCenterConfig(getSqlHCCByName(),lblDefault);
        return !lsAllHCC.isEmpty() ? lsAllHCC[0] : null;
    }
    private static String getOrderAndLimit(){
        String orderField = getDefaultOrderField();//default
        String strLimit = '';
        Help_Center_Config__mdt hcConfig = getDefaultHelpCenterConfig();
        if(hcConfig != null){
            orderField = String.isNotBlank(hcConfig.Field_Order__c) ? hcConfig.Field_Order__c : ''; //defined in metadata Help_Center_Config__mdt Help_Center_Config__mdt
            strLimit = hcConfig.Limit__c != null && hcConfig.Limit__c > 0 ? (' LIMIT ' + hcConfig.Limit__c) : ''; 
        }
        return ' ORDER BY ' + orderField + strLimit; //default ASC
    }
    private static String getSqlHCCByLabel(){
        return sqlHCConfig + ' WHERE Label =:name';
    }
    private static String getSqlHCCByName(){
        return sqlHCConfig + ' WHERE DeveloperName =:name';
    }
    private static String getDefaultOrderField(){
        return 'Title';
    }
}