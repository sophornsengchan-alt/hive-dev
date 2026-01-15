/*********************************************************************************************************************************
@ Class:          CancelDealItemsController
@ Version:        1.0
@ Author:         Sarom Chetra Nao (sarom.chetra@gaea-sys.com)
@ Purpose:        US-0013051 - Deal Contract Agreement - Cancel Deal Items
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 10.03.2023 / Sarom Chetra / Created the class.
*********************************************************************************************************************************/
@isTest
public class CancelDealItemsControllerTest {
	@TestSetup
    static void setup() {

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
        RecordType contactDWHRecordType = ApexUtil.getRecordTypeByName('Contact','EBH_DWH');

        Account eBaySeller1 = new Account (Name='Test eBaySeller For Doc Approve 1',ParentId = acc.Id,RecordTypeID = sellerRecordType.Id,SP_Promotions_Manager__c = 'Full Access');
        Account eBaySeller2 = new Account (Name='Test eBaySeller For Doc Approve 2',ParentId = acc.Id,RecordTypeID = sellerRecordType.Id,SP_Promotions_Manager__c = 'Full Access');
        insert new List<Account>{eBaySeller1,eBaySeller2};
        Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test1',
                                      email='test1@test.com' , AccountId = eBaySeller1.Id, RecordTypeID = contactDWHRecordType.Id);
        Contact contact2 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test2',
                                      email='test2@test.com' , AccountId = eBaySeller2.Id, RecordTypeID = contactDWHRecordType.Id);
        insert new List<Contact>{contact1,contact2};
    
        RecordType subDealRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2');
        Id devRecordTypeId = subDealRecordType.Id;

       	RecordType PMDCA = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Promotions_Manager_Deals');
        Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c(RecordTypeId = PMDCA.id);
        insert ndca;
        
        Time myTime = Time.newInstance(1, 1, 1, 1);
        List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>();
        for(Integer i = 1; i < 3; i++){
        	EBH_Deal__c d1 = new EBH_Deal__c(
            EBH_eBayItemID__c = '00000000001'+i, 
	        Seller_Approver_1__c = contact1.Id,
	        EBH_BusinessName__c=eBaySeller1.ID,
	        RecordTypeId=devRecordTypeId,
	        EBH_SellerPrice__c=20,EBH_DealPrice__c=5,
	        EBH_Quantity__c=2,EBH_DealStartTime__c = 
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
        RecordTypeId=devRecordTypeId,
        EBH_SellerPrice__c=20,EBH_DealPrice__c=5,
        EBH_Quantity__c=2,EBH_DealStartTime__c = 
        myTime,
        EBH_DealEndTime__c = myTime,
        EBH_Status__c='Internally Approved',
        EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',
        Sub_Category__c='Bedding', EBH_ProductTitle__c='product 1',
        EBH_SellerEmail__c='sales@test.com',Deal_Contract_Agreement__c = ndca.id);
        lstDeal.add(d2);
        insert lstDeal;
    }
    
    @IsTest
    private static void test_CancelApprovalProcess() {
        //testSetup();
        Id userId = UserInfo.getUserId();

        Account eBaySeller = [Select id From Account where Name ='Test eBaySeller For Doc Approve 1'];
        
        EBH_Deal__c deal1 = [select id,
                                Seller_Approver_1__r.Email,
                                Seller_Approver_2__r.Email,
                                Seller_Approver_3__r.Email,
                                Seller_Approver_4__r.Email,
                                Seller_Approver_5__r.Email,
                                Deal_Contract_Agreement__c,
                                EBH_BusinessName__c, 
                                OwnerId 
                            from EBH_Deal__c where EBH_BusinessName__r.Name = 'Test eBaySeller For Doc Approve 1' Limit 1];
    	EBH_Deal__c deal2 = [select id,
                                Seller_Approver_1__r.Email,
                                Seller_Approver_2__r.Email,
                                Seller_Approver_3__r.Email,
                                Seller_Approver_4__r.Email,
                                Seller_Approver_5__r.Email,
                                Deal_Contract_Agreement__c,
                                EBH_BusinessName__c, 
                                OwnerId 
                            from EBH_Deal__c where EBH_BusinessName__r.Name = 'Test eBaySeller For Doc Approve 2' Limit 1];
        List<EBH_Deal__c> listDeal = new List<EBH_Deal__c>{deal1,deal2};
        listDeal[0].Merchant_Approver__c = userId;
        listDeal[0].EBH_BusinessName__c = eBaySeller.Id;
        listDeal[1].Merchant_Approver__c = userId;
        listDeal[1].EBH_BusinessName__c = eBaySeller.Id;
        update listDeal;
        Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c(id = deal1.Deal_Contract_Agreement__c, Status__c='In Progress');
		update ndca;
        Test.startTest();
        PageReference pageRef = Page.CancelDealItems;
		Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', EncodingUtil.urlEncode(ndca.id, 'UTF-8'));
        
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(listDeal);
        ssc.setSelected(listDeal);
        CancelDealItemsController controller = new CancelDealItemsController(ssc);
        controller.cancellationReason = 'testCancel';
        controller.massCancelDeal();
		Test.stopTest();
        List<Seller_Communication__c> lstSellerCom = [select id,Email_Template__c from Seller_Communication__c];
        System.Assert(lstSellerCom.size() == 1,'only 1 seller com create because deal have the same seller');
        System.Assert(lstSellerCom[0].Email_Template__c == CancelDealItemsController.SELCOM_CANCEL_EMAILTEMPLATE);
    }
    
    @IsTest
    private static void test_confirmDeal() {
        List<EBH_Deal__c> listDeal = new List<EBH_Deal__c>{};
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(listDeal);
        ssc.setSelected(listDeal);
        CancelDealItemsController controller = new CancelDealItemsController(ssc);
        controller.cancellationReason = 'testCancel';
        controller.massCancelDeal();
        controller.confirmDeal();
        controller.cancel();
        controller.ok();
        controller.back();
        //controller.getCancellationReasonOptions();
    }
}