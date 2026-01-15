/*********************************************************************************************************************************
@ Class:          UserBadgeHandlerTest
@ Version:        1.0
@ Author:         SRONG TIN (srong.tin@gaea-sys.com)
@ Purpose:        Test class for UserBadgeHandler
@ Change history: 20.08.2021 / SRONG TIN / Created the class.
*********************************************************************************************************************************/
@isTest
public class UserBadgeHandlerTest {
    
	@testSetup static void setup(){
        EBH_TestDataFactory.setUpCustomSettings();  


       
        EBH_ActiveTriggers__c cusettingTrigger = EBH_ActiveTriggers__c.getInstance(CaseTriggerHandler.TRIGGERCONTROLLER);
        cusettingTrigger.UserBadgeTrigger__c = true;
        update cusettingTrigger;
        
        
       
    } 
    private  static User createAdmin() {
        Profile adminProfile = [select Id,Name from Profile where Name = 'System Administrator'];
		User user = new User();
        user.Alias='SRO';
        user.Email='sromail@ebay.com';
        user.EmailEncodingKey='UTF-8';
        user.LastName='SROUser';
        user.LanguageLocaleKey='en_US'; 
        user.LocaleSidKey='en_US';
        user.ProfileId = adminProfile.Id;
        user.TimeZoneSidKey='America/Los_Angeles';
        user.UserName='sromail@ebay.com';
        insert user;
        return user;
        
    }
    
    @IsTest
    static void updatePermissionToUserBadgeTest(){
        
        //User thisUser = [SELECT Id FROM User WHERE Email = 'sromail@ebay.com'];
        User thisUser = createAdmin();
           // System.runAs() allows mixed DML operations in test context
            System.runAs(thisUser) {
                // startTest/stopTest block to run future method synchronously
                Test.startTest();  
                PermissionSet p = new PermissionSet();
                p.Label = 'eBay NA Manage Deals1';
                p.Name = 'eBay_NA_Manage_Deals1';
                insert p;
                
                trailheadapp__Badge__c badge = new trailheadapp__Badge__c();
                badge.Name = 'SRO Test 001';
                badge.trailheadapp__Description__c = 'Hello This is test';
                badge.trailheadapp__URL__c = 'test url';
                badge.trailheadapp__Icon__c = 'test icon';
                badge.trailheadapp__API_Name__c= 'SRO-Test';
                badge.trailheadapp__Type__c = 'Module';
                badge.Permission_Set__c = 'eBay_NA_Manage_Deals1';
                badge.Permission_Set_Description__c = 'Hello Test';
                badge.trailheadapp__Namespace__c = 'de';
                insert badge;
                List<trailheadapp__User_Badge__c> listUserBadge = new List<trailheadapp__User_Badge__c>();
                for(integer i = 0;i<5;i++){
                    trailheadapp__User_Badge__c userBadge = new trailheadapp__User_Badge__c();
                    userBadge.trailheadapp__Badge__c = badge.Id;
                    userBadge.trailheadapp__Status__c = 'Assigned';
                    userBadge.trailheadapp__User__c = thisUser.Id;
                    userBadge.trailheadapp__External_ID__c = '123456789012'+i;
                    listUserBadge.add(userBadge);
                }
                insert listUserBadge;
                
                for(trailheadapp__User_Badge__c ub: listUserBadge){
                    ub.trailheadapp__Status__c = 'Completed';
                }
                update listUserBadge[0];
                
                Test.stopTest();
            }
        
    }
}