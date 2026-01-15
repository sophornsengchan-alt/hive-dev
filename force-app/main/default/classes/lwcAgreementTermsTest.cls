/**
 * @description Test unit for cover code in lwcAgreementTermsController class
 * @date        21/07/2021
 * @author      Samnang MUONG
 */
@isTest
public without sharing class lwcAgreementTermsTest {
    
    @testSetup
    static void setup(){       

        //create an account
        /* MN-10062024-US-0015298
        Account acc = new Account( Name = 'TestAccount' );
        insert acc;
        */

        Account acc = SEPTestGenerator.createSeller('Portal Seller NA', SEP_Helper.SEP_Domain_NA); //MN-10062024-US-0015298

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,
                                    FirstName='test fn', LastName='test ln', AccountId=acc.Id);
        insert con;

        /* MN-10062024-US-0015298
        Profile profile = [SELECT Id FROM Profile WHERE Name ='NA - Seller Portal' Limit 1];
        User user1 = new User(
                                Username = System.now().millisecond() + 'test12345@test.com',
                                ContactId = con.Id,
                                ProfileId = profile.Id,
                                Alias = 'test123',
                                Email = 'test12345xx@test.com',
                                EmailEncodingKey = 'UTF-8',
                                LastName = 'McTesty',
                                CommunityNickname = 'test12345',
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'en_US',
                                LanguageLocaleKey = 'en_US'
                                );
        */

        User existAdminUser = [Select Id,Name from User Where Profile.Name = 'System Administrator' And isActive = true Limit 1];
        System.runAs(existAdminUser){ // 17.08.2022 / Sophal Noch / US-0011795 : fix dml error
            //insert user1; //MN-10062024-US-0015298    
            User user1 = SEPTestGenerator.createSEPUser('sepUserlat1', con.Id); //MN-10062024-US-0015298
        }                
                               

    }
   
    @IsTest
    static void test_InitAgreementTerms(){
        
        Test.startTest();

        User u = [SELECT Id FROM User WHERE Email='test12345xx@test.com'];

        System.runAs(u) {
            // lwcAgreementTermsController.initAgreementTerms();
            lwcAgreementTermsController.initAgreementTerms('FR_Agreement_Terms'); // 11.01.2023 / Sophal Noch / US-0012730
        }

        
        Test.stopTest();
        
    }

    @IsTest
    static void test_acceptedAgreement(){
        EBH_TestDataFactory.setUpCustomSettings();  
        Test.startTest();

        User u = [SELECT Id, ContactId FROM User WHERE Email='test12345xx@test.com'];

        System.runAs(u) {

            lwcAgreementTermsController.initAgreementTerms('NA_Agreement_Terms');
            lwcAgreementTermsController.acceptedAgreement('NA_Agreement_Terms',null);

            lwcAgreementTermsController.initAgreementTerms('FR_Agreement_Terms');
            lwcAgreementTermsController.acceptedAgreement('FR_Agreement_Terms','FR_Agreement_Terms_Download'); // 11.01.2023 / Sophal Noch / US-0012730

            u = [SELECT Id,Contact.Accepted_Current_Deals_Agreement__c, ContactId , Contact.Account.SP_Promotion_General_T_Cs_Agreed__c FROM User WHERE Email='test12345xx@test.com'];
            System.assertEquals(true, u.Contact.Accepted_Current_Deals_Agreement__c);
            System.assertEquals(true, u.Contact.Account.SP_Promotion_General_T_Cs_Agreed__c);

        }
        
        Test.stopTest();

    }


    @IsTest
    static void test_NDAAgreement(){
        // 17.01.2023 / Sophal Noch / US-0013069
        EBH_TestDataFactory.setUpCustomSettings();  
        Test.startTest();

        User u = [SELECT Id, ContactId FROM User WHERE Email='test12345xx@test.com'];

        System.runAs(u) {
            
            lwcAgreementTermsController.initAgreementTerms('NDA_Influencer_Agreement_Terms');
            lwcAgreementTermsController.getFooterContent('NDA_Influencer_Agreement_Terms',true,'NDA_Influencer_Agreement_Terms_Footer'); // 11.01.2023 / Sophal Noch / US-0012730
            lwcAgreementTermsController.acceptedAgreement('NDA_Influencer_Agreement_Terms','NDA_Influencer_Agreement_Terms_Download'); // 11.01.2023 / Sophal Noch / US-0012730
           
        }
        
        Test.stopTest();
    }


}