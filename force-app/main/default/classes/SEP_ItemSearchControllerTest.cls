@isTest
private class SEP_ItemSearchControllerTest {
     
    @IsTest
    static void testSearchGetController(){
        
        insert new Category_Tree__c(Name='Auto-Parts-and-Vehicles',Category_ID__c='6000',Active__c=True,Level__c=1,Site__c='0',Site_Name__c='US');
        Test.startTest();
        SEP_ItemSearchController.getCategories('0');

        String sellerId ='noborie95731';
            String siteId = '0';
            String catId = '58058';
            String brand = 'Creative Media';
            String searchKey = 'BlasterX';
            
        Map<String,Object> result1 = SEP_ItemSearchController.apexSearch(sellerId, siteId, catId, brand, searchKey, 1, 20);
        System.assertEquals('true', result1.get('isok')+'','response success');
        System.assertEquals(true, ! ((List<Object>)result1.get('listResult')).isEmpty(), 'list item here');

        Map<String,Object> result2 = SEP_ItemSearchController.apexGetItemDetail('0', '171575589602');

        Test.stopTest();
        
    }

    @IsTest
    static void test_fetchSEPGlobalVarWithPrefix(){

        Test.startTest();

            List<Seller_Portal_Global_Variables__mdt> result = SEP_ItemSearchController.fetchSEPGlobalVarWithPrefix('DealSite');

            System.assert( result != null && !result.isEmpty(), 'There should be records in custom metadata Seller_Portal_Global_Variables__mdt.');

        Test.stopTest();

    }
}