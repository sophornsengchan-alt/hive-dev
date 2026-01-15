/**
 * @Description Test unit for cover code in Deal Retail Campaign class
 * @date        09/09/2021
 * @author      Samnang MUONG
 */

@isTest
private class DealRetailCampaignTest {
   
    @TestSetup
    static void makeData(){

        // create Deal Retail Campaign
        List<EBH_DealRetailCampaign__c> lstDRC = new List<EBH_DealRetailCampaign__c>();

        String recId = Schema.sObjectType.EBH_DealRetailCampaign__c.getRecordTypeInfosByName().get('Standard Campaign').getRecordTypeId();

        for (Integer i=0; i<10; i++) {
            lstDRC.add(new EBH_DealRetailCampaign__c( RecordTypeId=recId, EBH_Country__c='0', EBH_DealTitle__c='test '+i, EBH_Date__c=system.today(), EPH_EndDate__c=system.today()+1, End_Retail_Week__c='1', Quarter__c='Q1'));
        }

        insert lstDRC;
        
    }

    @isTest static void testFetchRetailCampaign() {
        Test.startTest();

        List<EBH_DealRetailCampaign__c> lstResults = DealRetailCampaignCtrl.fetchDealRetailCampaignBySite('');

        System.assertEquals(0, lstResults.size());
         Test.stopTest();
    }
}