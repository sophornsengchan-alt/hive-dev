/********************************************************************************************************************************
@ Class:          EBH_TargetingCockpitController2
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Controller Class for Targeting Cockpit Page
                  EPH-20 : Targeting Engine Filters
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.05.2017 / JOY MONDOL (jmondol@deloitte.co.uk) / Created the class.
@               : 10/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
@               : 12/06/2024/ Bora CHHORN/ US-0015212 - Bug in Targeting Engine Cloning feature
*********************************************************************************************************************************/
public with sharing class EBH_TargetingCockpitController2 {

    public Id filterId;
    
    public Boolean blockFilter{get;set;}
    
    public Boolean isTradingEngine{get;set;}
    
    /*****************************************************************************************************************************
    @ Constructor:    EBH_TargetingCockpitController2
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Initialises the class for controller instance.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      controller:   standard controller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.05.2017 / JOY MONDOL (jmondol@deloitte.co.uk) / Created the constructor.
    @               : 24/05/2018/ Vadhanak Voun (Vadhanak.voun@gaea-sys.com)/ [#EPH-5626] Lock TE when related campaign gets executed
    *****************************************************************************************************************************/
    public EBH_TargetingCockpitController2(ApexPages.StandardController controller) { 
        filterId = controller.getRecord().Id;
        //NK:24/05/2018
        blockFilter = false;
        for(Campaign c: Database.query(EBH_ConstantsUtility.SOQL_MCAMPAIGN_BY_SELLER_LIST))
        {
            if(EBH_ConstantsUtility.CAMPAIGN_STATUS_TO_BLOCK_TE.contains(c.Status))
            {
                blockFilter = true;break;
            }
        }
        //End-NK:24/05/2018
        
        EBH_Filter__c thisTE = Database.query(EBH_ConstantsUtility.SOQL_TARGETING_ENGINE +' WHERE ID =:filterId');
        isTradingEngine = thisTE.RecordType.DeveloperName == EBH_ConstantsUtility.TARGETING_ENGINE_RECTYPE_TRADING;
        
    }
    
    /*****************************************************************************************************************************
    @ Method:         cloneFilter
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        UI action to clone the the filter.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        PageReference: redirects to the cloned filter detail page
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.05.2017 / JOY MONDOL (jmondol@deloitte.co.uk) / Created the method.
    @               : 12/06/2024/ Bora CHHORN/ US-0015212 - Bug in Targeting Engine Cloning feature
    *****************************************************************************************************************************/
    public PageReference cloneFilter() {
        //get current filter
        EBH_Filter__c filter = Database.query(EBH_ConstantsUtility.TCC_FILTERQUERY); 
           
        //clone and save the cloned filter
        EBH_Filter__c clonedFilter = filter.clone(false, false, false); 
        clonedFilter.EBH_ListCode__c = String.valueOf(Math.random())
                                        .replace(EBH_ConstantsUtility.TCC_ZEROPOINT, EBH_ConstantsUtility.TCC_BLANK)
                                            .subString(EBH_ConstantsUtility.TCC_ZERO, EBH_ConstantsUtility.TCC_TEN);
        clonedFilter.ownerId = UserInfo.getUserId(); //US-0015212/BR/12-06-2024
        
        //safe insert
        try {
            Database.insert(clonedFilter);
        } catch(Exception ex) { EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.TCC_CLS, EBH_ConstantsUtility.TCC_METHODCF);}
        
              
        return new PageReference(EBH_ConstantsUtility.TCC_SLASH + clonedFilter.Id);
    }
    
    /*****************************************************************************************************************************
    @ Method:         fetchOptions
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        fetches the options for multi selects in UI
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      fieldApi: field api name
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<String> : options
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    @				: 11/04/2019 /Vadhanak Voun/ EPH-7285: crossobject, and added correct value and label
    *****************************************************************************************************************************/
    @RemoteAction
    @ReadOnly
    public static List<Map<String,String>> fetchOptions(String obj, String fieldApi) {  

        List<Map<String,String>> options = new List<Map<String,String>>();
        
        //EPH-7285: NK:11/04/2019
        Schema.SObjectField ft ;//= Schema.getGlobalDescribe().get(obj).getDescribe().Fields.getMap().get(fieldApi);
        if(EBH_ConstantsUtility.MAP_TE_FETCH_HELPTEXT.containsKey(obj) 
            && EBH_ConstantsUtility.MAP_TE_FETCH_HELPTEXT.get(obj).containsKey(fieldApi)) {
            //
            String sObj = EBH_ConstantsUtility.MAP_TE_FETCH_HELPTEXT.get(obj).get(fieldApi);
            String fld = fieldApi.substringAfterLast('.');
            ft = Schema.getGlobalDescribe().get(sObj).getDescribe().Fields.getMap().get(fld);
             
        }else{
            ft = Schema.getGlobalDescribe().get(obj).getDescribe().Fields.getMap().get(fieldApi);
             
        }
        
        Schema.DescribeFieldResult fd = ft.getDescribe();
        
        for( Schema.PicklistEntry pickListVal : fd.getPicklistValues()){
            //options.add(pickListVal.getLabel());
            if(pickListVal.isActive())
            {
            	options.add(new Map<String,String>{pickListVal.getValue()=>pickListVal.getLabel()});
            }
        }   

        return options;
    }
    
    /*****************************************************************************************************************************
    @ Method:         fetchHelpText
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        fetches the help text of the field
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      fieldApi:   field api name
                      sObjectApi: sObject api name
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        String : help text
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    @ReadOnly
    public static String fetchHelpText(String fieldApi, String sObjectApi) { 
        Schema.SObjectField ft; 
        // AMT:4-09-19, fetchHelp fixed to support cross object field
        if(EBH_ConstantsUtility.MAP_TE_FETCH_HELPTEXT.containsKey(sObjectApi) 
            && EBH_ConstantsUtility.MAP_TE_FETCH_HELPTEXT.get(sObjectApi).containsKey(fieldApi)) {
            //
            String sObj = EBH_ConstantsUtility.MAP_TE_FETCH_HELPTEXT.get(sObjectApi).get(fieldApi);
            String fld = fieldApi.substringAfterLast('.');
            ft = Schema.getGlobalDescribe().get(sObj).getDescribe().Fields.getMap().get(fld);
        }else{
            ft = Schema.getGlobalDescribe().get(sObjectApi).getDescribe().Fields.getMap().get(fieldApi);
        }
        
        return ft.getDescribe().getInlineHelpText();
    }
    
    /*****************************************************************************************************************************
    @ Method:         fetchSellersCount
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        fetches the sellers count based on the query
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      query:   account query icluding columns from fieldset
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Integer: count
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    @ReadOnly
    public static Integer fetchSellersCount(String query) {  
         
        return Database.countQuery(query);
    }
    
    /*****************************************************************************************************************************
    @ Method:         fetchSellersCount2
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        EPH-5627 Blacklist and Opt-ins in Targeting Engine: fetches the sellers count based on the query
    @               - Number of Sellers Blacklisted (Count number of sellers with "Marketing Blacklist" = TRUE)
    @               - Number of Sellers not Available (= Count number of sellers that have 0 contacts with Available for Marketing = TRUE)
    @               - Number of Contacts Available (= Count number of contacts with Available for Marketing = TRUE) 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      query:   account query icluding columns from fieldset
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map result: seller  count, Number of Sellers Blacklisted, Number of Sellers without Marketing Opt-In, 
    @                           Number of Contacts with Marketing Opt-in
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.04.2018 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    @ReadOnly
    public static Map<String,String> fetchSellersCount2(String filterId,String query) {  
        
        Map<String,String> mapResult = new Map<String,String>();
        Integer sellerCount = Database.countQuery(query);
        mapResult.put('sellerCount',sellerCount+'');
        
        EBH_Filter__c filter = [SELECT EBH_TE_Expiration_Date__c,EBH_NumberofSellersBlacklisted__c ,EBH_NumberofSellersWithoutMarketingOptIn__c  from EBH_Filter__c where Id = :filterId];
        String validateMsg = validateTE(sellerCount,filter);
        
        if(String.isNotBlank(validateMsg))
        {
        	mapResult.put('status','ko');
        	mapResult.put('msg',validateMsg);
        	 
        }else
        {
        	mapResult.put('status','ok');
        	
        	//Number of Sellers Blacklisted
	        String soqlBlackList = query.toLowerCase().replaceFirst(' where ',' where Marketing_Blacklist__c=true and ');
	        mapResult.put('sellerBlacklist',Database.countQuery(soqlBlackList)+'');        
	        
	        //NK:26/05/2018
	       // saveFieldsAsyn(filterId,'EBH_NumberofSellersBlacklisted__c',Integer.valueOf(mapResult.get('sellerBlacklist')));
	         
	         //EPH-5933 - to resolve concurrent error locking
	         if( filter.EBH_NumberofSellersBlacklisted__c != Integer.valueOf(mapResult.get('sellerBlacklist')) ){
	         
	             saveFieldsAsyn(filterId,'EBH_NumberofSellersBlacklisted__c',Integer.valueOf(mapResult.get('sellerBlacklist')));
	         }
        } 
        
        return mapResult;
    }

    /*****************************************************************************************************************************
    @ Method:         fetchSellersCount3
    @ Version:        1.0
    @ Author:         Acmatac Seing (acmatac.seing@gaea-sys.com)
    @ Purpose:        EPH-7265, Get all seller id with and chunk if query limit exceed
    @               
    @ Change history: 4.10.2019 / Acmatac Seing / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    @ReadOnly
    public static Map<String, Object> fetchSellersCount3(String filterId,String query,String lastId) {
        
        String soqlFetchAccount = query.toLowerCase().replace(' count() ', ' Id ').split('limit')[0];
        Map<String,Object> mapResult = new Map<String,Object>();
        String whereCl = '';
        if(String.isNotBlank(lastId)) {
            whereCl = ' AND Id>:lastId ';
        }
        soqlFetchAccount += whereCl + ' ORDER BY Id LIMIT ' + EBH_ConstantsUtility.LIMIT_SOQL;
        List<Account> lstAcc = Database.query(soqlFetchAccount);
        if(lstAcc.size() < EBH_ConstantsUtility.LIMIT_SOQL) {
            mapResult.put('qmore',false);
            mapResult.put('allAccIds', (new Map<Id, Account>(lstAcc)).keySet());
            mapResult.putAll(fetchSellersCount2(filterId, query));
        }else{
            mapResult.put('qmore',true);
            mapResult.put('allAccIds', (new Map<Id, Account>(lstAcc)).keySet());
            mapResult.put('lastId', lstAcc.get(lstAcc.size()-1).Id); // last id for next query order
        }
        
        return mapResult;

    }
    
    /*****************************************************************************************************************************
    @ Method:         validateTE
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        EPH-7019 Target Engine - Validation Rules for Expiration Date
    @               AC1) When I am on a targetlist record type snapshot and click GENERATE AND SAVE LIST  or click REFRESH then we will have the following validation rule (tiered approach)
	@				a) If seller count >8,500 and Expiration Date >2 years from today then block  save and show following validation message: 
	@				 "For your number of uploaded sellers the expiration date can be max. 2 years from today. Please make sure to set the expiration date to max. two years from today."
	@				b) If seller count between 50,000 and 100,000 and Expiration Date >1 years from today then block save and show following validation message: 
	@				 "For your number of uploaded sellers the expiration date can be max. 1 year from today. Please make sure to set the expiration date to max. one year from today."
	@				c) If seller count >100,000 and Expiration Date > 6 months from today then block  save and show following validation message: 
	@				 "For your number of uploaded sellers the expiration date can be max. 6 months  from today. Please make sure to set the expiration date to max. six months from today."
	@				d) If seller count > 300,000 then block  save and show following validation message: 
	@				 "Maximum numbers of sellers in a seller list should not exceed 300,000. Please add more filter to decrease number of sellers."
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      sellerCount:   number of seller with provided filter criteria 
    @				  filter	 : current Targeting Engine
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:         String of error or NULL
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.04.2018 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    @TestVisible
    private static String validateTE(Integer sellerCount,EBH_Filter__c filter)
    {
    	String errMsg = null;
    	Date next2Year = System.Today().addYears(2);
    	Date next1Year = System.Today().addYears(1);
    	Date next6Month = System.Today().addMonths(6);
    	
    	if(sellerCount > 8500 && filter.EBH_TE_Expiration_Date__c > next2Year)  
    	{
    		errMsg = System.Label.TE_Error2Year;
    	}else if((sellerCount >= 50000 && sellerCount <=100000) && filter.EBH_TE_Expiration_Date__c > next1Year)
    	{
    		errMsg = System.Label.TE_Error1Year;
    	}else if(sellerCount > 100000 && filter.EBH_TE_Expiration_Date__c > next6Month)
    	{
    		errMsg = System.Label.TE_Error6Months;
    	}else if(sellerCount >300000)
    	{
    		errMsg = System.Label.TE_ErrorMax300K;
    	}
    	
    	return errMsg;
    }
    
    /*****************************************************************************************************************************
    @ Method:         fetchNumContactAvailable 
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        EPH-5627 Blacklist and Opt-ins in Targeting Engine: fetches the sellers count based on the query
    @               - EPH-5859 : fixed cpu limit. 
    @               - Number of Contacts Available (= Count number of contacts with Available for Marketing = TRUE)             
    @               EPH-5859  ** split from fetchSellersCount2() to avoid cpu exeeded whe record more than 500k
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      query:   account query icluding columns from fieldset
    @                 lastId: lastId for soql manipultion for the next set of record
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map result: numContactAvailable
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 26.05.2018 / Vadhanak Voun / Created the  Method.
    @				: 14.06.2018 / Vadhanak Voun :
    @					- EPH-5824: Rename existing "Number of Contacts not Available" to "Number of Contacts Email Opt-out"
    @					- Update "Number of Contacts Email Opt-Out" calculation (=Count number of contacts with Available for Marketing = FALSE)
    *****************************************************************************************************************************/
    @RemoteAction
    @ReadOnly
    public static Map<String,String> fetchNumContactAvailable(String filterId,String query,String lastId) {
        Map<String,String> mapResult = new Map<String,String>();
        //Num of Contact Available
        String nextWhere = String.isBlank(lastId)?' where ':' where Id>:lastId and '; // for the next set of query
        query = query.toLowerCase().replaceFirst(' where ',nextWhere) + ' order by id limit '+EBH_ConstantsUtility.LIMIT_SOQL;
        String soqlContactAvailable = query.toLowerCase().replace(' count() ',' id,(select id from contacts where Available_for_Marketing__c = FALSE ) ');
        Integer numContactAvailable = 0;
        Account[] allAcc = Database.query(soqlContactAvailable);
        for(Account a: allAcc)
        {
            numContactAvailable+= a.contacts.size();
        }
        mapResult.put('numContactAvailable',numContactAvailable+'');
        
        if(allAcc.size() < EBH_ConstantsUtility.LIMIT_SOQL)
        {
            mapResult.put('qmore','false');
             
        }else
        {
            mapResult.put('qmore','true');
            mapResult.put('lastId',allAcc[allAcc.size()-1].Id); // last id for next query order
        }
        
        return mapResult;
    }
    /*****************************************************************************************************************************
    @ Method:         fetchSellersNotAvailable 
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        EPH-5627 Blacklist and Opt-ins in Targeting Engine: fetches the sellers count based on the query
    @               - Number of Sellers Blacklisted (Count number of sellers with "Marketing Blacklist" = TRUE)
    @               - Number of Sellers not Available (= Count number of sellers that have 0 contacts with Available for Marketing = TRUE)
    @               - Number of Contacts Available (= Count number of contacts with Available for Marketing = TRUE) 
    @               
    @               EPH-5859  ** split from fetchSellersCount2() to avoid cpu exeeded whe record more than 500k
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      query:   account query icluding columns from fieldset
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map result: seller  count, Number of Sellers Blacklisted, Number of Sellers without Marketing Opt-In, 
    @                           Number of Contacts with Marketing Opt-in
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.05.2018 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    @ReadOnly
    public static Map<String,String> fetchSellersNotAvailable(String filterId,String query,String lastId) {
        Map<String,String> mapResult = new Map<String,String>();
        Integer numSellerNotAvailable = 0;
        //Number of SellersNotAvailable
        //construct where cause to get next Id from the previouse query 
        String nextWhere = String.isBlank(lastId)?' where ':' where Id>:lastId and '; // for the next set of query
        query = query.toLowerCase().replaceFirst(' where ',nextWhere) + ' order by id limit '+EBH_ConstantsUtility.LIMIT_SOQL;
        
        //replace sub query
        String soqlSellerNotAvailable = query.toLowerCase().replace(' count() ',' id,(select id from contacts where Available_for_Marketing__c = TRUE limit 1) ');
       
        system.debug('>>>fetchSellersNotAvailable soqlSellerNotAvailable: '+soqlSellerNotAvailable);
       
        Account[] allAcc = Database.query(soqlSellerNotAvailable);
        for(Account a: allAcc)
        {
            if(a.contacts.isEmpty())
            {
                numSellerNotAvailable+=1;
            }
        }
        mapResult.put('numSellerNotAvailable',numSellerNotAvailable+'');
        
        //check if more record to query
        if(allAcc.size() < EBH_ConstantsUtility.LIMIT_SOQL)
        {
            mapResult.put('qmore','false');
           
            EBH_Filter__c filter = [SELECT EBH_NumberofSellersBlacklisted__c ,EBH_NumberofSellersWithoutMarketingOptIn__c  from EBH_Filter__c
             where Id = :filterId];
         
           //EPH-5933 - to resolve concurrent error locking
           if( filter.EBH_NumberofSellersWithoutMarketingOptIn__c != numSellerNotAvailable  ){
         
                saveFieldsAsyn(filterId,'EBH_NumberofSellersWithoutMarketingOptIn__c',numSellerNotAvailable);
            }
        }else
        {
            mapResult.put('qmore','true');
            mapResult.put('lastId',allAcc[allAcc.size()-1].Id); // last id for next query order
        }
        
        return mapResult; 
    }
    
    /*****************************************************************************************************************************
    @ Method:         fetchNumSellerPhoneOptOut 
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        EPH-5824 clarity on "Sellers Available" in TL
    @               - Number of Sellers Phone Opt-out (= Count number of sellers that have at least 1 contact with Phone Opt-out = TRUE and/or Do Not Contact = TRUE"))
    @               
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      query:   account query icluding columns from fieldset
    @                 lastId: lastId for soql manipultion for the next set of record
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map result: Number of Sellers Phone Opt-out
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.06.2018 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    @ReadOnly
    public static Map<String,String> fetchNumSellerPhoneOptOut(String filterId,String query,String lastId) {
        Map<String,String> mapResult = new Map<String,String>();
        //Num of Contact Available
        String nextWhere = String.isBlank(lastId)?' where ':' where Id>:lastId and '; // for the next set of query
        query = query.toLowerCase().replaceFirst(' where ',nextWhere) + ' order by id limit '+EBH_ConstantsUtility.LIMIT_SOQL;
        String soqlContact = query.toLowerCase().replace(' count() ',' id,(select id from contacts where EBH_PhoneOptOut__c = true OR EBH_DoNotContact__c = true limit 1) ');
        //system.debug('>>>soqlContactAvailable: '+soqlContact);                                         
        Integer numSellerPhoneOpt_Out = 0;
        Account[] allAcc = Database.query(soqlContact);
        for(Account a: allAcc)
        {
            numSellerPhoneOpt_Out = a.contacts.isEmpty() ? numSellerPhoneOpt_Out : numSellerPhoneOpt_Out + 1 ;
        }
        mapResult.put('numSellerPhoneOpt_Out',numSellerPhoneOpt_Out+'');
        
        if(allAcc.size() < EBH_ConstantsUtility.LIMIT_SOQL)
        {
            mapResult.put('qmore','false');
             
        }else
        {
            mapResult.put('qmore','true');
            mapResult.put('lastId',allAcc[allAcc.size()-1].Id); // last id for next query order
        }
        
        return mapResult;
    }
    
    /*****************************************************************************************************************************
    @ Method:         fetchNumContactPhoneOptOut 
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        EPH-5824 clarity on "Sellers Available" in TL
    @               - Number of Contacts Phone Opt-out (= Count number of contacts with Phone Opt-out = TRUE or Do not Contact = TRUE) 
    @               
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      query:   account query icluding columns from fieldset
    @                 lastId: lastId for soql manipultion for the next set of record
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map result: Number of Contacts Phone Opt-out
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.06.2018 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    @ReadOnly
    public static Map<String,String> fetchNumContactPhoneOptOut(String filterId,String query,String lastId) {
        Map<String,String> mapResult = new Map<String,String>();
         
        String nextWhere = String.isBlank(lastId)?' where ':' where Id>:lastId and '; // for the next set of query
        query = query.toLowerCase().replaceFirst(' where ',nextWhere) + ' order by id limit '+EBH_ConstantsUtility.LIMIT_SOQL;
        String soqlContact = query.toLowerCase().replace(' count() ',' id,(select id from contacts where EBH_PhoneOptOut__c = true OR EBH_DoNotContact__c = true ) ');
                                               
        Integer numContactPhoneOpt_Out = 0;
        Account[] allAcc = Database.query(soqlContact);
        for(Account a: allAcc)
        {
            numContactPhoneOpt_Out += a.contacts.size();
        }
        mapResult.put('numContactPhoneOpt_Out',numContactPhoneOpt_Out+'');
        
        if(allAcc.size() < EBH_ConstantsUtility.LIMIT_SOQL)
        {
            mapResult.put('qmore','false');
             
        }else
        {
            mapResult.put('qmore','true');
            mapResult.put('lastId',allAcc[allAcc.size()-1].Id); // last id for next query order
        }
        
        return mapResult;
    }
    
    /*****************************************************************************************************************************
    @ Method:         saveFieldsAsyn
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        save fields: numSellerBlacklist, numSellerWithOutOptIn 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      filterId:    EBH_Filter__c to be updated
    @                 numSellerBlacklist: value to save 
    @                 numSellerWithOutOptIn: value to save
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        void 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.05.2018 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    @future
    private static void saveFieldsAsyn(String filterId, String fName, Integer value)
    {
        try {
            EBH_Filter__c fltr = new EBH_Filter__c(Id = filterId);
            fltr.put(fName,value);
            
            Database.update(fltr);
        } catch(Exception ex) { EBH_ApexLogger.logError(new List<Exception> { ex },  EBH_ConstantsUtility.TCC_CLS, 'saveFieldsAsyn');  }
    } 
    /*****************************************************************************************************************************
    @ Method:         fetchSellers
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        fetches the sellers based on the query
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      query: account query icluding columns from fieldset
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<Account>:  related contact accounts indexed  by last offset index - single item map
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    @ReadOnly
    public static List<Account> fetchSellers(String query) {        
        
        return Database.query(query);
    }
 
    /*****************************************************************************************************************************
    @ Method:         fetchFilter
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        fetches the sellers based on the query
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      sellerListId:   Seller List Id
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        EBH_Filter__c:  Seller list record
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    @ReadOnly
    public static EBH_Filter__c fetchFilter(Id sellerListId) {
        
        return Database.query(EBH_ConstantsUtility.TCC_FILTERSELLERLISTQUERY);
    }
    
    /*****************************************************************************************************************************
    @ Method:         updateFilter
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        fetches the sellers based on the query
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      sellerListId:   Seller List Id
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        EBH_Filter__c:  Seller list record
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    public static Map<String,String> updateFilter(Id sellerListId, String filter) {
        
        Map<String,String> mapResult = new Map<String,String>();
        EBH_Filter__c fltr;
        if(String.isNotBlank(filter))
        {
        	Integer sellerCount = Database.countQuery(filter);
			fltr = Database.query(EBH_ConstantsUtility.TCC_FILTERSELLERLISTQUERY);			
			String validateMsg = validateTE(sellerCount,fltr);
			if(String.isNotBlank(validateMsg))
	        {
	        	mapResult.put('status','ko');mapResult.put('msg',validateMsg);	mapResult.put('sellerCount',sellerCount+'');
	        	return mapResult;  
	        }
        }else
        {
        	fltr = new EBH_Filter__c(Id = sellerListId);
        }
        
    	//EBH_Filter__c fltr = new EBH_Filter__c(Id = sellerListId, EBH_Filter__c = filter);
        fltr.EBH_Filter__c = filter;
        try {
            Database.update(fltr);
            mapResult.put('status','ok');
        } catch(Exception ex) {EBH_ApexLogger.logError(new List<Exception> { ex },EBH_ConstantsUtility.TCC_CLS, EBH_ConstantsUtility.TCC_METHODUF); mapResult.put('status','ko'); mapResult.put('msg',ex.getMessage());  }
         
        
        return mapResult;
    }
    
    /*****************************************************************************************************************************
    @ Method:         generateTargetedSellers
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        initiates the batch for targeted seller creation
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      sellerListId:   Seller List Id
                      query:          account query for batch
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean:  success status
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    public static Map<String,String> generateTargetedSellers(Id sellerListId, String query) {
        Map<String,String> mapResult = new Map<String,String>();
        
        EBH_Filter__c filter = Database.query(EBH_ConstantsUtility.TCC_FILTERSELLERLISTQUERY);
        //amt, 05-4-19, add ## to make sure it won't replace other Id field in WHERE clause. example : "SELECT Id FROM ... WHERE Id ...".
        String countSOQL = query.toLowerCase().replaceFirst('id',' COUNT() ');
        query = query.replace(' COUNT() ',' Id ');
        Integer sellerCount = Database.countQuery(countSOQL);
        
        String validateMsg = validateTE(sellerCount,filter);
		if(String.isNotBlank(validateMsg))
        {
        	mapResult.put('status','ko');
        	mapResult.put('msg',validateMsg);
        	mapResult.put('sellerCount',sellerCount+'');
        }else
        {
        
	        filter.EBH_Refreshing__c = true;        
	        try {
	            Database.update(filter);
	        } catch(Exception ex) {EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.TCC_CLS, EBH_ConstantsUtility.TCC_METHODGTS); }
	        EBH_DeleteTargetSellersBatch tSBatch  = new EBH_DeleteTargetSellersBatch(filter, query);
	        Database.executeBatch(tSBatch,200);
	        
	        mapResult.put('status','ok');
    	}
    	
        return mapResult;
    }
    
    /*****************************************************************************************************************************
    @ Method:         fetchAccountFieldValues
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        initiates the batch for targeted seller creation 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      query:      account query for auto suggest
                      fldApi:     field api name
                      sObjectApi: sObject Api name
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Set<String>:  distinct values
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    @               : 10/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
    *****************************************************************************************************************************/
    @RemoteAction    
    @ReadOnly
    public static Set<String> fetchAccountFieldValues(String query, String fldApi, String sObjectApi) {
        
        Set<String> values = new Set<String>();
        
        if(sObjectApi == EBH_ConstantsUtility.TCC_ACCOUNTFILTER) {
            for(Account acc : Database.query(query)) {
                values.add(String.valueOf(acc.get(fldApi)));
                
                if(values.size() == EBH_ConstantsUtility.TCC_TWENTY ) { break; }
            }
        } else {
            
            //EPH-3713 - Query actions from Action object directly as there are a lot of NBA records 
            // and results were not inappropriate
            if( query.contains('From EBH_NBA__c')){
                for(EBH_NBA__c nba : Database.query(query)) {
                    values.add(String.valueOf(nba.get(fldApi)));
                    
                    if(values.size() == EBH_ConstantsUtility.TCC_TWENTY ) { break; }
                }
            }else if(query.contains('From EBH_Action__c')){
                for(EBH_Action__c nba : Database.query(query)) {
                    if(!nba.EBH_NBAs__r.isEmpty())
                    values.add(String.valueOf(nba.get(fldApi)));
                    if(values.size() == EBH_ConstantsUtility.TCC_TWENTY ) { break; }
                }
            }
            //NK:10/05/2024/:US-0015118
            //amt 4-04-2019 : EPH-7265
            // else if(query.contains('FROM Seller_to_Product__c')){   
            //     for(sObject prod : Database.query(query)) {
            //         if(EBH_ConstantsUtility.MAP_TE_FETCH_HELPTEXT.containsKey(sObjectApi) 
            //             && EBH_ConstantsUtility.MAP_TE_FETCH_HELPTEXT.get(sObjectApi).containsKey(fldApi)) {
            //             //
            //             String sObj = EBH_ConstantsUtility.MAP_TE_FETCH_HELPTEXT.get(sObjectApi).get(fldApi);
            //             if(sObj.contains('__c')) {
            //                 sObj = sObj.replace('__c', '__r');
            //             }
            //             String fld = fldApi.substringAfterLast('.');
            //             values.add(String.valueOf(prod.getSObject(sObj).get(fld)));
            //         }else{
            //             values.add(String.valueOf(prod.get(fldApi)));
            //         }
            //         if(values.size() == EBH_ConstantsUtility.TCC_TWENTY ) { break; }
            //     }
            // }
            //amt 4-04-2019 : EPH-7265, Default query
            else{   
                for(sObject sObj : Database.query(query)) {
                    //values.add(String.valueOf(sObj.get(fldApi)));
					values.add(String.valueOf( ApexUtil.getValue(fldApi,sObj) ) ); //NK:18/04/2019
                    if(values.size() == EBH_ConstantsUtility.TCC_TWENTY ) { break; }
                }
            }
        }
        System.debug('###'+values);
        return values;
    }


    /*****************************************************************************************************************************
    @ Method:         countEstimatedProd
    @ Version:        1.0
    @ Author:         Acmatac Seing (acmatac.seing@gaea-sys.com)
    @ Purpose:        To count the filtered product from SellerToProduct
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 4.11.19 / Acmatac Seing / Created the  Method.
    @               : 10/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
    *****************************************************************************************************************************/
    /*
    @RemoteAction
    @ReadOnly
    public static Map<String,Object> countEstimatedProd(String query,String lastId, List<String> allAccId) {
        Map<String,Object> mapResult = new Map<String,Object>();
        System.debug('debug query1: '+query);
        query = query.toLowerCase();
		if(query.contains('from seller_to_product__c')) {
			query = query.replace('count()','(Select Id,Product__c From Seller_to_Products__r)');
            Set<Id> sProdId = new Set<Id>();
            Set<String> setSellerToProductIds = new Set<String>();
            String whereCl = '';
            if(String.isNotBlank(lastId)) {
                whereCl = ' AND Id>:lastId ';
            }            
            query += whereCl + ' ORDER BY Id LIMIT ' + LIMIT_COUNTPRODUCT;
            system.debug('query2 : '+query);
            List<Account> listSeller = Database.query(query);
            for(Account seller : listSeller) {
            	for(seller_to_product__c stp: seller.Seller_to_Products__r)
            	{
            		sProdId.add(stp.Product__c);
            		setSellerToProductIds.add(stp.Id);
            	}
            }
            if(listSeller.size() < LIMIT_COUNTPRODUCT) {
                mapResult.put('qmore',false);
                mapResult.put('allProdIds', sProdId);
                mapResult.put('sellerToProductIds', setSellerToProductIds);
            }else{
                mapResult.put('qmore',true);
                mapResult.put('allProdIds', sProdId);
                mapResult.put('sellerToProductIds', setSellerToProductIds);
                mapResult.put('lastId', listSeller.get(listSeller.size()-1).Id); // last id for next query order
            }
        }else{
            mapResult.put('qmore',false);
            mapResult.put('allProdIds', new Set<Id>());
            mapResult.put('sellerToProductIds', new Set<String>());
        }        
        
        return mapResult;
    }
	*/
	/*****************************************************************************************************************************
    @ Method:       countRBS
    @ Version:      1.0
    @ Author:       Vadhanak Voun (vadhanak.voung@gaea-sys.com)
    @ Purpose:      [#EPH-7285] Targeting Engine_ Range-Based Sourcing
    @				Estimated Range-Based Sourcing count
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.04.2019 / Vadhanak Voun / Created the  Method.
    @               : 10/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
    *****************************************************************************************************************************/
    /*
    @RemoteAction
    @ReadOnly
    public static Map<String,Object> countRBS(String query,String lastId, Set<String> setRBS) 
    {	
    	Map<String,Object> mapResult = new Map<String,Object>();
        query = query.toLowerCase();
        
        String nextWhere = String.isBlank(lastId)?' where ':' where Id>:lastId and '; // for the next set of query
        query = query.replaceFirst(' where ',nextWhere) + ' order by id limit '+EBH_ConstantsUtility.LIMIT_SOQL;
        String soqlSeller2 = query.replace(' count() ',' id ');
        String soqlSOPP = 'Select Range_Based_Sourcing__c From Sourcing_Opportunity__c Where Seller__c IN :allAcc ';                                       
         
        Account[] allAcc = Database.query(soqlSeller2);
        setRBS = setRBS==null? new Set<String>():setRBS; //set for uniq RBS count
        
        for(Sourcing_Opportunity__c sopp: Database.query(soqlSOPP))
        {
           setRBS.add(sopp.Range_Based_Sourcing__c); //set for unique counting
        }
         
        
        if(allAcc.size() < EBH_ConstantsUtility.LIMIT_SOQL)
        {
            mapResult.put('qmore','false');
             
        }else
        {
            mapResult.put('qmore','true');
            mapResult.put('lastId',allAcc[allAcc.size()-1].Id); // last id for next query order
        }
        mapResult.put('setRBS',setRBS);
        
        return mapResult;
    }
    */
    /*****************************************************************************************************************************
    @ Method:       countRBS
    @ Version:      1.0
    @ Author:       Vadhanak Voun (vadhanak.voung@gaea-sys.com)
    @ Purpose:      [#EPH-7285] Targeting Engine_ Range-Based Sourcing
    @				Estimated Range-Based Sourcing count
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.04.2019 / Vadhanak Voun / Created the  Method.
    @               : 10/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
    *****************************************************************************************************************************/
    /*
    @RemoteAction
    public static Map<String,Object> saveRelatedProducts(String te_Id,List<String> listIdProduct,List<String> listIdSellerToProduct) 
    {	
    	//system.debug('>>>listIdProduct: '+listIdProduct);
    	//system.debug('>>>listIdSellerToProduct: '+listIdSellerToProduct);
    	Map<String,Object> mapResult = new Map<String,Object>();
    	try
    	{
    		String msg = '';
    		if(!listIdProduct.isEmpty())
	    	{
	    		BatchTargetingEngineSaver bSaver;
	    		if(listIdProduct.size() <= LIMIT_SAVE)
	    		{
	    			bSaver = new BatchTargetingEngineSaver(te_Id);
	    			bSaver.saveProducts([Select Id From Product__c where Id IN:listIdProduct]);
	    			msg+='Targetted Product upsertted: ' +listIdProduct.size();
	    		}else
	    		{
	    			bSaver = new BatchTargetingEngineSaver(te_Id,BatchTargetingEngineSaver.TE_RELATED_PRODUCT,listIdProduct);
	    			Database.executeBatch(bSaver);
	    			msg+='Targetted Product upsert in background: '+listIdProduct.size();
	    		}
	    		
	    		
	    	}
	    	if(!listIdSellerToProduct.isEmpty())
	    	{
	    		BatchTargetingEngineSaver bSaver;
	    		if(listIdSellerToProduct.size() <= LIMIT_SAVE)
	    		{
	    			bSaver = new BatchTargetingEngineSaver(te_Id);
	    			bSaver.saveSellerToProduct([Select Id From Seller_to_Product__c where Id IN:listIdSellerToProduct]);
	    			msg+='\nTargetted Listing upsertted: '+listIdSellerToProduct.size();
	    		}else
	    		{
	    			bSaver = new BatchTargetingEngineSaver(te_Id,BatchTargetingEngineSaver.TE_RELATED_SELLER_TO_PRODUCT,listIdSellerToProduct);
	    			Database.executeBatch(bSaver);
	    			msg+='\nTargetted Listing upsert in background: '+listIdSellerToProduct.size();
	    		}
	    		
	    	}
	    	
	    	mapResult.put('status','ok');
	    	mapResult.put('msg',msg);
    	}catch(Exception ex){System.debug(ex);mapResult.put('status','ko');mapResult.put('msg',ex.getMessage()); 	}
    	
    	return mapResult;
    }
     
    public static Integer LIMIT_SAVE = 5000;
    public static Integer LIMIT_COUNTPRODUCT = 5000;

    */
}