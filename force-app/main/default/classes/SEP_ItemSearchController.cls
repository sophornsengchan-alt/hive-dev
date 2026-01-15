/*********************************************************************************************************************************
@ Interface:     SEP_ItemSearchController
@ Version:       1.0
@ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       US-0009877 - [SEP-EU] Item Listing for the Deals creation for EU Deals
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 15.09.2021 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / US-0009877
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.11.2021 / Mony Nou (mony.nou@gaea-sys.com) / US-0010805
@                 15.02.2024 / Mony Nou / US-0014491 - [Tech Debt] Remove dependency from URL Domain and replace with SP Main Domain Field in SEP Features
*********************************************************************************************************************************/
public with sharing class SEP_ItemSearchController {     

   
    @AuraEnabled    
    public static Map<String,Object> getCategories(String siteId)
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        List<Object> listCats = new List<Object>();
        for(Category_Tree__c cat : [Select Id,Name,Category_ID__c,Level__c From Category_Tree__c Where Level__c=1 AND Site__c=:siteId and Active__c=True])
        {
            listCats.add(
                new Map<String,String>{'label'=>cat.Name,'value'=>cat.Category_ID__c}
            );
        }
        mapResult.put('listCats',listCats);
        return mapResult;
    }

    // @AuraEnabled    
    // public static Map<String,Object> apexSearch(String sellerId,String siteId,String catId,String brand,String searchKey,Integer requestPage, Integer searchLimit)
    // {
    //     String ebaySiteKey = EbayService.MAP_EBAY_SITE.containsKey(siteId)?EbayService.MAP_EBAY_SITE.get(siteId):EbayService.MAP_EBAY_SITE.get('0'); 
    //     Map<String,Object> mapResult = new Map<String,Object>();

    //     //String sellerId = getCurrentSellerId();
    //     EbayService.SearchService sService = new EbayService.SearchService(sellerId,siteId,catId,brand,searchKey,requestPage,searchLimit);
    //     sService.sendRequest();
    //     List<Object> listResult = sService.getListObject();
        
    //     //system.debug('---items: '+listResult);
    //     mapResult.put('isok',sService.isSuccess());
    //     mapResult.put('msg',sService.getResult());        
    //     mapResult.put('listResult',listResult);
 

    //     mapResult.put('pagination',sService.getPage());
 
        
    //     return mapResult;
    // }

    /*********************************************************************************************************************************
    @ Method:     apexSearch
    @ Version:       1.0
    @ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:       US-0010734 - [SP - EU Deals] [Bug] Upgrade the API to get all the products under the Brand filter. Fix issue with Brand filter on Item Picker
    @----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27.11.2021 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / US-0010734: for new search (browse api)
    *********************************************************************************************************************************/
    @AuraEnabled    
    public static Map<String,Object> apexSearch(String sellerId,String siteId,String catId,String brand,String searchKey,Integer searchOffset, Integer searchLimit)
    {
        String ebaySiteKey = EbayService.MAP_EBAY_SITE.containsKey(siteId)?EbayService.MAP_EBAY_SITE.get(siteId):EbayService.MAP_EBAY_SITE.get('0'); 
        Map<String,Object> mapResult = new Map<String,Object>();

        //String sellerId = getCurrentSellerId();
        EbayService.SearchService sService = new EbayService.SearchService(sellerId,siteId,catId,brand,searchKey,searchOffset,searchLimit);
        sService.sendRequest();
        List<Object> listResult = sService.getListObject();
        Boolean isOk = sService.isSuccess();
        //system.debug('---items: '+listResult);
        mapResult.put('isok',isOk);
        mapResult.put('msg',isOk?'':(Object)sService.getResult());        
        mapResult.put('listResult',listResult); 

        mapResult.put('refinement',sService.getRefinement());
        mapResult.put('total',sService.getTotal());
        
        return mapResult;
    }
     
    @AuraEnabled    
    public static Map<String,Object> apexGetItemDetail(String siteId,String itemId)
    {
        Map<String,Object> mapResult = new Map<String,Object>();

        EbayService.GetItemService service = new EbayService.GetItemService(siteId,itemId);
        service.sendRequest();
        mapResult.put('status',service.isSuccess());
        mapResult.put('result',service.getListObject());
         
        mapResult.put('email',service.getEmail());
        
        
        return mapResult;

    }


    /**
     * Author: Mony Nou
     * Date :  23.11.2021 - US-0010805
     * Description: To get Custom Metadata Seller_Portal_Global_Variables__mdt's records via Prefix that assigned in DeveloperName field
     *  @param  String, prefix before underscore that we use in DeveloperName field of each records
        @return List<Seller_Portal_Global_Variables__mdt>
        @change log:
            27/04/2023/ vadhanak voun/ US-0013088 - DE - Visibility of the DRC - V1 for DE Seller Portal Domain
            15/02/2024/ Mony Nou/ US-0014491 - [Tech Debt] Remove dependency from URL Domain and replace with SP Main Domain Field in SEP Features
     */
    @AuraEnabled ( cacheable=true )   
    public static List<Seller_Portal_Global_Variables__mdt> fetchSEPGlobalVarWithPrefix(String prefix) {        
        
        //String curDomain = (ApexUtil.runningInASandbox())?System.Label.SEP_Current_Sandbox_Domain:ApexUtil.getDomain(); //MN-15022024-US-0014491
        String curDomain = !Test.isRunningTest()? SEP_Helper.getSPMainDomain():SEP_Helper.SEP_Domain_FR; //MN-15022024-US-0014491

        Boolean checkDomain = (prefix=='DealSite');//picklist Site default to current domain and a single Site (not allow to sellect) US-0013088
        
        String tmp = (String.isNotBlank(prefix)?prefix.trim():'') + '%';
        //List<Seller_Portal_Global_Variables__mdt> fetchMeta = [SELECT Id, Label, Value__c, DeveloperName FROM Seller_Portal_Global_Variables__mdt WHERE DeveloperName like:tmp Order By Label];
        //return fetchMeta;

        List<Seller_Portal_Global_Variables__mdt> fetchMeta = new List<Seller_Portal_Global_Variables__mdt>();
        for(Seller_Portal_Global_Variables__mdt meta:[SELECT Id, Label, Value__c, DeveloperName,For_Domains__c FROM Seller_Portal_Global_Variables__mdt WHERE DeveloperName like:tmp Order By Label])
        {   
            //if metadata record is for a specific domain?
            //ignore blank (consider match)
            if(checkDomain && (String.isNotBlank(meta.For_Domains__c) && !meta.For_Domains__c.contains(curDomain))) continue;
             
            fetchMeta.add(meta);
        }
        return fetchMeta;
    }

    // private static String getCurrentSellerId()
    // {
    //     return 'mw-live';//'newshoeboutique';
    //     //[select Name from Account where Id = User.Contact.AccountId]        
    // }
}