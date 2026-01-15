/*********************************************************************************************************************************
@ Class:          DocusignRecipientStatusRelatedTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:      US-0009928 - [Docusign] Display Related List to show Recipient Status
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.07.2021 / Sovantheany Dim / Created the class.
*********************************************************************************************************************************/
@isTest
public class DocusignRecipientStatusRelatedTest {
	static testMethod void testgetDocuRecipStatus(){
        List<Account> legalEntities = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');
        RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
        Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = legalEntities[0].Id,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
        insert contact;
        RecordType listingAggreementRecordType = ApexUtil.getRecordTypeByName('Contract','EBH_ListingAgreement');
        List<Contract> contractsListing = new List<Contract>();
        contractsListing.add(new Contract(RecordTypeId = listingAggreementRecordType.Id, 
                                       Name = 'Test Contract ', 
                                       accountId = legalEntities[0].Id, 
                                       EBH_eBayLegalEntity__c = legalEntities[1].id, Status='Draft'
                                       ,StartDate=System.today(),EndDate=System.today().addMonths(1), Surcharge__c = true,Business_Contact__c=contact.id));
        insert contractsListing;
        List<dsfs__DocuSign_Status__c> lstDocStatus = EBH_TestDataFactory.createDocuSignStatus(10,contractsListing,'Completed');
        List<dsfs__DocuSign_Recipient_Status__c> lstDocRecipStatus = new List<dsfs__DocuSign_Recipient_Status__c>();
        for(dsfs__DocuSign_Status__c dsStatus : lstDocStatus){
            for( integer i=0 ; i< 2 ; i++ ){
                lstDocRecipStatus.add(new dsfs__DocuSign_Recipient_Status__c(dsfs__Parent_Status_Record__c = dsStatus.Id,
                                                                             dsfs__DocuSign_Recipient_Id__c = 'testID'+i,
                                                                             Name='test'+i,
                                                                             dsfs__DocuSign_Recipient_Email__c = 'test'+i+'@test.com',
                                                                             dsfs__DocuSign_Routing_Order__c =i,
                                                                             dsfs__Recipient_Status__c = 'Completed'));
            }
        }
        insert lstDocRecipStatus;
        Test.startTest();
        Map<String,Object> mapResult = DocusignRecipientStatusRelatedController.getDocuRecipStatus(contractsListing[0].Id,6);                                 
        Test.stopTest();
        if(mapResult.containsKey('lstWrapper')){
            ContactsRelatedController.LightningTableWraper lstWrapper = (ContactsRelatedController.LightningTableWraper) mapResult.get('lstWrapper');
            System.assert(lstWrapper.tableRecord.size()==6);
        }
    }
}