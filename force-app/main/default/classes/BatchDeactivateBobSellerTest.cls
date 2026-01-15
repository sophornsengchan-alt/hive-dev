@isTest
public class BatchDeactivateBobSellerTest {
    /*****************************************************************************************************************************
	@ Method:   testDeactivateBS
    @ Version:  1.0
    @ Author:   Bora Chhorn (bora.chhorn@gaea-sys.com)
	@ Purpose:  US-0012616: Automation to change Cohort Seller Status to Inactive when Cohort Status is changed to "Inactive"
    *****************************************************************************************************************************/
	static testMethod void testDeactivateBS() {
        
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        //LA:05-12-2023-US-0014231- Remove EBH_DealsProgram__c ='Accepted' from Account 
        Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK');
        insert acc;
        //LA:05-12-2023-US-0014231- Remove EBH_DealsProgram__c ='Accepted' from Account
        Account acc1 = new Account(EBH_OracleId__c='1003293592',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK');
        insert acc1;
        
       		RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
        	BoB__c bob = new BoB__c(RecordTypeId = bobRecordTypeLTTM.Id, Status__c='Draft',EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',Managed_Type__c ='Others Managed');
            insert bob;
            
            RecordType bobSellerRecordTypeLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
            BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id,Seller__c=acc.Id, BoB__c = bob.Id,EBH_BOBSegment__c='MSO', BoB_Subsegment__c='Platin');
            BoB_Seller__c bs2 = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id, Seller__c=acc1.Id, BoB__c = bob.Id,EBH_BOBSegment__c='MSO', BoB_Subsegment__c='Platin');
            
            insert new List<BoB_Seller__c>{bs,bs2};
            
            bob.Status__c=EBH_ConstantsUtility.BOB_STATUS_INACTIVE;
        Test.startTest();
            update bob; 
        Test.stopTest();
        	
        List<BoB_Seller__c> lstBobSeller = new List<BoB_Seller__c>();
        for(BoB_Seller__c bobSeller : [Select RecordType.DeveloperName, Status__c, BoB__r.Status__c, Deactivation_Reason__c,BoB__c From BoB_Seller__c Where BoB__c =: bob.Id]){
            //System.assertEquals(bobSeller.Status__c, 'Inactive');//No automation to update child status when parent status is changed
            //System.assertEquals(bobSeller.Deactivation_Reason__c, 'Cohort Inactivated');//No automation to update child status when parent status is changed
            bobSeller.Status__c = 'Draft';
            lstBobSeller.add(bobSeller);
        }
        update lstBobSeller;
        
        BatchDeactivateBobSeller b = new BatchDeactivateBobSeller(new Set<Id>{bob.Id});
        Database.executeBatch(b);
        
        BatchDeactivateBobSeller batchBS = new BatchDeactivateBobSeller();
        Database.executeBatch(batchBS);
    }
}