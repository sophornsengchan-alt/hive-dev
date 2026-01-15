/*********************************************************************************************************************************
@ Class:          Coupon_AU_CS_BriefControllerTest
@ Version:        1.0
@ Author:         SRONG TIN (srong.tin@gaea-sys.com)
@ Purpose:        Coverage Coupon_AU_CS_BriefController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.09.2022 / SRONG TIN / Created the class.
*********************************************************************************************************************************/
@istest
public class Coupon_AU_CS_BriefControllerTest {

    @testSetup
    public static void setupdata(){
        String recordTypeId = ApexUtil.getRecordTypeByName('Coupon__c','Category_Based').Id;
        Coupon__c coupon = new Coupon__c(
            Coupon_Start_Time__c=System.Now().timeGmt(), 
            Coupon_End_Time__c=Time.newInstance(12, 22, 30, 000), 
            Coupon_Start_Date__c=System.Today(), 
            Coupon_End_Date__c=System.Today().addDays(2),
            Marketing_Coupon_Name__c = 'Test Coupon',
            Couponsite_s__c='ebay.com.au',
            Main_Coupon_Site__c='ebay.com.au', 
            Coupon_Co_invest_Type__c= 'GMV',
            Stage__c='Draft', 
            Coupon_ID__c = 'TestCoupon123',
            RecordTypeId = recordTypeId
        );
        insert coupon;           
        
    }
    
   	static testMethod void testMethod1(){
        List<Coupon__c> lstCoupon = [Select Id From Coupon__c limit 1];
         Test.setCurrentPage(Page.Coupon_AU_CS_BriefPage);
		 ApexPages.currentPage().getParameters().put('id',lstCoupon[0].Id);
		 ApexPages.StandardSetController sc = new ApexPages.StandardSetController(lstCoupon);
         Coupon_AU_CS_BriefController ext = new Coupon_AU_CS_BriefController(sc);
         ext.cancel(); 
         ext.initialize();
         ext.send();
         Map<String,Object> data =  Coupon_AU_CS_BriefController.doInitData(lstCoupon[0].Id);
         system.assertEquals(true, data.get('isCategoryType'));
       
     }
}