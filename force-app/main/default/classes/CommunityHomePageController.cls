/*********************************************************************************************************************************
@ Class:          CommunityHomePageController
@ Version:        1.0
@ Author:         
@ Purpose:        
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 01.03.2019 /  / Created the class.
@ 				06.05.2020/Sovantheany Dim/ US-0007317 - [AU] Define User Views on GCX Portal
*********************************************************************************************************************************/
public without sharing class CommunityHomePageController {
	/****************************************************************************************************************************
	* CONSTANTS DEFINITION
	*****************************************************************************************************************************/
	private static String SOQL_CAMPAIGN = 'select id from Campaign';
	private final static String TASK_QUERY='SELECT Id[PLACEHOLDER],Description FROM TASK WHERE OWNERID =:userID [EXTRA_CLAUSE] ORDER BY Call_Back_Window_start__c ASC nulls last,Field_for_sorting__c ASC, call_attempts__c ASC NULLS FIRST  LIMIT :PageSize OFFSET :PageNumber';
	/************************************END CONSTANTS DEFINITION*************************************************************/
    public ID userID {get;set;} 
    public Integer RowCount { get; set; }   
    public Decimal PageCount { get; set; }
    public Integer PageNumber { get; set; }    
    public Integer PageNumberDisplay { get; set; }
    public Integer PageSize { get { return Integer.valueOf(Label.Community_Home_Page_Size); } }
    public list<string> filtervalues= new list<string>{'Campaign','Task'};
        public string filterStatus{ get; set; }    
    public string filterCallAttempts { get; set; }    
    public string filterRelatedTo { get; set; }    
    public String filterPriority { get; set; }    
    public Task taskFilter { get; set; }  
    public String communityURL {get;set;}
    public Set<String> sCampaign;
    public List<Task> Tasks { 
        
        get {
            System.debug('Tasks are asked' + TaskQuery);
            return  Database.query(TaskQuery);}
        
    }
    //TH: 06/05/2020:US-0007317 - [AU] Define User Views on GCX Portal
    public string selectedPriorityValue {get; set;}
    public List<SelectOption> getPriorityDescription() {
        //NK:25/06/2020: US-0007760 - [Hypercare Bug] [GCX] Campaign Priority not allocating correctly
        //From: EBH_PriorityDescription__c to Campaign_Priority__c
        Schema.DescribeFieldResult priorityDescription = Campaign.Campaign_Priority__c.getDescribe();  
        
 	 	List<SelectOption> options = new List<SelectOption>();
 	 	options.add(new SelectOption('','--None--'));
 	 	for (Schema.Picklistentry pl : priorityDescription.getPicklistValues())
        {
            options.add(new SelectOption(pl.getValue(),pl.getLabel()));
        }
 	 	return options;
  	}
	//End US-0007317
	
    public PageReference filterResults(){
        System.debug(taskFilter);
        String countQuery=EBH_ConstantsUtility.TASK_COUNTQUERY.replace('[EXTRA_CLAUSE]',buildWhereClause());      
        //System.debug('<<<<countQuery='+countQuery);  
        RowCount = Database.countQuery(countQuery);        
        System.debug('ROWCOUNT==' + RowCount);        
        return null;        
    }
    
    private String buildWhereClause(){
        String whereClause='';
        if (taskFilter!=null){
            if (taskFilter.Status!=null){
                WhereClause+=' AND Status=\''+taskFilter.Status+'\'' ;
            }
            if (taskFilter.Call_attempts__c!=null){
                
                WhereClause +=' AND Call_attempts__c=' +taskFilter.Call_attempts__c ;                            
            }
            if (taskFilter.WhatId!=null){
                WhereClause +=' AND WhatID=\'' +taskFilter.WhatID +'\'';
            }
            //TH: 06/05/2020:US-0007317 - [AU] Define User Views on GCX Portal
            if(!String.isEmpty(selectedPriorityValue)){
            	WhereClause +=' AND Related_Campaign__r.Campaign_Priority__c =\'' +selectedPriorityValue+'\'';
            }
            //End US-0007317
            if (taskFilter.Order_Priority__c!=null){
                WhereClause += 'AND Order_Priority__c='+taskFilter.Order_Priority__c;   
            }                
            if (taskFilter.Whoid!=null){
                WhereClause += 'AND Whoid=\''+taskFilter.Whoid +'\' ';
            }                            
            if (taskFilter.Call_Back_Window_start__c!=null){
                WhereClause += ' AND Call_Back_Window_start__c>='+ filterDate(taskFilter.Call_Back_Window_start__c) ;
            }   
            // US-0007986, 20-August-2020 => @amt
            if (String.isNotBlank(taskFilter.EBH_Account__c)){
                WhereClause +=' AND EBH_Account__c=\'' +taskFilter.EBH_Account__c +'\'';
            }
            //Loumang:11-08-2021-US-0010021 - [PL Adv] Ads PL Team Mate to be able to filter by “Mailing State” and “Timezone”
            if (String.isNotBlank(taskFilter.ContactMailingState__c )){
                WhereClause +=' AND ContactMailingState__c =\'' +taskFilter.ContactMailingState__c +'\'';
            }
            if (String.isNotBlank(taskFilter.ContactTimeZone__c)){
                WhereClause +=' AND ContactTimeZone__c=\'' +taskFilter.ContactTimeZone__c +'\'';
            }
        }
        System.debug(WhereClause);
        return WhereClause;
    }
    private string filterDate(DateTime dt){
        String inputString = String.valueOf(dt);
        if (String.isBlank(inputString))return inputString;
        String queryString=inputString.left(10) + 'T' + inputString.right(8) + '.000Z';
            
        return queryString;
    }
    public String TaskQuery{
        get{
            //query campaign members using pagenumber offset
            String query = TASK_QUERY;
            String WhereClause=buildWhereClause();
            
            
            
            
            
            String PLACEHOLDER = EBH_ConstantsUtility.FR_BLANK;
            
            //All the fields are being queried which are present in the fieldset
            for(Schema.FieldSetMember fld : SObjectType.Task.FieldSets.Community_Home_Page.getFields()) {
                PLACEHOLDER += EBH_ConstantsUtility.ATCH_COMMA + fld.getFieldPath();
                
            }
            String returnQuery= !String.isBlank(PLACEHOLDER) ? query.replace(EBH_ConstantsUtility.PLACEH, PLACEHOLDER) : 
            query.replace(EBH_ConstantsUtility.PLACEH, EBH_ConstantsUtility.FR_BLANK);
            
            
            return !String.isBlank(WhereClause)?returnQuery.replace('[EXTRA_CLAUSE]',WhereClause):returnQuery.replace('[EXTRA_CLAUSE]',EBH_ConstantsUtility.FR_BLANK);
            
        }
    }   
    
    
    /*****************************************************************************************************************************
@ Method:         Constructor - EBH_CampaignHistoryController
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        To get the Seller Id, passed through inline VF page
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      ApexPages.StandardController 
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
*****************************************************************************************************************************/
    public CommunityHomePageController(ApexPages.StandardController controller) {        
        userId=UserInfo.getUserId();
        PageNumber = PageNumberDisplay = 0;   
        
        taskFilter = new Task();
        taskFilter.Status='Open';
        
        String countQuery=EBH_ConstantsUtility.TASK_COUNTQUERY.replace('[EXTRA_CLAUSE]','AND status=\'Open\'');
        
        RowCount = Database.countQuery(countQuery);
        PageCount = Math.ceil(Decimal.valueOf(RowCount).divide(PageSize, 1));
        communityUrl=getCommunityURL();
    }
    
    /*****************************************************************************************************************************
@ Method:         first
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        To get the first page of paginated records
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      No Parameters
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
*****************************************************************************************************************************/
    public void first() {
        PageNumber = PageNumberDisplay = 0;
    }
    
    /*****************************************************************************************************************************
@ Method:         next
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        To get the next set of paginated records
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      No Parameters
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
*****************************************************************************************************************************/
    public void next() {
        PageNumber += PageSize;
        PageNumberDisplay++;
    }
    
    /*****************************************************************************************************************************
@ Method:         previous
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        To get the previous set of paginated records
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      No Parameters
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
*****************************************************************************************************************************/
    public void previous() {
        PageNumber -= PageSize;
        PageNumberDisplay--;
    }
    
    /*****************************************************************************************************************************
@ Method:         last
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Used for getting the last set of records
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      No Parameter
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
*****************************************************************************************************************************/
    public void last() {
        PageNumber = Integer.valueOf(PageCount - 1) * PageSize;
        PageNumberDisplay = Integer.valueOf(PageCount - 1);
    }    
    
    private String getCommunityUrl(){
        
        
        String nwid = Network.getNetworkId();
        String servUrl = URL.getOrgDomainUrl().toExternalForm();
        if (!String.isBlank(nwid)) {
            nwid = Network.getLoginUrl(nwid);
            nwid = nwid.replace(servURL + '/', '');
            nwid = nwid.replace(servURL, '');
            nwid = nwid.split('/')[0];
            servUrl+= '/' + nwid;
        }         
        
        return servUrl;
        //return loginurl;
        
    }
}