/*********************************************************************************************************************************
@ Class:         Batch_BobSellerBulkCSV
@ Version:       1.0
@ Author:        sovantheany.dim (sovantheany.dim@gaea-sys.com)
@ Purpose:       US-0007333 - LTTM - Bulk Upload BoB Sellers
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 26.03.2020 /sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the class.
@				: 19.01.2021/ Vadhanak Voun (vadhanak.voun@gaea-sys.com)/ US-0008692 - [LTTM Plus]Bulk Upload Cohort Seller to include "Managed Segment" for upload
@				: 10.02.2022/ Mony Nou (mony.nou@gaea-sys.com)/ US-0011094 - Light Touch Cohort Bulk Upload error - Throws List Index out of Bounds Error
@				: 03.11.2022/ Loumang SENG (loumang.seng@gaea-sys.com)/ US-0012749 - Cannot upload BOB Seller that contain "LTAM" or "Pro-Trader Category" in Managed Segment
@				: 03.07.2023/ Sovantheany Dim (sovantheany.dim@gaea-sys.com) / US-0013790 - Add parent seller to cohort bulk upload file
@				: 07.05.2025/ Sophal Noch / US-0017215 - Helper for US-0017159 to deploy UploadController
*********************************************************************************************************************************/
global without sharing class Batch_BobSellerBulkCSV implements Database.batchable<String>, Database.Stateful{
	private String m_csvFile;
	private String newLineToUse;
	//requested from component
   	private String numFormat = 'en'; //de or en
   	private String csv_separator = ','; 
   	private String docUnigueName; //Temporary document inserted from upload
   	private String bobId;
	private Set<String> allAffectSellers = new Set<String>();
	private Set<String> allAffectSellersManSeg = new Set<String>();

   	private Map<String, BoB_Seller__c> mapAllAffectSellers = new Map<String, BoB_Seller__c>();
   	private Integer countAllItems = 0;
   	private Integer countAllItems_OK = 0;
   	public static final String NEWLINE_LF = '\n';
   	public static final String NEWLINE_CR = '\r';
   	public static final String NEWLINE_CRLF = '\r\n';
   	public static Boolean isBatchBobSeller = false;
   	public final static String SOQL_BOB_1 = 'Select LTTM_Campaign_Name__c, Status__c, Name, RecordTypeId,Account_Manager__c,Owner.Name,owner.Email From BOB__c';
   	//store only last error to be displayed in email 
   	Map<String,String> mapLastError = new Map<String,String>();
   	
   	private Set<String> setNewBobSeller_All = new Set<String>(); //store all newly created bob seller from each scope of csv list
	private Set<String> sNoSellerFound = new Set<String>();
	private Set<String> sNoParentSellerFound = new Set<String>();
   	private Set<String> sNoUserFound= new Set<String>();
   	//private Map<String,Account> mappAllSeller = new Map<String,Account>();
   	//private Map<String,Account> mappAllSellerName = new Map<String,Account>();
   	private Set<String>  setSellerFail = new Set<String> ();
   	
   	private String soqlBobSellerQuery = 'Select Oracle_Id__c,Unique_Id__c,Seller__r.Name, Seller__c, BoB__r.Group_Name__c, BoB__r.Managed_Type__c, BoB__r.Account_Manager__c, BoB__r.Status__c, BoB__r.Name, BoB__r.OwnerId,BoB__r.Owner.Name, BoB__c From BoB_Seller__c';
   	private Set<String> setStatus = new Set<String>{EBH_ConstantsUtility.BOB_STATUS_SUBMITTED,EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT};
	
	private final Map<String,String> MAP_MANAGED_SEGMENT_PKVAL = new Map<String,String>{
		'LTAM' => 'PT LTAM',
		'Pro-Trader Category' => 'Pro-Trader Cat'
	};//LA-03-11-2022-US-0012749

	public Batch_BobSellerBulkCSV(String bobId, String docUnigueName,String numFormat,String separator)
   	{
   		this.bobId = bobId;
		this.docUnigueName = docUnigueName;
		this.csv_separator = separator;
		this.numFormat = numFormat;
		Document d = [Select Name,Body From Document where Name =:docUnigueName];
		//TH: 05/06/2020 : US-0007688 : bug 2
		m_csvFile =  d.Body.toString();
		newLineToUse =  Batch_BobSellerBulkCSV.NEWLINE_LF;
		if(m_csvFile.contains(Batch_BobSellerBulkCSV.NEWLINE_CR)){
			newLineToUse = Batch_BobSellerBulkCSV.NEWLINE_CR;
			m_csvFile =  m_csvFile.replace('\n','');
		}
	}
	global Iterable<String> start(Database.batchableContext batchableContext)
   	{
   		Iterable<String> citer;
   		try
   		{
   			citer = new CSVIterator(m_csvFile,newLineToUse,true); //skip header
   		}catch(Exception ex)
   		{
   			citer=(Iterable<String>)new List<String>();mapLastError.put('error','At Start: '+ex.getMessage());
   		}
       return citer;
   	}
   	global void execute(Database.BatchableContext batchableContext, List<String> scope)  
   	{
   		String csvFile = ''; //construct small piece of csv from the scope 
       	for(String row : scope)
       	{
        	csvFile += row + newLineToUse;
       	}
       	OpenCSVParser parser = new OpenCSVParser(csv_separator,OpenCSVParser.DEFAULT_QUOTE_CHARACTER, OpenCSVParser.DEFAULT_ESCAPE_CHARACTER,OpenCSVParser.DEFAULT_STRICT_QUOTES, OpenCSVParser.DEFAULT_IGNORE_LEADING_WHITESPACE);
    	OpenCSVReader reader = new OpenCSVReader(parser,csvFile,newLineToUse,false);//unix user only \r //to false to allow double quote with comma: 123,"1,23"
    	List<List<String>>listAllRows = reader.readAll();
    	Set<String> sellerIds = new Set<String>();
    	Set<String> corpID = new Set<String>();
    	List<CSVData> listData = new List<CSVData>();
    	for(List<String> row : listAllRows)
    	{
    		try
    		{
    			CSVData cData = new CSVData(row,numFormat);
				
				if(MAP_MANAGED_SEGMENT_PKVAL.containsKey(cData.managedSegment)) cData.managedSegment = MAP_MANAGED_SEGMENT_PKVAL.get(cData.managedSegment);//LA-03-11-2022-US-0012749

	    		//dont know what to do with missing Oracle Id or Listing Id
	    		if(String.isBlank(cData.oracleId))continue; 
	    		listData.add(cData);
	    		if(String.isNotBlank(cData.oracleId))
	    		{
					sellerIds.add(cData.oracleId); //oracle id or sfid
					if(String.isNotBlank(cData.parentSellerOracleId)) sellerIds.add(cData.parentSellerOracleId);//TH:US-0013790: oracle id or sfid
	    			corpID.add(cData.accountManager);
	    			corpID.add(cData.secondaryAM);
	    			
	    		}
    		}catch(Exception ex)
    		{
    			mapLastError.put('error',ex.getMessage()+' - check csv format!');
    		}
    	}
    	//System.debug('<<<<listData='+listData);
    	//Lookup for Seller by provided Orcale Ids
	    Map<String,Account> mappSeller = new Map<String,Account>();
	    for(Account acc : Database.query(EBH_ConstantsUtility.CSV_SELLERQUERY))
	    {
	    	mappSeller.put(acc.EBH_OracleId__c,acc); 
	    	//store all seller in stateful
	    	//mappAllSeller.put(acc.EBH_OracleId__c,acc);
	    	//mappAllSellerName.put(acc.Id,acc);
	    } 
	    //TH: 05/08/2020: US-0007901: lookup for User by privided corp id
	    Map<String,User> userMap = new Map<String,User>();
	    for(User usr: Database.query('select id,FederationIdentifier from user where (FederationIdentifier IN: corpID OR Id IN: corpID) AND UserType in (\'Standard\', \'PowerPartner\')') ){ //07.05.2025/ Sophal Noch/ US-0017215 : fix governor limit 50001
	    	userMap.put(usr.FederationIdentifier, usr);
        }
	    Map<String,BoB_Seller__c> mapBobSellerNew = new Map<String,BoB_Seller__c>();
	    for(CSVData cdata : listData)
	    {
		    if(!setNewBobSeller_All.contains(cdata.oracleId)){
		    	//store in stateful
		    	setNewBobSeller_All.add(cdata.oracleId);
		    	Account seller = mappSeller.get(cdata.oracleId);
		    	if(seller == null) {
		    		sNoSellerFound.add(cdata.oracleId);
		    		continue;
				}
				
		    	BoB_Seller__c bobSellerNew = createBobSeller(bobId,seller,cdata);
		    	
		    	User userAccMang = userMap.get(cdata.accountManager);
		    	User userSecondary = userMap.get(cdata.secondaryAM);
		    	if(userAccMang == null){
		    		if(!String.isBlank(cdata.accountManager)) sNoUserFound.add(cdata.accountManager);
		    	}else{
		    		bobSellerNew.Account_Manager__c = userAccMang.Id;
		    	}
		    	if(userSecondary == null){
		    		if(!String.isBlank(cdata.secondaryAM)) sNoUserFound.add(cdata.secondaryAM);
		    	}else{
		    		bobSellerNew.TTEC_MANAGER__c = userSecondary.Id;
				}
				//TH:US-0013790: Parent Seller
				if(String.isNotBlank(cdata.parentSellerOracleId)){
					Account parentSeller = mappSeller.get(cdata.parentSellerOracleId);
					//if parent seller not exist
					if(parentSeller == null) {
						sNoParentSellerFound.add(cdata.parentSellerOracleId);
					}else{
						bobSellerNew.Parent_Seller__c = parentSeller.Id;
					}
				}
		    	mapBobSellerNew.put(cdata.oracleId,bobSellerNew);
		    }
	    }
	    set<String> sAffectSeller = new Set<String>();
	    List<BoB_Seller__c> listBobSellerToInsert = mapBobSellerNew.values();
	    isBatchBobSeller = true;
		Database.UpsertResult[] uBobSellerResult = Database.upsert(listBobSellerToInsert,BoB_Seller__c.Fields.Unique_Id__c,false); //partial success
       	//Database.SaveResult[] uBobSellerResult = Database.insert(listBobSellerToInsert,false);
       	for(Integer i=0;i< uBobSellerResult.size();i++)
		{
			if(uBobSellerResult[i].isSuccess())
			{
				countAllItems_OK++;
			}else
			{
				//TH:05.08.2020 :US-0007901
				String sellerId = listBobSellerToInsert.get(i).Seller__c;

				//NK:20/01/2021:US-0008692
				//system.debug('>>>error :'+uBobSellerResult[i].getErrors()[0].getMessage());	//Managed Segment: bad value for restricted picklist field: test
				//system.debug('>>>error :'+uBobSellerResult[i].getErrors()[0].getStatusCode());	//INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST
				if((uBobSellerResult[i].getErrors()[0].getStatusCode()+'').contains('INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST'))
				{
					allAffectSellersManSeg.add(sellerId);
				} 
				
				//check to avoid query bob seller multi time
				if(!allAffectSellers.isEmpty() && allAffectSellers.contains(sellerId)){
					continue;
				}
				//store in stateful
				allAffectSellers.add(sellerId);
								
				sAffectSeller.add(sellerId);
				
			}
		}
		
		if(!sAffectSeller.isEmpty()){
			String addtionalWhere = '  AND  (Active__c = true OR BoB__r.Status__c IN :setStatus)';
			for(BoB_Seller__c existingBobSeller : Database.query(soqlBobSellerQuery + ' where Seller__c IN: sAffectSeller'+addtionalWhere)){
				mapAllAffectSellers.put(existingBobSeller.BoB__c+'_'+existingBobSeller.Seller__c,existingBobSeller);
			}
		}
		
		//System.debug('<<<<uBobSellerResult='+uBobSellerResult);
		//System.debug('<<<<countAllItems_OK='+countAllItems_OK);
		countAllItems +=listData.size();
   	}
   	global void finish(Database.BatchableContext batchableContext)
	{
		isBatchBobSeller = false;
		//clear the tmp Doc
		Delete [Select Id from Document where Name = :docUnigueName];
		sendResult();
	}
	private void sendResult()
	{
		String emailTemplateName = EBH_ConstantsUtility.BULK_RESULT_EMAIL;
		String whereCl = ' Where DeveloperName =: emailTemplateName'; 
    	List<EmailTemplate> empt = Database.query(EBH_ConstantsUtility.SOQLEMAIL_TEMPLATES + whereCl);
    	
    	BOB__c bob = Database.query(SOQL_BOB_1 +' Where Id =:bobId');
    	
    	String htmlBody = contructBody(bob,empt[0]);
    	
	    if(!Test.isRunningTest()) ApexUtil.doSend(empt[0].subject.replace('{!BOB__c.Name}',bob.Name),bob.owner.Email,htmlBody);
			    
	}
	/*private String errorBody = 
	'<p>The below sellers are not successfully added to the cohort as they are part of another BoB that is either in draft, submitted or active. If you would like to proceed the seller need to be removed from the active BOB.</p>'+
	'<p>1.Please reach out to respective BoB owners and ask to remove these sellers from the current BoB.</p>'+
	'<p>2.Once the sellers has been removed from the current BOB you are able add to your book.</p>'+
	'<p><Strong>Affect Seller:</Strong> {!affectSeller}</p>';*/
 	
	private String contructBody(BOB__c bob, EmailTemplate emt)
	{
		String hbody = emt.HtmlValue;
	    List<BoB_Seller__c> listAffectSeller = mapAllAffectSellers.isEmpty() ? new List<BoB_Seller__c>() : mapAllAffectSellers.values();
	    //listAffectSeller.sort();
    	hbody = hbody.contains('{!listAffectSeller}')?hbody.replace('{!listAffectSeller}',generateHTMLRow(listAffectSeller,htmlRowTemplate,false)):hbody;
	    		
		List<String> noSellerFounds = new List<String>(sNoSellerFound);
		String noSellerFound = sNoSellerFound.isEmpty()?'': noSellerFounds.size()+' sellers are not found :'+String.join(noSellerFounds,',');

		//TH:US-0013790:add Parent seller not found message to template
		List<String> noParentSellerFounds = new List<String>(sNoParentSellerFound);
		String noParentSellerFound = noParentSellerFounds.isEmpty()?'': 'Below is the list of Parent Seller that are not updated because Id was incorrect or seller does not exist in HIVE:'+'['+String.join(noParentSellerFounds,',')+']';
		
		List<String> lstUserNotFounds = new List<String>(sNoUserFound);
		String userNotFound = lstUserNotFounds.isEmpty()?'':'['+String.join(lstUserNotFounds,',')+']';

		List<String> listErrorManSeg = new List<String>();
		for(Account seller : [Select Id,Name From Account where Id IN:allAffectSellersManSeg])
		{
			listErrorManSeg.add(seller.Name) ;

		}		 
		String sellerManSegList = listErrorManSeg.isEmpty()?'':'['+String.join(listErrorManSeg,', ')+']';

		return hbody
		.replace('{!Owner}',Test.isRunningTest()?'Test':bob.Owner.Name)
		.replace('{!CountBobSeller}',ApexUtil.formatNumber(Decimal.ValueOf(countAllItems_OK),0,numFormat.toUpperCase())+'')
		.replace('{!errorMessage}',mapLastError.containsKey('error')?mapLastError.get('error'):'')
		.replace('{!sellernotFound}',noSellerFound)
		.replace('{!parentSellernotFound}',noParentSellerFound)
		.replace('{!isAffectSeller}',listAffectSeller.isEmpty()?'display: none':'display: block')
		.replace('{!isCorrectUser}',lstUserNotFounds.isEmpty()?'display: none':'display: block')
		.replace('{!listIncorrectUser}',userNotFound)
		.replace('{!LTTMCampaignName}',bob.LTTM_Campaign_Name__c)

		.replace('{!showBlock_ManSeg}',allAffectSellersManSeg.isEmpty()?'none':'inline')
		.replace('{!listAffectSellerManSeg}',allAffectSellersManSeg.isEmpty()?'':sellerManSegList);
		//.replace('{!affectSeller}',affectSellerMessage);
	}
	
	private BoB_Seller__c createBobSeller(Id bobId ,Account seller,CSVData cdata)
   	{
   		RecordType lttmRecordType = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
   		BoB_Seller__c bs = new BoB_Seller__c(
			Seller__c = seller != null ? seller.Id : null,
			BoB__c = bobId,
			Unique_Id__c = bobId+'_'+cdata.oracleId,			
			RecordTypeID = lttmRecordType.Id);
			
		if(String.isNotBlank(cdata.managedSegment))
		{
			bs.EBH_BOBSegment__c = cdata.managedSegment;
		}
		return bs;
   	}
   	
   	private static String htmlRowTemplate = '<tr><td>{!sellerName}</td><td>{!oracleId}</td><td><a title="{!bobName}" href="{!url}/{!bobSellerId}">{!bobName} && {!bobGroupName}</a></td><td>{!bobManagedType}</td><td>{!bobOwner}</td><td>{!bobStatus}</td></tr>';
	
	private static String generateHTMLRow(List<BoB_Seller__c> listAffectSeller,String htmlRowStringTemplate,Boolean istext)
 	{ 
 		if(listAffectSeller==null || (listAffectSeller <>null && listAffectSeller.isEmpty()))return '';
 		
 		String htmlRowString  = '';
 		for(BoB_Seller__c affectSeller : listAffectSeller)
 		{
 			//'Select Unique_Id__c,Seller__r.Name, Seller__c, BoB__r.Group_Name__c, BoB__r.Managed_Type__c, BoB__r.Account_Manager__c, BoB__r.Status__c, BoB__r.Name, BoB__r.OwnerId,BoB__r.Owner.Name, BoB__c From BoB_Seller__c'
 			htmlRowString = htmlRowString + htmlRowStringTemplate
 			.replace('{!sellerName}',String.isBlank(affectSeller.Seller__c+'')?'':affectSeller.Seller__r.Name)
 			.replace('{!bobName}',String.isBlank(affectSeller.BoB__c)?'':affectSeller.BoB__r.Name)
 			.replace('{!bobGroupName}',String.isBlank(affectSeller.BoB__r.Group_Name__c)?'':affectSeller.BoB__r.Group_Name__c)
 			.replace('{!bobManagedType}',String.isBlank(affectSeller.BoB__r.Managed_Type__c)?'':affectSeller.BoB__r.Managed_Type__c)
 			.replace('{!bobOwner}',String.isBlank(affectSeller.BoB__r.OwnerId) || String.isBlank(affectSeller.BoB__r.Owner.Name)?'':affectSeller.BoB__r.Owner.Name)
 			.replace('{!bobStatus}',String.isBlank(affectSeller.BoB__r.Status__c)?'':affectSeller.BoB__r.Status__c)
 			.replace('{!url}',System.URL.getSalesforceBaseUrl().toExternalForm())
 			.replace('{!bobSellerId}',affectSeller.BoB__c)
			.replace('{!oracleId}',String.isBlank(affectSeller.Oracle_Id__c)?'':affectSeller.Oracle_Id__c) // LA:19-04-2021
 			;
 		}
 		return htmlRowString;
 	}
 	
	class CSVData{
		String oracleId;
		String accountManager;
		String secondaryAM;
		String managedSegment;
		String parentSellerOracleId;

		//Orcale Id
		public CSVData(String[] csvRow,String numFormat)
		{
			this.oracleId = csvRow[0]+''.trim();
			this.accountManager = csvRow.size()>1?csvRow[1]+''.trim():''; //MN-10022022-US-0011094
			this.secondaryAM = csvRow.size()>2?csvRow[2]+''.trim():''; //MN-10022022-US-0011094
			this.managedSegment = csvRow.size()>3?csvRow[3]+''.trim():''; 
			this.parentSellerOracleId = csvRow.size()>4?csvRow[4]+''.trim():''; //TH:03/07/23:US-0013790
		}
	}	
}