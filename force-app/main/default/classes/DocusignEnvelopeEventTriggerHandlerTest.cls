/**
 * Test class for DocusignEnvelopeEventTriggerHandler
 */
@isTest(seeAllData = False)
public with sharing class DocusignEnvelopeEventTriggerHandlerTest {
    @TestSetup
     static void makeData(){
        EBH_TestDataFactory.setUpCustomSettings();
     }

    static testmethod void testUpdateContract(){
        Map<String,Account> accounts = EBH_TestDataFactory.setupAccountTriggerHandlerData();    
    	RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
	    Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = accounts.get('le1').Id,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
	    insert contact;  
        /****** CREATE CONTRACT RECORD ************************/
        Contract contract = new Contract(RecordTypeId = ApexUtil.getRecordTypeByName('Contract',EBH_ConstantsUtility.CONTRACT_LISTINGRECORDTYPE).Id, 
            Name = 'Test Contract 1', 
            accountId = accounts.get('le1').Id,
            Status = EBH_ConstantsUtility.CONTRACT_DRAFTSTATUS,
            EBH_Site__c = 'UK',
            EBH_Language__c= 'English',
            EBH_AverageTakeRate__c=10,
            Reason_for_Contract_Amendment__c = 'Seller / Brand Acquisition',
            EBH_RequesterNotes__c = 'test',
            Surcharge__c = true,
            PricingVersion__c = 'P1.0',
            StartDate = System.today(),
            EndDate = System.today() + 1,
            Business_Contact__c=contact.id
        );
        insert contract;

        Test.startTest();

            dfsle__EnvelopeStatus__c docEnSt = new dfsle__EnvelopeStatus__c(dfsle__Contract__c= contract.Id,dfsle__Status__c='Sent');
            insert docEnSt;

            Docusign_Envelope_Status__e docEnv = new Docusign_Envelope_Status__e();
            docEnv.Contract_id__c = contract.Id;
            docEnv.Status__c = 'Sent for Finance Post-check';
            List<Docusign_Envelope_Status__e> docList = new List<Docusign_Envelope_Status__e>();
            docList.add(docEnv);
            //List<Database.SaveResult> results = EventBus.publish(docList);
            DocusignEnvelopeEventTriggerHandler.updateContractRecord(docList);
            contract contractObj = [SELECT Id, name,Status,LastModifiedBy.name FROM Contract WHERE Id = :contract.Id];
            System.assertEquals(contractObj.name,'Test Contract 1');

        Test.stopTest();


    
    }
}