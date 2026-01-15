/**
 * ...
 * //22.07.2024/ vadhanak voun/ US-0015373 - Align Apex Classes with Deactivated FVF_Campaign Record Type
 */
@isTest
private class BatchUpdateFVFStageTest {
     
    @isTest
    static void test_UpdateFVFStage_Decline() {

        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id, EBH_RevRollup__c = 'UK');
    	insert acc;
		
		RecordType fvfRecordType = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c','FVF_Seller_Level');
    	Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(
            Seller_Name__c=acc.Id, 
            RecordTypeId =fvfRecordType.Id, 
            Seller_Email__c='test@test.com',
            Site__c='UK',
            Start_Date_w__c = Date.today(),
            End_Date_w__c = Date.today(),
            Final_Value_Fee_Stage__c = 'eBay Approved'

        );
        insert fvf;

        Test.startTest();
            SchedulableContext sc = null;
            BatchUpdateFVFStage b = new BatchUpdateFVFStage();
            b.execute(sc);
        Test.stopTest();

        for (Final_Value_Fee_FVF__c f : [SELECT Final_Value_Fee_Stage__c, Contract_Decline_Reasons__c FROM Final_Value_Fee_FVF__c WHERE Id=:fvf.Id]) {
            System.assert( f.Final_Value_Fee_Stage__c == 'Contract Declined', 'FVF Stage should be updated to "Contract Declined".');
            System.assert( f.Contract_Decline_Reasons__c == 'Auto decline', 'Contract Decline Reason should be updated to "Auto decline".');
        }

    }

    @isTest
    static void test_UpdateFVFStage_Running() {

        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id, EBH_RevRollup__c = 'UK');
    	insert acc;
		
		RecordType fvfRecordType = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c','FVF_Listing_Level');
    	Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(
            Seller_Name__c=acc.Id, 
            RecordTypeId =fvfRecordType.Id, 
            Seller_Email__c='test@test.com',
            Site__c='UK',
            Start_Date_w__c = Date.today(),
            End_Date_w__c = Date.today(),
            Final_Value_Fee_Stage__c = 'Contract Signed'

        );
        insert fvf;

        Test.startTest();
        BatchUpdateFVFStage b = new BatchUpdateFVFStage(new Set<String>{fvf.Id});
        Database.executeBatch(b, 1);
        Test.stopTest();

        for (Final_Value_Fee_FVF__c f : [SELECT Final_Value_Fee_Stage__c FROM Final_Value_Fee_FVF__c WHERE Id=:fvf.Id]) {
            System.assert( f.Final_Value_Fee_Stage__c == 'Running Contract', 'FVF Stage should be updated to "Running Contract": '+ f.Final_Value_Fee_Stage__c);
        }

    }

    @isTest
    static void test_UpdateFVFStage_Executed() {

        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id, EBH_RevRollup__c = 'UK');
    	insert acc;
		
		RecordType fvfRecordType = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c','FVF_Seller_Level');
    	Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(
            Seller_Name__c=acc.Id, 
            RecordTypeId =fvfRecordType.Id, 
            Seller_Email__c='test@test.com',
            Site__c='UK',
            Start_Date_w__c = Date.today().addDays(-1),
            End_Date_w__c = Date.today(),
            Final_Value_Fee_Stage__c = 'Running Contract'

        );
        insert fvf;

        Test.startTest();
        BatchUpdateFVFStage b = new BatchUpdateFVFStage();
        Database.executeBatch(b, 1);
        Test.stopTest();

        for (Final_Value_Fee_FVF__c f : [SELECT Start_Date_w__c, End_Date_w__c, Final_Value_Fee_Stage__c FROM Final_Value_Fee_FVF__c WHERE Id=:fvf.Id]) {
            System.assert( f.Final_Value_Fee_Stage__c == 'Executed Contract', 'FVF Stage should be updated to "Executed Contract".');
        }

    }
    
}