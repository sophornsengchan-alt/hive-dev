/*********************************************************************************************************************************
@ Class:          GoToSellerController
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Congtroller for page: GoToSeller
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 29.04.2019 / Vadhanak Voun / Created the class.
*********************************************************************************************************************************/
public without sharing class GoToSellerController {
    public String oracleId {get;set;}
    private String sellerId {get;set;}
    
    //Constructor
    public GoToSellerController()
    {
    	oracleId  = ApexPages.currentPage().getParameters().get('oid');
    	oracleId = String.isBlank(oracleId)?null: String.escapeSingleQuotes(oracleId.trim());
    	 
    	if(String.isNotBlank(oracleId))
    	{
    		String soqlSeller = EBH_ConstantsUtility.TCC_SELACC +' WHERE EBH_OracleID__c =:oracleId';
	    	for(Account acc: Database.query(soqlSeller))
	    	{
	    		sellerId = acc.Id; 
	    	}
    	}
    	
    }
    
    /********************************************************************************************************************************************
	@ Method:         gotoSeller
	@ Version:        1.0
	@ Author:         Vadhanak Voun 
	@ Purpose:       EPH-7398 Create a VF page to create a deep link based on Oracle ID
	---------------------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 29.04.2019 / Vadhanak Voun / Created the  Method.
	********************************************************************************************************************************************/
    public PageReference gotoSeller()
    {
    	 
    	PageReference newPage = null;
    	if(String.isNotBlank(sellerId))
    	{
    		newPage = new PageReference('/lightning/r/Account/'+sellerId+'/view');
    		newPage.setRedirect(true);
    		 
    	}
    	
    	return newPage;
    }
}