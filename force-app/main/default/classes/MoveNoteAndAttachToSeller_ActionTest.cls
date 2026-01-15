@isTest
private class MoveNoteAndAttachToSeller_ActionTest {
    @testSetup static void setup(){
        EBH_TestDataFactory.setUpCustomSettings(); 
		ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = false;
        insert avr;

        Account accPartner1 = new Account(
		    Name = 'accPartner1',
		    RecordTypeId = ApexUtil.getRecordTypeByName('Account', 'EBH_Partner').Id,
            EBH_PartnerType__c = 'Shop System'
        );
		insert accPartner1;

        Lead oneL = EBH_TestDataFactory.createLeads();
		oneL.RecordTypeId = ApexUtil.getRecordTypeByName('Lead', 'EBH_eBayAUSMB').Id;
		oneL.EBH_eBayID__c = 'biggest_sellert_test';
		oneL.Site__c = 'DE';
		oneL.LeadSource = 'Self Gen';
		oneL.LeadSegment__c = 'SMB';
		oneL.OtherLeadSource__c = 'other leadsource tst';
		oneL.LastName = 'AMT Lead tst 01';
		oneL.Phone = '012 345 5678';
		oneL.Website = 'www.test.com.test';
		oneL.Email = 'test@tes.com.invalid';
		oneL.Shopping_Card__c = accPartner1.Id;
		oneL.EBH_Vertical__c = 'Collectibles';
		oneL.VAT_Number__c = '12312312312312';
		oneL.isapproved__c = true;
		oneL.Company = 'test1 company';
        insert oneL;
        
        Lead oneL2 = EBH_TestDataFactory.createLeads();
		oneL2.RecordTypeId = ApexUtil.getRecordTypeByName('Lead', 'EBH_eBayAUSMB').Id;
		oneL2.EBH_eBayID__c = 'biggest_sellert_test';
		oneL2.Site__c = 'AU';
		oneL2.LeadSource = 'Self Gen';
		oneL2.LeadSegment__c = 'SMB';
		oneL2.OtherLeadSource__c = 'other leadsource tst';
		oneL2.LastName = 'AMT Lead tst 02';
		oneL2.Phone = '012 345 5678';
		oneL2.Website = 'www.test2.com.test';
		oneL2.Email = 'test2@tes.com.invalid';
		oneL2.Shopping_Card__c = accPartner1.Id;
		oneL2.EBH_Vertical__c = 'Collectibles';
		oneL2.VAT_Number__c = '123123123123129999';
		oneL2.isapproved__c = true;
        oneL2.Company = 'test2 company';
		insert oneL2;

    }

    @isTest static void moveNoteAndAttachToSellerTest01(){
        Lead oneL = [SELECT Id FROM Lead WHERE LastName = 'AMT Lead tst 01'];
        oneL.Status = 'Qualified';
        update oneL;

        Account accSeller = new Account(
		    Name = 'accSeller 1',
            RecordTypeId = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller').Id
        );
        insert accSeller;

        EBH_Project__c proj1 = [SELECT Id FROM EBH_Project__c WHERE Lead__c =: oneL.Id];
        proj1.EBH_Seller__c = accSeller.Id;
        update proj1;
        
        ContentVersion attach1 = EBH_TestDataFactory.createFileAttachment('Test file 1', 'Test body 1', proj1.Id);
        ContentVersion attach2 = EBH_TestDataFactory.createFileAttachment('Test file 2', 'Test body 2', proj1.Id);

        MoveNoteAndAttachToSeller_Action.moveNoteAndAttachToSeller(new List<Id>{proj1.Id});
        proj1 = [SELECT Id, EBH_Stage__c, EBH_Seller__c FROM EBH_Project__c WHERE Lead__c =: oneL.Id];

        // System.assertEquals('Completed', proj1.EBH_Stage__c);


        Id projSellerId = proj1.EBH_Seller__c;
        List<ContentDocumentLink> lstcdl = Database.query(MoveNoteAndAttachToSeller_Action.CDL_SOQL + ' WHERE LinkedEntityId =: projSellerId');
        System.assertEquals(2, lstcdl.size());
    }

    @isTest static void moveNoteAndAttachToSellerTest02(){
        Lead oneL = [SELECT Id FROM Lead WHERE LastName = 'AMT Lead tst 02'];
        oneL.Status = 'Qualified';
        update oneL;

        Account accSeller = new Account(
		    Name = 'accSeller 1',
            RecordTypeId = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller').Id
        );
        insert accSeller;

        EBH_Project__c proj1 = [SELECT Id FROM EBH_Project__c WHERE Lead__c =: oneL.Id];
        proj1.EBH_Seller__c = accSeller.Id;
        proj1.OracleID__c = '145634234';
        proj1.Listings__c = 1231232131;
        proj1.LegalName__c = 'test legal name';
        update proj1;
        
        ContentVersion attach1 = EBH_TestDataFactory.createFileAttachment('Test file 1', 'Test body 1', proj1.Id);
        ContentVersion attach2 = EBH_TestDataFactory.createFileAttachment('Test file 2', 'Test body 2', proj1.Id);

        MoveNoteAndAttachToSeller_Action.moveNoteAndAttachToSeller(new List<Id>{proj1.Id});
        proj1 = [SELECT Id, EBH_Stage__c, EBH_Seller__c FROM EBH_Project__c WHERE Lead__c =: oneL.Id];

        // System.assertEquals('Live to Site', proj1.EBH_Stage__c);


        Id projSellerId = proj1.EBH_Seller__c;
        List<ContentDocumentLink> lstcdl = Database.query(MoveNoteAndAttachToSeller_Action.CDL_SOQL + ' WHERE LinkedEntityId =: projSellerId');
        System.assertEquals(2, lstcdl.size());
    }
}