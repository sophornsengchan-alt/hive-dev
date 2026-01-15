/*********************************************************************************************************************************
@ Class:          PromotionTriggerHandlerTest
@ Version:        1.0
@ Author:         David Herrero
@ Purpose:        Test class for PromotionTriggerHandler class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09/09/2022 / David Herrero / Created the test class.
*********************************************************************************************************************************/

@isTest
public class  PromotionTriggerHandlerTest {
  /*  @testSetup
    static void setupData() {
    	EBH_TestDataFactory.setUpCustomSettings();   
        

   
        


        copado__Org__c credential = new copado__Org__c();
        credential.copado__Default_Credential__c=true;
        credential.name='UAT';
   
        insert credential;



        copado__Environment__c environment = new copado__Environment__c();
        environment.name='UAT';
        environment.copado__Minimum_Apex_Test_Coverage__c=75;
        environment.copado__Promotion_Default_Credential__c='All Promotions';
        environment.copado__Type__c='Sandbox';
        environment.copado__Platform__c='Salesforce';
        environment.copado__Org_ID__c=credential.ID;

        insert environment;

        credential.copado__Environment__c=environment.ID;
        update credential;
        

    copado__Org__c credentialp = new copado__Org__c();
        credentialp.copado__Default_Credential__c=true;
        credentialp.name='PRODUCTION';
        insert credentialp;



        copado__Environment__c environmentp = new copado__Environment__c();
        environmentp.name='PRODUCTION';
        environmentp.copado__Minimum_Apex_Test_Coverage__c=75;
        environmentp.copado__Promotion_Default_Credential__c='All Promotions';
        environmentp.copado__Type__c='Sandbox';
        environmentp.copado__Platform__c='Salesforce';
        environmentp.copado__Org_ID__c=credentialp.ID;
        
        insert environmentp;

        credentialp.copado__Environment__c=environmentp.ID;
        
        update credentialp;


        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c();
        pipeline.name='test';
        pipeline.copado__active__c=true;
        insert pipeline;

        copado__Deployment_Flow_Step__c dfs = new copado__Deployment_Flow_Step__c();
        dfs.copado__Branch__c='UAT';
        dfs.copado__Deployment_Flow__c = pipeline.id;
        dfs.copado__Destination_Branch__c='PRODUCTION';
        
        dfs.copado__Destination_Environment__c=environmentp.id;
        
        dfs.copado__Source_Environment__c=environment.id;
        insert dfs;

        Copado__project__c p = new Copado__project__c();
        p.name='Testing Project';
        p.copado__status__c='In progress';
        p.copado__Deployment_Flow__c=pipeline.id;
        insert p;


        Copado__user_story__c us = new Copado__user_story__c();
        us.RecordtypeId='0123u000000iyiTAAQ'; //helper
        us.copado__User_Story_Title__c='Test';
        us.Copado__project__c=p.ID;
        us.copado__Org_Credential__c=credential.ID;
        us.copado__Environment__c=environment.ID;

        insert us;

        Copado__user_story__c us2 = new Copado__user_story__c();
        us2.RecordtypeId='0123u000000iyiTAAQ'; //helper
        us2.copado__User_Story_Title__c='Test 2';
        us2.Copado__project__c=p.ID;
        us2.copado__Org_Credential__c=credential.ID;
        us2.copado__Environment__c=environment.ID;

        insert us2;

        copado__Promotion__c promotion = new copado__Promotion__c();
        promotion.copado__Destination_Environment__c=environmentp.id;
        promotion.copado__Destination_Org_Credential__c=credentialp.id;
        promotion.copado__Order_by__c='copado__Latest_Commit_Date__c';
        promotion.copado__Project__c=p.id;
        promotion.copado__Source_Environment__c=environment.id;
        promotion.copado__Source_Org_Credential__c=credential.id;
        
        insert promotion;

        copado__User_Story_Metadata__c[] metadatas = new List<copado__User_Story_Metadata__c>();

        metadatas.add(new copado__User_Story_Metadata__c(copado__User_Story__c=us.id,
        copado__Metadata_API_Name__c='ApexClass.TestingClass1' ))        ;


        metadatas.add(new copado__User_Story_Metadata__c(copado__User_Story__c=us2.id,
        copado__Metadata_API_Name__c='ApexClass.TestingClass1' ))        ;

        insert metadatas;


        copado__Promoted_User_Story__c pus = new copado__Promoted_User_Story__c();
        pus.name='Testing';
        pus.copado__User_Story__c=us.id;
        pus.copado__Promotion__c=promotion.id;

        insert pus;



     
    }*/
@IsTest(SeeAllData=true)
static  void testPromoteStoryToProd() {

 /* if(EBH_ActiveTriggers__c.getInstance(EBH_ConstantsUtility.TRIGGERCONTROLLER)  ==null ||
     EBH_ActiveTriggers__c.getInstance(EBH_ConstantsUtility.TRIGGERCONTROLLER) !=null&&  !EBH_ActiveTriggers__c.getInstance(EBH_ConstantsUtility.TRIGGERCONTROLLER).Promotion_Trigger__c){
       
    }
 EBH_TestDataFactory.setUpCustomSettings();  */
  
      User adminWithCopadoLicense = [select id from User where isactive=true and profile.name='System Administrator' and name='David Herrero']; //we need to select a user with Copado license
    	adminWithCopadoLicense.FirstName = 'Test';//by pass validation rule
    	//User admin1 = [Select Id,Name From User where isActive = true and Profile.Name = 'System Administrator' AND Name NOT IN :excludeUser Limit 1 ];
    	System.runAs(adminWithCopadoLicense)
    	{
    
  copado__Org__c credential = new copado__Org__c();
        credential.copado__Default_Credential__c=true;
        credential.name='UAT';
   
        insert credential;
        copado__Environment__c environment = new copado__Environment__c();
        environment.name='UAT';
        environment.copado__Minimum_Apex_Test_Coverage__c=75;
        environment.copado__Promotion_Default_Credential__c='All Promotions';
        environment.copado__Type__c='Sandbox';
        environment.copado__Platform__c='Salesforce';
        environment.copado__Org_ID__c=credential.ID;
        insert environment;
        credential.copado__Environment__c=environment.ID;
        update credential;
        
    copado__Org__c credentialp = new copado__Org__c();
        credentialp.copado__Default_Credential__c=true;
        credentialp.name='PRODUCTION';
        insert credentialp;
        copado__Environment__c environmentp = new copado__Environment__c();
        environmentp.name='PRODUCTION';
        environmentp.copado__Minimum_Apex_Test_Coverage__c=75;
        environmentp.copado__Promotion_Default_Credential__c='All Promotions';
        environmentp.copado__Type__c='Sandbox';
        environmentp.copado__Platform__c='Salesforce';
        environmentp.copado__Org_ID__c=credentialp.ID;
        
        insert environmentp;
        credentialp.copado__Environment__c=environmentp.ID;
        
        update credentialp;
        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c();
        pipeline.name='test';
        pipeline.copado__active__c=true;
        insert pipeline;
        copado__Deployment_Flow_Step__c dfs = new copado__Deployment_Flow_Step__c();
        dfs.copado__Branch__c='UAT';
        dfs.copado__Deployment_Flow__c = pipeline.id;
        dfs.copado__Destination_Branch__c='PRODUCTION';
        
        dfs.copado__Destination_Environment__c=environmentp.id;
        
        dfs.copado__Source_Environment__c=environment.id;
        insert dfs;
        Copado__project__c p = new Copado__project__c();
        p.name='Testing Project';
        p.copado__status__c='In progress';
        p.copado__Deployment_Flow__c=pipeline.id;
        insert p;
        Copado__user_story__c us = new Copado__user_story__c();
        us.RecordtypeId='0123u000000iyiTAAQ'; //helper
        us.copado__User_Story_Title__c='Test';
        us.Copado__project__c=p.ID;
        us.copado__Org_Credential__c=credential.ID;
        us.copado__Environment__c=environment.ID;
        insert us;
        Copado__user_story__c us2 = new Copado__user_story__c();
        us2.RecordtypeId='0123u000000iyiTAAQ'; //helper
        us2.copado__User_Story_Title__c='Test 2';
        us2.Copado__project__c=p.ID;
        us2.copado__Org_Credential__c=credential.ID;
        us2.copado__Environment__c=environment.ID;
        insert us2;
        copado__Promotion__c promotion = new copado__Promotion__c();
        promotion.copado__Destination_Environment__c=environmentp.id;
        promotion.copado__Destination_Org_Credential__c=credentialp.id;
        promotion.copado__Order_by__c='copado__Latest_Commit_Date__c';
        promotion.copado__Project__c=p.id;
        promotion.copado__Source_Environment__c=environment.id;
        promotion.copado__Source_Org_Credential__c=credential.id;
        
        insert promotion;
        copado__User_Story_Metadata__c[] metadatas = new List<copado__User_Story_Metadata__c>();
        metadatas.add(new copado__User_Story_Metadata__c(copado__User_Story__c=us.id,
        copado__Metadata_API_Name__c='ApexClass.TestingClass1' ))        ;
        metadatas.add(new copado__User_Story_Metadata__c(copado__User_Story__c=us2.id,
        copado__Metadata_API_Name__c='ApexClass.TestingClass1' ))        ;
        insert metadatas;
        copado__Promoted_User_Story__c pus = new copado__Promoted_User_Story__c();
        pus.name='Testing';
        pus.copado__User_Story__c=us.id;
        pus.copado__Promotion__c=promotion.id;
        insert pus;
  
    
            copado__Promotion__c p2 =[select id,copado__Status__c from copado__promotion__c where copado__Status__c!='Completed' and copado__Source_Environment__r.name like '%UAT%' order by createddate desc limit 1];
        System.assertNotEquals(null, promotion,'No promotion was found');

        p2.copado__Status__c='Merge Conflict';

        update p2;

        }

    } 
}