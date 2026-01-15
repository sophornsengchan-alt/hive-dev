@istest
private class ApexSafeTest {
    
    @TestSetup
    static void makeData(){

        insert new Account(name='test-007');

    }



    private @IsTest
    static void testDml_insert(){

        Test.startTest();

            Database.SaveResult[] res = ApexSafe.dml().doInsert(new List<Sobject>{new Account(Name='test-001')},true);
            
            //assert
            List<Account> resAccount = [SELECT Id, Name FROM Account WHERE Name = 'test-001'];
            System.assert( !resAccount.isEmpty() , 'There should be one account with name test-001');           
            

            //by pass security check
            ApexSafe.dml().secCheck(false).doInsert(new List<Sobject>{new Account(Name='test-001abxyz')},true);
            //assert
            resAccount = [SELECT Id, Name FROM Account WHERE Name = 'test-001abxyz'];
            System.assert( !resAccount.isEmpty() , 'There should be one account with name test-001abxyz');
            
            Database.DMLOptions dlo = new Database.DMLOptions();
            dlo.OptAllOrNone = true;
            ApexSafe.dml().setDMLOPtion(dlo).doInsert(new List<Sobject>{new Account(Name='test-001abxyzddaaa')},true);

            resAccount = [SELECT Id, Name FROM Account WHERE Name = 'test-001abxyzddaaa'];
            System.assert( !resAccount.isEmpty() , 'There should be one account with name test-001abxyzddaaa');
        Test.stopTest();
     
    }

    private @IsTest
    static void testDml_update(){
        
        Test.startTest();

            List<Account> lstAccount = [SELECT Id, Name FROM Account WHERE Name = 'test-007'];
            
            lstAccount[0].Name = 'test-007 updated';

            Database.SaveResult[] res = ApexSafe.dml().doUpdate(lstAccount,true);
            //assert
            List<Account> resAccount = [SELECT Id, Name FROM Account WHERE Name = 'test-007 updated'];
            System.assert( !resAccount.isEmpty() , 'There should be one account with name test-007 updated');

            //by pass security check
            lstAccount[0].Name = 'test-007 updated again';
            ApexSafe.dml().secCheck(false).doUpdate(lstAccount,true);
            //assert
            resAccount = [SELECT Id, Name FROM Account WHERE Name = 'test-007 updated again'];
            System.assert( !resAccount.isEmpty() , 'There should be one account with name test-007 updated again');
            
        
        Test.stopTest();
     
    }

    private @IsTest
    static void testDml_upsert(){
        
        Test.startTest();


            List<Account> lstAccount = [SELECT Id, Name FROM Account WHERE Name = 'test-007'];
            
            lstAccount[0].Name = 'test-007 upserted';

            lstAccount.add(new Account(Name='test-008'));

            Database.UpsertResult[] res = ApexSafe.dml().doUpsert(lstAccount, Account.Id, true);
            //assert
            List<Account> resAccount = [SELECT Id, Name FROM Account WHERE Name IN ('test-007 upserted','test-008')];
            System.assert( !resAccount.isEmpty() && resAccount.size() == 2 , 'There should be one account with name test-007 upserted and one with name test-008');

            //by pass security check
            lstAccount[0].Name = 'test-007 upserted again';
            lstAccount[1].Name = 'test-008 upserted';
            ApexSafe.dml().secCheck(false).doUpsert(lstAccount, Account.Id, true);
            //assert
            resAccount = [SELECT Id, Name FROM Account WHERE Name IN ('test-007 upserted again','test-008 upserted')];
            System.assert( !resAccount.isEmpty() && resAccount.size() == 2 , 'There should be one account with name test-007 upserted again and one with name test-008 upserted');
            
        
        Test.stopTest();
     
    }

    private @IsTest
    static void testDml_delete(){
        
        Test.startTest();


            List<Account> lstAccount = [SELECT Id, Name FROM Account WHERE Name = 'test-007'];
            
            Database.DeleteResult[] res = ApexSafe.dml().doDelete(lstAccount,true);
            //assert
            List<Account> resAccount = [SELECT Id, Name FROM Account WHERE Name = 'test-007'];
            System.assert( resAccount.isEmpty() , 'There should be no account with name test-007');
            
            //by pass security check
            ApexSafe.dml().doInsert(new List<Sobject>{new Account(Name='test-008')},true);
            lstAccount = [SELECT Id, Name FROM Account WHERE Name = 'test-008'];
            ApexSafe.dml().secCheck(false).doDelete(lstAccount,true);

            //assert
            resAccount = [SELECT Id, Name FROM Account WHERE Name = 'test-008'];
            System.assert( resAccount.isEmpty() , 'There should be no account with name test-008');
        
        Test.stopTest();
     
    }

    private @IsTest
    static void testQuery(){
        
        //1 set up user

        //2, run as user
        Test.startTest();
        // System.runAs(contextuser){
          
            //4 case  query wit binding - binding var name and  value map (:Name=>test-007) - Case sensitive!!!
            Map<String, Object> mapa = new Map<String, Object>{'Name'=>ApexUtil.closeSQoute('test-007')};  //Casesensitive!!!
            String soql = 'select id, name from account where name=:Name';
            List<Sobject> result = ApexSafe.query().doQuery(soql,mapa);
            //assert result with field that should be visible
            
            //5, query without binding - here binding alredy done inside soql
            soql = 'select id, name from account where name=\'test-007\'';
            result = ApexSafe.query().doQuery(soql);
            //asser...

            //6, case bypass sec check
            //bypass sec check
            result = ApexSafe.query().secCheck(false).doQuery(soql,mapa);
            //assert result with field that should not be visible

            // Without sharing
            result = ApexSafe.query(true).secCheck(false).doQuery(soql,mapa);

        // }
        Test.stopTest();

       
       
        
    }

    private @IsTest
    static void testCount(){
        
        
        Test.startTest();
        
          
            Integer count = ApexSafe.query().doCount('select count() from account');
            //assert
            System.assert( count > 0 , 'There should be at least one account');

            //bypass sec check
            count = ApexSafe.query().secCheck(false).doCount('select count() from account');
            //assert
            System.assert( count > 0 , 'There should be at least one account');

        
        Test.stopTest();

       
       
        
    }
}