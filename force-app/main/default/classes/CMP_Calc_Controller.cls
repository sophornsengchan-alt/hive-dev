/*********************************************************************************************************************************
@ Class:        CMP_Calc_Controller
@ Version:      1.0
@ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:      Controller for aura: CMP_Calc
@               US-0007824 - EU Advertising CPM Calculator
@               replicated from TKPCalculator.page/TKPCalculatorController.cls
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.07.2020 / Vadhanak Voun / Created the Class.
@               : 01.06.2021/ vadhanak Voun / US-0009612 - [Ads 2020] Change to booking service
*********************************************************************************************************************************/
public without sharing class CMP_Calc_Controller {
	
	static final List<String> LIST_FIELD_QUOTE  = new List<String>
	{
		'Id',
		'Name',
		'QuoteNumber',
        'LineItems_Sort_Type__c',
        'CurrencyISOCode'		 
	};
	static final List<String> LIST_FIELD_QITEM = new List<String>
	{
		'AE__c',
		'Amount_Net_Net_Net__c',
		'Target_CPM__c',
		'Billing_Category__c',
		'Rate_Card_Discount_percent__c',
		'Rate_Card_Discount__c',
		'Special_Agency_Discount__c',
		'Special_Agency_Discount_shadow__c',
		'Rate_Discount_I__c',
		'Rate_Discount_II__c',
		'Rebate_In_Kind__c',
		'Rebate_In_Kind_Reason__c',
		'IsWallpaper__c',
		'until_Date__c',
		'from_Date__c',
		'Special_Agency_Discount_Percent__c',
		'Period__c',
		'Targeting_Type__c',
		'Targeting_Fee2__c',
		'Boomerang__c',
		'Number_of_Targeting_Criteria__c',
		'Discrepancy_Special_Agency__c',
		'Gross_CPM__c',
		'CPM_net__c',
		'Amount_Net__c',
		'CPM_net_net_net__c',
		'Package_Line_Item__c',
		'UnitPrice',
		'Quantity',
		'QuoteId',
		'LineNumber',
		'Description',
		'Product2.RecordType.Name',
		'Quote.OpportunityId',
		'Product2.Name',
		'Product2.Variable_CPM_price__c',
		'Product2.PlacementDB__r.Name',
        'Product2.Advertising_Medium__r.Name',
		'Id',
        'SalesPriceNet__c'	 
	};
    public static final String BILLING_CAT_FIXPRICE = 'Fix Price' ;
    public static final String BILLING_CAT_CPO = 'CPO';
    
    /*****************************************************************************************************************************
	@ Method:   apexInitCMP
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  US-0007824 - EU Advertising CPM Calculator
	@			init
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      parentId: parent  
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 06.07.2020 / Vadhanak Voun / Created the  Method.
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexInitCMP(String parentId,String selectedItem)
    {
		List<String> listSelected = String.isBlank(selectedItem)?new List<String>():selectedItem.split(',');
		String soqlQ = 'Select ' + String.join(LIST_FIELD_QUOTE,',') + ' From QUOTE Where Id=:parentId';
        String swhereItem = String.isBlank(selectedItem) ? ' Where QuoteId =:parentId AND package_line_item__c=null ' : ' Where Id IN:listSelected '; 
        
		
        
        Quote q = Database.query(soqlQ);
        //String strOrderBy = ('Manually'.equals(q.LineItems_Sort_Type__c) ? ' ORDER BY SortOrder' : ' ORDER BY from_date__c ASC');
        String strOrderBy = ' ORDER BY SortOrder__c ASC' ;
        
        String soqlQitem = 'Select '+String.join(LIST_FIELD_QITEM,',') +' From QuoteLineItem '+swhereItem+strOrderBy ;  

		System.debug('--parentId: '+parentId + ' selectedItem: ' + selectedItem);
		System.debug('--soqlQ: '+soqlQ);
		System.debug('--soqlQitem: '+soqlQitem);
		List<LineItem> listItem = new List<LineItem>();
		for(QuoteLineItem qitem : Database.query(soqlQitem))
		{
            //system.debug('>>>item:' +  JSON.serialize(qitem));
			listItem.add(new LineItem(qitem));
		}

		Map<String,Object> mapResult = new Map<String,Object>();
        mapResult.put('listItem',listItem);
        mapResult.put('quote',q);
        mapResult.put('pkl_Rebate_In_Kind_Reason__c',ApexUtil.getPicklistValues(QuoteLineItem.Rebate_In_Kind_Reason__c));
		mapResult.put('status','ok');

        return mapResult;
	}
	 
	 /*****************************************************************************************************************************
	@ Method:   apexSaveItems
	@ Version:  1.0
	@ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
	@ Purpose:  US-0007824 - EU Advertising CPM Calculator
    @			save items
    @           replicated from TKPCalculatorController.updateOlis()
	------------------------------------------------------------------------------------------------------------------------------
	@ Parameter:      parentId: parent  
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 13.07.2020 / Vadhanak Voun / Created the  Method.
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexSaveItems(String parentId,String jsonListItems)
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        //system.debug('--jsonListItems: '+jsonListItems);

        try 
        { 
            List<LineItem> listItems = ( List<LineItem>)JSON.deserialize(jsonListItems, List<LineItem>.class);

            Map<String,QuoteLineItem> mapItemAll = new Map<String,QuoteLineItem>();
            Map<String, List<QuoteLineItem>> mapPackageOlis = new Map<String, List<QuoteLineItem>>();//to get related pkg                
            
            for (LineItem item : listItems) 
            {
                mapItemAll.put(item.oli.Id,item.oli);    
                //system.debug('>>>item.oli.Product2.RecordType.Name: '+item.oli.Product2.RecordType.Name);             
                if (item.oli.Product2.RecordType.Name == 'Package') //PricebookEntry.Product2.RecordType.Name
                {
                    mapPackageOlis.put(item.oli.Id,null);
                }
            }
            //system.debug('>>>mapPackageOlis: '+mapPackageOlis.size());
            if (!mapPackageOlis.isEmpty()) 
            {
                Set<String> setCurrentOLI = mapPackageOlis.keySet();
                String soql_q_pkgWhere = ' Where package_line_item__c IN :setCurrentOLI order by package_line_item__c';
                String soqlQitem = 'Select '+String.join(LIST_FIELD_QITEM,',') +' From QuoteLineItem '+soql_q_pkgWhere;

                for (QuoteLineItem oli : Database.query(soqlQitem)) 
                {
                    List<QuoteLineItem> lst = mapPackageOlis.get(oli.package_line_item__c);
                    if (lst == null) 
                    {
                        lst = new List<QuoteLineItem>{oli};                         
                        mapPackageOlis.put(oli.package_line_item__c, lst);
                    } else 
                    {
                        lst.add(oli);
                    }
                }

                for (Id oid : mapPackageOlis.keySet()) 
                {
                    if (mapPackageOlis.get(oid) != null) 
                    {                         
                        if (mapPackageOlis.get(oid) != null && mapPackageOlis.get(oid).size() > 0) 
                        {
                            for (QuoteLineItem oli :mapPackageOlis.get(oid)) 
                            {
                                if (mapItemAll.get(oli.package_line_item__c) != null) 
                                {
                                    oli.SalesPriceNet__c = mapItemAll.get(oli.package_line_item__c).SalesPriceNet__c;
                                    oli.Quantity = mapItemAll.get(oli.package_line_item__c).Quantity;
                                    if (oli.Billing_category__c == BILLING_CAT_FIXPRICE || oli.Billing_category__c == BILLING_CAT_CPO) 
                                    {
                                        oli.SalesPriceNet__c = oli.SalesPriceNet__c / mapPackageOlis.get(oid).size();
                                    } else 
                                    {
                                        oli.Quantity = Math.floor(oli.Quantity / mapPackageOlis.get(oid).size());
                                    }
                                    oli.Rebate_In_Kind_Reason__c = mapItemAll.get(oli.package_line_item__c).Rebate_In_Kind_Reason__c;
                                    oli.Rate_Card_Discount_percent__c = mapItemAll.get(oli.package_line_item__c).Rate_Card_Discount_percent__c;
                                    oli.Rate_Discount_I__c = mapItemAll.get(oli.package_line_item__c).Rate_Discount_I__c;
                                    oli.Rate_Discount_II__c = mapItemAll.get(oli.package_line_item__c).Rate_Discount_II__c;
                                     
                                    oli.UnitPrice = oli.SalesPriceNet__c;

                                    mapItemAll.put(oli.Id, oli);
                                }
                            }
                        }   
                    }
                }
            }
            
            if (!mapItemAll.isEmpty()) 
            {
                update mapItemAll.values();
            }

            mapResult.put('status','ok');
            
        }catch(DMLException dex)
        {
            mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
        }
        catch(Exception ex)
        {
            mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
        }


        return mapResult;
    }

    @testVisible
	class LineItem {
		@AuraEnabled
			public QuoteLineItem oli;
		@AuraEnabled
			public Decimal targetCPM;
		@AuraEnabled
        	public Decimal budget;
		@AuraEnabled
			public Decimal grossPrice; 
		@AuraEnabled
			public Decimal cPMnnn;

        @AuraEnabled
			public Boolean editableUnitPrice;
        public LineItem(){}   

        public LineItem (QuoteLineItem lineItem) {
            this.oli = lineItem;
			init();
			 
        }
        public void init()
        {
            targetCPM = 0;
            budget = 0;
            oli.Rate_Discount_II__c = oli.Rate_Discount_II__c == null ? 0 : oli.Rate_Discount_II__c.setScale(2);
            grossPrice = ((oli.SalesPriceNet__c==null?0:oli.SalesPriceNet__c) + (oli.Targeting_fee2__c==null?0:oli.Targeting_fee2__c)) * oli.Quantity; 
            editableUnitPrice = oli.Product2.Variable_CPM_price__c;
        }		 
    }
}