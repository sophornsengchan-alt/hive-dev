/*****************************************************************************************************************************
    @ Method:         NewEbayLivePricingControllerTest
    @ Author:         Mony Nou
    @ Purpose:        US-0033112 - eBay Live: Pricing Guided Flow - Part 1 - Test Class
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.08.2025 / Mony Nou / Created Test Class
    *****************************************************************************************************************************/
@isTest
public class NewEbayLivePricingControllerTest {
    
    @isTest
    static void testJoinStrings() {
        // Test Case: Join multiple strings
        NewEbayLivePricingController.Request request1 = new NewEbayLivePricingController.Request();
        request1.values = new List<String>{'Category1', 'Category2', 'Category3', 'Category4'};
        
        List<NewEbayLivePricingController.Request> requests = new List<NewEbayLivePricingController.Request>{request1};
        
        Test.startTest();
        List<String> results = NewEbayLivePricingController.joinStrings(requests);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('Category1;Category2;Category3;Category4', results[0], 'Should join strings with semicolon');
    }
    
}