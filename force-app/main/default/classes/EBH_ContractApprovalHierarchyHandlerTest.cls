/*****************************************************************************************************************************
@ Class:       EBH_ContractApprovalHierarchyHandler
@ Author:      Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:     US-0008361 test class for EBH_ContractApprovalHierarchyHandler
------------------------------------------------------------------------------------------------------------------------------
@ Change history:  17.11.2021 / Mony Nou / Created the method.
------------------------------------------------------------------------------------------------------------------------------
@ Change history:  06.12.2023 / Vimean Heng / Fix mix DML.
@*****************************************************************************************************************************/
@IsTest 
private class EBH_ContractApprovalHierarchyHandlerTest {
    
    private static User currentUser = [ select Id, Name from User where Id = :UserInfo.getUserId() ];
    /*************************************************************************************************************************
    @ Change history:  06.12.2023 / Vimean Heng / US-0014422 Fix mix DML.
    *************************************************************************************************************************/
    @isTest static void test_method() {

        Test.startTest();
            System.runAs(currentUser){
                EBH_ActiveTriggers__c cusettingTrigger = new EBH_ActiveTriggers__c();
                cusettingTrigger.Name = 'EBH Trigger Controller';
                cusettingTrigger.EBH_ContactTrigger__c = true;
                cusettingTrigger.EBH_ContractApprovalHierarchyTrigger__c = true;
                cusettingTrigger.EBH_ExecuteContractUpdateBatch__c = false;
                insert cusettingTrigger; 
                //logic ignore flow User Before Context - Assign Role
                // create users and profile Chatter Free User then assign to profile Standard User
                User us = EBH_TestDataFactory.createUser('Standard User');
                List<User> users = EBH_TestDataFactory.createUsers(4, 'Chatter Free User');
                String profileId = us.ProfileId;
                insert users;  
                for(User u : users){
                    u.ProfileId = profileId;
                }
                update users;
                EBH_ContractApprovalMatrix__c  matrixRecordDE = EBH_TestDataFactory.createContractApprovalMatrix ( 'DE', users[0].id, users[1].id ) ;
                EBH_ContractApprovalMatrix__c  matrixRecordFR = EBH_TestDataFactory.createContractApprovalMatrix ( 'FR', users[0].id, users[1].id ) ;
                EBH_ContractApprovalMatrix__c  matrixRecordIT = EBH_TestDataFactory.createContractApprovalMatrix ('IT', users[0].id, users[1].id ) ;
                EBH_ContractApprovalMatrix__c  matrixRecordES = EBH_TestDataFactory.createContractApprovalMatrix ( 'ES', users[0].id, users[1].id ) ;
                EBH_ContractApprovalMatrix__c  matrixRecordUK = EBH_TestDataFactory.createContractApprovalMatrix ( 'UK', users[0].id, users[1].id ) ;
                EBH_ContractApprovalMatrix__c  matrixRecordRest = EBH_TestDataFactory.createContractApprovalMatrix ( 'Rest of Europe', users[0].id, users[1].id ) ;
                insert new List<EBH_ContractApprovalMatrix__c>{matrixRecordDE,matrixRecordFR,matrixRecordIT,matrixRecordES,matrixRecordUK,matrixRecordRest};

                EBH_ContractApprovalHierarchy__c child1 = EBH_TestDataFactory.createContractApprovalHierarchy ( EBH_ConstantsUtility.HIERARCHY_CONTROLLING, users[2].id, 5000000.0);
                child1.EBH_ContractApprovalMatrix__c = matrixRecordDE.Id;
                EBH_ContractApprovalHierarchy__c child2 = EBH_TestDataFactory.createContractApprovalHierarchy ( EBH_ConstantsUtility.HIERARCHY_FINANCE, users[3].id, 5000000.0);
                child2.EBH_ContractApprovalMatrix__c = matrixRecordFR.Id;
                insert new List<EBH_ContractApprovalHierarchy__c>{child1,child2};

                cusettingTrigger.EBH_ExecuteContractUpdateBatch__c = false;
                update cusettingTrigger;

                child1.EBH_Threshold__c = 3000000.0;
                update child1;
            }
            

        Test.stopTest();

    }

}