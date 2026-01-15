/*********************************************************************************************************************************
@ Class:         BatchDealRunningStatus
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
@               : 28.07.2021/ vadhanak voun/ US-0009100: deprciated (to be deleted!). job at BatchCouponSellerStatus
@				: 31.08.2021/ Mony/ US-0009948 - remove field Email_Adress__c from query string line 21
@				: 28.09.2023 / Loumang SENG / US-0013980 - Retire Contract Template field on Coupon
*********************************************************************************************************************************/
global without sharing class BatchDealRunningStatus implements Database.Batchable<SObject>, Schedulable{
	/****************************************************************************************************************************
	* CONSTANTS DEFINITION
	*****************************************************************************************************************************/
    //LA-28-09-2023-US-0013980: Remove Coupon__r.Contract_Language__c from query
	//private final static String SOQL_COUPON_SELLER = 'Select Coupon__r.Coupon_Subtitle_Copy__c,RecordType.DeveloperName, Allow_reaccept_contract__c,Advertising_Promotion__c, Day_1_Alert__c, Coupon_Contract_Due_Date__c, Day34AfterCouponEnd_Trigger_DE__c,Day4AfterCouponEnd_Trigger_DE__c,CurrencyIsoCode, Additional_Terms_Override_of_Agreement__c, Ad_Spend_Date__c, Advertising_Amount__c, Contract_Accept_Date__c,Coupon_Seller_Stage__c,Contract_Language__c,GMV_LC__c,Contra_LC__c,Cost_Share_Seller_LC__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Due_Date__c,Free_Subtitles__c,Coupon__r.Max_Redemptions__c,Coupon__r.Owner.Name,EBH_CouponSellerOwner__r.Name,EBH_CouponSellerOwner__c,EBH_CouponSellerOwner__r.Email,Coupon__r.Contract_Language__c,Coupon__r.Coupon_Cap__c,Coupon_ID__c ,Coupon__r.Marketing_Coupon_Name__c,Coupon__r.OwnerId,Coupon__r.Owner.Email,Coupon__r.RecordType.DeveloperName,Coupon__r.CurrencyIsoCode,Additional_Terms__c,Coupon__r.Minimum_Transaction_Value__c,Coupon__r.Name,Legal_Entity_Name_w__c,Legal_Entity_Street_w__c,Legal_Entity_Zip_w__c,Seller__r.Parent.EBH_BillingCountry__c,Seller__r.Parent.EBH_BillingCity__c,Seller__r.EBH_VATNumber__c,Seller__r.Name,Coupon__r.Couponsite_s__c,PayPal_adress_N__c,Coupon__r.Coupon_Start_Time__c,Coupon__r.Coupon_Start_Date__c,Coupon__r.Coupon_end_Time__c,Coupon__r.Coupon_End_Date__c,Coupon__r.Coupon_Discount__c,Coupon__r.Coupon_Discount_Amount__c,Coupon__r.T_Cs_URL__c,Id,Name,Seller__c,Coupon__c,Oracle_ID__c,PayPal_adress__c From Coupon_Seller__c ' ;
    private final static String SOQL_COUPON_SELLER = 'Select Coupon__r.Coupon_Subtitle_Copy__c,RecordType.DeveloperName, Allow_reaccept_contract__c,Advertising_Promotion__c, Day_1_Alert__c, Coupon_Contract_Due_Date__c, Day34AfterCouponEnd_Trigger_DE__c,Day4AfterCouponEnd_Trigger_DE__c,CurrencyIsoCode, Additional_Terms_Override_of_Agreement__c, Ad_Spend_Date__c, Advertising_Amount__c, Contract_Accept_Date__c,Coupon_Seller_Stage__c,Contract_Language__c,GMV_LC__c,Contra_LC__c,Cost_Share_Seller_LC__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Due_Date__c,Free_Subtitles__c,Coupon__r.Max_Redemptions__c,Coupon__r.Owner.Name,EBH_CouponSellerOwner__r.Name,EBH_CouponSellerOwner__c,EBH_CouponSellerOwner__r.Email,Coupon__r.Coupon_Cap__c,Coupon_ID__c ,Coupon__r.Marketing_Coupon_Name__c,Coupon__r.OwnerId,Coupon__r.Owner.Email,Coupon__r.RecordType.DeveloperName,Coupon__r.CurrencyIsoCode,Additional_Terms__c,Coupon__r.Minimum_Transaction_Value__c,Coupon__r.Name,Legal_Entity_Name_w__c,Legal_Entity_Street_w__c,Legal_Entity_Zip_w__c,Seller__r.Parent.EBH_BillingCountry__c,Seller__r.Parent.EBH_BillingCity__c,Seller__r.EBH_VATNumber__c,Seller__r.Name,Coupon__r.Couponsite_s__c,PayPal_adress_N__c,Coupon__r.Coupon_Start_Time__c,Coupon__r.Coupon_Start_Date__c,Coupon__r.Coupon_end_Time__c,Coupon__r.Coupon_End_Date__c,Coupon__r.Coupon_Discount__c,Coupon__r.Coupon_Discount_Amount__c,Coupon__r.T_Cs_URL__c,Id,Name,Seller__c,Coupon__c,Oracle_ID__c,PayPal_adress__c From Coupon_Seller__c ' ;
	/************************************END CONSTANTS DEFINITION*************************************************************/
	private Set<String> setStagesInclude = new Set<String>{EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SIGNED,EBH_ConstantsUtility.COUPON_SELLER_STAGE_RUNNING};
				
	private String soqlCS = SOQL_COUPON_SELLER;
	
	private String sWhere = ' Where Coupon__r.Coupon_Start_Date__c<>NULL AND Coupon__r.Coupon_End_Date__c<> NULL AND '+
    	' Coupon__r.Coupon_Start_Time__c <> NULL AND Coupon__r.Coupon_end_Time__c<>NULL AND '+
    	' (Coupon_Start_Date__c =TODAY OR Coupon_End_Date__c =TODAY) AND Coupon_Seller_Stage__c IN :setStagesInclude';
    
    private String couponId;
    public BatchDealRunningStatus()
    {
    }
    
    //testigng purpose
	// public BatchDealRunningStatus(String couponId)
    // {
    // 	this.couponId = couponId;
    // 	sWhere += ' And Coupon__c =:couponId';
    // }
	
    global Database.QueryLocator start(Database.BatchableContext BC){
        //return Database.getQueryLocator(soqlCS+sWhere);
        return Database.getQueryLocator(soqlCS+' LIMIT 1 ');
    }

    global void execute(Database.BatchableContext pBc, List<Coupon_Seller__c> scope){
        /*
        DateTime timeNow = DateTime.now();
        Date todayGMT = DateTime.now().dateGMT();
        List<Coupon_Seller__c> listCSToUpdate = new List<Coupon_Seller__c>();
		//Coupon__r.Coupon_Start_Time__c,Coupon__r.Coupon_Start_Date__c,Coupon__r.Coupon_end_Time__c,Coupon__r.Coupon_End_Date__c
        
            for (Coupon_Seller__c cs : scope) 
            { 
                //System.debug('Start_Date: '+cs.Coupon__r.Coupon_Start_Date__c+'>> End Date: '+cs.Coupon__r.Coupon_End_Date__c+' >>Start hour: '+cs.Coupon__r.Coupon_Start_Time__c.hour() +' >>End hour: '+cs.Coupon__r.Coupon_end_Time__c.hour()+' >>Hour GMT: '+timeNow.hourGmt());
                 
                //Coupon_Seller_Stage__c = COUPON RUNNING
                if (todayGMT.isSameDay(cs.Coupon__r.Coupon_Start_Date__c) && cs.Coupon__r.Coupon_Start_Time__c.hour() == timeNow.hourGmt()) {
                    cs.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_RUNNING;
                    listCSToUpdate.add(cs);
                    
                }// Coupon_Seller_Stage__c = COUPON EXECUTED
                else if(todayGMT.isSameDay(cs.Coupon__r.Coupon_End_Date__c) && cs.Coupon__r.Coupon_end_Time__c.hour()==timeNow.hourGmt())
                {
                	cs.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_EXEC;
                	listCSToUpdate.add(cs);
                }
                
            }
        try 
        {
        	if(!listCSToUpdate.isEmpty())
        	{
        		//Allow system to bypass validation
        		CouponSellerTriggerHandler.isUpdatedSellerStage = true;
        		update listCSToUpdate;
        		
        	}
        }catch (Exception ex) {
            EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchDealRunningStatus','execute');
        }
        */
    }

    global void finish(Database.BatchableContext pBc){

    }
    global void execute(SchedulableContext sc) { 
        //BatchDealRunningStatus b = new BatchDealRunningStatus();
        //Database.executeBatch(b);
    }
    
    //run only once after deployment
    // public static void runSchedulerHourly()
    // {
    // 	System.schedule('BatchDealRunningStatus', '0 0 * * * ?', new BatchDealRunningStatus() );
    // }
}