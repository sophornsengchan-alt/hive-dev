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
private class GoToSellerControllerTest {

    static testMethod void testGotoSeller() {
        
		Test.startTest();
			Account acc = new Account(Name='acctest 000001', EBH_OracleID__c = '12345678');
			insert acc;
			
			PageReference pageRef = Page.GoToSeller;
			pageRef.getParameters().put('oid','12345678');
			Test.setCurrentPage(pageRef);
			
			GoToSellerController ctr = new GoToSellerController();
			PageReference p = ctr.gotoSeller();
			
			System.assertNotEquals(null,p,'redirect to correct seller');
		Test.stopTest();
		
        
    }
}