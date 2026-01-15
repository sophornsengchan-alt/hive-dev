/*********************************************************************************************************************************
@ Class:         Batch_FixCampaignMemberResponseValueTest
@ Version:       1.0
@ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       Test Class for Batch_FixCampaignMemberResponseValue
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.02.2018 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
@isTest
private class Batch_FixCampaignMemberResponseValueTest {

    static testMethod void testBatchFixRespone() {
         
         List<Account> legalEntities = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
         List<Campaign> campaigns = EBH_TestDataFactory.createCampaignsWithSellerList(1, 'Test Campaign', 'UK', 'EBH_Campaign', null);
         List<Contact> contacts = EBH_TestDataFactory.createContacts(200, 'Test Contact', legalEntities[0].id);
          
         List<CampaignMember> listMember =  EBH_TestDataFactory.createCampaignMembers(1,campaigns[0].Id,contacts[0].Id, false);
         for(integer i=0;i<199;i++)
         {
            CampaignMember cmClone = listMember[0].clone(false,true,false,false);
            cmClone.ContactId = contacts[i+1].Id;
            listMember.add(cmClone);
         }
         upsert listMember;
         for(CampaignMember cm: listMember)
         {
            cm.EBH_Results__c = null;
         }
         update listMember;
        Test.startTest();
            Batch_FixCampaignMemberResponseValue b = new Batch_FixCampaignMemberResponseValue();
             b.execute(null);
        Test.stopTest();
       
        
        List<CampaignMember> listMemberSelect = [Select Id,EBH_Results__c from CampaignMember where Id IN:listMember]; 
         
        for(CampaignMember cm: listMemberSelect)
        {   
             System.assertNotEquals(null,cm.EBH_Results__c,'EBH_Results__c must be fixed by Batch_FixCampaignMemberResponseValue');
        }
        
    }
}