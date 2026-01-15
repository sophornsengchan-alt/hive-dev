/*********************************************************************************************************************************
@ Class:          EBH_AttachmentTriggerHandler
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Handler Class for Attachment Trigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 03.12.2017 / NEHA LUND / Created the class.

*********************************************************************************************************************************/

public with sharing class EBH_AttachmentTriggerHandler {
    /*****************************************************************************************************************************
@ Method:         updateContractAttachmentCheck
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        EPH-3971 : Updats Attachment check in contract once file(s) attached
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      cdLinks : trigger.new from trigger
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.11.2017 / JOY MONDOL / Created the  Method.
*****************************************************************************************************************************/
  /*  public static void updateContractAttachmentCheck(List<Attachment> cdLinks) {
        
        //updated contracts 
        List<Contract> contracts;
        
        //set of contract Ids from docuSign in scope
        Set<Id> contractIds = new Set<Id>();
        
        //fetch the ContentDocumentLinks from the the ContentDocuments in scope
        for(Attachment cdl : cdLinks) { 
            
            //check for the contract type from link types and populate the contract ids if found
            if(cdl.parentId.getSObjectType().getDescribe().getName() == EBH_ConstantsUtility.ATCH_CONTRACT) {
                contractIds.add(cdl.parentID);
            }       
        }
        
        //fetch contracts from contractIds
        contracts = Database.query(EBH_ConstantsUtility.ATCH_CONTRACTQUERY);
        
        //update the contract status
        for(Contract con : contracts) { 
            con.EBH_AttachmentCheck__c = true;
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
    }*/
    
    
    /*****************************************************************************************************************************
@ Method:         validateAttachmentDeletion
@ Version:        1.0
@ Author:         NEHA LUND (nalund@deloitte.co.uk)
@ Purpose:        EPH-4706 - To block deletion of attachments if Contract is Pending Approval and onwards
------------------------------------------------------------------------------------------------------------------------------
@ Parameter:      fileFeeds:      file feeds from the trigger scope
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 2.12.2017 / NEHA LUND / Created the  Method.
@ Change history: 11.04.2018 / David Herrero / Changed text for Label
*****************************************************************************************************************************/
    public static void validateAttachmentDeletion(List<Attachment> attachmentRecords) {
        
        Set<Id> contractIDs = new Set<Id>();
        Set<ID> validContractDeletionIds = new Set<ID>();
        
        List<Attachment> attachments = new List<Attachment>();
        Profile userProfile = [SELECT name, id from Profile where id = :UserInfo.getProfileId()];
        List<PermissionSetAssignment> ps = [SELECT id  from PermissionSetAssignment where AssigneeId = :USerInfo.getUserId()  
                                            and PermissionSet.Name = 'EBH_ContractAdmin'];
        
        for(Attachment file : attachmentRecords) {
            
            Schema.SObjectType token = file.parentId.getSObjectType();
            
            if(token.getDescribe().getName() == 'Contract') {
                contractIds.add(file.parentId);
                attachments.add(file);
                
            }
            
        }
        
        for( Contract con: [SELECT status from Contract where ID In :contractIds and (Status = 'Draft' or Status ='In Negotiation')]){
            
            validContractDeletionIds.add(con.Id);      
            
        }
        
        for( Attachment atch : attachments){
            
            if(userProfile.Name != 'Business Admin' && userProfile.Name != 'System Administrator' && 
               ps.isEmpty() && !validContractDeletionIds.contains(atch.ParentId)){
                   
                   //atch.addError('Attachment cannot be deleted at this stage of Contract');
                   atch.addError(Label.Contract_Attachment_Deletion_Error);
                   
               }
        }
        
        
    }
    public static void validateAttachmentInsertion(List<Attachment> attachmentRecords) {
        List<Attachment> attachments = new List<Attachment>();
        Set<Id> contractIDs = new Set<Id>();
         List<PermissionSetAssignment> ps = [SELECT id  from PermissionSetAssignment where AssigneeId = :USerInfo.getUserId() 
                                            and PermissionSet.Name = 'EBH_ContractAdmin']; 
        Profile userProfile = [SELECT name, id from Profile where id = :UserInfo.getProfileId()]; // If we get 101 SOQL queries error, we should move this query from here and from previous method to a static one
        Set<ID> validContractInsertionIds = new Set<ID>();  
        for( Contract con: [SELECT status from Contract where ID In :contractIds and Status in ('Draft','In Negotiation','Seller Signature Provided')]){
            
            validContractInsertionIds.add(con.Id);      
            
        }
        for(Attachment file : attachmentRecords) {
            
            Schema.SObjectType token = file.parentId.getSObjectType();
            
            if(token.getDescribe().getName() == 'Contract') {
                contractIds.add(file.parentId);
                attachments.add(file);
                
            }
            
        }        
        
        for( Attachment atch : attachments){
            sYSTEM.DEBUG(atch);
            sYSTEM.DEBUG(validContractInsertionIds);
            System.debug(validContractInsertionIds.contains(atch.ParentId));
            System.debug(userProfile.name);
            if(userProfile.Name != 'Business Admin' && userProfile.Name != 'System Administrator' && !validContractInsertionIds.contains(atch.ParentId) && ps.isEmpty()){
                
                
                atch.addError(Label.Contract_Attachment_Insertion_Error);
                
            }
        }
    }
}