@Istest
private  class LookupControllerTest {
    
    private @IsTest
    static void testSearch(){
        Account acc1 = new Account(Name='Test accx1111xxx111',Primary_Contact_Email__c='test@test.com');
        insert acc1;
        Test.startTest();
            //test search
            // doSearch(String sobjType,String key,String displayEntity1,String displayEntity2,String displayEntity3)
            List<LookupController.DisplayEntity>  result1 = LookupController.doSearch('Account','Test accx1111xxx111','Name','Primary_Contact_Email__c','');
            //system.debug('>>result1: '+result1);
            System.assertEquals(2, result1.size(),'1 account row + 1 search row (top)');
            //
            //test full search
            //List<DisplayEntity> doFullSearch(String sobjectType,String key,String fullSearchFields,String sortClause)
            LookupController.MyField f1 = new LookupController.MyField();
            f1.name = 'Primary_Contact_Email__c';
            f1.pname = 'Primary_Contact_Email__c';
            f1.label = 'Primary Email';
            List<LookupController.MyField> fieldList = new List<LookupController.MyField>{f1};
            
            result1 = LookupController.doFullSearch('Account','accx1111xxx111',JSON.serialize(fieldList),' Order by Name ');

            //test describe fieltype
            //List<Map<String,String>> describeFieldsType(String sobjectType,String strFullSearchFields)
            List<Map<String,String>> listMapF = new List<Map<String,String>>{new Map<String,String>{'pname'=>'Primary_Contact_Email__c'}};

            List<Map<String,String>> dResult = LookupController.describeFieldsType('Account',JSON.serialize(listMapF));
        Test.stopTest();
        
    }
}