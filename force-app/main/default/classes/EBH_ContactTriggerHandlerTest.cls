/*********************************************************************************************************************************
@ Class:          EBH_ContactTriggerHandlerTest
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Test class for EBH_ContactTriggerHandler class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 28.09.2017 / NEHA LUND / Created the test class.
02/05/2018 / DSTN/ test countNumberOfContactsWithIssues
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_ContactTriggerHandlerTest {
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND (jmondol@deloitte.co.uk)
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {       
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testUpdateCustomRollUp(); }        
    }
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SU
    @ Version:        1.0
    @ Author:         NEHA LUND (jmondol@deloitte.co.uk)
    @ Purpose:        Profile testing for Standard User
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SU() {
        System.runAs(EBH_TestDataFactory.createUser('Standard User')) { testUpdateCustomRollUp(); }
    }
    
    /*****************************************************************************************************************************
    @ Method:         testUpdateCustomRollUp
    @ Version:        1.0
    @ Author:         NEHA LUND (jmondol@deloitte.co.uk)
    @ Purpose:        TEST CASE (*) System should be able to rollup the following fields in sellers to its legal entity 
                                    (which is a one to many relationship of one level of depth) 
                                    on insert and update and reparenting:
                                     - GMV
                                     - Revenue 
                                     - Sold Items
                      COVERAGES (*) updateCustomRollUp(): Updates custom roll ups on legal entity from child sellers 
                                        |___hasRollupChanged(): Checks field change in seller
                                        |___hasParentChanged(): Checks parent change in seller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testUpdateCustomRollUp() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();     
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

        Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            
            
            /*Excecute test*/
            try{
            Map<String, AccountContactRelation> testDataMap = EBH_TestDataFactory.setupAccountContactTriggerHandlerData();     
        List<Contact> contacts= [SELECT id from Contact];
            
            contacts[0].EBH_Status__c = 'Deleted';
            
            update contacts[0];
           
            
            contacts[0].EBH_DataOrigin__c = 'DW';
            update contacts[0];
             }
            catch(Exception e){
            }
            
            /*Validate test*/
            //System.assertEquals( 'Confirmed', [SELECT EBH_Status__c from Contact limit 1].EBH_Status__c);
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            
            /*Excecute test*/
            
            /*Validate test*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
            /*Modify data for test*/             
            
            /*Excecute test*/
            
            /*Validate test*/
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
        Test.stopTest();
    }
    
    /*****************************************************************************************************************************
    @ Method:         testcountNumberOfContactsWithIssues
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        EPH-5630 Seller - Quality & Preference
    					Number of Contacts with Issues = COUNT number of Contacts that are not Green 
    					Contact Data Quality =	"Red" =Seller has 0 Contacts with Contact Data Quality equal to "Green".
										"Amber" = Seller has 1 or more Contacts not Green, but at least 1 Contact that is Green
										"Green" = All Contacts of the Seller are Green
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.05.2018 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testcountNumberOfContactsWithIssues(){
    		EBH_TestDataFactory.setUpCustomSettings();
    		List<Account> lstAcc = EBH_TestDataFactory.createAccounts(1,'EBH_Seller');
    		/**EPH-5629 Contact - Quality & Preference
    		 *Contact Data Quality : IF <email-bounced> or <incorrect phone number> Then "Red" Otherwise "Green" */
    		 
    		 List<Contact> lstCont = new List<Contact>();
    		for(Integer i = 0; i < 5; i++){
    			Contact con = new Contact(LastName = 'testCount' + i, AccountId = lstAcc[0].Id, EBH_DataOrigin__c='test',EBH_Status__c='Active');
    			con.Email_Bounced__c = false;
    			con.Incorrect_Phone_Number__c = false;
    			lstCont.add(con);
    		}
    		Test.startTest();
    			insert lstCont;
    			List<Account> lstAccSel = [select Number_of_Contacts_with_Issues__c,Contact_Data_Quality__c from Account where id iN: lstAcc];
			Test.stopTest();
			
			System.assertEquals(0,lstAccSel[0].Number_of_Contacts_with_Issues__c,'0 Number of contact that are not green');
			System.assertEquals(EBH_ConstantsUtility.GREEN_CONTACT,lstAccSel[0].Contact_Data_Quality__c,'All Contacts of the Seller are Green => Green');
			
    }
    
    /*****************************************************************************************************************************
    @ Method:         testRedAccount
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        EPH-5630 Seller - Quality & Preference
    					Number of Contacts with Issues = COUNT number of Contacts that are not Green 
    					Contact Data Quality =	"Red" =Seller has 0 Contacts with Contact Data Quality equal to "Green".
										"Amber" = Seller has 1 or more Contacts not Green, but at least 1 Contact that is Green
										"Green" = All Contacts of the Seller are Green
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.05.2018 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testRedAccount(){
    	EBH_TestDataFactory.setUpCustomSettings();
    	List<Account> lstAcc = EBH_TestDataFactory.createAccounts(1,'EBH_Seller');
    	List<Contact> lstCont = new List<Contact>();
		for(Integer i = 0; i < 5; i++){
			Contact con = new Contact(LastName = 'testCount' + i, AccountId = lstAcc[0].Id, EBH_DataOrigin__c='test',EBH_Status__c='Active');
			con.Email_Bounced__c = true;
			con.Incorrect_Phone_Number__c = false;
			lstCont.add(con);
		}
    	Test.startTest();
    	insert lstCont;
    	
    	
		List<Account> lstAccSel2 = [select Number_of_Contacts_with_Issues__c,Contact_Data_Quality__c from Account where id iN: lstAcc];
		System.assertEquals(5,lstAccSel2[0].Number_of_Contacts_with_Issues__c,'5 Number of contact that are not green');
		System.assertEquals(EBH_ConstantsUtility.RED_ACCOUNT,lstAccSel2[0].Contact_Data_Quality__c,'All Contacts of the Seller are Red => Red');
    }
    
    /*****************************************************************************************************************************
    @ Method:         testAmberAccount
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        EPH-5630 Seller - Quality & Preference
    					Number of Contacts with Issues = COUNT number of Contacts that are not Green 
    					Contact Data Quality =	"Red" =Seller has 0 Contacts with Contact Data Quality equal to "Green".
										"Amber" = Seller has 1 or more Contacts not Green, but at least 1 Contact that is Green
										"Green" = All Contacts of the Seller are Green
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.05.2018 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testAmberAccount(){
    	EBH_TestDataFactory.setUpCustomSettings();
    	List<Account> lstAcc = EBH_TestDataFactory.createAccounts(1,'EBH_Seller');
    	List<Contact> lstCont = new List<Contact>();
		for(Integer i = 0; i < 5; i++){
			Contact con = new Contact(LastName = 'testCount' + i, AccountId = lstAcc[0].Id, EBH_DataOrigin__c='test',EBH_Status__c='Active');
			con.Email_Bounced__c = true;
			con.Incorrect_Phone_Number__c = false;
			lstCont.add(con);
		}
    	Test.startTest();
    	insert lstCont;
    	lstCont[0].Email_Bounced__c = false;
		update lstCont;
    	Test.stopTest();
    	
    	List<Account> lstAccSel3 = [select Number_of_Contacts_with_Issues__c,Contact_Data_Quality__c from Account where id iN: lstAcc];
		System.assertEquals(4,lstAccSel3[0].Number_of_Contacts_with_Issues__c,'4 Number of contact that are not green and 1 contact is green');
		System.assertEquals(EBH_ConstantsUtility.AMBER_ACCOUNT,lstAccSel3[0].Contact_Data_Quality__c,'Seller has 1 or more Contacts not Green, but at least 1 Contact that is Green => Amber');
    }
    
    /*****************************************************************************************************************************
    @ Method:         testDeleteAndUnDeleteOneOfAmberContact
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        EPH-5630 Seller - Quality & Preference
    					Number of Contacts with Issues = COUNT number of Contacts that are not Green 
    					Contact Data Quality =	"Red" =Seller has 0 Contacts with Contact Data Quality equal to "Green".
										"Amber" = Seller has 1 or more Contacts not Green, but at least 1 Contact that is Green
										"Green" = All Contacts of the Seller are Green
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.05.2018 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testDeleteAndUnDeleteOneOfAmberContact(){
	    EBH_TestDataFactory.setUpCustomSettings();
		RecordType contactRecTypeManual = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
		List<Account> lstAcc = EBH_TestDataFactory.createAccounts(1,'EBH_Seller');
		List<Contact> lstCont = new List<Contact>();
		for(Integer i = 0; i < 5; i++){
			Contact con = new Contact(LastName = 'testCount' + i, AccountId = lstAcc[0].Id, EBH_DataOrigin__c='test',EBH_Status__c='Active');
			con.RecordTypeId = contactRecTypeManual.Id;
			con.Email_Bounced__c = true;
			con.Incorrect_Phone_Number__c = false;
			lstCont.add(con);
		}
		Test.startTest();
		insert lstCont;
		lstCont[0].Email_Bounced__c = false;
		update lstCont;
		delete lstCont[0];
		Test.stopTest();
    	
		List<Account> lstAccSel4 = [select Number_of_Contacts_with_Issues__c,Contact_Data_Quality__c from Account where id iN: lstAcc];
		System.assertEquals(4,lstAccSel4[0].Number_of_Contacts_with_Issues__c,'4 Number of contact that are not green');
		System.assertEquals(EBH_ConstantsUtility.RED_ACCOUNT,lstAccSel4[0].Contact_Data_Quality__c,'All Contacts of the Seller are Red => Red');
    	
    	undelete lstCont[0];
		List<Account> lstAccSel5 = [select Number_of_Contacts_with_Issues__c,Contact_Data_Quality__c from Account where id iN: lstAcc];
		System.assertEquals(4,lstAccSel5[0].Number_of_Contacts_with_Issues__c,'4 Number of contact that are not green and 1 contact is green');
		System.assertEquals(EBH_ConstantsUtility.AMBER_ACCOUNT,lstAccSel5[0].Contact_Data_Quality__c,'Seller has 1 or more Contacts not Green, but at least 1 Contact that is Green => Amber');
		
		delete lstCont;
		List<Account> lstAccSel6 = [select Number_of_Contacts_with_Issues__c,Contact_Data_Quality__c from Account where id iN: lstAcc];
		System.assertEquals(0,lstAccSel6[0].Number_of_Contacts_with_Issues__c,'0 Number of contact that are not green');
		System.assertEquals(null,lstAccSel6[0].Contact_Data_Quality__c,'no contact found');
    }
    /*****************************************************************************************************************************
    @ Method:         testcheckPrimaryContact
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:       EPH-5629 Contact - Quality & Preference
    					there can only be one "Primary Contact" for each Account
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.05.2018 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testcheckPrimaryContact(){
    		EBH_TestDataFactory.setUpCustomSettings();
    		List<Account> lstAcc = EBH_TestDataFactory.createAccounts(1,'EBH_Seller');
    		List<Contact> lstCont = new List<Contact>();
    		for(Integer i = 0; i < 5; i++){
    			Contact con = new Contact(LastName = 'testPrim' + i, AccountId = lstAcc[0].Id, EBH_DataOrigin__c='test',EBH_Status__c='Active',Primary_Contact__c = true);
    			lstCont.add(con);
    		}
    		Test.startTest();
    		/*Test Insert Fail - Start*/
    		try{
    			insert lstCont;
    		}catch(Exception ex){
    			System.assert(ex.getMessage().contains(System.Label.PrimaryContact_Error_Msg));
    		}
    		/*Tet Insert Fail - End*/
    		/*Test Insert Success - Start*/
    		for(Contact con : lstCont){
    			con.Primary_Contact__c = false;
    		}
    		//insert lstCont;
    		update lstCont;
    		/*Test Insert Success - End*/
    		/*Test Update Success - Start*/
    		lstCont[0].Primary_Contact__c = true;
    		update lstCont;
    		/*Test Update Success - End*/
    		/*Test Update Fail - Start*/
    		try{
    			lstCont[1].Primary_Contact__c = true;
    			update lstCont;
    		}catch(Exception ex){
    			System.assert(ex.getMessage().contains(System.Label.PrimaryContact_Error_Msg));
    		}
    		/*Test Update Fail - End*/
    		
    		Test.stopTest();
    }
	
	/*****************************************************************************************************************************
    @ Method:         testPreventDeleteDWHContact
    @ Version:        1.0
    @ Author:         Sothea Horn
    @ Purpose:        US-0033083 - Enable the merging tool for DWH contact
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.07.2025 / Sothea Horn / Created the test Method.
    *****************************************************************************************************************************/
	static testMethod void testPreventDeleteDWHContact(){
    		EBH_TestDataFactory.setUpCustomSettings();
			RecordType contactRecTypeDWH = ApexUtil.getRecordTypeByName('Contact','EBH_DWH');
			// create a customer with Seller record type for testing
    		List<Account> lstAcc = EBH_TestDataFactory.createAccounts(1,'EBH_Seller');
    		// create a DWH contact for this customer for testing
			Contact testDWHCon = new Contact(
				Salutation = 'Mr.',
				FirstName = 'test',
				LastName = 'Contact01',
				Email = 'contact.test01@test.com',
				RecordTypeId = contactRecTypeDWH.Id,
				AccountId = lstAcc[0].Id
			);
			insert testDWHCon;

			//test fail to delete DWH contact and throw error message
    		Test.startTest();
				try{
					delete testDWHCon;
				}catch(Exception ex){
					System.assert(ex.getMessage().contains(System.Label.Prevent_Deletion_of_DWH_Contact_Message));
				}
    		Test.stopTest();
    }
    
}