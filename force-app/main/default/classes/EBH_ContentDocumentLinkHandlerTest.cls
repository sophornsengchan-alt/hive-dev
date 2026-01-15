/*********************************************************************************************************************************
@ Class:          EBH_ContentDocumentLinkHandlerTest
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Test class for EBH_ContentDocumentLinkHandler class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.06.2017 / NEHA LUND / Created the test class.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_ContentDocumentLinkHandlerTest{
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {       
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testContentDocument(); }        
    }
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SU
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for Standard User
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    /*
    static testMethod void testProfile_SU() {
        System.runAs(EBH_TestDataFactory.createUser('Business Admin')) { testContentDocument(); }
    }
    */
    /*****************************************************************************************************************************
    @ Method:         testContentDocument
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        TEST CASE (*) System should be able to create the Targeted Sellers based on the attachment
                                    uploaded on Seller List Snapshot record, It will delete previous Targeted Sellers &
                                    creates the new Targeted Sellers
                      COVERAGES (*) testContentDocument(): Creates the Seller records
                                    Attachment records on Seller List Snapshot object
                                    Attachment Trigger and Handler class
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testContentDocument() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();     
      //  EBH_TestDataFactory.setUpAttachmentTriggerHandlerData();     
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

        Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
                         
            EBH_TestDataFactory.setUpAttachmentTriggerHandlerData();
            /*Excecute test*/
            
            /*Validate test*/
            List<EBH_TargetedSeller__c> targetedSellers = [SELECT id from EBH_TargetedSeller__c];
            System.assertEquals( 1 , targetedSellers.size() );
            
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
             List<Contract> testData = EBH_TestDataFactory.setUpContractTriggerHandlerData(); 
            /*Excecute test*/
            /*EBH_TestDataFactory.createAttachment('test', 'test attachment', 
                                    EBH_TestDataFactory.createAccounts(1, 'EBH_LegalEntity')[0].id);
            
           
            System.assertEquals( 1 , targetedSellers.size() );
            
            //System.assertEquals( true, EBH_CheckRecursive.runOnce());
            //System.assertEquals( false, EBH_CheckRecursive.runOnce());
             
             List<Contract> testData = EBH_TestDataFactory.setUpContractTriggerHandlerData();     
             
             
             Attachment at = EBH_TestDataFactory.createAttachment('test', 'test attachment', testdata[0].Id);
             try{
             delete at;
             }
             catch(Exception e){
             }*/
             ContentVersion contentVersion_1 = new ContentVersion(
              Title = 'Penguins',
              PathOnClient = 'Penguins.pdf',
              VersionData = Blob.valueOf('Test Content')
              
           
            );
            insert contentVersion_1;
            
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = documents[1].Id;
            cdl.LinkedEntityId  = testData[0].ID;
            cdl.shareType = 'V';
            insert cdl;
            delete documents;
                     
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
            /*Modify data for test*/             
            
            /*Excecute test*/
            
            /*Validate test*/
            
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateBusinessCaseRequestFileCheck() {
        
        // Test setup
        EBH_TestDataFactory.setUpCustomSettings();     

        // Create a BusinessCaseRequest record
        BusinessCaseRequest__c bcr = new BusinessCaseRequest__c();
        insert bcr;

        // Create a ContentVersion record (used to create ContentDocument)
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test PDF Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;

        // Query the ContentDocument created by the ContentVersion
        List<ContentDocument> contentDoc = [SELECT Id, LatestPublishedVersionId FROM ContentDocument];

        

        // Test execution
        Test.startTest();

            // Create a ContentDocumentLink record
            ContentDocumentLink cdl = new ContentDocumentLink(
                LinkedEntityId = bcr.Id,
                ContentDocumentId = contentDoc[0].Id,
                ShareType = 'V'
            );
            insert cdl;
        

            // Assertions
            BusinessCaseRequest__c updatedBCR = [SELECT Id, AttachedFileCheck__c FROM BusinessCaseRequest__c WHERE Id = :bcr.Id];
            System.assertEquals(true, updatedBCR.AttachedFileCheck__c, 'AttachedFileCheck__c should be updated to true');

            //Delete Contact Document
            delete contentDoc;

            //Assertions
            updatedBCR = [SELECT Id, AttachedFileCheck__c FROM BusinessCaseRequest__c WHERE Id = :bcr.Id];
            System.assertEquals(false, updatedBCR.AttachedFileCheck__c, 'AttachedFileCheck__c should be updated to false after deletion of ContentDocumentLink');

        Test.stopTest();
    }
}