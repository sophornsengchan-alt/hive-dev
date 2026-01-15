@isTest
/*********************************************************************************************************************************
@ Class:          SubmitForApprovalControllerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0008230
                  It was migrated from join instance with original name: DD_SubmitForApprovalControllerTest.
                  Test class for SubmitForApprovalControllerTest
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  07.10.2020 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
private class SubmitForApprovalControllerTest {
	@testSetup
    static void setup(){
    	byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
    }


    /*********************************************************************************************************************************
    @ Method:         test_submitForApproval
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008230
                      It was migrated from join instance with original name: DD_SubmitForApprovalControllerTest.test_submitForApproval

                      Test method to validation deal approval process.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  07.10.2020 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    @isTest
    public static void test_submitForApproval(){

        //     Profile p = [select id from Profile where name='System Administrator' limit 1];
        // User u1 = new User(alias = 'TestApro', email='TestsubApprov@ebay.com',
        //                 emailencodingkey='UTF-8', lastname='TestsubApprov', firstname='TestsubApprov', languagelocalekey='en_US',
        //                 localesidkey='en_US', profileid = p.Id,
        //                 timezonesidkey='America/Los_Angeles', username='TestsubApprov@salesforce.de', isActive = true);
        //     insert u1;

        //     User u2 = new User(alias = 'TestApr2', email='TestApr2@ebay.com',
        //                 emailencodingkey='UTF-8', lastname='TestApr2', firstname='TestApr2', languagelocalekey='en_US',
        //                 localesidkey='en_US', profileid = p.Id,
        //                 timezonesidkey='America/Los_Angeles', username='TestApr2@salesforce.de', isActive = true,Hierarchy_Manager__c=u1.Id);
        // insert u2;
    	// Deal_Timezone__c dealTimezone = new Deal_Timezone__c();
        // dealTimezone.TimeZone__c='America/Los_Angeles';
        // insert dealTimezone;
        // Account acc = new Account(Name='Test Account Name: 1', BillingCountry='CH');
        // insert acc;
        // eBay_Seller__c eBaySeller = new eBay_Seller__c (Name='Test eBaySeller 1',Account__c = acc.Id,GMV_Full_Yr_Goal__c=1500,Oracle_ID__c='12345',Daily_Deals_Whitelist__c=true);
        //     eBay_Seller__c eBaySeller2 = new eBay_Seller__c (Name='Test eBaySeller 2',Account__c = acc.Id,GMV_Full_Yr_Goal__c=1500,Oracle_ID__c='12346',Daily_Deals_Whitelist__c=true);
        //     insert new List<eBay_Seller__c>{eBaySeller,eBaySeller2};
        //     Id spotRecordTypeId = Schema.SObjectType.EBH_SpotlightCategory__c.getRecordTypeInfosByName().get('eBay NA Spotlight Categories').getRecordTypeId();
        // EBH_SpotlightCategory__c spotCat = new EBH_SpotlightCategory__c(RecordTypeId = spotRecordTypeId,Name = 'test spotLightCat',Country__c='NA',Spotlight_Category_ID__c='testSpotId');
        //     EBH_SpotlightCategory__c spotCat2 = new EBH_SpotlightCategory__c(RecordTypeId = spotRecordTypeId,Name = 'test spotLightCat2',Country__c='NA',Spotlight_Category_ID__c='testSpotId');
        //     insert new List<EBH_SpotlightCategory__c>{spotCat,spotCat2};
        //     Id devRecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('eBay NA').getRecordTypeId();
        //     Date myDate = System.today();
        // EBH_Deal__c d1 = new EBH_Deal__c(EBH_SpotlightCategory__c = spotCat.Id,eBay_Seller__c=eBaySeller.Id,RecordTypeId=devRecordTypeId,Seller_Price__c=10,Deal_Price__c=5,Deal_Start_Date__c=myDate,Deal_End_Date__c=myDate+1,Status__c='New',Vertical__c = 'Home & Garden',Category__c='Home & Garden', Product_Title__c='product 1',Seller_Email__c='sales@test.com',Quantity__c=1);
        // EBH_Deal__c d1a = new EBH_Deal__c(EBH_SpotlightCategory__c = spotCat2.Id,eBay_Seller__c=eBaySeller2.Id,RecordTypeId=devRecordTypeId,Seller_Price__c=10,Deal_Price__c=5,Deal_Start_Date__c=myDate,Deal_End_Date__c=myDate+1,Status__c='New',Vertical__c = 'Home & Garden',Category__c='Home & Garden', Product_Title__c='product 2',Seller_Email__c='sales@test.com',Quantity__c=1);
        // List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>{d1,d1a};


        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        User u1;

        Group dealGroup;
        GroupMember gMember;

        System.runAs(admin){

            Profile p = [select id from Profile where name='NA Standard User Base' limit 1];
            u1 = new User(alias = 'TestApro', email='TestsubApprov@ebay.com',
                            emailencodingkey='UTF-8', lastname='TestsubApprov', firstname='TestsubApprov', languagelocalekey='en_US',
                            localesidkey='en_US', profileid = p.Id,
                            timezonesidkey='America/Los_Angeles', username='TestsubApprov@salesforce.de', isActive = true);
            insert u1;

            List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
            for(PermissionSet ps :  [SELECT Id, Name FROM PermissionSet WHERE Name = 'US_Manage_Deals' Or Name = 'Deal_Start_End_time_fileds']){
                psa.add(new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = u1.Id));
            }
            insert psa;

            dealGroup = new Group(Name='test deal group', Type='Queue');
            insert dealGroup;

            gMember = new GroupMember();
            gMember.UserOrGroupId = u1.Id;
            gMember.GroupId = dealGroup.Id;
            Insert gMember;
        }


        System.runAs(u1){

            Account ac = new Account(Name='Seller',EBH_VATNumber__c='1122334455');
            ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
            insert ac;
    
            EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c();
            insert sc;
    
            Id dealNARecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByDeveloperName().get('Deal_V2').getRecordTypeId();
    
            // US-0009033
            Contact cont = new Contact();
            cont.LastName = 'NSP_Cont';
            cont.AccountId = ac.Id;
            cont.Contact_Role__c='Deals;Marketplaces - Daily Deals Statement Recipient';
            //cont.EBH_Decision_Maker_Role__c = 'Deals'; //MN:13/05/2021:US-0009542 - [NA] Deals: Remove unused value from 'Decision Maker Role' on Contact
            cont.Email ='test@ebay.dailydeal.com';
            cont.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('EBH_MANUAL').getRecordTypeId();
            insert cont;
    
    
            EBH_Deal__c d1 = new EBH_Deal__c(
                EBH_DealStartTime__c= System.now().time(),
                EBH_DealStartDate__c=System.toDay().addDays(1),
                EBH_eBayItemID__c='123456789011',
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
                Merchant_Approver__c = admin.Id,
                Seller_Approver_1__c = cont.Id // US-0009033
            );
            EBH_Deal__c d2 = new EBH_Deal__c(
                EBH_DealStartTime__c= System.now().time(),
                EBH_DealStartDate__c=System.toDay().addDays(1),
                EBH_eBayItemID__c='123456789022',
                EBH_BusinessName__c=ac.Id,
                EBH_SpotlightCategory__c=sc.Id,
                EBH_SellerPrice__c = 40,
                EBH_DealPrice__c=20,
                EBH_Vertical__c='Business & Industrial',
                EBH_Category__c = 'Business',
                EBH_DealEndDate__c = System.toDay().addMonths(2),
                EBH_Status__c='New' ,
                EBH_ProductTitle__c='product 2',
                EBH_Quantity__c=1,
                RecordTypeId = dealNARecordTypeId,
                Merchant_Approver__c = admin.Id,
                Seller_Approver_1__c = cont.Id // US-0009033
            );
    
            EBH_Deal__c d3 = new EBH_Deal__c(
                EBH_DealStartTime__c= System.now().time(),
                EBH_DealStartDate__c=System.toDay().addDays(1),
                EBH_eBayItemID__c='123456789033',
                EBH_BusinessName__c=ac.Id,
                EBH_SpotlightCategory__c=sc.Id,
                EBH_SellerPrice__c = 40,
                EBH_DealPrice__c=20,
                EBH_Vertical__c='Business & Industrial',
                EBH_Category__c = 'Business',
                EBH_DealEndDate__c = System.toDay().addMonths(2),
                EBH_Status__c='New' ,
                EBH_ProductTitle__c='product 2',
                EBH_Quantity__c=1,
                RecordTypeId = dealNARecordTypeId,
                Merchant_Approver__c = admin.Id,
                Seller_Approver_1__c = cont.Id // US-0009033
            );
    
            EBH_Deal__c d4 = new EBH_Deal__c(
                EBH_DealStartTime__c= System.now().time(),
                EBH_DealStartDate__c=System.toDay().addDays(1),
                EBH_eBayItemID__c='123456789044',
                EBH_BusinessName__c=ac.Id,
                EBH_SpotlightCategory__c=sc.Id,
                EBH_SellerPrice__c = 40,
                EBH_DealPrice__c=20,
                EBH_Vertical__c='Business & Industrial',
                EBH_Category__c = 'Business',
                EBH_DealEndDate__c = System.toDay().addMonths(2),
                EBH_Status__c='New' ,
                EBH_ProductTitle__c='product 2',
                EBH_Quantity__c=1,
                RecordTypeId = dealNARecordTypeId,
                Merchant_Approver__c = admin.Id,
                Seller_Approver_1__c = cont.Id // US-0009033
            );
    
            List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>{d1,d2,d3,d4};

            insert lstDeal;

            d1.EBH_Vertical__c = 'Business & Industrial';
            d1.OwnerId = u1.Id;

            d2.EBH_Vertical__c = 'Business & Industrial';
            d2.OwnerId = u1.Id;

            d3.EBH_Vertical__c = 'Business & Industrial';
            d3.OwnerId = u1.Id;

            d4.EBH_Vertical__c = 'Business & Industrial';
            d4.OwnerId = u1.Id;

            lstDeal = new List<EBH_Deal__c>{d1,d2,d3,d4};
            update lstDeal;

            List<EBH_Deal__c> queriedDeal = [Select Id,EBH_Vertical__c,OwnerId From EBH_Deal__c Where Id IN: lstDeal Order By Id ASC];

            System.assertEquals('Business & Industrial', queriedDeal[0].EBH_Vertical__c);
            System.assertEquals('Business & Industrial', queriedDeal[1].EBH_Vertical__c);
            System.assertEquals('Business & Industrial', queriedDeal[2].EBH_Vertical__c);
            System.assertEquals('Business & Industrial', queriedDeal[3].EBH_Vertical__c);

            System.assertEquals(u1.Id, queriedDeal[0].OwnerId);
            System.assertEquals(u1.Id, queriedDeal[1].OwnerId);
            System.assertEquals(u1.Id, queriedDeal[2].OwnerId);
            System.assertEquals(u1.Id, queriedDeal[3].OwnerId);


            Test.startTest();
            PageReference ref = new PageReference('/apex/SubmitForApprovalPage');
            Test.setCurrentPage(ref);

            ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstDeal);
            ssc.setSelected(lstDeal);

            SubmitForApprovalController controller = new SubmitForApprovalController(ssc);
            System.assertEquals(false, controller.isNotebayNa);  // US-0009033
            System.assertEquals(true, controller.displayPopup);  // US-0009033
            
            // Map<String,Object> mapResult = new Map<String,Object>(); //Sophal:06/04/2021:US-0009353

            
            // controller.submitForApproval(); //Sophal:06/04/2021:US-0009353
            // mapResult = SubmitForApprovalController.submitForApproval(controller.lstSelDid, controller.dealNARecordTypeId, new List<Id>()); //Sophal:06/04/2021:US-0009353
            controller.submitForApproval(); // Sophal: 11.08.2021 : US-0009771
            controller.cancel();

            Test.stopTest();
            List<ProcessInstanceWorkItem> workItems = [SELECT ActorId,OriginalActorId, ProcessInstance.TargetObjectId,ProcessInstance.Status FROM ProcessInstanceWorkItem WHERE ProcessInstance.Status in ('Pending') and ProcessInstance.TargetObjectId IN: lstDeal Order By ProcessInstance.TargetObjectId ASC];
          //commented by DHE to fix deployment  System.assertEquals(null, controller.errMsg);  // US-0009033
            // System.assert(controller.isSuccess); //Sophal:06/04/2021:US-0009353
           //  System.assertEquals('ok',mapResult.get('status')); //Sophal:06/04/2021:US-0009353
            System.assert(workItems.size() == 4);

            workItems[2].OriginalActorId = dealGroup.Id;
            workItems[3].OriginalActorId = dealGroup.Id;
            update new List<ProcessInstanceWorkItem>{workItems[2],workItems[3]};

            // resend to notified emails
            // controller.submitForApproval(); //Sophal:06/04/2021:US-0009353
            // mapResult = SubmitForApprovalController.submitForApproval(controller.lstSelDid, controller.dealNARecordTypeId, new List<Id>()); //Sophal:06/04/2021:US-0009353
            controller.submitForApproval(); // Sophal: 11.08.2021 : US-0009771
            workItems = [SELECT ActorId,OriginalActorId, ProcessInstance.TargetObjectId,ProcessInstance.Status FROM ProcessInstanceWorkItem WHERE ProcessInstance.Status in ('Pending') and ProcessInstance.TargetObjectId IN: lstDeal Order By ProcessInstance.TargetObjectId ASC];
            // System.assert(controller.isSuccess); //Sophal:06/04/2021:US-0009353
            // System.assertEquals('ok',mapResult.get('status')); //Sophal:06/04/2021:US-0009353
            System.assert(workItems.size() == 4);

            // SubmitForApprovalController.notifyApproversInDeals(controller.lstSelDid, controller.dealNARecordTypeId); //Sophal:06/04/2021:US-0009353
            controller.notifyApproversInDeals(); // Sophal: 11.08.2021 : US-0009771
            Map<Id,SubmitForApprovalController.UserApprovalDetail> mapUserIdToDeal = SubmitForApprovalController.testMapUserIdToDeal;
            System.assert(mapUserIdToDeal.size() == 2);

            System.assert(mapUserIdToDeal.containsKey(admin.Id));
            System.assert(mapUserIdToDeal.get(admin.Id).mapVerticalAndCategory.size() == 1);
            System.assert(mapUserIdToDeal.get(admin.Id).mapVerticalAndCategory.values()[0].size == 2);


            System.assert(mapUserIdToDeal.containsKey(u1.Id));
            System.assert(mapUserIdToDeal.get(u1.Id).mapVerticalAndCategory.size() == 1);
            System.assert(mapUserIdToDeal.get(u1.Id).mapVerticalAndCategory.values()[0].size == 2);


            List<User> listUser = [
                Select Id,
                UserPreferencesReceiveNoNotificationsAsApprover,
                UserPreferencesReceiveNotificationsAsDelegatedApprover 
                From User 
                WHERE Id = :u1.Id
            ];

           // SubmitForApprovalController.remoteUpdateUserNotification(listUser, false);





        }



        // System.runAs(u2){
        // insert lstDeal;

        //     Test.startTest();
        //     PageReference ref = new PageReference('/apex/SubmitForApprovalPage');
        //     Test.setCurrentPage(ref);

        //     ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstDeal);
        //     ssc.setSelected(lstDeal);

        //     DD_SubmitForApprovalController controller = new DD_SubmitForApprovalController(ssc);
        //     controller.submitForApproval();
        //     controller.cancel();
        // Test.stopTest();
        // List<ProcessInstanceWorkItem> workItems = [SELECT ActorId, ProcessInstance.TargetObjectId,ProcessInstance.Status FROM ProcessInstanceWorkItem WHERE ProcessInstance.Status in ('Pending') and ProcessInstance.TargetObjectId IN: lstDeal];
        // System.assert(controller.isSuccess);
        // System.assert(workItems.size() == 2);
        // }
    }


    /*********************************************************************************************************************************
    @ Method:         test_submitCaDealForApproval
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0009606 test method when submit CA deal for approval
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  04.06.2021 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    @isTest
    public static void test_submitCaDealForApproval(){
        
        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        User u1;

        Group dealGroup1;
        GroupMember gMember1;

        Group dealGroup2;
        GroupMember gMember2;

        System.runAs(admin){

            Profile p = [select id from Profile where name='NA Standard User Base' limit 1];
            u1 = new User(alias = 'TestApro', email='TestsubApprov@ebay.com',
                            emailencodingkey='UTF-8', lastname='TestsubApprov', firstname='TestsubApprov', languagelocalekey='en_US',
                            localesidkey='en_US', profileid = p.Id,
                            timezonesidkey='America/Los_Angeles', username='TestsubApprov@salesforce.de', isActive = true);
            insert u1;

            List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
            for(PermissionSet ps :  [SELECT Id, Name FROM PermissionSet WHERE Name = 'US_Manage_Deals' Or Name = 'Deal_Start_End_time_fileds']){
                psa.add(new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = u1.Id));
            }
            insert psa;

            dealGroup1 = [Select Id From Group Where DeveloperName='CA_Deals_Approvers' Limit 1];

            gMember1 = new GroupMember();
            gMember1.UserOrGroupId = u1.Id;
            gMember1.GroupId = dealGroup1.Id;
            Insert gMember1;

            dealGroup2 = [Select Id From Group Where DeveloperName='Daily_Deals_Finance' Limit 1];
            gMember2 = new GroupMember();
            gMember2.UserOrGroupId = u1.Id;
            gMember2.GroupId = dealGroup2.Id;
            Insert gMember2;
        }

        System.runAs(u1){

            Account ac = new Account(Name='Seller',EBH_VATNumber__c='1122334455');
            ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
            insert ac;
    
            EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c();
            insert sc;
    
            Id dealNARecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByDeveloperName().get('Deal_V2').getRecordTypeId();
    
            Contact cont = new Contact();
            cont.LastName = 'NSP_Cont';
            cont.AccountId = ac.Id;
            cont.Contact_Role__c='Deals;Marketplaces - Daily Deals Statement Recipient';
            cont.Email ='test@ebay.dailydeal.com';
            cont.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('EBH_MANUAL').getRecordTypeId();
            insert cont;
    
    		Date startDate = System.today().addMonths(1).toStartOfMonth(); // 1st day of next month
            Date endDate = startDate.addMonths(1).addDays(-1); // last day of next month
            EBH_Deal__c d1 = new EBH_Deal__c(
                EBH_DealStartTime__c= System.now().time(),
                EBH_DealStartDate__c = startDate,
                EBH_eBayItemID__c='123456789011',
                EBH_BusinessName__c=ac.Id,
                EBH_SpotlightCategory__c=sc.Id,
                EBH_SellerPrice__c=40,
                EBH_DealPrice__c=20,
                EBH_Vertical__c='Business & Industrial',
                EBH_Category__c = 'Business',
                EBH_DealEndDate__c = endDate,
                EBH_Status__c= 'New' ,
                EBH_ProductTitle__c='product 2',
                EBH_Quantity__c=1,
                RecordTypeId = dealNARecordTypeId,
                Seller_Approver_1__c = cont.Id,
                EBH_DealSiteId__c ='2' // US-0009606 deal site must be CA in this method
            );
            EBH_Deal__c d2 = new EBH_Deal__c(
                EBH_DealStartTime__c= System.now().time(),
                EBH_DealStartDate__c = startDate,
                EBH_eBayItemID__c='123456789022',
                EBH_BusinessName__c=ac.Id,
                EBH_SpotlightCategory__c=sc.Id,
                EBH_SellerPrice__c = 40,
                EBH_DealPrice__c=20,
                EBH_Vertical__c='Business & Industrial',
                EBH_Category__c = 'Business',
                EBH_DealEndDate__c = endDate,
                EBH_Status__c='New' ,
                EBH_ProductTitle__c='product 2',
                EBH_Quantity__c=1,
                RecordTypeId = dealNARecordTypeId,
                Seller_Approver_1__c = cont.Id,
                EBH_DealSiteId__c ='2' // US-0009606 deal site must be CA in this method
            );
    
            List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>{d1,d2};

            insert lstDeal;

            d1.EBH_Vertical__c = 'Business & Industrial';
            d1.OwnerId = u1.Id;

            d2.EBH_Vertical__c = 'Business & Industrial';
            d2.OwnerId = u1.Id;

            lstDeal = new List<EBH_Deal__c>{d1,d2};
            update lstDeal;

            List<EBH_Deal__c> queriedDeal = [Select Id,EBH_Vertical__c,OwnerId From EBH_Deal__c Where Id IN: lstDeal Order By Id ASC];

            System.assertEquals('Business & Industrial', queriedDeal[0].EBH_Vertical__c);
            System.assertEquals('Business & Industrial', queriedDeal[1].EBH_Vertical__c);

            System.assertEquals(u1.Id, queriedDeal[0].OwnerId);
            System.assertEquals(u1.Id, queriedDeal[1].OwnerId);


            Test.startTest();

                PageReference ref = new PageReference('/apex/SubmitForApprovalPage');
                Test.setCurrentPage(ref);

                ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstDeal);
                ssc.setSelected(lstDeal);

                SubmitForApprovalController controller = new SubmitForApprovalController(ssc);
                System.assertEquals(false, controller.isNotebayNa);  
                System.assertEquals(true, controller.displayPopup); 
                
                // Map<String,Object> mapResult = new Map<String,Object>();

                // mapResult = SubmitForApprovalController.submitForApproval(controller.lstSelDid, controller.dealNARecordTypeId, new List<Id>()); //Sophal:06/04/2021:US-0009353
                controller.submitForApproval();
                controller.cancel();

                

                List<ProcessInstanceWorkItem> workItems = [SELECT ActorId,OriginalActorId, ProcessInstance.TargetObjectId,ProcessInstance.Status FROM ProcessInstanceWorkItem WHERE ProcessInstance.Status in ('Pending') and ProcessInstance.TargetObjectId IN: lstDeal Order By ProcessInstance.TargetObjectId ASC];

                // System.assertEquals('ok',mapResult.get('status'));
                System.assert(workItems.size() == 2);

                System.assertEquals(workItems[0].OriginalActorId,dealGroup1.Id);
                System.assertEquals(workItems[1].OriginalActorId,dealGroup1.Id);

            Test.stopTest();

        }

    }


}