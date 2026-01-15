/*********************************************************************************************************************************
@ Class:          DealContractAgreementTriggerHandlerTest
@ Version:        1.0
@ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:        US-0012299 - Contract - Start, end and running status changes
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.09.2022 / Sambath Seng / Create class
@               : 21.09.2023 / Sambath Seng / US-0013982 - PM Deal Items to reflect changes made on record
*********************************************************************************************************************************/
@isTest
private class DealContractAgreementTriggerHandlerTest {
    @testSetup
    static void setup(){
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller',Deal_Contract_Agreement_Trigger__c=true);
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        //create an account
        Account acc = new Account( Name = 'TestAccount', SP_Promotions_Manager__c='Full Access',RecordTypeId = recSeller.Id,NA_Deal_Program_Vetted__c = true);
        Account acc2 = new Account( Name = 'Seller2', SP_Promotions_Manager__c='Full Access',RecordTypeId = recSeller.Id,NA_Deal_Program_Vetted__c = true);
        insert new List<Account>{acc,acc2};

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,
                                    FirstName='test fn', LastName='test ln', AccountId=acc.Id, Email = 'test123@test.com');
        insert con;
        Date today = System.today();
        //create dca
        RecordType pmRecType = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Promotions_Manager_Deals');
        Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c(eBay_Seller__c = acc.id, Deal_Site__c = '0',Deal_Start_Date__c=Date.newInstance(2023, 1, 1), Deal_End_Date__c =Date.newInstance(2023, 1, 10), Deal_Start_Time__c=System.Now().timeGmt(), Deal_End_Time__c=System.Now().timeGmt(), RecordTypeId=pmRecType.Id);
        insert ndca;
        //create deal
        RecordType pmDealRecType = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'PM_Deal');
        EBH_Deal__c ndeal = new EBH_Deal__c(EBH_BusinessName__c=acc.Id,Deal_Contract_Agreement__c=ndca.Id,RecordTypeId=pmDealRecType.Id);
        insert ndeal;

        //------------US-0016364
        RecordType rtDWH = ApexUtil.getRecordTypeByName('Contact','EBH_DWH');
        RecordType rtSP = ApexUtil.getRecordTypeByName('Contact','Seller_Portal');

        Contact conDWH1 = new Contact(Contact_Role__c='Deals',RecordTypeId=rtDWH.Id,FirstName='test', LastName='DWH007', AccountId=acc2.Id, Email = 'dwh_test007@test007.com');
        Contact conSP1 = new Contact(Contact_Role__c='Deals',RecordTypeId=rtSP.Id,FirstName='test', LastName='SP007', AccountId=acc2.Id, Email = 'sp_test007@test007.com');
        insert new List<Contact>{conDWH1,conSP1};

        RecordType rtDCASub = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals');
        Deal_Contract_Agreement__c sdca = new Deal_Contract_Agreement__c(eBay_Seller__c = acc2.id, Deal_Site__c = '0',Deal_Start_Date__c=Date.newInstance(2023, 1, 1), Deal_End_Date__c =Date.newInstance(2023, 1, 10), Deal_Start_Time__c=System.Now().timeGmt(), Deal_End_Time__c=System.Now().timeGmt(), RecordTypeId=rtDCASub.Id);
        insert sdca;

        RecordType rtDealSub = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2');
        //EBH_Deal__c sdeal = new EBH_Deal__c(EBH_Status__c='In Approval',EBH_Quantity__c=100,Seller_Approver_1__c=conDWH1.Id,EBH_MaximumPurchases__c=10,EBH_DealSiteId__c='0',EBH_DealPrice__c=100,EBH_SellerPrice__c=200,EBH_BusinessName__c=acc2.Id,Deal_Contract_Agreement__c=sdca.Id,RecordTypeId=rtDealSub.Id);
        List<EBH_Deal__c> listDeals = new List<EBH_Deal__c>();
        for(Integer i=0; i<5; i++)
        {
            listDeals.add(
                new EBH_Deal__c(EBH_Status__c='In Approval',EBH_Quantity__c=100,Seller_Approver_1__c=conDWH1.Id,EBH_MaximumPurchases__c=10,EBH_DealSiteId__c='0',EBH_DealPrice__c=100,EBH_SellerPrice__c=200,EBH_BusinessName__c=acc2.Id,Deal_Contract_Agreement__c=sdca.Id,RecordTypeId=rtDealSub.Id)
            );
           
        }
        insert listDeals;
    }

    @isTest
    static void autoPopulateStartDateTime () {
        DateTime currentDateTime = System.now();
        Deal_Contract_Agreement__c dca = [SELECT ID,Status__c,Deal_Start_Date_and_Time__c,Deal_End_Date_and_Time__c FROM Deal_Contract_Agreement__c LIMIT 1];
        dca.Deal_Start_Date_and_Time__c = null;
        dca.Deal_End_Date_and_Time__c = null;
        update dca;
        Test.startTest();
            dca.Category__c = 'Art';
            update dca;
        Test.stopTest();
        Deal_Contract_Agreement__c result = [SELECT ID,Status__c,Deal_Start_Date_and_Time__c,Deal_End_Date_and_Time__c FROM Deal_Contract_Agreement__c LIMIT 1];
        System.assertEquals(true, result.Deal_Start_Date_and_Time__c <> null);
        System.assertEquals(true, result.Deal_End_Date_and_Time__c <> null);
    }

    @isTest
    static void syncAttachedDeals() {
        Deal_Contract_Agreement__c dca = [SELECT Id,Deal_Start_Date__c,Deal_Start_Time__c,Deal_End_Date__c,Deal_End_Time__c,Category__c FROM Deal_Contract_Agreement__c LIMIT 1];
        Time testTime = Time.newInstance(14, 30, 45, 0);
        Test.startTest();
            // Modify the parent record to trigger the update
            dca.Deal_Start_Time__c = testTime;
            dca.Deal_End_Time__c = testTime;
            dca.Category__c = 'Art';
            update dca;
        Test.stopTest();

        // Query child records after the update
        List<EBH_Deal__c> dealRecords = [SELECT Id,EBH_DealStartDate__c,EBH_DealStartTime__c,EBH_DealEndDate__c,EBH_DealEndTime__c,EBH_Category__c,Deal_Contract_Agreement__c FROM EBH_Deal__c WHERE Deal_Contract_Agreement__c = :dca.Id];

        // Verify that child records have been synced
        System.assertEquals(1, dealRecords.size());

        for (EBH_Deal__c child : dealRecords) {
            System.assertEquals(dca.Deal_Start_Date__c, child.EBH_DealStartDate__c);
            System.assertEquals(dca.Deal_Start_Time__c, child.EBH_DealStartTime__c);
            System.assertEquals(dca.Deal_End_Date__c, child.EBH_DealEndDate__c);
            System.assertEquals(dca.Deal_End_Time__c, child.EBH_DealEndTime__c);
            System.assertEquals(dca.Category__c, child.EBH_Category__c);
        }
    }

    @isTest
    static void testStatusChanged() 
    {
        Deal_Contract_Agreement__c dca = [Select Id From Deal_Contract_Agreement__c Where eBay_Seller__r.Name='Seller2'];
        Test.startTest();
            dca.Status__c = 'Sent to Seller';
            update dca;
            List<EBH_Deal__c> listDeals = [Select Id,EBH_Status__c From EBH_Deal__c Where Deal_Contract_Agreement__c =:dca.Id];
            System.assertEquals('Sent to Seller', listDeals[0].EBH_Status__c,'Related deal updated to "Sent to Seller"');

            List<Seller_Communication__c> listSC = [Select Id From Seller_Communication__c Where PM_Deal__c =:dca.Id];
            System.assertEquals(2, listSC.size(),'2 SC created. 1 for DWH and 1 for SP');

            dca.Status__c = 'Internally Rejected';
            update dca;
            listDeals = [Select Id,EBH_Status__c From EBH_Deal__c Where Deal_Contract_Agreement__c =:dca.Id];
            System.assertEquals('Internally Rejected', listDeals[0].EBH_Status__c,'Related deal updated to "Internally Rejected"');

        Test.stopTest();


    }
}