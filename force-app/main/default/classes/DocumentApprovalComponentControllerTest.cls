/**
 * Test class for DocumentApprovalComponentController
 */
@isTest
private class DocumentApprovalComponentControllerTest {

    static testMethod void myUnitTest() {
        byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
        
        Deal_Timezone__c dealTimezone = new Deal_Timezone__c();
        dealTimezone.TimeZone__c='America/Los_Angeles';     
        insert dealTimezone;
        RecordType rect_legal = ApexUtil.getRecordTypeByName('Account', 'EBH_LegalEntity');
        RecordType rect_seller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        
        Account acc = new Account(Name='La Test Account Name: 1', BillingCountry='CH',RecordTypeId=rect_legal.Id);
        insert acc;
        Account eBaySeller = new Account (Name='La Test eBaySeller For Doc Approve 1',ParentId = acc.Id,RecordTypeId=rect_seller.Id);
        insert eBaySeller;
        /*Account acc  = new Account();
        acc.Name            = 'Test Account Name: 1';
        acc.BillingCountry  = 'CH';
        insert acc;
        Deal_Timezone__c dealTimezone = new Deal_Timezone__c();
        dealTimezone.TimeZone__c='America/Los_Angeles';     
        insert dealTimezone;
        eBay_Seller__c eBaySeller = new eBay_Seller__c ();
        eBaySeller.Name                   = 'Test eBaySeller Contract Control 1';
        eBaySeller.Account__c             = acc.Id;
        eBaySeller.GMV_Full_Yr_Goal__c    = 1500;
        eBaySeller.Oracle_ID__c           = '12345';
        eBaySeller.Daily_Deals_Whitelist__c = true;
        insert eBaySeller;*/
        
        Contact contact = new Contact();
        contact.MailingCountry  = 'USA';
        contact.MailingState    = 'TX';
        contact.MailingCity     = 'Dallas';
        contact.FirstName       = 'firstname';
        contact.Salutation      = 'Mr.';
        contact.LastName        = 'test1';
        contact.Email           = 'test1@test.com';
        contact.AccountId       = eBaySeller.Id;  
        //Contact.EBH_Decision_Maker_Role__c ='Deals';
        insert contact;
        
        EBH_SpotlightCategory__c spotCat = new EBH_SpotlightCategory__c();
        spotCat.Name                     = 'test spotLightCat';
        spotCat.EBH_Country__c           = 'NA';
        spotCat.EBH_SpotlightCategoryID__c = 'testSpotId';
        insert spotCat;
        
        Date myDate        = System.today().addDays(2);
        Time myTime = Time.newInstance(11, 11, 1, 1);
        Id naRecordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id;//Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('eBay NA').getRecordTypeId();

        Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c(RecordTypeId=ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals').Id);
        insert ndca;
            
        EBH_Deal__c d1 = new EBH_Deal__c();
        d1.EBH_eBayItemID__c          = '000000000010';
        d1.Seller_Approver_1__c       = contact.Id;
        d1.EBH_BusinessName__c        = eBaySeller.ID;
        d1.EBH_SpotlightCategory__c   = spotCat.Id;
        d1.RecordTypeId               = naRecordTypeId;
        d1.EBH_SellerPrice__c         = 20;
        d1.EBH_DealPrice__c           = 5;
        d1.EBH_Quantity__c            = 2;
        d1.EBH_DealStartDate__c       = myDate;
        d1.EBH_DealEndDate__c         = myDate;
        d1.EBH_DealStartTime__c       = myTime;
        d1.EBH_DealEndTime__c         = myTime;
        d1.EBH_Status__c              = 'Internally Approved';  //= 'Cancelled';
        d1.EBH_Vertical__c            = 'Fashion';
        d1.EBH_Category__c            = 'Health';
        d1.EBH_ProductTitle__c        = 'product 1';
        d1.EBH_SellerEmail__c         = 'sales@test.com';
        d1.Deal_Contract_Agreement__c = ndca.id;
        d1.SiteURL__c= ApexUtil.getSiteUrl('Deal_Acceptance');
		d1.Unique_Id_Ext__c = EncodingUtil.urlEncode(ApexUtil.genUniqueString(30), 'UTF-8');
        //d1.Cancellation_Date_Time__c = System.Now();
        insert d1;
        
        DD_SendToSellerHelper.convertTContractAgreementWrapper(New List<EBH_Deal__c>{d1}, new List<EBH_Deal__c>());
        DD_SendToSellerHelper.createDealContractAgreement(New List<EBH_Deal__c>{d1}, new List<EBH_Deal__c>());
        
        d1.EBH_Status__c             = 'Cancelled';
        d1.Cancellation_Date_Time__c = System.Now();
        Update d1;
        Test.startTest();
        List<EBH_Deal__c> dContr = [SELECT Id,
                                    	EBH_Status__c,
                                        Current_Digest__c,
                                        Deal_Contract_Agreement__c,
                                        Deal_Contract_Agreement__r.Current_Digest__c,
                                        Deal_Contract_Seller_Name__c,
                                        SiteURL__c
                                        FROM EBH_Deal__c WHERE Id =:d1.Id];	
        DocumentApprovalComponentController controller = new DocumentApprovalComponentController();
        controller.isPreview = false;
        controller.dealStatus = 'Cancelled';
        controller.dealAgreementlId = dContr[0].Deal_Contract_Agreement__c;
        Test.stopTest();
        System.assertEquals(1,controller.getdealsWrapper().size());
    }
    
}