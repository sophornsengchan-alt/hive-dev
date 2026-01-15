@isTest
private class DealSubAmendUploadControllerTest {

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
        Deal_Contract_Agreement__c sdca = new Deal_Contract_Agreement__c(eBay_Seller__c = acc2.id, Deal_Site__c = '0',Deal_Start_Date__c=Date.toDay(), Deal_End_Date__c = Date.toDay().addDays(10), Deal_Start_Time__c=System.Now().timeGmt(), Deal_End_Time__c=System.Now().timeGmt(), RecordTypeId=rtDCASub.Id);
        insert sdca;
        RecordType rtSubDeal = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2');
        EBH_Deal__c deal = new EBH_Deal__c();
        deal.EBH_ProductTitle__c = 'Item_Title11gg';
        deal.EBH_eBayItemID__c = '555555666666';
        deal.Deal_Contract_Agreement__c = sdca.Id;
        deal.RecordTypeId = rtSubDeal.Id;
        deal.EBH_SellerPrice__c = 100;
        deal.EBH_DealPrice__c = 90;
        deal.EBH_Status__c = 'Running';
        deal.EBH_RRPWASPrice__c = 200;
        deal.EBH_Quantity__c = 100;
        deal.EBH_DealSiteId__c = '101';
        deal.EBH_MaximumPurchases__c = 10;
        deal.EBH_BusinessName__c = acc2.id;
        deal.EBH_DealStartDate__c = Date.toDay().addDays(1);
        deal.EBH_DealStartTime__c = Time.newInstance(1,00,00,0);
        deal.EBH_DealEndDate__c = Date.toDay().addDays(3);
        deal.EBH_DealEndTime__c = Time.newInstance(23,59,59,0);
        insert deal;
    }    
    
    @IsTest
    static void testUpload(){
        String metadataName = 'Amend_Contracts_Upload_Deals';

        Test.startTest();
            
        Map<String,Object> mapResult = (Map<String, Object>)DealSubAmendUploadController.doLoadSetting(metadataName);
        System.assertEquals('success',mapResult.get('status')+'');
        mapResult = (Map<String, Object>)DealSubAmendUploadController.getAllDeals(new List<String>{'555555666666'},new List<String>{'555555666666'});
        System.assertEquals('success',mapResult.get('status')+'');
        List<EBH_Deal__c> lstDeals = (List<EBH_Deal__c>)mapResult.get('allDeals');
        Map<String,String> mapDCA = new Map<String,String>{'category'=>lstDeals[0].Deal_Contract_Agreement__r.Category__c,'vertical'=>lstDeals[0].Deal_Contract_Agreement__r.Vertical__c,'dealSite'=>lstDeals[0].Deal_Contract_Agreement__r.Deal_Site__c};
        Map<String,Map<String,String>> mapParams = new Map<String,Map<String,String>>{lstDeals[0].EBH_BusinessName__c=>mapDCA};
        List<EBH_Deal__c> listDeal = new List<EBH_Deal__c>();
        EBH_Deal__c deal = new EBH_Deal__c();
        deal.EBH_ProductTitle__c = 'Item_Title11gg';
        deal.EBH_SellerPrice__c = 100;
        deal.EBH_DealPrice__c = 90;
        deal.EBH_Quantity__c = 100;
        deal.EBH_BusinessName__c = lstDeals[0].EBH_BusinessName__c;
        deal.EBH_eBayItemID__c = '555555666667';
        deal.EBH_MaximumPurchases__c = 10;
        deal.EBH_DealSiteId__c = '101';
        deal.EBH_DealStartDate__c = System.now().addDays(1).date();
        deal.EBH_DealStartTime__c = Time.newInstance(1,00,00,0);
        deal.EBH_DealEndDate__c = System.now().addDays(7).date();
        deal.EBH_DealEndTime__c = Time.newInstance(23,59,59,0);
        listDeal.add(deal);

        system.debug('>>mapParams:'+mapParams);
        mapResult = (Map<String, Object>)DealSubAmendUploadController.submitDeals(listDeal,mapParams,new Map<String,String>());
        system.debug('>>mapResult:'+mapResult);
        System.assertEquals('success',mapResult.get('status')+'');
       
        Database.UpsertResult[] srList =  ( Database.UpsertResult[])JSON.deserialize(mapResult.get('srList')+'', List<Database.UpsertResult>.class);
        for(Database.UpsertResult srr : srList)
        {
            System.assertEquals(true, srr.isSuccess(),'Must be ok: '+srr.getErrors());
        }
         
        List<EBH_Deal__c> listDeal1 = [SELECT ID FROM EBH_Deal__c WHERE EBH_ProductTitle__c = 'Item_Title11gg' LIMIT 1];
        System.assertEquals(1,listDeal1.size(),'1 Deal is created');

        Test.stopTest();
        
    }
}