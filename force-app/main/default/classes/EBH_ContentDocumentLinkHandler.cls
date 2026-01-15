/*********************************************************************************************************************************
@ Class:          EBH_ContentDocumentLinkHandler
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Handler Class for ContentDocumentLink Trigger
                  EPH-2759 : Training Material
                  EPH-3971 : Contract Management - Digital signature automation with DocuSign
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.06.2017 / JOY MONDOL / Created the class.
                  07.11.2017 / JOY MONDOL / Updated the class in Release 3.
                  19.03.2025 / Sambath Seng / US-0016682 - [Dev Only] Apex Class Classification to upgrade API version 3/5
                  30.06.2025 / Mony Nou / US-0032974 - New Business Case Request Object Creation - AC6
*********************************************************************************************************************************/

public with sharing class EBH_ContentDocumentLinkHandler {

    private final static String SOBJ_BUSINESSCASEREQUEST = 'BusinessCaseRequest__c';
    private final static String CLASSNAME = 'EBH_ContentDocumentLinkHandler';
    private final static String METHOD = 'updateBusinessCaseRequestFileCheck';
    
    /*****************************************************************************************************************************
    @ Method:         updateTrainingMaterialFileURL
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Updates the EBH_FileURL__c field with the latest file attached/uploaded in the Training Material records
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      fileFeeds:      file feeds from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.06.2017 / JOY MONDOL / Created the  Method.
    @               : 19.03.2025 / Sambath Seng / US-0016682 - [Dev Only] Apex Class Classification to upgrade API version 3/5
    *****************************************************************************************************************************/
    public static void updateTrainingMaterialFileURL(Map<Id, ContentDocumentLink> fileFeeds) {
        
        Map<Id, String> trainingMaterialIdURLs = new Map<Id, String>();
        List<EBH_TrainingMaterial__c> trainingMaterials = new List<EBH_TrainingMaterial__c>();
        Set<Id> fileFeedIds = fileFeeds.keySet();
        Set<Id> trainingMaterialMapId = new Set<Id>();
        
        for(ContentDocumentLink file : Database.query(EBH_ConstantsUtility.CDLH_CONTENTDOCUMENTQUERY)) {
                                            
            Schema.SObjectType token = file.LinkedEntityId.getSObjectType();
            
            //19.03.2025 Sambath Seng US-0016682 Replace getSalesforceBaseUrl
            if(token.getDescribe().getName() == EBH_ConstantsUtility.CDLH_TRAININGMATERIAL) {
                trainingMaterialIdURLs.put(file.LinkedEntityId, 
                    URL.getOrgDomainURL() .toExternalForm() + 
                    EBH_ConstantsUtility.CDLH_DOWNLOADURL + file.ContentDocument.LatestPublishedVersionId);
            }
        }
        
        trainingMaterialMapId = trainingMaterialIdURLs.keySet();
        trainingMaterials = Database.query(EBH_ConstantsUtility.CDLH_TRAININGMATERIALQUERY);
        
        for(EBH_TrainingMaterial__c tMat : trainingMaterials) {
            tMat.EBH_FileURL__c = trainingMaterialIdURLs.get(tMat.Id);
        }
        
        try {
            Database.update(trainingMaterials);
        } catch(Exception ex) {
            EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.CDLH_CLASSNAME, EBH_ConstantsUtility.CDLH_METHOD);
        }
    }

    /*****************************************************************************************************************************
    @ Method:         updateContractAttachmentCheck
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        EPH-3971 : Updats Attachment check in contract once file(s) attached
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      cdLinks : trigger.new from trigger
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.11.2017 / JOY MONDOL / Created the  Method.
    					07/07/2021 / Dim sovantheany / Update method : US-0009862 - [Docusign] Validation when contract is set to “Ready for signature” to check the attachment is PDF
    *****************************************************************************************************************************/
    public static void updateContractAttachmentCheck(List<ContentDocumentLink> cdLinks) {
        
        //updated contracts 
        List<Contract> contracts = new List<Contract>();
        
        //set of contract Ids from docuSign in scope
        Set<Id> contractIds = new Set<Id>();
        
        //fetch the ContentDocumentLinks from the the ContentDocuments in scope
        for(ContentDocumentLink cdl : cdLinks) { 
            
            //check for the contract type from link types and populate the contract ids if found
            if(cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == EBH_ConstantsUtility.ATCH_CONTRACT) {
                contractIds.add(cdl.LinkedEntityId);
            }       
        }
        
        //fetch contracts from contractIds
        //contracts = Database.query(EBH_ConstantsUtility.ATCH_CONTRACTQUERY);
       // Map<ID, Integer> contractAttachmentMap = new Map<ID,Integer>();
        //integer count = 1;
        set<String> setContrId = new set<String>();
        if(!contractIds.isEmpty()){
        for( ContentDocumentLink  cd : [SELECT id,ContentDocument.LatestPublishedVersion.FileType,linkedEntityId from ContentDocumentLink where linkedEntityId In :contractIds]){
            
            //TH: comment out for US-0009862
            //count =  contractAttachmentMap.containsKey(cd.linkedEntityId) ?contractAttachmentMap.get(cd.linkedEntityId) : 0;
            //count++;
            //contractAttachmentMap.put(cd.linkedentityId, count);
            
            //TH: US-0009862 : check if contract have PDF attachment
            if(cd.ContentDocument.LatestPublishedVersion.FileType.equalsIgnoreCase('PDF')) {
            	setContrId.add(cd.linkedentityId);
            }
            //End US-0009862
            
        } 
        
        //update the contract status
        //TH: comment out for US-0009862
        /*for(Id con : contractIds) { 
            Contract conRecord = new Contract(Id = con);
            if( contractAttachmentMap.containsKey(con) && contractAttachmentMap.get(con) >=2){
                conRecord.EBH_AttachmentCheck__c = true;
                contracts.add(conRecord);
            
            }
        }*/
        //TH: US-0009862 : update EBH_AttachmentCheck__c to true for contract have PDF attachement
        for(String contrId : setContrId){
        	Contract conRecord = new Contract(Id = contrId,EBH_AttachmentCheck__c = true);
        	contracts.add(conRecord);
        }
        //End US-0009862 
        }
        //update contracts
        if(!contracts.isEmpty()) {
            try {       
                update contracts;
            } catch(Exception ex) { 
                EBH_ApexLogger.logError(new List<Exception> { ex }, 
                    EBH_ConstantsUtility.ATCH_CLASS, EBH_ConstantsUtility.ATCH_METHODNAME);
            } 
        }  
             
    }
    
  
     
      /*****************************************************************************************************************************
    @ Method:         validateAttachmentDeletion
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        EPH-4706 - To block deletion of attachments if Contract is Pending Approval and onwards
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      fileFeeds:      file feeds from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 2.12.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static void validateAttachmentInsertion(Map<Id, ContentDocumentLink> fileFeeds) {
        
   
        Set<ID> validContentIDs = new Set<ID>();
         Set<Id> contractIDs = new Set<Id>();
        Set<ID> validContractDeletionIds = new Set<ID>();
        Set<ID> WrongIds = new Set<ID>();
        
        List<Attachment> attachments = new List<Attachment>();
        Profile userProfile = [SELECT name, id from Profile where id = :UserInfo.getProfileId()];
        List<PermissionSetAssignment> ps = [SELECT id  from PermissionSetAssignment where AssigneeId = :USerInfo.getUserId() 
                                     and PermissionSet.Name = 'EBH_ContractAdmin'];
        
       
         
        
        
        
         for(ContentdocumentLink cd:fileFeeds.values()){
             
              Schema.SObjectType token = cd.LinkedEntityId.getSObjectType();
             
             
             
            
            if(token.getDescribe().getName() == 'Contract') {
                contractIds.add(cd.LinkedEntityId);
                validContentIDs.add(cd.ContentDocumentId);
               
                    
            }
         }
      
        if(!contractIds.isEmpty()){
         for( Contract con: [SELECT status from Contract where ID In :contractIds and Status in ('Draft','In Negotiation','Seller Signature Provided')]){
              
              validContractDeletionIds.add(con.Id);      
            
        }
            }
        List<ID>lValidContentIds = new List<ID>(validContentIds);
	
        if(!validContentIDs.isEmpty()){
            
        
        
        String contentDocumentIds='';
        Integer contentSize=lValidContentIds.size();
        for (Integer i=0;i<contentSize;){
            contentDocumentIds+='contentDocumentId=\''+lValidContentIds[i] +'\'';
            if (i++<contentSize){
                contentDocumentIds+=' or ';
            }
        }
        contentDocumentIds=contentDocumentIds.substring(0,contentDocumentIds.lastIndexOf(' or '));
        String query='SELECT linkedEntityId, contentDocumentID from ContentDocumentLink where '+ contentDocumentIds;
        
        for(ContentdocumentLink cd: Database.query(query)){
            
               
              if(
               cd.LinkedEntityId.getSObjectType().getDescribe().getName() == EBH_ConstantsUtility.ATCH_CONTRACT &&
               userProfile.Name != 'Business Admin' && userProfile.Name != 'System Administrator' && 
               ps.isEmpty() && !validContractDeletionIds.contains(cd.LinkedEntityID)){
                   
                   
                   WrongIds.add(cd.contentDocumentId);
               }
                    
            
         }
            
            /*
             * removed by DHE on 2021-02-16
             * reason : 0008597 
        System.debug('We should add errors on following documents' + WrongIds);
		System.debug([select id from ContentDocument where id in :wrongIds]);
        
         for(ContentDocument cd: [select id from ContentDocument where id in :wrongIds]){
         
                       cd.addError(Label.Contract_Attachment_Insertion_Error);
         
                 }
*/
     }
     }
    
    
      public static void validateAttachmentDeletion(Map<Id, ContentDocument> fileFeeds) {
        
   
        Set<ID> validContentIDs = new Set<ID>();
         Set<Id> contractIDs = new Set<Id>();
        Set<ID> validContractDeletionIds = new Set<ID>();
        
        List<Attachment> attachments = new List<Attachment>();
        Profile userProfile = [SELECT name, id from Profile where id = :UserInfo.getProfileId()];
        List<PermissionSetAssignment> ps = [SELECT id  from PermissionSetAssignment where AssigneeId = :USerInfo.getUserId() 
                                     and PermissionSet.Name = 'EBH_ContractAdmin'];
        
       
         
          Set<ID> contentIds = new Set<ID>();
                 for(ContentDocument cd: fileFeeds.values()){
                     contentIds.add(cd.Id);
                 }
         
               
         if(!contentIds.isEMpty())
         for(ContentdocumentLink cd: [SELECT linkedEntityId, contentDocumentID from ContentDocumentLink where contentDocumentId IN :contentIds]){
              Schema.SObjectType token = cd.LinkedEntityId.getSObjectType();
           
            
            if(token.getDescribe().getName() == 'Contract') {
                contractIds.add(cd.LinkedEntityId);
               
                    
            }
         }
         if(!contractIds.isEmpty())
         for( Contract con: [SELECT status from Contract where ID In :contractIds and Status in ('Draft','In Negotiation')]){
              
              validContractDeletionIds.add(con.Id);      
            
        }
        if(!contentIds.isEmpty())
        for(ContentdocumentLink cd: [SELECT linkedEntityId, contentDocumentID from ContentDocumentLink where contentDocumentId IN :contentIds]){
              if(
               cd.LinkedEntityId.getSObjectType().getDescribe().getName() == EBH_ConstantsUtility.ATCH_CONTRACT &&
               userProfile.Name != 'Business Admin' && userProfile.Name != 'System Administrator' && 
               ps.isEmpty() && !validContractDeletionIds.contains(cd.LinkedEntityID)){
                   validContentIds.add(cd.contentDocumentId);
               }
                    
            
         }
         for(ContentDocument cd: fileFeeds.values()){
                   if(validContentIds.contains(cd.Id)){
                       cd.addError( Label.Contract_Attachment_Deletion_Error);
                   }
                 }
     
     }

    /*****************************************************************************************************************************
    @ Method:         updateBusinessCaseRequestFileCheck
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        US-0032974 - New Business Case Request Object Creation - AC6
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      cdLinks : trigger.new (insert) from ContentDocumentLink trigger 
                      cdDocs  : trigger.oldMap (delete) from ContentDocument trigger
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 10/10/2023 / Mony Nou / Updated method name and purpose for business case request handling
    *****************************************************************************************************************************/
    public static void updateBusinessCaseRequestFileCheck(List<ContentDocumentLink> cdLinks, Map<Id, ContentDocument> cdDocs) {
        
        Map<Id, BusinessCaseRequest__c> mBCR2Update = new Map<Id, BusinessCaseRequest__c>();
        Set<Id> sBCRIds = new Set<Id>();
        Set<Id> sBCRIdsWithFile = new Set<Id>();
        Map<Id, ContentDocumentLink> mDeleteCDLinks = new Map<Id, ContentDocumentLink>();
        String query;

        // This method will called from ContentDocument trigger after delete when user delete the file
        if ((cdLinks == null || cdLinks.isEmpty()) && cdDocs != null && !cdDocs.isEmpty()) {
            query = 'SELECT LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN:cdDocs'; 
            cdLinks = ApexSafe.query().secCheck(true).doQuery(query, new Map<String,Object>{'cdDocs' => cdDocs.keySet()});
            mDeleteCDLinks.putAll(cdLinks);
        }

        // If no ContentDocumentLinks are provided, exit the method
        if (cdLinks == null || cdLinks.isEmpty()) { return; } 
        
        // Collect Business Case Request IDs from the ContentDocumentLinks
        for (ContentDocumentLink cdl : cdLinks) {
            sBCRIds.add(cdl.LinkedEntityId);
        }

        // Query ContentDocumentLinks for Business Case Requests with PDF files
        query = 'SELECT LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN:sBCRIds AND LinkedEntity.Type =:SOBJ_BUSINESSCASEREQUEST';
        List<ContentDocumentLink> contentDocumentLinks = ApexSafe.query().secCheck(true).doQuery(query, new Map<String,Object>{'sBCRIds' => sBCRIds, 'SOBJ_BUSINESSCASEREQUEST' => SOBJ_BUSINESSCASEREQUEST});
        
        // Collect Business Case Request IDs that have PDF files attached
        for (ContentDocumentLink cdl : contentDocumentLinks) {
            if (!mDeleteCDLinks.containsKey(cdl.Id)) {
                // Only add the LinkedEntityId if it is not in the delete map
                sBCRIdsWithFile.add(cdl.LinkedEntityId);
            }
            
        }

        
        for (Id bcrId : sBCRIds) {
            
            if (bcrId.getSObjectType().getDescribe().getName() == SOBJ_BUSINESSCASEREQUEST) { // Ensure the ID is for a BusinessCaseRequest__c record
                Boolean flag = sBCRIdsWithFile.contains(bcrId); // Check if the Business Case Request has a PDF file attached
                // Update the BusinessCaseRequest__c record with the AttachedFileCheck__c field set
                // to true if it has a PDF file, otherwise set it to false
                BusinessCaseRequest__c bcr = new BusinessCaseRequest__c(Id = bcrId, AttachedFileCheck__c = flag);
                mBCR2Update.put(bcr.Id, bcr);
            }
        }

        // Perform the update operation on BusinessCaseRequest__c records
        try {       
            ApexSafe.dml().secCheck(false).doUpdate(mBCR2Update.values(), true);
        } catch(Exception ex) { EBH_ApexLogger.logError(new List<Exception> { ex }, CLASSNAME, METHOD); }  

    }

    
}