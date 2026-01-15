/*********************************************************************************************************************************
@ Class:        AbstractAgreementTermsControllerTest
@ Version:      1.0
@ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:      test class for AbstractAgreementTermsController, AgreementTermsControllerSEP, AgreementTermsControllerInfluencer
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16.02.2023 / Sophal Noch (sophal.noch@gaea-sys.com) / Created the class.
@                 10.06.2024 / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c
*********************************************************************************************************************************/
@isTest
public with sharing class AbstractAgreementTermsControllerTest {
    @testSetup
    static void setup(){   
        
        // 16.02.2023 / Sophal Noch / US-0013171 :
        /* MN-10062024-US-0015298
        //create an account
        Account acc = new Account( Name = 'TestAccount' );
        insert acc;

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,
                                    FirstName='test fn', LastName='test ln', AccountId=acc.Id);
        insert con;
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

        Account accNADomain = SEPTestGenerator.createSeller('Portal Seller NA', SEP_Helper.SEP_Domain_NA, null, null, null);
        
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false, FirstName='test fn', LastName='test ln', AccountId=accNADomain.Id);
        insert con;

        User existAdminUser = [Select Id,Name from User Where Profile.Name = 'System Administrator' And isActive = true Limit 1];
        System.runAs(existAdminUser){
            SEPTestGenerator.createSEPUser('sepNAaatc1', con.Id);
        }                
                               
    }

    @IsTest
    static void test_NAAgreementTerms(){

        // 16.02.2023 / Sophal Noch / US-0013171 :
        
        Test.startTest();

        User u = [SELECT Id, Name, Profile.Name, SPMainDomain__c FROM User WHERE Email='test12345xx@test.com'];
        
        System.runAs(u) {

            AgreementTermsControllerSEP.initAgreementTerms('NA_Agreement_Terms');
            // AgreementTermsControllerSEP.acceptedAgreement('NA_Agreement_Terms');
            AgreementTermsControllerSEP.acceptedAgreement('NA_Agreement_Terms',null); // 15.03.2023 / Sophal Noch  / US-0012238

            AgreementTermsControllerSEP ctrl = new AgreementTermsControllerSEP();
            ctrl.doInitAgmt('NA_Agreement_Terms');
            ctrl.doAcceptAgmt('NA_Agreement_Terms');
        }

        
        Test.stopTest();
        
    }

    @IsTest
    static void test_FRAgreementTerms(){

        // 16.02.2023 / Sophal Noch / US-0013171 :
        
        Test.startTest();

        User u = [SELECT Id FROM User WHERE Email='test12345xx@test.com'];

        System.runAs(u) {

            //NK:17/03/2023:US-0013108
            Map<String,Object>  mapInitResult = AgreementTermsControllerSEP.apexInitAgreementTheme();            
            System.assertEquals('FR_Agreement_Terms', mapInitResult.get('agmtMdtName'),'metadata agreement config for FR');
            System.assertEquals(true, (Boolean)mapInitResult.get('showAgreement'),'show agreement');

            AgreementTermsControllerSEP.initAgreementTerms('FR_Agreement_Terms');
            // AgreementTermsControllerSEP.acceptedAgreement('FR_Agreement_Terms');
            AgreementTermsControllerSEP.acceptedAgreement('FR_Agreement_Terms', null); // 15.03.2023 / Sophal Noch  / US-0012238

            AgreementTermsControllerSEP ctrl = new AgreementTermsControllerSEP();
            ctrl.doInitAgmt('FR_Agreement_Terms');
            ctrl.doAcceptAgmt('FR_Agreement_Terms');
        }
        Test.stopTest();
        
    }

    @IsTest
    static void test_NDAAgreementTerms(){

        // 16.02.2023 / Sophal Noch / US-0013171 :
        
        Test.startTest();

        User u = [SELECT Id FROM User WHERE Email='test12345xx@test.com'];

        System.runAs(u) {

            AgreementTermsControllerInfluencer.initAgreementTerms('NDA_Influencer_Agreement_Terms');
            AgreementTermsControllerInfluencer.acceptedAgreement('NDA_Influencer_Agreement_Terms');

            AgreementTermsControllerInfluencer ctrl = new AgreementTermsControllerInfluencer();
            ctrl.doInitAgmt('NDA_Influencer_Agreement_Terms');
            ctrl.doAcceptAgmt('NDA_Influencer_Agreement_Terms');
        }
        Test.stopTest();
        
    }

    @IsTest
    static void test_AUDealWindowAgreementTerms(){

        // 16.03.2023 / Sophal Noch / US-0012238
        
        Test.startTest();

        User u = [SELECT Id, Contact.AccountId FROM User WHERE Email='test12345xx@test.com'];

        System.runAs(u) {

            Map<String, Object> mapArgs = new Map<String, Object>();
            mapArgs.put('accountId', u.Contact.AccountId);

            AgreementTermsControllerSEP.initAgreementTerms('AU_Deal_Window_Agreement_Terms');
            AgreementTermsControllerSEP.acceptedAgreement('AU_Deal_Window_Agreement_Terms',mapArgs);

            AgreementTermsControllerSEP ctrl = new AgreementTermsControllerSEP();
            ctrl.doInitAgmt('AU_Deal_Window_Agreement_Terms');
            ctrl.doAcceptAgmt('AU_Deal_Window_Agreement_Terms');
        }
        Test.stopTest();
        
    }
}