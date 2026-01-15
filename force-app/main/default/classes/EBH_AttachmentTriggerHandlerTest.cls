/*********************************************************************************************************************************
@ Class:          EBH_AttachmentTriggerHandlerTest
@ Version:        1.0
@ Author:         SRONG TIN (srong.tin@gaea-sys.com)
@ Purpose:        Test class for EBH_AttachmentTriggerHandler class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 28.09.2021 / SRONG TIN / Created the test class.
*********************************************************************************************************************************/

@isTest
public class EBH_AttachmentTriggerHandlerTest {
	@testSetup private static void setup() {
		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' Limit 1];  
        User objUser = new User(Alias = 'SRO', 
                                Email = 'test.sro-lea@testse.com', 
                                EmailEncodingKey = 'UTF-8', 
                                LastName = 'TIN',
                                LocaleSidKey = 'en_US', 
                                LanguageLocaleKey='en_US', 
                                ProfileId = objProfile.Id, 
                                TimeZoneSidKey = 'Europe/London', 
                                UserName = 'test@hive.project.com.invalide');
        insert objUser;
        Contact oneCont = new Contact();
        oneCont.LastName = 'testCont';
        oneCont.Email = 'test@gg.com';
        insert oneCont;
        
        Account acc = new Account();
        acc.Name = 'TestAcclegal';
        acc.RecordTypeID = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity').Id;
        acc.Primary_Contact__c = oneCont.Id;
        acc.EBH_BillingCountry__c = 'UK';
        acc.EBH_OracleID__c = '11111';
        insert acc;
        
        EBH_ActiveTriggers__c setting = new EBH_ActiveTriggers__c();
        setting.Name = 'EBH Trigger Controller';
        setting.EBH_AttachmentTrigger__c = true;
        insert setting;
        
	}
    
    static Contract createContract(id userId, id accId){
		RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
        RecordType conRT = [Select Id, Name From RecordType Where SobJectType='Contract' AND DeveloperName='EBH_ListingAgreement' Limit 1];
	    Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = accId,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
	    insert contact;
		Contract c = new Contract(Name='Test Contract',
                                  AccountId=accId,
                                  Status='Draft',
                                  RecordTypeId=conRT.Id,
                                  companySignedId=userId,
                                  CompanySignedDate=System.Today(), 
                                  CustomerSignedDate=System.Today(),
                                  StartDate=System.Today(),
                                  EndDate=System.Today(),
                                  EBH_ContractValue__c=300.00,
                                  EBH_Language__c = 'English',
                                  Surcharge__c = true,
                                  Business_Contact__c=contact.id);
        return c;
	}
    
    static testMethod void testMethods()
    {
        User user = [select id from User where UserName = 'test@hive.project.com.invalide'];
		Account acc = [select id from Account where Name = 'TestAcclegal'];
        Contract contract = createContract(user.Id, acc.Id);
        insert contract;
        Attachment a = new Attachment(parentId=contract.id,name='test');
  		a.body = Blob.valueOf('Testing Body of Attachment');
  		insert a;
        List<Attachment> att = [Select Id From Attachment];
        System.assertEquals(1, att.size());
        delete a;
        att = [Select Id From Attachment];
        System.assertEquals(0, att.size());
    }
}