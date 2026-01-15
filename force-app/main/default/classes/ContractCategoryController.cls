/*********************************************************************************************************************************
@ Class:        ContractCategoryController
@ Version:      1.0
@ Author:       Sambath Seng
@ Purpose:      US-0015241 - Create new Contract Category object
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 30.05.2024 / Sambath Seng / Clone from CouponCategoryController
*********************************************************************************************************************************/
public with sharing class ContractCategoryController extends CategoryTreeController {

    private final static String STR_ALL = 'All';
    private final static Integer CAT_TREE_LEVEL_4 = 4;
    private final static Integer CAT_TREE_LEVEL_5 = 5;
    
    private final static String SOQL_CAT_TREE = 'Select Id, Note_ID__c, Name, Level_auto__c' // level 5
    + ', Note_ID__r.Id, Note_ID__r.Name, Note_ID__r.Level_auto__c' // level 4
    + ', Note_ID__r.Note_ID__r.Id, Note_ID__r.Note_ID__r.Name, Note_ID__r.Note_ID__r.Level_auto__c' // level 3
    + ', Note_ID__r.Note_ID__r.Note_ID__r.Id, Note_ID__r.Note_ID__r.Note_ID__r.Name, Note_ID__r.Note_ID__r.Note_ID__r.Level_auto__c' // level 2
    + ', Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Id, Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Name, Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Level_auto__c' // level 1
    + ', Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Id, Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Name, Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Level_auto__c' // level 0
    + ' From Category_Tree__c ';

    private final static Map<Integer, List<PathItem>> MAP_FIELD_PATH_LEVEL {
        get {
            if (MAP_FIELD_PATH_LEVEL == null) {
                MAP_FIELD_PATH_LEVEL = CategoryTreeController.mapFieldPathLevel;
                MAP_FIELD_PATH_LEVEL.putAll(new Map<Integer, List<PathItem>>{
                    4 => new List<PathItem>{new PathItem('Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Name', 'Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Id', 0), new PathItem('Note_ID__r.Note_ID__r.Note_ID__r.Name', 'Note_ID__r.Note_ID__r.Note_ID__r.Id', 1), new PathItem('Note_ID__r.Note_ID__r.Name', 'Note_ID__r.Note_ID__r.Id', 2), new PathItem('Note_ID__r.Name', 'Note_ID__r.Id', 3), new PathItem('Name', 'Id', 4)},
                    5 => new List<PathItem>{new PathItem('Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Name', 'Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Id', 0), new PathItem('Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Name', 'Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Id', 1), new PathItem('Note_ID__r.Note_ID__r.Note_ID__r.Name', 'Note_ID__r.Note_ID__r.Note_ID__r.Id', 2), new PathItem('Note_ID__r.Note_ID__r.Name', 'Note_ID__r.Note_ID__r.Id', 3), new PathItem('Note_ID__r.Name', 'Note_ID__r.Id', 4), new PathItem('Name', 'Id', 5)}
                });
            }
            return MAP_FIELD_PATH_LEVEL;
        }
        set {}
    }

    private static Map<String, String> MAP_CONTRACT_SITE_TO_SITE_ID = new Map<String, String>{
        'DE' => '77',
        'ES' => '186',
        'UK' => '3',
        'FR' => '71',
        'IT' => '101',
        'CH' => '193',
        'AT' => '16',
        'PL' => '212',
        'NL' => '146',
        'US' => '0',
        'AU' => '15',
        'CA' => '2'
    };

    /*****************************************************************************************************************************
    @ Method:   apexQueryCat
    @ Version:  1.0
    @ Author:   Sambath Seng
    @ Purpose:  US-0015241 - Create new Contract Category object
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 30.05.2024 / Sambath Seng / Clone from CouponCategoryController
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> apexQueryCat(String country, String parentContractId, String parentCatId, String textSearch) {
        Map<String, Object> mapResult = new Map<String, Object>();
        String parentId = parentCatId;

        String soql = 'Select Id, Name, EBH_Site__c From Contract Where Id = :contractId Limit 1';
        List<Contract> contr = ApexSafe.query().doQuery(soql, new Map<String, Object>{'contractId' => parentContractId});

        if (String.isBlank(country)) {
            country = MAP_CONTRACT_SITE_TO_SITE_ID.get(contr[0].EBH_Site__c);
            mapResult.put('setSite', true);
            mapResult.put('site', country);
        }

        List<PathItem> listPath = generatePath(parentCatId); 
        mapResult.put('listPath', listPath);
        
        List<CatItem> listCat = doQueryCat(parentCatId, parentContractId, country, textSearch); 
        mapResult.put('listResult', listCat);
        mapResult.put('status', 'ok');
        
        return mapResult;
    }

    /*****************************************************************************************************************************
    @ Method:   doQueryCat
    @ Version:  1.0
    @ Author:   Sambath Seng
    @ Purpose:  US-0015241 - Create new Contract Category object
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 30.05.2024 / Sambath Seng / Clone from CouponCategoryController
    *****************************************************************************************************************************/
    private static List<CatItem> doQueryCat(String parentCatId, String parentContractId, String country, String textSearch) {
        List<CatItem> listCat = new List<CatItem>(); 
        String sWhere = ' Where Active__c = true and Site_auto__c = :country ';
        
        if (String.isNotBlank(parentCatId)) {
            sWhere += ' AND Note_ID__c = :parentCatId ';
        } else {
            sWhere += ' AND Level_auto__c = 0 ';
        }
        
        String sOrder = ' Order By Name';
        
        for (Category_Tree__c cat : (List<Category_Tree__c>) ApexSafe.query().doQuery(SOQL_CAT_TREE + sWhere + sOrder, new Map<String, Object>{'country' => country, 'parentCatId' => parentCatId})) {
            listCat.add(populateItem(cat, parentContractId));
        }
        
        return listCat;	
    }

    /*****************************************************************************************************************************
    @ Method:   generatePath
    @ Version:  1.0
    @ Author:   Sambath Seng
    @ Purpose:  US-0015241 - Create new Contract Category object
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 30.05.2024 / Sambath Seng / Clone from CouponCategoryController
    *****************************************************************************************************************************/
    private static List<PathItem> generatePath(String parentCatId) {
        List<PathItem> listPath = new List<PathItem>(); 
        PathItem ptRoot = new PathItem(STR_ALL, '', -1);
        ptRoot.name = STR_ALL;
        ptRoot.id = '';
        listPath.add(ptRoot);
        String sWhere = ' Where Id = :parentCatId LIMIT 1';
        
        if (String.isNotBlank(parentCatId)) {
            List<Category_Tree__c> parentCat = ApexSafe.query().doQuery(SOQL_CAT_TREE + sWhere, new Map<String, Object>{'parentCatId' => parentCatId});
            Integer currentCatLevel = parentCat[0].Level_auto__c > CAT_TREE_LEVEL_5 ? CAT_TREE_LEVEL_5 : Integer.valueOf(parentCat[0].Level_auto__c);
            
            for (PathItem f : MAP_FIELD_PATH_LEVEL.get(currentCatLevel)) {
                f.name = ApexUtil.getValue(f.fname, parentCat[0]) + '';
                f.id = ApexUtil.getValue(f.fId, parentCat[0]) + '';
                listPath.add(f);
            }
        } 
        
        return listPath;
    }

    /*****************************************************************************************************************************
    @ Method:   apexSaveCat
    @ Version:  1.0
    @ Author:   Sambath Seng
    @ Purpose:  US-0015241 - Create new Contract Category object
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 30.05.2024 / Sambath Seng / Clone from CouponCategoryController
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> apexSaveCat(List<Contract_Category__c> listSelectedCat) {
        Map<String, Object> mapResult = new Map<String, Object>();
        Database.SaveResult[] result = ApexSafe.dml().doInsert(listSelectedCat, true);

        if (result[0].isSuccess()) {
            mapResult.put('status', 'ok');
        } else {
            mapResult.put('status', 'ko');
            mapResult.put('error', result[0].getErrors()[0].getMessage());
            mapResult.put('errorDetail', result[0].getErrors()[0].getMessage());
        }
            
        return mapResult;
    }

    /*****************************************************************************************************************************
    @ Method:   populateItem
    @ Version:  1.0
    @ Author:   Sambath Seng
    @ Purpose:  US-0015241 - Create new Contract Category object
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 30.05.2024 / Sambath Seng / Clone from CouponCategoryController
    *****************************************************************************************************************************/
    private static CatItem populateItem(Category_Tree__c cat, String parentContractId) {
        CatItem parent0;
        
        if (cat.Level_auto__c == CAT_TREE_LEVEL_5) {  
            parent0 = new CatItem(cat.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__c, cat.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Name, null, Integer.valueOf(cat.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Level_auto__c));
        } else if (cat.Level_auto__c == CAT_TREE_LEVEL_4) { 
            parent0 = new CatItem(cat.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__c, cat.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Name, null, Integer.valueOf(cat.Note_ID__r.Note_ID__r.Note_ID__r.Note_ID__r.Level_auto__c));
        } else {
            parent0 = new CatItem(cat.Note_ID__r.Note_ID__r.Note_ID__c, cat.Note_ID__r.Note_ID__r.Note_ID__r.Name, null, Integer.valueOf(cat.Note_ID__r.Note_ID__r.Note_ID__r.Level_auto__c));
        }
        
        CatItem parent2 = new CatItem(cat.Note_ID__c, cat.Note_ID__r.Name, parent0, Integer.valueOf(cat.Note_ID__r.Level_auto__c));
        CatItem catItem = new CatItem(cat.Id, cat.Name, parent2, Integer.valueOf(cat.Level_auto__c));
        catItem.contractCat = new Contract_Category__c(Category__c = cat.Id, Contract__c = parentContractId);
        
        return catItem;
    }
}