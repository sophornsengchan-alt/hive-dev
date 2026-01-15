/*********************************************************************************************************************************
 @ Class:          CouponCoInvestTriggerHandlerTest
 @ Version:        1.0
 @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
 @ Purpose:        test Handler Class for trigger CouponCoInvestTrigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.06.2019 /  Sovantheany Dim / Created the class.
@ Change history:  14.12.2023 / Vimean Heng / Fix lock row.
*********************************************************************************************************************************/
@isTest
private class CouponCoInvestTriggerHandlerTest {

    /*
    static testmethod void setupData(){
        EBH_TestDataFactory.setUpCustomSettings();   
        
       
    }
    */

    @testSetup
    static void setup(){
        
        EBH_TestDataFactory.setUpCustomSettings();

    }

    static testMethod void testsetDefaultSellerShare() {
        // setupdata();
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_RevRollup__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	insert acc;
        // Coupon__c c1 = new Coupon__c(Seller_Co_funding_share_forecast__c = 10);
        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
        Coupon__c c1 = new Coupon__c(Coupon_ID__c = 'TestCoupon123',Seller_Co_funding_share_forecast__c = 10,Main_Coupon_Site__c = 'ebay.com',MC_Whitelisted__c = true,Stage__c = 'Draft', RecordTypeID = couponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1);
        insert c1;
        Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id, SellerShareHolder__c = 20);
        insert cs1;
        Coupon_Co_Invest__c coInvest = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id,Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id);
        Test.startTest();
        	insert coInvest;
        Test.stopTest();
        System.assertEquals(cs1.SellerShareHolder__c,[select Co_Invest__c from Coupon_Co_Invest__c where id =: coInvest.Id].Co_Invest__c);
    }
    static testmethod void testupdatedCouponCoInvest(){
    	// setupdata();
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_RevRollup__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	insert acc;
        // Coupon__c c1 = new Coupon__c(Seller_Co_funding_share_forecast__c = 10,CurrencyIsoCode='EUR');
        RecordType couponRecordTypeCate = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_CATEGORYBASE);
        Coupon__c c1 = new Coupon__c(Coupon_ID__c = 'TestCoupon123',Seller_Co_funding_share_forecast__c=10,CurrencyIsoCode='EUR',Main_Coupon_Site__c = 'ebay.com',MC_Whitelisted__c = true,Stage__c = 'Draft', RecordTypeID = couponRecordTypeCate.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1);
        insert c1;
        
        Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id);
        insert cs1;
        Category_Tree__c ct1 = new Category_Tree__c(Name = 'testCategoryTree1',Level__c = 0,Active__c=true);
        Category_Tree__c ct2 = new Category_Tree__c(Name = 'testCategoryTree2',Level__c = 0,Active__c=true);
        List<Category_Tree__c> ctList = new List<Category_Tree__c>{ct1,ct2};
    	insert ctList;
        Coupon_Category__c cc1 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct1.Id);
        insert cc1;
        Coupon_Category__c cc2 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct2.Id,Exception_Category__c=true);
        insert cc2;
        Coupon_Co_Invest__c coInvest2 = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id,Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Coupon_Category__c=cc2.Id);
        insert coInvest2;
        Test.startTest();
        coInvest2.CurrencyIsoCode = '';
        update coInvest2;
        Test.stopTest();
        System.assert([select CurrencyIsoCode from Coupon_Co_Invest__c where id =: coInvest2.Id].CurrencyIsoCode == c1.CurrencyIsoCode);
    }
    
    static testmethod void testdeleteCouponCoInvest(){
    	// setupdata();
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_RevRollup__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	insert acc;
        //Coupon__c c1 = new Coupon__c(Seller_Co_funding_share_forecast__c = 10);
        RecordType couponRecordTypeCate = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_CATEGORYBASE);
        Coupon__c c1 = new Coupon__c(Coupon_ID__c = 'TestCoupon123',Seller_Co_funding_share_forecast__c=10,Main_Coupon_Site__c = 'ebay.com',MC_Whitelisted__c = true,Stage__c = 'Draft', RecordTypeID = couponRecordTypeCate.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1);
        insert c1;
        Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id);
        insert cs1;
        Category_Tree__c ct1 = new Category_Tree__c(Name = 'testCategoryTree1',Level__c = 0,Active__c=true);
        Category_Tree__c ct2 = new Category_Tree__c(Name = 'testCategoryTree2',Level__c = 0,Active__c=true);
        List<Category_Tree__c> ctList = new List<Category_Tree__c>{ct1,ct2};
    	insert ctList;
        Coupon_Category__c cc1 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct1.Id);
        insert cc1;
        Coupon_Category__c cc2 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct2.Id,Exception_Category__c=true);
        insert cc2;
        try{
        	Coupon_Co_Invest__c coInvest = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id,Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Coupon_Category__c=cc1.Id);
        	insert coInvest;
        }catch(Exception e){
        	System.assert(e.getMessage().contains(system.label.Coupon_Owner_Exception_Error_Message_2));
        }
        Coupon_Co_Invest__c coInvest2 = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id,Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Coupon_Category__c=cc2.Id);
        insert coInvest2;
        Test.startTest();
        	delete coInvest2;
        Test.stopTest();
    }

    //@ Change history:  14.12.2023 / Vimean Heng / US-0014423 / Fix lock row.
    @isTest
    static void couponCoInvestAccessibilityTest(){
        // setupdata();
        
        Test.startTest();
            String auProfile = [SELECT Id FROM Profile WHERE Name =: EBH_ConstantsUtility.TICKET_AU_PROFILE].Id;
            //User auUser1 = [SELECT Id FROM User WHERE ProfileId =: auProfile AND isActive=true LIMIT 1 ];
            //User auUser1 = EBH_TestDataFactory.createUser(EBH_ConstantsUtility.TICKET_AU_PROFILE);
            //User auUser2 = [SELECT Id FROM User WHERE ProfileId =: auProfile AND Id !=: auUser1.Id AND isActive=true LIMIT 1];
            //User auUser2 = EBH_TestDataFactory.createUser(EBH_ConstantsUtility.TICKET_AU_PROFILE);
            //VM 14.12.2023 / US-0014423 / ignore flow assign role.
            UserRole r = [select Id from UserRole where DeveloperName='Standard_Users' Limit 1];
            User auUser = EBH_TestDataFactory.createUser(EBH_ConstantsUtility.TICKET_AU_PROFILE);
            User auUser1 = EBH_TestDataFactory.createUser('Chatter Free User');
            User auUser2 = EBH_TestDataFactory.createUser('Chatter Free User');
            insert new List<User>{auUser1,auUser2};
            auUser1.ProfileId = auUser.ProfileId;
            auUser2.ProfileId = auUser.ProfileId;
            update new List<User>{auUser1,auUser2};
            System.runAs(auUser2){
                PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name =: EBH_ConstantsUtility.PERMISSION_COUPONSPECIALPERMISSION];
                PermissionSetAssignment pmm = new PermissionSetAssignment(AssigneeId = auUser1.id, PermissionSetId = ps.Id);
                insert pmm;
            }
            Account acc;
            Coupon__c c1;
            Coupon_Seller__c cs1;
            Coupon_Co_Invest__c coInvest2;
            // Only user with special permission can approve coupon seller
            System.runAs(auUser1){
                RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
                acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_RevRollup__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
                insert acc;
                RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_CATEGORYBASE);
                c1 = new Coupon__c(Coupon_ID__c = 'TestCoupon123',Seller_Co_funding_share_forecast__c = 10,CurrencyIsoCode='EUR',Negotiation_End_Date__c=System.today(),Main_Coupon_Site__c='ebay.com.au');
                insert c1;
                cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id, Coupon_Seller_Stage__c=EBH_ConstantsUtility.COUPONSELLER_STAGE_APPROVED);
                insert cs1;
                coInvest2 = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id,Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id);
                insert coInvest2;
            }
            
            
            System.runAs(auUser2){
                // Category_Tree__c ct1 = new Category_Tree__c(Name = 'testCategoryTree1',Level__c = 0);
                // Category_Tree__c ct2 = new Category_Tree__c(Name = 'testCategoryTree2',Level__c = 0);
                // List<Category_Tree__c> ctList = new List<Category_Tree__c>{ct1,ct2};
                // insert ctList;
                // Coupon_Category__c cc1 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct1.Id);
                // insert cc1;
                // Coupon_Category__c cc2 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct2.Id,Exception_Category__c=true);
                // insert cc2;
                
            
                try {
                    coInvest2.Co_Invest__c = 15;
                    update coInvest2;
                    //System.assert(false, 'Seller Share should be locked to edit');
                } catch (Exception ex) {
                    //System.assert(ex.getMessage().contains(EBH_ConstantsUtility.MSG_SELLERFUNDINGLOCKED), 'Error : '+ex.getMessage());
                }

                try {
                    c1.Negotiation_End_Date__c = System.today().addDays(-1);
                    update c1;

                    cs1.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_NEGO;
                    update cs1;

                    coInvest2.Co_Invest__c = 15;
                    update coInvest2;
                    //System.assert(false, 'Seller Share should be locked to edit');
                } catch (Exception ex) {
                    //System.assert(ex.getMessage().contains(EBH_ConstantsUtility.MSG_SELLERFUNDINGLOCKED_SENTAPPROVAL), 'Error : '+ex.getMessage());
                }
            }
        Test.stopTest();
    }

    @isTest 
    static void testvalidateCouponCoInvest(){

    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        RecordType coRecordType = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
        Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_RevRollup__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        insert acc;

        Coupon__c c1 = new Coupon__c(RecordTypeID = coRecordType.Id,Main_Coupon_Site__c='ebay.com', Couponsite_s__c = 'ebay.com', Coupon_ID__c = 'TestCoupon123');
        insert c1;
        
        Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id,Coupon_Seller_Stage__c='Contract Signed');
        insert cs1;
        
        Id itemRTID = CouponCoInvestTriggerHandler.RTID_COUPONCOINVESTITEM;
        
        Test.startTest();

            try {

                Coupon_Co_Invest__c ci1 = new Coupon_Co_Invest__c(RecordtypeId=itemRTID, Coupon_Name__c=c1.Id, Coupon_Seller__c=cs1.Id,Item_ID__c='100001');
                Coupon_Co_Invest__c ci2 = new Coupon_Co_Invest__c(RecordtypeId=itemRTID, Coupon_Name__c=c1.Id, Coupon_Seller__c=cs1.Id,Item_ID__c='100002');
                Coupon_Co_Invest__c ci2_1 = new Coupon_Co_Invest__c(RecordtypeId=itemRTID, Coupon_Name__c=c1.Id, Coupon_Seller__c=cs1.Id,Item_ID__c='100002');
                List<Coupon_Co_Invest__c> ctList = new List<Coupon_Co_Invest__c>{ci1,ci2,ci2_1};
                insert ctList;
            
            } catch(Exception e){
                System.assert(true);
                System.assert(e.getMessage().contains(System.Label.Error_Duplicate_Coupon_Item_In_File),'error: '+System.Label.Error_Duplicate_Coupon_Item_In_File);
            }

            try{
                Coupon_Co_Invest__c ci3 = new Coupon_Co_Invest__c(RecordtypeId=itemRTID, Coupon_Name__c=c1.Id, Coupon_Seller__c=cs1.Id,Item_ID__c='100001');
                Coupon_Co_Invest__c ci4 = new Coupon_Co_Invest__c(RecordtypeId=itemRTID, Coupon_Name__c=c1.Id, Coupon_Seller__c=cs1.Id,Item_ID__c='100002');
                insert new List<Coupon_Co_Invest__c>{ci3,ci4};
            }catch(Exception e){
                System.assert(true);
                //System.assert(e.getMessage().contains(System.Label.Error_Duplicate_Coupon_Item_In_File),'error: '+System.Label.Error_Duplicate_Coupon_Item_In_File);
                System.assert(e.getMessage().contains(System.Label.Error_Duplicate_Coupon_Item),'error: '+System.Label.Error_Duplicate_Coupon_Item);
            }
        Test.stopTest();
    }
}