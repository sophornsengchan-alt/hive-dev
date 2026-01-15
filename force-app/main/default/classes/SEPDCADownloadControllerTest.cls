@isTest
private class SEPDCADownloadControllerTest {
    
    @TestSetup
    static void makeData(){
         
        EBH_TestDataFactory.setUpCustomSettings();

    	//create an account
        Account acc = new Account( Name = 'TestAccount', SP_Deals__c='Full Access', NA_Deal_Program_Vetted__c = true);
        insert acc;

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,
                                    FirstName='test fn', LastName='test ln', AccountId=acc.Id, Email = 'test123@test.com');
        insert con;
        
        Date today = System.today();
        Date dDate = Date.newInstance( today.year()+1, today.month()+1, 1);
        Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c();
        ndca.RecordTypeId = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals').Id;
        ndca.eBay_Seller__c = acc.Id;
        ndca.Seller_Accepted__c = datetime.now();
        ndca.Seller_Name__c = acc.Name;
        ndca.Seller_Response_Time__c = System.now().time();
        insert ndca;

        RecordType subDealRecordType = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V2');
        Id devRecordTypeId = subDealRecordType.Id;

        EBH_SpotlightCategory__c spotCat = new EBH_SpotlightCategory__c(Name = 'test spotLightCat',EBH_Country__c ='IT');
        insert spotCat;

        Date myDate = System.today().addDays(1); // 28.05.2021 / Sophal Noch / US-0009533
        EBH_Deal__c d1 = new EBH_Deal__c(EBH_eBayItemID__c  = '000000000010', Seller_Approver_1__c = con.Id,EBH_BusinessName__c =acc.ID,EBH_SpotlightCategory__c = spotCat.Id,RecordTypeId=devRecordTypeId,EBH_SellerPrice__c =20,EBH_DealPrice__c =5,EBH_Quantity__c =20,EBH_DealStartDate__c =myDate,EBH_DealEndDate__c =myDate,EBH_Status__c='Sent to Seller',EBH_DealSiteId__c = '101',EBH_Vertical__c = 'Home & Garden',EBH_Category__c ='Home & Garden',Sub_Category__c='Bedding', EBH_ProductTitle__c ='product 1',EBH_SellerEmail__c ='sales@test.com',Deal_Contract_Agreement__c=ndca.Id,EBH_MaximumPurchases__c=10);
        insert d1;
    }

    @IsTest
    static void testDownload(){
   
        Deal_Contract_Agreement__c dca = [SELECT Id,Name,CreatedDate,Seller_Response_Time__c,Seller_Accepted__c,Seller_Name__c FROM Deal_Contract_Agreement__c LIMIT 1];

        EBH_Deal__c deal = [SELECT Id FROM EBH_Deal__c limit 1];

        Test.startTest(); 

            Pagereference pdfPage = Page.SEPDCADownloadPage;
            pdfPage.getParameters().put('id',dca.Id);
            
            Test.setCurrentPage(pdfPage);
            SEPDCADownloadController cont = new SEPDCADownloadController();

            Map<String,String> mapAtt = SEPDCADownloadController.createAttachment(dca);
            System.assert(mapAtt.get('id') <> null,'Attachment created');

        Test.stopTest();
        
    }
}