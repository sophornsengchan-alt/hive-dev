@isTest
private class Action_TemplateHandlerTest {
     
    static @TestSetup
    void makeData(){
        EBH_TestDataFactory.setUpCustomSettings();
        EBH_ActiveTriggers__c cusettingTrigger = EBH_ActiveTriggers__c.getInstance('EBH Trigger Controller');
		        cusettingTrigger.Action_Template__c = true;
		        update cusettingTrigger;
    }

    @IsTest
    static void testUpdateDescription(){
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
        RecordType recTemplateAcq = ApexUtil.getRecordTypeByName('Action_Template__c','LTTM');
        RecordType recAction = ApexUtil.getRecordTypeByName('Action__c','LTTM');
        RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');        

        Account acc = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK');//LA:05-12-2023-US-0014231: Remove EBH_DealsProgram__c='Accepted'
		insert acc;
        
        Action_Template__c tm1 = new Action_Template__c(Name='Temp1',RecordTypeId=recTemplateAcq.Id,Required__c=true,Active__c=true,Country__c='AU',Detailed_Description__c='test1');
        insert new Action_Template__c[]{tm1};
        
	    BoB__c bob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='15',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id);
		insert bob;

        BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeLttm.Id,Seller__c=acc.Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        insert bs;  

        EBH_Project__c pro = new EBH_Project__c(Name='Project 1');
        insert pro;

        Action__c act = new Action__c(Name='Test1',LTTM_Seller__c=bs.Id,Action_Template__c=tm1.Id,TemplateUniqueId__c=pro.Id+'_'+tm1.Id);
        insert act;

        Test.startTest();

            tm1.Detailed_Description__c = 'test2';
            update tm1;
        
        Test.stopTest();

        Action__c acSel = [Select Id,Detailed_Description__c From Action__c Where Id=:act.Id];

        System.assertEquals(tm1.Detailed_Description__c, acSel.Detailed_Description__c);
        
    }
}