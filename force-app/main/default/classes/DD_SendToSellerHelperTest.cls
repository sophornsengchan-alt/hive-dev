@isTest
private class DD_SendToSellerHelperTest {

    static testMethod void convertTContractAgreementWrapperTest(){
        byPass__c settings = byPass__c.getOrgDefaults();
        settings.ByPass_Validation__c = true;
        upsert settings byPass__c.Id;
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Date myDate = System.today();
        //MN-17082022-US-0011119-Remove reference with old record type name
        // Id devRecordTypeId = Schema.SObjectType.EBH_Deal__c.getRecordTypeInfosByName().get('NA Deal').getRecordTypeId();
        RecordType subDealRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2');
        Id devRecordTypeId = subDealRecordType.Id;
        
        Account eBaySeller1 = new Account (Name='Test 1',EBH_OracleID__c ='5758657',RecordTypeID = sellerRecordType.Id);
        insert eBaySeller1;
        
        Contact contact1 = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                           FirstName='firstname',Salutation='Mr.',LastName='test1',
                           email='test1@test.com' , AccountId = eBaySeller1.Id);
        insert contact1;
        
        Deal_Contract_Agreement__c dc = new Deal_Contract_Agreement__c(RecordTypeId=ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals').Id);
        insert dc;
        
        Test.startTest();
			EBH_Deal__c d = new EBH_Deal__c(Deal_Contract_Agreement__c=dc.Id,EBH_eBayItemID__c = '000000000013',Seller_Approver_1__c = contact1.Id, EBH_BusinessName__c=eBaySeller1.ID,RecordTypeId=devRecordTypeId,EBH_SellerPrice__c=20,EBH_DealPrice__c=5,EBH_Quantity__c=2,EBH_DealStartDate__c=myDate+4,EBH_DealEndDate__c=myDate+5,EBH_Status__c='New',EBH_DealSiteId__c = '0',EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c='product 4',EBH_SellerEmail__c='sales@test.com');
			EBH_Deal__c d1 = new EBH_Deal__c(Deal_Contract_Agreement__c=dc.Id,EBH_eBayItemID__c = '0000000000133',Seller_Approver_1__c = contact1.Id, EBH_BusinessName__c=eBaySeller1.ID,RecordTypeId=devRecordTypeId,EBH_SellerPrice__c=20,EBH_DealPrice__c=5,EBH_Quantity__c=2,EBH_DealStartDate__c=myDate+1,EBH_DealEndDate__c=myDate+2,EBH_Status__c='New',EBH_DealSiteId__c = '0',EBH_Vertical__c = 'Home & Garden',EBH_Category__c='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c='product 4',EBH_SellerEmail__c='sales@test.com');
        	List<EBH_Deal__c> lstd = new List<EBH_Deal__c>{d,d1};  
            insert lstd;
        
        	DD_SendToSellerHelper.convertTContractAgreementWrapper(lstd,new List<EBH_Deal__c>()); // Sophal:27/04/2021: US-0009436
            DD_SendToSellerHelper.createDealContractAgreement(lstd,new List<EBH_Deal__c>()); // Sophal:27/04/2021: US-0009436
        	
            List<EBH_Deal__c> dContr = [SELECT Id,
                                        Current_Digest__c,
                                        Deal_Contract_Agreement__c,
                                        Deal_Contract_Agreement__r.Current_Digest__c,
                                        Deal_Contract_Seller_Name__c,
                                        SiteURL__c,
                                        Seller_Approver_1__c,
                                        Seller_Approver_1_Email__c,
                                        Seller_Approver_2__c,
                                        Seller_Approver_2_Email__c,
                                        Seller_Approver_3__c,
                                        Seller_Approver_3_Email__c,
                                        Seller_Approver_4__c,
                                        Seller_Approver_4_Email__c,
                                        Seller_Approver_5__c,
                                        Seller_Approver_5_Email__c
                                        FROM EBH_Deal__c WHERE Deal_Contract_Agreement__c =:dc.Id];	
            System.assert(dContr[0].Deal_Contract_Agreement__r.Current_Digest__c!=null, 'Curren digest value updated');
            DD_SendToSellerHelper.sendApprovalToExternalSeller(dContr);
        Test.stopTest();
    }
}