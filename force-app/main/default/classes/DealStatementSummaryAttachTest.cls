/*********************************************************************************************************************************
@ Class:          DealStatementSummaryAttachTest
@ Version:        1.0
@ Author:         sovantheany.dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        Test class for DealStatementSummaryAttach
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  03.03.2022 / sovantheany.dim / Created the  class.
*********************************************************************************************************************************/
@isTest
private class DealStatementSummaryAttachTest {
    @testSetup static void setup() {
        Date myDate = System.Today().adddays(2);
        Account eBSeller = new Account();
        eBSeller.Name = 'AMT_Seller';
        eBSeller.EBH_MainVertical__c = 'Electronics';
        eBSeller.EBH_OracleID__c = 'AXTP-930494';
        insert eBSeller;
        
        Deal_Statement__c ds1 = new Deal_Statement__c();
        ds1.Name = eBSeller.Name+myDate.month()+'Statement';
        ds1.Subsidy_Final_Calculation__c=0;                 
        ds1.Status__c = '1st Payout Approved';
        ds1.eBay_Seller__c =eBSeller.Id ;
        ds1.Subsidy_Final_Calculation__c=0;
        insert ds1;
        
        Deal_Statement_Summary__c dss = new Deal_Statement_Summary__c(Month__c = mydate.month()+'', Year__c = mydate.year()+'', Status__c = 'New', Statement_Type__c = '1st Statement');
        insert dss;
        
        Attachment att1 = new Attachment(name='test',parentId=dss.Id,body = blob.valueOf('test'));
        insert att1;
        
        Approval.ProcessSubmitRequest req1 =  new Approval.ProcessSubmitRequest();
        req1.setComments('test');
        req1.setObjectId(dss.Id);
        req1.setSubmitterId(UserInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Deal_Statement_Summary_Approval_V2');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
    }
	@isTest 
    private static void test_method(){
        Deal_Statement_Summary__c dealStSummary = [select id from Deal_Statement_Summary__c where Statement_Type__c = '1st Statement' limit 1];
        Test.startTest();
        DealStatementSummaryAttachController controller = new DealStatementSummaryAttachController();
        controller.dss = dealStSummary;
        List<Attachment> lstatt = controller.getattachments();
        String approvalhistory = controller.getsummaryApprovalBody();
        Test.stopTest();
        System.assert(!lstatt.isEmpty());
        System.assert(!string.isBlank(approvalhistory));
    }
}