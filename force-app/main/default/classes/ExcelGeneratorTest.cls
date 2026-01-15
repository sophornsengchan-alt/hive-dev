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
private class ExcelGeneratorTest {

    static testMethod void testXLS() {
    	 
    	 Test.startTest();
	         List<List<String>> listRows = new List<List<String>>{
	         	new List<String>{'h1','h2','h3'},
	         	new List<String>{'col1a','col2a','col3a'},
	         	new List<String>{'col1b','col2b','col23b'}};
	         
	        ExcelGenerator.xSheet sheet1 = new ExcelGenerator.xSheet('Sheet1',listRows);
	        List<ExcelGenerator.xSheet> listSheets = new  List<ExcelGenerator.xSheet>();
	    	listSheets.add(sheet1);
	    	
	    	ExcelGenerator generator = new ExcelGenerator('Me',listSheets); 
			generator.generateWorkBook();
			String xml = generator.getWorkbookXML();
		
		Test.stopTest();
		
		System.assertNotEquals(null,xml,'excel as xml generated');
    	
        
    }

	static testMethod void testXLS_1() {
    	 
		Test.startTest();
			List<List<String>> listRows = new List<List<String>>{
				new List<String>{'h1','h2','h3'},
				new List<String>{'col1a','col2a','col3a'},
				new List<String>{'col1b','col2b','col23b'}};
			
		   ExcelGenerator.xSheet sheet1 = new ExcelGenerator.xSheet('Sheet1',listRows);
		   List<ExcelGenerator.xSheet> listSheets = new  List<ExcelGenerator.xSheet>();
		   listSheets.add(sheet1);
		   
		   ExcelGenerator generator = new ExcelGenerator('Me',listSheets,true); 
		   generator.generateWorkBook();
		   String xml = generator.getWorkbookXML();
	   
	   Test.stopTest();
	   
	   System.assertNotEquals(null,xml,'excel as xml generated');
	   
	   
   }
}