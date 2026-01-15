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
/***************************************************************************************************************************************
@ Change history:  13.12.2023 / Vimean Heng / Fix Attempt to de-reference a null.
***************************************************************************************************************************************/
@isTest
private class Deal_DailyViewControllerTest {
    private static Id dealRT_V1 = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V1').Id;

    //@ Change history:  13.12.2023 / Vimean Heng / US-0014430 / Fix Attempt to de-reference a null by EBH_TestDataFactory.setUpCustomSettings();
    static testMethod void testDealSlotTable() {
         EBH_TestDataFactory.setUpCustomSettings();
         Account ac = new Account(Name='Seller',EBH_VATNumber__c='1122334455');
         ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
         ac.EBH_VATNumber__c = 'VAT1111';
         ac.EBH_RegistrationCountry__c = 'United Kingdom';
         insert ac;
		 Contact cont = new Contact(
						LastName = 'SellerContactTest',
						Email='test@test.com.invalid', 
						AccountId=ac.Id
                );
        insert cont;
   		Date myDate = Date.today();
         
   		EBH_DealRetailCampaign__c dsa1 = new EBH_DealRetailCampaign__c(EBH_Slots__c =2);
        insert dsa1;
        
         EBH_SpotlightCategory__c spc1 = new EBH_SpotlightCategory__c(Name='Test1', EBH_Country__c='DE',Spotlight_Start_Date__c=myDate);
   		 EBH_SpotlightCategory__c spc2 = new EBH_SpotlightCategory__c(Name='Test2', EBH_Country__c='DE',Spotlight_Start_Date__c=myDate);
         insert new EBH_SpotlightCategory__c[]{spc1,spc2};
        
        
        EBH_DealSlotAllocation__c dsa = new EBH_DealSlotAllocation__c(EBH_DealFormat__c='Primary',EBH_Vertical__c='Soft Home',EBH_Date__c=myDate.addDays(2),EBH_Country__c='77',EBH_Slots__c=1);
        EBH_DealSlotAllocation__c dsa2 = new EBH_DealSlotAllocation__c(EBH_DealFormat__c='Primary',EBH_Vertical__c='Hard Home',EBH_Date__c=myDate,EBH_Country__c='77',EBH_Slots__c=10);
        EBH_DealSlotAllocation__c dsa3 = new EBH_DealSlotAllocation__c(EBH_DealFormat__c='Primary',EBH_Vertical__c='Fashion',EBH_Date__c=myDate.addDays(-1),EBH_Country__c='77',EBH_Slots__c=10);
        insert new List<EBH_DealSlotAllocation__c>{dsa,dsa2,dsa3};

        EBH_Deal__c d1 = new EBH_Deal__c(Seller_Contact__c=cont.Id, RecordTypeId = dealRT_V1,EBH_DealEndTime__c=System.now().time(),EBH_DealStartTime__c= System.now().time(), EBH_DealStartDate__c=myDate.addDays(2),EBH_eBayItemID__c='12345678901',EBH_DEALSITEID__c='77',
        	 EBH_BusinessName__c=ac.Id,EBH_SpotlightCategory__c=spc1.Id,EBH_MaximumPurchases__c =324,EBH_DealRetailCampaign__c=dsa1.Id,EBH_SellerPrice__c=1000,EBH_DealPrice__c=200,EBH_SoldItems__c=2,EBH_Vertical__c='Soft Home',EBH_DealEndDate__c = myDate.addDays(20),EBH_Status__c=EBH_ConstantsUtility.DEAL_STATUS_PLANNED ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
         EBH_Deal__c d2 = new EBH_Deal__c(Seller_Contact__c=cont.Id, RecordTypeId = dealRT_V1,EBH_DealEndTime__c=System.now().time(),EBH_DealStartTime__c= System.now().time(), EBH_DealStartDate__c=myDate,EBH_eBayItemID__c='12345678902',EBH_DEALSITEID__c='77',
        	 EBH_BusinessName__c=ac.Id,EBH_SpotlightCategory__c=spc2.Id,EBH_MaximumPurchases__c =324,EBH_DealRetailCampaign__c=dsa1.Id,EBH_SellerPrice__c=1000,EBH_DealPrice__c=200,EBH_SoldItems__c=2,EBH_Vertical__c='Soft Home',EBH_DealEndDate__c = myDate.addDays(20),EBH_Status__c=EBH_ConstantsUtility.DEAL_STATUS_PLANNED ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1);
        	 
        insert new List<EBH_Deal__c>{d1,d2};
        
        
   		Test.startTest();
   		
   		 Deal_DailyViewController.apexInitDailyView(); 
   		 
   		 String dateYYYMMDD = myDate.year()+'-'+myDate.month()+'-'+myDate.day();
   		 String dateYYYMMDD2 = myDate.addDays(2).year()+'-'+myDate.addDays(2).month()+'-'+myDate.addDays(2).day();
   		 Map<String,Object> result = Deal_DailyViewController.apexQueryDailyView('77','Primary',new List<String>(),dateYYYMMDD2,false);
   		  
   		 Map<String,Object>  result2 = Deal_DailyViewController.apexQueryDailyView('77','Primary',new List<String>(),dateYYYMMDD,true);
   		 
   		 
   		 //test weekly
   		
   		 Map<String,Object>  result3 = Deal_DailyViewController.apexQueryWeeklyDeals(dateYYYMMDD,'77',new List<String>());
   		
   		Test.stopTest(); 
    }
}