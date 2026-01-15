/*********************************************************************************************************************************
@ Class:          MassEditInviteSellerTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0013334 - New fields and automations on Seller Invitation process
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.03.2023 / Sovantheany Dim / Created the class.
                : 30.11.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
				: 05.12.2023 / Loumang SENG / US-0014231 - Retire/Remove any custom code for Growth Portal functionality
                : 11.06.2024/ vadhanak voun (vadhanak.voun@gaea-sys.com) US-0015255 - Destructive change User.BoB_Country__c field
                : 02.09.2025 / Sophal Noch / US-0033165 - Cohorts: Enable individual cohort seller changes
*********************************************************************************************************************************/

@isTest
private class MassEditInviteSellerTest {
	@testSetup private static void setup() {
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        //LA:05-12-2023-US-0014231
		//Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_DealsProgram__c ='Accepted');
        //Account acc2 = new Account(EBH_OracleId__c='1003293592',Name='Test Acc2',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_DealsProgram__c ='Accepted');
        Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK');
        Account acc2 = new Account(EBH_OracleId__c='1003293592',Name='Test Acc2',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK');
        insert new List<Account>{acc,acc2};
		
		List<User> admUsers=[select id, profileid from user where isactive=true and Profile.Name = 'System Administrator'];
		//admUsers[0].BoB_Country__c = '77';
			
		RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
		BoB__c bob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='77',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = admUsers[0].Id);
		BoB__c bob2 = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='77',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = admUsers[0].Id);
		insert new List<BoB__c>{bob,bob2};
		RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
		BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLttm.Id,Seller__c=acc.Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        BoB_Seller__c bs2 = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLttm.Id,Seller__c=acc2.Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        insert new List<BoB_Seller__c>{bs,bs2};  
    }
    private static testMethod void updateStageActionTest() {
        Test.startTest();
        List<BoB_Seller__c> lstbs = [SELECT Invite_Seller__c,BoB__c FROM BoB_Seller__c];
        PageReference editorPage = Page.MassEditInviteSeller;
        Test.setCurrentPage(editorPage);
        ApexPages.currentPage().getParameters().put('id', lstbs[0].BoB__c);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstbs);

        List<BoB__c> listBob = [SELECT Id, Status__c FROM BoB__c WHERE Status__c = 'Draft' And EBH_BOBCNTRY__c = '77'];
        
        for(BoB__c bob : listBob){
            bob.Managed_Type__c = 'Others Managed';
        }
        update listBob;
        stdSetController.setSelected(lstbs); // to cover invite non pro-trader 
        MassEditInviteSeller ctr = new MassEditInviteSeller(stdSetController); 
        System.assertEquals(true, ctr.isError);

        for(BoB__c bob : listBob){
            bob.Managed_Type__c = 'LTTM Managed';
            bob.Managed_Segment__c = 'Pro-Trader Cat'; // 14.05.2024 / Sophal Noch / US-0015200
            bob.Registration_Start_Date__c = Date.today().addDays(1); // 02.09.2025 / Sophal Noch / US-0033165
            bob.RegistrationCloseDate__c = Date.today().addDays(6); // 02.09.2025 / Sophal Noch / US-0033165
        }
        update listBob;

        stdSetController.setSelected(lstbs);
        ctr = new MassEditInviteSeller(stdSetController); 
        System.assertEquals(false, ctr.isError);

        ctr.cancelAction();
        //test update success
        // ctr.inviteSeller = true;
        // ctr.updateInviteSeller();
        Test.stopTest();
        

        // List<BoB_Seller__c> lstBsAfterUpdated = [select Invite_Seller__c from BoB_Seller__c where id IN: lstbs];
        // System.assert(lstBsAfterUpdated.size()==2);
        // for(BoB_Seller__c bs : lstBsAfterUpdated){
        //     System.assert(bs.Invite_Seller__c);
        // }
    }
}