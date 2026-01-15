@isTest
private  class SEPCouponContractDownloadControllerTest {

    @TestSetup
    static void makeData(){
         
        EBH_TestDataFactory.setUpCustomSettings();

    	//create an account
        Account acc = new Account( EBH_RevRollup__c='US', Name = 'TestAccount', SP_Coupons__c='Full Access', SP_Main_Domain__c = SEP_Helper.SEP_Domain_NA);
        insert acc;

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,
                                    FirstName='test fn', LastName='test ln', AccountId=acc.Id, Email = 'test123@test.com');
        insert con;
        
        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
        RecordType couponRecordTypeCat = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_CATEGORYBASE);
        Coupon__c c1 = new Coupon__c(Coupon_ID__c='SALE16',Main_Coupon_Site__c = 'ebay.com',MC_Whitelisted__c = true,Stage__c = 'Draft', RecordTypeID = couponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1);
        insert new List<Coupon__c>{c1};

        RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
        Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Review', Seller_Contact__c=con.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc.Id,RecordTypeID=manhattanCouponSellerRecordType.Id);
        insert cs1;

        List<Coupon_Co_Invest__c> lstCCI = new List<Coupon_Co_Invest__c>();
            Id cciRT = Schema.SObjectType.Coupon_Co_Invest__c.getRecordTypeInfosByName().get('Coupon Co-Invest Item').getRecordTypeId();

            lstCCI.add(new Coupon_Co_Invest__c(
                Coupon_Seller__c = cs1.Id,
                Seller_Name__c = acc.Id,
                Co_Invest__c = 10,
                CurrencyIsoCode = 'USD',
                RecordtypeId = cciRT
            ));

            // Object result = ClsBulkUploadCSV.doSubmitMultipleCouponItems(lstCCI, 'Item Based');
            insert lstCCI;
            
    }

    @IsTest
    static void testDownload(){
   
        Coupon_Seller__c cs1 = [Select Id,Name, Coupon_ID__c, Coupon_Start_Date__c, Coupon_End_Date__c, Legal_Entity_Name_w__c, Legal_Entity_Street_w__c, Legal_Entity_Zip_w__c, Seller__r.Parent.EBH_BillingCity__c, Seller__r.Name, Coupon_Start_Time__c, Coupon_End_Time__c, Additional_Terms__c, Seller__r.Parent.EBH_BillingCountry__c, Coupon__r.Couponsite_s__c, Marketing_Coupon_Name__c, CurrencyIsoCode, Min_Transaction_Value__c, SP_Coupon_Discount_Rate__c, Coupon_Site__c, Max_Redemptions__c, Coupon_Discount_Amount__c, Legal_Entity_City__c, Maximum_Discount_Value__c, Coupon_Contract_Due_Date__c, Coupon_Seller_Stage__c, Contract_Accept_Date__c, Contract_Accepted_From__c, Contract_Signed_Declined_By__c, Legal_Entity_Country__c, Coupon_Type__c, Allow_reaccept_contract__c,Main_Coupon_Site__c From Coupon_Seller__c LIMIT 1];

        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount' limit 1];
        Contact con = [SELECT Id,Email FROM Contact WHERE FirstName='test fn' AND LastName='test ln' limit 1];

        User user1 = SEPTestGenerator.createSEPUser('sepUsersccdc1', con.Id);
                SEPTestGenerator.assignPermissionSetGroupToUser('Seller_Portal_NA', user1.Id);


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
        
        insert user1;
        */


        Test.startTest(); 

        System.runAs(user1) {

            Pagereference pdfPage = Page.SEPCouponContractDownloadPage;
            pdfPage.getParameters().put('id',cs1.Id);
            pdfPage.getParameters().put('domain',Site.getBaseCustomUrl()); 
            
            Test.setCurrentPage(pdfPage);
            SEPCouponContractDownloadController cont = new SEPCouponContractDownloadController();

            Map<String,String> mapAtt = SEPCouponContractDownloadController.createAttachment(cs1);
            System.assert(mapAtt.get('id') <> null,'Attachment created');

            Map<String,Object> mapAtt2 = SEPCouponContractDownloadController.downloadDraftContractPdf(cs1.Id,'true');
            System.assert(mapAtt2.get('downloadContent') <> null,'Attachment created');
        
        }   
        

        Test.stopTest();
        
    }
    
}