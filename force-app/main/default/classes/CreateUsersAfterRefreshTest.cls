/*********************************************************************************************************************************
@ Class:          CreateUsersAfterRefresh
@ Version:        1.0
@ Author:         Mony Nou
@ Purpose:        US-0012362 - Test class for CreateUsersAfterRefresh
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.10.2022 / Mony Nou / Created the class.
*********************************************************************************************************************************/

@isTest
private class CreateUsersAfterRefreshTest {
    
    @IsTest
    static void test_runApexClass() {

        Test.startTest();

            Test.testSandboxPostCopyScript(
                new CreateUsersAfterRefresh(), UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(), UserInfo.getOrganizationName());

        Test.stopTest();
    }
}