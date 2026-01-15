@isTest
public class CustomObjectUsageControllerTest {
    @TestSetup
    static void makeData(){
        Profile profile = [SELECT Id FROM Profile WHERE Name ='System Administrator' Limit 1];
        User user1 = new User(
                                Username = System.now().millisecond() + 'test67890@ebay.com',
                                ProfileId = profile.Id,
                                Alias = 'test456',
                                Email = 'test67890xx@ebay.com',
                                EmailEncodingKey = 'UTF-8',
                                LastName = 'McTesty',
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'en_US',
                                LanguageLocaleKey = 'en_US'
                                );
        User user2 = new User(
                                Username = System.now().millisecond() + 'test12345@ebay.com',
                                ProfileId = profile.Id,
                                Alias = 'test123',
                                Email = 'test12345xx@ebay.com',
                                EmailEncodingKey = 'UTF-8',
                                LastName = 'McTesty',
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'en_US',
                                LanguageLocaleKey = 'en_US'
                                );
        insert new User[]{user1,user2};
        
        CustomObjectUsageControllerTest.addPermissionSet(user2.Id);
    }

    @isTest
    static void testConstructorWithoutPermission() {
        User user1 = [SELECT Id FROM User WHERE Alias = 'test456'];

        System.runAs(user1){
            CustomObjectUsageController cos = new CustomObjectUsageController();
            System.assertEquals(false, cos.hasCustomPermission, 'Does not have Permissions');
        }
    }

    @isTest
    static void testConstructorWithPermission() {       
        User user2 = [SELECT Id, Alias FROM User WHERE Alias = 'test123' LIMIT 1];
        Test.startTest();  
        PageReference pageRef = Page.CustomObjectUsage;
        Test.setCurrentPage(pageRef);
        System.runAs(user2){
            CustomObjectUsageController cos = new CustomObjectUsageController();
            cos.loadData();
            System.assertEquals(true, cos.hasCustomPermission, 'Has Permissions');
        }
        Test.stopTest();
    }

    @isTest
    static void testFirstPage() {
        User user2 = [SELECT Id FROM User WHERE Alias = 'test123'];

        Test.startTest();
            System.runAs(user2){
                PageReference pageRef = Page.CustomObjectUsage;
                Test.setCurrentPage(pageRef);
                CustomObjectUsageController controller = new CustomObjectUsageController();
                controller.firstPage();
                System.assertEquals(controller.firstPage(),null, 'Checking the First Page method');
            }
        Test.stopTest();
    }

    @isTest
    static void testNextPage() {
        User user2 = [SELECT Id FROM User WHERE Alias = 'test123'];

        Test.startTest();
            System.runAs(user2){
                PageReference pageRef = Page.CustomObjectUsage;
                Test.setCurrentPage(pageRef);
                CustomObjectUsageController controller = new CustomObjectUsageController();
                controller.nextPage();
                System.assertEquals(controller.nextPage(),null, 'Checking the Next Page method');
            }
        Test.stopTest();
    }
    @isTest
    static void testPrevPage() {
        User user2 = [SELECT Id FROM User WHERE Alias = 'test123'];

        Test.startTest();
            System.runAs(user2){
                PageReference pageRef = Page.CustomObjectUsage;
                Test.setCurrentPage(pageRef);
                CustomObjectUsageController controller = new CustomObjectUsageController();
                controller.previousPage();
                System.assertEquals(controller.nextPage(),null, 'Checking the Previous Page method');
            }
        Test.stopTest();
    }
    @isTest
    static void testLastPage() {
        User user2 = [SELECT Id FROM User WHERE Alias = 'test123'];

        Test.startTest();
            System.runAs(user2){
                PageReference pageRef = Page.CustomObjectUsage;
                Test.setCurrentPage(pageRef);
                CustomObjectUsageController controller = new CustomObjectUsageController();
                controller.lastPage();
                System.assertEquals(controller.nextPage(),null, 'Checking the Last Page method');
            }
        Test.stopTest();
    }

    @isTest
    static void testDisableButtons() {
        User user2 = [SELECT Id FROM User WHERE Alias = 'test123'];

        Test.startTest();
            System.runAs(user2){
                PageReference pageRef = Page.CustomObjectUsage;
                Test.setCurrentPage(pageRef);
                CustomObjectUsageController controller = new CustomObjectUsageController();

                controller.getDisablePrevious();                                
                System.assertEquals(controller.getDisablePrevious(),true, 'Checking the Disable Previous method');

                controller.getDisableNext();
                System.assertEquals(controller.getDisableNext(),false, 'Checking the Disable Next method');

                //Setting the record size to check true scenario
                controller.recordSize = 10;
                controller.getDisableNext();
                System.assertEquals(controller.getDisableNext(),true, 'Checking the Disable Next method');

                //Setting the counter to check false scenario
                controller.counter = 10;
                controller.getDisablePrevious();
                System.assertEquals(controller.getDisablePrevious(),false, 'Checking the Disable Previous method');

                controller.getPageNumber();
                system.assertNotEquals(controller.getPageNumber(), 0, 'Page Number not equal to 0');

                controller.getTotalPages();
                system.assertNotEquals(controller.getTotalPages(), 0, 'Total Pages not equal to 0');
                
                controller.recordSize = 0;
                controller.getTotalPages();
                system.assertEquals(controller.getTotalPages(), 0, 'Total Pages is equal to 0');
            }
        Test.stopTest();
    }

    @future
    private static void addPermissionSet(id userid) {
        //Retrieving Custom Permission
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Custom_Object_Usage_Permission_Set' LIMIT 1];

        //Assigning Custom Permission to Test User
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = userid;
        psa.PermissionSetId = ps.Id;
        insert psa;
    }
}