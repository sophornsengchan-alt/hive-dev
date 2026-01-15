/*********************************************************************************************************************************
@ Class:        CouponCategoryController
@ Version:      1.0
@ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:      US-0013712 - Add filter on coupon category component
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 14.06.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / Created the class.
                : 27.07.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / US-0013906 - Ensure L4 and L5 categories are visible in component & displayed on portal
*********************************************************************************************************************************/
public with sharing class CouponCategoryController extends CategoryTreeController {

    private final static String STR_ALL = 'All';
    private final static Integer CAT_TREE_LEVEL_4 = 4;
    private final static Integer CAT_TREE_LEVEL_5 = 5;

    // private final static String SOQL_CAT_TREE = 'Select Note_ID__r.Note_ID__r.Note_ID__r.Level_auto__c,Note_ID__r.Note_ID__r.Note_ID__r.Name,Note_ID__r.Note_ID__r.Note_ID__r.Id, Id,Name,Category_ID__c,External_ID__c,Level_auto__c,Site_auto__c,Site__c,Site_Name__c,Note_ID__c,Note_ID__r.Id,Note_ID__r.Name,Note_ID__r.Level_auto__c,Note_ID__r.Note_ID__c,Note_ID__r.Note_ID__r.Id,Note_ID__r.Note_ID__r.Name,Note_ID__r.Note_ID__r.Level_auto__c From Category_Tree__c ';
	
    // 27.07.2023 / Sophal Noch / US-0013906 : organize the query and make query support up to 5 level.
    private final static String SOQL_CAT_TREE = 'Select Id,Note_ID__c,Name,Level_auto__c' // level 5
	+ ',Note_ID__r.Id, Note_ID__r.Name, Note_ID__r.Level_auto__c'+ // level 4
	+ ',Note_ID__r.Note_ID__r.Id, Note_ID__r.Note_ID__r.Name, Note_ID__r.Note_ID__r.Level_auto__c'+ // level 3
	+ ',Note_ID__r.Note_ID__r.Note_ID__r.Id, Note_ID__r.Note_ID__r.Note_ID__r.Name, Note_ID__r.Note_ID__r.Note_ID__r.Level_auto__c'+ // level 2
	+ ',Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Id, Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Name, Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Level_auto__c'+ // level 1
	+ ',Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Id,Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Name, Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Level_auto__c'+ // level 0
	+ ' From Category_Tree__c ';

    // 27.07.2023 / Sophal Noch / US-0013906 : add level 4 and level 5 to path
    private final static Map<Integer,List<PathItem>> MAP_FIELD_PATH_LEVEL{
        get{
            if(MAP_FIELD_PATH_LEVEL == null){
                MAP_FIELD_PATH_LEVEL = CategoryTreeController.mapFieldPathLevel;
                MAP_FIELD_PATH_LEVEL.putAll(new Map<Integer,List<PathItem>>{
                    4 => new List<PathItem>{new PathItem('Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Name','Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Id',0), new PathItem('Note_ID__r.Note_ID__r.Note_ID__r.Name','Note_ID__r.Note_ID__r.Note_ID__r.Id',1),new PathItem('Note_ID__r.Note_ID__r.Name','Note_ID__r.Note_ID__r.Id',2),new PathItem('Note_ID__r.Name','Note_ID__r.Id',3),new PathItem('Name','Id',4)},
                    5 => new List<PathItem>{new PathItem('Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Name','Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Id',0), new PathItem('Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Name','Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Id',1), new PathItem('Note_ID__r.Note_ID__r.Note_ID__r.Name','Note_ID__r.Note_ID__r.Note_ID__r.Id',2),new PathItem('Note_ID__r.Note_ID__r.Name','Note_ID__r.Note_ID__r.Id',3),new PathItem('Note_ID__r.Name','Note_ID__r.Id',4),new PathItem('Name','Id',5)}
                });
            }
            return MAP_FIELD_PATH_LEVEL;
        }
        set{}
    }



    private static Map<String,String> MAP_COUPON_SITE_TO_SITE_ID = new  Map<String,String>{
        'ebay.de' => '77',
        'ebay.es' => '186',
        'ebay.co.uk' => '3',
        'ebay.fr' => '71',
        'ebay.it' => '101',
        'ebay.ch' => '193',
        'ebay.at' => '16',
        'ebay.pl' => '212',
        'ebay.nl' => '146',
        'ebay.com' => '0',
        'ebay.com.au' => '15',
        'ebay.ca' => '2'
    };

    /*****************************************************************************************************************************
    @ Method:   apexQueryCat
    @ Version:  1.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:  US-0013712 - Add filter on coupon category component
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.06.2023 / Sophal Noch / Created the  Method.
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexQueryCat(String country, String parentCouponId,String parentCatId,String textSearch){
    
        Map<String,Object> mapResult = new Map<String,Object>();
        String parentId = parentCatId;

        Coupon__c coupon  = [Select Id, Name, Main_Coupon_Site__c From Coupon__c Where Id =: parentCouponId Limit 1];

        if(String.isBlank(country))
        {
            country = MAP_COUPON_SITE_TO_SITE_ID.get(coupon.Main_Coupon_Site__c);
            mapResult.put('setSite',true);
            mapResult.put('site',country);
        }

        List<PathItem> listPath = generatePath(parentCatId); 
        
        mapResult.put('listPath',listPath);
        
        List<CatItem> listCat = doQueryCat(parentCatId, parentCouponId, country, textSearch); 
        
        mapResult.put('listResult',listCat);
        mapResult.put('status','ok');
        return mapResult;
    }

    private static List<CatItem> doQueryCat(String parentCatId, String parentCouponId, String country, String textSearch)
    {

        List<CatItem> listCat = new List<CatItem>(); 
        String sWhere = ' Where Active__c=true and Site_auto__c=:country ';
        
        // if(String.isNotBlank(textSearch)) // not using search anymore.
        // {
        //     textSearch = '%'+textSearch+'%';
        //     sWhere+= ' AND NAME LIKE :textSearch ';
        // }else 
        if(String.isNotBlank(parentCatId)){
            sWhere+= ' AND Note_ID__c=:parentCatId ';
        }else{
            sWhere+= ' AND Level_auto__c=0 ';
        }
        String sOrder = ' Order By Name';
        
        for(Category_Tree__c cat: Database.query(SOQL_CAT_TREE + sWhere + sOrder))
        {
            listCat.add(
                populateItem(cat, parentCouponId)
            );
        }
        
        return listCat;	
    }

    private static List<PathItem> generatePath(String parentCatId){
        // 27.07.2023 / Sophal Noch / US-0013906 : generate path from level 1 to level 5
        List<PathItem> listPath = new List<PathItem>(); 
        PathItem ptRoot = new PathItem(STR_ALL,'',-1);
        ptRoot.name = STR_ALL;
        ptRoot.id = '';
        listPath.add(ptRoot);
        if(String.isNotBlank(parentCatId)){
            Category_Tree__c parentCat =  Database.query(SOQL_CAT_TREE + ' Where Id=:parentCatId');
            Integer currentCatLevel = parentCat.Level_auto__c > CAT_TREE_LEVEL_5 ? CAT_TREE_LEVEL_5 : Integer.valueOf(parentCat.Level_auto__c);
            for(PathItem f : MAP_FIELD_PATH_LEVEL.get(currentCatLevel)){
                f.name = ApexUtil.getValue(f.fname,parentCat)+'';
                f.id = ApexUtil.getValue(f.fId,parentCat)+'';
                listPath.add(f);
            }
        } 
        return listPath;
    }


    /*****************************************************************************************************************************
    @ Method:   apexSaveCat
    @ Version:  1.0
    @ Author:   Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:  US-0013712 - Add filter on coupon category component
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 14.06.2023 / Sophal Noch / Created the  Method.
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexSaveCat(List<Coupon_Category__c> listSelectedCat)
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        try{	
           insert listSelectedCat;
           mapResult.put('status','ok');        
        }catch(DMLException dex){mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());}
        catch(Exception ex){mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());}
       
        return mapResult;
    }

    private static CatItem populateItem(Category_Tree__c cat, String parentCouponId)
	{
        // CatItem parent0 = new CatItem(cat.Note_ID__r.Note_ID__r.Note_ID__c,cat.Note_ID__r.Note_ID__r.Note_ID__r.Name,null,Integer.valueOf(cat.Note_ID__r.Note_ID__r.Note_ID__r.Level_auto__c));
        CatItem parent0;
		if(cat.Level_auto__c == CAT_TREE_LEVEL_5){  // 27.07.2023 / Sophal Noch / US-0013906 : find level 0 when current level is 5
            parent0 = new CatItem(cat.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__c,cat.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Name,null,Integer.valueOf(cat.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Level_auto__c));
        }else if(cat.Level_auto__c == CAT_TREE_LEVEL_4){ // 27.07.2023 / Sophal Noch / US-0013906 : find level 0 when current level is 4
            parent0 = new CatItem(cat.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__c,cat.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Name,null,Integer.valueOf(cat.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Level_auto__c));
        }else{
            parent0 = new CatItem(cat.Note_ID__r.Note_ID__r.Note_ID__c,cat.Note_ID__r.Note_ID__r.Note_ID__r.Name,null,Integer.valueOf(cat.Note_ID__r.Note_ID__r.Note_ID__r.Level_auto__c));
        }
        
        // CatItem parent1 = new CatItem(cat.Note_ID__r.Note_ID__c,cat.Note_ID__r.Note_ID__r.Name,null,Integer.valueOf(cat.Note_ID__r.Note_ID__r.Level_auto__c));
		CatItem parent2 = new CatItem(cat.Note_ID__c,cat.Note_ID__r.Name,parent0,Integer.valueOf(cat.Note_ID__r.Level_auto__c));

        CatItem catItem = new CatItem(cat.Id,cat.Name,parent2,Integer.valueOf(cat.Level_auto__c));
        catItem.couponCat = new Coupon_Category__c(Category__c = cat.Id, Coupon__c = parentCouponId);
		return catItem;
	}

}