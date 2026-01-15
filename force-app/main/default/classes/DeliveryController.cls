/*****************************************************************************************************************************************************************
    @ Class:          DeliveryController
    @ Version:        1.0
    @ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0007908 [Ads 2020] Migrate DFP Batch Process to Hive.
    @                 Cloned from EU Advertising
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  30.11.2020 / Acmatac SEING / Created the class.
    @ Change history: 18.09.2023 /Vimean Heng/US-0013941 - PART 3 - Upgrade API version of all classes having an API version lower than 31
***********************************************************************************************************************************************************/

public without sharing class DeliveryController  extends DARTObject.AbstractDARTController{
    public static final String AD_PRODUCT_API_NAME = 'Ad_Product__c'; // OPPORTUNITY_PRODUCT_API_NAME = 'OpportunityLineItem';
    public static final String AD_REVENUE_DAILY_API_NAME = 'Ad_Revenue_Daily__c'; // REVENUE_SCHEDULE_DAILY_API_NAME = 'Revenue_Schedule_daily2__c'; 
    public static final String AD_REVENUE_MONTHLY_API_NAME = 'Ad_Revenue_Monthly__c'; // REVENUE_SCHEDULE_API_NAME = 'Revenue_Schedule2__c';
    
    public static final String SOBJECT_AD_PRODUCT = 'Ad Product'; // SOBJECT_OPPPRODUCT = 'Opportunity Product';
    public static final String SOBJECT_AD_REV_DAILY = 'Ad Revenue Daily'; // SOBJECT_REV_SCH2_DAILY = 'Revenue Schedule Daily2';
    public static final String SOBJECT_AD_REV_MONTHLY = 'Ad Revenue Monthly'; // SOBJECT_REV_SCH2 = 'Revenue Schedules2';
    public static final String SOBJECT_AD_REV_MONTHLY_MTD = 'Ad Revenue Monthly - Month To Date'; // SOBJECT_REV_SCH2_MTD = 'Revenue Schedules2 - Month To Date';

    public static final String DART_STATUS_NEW = 'New';
    public static final String DART_STATUS_AWAIT = 'Await';
    public static final String DART_STATUS_FINISHED = 'Finished';
    public static final String SCH_TYPE_DAILY = 'Daily'; 
    public static final String SCH_TYPE_MONTHLY = 'Monthly';
    public static final String SCH_TYPE_MANUALLY = 'Manually';
    public static final String SCH_TYPE_WEEKLY = 'Weekly';
    public static final String TYPE_MANUALLY_POLLING = 'Polling Import';
    public static final String REPORT_QUERY_FAILED = 'FAILED';
    public static final String REPORT_QUERY_INPROGRESS = 'IN_PROGRESS';
    public static final String REPORT_QUERY_COMPLETED = 'COMPLETED';
    public static final String REPORT_QUERY_RETRY = 'RETRY';
    public static final Integer MAX_RETRY_IMPORT = 3;
    public static final Integer MAX_ATTAMPT_WAITING = 10;
    public static final List<String> zoneList = new List<String>{'APAC','EMEA','America'};
    public static final String QUERY_START_DATE = '%StartDate%';
    public static final String QUERY_END_DATE = '%EndDate%';
    
    private AdServer_Login__c login;
    private String breakDown; 

    public static final String IMPORT_TYPE_DELIVERY_IMPORT = 'Delivery Import'; // represent NA import logic
    public static final String IMPORT_TYPE_DELIVERY_IMPORT_NEW = 'Delivery Import New'; // represent EU import logic
    
    public DART_Delivery_Support__c dartDelStatus {get; set;}
     
    public DeliveryController(DART_Delivery_Support__c dds)
    {
        dartDelStatus = dds;
        login = [SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c FROM AdServer_Login__c WHERE Id =: dds.AdServer_Login__c limit 1];
    }
    
    public DeliveryController(DART_Delivery_Support__c dds, String breakDown){
        this(dds);
        this.breakDown = breakDown;
    }
    
    private Long jobid;
    public void setJobid(Long jobid){
        this.jobid = jobid;
    }
    
    private DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService;
    public void setReportService (DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService){
        this.reportService = reportService;
    }
    
    /**
     * Is zone defined?
     */
    public static Boolean isByZone(String zone){
        return (zone != null && zone != '');
    }
    
    //RS: 15 DeliverySupport with 2-day-packages.
    public static final Integer DAY_NUM_SPLIT = 2;
    /**
     * Start the process with Date Range define, start date and end date
     */
    public static void start(String scheduleType, String sobj, Date startDate, Date endDate, String zone)
    {
        List<Date> lstStartDate = new List<Date>();
        List<Date> lstEndDate = new List<Date>();
        if(sobj == SOBJECT_AD_REV_MONTHLY){
            startDate = Date.newInstance(startDate.year(), startDate.month(), 1);
            endDate = Date.newInstance(endDate.year(), endDate.month(), Date.daysInMonth(endDate.year(), endDate.month()));
            lstStartDate.add(startDate);
            lstEndDate.add(endDate);
        }else if(sobj == SOBJECT_AD_REV_MONTHLY_MTD){
            startDate = Date.newInstance(startDate.year(), startDate.month(), 1);
            lstStartDate.add(startDate);
            lstEndDate.add(endDate);
        }else if(startDate.daysBetween(endDate) >= 10){
            Date tmpDate = startDate;
            Date tmpDate2 = endDate;
            while(tmpDate < endDate){
                lstStartDate.add(Date.newInstance(tmpDate.year(),tmpDate.month(),tmpDate.day()));
                tmpDate = tmpDate.addDays(DAY_NUM_SPLIT);            
                tmpDate2 = tmpDate.addDays(-1);
                lstEndDate.add(Date.newInstance(tmpDate2.year(),tmpDate2.month(),tmpDate2.day()));
            }
            if(tmpDate2 < endDate || startDate == endDate) {
                lstStartDate.add(Date.newInstance(endDate.year(), endDate.month(), endDate.day()));
                lstEndDate.add(Date.newInstance(endDate.year(), endDate.month(), endDate.day()));
            }
        }else{
        	
            lstStartDate.add(startDate);
            lstEndDate.add(endDate);
        }
        //return;
        DART_Delivery_Support__c[] listDDs = new List<DART_Delivery_Support__c>();
        for(AdServer_Login__c login : [SELECT RecordType.name, Add_One_Additional_Day__c, Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c, Zone__c FROM AdServer_Login__c WHERE Active__c=true AND Publisher_ID__c = null AND isDeleted=false AND (RecordType.name=:DARTUtil.DART6)]) //And (Id='a0U2000000JDH6Z' OR Id ='a0U2000000JDH6M')
        {
            if(isByZone(zone) && login.Zone__c != zone) continue;
            for(Integer i = 0; i < lstStartDate.size(); i++){
                DART_Delivery_Support__c dds = new DART_Delivery_Support__c(
                    AdServer_Login__c=login.Id,Attempt__c=0,
                    Schedule_Type__c = scheduleType,
                    Sobject__c = sobj,
                    Retry_Counter__c = 0,
                    Status__c = DART_STATUS_NEW,
                    Query_Start_Date__c = lstStartDate[i],
                    Query_End_Date__c = lstEndDate[i],
                    Zone__c = isByZone(zone) ? zone : null,
                    By_Zone__c = isByZone(zone)
                );
                if(sobj != SOBJECT_AD_REV_MONTHLY && sobj != SOBJECT_AD_REV_MONTHLY_MTD && login.Add_One_Additional_Day__c){
                    dds.Query_Start_Date__c = dds.Query_Start_Date__c.addDays(1);
                    dds.Query_End_Date__c = dds.Query_End_Date__c.addDays(1);
                }
                listDDs.add(dds);
            }
        }
        if(!listDDs.isEmpty())
        {
            insert listDDs; 
            DART6BatchDeliverySupport batchSupport = new DART6BatchDeliverySupport(listDDs[0].Id, DART6BatchDeliverySupport.CALL_TYPE_REQUEST_REPORT);
            ID batchprocessid = Database.executeBatch(batchSupport);
        }
    }
    
    /**
     * Date Rang for DART6
     */
    private static DateTime todayDate = System.now();
    private static DateTime yesterdayDate = todayDate.addDays(-1);
    private static DateTime b4yesterdayDate = todayDate.addDays(-2);
    private static DateTime lastMonthDate = todayDate.addMonths(-1);
    private static DateTime daystartLastMonth = DateTime.newInstance(lastMonthDate.year(),lastMonthDate.month(),5);
    private static DateTime daystartThisMonth = DateTime.newInstance(todayDate.year(),todayDate.month(),5);
    /**
     * Date Rang for DART6 : Start Date
     */
    public static DateTime getStartDate(String sobj){
        DateTime startDate;  
        if(sobj == SOBJECT_AD_PRODUCT){
            startDate = yesterdayDate;
        }else if(sobj == SOBJECT_AD_REV_DAILY){
            startDate = b4yesterdayDate;
        }else if(sobj == SOBJECT_AD_REV_MONTHLY){
            startDate = daystartLastMonth;
        }else if(sobj == SOBJECT_AD_REV_MONTHLY_MTD){
            startDate = daystartThisMonth;
            if(todayDate.day() == 1) startDate = daystartLastMonth;
        }
        return startDate;
    }
    
    /**
     * Date Rang for DART6 : End Date
     */
    public static DateTime getEndDate(String sobj){
        DateTime endDate;
        if(sobj == SOBJECT_AD_PRODUCT){
            endDate = todayDate;
        }else if(sobj == SOBJECT_AD_REV_DAILY){
            endDate = yesterdayDate;
        }else if(sobj == SOBJECT_AD_REV_MONTHLY){
            endDate = daystartLastMonth;
        }else if(sobj == SOBJECT_AD_REV_MONTHLY_MTD){
            endDate = yesterdayDate;
        }
        return endDate;
    }
    
    /** 
     *  CHANGES FOR ZONE
     *  initate the ImportDelivery Process 
     *  import by zone, zone would be APAC/EMEA/America
     *  @param zone
     */
    public static void start(String scheduleType,String sobj, String zone){
        start(scheduleType, sobj, getStartDate(sobj).dateGMT(), getEndDate(sobj).dateGMT(), zone);
    }
    
    
    /** initate the ImportDelivery Process 
     *  - just insert the the relavant DDS from the eligible Logins
     *  - should be called from Scheduler
     *  - manually
     *  @param scheduleType
     *  @param sobj
     */
    public static void start(String scheduleType,String sobj)
    {
        start(scheduleType, sobj, getStartDate(sobj).dateGMT(), getEndDate(sobj).dateGMT(), null);
    }
    
    /** dart6: create a report job at dart server */
    public static void createReportJob(DART_Delivery_Support__c dds, DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService, Dart6_ReportService.ReportJob reportJob)
    {
        dds.Job_Id__c = runReportRequest(reportService, reportJob);
        dds.DART_Status__c = REPORT_QUERY_INPROGRESS;
        dds.Status__c = DART_STATUS_AWAIT;
        dds.Attempt__c = dds.Attempt__c + 1;
        update dds;
        createSchedulerWatcher(dds.Id, dds.Sobject__c, dds.Zone__c);
    } 
    
    /** createSchedulerWatcher */
    public static void createSchedulerWatcher(String ddsId, String sObj, String zone){
        DART6SchReportRequestWatcher watcher = new DART6SchReportRequestWatcher(ddsId);
        System.schedule('DART6 Delivery RunningReport Checker for Report ' + sObj + (zone != null ? '' : ' (' + zone + ')')+' at ' + Datetime.now()  , watcher.createCronExpForNextFireTime(), watcher);
    } 
    
    /** CHANGES FOR ZONE
     * Next ad login with zone
     */
    public static void startNextAdServer(String sobj, String scheduletype, String zone){
        List<DART_Delivery_Support__c> ldds = [Select AdServer_Login__r.Name, AdServer_Login__r.Network_ID__c, AdServer_Login__r.RecordType.name,Status__c, Sobject__c, Schedule_Type__c, Job_Id__c, DART_Status__c, Attempt__c, AdServer_Login__c, Zone__c, By_Zone__c, Query_Start_Date__c, Query_End_Date__c, Retry_Counter__c From DART_Delivery_Support__c Where Status__c =: DART_STATUS_NEW And Sobject__c =: sobj And Schedule_Type__c =: scheduletype And Zone__c =: zone limit 1];
        if(ldds.isEmpty()) return;
        DART6BatchDeliverySupport batchSupport = new DART6BatchDeliverySupport(ldds[0].Id, DART6BatchDeliverySupport.CALL_TYPE_REQUEST_REPORT);
        ID batchprocessstartNextAdServerid = Database.executeBatch(batchSupport);
    }
    
    /**
    * Next ad login 
    */
    public static void startNextAdServer(String sobj, String scheduletype){
        List<DART_Delivery_Support__c> ldds = [Select AdServer_Login__r.Name, AdServer_Login__r.Network_ID__c, AdServer_Login__r.RecordType.name,Status__c, Sobject__c, Schedule_Type__c, Job_Id__c, DART_Status__c, Attempt__c, AdServer_Login__c, Zone__c, By_Zone__c, Query_Start_Date__c, Query_End_Date__c, Retry_Counter__c From DART_Delivery_Support__c Where Status__c =: DART_STATUS_NEW And Sobject__c =: sobj And Schedule_Type__c =: scheduletype limit 1];
        if(ldds.isEmpty()) return;
        DART6BatchDeliverySupport batchSupport = new DART6BatchDeliverySupport(ldds[0].Id, DART6BatchDeliverySupport.CALL_TYPE_REQUEST_REPORT);
        ID batchprocessstartNextAdServerid = Database.executeBatch(batchSupport);
    }
    
    /** dart6: check job status */ 
    public static void checkJobStatus(DART_Delivery_Support__c dds) 
    {
        //dds = getDeliverySupportRecord(dds.Id);
        DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService = DeliveryController.buildQueryService(dds);
        //request to get status here: COMPLETED, IN_PROGRESS, FAILED
        String reportJobStatus = reportService.getReportJobStatus((long)dds.Job_Id__c);
        // if complete ok -> run controller batch from importDelivery()
        if(reportJobStatus == DART6_REPORTSERVICE.REPORTJOBSTATUS_COMPLETED){
            DeliveryController controller = new DeliveryController(dds);
            controller.setReportService(reportService);
            controller.setJobid((long)dds.Job_Id__c);
            controller.importDelivery();
            processBatchDelivery(dds, controller.getListDart());
            controller = null;
            return;
        }
        
        // If attempt more than MAX_ATTAMPT_WAITING, report job is stuck. A new job will be attempted 
        if( (dds.Attempt__c > MAX_ATTAMPT_WAITING && dds.Status__c == DART_STATUS_AWAIT) || 
            reportJobStatus == DART6_REPORTSERVICE.REPORTJOBSTATUS_FAILED ){
            String loggedDescription = 'Requesting report takes time too long with more than ' + MAX_ATTAMPT_WAITING + ' attempts';
            // report job complete but FAILED
            if (reportJobStatus == DART6_REPORTSERVICE.REPORTJOBSTATUS_FAILED) loggedDescription = 'Failed to query report from server dues to connection problem';
            retryImport(dds, new DARTLogger.LogMessage(
                                dds.Id ,'Import Delivery Process was abandoned',
                                'DeliveryController.checkJobStatus', dds.AdServer_Login__r.RecordType.name,
                                DARTLogger.TYPE_ERROR, dds.Status__c, loggedDescription ));
            return;
        }
            
        // if in progress -> run scheduler watcher, attempt++
        dds.DART_Status__c = REPORT_QUERY_INPROGRESS;
        dds.Status__c = DART_STATUS_AWAIT;
        dds.Attempt__c = dds.Attempt__c + 1;
        createSchedulerWatcher(dds.Id, dds.Sobject__c, dds.Zone__c);
        update dds;
    }
    
    
    /** 
     *  dart6: download xml : process in batch
     */
    public void importDelivery()
    {
        //create request
        HTTPWrapper.IGenericRequest deliveryRequest = FactoryDARTRequest.getInstance().createDartDeliveryRequest(login,breakDown, jobid, reportService, dartDelStatus.Sobject__c, dartDelStatus.Query_Start_Date__c, dartDelStatus.Query_End_Date__c);
        
        //create parser 
        DART6Parser.IDartParser deliveryParser = FactoryParser.getInstance().createDeliveryParser_EU(login.RecordType.Name, dartDelStatus.Sobject__c);
        
        // create connection
        DARTObject.IDARTConnector deliveryCon = FactoryConnector.getInstance().createConnector(login.RecordType.Name,deliveryRequest, deliveryParser);
        deliveryCon.connect();    
        invokedMethod = deliveryRequest.getInvokedMethod();
        
        //getDartObjects
        listDartObjects = deliveryCon.getDartObjects();
    }
    
    public static DART_Delivery_Support__c getDeliverySupportRecord(String recId){
         return [Select Retried_DART_Delivery_Support__c, AdServer_Login__r.Name, AdServer_Login__r.Network_ID__c, AdServer_Login__r.RecordType.name,Status__c, Sobject__c, Schedule_Type__c, Job_Id__c, DART_Status__c, Attempt__c, AdServer_Login__c, Retry_Counter__c, Zone__c, By_Zone__c, Query_Start_Date__c, Query_End_Date__c From DART_Delivery_Support__c where Id =: recId];
    } 
    
    public static Map<String, String> mGeneralQuery = new Map<String, String>{
        SOBJECT_AD_REV_DAILY => 'Select Ad_Id__c, Order_Id__c, Delivered_AI__c, Delivered_AI_Lifetime__c, Clicks_Recorded__c, Clicks_Recorded_Lifetime__c, OSI__c, Product_Country__c, Transaction_Date__c, Ad_Product__r.Product2__r.Advertising_Medium__r.Quantity_Multiplier__c From ' + AD_REVENUE_DAILY_API_NAME + ' Where %DATECRIT% Product_Country__c =\'%1\' AND (Ad_Id__c <> null OR Order_Id__c <> null)',
        SOBJECT_AD_REV_MONTHLY => 'Select Ad_Id__c, Order_Id__c, Delivered_AI__c, Delivered_AI_Lifetime__c, Clicks_Recorded__c, Clicks_Recorded_Lifetime__c, Product_Country__c, Transaction_Date__c, Ad_Product__r.Product2__r.Advertising_Medium__r.Quantity_Multiplier__c From ' + AD_REVENUE_MONTHLY_API_NAME  + ' Where %DATECRIT% Product_Country__c =\'%1\' AND (Ad_Id__c <> null OR Order_Id__c <> null)',
        SOBJECT_AD_REV_MONTHLY_MTD => 'Select Ad_Id__c, Order_Id__c, Delivered_AI__c, Delivered_AI_Lifetime__c, Clicks_Recorded__c, Clicks_Recorded_Lifetime__c, Product_Country__c, Transaction_Date__c, Ad_Product__r.Product2__r.Advertising_Medium__r.Quantity_Multiplier__c From ' + AD_REVENUE_MONTHLY_API_NAME  + ' Where %DATECRIT% Product_Country__c =\'%1\' AND (Ad_Id__c <> null OR Order_Id__c <> null)',
        SOBJECT_AD_PRODUCT => 'Select Ad_Id__c, Adserver_ID_Order_ID__c, Delivered_Impressions__c, Delivered_Clicks__c, OSI__c, Product2__r.Site__r.Country__c, Product2__r.RecordType.DeveloperName, Product2__r.RecordType.Name, Deliverystats_Update_Date__c, Product2__r.Advertising_Medium__r.Quantity_Multiplier__c From ' + AD_PRODUCT_API_NAME + ' Where %DATECRIT% Product2__r.Site__r.Country__c =\'%1\' AND (Ad_Id__c <> null OR Adserver_ID_Order_ID__c <> null)'
    };

    public static Map<String, String> mQuerySObject = new Map<String, String>{
        SOBJECT_AD_REV_DAILY => mGeneralQuery.get(SOBJECT_AD_REV_DAILY).replace('%DATECRIT%', 'Transaction_Date__c >= ' + QUERY_START_DATE + ' AND Transaction_Date__c <= ' + QUERY_END_DATE + ' AND '),
        SOBJECT_AD_REV_MONTHLY => mGeneralQuery.get(SOBJECT_AD_REV_MONTHLY).replace('%DATECRIT%', 'Transaction_Date__c >= ' + QUERY_START_DATE + ' AND Transaction_Date__c <= ' + QUERY_END_DATE + ' AND '),
        SOBJECT_AD_REV_MONTHLY_MTD => mGeneralQuery.get(SOBJECT_AD_REV_MONTHLY).replace('%DATECRIT%', 'Transaction_Date__c >= ' + QUERY_START_DATE + ' AND Transaction_Date__c <= ' + QUERY_END_DATE + ' AND '),
        SOBJECT_AD_PRODUCT => mGeneralQuery.get(SOBJECT_AD_PRODUCT).replace('%DATECRIT%', '(' +
                            '(from_Date__c <= ' + QUERY_START_DATE + ' AND until_Date__c >= ' + QUERY_END_DATE + ') ' + 
                            'OR (from_Date__c <= ' + QUERY_START_DATE + ' AND until_Date__c >= ' + QUERY_START_DATE + ') ' + 
                            'OR (from_Date__c <= ' + QUERY_END_DATE + ' AND until_Date__c >= ' + QUERY_END_DATE + ') ' +
                            ') AND ')
    };
         
    /**Called from 'start' of Main scheduler. and from Batch to continue to next Login */ 
    public static void doStart(DART_Delivery_Support__c dds)
    {   
        if(DARTUtil.DART6.equals(dds.AdServer_Login__r.RecordType.name)) 
        {
            //Chr-10-03-2015: comment out the filter bellow
            //dds.AdServer_Login__r.Name == 'UK' ? 'WHERE ORDER_NAME LIKE \'UK_%\'' : ''; just only for testing on network UK
            //String addQuery = ''; //dds.AdServer_Login__r.Name == 'UK' ? 'WHERE ORDER_NAME LIKE \'UK_%\'' : '';
            //SCR:25-06-2016 add filter get all report in case order.po_number<>"Binder"
            //String addQuery = 'WHERE ORDER_PO_NUMBER <> \'Bidder\'';
            
            //NK:27/01/2017:#10480. added more filtering <> Prebid
            String addQuery = 'WHERE ORDER_PO_NUMBER <> \'Bidder\' AND NOT ORDER_NAME LIKE \'%Prebid%\'';
            
            DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService = buildQueryService(dds);
            Dart6_ReportService.ReportJob reportJob = buildReportQuery(dds, addQuery);
            createReportJob(dds, reportService, reportJob);
        }
    }
    
    public static void processBatchDelivery(DART_Delivery_Support__c dds, List<DARTObject.IDARTGenericObject> lstDartObject){
        String dsStartDate = DateTime.newInstance(dds.Query_Start_Date__c.year(),dds.Query_Start_Date__c.month(),dds.Query_Start_Date__c.day()).format(DARTUtil.DART_DATEFORMAT_QUERY) ;
        String dsEndDate = DateTime.newInstance(dds.Query_End_Date__c.year(),dds.Query_End_Date__c.month(),dds.Query_End_Date__c.day()).format(DARTUtil.DART_DATEFORMAT_QUERY) ;
        String queryStr = mQuerySObject.get(dds.Sobject__c).replace('%1', dds.AdServer_Login__r.Name).replace('%2', dds.AdServer_Login__r.RecordType.Name);
        queryStr = queryStr.replaceAll(QUERY_START_DATE, dsStartDate).replaceAll(QUERY_END_DATE, dsEndDate);
        BatchDeliveryProcess batchDelivery = new BatchDeliveryProcess(queryStr, lstDartObject, dds.Id);

        ID batchprocessid = Database.executeBatch(batchDelivery, 30);
    }
    
    /** 
     * BuildQueryService with DART_Delivery_Support
     */
    public static DART6_REPORTSERVICE.REPORTServiceInterfacePort buildQueryService(DART_Delivery_Support__c dds){       
        return buildQueryService(dds.AdServer_Login__r.Name, dds.AdServer_Login__r.Network_ID__c);
    } 
    
    /** 
     * BuildQueryService with adServName & netId
     */
    public static DART6_REPORTSERVICE.REPORTServiceInterfacePort buildQueryService(String adServName, String netId){
        // Get Authentication 
        AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6, adServName);
        String authToken = DARTUtil.getAccessToken(login); // new version 201411
        
        // Build Service Request Header
        DART6_REPORTSERVICE.SoapRequestHeader header = new DART6_REPORTSERVICE.SoapRequestHeader();
        header.applicationName='ReportService';
        header.networkCode= netId;
        
        Map<String,String> inputHttpHeaders_x = new Map<String, String>();     // new version 201411
        inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);          // new version 201411
 
        DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService = new DART6_REPORTSERVICE.ReportServiceInterfacePort();
        reportService.RequestHeader = header;
        reportService.inputHttpHeaders_x = inputHttpHeaders_x;       // new version 201411
        reportService.timeout_x = 120000;//Extend timeout due to massive download size
        return reportService;
    }
    /**
     * @updated: 31-07-2015
     * Chr: #6975
     * Desc: Due to google will not supported with MERGED_ And _LIFETIME_MERGED_
     * So we have to change to use new columns & deminsions 'TOTAL_LINE_ITEM_LEVEL_IMPRESSIONS','TOTAL_LINE_ITEM_LEVEL_CLICKS','AD_SERVER_DELIVERY_INDICATOR'
     * 'LINE_ITEM_LIFETIME_IMPRESSIONS', 'LINE_ITEM_LIFETIME_CLICKS'
     * 
     */
    private static Map<String,String[]> queryFieldsDART6 = new Map<String, String[]>{
        SOBJECT_AD_PRODUCT => new String[]{'TOTAL_LINE_ITEM_LEVEL_IMPRESSIONS','TOTAL_LINE_ITEM_LEVEL_CLICKS'},
        SOBJECT_AD_REV_DAILY => new String[]{'TOTAL_LINE_ITEM_LEVEL_IMPRESSIONS','TOTAL_LINE_ITEM_LEVEL_CLICKS'},
        SOBJECT_AD_REV_MONTHLY => new String[]{'TOTAL_LINE_ITEM_LEVEL_IMPRESSIONS','TOTAL_LINE_ITEM_LEVEL_CLICKS'},
        SOBJECT_AD_REV_MONTHLY_MTD => new String[]{'TOTAL_LINE_ITEM_LEVEL_IMPRESSIONS','TOTAL_LINE_ITEM_LEVEL_CLICKS'}
    };
    
    private static Map<String,String[]> dimensionFieldsDART6 = new Map<String, String[]>{
        SOBJECT_AD_PRODUCT => new String[]{'ORDER_ID', 'LINE_ITEM_ID'},
        SOBJECT_AD_REV_DAILY => new String[] {'ORDER_ID', 'LINE_ITEM_ID', 'DATE'},
        SOBJECT_AD_REV_MONTHLY => new String[] {'ORDER_ID', 'LINE_ITEM_ID', 'MONTH_AND_YEAR'},      //@vitou 05-12-2014 : new Version 201411 --> change from MONTH to MONTH_AND_YEAR
        SOBJECT_AD_REV_MONTHLY_MTD => new String[] {'ORDER_ID', 'LINE_ITEM_ID', 'MONTH_AND_YEAR'}   //@vitou 05-12-2014 : new Version 201411 --> change from MONTH to MONTH_AND_YEAR
    };
    
    /**
     * Build Query for report service
     */
    public static Dart6_ReportService.ReportJob buildReportQuery(DART_Delivery_Support__c dds, String addQuery){
        String sobjType = dds.Sobject__c;
        // Create report query.
        Dart6_ReportService.Statement statement = new Dart6_ReportService.Statement();
        statement.query = addQuery;
        Dart6_ReportService.ReportQuery reportQuery = new Dart6_ReportService.ReportQuery();
        reportQuery.statement = statement;
        reportQuery.dateRangeType = 'CUSTOM_DATE';
        reportQuery.columns = queryFieldsDART6.get(sobjType);
        reportQuery.dimensions = dimensionFieldsDART6.get(sobjType);
        
        //Date startDate = Date.newInstance(2016,07,11);
        //Date endDate =  Date.newInstance(2016,07,12);
        //dds = [Select AdServer_Login__r.Name, AdServer_Login__r.Network_ID__c, AdServer_Login__r.RecordType.name,Status__c, Sobject__c, Schedule_Type__c, Job_Id__c, DART_Status__c, Attempt__c, AdServer_Login__c, Zone__c, By_Zone__c, Query_Start_Date__c, Query_End_Date__c, Retry_Counter__c From DART_Delivery_Support__c Where id='a0t11000001HTiG' ];
        reportQuery.startDate = new Dart6_ReportService.Date_x();
        reportQuery.startDate.year = dds.Query_Start_Date__c.year();
        reportQuery.startDate.month = dds.Query_Start_Date__c.month();
        reportQuery.startDate.day = dds.Query_Start_Date__c.day();
        
        reportQuery.endDate = new Dart6_ReportService.Date_x();
        reportQuery.endDate.year = dds.Query_End_Date__c.year();
        reportQuery.endDate.month = dds.Query_End_Date__c.month();
        reportQuery.endDate.day = dds.Query_End_Date__c.day();
        reportQuery.dimensionAttributes = new String[]{'LINE_ITEM_DELIVERY_INDICATOR'};
        if(sobjType == SOBJECT_AD_PRODUCT){
            reportQuery.dimensionAttributes.addall(new String[]{'LINE_ITEM_LIFETIME_IMPRESSIONS', 'LINE_ITEM_LIFETIME_CLICKS'}); 
        }else if(sobjType == SOBJECT_AD_REV_DAILY){
            reportQuery.dimensionAttributes.addall(new String[]{'LINE_ITEM_LIFETIME_IMPRESSIONS', 'LINE_ITEM_LIFETIME_CLICKS'});
        }
        //test dateRange
        //reportQuery.statement.query = 'WHERE LINE_ITEM_ID IN (9385390, 9320350)';
        //reportQuery.dateRangeType = 'CUSTOM_DATE';
        // reportQuery.statement.query = 'WHERE LINE_ITEM_ID IN (2782687366)';
        Dart6_ReportService.ReportJob reportJob = new Dart6_ReportService.ReportJob();
        reportJob.reportQuery = reportQuery;
        return reportJob;
    }
    
    /**
     * @return runningReportId as String
     */
    public static Long runReportRequest(DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService, Dart6_ReportService.ReportJob reportJob){
        // Run report job.
        reportJob = reportService.runReportJob(reportJob);
        return reportJob.id;
    }
    
    /**
    * Retry another job after a time-out failure OR job has been stuck
    */
    public static void retryImport(DART_Delivery_Support__c failedDds, DARTLogger.LogMessage logmsg){
        if(failedDds.Status__c != DART_STATUS_FINISHED && failedDds.Retry_Counter__c < MAX_RETRY_IMPORT){
            DART_Delivery_Support__c retriedDds = failedDds.clone(false);
            retriedDds.Attempt__c = 0;
            retriedDds.Status__c = DART_STATUS_NEW;
            retriedDds.DART_Status__c = null;
            retriedDds.Job_Id__c = null;
            retriedDds.Retry_Counter__c = failedDds.Retry_Counter__c + 1;
            insert retriedDds;
            failedDds.Retried_DART_Delivery_Support__c = retriedDds.Id;
            failedDds.DART_Status__c = REPORT_QUERY_RETRY;
        }
        failedDds.Status__c = DART_STATUS_FINISHED;
        if(failedDds.DART_Status__c != REPORT_QUERY_RETRY) failedDds.DART_Status__c = REPORT_QUERY_FAILED;
        update failedDds;
        if(logmsg != null) DARTLogger.getInstance().log(failedDds.Id,new List<DARTLogger.LogMessage>{logmsg});
        if(failedDds.By_Zone__c) DeliveryController.startNextAdServer(failedDds.Sobject__c, failedDds.Schedule_Type__c, failedDds.Zone__c);
        else DeliveryController.startNextAdServer(failedDds.Sobject__c, failedDds.Schedule_Type__c);
    }
}