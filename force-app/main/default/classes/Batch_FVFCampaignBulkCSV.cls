/*********************************************************************************************************************************
@ Class:         Batch_FVFCampaignBulkCSV
@ Version:       1.0
@ Author:        vadhanak voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       US-0006998 Bulk Upload FVF Campaign
@		- For every unique Oracle id uploaded new FVF (listing level) record is created. 		Oracle_ID__c
@ 		- Newly created FVF(listing level) record relates to the initial FVF Campaign record 	FVF_Campaign__c
@ 		- FVF (listing level).Seller = Lookup (oracle id) that was bulk uploaded 			Seller_Name__r.EBH_OracleID__c
@ 		- Some values from FVF Campaign record are copied to FVF (listing level) record			Unique_Id__c
@ 			Start Date		Start_Date_w__c
@ 			Start Time		Start_Time__c
@ 			End Date		End_Date_w__c
@ 			End Time		End_Time__c
@ 			Free shipping required		Free_shipping__c
@ 			Requestor		Requestor__c
@ 			Discount (FVF)	Discount_FVF__c
@ 			Campaign Name- FVF.listing level record should have a value FVF Campaign. Campaign Name_ seller			Campaign_Name__c
@ 		- For every listing id uploaded in AC1, new "nominated item" record is created
@ 			Nominated items. Listing ID = Listing Id that was uploaded			Listing_ID_w__c
@ 			Nominated Items. Price (target) = Price (target) uploaded			Price_target_w__c
@ 			Nominated Items. FVF Discount - copy value from FVF Campaign		Discount_FVF_w__c
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.02.2020 /vadhanak voun (vadhanak.voun@gaea-sys.com) / Created the class.
@				: 28.10.2020 /vadhanak voun (vadhanak.voun@gaea-sys.com)/ US-0008525 - Hypercare: UK FVF (listing) Bulk Upload Nominated Item
@				: 19.05.2025 / Vimean Heng / US-0026060 - Hiveforce product areas testing due to API version upgrade (1/5)
*********************************************************************************************************************************/
global without sharing class Batch_FVFCampaignBulkCSV implements Database.batchable<String>, Database.Stateful{	

  	private String m_csvFile;
   	
   	//requested from component
   	private String numFormat = 'en'; //de or en
   	private String csv_separator = ','; 
   	
   	public static final String NEWLINE_LF = '\n';
   	public static final String NEWLINE_CR = '\r';
   	public static final String NEWLINE_CRLF = '\r\n';
   	
   	private String docUnigueName; //Temporary document inserted from upload
   	private String fvfCampaignId;
   	
   	
   	private Map<String,String> mapNewFVF_All = new Map<String,String>(); //store all newly created FVF from each scope of csv list
   	
   	//maybe later need more detail result
   	//private Set<String> setNewFVF_OK = new Set<String>(); //store newly created FVF from each scope of csv list - Success
   	//private Map<String,String> mapNewFVF_KO = new Map<String,String>(); //store newly created FVF from each scope of csv list - Error
   	
   	//private Set<String> setNewItem_OK = new Set<String>(); //store newly nominated items
   	//private Map<String,String> mapNewItem_KO = new Map<String,String>(); //store newly nominated items
	   
	//number of error to be displayed in the email.
   	static final INTEGER NUM_ERROR_PER_LIST  = 20;
	   Map<String,Set<String>> mapError = new Map<String,Set<String>>
	   {
		   'fvf'=> new Set<String>(),
		   'item'=> new Set<String>()
	   };
   	
   	private Integer countAllFVF_OK = 0;
   	private Integer countAllFVF_KO = 0;
   	private Integer countAllItems = 0;
   	private Integer countAllItems_OK = 0;
   	private Integer countAllItems_KO = 0;
   	
   	RecordType fvfRecordTypeListing = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c',EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE);
   	 
   	public Batch_FVFCampaignBulkCSV(String fvfCampaignId, String docUnigueName,String numFormat,String separator)
   	{
   		this.fvfCampaignId = fvfCampaignId;
		this.docUnigueName = docUnigueName;
		this.csv_separator = separator;
		this.numFormat = numFormat;
		
		Document d = [Select Name,Body From Document where Name =:docUnigueName];
		m_csvFile =  d.Body.toString().replace('\n',''); //unix user only \r
	}
   	 
   	global Iterable<String> start(Database.batchableContext batchableContext)
   	{ 
   		Iterable<String> citer;
   		try
   		{
   			citer = new CSVIterator(m_csvFile,NEWLINE_CR,true); //skip header
   		}catch(Exception ex)
   		{
   			citer=(Iterable<String>)new List<String>(); System.debug('>>>Start Error: '+ex.getMessage());putError('fvf',ex.getMessage());
   		}
       return citer;
   	}
   	global void execute(Database.BatchableContext batchableContext, List<String> scope)  
   	{
       	String csvFile = ''; //construct small piece of csv from the scope 
       	for(String row : scope)
       	{
        	csvFile += row + NEWLINE_CR;
       	}
    	
    	OpenCSVParser parser = new OpenCSVParser(csv_separator,OpenCSVParser.DEFAULT_QUOTE_CHARACTER, OpenCSVParser.DEFAULT_ESCAPE_CHARACTER,OpenCSVParser.DEFAULT_STRICT_QUOTES, OpenCSVParser.DEFAULT_IGNORE_LEADING_WHITESPACE);
    	OpenCSVReader reader = new OpenCSVReader(parser,csvFile,NEWLINE_CR,false);//unix user only \r //to false to allow double quote with comma: 123,"1,23"
    	List<List<String>>listAllRows = reader.readAll();
    	
    	Set<String> sellerIds = new Set<String>();
    	//Orcale Id,	Listing Id,	Price target
    	List<CSVData> listData = new List<CSVData>();
    	
    	for(List<String> row : listAllRows)
    	{
    		try
    		{
    			CSVData cData = new CSVData(row,numFormat);
	    		//dont know what to do with missing Oracle Id or Listing Id
	    		if(String.isBlank(cData.oracleId) || String.isBlank(cData.listingId))continue; 
	    		
	    		listData.add(cData);
	    		if(String.isNotBlank(cData.oracleId))
	    		{
	    			sellerIds.add(cData.oracleId); //oracle id or sfid
	    		}
    		}catch(Exception ex)
    		{
    			putError('fvf',ex.getMessage()+' - check csv format!');system.debug('>>>Error execute: '+ex);
    		}
    	}
    	
    	//get parent FVF Campaign recordtype to copy field to newly created fvf listing 
    	Final_Value_Fee_FVF__c fvfCampaign = Database.query(EBH_ConstantsUtility.SOQL_FVF +' Where Id =:fvfCampaignId');
    	
    	//Lookup for Seller by provided Orcale Ids
    	Map<String,Account> mappSeller = new Map<String,Account>();
    	for(Account acc : Database.query(EBH_ConstantsUtility.CSV_SELLERQUERY))
    	{
			mappSeller.put(acc.EBH_OracleId__c,acc);    		
    	} 
    	//system.debug('>>>listData: '+listData);
    	
    	Map<String,Final_Value_Fee_FVF__c> mapFVFNew = new Map<String,Final_Value_Fee_FVF__c>();
    	//1, create FVF (listing) first
    	for(CSVData cdata : listData)
    	{
    		//avoid creating the same fvf listing from the same scope and all previous batches
			if(!mapNewFVF_All.containsKey(cdata.oracleId))
    		{
    			Account seller = mappSeller.get(cdata.oracleId);
	    		Final_Value_Fee_FVF__c fvfNew = createFVF(fvfCampaign,seller,cdata.oracleId);
				mapFVFNew.put(cdata.oracleId,fvfNew);  	
				
				//store in stateful
				//mapNewFVF_All.put(cdata.oracleId,null);
    		}
		}
		if(!mapFVFNew.isEmpty())
		{
			List<Final_Value_Fee_FVF__c> listFVFToInsert = mapFVFNew.values();
			Database.UpsertResult[] uFVFResult = Database.upsert(listFVFToInsert,Final_Value_Fee_FVF__c.Fields.Unique_Id__c,false); //partial success
			//system.debug('>>>listFVFToInsert: '+listFVFToInsert.size() );
			//system.debug('>>>mapFVFNew: '+JSON.serialize(mapFVFNew ));
			//system.debug('>>>mapNewFVF_All: '+mapNewFVF_All);
			for(Integer i=0;i< uFVFResult.size();i++)
			{
				if(uFVFResult[i].isSuccess())
				{
					//setNewFVF_OK.add(uFVFResult[i].getId());
					countAllFVF_OK++;
					String oraId = listFVFToInsert[i].Unique_Id__c.split('_')[1]; //parentFVF.Id+'_'+uidCSV
					//store in stateful
					mapNewFVF_All.put(oraId,uFVFResult[i].getId());
				}else
				{
					countAllFVF_KO++; putError('fvf',uFVFResult[i].getErrors()[0].getMessage());
					//System.debug('>>>>>>>fvf error:  '+uFVFResult[i].getErrors());
				}
				//else{mapNewFVF_KO.put(listFVFToInsert[i].Unique_Id__c.split('_')[1],uFVFResult[i].getErrors()[0].getMessage()); //parentFVF.Id+'_'+uidCSV}
			}
		}
    	
		
    	List<Nominated_Item__c> listItem = new List<Nominated_Item__c>();
    	//2, Create NItem 
    	for(CSVData cdata : listData)
    	{
    		//FVF-NomiantedItem: master detail
    		//FVF Listing needs to be first create sucessfully
    		if(mapNewFVF_All.containsKey(cdata.oracleId) && mapNewFVF_All.get(cdata.oracleId) <> null)
    		{
    			listItem.add(
	    			createITem(cdata,fvfCampaign,mapNewFVF_All.get(cdata.oracleId))
	    		);
    		}else {
				putError('item','FVF(listing level) Not Created: '+cdata.oracleId);
			}
    	}
    	countAllItems +=listData.size();
    	//system.debug('>>>listItem: '+listItem.size());
    	//count result of dml items
    	Database.UpsertResult [] itemInsertResult = Database.upsert(listItem, Nominated_Item__c.Fields.Unique_Id__c, false);
    	for(Integer i=0;i< itemInsertResult.size();i++)
		{
			if(itemInsertResult[i].isSuccess())
			{
				//mapNewItem_OK.put(itemInsertResult[i].getId());
				 countAllItems_OK++;
			}else
			{
				countAllItems_KO++;
				putError('item',itemInsertResult[i].getErrors()[0].getMessage());
			}
		}
   	}
   	
   	private Final_Value_Fee_FVF__c createFVF(Final_Value_Fee_FVF__c parentFVF ,Account seller,String uidCSV)
   	{
   		return new Final_Value_Fee_FVF__c(
   			FVF_Campaign__c = parentFVF.Id,
   			RecordTypeId = fvfRecordTypeListing.Id,
   			Seller_Name__c = seller==null?null:seller.Id,
   			Unique_Id__c = parentFVF.Id+'_'+uidCSV,   //external id for upsert
   			Start_Date_w__c = parentFVF.Start_Date_w__c,
   			Start_Time__c = parentFVF.Start_Time__c,
   			End_Date_w__c = parentFVF.End_Date_w__c,
   			End_Time__c = parentFVF.End_Time__c,
   			Free_shipping__c = parentFVF.Free_shipping__c,
   			Requestor__c = parentFVF.Requestor__c,
   			Discount_FVF__c = parentFVF.Discount_FVF__c,
   			Campaign_Name__c = parentFVF.Campaign_Name__c+'_'+(seller==null?uidCSV:seller.Name),
   			Business_Reason__c = parentFVF.Business_Reason__c
   		);
   	}
   	
   	private Nominated_Item__c createITem(CSVData cdata,Final_Value_Fee_FVF__c fvfCampaign, String fvfListingId)
   	{
   		return new Nominated_Item__c(
   			From_Upload__c = true,
			Unique_Id__c = fvfListingId+'_'+Decimal.valueOf(cdata.listingId).toPlainString(),
			Final_Value_Fee_FVF__c = fvfListingId,
	    	Price_target_w__c = cdata.priceTarget,
   			Listing_ID_w__c = cdata.listingId,
   			Discount_FVF_w__c = fvfCampaign.Discount_FVF__c
   		);	
   	}
   	
   	global void finish(Database.BatchableContext batchableContext)
	{
		//clear the tmp Doc
		Delete [Select Id from Document where Name = :docUnigueName];
		
		sendResult();    	
    	
	}
	
	private void sendResult()
	{
		String emailTemplateName = EBH_ConstantsUtility.EMAILTEMPLATE_FVF_CAMPAIGN_UPLOAD_RESULT;
		String whereCl = ' Where DeveloperName =: emailTemplateName'; 
    	List<EmailTemplate> empt = Database.query(EBH_ConstantsUtility.SOQLEMAIL_TEMPLATES + whereCl);
    	//System.debug('>>>fvfCampaignId: '+fvfCampaignId);
    	
    	Final_Value_Fee_FVF__c fvfCampaign = Database.query(EBH_ConstantsUtility.SOQL_FVF +' Where Id =:fvfCampaignId');
    	String htmlBody = contructBody(fvfCampaign,empt[0].HtmlValue);
	    if(!Test.isRunningTest()) ApexUtil.doSend(empt[0].subject,fvfCampaign.owner.Email,htmlBody);
			    
	}

	private void putError(String objType,String err)
	{
		//limit to 20 error list per object (fvf, item)
		if(mapError.get(objType).size()<NUM_ERROR_PER_LIST) 
		{
			mapError.get(objType).add(err);
		}else {
			mapError.get(objType).add('\r...AND MORE...');
		}
		
	}	
	private String getError(String objType)
	{
		return String.join(new List<String>(mapError.get(objType)),'\n');		 
	}	
	/********************************************************************
	@ Change history : 19.05.2025 / Vimean Heng / US-0026060 - Hiveforce product areas testing due to API version upgrade (1/5)
	********************************************************************/
	private String contructBody(Final_Value_Fee_FVF__c fvfCampaign, String hbody)
	{
		//system.debug('>>>mapError: '+mapError);
		//system.debug('>>>countAllItems_KO: '+countAllItems_KO+'  >>countAllItems_OK: '+countAllItems_OK);
		
		return hbody
		.replace('{!Owner}',Test.isRunningTest()?'Test':fvfCampaign.Owner.Name)
		.replace('{!urlFVF}',URL.getOrgDomainURL().toExternalForm() +'/lightning/r/Final_Value_Fee_FVF__c/'+fvfCampaign.Id+'/view')
		.replace('{!countItem}',ApexUtil.formatNumber(Decimal.ValueOf(countAllItems),0,numFormat.toUpperCase())+'')
		.replace('{!countFVF}',ApexUtil.formatNumber(Decimal.ValueOf(mapNewFVF_All.size()),0,numFormat.toUpperCase())+'')
		
		.replace('{!fvfOK}',ApexUtil.formatNumber(Decimal.ValueOf(countAllFVF_OK ),0,numFormat.toUpperCase())+'')
		.replace('{!fvfKO}',ApexUtil.formatNumber(Decimal.ValueOf(countAllFVF_KO ),0,numFormat.toUpperCase())+'')
		.replace('{!itemOK}',ApexUtil.formatNumber(Decimal.ValueOf(countAllItems_OK ),0,numFormat.toUpperCase())+'')
		.replace('{!itemKO}',ApexUtil.formatNumber(Decimal.ValueOf(countAllItems_KO ),0,numFormat.toUpperCase())+'')
		.replace('{!fvfError}',getError('fvf'))
		.replace('{!itemError}',getError('item'));
	}
	
	class CSVData{
		String oracleId;
		String listingId;
		Decimal priceTarget;
		
		//Orcale Id,	Listing Id,	Price target
		public CSVData(String[] csvRow,String numFormat)
		{
			//system.debug('>>>csvRow: '+csvRow);
			this.oracleId = csvRow[0]+''.trim();
			this.listingId= csvRow[1]+''.trim();
			this.priceTarget = Decimal.valueOf(ApexUtil.fixNumber(csvRow[2]+''.trim(), numFormat));
		}
		
	}	
	
	class TmpException extends Exception{

	}
}