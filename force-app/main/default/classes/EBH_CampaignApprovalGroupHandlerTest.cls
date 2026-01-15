/*********************************************************************************************************************************
@ Class:          EBH_CampaignApprovalGroupHandlerTest
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Test class for EBH_CampaignApprovalGroupHandler class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 27.09.2017 / NEHA LUND / Created the test class.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_CampaignApprovalGroupHandlerTest {
    

    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() { 
                 EBH_TestDataFactory.setUpGroup('EBH_DEPUBLICGROUP');
      
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testPublicGroup(); }        
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
             EBH_TestDataFactory.setUpGroup('EBH_DEPUBLICGROUP');

        //System.runAs(EBH_TestDataFactory.createUser('Standard User')) { testPublicGroup(); }
    }
    
    /*****************************************************************************************************************************
    @ Method:         testPublicGroup
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        TEST CASE (*) System should be able to update the public group as and when Campaign Approval Hierarchy
                                    is updated
                      COVERAGES (*) testPublicGroup(): tests the public group sync with Campaign Approval matrix
                                        |___ hasSiteOrApproversChanged(): Checks field change in Site/Approver for Campaign
                                                                          Approval Group
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testPublicGroup() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();     
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/
        List<EBH_CampaignApprovalGroup__c> testDataMap = EBH_TestDataFactory.setupCampaignGroupTriggerHandlerData();     

        Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            System.assertEquals(10, [SELECT id from EBH_CampaignApprovalGroup__c].size());
            /*Excecute test*/
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/  
            testDataMap[0].EBH_Approver__c = UserInfo.getUserId();
            /*Excecute test*/
            System.assertEquals(UserInfo.getUserId(), testDataMap[0].EBH_Approver__c);
            /*Validate test*/
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
            /*Modify data for test*/             
            /*Excecute test*/
             
            /*Validate test*/
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
         Test.stopTest();
            List<GroupMember> groupMembers = [SELECT id from GroupMember WHERE Group.Name ='EBH_DEPUBLICGROUP'];
            /*Validate test*/
            //System.assertEquals(10, groupMembers.size() );
            List<EBH_CampaignApprovalMatrix__c> camRec = [SELECT id FROM EBH_CampaignApprovalMatrix__c WHERE id =: testDataMap[0].id 
                                                    LIMIT 1]; 
            //delete groupMembers[1];
            //System.assertEquals(1, camRec.size());
            testDataMap[0].EBH_Approver__c = UserInfo.getUserId();
            
            update testDataMap[0];
            //System.assertEquals(1, [SELECT EBH_MethodName__c FROM EBH_ApexLog__c 
            //                      WHERE EBH_MethodName__c = 'createCampaignApprovalGroup'].size());
            
    }
}