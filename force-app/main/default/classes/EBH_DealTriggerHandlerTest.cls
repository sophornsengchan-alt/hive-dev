/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class EBH_DealTriggerHandlerTest {
	// static {EBH_TestDataFactory.setUpCustomSettings();}
	private static ID dealNARecordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2').Id;
	private static ID dealStandardRecordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V1').Id;
    private static RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    private static RecordType contactRecordTYpe = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
	private static ID dealNAUnsubRecordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V3').Id;
	
	@testSetup
    static void setup(){
		EBH_TestDataFactory.setUpCustomSettings();

    	byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
		settings.triggerObjects__c='EBH_Deal__c'; //Adding bypass
        upsert settings byPass__c.Id;
    }
   // static testMethod void testCalculateToDealBudgetMonth() {
////       	 Date myDate = Date.newInstance(2017, 1, 1);
//		Date myDate  = Date.newInstance(Date.today().year(), Date.today().month(), 1);
//       	 
//         EBH_DealsBudget__c db = new EBH_DealsBudget__c(EBH_Vertical__c='CSA',EBH_Quarter__c='Q1');
//         insert db;
//         
//         EBH_DealsBudgetMonth__c dbm1 = new EBH_DealsBudgetMonth__c(EBH_DealsBudget__c=db.Id,EBH_Month__c='January');
//         insert dbm1;
//         
//          //UID__c: TEXT(Deal_Format__c) & TEXT(Vertical__c) & TEXT(Date__c)
//         EBH_DealSlotAllocation__c dsa = new EBH_DealSlotAllocation__c(EBH_DealFormat__c='Primary',EBH_Vertical__c='CSA',EBH_Date__c=myDate,EBH_Country__c='DE',EBH_Slots__c=1);
//         EBH_DealSlotAllocation__c dsa2 = new EBH_DealSlotAllocation__c(EBH_DealFormat__c='Primary',EBH_Vertical__c='Tech',EBH_Date__c=myDate,EBH_Country__c='DE',EBH_Slots__c=1);
//         insert new List<EBH_DealSlotAllocation__c>{dsa,dsa2};
//         
//         Account ac = new Account(Name='Seller',EBH_VATNumber__c='1122334455');
//         ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
//         insert ac;
//         
//         EBH_DealStatus__c ds1 = new EBH_DealStatus__c(Name='AVAIL_STATUS',EBH_StatusSet__c='Ready for Payment,Paid,Executed,Planned,Deal Agreed,Running');
//         EBH_DealStatus__c ds2 = new EBH_DealStatus__c(Name='STATUS_SLOT_ALLOC_NULL',EBH_StatusSet__c='New,Negotiating,Rejected');
//         EBH_DealStatus__c ds3 = new EBH_DealStatus__c(Name='s_final',EBH_StatusSet__c='Paid');
//         EBH_DealStatus__c ds4 = new EBH_DealStatus__c(Name='s_forecast',EBH_StatusSet__c='Executed');
//         EBH_DealStatus__c ds5 = new EBH_DealStatus__c(Name='s_invoiced',EBH_StatusSet__c='Ready for Payment');
//         EBH_DealStatus__c ds6 = new EBH_DealStatus__c(Name='s_max',EBH_StatusSet__c='Planned,Deal Agreed,Running');
//         
//         insert new List<EBH_DealStatus__c>{ds1,ds2,ds3,ds4,ds5,ds6};
//         Test.startTest();
//         
//         //Subsidy:IF( Deal_Price__c > 0, Seller_Price__c - Deal_Price__c, 0)
//         //Subsidy_Final__c: Subsidy__c * Sold_Items__c
//         //Subsidy_Forecast__c: Subsidy__c * Sold_Items_Forecast__c
//         //Subsidy_Max__c: Quantity__c * Subsidy__c
//         
//         //UID__c: TEXT(Deal_Format__c) & TEXT(Vertical__c) & TEXT(Deal_Start_Date__c)
//         //req: ,Category__c='Gold', Product_Title__c='product 1',Seller_Email__c='sales@test.com', Quantity__c=, 
//         
//         EBH_Deal__c d1 = new EBH_Deal__c(EBH_SellerPrice__c=1000,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=myDate,EBH_Status__c='Ready for Payment',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
//         EBH_Deal__c d1a = new EBH_Deal__c(EBH_SellerPrice__c=1000,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=myDate,EBH_Status__c='Ready for Payment',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
//         d1a.EBH_DealPrice__c = 200;
//         d1a.EBH_DealFormat__c = 'iji';
//         d1a.EBH_DealStartDate__c = Date.today();
//         d1a.EBH_DealEndDate__c = Date.today();
//         d1a.EBH_SellerEmail__c ='dd@d.com';
//         d1a.EBH_MaximumPurchases__c =324;
//         d1a.EBH_BusinessName__c = ac.Id;
//         d1.EBH_DealPrice__c = 200;
//         d1.EBH_DealFormat__c = 'iji';
//         d1.EBH_DealStartDate__c = Date.today();
//         d1.EBH_DealEndDate__c = Date.today();
//         d1.EBH_SellerEmail__c ='dd@d.com';
//         d1.EBH_MaximumPurchases__c =324;
//         d1.EBH_BusinessName__c = ac.Id;
//         EBH_Deal__c d2 = new EBH_Deal__c(EBH_SellerPrice__c=1000,EBH_DealPrice__c=5,EBH_SoldItemsForecast__c=4,EBH_Vertical__c='CSA',EBH_DealStartDate__c=myDate,EBH_Status__c='Executed',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com' ,EBH_Quantity__c=1);
//         EBH_Deal__c d2a = new EBH_Deal__c(EBH_SellerPrice__c=1000,EBH_DealPrice__c=5,EBH_SoldItemsForecast__c=4,EBH_Vertical__c='CSA',EBH_DealStartDate__c=myDate,EBH_Status__c='Executed' ,EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
//         d2a.EBH_DealPrice__c = 200;
//         d2a.EBH_DealFormat__c = 'iji';
//         d2a.EBH_DealStartDate__c = Date.today();
//         d2a.EBH_DealEndDate__c = Date.today();
//         d2a.EBH_SellerEmail__c ='dd@d.com';
//         d2a.EBH_MaximumPurchases__c =324;
//         d2a.EBH_BusinessName__c = ac.Id;
//         d2.EBH_DealPrice__c = 200;
//         d2.EBH_DealFormat__c = 'iji';
//         d2.EBH_DealStartDate__c = Date.today();
//         d2.EBH_DealEndDate__c = Date.today();
//         d2.EBH_SellerEmail__c ='dd@d.com';
//         d2.EBH_MaximumPurchases__c =324;
//         d2.EBH_BusinessName__c = ac.Id;
//         EBH_Deal__c d3 = new EBH_Deal__c(EBH_SellerPrice__c=2000,EBH_DealPrice__c=5,EBH_Quantity__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=myDate,EBH_Status__c='Planned' ,EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com');
//         EBH_Deal__c d3a = new EBH_Deal__c(EBH_SellerPrice__c=2000,EBH_DealPrice__c=5,EBH_Quantity__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=myDate,EBH_Status__c='Planned' ,EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com');
//         d3a.EBH_DealPrice__c = 200;
//         d3a.EBH_DealFormat__c = 'iji';
//         d3a.EBH_DealStartDate__c = Date.today();
//         d3a.EBH_DealEndDate__c = Date.today();
//         d3a.EBH_SellerEmail__c ='dd@d.com';
//         d3a.EBH_MaximumPurchases__c =324;
//         d3a.EBH_BusinessName__c = ac.Id;
//         d3.EBH_DealPrice__c = 200;
//         d3.EBH_DealFormat__c = 'iji';
//         d3.EBH_DealStartDate__c = Date.today();
//         d3.EBH_DealEndDate__c = Date.today();
//         d3.EBH_SellerEmail__c ='dd@d.com';
//         d3.EBH_MaximumPurchases__c =324;
//         d3.EBH_BusinessName__c = ac.Id;
//         EBH_Deal__c d4 = new EBH_Deal__c(EBH_SellerPrice__c=1000,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=myDate,EBH_Status__c='New' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
//         d4.EBH_DealPrice__c = 200;
//         d4.EBH_DealFormat__c = 'iji';
//         d4.EBH_DealStartDate__c = Date.today();
//         d4.EBH_DealEndDate__c = Date.today();
//         d4.EBH_SellerEmail__c ='dd@d.com';
//         d4.EBH_MaximumPurchases__c =324;
//         d4.EBH_BusinessName__c = ac.Id;
//         //Subsidy = 40 - 5 = 35;  Subsidy_Final__c = 35 * 2 = 70; 
//         EBH_Deal__c d5 = new EBH_Deal__c(EBH_SellerPrice__c=4000,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=myDate,EBH_Status__c='Paid' ,EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
//         EBH_Deal__c d5a = new EBH_Deal__c(EBH_SellerPrice__c=4000,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=myDate,EBH_Status__c='Paid' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
//         d5.EBH_DealPrice__c = 200;
//         d5.EBH_DealFormat__c = 'iji';
//         d5.EBH_DealStartDate__c = Date.today();
//         d5.EBH_DealEndDate__c = Date.today();
//         d5.EBH_SellerEmail__c ='dd@d.com';
//         d5.EBH_MaximumPurchases__c =324;
//         d5.EBH_BusinessName__c = ac.Id;
//         d5a.EBH_DealPrice__c = 200;
//         d5a.EBH_DealFormat__c = 'iji';
//         d5a.EBH_DealStartDate__c = Date.today();
//         d5a.EBH_DealEndDate__c = Date.today();
//         d5a.EBH_SellerEmail__c ='dd@d.com';
//         d5a.EBH_MaximumPurchases__c =324;
//          d5a.EBH_BusinessName__c = ac.Id;
//            //update d1;
//            d1.EBH_eBayItemID__c='123456789';
//            d1a.EBH_eBayItemID__c='123456789';
//            d2.EBH_eBayItemID__c='123456789';
//            d2a.EBH_eBayItemID__c='123456789';
//            d3.EBH_eBayItemID__c='123456789';
//            d3a.EBH_eBayItemID__c='123456789';
//            d4.EBH_eBayItemID__c='123456789';
//            d5.EBH_eBayItemID__c='123456789';
//            d5a.EBH_eBayItemID__c='123456789';
//         insert new List<EBH_Deal__c>{d1,d1a,d2,d2a,d3,d3a,d4,d5,d5a};
//         
//         EBH_Deal__c[] selDeals = [Select Id,EBH_DealSlotAllocation__c From EBH_Deal__c where Id=:d5a.Id];
//         //System.assertEquals(dsa.Id,selDeals[0].EBH_DealSlotAllocation__c,'Deal Slot Allocation must be assigned to Deal');
//          
//         EBH_DealsBudgetMonth__c dbmSelect =[Select Id,EBH_SubsidyInvoiced__c,EBH_SubsidyPaid__c,EBH_SubsidyForecast__c,EBH_SubsidyMax__c From EBH_DealsBudgetMonth__c WHERE id=:dbm1.Id];
//         
//        /* System.assertEquals(20,dbmSelect.EBH_SubsidyInvoiced__c,'invoiced status summed up');
//         System.assertEquals(140,dbmSelect.EBH_SubsidyPaid__c,'paid status summed up');
//         System.assertEquals(40,dbmSelect.EBH_SubsidyForecast__c,'forecast status summed up');
//         System.assertEquals(60,dbmSelect.EBH_SubsidyMax__c,'max status summed up');*/
//         
//         d4.EBH_Status__c =  'Ready for Payment';
//         update d4;
//         dbmSelect =[Select Id,EBH_SubsidyPaid__c,EBH_SubsidyInvoiced__c,EBH_SubsidyForecast__c,EBH_SubsidyMax__c From EBH_DealsBudgetMonth__c WHERE id=:dbm1.Id];
//         
//       //  System.assertEquals(30,dbmSelect.EBH_SubsidyInvoiced__c,'final status summed up by updated the status');
//         
//         delete d4;
//         dbmSelect =[Select Id,EBH_SubsidyPaid__c,EBH_SubsidyInvoiced__c,EBH_SubsidyForecast__c,EBH_SubsidyMax__c From EBH_DealsBudgetMonth__c WHERE id=:dbm1.Id];
//        // System.assertEquals(20,dbmSelect.EBH_SubsidyInvoiced__c,'final: minus 10 from the deleted deal');
//         
//         undelete d4;
//         dbmSelect =[Select Id,EBH_SubsidyPaid__c,EBH_SubsidyInvoiced__c,EBH_SubsidyForecast__c,EBH_SubsidyMax__c From EBH_DealsBudgetMonth__c WHERE id=:dbm1.Id];
//        // System.assertEquals(30,dbmSelect.EBH_SubsidyInvoiced__c,'final: added back more 10(=30) after undelete');
//         
//         d5a.EBH_Status__c = 'Rejected'; //  paid = 140  -70 = 70
//         update d5a;
//         selDeals = [Select Id,EBH_DealSlotAllocation__c From EBH_Deal__c where Id=:d5a.Id];
//       //  System.assertEquals(null,selDeals[0].EBH_DealSlotAllocation__c,'Deal Slot Allocation must be cleared after "Rejected"');
//         
//         d5a.EBH_Status__c = 'Deal Agreed'; // max = 60 + 70
//         d5a.EBH_Quantity__c = 2 ;
//         update d5a;
//         selDeals = [Select Id,EBH_DealSlotAllocation__c From EBH_Deal__c where Id=:d5a.Id];
//       //  System.assertEquals(dsa.Id,selDeals[0].EBH_DealSlotAllocation__c,'Deal Slot Allocation must be assigned for "Deal Agreed"');
//         
//         //test batch scheduler
//         dbm1.EBH_SubsidyInvoiced__c = null;
//         dbm1.EBH_SubsidyPaid__c = null;
//         ////TH: EPH-7468 change to new formula On EBH_DealTriggerHandler.sumDealForDealBudgetMonth
         //dbm1.EBH_SubsidyForecast__c = null;
//         dbm1.EBH_SubsidyMax__c = null;
//         
//         update dbm1;
//         
//         EBH_Deal__c d6 = new EBH_Deal__c(EBH_SellerPrice__c=4000,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='Tech',EBH_DealStartDate__c=myDate,EBH_Status__c='Paid' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
//         d6.EBH_DealPrice__c = 200;
//         d6.EBH_DealFormat__c = 'iji';
//         d6.EBH_DealStartDate__c = Date.today();
//         d6.EBH_DealEndDate__c = Date.today();
//         d6.EBH_SellerEmail__c ='dd@d.com';
//         d6.EBH_MaximumPurchases__c =324;
//         d6.EBH_BusinessName__c = ac.Id;
//         d6.EBH_eBayItemID__c='123456789';
//         insert d6;
//         
//         EBH_Deal__c d6Select = [Select Id,EBH_UID__c,EBH_DealSlotAllocation__c From EBH_Deal__c where Id=:d6.Id];
//         
//        // System.assertEquals(dsa2.Id,d6Select.EBH_DealSlotAllocation__c,'Deal Slot Allocation must be assigned from trigger');
//         
//         d6.EBH_DealSlotAllocation__c = null;
//         update d6;
//         
//         Test.stopTest();
//         /*
//         BCalculateDeals bc = new BAT_CalculateDeals();
//         bc.execute(null); 
//        
//         Test.stopTest();
//         
//         d6Select = [Select Id,EBH_DealSlotAllocation__c From EBH_Deal__c where Id=:d6.Id];
//         System.assertEquals(dsa2.Id,d6Select.EBH_DealSlotAllocation__c,'Deal Slot Allocation must be assigned from batch');
//         
//         dbmSelect =[Select Id,EBH_SubsidyInvoiced__c,EBH_SubsidyPaid__c,EBH_SubsidyForecast__c,EBH_SubsidyMax__c From EBH_DealsBudgetMonth__c WHERE id=:dbm1.Id];
//         
//         System.assertEquals(30,dbmSelect.EBH_SubsidyInvoiced__c,'invoiced status summed up in batch');
//         System.assertEquals(70,dbmSelect.EBH_SubsidyPaid__c,'paid status summed up in batch');
//         System.assertEquals(40,dbmSelect.EBH_SubsidyForecast__c,'forecast status summed up in batch');
//         System.assertEquals(130,dbmSelect.EBH_SubsidyMax__c,'max status summed up in batch');
//         
//         */
//         
//         
//    }

static Id v1_recordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c',DealFilter.RECTYPE_STD).Id;
    
    //NK:02/04/2018:EPH-5465
   static testMethod void testCalculateAvailableSlot()
   {
		Account ac = new Account(Name='Seller',EBH_VATNumber__c='1122334455');
         ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
         insert ac;
		 
   		Date myDate = Date.today().addDays(30);
         
   		EBH_DealRetailCampaign__c dsa1 = new EBH_DealRetailCampaign__c(EBH_Slots__c =2);
        insert dsa1;
        
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c();
        insert sc; 
        
        
        EBH_Deal__c d1 = new EBH_Deal__c(EBH_DealSiteId__c='15', RecordTypeId = v1_recordTypeId, EBH_BusinessName__c=ac.Id,EBH_SpotlightCategory__c=sc.Id,EBH_MaximumPurchases__c =324,EBH_DealRetailCampaign__c=dsa1.Id,EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.toDay(),EBH_DealEndDate__c = myDate,EBH_Status__c='Paid' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_eBayItemID__c='123456789001');
        EBH_Deal__c d2 = new EBH_Deal__c(EBH_DealSiteId__c='15',RecordTypeId = v1_recordTypeId, EBH_BusinessName__c=ac.Id,EBH_SpotlightCategory__c=sc.Id,EBH_MaximumPurchases__c =324,EBH_DealRetailCampaign__c=dsa1.Id,EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.toDay(),EBH_DealEndDate__c = myDate,EBH_Status__c='New' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_eBayItemID__c='123456789002');
        EBH_Deal__c d3 = new EBH_Deal__c(EBH_DealSiteId__c='15',RecordTypeId = v1_recordTypeId, EBH_BusinessName__c=ac.Id,EBH_SpotlightCategory__c=sc.Id,EBH_MaximumPurchases__c =324,EBH_DealRetailCampaign__c=dsa1.Id,EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.toDay(),EBH_DealEndDate__c = myDate,EBH_Status__c='Paid' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_eBayItemID__c='123456789003');
        EBH_Deal__c d4 = new EBH_Deal__c(EBH_DealSiteId__c='15',RecordTypeId = v1_recordTypeId, EBH_BusinessName__c=ac.Id,EBH_SpotlightCategory__c=sc.Id,EBH_MaximumPurchases__c =324,EBH_DealRetailCampaign__c=dsa1.Id,EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.toDay(),EBH_DealEndDate__c = myDate,EBH_Status__c='New' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_eBayItemID__c='123456789004');
        
        
        List<EBH_Deal__c> listDeal =  new List<EBH_Deal__c>{d1,d2,d3,d4};
        insert listDeal;
       
       	EBH_DealInvoice__c div1 = new EBH_DealInvoice__c(EBH_Deal__c = d1.Id);
	    insert div1; 
        Test.startTest();
        
        EBH_DealRetailCampaign__c dsaSel = [Select Id,EBH_OpenSeatsAvailable__c from EBH_DealRetailCampaign__c where Id=:dsa1.Id];
        System.assertEquals(0,dsaSel.EBH_OpenSeatsAvailable__c,'count 0, 2 New');
        d1.EBH_Status__c = 'Rejected';
        d1.EBH_DealSiteId__c = '3';
        update d1;
        dsaSel = [Select Id,EBH_OpenSeatsAvailable__c from EBH_DealRetailCampaign__c where Id=:dsa1.Id];
        System.assertEquals(1,dsaSel.EBH_OpenSeatsAvailable__c,'count 1, +1 Rejected');
        
        delete d3;
        dsaSel = [Select Id,EBH_OpenSeatsAvailable__c from EBH_DealRetailCampaign__c where Id=:dsa1.Id];
        System.assertEquals(2,dsaSel.EBH_OpenSeatsAvailable__c,'count 2,  1 deleted');
        
        undelete d3;
        dsaSel = [Select Id,EBH_OpenSeatsAvailable__c from EBH_DealRetailCampaign__c where Id=:dsa1.Id];
        System.assertEquals(1,dsaSel.EBH_OpenSeatsAvailable__c,'count 1,   1 undeleted');
        
        Test.stopTest();
        
   }
   
   /*static testMethod void testNegotiateLock()
   {
   		Account ac = new Account(Name='Seller',EBH_VATNumber__c='1122334455');
         ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
         insert ac;
		 
   		Date myDate = Date.newInstance(2017, 1, 1);
         
   		EBH_DealRetailCampaign__c dsa1 = new EBH_DealRetailCampaign__c(EBH_Slots__c =2);
        insert dsa1;
        
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c();
        insert sc; 
        
        EBH_Deal__c d1 = new EBH_Deal__c(RecordTypeId = v1_recordTypeId, EBH_BusinessName__c=ac.Id,EBH_SpotlightCategory__c=sc.Id,EBH_MaximumPurchases__c =324,EBH_DealRetailCampaign__c=dsa1.Id,EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.toDay(),EBH_DealEndDate__c = myDate,EBH_Status__c='New' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
		insert d1;
        
   		Test.startTest();
   		
   		d1.EBH_Status__c  = 'Negotiating';
		update d1;

		//TH: 10/11/2021: Comment out System.runAs(standardUser) : Error : INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY
		//User standardUser = EBH_TestDataFactory.createUser('Standard User Profile'); 
   		//System.runAs(standardUser)  //Deals User Profile
   		//{       
			try
			{
				d1.EBH_Status__c  = 'New';
				update d1;
			}catch(Exception ex)
			{
				System.assert(ex.getMessage().contains('Deal is locked while in Negotiating'),' Deal is locked while in Negotiating!');
			}		
			try
			{
				d1.EBH_Status__c  = 'Negotiating';
				d1.EBH_Quantity__c=2;
				update d1;
			}catch(Exception ex)
			{
				System.assert(ex.getMessage().contains('Deal is locked while in Negotiating'),' Deal is locked while in Negotiating!');
			}	
   		//}
   		Test.stopTest();
   }*/
   
   static testMethod void testCheckDealNotification()
   {
   		Account ac = new Account(Name='Seller',EBH_VATNumber__c='1122334455');
         ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
         insert ac;
		 
   		Date myDate = Date.today().addDays(2);
         
   		EBH_DealRetailCampaign__c dsa1 = new EBH_DealRetailCampaign__c(
		   EBH_Slots__c =2,
		   EBH_Date__c = Date.today(),
		   EPH_EndDate__c = Date.today().addDays(7),
		   Start_Time__c = Time.newInstance(8, 0, 0, 0),
		   End_Time__c = Time.newInstance(8, 0, 0, 0)
		);
        insert dsa1;
        
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c();
        insert sc; 
        
		Contact oContact = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',FirstName='firstname',Salutation='Mr.',LastName='test1',Email='test1@test.com' , AccountId = ac.Id,Contact_Role__c='Deals');
        insert oContact;
			
        EBH_Deal__c d1 = new EBH_Deal__c( Seller_Contact__c=oContact.Id, RecordTypeId = v1_recordTypeId, EBH_DealStartTime__c= System.now().time(), EBH_DealStartDate__c=System.toDay().addDays(1),EBH_eBayItemID__c='12345678901',EBH_DEALSITEID__c='77',
        	 EBH_BusinessName__c=ac.Id,EBH_SpotlightCategory__c=sc.Id,EBH_MaximumPurchases__c =324,EBH_DealRetailCampaign__c=dsa1.Id,EBH_SellerPrice__c=40,EBH_DealPrice__c=20,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealEndDate__c = myDate, EBH_DealEndTime__c= System.now().time(), EBH_Status__c='New' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
         EBH_Deal__c d2 = new EBH_Deal__c(Seller_Contact__c=oContact.Id, RecordTypeId = v1_recordTypeId, EBH_DealStartTime__c= System.now().time(), EBH_DealStartDate__c=System.toDay().addDays(1),EBH_eBayItemID__c='12345678902',EBH_DEALSITEID__c='77',
        	 EBH_BusinessName__c=ac.Id,EBH_SpotlightCategory__c=sc.Id,EBH_MaximumPurchases__c =324,EBH_DealRetailCampaign__c=dsa1.Id,EBH_SellerPrice__c=40,EBH_DealPrice__c=0,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealEndDate__c = myDate, EBH_DealEndTime__c= System.now().time(), EBH_Status__c='New' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);



        insert new List<EBH_Deal__c>{d1,d2};
        
        
   		Test.startTest();
   		
   		d1.EBH_Status__c  = EBH_ConstantsUtility.DEAL_STATUS_PLANNED;
   		d2.EBH_Status__c  = EBH_ConstantsUtility.DEAL_STATUS_PLANNED;
   		update new List<EBH_Deal__c>{d1,d2};
   		
   		Test.stopTest();
   		//time base workflow does not work in test class
   		//simulate it as timebase runs
   		d1.Notify_Counter__c  = 1;
   		d2.Notify_Counter__c  = 1;
   		update new List<EBH_Deal__c>{d1,d2};
   		
   		Map<Id,EBH_Deal__c> mapSel = new Map<Id,EBH_Deal__c>([Select Id,TriggerEmailSubsidy__c,TriggerEmailNoSubsidy__c,Notify_Counter__c From EBH_Deal__c Where Id=:d1.Id OR Id=:d2.Id ]);
   		System.assertNotEquals(null,mapSel.get(d1.Id).TriggerEmailSubsidy__c,' date field populated to trigger email alert'); 
   		System.assertNotEquals(null,mapSel.get(d2.Id).TriggerEmailNoSubsidy__c,' date field populated to trigger email alert'); 
   }
   
 /*  static testMethod void testSumDealWhenDealInsert()
   {
   		EBH_DealsBudget__c db1 = new EBH_DealsBudget__c(Deal_Site__c='77', EBH_Vertical__c='Soft Home', EBH_Quarter__c = 'Q1',Year__c = String.valueOf(Date.today().year()),Non_Payout_Items_Estimate__c = 10);
		 EBH_DealsBudget__c db2 = new EBH_DealsBudget__c(Deal_Site__c='77', EBH_Vertical__c='Hard Home', EBH_Quarter__c = 'Q2',Year__c = String.valueOf(Date.today().year()),Non_Payout_Items_Estimate__c = 10);
		 insert new List<EBH_DealsBudget__c>{db1,db2};
		 Account ac = new Account(Name='Seller',EBH_VATNumber__c='VAT1111');
	     ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
	     insert ac;
		 EBH_Deal__c d1a = new EBH_Deal__c(RecordTypeId = v1_recordTypeId, EBH_SellerPrice__c=1000,EBH_SoldItems__c=2,EBH_Vertical__c='Soft Home',EBH_DealSiteId__c='77',EBH_Status__c='New',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_Quantity__c=1);
	     d1a.EBH_DealPrice__c = 200;
	     d1a.EBH_DealFormat__c = 'iji';
	     d1a.EBH_DealStartDate__c = Date.newInstance(Date.today().year(),1,4);
	     d1a.EBH_DealEndDate__c = Date.today()-60;
	     d1a.EBH_SellerEmail__c ='dd@d.com';
	     d1a.EBH_MaximumPurchases__c =324;
	     d1a.EBH_BusinessName__c = ac.Id;
	     d1a.Subsidy_Running__c = 10;
	     d1a.EBH_Payout_SI__c = 10;
	     
	     EBH_Deal__c d2a = new EBH_Deal__c(RecordTypeId = v1_recordTypeId, EBH_SellerPrice__c=1000,EBH_SoldItems__c=2,EBH_Vertical__c='Hard Home',EBH_DealSiteId__c='77',EBH_Status__c='New',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_Quantity__c=1);
	     d2a.EBH_DealPrice__c = 200;
	     d2a.EBH_DealFormat__c = 'iji';
	     d2a.EBH_DealStartDate__c = Date.newInstance(Date.today().year(),4,4);
	     d2a.EBH_DealEndDate__c = Date.today()-60;
	     d2a.EBH_SellerEmail__c ='dd@d.com';
	     d2a.EBH_MaximumPurchases__c =324;
	     d2a.EBH_BusinessName__c = ac.Id;
	     d2a.Subsidy_Running__c = 10;
	     d2a.EBH_Payout_SI__c = 10;
	     Test.startTest();
	     insert new List<EBH_Deal__c>{d1a,d2a};
	     Test.stopTest();
	     List<EBH_Deal__c> lstDeal = [select Non_Payout_Items_Estimate_N__c from EBH_Deal__c where id IN: new List<EBH_Deal__c>{d1a,d2a}];
	     
	     System.assertEquals(10,lstDeal[0].Non_Payout_Items_Estimate_N__c);
         System.assertEquals(10,lstDeal[1].Non_Payout_Items_Estimate_N__c);
        
	    List<EBH_DealsBudget__c> lstDealBudget = [Select e.Subsidy_Running__c, e.Subsidy_Planned__c, e.Subsidy_Forecast__c, e.Subsidy_Final__c From EBH_DealsBudget__c e where id IN: new List<EBH_DealsBudget__c>{db1,db2}];
        System.assertEquals(10,lstDealBudget[0].Subsidy_Running__c);
        //System.assertEquals(790,lstDealBudget[0].Subsidy_Planned__c);
        System.assertEquals(800,lstDealBudget[0].Subsidy_Final__c);
        
        System.assertEquals(10,lstDealBudget[1].Subsidy_Running__c);
        //System.assertEquals(790,lstDealBudget[1].Subsidy_Planned__c);
        System.assertEquals(800,lstDealBudget[1].Subsidy_Final__c);
        
        List<EBH_DealsBudgetMonth__c> lstDealBudgetMonth = [Select e.Subsidy_Running__c, e.Subsidy_Planned__c, e.Subsidy_Final__c, e.EBH_SubsidyForecast__c, e.EBH_MonthYear__c, e.EBH_DealsBudget__r.EBH_Vertical__c, e.EBH_DealsBudget__c From EBH_DealsBudgetMonth__c e where EBH_DealsBudget__c IN: new List<EBH_DealsBudget__c>{db1,db2}];
	     System.assertEquals(6,lstDealBudgetMonth.size());
	     for(EBH_DealsBudgetMonth__c dMonth : lstDealBudgetMonth){
	     	if(dMonth.EBH_MonthYear__c == '1'+String.valueOf(Date.today().year()) || dMonth.EBH_MonthYear__c == '4'+String.valueOf(Date.today().year())){
	     		System.assertEquals(10,dMonth.Subsidy_Running__c);
		        //System.assertEquals(790,dMonth.Subsidy_Planned__c);
		        System.assertEquals(800,dMonth.Subsidy_Final__c);
	     	}
	     }
   }
   */
  /*
   static testMethod void testSumDealWhenDealUpdate()
   {
   		EBH_DealsBudget__c db1 = new EBH_DealsBudget__c(Deal_Site__c='77', EBH_Vertical__c='Soft Home', EBH_Quarter__c = 'Q1',Year__c = String.valueOf(Date.today().year()),Non_Payout_Items_Estimate__c = 20);
		 EBH_DealsBudget__c db2 = new EBH_DealsBudget__c(Deal_Site__c='77', EBH_Vertical__c='Hard Home', EBH_Quarter__c = 'Q2',Year__c = String.valueOf(Date.today().year()),Non_Payout_Items_Estimate__c = 10);
		 insert new List<EBH_DealsBudget__c>{db1,db2};
		 Account ac = new Account(Name='Seller',EBH_VATNumber__c='VAT1111');
	     ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
	     insert ac;
		 EBH_Deal__c d1a = new EBH_Deal__c(RecordTypeId = v1_recordTypeId, EBH_SellerPrice__c=1000,EBH_SoldItems__c=2,EBH_Vertical__c='Soft Home',EBH_DealSiteId__c='77',EBH_Status__c='New',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_Quantity__c=1);
	     d1a.EBH_DealPrice__c = 200;
	     d1a.EBH_DealFormat__c = 'iji';
	     d1a.EBH_DealStartDate__c = Date.newInstance(Date.today().year(),1,4);
	     d1a.EBH_DealEndDate__c = Date.today()-60;
	     d1a.EBH_SellerEmail__c ='dd@d.com';
	     d1a.EBH_MaximumPurchases__c =324;
	     d1a.EBH_BusinessName__c = ac.Id;
	     d1a.Subsidy_Running__c = 10;
	     d1a.EBH_Payout_SI__c = 10;
	     EBH_Deal__c d2a = new EBH_Deal__c(RecordTypeId = v1_recordTypeId, EBH_SellerPrice__c=1000,EBH_SoldItems__c=2,EBH_Vertical__c='Hard Home',EBH_DealSiteId__c='77',EBH_Status__c='New',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_Quantity__c=1);
	     d2a.EBH_DealPrice__c = 200;
	     d2a.EBH_DealFormat__c = 'iji';
	     d2a.EBH_DealStartDate__c = Date.newInstance(Date.today().year(),4,4);
	     d2a.EBH_DealEndDate__c = Date.today()-60;
	     d2a.EBH_SellerEmail__c ='dd@d.com';
	     d2a.EBH_MaximumPurchases__c =324;
	     d2a.EBH_BusinessName__c = ac.Id;
	     d2a.Subsidy_Running__c = 10;
	     d2a.EBH_Payout_SI__c = 10;
	     insert new List<EBH_Deal__c>{d1a,d2a};
	     Test.startTest();
	     d2a.EBH_DealStartDate__c = Date.newInstance(Date.today().year(),2,4);
	     d2a.EBH_Vertical__c = 'Soft Home';
	     update d2a;
	     Test.stopTest();
	     EBH_Deal__c deal0 = [select Non_Payout_Items_Estimate_N__c from EBH_Deal__c where id =: d1a.Id];
	     System.assertEquals(20,deal0.Non_Payout_Items_Estimate_N__c);
         
         EBH_Deal__c deal1 = [select Non_Payout_Items_Estimate_N__c from EBH_Deal__c where id =: d2a.Id];
	     System.assertEquals(20,deal1.Non_Payout_Items_Estimate_N__c);
         
	     EBH_DealsBudget__c dealBudget = [Select e.Subsidy_Running__c, e.Subsidy_Planned__c, e.Subsidy_Forecast__c, e.Subsidy_Final__c From EBH_DealsBudget__c e where id =: db1.Id];
        System.assertEquals(10*2,dealBudget.Subsidy_Running__c);
        //System.assertEquals(790*2,dealBudget.Subsidy_Planned__c);
        System.assertEquals(800*2,dealBudget.Subsidy_Final__c);
        
        EBH_DealsBudget__c dealBudget2 = [Select e.Subsidy_Running__c, e.Subsidy_Planned__c, e.Subsidy_Forecast__c, e.Subsidy_Final__c From EBH_DealsBudget__c e where id =: db2.Id];
        System.assertEquals(0,dealBudget2.Subsidy_Running__c);
        //System.assertEquals(0,dealBudget2.Subsidy_Planned__c);
        System.assertEquals(0,dealBudget2.Subsidy_Final__c);
        
        List<EBH_DealsBudgetMonth__c> lstDealBudgetMonth = [Select e.Subsidy_Running__c, e.Subsidy_Planned__c, e.Subsidy_Final__c, e.EBH_SubsidyForecast__c, e.EBH_MonthYear__c, e.EBH_DealsBudget__r.EBH_Vertical__c, e.EBH_DealsBudget__c From EBH_DealsBudgetMonth__c e where EBH_DealsBudget__c IN: new List<EBH_DealsBudget__c>{db1,db2}];
	     System.assertEquals(6,lstDealBudgetMonth.size());
	     for(EBH_DealsBudgetMonth__c dMonth : lstDealBudgetMonth){
	     	if(dMonth.EBH_MonthYear__c == '1'+String.valueOf(Date.today().year()) || dMonth.EBH_MonthYear__c == '2'+String.valueOf(Date.today().year())){
	     		System.assertEquals(10,dMonth.Subsidy_Running__c);
		        //System.assertEquals(790,dMonth.Subsidy_Planned__c);
		        System.assertEquals(800,dMonth.Subsidy_Final__c);
	     	}
	     }
   }
   */
    //DHE 25/09/2019 method for testing get images
    //
   static testMethod void testgettingImages(){
        EBH_DealsBudget__c db1 = new EBH_DealsBudget__c(Deal_Site__c='77', EBH_Vertical__c='Soft Home', EBH_Quarter__c = 'Q1',Year__c = String.valueOf(Date.today().year()),Non_Payout_Items_Estimate__c = 10);
		 EBH_DealsBudget__c db2 = new EBH_DealsBudget__c(Deal_Site__c='77', EBH_Vertical__c='Hard Home', EBH_Quarter__c = 'Q2',Year__c = String.valueOf(Date.today().year()),Non_Payout_Items_Estimate__c = 10);
		 insert new List<EBH_DealsBudget__c>{db1,db2};
		 Account ac = new Account(Name='Seller',EBH_VATNumber__c='VAT1111');
	     ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
	     insert ac;
		 
        Test.startTest();
        
        	EBH_Deal__c d1a = new EBH_Deal__c(EBH_DealStartDate__c = Date.newInstance(Date.today().year(),1,1), RecordTypeId = v1_recordTypeId, EBH_DealPrice__c=10,Current_Seller_Price__c=10,ebh_businessname__c=ac.id,EBH_eBayItemID__c='233121274562', EBH_SellerPrice__c=1000,EBH_SoldItems__c=2,EBH_Vertical__c='Soft Home',EBH_DealSiteId__c='77',EBH_Status__c='New',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_Quantity__c=1);
			insert d1a;
			
        Test.stopTest();
        	EBH_Deal__c dSel = [Select Id,Current_Seller_Price__c From EBH_Deal__c Where Id=:d1a.Id];
			System.assertEquals(109.99,dSel.Current_Seller_Price__c,'sell price updated from api call ( mocked: SimpleeBayResponse)');
        
    }
   /* static testMethod void testSumDealWhenDealDeleted()
   {
   		EBH_DealsBudget__c db1 = new EBH_DealsBudget__c(Deal_Site__c='77', EBH_Vertical__c='Soft Home', EBH_Quarter__c = 'Q1',Year__c = String.valueOf(Date.today().year()));
		 EBH_DealsBudget__c db2 = new EBH_DealsBudget__c(Deal_Site__c='77', EBH_Vertical__c='Hard Home', EBH_Quarter__c = 'Q2',Year__c = String.valueOf(Date.today().year()));
		 insert new List<EBH_DealsBudget__c>{db1,db2};
		 Account ac = new Account(Name='Seller',EBH_VATNumber__c='VAT1111');
	     ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
	     insert ac;
		 EBH_Deal__c d1a = new EBH_Deal__c(RecordTypeId = v1_recordTypeId, EBH_SellerPrice__c=1000,EBH_SoldItems__c=2,EBH_Vertical__c='Soft Home',EBH_DealSiteId__c='77',EBH_Status__c='New',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_Quantity__c=1);
	     d1a.EBH_DealPrice__c = 200;
	     d1a.EBH_DealFormat__c = 'iji';
	     d1a.EBH_DealStartDate__c = Date.newInstance(Date.today().year(),1,4);
	     d1a.EBH_DealEndDate__c = Date.today()-60;
	     d1a.EBH_SellerEmail__c ='dd@d.com';
	     d1a.EBH_MaximumPurchases__c =324;
	     d1a.EBH_BusinessName__c = ac.Id;
	     d1a.Subsidy_Running__c = 10;
	     d1a.EBH_Payout_SI__c = 10;
	     EBH_Deal__c d2a = new EBH_Deal__c(RecordTypeId = v1_recordTypeId, EBH_SellerPrice__c=1000,EBH_SoldItems__c=2,EBH_Vertical__c='Hard Home',EBH_DealSiteId__c='77',EBH_Status__c='New',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_Quantity__c=1);
	     d2a.EBH_DealPrice__c = 200;
	     d2a.EBH_DealFormat__c = 'iji';
	     d2a.EBH_DealStartDate__c = Date.newInstance(Date.today().year(),4,4);
	     d2a.EBH_DealEndDate__c = Date.today()-60;
	     d2a.EBH_SellerEmail__c ='dd@d.com';
	     d2a.EBH_MaximumPurchases__c =324;
	     d2a.EBH_BusinessName__c = ac.Id;
	     d2a.Subsidy_Running__c = 10;
	     d2a.EBH_Payout_SI__c = 10;
	     insert new List<EBH_Deal__c>{d1a,d2a};
	     
	     Test.startTest();
	     delete d2a;
	     Test.stopTest();
	     EBH_DealsBudget__c dealBudget = [Select e.Subsidy_Running__c, e.Subsidy_Planned__c, e.Subsidy_Forecast__c, e.Subsidy_Final__c From EBH_DealsBudget__c e where id =: db1.Id];
        System.assertEquals(10,dealBudget.Subsidy_Running__c);
        //System.assertEquals(790,dealBudget.Subsidy_Planned__c);
        System.assertEquals(800,dealBudget.Subsidy_Final__c);
        
        EBH_DealsBudget__c dealBudget2 = [Select e.Subsidy_Running__c, e.Subsidy_Planned__c, e.Subsidy_Forecast__c, e.Subsidy_Final__c From EBH_DealsBudget__c e where id =: db2.Id];
        System.assertEquals(0,dealBudget2.Subsidy_Running__c);
        //System.assertEquals(0,dealBudget2.Subsidy_Planned__c);
        System.assertEquals(0,dealBudget2.Subsidy_Final__c);
        
        List<EBH_DealsBudgetMonth__c> lstDealBudgetMonth = [Select e.Subsidy_Running__c, e.Subsidy_Planned__c, e.Subsidy_Final__c, e.EBH_SubsidyForecast__c, e.EBH_MonthYear__c, e.EBH_DealsBudget__r.EBH_Vertical__c, e.EBH_DealsBudget__c From EBH_DealsBudgetMonth__c e where EBH_DealsBudget__c IN: new List<EBH_DealsBudget__c>{db1,db2}];
	     System.assertEquals(6,lstDealBudgetMonth.size());
	     for(EBH_DealsBudgetMonth__c dMonth : lstDealBudgetMonth){
	     	if(dMonth.EBH_MonthYear__c == '1'+String.valueOf(Date.today().year())){
	     		System.assertEquals(10,dMonth.Subsidy_Running__c);
		        //System.assertEquals(790,dMonth.Subsidy_Planned__c);
		        System.assertEquals(800,dMonth.Subsidy_Final__c);
	     	}else if(dMonth.EBH_MonthYear__c == '4'+String.valueOf(Date.today().year())){
	     		System.assertEquals(0,dMonth.Subsidy_Running__c);
		        //System.assertEquals(0,dMonth.Subsidy_Planned__c);
		        System.assertEquals(0,dMonth.Subsidy_Final__c);
	     	}
	     }
   }
   */
  
   /*static testMethod void testsendClickAcceptDeal()
   {
   		Account ac = new Account(Name='Seller',EBH_VATNumber__c='1122334455');
         ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
         insert ac;
		 
   		Date myDate = Date.today().addDays(2);
         
   		EBH_DealRetailCampaign__c dsa1 = new EBH_DealRetailCampaign__c(EBH_Slots__c =2);
        insert dsa1;
        
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c();
        insert sc; 
        
        EBH_Deal__c d1 = new EBH_Deal__c(RecordTypeId = v1_recordTypeId, EBH_DealStartTime__c= System.now().time(), EBH_DealStartDate__c=System.toDay().addDays(1),EBH_eBayItemID__c='12345678901',EBH_DEALSITEID__c='15',
        	 EBH_BusinessName__c=ac.Id,EBH_SpotlightCategory__c=sc.Id,EBH_MaximumPurchases__c =324,EBH_DealRetailCampaign__c=dsa1.Id,EBH_SellerPrice__c=40,EBH_DealPrice__c=20,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealEndDate__c = myDate,EBH_Status__c='New' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
         EBH_Deal__c d2 = new EBH_Deal__c(RecordTypeId = v1_recordTypeId, EBH_DealStartTime__c= System.now().time(), EBH_DealStartDate__c=System.toDay().addDays(1),EBH_eBayItemID__c='12345678902',EBH_DEALSITEID__c='15',
        	 EBH_BusinessName__c=ac.Id,EBH_SpotlightCategory__c=sc.Id,EBH_MaximumPurchases__c =324,EBH_DealRetailCampaign__c=dsa1.Id,EBH_SellerPrice__c=40,EBH_DealPrice__c=0,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealEndDate__c = myDate,EBH_Status__c='New' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
        	 
        insert new List<EBH_Deal__c>{d1,d2};
   	Test.startTest();
   		d1.EBH_Status__c = EBH_ConstantsUtility.DEAL_STATUS_PLANNED;
   		d1.DateAcceptSend__c = system.now();
   		d1.EBH_DealSiteId__c = '15';
   		d2.EBH_Status__c = EBH_ConstantsUtility.DEAL_STATUS_PLANNED;
   		d2.DateAcceptSend__c = system.now();
   		d2.EBH_DealSiteId__c = '15';
   	 	update new List<EBH_Deal__c>{d1,d2};
   	Test.stopTest();
   }*/
   
   static testMethod void testClone()
   {
   	Account ac = new Account(Name='Seller',EBH_VATNumber__c='1122334455');
         ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
         insert ac;
		 
   		Date myDate = Date.today().addDays(2);
         
   		EBH_DealRetailCampaign__c dsa1 = new EBH_DealRetailCampaign__c(EBH_Slots__c =2);
        insert dsa1;
        
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c();
        insert sc; 
        
        EBH_Deal__c d1 = new EBH_Deal__c(RecordTypeId = v1_recordTypeId, EBH_DealStartTime__c= System.now().time(), EBH_DealStartDate__c=System.toDay().addDays(1),EBH_eBayItemID__c='12345678901',EBH_DEALSITEID__c='15',
        	 EBH_BusinessName__c=ac.Id,EBH_SpotlightCategory__c=sc.Id,EBH_MaximumPurchases__c =324,EBH_DealRetailCampaign__c=dsa1.Id,EBH_SellerPrice__c=40,EBH_DealPrice__c=20,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealEndDate__c = myDate,EBH_Status__c='New' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
        insert d1;
        	 
   		EBH_Deal__c d2 = EBH_DealTriggerHandler.CloneDealCustom(d1);
   }

   static testMethod void createEmailLog(){
		Account ac = new Account(Name='Seller',EBH_VATNumber__c='1122334455');
		ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
		insert ac;

		Date myDate = Date.today().addDays(2);

		EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c();
		insert sc;

		EBH_Deal__c d1 = new EBH_Deal__c(RecordTypeId = v1_recordTypeId, EBH_DealSiteId__c='77',EBH_BusinessName__c=ac.Id,EBH_SpotlightCategory__c=sc.Id,EBH_MaximumPurchases__c =324,EBH_SellerPrice__c=40,EBH_DealPrice__c=50,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.toDay(),EBH_DealEndDate__c = myDate,EBH_Status__c='New' ,EBH_DealFormat__c='Featured',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_eBayItemID__c='123456789');
		EBH_Deal__c d2 = new EBH_Deal__c(RecordTypeId = v1_recordTypeId, EBH_DealSiteId__c='77',EBH_BusinessName__c=ac.Id,EBH_SpotlightCategory__c=sc.Id,EBH_MaximumPurchases__c =324,EBH_SellerPrice__c=40,EBH_DealPrice__c=40,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.toDay(),EBH_DealEndDate__c = myDate,EBH_Status__c='New' ,EBH_DealFormat__c='Featured',EBH_Category__c='Gold', EBH_ProductTitle__c='product 2',EBH_SellerEmail__c='sales2@test.com',EBH_Quantity__c=1,EBH_eBayItemID__c='12345678936546');
		List<EBH_Deal__c> lst = new List<EBH_Deal__c>{d1,d2};
		

		Test.startTest();
			insert lst;
			EBH_DealTriggerHandler.createEmailLog(lst);
		Test.stopTest();
   }
   
		
		static testMethod void testCheckDuplicateListingId(){
        
			ID dealNARecordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2').Id;
			RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
			RecordType contactRecordTYpe = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
			Account ac = new Account(Name='Seller',EBH_VATNumber__c='VAT1111',RecordTypeID = sellerRecordType.Id);
		     insert ac;
		     Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = ac.Id, 
									  //EBH_Decision_Maker_Role__c = 'Deals', //MN:13/05/2021:US-0009542 - [NA] Deals: Remove unused value from 'Decision Maker Role' on Contact
									  Contact_Role__c='Deals', //MN:13/05/2021:US-0009542 - use Contact_Role__c instead
									  recordtypeId = contactRecordTYpe.Id);
             insert contact1;
			 EBH_Deal__c d1a = new EBH_Deal__c( EBH_SellerPrice__c=1000,EBH_SoldItems__c=2,EBH_Vertical__c='Soft Home',EBH_DealSiteId__c='77',EBH_Status__c='New',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_Quantity__c=1);
		     d1a.EBH_DealPrice__c = 200;
		     d1a.EBH_DealFormat__c = 'iji';
		     d1a.EBH_DealStartDate__c = Date.today()+1;
		     d1a.EBH_DealEndDate__c = Date.today()+30;
		     d1a.EBH_SellerEmail__c ='dd@d.com';
		     d1a.EBH_MaximumPurchases__c =1;
		     d1a.EBH_BusinessName__c = ac.Id;
		     d1a.Subsidy_Running__c = 10;
		     d1a.EBH_Payout_SI__c = 10;
		     d1a.recordtypeId = dealNARecordTypeId;
		     d1a.EBH_eBayItemID__c='123456789000';
		     d1a.Seller_Approver_1__c=contact1.Id;
		     insert d1a;
		     
		     Test.startTest();
		     try{
		     	EBH_Deal__c d2a = new EBH_Deal__c(EBH_SellerPrice__c=1000,EBH_SoldItems__c=2,EBH_Vertical__c='Hard Home',EBH_DealSiteId__c='77',EBH_Status__c='New',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_Quantity__c=1);
			     d2a.EBH_DealPrice__c = 200;
			     d2a.EBH_DealFormat__c = 'ijk';
			     d2a.EBH_DealStartDate__c = Date.today()+1;
			     d2a.EBH_DealEndDate__c = Date.today()+30;
			     d2a.EBH_SellerEmail__c ='dd@d.com';
			     d2a.EBH_MaximumPurchases__c =1;
			     d2a.EBH_BusinessName__c = ac.Id;
			     d2a.Subsidy_Running__c = 10;
			     d2a.EBH_Payout_SI__c = 10;
			     d2a.recordtypeId = dealNARecordTypeId;
			     d2a.EBH_eBayItemID__c='123456789000';
			     d2a.Seller_Approver_1__c=contact1.Id;
			     insert d2a;
		    }catch (Exception ex) {
				System.assert(true);
				System.assert(ex.getMessage().contains(System.label.DD_DuplicateError));
			}
		     Test.stopTest();
		}

		/*********************************************************************************************************************************
		@ Method:         test_notifyMerchantApprover
		@ Version:        1.0
		@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
		@ Purpose:        US-0008230
		@                 It was migrated from join instance with original name: Deal_HandlerTest.test_notifyMerchantApprover
		@				  Test method for EBH_DealTriggerHandler.notifyMerchantApproverDealsReady4approval		
		------------------------------------------------------------------------------------------------------------------------------
		@ Parameter:	none
		----------------------------------------------------------------------------------------------------------------------------------
		@ Change history:  07.10.2020 / Sophal Noch / Created the method.
		*********************************************************************************************************************************/
		@isTest public static void test_notifyMerchantApprover(){

			// Deal__c deal = [SELECT Status__c FROM Deal__c WHERE Product_Title__c = 'AMTProductTest'];
			// deal.Status__c = 'In Approval';
			// update deal;

			Account ac = new Account(Name='Seller',EBH_VATNumber__c='1122334455');
			ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
			insert ac;
			RecordType contactRecordTYpe = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
			Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = ac.Id, 
									  //EBH_Decision_Maker_Role__c = 'Deals', //MN:13/05/2021:US-0009542 - [NA] Deals: Remove unused value from 'Decision Maker Role' on Contact
									  Contact_Role__c='Deals', //MN:13/05/2021:US-0009542 - use Contact_Role__c instead
									  recordtypeId = contactRecordTYpe.Id);
             insert contact1;
             
			EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c();
			insert sc;
			
			Id dealNARecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByDeveloperName().get('Deal_V2').getRecordTypeId();
	
			EBH_Deal__c d1 = new EBH_Deal__c(
				EBH_DealStartTime__c= System.now().time(), 
				EBH_DealStartDate__c=System.toDay().addDays(1),
				EBH_eBayItemID__c='123456789000',
				EBH_BusinessName__c=ac.Id,
				EBH_SpotlightCategory__c=sc.Id,
				EBH_SellerPrice__c=40,
				EBH_DealPrice__c=20,
				EBH_Vertical__c='Business & Industrial',
				EBH_Category__c = 'Business',
				EBH_DealEndDate__c = System.toDay().addMonths(2),
				EBH_Status__c= 'New' ,
				EBH_ProductTitle__c='product 2',
				EBH_Quantity__c=1,
				RecordTypeId = dealNARecordTypeId,
				Merchant_Approver__c = UserInfo.getUserId() ,
				Seller_Approver_1__c=contact1.Id
			);
			insert d1;
			d1.EBH_Status__c = 'In Approval';
			update d1;

		}
		
		/*********************************************************************************************************************************
		@ Method:         test_newDealNotBackDate
		@ Version:        1.0
		@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
		@ Purpose:        Test method for EBH_DealTriggerHandler.newDealNotBackDate		
		------------------------------------------------------------------------------------------------------------------------------
		@ Parameter:	none
		----------------------------------------------------------------------------------------------------------------------------------
		@ Change history:  07.10.2020 / Sophal Noch / Created the method.
		*********************************************************************************************************************************/
		@isTest public static void test_newDealNotBackDate(){
			Deal_Timezone__c dealTimezone = Deal_Timezone__c.getInstance();
			Account ac = new Account(Name='Seller',EBH_VATNumber__c='1122334455');
			ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
			insert ac;
			RecordType contactRecordTYpe = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
			Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = ac.Id, 
									  //EBH_Decision_Maker_Role__c = 'Deals', //MN:13/05/2021:US-0009542 - [NA] Deals: Remove unused value from 'Decision Maker Role' on Contact
									  Contact_Role__c='Deals', //MN:13/05/2021:US-0009542 - use Contact_Role__c instead
									  recordtypeId = contactRecordTYpe.Id);
             insert contact1;
             
			EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c();
			insert sc;
			Id dealNARecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByDeveloperName().get('Deal_V2').getRecordTypeId();
			EBH_Deal__c d1 = new EBH_Deal__c(
				EBH_DealStartTime__c= System.now().time(), 
				EBH_DealStartDate__c=System.toDay().addDays(-2),
				EBH_eBayItemID__c='000000000016',
				EBH_BusinessName__c=ac.Id,
				EBH_SpotlightCategory__c=sc.Id,
				EBH_SellerPrice__c=40,
				EBH_DealPrice__c=20,
				EBH_Vertical__c='Business & Industrial',
				EBH_Category__c = 'Business',
				EBH_DealEndDate__c = System.toDay().addMonths(2),
				EBH_Status__c= 'New' ,
				EBH_ProductTitle__c='product 2',
				EBH_Quantity__c=1,
				RecordTypeId = dealNARecordTypeId,
				Merchant_Approver__c = UserInfo.getUserId() ,
				Seller_Approver_1__c=contact1.Id
			);
			Timezone tz = Timezone.getTimeZone(dealTimezone.TimeZone__c);
            Datetime dNow =  DateTime.newInstance(System.Now().getTime() + tz.getOffset(System.Now()));
            Time timeBacked = Time.newInstance(dNow.hour(),dNow.minute(),dNow.second(),dNow.millisecond());
            timeBacked=timeBacked.addMinutes(-2);
            d1.EBH_DealStartTime__c=timeBacked;
            Test.startTest();
            try{
                insert d1;
            }catch(Exception e){
                System.assert(e.getMessage().contains(Label.NEW_DEAL_CANNOT_BE_BACKDATED));
            }
        	Test.stopTest();
		}
		
		/*********************************************************************************************************************************
		@ Method:         testLockCompletedDeals
		@ Version:        1.0
		@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
		@ Purpose:        Test method for EBH_DealTriggerHandler.newDealNotBackDate		
		------------------------------------------------------------------------------------------------------------------------------
		@ Parameter:	none
		----------------------------------------------------------------------------------------------------------------------------------
		@ Change history:  28.12.2020 / sovantheany dim / Created the method.migrate from join instant
		*********************************************************************************************************************************/
		@isTest public static void testLockCompletedDeals(){
        Profile Profile = [select Id,Name from Profile where Name = 'NA Standard User Base'];//Daily Deals Profil
        PermissionSet PS = [select Id, Name From PermissionSet Where Name = 'US_Manage_Deals'];
        
        User existAdminUser = [Select Id from User Where isActive = true and Profile.Name = 'System Administrator' Limit 1];

        User user = new User();
		
		user.Alias='AMT1';
		user.Email='amtmail2@ebay.com';
		user.EmailEncodingKey='UTF-8';
		user.LastName='AMTUser212';
		user.LanguageLocaleKey='en_US'; 
		user.LocaleSidKey='en_US';
		user.ProfileId = Profile.Id;
		user.TimeZoneSidKey='America/Los_Angeles';
		user.UserName='amtmail2@ebay.com';

		System.runAs(existAdminUser){  // 24.06.2022 / Sophal Noch / US-0011987 : fix mix dml error
			insert user;
		}

        
        Profile adminProfile = [select Id,Name from Profile where Name = 'System Administrator'];

        User userAdmin = new User();
        userAdmin.Alias='AMT';
        userAdmin.Email='amtmail@ebay.com';
        userAdmin.EmailEncodingKey='UTF-8';
        userAdmin.LastName='AMTUser';
        userAdmin.LanguageLocaleKey='en_US'; 
        userAdmin.LocaleSidKey='en_US';
        userAdmin.ProfileId = adminProfile.Id;
        userAdmin.TimeZoneSidKey='America/Los_Angeles';
        userAdmin.UserName='amtmail@ebay.com';

		System.runAs(existAdminUser){
			insert userAdmin;
		}
        
        System.runAs(userAdmin){
        PermissionSetAssignment PSA = new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = PS.Id);
        insert PSA;
        
        Id sellerRT_Id = ApexUtil.getRecordTypeByName('Account','EBH_Seller').Id;
    	Account ac = new Account(Name='Seller',EBH_VATNumber__c='1122334455',recordtypeId=sellerRT_Id);
        insert ac;
		RecordType contactRecordTYpe = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
        Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = ac.Id, 
									  //EBH_Decision_Maker_Role__c = 'Deals', //MN:13/05/2021:US-0009542 - [NA] Deals: Remove unused value from 'Decision Maker Role' on Contact
									  Contact_Role__c='Deals', //MN:13/05/2021:US-0009542 - use Contact_Role__c instead
									  recordtypeId = contactRecordTYpe.Id);
        insert contact1;
        Date myDate = System.today();
        Time myTime = Time.newInstance(1, 1, 1, 1);
        Id dealNARecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByDeveloperName().get('Deal_V2').getRecordTypeId();
        EBH_Deal__c d4 = new EBH_Deal__c(EBH_eBayItemID__c = '000000000013',EBH_BusinessName__c = ac.Id,Seller_Approver_1__c = contact1.Id,EBH_Status__c='Running',RecordTypeId=dealNARecordTypeId,EBH_SellerPrice__c=10,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_DealStartDate__c=myDate+4,EBH_DealEndDate__c=myDate+5,EBH_DealStartTime__c=mytime,EBH_DealEndTime__c=mytime,EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c='product for ChangAllow 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_DealFormat__c='Primary');
        EBH_Deal__c d5 = new EBH_Deal__c(EBH_eBayItemID__c = '000000000014',EBH_BusinessName__c = ac.Id,Seller_Approver_1__c = contact1.Id,EBH_Status__c='Running',RecordTypeId=dealNARecordTypeId,EBH_SellerPrice__c=10,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_DealStartDate__c=myDate+4,EBH_DealEndDate__c=myDate+5,EBH_DealStartTime__c=mytime,EBH_DealEndTime__c=mytime,EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c='product for ChangAllow 2',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_DealFormat__c='Primary');
        EBH_Deal__c d6 = new EBH_Deal__c(EBH_eBayItemID__c = '000000000015',EBH_BusinessName__c = ac.Id,Seller_Approver_1__c = contact1.Id,EBH_Status__c='Running',RecordTypeId=dealNARecordTypeId,EBH_SellerPrice__c=10,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_DealStartDate__c=myDate+4,EBH_DealEndDate__c=myDate+5,EBH_DealStartTime__c=mytime,EBH_DealEndTime__c=mytime,EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c='product for ChangAllow 3',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_DealFormat__c='Primary');
        List<EBH_Deal__c> listUpdatestatus = new List<EBH_Deal__c>{d4,d5,d6};
        insert listUpdatestatus;
        
        for(EBH_Deal__c d:listUpdatestatus){
            d.ownerid = user.id; 
            if(d.EBH_eBayItemID__c == '000000000013'){
                d.EBH_Status__c = 'Sent to Seller';
            }else if(d.EBH_eBayItemID__c == '000000000014'){
                d.EBH_Status__c = 'Completed';
                d.Cancelled_Deal__c = true;
                d.EBH_DealStartDate__c = System.Today().addDays(-85);
                d.EBH_DealEndDate__c = System.Today().addDays(-55);
            }
        }
        update listUpdateStatus;
        
        System.Runas(user){
            EBH_Deal__c dealseller;
            EBH_Deal__c dealrunning;
            EBH_Deal__c dealcompleted;
            for(EBH_Deal__c d:listUpdatestatus){
                if(d.EBH_Status__c == 'Sent to Seller'){
                    d.EBH_ProductTitle__c = 'AMTProductTest2';
                    dealseller = d;
                }else if(d.EBH_Status__c == 'Completed'){
                    d.EBH_ProductTitle__c = 'AMTProductTest2';
                    dealcompleted = d;                  
                }else if(d.EBH_Status__c == 'Running'){
                    d.EBH_ProductTitle__c = 'AMTProductTest2';
                    dealrunning = d;                    
                }
            }
            try{
                update dealseller;
            }catch(exception e){
                System.Assert(e.getMessage().contains(Label.DD_Sent_to_Seller_Lock_Message));
            }
           
            try{
                update dealrunning;
             }catch(exception e){
                System.Assert(e.getMessage().contains(Label.DD_Cancelled_Lock_Message));
            }

            try{
                update dealcompleted;
            }catch(exception e){
                System.Assert(e.getMessage().contains(Label.DD_DealUpdate_Lock_Completed_Message));
            }
            
            //Test changeAllowed method
            try{
            	dealseller.EBH_eBayItemID__c = '000000000017';
            	update dealseller;
            }catch(exception e){
            	System.Assert(e.getMessage().contains(Label.DD_ApprovedChangeError_ItemId));
            }
            
            try{
            	dealrunning.EBH_DealPrice__c = 3;
            	update dealrunning;
            }catch(exception e){
            	System.Assert(e.getMessage().contains(Label.DD_ApprovedChangeError_Pricing));
            }
            
        }
        }
    }
    
    /*********************************************************************************************************************************
	@ Method:         testDisputeAmountRollup
	@ Version:        1.0
	@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
	@ Purpose:        Test method for EBH_DealTriggerHandler.rollUpDisputeAmountForDealStatement		
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:	none
	----------------------------------------------------------------------------------------------------------------------------------
	@ Change history:  28.12.2020 / sovantheany dim / Created the method.migrate from join instant
	*********************************************************************************************************************************/
    @isTest public static void testDisputeAmountRollup(){
        Id sellerRT_Id = ApexUtil.getRecordTypeByName('Account','EBH_Seller').Id;
    	Account acc = new Account(Name='Seller',EBH_VATNumber__c='1122334455',recordtypeId=sellerRT_Id);
        insert acc;
		RecordType contactRecordTYpe = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
        Contact con = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = acc.Id, 
									  //EBH_Decision_Maker_Role__c = 'Deals', //MN:13/05/2021:US-0009542 - [NA] Deals: Remove unused value from 'Decision Maker Role' on Contact
									  Contact_Role__c='Deals', //MN:13/05/2021:US-0009542 - use Contact_Role__c instead
									  recordtypeId = contactRecordTYpe.Id);
        insert con;
        Deal_Statement__c statement = new Deal_Statement__c (name=acc.name + 'Statement');
        insert statement;      
        Date myDate = System.today()+1;
        Time mytime = Time.newinstance(14,0,0,0);
        Id dealNARecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByDeveloperName().get('Deal_V2').getRecordTypeId();
        EBH_Deal__c deal = new EBH_Deal__c(EBH_eBayItemID__c = '000000000010',EBH_BusinessName__c = acc.Id,Seller_Approver_1__c = con.Id,EBH_Status__c='Completed',RecordTypeId=dealNARecordTypeId,EBH_SellerPrice__c=10,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_DealStartDate__c=myDate,EBH_DealEndDate__c=myDate,EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c='product for update 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_DealFormat__c='Primary',deal_statement__c = statement.id);
        insert deal;
        
        deal.Subsidy_Due_Disputes__c = 50;
        deal.Subsidy_Due_Further_Dispute__c = 25;
        update deal;
        
        Deal_Statement__c dealstatement = [Select id, Disputes_Payout__c, Further_Dispute_Payout__c From Deal_Statement__c Where id = :statement.id];
        System.AssertEquals(dealstatement.Further_Dispute_Payout__c, 25.00);
        System.AssertEquals(dealstatement.Disputes_Payout__c, 50.00);
        
        EBH_Deal__c deal2 = new EBH_Deal__c(EBH_eBayItemID__c = '000000000011',EBH_BusinessName__c = acc.Id,Seller_Approver_1__c = con.Id,EBH_Status__c='Completed',RecordTypeId=dealNARecordTypeId,EBH_SellerPrice__c=10,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_DealStartDate__c=myDate,EBH_DealEndDate__c=myDate,EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c='product for update 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_DealFormat__c='Primary',deal_statement__c = statement.id);
        insert deal2;
        
        deal2.Subsidy_Due_Disputes__c = 50;
        deal2.Subsidy_Due_Further_Dispute__c = 25;
        update deal2;
        
        dealstatement = [Select id, Disputes_Payout__c, Further_Dispute_Payout__c From Deal_Statement__c Where id = :statement.id];
        System.AssertEquals(dealstatement.Further_Dispute_Payout__c, 50.00);
        System.AssertEquals(dealstatement.Disputes_Payout__c, 100.00);
        
        deal2.Subsidy_Due_Disputes__c = 25;
        deal2.Subsidy_Due_Further_Dispute__c = 5;
        update deal2;
        
        dealstatement = [Select id, Disputes_Payout__c, Further_Dispute_Payout__c From Deal_Statement__c Where id = :statement.id];
        System.AssertEquals(dealstatement.Further_Dispute_Payout__c, 30.00);
        System.AssertEquals(dealstatement.Disputes_Payout__c, 75.00);
    }
		// US-0009179, Acmatac SEING
		@isTest
		static void testNADealStatusUpdate(){
			Account ac = new Account(Name='Seller',EBH_VATNumber__c='VAT1111',RecordTypeID = sellerRecordType.Id,NA_Deal_Program_Vetted__c=true);
			insert ac;
	
			Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
									FirstName='firstname',Salutation='Mr.',LastName='test1',
									email='test1@test.com' , AccountId = ac.Id, 
									//EBH_Decision_Maker_Role__c = 'Deals', //MN:13/05/2021:US-0009542 - [NA] Deals: Remove unused value from 'Decision Maker Role' on Contact
									Contact_Role__c='Deals', //MN:13/05/2021:US-0009542 - use Contact_Role__c instead
									recordtypeId = contactRecordTYpe.Id);
			insert contact1;
	
			EBH_Deal__c d1a = new EBH_Deal__c( 
				EBH_SellerPrice__c=1000
				, EBH_SoldItems__c=2
				, EBH_Vertical__c='Soft Home'
				, EBH_DealSiteId__c='77'
				, EBH_Status__c='New'
				, EBH_Category__c='Gold'
				, EBH_ProductTitle__c='product 1'
				, EBH_Quantity__c=1
				, EBH_DealPrice__c = 200
				, EBH_DealFormat__c = 'iji'
				, EBH_DealStartDate__c = Date.today()+1
				, EBH_DealEndDate__c = Date.today()+30
				, EBH_SellerEmail__c ='dd@d.com'
				, EBH_MaximumPurchases__c =1
				, EBH_BusinessName__c = ac.Id
				, Subsidy_Running__c = 10
				, EBH_Payout_SI__c = 10
				, recordtypeId = dealNARecordTypeId
				, EBH_eBayItemID__c='123456789000'
				, Seller_Approver_1__c=contact1.Id
			);
			insert d1a;

			User existAdminUser = [Select Id from User Where isActive = true and Profile.Name = 'System Administrator' Limit 1];
			User userAdmin = new User();
			System.runAs(existAdminUser){  // 24.06.2022 / Sophal Noch / US-0011987 : fix mix dml error
				userAdmin = EBH_TestDataFactory.createUser('System Administrator');
				insert userAdmin;
			}
	
			Test.startTest(); 
				System.runAs(userAdmin){
					EBH_Deal__c oD = [SELECT Id FROM EBH_Deal__c WHERE EBH_eBayItemID__c='123456789000'];
					oD.EBH_DealStartDate__c = System.today().addDays(-2);
					oD.EBH_Status__c = 'Seller Approved';
					update oD;
	
	
					oD = [SELECT EBH_Status__c FROM EBH_Deal__c WHERE Id=:oD.Id];
					// System.debug('Debug>>>1 '+oD.EBH_Status__c);
	
	
					oD = [SELECT EBH_Status__c FROM EBH_Deal__c WHERE Id=:oD.Id];
					// System.debug('Debug>>>2 '+oD.EBH_Status__c);
				}
			Test.stopTest();
		}

	// static testMethod void testPrePopuldateDealStartTime()
	// {
	// 	// 28.05.2021 / Sophal Noch / US-0009533
    //     Profile adminProfile = [select Id,Name from Profile where Name = 'System Administrator'];

    //     User user = new User();
    //     user.Alias='testUser';
    //     user.Email='test@ebay.com';
    //     user.EmailEncodingKey='UTF-8';
    //     user.LastName='testUser';
    //     user.LanguageLocaleKey='en_US'; 
    //     user.LocaleSidKey='en_US';
    //     user.ProfileId = adminProfile.Id;
    //     user.TimeZoneSidKey='America/Los_Angeles';
    //     user.UserName='testuser@ebay.com';
    //     insert user;
        
    //     Deal_Timezone__c dealTimezone = new Deal_Timezone__c();
    //     dealTimezone.TimeZone__c='America/Los_Angeles';     
    //     insert dealTimezone;

    //     Account acc = new Account();
    //     acc.Name = 'account1';
    //     acc.BillingCountry = 'US';
    //     insert acc;

    //     Account eBSeller = new Account();
    //     eBSeller.Name = 'seller';
    //     eBSeller.EBH_MainVertical__c = 'Electronics';
    //     eBSeller.EBH_OracleID__c = 'AXTP-930494';
    //     insert eBSeller;

    //     Contact cont = new Contact(RecordtypeId=ApexUtil.getRecordTypeByName('Contact', 'EBH_MANUAL').Id);
    //     cont.LastName = 'AMT_Cont';
    //     cont.AccountId = eBSeller.Id;
    //     cont.Contact_Role__c='Deals;NA Deals Statement Recipient'; 
    //     cont.Email ='test@ebay.dailydeal.com';
    //     insert cont;

    //     EBH_SpotlightCategory__c spCat = new EBH_SpotlightCategory__c();
    //     spCat.Name = 'AMT_Spotligth NA';
    //     spCat.EBH_Country__c = 'NA';
    //     spCat.EBH_SpotlightCategoryID__c = 'SCiD-934035';
    //     insert spCat;



    //     Date myEndDate = System.Today().addMonths(10);
    //     Time myEndTime = Time.newInstance(1, 1, 1, 1);

    //     Id naRecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('NA Deal').getRecordTypeId();
        

    //     EBH_Deal__c deal1 = new EBH_Deal__c();
    //     deal1.RecordTypeId = naRecordTypeId;
    //     deal1.Merchant_Approver__c = user.Id;
    //     deal1.EBH_BusinessName__c = eBSeller.Id;
    //     deal1.EBH_ProductTitle__c = 'deal1';
    //     deal1.EBH_DealSiteId__c = '0';
    //     deal1.EBH_Vertical__c = 'Home & Garden';
    //     deal1.EBH_Category__c='Home & Garden';
    //     deal1.Sub_Category__c = 'Bedding';
    //     deal1.EBH_DealFormat__c = 'Primary';
    //     deal1.EBH_DealEndDate__c = myEndDate;
    //     deal1.EBH_DealEndTime__c = myEndTime;
    //     deal1.EBH_Status__c = 'New';
    //     deal1.EBH_Quantity__c = 1;
    //     deal1.Quantity_Limitation_per_Purchaser__c = 1;
    //     deal1.EBH_DealPrice__c = 1;
    //     deal1.EBH_SellerPrice__c = 1;
    //     deal1.EBH_SoldItemsForecast__c = 123456;
    //     deal1.Seller_Approver_1__c = cont.Id;
    //     deal1.Sold_Items_30_Days__c = 1;
    //     deal1.Sold_Items_60_Days__c = 2;
    //     deal1.Final_Sold_Items__c = 1; 

     
    //     EBH_Deal__c deal2 = deal1.clone(false,false,false,false);
    //     deal2.EBH_ProductTitle__c = 'deal2';
    //     deal2.EBH_Status__c = 'Internally Approved';

    //     EBH_Deal__c deal3 = deal1.clone(false,false,false,false);
    //     deal3.EBH_ProductTitle__c = 'deal3';
    //     deal3.EBH_Status__c = 'Sent to Seller';

    //     EBH_Deal__c  deal4 = deal1.clone(false,false,false,false);
    //     deal4.EBH_ProductTitle__c = 'deal4';
    //     deal4.EBH_Status__c = 'Negotiating';

	// 	Date myStartDate = System.Today();
    //     Time myStartTime = Time.newInstance(23, 59, 59, 999);

    //     deal1.EBH_DealStartDate__c = myStartDate;
    //     deal1.EBH_DealStartTime__c = myStartTime;

    //     deal2.EBH_DealStartDate__c = myStartDate;
    //     deal2.EBH_DealStartTime__c = myStartTime;

    //     deal3.EBH_DealStartDate__c = myStartDate;
    //     deal3.EBH_DealStartTime__c = myStartTime;

    //     deal4.EBH_DealStartDate__c = myStartDate;
    //     deal4.EBH_DealStartTime__c = myStartTime;


    //     List<EBH_Deal__c> insertedDeals = new List<EBH_Deal__c>{deal1, deal2, deal3, deal4};
    //     insert insertedDeals;

	// 	List<EBH_Deal__c> queriedDeals = [Select Id,Deal_Start_Date_Time2__c From EBH_Deal__c Where Id in: insertedDeals order by id asc];
    //     System.assertNotEquals(null, queriedDeals[0].Deal_Start_Date_Time2__c);
    //     System.assertNotEquals(null, queriedDeals[1].Deal_Start_Date_Time2__c);
    //     System.assertNotEquals(null, queriedDeals[2].Deal_Start_Date_Time2__c);
    //     System.assertNotEquals(null, queriedDeals[3].Deal_Start_Date_Time2__c);
	// }
	static testMethod void testDealStatusUpdateToInternallyApproved()
	{
		// 01.09.2021 / Sophal Noch / US-0010285
        Profile adminProfile = [select Id,Name from Profile where Name = 'System Administrator'];
		User existAdminUser = [Select Id from User Where isActive = true and ProfileId =: adminProfile.Id Limit 1];

        User user = new User();
		System.runAs(existAdminUser){  // 24.06.2022 / Sophal Noch / US-0011987 : fix mix dml error
			user.Alias='testUs8';
			user.Email='test@ebay.com';
			user.EmailEncodingKey='UTF-8';
			user.LastName='jamy22';
			user.LanguageLocaleKey='en_US'; 
			user.LocaleSidKey='en_US';
			user.ProfileId = adminProfile.Id;
			user.TimeZoneSidKey='America/Los_Angeles';
			user.UserName='jamy22@ebay.com';
			insert user;
		}

        // Deal_Timezone__c dealTimezone = new Deal_Timezone__c();
        // dealTimezone.TimeZone__c='America/Los_Angeles';     
        // insert dealTimezone;

        Account acc = new Account();
        acc.Name = 'account1';
        acc.BillingCountry = 'US';
        insert acc;

        Account eBSeller = new Account();
        eBSeller.Name = 'seller';
        eBSeller.EBH_MainVertical__c = 'Electronics';
        eBSeller.EBH_OracleID__c = 'AXTP-930494';
        insert eBSeller;

        Contact cont = new Contact(RecordtypeId=ApexUtil.getRecordTypeByName('Contact', 'EBH_MANUAL').Id);
        cont.LastName = 'AMT_Cont';
        cont.AccountId = eBSeller.Id;
        cont.Contact_Role__c='Deals;NA Deals Statement Recipient'; 
        cont.Email ='test@ebay.dailydeal.com';
        insert cont;

        EBH_SpotlightCategory__c spCat = new EBH_SpotlightCategory__c();
        spCat.Name = 'AMT_Spotligth NA';
        spCat.EBH_Country__c = 'NA';
        spCat.EBH_SpotlightCategoryID__c = 'SCiD-934035';
        insert spCat;



        Date myEndDate = System.Today().addMonths(10);
        Time myEndTime = Time.newInstance(1, 1, 1, 1);
		
		//MN-17082022-US-0011119-Remove reference with old record type name
        // Id naRecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('NA Deal').getRecordTypeId();
        RecordType subDealRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2');
		Id naRecordTypeId = subDealRecordType.Id;

        EBH_Deal__c deal1 = new EBH_Deal__c();
        deal1.RecordTypeId = naRecordTypeId;
        deal1.Merchant_Approver__c = user.Id;
        deal1.EBH_BusinessName__c = eBSeller.Id;
        deal1.EBH_ProductTitle__c = 'deal1';
        deal1.EBH_DealSiteId__c = '0';
        deal1.EBH_Vertical__c = 'Home & Garden';
        deal1.EBH_Category__c='Home & Garden';
        deal1.Sub_Category__c = 'Bedding';
        deal1.EBH_DealFormat__c = 'Primary';
        deal1.EBH_DealEndDate__c = myEndDate;
        deal1.EBH_DealEndTime__c = myEndTime;
        deal1.EBH_Status__c = 'New';
        deal1.EBH_Quantity__c = 1;
        deal1.Quantity_Limitation_per_Purchaser__c = 1;
        deal1.EBH_DealPrice__c = 1;
        deal1.EBH_SellerPrice__c = 1;
        deal1.EBH_SoldItemsForecast__c = 123456;
        deal1.Seller_Approver_1__c = cont.Id;
        deal1.Sold_Items_30_Days__c = 1;
        deal1.Sold_Items_60_Days__c = 2;
        deal1.Final_Sold_Items__c = 1; 

     
        EBH_Deal__c deal2 = deal1.clone(false,false,false,false);
        deal2.EBH_ProductTitle__c = 'deal2';
        deal2.EBH_Status__c = 'New';

        EBH_Deal__c deal3 = deal1.clone(false,false,false,false);
        deal3.EBH_ProductTitle__c = 'deal3';
        deal3.EBH_Status__c = 'New';

        EBH_Deal__c  deal4 = deal1.clone(false,false,false,false);
        deal4.EBH_ProductTitle__c = 'deal4';
        deal4.EBH_Status__c = 'New';


        List<EBH_Deal__c> insertedDeals = new List<EBH_Deal__c>{deal1, deal2, deal3, deal4};
        insert insertedDeals;

		insertedDeals[0].EBH_Status__c = 'Internally Approved';
		insertedDeals[1].EBH_Status__c = 'Internally Rejected';
		insertedDeals[2].EBH_Status__c = 'Internally Approved';
		insertedDeals[3].EBH_Status__c = 'Internally Rejected';
		Test.startTest();
			update insertedDeals;
		Test.stopTest();


		List<EBH_Deal__c> queriedDeals = [Select Id,Internally_Approved_Rejected_Timestamp__c From EBH_Deal__c Where Id in: insertedDeals order by id asc];
        System.assertNotEquals(null, queriedDeals[0].Internally_Approved_Rejected_Timestamp__c);
        System.assertNotEquals(null, queriedDeals[1].Internally_Approved_Rejected_Timestamp__c);
        System.assertNotEquals(null, queriedDeals[2].Internally_Approved_Rejected_Timestamp__c);
        System.assertNotEquals(null, queriedDeals[3].Internally_Approved_Rejected_Timestamp__c);
	}
/*
    @isTest 
	public static void dealStatusMappingWithSEPTest(){
		Account acc = new Account (
			Name = 'newAcc1',
			EBH_VATNumber__c='1234567890'
		);  
		insert acc;
		Contact con = new Contact (
			AccountId = acc.id,
			LastName = 'portalTestUser'
		);
		insert con;
		Profile p = [select Id,name from Profile where UserType =: Label.USER_TYPE_POWER_CUSTOMER_SUCCESS limit 1];
		User newUser;
		System.runAs(EBH_TestDataFactory.createUser('System Administrator')){
			newUser = new User(
				profileId = p.id,
				username = 'newUser@test.test',
				email = 'pb@ff.com',
				emailencodingkey = 'UTF-8',
				localesidkey = 'en_US',
				languagelocalekey = 'en_US',
				timezonesidkey = 'America/Los_Angeles',
				alias='nuser',
				lastname='lastname',
				contactId = con.id
				);
			insert newUser;
		}
		List<EBH_Deal__c> lstDeal;
		Test.startTest();

			System.runAs(newUser){
				EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c();
				insert sc;
				Integer iCount = 1;
				lstDeal = new List<EBH_Deal__c>();
				for(String ddStatus: EBH_DealTriggerHandler.DEAL_STATUS_SEP_MAPPING.keySet()){
					if(ddStatus == 'Negotiating') continue;
					lstDeal.add(new EBH_Deal__c(
						EBH_DealStartTime__c= System.now().time(), 
						EBH_DealStartDate__c=System.toDay(),
						EBH_eBayItemID__c='00000009993'+String.valueOf(iCount),
						EBH_BusinessName__c=acc.Id,
						EBH_SpotlightCategory__c=sc.Id,
						EBH_SellerPrice__c=200,
						EBH_Vertical__c='Business & Industrial',
						EBH_Category__c = 'Business',
						EBH_DealPrice__c = 200,
                        EBH_DealEndTime__c = System.now().time(),
						EBH_DealEndDate__c = System.toDay().addMonths(5),
						EBH_Status__c= ddStatus,
						EBH_ProductTitle__c='product 2',
						EBH_Quantity__c=1,
						RecordTypeId = dealStandardRecordTypeId,
						Merchant_Approver__c = UserInfo.getUserId() ,
						Seller_Approver_1__c=con.Id
					));
					iCount++;
				}
				EBH_DealTriggerHandler.UPDATE_STATUS_SYS = true;
				//
				insert lstDeal;
			}
	
		Test.stopTest();
		for(EBH_Deal__c oDl : [SELECT CreatedBy.UserType, EBH_Status__c, EBH_DealPrice__c, EBH_SellerPrice__c, Seller_Portal_Status__c FROM EBH_Deal__c WHERE Id IN: lstDeal]){
			System.assertEquals(oDl.EBH_DealPrice__c, oDl.EBH_SellerPrice__c);
			System.assertEquals(oDl.Seller_Portal_Status__c, EBH_DealTriggerHandler.DEAL_STATUS_SEP_MAPPING.get(oDl.EBH_Status__c));
		}
	} 
*/	
	// SB 12.01.2024 US-0013136
	/*@isTest
	static void testNAUnsubDealStatusMappingWithSEP(){
		Account ac = new Account(Name='Seller',EBH_VATNumber__c='VAT1111',RecordTypeID = sellerRecordType.Id,NA_Deal_Program_Vetted__c=true);
		insert ac;

		Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
								FirstName='firstname',Salutation='Mr.',LastName='test1',
								email='test1@test.com' , AccountId = ac.Id,
								Contact_Role__c='Deals',
								recordtypeId = contactRecordTYpe.Id);
		insert contact1;

		EBH_Deal__c d1a = new EBH_Deal__c( 
			EBH_SellerPrice__c=1000
			, EBH_SoldItems__c=2
			, EBH_Vertical__c='Soft Home'
			, EBH_DealSiteId__c='0'
			, EBH_Status__c='New'
			, EBH_Category__c='Gold'
			, EBH_ProductTitle__c='product 1'
			, EBH_Quantity__c=1
			, EBH_DealPrice__c = 200
			, EBH_DealFormat__c = 'iji'
			, EBH_DealStartDate__c = Date.today()+1
			, EBH_DealEndDate__c = Date.today()+30
			, EBH_SellerEmail__c ='dd@d.com'
			, EBH_MaximumPurchases__c =1
			, EBH_BusinessName__c = ac.Id
			, Subsidy_Running__c = 10
			, EBH_Payout_SI__c = 10
			, recordtypeId = dealNAUnsubRecordTypeId
			, EBH_eBayItemID__c='123456789000'
			, Seller_Approver_1__c=contact1.Id
		);
		insert d1a;

		User existAdminUser = [Select Id from User Where isActive = true and Profile.Name = 'System Administrator' Limit 1];
		User userAdmin = new User();
		System.runAs(existAdminUser){ // 24.06.2022 / Sophal Noch / US-0011987 : fix mix dml error
			userAdmin = EBH_TestDataFactory.createUser('System Administrator');
			insert userAdmin;
		}

		Test.startTest(); 
			System.runAs(userAdmin){
				d1a.EBH_Status__c = 'Processing';
				update d1a;
			}
			
		Test.stopTest();
		
		EBH_Deal__c d1 = [SELECT Id,Seller_Portal_Status__c,EBH_Status__c FROM EBH_Deal__c WHERE Id=: d1a.Id];
		System.AssertEquals(d1.Seller_Portal_Status__c,'Editable');
	}*/


	@isTest
	static void testPrePopulateDeal() {

   		Account ac = new Account(Name='Seller',EBH_VATNumber__c='1122334455');
         ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
         insert ac;
		 
   		Date myDate = Date.today().addDays(2);
         
   		EBH_DealRetailCampaign__c dsa1 = new EBH_DealRetailCampaign__c(
			EBH_Slots__c =2,
			EBH_Date__c = Date.today(),
			EPH_EndDate__c = Date.today().addDays(7),
			Start_Time__c = Time.newInstance(8, 0, 0, 0),
			End_Time__c = Time.newInstance(8, 0, 0, 0)
		);
        insert dsa1;
        
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c();
        insert sc; 
        
        EBH_Deal__c d1 = new EBH_Deal__c(
			RecordTypeId = v1_recordTypeId, 
			EBH_eBayItemID__c='12345678901',EBH_DEALSITEID__c='77',
        	EBH_BusinessName__c=ac.Id,
			EBH_SpotlightCategory__c=sc.Id,
			EBH_MaximumPurchases__c =324,
			EBH_DealRetailCampaign__c=dsa1.Id,
			EBH_SellerPrice__c=40,
			EBH_DealPrice__c=20,
			EBH_SoldItems__c=2,
			EBH_Vertical__c='CSA',
			EBH_Status__c='New' ,
			EBH_DealFormat__c='Primary',
			EBH_Category__c='Gold', 
			EBH_ProductTitle__c='product 1',
			EBH_SellerEmail__c='sales@test.com',
			EBH_Quantity__c=1);
         
			EBH_Deal__c d2 = new EBH_Deal__c(
				RecordTypeId = v1_recordTypeId, 
				EBH_eBayItemID__c='12345678902',
				EBH_DEALSITEID__c='77',
        	 	EBH_BusinessName__c=ac.Id,
				EBH_SpotlightCategory__c=sc.Id,
				EBH_MaximumPurchases__c =324,
				EBH_DealRetailCampaign__c=dsa1.Id,
				EBH_SellerPrice__c=40,
				EBH_DealPrice__c=0,
				EBH_SoldItems__c=2,
				EBH_Vertical__c='CSA',
				EBH_Status__c='New' ,
				EBH_DealFormat__c='Primary',
				EBH_Category__c='Gold', 
				EBH_ProductTitle__c='product 1',
				EBH_SellerEmail__c='sales@test.com',
				EBH_Quantity__c=1);

		Test.startTest();

        	EBH_DealTriggerHandler.isFromBulkUpload_DE = true;
			insert new List<EBH_Deal__c>{d1,d2};
        
			for (EBH_Deal__c d : [SELECT Id,EBH_DealStartDate__c, EBH_DealStartTime__c,EBH_DealEndDate__c,EBH_DealEndTime__c FROM EBH_Deal__c WHERE Id =:d1.Id or ID=:d2.Id]) {
				System.debug('**** d :: ' + d);
				System.debug('**** dsa1 :: ' + dsa1);
				System.assert( d.EBH_DealStartDate__c == dsa1.EBH_Date__c, 'Deal\'s StartDate should be the same as Deal Retail Campaign\'');
				System.assert( d.EBH_DealEndDate__c == dsa1.EPH_EndDate__c, 'Deal\'s EndDate should be the same as Deal Retail Campaign\'');
				System.assert( d.EBH_DealStartTime__c == dsa1.Start_Time__c, 'Deal\'s StartTime should be the same as Deal Retail Campaign\'');
				System.assert( d.EBH_DealEndTime__c == dsa1.End_Time__c, 'Deal\'s EndTime should be the same as Deal Retail Campaign\'');
			}
        
		Test.stopTest();
   		
   		
   }


   @IsTest
    static void testCalc(){
        
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='se1',RecordTypeID = sellerRecordType.Id);
        insert acc;

        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c(Name='Test', EBH_Country__c='UK');
        insert sc;
        RecordType dealV1Rec = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V1')        ;

        EBH_Deal__c d1 = new EBH_Deal__c(RecordTypeId=dealV1Rec.Id,EBH_BusinessName__c=acc.Id, EBH_SellerPrice__c=10, EBH_eBayItemID__c='123456789', EBH_DealPrice__c=2, EBH_RRPWASPrice__c=2, 
                                EBH_RecommendedRetailPriceWAS__c='RRP', EBH_MarketingTitle__c='test', EBH_SpotlightCategory__c=sc.Id,
                                EBH_DealFormat__c='Primary', EBH_DealStartDate__c=Date.today(), EBH_DealEndDate__c=Date.today().addDays(1),
                                EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,EBH_Vertical__c='Fashion',EBH_DealSiteId__c='77');
        insert d1;

        EBH_DealsBudget__c db = new EBH_DealsBudget__c(Deal_Site__c='77',EBH_Budget__c=1000,Subsidy_Final__c=2000,EBH_Vertical__c='Fashion',Year__c=Date.today().year()+'',EBH_Quarter__c='Q1');
        insert db;
        
        String thisMonth = Datetime.now().format('MMMM');

        EBH_DealsBudgetMonth__c dbm1 = new EBH_DealsBudgetMonth__c(EBH_Month__c=thisMonth,EBH_DealsBudget__c=db.Id);
        insert dbm1;

        EBH_Deal__c[]  ddd = [Select Id From EBH_Deal__c WHERE SystemModStamp =TODAY AND EBH_Vertical__c<> null AND EBH_DealStartDate__c<>null];
         
        Test.startTest();     
            
		Set<String> setMonthYear = new Set<String>();
    	Set<String> setVertical = new Set<String>();
		List<EBH_Deal__c> scope = new List<EBH_Deal__c>();
    
       	for(EBH_Deal__c deal : [Select Id,RecordTypeId, EBH_UID__c,EBH_Status__c,EBH_DealStartDate__c,EBH_DealPrice__c,EBH_Quantity__c,EBH_Vertical__c,EBH_SubsidyFinal__c,EBH_SubsidyForecast__c,EBH_SubsidyMax__c, EBH_StartDateMonthYear__c  
									From EBH_Deal__c WHERE SystemModStamp = TODAY AND EBH_Vertical__c<>null AND EBH_DealStartDate__c<>null])
       	{
      		setMonthYear.add(deal.EBH_DealStartDate__c.month()+''+deal.EBH_DealStartDate__c.year());
      		setVertical.add(deal.EBH_Vertical__c);
			  scope.add(deal);
       	}
    	//query the relavant DBM  
       Map<String,EBH_DealsBudgetMonth__c> mapDBM = new Map<String,EBH_DealsBudgetMonth__c>();
		for(EBH_DealsBudgetMonth__c dbm:[Select Id,EBH_MonthYear__c,EBH_DealsBudget__r.EBH_Vertical__c From EBH_DealsBudgetMonth__c WHERE EBH_MonthYear__c IN:setMonthYear AND EBH_DealsBudget__r.EBH_Vertical__c IN:setVertical])
		{
			mapDBM.put(dbm.EBH_MonthYear__c+''+dbm.EBH_DealsBudget__r.EBH_Vertical__c,dbm);
		}
    
    	//calculate deals here:  
       	EBH_DealTriggerHandler.doCalculateDeals(mapDBM,scope,false);  

        Test.stopTest();
        
    }
}