/*********************************************************************************************************************************
@ Class:          QuoteLineItemMainTriggerHandler
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Handler Class for quoteLineItemMain.trigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:   06.09.2023 / Sophal Noch / US-0014020 - PL Opportunity Process - Ad product Sync
*********************************************************************************************************************************/
public with sharing class QuoteLineItemMainTriggerHandler implements ITrigger{
	//List<QuoteLineItem> targetingUpdatedQli = new List<QuoteLineItem>();
    //List<QuoteLineItem> updatedQliToUpdateIOli = new List<QuoteLineItem>();
    //List<QuoteLineItem> deltaFeildsUpdatedQli = new List<QuoteLineItem>();
    //Set<String> fieldToUpdateIOli = new Set<String>{Util.NS +'until_date__c', Util.NS + 'from_date__c', Util.NS + 'SalesPriceNet__c', 'Quantity', Util.NS + 'Budget__c' };
    List<QuoteLineItem> nonRevisonQliUpdate = new List<QuoteLineItem>();
    Set<Id> setNonRevisonQliUpdateId = new Set<Id>();
    Set<Id> qliIds = new Set<Id>();
    Set<Id> qlSyncIds = new Set<Id>();
    Set<String> qSyncRTNames = new Set<String>{
        'eBay_Advertising',
        'PG_PMP_Quote',
        'eBay_Ads_Promoted_Listings' // 06.09.2023 / Sophal Noch / US-0014020
    };


    static List<QLI2AP_Mapping__mdt> fieldMappers;
    static List<QLI2IOLI_Mapping__mdt> fieldMappersToSyncIO;


    public quoteLineItemMainTriggerHandler() {
        
    }

    public void bulkBefore()
    {
        if(Trigger.isDelete){

            GW_QuoteLineItem.preventDeletingOrUpdatingQli((List<QuoteLineItem>)Trigger.old, (Map<Id,QuoteLineItem>)Trigger.newMap);  // US-0008517, Sophal Noch 21/10/2020
            

            //US-0008726 Sophal 16/12/2020 disable to reduce query // Util.cache(QueryUtil.queryRecords('QuoteLineItem', 'Id IN:value1 ', new Set<String>{'Quote.Status','Quote.'+Util.NS+'Selected_Quote__c','Quote.Primary_Quote__c','Quote.RecordType.DeveloperName'}, new Map<String,Object>{'value1'=>Trigger.oldMap.keySet()})) ;
        

        }else if(Trigger.isUpdate){

            GW_QuoteLineItem.preventDeletingOrUpdatingQli((List<QuoteLineItem>)Trigger.old, (Map<Id,QuoteLineItem>)Trigger.newMap); // US-0008517, Sophal Noch 21/10/2020
            GW_QuoteLineItem.prepopulateQLIFields((List<QuoteLineItem>)Trigger.new, (Map<Id,QuoteLineItem>)Trigger.oldMap); //MN-27052021-US-0009582


        }else if(Trigger.isInsert){
            // 18.12.2020 / Sophal Noch / US-0008866 validata AdProduct__c field in quotelineitem
            // GW_QuoteLineItem.validateAdproductLookup((List<QuoteLineItem>)Trigger.new);  // 28.05.2021 / Sophal Noch / US-0009582 move this to other method GW_QuoteLineItem.prepopulateQLIFields;
            GW_QuoteLineItem.prepopulateQLIFields((List<QuoteLineItem>)Trigger.new, (Map<Id,QuoteLineItem>)Trigger.oldMap); //MN-27052021-US-0009582
        }
    }

    public void bulkAfter()
    {

        if(Trigger.isUpdate){
             //US-0008726, Sophal 16/12/2020 get specific fields
            fieldMappers = fieldMappers != null ? fieldMappers : ((List<QLI2AP_Mapping__mdt>) QueryUtil.queryRecords('QLI2AP_Mapping__mdt'));
            fieldMappersToSyncIO = fieldMappersToSyncIO != null ? fieldMappersToSyncIO : ((List<QLI2IOLI_Mapping__mdt>) QueryUtil.queryRecords(Util.NS+'QLI2IOLI_Mapping__mdt',Util.NS+'update__c=true'));


        }

        // if (Trigger.isUpdate || Trigger.isInsert){
        //     //US-0008726 Sophal 16/12/2020 disable to reduce query
        //     Util.cache(QueryUtil.queryRecords('QuoteLineItem', 'Id IN:value1 ', new Set<String>{'Quote.Media_Plan__r.IsRevision__c','Quote.Opportunity.Type','Quote.'+Util.NS+'IO__c','Quote.Primary_Quote__c','Quote.RecordType.DeveloperName'}, new Map<String,Object>{'value1'=>Trigger.newMap.keySet()})) ;
        // }
    }
    
    public void beforeInsert(SObject so){
    }
    
    public void beforeUpdate(SObject oldSo, SObject so){

    	//QuoteLineItem oldQli = (QuoteLineItem) oldSo;
    	//QuoteLineItem newQli = (QuoteLineItem) so;
    	//if( oldQli.Targeting__c != newQli.Targeting__c){
    	//	targetingUpdatedQli.add(newQli);
    	//}
    }
    
    /**
     * beforeDelete
     *
     * This method is called iteratively for each record to be deleted during a BEFORE
     * trigger.
     */
    public void beforeDelete(SObject so){   

        //US-0008726 Sophal 16/12/2020 disable to reduce query
        // QuoteLineItem delQLI = (QuoteLineItem) Util.getCache(so.Id);   
        // if(delQLI.Quote.Status == 'Approved') {
        //     qliIds.add(delQLI.Id);
        // }
        QuoteLineItem delQLI = (QuoteLineItem)so;
        if(delQLI.QuoteStatus__c == 'Approved') { //US-0008726 Sophal 16/12/2020 use formula field instead
            qliIds.add(delQLI.Id);
        }
        System.debug('##### qliIds :: ' + qliIds);
    }
    
    public void afterInsert(SObject so){




        //US-0008726 Sophal 16/12/2020 disable to reduce query

        // QuoteLineItem qli = (QuoteLineItem) Util.getCache(so.Id);
        // // US-0008016, @amt 2/09/2020 [Ads 2020] New Functionality - Sync of QuoteLineItems-> to Ad Product
        // if(String.isNotBlank(qli.QuoteId) && qli.Quote.Primary_Quote__c && qSyncRTNames.contains(qli.Quote.RecordType.DeveloperName)){
        //     qlSyncIds.add(qli.QuoteId);
        // }
        
        //US-0008726 Sophal 16/12/2020 use formula field instead
        QuoteLineItem qli = (QuoteLineItem)so;
        if(String.isNotBlank(qli.QuoteId) && qli.PrimaryQuote__c == true && qSyncRTNames.contains(qli.QuoteRecordTypeName__c)){



            qlSyncIds.add(qli.QuoteId);
        }
    }
    
    public void afterUpdate(SObject oldSo, SObject so){
        QuoteLineItem oqli = (QuoteLineItem) oldSo;
        QuoteLineItem qli = (QuoteLineItem) so;




        //US-0008726 Sophal 16/12/2020 disable to reduce query
        // QuoteLineItem newQli = (QuoteLineItem) Util.getCache(so.Id);
        // if(!GW_QuoteLineItem.isRevision(newQli)){
        //     nonRevisonQliUpdate.add(newQli);
        // }

        if(String.isNotBlank(qli.QuoteMediaPlan__c) && !qli.QuoteMediaPlanRevision__c && hasAnyFieldChangedToSyncIO(qli,oqli)){  
            //US-0008726, Sophal 16/12/2020 use formula field in condition instead of from query
            setNonRevisonQliUpdateId.add(qli.Id); 
        } 

        // US-0008016, @amt 2/09/2020 [Ads 2020] New Functionality - Sync of QuoteLineItems-> to Ad Product
        if(
            String.isNotBlank(qli.QuoteId) && qli.PrimaryQuote__c == true && qSyncRTNames.contains(qli.QuoteRecordTypeName__c) //US-0008726, Sophal 16/12/2020 use formula field in condition instead of from query
            && hasAnyFieldChanged(qli,oqli) //US-0008726, Sophal 16/12/2020 check specific fields change only
        ){



            qlSyncIds.add(qli.QuoteId);
        }
    }
    

    public void afterDelete(SObject so){




        // US-0008726 Sophal 16/12/2020 disable to reduce query

        // QuoteLineItem delQLI = (QuoteLineItem) Util.getCache(so.Id); 
        // // US-0008016, @amt 2/09/2020 [Ads 2020] New Functionality - Sync of QuoteLineItems-> to Ad Product
        // if(String.isNotBlank(delQLI.QuoteId) && delQLI.Quote.Primary_Quote__c && qSyncRTNames.contains(delQLI.Quote.RecordType.DeveloperName)){
        //     qlSyncIds.add(delQLI.QuoteId);
        // }

        // US-0008726 Sophal 16/12/2020 use formula field instead 
        QuoteLineItem delQLI = (QuoteLineItem) so;
        if(String.isNotBlank(delQLI.QuoteId) && delQLI.PrimaryQuote__c && qSyncRTNames.contains(delQLI.QuoteRecordTypeName__c)){
            qlSyncIds.add(delQLI.QuoteId);
        }




    }
    
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally(){
    	//GW_IO.setTargetingToIOLine(targetingUpdatedQli);
        
        //GW_IO.updateIOliFromQli(updatedQliToUpdateIOli,fieldToUpdateIOli); //US-0008726 Sophal 16/12/2020 disable before it use query beforehand
        if(!setNonRevisonQliUpdateId.isEmpty()){

             //US-0008726 Sophal 16/12/2020 query from the given set Id
            nonRevisonQliUpdate = QueryUtil.queryRecords('QuoteLineItem', 'Id IN:value1 ', new Set<String>{'Quote.Media_Plan__r.IsRevision__c','Quote.Opportunity.Type','Quote.'+Util.NS+'IO__c','Quote.Primary_Quote__c','Quote.RecordType.DeveloperName'}, new Map<String,Object>{'value1'=>setNonRevisonQliUpdateId});
        GW_QuoteLineItem.updateIOLineItem(nonRevisonQliUpdate);
        



        }


        if(!qliIds.isEmpty()){GW_QuoteLineItem.deleteIOLI(qliIds);}
        



        // US-0008016, @amt 2/09/2020 [Ads 2020] New Functionality - Sync of QuoteLineItems-> to Ad Product
        if(!qlSyncIds.isEmpty()) GW_Quote2.copyQlinesToAP(qlSyncIds);



    }

    private Boolean hasAnyFieldChanged(QuoteLineItem qli, QuoteLineItem oqli){
        //US-0008726, Sophal 16/12/2020 check specific fields change only
        for(QLI2AP_Mapping__mdt fieldMapper: fieldMappers) {
            if(qli.get(fieldMapper.Quote_LineItem_Field__c) != oqli.get(fieldMapper.Quote_LineItem_Field__c)){
                return true;
            }
        }
        return false;
    }

    private Boolean hasAnyFieldChangedToSyncIO(QuoteLineItem qli, QuoteLineItem oqli){
        //US-0008726, Sophal 16/12/2020 check specific fields change only
        for(QLI2IOLI_Mapping__mdt fieldMapperIo: fieldMappersToSyncIO) {
            if(qli.get(fieldMapperIo.Quote_LineItem_Field__c) != oqli.get(fieldMapperIo.Quote_LineItem_Field__c)){
                return true;
            }
        }
        return false;



    }
 
 }