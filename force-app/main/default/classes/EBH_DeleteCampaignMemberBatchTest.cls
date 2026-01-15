@isTest
private class EBH_DeleteCampaignMemberBatchTest {
    
    @IsTest
    static void testBatch1()
    {

        EBH_TestDataFactory.setUpCustomSettings();  
        insert new EBH_DataOrigin__c (Name='1');

        Test.startTest(); 

            List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller') ;
            
            RecordType rtSellerlist = EBH_TestDataFactory.getRecordTypeByName('EBH_Filter__c','EBH_ManualSellerList');
            EBH_Filter__c sellerList1 = new EBH_Filter__c(Name='test m1',RecordTypeId=rtSellerlist.Id);
            insert sellerList1;

            List<Campaign> campaigns1 = EBH_TestDataFactory.createCampaignsWithParent(1, 'Test Campaign1', 'UK', EBH_ConstantsUtility.CMRC_MASCAMPRECORDTYPE,null,'Feasibility');

            EBH_TargetedSeller__c targetedSeller = new EBH_TargetedSeller__c();
            targetedSeller.EBH_Seller__c = sellers[0].Id;
            targetedSeller.EBH_SellerList__c = sellerList1.Id;
            insert targetedSeller;

            List<Contact> contacts = EBH_TestDataFactory.createContacts(2, 'Test Contact', sellers[0].id);
            
            contacts[0].EBH_PhoneOptOut__c = false;
            contacts[1].EBH_PhoneOptOut__c = false;    	 
            update contacts;    	
            
            
            List<CampaignMember> listCM0 = EBH_TestDataFactory.createCampaignMembers2(1,campaigns1[0].Id,contacts[0].Id,10,System.today()-5,System.today());               

            EBH_DeleteCampaignMemberBatch b = new EBH_DeleteCampaignMemberBatch(new Set<ID>{sellers[0].Id},new Set<ID>{campaigns1[0].Id},new Map<Id,List<EBH_TargetedSeller__c>>(),new Map<Id, Campaign>());
            Database.executeBatch(b);

        Test.stopTest();
        
    }
}