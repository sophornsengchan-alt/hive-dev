/** Trigger Handler for QuoteMain.trigger
 @  Change history:  23.03.2021 / Mony Nou / US-0009260 - [Ads 2020] OLI Trigger to QLI/AP, Fields & Syncing
                     08.04.2021 / Mony Nou / US-0009334 - [Ads 2020] Handling Discounts
                     06.09.2023 / Sophal Noch / US-0014020 - PL Opportunity Process - Ad product Sync
 */  
public with sharing class QuoteHandler implements ITrigger{
    Opportunity[] opps = new List<Opportunity>();
    Set<Id> approvingIds = new Set<Id>();
    // Set<Id> primQuoteIds = new Set<Id>(); // 17.12.2020 / Sophal Noch / US-0008858 disble because need to make sure only one quote is from one opportunity
    Map<Id,Id> oppIdsMapToPrimQuoteIds = new Map<Id,Id>(); // 17.12.2020 / Sophal Noch / US-0008858 use opportunity id to make sure only one quote per opp can be set to primary
    Set<Id> primQuoteRTIds = new Set<Id>{
        ApexUtil.getRecordTypeByName('Quote','eBay_Advertising').Id,
        ApexUtil.getRecordTypeByName('Quote','PG_PMP_Quote').Id,
        ApexUtil.getRecordTypeByName('Quote','eBay_Ads_Promoted_Listings').Id // 06.09.2023 / Sophal Noch / US-0014020
    };

    
    Set<Id> sQuoteIds				= new Set<Id>();
    map<Id, Quote> qValuesMap	    = new map<Id, Quote>();
    map<Id, Boolean> qR2Changed		= new map<Id, Boolean>(); // 23.03.2021 / Mony Nou / US-0009260 - [Ads 2020] OLI Trigger to QLI/AP, Fields & Syncing
    
    List<Quote> lstQuoteToUpdateOppCampDate = new  List<Quote>();  // 03.06.2021/ Sophal Noch/ US-0009608

    public void bulkBefore() { 

        if(Trigger.isInsert || Trigger.isUpdate){
            // 23.12.2020 / Sophal Noch 
            GW_Quote2.populateAndValidateFields((List<Quote>)Trigger.new, (Map<Id,Quote>)Trigger.oldMap);
        }
        
    }

    public void bulkAfter() { }
    
    public void beforeInsert(SObject so) { }
    
    public void beforeUpdate(SObject oldSo, SObject so) {}
    
    public void beforeDelete(SObject so) { }
    
    public void afterInsert(SObject so) { }
    
    public void afterUpdate(SObject oldSo, SObject so) {
    	Quote q = (Quote) so;
        Quote oq = (Quote) oldSo;

    	// if(q.IO__c != oq.IO__c) {    // 25.01.2021 / Sophal Noch // US-0009019
        //     opps.add(new Opportunity(id=q.OpportunityId, IO__c = q.IO__c));
        // }
        
    	// if(oq.Status != q.Status && q.Status.equalsIgnoreCase(Label.QUOTE_STATUS_APPROVED)) {    // 25.01.2021 / Sophal Noch // US-0009019
    	// 	if (q.IO__c != null) approvingIds.add(q.Id);
        // }
        
        // US-0008016, @amt 2/09/2020 [Ads 2020] New Functionality - Sync of QuoteLineItems-> to Ad Product
        if(oq.Primary_Quote__c != q.Primary_Quote__c && q.Primary_Quote__c && primQuoteRTIds.contains(q.RecordTypeId) && q.OpportunityId != null){
            //primQuoteIds.add(q.Id);
            oppIdsMapToPrimQuoteIds.put(q.OpportunityId,q.Id); // 17.12.2020 / Sophal Noch / US-0008858 only one quote in each opportunity can be primary quote. 
        }

        // MN-230320201 - US-0009260 - [Ads 2020] OLI Trigger to QLI/AP, Fields & Syncing
        if (q.AE__c                                     != oq.AE__c ||
            q.Rate_Special_Agency_Discount__c		 	!= oq.Rate_Special_Agency_Discount__c ||
            q.Special_Agency_Discount__c				!= oq.Special_Agency_Discount__c ||
            q.Name_Discount_I__c                        != oq.Name_Discount_I__c || //08.04.2021 / Mony Nou / US-0009334
            q.Rate_Discount_II__c					 	!= oq.Rate_Discount_II__c) {
                
                if (q.Rate_Discount_II__c != oq.Rate_Discount_II__c) { qR2Changed.put(q.Id, true); }
                
                sQuoteIds.add(q.Id);
                qValuesMap.put(q.Id, q);
            
        }

        // 03.06.2021/ Sophal Noch/ US-0009608 Ads UAT Bug- Sync Quote Start and End Dates to Opportunity
        if( q.Primary_Quote__c && q.Campaign_Start__c != null && q.Campaign_End__c != null
            && (q.Primary_Quote__c != oq.Primary_Quote__c || q.Campaign_Start__c != oq.Campaign_Start__c || q.Campaign_End__c != oq.Campaign_End__c)
        ){
            lstQuoteToUpdateOppCampDate.add(q);
        }

        
        
    }
    
    public void afterDelete(SObject so) { }
    
    public void andFinally() {
        
        // WithoutSharing.doUpdate(opps);   // 25.01.2021 / Sophal Noch // US-0009019
        // GW_Quote.copyQlinesToIOLines(approvingIds);  // 25.01.2021 / Sophal Noch // US-0009019
        // US-0008016, @amt 2/09/2020 [Ads 2020] New Functionality - Sync of QuoteLineItems-> to Ad Product
        // if(!primQuoteIds.isEmpty()) GW_Quote2.copyQlinesToAP(primQuoteIds); 
        if(!oppIdsMapToPrimQuoteIds.isEmpty()){
            GW_Quote2.copyQlinesToAP(new Set<Id>(oppIdsMapToPrimQuoteIds.values())); // 17.12.2020 / Sophal Noch / US-0008858 run syncing quotelineitem to adproduct when one quote per opp is set to primary
            GW_Quote2.updateQuoteToNonPrimary(oppIdsMapToPrimQuoteIds); // 17.12.2020 / Sophal Noch / US-0008858 update other quotes to non primary
        }

        if (!sQuoteIds.isEmpty()) GW_Quote2.copyDiscountsFromQuoteToQuoteLineItems(sQuoteIds, qValuesMap, qR2Changed); // 25.03.2021 / Mony Nou / US-0009260 - [Ads 2020] OLI Trigger to QLI/AP, Fields & Syncing

        
        if(!lstQuoteToUpdateOppCampDate.isEmpty()){ // 03.06.2021/ Sophal Noch/ US-0009608
            GW_Quote2.updateOppCampaignDate(lstQuoteToUpdateOppCampDate);  // 03.06.2021/ Sophal Noch/ US-0009608 should run after GwQuote2.copyQlinesToAP, GW_Quote2.updateQuoteToNonPrimary
        }

    }

}