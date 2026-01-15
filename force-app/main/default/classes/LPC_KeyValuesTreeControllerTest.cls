/**
 * Test class for LPC_KeyValuesTreeController
 */
@isTest
private class LPC_KeyValuesTreeControllerTest {
   
    @testSetup static void setup(){
    	TestDARTCodeCoverage.createTestUser();
        TestDARTCodeCoverage.createCredential('DE');
        TestDARTCodeCoverage.createTargetingKVHierarchy();
    }

    @isTest
    static void test_getGAMValueTreeStructure() {

        Test.startTest();

            List<GAM_Key_Value__c> lstKey = [SELECT Id, Name FROM GAM_Key_Value__c WHERE RecordType.Name = 'Key'];
            List<GAM_Key_Value__c> lstChildVal = new List<GAM_Key_Value__c>();
            String parValId;
            for (GAM_Key_Value__c par_val : [SELECT Id, Name, Disaplay_Name__c, RecordTypeId FROM GAM_Key_Value__c WHERE Parent__c=:lstKey.get(0).Id LIMIT 1]) {
                
                lstChildVal.add(new GAM_Key_Value__c(
                    Name='Test', 
                    Disaplay_Name__c = 'Test',
                    Parent__c = lstKey.get(0).Id,
                    Parent_Node__c = par_val.Id,
                    RecordTypeId = par_val.RecordTypeId
                ));

                parValId = par_val.Id;
            }

            insert lstChildVal;

            //-Find Parent Node
            Map<String,Object> result = LPC_KeyValuesTreeController.getGAMValueTreeStructure(lstKey.get(0).Id, '', '', true);
            System.assert(result != null && !result.isEmpty(), 'There should be an Tree Attributes store in the result map.');
            
            //-Find Child Node
            result = LPC_KeyValuesTreeController.getGAMValueTreeStructure(lstKey.get(0).Id, parValId, '', false);
            System.assert(result != null && !result.isEmpty(), 'There should be an Tree Attributes store in the result map.');

                

        Test.stopTest();
    }
}