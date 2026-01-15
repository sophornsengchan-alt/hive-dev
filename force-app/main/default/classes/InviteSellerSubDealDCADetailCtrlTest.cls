@isTest
private with sharing class InviteSellerSubDealDCADetailCtrlTest {
    @TestSetup
    static void makeData()
    {
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller',Deal_Contract_Agreement_Trigger__c=true);
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account','EBH_Seller');       
        Account acc2 = new Account( Name = 'Seller2', SP_Promotions_Manager__c='Full Access',RecordTypeId = recSeller.Id,NA_Deal_Program_Vetted__c = true);
        insert new List<Account>{acc2};

        RecordType rtDWH = ApexUtil.getRecordTypeByName('Contact','EBH_DWH');
        RecordType rtSP = ApexUtil.getRecordTypeByName('Contact','Seller_Portal');

        Contact conDWH1 = new Contact(Contact_Role__c='Deals',RecordTypeId=rtDWH.Id,FirstName='test', LastName='DWH007', AccountId=acc2.Id, Email = 'dwh_test007@test007.com');
        Contact conSP1 = new Contact(Contact_Role__c='Deals',RecordTypeId=rtSP.Id,FirstName='test', LastName='SP007', AccountId=acc2.Id, Email = 'sp_test007@test007.com');
        insert new List<Contact>{conDWH1,conSP1};

        RecordType rtDCASub = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals');
        Deal_Contract_Agreement__c sdca = new Deal_Contract_Agreement__c(eBay_Seller__c = acc2.id, Deal_Site__c = '0',Deal_Start_Date__c=Date.newInstance(2023, 1, 1), Deal_End_Date__c =Date.newInstance(2023, 1, 10), Deal_Start_Time__c=System.Now().timeGmt(), Deal_End_Time__c=System.Now().timeGmt(), RecordTypeId=rtDCASub.Id);
        insert sdca;

      
    }

    @IsTest
    static void  testInvite()
    {
        Deal_Contract_Agreement__c dca = [SELECT ID  FROM Deal_Contract_Agreement__c WHERE eBay_Seller__r.Name='Seller2' LIMIT 1];

        Test.startTest();
            Map<String,Object> moreParam = new Map<String,Object>{'dontSendToSeller'=>false};
            Map<String,Object> result = InviteSellerSubDealDCADetailController.apexInviteSeller(dca.Id,moreParam);
            System.assertEquals('ok',result.get('status')+'');
          
            dca = [SELECT ID,Status__c  FROM Deal_Contract_Agreement__c WHERE Id=:dca.Id];
            System.assertEquals(InviteSellerSubDealDCADetailController.DCA_STATUS_WAITING_FOR_SUBMISSION,dca.Status__c);
            
        Test.stopTest();

    }
 
}