/*****************************************************************************************************************************
@ Class:       LC_DateRangeDeliveryController
@ Author:      Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:     US-0008370 - Upgrade code coverage of LC_DateRangeDeliveryController from 0% to 85% [ lines not covered 11]
------------------------------------------------------------------------------------------------------------------------------
@ Change history:  21.04.2021 / Mony Nou / Created the method.
@*****************************************************************************************************************************/
@IsTest 
private class LC_DateRangeDeliveryControllerTest {
    
    @isTest
    static void test_importDFPDelivery () {

        Test.startTest();

            Id adServerDartRTId = ApexUtil.getRecordTypeByName('AdServer_Login__c','DART6').Id;
            AdServer_Login__c adServer = new AdServer_Login__c(
                Name = 'US',
                Login_URL__c='http://test.com',
                User_Name__c='dart6testuser@gmail.com',
                Password__c ='testpwddart6123456',
                Active__c = true,
                Network_ID__c='123456',
                Client_ID__c = 'xxxxxxxxxxxxxxxxxxxxx',
                Client_Secret__c = 'xxxxxxxxxxxxxxx',
                Refresh_Token__c = 'xxxxxxxxxxx',
                RT_Waiting__c = true,
                RecordTypeId = adServerDartRTId
            );
            insert adServer;
            
            Site__c site = TST_DataGenerator.generateSite();
            site.Name = 'US';
            site.Country__c = 'US';
            site.currencyIsoCode = 'USD';
            insert site;
            
            RemoteResponse result = LC_DateRangeDeliveryController.importDFPDelivery(site.Id, String.valueOf(Date.today()), String.valueOf(Date.today().addDays(7)));

            System.debug('#### result :: ' + result);

        Test.stopTest();
    }
}