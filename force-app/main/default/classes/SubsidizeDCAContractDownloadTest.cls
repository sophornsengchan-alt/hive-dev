@isTest
private class SubsidizeDCAContractDownloadTest {
    @TestSetup
    static void makeData(){
        EBH_TestDataFactory.setUpCustomSettings();

        //create an account
        Account acc = new Account( Name = 'TestAccount', SP_Deals__c='Full Access', NA_Deal_Program_Vetted__c = true, SP_Main_Domain__c = SEP_Helper.SEP_Domain_NA);
        insert acc;

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,
                                    FirstName='test fn', LastName='test ln', AccountId=acc.Id, Email = 'test123@test.com');
        insert con;
        
        Date today = System.today();
        Date dDate = Date.newInstance( today.year()+1, today.month()+1, 1);
        RecordType rtSubsidizeDCA = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c','Subsidized_Deals');
        Deal_Contract_Agreement__c pmDca = new Deal_Contract_Agreement__c(
            eBay_Seller__c = acc.Id,
            Title__c = 'Test Title',
            Deal_Start_Date__c = dDate,
            Deal_End_Date__c = dDate+10,
            RecordTypeId = rtSubsidizeDCA.Id

        );

        insert pmDca;
    }

    @IsTest
    static void testDownload(){
        Deal_Contract_Agreement__c dca = [SELECT Title__c, Name, CreatedDate FROM Deal_Contract_Agreement__c LIMIT 1];
        Contact con = [SELECT Id,Email FROM Contact WHERE FirstName='test fn' AND LastName='test ln' limit 1];

        User user1 = SEPTestGenerator.createSEPUser('sepUsersdcdc1', con.Id);
        PermissionSetGroup psg = [SELECT Id, Status FROM PermissionSetGroup WHERE DeveloperName = 'Seller_Portal_NA'];
        if (psg.Status != 'Updated') {
            Test.calculatePermissionSetGroup(psg.Id);
        }
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = user1.Id,
            PermissionSetGroupId = psg.Id
        );
        insert psa;
        Test.startTest(); 

        System.runAs(user1) {

            Pagereference pdfPage = Page.SubsidizeDCAContractDownloadPage;
            pdfPage.getParameters().put('id',dca.Id);
            
            Test.setCurrentPage(pdfPage);
            SubsidizeDCAContractDownloadController cont = new SubsidizeDCAContractDownloadController();

            Map<String,String> mapAtt = SubsidizeDCAContractDownloadController.createAttachment(dca);
            System.assert(mapAtt.get('id') <> null,'Attachment created');
        
        }   
        

        Test.stopTest();
    }
}