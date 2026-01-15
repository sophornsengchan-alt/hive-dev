/*****************************************************************************************************************************
    @ Method:         NewPricingRequestController
    @ Author:         SRONG TIN
    @ Purpose:        US-0016732 - Enhance Pricing Guided flow with Feature Fee steps - Listing Agreement Pricing P1
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.02.2025 / SRONG TIN / Created Class
    @               : 01-04-2025 / Loumang SENG / US-0015677 - Contracts Guided Flow and Contracts User Permission Sets
    @               : 22-05-2025 / Loumang SENG / US-0026099 - Improve Exclusion Category table display in pricing guided flows
    @               : 26-06-2025 / Mony Nou / US-0032850 - Remove ability to manage Pricing and Fee Type outside of guided flow controls
    @               : 25-07-2025 / Mony Nou / US-0033150 - Ability to manage Pricing and Fee Type for VIP & Add New Fee Type
    *****************************************************************************************************************************/
public with sharing class NewPricingRequestController {

    private final static String CPM_RECORDTYPE_METACATEGORY = 'EBH_MetaCategory';
    private final static String CPM_RECORDTYPE_VERITICALLL2 = 'EBH_VerticalL2';
    private final static String CC_RECORDTYPE_PRICING = 'Pricing_Contract_Category'; //MN-25072025-US-0033150
    private final static String CPM_OBJNAME = 'EBH_ContractPricingMatrix__c';
    private final static String CC_OBJNAME = 'Contract_Category__c'; //MN-25072025-US-0033150
    private final static String INCL = '1'; //MN-29052025-US-0033150
    private final static String EXCL = '0'; //MN-29052025-US-0033150
    private final static String MetaCategoryId = ApexUtil.getRecordTypeByName(CPM_OBJNAME,CPM_RECORDTYPE_METACATEGORY).Id;
    private final static String VerticalL2Id = ApexUtil.getRecordTypeByName(CPM_OBJNAME,CPM_RECORDTYPE_VERITICALLL2).Id;
    private final static String QUERY_CATEGORYTREE  = 'SELECT Id, Name,Name_with_Id__c, Category_ID__c,Level__c,Site__c,Level_auto__c FROM Category_Tree__c';//LA-22-05-2025-US-0026099
    private final static String WHERE_CLAUSE_ACP    = ' WHERE Site__c In :siteList AND Active__c = :isActive';//LA-22-05-2025-US-0026099
    private final static String WHERE_CLAUSE_LA     = ' WHERE Site__c In :siteList AND Active__c = :isActive AND Level__c > :cateLevel';//LA-22-05-2025-US-0026099
    private final static String WHERE_SEARCH_ACP    = ' WHERE Site__c In :siteList AND ((Name LIKE :key) OR (Category_ID__c LIKE :key)) AND Active__c = :isActive';//LA-22-05-2025-US-0026099
    private final static String WHERE_SEARCH_LA     = ' WHERE Site__c In :siteList AND ((Name LIKE :key) OR (Category_ID__c LIKE :key)) AND Active__c = :isActive AND Level__c > :cateLevel';//LA-22-05-2025-US-0026099
    private final static String WHERE_SEARCH_WITHCATEGORY_ACP = ' WHERE Site__c In :siteList AND Category_ID__c IN:cateList AND Active__c = :isActive';//MN-26062025-US-0032850
    private final static String WHERE_SEARCH_WITHCATEGORY_LA     = ' WHERE Site__c In :siteList AND Category_ID__c IN:cateList AND Active__c = :isActive AND Level__c > :cateLevel'; //MN-26062025-US-0032850
    private final static String LAST_CLAUSE = ' ORDER BY Site__c, Name Limit :DEFAULT_LIMIT';//MN-26062025-US-0032850
    private static Integer DEFAULT_LIMIT = 25; //MN-26062025-US-0032850
    /*****************************************************************************************************************************
    @ Method:         getCategories
    @ Author:         SRONG TIN
    @ Purpose:        US-0016732 - Enhance Pricing Guided flow with Feature Fee steps - Listing Agreement Pricing P1
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     searchKey, site
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.02.2025 / SRONG TIN / Created Method
    *****************************************************************************************************************************/
    @AuraEnabled
    public static List<EBH_ContractPricingMatrix__c> getCategories(String searchKey, String site,Boolean isChangeSite) {
        // Construct the search key with wildcards
        Set<String> recordTypeIds = new Set<String>{MetaCategoryId, VerticalL2Id};
        String key = '%' + searchKey + '%';
        Boolean isActive = true;
        try {
            // Perform the SOQL query using static SOQL with bind variables
            List<EBH_ContractPricingMatrix__c> category = new List<EBH_ContractPricingMatrix__c>();
            String query = 'SELECT Id, Name, EBH_MetaCategoryL2__c, Store__c, GMVThreshold2__c, GMVThreshold3__c, Tier_2_bps_Discount__c, CurrencyIsoCode, ASPThreshold__c, FixedFVF__c, VariableFVF__c, VariableFVFaboveASPThreshold__c, Tier_3_bps_Discount__c, EBH_Site__c, Category_Level__c, Category_Name__c, Category_Id__c, EBH_ListingFormat__c FROM EBH_ContractPricingMatrix__c';
            String whereClause = ' WHERE ((EBH_L2_Category__r.Name LIKE :key ) OR (EBH_L2_Category__r.Category_ID__c  LIKE :key )) AND EBH_Site__c = :site AND RecordTypeId IN :recordTypeIds AND Active__c = :isActive Limit 25';
            if(isChangeSite || String.isBlank(searchKey)){
                whereClause = ' WHERE EBH_Site__c = :site AND RecordTypeId IN :recordTypeIds AND Active__c = :isActive Limit 25';
            } 
            query += whereClause;
            category = Database.query(query); 
            return category;
        } catch (Exception e) { EBH_ApexLogger.logError(new List<Exception> { e }, 'NewPricingRequestController','getCategories'); throw new AuraHandledException('An error occurred while fetching categories: ' + e.getMessage()); }
    }

    /*****************************************************************************************************************************
    @ Method:         getCategoryTree
    @ Author:         SRONG TIN
    @ Purpose:        US-0016768 - Enhance Pricing Guided flow with Feature Fee steps - Listing Agreement Pricing P1
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     searchKey, site
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.02.2025 / SRONG TIN / Created Method 
    @               : 01-04-2025 / Loumang SENG / US-0015677 - Contracts Guided Flow and Contracts User Permission Sets
    @               : 22-05-2025 / Loumang SENG / US-0026099 - Improve Exclusion Category table display in pricing guided flows
    *****************************************************************************************************************************/
    @AuraEnabled
    public static List<Category_Tree__c> getCategoryTree(List<String> siteList, String searchKey, Boolean isSearchCategory,Boolean isContractLA, Integer cateLevel, List<String> cateList)
    {       
        String key = '%' + searchKey + '%';
        Boolean isActive = true;
        try {

            // Perform the SOQL query using static SOQL with bind variables ORDER BY Site__c, Name
            List<Category_Tree__c> allCategories = new List<Category_Tree__c>();
            List<Category_Tree__c> existedCategories = new List<Category_Tree__c>();
            //String query = 'SELECT Id, Name,Name_with_Id__c, Category_ID__c,Level__c,Site__c,Level_auto__c FROM Category_Tree__c';
            //String whereClause = ' WHERE Site__c In :siteList AND Active__c = :isActive ORDER BY Site__c, Name';
            String whereClause = isContractLA? WHERE_CLAUSE_LA : WHERE_CLAUSE_ACP;//LA-22-05-2025-US-0026099
            if(isSearchCategory){
                whereClause = isContractLA? WHERE_SEARCH_LA : WHERE_SEARCH_ACP;//LA-22-05-2025-US-0026099
                //whereClause = ' WHERE Site__c In :siteList AND ((Name LIKE :key) OR (Category_ID__c LIKE :key)) AND Active__c = :isActive Limit 25';
            }

            //LA-22-05-2025-US-0026099
            //query += whereClause;
            //allCategories = Database.query(query);
            allCategories = Database.query(QUERY_CATEGORYTREE + whereClause + LAST_CLAUSE); //MN-26062025-US-0032850: Added last clause

            if(!isSearchCategory){
                // Group records by Site and limit to 25 per site
                Map<String, List<Category_Tree__c>> groupedCategories = new Map<String, List<Category_Tree__c>>();
                for (Category_Tree__c category : allCategories) {
                    if (!groupedCategories.containsKey(category.Site__c)) {
                        groupedCategories.put(category.Site__c, new List<Category_Tree__c>());
                    }
                    if (groupedCategories.get(category.Site__c).size() < 25) {
                        groupedCategories.get(category.Site__c).add(category);
                    }
                }

                // Combine all limited records into a single list
                List<Category_Tree__c> limitedCategories = new List<Category_Tree__c>();
                for (List<Category_Tree__c> categories : groupedCategories.values()) {
                    limitedCategories.addAll(categories);
                }
                allCategories = limitedCategories;
            }

            if (!cateList.isEmpty()) { //MN-26062025-US-0032850: Check if cateList is not empty
                DEFAULT_LIMIT = cateList.size(); //MN-26062025-US-0032850: Set default limit to the size of cateList
                existedCategories = Database.query(QUERY_CATEGORYTREE + (isContractLA ? WHERE_SEARCH_WITHCATEGORY_LA : WHERE_SEARCH_WITHCATEGORY_ACP) + LAST_CLAUSE); //MN-26062025-US-0032850: Added last clause
                
                Map<String, Category_Tree__c> categoryMap = new Map<String, Category_Tree__c>();
                
                categoryMap.putAll(allCategories);
                categoryMap.putAll(existedCategories);

                allCategories = categoryMap.values();
            }

            return allCategories;
        } catch (Exception e) { EBH_ApexLogger.logError(new List<Exception> { e }, 'NewPricingRequestController','getCategoryTree'); throw new AuraHandledException('An error occurred while fetching categories: ' + e.getMessage()); }
    }

    /*****************************************************************************************************************************
    @ Method:         getContractCategories
    @ Author:         Mony Nou
    @ Purpose:        US-0033150 - Ability to manage Pricing and Fee Type for VIP & Add New Fee Type
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     pricingId, site, queryAllCategoryTree, searchKey, isSearch, cateList, defExclCate
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.07.2025 / Mony Nou / Created Method 
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> getContractCategories (String pricingId, String site, Boolean queryAllCategoryTree, String searchKey, Boolean isSearch, List<String> cateList, List<String> defExclCate) {
        
        Map<String, Object> mapResult = new Map<String, Object>();
        mapResult.put('status','success');

        try {

            String query = '';

            if (!isSearch) {
                query = 'SELECT Id, Category__c, CategoryID__c,CategoryLabel__c, ContractPricing__c, Contratc_Category_Type__c FROM Contract_Category__c WHERE ContractPricing__c =:pricingId AND (Contratc_Category_Type__c =:INCL OR (Contratc_Category_Type__c =:EXCL AND Category__c NOT IN:defExclCate)) ORDER BY Contratc_Category_Type__c';
                Sobject[] contcateList = ApexSafe.query().doQuery(query, new Map<String, Object> {'pricingId' => pricingId, 'INCL' => INCL, 'EXCL' => EXCL, 'defExclCate' => defExclCate});
                
                mapResult.put('ContractCategory', contcateList);

                query = 'SELECT Id, Name,Name_with_Id__c, Category_ID__c,Level__c,Site__c,Site_Name__c, Level_auto__c FROM Category_Tree__c WHERE Active__c = TRUE AND Id in (SELECT Category__c FROM Contract_Category__c WHERE ContractPricing__c =:pricingId AND (Contratc_Category_Type__c =:INCL OR (Contratc_Category_Type__c =:EXCL AND Category__c NOT IN:defExclCate)))';
                Sobject[] selCategories = ApexSafe.query().doQuery(query, new Map<String, Object> {'pricingId' => pricingId, 'INCL' => INCL, 'EXCL' => EXCL, 'defExclCate' => defExclCate});
                mapResult.put('SelectedCategory', selCategories);
            }
            
            if (queryAllCategoryTree) {

                String key = '%' + searchKey + '%';
                String queryKey = (String.isBlank(searchKey))?'':' AND ((Name LIKE :key) OR (Category_ID__c LIKE :key) OR Id IN:cateList)'; 

                query = 'SELECT Id, Name,Name_with_Id__c, Category_ID__c,Level__c,Site__c,Site_Name__c,Level_auto__c FROM Category_Tree__c WHERE Active__c = TRUE AND Site_Name__c=:site'+ queryKey + ' ORDER BY Site__c, Level__c, Name LIMIT 200';
                Sobject[] allCategories = ApexSafe.query().doQuery(query, new Map<String, Object> {'site' => site, 'key' => key, 'cateList' => cateList});
                mapResult.put('AllCategories', allCategories);
            }
            
            String rtPricingContractCategory = ApexUtil.getRecordTypeByName(CC_OBJNAME ,CC_RECORDTYPE_PRICING).Id;
            mapResult.put('ccPricingRT', rtPricingContractCategory);

        } catch (Exception ex) { mapResult.put('status','error'); mapResult.put('error',ex.getMessage()); }

        return mapResult;

    }
}