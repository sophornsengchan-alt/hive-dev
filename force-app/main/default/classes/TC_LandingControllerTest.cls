/*********************************************************************************************************************************
@ Class:          TC_LandingControllerTest
@ Version:        1.0
@ Author:         
@ Purpose:        Test class for TC_LandingController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.08.2020 /  / Created the test class.
*********************************************************************************************************************************/
@isTest
public with sharing class TC_LandingControllerTest {

    static testMethod void validateCheckBoxTest(){
        
        EBH_TestDataFactory.setUpCustomSettings();     
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account acc = new Account(Name='Test Abc123',RecordTypeID = sellerRecordType.Id);
        Account acc2 = new Account(Name='Test Abc124',RecordTypeID = sellerRecordType.Id);
        insert new List<Account>{acc,acc2};
        RecordType couponRecordTypeCategory = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_CATEGORYBASE);
        RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
        Coupon__c c1 = new Coupon__c(Main_Coupon_Site__c = 'ebay.com.au',Coupon_Co_invest_Type__c='Contra',RecordTypeID = couponRecordTypeCategory.Id,Contract_Due_Date__c = System.today()-2, Coupon_Start_Date__c = System.today()+1, Coupon_End_Date__c = System.today() +2
        ,Coupon_Start_Time__c=Time.newInstance(1, 20, 20, 20),Coupon_end_Time__c=Time.newInstance(1, 20, 20, 20));
        Coupon__c c2 = new Coupon__c(Main_Coupon_Site__c = 'ebay.com.au',Coupon_Co_invest_Type__c='Contra',RecordTypeID = couponRecordTypeItem.Id,Contract_Due_Date__c = System.today()-2, Coupon_Start_Date__c = System.today()+1, Coupon_End_Date__c = System.today() +2
        ,Coupon_Start_Time__c=Time.newInstance(1, 20, 20, 20),Coupon_end_Time__c=Time.newInstance(1, 20, 20, 20));
        insert new List<Coupon__c>{c1,c2};
        Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c=EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SIGNED,Seller__c = acc.Id,Allow_reaccept_contract__c=false);
        Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c2.Id,Coupon_Seller_Stage__c=EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SIGNED,Seller__c = acc2.Id,Allow_reaccept_contract__c=false);
        insert new List<Coupon_Seller__c>{cs1,cs2};
        // Coupon_Item__c ci = new Coupon_Item__c(Coupon_ID__c=c2.Id, Coupon_Seller_ID__c=cs2.Id,Item_ID__c='1234567890');
        // insert ci;
        Category_Tree__c ct1 = new Category_Tree__c(Name = 'Australia (Site Level)',Level__c = 0,Active__c=true);
        Category_Tree__c ct2 = new Category_Tree__c(Name = 'Test',Level__c = 0,Active__c=true);
        insert new List<Category_Tree__c>{ct1,ct2};
        Coupon_Category__c cc1 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct1.Id,Exception_Category__c=true);
        Coupon_Category__c cc2 = new Coupon_Category__c(Coupon__c = c1.Id,Category__c = ct2.Id,Exception_Category__c=true);
        insert new List<Coupon_Category__c>{cc1,cc2};
        Coupon_Co_Invest__c coInvest = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id,Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Co_Invest__c=10);
		Coupon_Co_Invest__c coInvest1 = new Coupon_Co_Invest__c(Coupon_Category__c=cc1.Id, Coupon_Seller__c=cs1.Id,Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Co_Invest__c=10);
        Coupon_Co_Invest__c coInvest2 = new Coupon_Co_Invest__c(Coupon_Category__c=cc2.Id, Coupon_Seller__c=cs1.Id,Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Co_Invest__c=10);
        Coupon_Co_Invest__c coInvest3 = new Coupon_Co_Invest__c(Coupon_Seller__c=cs2.Id,Seller_Name__c=acc2.Id,Coupon_Name__c=c2.Id,Co_Invest__c=10);
        insert new List<Coupon_Co_Invest__c>{coInvest,coInvest1,coInvest2,coInvest3};
        
        Test.startTest();
            ApexPages.StandardController sc = new ApexPages.standardController(cs1);
            ApexPages.currentPage().getParameters().put('id', cs1.Id);
            TC_LandingController tc = new TC_LandingController(sc);
            tc.validateCheckBox();
            System.assert(!tc.msg.contains(System.Label.WarningTaskAlreadyCreated ));
            ApexPages.StandardController sc2 = new ApexPages.standardController(cs2);
            ApexPages.currentPage().getParameters().put('id', cs2.Id);
            TC_LandingController tc2 = new TC_LandingController(sc2);
        Test.stopTest();
    }

}