/*********************************************************************************************************************************
@ Class:          DocuSignRecipientStatusTriggerHandler
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        Trigger handler class for DocuSignRecipientStatusTrigger.trigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.07.2021 / Sophal Noch / Create Class
*********************************************************************************************************************************/
public without sharing class DocuSignRecipientStatusTriggerHandler {


    /*****************************************************************************************************************************
    @ Method:         updateContractSellerContact
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        method to update contract dsfs__Contract__c, and Seller_Signed_Date__c filed when recipient 2 signs contract
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  22.07.2021 / Sophal Noch / US-0009886 Create Method
    *****************************************************************************************************************************/
    public static void updateContractSellerContact(List<dsfs__DocuSign_Recipient_Status__c> listRecipient, Map<Id,dsfs__DocuSign_Recipient_Status__c> mapOldRecipient) {

        List<dsfs__DocuSign_Recipient_Status__c> listCompletedSigner = new List<dsfs__DocuSign_Recipient_Status__c>();
        Set<Id> setDocSignIds = new Set<Id>();
        for(dsfs__DocuSign_Recipient_Status__c recipent : listRecipient){
            if(recipent.dsfs__Date_Signed__c != null && mapOldRecipient.get(recipent.Id).dsfs__Date_Signed__c != recipent.dsfs__Date_Signed__c){
                listCompletedSigner.add(recipent);
                setDocSignIds.add(recipent.dsfs__Parent_Status_Record__c);
            }
        }

        if(!listCompletedSigner.isEmpty()){

            Map<Id,dsfs__DocuSign_Status__c> mapDocoSignStatus = new Map<Id,dsfs__DocuSign_Status__c>([Select Id, 
                                            dsfs__Contract__c, 
                                            dsfs__Contract__r.Business_Contact__c,
                                            dsfs__Contract__r.Business_Contact__r.Email 
                                            From dsfs__DocuSign_Status__c 
                                            Where dsfs__Contract__c != null 
                                            AND dsfs__Contract__r.Business_Contact__c != null
                                            AND dsfs__Contract__r.Business_Contact__r.Email != null 
                                            AND Id IN : setDocSignIds]);
            if(!mapDocoSignStatus.isEmpty()){

                Map<Id,Contract> mapContractToUpdate = new Map<Id,Contract>();
                for(dsfs__DocuSign_Recipient_Status__c signer : listCompletedSigner){

                    dsfs__DocuSign_Status__c docSignStatus = mapDocoSignStatus.get(signer.dsfs__Parent_Status_Record__c);
                    if(docSignStatus != null && docSignStatus.dsfs__Contract__r.Business_Contact__r.Email == signer.dsfs__DocuSign_Recipient_Email__c){
                        Date signedDate = Date.newinstance(signer.dsfs__Date_Signed__c.year(), signer.dsfs__Date_Signed__c.month(), signer.dsfs__Date_Signed__c.day());
                        mapContractToUpdate.put(docSignStatus.dsfs__Contract__c,new Contract (Id=docSignStatus.dsfs__Contract__c, Contract_Signed_by__c = docSignStatus.dsfs__Contract__r.Business_Contact__c, Seller_Signed_Date__c = signedDate));
                    }
                }
                
                if(!mapContractToUpdate.isEmpty()){
                    try {       
                        update mapContractToUpdate.values();
                    } catch(Exception ex) { 
                        System.debug('nsp: DocuSignRecipientStatusTriggerHandler Error: '+ex.getMessage());
                    } 
                }
            }
            
        }


    }
}