@isTest
private class SEPDownloadControllerTest {
    
    @testSetup
    static void setup(){
        
        EBH_TestDataFactory.setUpCustomSettings();
        ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = false;
		insert avr;

    	//create an account
        Account acc = new Account( EBH_RevRollup__c='US',SP_Main_Domain__c = SEP_Helper.SEP_Domain_NA, Name = 'TestAccount',SP_Deals__c = 'Full Access', SP_Coupons__c = 'Full Access', SP_Promotions_Manager__c='Full Access', NA_Deal_Program_Vetted__c = true);
        insert acc;

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,
                                    FirstName='test fn', LastName='test ln', AccountId=acc.Id, Email = 'test123@test.com');
        insert con;
        
        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
        Coupon__c c1 = new Coupon__c(Coupon_ID__c='CC001',Main_Coupon_Site__c = 'ebay.com',MC_Whitelisted__c = true,Stage__c = 'Draft', RecordTypeID = couponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1);
        insert new List<Coupon__c>{c1};

        RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
        Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Seller_Contact__c=con.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc.Id,RecordTypeID=manhattanCouponSellerRecordType.Id);
        insert cs1;

        RecordType rtPMDealDCA = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c','Promotions_Manager_Deals');
        Date today = System.today();
        Date dDate = Date.newInstance( today.year()+1, today.month()+1, 1);
        Deal_Contract_Agreement__c pm_dca = new Deal_Contract_Agreement__c(
            eBay_Seller__c = acc.Id,
            Title__c = 'Test Title',
            Deal_Start_Date__c = dDate,
            Deal_End_Date__c = dDate+10,
            Merchant_Approver__c = UserInfo.getUserId(),
            Category__c = 'Antiques',
            eBay_Funding__c = 10,
            Max_Total_Subsidy__c = 1000,
            Max_Unit_Subsidy__c = 1000,
            RecordTypeId = rtPMDealDCA.Id
        );

        insert pm_dca;
        
    }
    @isTest 
    static void test_getDownloadExcel() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount' limit 1];
        Contact con = [SELECT Id,Email FROM Contact WHERE FirstName='test fn' AND LastName='test ln' limit 1];
        RecordType couponRecordTypeCat = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_CATEGORYBASE);
        Coupon__c c1 = new Coupon__c(Coupon_ID__c='CC001',Main_Coupon_Site__c = 'ebay.com',MC_Whitelisted__c = true,Stage__c = 'Draft', RecordTypeID = couponRecordTypeCat.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1);
        insert c1;
        RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
        Coupon_Seller__c cs = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Targeted',Seller_Contact__c=con.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc.Id,RecordTypeID=manhattanCouponSellerRecordType.Id);
        insert cs;
        List<Coupon_Co_Invest__c> lstCCI = new List<Coupon_Co_Invest__c>();
            Id cciRT = Schema.SObjectType.Coupon_Co_Invest__c.getRecordTypeInfosByName().get('Coupon Co-Invest Item').getRecordTypeId();
            lstCCI.add(new Coupon_Co_Invest__c(
                Coupon_Seller__c = cs.Id,
                Seller_Name__c = acc.Id,
                Co_Invest__c = 10,
                CurrencyIsoCode = 'USD',
                RecordtypeId = cciRT
            ));
            insert lstCCI;
        Test.startTest(); 
            PageReference pageRef = new PageReference('/apex/SEPDownloadPage');
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('Id',cs.Id);

            SEPDownloadController controller =new SEPDownloadController();
            SEPDownloadController.CouponSellerWrapper sheet = controller.cs;
            SEPDownloadController.getDownloadExcel(cs.Id);
            System.debug('sheet' +sheet);
            //System.assert(String.isNotBlank(result));
        Test.stopTest();

    }

    @IsTest
    static void test_downloadPMDealDCA () {
        
        Deal_Contract_Agreement__c dca = [SELECT eBay_Seller__r.Name, eBay_Seller__r.EBH_RevRollup__c, Title__c, eBay_Funding__c, Deal_Page_Placement__c, 
        Deal_Start_Date__c, Deal_Start_Time__c, Deal_End_Date__c, Deal_End_Time__c, Discount_Applied_in_Cart__c, 
        Max_Total_Subsidy__c, Max_Unit_Subsidy__c, CurrencyIsoCode 
        FROM Deal_Contract_Agreement__c LIMIT 1];

        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount' limit 1];
        Contact con = [SELECT Id,Email FROM Contact WHERE FirstName='test fn' AND LastName='test ln' limit 1];

        User user1 = SEPTestGenerator.createSEPUser('sepUsersdc1', con.Id); //MN-10062024-US-0015298
        SEPTestGenerator.assignPermissionSetGroupToUser('Seller_Portal_NA', user1.Id);
        
        System.runAs(user1) {
            Test.startTest(); 
                Pagereference pdfPage = Page.SEPDCAContractDownloadPage;
                pdfPage.getParameters().put('id',dca.Id);
                
                Test.setCurrentPage(pdfPage);
                SEPDCAContractDownloadController cont = new SEPDCAContractDownloadController();

                Map<String,String> mapAtt = SEPDCAContractDownloadController.createAttachment(dca);
                System.assert(mapAtt.get('id') <> null,'Attachment created');
            Test.stopTest();
        }   
        

        
    }
}