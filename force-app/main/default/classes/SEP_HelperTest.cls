@isTest
private class SEP_HelperTest {
    
    @TestSetup
    static void makeData(){
        
        insert new SEPWindowAlert__c(SetupOwnerId=UserInfo.getOrganizationId(), Deploying__c=true);

        EBH_TestDataFactory.setUpCustomSettings();

    	//create an account
        Account acc = new Account( Name = 'TestAccount' ,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102', EBH_RevRollup__c = 'US');
        insert acc;

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,
                                    FirstName='test fn', LastName='test ln', AccountId=acc.Id, Email = 'test123@test.com');
        insert con;
        
        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
        RecordType couponRecordTypeCat = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_CATEGORYBASE);
        Coupon__c c1 = new Coupon__c(Coupon_ID__c = 'TestCouponID', Marketing_Coupon_Name__c = 'Test Marketing Coupon Name', Main_Coupon_Site__c = 'ebay.com',MC_Whitelisted__c = true,Stage__c = 'Draft', RecordTypeID = couponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1);
        insert new List<Coupon__c>{c1};

        RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
        Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Seller_Contact__c=con.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc.Id,RecordTypeID=manhattanCouponSellerRecordType.Id);
        insert cs1;

    }

    @IsTest 
    static void test_initRecordInfo() {

        Test.startTest();
            
            Coupon_Seller__c cs1 = [SELECT ID FROM Coupon_Seller__c LIMIT 1];

            Map<String, Object> mResult = SEP_Helper.initRecordInfo(cs1.Id, '', '');

            System.assert( !mResult.isEmpty(), 'There should be data in the result.');

            
        Test.stopTest();
    }

    @IsTest 
    static void test_getProfileMappingMetaName() {

        Test.startTest();

            String result = SEP_Helper.getProfileMappingMetaName();

            System.assert(String.isNotBlank(result), 'The return value should not be null.');

        Test.stopTest();
    }

    @isTest
    static void test_getPortalDomain() {

        Test.startTest();

            Map<String, Object> mResult = SEP_Helper.getPortalFooter('eBay Seller Portal');

            System.assert(!mResult.isEmpty(), 'The return value should not be null.');

        Test.stopTest();
    }

    //MN-11062024-US-0015298
    @isTest
    static void test_getSEPUser() {

        User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 2];
        Account portalAccount1;
        Contact contact1;
        User sepUser;
        System.runAs(admins[0])
        {
            //Create account
            portalAccount1 = SEPTestGenerator.prepareAccountRecord('Portal Seller', null, 'test_test_test', SEP_Helper.SEP_Domain_NA, null, null, null);
            insert portalAccount1;

            RecordType recSP = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
            contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'Portal Contact',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test1@test.com',
                RecordTypeId=recSP.Id
            );
            insert contact1;
        }
        System.runAs(admins[1])
        {
            //Create user
            sepUser = SEPTestGenerator.createSEPUser('sepUsersh1', contact1.Id);
            
        }

        Test.startTest();

        System.runAs(sepUser)
        {
            //Create user
            SEP_Helper.SEPUser su = SEP_Helper.sepUser;

            System.assert( su.isNA(), 'The user should be NA.');
            System.assert( !su.isAU(), 'The user should not be AU.');
            System.assert( !su.isDE(), 'The user should not be DE.');
            System.assert( !su.isUK(), 'The user should not be UK.');
            System.assert( !su.isFR(), 'The user should not be FR.');
            System.assert( !su.isIT(), 'The user should not be IT.');
            System.assert( !su.isEU(), 'The user should not be EU.');
            
        }

        Test.stopTest();
    }

    /*****************************************************************************************************************************
    @ Method:   testActiveGSDAccMgnCohort
    @ Version:  1.0
    @ Author:   Sophal Noch
    @ Purpose:  04.07.2025 / Sophal Noch / US-0033064 - Limiting paid programs visibility to only existing subscribers
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  04.07.2025 / Sophal Noch / US-0033064 / Created the Method.
    *****************************************************************************************************************************/
    @isTest
    static void testIsGSDAccMgnEligible(){
        // 04.07.2025 / Sophal Noch / US-0033064 : test method to when GSD Account Management is eligible for seller facing
        
        User currentUser = [Select Id From User Where Id = : UserInfo.getUserId() And IsActive = true Limit 1];
        System.runAs(currentUser){ 
            currentUser.Calendly__CalendlyLink__c = 'ebay.com';
            ApexSafe.dml().secCheck(false).doUpdate(new List<User>{currentUser}, true);
        } 

        List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');

        Date today = Date.today();

        RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort');
        BoB__c lttmBob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='77',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id, Managed_Type__c = 'Managed BoB', Registration_Start_Date__c = today.addDays(1), RegistrationCloseDate__c =  today.addDays(6));
        ApexSafe.dml().secCheck(false).doInsert(new List<BoB__c>{lttmBob}, true);

        RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        BoB_Seller__c lttmBobSeller1 = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=lttmBob.Id, Seller__c=sellers[0].Id, EBH_BOBSegment__c = 'Enterprise', Account_Manager__c = currentUser.Id);
        ApexSafe.dml().secCheck(false).doInsert(new List<BoB_Seller__c>{lttmBobSeller1}, true);

        Test.startTest();
            lttmBob.Status__c = 'BoB Active';
            ApexSafe.dml().secCheck(false).doUpdate(new List<BoB__c>{lttmBob}, true);

            lttmBobSeller1.EBH_BOBSegment__c = 'Enterprise';
            lttmBobSeller1.Status__c = 'Draft';
            ApexSafe.dml().secCheck(false).doUpdate(new List<BOB_Seller__c>{lttmBobSeller1}, true);
        Test.stopTest();

        List<BoB_Seller__c> listBs = (List<BoB_Seller__c>)ApexSafe.query().secCheck(false).doQuery('Select Id, RecordTypeId, Managed_Type__c, EBH_BOBSegment__c, Status__c, BoB_Country__c From BoB_Seller__c Where Id =:bobSellerId', new Map<String, Object> {'bobSellerId' => lttmBobSeller1.Id});

        Boolean isEligible = SEP_Helper.isGSDAccMgnEligible(listBs[0]);
        System.assert(isEligible, 'The cohort seller should be eligible for GSD Account Management.');
    }
}