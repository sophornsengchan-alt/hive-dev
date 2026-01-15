@isTest
public class menusControllerTest {
    
    @testSetup static void testSetupMethod()
    {
        Menu__c menu = new Menu__c(
            Name='test menu'
        );

        insert menu;

        Menu_Item__c mi1 = new Menu_Item__c(
            Name='MI 1', URL__c='test-mi1', Position__c='1', SLDS_Icon_Position__c='left', Menu__c=menu.Id
        );

        insert mi1;

        Menu_Item__c mi2 = new Menu_Item__c(
            Name='MI 2', URL__c='test-mi2', Position__c='1', SLDS_Icon_Position__c='left', Menu__c=menu.Id,
            Menu_Item__c=mi1.Id
        );

        insert mi2;

        Menu_Item__c mi3 = new Menu_Item__c(
            Name='MI 3', URL__c='test-mi3', Position__c='1', SLDS_Icon_Position__c='left', Menu__c=menu.Id,
            Menu_Item__c=mi2.Id
        );

        insert mi3;

        Menu_Item__c mi4 = new Menu_Item__c(
            Name='MI 4', URL__c='test-mi4', Position__c='1', SLDS_Icon_Position__c='left', Menu__c=menu.Id,
            Menu_Item__c=mi3.Id
        );

        insert mi4;

        Menu_Item__c mi5 = new Menu_Item__c(
            Name='MI 5', URL__c='test-mi5', Position__c='1', SLDS_Icon_Position__c='left', Menu__c=menu.Id,
            Menu_Item__c=mi4.Id
        );

        insert mi5;

        Menu_Item__c mi6 = new Menu_Item__c(
            Name='MI 6', URL__c='test-mi6', Position__c='1', SLDS_Icon_Position__c='left', Menu__c=menu.Id,
            Menu_Item__c=mi5.Id
        );

        insert mi6;
    }

    public static testMethod void test_success_menusController()
    {
        
        
        List<Menu__c> menuList = [SELECT Id FROM Menu__c WHERE Name ='test menu'];
        System.assert(menuList.size() > 0);

        String menuId = menuList[0].Id;

        String menuJSON = menusController.getMenu('nameFilter','','test menu');
        Map<String,Object> menuObjectMap = (Map<String,Object>) System.JSON.deserializeUntyped(menuJSON);
        String treeItemJSON = JSON.serialize(menuObjectMap.get('menu'));
        List<menusController.treeItem> menuItemList = (List<menusController.treeItem>)System.JSON.deserialize(treeItemJSON,List<menusController.treeItem>.class);
        System.assert(menuItemList.size() > 0);

    }

}