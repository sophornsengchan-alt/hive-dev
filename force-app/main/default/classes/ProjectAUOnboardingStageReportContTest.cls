@isTest
private class ProjectAUOnboardingStageReportContTest {
    
    @TestSetup
    static void setup(){

        EBH_TestDataFactory.setUpCustomSettings();
        
        RecordType recTypeAuSMBLead = ApexUtil.getRecordTypeByName('Lead','EBH_eBayAUSMB');
    	Lead l = EBH_TestDataFactory.createLeads();
    	l.LeadSource = EBH_ConstantsUtility.LEAD_SOURCE_SELF_GEN;
    	l.RecordTypeId = recTypeAuSMBLead.Id;
    	l.isapproved__c = false;
    	l.Site__c = 'UK';
    	l.LeadSegment__c = 'SMB';
    	insert l;
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	RecordType legalRecordType = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity');
        //LA:06-12-2023-US-0014231
    	//Account legal = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = legalRecordType.Id,EBH_RevRollup__c='UK',EBH_DealsProgram__c ='Accepted');
        Account legal = new Account(EBH_OracleId__c='1003293591',Name='Test Acc1',RecordTypeID = legalRecordType.Id,EBH_RevRollup__c='UK');
		insert legal;
        //LA:06-12-2023-US-0014231
		//Account sellerAcc = new Account(ParentId = legal.Id, EBH_OracleId__c='1003293592',Name='Test Acc2',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',EBH_DealsProgram__c ='Accepted');
        Account sellerAcc = new Account(ParentId = legal.Id, EBH_OracleId__c='1003293592',Name='Test Acc2',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK');
    	insert sellerAcc;
    	Contact con = new Contact(LastName = 'testContact', AccountId = legal.Id,EBH_Status__c='Active');
    	insert con;
    	EBH_Project__c p1 = new EBH_Project__c(
            LegalEntity__c = legal.Id,
            Lead__c = l.Id, 
            EBH_Seller__c=sellerAcc.Id,
            ProjectName__c='Project 1',
            RecordTypeId=ApexUtil.getRecordTypeByName('EBH_Project__c','eBayAUSMB').Id,
            AcquisitionManager__c = UserInfo.getUserId(),
            IntegrationManager__c = UserInfo.getUserId()
        );

        EBH_Project__c p2 = new EBH_Project__c(
            LegalEntity__c = legal.Id,
            Lead__c = l.Id, 
            EBH_Seller__c=sellerAcc.Id,
            ProjectName__c='Project 2',
            RecordTypeId=ApexUtil.getRecordTypeByName('EBH_Project__c','eBayAUSMB').Id,
            AcquisitionManager__c = UserInfo.getUserId(),
            IntegrationManager__c = UserInfo.getUserId()
        );
    	insert new List<EBH_Project__c> {p1, p2};
        
    }

    @isTest 
    static void test_ProjDurationReports () {

        EBH_Project__c proj = [select AcquisitionManager__c, IntegrationManager__c from EBH_Project__c Where ProjectName__c = 'Project 1'];

        Test.startTest();

            PageReference pageRef = new PageReference('/apex/ProjectAUOnboardingStageReport');
            Test.setCurrentPage(pageRef);
            
            pageRef.getParameters().put('id', proj.Id);
            pageRef.getParameters().put('rp', 'duration');
            pageRef.getParameters().put('acqMngr', proj.AcquisitionManager__c);
            pageRef.getParameters().put('intMngr', proj.IntegrationManager__c);

            ProjectAUOnboardingStageReportController cont = new ProjectAUOnboardingStageReportController();

            System.assert(String.isNotBlank(cont.reportFilterProjDurAcqMngr), 'There should be a filtering param for report');
            System.assert(String.isNotBlank(cont.reportFilterProjDurIntMngr), 'There should be a filtering param for report');

        Test.stopTest();
    }

    @isTest 
    static void test_AVGProjDurationReports () {

        EBH_Project__c proj = [select EBH_Stage__c,AcquisitionManager__c from EBH_Project__c Where ProjectName__c = 'Project 1'];

        Test.startTest();

            PageReference pageRef = new PageReference('/apex/ProjectAUOnboardingStageReport');
            Test.setCurrentPage(pageRef);
            
            pageRef.getParameters().put('id', proj.Id);
            pageRef.getParameters().put('tm', proj.AcquisitionManager__c);
            pageRef.getParameters().put('stage', proj.EBH_Stage__c);
            pageRef.getParameters().put('proj', proj.ID);
            pageRef.getParameters().put('time', 'THIS_TIME');
            
            ProjectAUOnboardingStageReportController cont = new ProjectAUOnboardingStageReportController();

            System.assert(String.isNotBlank(cont.reportFilterCurProject), 'There should be a filtering param for report');
            System.assert(String.isNotBlank(cont.reportFilterExistedProject), 'There should be a filtering param for report');

        Test.stopTest();
    }

    @isTest 
    static void test_apexInit () {
        EBH_Project__c proj = [select Id from EBH_Project__c Where ProjectName__c = 'Project 1'];

        Test.startTest();

            Map<String,Object> res = ProjectAUOnboardingStageReportController.apexInit(proj.Id);

            System.assert(!res.isEmpty(), 'There should be some value return.');

        Test.stopTest();
    }

}