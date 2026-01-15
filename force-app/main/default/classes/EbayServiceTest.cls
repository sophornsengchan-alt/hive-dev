@isTest
private class EbayServiceTest {
     

    @IsTest
    static void testSearchItem(){
        
        Test.startTest();

            String sellerId ='noborie95731';
            String siteId = '0';
            String catId = '58058';
            String brand = 'Creative Media';
            String searchKey = 'BlasterX';
             
        EbayService.SearchService sServiceSearch = new EbayService.SearchService(sellerId,siteId,catId,brand,searchKey,1,20);
        sServiceSearch.sendRequest();
        List<Object> listResult = sServiceSearch.getListObject();
        Object refPage = sServiceSearch.getRefinement();
        sServiceSearch.getResult();
        sServiceSearch.getTotal();

        System.assertEquals(true, sServiceSearch.isSuccess());
        System.assertEquals(true, !listResult.isEmpty());

        EbayService.GetItemService serviceGetItem = new EbayService.GetItemService(siteId,'171575589602');
        serviceGetItem.sendRequest();

        System.assertEquals(true, serviceGetItem.isSuccess());
        System.assertEquals(true, !serviceGetItem.getListObject().isEmpty());

        System.assertEquals('test@test.de',serviceGetItem.getEmail());
        
        //US-0011082:vadhanak:28/04/2022
        EbayService.GetSessionService ssService = new EbayService.GetSessionService('0','eBay_DE_Login');
        ssService.sendRequest();
        String sessionId = ssService.getListObject().isEmpty()?'':ssService.getListObject()[0]+'';
        System.assert(String.isNotBlank(sessionId),'ssesion id returns from ebay');
        
        EbayService.IdentityConfirmService idService = new EbayService.IdentityConfirmService('0','eBay_DE_Login',sessionId);
        idService.sendRequest();
        List<Object> resultID = idService.getListObject();
        System.assertEquals(resultID[0]+'','Success'); //Ack
        System.assertEquals(resultID[1]+'','test_seller007'); //UserID

        Test.stopTest();
        
    }
}