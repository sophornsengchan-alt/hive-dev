/*********************************************************************************************************************************
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 04.10.2022 / Sarom Chetra / US-0012485 - Fix failing test class Subsidize_DealControllerTest
@               : 17.01.2024 / Venkata Sharath Simhadri / US-0014529
*********************************************************************************************************************************/
@isTest
private  class Subsidize_DealControllerTest {
    
    public static final String NA_UNSUB_DEAL = 'Deal_V3';
    public static final String DRC_DEAL_WINDOW = 'Deal_Campaign_V2';    

    // @ Change history: 04.10.2022 / Sarom Chetra / US-0012485 - Fix failing test class Subsidize_DealControllerTest
    @testSetup 
    static void setup(){
        //DealRetailCampaignTriggerHandler.updateDealStatusByTimeBaseChange();
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Id dealRecordTypeId =  ApexUtil.getRecordTypeByName('EBH_Deal__c', NA_UNSUB_DEAL).Id;
        Id drcRecordTypeId = ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', DRC_DEAL_WINDOW).Id;
        Account acc = new Account(Name='Test se2',RecordTypeID = sellerRecordType.Id,NA_Deals_Subsidy_PayPal_Email__c='test@test.com',NA_Deal_Program_Vetted__c = true);
        insert acc;

        RecordType contactRecordTYpe = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
        Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                        FirstName='firstname',Salutation='Mr.',LastName='test1', Contact_Role__c = 'Deals',
                                        email='test1@test.com' , AccountId = acc.Id, recordtypeId = contactRecordTYpe.Id);
        insert contact1;         
         
        EBH_DealRetailCampaign__c drc = new EBH_DealRetailCampaign__c(
            EBH_Country__c = '0',
            RecordTypeId = drcRecordTypeId,
            Status__c = 'Draft',
            EBH_DealTitle__c = 'SRO Test 001',
            Start_Retail_Week__c='2',
            EBH_Date__c = Date.today(),
            EPH_EndDate__c=Date.today().addDays(5),
            End_Retail_Week__c = '5',
            EBH_Slots__c=3);

        insert drc;
        
        DateTime dt = System.today();
        Time myTime = Time.newInstance(dt.hour(), dt.minute(), dt.second(), dt.millisecond());
        // create defualt spotlight category
        EBH_Deal__c d1 = new EBH_Deal__c(
                                            EBH_MaximumPurchases__c = 1,  // 04.10.2022 / Sarom Chetra / US-0012485
                                            RecordTypeId = dealRecordTypeId, 
                                            EBH_SellerPrice__c = 1000,
                                            EBH_DealPrice__c = 11,
                                            EBH_BusinessName__c = acc.Id,
                                            EBH_SoldItems__c = 2,
                                            EBH_Vertical__c = 'CSA',
                                            EBH_DealStartDate__c = System.today(),
                                            EBH_DealEndDate__c = System.today().addDays(1),
                                            EBH_Status__c = 'New',
                                            EBH_Category__c = 'Gold',
                                            EBH_ProductTitle__c = 'product-1',                                            
                                            EBH_Quantity__c = 1,
                                            EBH_DealStartTime__c = myTime,
                                            EBH_DealEndTime__c = myTime,
                                            EBH_DealFormat__c = 'Deal',
                                            EBH_eBayItemID__c = '123456789110',
                                            EBH_DealSiteId__c='77',
                                            EBH_DealRetailCampaign__c = drc.Id,                                            
                                            Seller_Approver_1__c = contact1.Id);
                                             
      

        insert d1;
        
    }   

    @IsTest
    static void testSubsidize(){
        EBH_DealRetailCampaign__c window = [Select Id from EBH_DealRetailCampaign__c Limit 1];
        EBH_Deal__c d1 = [Select Id from EBH_Deal__c Limit 1];
        Test.startTest();
            Map<String,Object> result = Subsidize_DealController.apexInit(window.Id,d1.Id);
            System.assertEquals('ko', result.get('status')+'','convert success error incorrect status '+result);

            d1.EBH_Status__c = 'Ops Review';
            update d1;
            result = Subsidize_DealController.apexInit(window.Id,d1.Id);

            System.assertEquals('ok', result.get('status')+'','convert success: '+result);
            d1 = [Select Id,EBH_Status__c from EBH_Deal__c Limit 1];
            System.assertEquals('New', d1.EBH_Status__c,'convert success to New NA Deal');

        Test.stopTest();
        
    }

    @IsTest
    static void testSubsidizePaypalEmailBlank(){
        EBH_DealRetailCampaign__c window = [Select Id from EBH_DealRetailCampaign__c Limit 1];
        EBH_Deal__c d1 = [Select Id from EBH_Deal__c Limit 1];
        Account acc = [Select Id from Account Limit 1];
        Test.startTest();
            acc.NA_Deals_Subsidy_PayPal_Email__c = '';
            update acc;
            d1.EBH_Status__c = 'Ops Review';
            update d1;
            Map<String,Object> result = Subsidize_DealController.apexInit(window.Id,d1.Id);
            System.assertEquals('ko', result.get('status')+'','convert success error incorrect status '+result);
        Test.stopTest();
    }

    @IsTest
    static void testSubsidizeSiteUS(){
        EBH_DealRetailCampaign__c window = [Select Id from EBH_DealRetailCampaign__c Limit 1];
        EBH_Deal__c d1 = [Select Id from EBH_Deal__c Limit 1];
        Profile profile = [select Id,Name from Profile where Name = 'NA Standard User Base'];
        PermissionSet ps = [select Id, Name From PermissionSet Where Name = 'US_Manage_Deals'];
        User existAdminUser = [Select Id from User Where isActive = true and profile.Name = 'System Administrator' Limit 1];
        User user = new User();
		user.Alias='SB';
		user.Email='sb@ebay.com';
		user.EmailEncodingKey='UTF-8';
		user.LastName='sbUser';
		user.LanguageLocaleKey='en_US'; 
		user.LocaleSidKey='en_US';
		user.ProfileId = profile.Id;
		user.TimeZoneSidKey='America/Los_Angeles';
		user.UserName='sb@ebay.com';
        user.ManagerId=existAdminUser.Id;

		System.runAs(existAdminUser){
			insert user;
            Account acc = [SELECT OwnerId FROM Account limit 1];
            acc.OwnerId = user.Id;
            update acc;
		}

        Test.startTest();
            System.runAs(user){
                d1.EBH_Status__c = 'Ops Review';
                d1.EBH_DealSiteId__c = '0';
                update d1;
                Map<String,Object> result = Subsidize_DealController.apexInit(window.Id,d1.Id);
                System.assertEquals('ok', result.get('status')+'','convert success: '+result);
                d1 = [Select Id,Merchant_Approver__c,Director__c from EBH_Deal__c Limit 1];
                System.assertNotEquals(d1.Merchant_Approver__c, user.Id, 'Merchant Approver should not be null'); //VS-01172024-US-0014529
            }

        Test.stopTest();
    }
}