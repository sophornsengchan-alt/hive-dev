/*********************************************************************************************************************************
@ Class:          DealFilter
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        US-0008846 - [NA] Migrate JOIN NA Deals Trigger and related Classes to Hive 
@ Usage:		  DealFilter.getInstance().getListNew_STD(); DealFilter.getInstance().getListNew_NA();...
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.12.2020 / Vadhanak Voun / Created the class.
*********************************************************************************************************************************/
public without sharing class DealFilter{
	
	public final static String RECTYPE_STD = 'Deal_V1'; //developer name
	public final static String RECTYPE_NA  = 'Deal_V2';
	
	private static DealFilter df;
	
	private Map<String,EBH_Deal__c[]> mapOfListDeals = new Map<String,EBH_Deal__c[]>(); // trigger.old, trigger.new
	private Map<String,Map<Id,EBH_Deal__c>> mapOfMapDeals = new Map<String,Map<Id,EBH_Deal__c>>(); //oldMap, newMap
	
	private final String recStateOld = 'old';	//map identifier trigger.old or trigger.new
	private final String recStateNew = 'new';
	
	private List<EBH_Deal__c> listNew; //for trigger.new
	private List<EBH_Deal__c> listOld; //for trigger.old
	
	private DealFilter(List<EBH_Deal__c> listNew,List<EBH_Deal__c> listOld)
	{
		this.listNew = listNew;
		this.listOld = listOld;
	}
	//for Test or  future use for manual filtering
	public static DealFilter getInstance(List<EBH_Deal__c> listNew,List<EBH_Deal__c> listOld)
	{
		return createDF(listNew,listOld);
	}
	
	//For real use
	public static DealFilter getInstance()
	{
		return createDF(Trigger.new,Trigger.old);
	}
	
	private static DealFilter createDF(List<EBH_Deal__c> listNew,List<EBH_Deal__c> listOld)
	{
		if(df==null)
		{
			df = new DealFilter(listNew,listOld);
		}
		df.assignList(listNew,listOld);
		df.filterDeals();
		return df;
	}
	private void assignList(List<EBH_Deal__c> listNew,List<EBH_Deal__c> listOld)
	{
		this.listNew  =listNew;
		this.listOld  =listOld;
	}
	private void filterDeals()
	{
	
		//System.debug('<<<<<getListNew_STD(): '+getListNew_STD());
		//System.debug('<<<<<getListOLD_STD(): '+getListOLD_STD());
		//start filtering if not yet filter
		if(!mapOfListDeals.isEmpty()){
			for(String key : mapOfListDeals.keySet()){
				mapOfListDeals.put(key,new List<EBH_Deal__c>());
				mapOfMapDeals.put(key,new Map<Id,EBH_Deal__c>());
			}
		}
		
		if(listNew <> null)
		{
			for(EBH_Deal__c d: listNew)
			{
				if(!mapOfMapDeals.containsKey(d.RecordTypeId+recStateNew))
				{
					mapOfMapDeals.put(d.RecordTypeId+recStateNew,new Map<Id,EBH_Deal__c>());
					mapOfListDeals.put(d.RecordTypeId+recStateNew,new List<EBH_Deal__c>());
				}
				//mapOfMapDeals.get(d.RecordTypeId+recStateNew).put(d.Id,d);
				if(d.Id != null) mapOfMapDeals.get(d.RecordTypeId+recStateNew).put(d.Id,d);
				mapOfListDeals.get(d.RecordTypeId+recStateNew).add(d);
			}
		}
		
		if(listOld <> null)
		{
			for(EBH_Deal__c d: listOld)
			{
				if(!mapOfMapDeals.containsKey(d.RecordTypeId+recStateOld))
				{
					mapOfMapDeals.put(d.RecordTypeId+recStateOld,new Map<Id,EBH_Deal__c>());
					mapOfListDeals.put(d.RecordTypeId+recStateOld,new List<EBH_Deal__c>());
				}
				if(d.Id != null) mapOfMapDeals.get(d.RecordTypeId+recStateOld).put(d.Id,d);
				mapOfListDeals.get(d.RecordTypeId+recStateOld).add(d);
			}
		}
	}
	public List<EBH_Deal__c> getListNew_STD()
	{
		String key = ApexUtil.getRecordTypeByName('EBH_Deal__c',RECTYPE_STD).Id+recStateNew;
		return (mapOfListDeals.containskey(key) ? mapOfListDeals.get(key) : new List<EBH_Deal__c>());
	}
	public List<EBH_Deal__c> getListNew_NA()
	{
		String key = ApexUtil.getRecordTypeByName('EBH_Deal__c',RECTYPE_NA).Id+recStateNew;
		return (mapOfListDeals.containsKey(key) ? mapOfListDeals.get(key) : new List<EBH_Deal__c>());
	}
	public List<EBH_Deal__c> getListOLD_STD()
	{
		String key = ApexUtil.getRecordTypeByName('EBH_Deal__c',RECTYPE_STD).Id+recStateOld;
		return (mapOfListDeals.containsKey(key) ? mapOfListDeals.get(key) : new List<EBH_Deal__c>());
	}
	public List<EBH_Deal__c> getListOLD_NA()
	{
		String key = ApexUtil.getRecordTypeByName('EBH_Deal__c',RECTYPE_NA).Id+recStateOld;
		return (mapOfListDeals.containsKey(key) ? mapOfListDeals.get(key) :new List<EBH_Deal__c>());
	}
	
	public Map<Id,EBH_Deal__c> getMapOld_STD()
	{
		String key = ApexUtil.getRecordTypeByName('EBH_Deal__c',RECTYPE_STD).Id+recStateOld;
		return (mapOfMapDeals.containsKey(key) ? mapOfMapDeals.get(key) : new Map<Id,EBH_Deal__c>());
	}
	public Map<Id,EBH_Deal__c> getMapOld_NA()
	{
		String key = ApexUtil.getRecordTypeByName('EBH_Deal__c',RECTYPE_NA).Id+recStateOld;
		return (mapOfMapDeals.containsKey(key) ? mapOfMapDeals.get(key) : new Map<Id,EBH_Deal__c>());
	}
	public Map<Id,EBH_Deal__c> getMapNew_STD()
	{
		String key = ApexUtil.getRecordTypeByName('EBH_Deal__c',RECTYPE_STD).Id+recStateNew;
		return (mapOfMapDeals.containsKey(key) ? mapOfMapDeals.get(key) : new Map<Id,EBH_Deal__c>());
	}
	public Map<Id,EBH_Deal__c> getMapNew_NA()
	{
		String key = ApexUtil.getRecordTypeByName('EBH_Deal__c',RECTYPE_NA).Id+recStateNew;
		return (mapOfMapDeals.containsKey(key) ? mapOfMapDeals.get(key) : new Map<Id,EBH_Deal__c>());
	}
}