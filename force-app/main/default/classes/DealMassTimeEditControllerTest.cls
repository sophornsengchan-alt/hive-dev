/*********************************************************************************************************************************
@ Class:          DealMassTimeEditControllerTest
@ Version:        1.0
@ Author:         Loumang SENG (loumang.seng@gaea-sys.com)
@ Purpose:        test Class for DealMassTimeEditController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.10.2020 / Loumang SENG / Created the class.
*********************************************************************************************************************************/
@isTest
private class DealMassTimeEditControllerTest {
    @testSetup static void testSetup() {

        EBH_TestDataFactory.setUpCustomSettings();   
        ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = false;
		insert avr;

        byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;


        RecordType sellerRecordTypeLeg = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity');
    	Account acc = new Account(Name='Test Account Name: 1', BillingCountry='CH',RecordTypeID = sellerRecordTypeLeg.Id);
        insert acc;
        
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');

        Account eBaySeller1 = new Account (Name='Test eBaySeller For Doc Approve 1',ParentId = acc.Id,RecordTypeID = sellerRecordType.Id);
        Account eBaySeller2 = new Account (Name='Test eBaySeller For Doc Approve 2',ParentId = acc.Id,RecordTypeID = sellerRecordType.Id);
        insert new List<Account>{eBaySeller1,eBaySeller2};
        Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = eBaySeller1.Id);
        Contact contact2 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test2',
                                      email='test2@test.com' , AccountId = eBaySeller2.Id);
        insert new List<Contact>{contact1,contact2};
            
        Date myDate = System.Today().adddays(2);
        EBH_SpotlightCategory__c spotCat = new EBH_SpotlightCategory__c(Name = 'test spotLightCat',EBH_Country__c='UK',EBH_SpotlightCategoryID__c='1243545',Spotlight_Start_Date__c=myDate,Spotlight_End_Date__c=myDate);
        insert spotCat;
        //MN-17082022-US-0011119-Remove reference with old record type name
        // Id devRecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('NA Deal').getRecordTypeId();
        RecordType subDealRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2');
        Id devRecordTypeId = subDealRecordType.Id;

        Id stdDealRTId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(); 
        Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c();
        insert ndca;
        
        Time myTime = Time.newInstance(1, 1, 1, 1);
        List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>();
        for(Integer i = 1; i < 3; i++){
        	EBH_Deal__c d1 = new EBH_Deal__c(
            EBH_eBayItemID__c = '00000000001'+i, 
	        Seller_Approver_1__c = contact1.Id,
	        EBH_BusinessName__c=eBaySeller1.ID,
	        EBH_SpotlightCategory__c = spotCat.Id,
	        RecordTypeId=devRecordTypeId,
	        EBH_SellerPrice__c=20,EBH_DealPrice__c=5,
	        EBH_Quantity__c=2,EBH_DealStartDate__c=myDate,
	        EBH_DealEndDate__c=myDate,EBH_DealStartTime__c = 
	        myTime,
	        EBH_DealEndTime__c = myTime,
	        EBH_Status__c='Internally Approved',
            EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',
	        Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1',
	        EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id);
	        lstDeal.add(d1);
        }
        
        EBH_Deal__c d2 = new EBH_Deal__c(
        EBH_eBayItemID__c = '000000000010', 
        Seller_Approver_1__c = contact2.Id,
        EBH_BusinessName__c=eBaySeller2.ID,
        EBH_SpotlightCategory__c = spotCat.Id,
        RecordTypeId=devRecordTypeId,
        EBH_SellerPrice__c=20,EBH_DealPrice__c=5,
        EBH_Quantity__c=2,EBH_DealStartDate__c=myDate,
        EBH_DealEndDate__c=myDate,EBH_DealStartTime__c = 
        myTime,
        EBH_DealEndTime__c = myTime,
        EBH_Status__c='Internally Approved',
        EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',
        Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1',
        EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id);
        lstDeal.add(d2);
        insert lstDeal;

        

    }
    
    @isTest
    public static void singleUpdateTest() {
        List<EBH_Deal__c> lstDealSeller = [select id,OwnerId,EBH_DealStartTime__c,EBH_DealEndTime__c from EBH_Deal__c where EBH_BusinessName__r.Name = 'Test eBaySeller For Doc Approve 1'];
    	List<EBH_Deal__c> lstDealSeller2 = [select id,OwnerId,EBH_DealStartTime__c,EBH_DealEndTime__c from EBH_Deal__c where EBH_BusinessName__r.Name = 'Test eBaySeller For Doc Approve 2'];
        Test.startTest();
    		//test error no profile with permissionset
        	System.runAs(EBH_TestDataFactory.createUser('Standard User Profile')) { 
                    ApexPages.StandardSetController ssc0 = new ApexPages.StandardSetController(new List<EBH_Deal__c>());
            		ssc0.setSelected(new List<EBH_Deal__c>());
            		DealMassTimeEditController controller0 = new DealMassTimeEditController(ssc0);
            }
            
            List<User> admins = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' and isActive = true LIMIT 2];
            System.runAs(admins[0]) {

                //test success updated
                ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstDealSeller);
                ssc.setSelected(lstDealSeller);
                DealMassTimeEditController controller = new DealMassTimeEditController(ssc);
                controller.isError = false;
                controller.isUpdateError = false;
                controller.errormessage = '';
                DateTime startDate = DateTime.newInstance(2006, 3, 16, 4, 0, 0);
                DateTime endDate = DateTime.newInstance(2006, 3, 16, 5, 0, 0);
                controller.startTime = startDate.time();
                controller.endTime = endDate.time();
                controller.updateDeal();
                        
                List<EBH_Deal__c> dealsupdated = [SELECT Id,OwnerId,EBH_DealStartDate__c,EBH_DealEndDate__c,EBH_DealStartTime__c,EBH_DealEndTime__c FROM EBH_Deal__c WHERE Id =: lstDealSeller];
                for (EBH_Deal__c d : dealsupdated) {
                    System.debug('**** d :: ' + d);
                    System.debug('**** controller :: ' + controller);
                    System.assertEquals(d.EBH_DealStartTime__c, controller.startTime);
                    System.assertEquals(d.EBH_DealEndTime__c, controller.endTime);
                    
                }
                controller.cancel();
                //test error null startTime,endTime
                List<EBH_Deal__c> ListDeal2 = new List<EBH_Deal__c>();
                ListDeal2.addall(lstDealSeller2);
                ApexPages.StandardSetController ssc2 = new ApexPages.StandardSetController(ListDeal2);
                ssc2.setSelected(ListDeal2);
                DealMassTimeEditController controller2 = new DealMassTimeEditController(ssc);
                controller2.startTime = null;
                controller2.endTime = null;
                controller2.updateDeal();
            }

    	Test.stopTest();
                
        
     }

}