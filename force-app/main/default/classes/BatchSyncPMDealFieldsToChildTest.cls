@isTest
public class BatchSyncPMDealFieldsToChildTest {

    @testSetup
    static void setup(){
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller',Deal_Contract_Agreement_Trigger__c=true);
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        //create an account
        Account acc = new Account( Name = 'TestAccount', SP_Promotions_Manager__c='Full Access',RecordTypeId = recSeller.Id,NA_Deal_Program_Vetted__c = true);
        insert acc;

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,
                                    FirstName='test fn', LastName='test ln', AccountId=acc.Id, Email = 'test123@test.com');
        insert con;
        Date today = System.today();
        //create dca
        Time testTime = Time.newInstance(14, 30, 45, 0);
        RecordType pmRecType = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Promotions_Manager_Deals');
        Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c(eBay_Seller__c = acc.id, Deal_Site__c = '0',Deal_Start_Date__c=Date.newInstance(2023, 1, 1), Deal_End_Date__c = Date.newInstance(2023, 1, 5), Deal_Start_Time__c=testTime, Deal_End_Time__c=testTime, RecordTypeId=pmRecType.Id,Category__c = 'Art');
        insert ndca;
    }

    // Positive test case: Verify that the batch updates records correctly
    @isTest
    static void testBatchPositive() {
        // Create test data for EBH_Deal__c and Deal_Contract_Agreement__c objects
        Account seller = [SELECT Id FROM Account LIMIT 1];
        List<EBH_Deal__c> deals = new List<EBH_Deal__c>();
        Deal_Contract_Agreement__c dca = [SELECT Id,Deal_Start_Date__c,Deal_Start_Time__c,Deal_End_Date__c,Deal_End_Time__c,Category__c FROM Deal_Contract_Agreement__c LIMIT 1];
        
        // Create and insert test records for EBH_Deal__c
        RecordType pmDealRecType = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'PM_Deal');
        for (Integer i = 0; i < 200; i++) { // Create 200 records
            EBH_Deal__c deal = new EBH_Deal__c(
                EBH_BusinessName__c = seller.Id,
                Deal_Contract_Agreement__c = dca.Id,
                RecordtypeId = pmDealRecType.Id
            );
            deals.add(deal);
        }
        insert deals;
        
        // Start the batch
        Test.startTest();
        BatchSyncPMDealFieldsToChild batch = new BatchSyncPMDealFieldsToChild(new Set<Id>{dca.Id});
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify that the records were updated correctly
        List<EBH_Deal__c> updatedDeals = [SELECT EBH_DealStartDate__c, EBH_DealStartTime__c, EBH_DealEndDate__c, EBH_DealEndTime__c, EBH_Category__c FROM EBH_Deal__c WHERE Id IN :deals];
        Time testTime = Time.newInstance(14, 30, 45, 0);
        for (EBH_Deal__c updatedDeal : updatedDeals) {
            // Perform assertions to verify the updated fields
            System.assertEquals(dca.Deal_Start_Date__c, updatedDeal.EBH_DealStartDate__c);
            System.assertEquals(testTime, updatedDeal.EBH_DealStartTime__c);
            System.assertEquals(dca.Deal_End_Date__c, updatedDeal.EBH_DealEndDate__c);
            System.assertEquals(testTime, updatedDeal.EBH_DealEndTime__c);
            System.assertEquals('Art', updatedDeal.EBH_Category__c);
        }
    }
}