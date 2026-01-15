/*********************************************************************************************************************************
@ Class:          EBH_ProjectTriggerHandlerTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        Test class for Project Trigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 27.12.2019 / Sovantheany Dim / Created the test class.
@ Change history: 30.06.2023 / Chetra Sarom / US-0013306 - Retirement of Managed Payment Solution (Technical Debt3)
*********************************************************************************************************************************/
@isTest
private class EBH_ProjectTriggerHandlerTest {
    static String ADMIN_PROFILE_ID = '00e6A000000HNzwQAG';
    private static RecordType recTypeSRMProj = ApexUtil.getRecordTypeByName('EBH_Project__c','Seller_Risk_Management');
    @TestSetup
    static void makeData(){
        EBH_TestDataFactory.setUpCustomSettings(); 
		ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = false;
		insert avr;
        Lead oneL = new Lead();
		oneL.RecordTypeId = ApexUtil.getRecordTypeByName('Lead', 'EBH_eBayAUSMB').Id;
		oneL.EBH_eBayID__c = 'biggest_sellert_test';
		oneL.Site__c = 'AU';
		oneL.LeadSource = 'Self Gen';
		oneL.LeadSegment__c = 'SMB';
		oneL.OtherLeadSource__c = 'other leadsource tst';
		oneL.LastName = 'AMT Lead tst 01';
		oneL.Phone = '012 345 5678';
		oneL.Website = 'www.test.com.test';
		oneL.Email = 'test@tes.com.invalid';
		oneL.EBH_Vertical__c = 'Collectibles';
        oneL.VAT_Number__c = '12312312312312';
        oneL.Company = 'AMT Company';
        insert oneL;
    }

    /*****************************************************************************************************************************
    @ Method:   testValidateOneOfAccountManagement
    @ Version:  1.0
    @ Author:   Vimean Heng (vimean.heng@gaea-sys.com)
	@ Purpose: 	US-0015879 - 1.2 One-Off Account Management Project record needs to be created only from quick actions button
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 30.07.2021 / Sovantheany Dim / Created the  Method.
    @ Change history:  18.09.2024 / Vimean Heng / Deprecated the methode, Reason : This method is deprecated in EBH_Project.trigger.
    *****************************************************************************************************************************/
    @isTest
    static void testValidateOneOfAccountManagement() {
        RecordType recTypeAccManagement = ApexUtil.getRecordTypeByName('EBH_Project__c','One_Off_Account_Management');
            List<Account> sellers =  EBH_TestDataFactory.createAccounts(1, 'EBH_Seller') ;
        User admins = [Select Id from User where ProfileId = :ADMIN_PROFILE_ID And IsActive = true limit 1];
        EBH_Project__c proj1 = new EBH_Project__c(Name= 'Test - ' + sellers[0].Name,RecordTypeId=recTypeAccManagement.Id); 
        List<EBH_Project__c> proList = new List<EBH_Project__c>{proj1};
        
        Test.startTest();
        EBH_Project__c projUpdate = new EBH_Project__c(Name= 'Test - Coverage EHB_Project' ); 
        //add coverage to the trigger
        insert projUpdate;
        update projUpdate;
            try {
            insert proList;
        }catch(Exception e){
                System.AssertEquals(e.getMessage().contains(System.label.Project_One_Off_Account_Management_Error), true,true);
            }

        Test.stopTest();
    }

    	
	@isTest
	private static void testAutoLinkSeller(){
		EBH_TestDataFactory.setUpCustomSettings();
		List<Account> listSeller =  EBH_TestDataFactory.createAccounts(2, 'EBH_Seller') ;
		//listSeller[0].Name = 'TEST Seller AMT 01';
    	listSeller[0].EBH_OracleId__c = '111222333';
        listSeller[0].EBH_ActualStandard__c = 'Above Standard';

		//listSeller[1].Name = 'TEST Seller AMT 02';
    	listSeller[1].EBH_OracleId__c = '444555666';
        listSeller[1].EBH_ActualStandard__c = 'Above Standard';
		update listSeller;

		RecordType recTypeAuSMB = ApexUtil.getRecordTypeByName('Lead','EBH_eBayAUSMB');
    	Lead l = EBH_TestDataFactory.createLeads();
    	l.LeadSource = EBH_ConstantsUtility.LEAD_SOURCE_SELF_GEN;
    	l.RecordTypeId = recTypeAuSMB.Id;
    	l.isapproved__c = false;
    	l.Site__c = 'AU';
    	l.LeadSegment__c = 'SMB';
    	insert l;
    	EBH_Project__c oProjectTest = new EBH_Project__c(Lead__c = l.id,EBH_Seller__c=listSeller[0].Id,ProjectName__c='Project 1',RecordTypeId=ApexUtil.getRecordTypeByName('EBH_Project__c','Integration_Help').Id);
		insert oProjectTest;

		Test.startTest();
			EBH_Project__c oProject = [SELECT Name, EBH_Seller__c, OracleID__c, Seller_Name__c, Incoming_Seller_Standard__c FROM EBH_Project__c WHERE Id=:oProjectTest.Id];
			System.assertEquals(oProject.OracleID__c, listSeller[0].EBH_OracleId__c, ' OracleId should be inherited from Seller');
			System.assertEquals(oProject.Seller_Name__c, listSeller[0].Name, ' SellerName should be inherited from Seller');
            System.assertEquals(oProject.Incoming_Seller_Standard__c, listSeller[0].EBH_ActualStandard__c, ' Incoming Seller Standard should be inherited from Seller Actual Standard');
			
			oProject.EBH_Seller__c = null;
			oProject.OracleID__c = '444555666';
			update oProject;
			oProject = [SELECT Name, EBH_Seller__c, OracleID__c, Seller_Name__c, Incoming_Seller_Standard__c FROM EBH_Project__c WHERE Id=:oProjectTest.Id];
			System.assertEquals(oProject.EBH_Seller__c, listSeller[1].Id, ' Seller should be == Seller of that oracleId');
			System.assertEquals(oProject.Incoming_Seller_Standard__c, listSeller[0].EBH_ActualStandard__c, ' Incoming Seller Standard should be inherited from Seller Actual Standard');
		Test.stopTest();
	}
}