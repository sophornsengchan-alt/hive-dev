/*********************************************************************************************************************************
@ Change history: 22.06.2020 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0007615 Change Ticket__c to Case
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 15.02.2021 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0008362  Upgrade code coverage of FindInactiveUserController from 0% to 85% 
*********************************************************************************************************************************/
@isTest
private class FindInactiveUserControllerTest {
    
    private static testMethod void testSearch()
    {
        User[] admins = [Select Id,Name From User Where ProfileId =:ApexUtil.ADMIN_PROFILE_ID AND isActive = true AND UserRoleId<>null limit 2];
        System.runAs(admins[0])
        {
            EBH_TestDataFactory.setUpCustomSettings();
        }
        System.runAs(admins[1])
        {
            Case t = new Case(
                Country__c=CaseTriggerHandler.TICKET_COUNTRY_AU,
                User_Type__c='GCX Portal User', //MN-07112023-US-0014413
                RecordTypeId=ApexUtil.getRecordTypeByName('Case', 'User_Reactivation').Id,
                Email_Address__c='test@test.com'
                ,Status = 'New' // US-0008362 chnage from 'In Progress' to 'New' to byPass validation rule
                ,Picklist__c=CaseTriggerHandler.PROFILE_GCX_PARTNER);

            Map<String,String> mapResult = FindInactiveUserController.apexSaveTicket(t.Id, UserInfo.getUserId()+''); // US-0008362 to coverage exception code block

            insert t;

            t.Status = 'In Progress';
            t.OwnerId = UserInfo.getUserId();
            update t;

            Test.startTest();  
                mapResult = FindInactiveUserController.apexSaveTicket(t.Id, UserInfo.getUserId()+'');
                System.assertEquals('ok', mapResult.get('status'),'user id set');
                Case t2 = [Select Id,Inactive_User__c From Case where Id=:t.Id];
                System.assertEquals(t2.Inactive_User__c, UserInfo.getUserId(),'user id set correctly');
                
                mapResult = FindInactiveUserController.apexSaveTicket(t.Id, 'xxxxxxxxxxxxxxx');
                System.assertEquals('ko', mapResult.get('status'),'invalid id');
            Test.stopTest();
        }
        
    }
}