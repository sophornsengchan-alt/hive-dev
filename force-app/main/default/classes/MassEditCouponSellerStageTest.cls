/*********************************************************************************************************************************
@ Class:          MassEditCouponSellerStageTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0009605 - Coupon Seller: mass update of stage button
@					As any user
@					Given that I am on the related of a Coupon record (either for Category Based or Item Based)
@					and I select All or a few coupon seller names
@					When I click on the button "Mass editstage"
@					I want to be able to mass update the field Coupon_Seller_Stage__c to the value "Reached" OR "Committed" OR "Negotiation" OR "Approved".
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 15.06.2021 / Sovantheany Dim / Created the class.
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 04.12.2023 / Vimean Heng  / fix test update fail
*********************************************************************************************************************************/

@isTest
private class MassEditCouponSellerStageTest {
    @testSetup private static void setup() {
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        RecordType couponItemBaseRecordType = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
        RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RegistrationCountry__c = '77',EBH_RevRollup__c='DE',SP_Coupons__c='Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	Account acc2 = new Account(Name='Test Acc2',RecordTypeID = sellerRecordType.Id,EBH_RegistrationCountry__c = '77',EBH_RevRollup__c='DE',SP_Coupons__c='Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	insert new List<Account>{acc,acc2};
    	Coupon__c c1 = new Coupon__c(RecordTypeID = couponItemBaseRecordType.Id,Main_Coupon_Site__c = 'ebay.de',Coupon_Co_invest_Type__c='Contra');
		insert c1;
    	Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id,RecordTypeId = manhattanCouponSellerRecordType.Id);
    	Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc2.Id,RecordTypeId = manhattanCouponSellerRecordType.Id);
    	insert new List<Coupon_Seller__c>{cs1,cs2};
    }
    /*****************************************************************************************************************************
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 04.12.2023 / Vimean Heng  / US-001442 test update fail
    *****************************************************************************************************************************/
    private static testMethod void updateStageActionTest() {
        Test.startTest();
        List<Coupon_Seller__c> lstCs = [SELECT Coupon_Seller_Stage__c FROM Coupon_Seller__c];
        Test.setCurrentPage(Page.MassEditCouponSellerStage);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstCs);
        stdSetController.setSelected(lstCs);
        MassEditCouponSellerStage ctr = new MassEditCouponSellerStage(stdSetController);
        ctr.cancelAction();
        //test update success
        ctr.getStageSelected();
        ctr.selectedStageValue = 'Reached';
        ctr.updateStageAction();
        Test.stopTest();
        List<Coupon_Seller__c> lstCsAfterUpdated = [select Coupon_Seller_Stage__c from Coupon_Seller__c where id IN: lstCs];       
        for(Coupon_Seller__c cs : lstCsAfterUpdated){
           System.assert(cs.Coupon_Seller_Stage__c=='Reached');
        }
        //test update fail
        ctr.selectedStageValue = 'Contract Send';
        ctr.updateStageAction();
        System.assertEquals(ctr.isError,true);
    }
    private static testMethod void testCouponSellerSelectFail() {
        Test.startTest();
        List<Coupon_Seller__c> lstCs = [SELECT Coupon_Seller_Stage__c FROM Coupon_Seller__c];
        //test previous coupon seller select stage is not "Targeted" OR "Reached" OR "Committed" OR "Negotiation"
        lstCs[0].Coupon_Seller_Stage__c = 'Contract Signed';
        update lstCs[0];
        ApexPages.StandardSetController stdSetController2 = new ApexPages.StandardSetController(lstCs);
        stdSetController2.setSelected(lstCs);
        MassEditCouponSellerStage ctr2 = new MassEditCouponSellerStage(stdSetController2);
        Test.stopTest();
        System.assert(!ctr2.isCSStageOk);
    }
}