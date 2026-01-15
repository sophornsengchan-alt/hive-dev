/*********************************************************************************************************************************
@ Class:          DealWindowActiveDeactiveButtonCtrlTest
@ Version:        1.0
@ Author:         SRONG TIN (srong.tin@gaea-sys.com)
@ Purpose:        Test Controller Class for DealWindowActiveDeactiveButtonController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  19.07.2021 / SRONG TIN / Created the class.
*********************************************************************************************************************************/
@isTest
public class DealWindowActiveDeactiveButtonCtrlTest {
    public static final String NA_Unsub_Deal = 'Deal_V3';
    public static final String DRC_Deal_WINDOW = 'Deal_Campaign_V2';
    
	@testSetup static void setup(){
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Id dealRecordTypeId =  ApexUtil.getRecordTypeByName('EBH_Deal__c', NA_Unsub_Deal).Id;
        Id drcRecordTypeId = ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', DRC_Deal_WINDOW).Id;
    	Account acc = new Account(Name='Test se2',RecordTypeID = sellerRecordType.Id);
        insert acc;
        

        EBH_ActiveTriggers__c setting = new EBH_ActiveTriggers__c();
        setting.Name = 'EBH Trigger Controller';
        setting.DealRetailCampaign_Trigger__c = true;
        insert setting;
        Date startDate = System.today().addDays(20);
        Date endDate = System.today().addDays(21);
        DateTime dt = System.today();
        Time myTime = Time.newInstance(dt.hour(), dt.minute(), dt.second(), dt.millisecond());
        // create defualt spotlight category
        EBH_SpotlightCategory__c sc = new EBH_SpotlightCategory__c();
        sc.Name = Label.US_UnSubDeal_Default_Spotlight;
        sc.EBH_Country__c = 'US';
        sc.EBH_SpotlightCategoryID__c = '123456789012';
        sc.Spotlight_End_Date__c = endDate;
        sc.Spotlight_Start_Date__c = startDate;
        insert sc;

        EBH_DealRetailCampaign__c drc = new EBH_DealRetailCampaign__c(
            RecordTypeId = drcRecordTypeId,
            Status__c = 'Draft',
            EBH_DealTitle__c = 'SRO Test 001',
            Start_Retail_Week__c='2',
            EBH_Date__c = startDate,
            EPH_EndDate__c=endDate,
            End_Retail_Week__c = '5',
            EBH_Slots__c=3);
        insert drc;
        
    }
    @isTest 
    public static void test_method(){
        Test.startTest();
        EBH_DealRetailCampaign__c drc = [SELECT Id,Status__c FROM EBH_DealRetailCampaign__c WHERE EBH_DealTitle__c = 'SRO Test 001'];
        // isActivated is true
        DealWindowActiveDeactiveButtonController.activateDeactivateDRC(drc.Id, true);
        drc = [SELECT Id,Status__c FROM EBH_DealRetailCampaign__c WHERE Id = :drc.Id];
        System.assertEquals(drc.Status__c,'Pending');
        
        // isDeactivated is true
        DealWindowActiveDeactiveButtonController.activateDeactivateDRC(drc.Id, false);
        drc = [SELECT Id,Status__c FROM EBH_DealRetailCampaign__c WHERE Id = :drc.Id];
        System.assertEquals(drc.Status__c,'Draft');
       
        //  DRC was already activated and process.
        drc.Status__c = 'Open for Submissions';
        update drc;
        DealWindowActiveDeactiveButtonController.activateDeactivateDRC(drc.Id, false);
        drc = [SELECT Id,Status__c FROM EBH_DealRetailCampaign__c WHERE Id = :drc.Id];
        System.assertEquals(drc.Status__c,'Open for Submissions');
        
        // is error id
        Map<String,String> result = DealWindowActiveDeactiveButtonController.activateDeactivateDRC(null, false);
        System.assertEquals(result.get('status'),'ko');
        Test.stopTest();
    }
}