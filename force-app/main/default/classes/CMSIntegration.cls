global class CMSIntegration {
  


    public static List<CMSRecord> CMSRecords = new List<CMSRecord>();
    public static List<CMSRecord> CMSRecordsSend = new List<CMSRecord>();
    public static List<CMSRecord> ErrorCMSRecords = new List<CMSRecord>();
    public static List<Contract> listContracts = new List<Contract>();
    public static Map<id,List<CMSAttachment>> CMSattach = new Map<id,List<CMSAttachment>>();
    public static String baseURL = URL.getSalesforceBaseUrl().toExternalForm() + '/';
    public static List<AttachmentContractMapping__c> contractAttachControl = AttachmentContractMapping__c.getall().values();
    public static Boolean CustomSettingFail = false;
    public static Map<String,CMS_Control__c> MapCMSControl = new Map<String,CMS_Control__c>();
    public static Integer batchSizeSet;
    public static DateTime TimeNow;
    public static String query;
    

      
    //Queries all contracts since the time Contracts were last sent
    public static List<Contract> getContractsSinceLastRun() {
      
      getTimeMinus5(); // built in delay to ensure all attachments have arrived (can be slight delay from Docusign)
      List<String> ContractStatuses;
          
      query = 'SELECT ';
      for(String f : getFieldsUnique()) {
        query += f + ', ';
      }
      query += 'id FROM Contract Where ';
      for(CMS_Control__c CMS:MapCMSControl.values()){
        String CMSTime = CMS.Next_Start_Time__c.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'z\'');
        String CMSTimeNow = CMS.Next_End_Time__c==null?TimeNow.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'z\''):CMS.Next_End_Time__c.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'z\'');
        if(CMS.Last_CMS_Processed_Contract__c != null){
          query += '(LastModifiedDate >= '+CMSTime+' AND LastModifiedDate <= '+CMSTimeNow+' AND RecordType.Name = \''+CMS.Contract_Record_Type__c+'\' AND ContractNumber > \''+CMS.Last_CMS_Processed_Contract__c+'\' ';
          query += 'AND Status IN (';
          ContractStatuses = CMS.Contract_Status__c.split(';');
          for(String s:ContractStatuses){
               query += '\''+s+'\', ';
          }
          query = query.removeEndIgnoreCase(', ');
          query += ')) OR ';
        }
        else{
          query+= '(LastModifiedDate >= '+CMSTime+' AND LastModifiedDate <= '+CMSTimeNow+' AND RecordType.Name = \''+CMS.Contract_Record_Type__c+'\' ';
          query += 'AND Status IN (';
          ContractStatuses = CMS.Contract_Status__c.split(';');
          for(String s:ContractStatuses){
             query += '\''+s+'\', ';
          }
          query = query.removeEndIgnoreCase(', ');
          query += ')) OR ';
        }
      }
      query = query.removeEndIgnoreCase('OR ');
      query+= ' ORDER BY ContractNumber ASC LIMIT 10000';  
      System.debug('QUERY: ' + query);
      return Database.query(query);
    }
     
     //Queries Contracts based on a Start and End Date Period 
     public static List<Contract> getContracts(Date fromDate, Date toDate) {
        Set<String> RecordTypes = new Set<String>();
        for(CMS_Control__c CMS:MapCMSControl.values()){
          RecordTypes.add(CMS.Contract_Record_Type__c);
        }
          List<CMS_Interface_Audit_Log__c> AuditLogs = [Select id, Retrieval_Date_Time_Sent__c, Contract__c, Contract__r.RecordType.Name, Contract__r.Status From CMS_Interface_Audit_Log__c Where Contract__c != '' AND Retrieval_Date_Time_Sent__c >= :fromDate AND Retrieval_Date_Time_Sent__c <= :toDate AND Contract__r.RecordType.Name = :RecordTypes Order By Contract__c];    
          Set<Id> ContractIds = new Set<Id>();
          
          for(CMS_Interface_Audit_Log__c AL: AuditLogs){
              ContractIds.add(AL.Contract__c);
          }
          query = 'SELECT ';
          for(String f : getFieldsUnique()) {
            query += f + ', ';
          }
          query += ' id FROM Contract Where Id IN :ContractIds';
          for(CMS_Control__c CMS:MapCMSControl.values()){
              if(CMS.Last_CMS_Processed_Contract__c != null){
                  query += ' AND ContractNumber > \''+CMS.Last_CMS_Processed_Contract__c+'\'';
                  break;
              }
          }
          query += ' Order By ContractNumber ASC';
          return Database.query(query);
      }
     
     //Queries Contracts based on Doc Name reference provided 
     global static List<Contract> getContract(String Unique_Doc_name) {
          query = 'SELECT ';
          for(String f : getFieldsUnique()) {
            query += f + ', ';
          }

          // Acmatac SEING, 17/03/2022 US-0011204 - Should use binding variable instead
          // query += ' id FROM Contract Where ContractNumber = \'' + Unique_Doc_name + '\' LIMIT 1';
          query += ' id FROM Contract Where ContractNumber =: Unique_Doc_name LIMIT 1';
          return Database.query(query);
      }
      
      //Returns all the Attachments related to the Contracts
      //Each attachment is added to a list for the each Parent Id and returned in Map form.
      public static Map<id,List<CMSAttachment>> getAttachments(List<Contract> Parents)
      {
          Set<id> ParentIds = new set<id>();
          for(Contract c:Parents){
              ParentIds.add(c.id);
          }
          
          List<ContentDocumentLink> listAttach = [SELECT id, linkedEntityId, contentDocumentId, contentDocument.title, contentDocument.LatestPublishedVersionid, contentDocument.LatestPublishedVersion.title, linkedEntity.recordType.name FROM contentDocumentLink WHERE linkedEntityId = :ParentIds Order By linkedEntityId, ContentDocument.CreatedDate DESC];
          Map<id,List<CMSAttachment>> mapAttach = new Map<id,List<CMSAttachment>>();
          Map<Id,Set<String>> AttachmentPrefix = new Map<id,Set<String>>();
          
          for(ContentDocumentLink a:listAttach){
              for(AttachmentContractMapping__c var: contractAttachControl){
  
                   if( ((a.contentDocument.Title.startsWith(var.SFDC_Contract_Attachment_Prefix__c)) || (a.contentDocument.Title.contains(var.SFDC_Contract_Attachment_Prefix__c)) || var.SFDC_Contract_Attachment_Prefix__c == '*') && a.linkedEntity.RecordType.Name == var.Salesforce_Contract_Record_Type__c){
                      
                      CMSAttachment cmsatt = new CMSAttachment();
                      cmsatt.Attachmentid = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/ContentDocument/' + a.contentDocumentId + '/view'; 
                      cmsatt.name = a.contentDocument.title;
                      cmsatt.isPrimary = var.Is_Primary_Attachment__c==true?true:false;

                      // There should only be one "primary" attachment per linkedEntityId. However, if we can't find a primary, we will attach all attachments as non-primary. 
                      // If this attachment is "primary", then it should be the ONLY attachment for this linkedEntityId - reinitialize this list for just the primary.
                      // If not primary, do we already have primary in the list (check the first object in array)? If not, then add this cms to the existing (or new) list. Otherwise, ignore it.

                      List<CMSAttachment> existingAttachments;
                      if (cmsatt.isPrimary) {
                        existingAttachments = new List<CMSAttachment>();
                        existingAttachments.add(cmsatt);
                      } else {
                        existingAttachments = mapAttach.get(a.linkedEntityId);
                        if (existingAttachments == null || !existingAttachments.get(0).isPrimary) {
                          if (existingAttachments == null) {
                            existingAttachments = new List<CMSAttachment>();
                          }
                          existingAttachments.add(cmsatt);
                        }
                      }
                      mapAttach.put(a.linkedEntityId, existingAttachments);

                  }
              }
          } 
          return mapAttach;
      }
     
     public static set<String> getFieldsUnique() {
       set<String> uniqueFields = new set<String>();
       for (CMS_Field_Mapping__mdt s : getFields()) {
          uniqueFields.add(s.Contract_Field__c); // a column might be used twice. SOQL does not support duplicate columns.
       }
       return uniqueFields;
     }

     //Returns all fields referenced in the Field Set 
     public static List<CMS_Field_Mapping__mdt> getFields() {
          return [SELECT MasterLabel, QualifiedApiName, Contract_Field__c, Required__c FROM CMS_Field_Mapping__mdt];
      }
      
      //Method manages whether there are more records to be sent
      public static void ManageBatchSize(){
        String ContractNumber;
        String LastContractNumber;
        CmsRecordssend = new List<CMSRecord>();
        for(Integer i=0;i<batchsizeSet;i++){
              if(i>=CmsRecords.size()) break;
              CmsRecordssend.add(cmsrecords[i]);
              ContractNumber = cmsrecords[i].UNIQUE_DOC_NAME;
        }
        for(CMS_Control__c CMS:MapCMSControl.values()){
          if(CMS.Next_End_Time__c == null)CMS.Next_End_Time__c = TimeNow;
          CMS.Last_SF_Processed_Contract__c = ContractNumber;
          if(cmsrecords.size() > CmsRecordssend.size())CMS.Last_Batch__c = false;
          else if(cmsrecords.size() == CmsRecordssend.size()){
              CMS.Last_Batch__c = true;
              LastContractNumber = ContractNumber;
          }
        }
        update MapCMSControl.values();
        
        for(CMSRecord CMS:CMSRecordsSend){
          if(CMS.UNIQUE_DOC_NAME == LastContractNumber)CMS.LAST_RECORD = true;
        }
      }
     
     //Method updates Map MapCMSControl based on the method being used 
     public static void ManageCustomSettings(String MethodName){
      List<CMS_Control__c> ListCMS = CMS_Control__c.getAll().values();
      for(CMS_Control__c CMS:ListCMS){
          if(CMS.Method_Name__c == MethodName)MapCMSControl.put(CMS.Contract_Record_Type__c,CMS);
      }
     }
     
     //Retrieve records that have been activated since process last ran
     webservice static List<CMSRecord> getCMSRecordsSinceLastRun(Integer batchSize){
       try{
            ManageCustomSettings('getCMSRecordsSinceLastRun');
           if(MapCMSControl.size()>0){
              getTimeMinus5();
              batchSizeSet = batchsize;
              listContracts = getContractsSinceLastRun();
              if(listContracts.size() == 0){
                for(CMS_Control__c CMS:MapCMSControl.values()){
                  if(CMS.Next_End_Time__c != null){
                    CMS.Last_CMS_Processed_Contract__c=null;
                    CMS.Last_SF_Processed_Contract__c=null;
                    CMS.Next_Start_Time__c =CMS.Next_End_Time__c;
                    CMS.Next_End_Time__c =null;
                  }
                }
                update MapCMSControl.values();
                listContracts = getContractsSinceLastRun();
              }
              
              if(listContracts.size()>0){
                CMSattach = getAttachments(listContracts); 
                CMSRecords = getMapping(listContracts,CMSattach);
                if(ErrorCMSRecords.size()>0)createErrorAuditLog(ErrorCMSRecords,'getCMSRecordsSinceLastRun','Mandatory Fields are missing, cannot send to CMS');
                //if(CMSRecords.size()==0)throw new CMSException('Unable to send records');
                if(CMSRecords.size()>0){
                  ManageBatchSize();
                  if(CMSRecordsSend.size()>0)createSentAuditLog(CMSRecordsSend,'getCMSRecordsSinceLastRun');
                }
                return CMSRecordsSend;
              }
              else{
                  List<CMSRecord> listCMS = new List<CMSRecord>();
                return listCMS;
              }
           }
           else{
              createErrorAuditLog(CMSRecords,'getCMSRecordsSinceLastRun','CMS Interface failed because of incorrect Custom Setting configuration');
              throw new CMSException('Incorrect Mapping Set Up');
           }
      }
       catch(Exception e){
     //     createErrorAuditLog(CMSRecords,'getCMSRecordsSinceLastRun',e.getMessage());
     //     throw new CMSException(e.getMessage());
     throw e;
       }
     }
     
     //Retrieve record based on the Contract Number
     webservice static CMSRecord getCMSSingleRecord(String Unique_Doc_name){
       try{
           ManageCustomSettings('getCMSSingleRecord');
           if(MapCMSControl.size()>0){
               getTimeMinus5();
               listContracts = getContract(Unique_Doc_name);
               if(listContracts.size()>0){
                CMSattach = getAttachments(listContracts); 
                CMSRecords = getMapping(listContracts,CMSattach);
                if(ErrorCMSRecords.size()>0)createErrorAuditLog(ErrorCMSRecords,'getCMSSingleRecord','Mandatory Fields are missing, cannot send to CMS');
                if(CMSRecords.size()>0){
                  createSentAuditLog(CMSRecords,'getCMSSingleRecord');
                  return CMSRecords[0];
                }
                else{
                  CMSRecord CMS = new CMSRecord();
                  return CMS;
                }
               }
              else{
                  CMSRecord CMS = new CMSRecord();
                  return CMS;
              }               
           }
           else{
              createErrorAuditLog(CMSRecords,'getCMSSingleRecord','CMS Interface failed because of incorrect Custom Setting configuration');
              throw new CMSException('Incorrect Mapping Set Up');
           }
       }
       catch(Exception e){
          createErrorAuditLog(CMSRecords,'getCMSSingleRecord',e.getMessage());    
          throw new CMSException(e.getMessage());
       }
     }
     
     //Retrieve Contracts between to Dates
     webservice static List<CMSRecord> getCMSRecordsBetweenDates(Date StartDate, Date EndDate, Integer BatchSize){
          try{
              ManageCustomSettings('getCMSRecordsBetweenDates');
               if(MapCMSControl.size()>0){
                getTimeMinus5();
                batchSizeSet = batchsize;
                listContracts = getContracts(StartDate,EndDate);
                if(listContracts.size()>0){
                  CMSattach = getAttachments(listContracts); 
                  CMSRecords = getMapping(listContracts,CMSattach);
                  if(ErrorCMSRecords.size()>0)createErrorAuditLog(ErrorCMSRecords,'getCMSRecordsBetweenDates','Mandatory Fields are missing, cannot send to CMS');               
                  if(CMSRecords.size()==0)throw new CMSException('Unable to send records');                
                  ManageBatchSize();
                  if(CMSRecordsSend.size()>0)createSentAuditLog(CMSRecordsSend,'getCMSRecordsBetweenDates');
                  return CMSRecordsSend;
                }
                else{
                    List<CMSRecord> listCMS = new List<CMSRecord>();
                    return listCMS;
                }  
             }
           else{
              createErrorAuditLog(CMSRecords,'getCMSRecordsBetweenDates','CMS Interface failed because of incorrect Custom Setting configuration');
              throw new CMSException('Incorrect Mapping Set Up');
           }
         }
         catch(Exception e){
          createErrorAuditLog(CMSRecords,'getCMSRecordsBetweenDates',e.getMessage());
          throw new CMSException(e.getMessage());    
       }  
     }
     
     //Process updates when CMS has succesfully processed a record.
     webservice static void setLastContractProcessed(String Unique_Doc_name){
      string methodname = ProcessedAuditLog(Unique_Doc_name);
      SetCMSControl(Unique_Doc_name,methodname);
     }
     
     //Method updates custom settings with how far CMS has processed the batch
     //Once all records are processed records are reset
     private static void setCMSControl(String ContractNumber, String Methodname){
      ManageCustomSettings(methodname);
      
      for(CMS_Control__c CMS:MapCMSControl.values()){
          if(CMS.Next_End_Time__c != null)CMS.Last_CMS_Processed_Contract__c = ContractNumber;
          if(CMS.Last_CMS_Processed_Contract__c == CMS.Last_SF_Processed_Contract__c && CMS.Last_Batch__c == true){
              CMS.Last_CMS_Processed_Contract__c = null;
              CMS.Last_SF_Processed_Contract__c = null;
              CMS.Last_Batch__c = false;
              CMS.Next_Start_Time__c = CMS.Next_End_Time__c;
              CMS.Next_End_Time__c = null;
          }
      }
      update MapCMSControl.values();
     }
     
     //Creates Audit Log records based on successful CMSRecords inputted
     private static void createSentAuditLog(List<CMSRecord> listCMSRecords,String MethodName){
          List<CMS_Interface_Audit_Log__c> listAL = new List<CMS_Interface_Audit_Log__c>();
  
          for(CMSRecord CMS: listCMSRecords)
          {
              CMS_Interface_Audit_Log__c AL = new CMS_Interface_Audit_Log__c();
              AL.Retrieval_Date_Time_Sent__c = TimeNow;
              AL.Audit_Log__c = 'Contract sent to CMS successfully.';
              AL.Method_Name__c = MethodName;
              AL.Contract__c = CMS.CONTRACT_ID;
              AL.Contract_Name__c = CMS.DISPLAY_NAME;
              AL.Contract_Record_Type__c = CMS.RECORD_TYPE;
              
              for(CMSAttachment cmsatt:CMS.attachments)
              {
                  if(cmsatt.IsPrimary == true){
                      AL.Primary_Attachment__c = cmsatt.Attachmentid;
                      AL.Attachment_URL__c = cmsatt.Attachmentid;
                  }
              }
              listAL.add(AL);
          }
          insert listAL;
     }
     
     //Update latest Audit Log record when record is processed by CMS
     private static string ProcessedAuditLog(String ContractNumber){
        List<CMS_Interface_Audit_Log__c> listAL = [Select Id,Contract__r.ContractNumber,Audit_Log__c,Method_Name__c From CMS_Interface_Audit_Log__c Where Contract__r.ContractNumber = :ContractNumber Order By Retrieval_Date_Time_Sent__c DESC Limit 1];
        listAL[0].Audit_Log__c = 'Contract processed in CMS successfully.';
        update listAL[0];
        
        
        List<CMS_Interface_Audit_Log__c> listAL2 = [Select Id,Contract__r.ContractNumber,Audit_Log__c,Method_Name__c From CMS_Interface_Audit_Log__c Where Contract__r.ContractNumber = :ContractNumber And Contract_Processed__c != true Order By Retrieval_Date_Time_Sent__c];     
        for(CMS_Interface_Audit_Log__c Log:listAL2){
          Log.Contract_Processed__c = true;
        }
        update listAL2;
        
        return listAL[0].Method_Name__c;
     }
     
     //Creates Audit Log records based on CMSRecords that are not able to be migrated
     private static void createErrorAuditLog(List<CMSRecord> listCMSRecords,String MethodName, String ErrorMessage){
          List<CMS_Interface_Audit_Log__c> listAL = new List<CMS_Interface_Audit_Log__c>();
          for(CMSRecord CMS: listCMSRecords){
              CMS_Interface_Audit_Log__c AL = new CMS_Interface_Audit_Log__c();
              AL.Retrieval_Date_Time_Sent__c = TimeNow;
              AL.Is_Error__c = true;
              AL.Audit_Log__c = ErrorMessage + ' ' + CMS.FIELDS_MISSING;
              AL.Method_Name__c = MethodName;
              AL.Contract__c = CMS.CONTRACT_ID;
              AL.Contract_Name__c = CMS.DISPLAY_NAME;
              AL.Contract_Record_Type__c = CMS.RECORD_TYPE;
              if(CMS.Attachments!=null){
                  for(CMSAttachment cmsatt:CMS.attachments)
                  {
                      if(cmsatt.IsPrimary == true){
                          AL.Primary_Attachment__c = cmsatt.Attachmentid;
                          AL.Attachment_URL__c = baseurl + cmsatt.Attachmentid;
                      }
                  }
              }
              listAL.add(AL);
          }
          if(listCMSRecords.isEmpty()&&listAL.isEmpty()){
              CMS_Interface_Audit_Log__c AL = new CMS_Interface_Audit_Log__c();
              AL.Retrieval_Date_Time_Sent__c = TimeNow;
              AL.Is_Error__c = true;
              AL.Audit_Log__c = ErrorMessage;
              AL.Method_Name__c = MethodName;
              listAL.add(AL);
          }
          insert listAL;
     }
     
     //Returns a list of CMSRecords from an input of Contracts and Attachments.
     //Mapping is being controlled mainly by Custom setting CMS_Integration_Field_Mapping__c
     public static List<CMSRecord> getMapping(List<Contract> listCons,Map<id,List<CMSAttachment>> mapAttach){
       List<CMSRecord> listCMSRecord = new List<CMSRecord>();
       Map<id,List<CMSRecord>> MapCMSRecord = new Map<Id,List<CMSRecord>>();
       Boolean DoNotSend = false;
       Set<String> FieldsMissing = new Set<String>();
       List<CMSRelatedFacility> RelatedList = new List<CMSRelatedFacility>();
        Set<String> Countries = new Set<String>();
       
       for(Contract c :listCons){
           Map<String, Object> mapOfFields = new Map<String, Object>();
           DoNotSend = false;
           FieldsMissing = new Set<String>();

           for(CMS_Field_Mapping__mdt f : getFields()) {
             Object val;
             System.debug(f.contract_field__c);
             if (f.contract_field__c.indexOf('.') > -1) {
                String objectName = f.contract_field__c.split('\\.').get(0);
                String fieldName = f.contract_field__c.split('\\.').get(1);
                if (c.getSObject(objectName) != null) val = c.getSObject(objectName).get(fieldName);
             } else {
                val = c.get(f.contract_field__c);
             } 
            
             if (f.required__c && val == null) {
                DoNotSend = true;
                fieldsmissing.add(f.contract_field__c);
             } else {
                mapOfFields.put(f.MasterLabel, val);
             }
           }
    
           CMSRecord newCMSRecord = new CMSRecord(mapOfFields);
           newCMSRecord.CONTRACT_ID = c.Id;
           newCMSRecord.attachments = mapAttach.get(c.Id);
           if(newCMSRecord.attachments == null){
              DoNotSend = true;
              fieldsmissing.add('Attachment');
           }

           if(DoNotSend==true){
             newCMSRecord.fields_missing = ' ' + fieldsmissing;
             ErrorCMSRecords.add(newCMSRecord);
           }          
           else listCMSRecord.add(newCMSRecord);
   

        }
  
        return listCMSRecord;
     }

     public static void getTimeMinus5(){
       TimeNow = System.Now().addSeconds(0);
     }  

     global class CMSRecord {
      webservice String   ACCOUNT_NAME;
      webservice String   COMPANY_SIGNED_BY;
      webservice Date     COMPANY_SIGNED_DATE;
      webservice String   CONTRACT_TYPE_T;
      webservice Double   CONTRACT_VALUE;
      webservice String   CUST_SIGNED_BY;
      webservice Date     CUST_SIGNED_DATE;
      webservice String   DISPLAY_NAME;
      webservice String   DOC_OWNER_USER;
      webservice Date     EFFECTIVE_DATE;
      webservice String   LEGAL_REGION;
      webservice String   OTHER_PARTY;
      webservice String   STATUS;
      webservice String   UNIQUE_DOC_NAME;
      webservice String   ATTORNEY_ASSIGNED;
      webservice String   BILLING_CITY;
      webservice String   BILLING_COUNTRY;
      webservice String   BILLING_POSTALCODE;
      webservice String   BILLING_STATE;
      webservice String   BILLING_STREET;
      webservice String   COUNTRY;
      webservice String   DOC_TYPE;
      webservice String   ADD_PARTY;
      webservice String   RECORD_TYPE;
      webservice String   BUSINESS_REG_NUMBER;
      webservice String   BUSINESS_VAT_NUMBER;
      webservice String   BUSINESS_TYPE;
      webservice Integer  CONTRACT_TERM;
      webservice String   CONTRACT_CURRENCY;
      webservice String   COST_CENTER_NUM;
      webservice String   CUST_SIGNED_TITLE;
      webservice String   DEPT_T;
      webservice String   DOCUMENT_DESCRIPTION;
      webservice String   ENTITY_NAME_T;
      webservice Date     EXPIRATION_DATE;
      webservice String   FINANCIAL_ANALYST;
      webservice String   FINANCE_TYPE;
      webservice String   GOVERNING_LAW_T;
      webservice String   LANG_OF_CONT;
      webservice String   LEGAL_ADMIN;
      webservice String   OTHER_PARTY_SHORT;
      webservice String   OWNER_BUSINESS;
      webservice String   PLACE_OF_REGISTRATION;
      webservice String   REGION;
      webservice String   STORAGE_LOCATION;
      webservice String   SUB_REGION;
      webservice DateTime LAST_MODIFIED_DATE;
      webservice String   LINKED_CONTRACT;
      webservice String   CONTRACT_AMENDMENT;
      private    String   CONTRACT_ID;
      private    String   FIELDS_MISSING;
      webservice Boolean  LAST_RECORD;
      webservice CMSRelatedFacility[] relatedFacilities;
      webservice CMSAttachment[] attachments;
      webservice CMSWebsite[] websites;

      global CMSRecord() {

      }


      global CMSRecord(Map<String, Object> mapOfFields) {
         this.ACCOUNT_NAME = (String)mapOfFields.get('ACCOUNT_NAME') ;
         this.COMPANY_SIGNED_BY= (String)mapOfFields.get('COMPANY_SIGNED_BY') ;
         this.COMPANY_SIGNED_DATE= (Date)mapOfFields.get('COMPANY_SIGNED_DATE') ;
         this.CONTRACT_TYPE_T= (String)mapOfFields.get('CONTRACT_TYPE_T') ;
         this.CONTRACT_VALUE= (Double)mapOfFields.get('CONTRACT_VALUE') ;
         this.CUST_SIGNED_BY= (String)mapOfFields.get('CUST_SIGNED_BY') ;
         this.CUST_SIGNED_DATE= (Date)mapOfFields.get('CUST_SIGNED_DATE') ;
         this.DISPLAY_NAME= (String)mapOfFields.get('DISPLAY_NAME') ;
         this.DOC_OWNER_USER= (String)mapOfFields.get('DOC_OWNER_USER') ;
         this.EFFECTIVE_DATE= (Date)mapOfFields.get('EFFECTIVE_DATE') ;
         this.LEGAL_REGION= (String)mapOfFields.get('LEGAL_REGION') ;
         this.OTHER_PARTY= (String)mapOfFields.get('OTHER_PARTY') ;
         this.STATUS= (String)mapOfFields.get('STATUS') ;
         this.UNIQUE_DOC_NAME= (String)mapOfFields.get('UNIQUE_DOC_NAME') ;
         this.ATTORNEY_ASSIGNED= (String)mapOfFields.get('ATTORNEY_ASSIGNED') ;
         this.BILLING_CITY= (String)mapOfFields.get('BILLING_CITY') ;
         this.BILLING_COUNTRY= (String)mapOfFields.get('BILLING_COUNTRY') ;
         this.BILLING_POSTALCODE= (String)mapOfFields.get('BILLING_POSTALCODE') ;
         this.BILLING_STATE= (String)mapOfFields.get('BILLING_STATE') ;
         this.BILLING_STREET= (String)mapOfFields.get('BILLING_STREET') ;
         this.COUNTRY= (String)mapOfFields.get('COUNTRY') ;
         this.DOC_TYPE= (String)mapOfFields.get('DOC_TYPE') ;
         this.ADD_PARTY= (String)mapOfFields.get('ADD_PARTY') ;
         this.RECORD_TYPE= (String)mapOfFields.get('RECORD_TYPE') ;
         this.BUSINESS_REG_NUMBER= (String)mapOfFields.get('BUSINESS_REG_NUMBER') ;
         this.BUSINESS_VAT_NUMBER= (String)mapOfFields.get('BUSINESS_VAT_NUMBER') ;
         this.BUSINESS_TYPE= (String)mapOfFields.get('BUSINESS_TYPE') ;
         this.CONTRACT_TERM= (Integer)mapOfFields.get('CONTRACT_TERM') ;
         this.CONTRACT_CURRENCY= (String)mapOfFields.get('CONTRACT_CURRENCY') ;
         this.COST_CENTER_NUM= (String)mapOfFields.get('COST_CENTER_NUM') ;
         this.CUST_SIGNED_TITLE= (String)mapOfFields.get('CUST_SIGNED_TITLE') ;
         this.DEPT_T= (String)mapOfFields.get('DEPT_T') ;
         this.DOCUMENT_DESCRIPTION= (String)mapOfFields.get('DOCUMENT_DESCRIPTION') ;
         this.ENTITY_NAME_T= (String)mapOfFields.get('ENTITY_NAME_T') ;
         this.EXPIRATION_DATE= (Date)mapOfFields.get('EXPIRATION_DATE') ;
         this.FINANCIAL_ANALYST= (String)mapOfFields.get('FINANCIAL_ANALYST') ;
         this.FINANCE_TYPE= (String)mapOfFields.get('FINANCE_TYPE') ;
         this.GOVERNING_LAW_T= (String)mapOfFields.get('GOVERNING_LAW_T') ;
         this.LANG_OF_CONT= (String)mapOfFields.get('LANG_OF_CONT') ;
         this.LEGAL_ADMIN= (String)mapOfFields.get('LEGAL_ADMIN') ;
         this.OTHER_PARTY_SHORT= (String)mapOfFields.get('OTHER_PARTY_SHORT') ;
         this.OWNER_BUSINESS= (String)mapOfFields.get('OWNER_BUSINESS') ;
         this.PLACE_OF_REGISTRATION= (String)mapOfFields.get('PLACE_OF_REGISTRATION') ;
         this.REGION= (String)mapOfFields.get('REGION') ;
         this.STORAGE_LOCATION= (String)mapOfFields.get('STORAGE_LOCATION') ;
         this.SUB_REGION= (String)mapOfFields.get('SUB_REGION') ;
         this.LAST_MODIFIED_DATE= (DateTime)mapOfFields.get('LAST_MODIFIED_DATE') ;
         this.LINKED_CONTRACT = (String)mapOfFields.get('LINKED_CONTRACT') ;
         this.CONTRACT_AMENDMENT = (String)mapOfFields.get('CONTRACT_AMENDMENT') ;

         this.attachments = new CMSAttachment[]{};
         this.relatedFacilities = new CMSRelatedFacility[]{};
         this.websites = new CMSWebsite[]{};

      }

   }
   
   global class CMSAttachment {
       webservice String Attachmentid;
       webservice string Name;
       webservice boolean isPrimary;
     }
   
   global class CMSRelatedFacility {
     webservice string Name;
     webservice string URL;
   }
   
   global class CMSWebsite{
     webservice String URL;
   }
   
   global class CMSException extends Exception {}


  }