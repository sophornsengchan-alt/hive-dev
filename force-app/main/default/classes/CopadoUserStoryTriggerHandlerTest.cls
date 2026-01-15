@istest
private class CopadoUserStoryTriggerHandlerTest {
    @testSetup
    public static void setupdata(){
         insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller',
                                         CopadoUserStory__c=true,
                                         Hive_Project__c=true
                                         );       
        
        List<copado__Team__c>listTeam =  new List<copado__Team__c>{
                        new copado__Team__c(Name='Team1'),
                        new copado__Team__c(Name='Team2'),
                        new copado__Team__c(Name='Team3')
                    };                                    
        insert listTeam;
        List<HIVE_Products__c> listPro = new List<HIVE_Products__c>{
            new HIVE_Products__c(Name='Product1',Team__c=listTeam[0].Id),
            new HIVE_Products__c(Name='Product2',Team__c=listTeam[1].Id),
            new HIVE_Products__c(Name='Product3',Team__c=listTeam[2].Id)
        };

      insert listPro;

    }

    static testMethod void testCUS(){
        Id rtUSId = ApexUtil.getRecordTypeByName('copado__User_Story__c','User_Story').Id;
        copado__User_Story__c cus = new copado__User_Story__c(BA_Priority__c='Medium',Business_Value_Points__c=300,RecordTypeId=rtUSId);
        cus.copado__User_Story_Title__c='test';
        cus.Description__c='test';
        cus.copado__Technical_Specifications__c='test';
            insert cus;
            TEst.startTest();
            cus.Description__c='test2';
            update cus;
            Test.stopTest();
    }
    
    
    static testMethod void testCUS3(){
        Id rtUSId = ApexUtil.getRecordTypeByName('copado__User_Story__c','User_Story').Id;
        copado__User_Story__c cus = new copado__User_Story__c(BA_Priority__c='Medium',Business_Value_Points__c=300,RecordTypeId=rtUSId);
        cus.copado__User_Story_Title__c='test';
        cus.Description__c='test';
        cus.copado__Technical_Specifications__c='';
            insert cus;
            TEst.startTest();
            Insert cus.clone();
            Test.stopTest();
        }

    @isTest
	static void testcheckDependency(){
        Id rtUSId = ApexUtil.getRecordTypeByName('copado__User_Story__c','User_Story').Id;
        copado__User_Story__c cus_parents = new copado__User_Story__c(copado__User_Story_Title__c='test cus_parents',Description__c='test 0001',copado__Technical_Specifications__c='test test 001',copado__Status__c ='Draft',BA_Priority__c='Medium',Business_Value_Points__c=300,RecordTypeId=rtUSId);
        copado__User_Story__c cus_child1 = new copado__User_Story__c(copado__User_Story_Title__c='test cus_child1',Description__c='test 0002',copado__Technical_Specifications__c='test test 002',copado__Status__c ='Draft',BA_Priority__c='Medium',Business_Value_Points__c=300,RecordTypeId=rtUSId);
        copado__User_Story__c cus_child2 = new copado__User_Story__c(copado__User_Story_Title__c='test cus_child2',Description__c='test 0003',copado__Technical_Specifications__c='test test 003',copado__Status__c ='Draft',BA_Priority__c='Medium',Business_Value_Points__c=300,RecordTypeId=rtUSId);
        insert new List<copado__User_Story__c>{cus_parents,cus_child1,cus_child2};
        copado__Team_Dependency__c usd1 = new copado__Team_Dependency__c(copado__Dependent_User_Story__c = cus_child1.Id,copado__Provider_User_Story__c = cus_parents.Id,Relationship__c='Binded');
        copado__Team_Dependency__c usd2= new copado__Team_Dependency__c(copado__Dependent_User_Story__c = cus_child2.Id,copado__Provider_User_Story__c = cus_child1.Id,Relationship__c='Binded');
        insert new List<copado__Team_Dependency__c>{usd1,usd2};
        //insert cus_parents;

        Test.startTest();
            cus_parents.copado__Status__c ='Technical Review';
            update cus_parents;
            copado__User_Story__c updateChild1 =[select Id,copado__Status__c from copado__User_Story__c where Id=:cus_child1.Id];
            System.assertEquals(updateChild1.copado__Status__c,'Technical Review');
            copado__User_Story__c updateChild2 =[select Id,copado__Status__c from copado__User_Story__c where Id=:cus_child2.Id];
            System.assertEquals(updateChild2.copado__Status__c,'Technical Review');
        Test.stopTest();

    }
    
    @isTest
	static void testUpdateProjectStatus(){
        Id rtUSId = ApexUtil.getRecordTypeByName('copado__User_Story__c','User_Story').Id;
        Hive_Project__c p = new Hive_Project__c(name='Testint project',Status__c='New');
        insert p;
        copado__User_Story__c cus_parents = new copado__User_Story__c(Hive_Project__c=p.Id,copado__User_Story_Title__c='test cus_parents',Description__c='test 0001',copado__Technical_Specifications__c='test test 001',copado__Status__c ='Draft',BA_Priority__c='Medium',Business_Value_Points__c=300,RecordTypeId=rtUSId);
        copado__User_Story__c cus_child1 = new copado__User_Story__c(Hive_Project__c=p.Id,copado__User_Story_Title__c='test cus_child1',Description__c='test 0002',copado__Technical_Specifications__c='test test 002',copado__Status__c ='Draft',BA_Priority__c='Medium',Business_Value_Points__c=300,RecordTypeId=rtUSId);
        copado__User_Story__c cus_child2 = new copado__User_Story__c(Hive_Project__c=p.Id,copado__User_Story_Title__c='test cus_child2',Description__c='test 0003',copado__Technical_Specifications__c='test test 003',copado__Status__c ='Draft',BA_Priority__c='Medium',Business_Value_Points__c=300,RecordTypeId=rtUSId);
        insert new List<copado__User_Story__c>{cus_parents,cus_child1,cus_child2};
        copado__Sprint__c sp = new copado__Sprint__c (Name='test Sprint 1', Active_Sprint__c=true);
        insert sp;
        Test.startTest();
        cus_parents.copado__Sprint__c = sp.Id;
       	update cus_parents;
        //System.assertEquals('Development', [select Status__c From Hive_Project__c where ID =: p.Id].Status__c);
        cus_parents.copado__Status__c = 'Deployed in PROD';
        update cus_parents;
        //System.assertEquals('Development', [select Status__c From Hive_Project__c where ID =: p.Id].Status__c);
        cus_child1.copado__Sprint__c = sp.Id;
        cus_child1.copado__Status__c = 'Duplicated';
        cus_child2.copado__Sprint__c = sp.Id;
        cus_child2.copado__Status__c = 'Closed - Complete';
        update new List<copado__User_Story__c>{cus_child1,cus_child2};
        //System.assertEquals('Completed', [select Status__c From Hive_Project__c where ID =: p.Id].Status__c);
        Test.stopTest();
    }

    @isTest
	static void testPriorityChanged(){

        // 08.07.2022 / Sophal Noch / US-0011960 

        Id rtUSId = ApexUtil.getRecordTypeByName('copado__User_Story__c','User_Story').Id;
        Hive_Project__c p = new Hive_Project__c(name='Testint project',Status__c='New');
        insert p;
        copado__Sprint__c sp = new copado__Sprint__c (Name='Salami Stream',copado__Status__c ='In progress');
        insert sp;

        copado__User_Story__c us = new copado__User_Story__c(Hive_Project__c=p.Id,copado__Status__c='Approved',copado__Sprint__c=sp.Id,copado__User_Story_Title__c='test cus_parents',Description__c='test 0001',copado__Technical_Specifications__c='test test 001',BA_Priority__c='Medium',Business_Value_Points__c=300,RecordTypeId=rtUSId);
        insert us;
        us.BA_Priority__c = 'High';
        List<copado__User_Story__c> listUs  = new List<copado__User_Story__c>();
        listUs.add(us);
        Test.startTest();
            List<Database.SaveResult> saveResult = Database.update(listUs, false);
            System.assertEquals(false,saveResult[0].isSuccess());
            System.assertEquals(Label.ErrorChangeBAPriorityWhenApproved,saveResult[0].getErrors()[0].getMessage());
        Test.stopTest();

    }
    //NK:26/07/2023:US-0013924 
    //NK:07/08/2023:US-0013957
    //NK:26/10/2023:US-0014332
    @isTest
	static void testPopulateTeam()
    {
        // String unknowTeam = 'Unknown Team';
        // List<HIVE_Products__c> listPro = new List<HIVE_Products__c>();
        // //Set<copado__Team__c> setTeam = new Set<copado__Team__c>();
        // Map<String,copado__Team__c> mapProTeam = new Map<String,copado__Team__c>();
        // Map<String,String> mapTeamName = new Map<String,String>();
        // for(Hive_Product_Team_Mapping__mdt mdt : [Select Id,MasterLabel,DeveloperName,Team__c From Hive_Product_Team_Mapping__mdt Order by Team__c])
        // {
        //     listPro.add(new HIVE_Products__c(Name=mdt.MasterLabel));
        //     mapTeamName.put(mdt.MasterLabel,mdt.Team__c);
        //     mapProTeam.put(mdt.Team__c,new copado__Team__c(Name=mdt.Team__c));
        // }
        
        // mapProTeam.put(unknowTeam,new copado__Team__c(Name=unknowTeam));

        // insert listPro;
        // insert mapProTeam.values();

        List<HIVE_Products__c> listPro = [Select Id,Name,Team__c,Team__r.Name From HIVE_Products__c order by Name];

        Test.startTest();

            Id rtUSId = ApexUtil.getRecordTypeByName('copado__User_Story__c','User_Story').Id;
            copado__User_Story__c story1 = new copado__User_Story__c(HIVE_Products__c=listPro[0].Id,copado__User_Story_Title__c='test cus_parents',Description__c='test 0001',copado__Technical_Specifications__c='test test 001',copado__Status__c ='Draft',BA_Priority__c='Medium',Business_Value_Points__c=300,RecordTypeId=rtUSId);
            insert story1;

            copado__User_Story__c story1Sel = [Select Id,Name,copado__Team__c,copado__Team__r.Name,HIVE_Products__c,HIVE_Products__r.Name From copado__User_Story__c Where Id=:story1.Id];
            System.assertNotEquals(story1Sel.copado__Team__c,NULL,'Team has been automatically assigned by the HiveProduct mapping');
            System.assertEquals(story1Sel.copado__Team__r.Name,listPro[0].Team__r.Name,'Team has been automatically assigned to: '+listPro[0].Team__r.Name);


            story1.HIVE_Products__c=listPro[1].Id;
            update story1;
            story1Sel = [Select Id,Name,copado__Team__c,copado__Team__r.Name,HIVE_Products__c,HIVE_Products__r.Name  From copado__User_Story__c Where Id=:story1.Id];
            System.assertEquals(story1Sel.copado__Team__r.Name,listPro[1].Team__r.Name,'Team has been automatically changed to: '+listPro[1].Team__r.Name);
            
            story1Sel.copado__Team__c = listPro[2].Team__c;

            try
            {
                update story1Sel;
            }catch(DmlException dex)
            {
                System.assertEquals(System.Label.Error_Invalid_HiveProduct_Team,dex.getDmlMessage(0),'In valid team selection.');
            }

        Test.stopTest();

    }

    // @isTest
    // private static void validateFieldsWhenStatusApprovedTest(){
    //     Id rtUSId = ApexUtil.getRecordTypeByName('copado__User_Story__c','User_Story').Id;
    //     Hive_Project__c p = new Hive_Project__c(name='Testint project',Status__c='New');
    //     insert p;
    //     copado__Sprint__c sp = new copado__Sprint__c (Name='Salami Stream',copado__Status__c ='In progress');
    //     insert sp;

    //     copado__User_Story__c us = new copado__User_Story__c(Hive_Project__c=p.Id,copado__Status__c='Draft',copado__Sprint__c=sp.Id,copado__User_Story_Title__c='test cus_parents',Description__c='test 0001',copado__Technical_Specifications__c='test test 001',BA_Priority__c='Medium',Business_Value_Points__c=300,RecordTypeId=rtUSId);
    //     insert us;

    //     Test.startTest();
    //     copado__User_Story__c us1 = new copado__User_Story__c(Id=us.Id, copado__Status__c = 'Approved');
    //         Database.SaveResult saveResult = Database.update(us1, false);
    //         System.assertEquals(false,saveResult.isSuccess());
    //         System.assertEquals(Label.Complete_This_Field, saveResult.getErrors()[0].getMessage());
    //     Test.stopTest();
    // }
}