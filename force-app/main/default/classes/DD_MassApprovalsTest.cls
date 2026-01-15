@isTest
private class DD_MassApprovalsTest {

    @testSetup static void setup() {

        List<User> admins = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' and isActive = true LIMIT 2];

    	byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
        
        Profile adminProfile = [select Id,Name from Profile where Name = 'System Administrator'];

        User approver1,approver2,merchant;
        System.runAs(admins[0]) {
            
            approver1 = new User();
            approver1.Alias='AMT';
            approver1.Email='amtmail@ebay.com';
            approver1.EmailEncodingKey='UTF-8';
            approver1.LastName='AMTUser';
            approver1.LanguageLocaleKey='en_US';
            approver1.LocaleSidKey='en_US';
            approver1.ProfileId = adminProfile.Id;
            approver1.TimeZoneSidKey='America/Los_Angeles';
            approver1.UserName='approver1@ebay.com';
            insert approver1;

            approver2 = new User();
            approver2.Alias='AMT';
            approver2.Email='amtmail@ebay.com';
            approver2.EmailEncodingKey='UTF-8';
            approver2.LastName='AMTUser';
            approver2.LanguageLocaleKey='en_US';
            approver2.LocaleSidKey='en_US';
            approver2.ProfileId = adminProfile.Id;
            approver2.TimeZoneSidKey='America/Los_Angeles';
            approver2.UserName='approver2@ebay.com';
            insert approver2;

            merchant = new User();
            merchant.Alias='AMT';
            merchant.Email='amtmail@ebay.com';
            merchant.EmailEncodingKey='UTF-8';
            merchant.LastName='AMTUser';
            merchant.LanguageLocaleKey='en_US';
            merchant.LocaleSidKey='en_US';
            merchant.ProfileId = adminProfile.Id;
            merchant.TimeZoneSidKey='America/Los_Angeles';
            merchant.UserName='amtmail@ebay.com';
            merchant.ProfileId=EBH_ConstantsUtility.ADMIN_PROFILE_ID;
            //merchant.Merchant_Approver__c = approver1.Id;
            //merchant.Director__c = approver2.Id;
            insert merchant;
        
        }
        //System.Debug('--- merchantuser'+merchant);

        Account acc = new Account();
        acc.Name            = 'Test Account Name: 1';
        acc.BillingCountry  = 'CH';
        insert acc;

        // Deal_Timezone__c dealTimezone = new Deal_Timezone__c();
        // dealTimezone.TimeZone__c='America/Los_Angeles';
        // insert dealTimezone;

        Account eBaySeller = new Account ();
        eBaySeller.Name                     = 'Test eBaySeller 1';
        eBaySeller.RecordTypeId             = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Seller').getRecordTypeId();
        //eBaySeller.Account__c               = acc.Id;
        //eBaySeller.Vertical_new__c          = 'Electronics';
        //eBaySeller.Seller_Status__c         = 'Active';
        //eBaySeller.GMV_Full_Yr_Goal__c      = 1500;
        //eBaySeller.Daily_Deals_Whitelist__c = true;
        //eBaySeller.Service_Model_Segment__c = 'Deals Only';
        //eBaySeller.Oracle_ID__c             = '123456';

        Account eBaySeller2 = new Account ();
        eBaySeller.RecordTypeId             = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Seller').getRecordTypeId();
        eBaySeller2.Name                     = 'Test eBaySeller 2';
        //eBaySeller2.Account__c               = acc.Id;
        //eBaySeller2.Vertical_new__c          = 'Electronics';
        //eBaySeller2.Seller_Status__c         = 'Active';
        //eBaySeller2.GMV_Full_Yr_Goal__c      = 1500;
        //eBaySeller2.Daily_Deals_Whitelist__c = true;
        //eBaySeller2.Service_Model_Segment__c = 'Deals Only';
        //eBaySeller2.Oracle_ID__c             = '123467';

        Account eBaySeller3 = new Account ();
        eBaySeller.RecordTypeId              = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Seller').getRecordTypeId();
        eBaySeller3.Name                     = 'Test eBaySeller 3';
        //eBaySeller3.Account__c               = acc.Id;
        //eBaySeller3.Vertical_new__c          = 'Electronics';
        //eBaySeller3.Seller_Status__c         = 'Active';
        //eBaySeller3.GMV_Full_Yr_Goal__c      = 1500;
        //eBaySeller3.Daily_Deals_Whitelist__c = true;
        //eBaySeller3.Service_Model_Segment__c = 'Deals Only';
        //eBaySeller3.Oracle_ID__c             = '123437';

        insert new List<Account>{eBaySeller,eBaySeller2,eBaySeller3};
        
        RecordType contactRecordTYpe = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
        /* //MN:13/05/2021:US-0009542 - [NA] Deals: Remove unused value from 'Decision Maker Role' on Contact
        Contact con = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = eBaySeller.Id, EBH_Decision_Maker_Role__c = 'Deals',recordtypeId = contactRecordTYpe.Id); */
        
        //MN:13/05/2021:US-0009542 - Use Contact_Role__c instead
        Contact con = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                    FirstName='firstname',Salutation='Mr.',LastName='test1',
                                    email='test1@test.com' , AccountId = eBaySeller.Id, Contact_Role__c = 'Deals',recordtypeId = contactRecordTYpe.Id);                              
        insert con;
        
        //Id spotRecordTypeId = Schema.SObjectType.EBH_SpotlightCategory__c.getRecordTypeInfosByName().get('eBay NA Spotlight Categories').getRecordTypeId();
        EBH_SpotlightCategory__c spotCat = new EBH_SpotlightCategory__c();
        //spotCat.RecordTypeId             = spotRecordTypeId;
        spotCat.Name                         = 'test spotLightCat';
        spotCat.EBH_Country__c               = 'NA';
        spotCat.EBH_SpotlightCategoryID__c   = 'testSpotId';

        EBH_SpotlightCategory__c spotCat2 = new EBH_SpotlightCategory__c();
        //spotCat2.RecordTypeId             = spotRecordTypeId;
        spotCat2.Name                         = 'test spotLightCat2';
        spotCat2.EBH_Country__c               = 'NA';
        spotCat2.EBH_SpotlightCategoryID__c   = 'testSpotId';

        EBH_SpotlightCategory__c spotCat3 = new EBH_SpotlightCategory__c();
        //spotCat3.RecordTypeId             = spotRecordTypeId;
        spotCat3.Name                         = 'test spotLightCat3';
        spotCat3.EBH_Country__c               = 'NA';
        spotCat3.EBH_SpotlightCategoryID__c   = 'testSpotId';

        insert new List<EBH_SpotlightCategory__c>{spotCat,spotCat2,spotCat3};

        //MN-17082022-US-0011119-Remove reference with old record type name
        // Id devRecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('NA Deal').getRecordTypeId();
        RecordType subDealRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2');
        Id devRecordTypeId = subDealRecordType.Id;
        
        Date myDate = System.today();

        EBH_Deal__c d1 = new EBH_Deal__c();

        d1.EBH_eBayItemID__c        = '000000000010';
        d1.OwnerId                = merchant.Id;
        d1.Merchant_Approver__c   = merchant.Id;
        d1.EBH_SpotlightCategory__c  = spotCat.Id;
        d1.EBH_BusinessName__c         = eBaySeller.Id;
        d1.RecordTypeId           = devRecordTypeId;
        d1.EBH_SellerPrice__c        = 20;
        d1.EBH_DealPrice__c          = 5;
        d1.EBH_Quantity__c            = 2;
        d1.EBH_DealStartDate__c     = myDate+1;
        d1.EBH_DealEndDate__c       = myDate+1;
        d1.EBH_Status__c              = 'In Approval';
        d1.EBH_Vertical__c            = 'Business & Industrial';
        d1.EBH_Category__c            = 'Health & Beauty';
        d1.EBH_ProductTitle__c       = 'product 1';
        d1.EBH_SellerEmail__c        = 'sales@test.com';
        d1.EBH_SoldItemsForecast__c = 123456;
        d1.EBH_SoldItemsForecast__c   = 1000000;
        d1.EBH_DealSiteId__c = '3';
        d1.Seller_Approver_1__c = con.Id;
        
        EBH_Deal__c d2 = new EBH_Deal__c();
        d2.EBH_eBayItemID__c        = '000000000010';
        d2.OwnerId                = merchant.Id;
        d2.Merchant_Approver__c   = merchant.Id;
        d2.EBH_SpotlightCategory__c  = spotCat.Id;
        d2.EBH_BusinessName__c         = eBaySeller.Id;
        d2.RecordTypeId           = devRecordTypeId;
        d2.EBH_SellerPrice__c        = 20;
        d2.EBH_DealPrice__c          = 5;
        d2.EBH_Quantity__c            = 2;
        d2.EBH_DealStartDate__c     = myDate+2;
        d2.EBH_DealEndDate__c       = myDate+2;
        d2.EBH_Status__c              = 'In Approval';
        d2.EBH_Vertical__c            = 'Business & Industrial';
        d2.EBH_Category__c            = 'Health & Beauty';
        d2.EBH_ProductTitle__c       = 'product 2';
        d2.EBH_SellerEmail__c        = 'sales@test.com';
        d2.EBH_SoldItemsForecast__c = 123456;
        d2.EBH_SoldItemsForecast__c   = 1000000;
        d2.EBH_DealSiteId__c = '3';
        d2.Seller_Approver_1__c = con.Id;
        
        EBH_Deal__c d3 = new EBH_Deal__c();
        d3.EBH_eBayItemID__c        = '000000000010';
        d3.OwnerId                = merchant.Id;
        d3.Merchant_Approver__c   = merchant.Id;
        d3.EBH_SpotlightCategory__c  = spotCat.Id;
        d3.EBH_BusinessName__c         = eBaySeller.Id;
        d3.RecordTypeId           = devRecordTypeId;
        d3.EBH_SellerPrice__c        = 20;
        d3.EBH_DealPrice__c          = 5;
        d3.EBH_Quantity__c            = 2;
        d3.EBH_DealStartDate__c     = myDate+3;
        d3.EBH_DealEndDate__c       = myDate+3;
        d3.EBH_Status__c              = 'In Approval';
        d3.EBH_Vertical__c            = 'Business & Industrial';
        d3.EBH_Category__c            = 'Health & Beauty';
        d3.EBH_ProductTitle__c       = 'product 3';
        d3.EBH_SellerEmail__c        = 'sales@test.com';
        d3.EBH_SoldItemsForecast__c = 123456;
        d3.EBH_SoldItemsForecast__c   = 1000000;
        d3.EBH_DealSiteId__c = '3';
        d3.Seller_Approver_1__c = con.Id;
        
        List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>{d1,d2,d3};
        insert lstDeal;
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        //System.debug('<<<<<selected deal: '+[select id from EBH_Deal__c where EBH_BusinessName__r.Name like: 'Test eBaySeller%']);
        for(EBH_Deal__c deal : [select id,OwnerId,Merchant_Approver__c from EBH_Deal__c where EBH_BusinessName__r.Name like: 'Test eBaySeller%']){
            //System.debug('<<<<<deal.OwnerId='+deal.OwnerId);
            //System.debug('------ Merchant_Approver__c ::: ' + deal.Merchant_Approver__c + '-----' + mApproverId());
            // Create an approval request for the Deal
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Submitted for approval. Please approve.');
            req.setObjectId(deal.Id);
            req.setSubmitterId(merchant.Id);
            //req.setProcessDefinitionNameOrId('DD_AP_Deal_Fashion');
            req.setProcessDefinitionNameOrId('DD_AP_Deal_Fashion_V2');
            req.setSkipEntryCriteria(true);
            requests.add(req);
            //System.debug('<<<<<requests='+requests);
        }
        if(!requests.isEmpty()){
            Approval.ProcessResult[] processResults = null;
            processResults = Approval.process(requests, true);
            for(Approval.ProcessResult result: processResults){
                System.assert(result.isSuccess());
                System.assertEquals('Pending', result.getInstanceStatus(),'Instance Status'+result.getInstanceStatus());
            }
        }

    }

    private static Id mApproverId() {
        return  [Select id From User Where username = 'amtmail@ebay.com'].Id;
    }
    private static Id mQueueId() {
        return [Select Id FROM Group WHERE Type='Queue' LIMIT 1][0].Id;
    }

    @isTest
    public static void test_DD_MassApprovalsConstruc(){
        Test.startTest();
            PageReference pageRef = Page.DD_MassApprovals;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('object','EBH_Deal__c');
            ApexPages.currentPage().getParameters().put('recordtype','Deal_V2');
            DD_MassApprovals ddMassApprov = new DD_MassApprovals();
        Test.stopTest();
        System.assertEquals('EBH_Deal__c',ddMassApprov.objectName);
        System.assertEquals('Deal_V2',ddMassApprov.recordType);
    }

    // Last process of approval, user is queue
    private static void approve_deal_2steps() {
        // Approval Step 1
        requestApprovalSubmitDeal();
        // Approval Step 2
        requestApprovalSubmitDeal();
    }

    private static void requestApprovalSubmitDeal () {
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        Set<Id> sDeal = new Set<Id>();
        for (EBH_Deal__c deal : [SELECT Id FROM EBH_Deal__c]) {
            sDeal.add(deal.Id);
        }

        List<ProcessInstanceWorkitem> workItemLst = [SELECT Id FROM ProcessInstanceWorkitem WHERE processInstance.TargetObjectId IN:sDeal AND ProcessInstance.Status = 'Pending'];
        for (ProcessInstanceWorkitem piwi : workItemLst) {
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setComments( 'Automatic approval request.' );
            req.setAction('Approve');
            req.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            req.setWorkitemId(piwi.Id);
            Approval.process(req);
        }
    }

    @isTest
    public static void test_initData(){
        Test.startTest();
            System.runAs(new User(Id = mApproverId())) {
                Map<String, Object> mapResult = DD_MassApprovals.initData('EBH_Deal__c','Deal_V2', 'Mass_Approval_Table_Columns','EBH_BusinessName__c',true,'');
                System.debug('mapResult>>>'+mapResult);
                DD_MassApprovals.fetchRecordType();
                //System.debug('<<<<<<mapResult='+mapResult);
                List<DD_MassApprovals.ItemWrapper> ListDealWrapper = (List<DD_MassApprovals.ItemWrapper>) mapResult.get('ListDealWrapper');
                String massAppCol = String.valueOf(mapResult.get('Mass_Approval_Table_Columns'));
                System.debug('massAppCol>>>'+massAppCol);
                massAppCol.removeStart('[');
                massAppCol.removeEnd(']');
                //System.debug('<<<<<<ListDealWrapper='+ListDealWrapper);
                //System.debug('<<<<<<ListDealWrapper Size='+ListDealWrapper.size());
                System.assert(ListDealWrapper.size() == 3);
                System.assert(!String.isEmpty(massAppCol));
                try {
                    DD_MassApprovals.initData(null, null, null, null, true,'');
                } catch(Exception e) {
                    System.debug('e.msg>>>'+e.getMessage());
                }
            }
        Test.stopTest();
    }

    /*@isTest
    public static void test_initData_Approve2Steps(){
        Test.startTest();
            System.runAs(new User(Id = mApproverId())) {
                approve_deal_2steps();
                Map<String, Object> mapResult = DD_MassApprovals.initData('Deal__c','Deal_V2', 'Mass_Approval_Table_Columns','EBH_BusinessName__c',true);
                System.debug('<<<<<<mapResult='+mapResult);
                List<DD_MassApprovals.ItemWrapper> ListDealWrapper = (List<DD_MassApprovals.ItemWrapper>) mapResult.get('ListDealWrapper');
                String massAppCol = String.valueOf(mapResult.get('Mass_Approval_Table_Columns'));
                massAppCol.removeStart('[');
                massAppCol.removeEnd(']');
                System.assert(!String.isEmpty(massAppCol));
                try {
                    DD_MassApprovals.initData(null, null, null, null, true);
                } catch(Exception e) {

                }
            }
        Test.stopTest();
    }*/

    @isTest
    public static void test_approveRecords(){
        Test.startTest();
        //System.debug('mApproverId()>>>'+mApproverId());
            System.runAs(new User(Id = mApproverId())) {
                Set<Id> allRecordIds = new Set<Id>();
                List<DD_MassApprovals.ItemWrapper> lstWrapper = DD_MassApprovals.loadData('EBH_Deal__c','Deal_V2','Mass_Approval_Table_Columns','EBH_BusinessName__c',true,allRecordIds,'');
                System.debug('lstWrapper>>>'+lstWrapper);
                for(DD_MassApprovals.ItemWrapper itemWrapper : lstWrapper){
                    itemWrapper.checked = true;
                }
                String jsonitems = JSON.serialize(lstWrapper);

                //System.debug('------------------------------ListDealWrapper='+lstWrapper);
                String approve = DD_MassApprovals.approveRecords(jsonitems,'EBH_Deal__c');
                try {
                    DD_MassApprovals.approveRecords(null,'EBH_Deal__c');
                }catch (Exception e) {

                }
                System.assertEquals('Approve',approve);
            }
        Test.stopTest();
    }
    @isTest
    public static void test_rejectRecords(){
        Set<Id> allRecordIds = new Set<Id>();
        List<DD_MassApprovals.ItemWrapper> lstWrapper = DD_MassApprovals.loadData('EBH_Deal__c','Deal_V2','Mass_Approval_Table_Columns','EBH_BusinessName__c',true,allRecordIds,'');
        for(DD_MassApprovals.ItemWrapper itemWrapper : lstWrapper){
            itemWrapper.checked = true;
        }
        String jsonitems = JSON.serialize(lstWrapper);
        Test.startTest();
            String reject = DD_MassApprovals.rejectRecords(jsonitems,'EBH_Deal__c');
            try {
                DD_MassApprovals.rejectRecords(null,'EBH_Deal__c');
            }catch (Exception e) {

            }
        Test.stopTest();
        System.assertEquals('Reject',reject);
    }




    /*********************************************************************************************************************************
    @ Method:         test_approveRecordsWithAllApprovers
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008618
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  18.11.2020 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    @isTest 
    public static void test_approveRecordsWithAllApprovers(){
        
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

            //dealGroup = [Select Id From Group Where DeveloperName='Daily_Deals_Finance' Limit 1];//LA-10-08-2023-US-0013318
            dealGroup = [Select Id From Group Where DeveloperName='US_Deals_Contract_Approvers' Limit 1];//LA-10-08-2023-US-0013318

            gMember = new GroupMember();
            gMember.UserOrGroupId = u1.Id;
            gMember.GroupId = dealGroup.Id;
            Insert gMember;
        }
        

        Account ac = new Account(Name='Seller',EBH_VATNumber__c='1122334455');
        ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
        insert ac;
        
        RecordType contactRecordTYpe = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
        /* //MN:13/05/2021:US-0009542 - [NA] Deals: Remove unused value from 'Decision Maker Role' on Contact
        Contact con = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = ac.Id, EBH_Decision_Maker_Role__c = 'Deals',recordtypeId = contactRecordTYpe.Id);*/
        
        //MN:13/05/2021:US-0009542 - Use Contact_Role__c instead
        Contact con = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                    FirstName='firstname',Salutation='Mr.',LastName='test1',
                                    email='test1@test.com' , AccountId = ac.Id, Contact_Role__c = 'Deals',recordtypeId = contactRecordTYpe.Id);
        insert con;
        
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c();
        insert sc;
        
        Id dealNARecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByDeveloperName().get('Deal_V2').getRecordTypeId();

        

        EBH_Deal__c d1 = new EBH_Deal__c(
            EBH_DealStartTime__c= System.now().time(), 
            EBH_DealStartDate__c=System.toDay().addDays(1),
            EBH_eBayItemID__c='123456789010',
            EBH_BusinessName__c=ac.Id,
            EBH_SpotlightCategory__c=sc.Id,
            EBH_Vertical__c='Business & Industrial',
            EBH_Category__c = 'Health & Beauty',
            EBH_DealEndDate__c = System.toDay().addMonths(2),
            EBH_Status__c= 'New' ,
            EBH_ProductTitle__c='product 2',
            EBH_SellerPrice__c = 1000001,
            EBH_DealPrice__c = 1,
            EBH_Quantity__c=1,
            RecordTypeId = dealNARecordTypeId,
            Merchant_Approver__c = admin.Id,
            Director__c = admin.Id,
            Seller_Approver_1__c = con.Id,
            EBH_DealSiteId__c = '3'
        );
		EBH_Deal__c d2 = new EBH_Deal__c(
            EBH_DealStartTime__c= System.now().time(), 
            EBH_DealStartDate__c=System.toDay().addDays(1),
            EBH_eBayItemID__c='123456789021',
            EBH_BusinessName__c=ac.Id,
            EBH_SpotlightCategory__c=sc.Id,
            EBH_Vertical__c='Business & Industrial',
            EBH_Category__c = 'Health & Beauty',
            EBH_DealEndDate__c = System.toDay().addMonths(2),
            EBH_Status__c='New' ,
            EBH_ProductTitle__c='product 2',
            EBH_SellerPrice__c = 1000001,
            EBH_DealPrice__c = 1,
            EBH_Quantity__c=1,
            RecordTypeId = dealNARecordTypeId,
            Merchant_Approver__c = admin.Id,
            Director__c = admin.Id,
            Seller_Approver_1__c = con.Id,
            EBH_DealSiteId__c = '3'
        );

        EBH_Deal__c d3 = new EBH_Deal__c(
            EBH_DealStartTime__c= System.now().time(), 
            EBH_DealStartDate__c=System.toDay().addDays(1),
            EBH_eBayItemID__c='123456789032',
            EBH_BusinessName__c=ac.Id,
            EBH_SpotlightCategory__c=sc.Id,
            EBH_Vertical__c='Business & Industrial',
            EBH_Category__c = 'Health & Beauty',
            EBH_DealEndDate__c = System.toDay().addMonths(2),
            EBH_Status__c='New' ,
            EBH_ProductTitle__c='product 2',
            EBH_SellerPrice__c = 1000001,
            EBH_DealPrice__c = 1,
            EBH_Quantity__c=1,
            RecordTypeId = dealNARecordTypeId,
            Merchant_Approver__c = admin.Id,
            Director__c = admin.Id,
            Seller_Approver_1__c = con.Id,
            EBH_DealSiteId__c = '3'
        );

        EBH_Deal__c d4 = new EBH_Deal__c(
            EBH_DealStartTime__c= System.now().time(), 
            EBH_DealStartDate__c=System.toDay().addDays(1),
            EBH_eBayItemID__c='123456789043',
            EBH_BusinessName__c=ac.Id,
            EBH_SpotlightCategory__c=sc.Id,
            EBH_Vertical__c='Business & Industrial',
            EBH_Category__c = 'Health & Beauty',
            EBH_DealEndDate__c = System.toDay().addMonths(2),
            EBH_Status__c='New' ,
            EBH_ProductTitle__c='product 2',
            EBH_SellerPrice__c = 1000001,
            EBH_DealPrice__c = 1,
            EBH_Quantity__c=1,
            RecordTypeId = dealNARecordTypeId,
            Merchant_Approver__c = admin.Id,
            Director__c = admin.Id,
            Seller_Approver_1__c = con.Id,
            EBH_DealSiteId__c = '3'
        );

        List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>{d1,d2,d3,d4};
           
       
    
        System.runAs(admin){

            insert lstDeal;

            PageReference ref = new PageReference('/apex/SubmitForApprovalPage');
            Test.setCurrentPage(ref);
            
            ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstDeal);
            ssc.setSelected(lstDeal);
            
            SubmitForApprovalController controller = new SubmitForApprovalController(ssc);
            // controller.submitForApproval(); //Sophal:06/04/2021:US-0009353
            //Sophal:06/04/2021:US-0009353
            // SubmitForApprovalController.submitForApproval(controller.lstSelDid, controller.dealNARecordTypeId, new List<Id>());
            controller.submitForApproval(); // Sophal: 11.08.2021 : US-0009771
            controller.cancel();
            
            Set<Id> allRecordIds = new Set<Id>();
            List<DD_MassApprovals.ItemWrapper> lstWrapper = DD_MassApprovals.loadData('EBH_Deal__c','Deal_V2','Mass_Approval_Table_Columns','EBH_BusinessName__c',false, allRecordIds,'');
            System.debug('lstWrapper>>>'+lstWrapper);
            System.assertEquals(4,lstWrapper.size());
            for(DD_MassApprovals.ItemWrapper itemWrapper : lstWrapper){
                itemWrapper.checked = true;
            }
            String jsonitems = JSON.serialize(lstWrapper);
    
            //System.debug('------------------------------ListDealWrapper='+lstWrapper);
            Test.startTest();
            String approve = DD_MassApprovals.approveRecords(jsonitems,'EBH_Deal__c');
            Test.stopTest();
            System.assertEquals('Approve',approve);
        }
            

    }

    @isTest 
    public static void test_approveRecordsCaAndFinanceApprover(){
        
        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        User u1;
        User u2;

        Group dealGroup1;
        GroupMember gMember1;

        Group dealGroup2;
        GroupMember gMember2;

        Group dealGroup3;
        GroupMember gMember3;

        System.runAs(admin){
            
            Profile p = [select id from Profile where name='NA Standard User Base' limit 1];
            u1 = new User(alias = 'testApr1', email='testApr1@ebay.com', 
                            emailencodingkey='UTF-8', lastname='approver1', firstname='test', languagelocalekey='en_US', 
                            localesidkey='en_US', profileid = p.Id, 
                            timezonesidkey='America/Los_Angeles', username='TestsubApprov@salesforce.de', isActive = true);

            u2 = new User(alias = 'testApr2', email='testsubApprov2@ebay.com', 
            emailencodingkey='UTF-8', lastname='approver2', firstname='test', languagelocalekey='en_US', 
            localesidkey='en_US', profileid = p.Id, 
            timezonesidkey='America/Los_Angeles', username='testApr2@ebay.com', isActive = true);

            insert new List<User>{u1,u2};

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

            //dealGroup2 = [Select Id From Group Where DeveloperName='Daily_Deals_Finance' Limit 1];
            dealGroup2 = [Select Id From Group Where DeveloperName='US_Deals_Contract_Approvers' Limit 1];
            gMember2 = new GroupMember();
            gMember2.UserOrGroupId = u2.Id;
            gMember2.GroupId = dealGroup2.Id;
            Insert gMember2;
            
            dealGroup3 = [Select Id From Group Where DeveloperName='CA_Deals_Financial_Approvers' Limit 1];
            gMember3 = new GroupMember();
            gMember3.UserOrGroupId = u2.Id;
            gMember3.GroupId = dealGroup2.Id;
            Insert gMember3;

        }
        

        Account ac = new Account(Name='Seller',EBH_VATNumber__c='1122334455');
        ac.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
        insert ac;
        
        RecordType contactRecordTYpe = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
        
        Contact con = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                    FirstName='firstname',Salutation='Mr.',LastName='test1',
                                    email='test1@test.com' , AccountId = ac.Id, Contact_Role__c = 'Deals',recordtypeId = contactRecordTYpe.Id);
        insert con;
        
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c();
        insert sc;
        
        Id dealNARecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByDeveloperName().get('Deal_V2').getRecordTypeId();

        Date startDate = System.today().addMonths(1).toStartOfMonth(); // 1st day of next month
        Date endDate = startDate.addMonths(1).addDays(-1); // last day of next month
        EBH_Deal__c d1 = new EBH_Deal__c(
            EBH_DealStartTime__c= System.now().time(), 
            EBH_DealStartDate__c = startDate,
            EBH_eBayItemID__c='123456789010',
            EBH_BusinessName__c=ac.Id,
            EBH_SpotlightCategory__c=sc.Id,
            EBH_Vertical__c='Business & Industrial',
            EBH_Category__c = 'Health & Beauty',
            EBH_DealEndDate__c = endDate,
            EBH_Status__c= 'New' ,
            EBH_ProductTitle__c='product 2',
            EBH_SellerPrice__c = 1000001,
            EBH_DealPrice__c = 1,
            EBH_Quantity__c=1,
            RecordTypeId = dealNARecordTypeId,
            Seller_Approver_1__c = con.Id,
            EBH_DealSiteId__c = '2'
        );
		EBH_Deal__c d2 = new EBH_Deal__c(
            EBH_DealStartTime__c= System.now().time(), 
            EBH_DealStartDate__c = startDate,
            EBH_eBayItemID__c='123456789021',
            EBH_BusinessName__c=ac.Id,
            EBH_SpotlightCategory__c=sc.Id,
            EBH_Vertical__c='Business & Industrial',
            EBH_Category__c = 'Health & Beauty',
            EBH_DealEndDate__c = endDate,
            EBH_Status__c='New' ,
            EBH_ProductTitle__c='product 2',
            EBH_SellerPrice__c = 1000001,
            EBH_DealPrice__c = 1,
            EBH_Quantity__c=1,
            RecordTypeId = dealNARecordTypeId,
            Seller_Approver_1__c = con.Id,
            EBH_DealSiteId__c = '2'
        );

        List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>{d1,d2};
           
        System.runAs(admin){

            insert lstDeal;

            PageReference ref = new PageReference('/apex/SubmitForApprovalPage');
            Test.setCurrentPage(ref);
            
            ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstDeal);
            ssc.setSelected(lstDeal);
            
            SubmitForApprovalController controller = new SubmitForApprovalController(ssc);

            // SubmitForApprovalController.submitForApproval(controller.lstSelDid, controller.dealNARecordTypeId, new List<Id>());
            controller.submitForApproval(); // Sophal: 11.08.2021 : US-0009771
            controller.cancel();

            List<ProcessInstanceWorkItem> workItems = [SELECT ActorId,OriginalActorId, ProcessInstance.TargetObjectId,ProcessInstance.Status FROM ProcessInstanceWorkItem WHERE ProcessInstance.Status in ('Pending') and ProcessInstance.TargetObjectId IN: lstDeal Order By ProcessInstance.TargetObjectId ASC];
            System.assert(workItems.size() == 2);

            System.assertEquals(workItems[0].OriginalActorId,dealGroup1.Id);
            System.assertEquals(workItems[1].OriginalActorId,dealGroup1.Id);

            Test.startTest();

                System.runAs(u1){

                    Set<Id> allRecordIds = new Set<Id>();
                    List<DD_MassApprovals.ItemWrapper> lstWrapper = DD_MassApprovals.loadData('EBH_Deal__c','Deal_V2','Mass_Approval_Table_Columns','EBH_BusinessName__c',false, allRecordIds,'');
                    System.assertEquals(2,lstWrapper.size());
                    for(DD_MassApprovals.ItemWrapper itemWrapper : lstWrapper){
                        itemWrapper.checked = true;
                    }
                    String jsonitems = JSON.serialize(lstWrapper);
        
                    
                        String approve = DD_MassApprovals.approveRecords(jsonitems,'EBH_Deal__c');
        
                        workItems = [SELECT ActorId,OriginalActorId, ProcessInstance.TargetObjectId,ProcessInstance.Status FROM ProcessInstanceWorkItem WHERE ProcessInstance.Status in ('Pending') and ProcessInstance.TargetObjectId IN: lstDeal Order By ProcessInstance.TargetObjectId ASC];
                        System.assert(workItems.size() == 2);

                        //System.assertEquals(workItems[0].OriginalActorId,dealGroup2.Id);
                        //System.assertEquals(workItems[1].OriginalActorId,dealGroup2.Id);
                        System.assertEquals(workItems[0].OriginalActorId,dealGroup3.Id);
                        System.assertEquals(workItems[1].OriginalActorId,dealGroup3.Id);

                }
            
            Test.stopTest();

  
        }
            

    }



}