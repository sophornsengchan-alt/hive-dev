/*********************************************************************************************************************************
@ Class:         Deal_DailyViewController
@ Version:       1.0
@ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       Controller for aura: Deal_DailyView
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.11.2019 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / Created the class.
@				: 03.12.2019/ Vadhanak Voun  (vadhanak.voun@gaea-sys.com) / shared with Weekly view aura
@				: 13.02.2020/Vadhanka Voun / US-0007014 Deals - Masterschedule - Do not show Deals that are in Status "REJECTED"
@				: 02/02/2023/ Sovantheany dim / US-0013020 - Remove negotiating picklist from the Deal V1 record type
@				: 31.03.2023 / Sophal Noch / US-0013495 - Seller Cancelled Deals are appearing in the Deal Calendar
*********************************************************************************************************************************/
public without sharing class Deal_DailyViewController{
	
	final static Integer DEFAULT_LIST_SIZE = 200;
	public static final String SF_DATE_FORMAT = 'YYYY-MM-DD';
	static final String statusPlanned = EBH_ConstantsUtility.DEAL_STATUS_PLANNED;
	
	// >= Planned
	//TH:US-0013020:comment out
	/*static final Set<String> EXCLUDE_STATUS = new Set<String>
	{
		'New','Negotiating','Negotiating Amended','Rejected' 
	};*/
	static final Set<String> EXCLUDE_STATUS = new Set<String>
	{
		'New','Rejected', 'Seller Cancelled' // 31.03.2023 / Sophal Noch / US-0013495 : add 'Seller Cancelled'
	};
	//blue, red, green, purple, brown, orange, grey	
	static final Map<String,String> MAP_COLOR  = new Map<String,String>
	{
		'Soft Home'=>'green',
		'Hard Home'=>'green',
		'Home Appliances'=>'green',
		'Fashion'=>'red',
		'Fashion, Sport & Beauty'=>'red2',
		'Parts'=>'brown',
		'Other'=>'purple',
		'P&A'=>'brown',
		'Health & Beauty'=>'pink',
		'Electronics'=>'blue',
		'Home & Garden'=>'green',
		'Media'=>'blue',
		'Toys'=>'orange',
		'Sports & Leisure'=>'orange',
		'Lifestyle'=>'pink',
		'Business & Industrial'=>'purple',
		'Fitness'=>'yellow',
		'Automotive'=>'brown',
		'Joyería y Belleza'=>'yellow',
		'Electrónica'=>'blue',
		'Moda'=>'red',
		'Casa y Jardín'=>'green',
		'Ocio'=>'purple',
		'Deportes'=>'pink',
		'Motor'=>'brown',
		'Coleccionismo'=>'orange',
		'Otras categorías'=>'purple',
		'High-Tech'=>'blue',
		'Mode'=>'red',
		'Maison & Jardin'=>'green',
		'Auto et Moto'=>'brown',
		'Collections & Antiquités'=>'orange',
		'Collectibles'=>'orange',
		'Tecnologia'=>'blue',
		'Casa & Giardino'=>'green',
		'Sport & Viaggi'=>'orange',
		'Auto & Moto'=>'brown',
		'Collezionabili'=>'orange',
		'Commercio, Ufficio e Industria'=>'pink',
		'Suministros industriales'=>'purple',
		'H&G'=>'green',
		'Unassigned'=>'grey'
	};
	final static List<String> COLOR_LIST = new List<String>
	{
		'rgb(88, 222, 255)','rgb(237, 221, 255)','rgb(249, 225, 242)','rgb(249, 225, 227)','rgb(225, 228, 249)','rgb(225, 236, 249)','rgb(225, 247, 249)','rgb(225, 249, 242)','rgb(249, 231, 225)','rgb(238, 243, 200)','rgb(204, 241, 247)','rgb(204, 207, 247)','rgb(239, 201, 213)'
	};
	static List<Map<String,Object>> listDealColNameMini = new List<Map<String,Object>> // for mini table
		{
			new Map<String,Object>{'label'=>'Vertical','fieldName'=>'vertical','type'=>'STRING'},
			new Map<String,Object>{'label'=>'Assigned','fieldName'=>'assigned','type'=>'DOUBLE'},
			new Map<String,Object>{'label'=>'Free','fieldName'=>'free','type'=>'DOUBLE'}
		};
		
	@auraEnabled
	public static Map<String,Object> apexInitDailyView()
	{
		Map<String,Object> mapResult = new Map<String,Object>();
		
    	Map<String,List<ApexUtil.PicklistEntryWrapper>> pklDepVertical  = ApexUtil.getDependentMap(EBH_Deal__c.getSObjectType(),'EBH_DealSiteId__c','EBH_Vertical__c');
		
    	List<Schema.FieldSetMember> fieldSetDealTable = SObjectType.EBH_Deal__c.FieldSets.DailyDealViewTable.getFields();
    	 
    	List<Map<String,Object>> listDealColName = genListDealColName(fieldSetDealTable);
    	
        List<Map<String,String>> listPklValDealFormat = ApexUtil.getPicklistValues(EBH_Deal__c.EBH_DealFormat__c);
        List<Map<String,String>> listPklValDealSite = ApexUtil.getPicklistValues(EBH_Deal__c.EBH_DealSiteId__c);
        List<Map<String,String>> listPklValDealVertical = ApexUtil.getPicklistValues(EBH_Deal__c.EBH_Vertical__c);
        
        mapResult.put('listPklValDealFormat',listPklValDealFormat);
        mapResult.put('listPklValDealSite',listPklValDealSite);
        mapResult.put('listPklValDealVertical',listPklValDealVertical);
        mapResult.put('pklDepVertical',pklDepVertical);
        
      
        mapResult.put('listDealColName',listDealColName);
        mapResult.put('listDealColNameMini',listDealColNameMini);
        
        mapResult.put('status','ok');
		return mapResult;
		
	}
	@auraEnabled
	public static Map<String,Object> apexQueryDailyView(String dealSite,String dealFormat,String[] selVerticals,String dateYYYMMDD,Boolean onlyFreeSlot)
	{
		Map<String,Object> mapResult = new Map<String,Object>();
		dealFormat = 'Primary'; //always Primary
		
		String[] dateSplitStr = dateYYYMMDD.split('-');
		Date currentDate = Date.newInstance(Integer.valueOf(dateSplitStr[0]), Integer.valueOf(dateSplitStr[1]), Integer.valueOf(dateSplitStr[2]));
		Date preDate = currentDate.addDays(-1);
		Date nextDate = currentDate.addDays(+1); 
		
    	String defaultWhere = ' Where EBH_Status__c NOT IN:EXCLUDE_STATUS AND EBH_DealSiteId__c=:dealSite AND EBH_DealFormat__c=:dealFormat  ';
    	
		String dealBaseSoql = generateSQOLDeal(dealSite);
		String soqlWhereAll = dealBaseSoql + defaultWhere + ((selVerticals <> null && !selVerticals.isEmpty())? 'AND EBH_Vertical__c IN:selVerticals':''); 
		
		system.debug('>>>soqlWhereAll: '+soqlWhereAll); 
		
		//'Select Id,Name,EBH_Date__c,EBH_DealFormat__c,EBH_Country__c, 
		//EBH_Category__c,EBH_Description__c,EBH_DealSlotDisabled__c,EBH_DealTitle__c,EBH_OpenSeatsAvailable__c,EBH_Slots__c,
		//EBH_Vertical__c From EBH_DealSlotAllocation__c ';
		String sWherAlloc = ' Where EBH_DealFormat__c=:dealFormat AND EBH_Country__c=:dealSite ' + ((selVerticals <> null && !selVerticals.isEmpty())? ' AND EBH_Vertical__c IN:selVerticals ':'');  
		
		List<EBH_DealSlotAllocation__c> slotAllocCurrent = Database.query(EBH_ConstantsUtility.SOQL_DEAL_SLOT_ALLOC+sWherAlloc+' AND EBH_Date__c=:currentDate ORDER BY EBH_Vertical__c');
		List<EBH_DealSlotAllocation__c> slotAlloPre = Database.query(EBH_ConstantsUtility.SOQL_DEAL_SLOT_ALLOC+sWherAlloc+' AND EBH_Date__c=:preDate ORDER BY EBH_Vertical__c');
		List<EBH_DealSlotAllocation__c> slotAllocNext = Database.query(EBH_ConstantsUtility.SOQL_DEAL_SLOT_ALLOC+sWherAlloc+' AND EBH_Date__c=:nextDate ORDER BY EBH_Vertical__c');
		
		List<EBH_Deal__c> listDealCurrent = Database.query(soqlWhereAll+' AND EBH_DealStartDate__c=:currentDate'); //current = today +1
        List<EBH_Deal__c> listDealPre = Database.query(soqlWhereAll+' AND EBH_DealStartDate__c=:preDate'); //current -1 = today
        List<EBH_Deal__c> listDealNext = Database.query(soqlWhereAll+' AND EBH_DealStartDate__c=:nextDate'); //current +1 = tmr +1
		
		List<Schema.FieldSetMember> fieldSetDealTable = SObjectType.EBH_Deal__c.FieldSets.DailyDealViewTable.getFields();
    	List<Map<String,Object>> listDealColName = genListDealColName(fieldSetDealTable);
    	
        DealSlotCount countCurrent = new DealSlotCount();
        DealSlotCount countPre = new DealSlotCount();
        DealSlotCount countNext = new DealSlotCount();
         
         
		List<Object> listMapCurrent = populateSlotTable(listDealColName,listDealCurrent,slotAllocCurrent,countCurrent,false,onlyFreeSlot);
		List<Object> listDealSlotPre = populateSlotTable(listDealColName,listDealPre,slotAlloPre,countPre,true,onlyFreeSlot);
		List<Object> listDealSlotNex = populateSlotTable(listDealColName,listDealNext,slotAllocNext,countNext,true,onlyFreeSlot);
        
        mapResult.put('listDealCurrent',listMapCurrent);
        mapResult.put('listDealPre',listDealSlotPre);
        mapResult.put('listDealNext',listDealSlotNex);
        
        mapResult.put('countCurrent',countCurrent);
        mapResult.put('countPre',countPre);
        mapResult.put('countNext',countNext);
        
        mapResult.put('status','ok');
		return mapResult;
	}
	/**
		- Slots Total: Count of Slots field from all related Deal Slot Records for that particular day
		- Slots Assigned: Count of Slots field from all related Deal Slot Records for that particular day and that have a Vertical
		- Slots Planned: Count of Slots field from all related Deal Slot Records for that particular day and that have a Deal Record assigned
	*/
	private static List<Object> populateSlotTable(List<Map<String,Object>> listDealColName,List<EBH_Deal__c> listDealCurrent, List<EBH_DealSlotAllocation__c> slotAlloc,DealSlotCount slotCount,Boolean isMini,Boolean onlyFreeSlot)
	{
		List<Object> listMapCurrent = new List<Object>();
		Map<String,List<EBH_Deal__c>> mapDealByVertical = new Map<String,List<EBH_Deal__c>>();
		for(EBH_Deal__c d: listDealCurrent)
		{
			if(!mapDealByVertical.containsKey(d.EBH_Vertical__c))
			{
				mapDealByVertical.put(d.EBH_Vertical__c,new List<EBH_Deal__c>());
			}
			mapDealByVertical.get(d.EBH_Vertical__c).add(d);
		}
		
		Integer sTotal=0,sAssigned=0,sPlanned=0,sFree=0;
		Integer totalDeal = 0;
		for(EBH_DealSlotAllocation__c dSlot: slotAlloc)
    	{
    		Integer slotNUm = Integer.valueOf((dSlot.EBH_Slots__c==null?0:dSlot.EBH_Slots__c)); 
    		sTotal += slotNUm;
    		sAssigned += dSlot.EBH_Vertical__c==null?0:slotNUm;
    		
    		List<EBH_Deal__c> listDealByVertical = mapDealByVertical.get(dSlot.EBH_Vertical__c);
    		Integer dealSize = listDealByVertical== null?0:listDealByVertical.size();
    		totalDeal += dealSize;
    		
    		//system.debug('>>>vertical: '+dSlot.EBH_Vertical__c+' slot: '+dSlot.EBH_Slots__c+'  Dealsize: '+dealSize+ ' >>>>sTotal: '+sTotal +' >>slotNUm: '+slotNUm+' >>sAssigned: '+sAssigned);
    		Integer numSlotToShow = slotNUm-dealSize;// (slotNUm-dealSize <=0?0:slotNUm-dealSize);
			sFree +=numSlotToShow;
			
    		if(isMini) //mini table
			{
				DealSlot slotMini = new DealSlot(dSlot.get('vertical')+'',slotNUm,(slotNUm - dealSize),getColor(dSlot.EBH_Vertical__c));
			 	listMapCurrent.add(slotMini);
			}
    		else
    		{
    			//display all slot both used and free slot
    			// if onlyFreeSlot flag is checked, then so only slot that not used by deal
				if(!onlyFreeSlot && listDealByVertical!=null)
    			{
    				for(EBH_Deal__c d: listDealByVertical)
					{
						listMapCurrent.add(createRow(listDealColName,dSlot,d));
					}
    			} 
	    			
    			for(Integer i=0;I<numSlotToShow;i++)
    			{	
    				listMapCurrent.add(createRow(listDealColName,dSlot,null));
    			}
    			
    		}	
    		
    	}
		
		slotCount.slotTotal = Integer.valueOf(sTotal);
		slotCount.slotAssigned = Integer.valueOf(sAssigned);
		slotCount.slotPlanned = Integer.valueOf(totalDeal);
		slotCount.slotFree = sFree;
		
		return listMapCurrent;
	}
	
	private static List<Map<String,Object>> createRow(List<Map<String,Object>> listDealColName,EBH_DealSlotAllocation__c dSlot,EBH_Deal__c d)
	{
		List<Map<String,Object>> listValue = new List<Map<String,Object>> 
		{	
			new Map<String,Object>{'fieldName'=>'Id','value'=>d==null?'':d.Id,'type'=>'STRING','cellClass'=>'','visible'=>false,'vertical'=>dSlot.get('vertical')} //hide id field	
		};
		for(Map<String,Object> f : listDealColName)
		{
			 listValue.add(
				 	new Map<String,Object>{
				 		'fieldName'=>f.get('fieldName'),
				 		'value'=>d==null?((f.get('fieldName')=='EBH_Vertical__c'?dSlot.get('vertical')+'':'')):ApexUtil.getValue(f.get('fieldName')+'',d),
				 		'type'=>f.get('type')+'','cellClass'=>getColor(dSlot.EBH_Vertical__c),
				 		'visible'=>setHiddenFields.contains(f.get('fieldName')+'')?false:true,
				 		'isRef'=>d==null?false:Boolean.valueOf(f.get('isRef')),
				 		'isRef2'=> mapSpecialURLFields.containsKey(f.get('fieldName')+''),
				 		'ref2Value'=>mapSpecialURLFields.containsKey(f.get('fieldName')+'')?ApexUtil.getValue(mapSpecialURLFields.get(f.get('fieldName')+''),d):'',
				 		'refId'=>d==null?'':(Boolean.valueOf(f.get('isRef'))?ApexUtil.getValue(ApexUtil.getFieldIdRef(f.get('fieldName')+'')+'',d):''),
				 		'initWidth'=>f.get('initWidth')
				 		}
				 );
							 
		}
		
		return listValue;
	}
	//some fields not to visible to the page, but to get reference value. because we use fieldset to query all fields
	private static Set<String> setHiddenFields = new Set<String>{'eBay_Link_URL__c'};
	
	//e.g. field item id needs a link by formula field: eBay_Link_URL__c
	private static Map<String,String> mapSpecialURLFields = new Map<String,String>{'EBH_eBayItemID__c'=>'eBay_Link_URL__c'};
	
	private static List<Map<String,Object>> genListDealColName(List<Schema.FieldSetMember> fieldSetDealTable)
	{
    	List<Map<String,Object>> listDealColName = new List<Map<String,Object>>();
    	
        for(Schema.FieldSetMember f : fieldSetDealTable) {
        	if(setHiddenFields.contains(f.getFieldPath()+''))continue;
            listDealColName.add(
            	new Map<String,Object>{
            		'label'=>mapFieldLabel.get(f.getFieldPath()),
            		'fieldName'=>f.getFieldPath(),
            		'type'=>f.getType(),
            		'isRef'=>(f.getFieldPath().contains('.') && f.getFieldPath().endsWith('Name')), //if field is referent to parent Name\
            		'isRef2'=> mapSpecialURLFields.containsKey(f.getFieldPath()+''),
            		'initWidth'=> mapFieldWith.get(f.getFieldPath())
            	}
            );
        }
        
        return listDealColName;
	} 
	private static Map<String,String> mapFieldWith = new  Map<String,String>
	{
		'Rank__c'=>'width: 65px;',
		'EBH_Vertical__c'=>'min-width: 155px;',
		'EBH_eBayItemID__c'=>'',
		'EBH_BusinessName__r.Name'=>'',
		'EBH_ProductTitle__c'=>'',
		'EBH_Quantity__c'=>'width: 75px;',
		'EBH_DealPrice__c'=>'',
		'EBH_Subsidy__c'=>'',
		'EBH_SubsidyP__c'=>'',
		'EBH_GMV__c'=>'',
		'EBH_SubsidyMax__c'=>''
	};
	//Oliver want field label chaned in the page (shorter)
	private static Map<String,String> mapFieldLabel = new  Map<String,String>
	{
		'Rank__c'=>'Rank',
		'EBH_Vertical__c'=>'Vertical',
		'EBH_eBayItemID__c'=>'Item Id',
		'EBH_BusinessName__r.Name'=>'Seller',
		'EBH_ProductTitle__c'=>'Title',
		'EBH_Quantity__c'=>'QTY',
		'EBH_DealPrice__c'=>'Deal Price',
		'EBH_Subsidy__c'=>'Subsidy per SI',
		'EBH_SubsidyP__c'=>'Subsidy %',
		'EBH_GMV__c'=>'GMV (Planned)',
		'EBH_SubsidyMax__c'=>'Subsidy Planned Net',
		'Owner.Name'=>'Owner'
	}; 
	private static String generateSQOLDeal(String dealSite)
	{
		List<Schema.FieldSetMember> fieldSetDealTable = SObjectType.EBH_Deal__c.FieldSets.DailyDealViewTable.getFields();
    	String dealBaseSoql = 'SELECT ';
    	Set<String> setFields = new Set<String>{'Id'};
        for(Schema.FieldSetMember f : fieldSetDealTable) 
        {        	
        	setFields.add(f.getFieldPath());
        	if(f.getFieldPath().contains('.') && f.getFieldPath().endsWith('Name'))
        	{
        		String fId = ApexUtil.getFieldIdRef(f.getFieldPath());
        		setFields.add(fId);
        	}
        }
        for(String f: setFields)
        {
        	dealBaseSoql += f + ', ';
        	
        }
        dealBaseSoql = dealBaseSoql.removeEnd(', ');
        dealBaseSoql += ' FROM EBH_Deal__c ';
        system.debug('>>>>>>>dealBaseSoql: '+dealBaseSoql);
        return dealBaseSoql;
	}
	
	private static String getColor(String vertical)
	{
		return MAP_COLOR.containsKey(vertical)?MAP_COLOR.get(vertical):MAP_COLOR.get('Unassigned');
	}
	 
	class DealSlot{
		@auraEnabled public String vertical;
		@auraEnabled public Integer assigned;
		@auraEnabled public Integer free;
		@auraEnabled public String cellClass;
		public DealSlot(String vertical,Integer assigned,Integer free,String cellClass)
		{
			this.vertical = vertical;
			this.assigned = assigned;
			this.free = free;
			this.cellClass = cellClass;
		}
	}
	
	class DealSlotCount{
		@auraEnabled public Integer slotTotal = 0;
		@auraEnabled public Integer slotAssigned =0;
		@auraEnabled public Integer slotPlanned =0;
		@auraEnabled public Integer slotFree =0;
		public DealSlotCount()
		{
		}
	}
	
	/*****************************************************************************************************************************
    @ Method:   apexQueryWeeklyDeals
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  US-0018763 Deals - Masterschedule - New Page 'Daily View on Deal Object
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      dateYYYMMDD , siteId , spotLights
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.03.2020 / Vadhanak Voun / Updated the  Method.
    @					13.03.2020:	US-0007341: either end date is in the future (> today) or the end date is empty (which means there is no end date) 
    *****************************************************************************************************************************/
	@auraEnabled
	public static Map<String,Object> apexQueryWeeklyDeals(String dateYYYMMDD,String siteId,String[] spotLights)
	{
		System.debug('>>>:dateYYYMMDD: '+dateYYYMMDD +' >>siteId: '+ siteId +' >>>spotLights: '+spotLights);
		
		Map<String,Object> mapResult = new Map<String,Object>();
		
		String[] dateSplitStr = dateYYYMMDD.split('-');
		Date currentDate = Date.newInstance(Integer.valueOf(dateSplitStr[0]), Integer.valueOf(dateSplitStr[1]), Integer.valueOf(dateSplitStr[2]));
		
		Date dateStartCurrentWeek = getFirstDateofWeek(currentDate).date();
		Date dateEndCurrentWeek = dateStartCurrentWeek.addDays(6);
		Date dateStartNextWeek = dateEndCurrentWeek.addDays(1);
		Date dateEndNextWeek = dateStartNextWeek.addDays(6);
		System.debug('>>>>dateStartCurrentWeek: ' +dateStartCurrentWeek +'  >>:dateEndCurrentWeek: '+dateEndCurrentWeek +'  >>:dateStartNextWeek: '+dateStartNextWeek+'   >>:dateEndNextWeek:'+dateEndNextWeek);
		
		String dealFormatFeature = 'Featured'; 
		
		String sWhereDealW1 = ' WHERE EBH_DealSiteId__c=:siteId ' +
						' AND (EBH_DealStartDate__c >=:dateStartCurrentWeek AND EBH_DealStartDate__c <=:dateEndCurrentWeek) '+
						' AND EBH_DealFormat__c=:dealFormatFeature '+
						' AND EBH_Status__c NOT IN:EXCLUDE_STATUS ';
		String sWhereDealW2 = ' WHERE EBH_DealSiteId__c=:siteId ' +
						' AND (EBH_DealStartDate__c >=:dateStartNextWeek AND EBH_DealStartDate__c <=:dateEndNextWeek) '+
						' AND EBH_DealFormat__c=:dealFormatFeature '+
						' AND EBH_Status__c NOT IN:EXCLUDE_STATUS ';
										
		String siteName = EBH_ConstantsUtility.MAP_CODE_TO_COUNTRY.get(siteId);
		
		String sSpotLightForSpotLIght = (spotLights<>null&&!spotLights.isEmpty())?' AND ID IN:spotLights':'';
		String sSpotLightForDeal = (spotLights<>null&&!spotLights.isEmpty())?' AND EBH_SpotlightCategory__c IN:spotLights':'';
		
		System.debug('>>>>sSpotLight: ' +sSpotLightForDeal);
		System.debug('>>>>sSpotLightForSpotLIght: ' +sSpotLightForSpotLIght);
		
		//US-0007341: this flag Active (formula) includes two scenarios a)  either end date is in the future (> today) or the end date is empoty (which means there is no end date) 
		String sWhereSpotLight = ' WHERE EBH_Country__c= :siteName AND Active__c = TRUE '+ sSpotLightForSpotLIght;
						
		Map<String,List<EBH_Deal__c>> mapDealList = new Map<String,List<EBH_Deal__c>>();
		//soql spotlight with deal for Current week
		String soqlSpotLightW1 = 'Select Spotlight_Start_Date__c, Spotlight_End_Date__c, Name, EBH_SpotlightCategoryID__c, EBH_Country__c, Active__c, '+ 
							'(Select Id, Name, CurrencyIsoCode, EBH_BusinessName__c,EBH_BusinessName__r.Name, EBH_Category__c, EBH_DealEndDate__c, EBH_DealFormat__c'+
							' ,EBH_DealPrice__c, EBH_DealStartDate__c, EBH_MarketingTitle__c, EBH_ProductTitle__c, EBH_Quantity__c,EBH_eBayItemID__c, EBH_SellerAccepted__c '+
							', EBH_SpotlightCategory__c From EBH_SpotlightCategory__r '+sWhereDealW1+' ORDER BY EBH_BusinessName__r.Name LIMIT '+DEFAULT_LIST_SIZE+ ' ) '+
							' From EBH_SpotlightCategory__c '+sWhereSpotLight+' ORDER BY NAME';
		
		//soql spotlight with deal for Next week					
		String soqlSpotLightW2 = 'Select Spotlight_Start_Date__c, Spotlight_End_Date__c, Name, EBH_SpotlightCategoryID__c, EBH_Country__c, Active__c, '+ 
							'(Select Id, Name, CurrencyIsoCode, EBH_BusinessName__c,EBH_BusinessName__r.Name, EBH_Category__c, EBH_DealEndDate__c, EBH_DealFormat__c'+
							' ,EBH_DealPrice__c, EBH_DealStartDate__c, EBH_MarketingTitle__c, EBH_ProductTitle__c, EBH_Quantity__c,EBH_eBayItemID__c, EBH_SellerAccepted__c '+
							', EBH_SpotlightCategory__c From EBH_SpotlightCategory__r '+sWhereDealW2+' ORDER BY EBH_BusinessName__r.Name LIMIT '+DEFAULT_LIST_SIZE+ ' ) '+
							' From EBH_SpotlightCategory__c '+sWhereSpotLight+' ORDER BY NAME';
		
		System.debug('>>>>soqlSpotLight1: ' +soqlSpotLightW1);
		System.debug('>>>>soqlSpotLight2: ' +soqlSpotLightW2);
		System.debug('>>>>sWhereDeal: ' +sWhereDealW1);
		
		String sWhereRED = ' AND (EBH_eBayItemID__c = null OR EBH_SellerAccepted__c=null) ';
		//count for week1 
		String soqlARG1 = 'Select EBH_SpotlightCategory__c, Count(Id) numDeal FROM EBH_Deal__c '+sWhereDealW1+sSpotLightForDeal +' Group By EBH_SpotlightCategory__c';
		String soqlARG1_RED = 'Select EBH_SpotlightCategory__c, Count(Id) numRed FROM EBH_Deal__c '+sWhereDealW1+sSpotLightForDeal+ sWhereRED +' Group By EBH_SpotlightCategory__c';
		//count for week2
		String soqlARG2 = 'Select EBH_SpotlightCategory__c, Count(Id) numDeal FROM EBH_Deal__c '+sWhereDealW2+sSpotLightForDeal +' Group By EBH_SpotlightCategory__c';
		String soqlARG2_RED = 'Select EBH_SpotlightCategory__c, Count(Id) numRed FROM EBH_Deal__c '+sWhereDealW2+sSpotLightForDeal + sWhereRED +' Group By EBH_SpotlightCategory__c';
		
		Map<String,Integer> mapCount = new Map<String,Integer>(); 
		for(Aggregateresult ar: Database.query(soqlARG1))
		{
			mapCount.put(ar.get('EBH_SpotlightCategory__c')+'_W1',Integer.valueOf(ar.get('numDeal')));
		}
		for(Aggregateresult ar: Database.query(soqlARG2))
		{
			mapCount.put(ar.get('EBH_SpotlightCategory__c')+'_W2',Integer.valueOf(ar.get('numDeal')));
		}
		
		//aggr for Red Status
		for(Aggregateresult ar: Database.query(soqlARG1_RED))
		{
			mapCount.put(ar.get('EBH_SpotlightCategory__c')+'_W1RED',Integer.valueOf(ar.get('numRed')));
		}
		for(Aggregateresult ar: Database.query(soqlARG2_RED))
		{
			mapCount.put(ar.get('EBH_SpotlightCategory__c')+'_W2RED',Integer.valueOf(ar.get('numRed')));
		}
		system.debug('>>>>mapCount: '+mapCount);
		
		List<Map<String,Object>> listDealBySpotLight = new List<Map<String,Object>>();
		Integer index = 0;
		 
		Map<String,EBH_SpotlightCategory__c> mapSpotlightW2 = new Map<String,EBH_SpotlightCategory__c>((EBH_SpotlightCategory__c[])Database.query(soqlSpotLightW2 ));
		
		for(EBH_SpotlightCategory__c spl:  Database.query(soqlSpotLightW1 ))
		{
			List<EBH_Deal__c> listDealCurrentWeek = spl.EBH_SpotlightCategory__r==null?new List<EBH_Deal__c>():spl.EBH_SpotlightCategory__r;
			EBH_SpotlightCategory__c splNexWDeal = mapSpotlightW2.get(spl.Id); //same spotlight but contains deal for next week
			List<EBH_Deal__c> listDealNextWeek = splNexWDeal.EBH_SpotlightCategory__r==null?new List<EBH_Deal__c>():splNexWDeal.EBH_SpotlightCategory__r;
			
			//Datetime.newInstanceGmt(input, Time.newInstance(0,0,0,0)).format(SF_DATE_FORMAT);
			listDealBySpotLight.add(
				new Map<String,Object>{
					'spotlightId'=>spl.Id,
					'spotlightName'=>spl.Name,
					'currentWeekPlanned'=>mapCount.containsKey(spl.Id+'_W1')?mapCount.get(spl.Id+'_W1'):0,
					'nextWeekPlanned'=>mapCount.containsKey(spl.Id+'_W2')?mapCount.get(spl.Id+'_W2'):0,
					'listDealCurrentWeek'=>listDealCurrentWeek,
					'listDealNextWeek'=>listDealNextWeek,
					'dateStartW1'=>dateStartCurrentWeek,
					'dateEndW1'=>dateEndCurrentWeek,
					'dateStartW2'=>dateStartNextWeek,
					'dateEndW2'=>dateEndNextWeek,
					'color'=> COLOR_LIST[index],
					'w1Red'=>mapCount.containsKey(spl.Id+'_W1RED')?mapCount.get(spl.Id+'_W1RED'):0,
					'w2Red'=>mapCount.containsKey(spl.Id+'_W2RED')?mapCount.get(spl.Id+'_W2RED'):0
				}
			);
			
			//to make sure that when they refresh the page will not get different color
			index = index <(COLOR_LIST.size()-1)?index+1:0;
			 
		}
		
		
		List<Map<String,String>> listSpotLight = new List<Map<String,String>>();
		Map<String,EBH_SpotlightCategory__c> mapSLC = new Map<String,EBH_SpotlightCategory__c>(); 
		String sWhereALLSPL = ' WHERE Active__c = TRUE AND EBH_Country__c=:siteName';
		for(EBH_SpotlightCategory__c spc: Database.query(EBH_ConstantsUtility.SOQL_SPOTLIGHT_CAT +sWhereALLSPL))
		{
			mapSLC.put(spc.Name,spc); //making uniqueness
		}
		List<String> listSPCName = new List<String>();
		for(EBH_SpotlightCategory__c spc: mapSLC.values())
		{
			listSPCName.add(spc.Name);
		}
		listSPCName.sort(); //sort for better order in picklist
		
		for(String spcName: listSPCName)
		{
			EBH_SpotlightCategory__c spc = mapSLC.get(spcName);
			listSpotLight.add(
				new Map<String,String>{'label'=>spc.Name,'value'=>spc.Id}
			);
		}
       	
       	List<Map<String,String>> listPklValDealSite = ApexUtil.getPicklistValues(EBH_Deal__c.EBH_DealSiteId__c);
       	
        mapResult.put('listSpotLight',listSpotLight);
        mapResult.put('listPklValDealSite',listPklValDealSite);
         
		mapResult.put('listDealBySpotLight',listDealBySpotLight);
		 
		mapResult.put('status','ok'); 
		return mapResult;
	}
	
	/*****************************************************************************************************************************
    @ Method:   getFirstDateofWeek
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:  US-0018763 Deals - Masterschedule - New Page 'Daily View on Deal Object
    @			Monday: 1 - Sunday: 7
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Date
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.03.2020 / Vadhanak Voun / Updated the  Method.
    @						Weekly Deal week starts from Thursday to Wednesday
    *****************************************************************************************************************************/
	private static DateTime getFirstDateofWeek(Date currentDate )
	{
		DateTime currDate = DateTime.newInstanceGmt(currentDate.year(), currentDate.month(), currentDate.day());
		Integer dayOfWeek = Integer.valueOf(currDate.formatGMT('u')); //05/03/2020:NK:US-0007305. fixe added GMT to format
		DateTime firstDayOfWeek = currDate.addDays(4-dayOfWeek);
		firstDayOfWeek = currDate < firstDayOfWeek? firstDayOfWeek.addDays(-7):firstDayOfWeek;
		return firstDayOfWeek;
	}
}