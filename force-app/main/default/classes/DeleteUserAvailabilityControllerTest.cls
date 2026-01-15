/*********************************************************************************************************************************
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.10.2022 / Sarom Chetra / US-0012471 - Fix failing test class DeleteUserAvailabilityControllerTest
********************************************************************************************************************************/
@isTest
private class DeleteUserAvailabilityControllerTest {

    @testSetup
    static void setupData(){

    }

    //@ Change history: 06.10.2022 / Sarom Chetra / US-0012471 - Fix failing test class DeleteUserAvailabilityControllerTest
    @isTest
    private static void testDeleteUserAvailability()
    {
    	DeleteUserAvailabilityController dUA;
        User stdU = EBH_TestDataFactory.createUser('Business Admin');
        insert stdU;

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name =: DeleteUserAvailabilityController.PERMISSION_BOB_CATEGORY_LEAD];
        insert new PermissionSetAssignment(AssigneeId = stdU.id, PermissionSetId = ps.Id);
    
    	Test.startTest();
            System.runAs(stdU){
                User_Availability__c ua1 = new User_Availability__c();
                insert ua1;

                // 06.10.2022 / Sarom Chetra / US-0012471
                User_Availability__c ua2 = new User_Availability__c(Date__c=Date.today(), Unique_Id__c=(UserInfo.getUserId()+'#'+Date.today()), Available_Calls_Morning_Slot__c = 5, Available_Calls_Afternoon_Slot__c = 5, OwnerId= UserInfo.getUserId());
                insert ua2;
                // end 06.10.2022 / Sarom Chetra / US-0012471

                List<User_Availability__c> lstUA = [SELECT Id FROM User_Availability__c];
                System.assert(lstUA.size() == 2);

                ApexPages.StandardSetController sc = new ApexPages.StandardSetController(lstUA);
                sc.setSelected(lstUA);
                dUA = new DeleteUserAvailabilityController(sc);
                dUA.backToListView();
                dUA.initDeleting();
                dUA.actionDelete();
            }
    	Test.stopTest();	
    }

    @isTest
    private static void testDeleteUserAvailabilityError()
    {
    	DeleteUserAvailabilityController dUA;
        User stdU = EBH_TestDataFactory.createUser('Business Admin');
        insert stdU;

    	Test.startTest();
            System.runAs(stdU){
                User_Availability__c ua1 = new User_Availability__c();
                insert ua1;

                // 06.10.2022 / Sarom Chetra / US-0012471
                User_Availability__c ua2 = new User_Availability__c(Date__c=Date.today(), Unique_Id__c=(UserInfo.getUserId()+'#'+Date.today()), Available_Calls_Morning_Slot__c = 4, Available_Calls_Afternoon_Slot__c = 4, OwnerId= UserInfo.getUserId());
                insert ua2;
                // end 06.10.2022 / Sarom Chetra / US-0012471

                List<User_Availability__c> lstUA = [SELECT Id FROM User_Availability__c];
                System.assert(lstUA.size() == 2);

                ApexPages.StandardSetController sc = new ApexPages.StandardSetController(lstUA);
                sc.setSelected(lstUA);
                dUA = new DeleteUserAvailabilityController(sc);
                dUA.backToListView();
                dUA.initDeleting();
                dUA.actionDelete();
            }
    	Test.stopTest();
        System.assert([SELECT Id FROM User_Availability__c].size() == 2);
    	
    }
}