@isTest(SeeAllData=true)
private class BatchLeadConversionTest {

    private static void setup(){
        // EBH_TestDataFactory.setUpCustomSettings(); 

        // ActiveValidationRules__c setting= new ActiveValidationRules__c(SetupOwnerId=Userinfo.getProfileId(), All_Validation_Rules_Deactivated__c = false);
        // insert setting;

        Lead oneLead = new Lead();
        oneLead.Status = EBH_ConstantsUtility.LEAD_STATUS_QUALIFIED;
        oneLead.LeadSource = 'Self Gen';
        oneLead.OtherLeadSource__c = 'test';
        oneLead.LastName = 'Lead1';
        oneLead.FirstName  =  'FirstTest';
        oneLead.MobilePhone = '11223344';
        oneLead.Phone = '11223344';
        oneLead.Email = 'test@test.com';
        oneLead.Website = 'www.ebaytest.com';
        oneLead.EBH_Vertical__c = 'Collectibles';
        oneLead.VAT_Number__c = '112233';
        oneLead.Company = 'eBay';
        oneLead.LeadSegment__c = EBH_ConstantsUtility.LEAD_SEGMENT_SMB;
        oneLead.RecordTypeId = ApexUtil.getRecordTypeByName('Lead','EBH_eBayAUSMB').Id;
		insert oneLead;
        
        // AU Task
		Task oneT = new Task();
		oneT.RecordTypeId = ApexUtil.getRecordTypeByName('Task', EBH_ConstantsUtility.TASK_AU_RT).Id;
		oneT.WhoId = oneLead.Id;
		insert oneT;

		// Nomal Task
		Task oneT2 = new Task();
		oneT2.WhoId = oneLead.Id;
		insert oneT2;

        Account acc = new Account();
        acc.Name = 'Test Acc1';
        acc.RecordTypeID = ApexUtil.getRecordTypeByName('Account','EBH_Seller').Id;
        insert acc;

        Contact oneCont = new Contact();
        oneCont.LastName = 'testCont';
        oneCont.Email = 'test@gg.com';
        oneCont.Primary_Contact__c = true;
        oneCont.AccountId = acc.Id;
        insert oneCont;
                
        EBH_Project__c oneProj = new EBH_Project__c();
        oneProj.RecordTypeId = ApexUtil.getRecordTypeByName('EBH_Project__c',EBH_ConstantsUtility.PROJECT_RT_AUSMB).Id;
        oneProj.EBH_Seller__c = acc.Id;
        oneProj.OracleID__c = '131233231233334';
        oneProj.Listings__c = 5.00;
        oneProj.LegalName__c = 'testLegalabc';
        oneProj.ABNVATNumber__c = '11122333444';
        oneProj.Lead__c = oneLead.Id;
        oneProj.EBH_Stage__c = EBH_ConstantsUtility.PROJECT_STAGE_STORELAUNCHED;
        oneProj.API__c = 'Other eBay API';
        insert oneProj;
        
    }
    @isTest
    private static void testBatch1(){
        setup();
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        test.startTest();
            String CRON_EXP = '0 30 * * * ?';
            BatchLeadConversionScheduler sch = new BatchLeadConversionScheduler();
            system.schedule('BatchLeadConversion', CRON_EXP, sch); 
        test.stopTest();
    }
    
    @isTest
    private static void testBatch2(){
        setup();
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
       
        Contact oneCont = [SELECT Id FROM Contact WHERE LastName = 'testCont'];
        oneCont.Email = 'test@test.com';
        update oneCont;
        test.startTest();
            String CRON_EXP = '0 30 * * * ?';
            BatchLeadConversionScheduler sch = new BatchLeadConversionScheduler();
            system.schedule('BatchLeadConversion', CRON_EXP, sch); 
        test.stopTest();
        
    }
    
}