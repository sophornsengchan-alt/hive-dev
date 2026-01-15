/*****************************************************************************************************************************************************************
@ Class:          BCDContractApprovedControllerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
----------------------------------------------------------------------------------------------------------------------------------------------------------
@ Change history:  Sophal Noch / 14.10.2022 / Created the class.
***********************************************************************************************************************************************************/
@isTest
private class BCDContractApprovedControllerTest {

    @isTest
    private static void testGetPage() {

        // Sophal Noch / 14.10.2022 / US-0012073 :

        RecordType bcdContrRecType = ApexUtil.getRecordTypeByName('BCD_Statement__c','ACP_Contract');
        BCD_Statement__c bcdStatement = new BCD_Statement__c(Name = 'testBCD1',Status__c = 'New' ,Rev_RollUp__c = 'DE', Site__c = '77', RecordTypeId = bcdContrRecType.Id,Credit_Total_Value__c = 10);
        insert bcdStatement;

        Blob bodyBlob=Blob.valueOf('id,name');
        ContentVersion cv = new ContentVersion(Title='Test Attr',FirstPublishLocationID=bcdStatement.Id,VersionData = bodyBlob, pathOnCLient='test.csv');
        insert cv;

        bcdStatement.Status__c = 'BCD ready';
        bcdStatement.BCD_File_SF_Id__c = cv.Id;
        update bcdStatement;

        Test.startTest();

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('test comment');
        req.setObjectId(bcdStatement.Id);
        req.setSubmitterId(UserInfo.getUserId());

        Approval.process(req, true);

        // bu approved
        ProcessInstance proIns = [SELECT Id,Status,TargetObjectId FROM ProcessInstance where Status='Pending' and TargetObjectId = :bcdStatement.Id];
        ProcessInstanceWorkitem proInsWorkItm = [SELECT Id,ProcessInstanceId, ProcessInstance.Status, ProcessInstance.TargetObjectId
                                                                      FROM ProcessInstanceWorkitem WHERE ProcessInstanceId =:proIns.Id];

        Approval.ProcessWorkitemRequest apprReq = new Approval.ProcessWorkitemRequest();
        apprReq.setComments('test');
        apprReq.setAction('Approve');

        apprReq.setWorkitemId(proInsWorkItm.Id);
        Approval.process(apprReq);

        // finance aproved

        proIns = [SELECT Id,Status,TargetObjectId FROM ProcessInstance where Status='Pending' and TargetObjectId = :bcdStatement.Id];
        proInsWorkItm = [SELECT Id,ProcessInstanceId, ProcessInstance.Status, ProcessInstance.TargetObjectId
                                                                      FROM ProcessInstanceWorkitem WHERE ProcessInstanceId =:proIns.Id];

        apprReq = new Approval.ProcessWorkitemRequest();
        apprReq.setComments('test');
        apprReq.setAction('Approve');
        apprReq.setWorkitemId(proInsWorkItm.Id);
        Approval.process(apprReq);

        BCDContractApprovedController bcdContr = new BCDContractApprovedController();
        bcdContr.bcdId = bcdStatement.Id;
        bcdContr.getPage();


        Test.stopTest();
       


    }
}