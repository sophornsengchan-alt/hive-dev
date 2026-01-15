@isTest
private class SEPDCAContractDownloadControllerTest {
    
    @TestSetup
    static void makeData(){
         
        EBH_TestDataFactory.setUpCustomSettings();

    	//create an account
        Account acc = new Account( Name = 'TestAccount', SP_Promotions_Manager__c='Full Access', NA_Deal_Program_Vetted__c = true, SP_Main_Domain__c = SEP_Helper.SEP_Domain_NA); //MN-10062024-US-0015298
        insert acc;

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,
                                    FirstName='test fn', LastName='test ln', AccountId=acc.Id, Email = 'test123@test.com');
        insert con;
        
        Date today = System.today();
        Date dDate = Date.newInstance( today.year()+1, today.month()+1, 1);
        RecordType rtPMDealDCA = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c','Promotions_Manager_Deals');
        Deal_Contract_Agreement__c pm_dca = new Deal_Contract_Agreement__c(
            eBay_Seller__c = acc.Id,
            Title__c = 'Test Title',
            Deal_Start_Date__c = dDate,
            Deal_End_Date__c = dDate+10,
            Merchant_Approver__c = UserInfo.getUserId(),
            Category__c = 'Antiques',
            eBay_Funding__c = 10,
            Max_Total_Subsidy__c = 1000,
            Max_Unit_Subsidy__c = 1000,
            RecordTypeId = rtPMDealDCA.Id

        );

        insert pm_dca;
    }

    @IsTest
    static void testDownload(){
   
        Deal_Contract_Agreement__c dca = [SELECT eBay_Seller__r.Name, eBay_Seller__r.EBH_RevRollup__c, Title__c, eBay_Funding__c, Deal_Page_Placement__c, 
        Deal_Start_Date__c, Deal_Start_Time__c, Deal_End_Date__c, Deal_End_Time__c, Discount_Applied_in_Cart__c, 
        Max_Total_Subsidy__c, Max_Unit_Subsidy__c, CurrencyIsoCode 
        FROM Deal_Contract_Agreement__c LIMIT 1];

        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount' limit 1];
        Contact con = [SELECT Id,Email FROM Contact WHERE FirstName='test fn' AND LastName='test ln' limit 1];

        User user1 = SEPTestGenerator.createSEPUser('sepUsersdcdc1', con.Id); //MN-10062024-US-0015298

        SEPTestGenerator.assignPermissionSetGroupToUser('Seller_Portal_NA', user1.Id);

        Test.startTest(); 

        System.runAs(user1) {

            Pagereference pdfPage = Page.SEPDCAContractDownloadPage;
            pdfPage.getParameters().put('id',dca.Id);
            
            Test.setCurrentPage(pdfPage);
            SEPDCAContractDownloadController cont = new SEPDCAContractDownloadController();

            Map<String,String> mapAtt = SEPDCAContractDownloadController.createAttachment(dca);
            System.assert(mapAtt.get('id') <> null,'Attachment created');
        
        }   
        

        Test.stopTest();
        
    }
}