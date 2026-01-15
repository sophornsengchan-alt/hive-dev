@isTest
private class DealBulkUploadDcaSubControllerTest {
    
    @TestSetup
    static void makeData(){
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller',Deal_Contract_Agreement_Trigger__c=true);
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account','EBH_Seller');       
        Account acc2 = new Account( Name = 'Seller2', SP_Promotions_Manager__c='Full Access',RecordTypeId = recSeller.Id,NA_Deal_Program_Vetted__c = true);
        insert new List<Account>{acc2};

        RecordType rtDWH = ApexUtil.getRecordTypeByName('Contact','EBH_DWH');
        RecordType rtSP = ApexUtil.getRecordTypeByName('Contact','Seller_Portal');

        Contact conDWH1 = new Contact(Contact_Role__c='Deals',RecordTypeId=rtDWH.Id,FirstName='test', LastName='DWH007', AccountId=acc2.Id, Email = 'dwh_test007@test007.com');
        Contact conSP1 = new Contact(Contact_Role__c='Deals',RecordTypeId=rtSP.Id,FirstName='test', LastName='SP007', AccountId=acc2.Id, Email = 'sp_test007@test007.com');
        insert new List<Contact>{conDWH1,conSP1};

        RecordType rtDCASub = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals');
        Deal_Contract_Agreement__c sdca = new Deal_Contract_Agreement__c(eBay_Seller__c = acc2.id, Deal_Site__c = '0',Deal_Start_Date__c=Date.newInstance(2023, 1, 1), Deal_End_Date__c =Date.newInstance(2023, 1, 10), Deal_Start_Time__c=System.Now().timeGmt(), Deal_End_Time__c=System.Now().timeGmt(), RecordTypeId=rtDCASub.Id);
        insert sdca;

      
    }    

    @IsTest
    static void testUpload(){
        String metadataName = 'SEP_Upload_Deal_DCA';

        Deal_Contract_Agreement__c dca = [SELECT ID,eBay_Seller__c  FROM Deal_Contract_Agreement__c WHERE eBay_Seller__r.Name='Seller2' LIMIT 1];
        Contact cont = [Select Id From Contact Where LastName = 'DWH007'Limit 1];
        Test.startTest();
            
        Map<String,Object> mapResult = (Map<String, Object>)DealBulkUploadDcaSubController.doLoadSettingLinkedAccount(metadataName,dca.Id,dca.eBay_Seller__c);
        System.assertEquals('success',mapResult.get('status')+'');

        Map<String,String> mapParams = new Map<String,String>{'accountId'=>dca.eBay_Seller__c,'dcaId'=>dca.Id,'contactId'=>cont.Id,'fullContactName'=>'test DWH007','email'=>'dwh_test007@test007.com'};
        List<EBH_Deal__c> listDeal = new List<EBH_Deal__c>();
        EBH_Deal__c deal = new EBH_Deal__c();
            deal.EBH_ProductTitle__c = 'Item_Title11gg';
            deal.EBH_SellerPrice__c = 100;
            deal.EBH_DealPrice__c = 90;
            deal.EBH_RRPWASPrice__c = 200;
            deal.EBH_Quantity__c = 100;
            deal.EBH_MaximumPurchases__c = 10;
            deal.EBH_DealStartDate__c = System.now().addDays(1).date();
            deal.EBH_DealStartTime__c = Time.newInstance(1,00,00,0);
            deal.EBH_DealEndDate__c = System.now().addDays(2).date();
            deal.EBH_DealEndTime__c = Time.newInstance(23,59,59,0);
            deal.EBH_CommentfromSeller__c = 'test';
            listDeal.add(deal);

        mapResult = (Map<String, Object>)DealBulkUploadDcaSubController.submitDeals(listDeal,mapParams);
        System.assertEquals('success',mapResult.get('status')+'');
       
        Database.SaveResult[] srList =  ( Database.SaveResult[])JSON.deserialize(mapResult.get('srList')+'', List<Database.SaveResult>.class);
        for(Database.SaveResult srr : srList)
        {
            System.assertEquals(true, srr.isSuccess(),'Must be ok: '+srr.getErrors());
        }
         
        List<EBH_Deal__c> listDeal1 = [SELECT ID FROM EBH_Deal__c WHERE EBH_ProductTitle__c = 'Item_Title11gg' LIMIT 1];
        System.assertEquals(1,listDeal1.size(),'1 Deal is created');

        DealBulkUploadDcaSubController.SubDealUploadDCAPostDMLSEP subUPload = new DealBulkUploadDcaSubController.SubDealUploadDCAPostDMLSEP();
        Map<String,String>postData = new Map<String,String>{'parentId'=>dca.Id};
        mapResult = ExcelImporterControllerSEP.apexProcessPostDMLSEP(postData,metadataName);
        System.assertEquals('ok',mapResult.get('status')+'',mapResult.get('error')+' \ndetail:'+mapResult.get('detail'));

        Map<String,String> mapParams1 = new Map<String,String>{'category'=>'Watches','catManagerEmail'=>'invalidemail99@test.inv'};
        mapResult = DealBulkUploadDcaSubController.createNewDca(mapParams1);

        System.assertEquals('ok',mapResult.get('status')+'',mapResult.get('error')+' \ndetail:'+mapResult.get('detail'));

        mapParams1 = new Map<String,String>{'category'=>'Watches','catManagerEmail'=>UserInfo.getUserEmail()};
        mapResult = DealBulkUploadDcaSubController.createNewDca(mapParams1);
        System.assertEquals('ok',mapResult.get('status')+'',mapResult.get('error')+' \ndetail:'+mapResult.get('detail'));


    Test.stopTest();
        
    }
}