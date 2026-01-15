/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class CategoryTreeControllerTest {

    static testMethod void testCategorySelection() {
         
        BoB__c bob0 = new BoB__c(Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion');
        insert bob0;
     	
     	Category_Tree__c ct1 = new Category_Tree__c(Name = 'l0',Active__c=true,Site__c='3');
     	insert ct1;
    	Category_Tree__c ct2 = new Category_Tree__c(Name = 'l1',Note_ID__c=ct1.Id,Active__c=true);
    	insert ct2;
    	
		Category_Tree__c ct3 = new Category_Tree__c(Name = 'l2a',Note_ID__c = ct2.Id,Active__c=true);
		insert ct3;
		Category_Tree__c ct4 = new Category_Tree__c(Name = 'l3',Note_ID__c = ct3.Id,Active__c=true);
    	insert ct4;
         	
        Test.startTest();
        	
        	 Map<String,Object> result = CategoryTreeController.apexQueryCat('3',bob0.Id,'','');
        	 System.assertEquals(1,((List<Object>)result.get('listResult')).size(),'1 child below');
         	
         	result = CategoryTreeController.apexQueryCat('',bob0.Id,'','');
        	 System.assertEquals(1,((List<Object>)result.get('listResult')).size(),'1 child below');
        	 
        	 
         	result = CategoryTreeController.apexQueryCat('3',bob0.Id,ct2.Id,'');
         	 System.assertEquals(1,((List<Object>)result.get('listResult')).size(),'2 child below');
         	 
         	result = CategoryTreeController.apexQueryCat('3',bob0.Id,'','l3');
         	 System.assertEquals(1,((List<Object>)result.get('listResult')).size(),'1 result');
         	
         	Map<String,Object> resultSave = CategoryTreeController.apexSaveCat(bob0.Id,new List<String>{ct4.Id});
         	System.assertEquals('ok',resultSave.get('status'),'save success');
         	
         	
         	CategoryTreeController.CatItem item = new CategoryTreeController.CatItem();
         	item.catId = 'xxxx';
         	item.catName = 'test';
         	item.parent = null;
         	item.level = 0;
         	
         	CategoryTreeController.PathItem pItem = new CategoryTreeController.PathItem();
         	pItem.name = 'tst';
         	pItem.fname = 'Name';
         	pItem.id = 'xxxx';
         	pItem.fId = 'Id';
         	pItem.level = 0;
         	
         Test.stopTest();
        
    }
}