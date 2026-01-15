/*********************************************************************************************************************************
@ Class:          RecordNavigatorController
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Generic Navigator class to support navigation through list of records (next/pre) 
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.07.2019 / Vadhanak Voun / Created the class.
*********************************************************************************************************************************/
public without sharing class RecordNavigator{
		
    	String soql;
    	String soql_count = 'Select Count() From ';
    	String fieldOrderBy = 'Name'; //default
    	String orderDirection = 'asc'; //default
    	Integer recordLimit = 100; //default 100 records per view
    	String soql_LimitAndOffset =' limit :recordLimit offset :myOffSet ';
    	
    	List<SObject> listRecord;
    	Integer totalResultCount = 0;
    	
    	Integer totalPage = 0;
    	Integer currentPage = 0; 
 
    	Integer myRequestPage = 1; //default
    	Integer myOffset = 0;
    	String sobj; 
    	String where1;
    	public RecordNavigator(String sobj,String soql,String where1,Integer requestPage)
    	{
    		this.sobj = sobj;
    		this.soql = soql;
    		this.myRequestPage = requestPage;
    		this.where1 = where1;
    		soql_count += sobj;
    		currentPage = requestPage;
    	}
    	
    	
    	public void fetch()
    	{
    	  	System.debug('>>>count: '+soql_count + where1);
    	  	
    	  	totalResultCount 	=  Database.countQuery(soql_count+where1);
    	  	
    	  	calTotalPage();
			
			findOffset();
			System.debug('>>>query: '+soql + where1 + getOrderBy() + soql_LimitAndOffset );
    		listRecord 			= 	Database.query(soql + where1 + getOrderBy() + soql_LimitAndOffset ); 
    		
    	}
    	private String getOrderBy()
    	{	
    		String strFieldOrders = fieldOrderBy.contains(',')?fieldOrderBy.replace(',',' '+orderDirection+','): fieldOrderBy +' '+ orderDirection;
    		return ' order by '+ strFieldOrders;
    	}
    	private void calTotalPage()
    	{
    		if(totalResultCount > 0)
    		{
    			Decimal d = Decimal.valueOf(totalResultCount) / Decimal.valueOf(recordLimit); 
				totalPage = d.round(System.RoundingMode.CEILING).intValue();
    		}
    		
    	}
    	private void findOffset()
    	{
    		myRequestPage = Integer.valueOf(myRequestPage); //convert Integer to Integer (sfdc bug? Internal Salesforce.com Error)
    		myOffset = myRequestPage==0?0:(myRequestPage * recordLimit ) - recordLimit;
    		System.debug('>>>myRequestPage: '+ myRequestPage+' >>recordLimit: '+recordLimit +' >>myOffset: '+ myOffset);
    	}
    	 
    	
    	public List<SObject> getListResult()
    	{
    		return listRecord;
    	}
    	public Integer getTotalResultCount()
    	{
    		return totalResultCount;
    	}
    	public Integer getTotalPage()
    	{
    		return totalPage;
    	}
    	public Integer getCurrentPage()
    	{
    		return currentPage;
    	}
    	
    	public void setRecordPerView(Integer recLimit)
    	{
    		recordLimit = recLimit;
    	}
    	public void setOrderField(String fname)
    	{
    		fieldOrderBy  = fname;
    	}
    	public void setOrderDirection(String direction)
    	{
    		orderDirection = direction;
    	}
    	
    /*****************************************************************************************************************************
	@ Method:   apexDoQuery
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  EPH-7701 Trading Engine. Initiating 1:1 communication
	@			 
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      sobjectName, soql,sWhere , requestPag,itemPerView,fieldOrder, orderDirection
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 20.07.2019/ Vadhanak Voun / Created the  Method. (same name confict in aura)
	@				: 25.08.2019/ Vadhank Voun / fieldOrder, orderDirection
	------------------------------------------------------------------------------------------------------------------------------
	@ Method:   apexDoQuery
	@ Version:  2.0
	@ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
	@ Purpose:  US-0005891 Select All Button on Invetory Diagnostic.
	@			return totalResultCount for component ForwardToSeller.cmp
	@			 
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      sobjectName, soql, sWhere , requestPag, itemPerView, fieldOrder, orderDirection
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 07.07.2020/ Sophal Noch / Modified the Method.
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexDoQuery(String sobjectName,String soql,String sWhere,Integer requestPage,Integer itemPerView,String fieldOrder, String orderDirection)
    {
    	Map<String,Object> mapResult = new Map<String,Object>();
    	RecordNavigator nav = new RecordNavigator(sobjectName,soql,sWhere,requestPage);
    	nav.setRecordPerView(itemPerView);
    	nav.setOrderField(fieldOrder);
    	nav.setOrderDirection(orderDirection);
    	nav.fetch();
    	
    	mapResult.put('listResult',nav.getListResult());
    	mapResult.put('totalPage',nav.getTotalPage());
		mapResult.put('currentPage',nav.getCurrentPage());
		mapResult.put('totalResultCount',nav.getTotalResultCount()); // US-0005891
    	
    	return mapResult;
    } 
    
}