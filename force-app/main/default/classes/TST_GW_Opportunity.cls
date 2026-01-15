/***
 * @author: SRONG TIN
 * @createdDate: 05/July/2018
 * @description: 
 *  - test class of GW_Opportunity
 *  - coverage : 100%
 * @references: 
 *  - 
 * @changeLog:
 *
 */
@isTest
private class TST_GW_Opportunity {

	public static Account account;
	public static Opportunity opp;

	@testSetup static void setup(){
		//
	}

	static testMethod void testOpportunity(){
			
        account = TST_DataGenerator.generateAccount();
        insert account;
        opp = TST_DataGenerator.generateOpp(account.Id);
        opp.IO_Paper__c = 'IAB 3.0 terms';
        opp.StageName = 'Qualified Meeting';
        insert opp;


        Test.startTest();

        //Media_Plan__c mediaPlan = GW_Opportunity.convertOppToMediaPlan(opp); 
        //insert mediaPlan;

        //System.assert(mediaPlan != null);

        // GW_Opportunity.createMediaPlan(new Set<String>{opp.Id});
        // opp =(Opportunity) QueryUtil.queryRecord(opp.Id);
        // System.assertNotEquals(opp.Media_Plan__c, null );
        //GW_Opportunity.setDefaultFromRelation(oppList);

        Test.stopTest();
	}
}