@isTest
private  class Batch_Disconnect_SEP_UsersTest {
    @TestSetup
    static void makeData(){
        User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 2];
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        Account portalAccount1;
        Contact contact1;
        System.runAs(admins[0])
        {
            //Create account
            portalAccount1 = new Account(
                Name = 'PORTAL__0001',
                eBay_API_User_Id__c = 'test_test_test',
                RecordTypeId = recSeller.Id,
                User_Disconnected__c = true
            );
 
            insert new List<Account>{portalAccount1};
            RecordType recSP = ApexUtil.getRecordTypeByName('Contact', 'Seller_Portal');
            RecordType recDWH = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
            contact1 = new Contact(
                FirstName = 'Test1111111111',
                Lastname = 'AMT_TEST',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test1@test.com',
                RecordTypeId=recSP.Id
            );
            
            insert new Contact[]{contact1};

            
        }
        

    }
    
    @IsTest
    static void testBatchDisconnect(){
        Account portalAccount1 = [Select Id,Name From Account Where Name='PORTAL__0001'];
        
        Batch_Disconnect_SEP_Users bat1 = new Batch_Disconnect_SEP_Users(new Set<String>{portalAccount1.Id});
        Test.startTest();            
            //Database.executeBatch(bat1);
            bat1.execute(null);
            
        Test.stopTest();
        portalAccount1 = [Select Id,Name,User_Disconnected__c From Account Where Id=:portalAccount1.Id];

        System.assertEquals(FALSE, portalAccount1.User_Disconnected__c,'flag cleared');

        bat1 = new Batch_Disconnect_SEP_Users();

       
    }
}