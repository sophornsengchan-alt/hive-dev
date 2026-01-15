/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
public class DealBudgetTriggerHandlerTest {
    
    static testMethod void testDealBudgetTriggerHandler() {
        
        List<EBH_DealsBudget__c> lstDB = new List<EBH_DealsBudget__c>();
        Map<Integer, String> mMonth = new Map<Integer, String>{
            1=> 'January', 
            2=> 'February', 
            3=> 'March', 
            4=> 'April',
            5=> 'May',
            6=> 'June',
            7=> 'July',
            8=> 'August',
            9=> 'September',
            10=> 'October',
            11=> 'November',
            12=> 'December'
        };

        for(Integer i=1; i<=4; i++){
        	EBH_DealsBudget__c db = new EBH_DealsBudget__c(Deal_Site__c='77', EBH_Vertical__c='Soft Home', EBH_Quarter__c = 'Q'+i);
        	lstDB.add(db);
        }
 
        insert lstDB;

        Test.startTest();
        List<EBH_DealsBudgetMonth__c> dbm = DealBudgetTriggerHandler.createDealBudgetMonth(lstDB);
        
        Integer i = 1;
        Date datobj = System.today();
        for(EBH_DealsBudgetMonth__c oneBDM : dbm){
        	System.assertEquals(mMonth.get(i), oneBDM.EBH_Month__c);
        	i++;
        }
       
        Test.stopTest();
    }
}