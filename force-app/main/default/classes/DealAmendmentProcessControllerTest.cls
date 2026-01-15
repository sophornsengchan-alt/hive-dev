/*********************************************************************************************************************************
@ Class:          DealAmendmentProcessControllerTest
@ Version:        1.0
@ Author:         Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:        Code Coverage for DealAmendmentProcessController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09.09.2021 / Mony Nou / Created the class.
*********************************************************************************************************************************/
@isTest
private class DealAmendmentProcessControllerTest {
    
    private static ID RT_NADEAL = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2').Id;
    
    @testSetup
    static void setup(){
    	
        byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
        
        RecordType sellerRecordType  = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        RecordType contactRecordTYpe = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
        Account ac = new Account(Name='Seller',EBH_VATNumber__c='VAT1111',RecordTypeID = sellerRecordType.Id);
        insert ac;
        Contact contact1 = new Contact(
            MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
            FirstName='firstname',Salutation='Mr.',LastName='test1',
            email='test1@test.com' , AccountId = ac.Id, 
            Contact_Role__c='Deals', 
            recordtypeId = contactRecordTYpe.Id
        );
        insert contact1;

        Time sTime = Time.newInstance(6, 0, 0, 0);
        Time eTime = Time.newInstance(22, 0, 0, 0);

        EBH_Deal__c originalDeal = new EBH_Deal__c( 
            EBH_SellerPrice__c=1000,
            EBH_SoldItems__c=2,
            EBH_Vertical__c='Soft Home',
            EBH_DealSiteId__c='77',
            EBH_Status__c='New',
            EBH_Category__c='Gold', 
            EBH_ProductTitle__c='product 1',
            EBH_Quantity__c=1,
            EBH_DealStartTime__c = sTime,
            EBH_DealEndTime__c = eTime
        );

        originalDeal.EBH_DealPrice__c = 200;
        originalDeal.EBH_DealFormat__c = 'iji';
        originalDeal.EBH_DealStartDate__c = Date.today();
        originalDeal.EBH_DealEndDate__c = Date.today()+30;
        originalDeal.EBH_SellerEmail__c ='dd@d.com';
        originalDeal.EBH_MaximumPurchases__c =1;
        originalDeal.EBH_BusinessName__c = ac.Id;
        originalDeal.Subsidy_Running__c = 10;
        originalDeal.EBH_Payout_SI__c = 10;
        originalDeal.recordtypeId = RT_NADEAL;
        originalDeal.EBH_eBayItemID__c='123456789000';
        originalDeal.Seller_Approver_1__c=contact1.Id;

        insert originalDeal;

    }

    @isTest
    static void test_validateDealForAmendContract() {

        Test.startTest();

            EBH_Deal__c oDeal = [SELECT Id FROM EBH_Deal__c LIMIT 1];

            //Validate - Error
            Map<String,Object>  result = DealAmendmentProcessController.validateDealForAmendContract(oDeal.Id);
            System.assertEquals(Label.NA_Deal_Amend_Contract_Error_Msg_2, result.get('msg'));

            //Validate - Ok
            oDeal.EBH_Status__c = 'Running';
            update oDeal;

            result = DealAmendmentProcessController.validateDealForAmendContract(oDeal.Id);
            System.assertEquals('ok', result.get('status'));
            
        Test.stopTest();

    }

    @isTest
    static void test_CreateNCancelAmendmentDeal() {

        Test.startTest();

            EBH_Deal__c oDeal = [SELECT EBH_BusinessName__c, Seller_Approver_1__c,EBH_DealStartDate__c,EBH_DealPrice__c  FROM EBH_Deal__c LIMIT 1];

            EBH_Deal__c aDeal = new EBH_Deal__c( 
                EBH_SellerPrice__c=1000,
                EBH_SoldItems__c=2,
                EBH_Vertical__c='Electronics',    
                EBH_DealSiteId__c='77',
                EBH_Status__c='New',
                EBH_Category__c='Gold', 
                EBH_ProductTitle__c='product 1',
                EBH_Quantity__c=1,
                EBH_RRPWASPrice__c=2, 
                EBH_RecommendedRetailPriceWAS__c='RRP', 
                EBH_MarketingTitle__c='test',
                Merchant_Approver__c = UserInfo.getUserId()
            );

            aDeal.EBH_DealPrice__c = 200;
            aDeal.EBH_DealFormat__c = 'Primary';
            aDeal.EBH_DealStartDate__c = Date.today()-3;
            aDeal.EBH_DealEndDate__c = Date.today()+30;
            aDeal.EBH_SellerEmail__c ='dd@d.com';
            aDeal.EBH_MaximumPurchases__c =1;
            aDeal.EBH_BusinessName__c = oDeal.EBH_BusinessName__c;
            aDeal.Subsidy_Running__c = 10;
            aDeal.EBH_Payout_SI__c = 10;
            aDeal.recordtypeId = RT_NADEAL;
            aDeal.EBH_eBayItemID__c='123456789000';
            aDeal.Seller_Approver_1__c=oDeal.Seller_Approver_1__c;
            aDeal.Originating_Deal__c = oDeal.Id;
            
            //Error 1
            Map<String,Object>  result = DealAmendmentProcessController.createAmendmentDeal(JSON.serialize(aDeal),JSON.serialize(oDeal));
            System.assertEquals(Label.NA_Deal_Amend_Contract_DateError_Msg_1, result.get('msg'));

            //Error2 
            aDeal.EBH_DealStartDate__c = Date.today();
            aDeal.EBH_DealPrice__c = 300;
            result = DealAmendmentProcessController.createAmendmentDeal(JSON.serialize(aDeal),JSON.serialize(oDeal));
            System.assertEquals(Label.NA_Deal_Amend_Contract_DateError_Msg_2, result.get('msg'));

            //Success
            aDeal.EBH_DealStartDate__c = Date.today()+3;
            aDeal.EBH_DealPrice__c = 200;
            result = DealAmendmentProcessController.createAmendmentDeal(JSON.serialize(aDeal),JSON.serialize(oDeal));
            System.assertEquals('ok', result.get('status'));
            System.assert(result.containsKey('aDealId') && result.get('aDealId') != null);
            

            //Cancel Amendment Deal
            String aDealId = String.valueOf(result.get('aDealId'));
            
            Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
            app.setObjectId(aDealId);
            Approval.ProcessResult appRes = Approval.process(app);
            
            result = DealAmendmentProcessController.cancelAmendContract(oDeal.Id);
            System.assertEquals('ok', result.get('status')); 
                                
            aDeal = [SELECT EBH_Status__c FROM EBH_Deal__c WHERE Id=:aDealId];
            System.assertEquals('Cancelled', aDeal.EBH_Status__c);

        Test.stopTest();

    }

}