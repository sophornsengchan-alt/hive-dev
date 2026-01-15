@isTest
private  class CancelSubDealDCADetailControllerTest {
    @TestSetup
    static void makeData()
    {
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

        RecordType rtDealSub = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2');
        //EBH_Deal__c sdeal = new EBH_Deal__c(EBH_Status__c='In Approval',EBH_Quantity__c=100,Seller_Approver_1__c=conDWH1.Id,EBH_MaximumPurchases__c=10,EBH_DealSiteId__c='0',EBH_DealPrice__c=100,EBH_SellerPrice__c=200,EBH_BusinessName__c=acc2.Id,Deal_Contract_Agreement__c=sdca.Id,RecordTypeId=rtDealSub.Id);
        List<EBH_Deal__c> listDeals = new List<EBH_Deal__c>();
        for(Integer i=0; i<5; i++)
        {
            listDeals.add(
                new EBH_Deal__c(EBH_Status__c='In Approval',EBH_Quantity__c=100,Seller_Approver_1__c=conDWH1.Id,EBH_MaximumPurchases__c=10,EBH_DealSiteId__c='0',EBH_DealPrice__c=100,EBH_SellerPrice__c=200,EBH_BusinessName__c=acc2.Id,Deal_Contract_Agreement__c=sdca.Id,RecordTypeId=rtDealSub.Id)
            );
           
        }
        insert listDeals;
    }

    @IsTest
    static void  testCancelSubDealDCADetail()
    {
        Deal_Contract_Agreement__c dca = [SELECT ID  FROM Deal_Contract_Agreement__c WHERE eBay_Seller__r.Name='Seller2' LIMIT 1];

        Test.startTest();

            Map<String,Object> result = CancelSubDealDCADetailController.apexInit(dca.Id);
            System.assertEquals('ok',result.get('status')+'');
            System.assertEquals(5,Integer.valueOf(result.get('numDeals')));
            
            result = CancelSubDealDCADetailController.apexCancelDeals(dca.Id,'Internal Hold',0);
            System.assertEquals(null,result.get('error'),'no error occurs');             

            dca = [SELECT ID,Status__c  FROM Deal_Contract_Agreement__c WHERE Id =:dca.Id];
            System.assertEquals(CancelSubDealDCADetailController.DCA_STATUS_CANCELLED,dca.Status__c);

            result = CancelSubDealDCADetailController.apexCancelDeals(dca.Id,'Internal Hold',1);
            result = CancelSubDealDCADetailController.apexCancelDeals(dca.Id,'Internal Hold',2);
            result = CancelSubDealDCADetailController.apexCancelDeals(dca.Id,'Internal Hold',3);
            result = CancelSubDealDCADetailController.apexCancelDeals(dca.Id,'Internal Hold',4);
            result = CancelSubDealDCADetailController.apexCancelDeals(dca.Id,'Internal Hold',5);
            System.assertEquals(null,result.get('error'),'no error occurs');
            System.assertEquals(true,Boolean.valueOf(result.get('done')),'no more deals to cancel');

            List<EBH_Deal__c> listDeal = [Select Id,EBH_Status__c from EBH_Deal__c where Deal_Contract_Agreement__c =:dca.Id];
            for(EBH_Deal__c oneDeal : listDeal  )
            {
                System.assertEquals(CancelSubDealDCADetailController.DEALSTATUS_CANCELLED,oneDeal.EBH_Status__c);
            }
            
        Test.stopTest();

    }
}