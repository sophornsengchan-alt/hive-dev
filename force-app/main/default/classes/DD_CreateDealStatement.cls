/*********************************************************************************************************************************
@ Class:          DD_CreateDealStatement
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0008779 - [NA] Monthly Deal Statement Approval Process
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.01.2021 / Sovantheany Dim / Created the class migrate from join
*********************************************************************************************************************************/
public with sharing class DD_CreateDealStatement implements Database.Batchable<SObject>,Schedulable,Database.Stateful{
    private static Deal_Statement_Setting__c ds_setting = Deal_Statement_Setting__c.getOrgDefaults();
    private List<Deal_Statement__c> orderDealStatements;
    private Set<id> DealStatement2Ids = new Set<id>();
    private Set<Id> DealStatementIds = new Set<id>();
    private Map<Id,EBH_Deal__c> newStatementDealIds = new Map<id,EBH_Deal__c>();
    private Set<String> newDsNames = new Set<String>();
	private List<Exception> listExceptions;
	private Map<String,Deal_Statement__c> mapStatements = new Map<String,Deal_Statement__c>();
	
    public Database.QueryLocator start(Database.BatchableContext bc) {
        try{
            Date now = System.today();      
	        if(Test.isRunningTest()){
	            //we need to add now in future 2month for test
	            now = now.addMonths(3);
	        }
	        //Set date parameters
	        Date endDate = now.toStartOfMonth();
	        Date startDate = endDate.addMonths(-3);
	
	        //Get all deals for that timeframe
	        List<EBH_Deal__c> listDeals = [Select id, Sold_Item_Effective_Date__c, deal_statement__r.sold_item_effective_date__c, deal_statement__c, deal_statement__r.Name, X2nd_Payout_Amount__c, EBH_BusinessName__c, EBH_BusinessName__r.Name, EBH_DealStartDate__c, EBH_DealStartTime__c From EBH_Deal__c
	                                    Where EBH_SoldItems__c!=null AND Final_Sold_Items__c!=null AND  EBH_DealStartDate__c>=:startDate AND EBH_DealEndDate__c<:endDate];
	        
	        //Loop through deals and determine if a new Statement is being created or if we need to update existing deal statement
	        for(EBH_Deal__c d: ListDeals){
	            if(d.deal_statement__c == null){
	                //New Statement being created
	                newStatementDealIds.put(d.id,d);
	            }
	            else if(d.Sold_Item_Effective_Date__c > d.deal_statement__r.sold_item_effective_date__c){
	                //Either sold items batch is updated or need to update for the 2nd payout
	                DealStatementIds.add(d.deal_statement__c);
	                if(d.X2nd_Payout_Amount__c != null) DealStatement2Ids.add(d.deal_statement__c);
	            }
	            
			}
			
	        //Queue owner for the Deal Statements so they're not assigned to a single user
	        List<Group> DealStatementOwner = [Select Id, Name from Group Where Type = 'Queue' and DeveloperName = :ds_setting.Deal_Statement_Owner__c];			
			orderDealStatements = new List<Deal_Statement__c>(); 
				        
	        //Loop through Deals to generate new Deal Staetment name
	        for(EBH_Deal__c d:newStatementDealIds.values()){
	            if(d.Deal_Statement__c == null){
	                String statementName = generateDSName(d);
	                if(!newDsNames.contains(statementName)){
						newDsNames.add(statementName);

						Deal_Statement__c ds = new Deal_Statement__c();
						ds.Name = statementName;
						ds.OwnerId = DealStatementOwner[0].Id;
						ds.ebay_seller__c = d.EBH_BusinessName__c;
						ds.Status__c = '1st Statement';
						ds.Subsidy_30_Day_Calculation__c = 0;
						ds.Month__c = String.ValueOf(d.EBH_DealStartDate__c.month());
						orderDealStatements.add(ds);
						mapStatements.put(ds.ebay_seller__c+ds.month__c,ds);
					}					
	            }           
			}
	        
	        //Loop through existing Deal statements and set calculations to 0 based on relevant update needed
	        for(Deal_Statement__c ds:[Select Id,Name,Subsidy_Final_Calculation__c ,Status__c, ebay_seller__c, month__c, sold_item_effective_date__c, Subsidy_30_Day_Calculation__c, Initial_Payout__c, Amount_Held_Back__c, Second_Payout__c from Deal_Statement__c where Id in:DealStatementIds]){				
	            if(DealStatement2Ids.contains(ds.Id)){
	                ds.Status__c = '2nd Statement';
	                ds.Subsidy_Final_Calculation__c = 0;
	            }
	            else{
	                ds.Subsidy_30_Day_Calculation__c = 0;
				}
				orderDealStatements.add(ds);
				mapStatements.put(ds.ebay_seller__c+ds.month__c,ds);
	        }   
	        
	        //Upsert new and existing deal statements ready for the batches of Deals
	        if(orderDealStatements.size() > 0) upsert orderDealStatements;
        }catch(exception e){
			if(listExceptions == null) listExceptions = new List<Exception>();
			listExceptions.add(e);
	    }
        //Deals that need to be processed could be smaller batch than first query due In filters and if no records needing to be updated then zero returned        
        return Database.getQueryLocator([Select Id,EBH_BusinessName__c,Net_Subsidy_Amount__c,EBH_BusinessName__r.Name,Deal_Statement__c,
                    EBH_DealStartDate__c, EBH_DealStartTime__c, Sold_Item_Effective_Date__c, deal_statement__r.sold_item_effective_date__c,
                    X1st_Payout_Amount__c, X1st_Payout_Amount_Remaining__c, X2nd_Payout_Amount__c,Subsidy_Due_30_Days__c,Subsidy_Due_60_Days__c
                    from EBH_Deal__c 
                    where deal_statement__c IN :DealStatementIDs OR Id IN :newStatementDealIds.keyset() 
                    order by EBH_BusinessName__c,EBH_DealStartDate__c ASC]);
    }
    
    private String generateDSName(EBH_Deal__c d){        
    	if(Test.IsRunningTest())return d.EBH_BusinessName__r.Name;
        DateTime startDateTime = DateTime.newinstance(d.EBH_DealStartDate__c, d.EBH_DealStartTime__c);
        String monthName = startDateTime.format('MMMMM');
        return d.EBH_BusinessName__r.Name+' '+monthName+' Statement';
        
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> objs){
    	try{
	        List<EBH_Deal__c> listUpdateDeals = new List<EBH_Deal__c>();
	        
	        //Loop through Deals in batch and 1) populate statement if not already 2) roll up sold item information
	        for(sObject so:objs){
	            EBH_Deal__c d=(EBH_Deal__c)so;
	            Deal_Statement__c ds  = mapStatements.get(d.EBH_BusinessName__c+String.ValueOf(d.EBH_DealStartDate__c.month()));
	            if(ds.eBay_Seller__c == null)ds.eBay_Seller__c =d.EBH_BusinessName__c;
	            if(ds.Month__c == null) ds.Month__c = String.ValueOf(d.EBH_DealStartDate__c.Month());     
	            if(ds.Sold_item_Effective_Date__c == null || ds.Sold_item_Effective_Date__c < d.Sold_Item_Effective_Date__c) ds.Sold_item_Effective_Date__c = d.Sold_Item_Effective_Date__c;    
	            if(ds.Status__c == '2nd Statement'){
	                // Calculate 2nd payout
	                if(ds.Subsidy_final_Calculation__c == null) ds.Subsidy_Final_Calculation__c=d.Subsidy_Due_60_Days__c;
	                else ds.Subsidy_Final_Calculation__c=ds.Subsidy_Final_Calculation__c+ (d.Subsidy_Due_60_Days__c == null ? 0 : d.Subsidy_Due_60_Days__c);
	            }
	            else if(ds.Status__c == '1st Statement'){
	                // Calculate 1st payout
	                if(ds.Subsidy_30_Day_Calculation__c == null) ds.Subsidy_30_Day_Calculation__c=d.Subsidy_Due_30_Days__c;
	                else ds.Subsidy_30_Day_Calculation__c=ds.Subsidy_30_Day_Calculation__c+ (d.Subsidy_Due_30_Days__c == null ? 0:d.Subsidy_Due_30_Days__c);             
	            }           
	            //Populate Deal Statement if it wasn't already
	            if(d.Deal_Statement__c == null){
	                d.Deal_Statement__c = ds.id;
	                listUpdateDeals.add(d);                
	            }
	        }
	        
	        //Update deals for the deal statement reference
	        if(listUpdateDeals.size()>0){
	            update listUpdateDeals;
	        }			
		}
		catch(exception e){
			if(listExceptions == null) listExceptions = new List<Exception>();
			listExceptions.add(e);			
		}
    }
    
    private void setInitPayout(Deal_Statement__c ds){
        //Initial_Payout__c = Use label Deal Statement Split and populate the 60% value of Subsidy_30_Day_Calculation__c 
        if(ds_setting!=null && ds_setting.Initial_Payout__c!=null){
            ds.Initial_Payout__c = ds.Subsidy_30_Day_Calculation__c*ds_setting.Initial_Payout__c;
        }else{
            ds.Initial_Payout__c=0;
        }
    }
    
    private void setAmountHeldBack(Deal_Statement__c ds){
        //Amount_Held_Back = Use label Deal Statement Split and populate the 40% value of Subsidy_30_Day_Calculation__c
        if(ds_setting!=null && ds_setting.Amount_Held_Back__c!=null){
            ds.Amount_Held_Back__c = ds.Subsidy_30_Day_Calculation__c*ds_setting.Amount_Held_Back__c;
        }else{
            ds.Amount_Held_Back__c=0;
        }
    }
    
    private void setSecondPay(Deal_Statement__c ds){
        //Second_Payout__c = Subsidy_Final_Calculation__c - Initial_Payout__c 
        ds.Second_Payout__c=ds.Subsidy_Final_Calculation__c-ds.Initial_Payout__c;
        if(ds.Subsidy_Final_Calculation__c<ds.Initial_Payout__c){
        	ds.Statement_Overpaid__c = 'Needs Attention';
        }
    }
    
    private void upsertRecs(List<Deal_Statement__c> lst){
        if(lst!=null && !lst.isEmpty()){
            for(Deal_Statement__c ds:lst){
                //calculate init payout
                setInitPayout(ds);
                //calcualte held dest back
                setAmountHeldBack(ds);
                if(DealStatement2Ids.contains(ds.Id)){
                    //update record, must calculate second pay
                    setSecondPay(ds);
                }
            }           
            upsert lst;
        }
    }
    
    public void finish(Database.BatchableContext bc){
    	//Update deal statements once all the deals have been processed
        if(orderDealStatements!=null && !orderDealStatements.isEmpty()){
            upsertRecs(orderdealstatements);
        }    
        
        if(listExceptions != null){
 			String templateName = 'Exception_Email_Alert';
        	List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    
	        Map<String,String> binding = new Map<String,String>();
	        binding.put('{!ApexClass}', 'DD_CreateDealStatement');
	        binding.put('{!Instance}', Url.getOrgDomainUrl().toExternalForm());
	        string Exceptions = String.join(listExceptions, '<br/>');
	        binding.put('{!ExceptionMessage}', Exceptions); 
	        List<String> recipientAddress = new List<String>();
	        recipientAddress.addAll(Label.ExceptionEmailAddresses.split(';'));               
	        emails.add(ApexUtil.prepareEmail(null, recipientAddress, null, templateName, null, binding, null, null));
	        
	        if (!emails.isEmpty() && !Test.isRunningTest()) {
	            ApexUtil.sendEmail(emails);
	        }  
 		}
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DD_CreateDealStatement(), 200);
    }

}