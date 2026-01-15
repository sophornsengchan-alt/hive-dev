/** Batch process of Delivery
 *  Request all Report From Dart and check with relevant SObjects
 *  1.  OpportunityProduct (daily run and manual run) 
 *  2.  Rev__c(Revenue Item) (monthly run) 
 *  3.  Metric__c(Metric) (daily run)
 *  @Created Date: 18/01/2013  
 *  @update: chr - replace old objects with the new objects
 *      - Revenue_Schedule_daily__c to Metric__c
 *      - Revenue_Schedule__c to Rec__c
 @  Change history:  14.12.2020 / Acmatac SEING / US-0007908 Merge the EU and NA process
                  : 14.09.2023 /vadhanak voun / US-0013942 - PART 4 - Upgrade API version of all classes having an API version lower than 31
 */  
global without sharing class BatchDeliveryProcess implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallOuts{
    /* ---------------------------------
    ------ VARIABLE START ------
    -----------------------------------*/

    private static final String SOBJ_FIELD_SEP = '.';
    private Map<String, DARTObject.IDARTGenericObject> mWithAdId;
    private Map<String, List<DARTObject.IDARTGenericObject>> mWithOutAdId;
    private String queryString;
    private String networkId;
    private String sobj;
    @testVisible
    private DART_Delivery_Support__c dds;
    private Integer dartSize = 0;
    private Set<String> ignoredFields = new Set<String>{'Ad_Id__c', 'Adserver_ID_Order_ID__c', 'Day__c', 'Month__c'};
    private List<String> successRecords = new List<String>();
    private List<String> unupdateRecords = new List<String>();
    private List<DARTObject.IDARTGenericObject> listImport= new List<DARTObject.IDARTGenericObject>();
    private List<DARTObject.DARTDelivery> listDeliveries = new  List<DARTObject.DARTDelivery>(); //list none update delivery
    private List<String> loggedString = new List<String>(); // 14-12-2020 US-0007908, Acmatac

    public static Boolean ignoreCalNonBanner = false; 

    /**
        * D6 FieldNames:
        * mergeReservationImpressionsDelivered -> MERGED_AD_SERVER_IMPRESSIONS
        * mergeLineItemDeliveryIndicator -> MERGED_AD_SERVER_DELIVERY_INDICATOR
        * mergeReservationClicksDelivered -> MERGED_AD_SERVER_CLICKS
        @ Change history:  14.12.2020 / Acmatac SEING / US-0007908 Move the variable from EU.
    */
    public static final Map<String, Map<String, String>> mFieldsDartToSObj_EU = new Map<String, Map<String, String>> {
        //Matching OpportunityLineItem
        DeliveryController.AD_PRODUCT_API_NAME => new Map<String, String> {
            'Ad_Id__c' => DARTObject.DEL_FIELD_ADID, //'lineItemId',
            'Adserver_ID_Order_ID__c' => DARTObject.DEL_FIELD_ORDERID, //'orderId',
            // 'Delivered_AI_LT__c' => DARTObject.DEL_FIELD_ADDELIVERED, //'mergeReservationImpressionsDelivered', Delivered (Lifetime)
            'Delivered_Impressions__c' => DARTObject.DEL_FIELD_ADDELIVERED, //'mergeReservationImpressionsDelivered', Delivered (Lifetime)
            'Delivered_Clicks__c' => DARTObject.DEL_FIELD_ADCLICKED_LIFETIME, //'mergeReservationClicksDelivered', Clicks Recorded (Lifetime) (delivered_Clicks_LT__c)
            'OSI__c' => DARTObject.DEL_FIELD_ADOSI
        }, //'mergeLineItemDeliveryIndicator', OSI (Lifetime)
        //Matching Revenue_Schedules2__c
        DeliveryController.AD_REVENUE_MONTHLY_API_NAME => new Map<String, String> {
            'Delivered_AI__c' => DARTObject.DEL_FIELD_IMPRESS_DELIVERED, //'mergeReservationImpressionsDelivered', Impressions Delivered  
            'Delivered_AI_Lifetime__c' => DARTObject.DEL_FIELD_ADDELIVERED, //'mergeReservationImpressionsDelivered', Delivered (Lifetime) 
            'Clicks_Recorded__c' => DARTObject.DEL_FIELD_CLICKS_DELIVERED, //'mergeReservationClicksDelivered', Clicks Recorded 
            'Clicks_Recorded_Lifetime__c' => DARTObject.DEL_FIELD_ADCLICKED_LIFETIME, //'mergeReservationClicksDelivered', Clicks Recorded (Lifetime)
            //Revenue_Schedules2__c Month To Date
            DeliveryController.SOBJECT_AD_REV_MONTHLY_MTD + SOBJ_FIELD_SEP + 'Delivered_AI_MTD__c' => DARTObject.DEL_FIELD_IMPRESS_DELIVERED, //'mergeReservationImpressionsDelivered', Impressions Delivered  
            DeliveryController.SOBJECT_AD_REV_MONTHLY_MTD + SOBJ_FIELD_SEP + 'Clicks_Recorded_MTD__c' => DARTObject.DEL_FIELD_CLICKS_DELIVERED //'mergeReservationClicksDelivered', Clicks Recorded 
        },
        //Revenue_Schedule_daily2__c
        DeliveryController.AD_REVENUE_DAILY_API_NAME => new Map<String, String> {
            'Delivered_AI__c' => DARTObject.DEL_FIELD_IMPRESS_DELIVERED, //'mergeReservationImpressionsDelivered', Impressions Delivered  
            'Delivered_AI_Lifetime__c' => DARTObject.DEL_FIELD_ADDELIVERED, //'mergeReservationImpressionsDelivered', Delivered (Lifetime) 
            'Clicks_Recorded__c' => DARTObject.DEL_FIELD_CLICKS_DELIVERED, //'mergeReservationClicksDelivered', Clicks Recorded 
            'Clicks_Recorded_Lifetime__c' => DARTObject.DEL_FIELD_ADCLICKED_LIFETIME, //'mergeReservationClicksDelivered', Clicks Recorded (Lifetime)
            // 'OSI__c' => DARTObject.DEL_FIELD_ADOSI //'mergeLineItemDeliveryIndicator'
            'OSI_RD__c' => DARTObject.DEL_FIELD_ADOSI //'mergeLineItemDeliveryIndicator'
        }
    };

    /* ---------------------------------
    ------ VARIABLE END ------
    -----------------------------------*/
    /** 
     * For executing on first adlogin 
     */
    public BatchDeliveryProcess(String queryString, List<DARTObject.IDARTGenericObject> lstDartObject, String ddsId){ 
        dartSize = lstDartObject.size();
        this.dds = DeliveryController.getDeliverySupportRecord(ddsId);
        this.networkId = dds.AdServer_Login__r.Name;
        this.queryString = queryString;
        this.sobj = dds.Sobject__c;
        this.listImport = lstDartObject;
    }
    
    /**
     * Start batch
     */
    global Database.QueryLocator start(Database.BatchableContext BC){
        initMapperDartObject_EU(this.listImport);
        return Database.getQueryLocator(queryString + (Test.isRunningTest()?' LIMIT 1':'')); //NK: 06/05/2013: fixed UnexpectedException: No more than one excecuteBatch can be called from withinn a testmethod.
    }
     
    /**
     * Execute batch
     */ 
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        doExecute_EU(scope);
    }  
    
    /**
     * Finish batch
     */
    global void finish(Database.BatchableContext BC){
        try{
            dofinish();
            if(dds.By_Zone__c) DeliveryController.startNextAdServer(dds.Sobject__c, dds.Schedule_Type__c, dds.Zone__c);
            else DeliveryController.startNextAdServer(dds.Sobject__c, dds.Schedule_Type__c);
        }catch(Exception e){
            DARTLogger.getInstance().log(dds.Id,new List<DARTLogger.LogMessage>{new DARTLogger.LogMessage(dds.Id ,'Import Delivery Process Fault', 'BatchDeliveryProcess.finish', dds.AdServer_Login__r.RecordType.name, DARTLogger.TYPE_ERROR, dds.DART_Status__c, e + '')});
            if(dds.By_Zone__c) DeliveryController.startNextAdServer(dds.Sobject__c, dds.Schedule_Type__c, dds.Zone__c);
            else DeliveryController.startNextAdServer(dds.Sobject__c, dds.Schedule_Type__c);
        } 
    }

    /* ---------------------------------
    ------ METHOD START ------
    -----------------------------------*/
    
    // 14-12-2020 US-0007908, Acmatac move from EU Instance
    global void doExecute_EU(List<Sobject> scope){
        List<DARTLogger.LogMessage> ldartLogger = new List<DARTLogger.LogMessage>();
        List<Sobject> lsobj = new List<Sobject>();
        
        for(Sobject sobj : scope){
        
            String sobjId = sobj.get('Id') + '';
            try{
                if(submitToSFRecord_EU(sobj)){
                    lsobj.add(sobj);
                    successRecords.add(sobjId); 
                }else{
                    unupdateRecords.add(sobjId);
                }
            }catch(Exception e){unupdateRecords.add(sobjId);
                ldartLogger.add(new DARTLogger.LogMessage(
                    sobj.Id ,'Import Delivery Process Fault',
                    'BatchDeliveryProcess.execute', dds.AdServer_Login__r.RecordType.name,
                    DARTLogger.TYPE_ERROR, e + '', e.getStackTraceString()));
            } 
        }
        if(!lsobj.isEmpty()) update lsobj;
        if(!ldartLogger.isEmpty()) DARTLogger.getInstance().log(dds.Id,ldartLogger);
    }

    global void dofinish(){
        dds.DART_Status__c = DeliveryController.REPORT_QUERY_COMPLETED;
        dds.Status__c = DeliveryController.DART_STATUS_FINISHED;
        update dds;
        Attachment attlog = createAttachedLogfile(true);
        DARTLogger.getInstance().log(dds.Id,new List<DARTLogger.LogMessage>{new DARTLogger.LogMessage(
                                dds.Id ,'Import Delivery Process',
                                'BatchDeliveryProcess.finish',dds.AdServer_Login__r.RecordType.name,
                                DARTLogger.TYPE_SUCCESS, dds.DART_Status__c, 'Update size: ' + successRecords.size() + ' of '+ dartSize + ' [ Attachment Id Details ' + attlog.Id + ' ]')});
    }
    
     /** 
     * Clear all completed schedule
     * 
     */
    @testVisible
    private void clearCompletedSch() {
        
        if(!Test.isRunningTest()) {
            Set<String> setStatus = new Set<String>{'COMPLETED', 'DELETED'};
            for(CronTrigger cron : [SELECT Id FROM CronTrigger WHERE State In : setStatus And  (NOT CronJobDetail.Name Like 'SCH_CustomJobDispatcher%')  Limit 150]) {
                system.abortJob(cron.id);
            }
            //delete all job records for jobs that have finished before Yesterday’s date.
            Integer countDay = System.purgeOldAsyncJobs(Date.today().addDays(-5));
        }
    }

    /**
     * For Matching Ad Id from report with Ad_Id__c
     * US-0007908 14-12-2020, Acmatac move from EU instance
     */
    private void initMapperDartObject_EU(List<DARTObject.IDARTGenericObject> lstDartObject){
        if(mWithAdId==null && mWithOutAdId==null){
            mWithAdId = new Map<String, DARTObject.IDARTGenericObject>();
            mWithOutAdId = new Map<String, List<DARTObject.IDARTGenericObject>>();
            for(DARTObject.IDARTGenericObject dObj : lstDartObject){
                DARTObject.DARTDelivery dartObj = (DARTObject.DARTDelivery)dObj;
                String strCombKey = getCombinedKeyDart(dartObj, false);
                if(dartObj.getAdId() != ''){
                    mWithAdId.put(strCombKey, dartObj);
                    loggedString.add(strCombKey + ' ========= ' + String.valueOf(dartObj));
                }
                if(dartObj.getOrderId() != ''){
                    String combinkey = getCombinedKeyDart(dartObj, true);
                    if(!mWithOutAdId.containsKey(combinkey)){
                        mWithOutAdId.put(combinkey, new List<DARTObject.IDARTGenericObject>());
                    }else{
                        mWithOutAdId.get(combinkey).add(dartObj);
                    }
                }
            }
        }

        
    }
    
    @testVisible
    private String getCombinedKeyDart(DARTObject.DARTDelivery dartObj, Boolean isAdIdNull){
        String dateString = Test.isRunningTest() ? Date.today().format() : dartObj.getDateString();
        
        dateString = dateString.split(' ')[0];
        if(isAdIdNull) return dartObj.getOrderId() + SOBJ_FIELD_SEP + networkId + SOBJ_FIELD_SEP + dateString;
        return dartObj.getAdId() + SOBJ_FIELD_SEP + networkId + SOBJ_FIELD_SEP + dateString;
    }

    /*
    @  Change history:  14.12.2020 / Acmatac SEING / US-0007908 Merge the EU and NA process
    */
    private String getCombinedKeySObject_EU(SObject sobj, Boolean isAdIdNull){
        return getCombinedKeySObject_EU(sobj, isAdIdNull, null);
    }

    /*
    @  Change history:  14.12.2020 / Acmatac SEING / US-0007908 Merge the EU and NA process
    @                   14.06.2021 / Acmatac SEING / US-0009694 - Deliveries - bug related to Site name vs code
    */
    private String getCombinedKeySObject_EU(SObject sobj, Boolean isAdIdNull, String adId){
        Map<String, String> mTypeField = new Map<String, String>{
            DeliveryController.AD_REVENUE_MONTHLY_API_NAME => 'Product_Country__c', 
            DeliveryController.AD_REVENUE_DAILY_API_NAME => 'Product_Country__c',
            // 14.06.2021 / Acmatac SEING / US-0009694 Update from 'Product2__r.Site__r.Country__c' => 'Product2__r.Site__r.Name'
            DeliveryController.AD_PRODUCT_API_NAME => 'Product2__r.Site__r.Name'
        };
        
        Map<String, String> mDateField = new Map<String, String>{
            DeliveryController.AD_REVENUE_MONTHLY_API_NAME => 'Transaction_Date__c', 
            DeliveryController.AD_REVENUE_DAILY_API_NAME => 'Transaction_Date__c',
            DeliveryController.AD_PRODUCT_API_NAME => ''
        }; 
         
        String sobjType = String.valueOf(sobj.getSObjectType());
        
        String valDate = mDateField.get(sobjType) == '' ? '' : sobj.get(mDateField.get(sobjType)) + '';

        if(valDate != ''){
            DateTime valDatetime = DateTime.valueOf(valDate);
            if(sobjType == DeliveryController.AD_REVENUE_MONTHLY_API_NAME) valDate = valDatetime.format('yyyy-MM'); //MINT_TO_MONTH.get(valDatetime.month());
            //csv format return date as yyyy-mm-dd
            else if(sobjType == DeliveryController.AD_REVENUE_DAILY_API_NAME) valDate = valDatetime.format('yyyy-MM-dd');
        } 

        if (Test.isRunningTest()) valDate =  Date.today().format(); //MN-13072021-US-0009770;
        
        String networkfield = mTypeField.get(sobjType);
        String valNetwork = '';
        // 14.06.2021 / Acmatac SEING / US-0009694 Update from 'Product2__r.Site__r.Country__c' => 'Product2__r.Site__r.Name'
        if(networkfield == 'Product2__r.Site__r.Name') valNetwork += sobj.getSObject('Product2__r').getSObject('Site__r').get('Country__c');
        else valNetwork += sobj.get(networkfield);
        
        //If Ad_Id__c = “” match Order Id from report with Order_Id__c, oppline If Ad_Id__c = “” match Order Id from report with Adserver_ID_Order_ID__c
        if(isAdIdNull) return (sobjType == DeliveryController.AD_PRODUCT_API_NAME ? sobj.get('Adserver_ID_Order_ID__c')  : sobj.get('Order_Id__c')) + SOBJ_FIELD_SEP + valNetwork + SOBJ_FIELD_SEP + valDate; 
        
        if(adId==null){
            return sobj.get('Ad_Id__c') + SOBJ_FIELD_SEP + valNetwork + SOBJ_FIELD_SEP + valDate; 
        }else{
            //Add logic here
            return adId + SOBJ_FIELD_SEP + valNetwork + SOBJ_FIELD_SEP + valDate;
        }
    }
    
    /**
     * • Match Ad Id from report with Ad_Id__c and submit values to SF according to 5.3
     * • If Ad_Id__c = “” match Order Id from report with Order_Id__c, sum up values and submit sum to SF according to 5.3
     * • Only for daily: Select from OpportunityProducts all records according to 5.2.2 and get Adserver_ID_Order_ID__c, Ad_Id__c
     * • Match Ad Id from report with Ad_Id__c and submit values to SF according to 5.3
     * • If Ad_Id__c = “” match Order Id from report with Adserver_ID_Order_ID__c, sum up values and submit sum to SF according to 5.3

     * @Updated Chr: 05-10-2015
     * @Desc: #8269 Enhancement of DFP Reporting Service
     * Structure for multiple IDs is always "XXXXXX, XXXXXXX, XXXXXXX,..." in Ad Id's field of OppLineItem
     * This is for Ad ID only, not for Order ID. The existing logic stays the same, just one option has to be added. 
     * If Ad ID contains multiple Ad IDs (can be identified, when the field contains at least one comma) the delivery numbers for all 
     * these Ad IDs are summed up and put into the related impressions/clicks field. 
     * OSI value is averaged (sum of OSI values / number of Ad IDs).
     * @  Change history:  14.12.2020 / Acmatac SEING / US-0007908 Merge the EU and NA process
     *                     14.06.2021 / Acmatac SEING / US-0009694 add reference 'Ad_Product__r'.'Product2__r'
     */
    private Boolean submitToSFRecord_EU(SObject sobj){
        loggedString.add(getCombinedKeySObject_EU(sobj, false) + ' >>>>>> ' + String.valueOf(sobj));
        String sobjType = sobj.getSObjectType()+'';// + SOBJ_FIELD_SEP ; //NK:09/03/2019: removed the sep! why sep?
        String sobjLabel = dds.Sobject__c + SOBJ_FIELD_SEP ;
        Map<String,String> sobjectField2DartField = mFieldsDartToSObj_EU.get(sobjType);
        
        if(sobjectField2DartField!=null){
            
            //Get Matching DartObjects
            DARTObject.DARTDelivery dartObject = null;
            Object adId = sobj.get('Ad_Id__c');
            if(adId == null){
                String val_Order = getCombinedKeySObject_EU(sobj, true);
                //Sum List dartObjects 
                if(mWithOutAdId.containsKey(val_Order)) dartObject = sumDartObjects_EU(mWithOutAdId.get(val_Order)); 
                //System.debug('\n\n---------------->>Without Ad ID::::' + dartObject);
            //check AdId != null and AdId contains comma(,)    
            }else {
                List<String> lstAdids = (adId+'').split(',');
                if(lstAdids.size()>1){
                    //size>1 mean that adId contain ,
                    //List<String> lstAdids = (sobj.get('Ad_Id__c')+'').split(',');
                    //clear old values of sobject
                    for(String sobjFieldname : sobjectField2DartField.keySet()){
                        String realField = getRealField(sobjFieldname,sobjLabel);
                        if(String.isNotBlank(realField)){
                            sobj.put(realField, 0);
                        }                       
                    }
                    
                    for(String sId : lstAdids){

                        String valKey = getCombinedKeySObject_EU(sobj, false, sId.replace(' ', ''));
                        
                        dartObject = (DARTObject.DARTDelivery)mWithAdId.get(valKey);
                        if(dartObject!=null){//mWithAdId.containsKey(valKey))
                            //Assign Values form matching DartObject to SObject                          
                            for(String sobjFieldname : sobjectField2DartField.keySet()){

                                String realField = getRealField(sobjFieldname,sobjLabel);
                                if(String.isNotBlank(realField)){
                                    String dartObjectFieldname = sobjectField2DartField.get(sobjFieldname);
                                    String dartVal = String.valueOf(dartObject.getValue(dartObjectFieldname)+'');
                                    dartVal = dartVal.replace('%', '').replace(',', '');
                                    if(DARTUtil.isNumber(dartVal)){
                                         if(!('OSI_RD__c'==sobjFieldname && Decimal.valueOf(dartVal) >1000)){
                                            sobj.put(realField, (Decimal.valueOf(sobj.get(realField)+'') + Decimal.valueOf(dartVal)));
                                         }
                                    }                                  
                                }
                            }
                        }
                    }
                    //OSI field need to sum and divid by number of AdIds
                    for(String combinTypeField : sobjectField2DartField.keySet()){
                        String realField = getRealField(combinTypeField,sobjLabel);
                        if(String.isNotBlank(realField)){
                            if(realField=='OSI__c' || realField=='OSI_RD__c'){
                              sobj.put(realField, (Decimal.valueOf(sobj.get(realField)+'') /lstAdids.size()));
                            }
                        }
                    }
                
                }else{
                    String val_advId = getCombinedKeySObject_EU(sobj, false);
                    //system.debug('>>>1 adId: val_advId:'+val_advId);
                    if(mWithAdId.containsKey(val_advId)){
                        dartObject = (DARTObject.DARTDelivery)mWithAdId.get(val_advId);
                    }else if(mWithOutAdId.containsKey(val_advId)){
                        dartObject = sumDartObjects_EU(mWithOutAdId.get(val_advId)); 
                    }
                }
            }
            if(dartObject == null) return false;
            //Assign Values form matching DartObject to SObject
            for(String combinTypeField : sobjectField2DartField.keySet()){
                String realField = getRealField(combinTypeField,sobjLabel);
                if(String.isNotBlank(realField)){
                    String dartObjectFieldname = sobjectField2DartField.get(combinTypeField);
                    String dartVal = String.valueOf(dartObject.getValue(dartObjectFieldname)+'');
                    dartVal = dartVal.replace('%', '').replace(',', '');
                    if(DARTUtil.isNumber(dartVal)){
                        //NK:15/07/2013:
                        //fixed error: NUMBER_OUTSIDE_VALID_RANGE, OSI (RSD): value outside of valid range on numeric field: 57051268.00: [OSI_RD__c]
                        // when the record only contains order id, stupid dart sums up all osi of this order instead of creating an average
                        if(!('OSI_RD__c'==realField && Decimal.valueOf(dartVal) >1000)){
                            //----
                            if((sobj.get('Ad_Id__c') != null && !(sobj.get('Ad_Id__c')+'').contains(',')) || (sobj.get('Ad_Id__c') == null)){
                                sobj.put(realField, Decimal.valueOf(dartVal));
                            }
                        }
                        
                    }
                    
                    
                }
            }
            if(sobjType.contains(DeliveryController.AD_PRODUCT_API_NAME)){
                sobj.put('Deliverystats_Update_Date__c', System.now());
            }
            if(sobjLabel.contains(DeliveryController.SOBJECT_AD_REV_MONTHLY_MTD)){ 
                sobj.put('Date_of_last_import__c', dds.Query_End_Date__c);
            }
            
            //Chr - 29-04-2016 #9212 DFP integration - quantity changes
            //DFP.DeliveredImpressions / Quantity_Multiplier__c = Delivered_AI__c (or similar fields in other objects)
            //Clicks_Recorded__c (or similar fields in other objects) is not affected by the multiplier
            // US-0009694 add reference 'Ad_Product__r'.'Product2__r'
            if(sobjLabel.contains(DeliveryController.SOBJECT_AD_REV_MONTHLY_MTD) || sobjLabel.contains(DeliveryController.SOBJECT_AD_REV_MONTHLY) || sobjLabel.contains(DeliveryController.SOBJECT_AD_REV_DAILY)){ 
                Double qtyMultiplier=1;
                if(sobj.getSObject('Ad_Product__r').getSObject('Product2__r')!=null && sobj.getSObject('Ad_Product__r').getSObject('Product2__r').getSObject('Advertising_Medium__r') != null){
                    qtyMultiplier= DARTUtil.toDouble(sobj.getSObject('Ad_Product__r').getSObject('Product2__r').getSObject('Advertising_Medium__r').get('Quantity_Multiplier__c')+'');
                    
                    // 28-10-2021 - Acmatac SEING, US-0010709 - Fix divided by 0
                    qtyMultiplier = qtyMultiplier == 0 ? 1 : qtyMultiplier;
                }
                sobj.put('Delivered_AI__c', (Decimal.valueOf(sobj.get('Delivered_AI__c')+'') /qtyMultiplier));
            }
            return true;
        }
        return false;
    }

    /*
    @  Change history:  14.12.2020 / Acmatac SEING / US-0007908 Merge the EU and NA process
    */
    private String getRealField(String field,String sobjLabel){
        //SOBJ_FIELD_SEP='.'
        List<String> fieldSplit =field.split('\\.');
        //Revenue_Schedules2__c Month To Date field= objectlable.fieldname
        if(sobjLabel.contains(DeliveryController.SOBJECT_AD_REV_MONTHLY_MTD)){
            if(fieldSplit.size()>1){
                String strField = fieldSplit.get(1);
                if(ignoredFields.contains(strField)){
                    return null;
                }
                return strField;
            }else{
                return null;
            }
        }
        if(fieldSplit.size()>1){
            //if not Month to date the fieldSplit must be one not two
            return null;
        }
        if(ignoredFields.contains(field)){
            return null;
        }
        return field;
    }
    /**
     * Sum all dartObject with empty Ad Id
     * @  Change history:  14.12.2020 / Acmatac SEING / US-0007908 Merge the EU and NA process
     */
    @testVisible
    private DARTObject.DARTDelivery sumDartObjects_EU(List<DARTObject.IDARTGenericObject> ldtDelivery){
        List<DARTObject.DARTDelivery> ldartDelivery = new List<DARTObject.DARTDelivery>();
        for(DARTObject.IDARTGenericObject idtobj : ldtDelivery){
            ldartDelivery.add((DARTObject.DARTDelivery)idtobj);
        }
        Map<Object,Object> mapRecord = new Map<Object,Object>{
            DARTObject.DEL_FIELD_ADDELIVERED => '0',
            DARTObject.DEL_FIELD_ADCLICKED_LIFETIME => '0',
            DARTObject.DEL_FIELD_ADOSI => '0',
            DARTObject.DEL_FIELD_ADID => '0',
            DARTObject.DEL_FIELD_ORDERID => '0',
            DARTObject.DEL_FIELD_IMPRESS_DELIVERED => '0',
            DARTObject.DEL_FIELD_CLICKS_DELIVERED => '0'
        };
        for(Integer i = 0; i<ldartDelivery.size(); i++){
            DARTObject.DARTDelivery dartDelivery = ldartDelivery[i];
            for(Object keyObject : mapRecord.keySet()){
                String fldname = (String)keyObject;
                if(fldname.equals(DARTObject.DEL_FIELD_ADID) || fldname.equals(DARTObject.DEL_FIELD_ORDERID)) continue; 
                String recVal = String.valueOf(mapRecord.get(fldname)+'').replace('%', '').replace(',', '');
                if(!DARTUtil.isNumber(recVal)) recVal = '0';
                String dartVal = String.valueOf(dartDelivery.getValue(fldname)+'').replace('%', '').replace(',', '');
                if(!DARTUtil.isNumber(dartVal)) dartVal = '0';
                Decimal sum = Decimal.valueOf(recVal) + Decimal.valueOf(dartVal);
                mapRecord.put(fldname, sum);
            }
        }
        if(!ldartDelivery.isEmpty()){
            Decimal osiVal = Decimal.valueOf(mapRecord.get(DARTObject.DEL_FIELD_ADOSI) + '');
            mapRecord.put(DARTObject.DEL_FIELD_ADOSI, osiVal/ldartDelivery.size());
        }
        return new DARTObject.DARTDelivery(mapRecord);
    } 

    public static final Map<Integer, String> MINT_TO_MONTH = new Map<Integer, String>{
        1 => 'January',
        2 => 'February',
        3 => 'March',
        4 => 'April',
        5 => 'May',
        6 => 'June',
        7 => 'July',
        8 => 'August',
        9 => 'September',
        10 => 'October',
        11 => 'November',
        12 => 'December'
    };
    
    /**
     * @description add reponsed report/Sf's record update & unupdate record to attachment
     * @param boolean doLog
     * @return Attachment
     */ 
    private Attachment createAttachedLogfile(Boolean doLog){
        Attachment att = new Attachment();
        att.ParentId = dds.Id;
        att.Name = 'Logged Import Data';
        if(!doLog) return att;
        String messageBody = 'Updated size: ' + successRecords.size() + ' of '+ dartSize;
        messageBody += '\n\nUpdated Records:[ ';
        for(String rec : successRecords) messageBody += ' ' + rec;
        messageBody += ' ]\n\nNonUpdate Records:[ ';
        for(String rec : unupdateRecords) messageBody += ' ' + rec;
        //do not write import data to log, because we will get cpu time limit when has many data from dfp
        //messageBody += ' ]\n\nImported Data:[ ';
        //for(DARTObject.IDARTGenericObject dObj : listImport){
        //    DARTObject.DARTDelivery dartObj = (DARTObject.DARTDelivery)dObj;
        //    messageBody += '\n' + dartObj.getAdId() + ' > ' + dartObj;
       // }
       // messageBody += ' ]'; 
        att.Body = Blob.valueOf(messageBody + '\n\n ----EXTRA MAPPING---- :\n\n' + String.join(loggedString, '\n\n'));
        insert att;
        return att;
    } 
    /* ---------------------------------
    ------ METHOD END ------
    -----------------------------------*/
}