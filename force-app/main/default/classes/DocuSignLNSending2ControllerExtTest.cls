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
private class DocuSignLNSending2ControllerExtTest {

    static testMethod void testSharing() {
    	
        List<User> stdUsers = EBH_TestDataFactory.createUsers(1, 'Standard User');
        List<Account> legalEntities;
        List<Contract> contractsListing;
        ContentVersion att;
        System.runAs(stdUsers[0]) {
             legalEntities = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');
	         contractsListing = EBH_TestDataFactory.createContracts (1, 'Listing Agreement', legalEntities[0].id, legalEntities[1].id);
	        
	         att = EBH_TestDataFactory.createFileAttachment('TestAtt', 'test attach' ,contractsListing[0].Id );
        	
        }
        
       Test.StartTest();
       ContentVersion att2 = EBH_TestDataFactory.createFileAttachment('TestAtt2', 'test attach2' ,contractsListing[0].Id );
         
        
       Map<String,String> result = DocuSignLNSending2ControllerExt.checkAndShareAttachments(contractsListing[0].Id);
       System.assertEquals('ok',result.get('status'),' successful sharing');
       System.assertEquals('1',result.get('newshared'),'1 file sucessfuly shared');
      
       Test.stopTest(); 
    }
	
	static testMethod void testButtonVisible() {
     	
        //MN-29042024-US-0014641--START
        List<User> stdUsers = EBH_TestDataFactory.createUsers(1, 'Standard User');
        List<Account> legalEntities;
        List<Contract> contractsListing;
        ContentVersion att;
        System.runAs(stdUsers[0]) {
             legalEntities = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');
	         contractsListing = EBH_TestDataFactory.createContracts (1, 'Listing Agreement', legalEntities[0].id, legalEntities[1].id);
	        
	         att = EBH_TestDataFactory.createFileAttachment('TestAtt', 'test attach' ,contractsListing[0].Id );
        	
        }
        //MN-29042024-US-0014641--END

     	Test.startTest();
     		PermissionSet ps = new PermissionSet(Name='DocuSign_Administrator',Label='DocuSign_Administrator');
     		insert ps;
     		PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=UserInfo.getUserId(),PermissionSetId=ps.Id);
     		insert psa;
     		
     		Map<String,Object> result = DocuSignLNSending2ControllerExt.handleButtonVisibility(contractsListing[0].Id); //MN-29042024-US-0014641: Changed return type to Map<String,Object>
     		System.assertEquals('ok',result.get('visible'));
     	Test.stopTest();
     }
}