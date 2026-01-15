@isTest
private class DD_SendToSellerControllerTest {
    @testSetup
    static void setup(){
    	byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
        Deal_Timezone__c dealTimezone = new Deal_Timezone__c();
        dealTimezone.TimeZone__c='America/Los_Angeles';     
        insert dealTimezone;
        	RecordType sellerRecordTypeLeg = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity');
            Account acc = new Account(Name='Test Account Name: 1', BillingCountry='CH',RecordTypeID = sellerRecordTypeLeg.Id);
        insert acc;
        	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
            Account eBaySeller1 = new Account (Name='Test eBaySeller 1',EBH_OracleID__c ='12345',ParentId = acc.Id,RecordTypeID = sellerRecordType.Id);
            Account eBaySeller2 = new Account (Name='Test eBaySeller 2',EBH_OracleID__c ='12346',ParentId = acc.Id,RecordTypeID = sellerRecordType.Id);
            Account eBaySeller3 = new Account (Name='Test eBaySeller 3',EBH_OracleID__c ='12347',ParentId = acc.Id,RecordTypeID = sellerRecordType.Id);
            Account eBaySeller4 = new Account (Name='Acc IT Test',EBH_PrimarySite__c='Italy',EBH_RevRollup__c='IT',EBH_OracleID__c ='12348',ParentId = acc.Id,RecordTypeID = sellerRecordType.Id,SP_Deals__c = 'Full Access');
        insert new List<Account>{eBaySeller1,eBaySeller2,eBaySeller3,eBaySeller4};
        
            

        Id contRecId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('EBH_MANUAL').getRecordTypeId();
        RecordType contactRecordType = ApexUtil.getRecordTypeByName('Contact','EBH_DWH');
        Contact contact0 = new Contact(FirstName='Test',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = eBaySeller4.Id,RecordTypeId = contactRecordType.Id);

        Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = eBaySeller1.Id,
                                      // US-0009044 / 26.01.2021 / Sophal Noch
                                      //Contact_Role__c = 'Marketplaces - Daily Deals Contracts',EBH_Decision_Maker_Role__c = 'Deals', //MN:13/05/2021:US-0009542 - [NA] Deals: Remove unused value from 'Decision Maker Role' on Contact
                                      Contact_Role__c = 'Deals;Marketplaces - Daily Deals Contracts',
                                      RecordTypeId = contRecId
                                      );
        Contact contact2 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test2',
                                      email='test2@test.com' , AccountId = eBaySeller2.Id,
                                      // US-0009044 / 26.01.2021 / Sophal Noch
                                      //Contact_Role__c = 'Marketplaces - Daily Deals Contracts',EBH_Decision_Maker_Role__c = 'Deals', //MN:13/05/2021:US-0009542 - [NA] Deals: Remove unused value from 'Decision Maker Role' on Contact
                                      Contact_Role__c = 'Deals;Marketplaces - Daily Deals Contracts',
                                      RecordTypeId = contRecId);
        Contact contact3 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test3',
                                      email='test3@test.com' ,AccountId = eBaySeller3.Id,
                                      // US-0009044 / 26.01.2021 / Sophal Noch
                                      //Contact_Role__c = 'Marketplaces - Daily Deals Contracts',EBH_Decision_Maker_Role__c = 'Deals', //MN:13/05/2021:US-0009542 - [NA] Deals: Remove unused value from 'Decision Maker Role' on Contact
                                      Contact_Role__c = 'Deals;Marketplaces - Daily Deals Contracts',
                                      RecordTypeId = contRecId);
        insert new List<Contact>{contact0,contact1,contact2,contact3};                                                            
        /*ebay_Seller_Contacts__c eBaySellerCon = new ebay_Seller_Contacts__c(Contact__c = contact.Id, eBay_Seller__c = eBaySeller.Id);
        ebay_Seller_Contacts__c eBaySellerCon2 = new ebay_Seller_Contacts__c(Contact__c = contact2.Id, eBay_Seller__c = eBaySeller.Id);
        ebay_Seller_Contacts__c eBaySellerCon3 = new ebay_Seller_Contacts__c(Contact__c = contact3.Id, eBay_Seller__c = eBaySeller.Id);
        insert new List<ebay_Seller_Contacts__c>{eBaySellerCon,eBaySellerCon2,eBaySellerCon3};*/
        EBH_SpotlightCategory__c spotCat = new EBH_SpotlightCategory__c(Name = 'test spotLightCat',EBH_Country__c ='NA');
            EBH_SpotlightCategory__c spotCat2 = new EBH_SpotlightCategory__c(Name = 'test spotLightCat2',EBH_Country__c ='NA');
            EBH_SpotlightCategory__c  spotCat3 = new EBH_SpotlightCategory__c (Name = 'test spotLightCat3',EBH_Country__c ='NA');
            insert new List<EBH_SpotlightCategory__c>{spotCat,spotCat2,spotCat3};
            Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c(RecordTypeId=ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals').Id);
            insert ndca;
            //MN-17082022-US-0011119-Remove reference with old record type name
            // Id devRecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('NA Deal').getRecordTypeId();
            RecordType subDealRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2');
            Id devRecordTypeId = subDealRecordType.Id;

            // Date myDate = System.today();
            Date myDate = System.today().addDays(1); // 28.05.2021 / Sophal Noch / US-0009533
        EBH_Deal__c d1 = new EBH_Deal__c(EBH_eBayItemID__c  = '000000000010', Seller_Approver_1__c = contact1.Id,EBH_BusinessName__c =eBaySeller1.ID,EBH_SpotlightCategory__c = spotCat.Id,RecordTypeId=devRecordTypeId,EBH_SellerPrice__c =20,EBH_DealPrice__c =5,EBH_Quantity__c =2,EBH_DealStartDate__c =myDate,EBH_DealEndDate__c =myDate,EBH_Status__c='Internally Approved',EBH_DealSiteId__c = '0',EBH_Vertical__c = 'Home & Garden',EBH_Category__c ='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c ='product 1',EBH_SellerEmail__c ='sales@test.com',Deal_Contract_Agreement__c=ndca.Id);
        EBH_Deal__c d2 = new EBH_Deal__c(EBH_eBayItemID__c  = '000000000011', Seller_Approver_1__c = contact2.Id, Seller_Approver_2__c = contact2.Id,EBH_BusinessName__c =eBaySeller2.ID,EBH_SpotlightCategory__c = spotCat2.Id,RecordTypeId=devRecordTypeId,EBH_SellerPrice__c =20,EBH_DealPrice__c =5,EBH_Quantity__c =2,EBH_DealStartDate__c =myDate,EBH_DealEndDate__c =myDate,EBH_Status__c='Internally Approved',EBH_DealSiteId__c = '0', EBH_Vertical__c = 'Home & Garden',EBH_Category__c ='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c ='product 2',EBH_SellerEmail__c ='sales@test.com');
        EBH_Deal__c d3 = new EBH_Deal__c(EBH_eBayItemID__c  = '000000000012', Seller_Approver_1__c = contact3.Id, Seller_Approver_3__c = contact3.Id,EBH_BusinessName__c =eBaySeller3.ID,EBH_SpotlightCategory__c = spotCat3.Id,RecordTypeId=devRecordTypeId,EBH_SellerPrice__c =10,EBH_DealPrice__c =5,EBH_SoldItems__c =2,EBH_DealStartDate__c =myDate,EBH_DealEndDate__c =myDate,EBH_Status__c='Internally Approved',EBH_DealSiteId__c = '0', EBH_Vertical__c = 'Home & Garden',EBH_Category__c ='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c ='product 3',EBH_SellerEmail__c ='sales@test.com',EBH_Quantity__c=1);
        
        EBH_Deal__c d4 = new EBH_Deal__c(EBH_eBayItemID__c  = '000000000013', Seller_Approver_1__c = contact1.Id,EBH_BusinessName__c =eBaySeller4.ID,EBH_SpotlightCategory__c = spotCat.Id,RecordTypeId=devRecordTypeId,EBH_SellerPrice__c =20,EBH_DealPrice__c =5,EBH_Quantity__c =2,EBH_DealStartDate__c =myDate,EBH_DealEndDate__c =myDate,EBH_Status__c='New',EBH_DealSiteId__c = '101',EBH_Vertical__c = 'Home & Garden',EBH_Category__c ='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c ='product 1',EBH_SellerEmail__c ='sales@test.com');
        EBH_Deal__c d5 = new EBH_Deal__c(EBH_eBayItemID__c  = '000000000014', Seller_Approver_1__c = contact2.Id, Seller_Approver_2__c = contact2.Id,EBH_BusinessName__c =eBaySeller4.ID,EBH_SpotlightCategory__c = spotCat2.Id,RecordTypeId=devRecordTypeId,EBH_SellerPrice__c =20,EBH_DealPrice__c =5,EBH_Quantity__c =2,EBH_DealStartDate__c =myDate,EBH_DealEndDate__c =myDate,EBH_Status__c='New',EBH_DealSiteId__c = '101', EBH_Vertical__c = 'Home & Garden',EBH_Category__c ='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c ='product 2',EBH_SellerEmail__c ='sales@test.com');
        EBH_Deal__c d6 = new EBH_Deal__c(EBH_eBayItemID__c  = '000000000015', Seller_Approver_1__c = contact3.Id, Seller_Approver_3__c = contact3.Id,EBH_BusinessName__c =eBaySeller4.ID,EBH_SpotlightCategory__c = spotCat3.Id,RecordTypeId=devRecordTypeId,EBH_SellerPrice__c =10,EBH_DealPrice__c =5,EBH_SoldItems__c =2,EBH_DealStartDate__c =myDate,EBH_DealEndDate__c =myDate,EBH_Status__c='New',EBH_DealSiteId__c = '101', EBH_Vertical__c = 'Home & Garden',EBH_Category__c ='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c ='product 3',EBH_SellerEmail__c ='sales@test.com',EBH_Quantity__c=1);
        List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>{d1,d2,d3,d4,d5,d6};
        insert lstDeal;
    }
    @isTest 
    public static void test_sentToSellerAction(){
        List<EBH_Deal__c> lstDeal = [select id from EBH_Deal__c where EBH_BusinessName__r.Name like 'Test eBaySeller%'];
        Test.startTest();
            ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstDeal);
            ssc.setSelected(lstDeal);
            DD_SendToSellerController controller = new DD_SendToSellerController(ssc);
            
            //controller.sentToSellerAction(); // Sophal:27/04/2021: US-0009436 use client to request
            // DD_SendToSellerController.sentToSellerAction(controller.lstAllDealId,new List<Id>(), new List<Id>(), new List<Id>()); // Sophal:27/04/2021: US-0009436 for running at first chunk
            
            /*

            // Sophal:24/06/2021: US-0009754 no longer use static method

            DD_SendToSellerController.sentToSellerAction(controller.lstAllDealId,new List<Id>(),controller.lstAllDealId, new List<Id>()); // Sophal:27/04/2021: US-0009436 for internal approval
            DD_SendToSellerController.sentToSellerAction(controller.lstAllDealId,new List<Id>(), new List<Id>(), controller.lstAllDealId); // Sophal:27/04/2021: US-0009436  for send to seller
            DD_SendToSellerController.sendEmailToSellerAction(controller.lstAllDealId); // Sophal:27/04/2021: US-0009436
            
            */

            controller.sentToSellerAction();// Sophal:24/06/2021: US-0009754 
            controller.sendEmailToSellerAction(); // Sophal:24/06/2021: US-0009754 

            controller.cancel();
        Test.stopTest();
        List<EBH_Deal__c> lstDealSel = [select Deal_Contract_Agreement__c,EBH_BusinessName__c,EBH_Status__c from EBH_Deal__c where id IN: lstDeal];
        System.assert(lstDealSel.size() == 3);
        for(EBH_Deal__c deal : lstDealSel){
            System.assert(deal.Deal_Contract_Agreement__c != null);
            System.assertEquals('Sent to Seller',deal.EBH_Status__c);
        }
    }
    @isTest 
    public static void test_sentToSellerActionIT(){
        List<EBH_Deal__c> lstDeal = [select id from EBH_Deal__c where EBH_BusinessName__r.Name like 'Acc IT Test%'];
        Test.startTest();
            ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstDeal);
            ssc.setSelected(lstDeal);
            DD_SendToSellerController controller = new DD_SendToSellerController(ssc);
            
            //controller.sentToSellerAction(); // Sophal:27/04/2021: US-0009436 use client to request
            // DD_SendToSellerController.sentToSellerAction(controller.lstAllDealId,new List<Id>(), new List<Id>(), new List<Id>()); // Sophal:27/04/2021: US-0009436 for running at first chunk
            
            /*

            // Sophal:24/06/2021: US-0009754 no longer use static method

            DD_SendToSellerController.sentToSellerAction(controller.lstAllDealId,new List<Id>(),controller.lstAllDealId, new List<Id>()); // Sophal:27/04/2021: US-0009436 for internal approval
            DD_SendToSellerController.sentToSellerAction(controller.lstAllDealId,new List<Id>(), new List<Id>(), controller.lstAllDealId); // Sophal:27/04/2021: US-0009436  for send to seller
            DD_SendToSellerController.sendEmailToSellerAction(controller.lstAllDealId); // Sophal:27/04/2021: US-0009436
            
            */

            controller.sentToSellerAction();// Sophal:24/06/2021: US-0009754 
            controller.sendEmailToSellerAction(); // Sophal:24/06/2021: US-0009754 

            controller.cancel();
        Test.stopTest();
        List<EBH_Deal__c> lstDealSel = [select Deal_Contract_Agreement__c,EBH_BusinessName__c,EBH_Status__c from EBH_Deal__c where id IN: lstDeal];
        System.assert(lstDealSel.size() == 3);
        for(EBH_Deal__c deal : lstDealSel){
            System.assert(deal.Deal_Contract_Agreement__c != null);
            System.assertEquals('Sent to Seller',deal.EBH_Status__c);
        }
    }
    @isTest 
    public static void test_isNotInternalApproved(){

            Id contRecId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('EBH_MANUAL').getRecordTypeId();

            RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
            Account eBaySeller1 = new Account (Name='Test 1',EBH_OracleID__c ='5758657',RecordTypeID = sellerRecordType.Id);
        	insert eBaySeller1;
        	Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = eBaySeller1.Id);
        	insert contact1;
        	Account acc = [select id from Account where Name = 'Test 1'];
            Contact c = [select id,Email from Contact where AccountId =: acc.Id limit 1];

            // US-0009044 / 26.01.2021 / Sophal Noch
            c.AccountId = eBaySeller1.Id;
            c.Contact_Role__c = 'Deals;Marketplaces - Daily Deals Contracts';
            //c.EBH_Decision_Maker_Role__c = 'Deals'; //MN:13/05/2021:US-0009542 - [NA] Deals: Remove unused value from 'Decision Maker Role' on Contact
            c.RecordTypeId = contRecId;
            update c;

            EBH_SpotlightCategory__c spotCat = [select id from EBH_SpotlightCategory__c where Name = 'test spotLightCat'];
            //MN-17082022-US-0011119-Remove reference with old record type name
            // Id devRecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('NA Deal').getRecordTypeId();
            RecordType subDealRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2');
            Id devRecordTypeId = subDealRecordType.Id;
            
            Account eBaySeller = new Account(Name='Test eBaySeller 4',EBH_OracleID__c='12348');
            Date myDate = System.today();
            EBH_Deal__c d = new EBH_Deal__c(EBH_eBayItemID__c = '000000000013',Seller_Approver_1__c = c.Id, EBH_BusinessName__c=eBaySeller1.ID,EBH_SpotlightCategory__c = spotCat.Id,RecordTypeId=devRecordTypeId,EBH_SellerPrice__c=20,EBH_DealPrice__c=5,EBH_Quantity__c=2,EBH_DealStartDate__c=myDate+4,EBH_DealEndDate__c=myDate+5,EBH_Status__c='New',EBH_DealSiteId__c = '0', EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c='product 4',EBH_SellerEmail__c='sales@test.com');
            insert d;
            Test.startTest();
                List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>{d};
                ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstDeal);
                ssc.setSelected(lstDeal);
                DD_SendToSellerController controller = new DD_SendToSellerController(ssc);
                // controller.sentToSellerAction(); // Sophal:27/04/2021: US-0009436 use client to request
                
                /*

                // Sophal:24/06/2021: US-0009754 no longer use static method
                
                DD_SendToSellerController.sentToSellerAction(controller.lstAllDealId, new List<Id>(),new List<Id>(),new List<Id>()); // Sophal:27/04/2021: US-0009436
                DD_SendToSellerController.sentToSellerAction(controller.lstAllDealId,new List<Id>(), controller.lstAllDealId, new List<Id>()); // Sophal:27/04/2021: US-0009436 for internal approval
                DD_SendToSellerController.sentToSellerAction(controller.lstAllDealId,new List<Id>(), new List<Id>(), controller.lstAllDealId); // Sophal:27/04/2021: US-0009436  for send to seller
                DD_SendToSellerController.sendEmailToSellerAction(controller.lstAllDealId); // Sophal:27/04/2021: US-0009436
                
                */

                controller.sentToSellerAction();// Sophal:24/06/2021: US-0009754 
                controller.sendEmailToSellerAction(); // Sophal:24/06/2021: US-0009754 

            Test.stopTest();
            System.assert(controller.isNotInternalApproved);
           
    }
    
    @isTest 
    public static void test_NoEmailFound(){

            Id contRecId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('EBH_MANUAL').getRecordTypeId();

        	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
            Account eBaySeller1 = new Account (Name='Test 1',EBH_OracleID__c ='5758657',RecordTypeID = sellerRecordType.Id);
        	insert eBaySeller1;
        	Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = eBaySeller1.Id);
        	insert contact1;
            Account acc = [select id from Account where Name = 'Test 1'];
            Contact c = [select id,Email from Contact where AccountId =: acc.Id limit 1];

            // US-0009044 / 26.01.2021 / Sophal Noch
            c.Email = null;
            c.AccountId = eBaySeller1.Id;
            c.Contact_Role__c = 'Deals;Marketplaces - Daily Deals Contracts';
            //c.EBH_Decision_Maker_Role__c = 'Deals'; //MN:13/05/2021:US-0009542 - [NA] Deals: Remove unused value from 'Decision Maker Role' on Contact
            c.RecordTypeId = contRecId;
            update c;
            EBH_SpotlightCategory__c spotCat = [select id from EBH_SpotlightCategory__c where Name = 'test spotLightCat'];
            //MN-17082022-US-0011119-Remove reference with old record type name
            // Id devRecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('NA Deal').getRecordTypeId();
            RecordType subDealRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2');
            Id devRecordTypeId = subDealRecordType.Id;

            Account eBaySeller = new Account(Name='Test eBaySeller 4',EBH_OracleID__c='12348');
            Date myDate = System.today();
            EBH_Deal__c d = new EBH_Deal__c(EBH_eBayItemID__c = '000000000014',Seller_Approver_1__c = c.Id, EBH_BusinessName__c=eBaySeller1.ID,EBH_SpotlightCategory__c = spotCat.Id,RecordTypeId=devRecordTypeId,EBH_SellerPrice__c=20,EBH_DealPrice__c=5,EBH_Quantity__c=2,EBH_DealStartDate__c=myDate+4,EBH_DealEndDate__c=myDate+5,EBH_Status__c='Internally Approved',EBH_DealSiteId__c = '0', EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c='product 4',EBH_SellerEmail__c='sales@test.com');
            insert d;
            try{
                Test.startTest();
                    List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>{d};
                    ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstDeal);
                    ssc.setSelected(lstDeal);
                    DD_SendToSellerController controller = new DD_SendToSellerController(ssc);
                    // controller.sentToSellerAction();  // Sophal:27/04/2021: US-0009436 use client to request
                    // DD_SendToSellerController.sentToSellerAction(controller.lstAllDealId,new List<Id>(), new List<Id>(), new List<Id>());  // Sophal:27/04/2021: US-0009436 for run at first chunk
                    
                    /*

                    // Sophal:24/06/2021: US-0009754 no longer use static method                    
                    
                    DD_SendToSellerController.sentToSellerAction(controller.lstAllDealId,new List<Id>(), controller.lstAllDealId, new List<Id>()); // Sophal:27/04/2021: US-0009436 for internal approval
                    DD_SendToSellerController.sentToSellerAction(controller.lstAllDealId,new List<Id>(), new List<Id>(), controller.lstAllDealId); // Sophal:27/04/2021: US-0009436  for send to seller
                    DD_SendToSellerController.sendEmailToSellerAction(controller.lstAllDealId);  // Sophal:27/04/2021: US-0009436 
                    
                    */

                    controller.sentToSellerAction();// Sophal:24/06/2021: US-0009754 
                    controller.sendEmailToSellerAction(); // Sophal:24/06/2021: US-0009754 

                Test.stopTest();
            }catch(Exception e){
                System.assert(e.getMessage().contains('No Email Found in the following Contact'));
            }
    }
}