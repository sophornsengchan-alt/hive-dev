/*****************************************************************************************************************************************************************
@ Class:          DECouponBCDContractApprovedContr
@ Version:        1.0
@ Author:         Bora Chhorn (bora.chhorn@gaea-sys.com)
----------------------------------------------------------------------------------------------------------------------------------------------------------
@ Created the class :  Bora Chhorn / 19.05.2023 / US-0012890 - Step 4: Notify GCX
***********************************************************************************************************************************************************/
@isTest
private class DECouponBCDContractApprovedContrTest {

    @isTest
    private static void testGetPage() {

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

        DECouponBCDContractApprovedContr bcdContr = new DECouponBCDContractApprovedContr();
        bcdContr.bcdId = bcdStatement.Id;
        bcdContr.getPage();
        
        Test.stopTest();
    }
}