/*********************************************************************************************************************************
@ Change history: 14.12.2022 / Bora Chhorn (bora.chhorn@gaea-sys.com) / US-0011835 - Clean Lead Layouts (Technical Debt)
*********************************************************************************************************************************/
@isTest
private class LX_QActionCreateProjectContrTest {
    @testSetup
    static void setup(){
        Lead oLead = new Lead();
        oLead.Status = 'Qualified';
        oLead.LeadSource = 'Self Gen';
        oLead.OtherLeadSource__c = 'test';
        oLead.LastName = 'Lead1';
        oLead.FirstName  =  'FirstTest';
        oLead.MobilePhone = '11223344';
        oLead.Phone = '11223344';
        oLead.Email = 'test@test.com';
        oLead.Website = 'www.ebay.com';
        oLead.EBH_Vertical__c = 'Collectibles';
        oLead.VAT_Number__c = '112233';
        oLead.Company = 'eBay';
        // oLead.RecordTypeId = ApexUtil.getRecordTypeByName('Lead','EBH_eBayAUEnterprise').Id; //BR-US-0011835
        oLead.RecordTypeId = ApexUtil.getRecordTypeByName('Lead','EBH_eBayAUSMB').Id;
        insert oLead;
    }

    @isTest
    static void doGetLeadTest(){
        Test.startTest();
            Lead oLead = [SELECT Id FROM Lead WHERE LastName =: 'Lead1'];
            Map<String, Object> mResult = LX_QActionCreateProjectContr.doGetLead(oLead.Id);
            System.assert(Boolean.valueOf(mResult.get('isSuccess')), 'Lead Status == Qualified can create AU Project');
        Test.stopTest();
    }
}