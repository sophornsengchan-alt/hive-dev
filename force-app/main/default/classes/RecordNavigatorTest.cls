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
private class RecordNavigatorTest {

    static testMethod void testNav() {
        
        
		Account acc1 = new Account(Name='test acc12312344455');
		Account acc2 = new Account(Name='test acc12312344455');
		Account acc3 = new Account(Name='test acc12312344455');
		Account acc4 = new Account(Name='test acc12312344455');
		List<Account> listAcc = new List<Account>{acc1,acc2,acc3,acc4};
		insert listAcc;
		
		Test.startTest();
			Set<String> setAccId = new Set<String>();
			for(Account acc: listAcc)
			{
				setAccId.add(acc.Id);
			}
			
			String sobjectName = 'Account';
			String soql = 'Select Id,Name From Account ';
			String sWhere = ' Where Name LIKE \'%test%\' ';
			Integer requestPage = 1;
			Integer itemPerView = 2;
			Map<String,Object> mapResult = RecordNavigator.apexDoQuery(sobjectName,soql,sWhere,requestPage,itemPerView,'Name','asc');
			System.assertEquals(2,ApexUtil.toInteger(mapResult.get('totalPage')+''),'2 pages, as 2 records per page');
			
			//next page
			 requestPage = 2;
			 mapResult = RecordNavigator.apexDoQuery(sobjectName,soql,sWhere,requestPage,itemPerView,'Name','asc');
			 
			 RecordNavigator nav = new RecordNavigator(sobjectName,soql,sWhere,requestPage);
			 nav.setRecordPerView(2);
			 nav.setOrderField('Name');
			 nav.setOrderDirection('asc');
			 nav.getTotalResultCount();
			 
		Test.stopTest();
	
         
    }
}