/*********************************************************************************************************************************
@ Class:          LC_ProductSearchController
@ Version:        1.0
@ Author:         Migrated from Join
@ Purpose:        US-0009355 - [Ads 2020] Product Packages
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 27.04.2021 / Vadhanak Voun / mofified the class. US-0009355 - [Ads 2020] Product Packages
@				: 19.05.2021 / Vadhanak Voun / US-0009560 - Ads UAT Bug - Product Configurator Currency Issues
@ 				: 20.05.2021 / Mony Nou / US-0009561 - Ads UAT Bug - Error on leaving Targeting page 
@											- Replace picklist with Lightning:recordEditForm to Combobox
@				: 22.06.2021 / Mony Nou / US-0009763 - Allow Editing on line items with End Date in present or future
@				: 20.01.2022 / Sophal Noch / US-0010886 - 1PD Campaign Tracking
@				: 23.03.2022 / SRONG TIN / US-0011527: ADS - Product Configurator line items
@				: 06.07.2023 / Bora Chhorn / US-0013228 - ADS - Package Components Sales Price Sync
@				: 10.10.2023 / Sophal Noch / US-0014249 - ADS - PL Product Configurator
@				: 10.12.2024 / Sothea Horn / US-0016235 - ADS - Apply Filters on Price books in Edit line items screen
*********************************************************************************************************************************/
public without sharing class LC_ProductSearchController {
    
    public static final String OVERRIDE_ON_EXISTING_LIST = 'override-list';
    public static final String EXTEND_EXISTING_LIST = 'extend-list';
    public static final String OVERRIDE_ACTION_UPDATE = 'update';
    public static final String OVERRIDE_ACTION_DELETE = 'delete';

	private final static String PRODUCT_RT_PACKAGE = 'Package';	

	//NK:30/04/2021:US-0009355/fields to copy from main product (package) to its related components
	private static Set<String> MAIN_FIELDS = new Set<String>{
		'X1P_Advertising__c','QuoteId',	'until_Date__c','from_Date__c','UnitPrice',	'Customer_Order_No__c',
		'Rate_Discount_II__c','Check_Inventory__c','Quantity','Guaranteed_AI__c','Targeting_type__c','FC_Quantity__c',
		'FC_Period__c','FC_Ad_served_every__c',	'AdKeyWords__c',
		'Additional_Billing_information2__c','Additional_Billing_information1__c',
		'Boomerang__c',	'Description', 'Billing_Category__c','Availability__c',	'PricebookEntryId',		
		'Rebate_In_Kind__c','Rebate_In_Kind_Reason__c', 'Targeting__c', 'CountriesDescription__c','AdKeyWords__c',
		'AE__c'//Sophal:12/04/2022:US-0011095
	};
	private final static String PARAM_LIST_EXIST_PKG_QLI_ID = 'listExistPkgQliId';

	// public static final String QUOTELINEITEM_SOQL = 'SELECT Id,Targeting__c,Product2.Targetings__c,Product_Package__r.Package__r.Targeting__c,'
	// +'Product2.PredifinedAdunit__c, Product2.Placement_Type__c,Product2.Device_Type__c,Product2Id, UnitPrice,'
	// +'until_Date__c, from_Date__c, Quantity, Quantity__c, Availability__c, Last_Availability_Forecast__c,'
	// +'Targeting__r.Id, Targeting__r.Availability__c, Targeting__r.Matching_Units__c, Targeting__r.Available_Impressions__c, Targeting__r.Available_Matching_Impressions__c,Targeting__r.Available_Share_of_Voice__c,Targeting__r.Last_Availability_Forecast__c,'
	// +'Product2.Name, Product2.Id, Product2.Time__c, Product2.Site__c, Product2.Site__r.Name,'
	// +'Product2.FC__c, Product2.OperatingSystem__c, Product2.Bandwidth__c, '
	// +'Product2.Connection__c, Product2.Browser__c, Product2.Device__c, '
	// +'Product2.Geo_IP__c, Product2.Keywords__c, Product2.Content__c, '
	// +'Product2.Billing_Category__c,'
	// +'Product2.Billing_Category2__c, Product2.Product_Type__c,'
	// +'Budget__c, SalesPriceNet__c, CreatedDate, Product_Package__c,'
	// +'Product_Package__r.Package__c , Product_Package__r.Package__r.Name,'
	// +'Description, SortOrder__c, PricebookEntryId,'
	// +'Product2.Advertising_Medium__r.Dart_AdSlotSize__c, Product2.Advertising_Medium__r.Name, Product2.Advertising_Medium__r.DART_AdType__c,'
	// +'Product2.Advertising_Medium__r.Dart_Product_Type__c,'
	// +'X1P_Advertising__c,Targeting_Type__c,Rebate_In_Kind_Reason__c,Rate_Discount_II__c,Additional_Billing_information1__c,'+'Additional_Billing_information2__c,Customer_Order_No__c,Billing_Category__c'
	// +' FROM QuoteLineItem WHERE QuoteId =: quoteId ORDER BY SortOrder__c ASC';

	// public static final String PE_SOQL = 'SELECT Product2.Placement_Type__c,Product2.Device_Type__c,Name, Id, UnitPrice,'
	// +'Product2.Name, Product2.Id, Product2.Family, Product2.Category__c, Product2.Site__c,'
	// +'Product2.Placement__r.Name, Product2.Advertising_Medium__r.Dart_AdSlotSize__c,'
	// +'Product2.Billing_Category__c,'
	// +'Product2.Advertising_Medium__r.Name, Product2.Advertising_Medium__r.DART_AdType__c, Product2.Advertising_Medium__r.Dart_Product_Type__c,'
	// +'Product2.Product_Type__c,Product2.Site__r.Name,Product2.Billing_Category2__c'
	// +' FROM PricebookEntry WHERE Pricebook2Id =: pricebook2Id AND isActive = true AND Product2.isActive = true';

    private static final String SOQL_PBE = 'SELECT Product2.Placement_Type__c,Product2.Device_Type__c,Name, Id, UnitPrice, PriceBook2Id,PriceBook2.Name,'+
			'Product2.Name, Product2.Id, Product2.Family, Product2.Category__c, Product2.Site__c, '+
			'Product2.Placement__r.Name, Product2.Advertising_Medium__r.Dart_AdSlotSize__c, Product2.Non_GAM_Product__c, '+
			'Product2.Billing_Category__c,Product2.Fixed_Price__c,Product2.RecordType.Name, CurrencyIsoCode, '+
			'Product2.Advertising_Medium__r.Name, Product2.Advertising_Medium__r.DART_AdType__c, Product2.Advertising_Medium__r.Dart_Product_Type__c, '+
			'Product2.Product_Type__c,Product2.Site__r.Name,Product2.Billing_Category2__c,Product2.RecordType.DeveloperName '+  // Sophal:26/02/2021:US-0009134, // Sophal:26/01/2022:US-0010886
			'FROM PricebookEntry ';

	@TestVisible
	private static final String SOQL_QLI = 'SELECT Id,Targeting__c,Product2.Targetings__c,Product_Package__r.Package__r.Targeting__c,Product2.PredifinedAdunit__c,'+
			'Product2.Placement_Type__c,Product2.Device_Type__c,Product2Id, UnitPrice,'+
			'until_Date__c, from_Date__c, Quantity, Quantity__c, Availability__c, Last_Availability_Forecast__c,'+
			'Targeting__r.Id, Targeting__r.Availability__c, Targeting__r.Matching_Units__c, Targeting__r.Available_Impressions__c, Targeting__r.Available_Matching_Impressions__c,Targeting__r.Available_Share_of_Voice__c,Targeting__r.Last_Availability_Forecast__c,'+ // Sophal:03/03/2021:US-0009139 
			'Product2.Name, Product2.Id, Product2.Time__c, Product2.Site__c, Product2.Site__r.Name,'+ // Sophal:26/02/2021:US-0009134 
			'Product2.FC__c, Product2.OperatingSystem__c, Product2.Bandwidth__c, Product2.Non_GAM_Product__c, '+
			'Product2.Connection__c, Product2.Browser__c, Product2.Device__c, '+
			'Product2.Geo_IP__c, Product2.Keywords__c, Product2.Content__c, Product2.Billing_Category__c,'+
			'Product2.Billing_Category2__c, Product2.Product_Type__c,'+  // Sophal:26/02/2021:US-0009134 
			'Targeting_Fee2__c,Rate_Discount_I__c,Special_Agency_Discount__c,AE__c,Special_Agency_Discount_Percent__c,Product2.Fixed_Price__c,'+ //NK:09/04/2021:US-0009335
			'Budget__c, SalesPriceNet__c, CreatedDate, Product_Package__c,Boomerang__c,Number_of_Targeting_Criteria__c,Product2.RecordType.Name,'+
			'Product_Package__r.Package_Product__c , Product_Package__r.Package_Product__r.Name,Product2.RecordType.DeveloperName,'+ // Sophal:26/01/2022:US-0010886
			'Description, SortOrder__c, PricebookEntryId,Product2.available_Key_Values__c,'+
			'package_line_item__c,QuoteId,PricebookEntry.Product2Id,'+ // Sophal:26/01/2022:US-0010886
			'Product2.Advertising_Medium__r.Dart_AdSlotSize__c, Product2.Advertising_Medium__r.Name, Product2.Advertising_Medium__r.DART_AdType__c, Product2.Advertising_Medium__r.Dart_Product_Type__c,'+ // Sophal:26/02/2021:US-0009134 
			'X1P_Advertising__c,Targeting_Type__c,Rebate_In_Kind_Reason__c,Rate_Discount_II__c,Additional_Billing_information1__c,Additional_Billing_information2__c,Customer_Order_No__c,Billing_Category__c FROM QuoteLineItem '; // Sophal:26/02/2021:US-0009134
	
	private static final String SOQL_QUOTE = 'SELECT Id, Name, Pricebook2Id, OpportunityId, Media_Plan__r.End_Flight_Date__c, Price_Book__c, CurrencyIsoCode,'+
			'Media_Plan__r.Start_Flight_Date__c, Opportunity.Amount, AE__c,Rate_Discount_I__c,'+
			'Rate_Special_Agency_Discount__c,'+ //MN-03062021-US-0009631
	        'Opportunity.Type, Dually_Signed__c,'+ 
			'Status, Media_Plan__r.IsRevision__c,'+
			'Opportunity.Start_Date__c, Opportunity.End_Date__c,'+ //Sophal Noch: 05/12/2020: US-
			'Is_Revised_Quote__c, Buyer_Accepted__c '+ //Sophal Noch: 25/01/2021: US-0009024
	        'FROM Quote WHERE Id = :quoteId LIMIT 1';		
	
	//	
	
	/*********************************************************************************************************************************
	----------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 25.02.2022 / Acmatac SEING / US-0010618 - ADS - New Product record types and rename existing
	@				: 10.10.2023 / Sophal Noch / US-0014249 - ADS - PL Product Configurator
	&				: 10.12.2024 / Sothea Horn / US-0016235 - ADS - Apply Filters on Price books in Edit line items screen
	*********************************************************************************************************************************/		
    @AuraEnabled
    public static RemoteResponse initializeQuoteAndPricebookEntries(String quoteId, List<Id> productIds) {
        RemoteResponse rrs = new RemoteResponse();
        Map<String, Object> res = new Map<String, Object>();
        List<PricebookEntry> lstPE = new List<PricebookEntry>();

		Set<Id> setSite = new Set<Id>();
        try {

			List<Quote> listQuotes = ApexSafe.query().doQuery(SOQL_QUOTE, new Map<String, Object> {'quoteId' => quoteId});
	        Quote quote = listQuotes[0];
			
			// GW_Quote.assignDefaultPricebook(q); //Sophal:26/02/2021: US-0009102 && US-0009134 // not use anymore
        	if(quote.Pricebook2Id == null){
				// Sophal:26/02/2021:US-0009102 && US-0009134 // if there is only 1 pricebook, use it as default
				List<Pricebook2> pricebook = LC_AddPricebook2Quote.getPricebookData(null, quote.OpportunityId);
				if (pricebook.size() == 1) {
					quote.Pricebook2Id = pricebook[0].Id; 
					ApexSafe.dml().doUpdate(new List<Quote>{quote}, true);
				}
			}
			
			//  Sophal:01/03/2021:US-0009134  use in  database query, so Product2.Billing_Category__c datatype can be changed to multi-select picklist 
			// Id pricebook2Id = q.Pricebook2Id; //Sophal:19/03/2021:US-0009251 disable. because we can use normal query now

			// Acmatac NOTE: DART6 = GAM
			String proRecTypeDart6 = 'DART6'; //AND Product2.RecordType.Name=:proRecTypeDart6 
			// SRONG TIN 23-03-2022 US-0011527: ADS - Product Configurator line items
			String proRecTypeCallisto = 'Callisto';
			String proRecTypeNonAdServer = 'Non_Ad_Server';
			String proRecTypePlCampaign= 'PL_Campaign'; // 10.10.2023 / Sophal Noch / US-0014249

			Set<String> setProRecType = new Set<String>{proRecTypeDart6, proRecTypeCallisto, proRecTypeNonAdServer, proRecTypePlCampaign}; // 10.10.2023 / Sophal Noch / US-0014249

			String priceBookId = quote.Pricebook2Id; 
			String currCode = quote.CurrencyIsoCode;

			// Acmatac: US-0010618 - ADS - New Product record types and rename existing
			// TH : US-0011975 - NA ADS - Illegal Request Issue on Export Line Items link : 08/07/2022 : include Product Package Record type
			// String swhere = ' WHERE Pricebook2Id =:priceBookId AND isActive=true AND Product2.isActive=true AND CurrencyIsoCode = :currCode AND Product2.package_component_only__c=false AND ( Product2.RecordType.DeveloperName=:proRecTypeDart6 OR Product2.RecordType.DeveloperName=:proRecTypeCallisto OR Product2.RecordType.DeveloperName=:proRecTypeNonAdServer)  Order by Product2.Name';
			// 10.10.2023 / Sophal Noch / US-0014249 : disable soql above and write a new one that support Set<String> for Product2.RecordType.DeveloperName
			String swhere = ' WHERE Pricebook2Id =:priceBookId AND isActive=true AND Product2.isActive=true AND CurrencyIsoCode = :currCode AND Product2.package_component_only__c=false AND Product2.RecordType.DeveloperName IN: setProRecType Order by Product2.Name';

			List<PricebookEntry> listPricebookEntries = ApexSafe.query().doQuery(SOQL_PBE + swhere, new Map<String, Object> {
				'priceBookId' => priceBookId,
				'currCode' => currCode,
				'setProRecType' => setProRecType
			});

			for (PricebookEntry pe : listPricebookEntries) {
			
			// Sophal:01/03/2021:US-0009134 use database query instead, Product2.billing_category__c datatype can be changed to multi-select picklist 
			// for (PricebookEntry pe : Database.query(PE_SOQL)){ //Sophal:19/03/2021:US-0009251 disable to use normal query because Product2.billing_category__c has changed to multi-picklist

					// MN-050320201: Shortening the codes to make it into one line for IF/ELSE IF
					if (productIds == null || productIds.isEmpty()) { lstPE.add(pe); } 
					else if (productIds.contains(pe.Product2.Id)) 	{ lstPE.add(pe); }
	        }

	        res.put('quote', quote);
	        res.put('lstPE', lstPE);
	        rrs.statusCode = RemoteResponse.STATUSCODE_OK;
	        rrs.content = res;
	        rrs.message = 'success';
        } catch (Exception e) { rrs.statusCode = RemoteResponse.STATUSCODE_ERROR;rrs.message = e.getMessage();rrs.debug = e.getMessage() + ':' + e.getStackTraceString();
        }
        return rrs;
    }   

    @AuraEnabled
    public static RemoteResponse initializeData(String quoteId){
    	
    	RemoteResponse rrs = new RemoteResponse();
    	Map<String, Object> res = new Map<String, Object>();

	    try {
	        RemoteResponse rrsQPE = initializeQuoteAndPricebookEntries(quoteId, null);
	        Quote q = (Quote)((Map<String, Object>)rrsQPE.content).get('quote');
	        List<PricebookEntry> lstPE = (List<PricebookEntry>)((Map<String, Object>)rrsQPE.content).get('lstPE');
        	res.put('quote', q);
        	res.put('lstPE', lstPE);
			//res.put('isRevision', (q.Opportunity.Type == Label.OPP_TYPE_DIRECT_REVISION));
			
        	// res.put('isRevision', (q.Media_Plan__r.IsRevision__c));
			// res.put('isLock', GW_Quote.isLock(q));
			res.put('isRevision', (q.Is_Revised_Quote__c)); //Sophal Noch: 25/01/2021: US-0009024
			res.put('isLock', isLock(q)); //Sophal Noch: 25/01/2021: US-0009024
	        
	        Map<Id, QuoteLineItem> mpLineItem = new Map<Id, QuoteLineItem>();
            //Map<Id, Package__c> mpPackage = new Map<Id, Package__c>();
			Map<Id, SObject> mpPackage = new Map<Id, SObject>();
            
			String sWhereQLI = ' WHERE QuoteId =:quoteId AND package_line_item__c=NULL ORDER BY SortOrder__c ASC'; //not the child of the package
            List<QuoteLineItem> lstQli = Database.query(SOQL_QLI + sWhereQLI);

			//  Sophal:01/03/2021:US-0009134 use database query instead, Product2.Billing_Category__c datatype can be changed to multi-select picklist
			// List<QuoteLineItem> lstQli = Database.query(QUOTELINEITEM_SOQL);  //Sophal:19/03/2021:US-0009251 disable to use normal query because Product2.billing_category__c has changed to multi-picklist
            
	        for(QuoteLineItem ql : lstQli){
	        	mpLineItem.put(ql.Product2Id, ql);
                mpPackage.put(ql.Product_Package__r.Package_Product__c, ql.Product_Package__r.Package_Product__r);
	        }

			// Sophal:26/02/2021:US-0009134 
			List<String> lstBillCat = new List<String>();
			//Sophal:01/03/2021:US-0009134 use Billing_Category2__c so Billing_Category__c can be used change to multi-select picklist, will swtich back to use Billing_Category__c later.
			// Schema.DescribeFieldResult fieldResult = Product2.Billing_Category2__c.getDescribe(); //Sophal:19/03/2021:US-0009251 decided to use Billing_Category__c.
			Schema.DescribeFieldResult fieldResult = Product2.Billing_Category__c.getDescribe(); //Sophal:19/03/2021:US-0009251 need to use orginal field Billing_Category__c
			List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
			for( Schema.PicklistEntry pickListVal : ple){
				lstBillCat.add(pickListVal.getValue());
			}     

			res.put('lstBillCat', lstBillCat);
	        res.put('mpLineItem', mpLineItem);
	        res.put('mpPackages', mpPackage);
	        res.put('qliList', lstQli);
	        res.put('baseURL', UTIL.getString(System.URL.getOrgDomainURL().gethost()));

			res.put('pkl_Family', ApexUtil.getPicklistValues(Product2.Family));
			res.put('pkl_Product_Type__c', ApexUtil.getPicklistValues(Product2.Product_Type__c));
			res.put('pkl_Device_Type__c', ApexUtil.getPicklistValues(Product2.Device_Type__c));		
			
			//MN-20052021-US-0009561
			res.put('pkl_Targeting_Type__c', ApexUtil.getPicklistValues(QuoteLineItem.Targeting_Type__c));
			res.put('pkl_Rebate_In_Kind_Reason__c', ApexUtil.getPicklistValues(QuoteLineItem.Rebate_In_Kind_Reason__c));

	        rrs.statusCode = RemoteResponse.STATUSCODE_OK;
	        rrs.content = res;
	        rrs.message = 'success';
	        
	    } catch (Exception e) { rrs.statusCode = RemoteResponse.STATUSCODE_ERROR;rrs.message = e.getMessage();rrs.debug = e.getMessage() + ':' + e.getStackTraceString();
	    }
	    
	    return rrs;
	    
    }
	
	//MN-230620201-US-0009763
	private static Boolean isUploadCSV = false;

    @AuraEnabled
    public static RemoteResponse saveQuoteLineItemsUsingMode(String quoteId, List<QuoteLineItem> quoteLineItems, String mode, String modeOverrideParamsJSON){
		isUploadCSV = true;
        return doSaveQuoteLineItemsUsingMode(quoteId,quoteLineItems,mode,modeOverrideParamsJSON,null);
    }

	@AuraEnabled
    public static RemoteResponse saveQuoteLineItemsWithDetails(String quoteId, List<QuoteLineItem> quoteLineItems){
	    return doSaveQuoteLineItemsUsingMode(quoteId, quoteLineItems, OVERRIDE_ON_EXISTING_LIST, null,null);
    }

	@AuraEnabled
    public static RemoteResponse saveQuoteLineItems(String quoteId, List<QuoteLineItem> quoteLineItems,Map<String,Object> additionalParam)
	{
		Set<String> setPreserveId = new Set<String>();// all qli id from previous save
		
		List<QuoteLineItem> listChildCmpToInsert = new List<QuoteLineItem>();
		if(additionalParam <> null && additionalParam.containsKey('childOnly'))
		{			

			for(QuoteLineItem qli : quoteLineItems)
			{
				setPreserveId.add(qli.Id);
			}

			if(additionalParam.containsKey(PARAM_LIST_EXIST_PKG_QLI_ID)){ // Sophal:09/02/2022:US-0010886 check param for creating clone records for child cmp qli
				List<String> listExistPkgQliId =  (List<String>)JSON.deserialize(String.valueOf(additionalParam.get(PARAM_LIST_EXIST_PKG_QLI_ID)), List<String>.class);
				if(!listExistPkgQliId.isEmpty()){
					cloneAdditionalChildComponents(listExistPkgQliId, quoteLineItems, listChildCmpToInsert);
				}
			}
		
			quoteLineItems = buildPackageComponents(quoteId, quoteLineItems, listChildCmpToInsert);
		} else if(additionalParam <> null && additionalParam.containsKey('setPreserveId')) {
			for (Object obj_id: (List<Object>)additionalParam.get('setPreserveId')) { setPreserveId.add(String.valueOf(obj_id)); }
		}

	    return doSaveQuoteLineItemsUsingMode(quoteId, quoteLineItems, OVERRIDE_ON_EXISTING_LIST,null, new Map<String,Object>{'setPreserveId'=>setPreserveId});
    }

	/***************************************************************************************************************************************
	@ Method:        saveQuoteLineItemsUsingMode
	@ Version:       1.0
	@ Author:        
	@ Purpose:       Migrated
	-----------------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 16.12.2020 / vadhanak voun (vadhanak.voun@gaea-sys.com) / US-0008726 - [Ads 2020] SOQL Error on Saving QuoteLineItems
	@							 / optimized soql 101	
	@				: 21.12.2020 /vadhanak voun (vadhanak.voun@gaea-sys.com) / US-0008850 - [Ads 20202 - Revise Existing 'Edit Line Items Component'	
	@							 / removed aditional Update after Insert
	@				: 05.03.2021 /Mony Nou (mony.nou@gaea-sys.com) / US-0009114 - [Ads 2020] Updates to Products, Available Sites and Contents
	@				: 16.06.2021/ vadhanak voun (vadhanak.voun@gaea-sys.com)/ US-0009711 - Ads UAT Bug - product configurator doesn't save predefined targeting when no other targeting is selected
	-----------------------------------------------------------------------------------------------------------------------------------------*/	 
	private static RemoteResponse doSaveQuoteLineItemsUsingMode(String quoteId, List<QuoteLineItem> quoteLineItems, String mode, String modeOverrideParamsJSON , Map<String,Object> additionalParam)
	{
		Map<String, String> modeOverrideParams = new Map<String, String>(); 
        if (!String.isEmpty(modeOverrideParamsJSON)) modeOverrideParams = (Map<String, String>)JSON.deserialize(modeOverrideParamsJSON, Map<String, String>.class);
        
        RemoteResponse rrs = new RemoteResponse();
        Map<String, Object> res = new Map<String, Object>();
        
		//List<QuoteLineItem> lstQl2Update = new List<QuoteLineItem>();
		Map<Id, QuoteLineItem> mapToUpdate = new Map<Id, QuoteLineItem>();
		
		Map<Id,QuoteLineItem> mapSourceQLI = new Map<Id,QuoteLineItem>(); //store source QLI data for new cloned qli to get Targeting // US-0009094 / Sophal/ 08.02.2021 migratd from hotfix

        List<QuoteLineItem> lstQl2Insert = new List<QuoteLineItem>();
        try {
            //throw new ExceptionGroup.CustomException(JSON.serialize(quoteLineItems));
			Set<String> qlIds = new Set<String>();
			Set<String> setProductId = new Set<String>();
			Map<Id,Product2> mapProduct = new Map<Id,Product2>();
			Map<Id, List<Available_Site__c>> mapProductAdsites = new Map<Id,List<Available_Site__c>>(); //MN-050320201-US-0009114
			//System.debug('>>>quoteId: '+quoteId);
            //System.debug('>>>quoteLineItems: '+JSON.serialize(quoteLineItems));			 		

            for(QuoteLineItem ql: quoteLineItems){
                if(String.isNotEmpty(ql.Id)){
                    qlIds.add(ql.Id);
					//lstQl2Update.add(ql);
					mapToUpdate.put(ql.Id,ql);
                }else{
					//predefined here no need another update
					ql.Predefined_Adunit__c = ql.Product2.PredifinedAdunit__c;
					lstQl2Insert.add(ql);	
					if(ql.ClonedFrom__c<>null)mapSourceQLI.put(ql.ClonedFrom__c,null); // US-0009094 / Sophal/ 08.02.2021 migratd from hotfix
                }
				
				if(ql.Product2Id != null) setProductId.add(ql.Product2Id); //MN-050320201-US-0009114
				//NK:23/06/2021: for cloned packaged
				if(ql.Product2Id==null && ql.PriceBookEntry <> null) setProductId.add(ql.PriceBookEntry.Product2Id);
            }

			//MN-050320201-US-0009114
			if (!setProductId.isEmpty()) {
				for (Product2 prod : [SELECT Id, Advertising_Medium__r.AdServer_Keywords_Key_Values__c, (SELECT Available_Site__c FROM Available_Sites__r) FROM Product2 WHERE Id IN:setProductId])
				{
					mapProductAdsites.put(prod.Id, prod.Available_Sites__r);
					mapProduct.put(prod.Id,prod);
				} 
			}
			
			if(!mapSourceQLI.isEmpty())
			{
				mapSourceQLI = new Map<Id,QuoteLineItem>([Select Id,Targeting__c From QuoteLineItem Where Id IN:mapSourceQLI.KeySet() ]); // US-0009094 / Sophal/ 08.02.2021 migratd from hotfix
			} 

			if(!mapToUpdate.isEmpty())
			{
				WithoutSharing.doUpdate(mapToUpdate.values());
			}
			//system.debug('>>>mapToUpdate: '+JSON.serialize(mapToUpdate.values())); 

            if(!lstQl2Insert.isEmpty())
			{				
				Map<Integer, Targeting__c> mQliId2InsertTg = new Map<Integer, Targeting__c>();
				Map<Id, QuoteLineItem> mQli2Update = new Map<Id, QuoteLineItem>();

				/*  copy targeting template for qli
					or copy targeting for copied qli */
				//instead of ID that not yet populated, use index for later assign the new Targeting (if any)
				Integer qIndex = 0;
				Map<String,String> mapQli2Targeting = new Map<String,String>();
				for(QuoteLineItem qli : lstQl2Insert){
					//system.debug('>>>qli.ClonedFrom__c: '+qli.ClonedFrom__c); 
					// clone Targetings p3
					String tgId = qli.Product2.Targetings__c; 
					//throw new ExceptionGroup.CustomException(tgId); Product2.Targetings__c,Product_Package__r.Package__r.Targeting__c
					// p2
					if(String.isNotBlank(qli.Product_Package__r.Package__r.Targeting__c))  tgId = qli.Product_Package__r.Package__r.Targeting__c;
					// p1
					if( GW_QuoteLineItem.isCopiedQli(qli)) tgId = mapSourceQLI.get(qli.ClonedFrom__c).Targeting__c; //mapToUpdate.get(qli.ClonedFrom__c).Targeting__c; // US-0009094 / Sophal/ 08.02.2021 migratd from hotfix
					//System.debug('>>tgId: '+tgId);
					if( tgId==null) {

						// Sophal-30062021-US-0009763 : fix null pointer, make sure product from mapProduct and product.Advertising_Medium__r are not null.
						Product2 prodWithAdsMedium = (mapProduct.containsKey(qli.Product2Id)) ? (mapProduct.get(qli.Product2Id)) : null;
						String adServerKeyWordKeyValue = (prodWithAdsMedium != null && prodWithAdsMedium.Advertising_Medium__r != null) ? prodWithAdsMedium.Advertising_Medium__r.AdServer_Keywords_Key_Values__c : null;
						
						mQliId2InsertTg.put(qIndex, new Targeting__c(Description__c = qli.Product2.Name + ' Targeting',KeyValueString__c=adServerKeyWordKeyValue));
						
					}else
					{
						//no id here because QLI not yet insert
						mapQli2Targeting.put(qIndex+'',tgId);
					}

					qIndex++;
				}
				//System.debug('>>mQliId2InsertTg: '+mQliId2InsertTg);				
				if(!mQliId2InsertTg.isEmpty())
				{
					//insert newly Targetting to get Id and assign to QLI. 
					WithoutSharing.doInsert(mQliId2InsertTg.values());	
					
					for(Integer k : mQliId2InsertTg.keySet())
					{
						QuoteLineItem qli = lstQl2Insert[k]; 
						qli.Targeting__c = mQliId2InsertTg.get(k).Id;	
									
					}
				}				
				//System.debug('>>mapQli2Targeting: '+mapQli2Targeting);
				if(!mapQli2Targeting.isEmpty())
				{
					//copy all instead of 1 by 1 in the loooooop 
					Map<Integer,String> mapResult = GW_Targeting.copyProdPackageTargetingToLine(mapQli2Targeting);			 
					//System.debug('>>mapResult: '+mapResult);
					for(Integer i : mapResult.keySet())
					{
						lstQl2Insert[i].Targeting__c = mapResult.get(i);
					}
				}	
				//system.debug('>>:lstQl2Insert: '+JSON.serialize(lstQl2Insert));
				//make sure only single Insert without addtional UPDATE
				System.debug('lstQl2Insert ::: '+lstQl2Insert);
				WithoutSharing.doInsert(lstQl2Insert); 		
				
				List<QuoteLineItem>  listAll = new List<QuoteLineItem>(lstQl2Insert);
				listAll.addAll( mapToUpdate.values());

				//***** START - MN-050320201-US-0009114 - Create TargetingContentAssociation
				Map<String, TargetingContentAssociation__c> mTCA2Insert = new Map<String, TargetingContentAssociation__c>();
				Set<String> sExstTCA = new Set<String>();

				//Get existed TargetingContentAssociation
				for (TargetingContentAssociation__c tca : [SELECT Targeting__c, TargetingContent__c FROM TargetingContentAssociation__c WHERE Targeting__c IN (SELECT Targeting__c FROM QuoteLineItem WHERE Id IN:listAll)]) {
					//Unique Key for Targeting#Content to avoid duplicate creation of TargetingContentAssociation	
					String key = tca.Targeting__c + '#' + tca.TargetingContent__c;
					sExstTCA.add(key);
				}

				Set<String> setPreserveId = additionalParam <> null && additionalParam.containsKey('setPreserveId') ? (Set<String>)additionalParam.get('setPreserveId') : new Set<String>();
				System.debug('#### additionalParam :: ' + additionalParam);
				System.debug('#### setPreserveId :: ' + setPreserveId);
				for(QuoteLineItem qli : listAll) {
					Id prodId = qli.Product2Id;
					Id tgId = qli.Targeting__c;
					if (tgId != null && mapProductAdsites.containsKey(prodId) && !mapProductAdsites.get(prodId).isEmpty()) {
						for (Available_Site__c avs : mapProductAdsites.get(prodId)) {
							Id contentId = avs.Available_Site__c;
							//Unique Key for Targeting#Content to avoid duplicate creation of TargetingContentAssociation	
							String key = tgId + '#' + contentId;
							if (!sExstTCA.contains(key) && !mTCA2Insert.containsKey(key)) {
								TargetingContentAssociation__c tca = new TargetingContentAssociation__c(
									Targeting__c = tgId,
									TargetingContent__c = contentId,
									Target_Content_Key__c = tgId + '' + contentId
								);
								mTCA2Insert.put(key, tca);
							}
						}
						
					}
					setPreserveId.add(qli.Id);
					if(!String.isEmpty(qli.package_line_item__c))
					{
						setPreserveId.add(qli.package_line_item__c);
					}
				}

				if (!mTCA2Insert.isEmpty()) WithoutSharing.doInsert(mTCA2Insert.values()); 
				//***** END - MN-050320201-US-0009114 - Create TargetingContentAssociation
				

				//res.put('quoteLineItemDeleted', manageActionDelete(mode, modeOverrideParams, quoteId, listAll)); 
				/* MN-23062021-US-0009763 
					- Since we change behavior to default unchecked all QLIs on Product Configuration Page, so we need to skip this logic in order to avoid deleted 
					all unselected QLIs.
					- We already investigated and below line of codes to delete QLIs, purposely for CSV Upload only.
				*/
				if (isUploadCSV) res.put('quoteLineItemDeleted', manageActionDelete(mode, modeOverrideParams, quoteId, setPreserveId));
			}
            		
			//system.debug('--Update: '+mapToUpdate.size()+'  >>>insert: '+lstQl2Insert.size());
			//system.debug('--:quoteLineItems: '+JSON.serialize(quoteLineItems));			
			
            //res.put('lstQl2Update', mapToUpdate.values());
            //res.put('lstQl2Insert', lstQl2Insert);
			res.put('quoteLineItems', quoteLineItems);
            res.put('msg', 'success');
            
            rrs.statusCode = RemoteResponse.STATUSCODE_OK;
            rrs.content = res;
            rrs.message = 'success';
		 
			//NK03/12/2020:US-0008676 - [Ads 2020] Validation Exception on Start and End Dates in the Past on Quote
			//Added DMLException for better user error msg
		}catch (DMLException dex) { rrs.statusCode = RemoteResponse.STATUSCODE_ERROR;rrs.message = dex.getDmlMessage(0);rrs.debug = dex.getMessage() + ':' + dex.getStackTraceString();System.debug(dex);
		} 
		catch (Exception e) { rrs.statusCode = RemoteResponse.STATUSCODE_ERROR;rrs.message = e.getMessage();rrs.debug = e.getMessage() + ':' + e.getStackTraceString();System.debug(e.getStackTraceString());
        }
        return rrs;
	}

	/***************************************************************************************************************************************
	@ Method:        cloneAdditionalChildComponents
	@ Version:       1.0
	@ Author:        Sophal Noch
	@ Purpose:       US-0010886 - 1PD Campaign Tracking	
	@				 Use Case for this method:
	@				 - 1 Package Product is defined to have 2 Child Products.
	@				 - When this package is added to Quote.
	@				 - 1 Main Qli and 2 Child Qlis are created
	@				 - User can go to Child Component Modal-Dialog and clone any child Qli and Save to increase the number of child Qli.
	@				 - Now There are 1 Main Qli and 3 Child Qlis.
	@				 - When user goes back to EditLineItem Page, when user clicks clone on Main Qli (Parent Qli) and Click Save.
	@				 - The new Cloned Main Qli should have 3 Childs, not 2 childs. 
	@				 - The logic choose 3 Exist Child Qlis instead of 2 Products defined in Package Product.
	@				 - This "cloneAdditionalChildComponents" method handle cloning the 3 Exist Child Qlis.
	@				 - List of child cmp Qlis returned from "cloneAdditionalChildComponents" method will be used in "buildPackageComponents" method for Param "listChildCmp"
	@				 - If Param "listChildCmp" has records in it, It uses the Records to Create Child Cmp Qlis.
	@				 - Otherwise, It creates Child Cmp Qlis from Child Products that are defined in Package Product.
	-----------------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 09.02.2022 / Sophal Noch / Create method					
	-----------------------------------------------------------------------------------------------------------------------------------------*/	 
	private static void cloneAdditionalChildComponents(List<String> listExistPkgQliId, List<QuoteLineItem> listParent,List<QuoteLineItem> listChildCmp){

		Map<String, List<QuoteLineItem>> mapQliIdToListChildCmp = new Map<String, List<QuoteLineItem>>();

		for(QuoteLineItem childQli : getChildComponentsByListId(listExistPkgQliId)){
			if(String.isBlank(childQli.package_line_item__c)) continue;
			List<QuoteLineItem> listQli = mapQliIdToListChildCmp.get(childQli.package_line_item__c); // map child qli to parent qli  by package_line_item__c 
			if(listQli == null){
				listQli = new List<QuoteLineItem>();
				mapQliIdToListChildCmp.put(childQli.package_line_item__c,listQli);
			}
			listQli.add(childQli);
		}

		if(mapQliIdToListChildCmp.isEmpty()) return;

		for(QuoteLineItem qli : listParent)
		{
			List<QuoteLineItem> listQli = mapQliIdToListChildCmp.get(qli.ClonedFrom__c); // to get qli to clone child cmp, cloned pkg qli use ClonedFrom__c field to get Original pkg qli
			if(listQli != null && qli.Id != null){
				for(QuoteLineItem childQli : listQli){
					QuoteLineItem clonedQli = childQli.clone(false,false,false,false);
					clonedQli.package_line_item__c = qli.Id;
					clonedQli.AdProduct__c = null;
					clonedQli.Targeting__c = null;
					clonedQli.ClonedFrom__c = null;
					clonedQli.Legacy_SFDC_ID__c = null;
					listChildCmp.add(clonedQli);
				}

			}
		}
	}	
    
	/***************************************************************************************************************************************
	@ Method:        buildPackageComponents
	@ Version:       1.0
	@ Author:        vadhanak vount
	@ Purpose:       US-0009355 - [Ads 2020] Product Packages
	-----------------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 29.04.2021 / vadhanak voun (vadhanak.voun@gaea-sys.com) / US-0009355 - [Ads 2020] Product Packages.
	@							/ handle package components. Main package show in UI, related components get created when saving.
	@ 				: 26.01.2022 / Sophal Noch / US-0010886 - 1PD Campaign Tracking
	@				: 06.07.2023 / Bora Chhorn / US-0013228 - ADS - Package Components Sales Price Sync						
	-----------------------------------------------------------------------------------------------------------------------------------------*/	 
	private static List<QuoteLineItem> buildPackageComponents(String quoteId,List<QuoteLineItem> quoteLineItems, List<QuoteLineItem> listChildCmp)
	{
		List<QuoteLineItem> listQLI_new = new List<QuoteLineItem>();
		Set<String> idProMain = new Set<String>();        
        Set<String> idOpliMain = new Set<String>();

		// Sophal:26/01/2022:US-0010886 map product id to number of Qli
        Map<String, Integer> mapItemIdToQliCount = new Map<String, Integer>(); 
        
        // Map<String, String> mapOpliChildExist = new Map<String, String>();
		Map<String, List<String>> mapOpliListChildExist = new Map<String, List<String>>(); 
        // Map<String, QuoteLineItem> mapOli = new Map<String, QuoteLineItem>();
        
        //get Package Product Id
        for(QuoteLineItem qli: quoteLineItems)
		{            
            //check record is Package or not 
            if(qli.Product2.RecordType.Name == PRODUCT_RT_PACKAGE )
			{                
                //get all Package product id            
                if(qli.id != null){
                    idOpliMain.add(qli.id);
                }
                idProMain.add(qli.Product2Id);
            }
        }
		 
		if(idProMain.isEmpty())
		{
			return quoteLineItems;
		}

		
        // Map<String, String> mapPackageComponentId2ItemId = new Map<String, String>(); // Task #10157 : The package product has the same procduct as multi Packagecomponents
        
		// Sophal:26/01/2022:US-0010886 mapPackageComponentId2ListItem is a map of product package key to list quotelineitem
		Map<String, List<QuoteLineItem>> mapPackageComponentId2ListItem = new Map<String, List<QuoteLineItem>>();
		
		//get all qli child
        // Set<String> idOpliChildExist = new Set<String>();

		// if(idOpliMain.size() > 0)
		// {
        //     for(QuoteLineItem qli: [select id, Product_Package__c, package_line_item__c, PricebookEntryId, PricebookEntry.Product2Id, PricebookEntry.Product2.Name,  AdKeywords__c  from QuoteLineItem where package_line_item__c in:idOpliMain])
		// 	{
        //         if(String.isNotBlank(qli.Product_Package__c))
		// 		{
        //             mapPackageComponentId2ItemId.put(qli.Product_Package__c +''+ qli.package_line_item__c, qli.id); //packageId + qliMainId
        //             continue;
        //         }
        //         if(!mapOpliChildExist.containsKey(qli.package_line_item__c + qli.PricebookEntry.Product2Id))
		// 		{
        //             mapOpliChildExist.put(qli.package_line_item__c + qli.PricebookEntry.Product2Id, qli.Id);
        //         }
        //     }
        // }
		
        if(!idOpliMain.isEmpty()){ // Sophal:26/01/2022:US-0010886 mapping for exist child component qli that has not been modified in EditLineItem Page
			List<QuoteLineItem> listExistQuoteLineItem = [select id, Product2Id, Product_Package__c, package_line_item__c, PricebookEntryId, PricebookEntry.Product2Id, PricebookEntry.Product2.Name,  AdKeywords__c  from QuoteLineItem where package_line_item__c in:idOpliMain and Id NOT IN: listChildCmp];
			mapParentToChildCmp(listExistQuoteLineItem, mapItemIdToQliCount, mapPackageComponentId2ListItem, mapOpliListChildExist);
        }

		if(!listChildCmp.isEmpty()){  // Sophal:26/01/2022:US-0010886 mapping for exist child component qli or new qli that has been modified in EditLineItem Page
			mapParentToChildCmp(listChildCmp ,mapItemIdToQliCount, mapPackageComponentId2ListItem, mapOpliListChildExist);
		}
        
        //get Package Component
        List<Product2> proMain = new List<Product2>([select Id,(Select Id,Product__c,Package_Product__c From Packaged_Products__r  order by CreatedDate) from Product2 where Id in:idProMain]);
		 
        Set<String> idProChild = new Set<String>();
        //get Package Component Id
        Map<String, List<String>> mapProMainChild = new Map<String, List<String>>();
        Map<String, List<String>> mapPackageProductId2PkgComs = new Map<String, List<String>>(); // Task #10157 : The package product has the same procduct as multi Packagecomponents
        for(Product2 p: proMain)
		{
            for(Product_Package__c pc: p.Packaged_Products__r){
                idProChild.add(pc.Product__c);
                
                if(mapProMainChild.get(p.Id) == null){
                    mapProMainChild.put(p.Id, new List<String>());
                }
                mapProMainChild.get(p.Id).add(pc.Product__c);
                
                if(mapPackageProductId2PkgComs.get(p.id) == null) {
                    mapPackageProductId2PkgComs.put(p.id, new List<String>());
                }
                mapPackageProductId2PkgComs.get(p.id).add(pc.id);
            }
        }
         
        Map<String, PricebookEntry> mapPbeChild = new Map<String, PricebookEntry>();
		String quoteCurrency = [Select CurrencyIsoCode From Quote Where Id =: quoteId Limit 1]?.CurrencyIsoCode; // Sophal:03/02/2022:US-0010886
        //get pricebook entry that match with package component
        for (PricebookEntry pbe:[Select Id, Product2.Billing_Category__c,Unitprice, Product2.Name, Product2.Id, Product2.Fixed_price__c,Product2Id,
                                                                Product2.Advertising_Medium__r.FC_Quantity__c,
                                                                Product2.Advertising_Medium__r.FC_Period__c,
                                                                Product2.Advertising_Medium__r.FC_Ad_served_every__c,
                                                                Product2.RecordType.Name, Product2.Fixed_Site__c, Product2.available_Key_Values__c
                                                                from PricebookEntry where CurrencyIsoCode =: quoteCurrency and Pricebook2Id IN (SELECT Pricebook2Id FROM Quote WHERE Id =:quoteId) and Product2Id in :idProChild])
		{
                            
            mapPbeChild.put(pbe.Product2Id, pbe);
        }
		//system.debug('--mapPbeChild: '+mapPbeChild);
        //get right Package product and package component
        Map<String, Product_Package__c> mapPackageCom = new Map<String, Product_Package__c>();
        Map<String, Product_Package__c> mapId2PkgCom = new Map<String, Product_Package__c>([Select Id,Product__c, Package_Product__c From Product_Package__c p where Product__c in:idProChild and Package_Product__c in:idProMain]);
        for(Product_Package__c pc : mapId2PkgCom.values())
		{
            //get Dart_Name to store in Rich_Line_Description__c of Product Component related
            String keyMap = pc.Product__c + ' ' + pc.Package_product__c;
            if(!mapPackageCom.containsKey(keyMap)){
                mapPackageCom.put(keyMap, pc);
            }
        }
		
        // Set<String> setSubUnit = new Set<String>{'Fix Price','FIxed','CPO'}; // BR-US-0013228
        for(QuoteLineItem opliMain : quoteLineItems)
		{             
			//listQLI_new.add(opliMain); //save child only
			
            if(opliMain.Product2.RecordType.Name != PRODUCT_RT_PACKAGE) continue; 
             
            if(!mapProMainChild.containsKey(opliMain.Product2Id)) continue;
            
            List<String> lstOpliChild = mapProMainChild.get(opliMain.Product2Id);
            
			// Sophal:26/01/2022:US-0010886 get number of package component by checking product inside package and number of qli
            // Decimal numOfPackCom = mapProMainChild.get(opliMain.Product2Id).size();
			Decimal numOfPackCom = 0;
			for(String prodId : mapProMainChild.get(opliMain.Product2Id)){
				Integer qliCount = mapItemIdToQliCount.get(opliMain.Id + prodId);
				qliCount = qliCount == null ? 1 : qliCount;
				numOfPackCom += qliCount;
			}

            //Decimal subUnitPrice = (opliMain.UnitPrice == null? 0: opliMain.UnitPrice); // BR-US-0013228
			Decimal subUnitPrice = (opliMain.SalesPriceNet__c == null? 0: opliMain.SalesPriceNet__c); // BR-US-0013228
            Double subQuantity = (opliMain.Quantity == null? 0: opliMain.Quantity);
			Decimal subBudget = (opliMain.Budget__c == null? 0: opliMain.Budget__c);
			// BR-US-0013228
            // if (setSubUnit.contains(opliMain.Billing_category__c)) 
			// {
            //     subUnitPrice = subUnitPrice / numOfPackCom;
            // }else 
			// {
            //     subQuantity = Math.floor(subQuantity / numOfPackCom);
            // }
			subQuantity = Math.floor(subQuantity / numOfPackCom);
			// END - BR-US-0013228
			
			subBudget = subBudget / numOfPackCom;

            for(Integer index = 0; index < lstOpliChild.size(); index++)
			{  //childProId = id single product
                String childProId = lstOpliChild.get(index);
                if (!mapPbeChild.containsKey(childProId))continue;
                
                // Task #10157 : The package product has the same procduct as multi Packagecomponents
                Id pkcNewId = mapPackageProductId2PkgComs.get(opliMain.Product2Id).get(index);	//mainProduct to list of package id 
                Product_Package__c pkcNew = mapId2PkgCom.get(pkcNewId);

                // Id existingOliId = pkcNew == null ? null : mapPackageComponentId2ItemId.get(pkcNew.id + '' + opliMain.id); 
				List<QuoteLineItem> existingListOli = pkcNew == null ? new List<QuoteLineItem>{new QuoteLineItem()} : mapPackageComponentId2ListItem.get(pkcNew.id + '' + opliMain.id);
				existingListOli = existingListOli == null ? new List<QuoteLineItem>{new QuoteLineItem()} : existingListOli;

				for(QuoteLineItem qliChild : existingListOli){

					if(String.isNotBlank(qliChild.Id)){
						// qliChild = createClone( opliMain, existingOliId);
						qliChild = createClone( opliMain, qliChild);
					} 
					
					// else if(opliMain.Id != null && mapOpliChildExist.containsKey(opliMain.Id + childProId))
					// {
					// 	qliChild = createClone(opliMain, mapOpliChildExist.remove(opliMain.Id + childProId));
					// }
					else if(opliMain.Id != null && mapOpliListChildExist.containsKey(opliMain.Id + childProId))
					{
						List<String> listChildId = mapOpliListChildExist.get(opliMain.Id + childProId);
						String childId = listChildId.remove(0);
						if(listChildId.isEmpty()) mapOpliListChildExist.remove(opliMain.Id + childProId);
						// qliChild = createClone(opliMain, childId);
						qliChild = createClone(opliMain, new QuoteLineItem(Id=childId));
					}else{
						// qliChild = createClone(opliMain, '');
						qliChild = createClone(opliMain, qliChild);
						qliChild.PricebookEntryId = mapPbeChild.get(childProId).Id;
					}
					//NK:23/06/2021
					qliChild.PricebookEntry = mapPbeChild.get(childProId);//enable Usage of Product Properties while cloning Lines
					Product_Package__c pkc = pkcNew != null ? pkcNew : mapPackageCom.get(childProId + ' ' + opliMain.Product2Id);
					 
					//opli.Rich_Line_Description__c = pkc == null? null : pkc.DART_Content__r.DartName__c;                
					 
					if (opliMain.Product2.available_Key_Values__c != null) 
					{                    
						qliChild.AdKeyWords__c = opliMain.AdKeyWords__c;
						
					}else
					{                                      
						String main_kw = String.isBlank(opliMain.AdKeyWords__c) ? '' : '(' + opliMain.AdKeyWords__c + ')';
						String pkc_kw = '';//(pkc == null || String.isBlank(pkc.predefined_Key_Values__c)) ? '': '(' + pkc.predefined_Key_Values__c + ')';
						
						qliChild.AdKeyWords__c = (String.isNotBlank(main_kw) && String.isNotBlank(pkc_kw)) ? (main_kw + ' AND ' + pkc_kw) : (main_kw + pkc_kw);                
					}
					
					//opli.related_package__c = opliMain.PricebookEntry.Product2Id;
					qliChild.UnitPrice =  subUnitPrice ; 
					qliChild.SalesPriceNet__c = subUnitPrice;
					qliChild.Quantity = subQuantity;
					qliChild.Quantity__c = subQuantity;
					qliChild.Budget__C = subBudget;
					qliChild.FC_Quantity__c = opliMain.FC_Quantity__c;
					qliChild.FC_Period__c = opliMain.FC_Period__c;
					qliChild.FC_Ad_served_every__c = opliMain.FC_Ad_served_every__c;      
					
					qliChild.package_line_item__c = opliMain.Id;
					qliChild.Product_Package__c = pkc == null ? qliChild.Product_Package__c : pkc.id;
					
					listQLI_new.add(qliChild);
				}


            }
            
        }
		//system.debug('---listQLI_new: '+JSON.serialize(listQLI_new));
		return listQLI_new;
	}

	private static void mapParentToChildCmp(List<QuoteLineItem> listQli, Map<String, Integer> mapItemIdToQliCount,Map<String, List<QuoteLineItem>> mapPackageComponentId2ListItem, Map<String, List<String>> mapOpliListChildExist){
		// Sophal:26/01/2022:US-0010886
		for(QuoteLineItem qli : listQli){

			String keyChild = qli.package_line_item__c + qli.PricebookEntry.Product2Id;

			Integer count = mapItemIdToQliCount.get(keyChild);
			if(count == null){count = 0;}
			count ++;
			mapItemIdToQliCount.put(keyChild, count);

			if(String.isNotBlank(qli.Product_Package__c)){
				String itemIdKey = qli.Product_Package__c +''+ qli.package_line_item__c;
				List<QuoteLineItem> listItem = mapPackageComponentId2ListItem.get(itemIdKey);
				if(listItem == null) listItem = new List<QuoteLineItem>{};
				listItem.add(qli);
				mapPackageComponentId2ListItem.put(itemIdKey, listItem);
				continue;
			}

			List<String> listChildId =  mapOpliListChildExist.get(keyChild);
			if(listChildId == null) listChildId = new List<String>{};
			if(qli.Id != null){
				listChildId.add(qli.Id);
				mapOpliListChildExist.put(keyChild, listChildId);
			}
			

		}
	}

	private static Map<String, Schema.SObjectField> mapQItemFields = Schema.SObjectType.QuoteLineItem.fields.getMap();

	private static QuoteLineItem createClone(QuoteLineItem srcObj, QuoteLineItem cItm)
	{
		// QuoteLineItem cItm = String.isEmpty(componentExistingId)? new QuoteLineItem(): new QuoteLineItem(Id=componentExistingId);		 
		cItm = cItm != null ? cItm : new QuoteLineItem(); 

		for(String fn : MAIN_FIELDS)
		{					
			if(srcObj.get(fn)== null) continue; 
			
			if(mapQItemFields.get(fn).getDescribe().getType() == Schema.DisplayType.DATETIME){
				cItm.put(fn,Datetime.valueOfGmt(srcObj.get(fn)+ ''));
				
			}else
			{				
				//after create then is not editable 
				// if(!String.isEmpty(componentExistingId) && (fn == 'QuoteId' || fn=='PricebookEntryId')) continue;
				if(!String.isEmpty(cItm.Id) && (fn == 'QuoteId' || fn=='PricebookEntryId')) continue;

				cItm.put(fn,(srcObj.get(fn)));
			}
			
		}
		return cItm;	
	}

	 
    private static Object manageActionDelete(String mode, Map<String, String> modeOverrideParams, Id quoteId, Set<String> setPreserveId) {
        List<QuoteLineItem> deletedQuoteLineItems = new List<QuoteLineItem>();
        if (EXTEND_EXISTING_LIST.equalsIgnoreCase(mode)) return deletedQuoteLineItems;
        
        if (modeOverrideParams.isEmpty()) {
	 
			//system.debug('--:setIdNotDelete: '+JSON.serialize(setIdNotDelete));
            //deletedQuoteLineItems = [SELECT Id, Targeting__c, Product2Id, Quote.Opportunity.Type, Quote.IO__c,Quote.Status FROM QuoteLineItem WHERE Id NOT IN :quoteLineItems AND QuoteId =: quoteId];
			deletedQuoteLineItems = [SELECT Id, Targeting__c, Product2Id, Quote.Opportunity.Type, Quote.IO__c,Quote.Status FROM QuoteLineItem WHERE Id NOT IN :setPreserveId AND QuoteId =: quoteId];
        } else {
            Set<Id> delIds = new Set<Id>();
            for (String delId : modeOverrideParams.keySet()) {
                if (String.isEmpty(delId)) continue;
                if (OVERRIDE_ACTION_DELETE.equalsIgnoreCase(modeOverrideParams.get(delId))) {
                    delIds.add(delId);
                }
            }
            deletedQuoteLineItems = [SELECT Id, Targeting__c, Product2Id, Quote.Opportunity.Type, Quote.IO__c,Quote.Status FROM QuoteLineItem WHERE Id IN :delIds];
        }
        return deleteQuoteLineItems(deletedQuoteLineItems);
    }
    
    public static Object deleteQuoteLineItems(List<QuoteLineItem> toDeleteItems) {
    	if(toDeleteItems.size() > 0) {
    		IO_LineItem_Junction__c[] toDeleteConj = [select id, IO_LineItem__c, IO_LineItem__r.Ad_Id__c, 
    															Quote_LineItem__r.Targeting__c, Quote_LineItem__r.Quote.Opportunity.Type, Quote_LineItem__r.Quote.Media_Plan__r.IsRevision__c,
    															Quote_LineItem__r.Quote.Status
    													from IO_LineItem_Junction__c where Quote_LineItem__c in :toDeleteItems];
    		Targeting__c[] toDeleteTarg = new List<Targeting__c>();
    		IO_LineItem__c[] toDeleteIOLines = new List<IO_LineItem__c>();
    		
        	for(IO_LineItem_Junction__c c : toDeleteConj) {
        		//if(c.Quote_LineItem__r.Quote.Opportunity.Type != Label.OPP_TYPE_DIRECT_REVISION) { ////MN-01072019 - We no longer use Direct Revision RecordType or any picklist value anymore
        		if(!c.Quote_LineItem__r.Quote.Media_Plan__r.IsRevision__c) {
        			toDeleteIOLines.add(new IO_LineItem__c(Id = c.IO_LineItem__c));
        			if(c.IO_LineItem__r.Ad_Id__c != null) {
        				throw new ExceptionGroup.CustomException(Label.ERR_QLI_DEL_FAILED_AS_IOLI_BOOKED);
        			}
        		}
        		if(c.Quote_LineItem__r.Targeting__c != null) {
        			toDeleteTarg.add( new Targeting__c(id = c.Quote_LineItem__r.Targeting__c) );
        		}
        	}
        	
        	
	    	WithoutSharing.doDelete(toDeleteConj);
	    	WithoutSharing.doDelete(toDeleteTarg);
	    	WithoutSharing.doDelete(toDeleteItems);
	    	WithoutSharing.doDelete(toDeleteIOLines);

    	}
    	return toDeleteItems;
    }

    @AuraEnabled
    public static RemoteResponse deleteQuoteLineItems(List<String> quoteLineItemIds){
    	RemoteResponse rrs = new RemoteResponse();
    	Map<String, Object> res = new Map<String, Object>();

    	try {

    		List<QuoteLineItem> lstQLI = new List<QuoteLineItem>();

    		for (String qliId : quoteLineItemIds)
			{
				lstQLI.add(new QuoteLineItem(Id=qliId)); 
			} 			

    		if (!lstQLI.isEmpty()) 
			{
				//also delete related child component if deleting item is a package
				lstQLI.addAll([SELECT Id, Targeting__c, Product2Id, Quote.Opportunity.Type, Quote.IO__c,Quote.Status FROM QuoteLineItem WHERE package_line_item__c IN :quoteLineItemIds]);
				LC_ProductSearchController.deleteQuoteLineItems(lstQLI);
			}
    		res.put('msg', 'success');
	        
	        rrs.statusCode = RemoteResponse.STATUSCODE_OK;
	        rrs.content = res;
	        rrs.message = 'success';

    	} catch (Exception e) { rrs.statusCode = RemoteResponse.STATUSCODE_ERROR;rrs.message = e.getMessage();rrs.debug = e.getMessage() + ':' + e.getStackTraceString();
	    }
	    return rrs;
    }
    
    
    @AuraEnabled
    public static RemoteResponse checkAvailability(String quoteLineId){
    	RemoteResponse rrs = new RemoteResponse();
	    try {
	    	
	        rrs = DFPController.getAvailability((Id)quoteLineId);
	        
	    } catch (Exception e) { rrs.statusCode = RemoteResponse.STATUSCODE_ERROR;rrs.message = e.getMessage();rrs.debug = e.getMessage() + ':' + e.getStackTraceString();
	    }
	    return rrs;
    }
    
   	@AuraEnabled
    public static RemoteResponse searchPackage(String packageName, List<String> ids, Id quoteId){
    	RemoteResponse rrs = new RemoteResponse();
    	try {
	    	String filter = '%' + packageName+''.trim() + '%';
	        rrs.statusCode = RemoteResponse.STATUSCODE_OK;
	        
	        //List<Package__c> lstPackage = new List<Package__c>(); 
			List<SObject> lstPackage = new List<SObject>(); 
	        List<String> prodIds = new List<String>();	
			

	        // for(PricebookEntry pbe : [SELECT Product2Id FROM PricebookEntry WHERE Pricebook2Id IN (SELECT Pricebook2Id FROM Quote WHERE Id =:quoteId) AND isActive=:true AND Product2.RecordType.Name=:proRecType]){
	        // 	prodIds.add(pbe.Product2Id);
	        // }

	        // if(!ids.isEmpty()){
	       	// 	// lstPackage = [SELECT 
	        // 	// 				Name, 
	        // 	// 				Id, (SELECT Id, Name, Package__c, Product__c FROM Product_Packages__r WHERE Product__c IN:prodIds)
	        // 	// 				FROM Package__c
	        // 	// 				WHERE Id IN :ids];

			// 	lstPackage = [SELECT 
			// 			Name, 
			// 			Id, (Select Id,Package_Product__c,Package_Product__r.Name From Product_Packages__r)
			// 			FROM Product2 
			// 			WHERE  Id IN:prodIds AND ID IN :ids ];  

	       	// }else{
	       	// 	// lstPackage = [SELECT 
	        // 	// 				Name, 
	        // 	// 				Id, (SELECT Id, Name, Package__c, Product__c FROM Product_Packages__r WHERE Product__c IN:prodIds)
	        // 	// 				FROM Package__c
	        // 	// 				WHERE Name LIKE :filter LIMIT 5];						 					 
			// 			// String swhere = ' WHERE Pricebook2Id IN (SELECT Pricebook2Id FROM Quote WHERE Id =:quoteId)  AND isActive=true AND Product2.isActive=true AND Product2.package_component_only__c=false AND Product2.RecordType.Name=:proRecType Order by Product2.Name limit 5';
				
			// 	//System.debug('--->prodIds: '+prodIds+'  filter: '+filter+'  ids: '+ids);
			// 	lstPackage = [SELECT 
			// 			Name, 
			// 			Id, (Select Id,Package_Product__c,Package_Product__r.Name From Product_Packages__r)
			// 			FROM Product2 
			// 			WHERE  Id IN:prodIds AND Name LIKE :filter LIMIT 5];  

	       	// }	

			Quote q = [Select CurrencyIsoCode,Pricebook2Id From Quote Where Id=:quoteId];
			String currCode = q.CurrencyIsoCode;
			String priceBook = q.Pricebook2Id;
	       	String sWhere = !ids.isEmpty()?' Where Product2.Id IN:ids': ' WHERE Pricebook2Id = :priceBook AND isActive=true AND CurrencyIsoCode =:currCode AND Product2.RecordType.Name=:PRODUCT_RT_PACKAGE And Product2.Name LIKE :filter LIMIT 5';		   
			List<PricebookEntry> listPBEMain = Database.query(SOQL_PBE + sWhere);
			    
			for(PricebookEntry pbe: listPBEMain)
			{
				prodIds.add(pbe.Product2Id);
			}	
			lstPackage = [SELECT 
						Name, 
						Id, (Select Id,Product__c,Package_Product__c,Product__r.Name From Packaged_Products__r)
						FROM Product2 
						WHERE  Id IN:prodIds];  

	        rrs.content = new Map<String, Object>{'ListPackage' => lstPackage, 'MapPackage' => new Map<String, SObject>(lstPackage),'listPBEMain'=>listPBEMain}; //,'MapPackagePBE' => new Map<String, SObject>(listPBEMain)
	        rrs.message = 'success';
	        
	    } catch (Exception e) { rrs.statusCode = RemoteResponse.STATUSCODE_ERROR;rrs.message = e.getMessage();rrs.debug = e.getMessage() + ':' + e.getStackTraceString();
	    }
	    return rrs;
    }
    @AuraEnabled
    public static RemoteResponse copyTargetings(String copyFromId, List<String> copyToIds){
    	RemoteResponse rrs = new RemoteResponse();
	    try {
	        rrs.statusCode = RemoteResponse.STATUSCODE_OK;
            rrs.content = '';
	        GW_Targeting.copyTargetings(copyFromId, copyToIds);
	    } catch (Exception e) { rrs.statusCode = RemoteResponse.STATUSCODE_ERROR;rrs.message = e.getMessage();rrs.debug = e.getMessage() + ':' + e.getStackTraceString();
	    }
	    return rrs;
	}

	
	/***************************************************************************************************************************************
	@ Method:        isLock
	@ Version:       1.0
	@ Author:        Sophal Noch (sophal.noch@gaea-sys.com)
	@ Purpose:       US-0009024 - BUG - products doesn't load on revision quote
	-----------------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 25.01.2021 / Sophal Noch / Created the method.
	-----------------------------------------------------------------------------------------------------------------------------------------*/	 
	public static Boolean isLock(Quote q){
		return q.Is_Revised_Quote__c && (q.Dually_Signed__c || q.Buyer_Accepted__c) && q.Status == Label.QUOTE_STATUS_APPROVED;
	}

	/***************************************************************************************************************************************
	@ Method:        getChildComponents
	@ Version:       1.0
	@ Author:        Sophal Noch (sophal.noch@gaea-sys.com)
	@ Purpose:       US-0010886 - 1PD Campaign Tracking
	-----------------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 26.01.2022 / Sophal Noch / Created the method.
	-----------------------------------------------------------------------------------------------------------------------------------------*/	 
	@AuraEnabled
    public static RemoteResponse getChildComponents(List<String>  listMainQliId){
		// Get child component list from parent qli
    	RemoteResponse rrs = new RemoteResponse();
		Map<String, Object> res = new Map<String, Object>();
	    try {
			rrs.statusCode = RemoteResponse.STATUSCODE_OK;
			List<QuoteLineItem> listQli = getChildComponentsByListId(listMainQliId);
            res.put('listQli', listQli);
			rrs.content = res;
	       
	    } catch (Exception e) { rrs.statusCode = RemoteResponse.STATUSCODE_ERROR;rrs.message = e.getMessage();rrs.debug = e.getMessage() + ':' + e.getStackTraceString();}
	    return rrs;
	}

	private static List<QuoteLineItem> getChildComponentsByListId(List<String>  listQliId){
		return Database.query(SOQL_QLI + 'Where package_line_item__c IN: listQliId');
	}
	
	/***************************************************************************************************************************************
	@ Method:        saveChildComponents
	@ Version:       1.0
	@ Author:        Sophal Noch (sophal.noch@gaea-sys.com)
	@ Purpose:       US-0010886 - 1PD Campaign Tracking
	-----------------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 26.01.2022 / Sophal Noch / Created the method.
	-----------------------------------------------------------------------------------------------------------------------------------------*/	 
	@AuraEnabled
    public static RemoteResponse saveChildComponents(String quoteId, QuoteLineItem mainQli, List<QuoteLineItem> childComponents, Boolean resetChanges){
		// Save child component list of parent qli
		RemoteResponse rrs = new RemoteResponse();
		Map<String, Object> res = new Map<String, Object>();
	    try {
			if(resetChanges) childComponents.clear();
			childComponents = buildPackageComponents(quoteId, new List<QuoteLineItem>{mainQli}, childComponents);
			rrs = doSaveQuoteLineItemsUsingMode(quoteId, childComponents, OVERRIDE_ON_EXISTING_LIST,null, new Map<String,Object>{'setPreserveId'=>new Set<String>{mainQli.Id}});
	       
	    } catch (Exception e) { rrs.statusCode = RemoteResponse.STATUSCODE_ERROR;rrs.message = e.getMessage();rrs.debug = e.getMessage() + ':' + e.getStackTraceString();}
	    return rrs;

	}

}