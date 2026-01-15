// 07-11-2023 - Sharath - US-0012584 - ✓[TS]Delete Metadata created for Trusted Shops
@isTest
public class dynamicMetadataControllersTest{

    @testSetup
    static void setup(){
        //create an account
        Account acc = new Account( Name = 'TestAccount' );
        insert acc;

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,
                                    FirstName='test fn', LastName='test ln', AccountId=acc.Id, Email = 'test123@test.com');
        insert con;

    }

    @IsTest
    static void helpTextMetadataTest() {
        Test.startTest();
        List<Component_help_text_setting__mdt> metadatlist = new List<Component_help_text_setting__mdt>([SELECT DeveloperName FROM Component_help_text_setting__mdt]);
        Component_help_text_setting__mdt obj = dynamicHelpTextController.helpTextMetadata(metadatlist[0].DeveloperName);
        System.assertNotEquals(null,obj);        
        Test.stopTest();
    }


    @IsTest
    static void accountManagementMetadataTest(){
        Test.startTest(); 
        List<Component_help_text_setting__mdt> metadatlist = new List<Component_help_text_setting__mdt>([SELECT DeveloperName FROM Component_help_text_setting__mdt]);
        list<Component_help_text_setting__mdt> accountManagementMetadata = dynamicHelpTextController.accountManagementMetadata(metadatlist[0].DeveloperName,metadatlist[0].DeveloperName,'');
        System.assertNotEquals(0,accountManagementMetadata.size());        
        Test.stopTest();
    }

    @IsTest
    static void pageBannerMetadataTest() {
        Test.startTest();
        List<Card_Banner__mdt> metadatlist = new List<Card_Banner__mdt>([SELECT DeveloperName FROM Card_Banner__mdt]);
        Card_Banner__mdt obj = dynamicCardBannerController.pageBannerMetadata(metadatlist[0].DeveloperName);
        System.assertNotEquals(null,obj);        
        Test.stopTest();
    }
    
    @IsTest
    static void sidebarMetadataTest() {
        
        /* Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount' limit 1];

        Profile profile1 = [SELECT Id, Name FROM Profile WHERE Name = 'DE - Seller Portal'];
        
        Contact con = [SELECT Id,Email FROM Contact WHERE FirstName='test fn' AND LastName='test ln' limit 1];
        User user1 = new User(
                                Username = System.now().millisecond() + 'test12345@test.com',
                                ContactId = con.Id,
                                ProfileId = profile1.Id,
                                
                                Alias = 'test123',
                                Email = 'test12345xx@test.com',
                                EmailEncodingKey = 'UTF-8',
                                LastName = 'McTesty',
                                CommunityNickname = 'test12345',
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'en_US',
                                LanguageLocaleKey = 'en_US'
                                );
        insert user1;

        PermissionSet ps = Database.query('SELECT Id, Name FROM PermissionSet WHERE Name = \'DE_Seller_Portal_Deals\'');
        PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = user1.Id);
        insert psa;

        System.runAs(user1) {
            Test.startTest();
                List<Sidebar_Card__mdt> metadatlist = new List<Sidebar_Card__mdt>([SELECT DeveloperName, Region__c FROM Sidebar_Card__mdt WHERE Region__c = 'DE']);
                List<Sidebar_Card__mdt> lstResult = dynamicCardBannerController.sidebarMetadata(metadatlist[0].Region__c,'');
                System.assertNotEquals(0,lstResult.size());
            Test.stopTest();
        } */
        Test.startTest();
        	List<Sidebar_Card__mdt> metadatlist = new List<Sidebar_Card__mdt>([SELECT DeveloperName, Region__c FROM Sidebar_Card__mdt WHERE Region__c = 'DE']);
            List<Sidebar_Card__mdt> lstResult = dynamicCardBannerController.sidebarMetadata(metadatlist[0].Region__c,'');
        	System.assertEquals(0, lstResult.size());
        	lstResult = dynamicCardBannerController.sidebarMetadata(metadatlist[0].Region__c,'Deals');
        	System.assertNotEquals(0, lstResult.size());
        Test.stopTest();
        
    }
}