/*********************************************************************************************************************************
@ Class:          EBH_DocuSignStatusTriggerHandler
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Handler Class for DocuSign Status trigger
                  EPH-3971 : Contract Management - Digital signature automation with DocuSign
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16.11.2017 / JOY MONDOL / Created the class.
*********************************************************************************************************************************/
public with sharing class EBH_DocuSignStatusTriggerHandler {

    // private final static String COMPLETED_STATUS = 'Completed';

    /*****************************************************************************************************************************
    @ Method:         updateContractStatus
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        EPH-3971 : Updates contract status when document has been sent for signature and signed back
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      docuSignStatuses : trigger.new from trigger
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.11.2017 / JOY MONDOL / Created the  Method.
    @                 04.06.2021 / Acmatac SEING / US-0009636 - {Hypercare} - [Contracts] - Status not auto-updating to Executed once contract is countersigned
    @                 22.07.2021 / Sophal Noch / US-0009886 -[Docusign] Automation to autopopulate Contract.Business Contact as Recipient 2 in Docusign
    *****************************************************************************************************************************/
    public static void updateContractStatus(List<dsfs__DocuSign_Status__c> docuSignStatuses) {
        
        //updated contracts 
        List<Contract> contracts = new List<Contract>();
        List<dsfs__DocuSign_Status__c> listCompletedDss = new List<dsfs__DocuSign_Status__c>();
        
        for(dsfs__DocuSign_Status__c dss : docuSignStatuses) {
            
            //if status is sent, update contract with status = sent for ebay signature 
            //else if status is complete, execute the contract with signed timestamp
            if(dss.dsfs__Envelope_Status__c == EBH_ConstantsUtility.DSTH_SENT) {
                contracts.add(new Contract(Id     = dss.dsfs__Contract__c, 
                                           Status = EBH_ConstantsUtility.DSTH_SENTFORSIGN));
            } else if(dss.dsfs__Envelope_Status__c == EBH_ConstantsUtility.DSTH_COMPLETED) {
                listCompletedDss.add(dss);
            }
        }

        if(!listCompletedDss.isEmpty()){

            Map<Id,List<dsfs__DocuSign_Recipient_Status__c>> mapDssIdToListDsrs = new Map<Id, List<dsfs__DocuSign_Recipient_Status__c>>();
            
            for(dsfs__DocuSign_Recipient_Status__c dsrs : [  // 22.07.2021 / Sophal Noch / US-0009886 query recipient and map with docuSignId
                    Select Id,
                    dsfs__Contact__c,
                    dsfs__Parent_Status_Record__c 
                    From dsfs__DocuSign_Recipient_Status__c 
                    Where dsfs__Parent_Status_Record__c IN: listCompletedDss
                    Order By dsfs__DocuSign_Routing_Order__c Desc] // 22.07.2021 / Sophal Noch / US-0009886 order dsfs__DocuSign_Routing_Order__c by Desc to get latest recipient
            ){
                
                if(!mapDssIdToListDsrs.containsKey(dsrs.dsfs__Parent_Status_Record__c)){
                    mapDssIdToListDsrs.put(dsrs.dsfs__Parent_Status_Record__c, new List<dsfs__DocuSign_Recipient_Status__c>());
                }
                mapDssIdToListDsrs.get(dsrs.dsfs__Parent_Status_Record__c).add(dsrs);
            }
                    
            for(dsfs__DocuSign_Status__c dss : listCompletedDss) {

                    Id contactId;
                    if(mapDssIdToListDsrs.containsKey(dss.Id)){ // 22.07.2021 / Sophal Noch / US-0009886 get recipient fields value for populating on contract
                        dsfs__DocuSign_Recipient_Status__c dsrs = mapDssIdToListDsrs.get(dss.Id)[0];
                        contactId = dsrs.dsfs__Contact__c;
                    }

                    Date signedDate;
                    if(dss.dsfs__Completed_Date_Time__c != null){
                        signedDate = Date.newinstance(dss.dsfs__Completed_Date_Time__c.year(), dss.dsfs__Completed_Date_Time__c.month(), dss.dsfs__Completed_Date_Time__c.day());
                    }
                    
                    contracts.add(
                        new Contract(Id = dss.dsfs__Contract__c, 
                            Status = EBH_ConstantsUtility.DSTH_EXECUTED,
                                            // Commented by Acmatac, US-0009636 - Hypercare
                                            //    EBH_EnvelopLink__c = dss.dsfs__Envelope_Link__c.split(',')[1],
                            /** Commented out by Robert Maier on 2018-03-16 or request from John Leichty 
                                                StartDate          = System.today(),    //needs to be removed
                            */                                 
                            CompanySignedDate  = System.today(),
                            Contract_Signed_by__c = contactId, // 22.07.2021 / Sophal Noch / US-0009886
                            Seller_Signed_Date__c = signedDate // 22.07.2021 / Sophal Noch / US-0009886
                        )
                    );
            }

        }
        
        //update contracts
        if(!contracts.isEmpty()) {
            try {       
                update contracts;    system.debug(contracts);
            } catch(Exception ex) { 
                System.debug('nsp: ex == '+ex.getMessage());
                EBH_ApexLogger.logError(new List<Exception> { ex }, 
                    EBH_ConstantsUtility.DSTH_CLASSNAME, EBH_ConstantsUtility.DSTH_METHODNAME);
            } 
        }       
    }
}