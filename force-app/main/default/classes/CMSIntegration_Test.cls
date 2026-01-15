@isTest
private class CMSIntegration_Test {
    
    public static Account a;
    public static Contact con;
    public static Opportunity o;
    public static User u;
    public static RecordType conRT;
    public static Contact contact;

  static testMethod void testgetCMSSingleRecord()
  {
        createCustomSettings();
        createRecordData();
        
        Contract c = new Contract(Name='Test Contract',
                                  AccountId=a.id,
                                  Status='Draft',
                                  RecordTypeId=conRT.Id,
                                  companySignedId=u.Id,
                                  CompanySignedDate=System.Today(), 
                                  CustomerSignedDate=System.Today(),
                                  StartDate=System.Today(),
                                  EndDate=System.Today(),
                                  EBH_ContractValue__c=300.00,
                                  EBH_Language__c = 'English',
                                  Surcharge__c = true,
                                  Business_Contact__c=contact.id);
        insert c;

        Blob bodyBlob=Blob.valueOf('Test Attachment Body');
        ContentVersion cv = new ContentVersion(Title='Test Attachment_completed',FirstPublishLocationID=c.Id,VersionData=bodyBlob, pathOnCLient='TEST.png');
        insert cv;
        
        Test.startTest();

        List<Contract> listContract = [Select id, ContractNumber, EBH_ContractValue__c From Contract Where id = :c.id];   
        System.AssertNotEquals(null, listContract[0].ContractNumber);
        
        CMSIntegration.CMSRecord ContractRecord = CMSIntegration.getCMSSingleRecord(listContract[0].ContractNumber);
        List<CMS_Interface_Audit_Log__c> listAL = [Select Id, Audit_Log__c From CMS_Interface_Audit_Log__c];
        System.AssertEquals('Contract sent to CMS successfully.', listAL[0].Audit_log__c);
        System.AssertNotEquals(ContractRecord,null);
  }

  /* AC - temporarily removed this test as we are not currently putting required marker on any custom metadata record (read from the test)
  static testMethod void testgetCMSSingleRecordMissingDates()
  {
        createCustomSettings();
        createRecordData();
        
        Contract c = new Contract(Name='Test Contract',
                                  AccountId=a.id,
                                  Status='Draft',
                                  RecordTypeId=conRT.Id,
                                  companySignedId=u.Id,
                                  CompanySignedDate=System.Today(), 
                                  CustomerSignedDate=System.Today(),
                                  StartDate=null,
                                  EndDate=null,
                                  EBH_ContractValue__c=300.00,
                                  EBH_Language__c = 'English');
        insert c;

        Blob bodyBlob=Blob.valueOf('Test Attachment Body');
        ContentVersion cv = new ContentVersion(Title='Test Attachment_completed',FirstPublishLocationID=c.Id,VersionData=bodyBlob, pathOnCLient='TEST.png');
        insert cv;
        
        Test.startTest();

        List<Contract> listContract = [Select id, ContractNumber, EBH_ContractValue__c From Contract Where id = :c.id];   
        System.AssertNotEquals(null, listContract[0].ContractNumber);
        
        CMSIntegration.CMSRecord ContractRecord = CMSIntegration.getCMSSingleRecord(listContract[0].ContractNumber);
        List<CMS_Interface_Audit_Log__c> listAL = [Select Id, Audit_Log__c From CMS_Interface_Audit_Log__c];
        System.AssertEquals('Mandatory Fields are missing, cannot send to CMS  {StartDate}', listAL[0].Audit_log__c);

  }

  */

  static testMethod void testGetNoRecords() {

    createCustomSettings();

    CMSIntegration.CMSRecord ContractRecord = CMSIntegration.getCMSSingleRecord('12345');
    System.AssertNotEquals(null, ContractRecord);
    System.AssertEquals(null, ContractRecord.UNIQUE_DOC_NAME);
    List<CMSIntegration.CMSRecord> ContractRecords = CMSIntegration.getCMSRecordsSinceLastRun(200);
    System.AssertEquals(ContractRecords.size(),0);
    ContractRecords = CMSIntegration.getCMSRecordsBetweenDates(System.Today(),System.Today(),200);
    System.AssertEquals(ContractRecords.size(),0);
  }

  static testMethod void testgetCMSRecordsSinceLastRun()
  {

        createCustomSettings();
        createRecordData();
        
        // In this test, we are also testing where there is no primary attachment meeting the criteria, so we will load all attachments as non-primary.
        AttachmentContractMapping__c acm = new AttachmentContractMapping__c(Name='Listing Agreement Non Primary',is_primary_attachment__c=false,
        Salesforce_Contract_Record_Type__c='Listing Agreement',SFDC_Contract_Attachment_Prefix__c='*',
        SFDC_Contract_Status__c='Draft');
        insert ACM;

        Contract c = new Contract(Name='Test Contract',
                                  AccountId=a.id,
                                  Status='Draft',
                                  RecordTypeId=conRT.Id,
                                  companySignedId=u.Id,
                                  CompanySignedDate=System.Today(), 
                                  CustomerSignedDate=System.Today(),
                                  StartDate=System.Today(),
                                  EndDate=System.Today(),
                                  EBH_ContractValue__c=300.00,
                                  EBH_Language__c = 'English',
                                  Surcharge__c = true,
                                  Business_Contact__c=contact.id);
        insert c;
        
        Blob bodyBlob=Blob.valueOf('Test Attachment Body');
        ContentVersion cv = new ContentVersion(Title='Test Attachment_Not_Match_Primary',FirstPublishLocationID=c.Id,VersionData=bodyBlob, pathOnCLient='TEST.png');
        insert cv;
        
        List<Contract> listContract = [Select id, ContractNumber From Contract Where id = :c.id];   
        System.AssertNotEquals(listContract[0].ContractNumber,null);
        
        List<CMSIntegration.CMSRecord> ContractRecords = CMSIntegration.getCMSRecordsSinceLastRun(200);

        Test.startTest();
        List<CMS_Interface_Audit_Log__c> listAL = [Select Id, Audit_Log__c,Contract__r.contractNumber From CMS_Interface_Audit_Log__c ORDER BY createdDate DESC];
        System.AssertEquals(1, listAL.size());
        System.AssertEquals(listAL[0].contract__r.contractNumber,listContract[0].ContractNumber);
        System.AssertEquals(listAL[0].Audit_log__c,'Contract sent to CMS successfully.');
        System.AssertNotEquals(ContractRecords,null);

      
        CMSIntegration.setLastContractProcessed(listContract[0].ContractNumber);

        Test.stopTest();

        listAL = [Select Id, Audit_Log__c,Contract__r.contractNumber From CMS_Interface_Audit_Log__c ORDER BY createdDate DESC];
        System.AssertEquals(1, listAL.size());
        System.AssertEquals(listAL[0].contract__r.contractNumber,listContract[0].ContractNumber);
        System.AssertEquals('Contract processed in CMS successfully.', listAL[0].Audit_log__c);

       

  }

  static testMethod void testgetCMSRecordsSinceLastRunBatchExceed()
  {

        createCustomSettings();
        createRecordData();
        
        List<Contract> listContracts = new List<Contract>();
        for(Integer i=0;i<50;i++){     
          Contract c = new Contract(Name='Test Contract',
            AccountId=a.id,
            Status='Draft',
            RecordTypeId=conRT.Id,
            companySignedId=u.Id,
            CompanySignedDate=System.Today(), 
            CustomerSignedDate=System.Today(),
            StartDate=System.Today(),
            EndDate=System.Today(),
            EBH_ContractValue__c=300.00,
            EBH_Language__c = 'English',
            Surcharge__c = true,
            Business_Contact__c=contact.id);
          listContracts.add(c);
        }
        insert listContracts;
        
        List<ContentVersion> listCVs = new List<ContentVersion>();
        for(Contract c:listContracts){
          Blob bodyBlob=Blob.valueOf('Test Attachment Body');
          ContentVersion cv = new ContentVersion(Title='Test Attachment_completed',FirstPublishLocationID=c.Id,VersionData=bodyBlob, pathOnCLient='TEST.png');
          listCVs.add(cv);
        }
        insert listCVs;
        
        List<Contract>contracts = [Select ContractNumber From Contract Where Id = :listContracts[19].Id];
        List<CMSIntegration.CMSRecord> ContractRecords = CMSIntegration.getCMSRecordsSinceLastRun(20);
        System.AssertEquals(ContractRecords.size(),20);
        List<CMS_Control__C> CMSControl = [Select Next_End_Time__c,Last_SF_Processed_Contract__c From CMS_Control__c Where Method_Name__c = 'getCMSRecordsSinceLastRun'];
        System.AssertEquals(CMSControl[0].Next_End_Time__c,CMSIntegration.TimeNow);
        System.AssertEquals(CMSControl[0].Last_SF_Processed_Contract__c,contracts[0].ContractNumber);
      
        for(CMS_Control__c CMS:CMSControl){
          CMS.Last_CMS_Processed_Contract__c = contracts[0].ContractNumber;
        }
        update CMSControl;
      
        contracts = [Select ContractNumber From Contract Where Id = :listContracts[39].Id];
        List<CMSIntegration.CMSRecord>ContractRecords2 = CMSIntegration.getCMSRecordsSinceLastRun(20);
        System.AssertEquals(ContractRecords2.size(),20);
        CMSControl = [Select Next_End_Time__c,Last_SF_Processed_Contract__c, Last_batch__c From CMS_Control__c Where Method_Name__c = 'getCMSRecordsSinceLastRun'];
        System.AssertEquals(CMSControl[0].Last_SF_Processed_Contract__c,contracts[0].ContractNumber);  
        
          for(CMS_Control__c CMS:CMSControl){
            CMS.Last_CMS_Processed_Contract__c = contracts[0].ContractNumber;
          }
          update CMSControl;  
        
        List<CMSIntegration.CMSRecord> ContractRecords3 = CMSIntegration.getCMSRecordsSinceLastRun(200);
        //System.AssertEquals(CMSIntegration.query,contracts[0].ContractNumber);
        System.AssertEquals(ContractRecords3.size(),10);
        CMSControl = [Select Next_End_Time__c,Next_Start_Time__c,Last_SF_Processed_Contract__c, Last_batch__c From CMS_Control__c Where Method_Name__c = 'getCMSRecordsSinceLastRun'];
        System.AssertEquals(CMSControl[0].Last_batch__c,true); 
   // }
  } 
  
  static testmethod void testBetweenDates(){

        createCustomSettings();
        createRecordData();
        
        List<Contract> listContracts = new List<Contract>();
        for(Integer i=0;i<10;i++){   
          Contract c = new Contract(Name='Test Contract',
            AccountId=a.id,
            Status='Draft',
            RecordTypeId=conRT.Id,
            companySignedId=u.Id,
            CompanySignedDate=System.Today(), 
            CustomerSignedDate=System.Today(),
            StartDate=System.Today(),
            EndDate=System.Today(),
            EBH_ContractValue__c=300.00,
            EBH_Language__c = 'English',
            Surcharge__c = true,
            Business_Contact__c=contact.id);
          listContracts.add(c);
        }
        insert listContracts;
        
        List<CMS_Interface_Audit_Log__c> listAL = new List<CMS_Interface_Audit_Log__c>();
        for(Contract c:listContracts){
          CMS_Interface_Audit_Log__c AL = new CMS_Interface_Audit_Log__c(Contract__c=c.id,Audit_Log__c='Contract sent to CMS successfully.',Retrieval_Date_Time_Sent__c=System.Today());
          insert AL;
        }
        insert listAL;
        
        List<ContentVersion> listCVs = new List<ContentVersion>();
        for(Contract c:listContracts){
          Blob bodyBlob=Blob.valueOf('Test Attachment Body');
          ContentVersion cv = new ContentVersion(Title='Test Attachment_completed',FirstPublishLocationID=c.Id,VersionData=bodyBlob, pathOnCLient='TEST.png');
          listCVs.add(cv);
        }
        insert listCVs;
        
        listContracts = new List<Contract>();
        for(Integer i=0;i<10;i++){   
          Contract c = new Contract(Name='Test Contract',
            AccountId=a.id,
            Status='Draft',
            RecordTypeId=conRT.Id,
            companySignedId=u.Id,
            CompanySignedDate=System.Today(), 
            CustomerSignedDate=System.Today(),
            StartDate=System.Today(),
            EndDate=System.Today(),
            EBH_ContractValue__c=300.00,
            EBH_Language__c = 'English',
            Surcharge__c = true,
            Business_Contact__c=contact.id);
          listContracts.add(c);         
        }
        insert listContracts;
        
        listAL = new List<CMS_Interface_Audit_Log__c>();
        for(Contract c:listContracts){
          CMS_Interface_Audit_Log__c AL = new CMS_Interface_Audit_Log__c(Contract__c=c.id,Audit_Log__c='Contract sent to CMS successfully.',Retrieval_Date_Time_Sent__c=System.Today().addDays(-2));
          insert AL;
        }
        insert listAL;
        
        listCVs = new List<ContentVersion>();
        for(Contract c:listContracts){
          Blob bodyBlob=Blob.valueOf('Test Attachment Body');
          ContentVersion cv = new ContentVersion(Title='Test Attachment_completed',FirstPublishLocationID=c.Id,VersionData=bodyBlob, pathOnCLient='TEST.png');
          listCVs.add(cv);
        }
        insert listCVs;
        
        List<CMSIntegration.CMSRecord> ContractRecords = CMSIntegration.getCMSRecordsBetweenDates(System.Today(),System.Today(),200);
        System.AssertEquals(ContractRecords.size(),10);

  }

  private static void createCustomSettings(){
    AttachmentContractMapping__c acm = new AttachmentContractMapping__c(Name='Listing Agreement',is_primary_attachment__c=true,
                                    Salesforce_Contract_Record_Type__c='Listing Agreement',SFDC_Contract_Attachment_Prefix__c='_completed',
                                    SFDC_Contract_Status__c='Draft');
                                    insert ACM;
                                    
                             
                                    
    CMS_Control__c control1 = new CMS_Control__c(Name='Listing Agreement - dates',Next_Start_Time__c=System.Now().addHours(-1),Contract_Status__c='Draft',Contract_Record_Type__c='Listing Agreement',Method_Name__c='getCMSRecordsBetweenDates',Default_Contract_Type__c='DefaultType',Default_Doc_Type__c='DefaultDocType',Default_Legal_Region__c='DefaultLegalRegion');
    CMS_Control__c control2 = new CMS_Control__c(Name='Listing Agreement - last run',Next_Start_Time__c=System.Now().addHours(-1),Contract_Status__c='Draft',Contract_Record_Type__c='Listing Agreement',Method_Name__c='getCMSRecordsSinceLastRun',Default_Contract_Type__c='DefaultType',Default_Doc_Type__c='DefaultDocType',Default_Legal_Region__c='DefaultLegalRegion');  
    CMS_Control__c control3 = new CMS_Control__c(Name='Listing Agreement - single',Next_Start_Time__c=System.Now().addHours(-1),Contract_Status__c='Draft',Contract_Record_Type__c='Listing Agreement',Method_Name__c='getCMSSingleRecord',Default_Contract_Type__c='DefaultType',Default_Doc_Type__c='DefaultDocType',Default_Legal_Region__c='DefaultLegalRegion');
    List<CMS_Control__c> CMSControlList = new List<CMS_Control__c>{control1,control2,control3};
    insert CMSControlList;
  }
  
  private static void createRecordData(){

    String accRT =  [Select Id, Name From RecordType Where SobJectType='Account' AND DeveloperName='EBH_LegalEntity' Limit 1].id;
    a = new Account(Name='Test Account',BillingCountry='US', recordTypeid = accRT,EBH_BillingCountry__c ='AT');
    insert a;
    
    u = [Select Id, Name From User LIMIT 1];
    
    conRT = [Select Id, Name From RecordType Where SobJectType='Contract' AND DeveloperName='EBH_ListingAgreement' Limit 1];
    RecordType manaulconRt = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
    contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = a.id,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
    insert contact;
  }
}