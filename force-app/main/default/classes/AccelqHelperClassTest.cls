//Test class for AccelqHelperClass
@isTest
public class AccelqHelperClassTest {
    @testSetup static void setUp() {
        User admin = EBH_TestDataFactory.createUser('System Administrator');
    	System.runAs(admin)
    	{
               Test.startTest();
                    RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
                    Account acc = new Account(
                                Name = 'Seller_1',
                                EBH_RevRollup__c = 'UK',
                                EBH_PrimarySite__c= 'UK',
                                EBH_DealsProgram__c='Accepted',
                                RecordTypeId = sellerRecordType.Id,
                                SP_Coupons__c = 'Full Access'
                                );
                    insert acc;

                    Contact cont = new Contact(
                                LastName = 'SellerContact_1',
                                Email='test@test.com.invalid', 
                                AccountId=acc.Id);
                    insert cont;

                    RecordType couponRecordTypeItem = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
                    Coupon__c c1 = new Coupon__c(Main_Coupon_Site__c = 'ebay.co.uk',Coupon_Co_invest_Type__c='Contra',MC_Whitelisted__c = true,Stage__c = 'Draft', RecordTypeID = couponRecordTypeItem.Id,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c=System.today(),Contract_Due_Date__c = System.today()-1);
                    insert new List<Coupon__c>{c1};
                    
                    RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
                    Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Review',Seller_Contact__c=cont.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc.Id,RecordTypeID=manhattanCouponSellerRecordType.Id);
                    Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,Coupon_Seller_Stage__c='Contract Negotiation',Seller_Contact__c=cont.Id,EBH_CouponSellerOwner__c = UserInfo.getUserId(),Seller__c = acc.Id,RecordTypeID=manhattanCouponSellerRecordType.Id);
                    insert new List<Coupon_Seller__c>{cs1,cs2};
                    
                    Coupon_Co_Invest__c coInvest1 = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id,Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Co_Invest__c=10);
                    Coupon_Co_Invest__c coInvest2 = new Coupon_Co_Invest__c(Coupon_Seller__c=cs2.Id,Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Co_Invest__c=10);
                    List<Coupon_Co_Invest__c> lstCCI = new List<Coupon_Co_Invest__c>{coInvest1,coInvest2}; 
                    insert lstCCI;
                    
                Test.stopTest();
            }     
               
    }

    @isTest static void testDeleteRecords() {
        
        List<Coupon__c> listCS = [select id from Coupon__c limit 1];
       
        // Call the method to test
        Test.startTest();
        AccelqHelperClass.deleteRecords(UserInfo.getUserId(), 'DeleteCoupon');
        Test.stopTest();

        
    }
    @isTest static void testCreateRecord() {
        RecordType contactRecTypeDWH = ApexUtil.getRecordTypeByName('Contact','EBH_DWH');
        List<Account> listAcc = [select id from Account limit 1];
        
        Map<String, Object> fieldsValuesMap = new Map<String, Object>();
        fieldsValuesMap.put('Salutation', 'Mr.');
        fieldsValuesMap.put('FirstName', 'Test');
        fieldsValuesMap.put('LastName', 'Contact02');
        fieldsValuesMap.put('Email', 'contact.test02@test.com');
        fieldsValuesMap.put('RecordTypeId', contactRecTypeDWH.Id);
        fieldsValuesMap.put('AccountId', listAcc[0].Id);
        // Call the method to test
        Test.startTest();
            AccelqHelperClass.createRecord(UserInfo.getUserId(), 'Contact', JSON.serialize(fieldsValuesMap));
            List<Contact> listContacts = [select id, Name, Email, RecordTypeId, AccountId from Contact Where Name = 'Test Contact02' and AccountId =: listAcc[0].Id];
            System.assertEquals(1, listContacts.size());
            System.assertEquals('Test Contact02', listContacts[0].Name);
            System.assertEquals('contact.test02@test.com', listContacts[0].Email);
            System.assertEquals(contactRecTypeDWH.Id, listContacts[0].RecordTypeId);
            System.assertEquals(listAcc[0].Id, listContacts[0].AccountId);
        Test.stopTest();
    }
}