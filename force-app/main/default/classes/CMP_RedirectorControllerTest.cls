@isTest
public class CMP_RedirectorControllerTest {

    static @IsTest
    void testRedirect()
    {
        Map<String,Object> mapResult = CMP_Calc_ControllerTest.setupData();
        List<QuoteLineItem> listItem = new List<QuoteLineItem>();
        listItem.add((QuoteLineItem)mapResult.get('item1'));
        listItem.add((QuoteLineItem)mapResult.get('item2'));

        
        Test.setCurrentPage(Page.CMP_Redirector);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(listItem);
        stdSetController.setSelected(listItem);

        Test.startTest();
            CMP_RedirectorController ctrl = new CMP_RedirectorController(stdSetController);


            String selIds = ctrl.selectedItems;
        Test.stopTest();
        System.assertEquals(2, selIds.split(',').size(),'2 items');
        
    }
    
     
}