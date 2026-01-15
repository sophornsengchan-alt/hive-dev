/*********************************************************************************************************************************
@ Class:          EBH_CSVUploaderController
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Handler Class for Page EBH_CSVUploader    
                  EPH-22, EPH-29 : Targeting Engine
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 08.05.2017 / JOY MONDOL / Created the class.
@				: 29.05.2018/ Vadhanak Voun / handle csv download
@				: 20.05.2022/ Sophal Noch / US-0011717 - Enable new column "Campaign Related Seller Details" in the Target List to create/update Key metrics in campaign members
*********************************************************************************************************************************/
global with sharing class EBH_CSVUploaderController {

    private static String FNAME_PRIORITY = 'Priority__c';

    public String csvData {get;set;}
    /*****************************************************************************************************************************
    @ Constructor:    EBH_CSVUploaderController
    @ Version:        1.0
    @ Author:         Vadhanak Voun (Vadhanak.voun@gaea-sys.com)
    @ Purpose:        initiates the class  for csv download                     
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.08.2018 / Vadhanak Voun / Created the Constructor.
    *****************************************************************************************************************************/
    public EBH_CSVUploaderController()
    { 
    	String attId = ApexPages.currentPage().getParameters().get('attId');
    	if(!String.isBlank(attId))
    	{
    		attId = String.escapeSingleQuotes(attId);
    		Attachment att = Database.query(EBH_ConstantsUtility.SOQL_ATTACHEMENT);
    		csvData = att.body.tostring();
    	}
    }   
	
    /*****************************************************************************************************************************
    @ Constructor:    EBH_CSVUploaderController
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        initiates the class                      
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.05.2017 / JOY MONDOL / Created the Constructor.
    *****************************************************************************************************************************/
    public EBH_CSVUploaderController(ApexPages.StandardController controller) { }   
    
    /*****************************************************************************************************************************
    @ Method:         createTargetedSellers
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        creates the Targeted Seller records                      
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String[]:     sellerIds - parsed from CSV uploaded on Seller List Snaphot
                      Id:           parentID
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.05.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    global static void createTargetedSellers(String[] sellerIds, Id parentId) {
        
        doCreateTargetedSellers(sellerIds,parentId,null);
    }
    
    /*****************************************************************************************************************************
    @ Method:         doCreateTargetedSellers
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        creates the Targeted Seller records . shairng with different param                   
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String[]:     	sellerIds - parsed from CSV uploaded on Seller List Snaphot
                      Id:           	parentID
                      jsMapId_priority: json object of mapping ora-id - priority
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.12.2018 / Vadhanak Voun / Created the  Method.
    @				: 31.07.2019 /Vadhanak Voun / EPH-7650: disabled 'delete' to allow duplicate
    @				: 22.11.2019/Vadhanak Voun / US-0000780 Don't insert duplicates in seller list
    @               : 20.05.2022/ Sophal Noch / US-0011717 - Enable new column "Campaign Related Seller Details" in the Target List to create/update Key metrics in campaign members
    *****************************************************************************************************************************/
    // private static void doCreateTargetedSellers(String[] sellerIds, Id parentId, String jsMapId_priority) {
    private static void doCreateTargetedSellers(String[] sellerIds, Id parentId, String jsMapId_fields) {
    	
    	// Map<String,Decimal> mapId_Priority = new Map<String,Decimal>();
    	// if(!String.isBlank(jsMapId_priority))
    	// {
    	// 	//system.debug('>>>>jsMapId_priority: '+jsMapId_priority);
    	// 	Map<String, String> m = (Map<String, String>)JSON.deserialize(jsMapId_priority,Map<String,String>.class);
        //     System.debug('m: '+m);
    	// 	for(String k: m.keySet())
    	// 	{
        //         System.debug('k: '+k);
    	// 		mapId_Priority.put(k, ApexUtil.toDecimal(m.get(k),2));
    	// 	}
  		// 	System.debug('>>>>mapId_Priority: '+mapId_Priority);
    	// }
        
        // 20.05.2022/ / Sophal Noch / US-0011717 : jsMapId_fields contains both Priority__c and Campaign_Related_Seller_Details__c
        Map<String, EBH_TargetedSeller__c> mapSellerIdToTargSeller = new  Map<String, EBH_TargetedSeller__c>();
        if(jsMapId_fields != null){
            mapSellerIdToTargSeller = (Map<String, EBH_TargetedSeller__c>)JSON.deserialize(jsMapId_fields,Map<String,EBH_TargetedSeller__c>.class);
            EBH_TargetedSeller__c firstTargSeller = !mapSellerIdToTargSeller.isEmpty() ? mapSellerIdToTargSeller.values()[0] : new EBH_TargetedSeller__c();
            // Boolean hasPriority = jsMapId_fields.contains('"Priority__c":');
            Boolean hasPriority = ((Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(firstTargSeller))).containsKey(FNAME_PRIORITY);
            for(EBH_TargetedSeller__c tSeller : mapSellerIdToTargSeller.values()){
                if(hasPriority) tSeller.Priority__c = tSeller.Priority__c == null ? tSeller.Priority__c : tSeller.Priority__c.setScale(2);
            }

        }


    	//delete previous targeted sellers
        //Note: exception handling done in page - remote handling
        //NK:31/07/2019
        //Database.delete(Database.query(EBH_ConstantsUtility.CSV_SELLERLISTQUERY));

        //Search Sellers based on the Oracle Id/Id
        Map<Id, Account> sellers = new Map<Id, Account>((List<Account>)Database.query(EBH_ConstantsUtility.CSV_ACCQUERY));
        
        List<EBH_TargetedSeller__c> targetedSellers = new List<EBH_TargetedSeller__c>();
        
        String strParentId = parentId.to15();

        //create new targeted Seller records
        for(Id sellerId : sellers.keySet()) {

            // targetedSellers.add(
            // new EBH_TargetedSeller__c(EBH_Seller__c = sellerId, EBH_SellerList__c = parentId,
            //     Priority__c = (mapId_Priority.containsKey(sellerId)?mapId_Priority.get(sellerId):(mapId_Priority.containsKey(sellers.get(sellerId).EBH_OracleId__c)?mapId_Priority.get(sellers.get(sellerId).EBH_OracleId__c):null))
            // )
            // );

            // 20.05.2022 / Sophal Noch / US-0011717 use target seller from json to insert or update with field EBH_UniqueListSeller__c
            EBH_TargetedSeller__c tSeller = (mapSellerIdToTargSeller.containsKey(sellerId)?mapSellerIdToTargSeller.get(sellerId):(mapSellerIdToTargSeller.containsKey(sellers.get(sellerId).EBH_OracleId__c)?mapSellerIdToTargSeller.get(sellers.get(sellerId).EBH_OracleId__c):new EBH_TargetedSeller__c()));
            String strSellerId = sellerId.to15();
            tSeller.EBH_UniqueListSeller__c = strSellerId + strParentId;
            tSeller.EBH_Seller__c = sellerId;
            tSeller.EBH_SellerList__c = parentId;
            targetedSellers.add(tSeller);
        }
        
        if(!targetedSellers.isEmpty()) {
            //Note: exception handling done in page - remote handling
            // Database.SaveResult[] saveResults = Database.insert(targetedSellers,false); //allow partial success if duplicate
            Database.UpsertResult[] saveResults = Database.upsert(targetedSellers,EBH_TargetedSeller__c.fields.EBH_UniqueListSeller__c, false); // 20.05.2022/ / Sophal Noch / US-001171
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:         createTargetedSellers
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        creates the Targeted Seller records                      
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String[]:     	sellerIds - parsed from CSV uploaded on Seller List Snaphot
                      Id:           	parentID
                      jsMapId_priority: json object of mapping ora-id - priority
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.12.2018 / Vadhanak Voun / Created the  Method.
    @ Change history: 20.05.2022/ Sophal Noch / US-0011717 - Enable new column "Campaign Related Seller Details" in the Target List to create/update Key metrics in campaign members
    *****************************************************************************************************************************/
    // @RemoteAction
    // global static void createTargetedSellers2(String[] sellerIds, Id parentId,String jsMapId_priority) {
    @RemoteAction
    global static void createTargetedSellers2(String[] sellerIds, Id parentId, String jsMapId_fields) {
        // doCreateTargetedSellers(sellerIds, parentId, jsMapId_priority);
    	doCreateTargetedSellers(sellerIds, parentId, jsMapId_fields);
    }
    /*****************************************************************************************************************************
    @ Method:         fetchSellers
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        fetches the valid seller oracle ids and id filtered by param oracle ids/ids                      
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String[]: sellerIds - seller oracle ids or ids
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map<String, List<String>>: map of valid seller oracle ids and ids
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.09.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    global static Map<String, List<String>> fetchSellers(String[] sellerIds) {
        
        //Sellers oracle id and id map on the Oracle Id/Id
        Map<String, List<String>> sellerMap
            = new Map<String, List<String>> { EBH_ConstantsUtility.CSV_IDS => new List<String>(), 
                                              EBH_ConstantsUtility.CSV_OIDS => new List<String>() };
        
        //fetch the sellers and populate the final map of valid sellers
        for(Account seller : Database.query(EBH_ConstantsUtility.CSV_SELLERQUERY)) {
            sellerMap.get(EBH_ConstantsUtility.CSV_IDS).add(seller.Id);
            sellerMap.get(EBH_ConstantsUtility.CSV_OIDS).add(seller.EBH_OracleId__c);
        }
        
        return sellerMap;
    }
	
	/*****************************************************************************************************************************
    @ Method:         createAttachment
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        [#EPH-5452] Target Engine - Manual Seller List Upload - Error Message Refinement
    @				  Temporary create an attachment for invalid id csv download, then delete right after csv downloaded                      
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String: csv data for attachment body
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map<String, String>: map result
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.05.2018 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    global static Map<String, String> createAttachment(String csvStringInvalidId,String parentId) {
        Map<String, String> mapResult = new Map<String,String>();
        
        Attachment attachment = new Attachment(ParentId=parentId,Name='TE_Temp_CSV',Body=Blob.valueOf(csvStringInvalidId));
        insert  attachment;
        
        mapResult.put('attId',attachment.Id);
        
        return mapResult;
    }
    /*****************************************************************************************************************************
    @ Method:         deleteAttachment
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        [#EPH-5452] Target Engine - Manual Seller List Upload - Error Message Refinement
    @				  Delete the Temporary attachment                      
    @------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.05.2018 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    public Pagereference deleteAttachment() {
    	String attId = ApexPages.currentPage().getParameters().get('attId');
    	if(!String.isBlank(attId))
    	{
    		attId = String.escapeSingleQuotes(attId);
    		database.delete(attId); 
    	}
       return null;
    } 
}