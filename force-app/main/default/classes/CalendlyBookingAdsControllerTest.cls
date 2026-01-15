@isTest
private class CalendlyBookingAdsControllerTest {
    @testSetup static void setUp() {
         
        User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 2];
        Contact contact;
        System.runAs(admins[0])
        {
            RecordType bobRecordTypeAds = ApexUtil.getRecordTypeByName('BOB__c','Advertising_Cohort');
            BoB__c bob = new BoB__c(Status__c= 'BoB Active',EBH_BOBCNTRY__c='77',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeAds.Id);
            insert bob;

            RecordType bobSellerRecordTypeAds = ApexUtil.getRecordTypeByName('BoB_Seller__c','Advertising');
            //List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');
            Account portalAccountNA = SEPTestGenerator.createSeller('Portal Seller NA', SEP_Helper.SEP_Domain_NA, 'Full Access', null, null);
            Account portalAccountDE = SEPTestGenerator.createSeller('Portal Seller DE', SEP_Helper.SEP_Domain_DE, 'Full Access', null, null);

            BoB_Seller__c bs = new BoB_Seller__c(Status__c= 'New', RecordTypeId = bobSellerRecordTypeAds.Id,Ads_Partner_Manager__c=UserInfo.getUserId(),Seller__c=portalAccountNA.Id,BoB__c = bob.Id);
            BoB_Seller__c bs1 = new BoB_Seller__c(Status__c= 'New', RecordTypeId = bobSellerRecordTypeAds.Id,Ads_Partner_Manager__c=UserInfo.getUserId(),Seller__c=portalAccountDE.Id,BoB__c = bob.Id);
            List<BoB_Seller__c> lstBs = new List<BoB_Seller__c>{bs,bs1}; 
            insert lstBs; 

            RecordType recDWH = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
            contact = new Contact(
                    FirstName = 'Test',
                    Lastname = 'test con2',
                    AccountId = portalAccountDE.Id,
                    Email = System.now().millisecond() + 'test2@test.com',
                    RecordTypeId=recDWH.Id
                );
            insert contact;
            AccountContactRelation acr =  new AccountContactRelation(ContactId=contact.Id,AccountId=portalAccountNA.Id,IsActive=True);
            insert acr;
        }

        System.runAs(admins[1])
        {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'DE - Seller Portal'];
            User sepDE = SEPTestGenerator.prepareCommunityUserRecord('sepNAamc1', contact.Id, p.Id);

            insert new List<User>{sepDE}; 

            PermissionSet psg = [SELECT Id FROM PermissionSet WHERE name = 'Bookings_Portal'];
            PermissionSetAssignment assignPS = new PermissionSetAssignment(
                AssigneeId = sepDE.Id,
                PermissionSetId = psg.Id
            );
            insert assignPS;
        }
        
    }

    @isTest
    private static void initData(){
        List<BoB_Seller__c> lstBs = [select id from BoB_Seller__c];
        Test.startTest();
            Map<String,Object> funcInitData = CalendlyBookingAdsController.initData(lstBs.get(0).Id);
        Test.stopTest();
        system.assertEquals(true, funcInitData.containsKey('accManagerName'),'Ads_Partner_Manager__c name is found');
    }

    @isTest
    private static void getAllAccountIdsRelated(){
        Contact con = [SELECT Id,Email FROM Contact limit 1];
        User user1 = [SELECT Id,name From User WHERE ContactId=:con.Id limit 1];
        System.runAs(user1) {
        Test.startTest(); 
        
            Map<String,Object> mapResult = CalendlyBookingAdsController.getAllAccountIdsRelated();
            List<Account> lstRelatedAccount = (List<Account>) mapResult.get('listRelatedAccounts');
        
        Test.stopTest();
        System.assertEquals(2, lstRelatedAccount.size(),'Found 2 Related Seller');
        }
    }
}