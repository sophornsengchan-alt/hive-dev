/*********************************************************************************************************************************
	@ Method:         Batch_CreateCoInvest
	@ Version:       1.0
	@ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:       US-0007195 - Coupon Co-Invest records creation is causing System.LimitException: Too many SOQL queries: 101 error
	@               CouponTriggerHandler.createCoInvestWithRecordType
    @               to fix CPU limit
	----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.05.2020/ Vadhanak Voun (vadhanak.voun@gaea-sys.com) / Created the Method.
    @               : 28/02/2023/ Sovantheany Dim / US-0013091 - Improve trigger when creating co-invest records Coupon Co-Invest records for big number of Categories and
    @				: 28.09.2023 / Loumang SENG / US-0013980 - Retire Contract Template field on Coupon
	*********************************************************************************************************************************/
global without sharing class Batch_CreateCoInvest implements Database.Batchable<SObject>,Database.Stateful{
	 /****************************************************************************************************************************
	* CONSTANTS DEFINITION
	*****************************************************************************************************************************/
	private Set<ID> sCoupon;
    private String whereCS = ' where Coupon__c IN: sCoupon';
    //LA-28-09-2023-US-0013980: Remove Coupon__r.Contract_Language__c from query
	//private final static String SOQL_COUPON_SELLER_2 = 'Select Coupon__r.Main_Coupon_Site__c, Coupon__r.Couponsite_s__c,Seller__r.Strategic_Seller_Share_w__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Language__c, Date_4days_Sent__c, Date_34_days_Sent__c, TriggerEmailManhattan__c, Id,Seller__c,Seller__r.EBH_OracleID__c,Coupon__c,Coupon_Seller_Stage__c,Coupon__r.RecordTypeID,Coupon__r.RecordType.DeveloperName,Coupon__r.Stage__c,SellerShareHolder__c From Coupon_Seller__c' ;
    private final static String SOQL_COUPON_SELLER_2 = 'Select Coupon__r.Main_Coupon_Site__c, Coupon__r.Couponsite_s__c,Seller__r.Strategic_Seller_Share_w__c,Coupon__r.Seller_Co_funding_share_forecast__c, Date_4days_Sent__c, Date_34_days_Sent__c, TriggerEmailManhattan__c, Id,Seller__c,Seller__r.EBH_OracleID__c,Coupon__c,Coupon_Seller_Stage__c,Coupon__r.RecordTypeID,Coupon__r.RecordType.DeveloperName,Coupon__r.Stage__c,SellerShareHolder__c From Coupon_Seller__c' ;
    private List<Coupon_Co_Invest__c> lstCoInvest;
    private Integer countAllCoInvest_OK = 0;//TH:US-0013091
    @TestVisible 
    private Integer countAllCoInvest_fail = 0;//TH:US-0013091
    private Map<String,Set<String>> mapError = new Map<String,Set<String>>();//TH:US-0013091
    private static final String EMAILTEMPLATE_COUPON_COINVEST_RESULT = 'ManagedCouponCoInvestResult';//TH:US-0013091 
    private final static String SOQLEMAIL_TEMPLATES = 'Select Body,Id,DeveloperName,Subject,HtmlValue from emailTemplate ';//TH:US-0013091 
    /************************************END CONSTANTS DEFINITION*************************************************************/

    public Batch_CreateCoInvest(Set<ID> sCoupon) 
    {
        this.sCoupon = sCoupon;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) 
    {        
        updatedCoupon(this.sCoupon,true);
        return Database.getQueryLocator(SOQL_COUPON_SELLER_2 + whereCS);
    }

    global void execute(Database.BatchableContext pBc, List<Coupon_Seller__c> scope)
    {
        Map<String,Object> mapResult = CouponTriggerHandler.processCoInvest(scope,countAllCoInvest_OK,countAllCoInvest_fail);
        countAllCoInvest_OK = Integer.valueOf(mapResult.get('countAllCoInvest_OK'));
        countAllCoInvest_fail = Integer.valueOf(mapResult.get('countAllCoInvest_fail'));
        
        Map<String,Set<String>> mapResultError = (Map<String,Set<String>>) mapResult.get('mapError');
        for(String key : mapResultError.keySet()){
            Set<String> sError = mapResultError.get(key);
            if(mapError.containsKey(key)){
                Set<String> sErrorFromMap = mapError.get(key);
                sErrorFromMap.addAll(sError);
                mapError.put(key,sErrorFromMap);
            }else{
                mapError.put(key,sError);
            }
        }
    }
    
    global void finish(Database.BatchableContext pBc)
    {
        updatedCoupon(this.sCoupon,false);
        ////TH:US-0013091 : if have fail send email to current user
        if(countAllCoInvest_fail>0) sendResult();
    }

    //TH: US-0013091 : set Batch_Processing__c to true when start running batch, and false when finish
    private void updatedCoupon(Set<ID> sCoupon, Boolean isBatchProcessing){
        CouponTriggerHandler.isBatchProcessing = true;// do not trigger the other tasks. just want to check the flag
        List<Coupon__c> lstCouponToUpdate = new List<Coupon__c>();
        for(Coupon__c c : [select Batch_Processing__c from Coupon__c where id IN: sCoupon]){
            c.Batch_Processing__c = isBatchProcessing;
            lstCouponToUpdate.add(c);
        }
        if(!lstCouponToUpdate.isEmpty()) update lstCouponToUpdate;
        CouponTriggerHandler.isBatchProcessing = false;// can trigger other tasks
    }

    //TH:US-0013091
	private void sendResult()
	{
		String whereCl = ' Where DeveloperName =: EMAILTEMPLATE_COUPON_COINVEST_RESULT'; 
    	List<EmailTemplate> empt = Database.query(SOQLEMAIL_TEMPLATES + whereCl);
    	String htmlBody = contructBody(empt[0].HtmlValue);
	    if(!Test.isRunningTest()) ApexUtil.doSend(empt[0].subject,UserInfo.getUserEmail(),htmlBody);
			    
	}
	//TH:US-0013091
	private String contructBody( String hbody)
	{
		return hbody
		.replace('{!Owner}',Test.isRunningTest()?'Test':UserInfo.getName())
		.replace('{!CountCoInvestOK}',String.valueOf(countAllCoInvest_OK))
		.replace('{!countCoInvestFail}',String.valueOf(countAllCoInvest_fail))
		.replace('{!CoInvestErrorMessage}',mapError.containsKey('coInvest')?String.join(new List<String>(mapError.get('coInvest')),'<br>'):'');
	}
}