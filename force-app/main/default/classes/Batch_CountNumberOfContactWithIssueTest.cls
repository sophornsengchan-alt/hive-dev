/*********************************************************************************************************************************
@ Class:         Batch_CountNumberOfContactWithIssueTest
@ Version:       1.0
@ Author:        Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:       Test Class for Batch_CountNumberOfContactWithIssue
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.05.2018 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
@isTest
private class Batch_CountNumberOfContactWithIssueTest {
    static testMethod void testBatchCountNumberOfContact() {
            List<Account> lstAcc = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
            List<Contact> lstCont = new List<Contact>();
            for(Integer i = 0; i < 100; i++){
                Contact con = new Contact(LastName = 'testCountContact' + i, AccountId = lstAcc[0].Id, EBH_DataOrigin__c='test',EBH_Status__c='Active');
                con.Email_Bounced__c = false;
                con.Incorrect_Phone_Number__c = false;
                lstCont.add(con);
            }
            Test.startTest();
            insert lstCont;
            Batch_CountNumberOfContactWithIssue.runCountContactToAccount();
        Test.stopTest();
        List<Account> lstAccSel = [select Number_of_Contacts_with_Issues__c,Contact_Data_Quality__c from Account where id iN: lstAcc];
        System.assertEquals(0,lstAccSel[0].Number_of_Contacts_with_Issues__c,'0 Number of contact that are not green');
        System.assertEquals(EBH_ConstantsUtility.GREEN_CONTACT,lstAccSel[0].Contact_Data_Quality__c,'All Contacts of the Seller are Green => Green');
    }
}