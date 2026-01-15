/*********************************************************************************************************************************
@ Class:          EBH_CampaignApprovalControllerTest
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Test class for EBH_CampaignApprovalController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 29.05.2017 / NEHA LUND / Created the test class.
@               : 21.11.2023 / SRONG TIN / Update the test Method. //US-0014419
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_CampaignApprovalControllerTest {
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {  
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testSubmitForApproval(); }        
    }
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SU
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for Standard User
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SU() {
        //statusForAssert = 'Draft';
		EBH_TestDataFactory.setUpGroup('EBH_CampaignRequestApprovers');
        System.runAs(EBH_TestDataFactory.createUser('Standard User')) { testSubmitForApproval(); }
    }
    static String statusForAssert = 'Submitted';
    /*****************************************************************************************************************************
    @ Method:         testSubmitForApproval
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        TEST CASE (*) System should be able to automatically submit the Campaign request for an approval
                                    For every site- we have dedicated group of users to approve the request and covert it into
                                    Campaign
                      COVERAGES (*) testSubmitForApproval(): 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.05.2017 / NEHA LUND / Created the test Method.
    @               : 21.11.2023 / SRONG TIN / Update the test Method. //US-0014419
    *****************************************************************************************************************************/
    static testMethod void testSubmitForApproval() {
                    
            /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
            EBH_TestDataFactory.setUpCustomSettings();   
            try{
                EBH_TestDataFactory.setUpGroup('EBH_CampaignRequestApprovers');
            }
            catch(Exception e){
                System.assert( e.getMessage() != null );
            
            }
            List<Campaign> campaigns = EBH_TestDataFactory.createCampaigns(2, 'Request', 'UK', 'EBH_Campaign');  //US-0014419 change EBH_CampaignRequest to EBH_Campaign
            /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/
    
            Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            
            System.assertEquals( 2, campaigns.size());
            /*Excecute test*/
            EBH_TestDataFactory.SetUpCampaignRequestSiteGroupSettings('UK','EBH_CampaignRequestApprovers');

            EBH_CampaignApprovalController.submitApprovalRequest( campaigns[0].id, 'Submit comments');
            
            /*Validate test*/

  //          System.assertEquals( statusForAssert, [SELECT Status from Campaign where id= :campaigns[0].id].Status );
            
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            campaigns[1].Status = 'Feasibility';
			campaigns[1].EBH_Channel__c = EBH_ConstantsUtility.CAMP_CHANNEL_AM_OUTREACH;
            campaigns[1].RecordtypeId = EBH_ConstantsUtility.CAMP_RECORDTYPE_OUTREACH_ID;
            update campaigns[1];    

            /*Excecute test*/
            EBH_CampaignApprovalController.submitApprovalRequest( campaigns[1].id, 'Submit comments');
            
            /*Validate test*/
            System.assertEquals( 'Feasibility', [SELECT Status from Campaign where id= :campaigns[1].id].Status );
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
            // try to submit record again
            /*Excecute test*/
            
            EBH_CampaignApprovalController.submitApprovalRequest( campaigns[0].id, 'Submit comments');
            /*Validate test*/
           
//            System.assertEquals( statusForAssert, [SELECT Status from Campaign where id= :campaigns[0].id].Status );
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
             Test.stopTest();
    }


    /*****************************************************************************************************************************
    @ Method:         testValidateApproval
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008393 
    @                 As a...
    @                 System Admin
    @                 Want to...
    @                 have 100% test classes running without failures
    @                 So that...
    @                 Everything will work better and we will be able to deploy running all test classes when needed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.11.2020 / Sophal Noch / Created the test Method.
	@               : 21.11.2023 / SRONG TIN / Update the test Method. //US-0014419
    *****************************************************************************************************************************/
    static testMethod void testValidateApproval() {

        EBH_TestDataFactory.setUpCustomSettings();   
        try{
            EBH_TestDataFactory.setUpGroup('EBH_CampaignRequestApprovers');
        }
        catch(Exception e){
            System.assert( e.getMessage() != null );
        
        }

        List<Campaign> campaigns = EBH_TestDataFactory.createCampaignsWithParent(1, 'Request', 'UK', 'EBH_Campaign',null,'Request Accepted');//US-0014419 change EBH_CampaignRequest to EBH_Campaign
        System.assertEquals( 1, campaigns.size());

        EBH_TestDataFactory.SetUpCampaignRequestSiteGroupSettings('UK','EBH_CampaignRequestApprovers');
        String result = EBH_CampaignApprovalController.validateApproval(campaigns[0].id);
        System.assertEquals( '', result);

        EBH_CampaignApprovalController.submitApprovalRequest( campaigns[0].id, 'Submit comments');
        
        result = EBH_CampaignApprovalController.validateApproval(campaigns[0].id);
        //System.assertEquals( Label.EBH_SubmittedCampaignApprovalError, result);

    }

}