/*********************************************************************************************************************************
@ Class:        EBH_DealLandingPageControllerTest
@ Version:      1.0
@ Author:       Acmatac Seing (acmatac.seing@gaea-sys.com)
@ Purpose:      Test Class for EBH_DealLandingPageController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.18.2019 / Acmatac Seing (acmatac.seing@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/

@isTest
private class EBH_DealLandingPageControllerTest {

    @testSetup static void setup(){

        //EBH_TestDataFactory.setUpCustomSettings();
        //Map<String, Account> testDataMap = EBH_TestDataFactory.setUpAccountTriggerHandlerData();     
        //Account acc = [SELECT EBH_SoldItems__c, EBH_GMVLast12Months__c, EBH_RevenueLast12Months__c
        //               FROM Account WHERE Id =: testDataMap.get('se1').Id][0];
        //
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='Test se2',RecordTypeID = sellerRecordType.Id);
        insert acc;
        DateTime dt = System.today();
        Time myTime = Time.newInstance(dt.hour(), dt.minute(), dt.second(), dt.millisecond());
        EBH_Deal__c d1 = new EBH_Deal__c(EBH_SellerPrice__c = 1000,EBH_DealPrice__c = 11,EBH_BusinessName__c = acc.Id,EBH_SoldItems__c = 2,EBH_Vertical__c = 'CSA',EBH_DealStartDate__c = System.today()
                        ,EBH_DealEndDate__c = System.today().addDays(1),EBH_Status__c = 'New',EBH_Category__c = 'Gold',EBH_ProductTitle__c = 'product 1',EBH_SellerEmail__c = 'sales@test.com',EBH_Quantity__c = 1
                        ,EBH_DealStartTime__c = myTime,EBH_DealEndTime__c = myTime,EBH_DealFormat__c = 'Deal',EBH_eBayItemID__c = '1234567891',EBH_DealSiteId__c='77');
        insert d1;
        EBH_Deal__c d2 = new EBH_Deal__c(EBH_SellerPrice__c = 1000,EBH_DealPrice__c = 11,EBH_BusinessName__c = acc.Id,EBH_SoldItems__c = 2,EBH_Vertical__c = 'CSA',EBH_DealStartDate__c = System.today()
                        ,EBH_DealEndDate__c = System.today().addDays(1),EBH_Status__c = 'New',EBH_Category__c = 'Gold',EBH_ProductTitle__c = 'product 2',EBH_SellerEmail__c = 'sales@test.com',EBH_Quantity__c = 1
                        ,EBH_DealStartTime__c = myTime,EBH_DealEndTime__c = myTime,EBH_DealFormat__c = 'Deal',EBH_eBayItemID__c = '1234567891',EBH_DealSiteId__c='77');
        insert d2;
        //SB 20/10/2021
        EBH_ActiveTriggers__c activeTrigger = new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller');
        insert activeTrigger;

    }   

    @isTest static void updateDealCommentTest(){

        Test.startTest();
            EBH_Deal__c sDeal = [SELECT EBH_Status__c, Id FROM EBH_Deal__c WHERE EBH_ProductTitle__c = 'product 1'];
            sDeal.EBH_Status__c = 'Statement Verified';
            update sDeal;

            PageReference pageRef = Page.EBH_ClarificationRequiredPage;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('id',sDeal.Id); // 07.06.2021 / Sophal Noch / pass deal id as param
            
            EBH_DealLandingPageController controller = new EBH_DealLandingPageController();
            controller.comment = 'test comment';  // 07.06.2021 / Sophal Noch / use controller to update variable, not using remote annotation anymore
            controller.updateDealComment();
        Test.stopTest();
        sDeal = [SELECT EBH_Status__c, Invoice_Comment_From_Seller__c FROM EBH_Deal__c WHERE Id =: sDeal.Id];
        System.assertEquals(sDeal.Invoice_Comment_From_Seller__c, 'test comment');
        System.assertEquals(sDeal.EBH_Status__c, EBH_ConstantsUtility.DEAL_STATUS_CLARIFICATION_REQUIRED);

    }

    @isTest static void updateDealUploadTest(){

        Test.startTest();
            EBH_Deal__c sDeal = [SELECT Unique_Id_Ext__c, EBH_DealSiteId__c,Invoice_Number__c FROM EBH_Deal__c WHERE EBH_ProductTitle__c = 'product 1'];
            sDeal.EBH_Status__c = EBH_ConstantsUtility.DEAL_STATUS_STATEMENT_VERIFIED;
            update sDeal;
            
            EBH_Deal__c sDeal2 = [SELECT EBH_DealSiteId__c,Invoice_Number__c FROM EBH_Deal__c WHERE EBH_ProductTitle__c = 'product 2'];
            sDeal2.EBH_Status__c = EBH_ConstantsUtility.DEAL_STATUS_VERIFY_INVOICE;
            update sDeal2;

            PageReference pageRef = Page.EBH_InvoiceUploadLandingPage;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('id',sDeal.Id); // 07.06.2021 / Sophal Noch / pass deal id as param
            
            EBH_DealLandingPageController controller = new EBH_DealLandingPageController();
            controller.sDeal = sDeal;
            controller.dealId = sDeal.Id;
            controller.dealSite = sDeal.EBH_DealSiteId__c;
            controller.loadSuccess = true;
        	controller.handleDealAgree();
            controller.attachment = new attachment(Name = 'test att', Body = Blob.valueOf('Unit Test Attachment Body'));
            controller.updateDealUpload();

            ApexPages.currentPage().getParameters().put('id',sDeal2.Id); // 07.06.2021 / Sophal Noch / pass deal id as param
            EBH_DealLandingPageController controller2 = new EBH_DealLandingPageController();
            controller2.sDeal = sDeal2;
            controller2.dealId = sDeal2.Id;
            controller2.dealSite = sDeal2.EBH_DealSiteId__c;
            controller2.loadSuccess = true;
        	controller2.handleDealAgree();
            controller2.attachment = new attachment(Name = 'test att2', Body = Blob.valueOf('Unit Test Attachment Body'));
            controller2.updateDealUpload();

        Test.stopTest(); 
        sDeal = [SELECT Id, EBH_Status__c, Invoice_Comment_From_Seller__c FROM EBH_Deal__c WHERE Id =: sDeal.Id];
        sDeal2 = [SELECT Id, EBH_Status__c, Invoice_Comment_From_Seller__c FROM EBH_Deal__c WHERE Id =: sDeal2.Id];
        //EBH_DealInvoice__c sDealInv = [SELECT Id FROM EBH_DealInvoice__c WHERE EBH_Deal__c =: sDeal.Id];
        //Attachment att = [SELECT Id FROM Attachment WHERE ParentId =: sDealInv.Id];
        System.assertEquals(EBH_ConstantsUtility.DEAL_STATUS_VERIFY_INVOICE,sDeal.EBH_Status__c);
        System.assertEquals(EBH_ConstantsUtility.DEAL_STATUS_VERIFY_INVOICE,sDeal2.EBH_Status__c);
        //System.assertNotEquals(sDealInv, null);
        //System.assertNotEquals(att.Id, null);

    }
    @isTest static void testProposeDeal(){
        // 18.10.2021 / Sophal Noch / US-0010546 :
        Test.startTest();
            EBH_Deal__c sDeal = [SELECT Unique_Id_Ext__c, EBH_DealSiteId__c, Invoice_Number__c FROM EBH_Deal__c WHERE EBH_ProductTitle__c = 'product 1'];
            sDeal.EBH_Status__c = 'Seller Invite';
            sDeal.EBH_DealSiteId__c = '77';
            update sDeal;
            PageReference pageRef = Page.FulfillmentProposalPage;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('id',sDeal.Id);

            EBH_DealLandingPageController controller = new EBH_DealLandingPageController();
            controller.sDeal = sDeal;
            controller.dealId = sDeal.Id;
            controller.dealSite = sDeal.EBH_DealSiteId__c;
            controller.sellerPrice = '100';
            controller.quantity = '50';
            controller.dealDate = String.valueOf(Date.today());
            controller.loadSuccess = true;
        	controller.proposeDeal();

            sDeal = [SELECT EBH_Status__c, Unique_Id_Ext__c, EBH_DealSiteId__c,Invoice_Number__c FROM EBH_Deal__c WHERE EBH_ProductTitle__c = 'product 1'];
            System.assertEquals('New', sDeal.EBH_Status__c);

        Test.stopTest(); 
    }
}