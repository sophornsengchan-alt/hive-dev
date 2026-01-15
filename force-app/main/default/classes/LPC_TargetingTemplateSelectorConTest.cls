/**
 * @author: GIS-DevTeam
 * @createdDate: 20/June/2018
 * @description: 
 *  - test class of LPC_TargetingTemplateSelectorController
 * @references: 
 *  - 
 * @changeLog:
 *
 */

@isTest
public class LPC_TargetingTemplateSelectorConTest {
	public static Opportunity opp;
    public static OpportunityLineItem item;
    public static Targeting__c targetting;
    public static Product2 prd;
    @testSetup static void setup() {
    	//create new targeting template
        Id RecId = Schema.SObjectType.Targeting__c.getRecordTypeInfosByName().get('Template').getRecordTypeId();
        Targeting__c targ = new Targeting__c();
        targ.Description__c = 'Tageting Template';
        targ.RecordTypeId = RecId;
        insert targ;

        Targeting__c t = new Targeting__c(TempBinder__c = true); 
        insert t;

		Account account = TST_DataGenerator.generateAccount();
        insert account;

        Opportunity opp = TST_DataGenerator.generateOpp(account.Id);
        insert opp;
        /* MN-14072021-No longer use with MediaPlan
        Media_Plan__c media = TST_DataGenerator.generateMediaPlan(opp);
        insert media;
        Quote quote = TST_DataGenerator.generateQuote(opp.Id, media.Id);
        */
        Quote quote = TST_DataGenerator.generateQuote(opp.Id);
        insert quote;
        Product2 product = TST_DataGenerator.generateProduct();
        insert product;
        PriceBookEntry pbe = TST_DataGenerator.generatePricebookEntry(product.Id,null);
        insert pbe;

        OpportunityLineItem oppItem = TST_DataGenerator.generateOpportunityLinItem(opp.Id, pbe.Id, t.Id);
       insert oppItem; 
    }
    static void getOppLineItems(){
         opp = [select id, Name, Owner.id, Owner.Name, AccountId from Opportunity limit 1];
         prd = [select Site__c, id from Product2 limit 1];
         item = [select id, OpportunityId from OpportunityLineItem where Description='Test Desc' and OpportunityId= :opp.Id];
    }
    static void getTargetting(){
        targetting = [select id from Targeting__c limit 1];
    }
    static Targeting__c targ;
    static{
        //create new targeting template
        Id RecId = Schema.SObjectType.Targeting__c.getRecordTypeInfosByName().get('Template').getRecordTypeId();

        targ = new Targeting__c();
        targ.Description__c = 'Tageting Template';
        targ.RecordTypeId = RecId;
        insert targ;
    }

    
    @isTest static void testTargetingTemplate() {
        getOppLineItems();
        getTargetting();

        Test.startTest();
            RemoteResponse response = LPC_TargetingTemplateSelectorController.initTemplateN(prd.Site__c);
            System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
            System.assert(response.content != null);

            RemoteResponse checkname = LPC_TargetingTemplateSelectorController.checkTemplateNameExist(targ.Description__c, prd.Site__c, false, item.Id);
            RemoteResponse checkNcreate = LPC_TargetingTemplateSelectorController.checkTemplateNameExist('Targeting Template 1', prd.Site__c, true, item.Id);
            System.assertEquals(checkNcreate.statusCode, RemoteResponse.STATUSCODE_ERROR);
           // System.assert(checkNcreate.content != null);
            
            RemoteResponse checkdataoli = LPC_TargetingTemplateSelectorController.checkTargetingNotEmptyData(item.Id);
            System.assertEquals(checkdataoli.statusCode, RemoteResponse.STATUSCODE_OK);
            System.assert(checkdataoli.content != null);

            item.DFP_Time_Wednesday__c = '0:00 - 0:59';
            update item;
            RemoteResponse checkdataoli1 = LPC_TargetingTemplateSelectorController.checkTargetingNotEmptyData(item.Id);
            System.assertEquals(checkdataoli1.statusCode, RemoteResponse.STATUSCODE_OK);
            System.assert(checkdataoli1.content != null);
            
            //cover code
            RemoteResponse rr1 = new RemoteResponse('Test', 0);
            rr1 = new RemoteResponse('test');

        Test.stopTest();
    }
}