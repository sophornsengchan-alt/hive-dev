/*********************************************************************************************************************************
@ Class:          ApproveRejectControllerTest
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        US-0016680 - [Dev Only] Apex Class Classification to upgrade API version 1/5
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  28.02.2025 / Sophal Noch / Update the class.
*********************************************************************************************************************************/
@isTest
private  class ApproveRejectControllerTest {

    static testMethod void testApproveReject(){

        Account sellerForApproveReject = new Account (Name='Test Seller For Approve & Reject',EBH_OracleID__c='12345', EBH_RevRollup__c='UK');
        insert sellerForApproveReject;
        
        RecordType fvfRecordTypeSeller = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c',EBH_ConstantsUtility.FVF_SELLER_RECORDTYPE);
        Final_Value_Fee_FVF__c fvf1 = new Final_Value_Fee_FVF__c(RecordTypeId = fvfRecordTypeSeller.Id, Seller_Name__c = sellerForApproveReject.Id, Final_Value_Fee_Stage__c=EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE, Budget_FVF_Exposure__c = 100);
        Final_Value_Fee_FVF__c fvf2 = new Final_Value_Fee_FVF__c(RecordTypeId = fvfRecordTypeSeller.Id, Seller_Name__c = sellerForApproveReject.Id, Final_Value_Fee_Stage__c=EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE, Budget_FVF_Exposure__c = 100);
        Final_Value_Fee_FVF__c fvf3 = new Final_Value_Fee_FVF__c(RecordTypeId = fvfRecordTypeSeller.Id, Seller_Name__c = sellerForApproveReject.Id, Final_Value_Fee_Stage__c='Draft', Budget_FVF_Exposure__c = 100);
        
        RecordType fvfRecordTypeListing = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c',EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE);
		Final_Value_Fee_FVF__c fvfListing = new Final_Value_Fee_FVF__c(RecordTypeId = fvfRecordTypeListing.Id, Seller_Name__c = sellerForApproveReject.Id, Final_Value_Fee_Stage__c=EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE, Budget_FVF_Exposure__c = 100);

        insert new Final_Value_Fee_FVF__c[]{fvf1,fvf2,fvf3,fvfListing};
        
		
 
        Test.startTest();

            ApproveRejectController.apexInit(fvf1.Id);
            ApproveRejectController.apexInit(fvfListing.Id);

            ApproveRejectController.apexDoApprove(fvf1.Id+'', 'Testing Comment');
            ApproveRejectController.apexDoReject(fvf2.Id+'', 'Testing Comment');
            ApproveRejectController.apexDoReject(fvf3.Id+'', 'Testing Comment');
            
            Final_Value_Fee_FVF__c f1 = [Select Id,Approved_Date__c,Rejected_Date__c From Final_Value_Fee_FVF__c where Id=:fvf1.Id];
            Final_Value_Fee_FVF__c f2 = [Select Id,Approved_Date__c,Rejected_Date__c From Final_Value_Fee_FVF__c where Id=:fvf2.Id];
            
            System.assert(f1.Approved_Date__c<>null, 'approved date populated');
            System.assert(f2.Rejected_Date__c<>null, 'rejected date populated');

        Test.stopTest();
    } 
    /*********************************************************************************************************************************
    @ Method:         testErrorApproveReject
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0016680 - [Dev Only] Apex Class Classification to upgrade API version 1/5
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  28.02.2025 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    @isTest
    static void testErrorApproveReject(){

        Account sellerForApproveReject = new Account (Name='Test Seller For Approve & Reject',EBH_OracleID__c='12345', EBH_RevRollup__c='UK');
        insert sellerForApproveReject;
        
        RecordType fvfRecordTypeSeller = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c',EBH_ConstantsUtility.FVF_SELLER_RECORDTYPE);
        Final_Value_Fee_FVF__c fvf1 = new Final_Value_Fee_FVF__c(RecordTypeId = fvfRecordTypeSeller.Id, Seller_Name__c = sellerForApproveReject.Id, Budget_FVF_Exposure__c = 100);
        Final_Value_Fee_FVF__c fvf2 = new Final_Value_Fee_FVF__c(RecordTypeId = fvfRecordTypeSeller.Id, Seller_Name__c = sellerForApproveReject.Id, Budget_FVF_Exposure__c = 100);
        Final_Value_Fee_FVF__c fvf3 = new Final_Value_Fee_FVF__c(RecordTypeId = fvfRecordTypeSeller.Id, Seller_Name__c = sellerForApproveReject.Id, Budget_FVF_Exposure__c = 100);
        
        RecordType fvfRecordTypeListing = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c',EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE);
		Final_Value_Fee_FVF__c fvfListing = new Final_Value_Fee_FVF__c(RecordTypeId = fvfRecordTypeListing.Id, Seller_Name__c = sellerForApproveReject.Id, Budget_FVF_Exposure__c = 100);

        insert new Final_Value_Fee_FVF__c[]{fvf1,fvf2,fvf3,fvfListing};

        Test.startTest();

            Map<String,string>  mapResult = new Map<String,string>();

            mapResult = ApproveRejectController.apexInit(fvf1.Id);
            System.assertEquals(true, mapResult.containsKey('msg'), 'expect msg exist' );

            mapResult = ApproveRejectController.apexInit(fvfListing.Id);
            System.assertEquals(true, mapResult.containsKey('msg'), 'expect msg exist'  );

            mapResult = ApproveRejectController.apexDoApprove(null, 'Testing Comment');
            System.assertEquals('ko', mapResult.get('status'), 'expect ko status' );

            mapResult = ApproveRejectController.apexDoReject(null, 'Testing Comment');
            System.assertEquals('ko', mapResult.get('status'), 'expect ko status' );
            
            // mapResult = ApproveRejectController.apexDoReject(fvf3.Id+'', 'Testing Comment');
            // System.assertEquals('ko', mapResult.get('status'), 'expect ko status' );
        

        Test.stopTest();

    }
}