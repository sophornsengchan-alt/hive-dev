/*********************************************************************************************************************************
@ Class:        BatchDealSlotAllocation
@ Version:      1.0
@ Author:       Sreymeas Nao (sreymeas.nao@gaea-sys.com)
@ Purpose:	US-0006486 Deals - Masterschedule - Batch Process for Deals Slot Record Creation      
@		Create a daily new batch to create new EBH_DealSlotAllocation__c Records per day for 12 weeks in advance by vertical for EBH_Country__c = DE and EBH_DealFormat__c = primary              
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11.25.2019 / Sreymeas Nao (sreymeas.nao@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/

global with sharing class BatchDealSlotAllocation implements Schedulable{
	
	@TestVisible
	private static Integer default12WeekNum = 12;//12 weeks onwards
    public void execute(SchedulableContext context){
      
      //get the last slot created by System
      //String sWhere = ' Where System_Created__c=TRUE Order BY EBH_Date__c DESC LIMIT 1';
      //EBH_DealSlotAllocation__c[] existingSlot = Database.query(EBH_ConstantsUtility.SOQL_DEAL_SLOT_ALLOC);
      
      populate12WeeksSlot(default12WeekNum);
      
    }

    private static Map<String,DealSlotMapping__c[]> mapSlotAlloc;
    private static DealSlotMapping__c[] getSlotAlloc(String day)
    {
    	if(mapSlotAlloc==null)
    	{
    		mapSlotAlloc = new Map<String,DealSlotMapping__c[]>();
    		for(DealSlotMapping__c sm: DealSlotMapping__c.getAll().values())
    		{
    			 
    			if(!mapSlotAlloc.containsKey(sm.Day__c))
    			{
    				mapSlotAlloc.put(sm.Day__c,new List<DealSlotMapping__c>());
    			}
    			mapSlotAlloc.get(sm.Day__c).add(sm);
    		}
    	}
    	return mapSlotAlloc.get(day);
    }
    
    private static EBH_DealSlotAllocation__c[] createSlot(Datetime sloteDate,String countryCode,String dformat)
    {
    	String day = sloteDate.format('EEEE');
    	String yyyyMMdd = sloteDate.format('yyyy-MM-dd');
    	List<EBH_DealSlotAllocation__c> listSlots = new List<EBH_DealSlotAllocation__c>();
    	for(DealSlotMapping__c sMap : getSlotAlloc(day))
	    {
	    	//date + vertical + site id
	    	String extId = yyyyMMdd+sMap.Vertical__c+countryCode;
	    	listSlots.add(
	    		new EBH_DealSlotAllocation__c(External_Id__c=extId,EBH_Date__c=sloteDate.dateGMT(),System_Created__c=true,EBH_Vertical__c=sMap.Vertical__c,EBH_Slots__c=sMap.Slot__c,EBH_Country__c = countryCode,EBH_DealFormat__c=dformat)
	    	);
	    }
    	return listSlots;
    }
    
    /*****************************************************************************************************************************
    @ Method:   populate12WeeksSlot
    @ Version:  1.0
    @ Author: 	Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:	US-0006486 Deals - Masterschedule - Batch Process for Deals Slot Record Creation
	@			AC2) Create a daily new batch to create new EBH_DealSlotAllocation__c Records per day for 12 weeks in advancet by vertical for EBH_Country__c = DE and EBH_DealFormat__c = primary and fill out the following fields:
    @ Event:	once after deployment (manual step)
    @ usate: 	BatchDealSlotAllocation.populate12WeeksSlot(12); //12 weeks (from now on)		
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Coupon__c> listNewCoupon, Map<ID,Coupon__c> mapoldCoupon
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history25.11.2019 / Vadhanak Voun / Created the Method
    *****************************************************************************************************************************/
    public static void populate12WeeksSlot(Integer numOfWeek)
    {
    	Integer numDays = numOfWeek * 7;
    	DateTime dNow = System.Now();
    	DateTime currDate = dNow;
    	
    	List<EBH_DealSlotAllocation__c> listSlotToCreate = new List<EBH_DealSlotAllocation__c>();
    	for(integer d=1;d<=numDays;d++) //12 weeks x 7 days
    	{
    		//6 records per day (each vertical)
    		List<EBH_DealSlotAllocation__c> listSlotByDay = createSlot(currDate,'77',EBH_ConstantsUtility.DEAL_FORMAT_PRIMARY);
    		listSlotToCreate.addAll(listSlotByDay);
    		currDate = currDate.addDays(1);
    	}
    	
    	Database.UpsertResult[] upsertResults = Database.upsert(listSlotToCreate, EBH_DealSlotAllocation__c.External_Id__c,false);//partial success
    	for(Database.UpsertResult r:upsertResults)
    	{
    		if(!r.isSuccess())
    		{
    			EBH_ApexLogger.logError(r.getErrors(), 'BatchDealSlotAllocation','populate12WeeksSlot');
    		}	
    	}
    }
}