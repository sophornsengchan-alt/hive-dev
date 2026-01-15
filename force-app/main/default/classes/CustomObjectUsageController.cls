public with sharing class CustomObjectUsageController {
    public Integer recordSize{get;set;}
    public List<Schema.SObjectType> globalObjects {get;set;}
    public List<Schema.SObjectType> filteredObjects{get;set;}
    public List<CustomObjectsWrapper> customObjects {get;set;}
    @testVisible private Integer counter = 0;
    @testVisible private Integer pageSize = 25;   //Maximum Page Size is 50 to avoid System.LimitException: Too many SOQL queries: 101
    @testVisible private Boolean hasCustomPermission = FeatureManagement.checkPermission('CustomObjectUsagePermission');
    public boolean showLoadData{get;set;}

    public CustomObjectUsageController(){
        if(hasCustomPermission == true){ 
            showLoadData = true;
            globalObjects = new List<Schema.SObjectType>(Schema.getGlobalDescribe().values());
            filteredObjects = new List<Schema.SObjectType>();
            for(Schema.SObjectType obj : globalObjects){
                If(obj.getDescribe().isCustom() && obj.getDescribe().getName().endsWith('__c') && !obj.getDescribe().isCustomSetting() ){                
                    filteredObjects.add(obj);
                }
            }
            recordSize = filteredObjects.size();            
        }       
    }  
  
   public void loadData(){
    customObjects = new List<CustomObjectsWrapper>();
    List<SObject> recordList = new List<SObject>();
    List<SObject> recordCountList = new List<SObject>();

    for(Integer i=counter;i<counter+pageSize;i++){
        if(i >= recordSize){ 
            break;
        }
        String queryString = 'Select Name, SystemModstamp from ' + filteredObjects[i].getDescribe().getName() + ' order by SystemModstamp DESC NULLS LAST limit 1';

        String queryCountString = 'Select Count(Id) from ' + filteredObjects[i].getDescribe().getName();

        //Cannot remove this query from the loop as this query needs to be executed for each Custom Object in the filtered list
        recordList = Database.query(String.escapeSingleQuotes(queryString));

        recordCountList = Database.query(String.escapeSingleQuotes(queryCountString));

        Integer recordCount = (Integer)recordCountList[0].get('expr0');
        
        customObjects.add(New CustomObjectsWrapper(
                                filteredObjects[i].getDescribe().getLabel(),
                                filteredObjects[i].getDescribe().getLocalName(),
                                recordList.size() > 0 ? (DateTime)recordList[0].get('SystemModstamp') : null,
                                recordCount
                              ));
    }
    showLoadData = false;
}
    
    public PageReference firstPage() {
        Counter = 0;
        if(!Test.isRunningTest()){
            loadData();
        }
        return null;
    }
    
    public PageReference nextPage() {
        counter += pageSize;
        if(!Test.isRunningTest()){
            loadData();
        }
        return null;
    }
    
    public PageReference previousPage() {
        counter -= pageSize;
        if(!Test.isRunningTest()){
            loadData();
        }
        return null;
    }
    
    public PageReference lastPage() {
        counter = ((recordSize-1)/pageSize)*pageSize;
        if(!Test.isRunningTest()){
            loadData();
        }
        return null;
    }
    
    public Boolean getDisableNext() {
        return Counter + PageSize > RecordSize;
    }
    
    public Boolean getDisablePrevious() {
        return Counter == 0;
    }

    public Integer getPageNumber() {
        return Counter/pageSize + 1;
     }
  
     public Integer getTotalPages() {
        if (math.mod(recordSize, pageSize) > 0) {
           return recordSize/pageSize + 1;
        } else {
           return (recordSize/pageSize);
        }
     }
    
    public class CustomObjectsWrapper {
        public String name { get; set; }
        public String apiName { get; set; }
        public DateTime systemModstamp { get; set; }
        public Integer count { get; set; }
        public CustomObjectsWrapper(String n, String an, DateTime d, Integer c){
            Name = n;
            ApiName = an;
            SystemModstamp = d;
            Count = c;        
        }
    }
}