/*********************************************************************************************************************************
@ Class:          ManageProgramParticipationControllerTest
@ Version:        1.0
@ Author:         Sothea Horn (sothea.horn@gaea-sys.com)
@ Purpose:        ManagedProgramsParticipationController unit test
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 27.11.2025 / Sothea Horn / Create the class / US-0033849 - Step 1 - Seller Overview
*********************************************************************************************************************************/
@isTest
private class ManageProgramParticipationControllerTest {
    @isTest
    private static void testHasPermissionSubmitChangeRequest() {

        Profile p = [select id from Profile where name='Standard User Profile' limit 1];
        User testUser = new User(alias = 'mppart', email='testmanagedProPartn@test.com', 
                            emailencodingkey='UTF-8', lastname='testmppart', firstname='testmppart', languagelocalekey='en_US', 
                            localesidkey='en_US', profileid = p.Id, 
                            timezonesidkey='America/Los_Angeles', username='testmanagedProPartn@test.com', isActive = true);
        ApexSafe.dml().doInsert(new List<User>{testUser},true);

        Boolean result;
        // Perform the test
        Test.startTest();
            System.runAs(testUser) {
                // Call the method to be tested
                result = ManagedProgramsParticipationController.hasPermissionSubmitChangeRequest();
            }
        // Stop the test
        Test.stopTest();

        // Assert the result
        System.assertEquals(result, false, 'This user should not have permission to submit change request.');
    }
}