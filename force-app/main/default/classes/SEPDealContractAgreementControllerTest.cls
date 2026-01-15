@isTest
private class SEPDealContractAgreementControllerTest {
    @testSetup
    static void setup(){

        EBH_TestDataFactory.setUpCustomSettings();
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        //create an account
        Account acc = new Account(SP_Main_Domain__c = SEP_Helper.SEP_Domain_NA, SP_Deals__c='Full Access', Name = 'TestAccount', SP_Promotions_Manager__c='Full Access', SP_Coupons__c='Full Access',RecordTypeId = recSeller.Id,NA_Deal_Program_Vetted__c = true);
        insert acc;

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,
                                    FirstName='test fn', LastName='test ln', AccountId=acc.Id, Email = 'test123@test.com');
        insert con;
        RecordType recPM = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c','Promotions_Manager_Deals');
        Date today = System.today();

        Integer month = System.today().month();
        Integer year = System.today().year();
        Date startDate = Date.newInstance(year, month+1, 1);
        Date endDate = startDate.addDays(10);
        Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c(
            RecordTypeId = recPM.Id,
            eBay_Seller__c = acc.id,
            Status__c = 'Sent to Seller',
            Deal_Site__c = '0',
            Deal_Start_Date__c=startDate, 
            Deal_End_Date__c = endDate,
            Title__c = 'Test title'
        );
        insert ndca;
    }

    @isTest
    static void test_getDealContractAgreement () {
        Deal_Contract_Agreement__c dca = [SELECT ID,Status__c FROM Deal_Contract_Agreement__c LIMIT 1];
        Test.startTest(); 
        Map<String,Object> restul = SEPDealContractAgreementController.getDealContractAgreement(dca.Id);
        system.assertEquals(false, restul.get('hasUploadItemsAccess'),'hasUploadItemsAccess');
        SEPDealContractAgreementController.getDealsRelatedToDCA(dca.Id,'Subsidize_All_Deals');
        Test.stopTest();
        
    }
    
    @isTest
    static void test_getDealContractAgreementData () {
        Deal_Contract_Agreement__c dca = [SELECT ID FROM Deal_Contract_Agreement__c LIMIT 1];
        dca.Status__c = 'Sent to Seller';
        update dca;
        Test.startTest(); 
        Map<String,Object> restul = SEPDealContractAgreementController.getDealContractAgreementData(dca.Id);
        system.assertEquals(true, restul.get('isShowAgreeOrDecline'));
        Test.stopTest();
        
    }
    
     @isTest
     static void test_doAgreeOrDeclineDealContractAgreement () {

         Deal_Contract_Agreement__c dca = [select id,Name,Status__c,eBay_Funding__c,Rejection_Reason__c,Rejection_Comments__c,SellerPortal_Status__c,Contract_Due_Date__c,eBay_Seller__r.Name,eBay_Seller__r.Primary_Contact__c,eBay_Seller__r.SP_Promotions_Manager__c, Title__c,Deal_Page_Placement__c, Deal_Start_Date__c, Deal_Start_Time__c, Deal_End_Date__c, Deal_End_Time__c, Discount_Applied_in_Cart__c, Max_Total_Subsidy__c, Max_Unit_Subsidy__c from Deal_Contract_Agreement__c LIMIT 1];
        //  Test.startTest(); 
        //  DealContractAgreementWrapper dcaWrapper = new DealContractAgreementWrapper();
        //  dcaWrapper.dca = dca;
        //  dcaWrapper.isAgree = true;
        //  String data = JSON.serialize(new List<DealContractAgreementWrapper>{dcaWrapper});
        //  Map<String,Object> restul = SEPDealContractAgreementController.doAgreeOrDeclineDealContractAgreement(data);
        //  system.assertEquals(true, restul.get('success'));
        //  Test.stopTest();



        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount' limit 1];
        Contact con = [SELECT Id,Email FROM Contact WHERE FirstName='test fn' AND LastName='test ln' limit 1];

        User user1 = SEPTestGenerator.createSEPUser('sepUsersdcac1', con.Id); //MN-10062024-US-0015298
        /* MN-10062024-US-0015298
        Profile profile1 = [SELECT Id, Name FROM Profile WHERE Name = 'NA - Seller Portal'];
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
        */
        Test.startTest(); 

            System.runAs(user1) {
                DealContractAgreementWrapper dcaWrapper = new DealContractAgreementWrapper();
                dcaWrapper.dca = dca;
                dcaWrapper.isAgree = true;
                String data = JSON.serialize(new List<DealContractAgreementWrapper>{dcaWrapper});
                Map<String,Object> restul = SEPDealContractAgreementController.doAgreeOrDeclineDealContractAgreement(data);
                system.assertEquals(true, restul.get('success'));

                Map<String,Object> result = SEPDealContractAgreementController.getDealContractAgreementData(dca.Id);
            }        
       
        Test.stopTest();
        
    }
    
    class DealContractAgreementWrapper {
        
        public Deal_Contract_Agreement__c dca;
        public String rejectedReason; 
        public String otherReason;
        public Boolean isAgree;
            
    }

    @IsTest
    static void testCheckDCA(){
        User[] admins = [Select Id,Name From User Where Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 2];
        Account acc = [Select Id,Name From Account where Name = 'TestAccount' LIMIT 1];
        Deal_Contract_Agreement__c dca = [SELECT ID,Status__c FROM Deal_Contract_Agreement__c LIMIT 1];
        Contact con = [SELECT Id,Email FROM Contact WHERE FirstName='test fn' AND LastName='test ln' limit 1];

        //Profile profile1 = [SELECT Id, Name FROM Profile WHERE Name = 'DE - Seller Portal']; //MN-10062024-US-0015298
        
        User user1 = null;
        System.runAs(admins[0])
        {
            
            PermissionSetGroup psgDE = [Select Id,DeveloperName From PermissionSetGroup Where PermissionSetGroup.DeveloperName ='Seller_Portal_DE'];
            
            user1 = SEPTestGenerator.createSEPUser('sepUsersdcac2', con.Id); //MN-10062024-US-0015298
            /* MN-10062024-US-0015298
            user1 = new User(
                Username = System.now().millisecond() + 'test12345_x777@test.com',
                ContactId = con.Id,
                ProfileId = profile1.Id,
                
                Alias = 'test177',
                Email = 'test12345_x777@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTestyx7',
                CommunityNickname = 'test12377',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                Hide_SP_Deals__c = 'No'
                );
            insert user1;
            */

            Database.insert(new PermissionSetAssignment(PermissionSetGroupId=psgDE.Id,AssigneeId=user1.Id),false);
        }
     

        Test.startTest();
           System.runAs(user1)
            {
                ContentVersion cVersion = new ContentVersion();
                cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                cVersion.PathOnClient = 'gggg';//File name with extention
                cVersion.Origin = 'C';//C-Content Origin. H-Chatter Origin.
                cVersion.OwnerId = UserInfo.getUserId();//Owner of the file
                cVersion.Title = 'gggggg';//Name of the file
                cVersion.VersionData = Blob.valueOf('Test');//File content
                cVersion.Description = 'SEP Auto Generated DCA';
                Id networkId = [SELECT Id FROM Network  where Name='eBay Seller Portal' LIMIT 1].Id;
                cVersion.NetworkId = networkId;
                insert cVersion;
                //After saved the Content Verison, get the ContentDocumentId
                Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
                
                //Insert ContentDocumentLink
                ContentDocumentLink cDocLink = new ContentDocumentLink();
                cDocLink.ContentDocumentId = conDocument;//Add ContentDocumentId
                cDocLink.LinkedEntityId = dca.Id;//Add attachment parentId
                cDocLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                cDocLink.Visibility = 'AllUsers';//AllUsers, InternalUsers, SharedUsers

                insert cDocLink;
                    
                

                Date myDate = Date.today().addDays(5);
                EBH_Deal__c deal1 = new EBH_Deal__c(Deal_Contract_Agreement__c=dca.Id,Hide_in_Seller_Portal__c=False,EBH_DealSiteId__c='101', RecordTypeId=ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id, EBH_BusinessName__c=acc.Id, EBH_MaximumPurchases__c =324,EBH_Quantity__c=500,EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.toDay().addDays(4),EBH_DealEndDate__c = myDate,EBH_Status__c='New' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_eBayItemID__c='123456789001');
                insert deal1;

                Map<String,Object> mapResult = SEPDealContractAgreementController.checkDCA(deal1.Id);
                Assert.areEqual(true, Boolean.valueOf(mapResult.get('showBtn')), 'button download visible to the Page becuase contract pdf is attached');
                
            }

            Test.stopTest();
        
    }

    @IsTest
    static void testdoApproveOrDeclineDeals(){
        User[] admins = [Select Id,Name From User Where Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 2];
        Account acc = [Select Id,Name From Account where Name = 'TestAccount' LIMIT 1];
        Deal_Contract_Agreement__c dca = [SELECT ID,Status__c FROM Deal_Contract_Agreement__c LIMIT 1];
        
        //Profile profile1 = [SELECT Id, Name FROM Profile WHERE Name = 'DE - Seller Portal']; //MN-10062024-US-0015298
        
        Contact con = [SELECT Id,Email FROM Contact WHERE FirstName='test fn' AND LastName='test ln' limit 1];

        User user1 = null;
        System.runAs(admins[0])
        {
            
            PermissionSetGroup psgDE = [Select Id,DeveloperName From PermissionSetGroup Where PermissionSetGroup.DeveloperName ='Seller_Portal_DE'];

            user1 = SEPTestGenerator.createSEPUser('sepUsersdcac3', con.Id); //MN-10062024-US-0015298
            /* MN-10062024-US-0015298
            user1 = new User(
                Username = System.now().millisecond() + 'test12345_x777@test.com',
                ContactId = con.Id,
                ProfileId = profile1.Id,
                
                Alias = 'test177',
                Email = 'test12345_x777@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTestyx7',
                CommunityNickname = 'test12377',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                Hide_SP_Deals__c = 'No'
                );
            insert user1;
            */
            Database.insert(new PermissionSetAssignment(PermissionSetGroupId=psgDE.Id,AssigneeId=user1.Id),false);
        }
     

        Test.startTest();
           System.runAs(user1)
            {
                Date myDate = Date.today().addDays(5);
                // Test approve selected deal
                EBH_Deal__c deal1 = new EBH_Deal__c(Deal_Contract_Agreement__c=dca.Id,Hide_in_Seller_Portal__c=False,EBH_DealSiteId__c='101', RecordTypeId=ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id, EBH_BusinessName__c=acc.Id, EBH_MaximumPurchases__c =324,EBH_Quantity__c=500,EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.toDay().addDays(4),EBH_DealEndDate__c = myDate,EBH_Status__c='Sent to Seller' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_eBayItemID__c='123456789001');
                EBH_Deal__c deal2 = new EBH_Deal__c(Deal_Contract_Agreement__c=dca.Id,Hide_in_Seller_Portal__c=False,EBH_DealSiteId__c='101', RecordTypeId=ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id, EBH_BusinessName__c=acc.Id, EBH_MaximumPurchases__c =324,EBH_Quantity__c=500,EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.toDay().addDays(4),EBH_DealEndDate__c = myDate,EBH_Status__c='Sent to Seller' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_eBayItemID__c='123456789002');
                insert new List<EBH_Deal__c>{deal1,deal2};

                Map<String,Object> mapResult = SEPDealContractAgreementController.doApproveOrDeclineDeals(new List<String>{deal1.Id,deal2.Id},true,'','Seller Approved',acc.Id);
                System.assertEquals('success', mapResult.get('status'),mapResult);

                // Test approve all deal
                EBH_Deal__c deal3 = new EBH_Deal__c(Deal_Contract_Agreement__c=dca.Id,Hide_in_Seller_Portal__c=False,EBH_DealSiteId__c='101', RecordTypeId=ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id, EBH_BusinessName__c=acc.Id, EBH_MaximumPurchases__c =324,EBH_Quantity__c=500,EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.toDay().addDays(4),EBH_DealEndDate__c = myDate,EBH_Status__c='Sent to Seller' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_eBayItemID__c='123456789003');
                EBH_Deal__c deal4 = new EBH_Deal__c(Deal_Contract_Agreement__c=dca.Id,Hide_in_Seller_Portal__c=False,EBH_DealSiteId__c='101', RecordTypeId=ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id, EBH_BusinessName__c=acc.Id, EBH_MaximumPurchases__c =324,EBH_Quantity__c=500,EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.toDay().addDays(4),EBH_DealEndDate__c = myDate,EBH_Status__c='Sent to Seller' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_eBayItemID__c='123456789004');
                insert new List<EBH_Deal__c>{deal3,deal4};

                mapResult = SEPDealContractAgreementController.doApproveOrDeclineDeals(new List<String>(),false,'','Seller Approved',acc.Id);
                System.assertEquals('success', mapResult.get('status'));

                // Test decline selected deal
                EBH_Deal__c deal5 = new EBH_Deal__c(Deal_Contract_Agreement__c=dca.Id,Hide_in_Seller_Portal__c=False,EBH_DealSiteId__c='101', RecordTypeId=ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id, EBH_BusinessName__c=acc.Id, EBH_MaximumPurchases__c =324,EBH_Quantity__c=500,EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.toDay().addDays(4),EBH_DealEndDate__c = myDate,EBH_Status__c='Sent to Seller' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_eBayItemID__c='123456789005');
                EBH_Deal__c deal6 = new EBH_Deal__c(Deal_Contract_Agreement__c=dca.Id,Hide_in_Seller_Portal__c=False,EBH_DealSiteId__c='101', RecordTypeId=ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id, EBH_BusinessName__c=acc.Id, EBH_MaximumPurchases__c =324,EBH_Quantity__c=500,EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='CSA',EBH_DealStartDate__c=System.toDay().addDays(4),EBH_DealEndDate__c = myDate,EBH_Status__c='Sent to Seller' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_eBayItemID__c='123456789006');
                insert new List<EBH_Deal__c>{deal5,deal6};

                mapResult = SEPDealContractAgreementController.doApproveOrDeclineDeals(new List<String>{deal5.Id,deal6.Id},true,'Other','Seller Rejected',acc.Id);
                System.assertEquals('success', mapResult.get('status'));

                mapResult = SEPDealContractAgreementController.generateDealApprovedPDF(dca.Id);
                System.assertEquals('success', mapResult.get('status'));
                
            }

            Test.stopTest();
        
    }
    @IsTest
    static void testdoApproveOrDeclineSubsidizeDeals(){
        User[] admins = [Select Id,Name From User Where Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 2];
        Deal_Contract_Agreement__c dca = [SELECT ID,Status__c FROM Deal_Contract_Agreement__c LIMIT 1];
        Account acc = [Select Id,Name From Account where Name = 'TestAccount' LIMIT 1];
        //Profile profile1 = [SELECT Id, Name FROM Profile WHERE Name = 'DE - Seller Portal']; //MN-10062024-US-0015298
        
        Contact con = [SELECT Id,Email FROM Contact WHERE FirstName='test fn' AND LastName='test ln' limit 1];
		con.Contact_Role__c='Deals';
        update con;
        
        User user1 = null;
        System.runAs(admins[0])
        {
            
            PermissionSetGroup psgDE = [Select Id,DeveloperName From PermissionSetGroup Where PermissionSetGroup.DeveloperName ='Seller_Portal_NA'];

            user1 = SEPTestGenerator.createSEPUser('sepUsersdcac3', con.Id);
            Database.insert(new PermissionSetAssignment(PermissionSetGroupId=psgDE.Id,AssigneeId=user1.Id),false);
        }
        Test.startTest();
           System.runAs(user1)
            {
                Date myDate = Date.today().addDays(5);
                EBH_Deal__c deal1 = new EBH_Deal__c(Seller_Approver_1__c=con.Id,Deal_Contract_Agreement__c=dca.Id,Hide_in_Seller_Portal__c=False,EBH_DealSiteId__c='0', RecordTypeId=ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id, EBH_BusinessName__c=acc.Id, EBH_MaximumPurchases__c =324,EBH_Quantity__c=500,EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_DealStartDate__c=System.toDay().addDays(4),EBH_DealEndDate__c = myDate,EBH_Status__c='Sent to Seller' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_eBayItemID__c='123456789001');
                EBH_Deal__c deal2 = new EBH_Deal__c(Seller_Approver_1__c=con.Id,Deal_Contract_Agreement__c=dca.Id,Hide_in_Seller_Portal__c=False,EBH_DealSiteId__c='0', RecordTypeId=ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id, EBH_BusinessName__c=acc.Id, EBH_MaximumPurchases__c =324,EBH_Quantity__c=500,EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_DealStartDate__c=System.toDay().addDays(4),EBH_DealEndDate__c = myDate,EBH_Status__c='Sent to Seller' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_eBayItemID__c='123456789002');
                insert new List<EBH_Deal__c>{deal1,deal2};
                    
                //Approved ALL
                Map<String,Object> mapResult = SEPDealContractAgreementController.doApproveOrDeclineSubsidizeDeals(new List<String>(),false,'','Seller Approved',dca.Id,2);
                //System.assertEquals('success', mapResult.get('status'));
                
                EBH_Deal__c deal3 = new EBH_Deal__c(Seller_Approver_1__c=con.Id,Deal_Contract_Agreement__c=dca.Id,Hide_in_Seller_Portal__c=False,EBH_DealSiteId__c='0', RecordTypeId=ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id, EBH_BusinessName__c=acc.Id, EBH_MaximumPurchases__c =324,EBH_Quantity__c=500,EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_DealStartDate__c=System.toDay().addDays(4),EBH_DealEndDate__c = myDate,EBH_Status__c='Sent to Seller' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_eBayItemID__c='123456789003');
                EBH_Deal__c deal4 = new EBH_Deal__c(Seller_Approver_1__c=con.Id,Deal_Contract_Agreement__c=dca.Id,Hide_in_Seller_Portal__c=False,EBH_DealSiteId__c='0', RecordTypeId=ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id, EBH_BusinessName__c=acc.Id, EBH_MaximumPurchases__c =324,EBH_Quantity__c=500,EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_DealStartDate__c=System.toDay().addDays(4),EBH_DealEndDate__c = myDate,EBH_Status__c='Sent to Seller' ,EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_eBayItemID__c='123456789004');
                insert new List<EBH_Deal__c>{deal3,deal4};
                    
                //Rejected All
                mapResult = SEPDealContractAgreementController.doApproveOrDeclineSubsidizeDeals(new List<String>(),false,'Other','Seller Rejected',dca.Id,2);
                //System.assertEquals('success', mapResult.get('status'));
                
                Map<String,String> mapPicklist = SEPDealContractAgreementController.getSelectedSellerDeclineReason('Deal_Seller_Decline_Reason_US','EBH_Deal__c','Seller_Decline_Reason__c');
                //System.assert(mapPicklist.size()>0);
                    
            }
    }
}