/*********************************************************************************************************************************
@ Class:         BatchCouponSellerStatus
@ Version:       1.0
@ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       EPH-7893 Coupon Seller Object: Trigger to automatically update Coupon Seller stage: Running and Executed
				i) For Stage = COUPON RUNNING
					When Current date =  Coupon Start Date and Coupon Start Time = Current time and Coupon_Seller_Stage__c = Contract Signed 
					the set satge to Coupon_Seller_Stage__c = COUPON RUNNING 
				ii) For Stage = COUPON EXECUTED
					When Current date =  Coupon End Date and Coupon End Time = Current time and Coupon_Seller_Stage__c = Contract Signed 
					the set satge to Coupon_Seller_Stage__c = COUPON EXECUTED
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 29.08.2019 / Vadhanak Voun / Created the class.
@				: 30.07.2020/ Vadhanak Voun / US-0007894 - Coupon Seller Stage Not Updated
@					Added filter enddate>today and stage still running
@				: 29.07.2021/ vadhanak voun/ US-0009100 - Hypercare bug: Coupon Seller Stage Not Updating. 
@										   / Depreciated moved to time base Flow. 
@				: 31.08.2021/ Mony/ US-0009948 - remove field Email_Adress__c from query string line 21
@				: 28.09.2023 / Loumang SENG / US-0013980 - Retire Contract Template field on Coupon
*********************************************************************************************************************************/
global without sharing class BatchCouponSellerStatus implements Database.Batchable<SObject>, Schedulable{
	//LA-28-09-2023-US-0013980: Remove Coupon__r.Contract_Language__c from query
	//public final static String SOQL_COUPON_SELLER = 'Select Coupon__r.Stage__c,Coupon__r.Days_since_coupon_End_Date__c,Coupon__r.Trigger34DayAfterEndDate__c,Coupon__r.Trigger4DayAfterEndDate__c,RecordType.DeveloperName, Allow_reaccept_contract__c,Advertising_Promotion__c, Day_1_Alert__c, Coupon_Contract_Due_Date__c, Day34AfterCouponEnd_Trigger_DE__c,Day4AfterCouponEnd_Trigger_DE__c,CurrencyIsoCode, Additional_Terms_Override_of_Agreement__c, Ad_Spend_Date__c, Advertising_Amount__c, Contract_Accept_Date__c,Coupon_Seller_Stage__c,Contract_Language__c,GMV_LC__c,Contra_LC__c,Cost_Share_Seller_LC__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Due_Date__c,Free_Subtitles__c,Coupon__r.Max_Redemptions__c,Coupon__r.Owner.Name,EBH_CouponSellerOwner__r.Name,EBH_CouponSellerOwner__c,EBH_CouponSellerOwner__r.Email,Coupon__r.Contract_Language__c,Coupon__r.Coupon_Cap__c,Coupon_ID__c ,Coupon__r.Marketing_Coupon_Name__c,Coupon__r.OwnerId,Coupon__r.Owner.Email,Coupon__r.RecordType.DeveloperName,Coupon__r.CurrencyIsoCode,Additional_Terms__c,Coupon__r.Minimum_Transaction_Value__c,Coupon__r.Name,Legal_Entity_Name_w__c,Legal_Entity_Street_w__c,Legal_Entity_Zip_w__c,Seller__r.Parent.EBH_BillingCountry__c,Seller__r.Parent.EBH_BillingCity__c,Seller__r.EBH_VATNumber__c,Seller__r.Name,Coupon__r.Couponsite_s__c,PayPal_adress_N__c,Coupon__r.Coupon_Start_Time__c,Coupon__r.Coupon_Start_Date__c,Coupon__r.Coupon_end_Time__c,Coupon__r.Coupon_End_Date__c,Coupon__r.Coupon_Discount__c,Coupon__r.Coupon_Discount_Amount__c,Coupon__r.T_Cs_URL__c,Id,Name,Seller__c,Coupon__c,Oracle_ID__c,PayPal_adress__c From Coupon_Seller__c ' ; //MN-31082021-US-0009948 - Remove Email_Adress__c from query
	public final static String SOQL_COUPON_SELLER = 'Select Coupon__r.Stage__c,Coupon__r.Days_since_coupon_End_Date__c,Coupon__r.Trigger34DayAfterEndDate__c,Coupon__r.Trigger4DayAfterEndDate__c,RecordType.DeveloperName, Allow_reaccept_contract__c,Advertising_Promotion__c, Day_1_Alert__c, Coupon_Contract_Due_Date__c, Day34AfterCouponEnd_Trigger_DE__c,Day4AfterCouponEnd_Trigger_DE__c,CurrencyIsoCode, Additional_Terms_Override_of_Agreement__c, Ad_Spend_Date__c, Advertising_Amount__c, Contract_Accept_Date__c,Coupon_Seller_Stage__c,Contract_Language__c,GMV_LC__c,Contra_LC__c,Cost_Share_Seller_LC__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Due_Date__c,Free_Subtitles__c,Coupon__r.Max_Redemptions__c,Coupon__r.Owner.Name,EBH_CouponSellerOwner__r.Name,EBH_CouponSellerOwner__c,EBH_CouponSellerOwner__r.Email,Coupon__r.Coupon_Cap__c,Coupon_ID__c ,Coupon__r.Marketing_Coupon_Name__c,Coupon__r.OwnerId,Coupon__r.Owner.Email,Coupon__r.RecordType.DeveloperName,Coupon__r.CurrencyIsoCode,Additional_Terms__c,Coupon__r.Minimum_Transaction_Value__c,Coupon__r.Name,Legal_Entity_Name_w__c,Legal_Entity_Street_w__c,Legal_Entity_Zip_w__c,Seller__r.Parent.EBH_BillingCountry__c,Seller__r.Parent.EBH_BillingCity__c,Seller__r.EBH_VATNumber__c,Seller__r.Name,Coupon__r.Couponsite_s__c,PayPal_adress_N__c,Coupon__r.Coupon_Start_Time__c,Coupon__r.Coupon_Start_Date__c,Coupon__r.Coupon_end_Time__c,Coupon__r.Coupon_End_Date__c,Coupon__r.Coupon_Discount__c,Coupon__r.Coupon_Discount_Amount__c,Coupon__r.T_Cs_URL__c,Id,Name,Seller__c,Coupon__c,Oracle_ID__c,PayPal_adress__c From Coupon_Seller__c ' ;
	private Set<String> setStagesInclude = new Set<String>{EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SIGNED,EBH_ConstantsUtility.COUPON_SELLER_STAGE_RUNNING,EBH_ConstantsUtility.COUPON_SELLER_STAGE_EXEC};
				
	private String soqlCoupon = EBH_ConstantsUtility.SOQL_COUPON;

	private final static String STAGE_RUNNING = EBH_ConstantsUtility.COUPON_SELLER_STAGE_RUNNING;
	
//	private String sWhere = ' Where Coupon__r.Coupon_Start_Date__c<>NULL AND Coupon__r.Coupon_End_Date__c<> NULL AND '+
//    	' Coupon__r.Coupon_Start_Time__c <> NULL AND Coupon__r.Coupon_end_Time__c<>NULL AND '+
//    	' (Coupon_Start_Date__c =TODAY OR Coupon_End_Date__c =TODAY) AND Coupon_Seller_Stage__c IN :setStagesInclude';
	
	//30.07.2020/NK:US-0007894: added 1 more filer (Coupon__r.Coupon_End_Date__c < TODAY AND Coupon_Seller_Stage__c=:STAGE_RUNNING) to fix any stalking stage afer endate
    private String sWhereCS = ' Where (Coupon__c IN:scope AND Coupon_Seller_Stage__c IN :setStagesInclude) OR (Coupon__r.Coupon_End_Date__c < TODAY AND Coupon_Seller_Stage__c=:STAGE_RUNNING) '; 
    
    private String sWhereCoupon = ' Where Coupon_Start_Date__c<>NULL AND Coupon_End_Date__c<> NULL AND '+
    	' Coupon_Start_Time__c <> NULL AND Coupon_end_Time__c<>NULL AND '+
    	'((Coupon_Start_Date__c =TODAY OR Coupon_End_Date__c =TODAY) '+ //for coupon seller statuses
    	'OR (Days_since_coupon_End_Date__c >=4 AND Trigger4DayAfterEndDate__c=null) '+ //t4, bcd
    	'OR ( Days_since_coupon_End_Date__c>=40 AND Trigger34DayAfterEndDate__c=null) '+ //t40, bcd
		') '; 
		
    
	private String couponId;
	private Boolean fixRunningStage = false;
    public BatchCouponSellerStatus()
    {
    }
    //testigng purpose
	public BatchCouponSellerStatus(String couponId)
    {
    	this.couponId = couponId;
    	sWhereCoupon += ' Where Id=:couponId';
    }
	
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(soqlCoupon+sWhereCoupon);
    }

    global void execute(Database.BatchableContext pBc, List<SObject> scope){
       // update Coupon Seller first to get status to T4,T40
       // then update Coupon to trigger BCD (file need t4/t40)
        DateTime timeNow = DateTime.now();
        Date todayGMT = DateTime.now().dateGMT();
        Map<String,Coupon__c> mapCouponToUpdate = new Map<String,Coupon__c>();
        for(Coupon__c c: (List<Coupon__c>) scope)
        {
        	if(c.Days_since_coupon_End_Date__c >=40 && c.Trigger34DayAfterEndDate__c == null)
        	{
        		c.Trigger34DayAfterEndDate__c = System.now();
        		c.Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_34; //NK:10/03/2020: found missing?
        		mapCouponToUpdate.put(c.Id,c);
        	}else if(c.Days_since_coupon_End_Date__c >=4 && c.Trigger4DayAfterEndDate__c==null)
        	{
        		c.Trigger4DayAfterEndDate__c = System.now();
        		c.Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_T4; //NK:10/03/2020: found missing?
        		mapCouponToUpdate.put(c.Id,c);
        	}
        }
         
        Map<String,Coupon_Seller__c> mapCSToUpdate = new Map<String,Coupon_Seller__c>();
		//Coupon__r.Coupon_Start_Time__c,Coupon__r.Coupon_Start_Date__c,Coupon__r.Coupon_end_Time__c,Coupon__r.Coupon_End_Date__c
        
		for (Coupon_Seller__c cs : Database.query(SOQL_COUPON_SELLER+sWhereCS)) 
		{ 
			//System.debug('Start_Date: '+cs.Coupon__r.Coupon_Start_Date__c+'>> End Date: '+cs.Coupon__r.Coupon_End_Date__c+' >>Start hour: '+cs.Coupon__r.Coupon_Start_Time__c.hour() +' >>End hour: '+cs.Coupon__r.Coupon_end_Time__c.hour()+' >>Hour GMT: '+timeNow.hourGmt());
			//coupon ended but stage still running.
			Boolean isDeadStage = 	(cs.Coupon__r.Coupon_End_Date__c < todayGMT &&  cs.Coupon_Seller_Stage__c == STAGE_RUNNING );
			//handle status hourly
			// ->Coupon_Seller_Stage__c = COUPON RUNNING
			if (todayGMT.isSameDay(cs.Coupon__r.Coupon_Start_Date__c) && cs.Coupon__r.Coupon_Start_Time__c.hour() == timeNow.hourGmt()) {
				cs.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_RUNNING;
				mapCSToUpdate.put(cs.Id,cs);
				
			}
			// ->Coupon_Seller_Stage__c = COUPON EXECUTED			
			if((todayGMT.isSameDay(cs.Coupon__r.Coupon_End_Date__c) && cs.Coupon__r.Coupon_end_Time__c.hour()==timeNow.hourGmt()) || isDeadStage ) 
			{
				cs.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_EXEC;
				mapCSToUpdate.put(cs.Id,cs);
			}
			 
			//handle T4/T40
			//Its coupon has reached T4 or T40
			if(mapCouponToUpdate.containsKey(cs.Coupon__c)  || isDeadStage)
			{
				Coupon__c c = isDeadStage?cs.Coupon__r : mapCouponToUpdate.get(cs.Coupon__c);
				if(c.Days_since_coupon_End_Date__c >=40 && cs.Day34AfterCouponEnd_Trigger_DE__c == null)  //should be all cs not only DE, CS trigger will check by it own  
				{
					cs.Day34AfterCouponEnd_Trigger_DE__c = System.now();
					mapCSToUpdate.put(cs.Id,cs);
				}else if(c.Days_since_coupon_End_Date__c >=4 && cs.Day4AfterCouponEnd_Trigger_DE__c==null)
				{
					cs.Day4AfterCouponEnd_Trigger_DE__c = System.now();
					mapCSToUpdate.put(cs.Id,cs);
				}
				
			}
		}
        try 
        {
        	if(!mapCSToUpdate.isEmpty())
        	{
        		//Allow system to bypass validation
        		CouponSellerTriggerHandler.isUpdatedSellerStage = true;
        		update mapCSToUpdate.values();
        		
        	}
        	
        	//dml separated from mapCSToUpdate. in case no coupon seller matched(running, exe,to t4, to t40) then Coupon can be upated alone
        	//update status already then Coupon BCD can have data in csv
        	if(!mapCouponToUpdate.isEmpty())
        	{
        		update mapCouponToUpdate.values();
        	}
        	
        }catch (Exception ex) {
            EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchCouponSellerStatus','execute');
        }
        
    }

    global void finish(Database.BatchableContext pBc){

    }
    global void execute(SchedulableContext sc) { 
        BatchCouponSellerStatus b = new BatchCouponSellerStatus();
        Database.executeBatch(b);
    }
    
    //run only once after deployment
	//NK:30/07/2021: US-0009100: abort the job. and depreciated the Batch
	//moved to Flow
    public static void runSchedulerHourly()
    {
    	//check and clear old obsoleted jobs first...
    	//BatchDealRunningStatus
    	CronTrigger[] oldJobs =  ApexUtil.findCronJob(new Set<String>{'BatchDealRunningStatus'});
    	for(CronTrigger j : oldJobs)
		{
		  System.abortJob(j.Id);
		}
		
		// Map<String,Integer> jobCounter  = ApexUtil.countRunningBatch(new Set<String> {'BatchCouponSellerStatus'});
		// if(jobCounter.get('BatchCouponSellerStatus')==0 && !Test.isRunningTest())
		// {
		// 	System.schedule('BatchCouponSellerStatus', '0 0 * * * ?', new BatchCouponSellerStatus() );
		// }
    	
    }
}