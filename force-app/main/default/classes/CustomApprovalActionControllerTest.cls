/*********************************************************************************************************************************
@ Class:          CustomApprovalActionControllerTest
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        est class for CustomApprovalActionController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 28.02.2018 / Vadhanak Voun / Created the class.
*********************************************************************************************************************************/
@isTest
private class CustomApprovalActionControllerTest {

    static testMethod void testApproval() {
        
//        List<User> stdUsers = createUsers(1, 'Standard User');
//        stdUsers[0].ManagerId = UserInfo.getUserId();
        
        List<Account> legalEntities = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');
        List<Contract> contractsListing = EBH_TestDataFactory.createContracts (3, 'Listing Agreement', legalEntities[0].id, legalEntities[1].id );
        for(Contract c: contractsListing)
        {
        	
        	c.EBH_FinancePreCheckApprover__c = UserInfo.getUserId();
        }
        update contractsListing;
        
        //1, do submit for approve here...
        submitNow(contractsListing[0].Id,'submit 1 for approve');
                                                    
        Test.startTest();
         
//         List<ProcessInstance> listInst = CustomApprovalActionController.getApprovalHistory(contractsListing[0].Id,' Limit 1 ');
//         System.assertEquals(1,listInst.size(),' 1 inst get quired to view');
//         System.assertEquals(2,listInst[0].StepsAndWorkitems.size(),' 2 histories get quired to view');
//         
//         CustomApprovalActionController.ItemData item1 = CustomApprovalActionController.getItemDetail(listInst[0].Id,listInst[0].StepsAndWorkitems[0].Id);
//         System.assertNotEquals(null,item1,' 1 item get quired to view');
         
         List<CustomApprovalActionController.ItemData> listInst2 = CustomApprovalActionController.getApprovalHistory2(contractsListing[0].Id,' Limit 1 ',false);
  //       System.assertEquals(1,listInst2.size(),' 1 inst get quired to view');
//         System.assertEquals(2,listInst2[0].proInstance.StepsAndWorkitems.size(),' 2 histories get quired to view');
         
    //    CustomApprovalActionController.ItemData item1 = CustomApprovalActionController.getItemDetail(listInst2[0].proInstance.Id,listInst2[0].proInstance.StepsAndWorkitems[0].Id);
  //       System.assertNotEquals(null,item1,' 1 item get quired to view');
         
         
         Map<String,String> mapApproveResultApprove =  CustomApprovalActionController.doApprove(contractsListing[0].Id,'test Approve');
    //     System.assertEquals('ok',mapApproveResultApprove.get('status'),' appove sucess');
      //   System.assertEquals('Approve',mapApproveResultApprove.get('action'),' appove sucess');
         
         //1, do submit for reject here...
         submitNow(contractsListing[1].Id,'submit 2 for reject');
         
         Map<String,String> mapApproveResultReject =  CustomApprovalActionController.doReject(contractsListing[1].Id,'test reject');
         //System.assertEquals('ok',mapApproveResultReject.get('status'),' Reject sucess');
         //System.assertEquals('Reject',mapApproveResultReject.get('action'),' Reject sucess');
         
         //1, do submit for recall here...
         submitNow(contractsListing[2].Id,'submit 3 for recall');
         
         Map<String,String> mapApproveResultRecall =  CustomApprovalActionController.doRecall(contractsListing[2].Id,'test recall');
//         System.assertEquals('ok',mapApproveResultRecall.get('status'),' Recall sucess');
//         System.assertEquals('Removed',mapApproveResultRecall.get('action'),' Recall sucess');
         
        Test.stopTest();
        
    }
    static void submitNow(String targetObjectId,String comments)
    {
    	Approval.ProcessSubmitRequest req1 =  new Approval.ProcessSubmitRequest();
        req1.setComments(comments);
        req1.setObjectId(targetObjectId);
        
        // Submit on behalf of a specific submitter
        req1.setSubmitterId(UserInfo.getUserId()); 
        
        // Submit the record to specific process and skip the criteria evaluation
        //req1.setProcessDefinitionNameOrId('EBH_ContractFinancePreCheckApproval'); //original approval 
      //  EPH_Contract_DE_Finance_Pre_Check
       // req1.setProcessDefinitionNameOrId('EPH_Contract_DE_Finance_Pre_Check_v1_01');
       req1.setProcessDefinitionNameOrId('ES_Contract_Approval_v_1_4');
        req1.setSkipEntryCriteria(true);
        //req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);
    }
}