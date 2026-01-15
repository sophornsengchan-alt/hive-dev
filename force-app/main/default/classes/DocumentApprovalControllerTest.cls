@isTest
private class DocumentApprovalControllerTest {

    private static Contact contact;
    private static EBH_Deal__c d1;
    static void setupData() {
    	byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
        Deal_Timezone__c dealTimezone = new Deal_Timezone__c();
        dealTimezone.TimeZone__c='America/Los_Angeles';     
        insert dealTimezone;
        RecordType rect_legal = ApexUtil.getRecordTypeByName('Account', 'EBH_LegalEntity');
        RecordType rect_seller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');

        Account acc = new Account(Name='Test Account Name: 1', BillingCountry='CH',RecordTypeId=rect_legal.Id);
        insert acc;
            Account eBaySeller = new Account (Name='Test eBaySeller For Doc Approve 1',ParentId = acc.Id,RecordTypeId=rect_seller.Id);
        insert eBaySeller;

        Id contactRTManual = ApexUtil.getRecordTypeByName('Contact', 'EBH_MANUAL').Id;
        contact = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email = 'test1sellerapprover@test.com' , AccountId = eBaySeller.Id,
                                      //EBH_Decision_Maker_Role__c = 'Deals', //MN:13/05/2021:US-0009542 - [NA] Deals: Remove unused value from 'Decision Maker Role' on Contact
                                      Contact_Role__c='Deals', //MN:13/05/2021:US-0009542 - use Contact_Role__c instead
                                      RecordTypeId = contactRTManual);
    
        //insert contact;

        Contact con2 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                    FirstName='firstname',Salutation='Mr.',LastName='test2',
                    email = 'test2sellerapprover@test.com' , AccountId = eBaySeller.Id,
                    Contact_Role__c='Deals', //MN:13/05/2021:US-0009542 - use Contact_Role__c instead
                    RecordTypeId = contactRTManual);

        Contact con3 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                    FirstName='firstname',Salutation='Mr.',LastName='test2',
                    email = 'test3sellerapprover@test.com' , AccountId = eBaySeller.Id,
                    Contact_Role__c='Deals', //MN:13/05/2021:US-0009542 - use Contact_Role__c instead
                    RecordTypeId = contactRTManual);

        Contact con4 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                    FirstName='firstname',Salutation='Mr.',LastName='test2',
                    email = 'test4sellerapprover@test.com' , AccountId = eBaySeller.Id,
                    Contact_Role__c='Deals', //MN:13/05/2021:US-0009542 - use Contact_Role__c instead
                    RecordTypeId = contactRTManual);

        Contact con5 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                    FirstName='firstname',Salutation='Mr.',LastName='test2',
                    email = 'test5sellerapprover@test.com' , AccountId = eBaySeller.Id,
                    Contact_Role__c='Deals', //MN:13/05/2021:US-0009542 - use Contact_Role__c instead
                    RecordTypeId = contactRTManual);
        
        insert new List<Contact>{contact, con2, con3, con4, con5};

        EBH_SpotlightCategory__c spotCat = new EBH_SpotlightCategory__c(Name = 'test spotLightCat',EBH_Country__c='NA',EBH_SpotlightCategoryID__c='testSpotId');
            insert spotCat;
            Id devRecordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id;//Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('eBay NA').getRecordTypeId();
            Date myDate = System.today();
        d1 = new EBH_Deal__c(
            EBH_eBayItemID__c= '000000000010', 
            Seller_Approver_1__c = contact.Id, 
            Seller_Approver_2__c = con2.Id, 
            Seller_Approver_3__c = con3.Id, 
            Seller_Approver_4__c = con4.Id, 
            Seller_Approver_5__c = con5.Id, 
            EBH_BusinessName__c=eBaySeller.ID,EBH_SpotlightCategory__c = spotCat.Id,RecordTypeId=devRecordTypeId,EBH_SellerPrice__c=20,EBH_DealPrice__c=5,EBH_Quantity__c=2,EBH_MaximumPurchases__c=2,EBH_DealStartDate__c=myDate,EBH_DealEndDate__c=myDate,EBH_DealStartTime__c = Time.newInstance(17, 30, 2, 20) ,EBH_DealEndTime__c = Time.newInstance(18, 30, 2, 20) ,EBH_Status__c='Internally Approved',EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1');
        insert d1;
    }
    @isTest
    public static void test_DocApproval(){
        setupData();
        User[] admins = [select id from User where Profile.Name='System Administrator' AND isActive=TRUE Limit 2];
        Profile     p       = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User    u   = new User();
        System.runAs(admins[0]){
            u.profileId         = p.id;
            u.username          = 'testirisuser1@ebay.com';
            u.email             = 'testirisuser1@ebay.com';
            u.emailencodingkey  = 'UTF-8';
            u.localesidkey      = 'en_US';
            u.languagelocalekey = 'en_US';
            u.timezonesidkey    = 'America/Los_Angeles';
            u.alias             = 'tus1';
            u.lastname          = 'testLastName';
            insert u;
        }
               
        
        System.runAs(u){
            EmailTemplate   et                  = new EmailTemplate(); 
                            et.isActive         = true;  
                            et.Name             = 'Deals - Send PDF';
                            et.DeveloperName    = 'Deals_Send_PDF';
                            et.FolderId         = u.Id;
                            et.Body             = '{!Deal_Contract_Agreement__c.Seller_Name__c}';
                            et.TemplateType     = 'custom';
                            et.HtmlValue        = '{!Deal_Contract_Agreement__c.Seller_Name__c}';
            insert et;
            
            Account seller = [select id from Account where Name = 'Test eBaySeller For Doc Approve 1'];
            List<EBH_Deal__c> lstDeal = [Select Id,Seller_Approver_1__c, 
                                Seller_Approver_2__c,
                                Seller_Approver_3__c,
                                Seller_Approver_4__c,
                                Seller_Approver_5__c,
                                Name, Deal_Contract_Agreement__c, EBH_BusinessName__c from EBH_Deal__c 
                                where EBH_BusinessName__c =: seller.Id AND Id =: d1.Id];
            List<DD_SendToSellerHelper.ContractAgreementWrapper> dcas = DD_SendToSellerHelper.createDealContractAgreement(lstDeal, new List<EBH_Deal__c>());  // Sophal:27/04/2021: US-0009436
            List<EBH_Deal__c> deals = [select Deal_Contract_Agreement__c, Deal_Contract_Agreement__r.Current_Digest__c,EBH_Status__c,EBH_BusinessName__c from EBH_Deal__c where id IN: lstDeal];
            Test.StartTest();
                PageReference docAp = Page.DocumentApproval;
                Test.setCurrentPage(docAp);
                docAp.getParameters().put('id', String.valueOf(deals[0].Deal_Contract_Agreement__r.Current_Digest__c));
                // US-0008605
                docAp.getParameters().put('approver', DD_SendToSellerHelper.generateSellerApproverToken(String.valueOf(deals[0].Deal_Contract_Agreement__r.Current_Digest__c) + contact.Email));
                DocumentApprovalController controller = new DocumentApprovalController();
                controller.checkDCAID();
                System.assert(!controller.rendered);
                System.assert(controller.alreadyreplied);
                System.assert(null==controller.latereply);
                System.assert(null==controller.ids);
                System.assert(null==controller.dealcontract);
                System.assert(null==controller.dealcontractname);
                // System.assert(null==controller.sellerName);
                System.assert(null==controller.sellerId);
                System.assert(null==controller.recordId);
                System.assert(null==controller.dealsJSON);
                System.assert(null==controller.latereply);
                
                System.assert(dcas.size()>0);
                deals[0].EBH_Status__c = 'Sent to Seller';
                update deals;
                controller.checkDCAID();
                System.assert(!controller.dealsWrapper.isEmpty());
                
                docAp.getParameters().put('status', 'Seller Approved');
                docAp.getParameters().put('index', '0');
                controller.changeStatus();
                DocumentApprovalController.signerName = 'test';
                
                controller.replicate_status = 'Seller Approved';
                controller.changeReplicateStatus();
                
                controller.replicate_reason = 'test';
                controller.doChangeReplicateReason();
                controller.checkNotSentToSeller(); // Sophal:29/04/2021: US-0009476
                controller.doSave();
                controller.sendPDF();
                controller.dealsWrapper[0].getDisplayDealStartTime();
                controller.dealsWrapper[0].getDisplayDealEndTime();

                controller.dealsWrapper[0].getDeal_Start_Date_Time_EST();
                controller.dealsWrapper[0].getDeal_End_Date_Time_EST();
            Test.StopTest();
            EBH_Deal__c deal = [select EBH_Status__c, EBH_CommentfromSeller__c, EBH_SellerAccepted__c, EBH_SellerEmail__c, Seller_Name__c from EBH_Deal__c where id IN: lstDeal];
            System.assertEquals('Seller Approved',deal.EBH_Status__c);
            System.assertEquals(contact.Email,controller.emailAddress);
            System.assertEquals(contact.Email,deal.EBH_SellerEmail__c);
            System.assertEquals('test',deal.Seller_Name__c);
            System.assertEquals('test',deal.EBH_CommentfromSeller__c);
        }
    }
    
    @isTest
    public static void test_DocApprovalPDF(){
        setupData();
            Account seller = [select id from Account  where Name = 'Test eBaySeller For Doc Approve 1'];
                List<EBH_Deal__c> lstDeal = [Select d.EBH_Quantity__c,d.EBH_MaximumPurchases__c,d.EBH_RRPWASPrice__c, d.EBH_eBayLink__c, d.EBH_BusinessName__c, d.EBH_CommentfromeBaySourcer__c,Seller_Approver_1__c,
                                                d.EBH_ProductTitle__c, 
                                                d.EBH_DealEndDate__c, d.EBH_DealStartDate__c,
                                                d.EBH_DealEndTime__c, EBH_DealStartTime__c,
                                                d.eBay_Seller_Name__c, d.EBH_eBayItemID__c, d.EBH_Vertical__c, 
                                                d.EBH_DealCalendarDescription__c, d.EBH_CommentfromSeller__c, 
                                                d.EBH_Status__c,
                                                d.EBH_Category__c, 
                                                d.Deal_Contract_Agreement__c,
                                                d.Deal_Contract_Agreement__r.CreatedById,
                                                d.Quantity_Limitation_per_Purchaser__c,
                                                d.EBH_DealPrice__c,d.List_Price__c,
                                                d.EBH_SellerPrice__c,
                                                d.EBH_Subsidy__c,
                                                d.ListPriceMSKULower__c,
                                                d.ListPriceMSKUUpper__c,
                                                d.SellersDealPriceMSKULower__c,
                                                d.SellersDealPriceMSKUUpper__c,
                                                d.SellersOfferPriceMSKULower__c,
                                                d.SellersOfferPriceMSKUUpper__c,
                                                Deal_Contract_Agreement__r.Current_Digest__c,
                                                d.Deal_Contract_agreement__r.Name,
                                                d.Seller_Approver_1__r.Email,
                                                d.Seller_Approver_2__r.Email,
                                                d.Seller_Approver_3__r.Email,
                                                d.Seller_Approver_4__r.Email,
                                                d.Seller_Approver_5__r.Email,
                                                d.Name,
                                                d.Optional_Notes__c,
                                                d.EBH_SubsidyP__c,
                                                d.Subsidy_Type__c
                                                From EBH_Deal__c d  
                                    where EBH_BusinessName__c =: seller.Id And Id =: d1.Id];
         Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c(RecordTypeId=ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals').Id);
        insert ndca;
       
        for(EBH_Deal__c d:lstDeal){
          d.Deal_Contract_Agreement__c=ndca.Id;
          d.EBH_Status__c = 'Seller Approved';
        }
        update lstDeal;
        Test.StartTest();
        System.debug('<<<<lstDeal[0].Id='+lstDeal[0].Id);
            PageReference PDf =  Page.DocumentApprovalPDF;
            PDf.getParameters().put('dcaid',ndca.Id);
            test.setCurrentPage(PDf);
            DocumentApprovalControllerPDF docPdf = new DocumentApprovalControllerPDF();
        Test.StopTest();                       
    }

    @isTest
    private static void test_resendPDF(){
        // Sophal:03/03/2022:US-0010859
        setupData();

        Account seller = [select id from Account  where Name = 'Test eBaySeller For Doc Approve 1'];
        seller.EBH_PrimarySite__c = 'Ebay';
        seller.NA_Contract_Type__c = 'Standard';
        update seller;

        Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c(RecordTypeId=ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals').Id);
        insert ndca;
       
        d1.Deal_Contract_Agreement__c=ndca.Id;
        d1.EBH_Status__c = 'Seller Approved';
        update d1;

        Test.StartTest();
            DocumentApprovalController.resendPDF(ndca.Id);
        Test.StopTest();                       
    }

}