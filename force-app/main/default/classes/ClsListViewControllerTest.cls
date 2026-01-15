/*********************************************************************************************************************************
@ Class:          ClsListViewControllerTest
@ Version:        1.0
@ Author:         Sochettra Saing
@ Purpose:        Ability to run test the logic in class ClsListViewController(EBAY-260)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 28.06.2021 / Sochettra Saing / Created the class.
@ Change history: 25.11.2021 / Sovantheany Dim / Update the class.
				: 09.06.2023 / Sambath Seng / Update test class
				: 17.10.2025 / Leon Morocki / US-0033386 - Added tests for hierarchical relationship display
                : 17.10.2025 / Leon Morocki / PMD fixes
*********************************************************************************************************************************/

@isTest
public with sharing class ClsListViewControllerTest {


    static RecordType sellerRecordType;
    static Map<String,RecordType> couponRecordType;
    static Account acc1;
    static Coupon__c c1;
    static Coupon_Seller__c cs1;

    @testSetup
    static void setupData(){

        sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	couponRecordType = ApexUtil.getRecordTypeBySobjectName('Coupon__c');
    	acc1 = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='US');
    	insert acc1;
    	// c1 = new Coupon__c(RecordTypeID = couponRecordType.get(EBH_ConstantsUtility.COUPON_CATEGORYBASE).Id);
        c1 = new Coupon__c(Coupon_ID__c = 'TEST123', Main_Coupon_Site__c = 'ebay.com', RecordTypeID = couponRecordType.get(EBH_ConstantsUtility.COUPON_CATEGORYBASE).Id,Contract_Due_Date__c = System.today()-2, Coupon_Start_Date__c = System.today()+1, Coupon_End_Date__c = System.today() +2);
        insert c1;
    	cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc1.Id);
    	insert cs1;

    }

    @isTest
    static void testMethod1() {


        Test.startTest();
        //TH:25.11.2021: test getMtdObjectName for code coverage
        String objectName = ClsListViewController.getMtdObjectName('My_Deal_Related_List');
        System.assertEquals('EBH_Deal__c',objectName,'Should return correct sobject name');

        //TH:25.11.2021:change to My_Deal_Related_List, previous setting does not exist
        Map<String, Object>  mResult = ClsListViewController.getAllSetting('My_Deal_Related_List');
        System.assertNotEquals(null, mResult, 'getAllSetting should return a result map');
        System.assert(mResult.containsKey('status'), 'Result should contain status key');

        Map<String, Object>  mSearchResult = ClsListViewController.getSearchResult('Test','My_Deal_Related_List','','');
        List<Sobject> lstSobj = (List<Sobject>) mSearchResult.get('listRecord');
        System.assertEquals(0, lstSobj.size(),'List record size should be 0');

        Map<String, Object> mSearchResult2 = ClsListViewController.getSearchResult('Test','Subsidize_Action_Required_DCA','','');
        System.assertNotEquals(null, mSearchResult2, 'Second search result should not be null');
        System.assert(mSearchResult2.containsKey('listRecord'), 'Second search result should contain listRecord key');
        
        Map<String, Object> mapResult = ClsListViewController.fetchActionMetadata('Deal_Contract_Agreement__c','Subsidize_Action_Required_DCA');
        System.assertNotEquals(null, mapResult, 'fetchActionMetadata should return a result map');
        Test.stopTest();
    }

    @isTest
    static void testUpdateContact() {
        Account acc = new Account( Name = 'TestAccount' );
        insert acc;

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false, Portal_Display_Density__c = 'High', FirstName='test fn', LastName='test ln', AccountId=acc.Id, Email = 'test123@test.com');
        insert con;

        Test.StartTest();

        /*String localCode = ClsListViewController.initLocalCode();
        System.debug('>>>>>>> localCode:'+ localCode);
        System.assertEquals('localCode:en', 'localCode:'+localCode);*/
        con.Portal_Display_Density__c = 'Low';
        Map<String, Object>  mResult = ClsListViewController.doUpdateContact(con);

        System.assertEquals('success', mResult.get('status'), 'Contact update should return success status');
        for(Contact c : [SELECT Id, Portal_Display_Density__c FROM Contact WHERE Id =: con.Id]){

            System.assertEquals('Low', c.Portal_Display_Density__c, 'Portal display density should be updated to Low');
        }

        Test.stopTest();
    }

    @isTest
    static void testupdateInterest(){

        setupData();

        List<Id> mList = new List<Id>();
        mList.add(c1.id);

        Map<String,Object> result = ClsListViewController.updateInterest(mList);
        System.assertEquals('success', result.get('status'), 'Update interest should return success status');
    }
    @isTest
    static void testupdateNotInterest(){

        setupData();

        List<Id> myList = new List<Id>();
        myList.add(c1.id);

        Map<String,Object> result = ClsListViewController.updateNotInterest(myList);
        System.assertEquals('success', result.get('status'), 'Update not interest should return success status');
    }

    /*********************************************************************************************************************************
    @ Method:          testGetSearchResultWithHierarchicalRelationship
    @ Purpose:         Test the new hierarchical relationship functionality in getSearchResult method (US-0033386)
    @ Change history:  17.10.2025 / Leon Morocki / US-0033386 - Hierarchical relationship display in Seller Portal list
    *********************************************************************************************************************************/
    @isTest
    static void testGetSearchResultWithHierarchicalRelationship(){
        Test.startTest();
        
        // Test the updated getSearchResult method that now includes Hierarchy_Relationship_Name__c
        Map<String, Object> mSearchResult = ClsListViewController.getSearchResult('Test','My_Deal_Related_List','','');
        
        // Verify that the method returns expected keys including the new hierarchyRelationshipName
        System.assert(mSearchResult.containsKey('query'), 'Result should contain query key');
        System.assert(mSearchResult.containsKey('settingName'), 'Result should contain settingName key');
        System.assert(mSearchResult.containsKey('listRecord'), 'Result should contain listRecord key');
        System.assert(mSearchResult.containsKey('newFilter'), 'Result should contain newFilter key');
        
        System.assert(mSearchResult.containsKey('hierarchyRelationshipName'), 'Result should contain hierarchyRelationshipName key');
        // Verify settingName is returned correctly
        System.assertEquals('My_Deal_Related_List', mSearchResult.get('settingName'), 'Setting name should match');
        
        // Verify the query includes hierarchy subquery when Hierarchy_Relationship_Name__c is present
        String query = (String) mSearchResult.get('query');
        System.assertNotEquals(null, query, 'Query should not be null');
        
        Test.stopTest();
    }


}