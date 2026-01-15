/*********************************************************************************************************************************
@ Class:          BulkSendCouponContractControllerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        BulkSendCouponContractController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  27.08.2020 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
@isTest
private class BulkSendCouponContractControllerTest {

    @testSetup private static void setup() {
        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
		System.runAs(admin){
			Profile p = [select id from Profile where name='Standard User Profile' limit 1];
            User standardUsr = new User(alias = 'tsUser', email='TestStardardUser@ebay.com',
                            emailencodingkey='UTF-8', lastname='TestStandardUser', firstname='TestStandardUser', languagelocalekey='en_US',
                            localesidkey='en_US', profileid = p.Id,
                            timezonesidkey='America/Los_Angeles', username='TestStardarduser@salesforce.de', isActive = true);
            insert standardUsr;
		}
        
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        RecordType couponItemBaseRecordType = ApexUtil.getRecordTypeByName('Coupon__c',EBH_ConstantsUtility.COUPON_ITEMBASE);
        RecordType manhattanCouponSellerRecordType = ApexUtil.getRecordTypeByName('Coupon_Seller__c',EBH_ConstantsUtility.COUPONSELLER_MANHATTAN_RECORDTYPE);
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RegistrationCountry__c = '0',EBH_RevRollup__c='US',SP_Coupons__c='Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	Account acc2 = new Account(Name='Test Acc2',RecordTypeID = sellerRecordType.Id,EBH_RegistrationCountry__c = '0',EBH_RevRollup__c='US',SP_Coupons__c='Full Access',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
    	insert new List<Account>{acc,acc2};
    	Coupon__c c1 = new Coupon__c(Coupon_ID__c='CC001',RecordTypeID = couponItemBaseRecordType.Id,Main_Coupon_Site__c = 'ebay.com',Coupon_Co_invest_Type__c='Contra');
		insert c1;
    	Coupon_Seller__c cs1 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc.Id,RecordTypeId = manhattanCouponSellerRecordType.Id, Coupon_Seller_Stage__c = 'Reached');
    	Coupon_Seller__c cs2 = new Coupon_Seller__c(Coupon__c = c1.Id,seller__c = acc2.Id,RecordTypeId = manhattanCouponSellerRecordType.Id, Coupon_Seller_Stage__c = 'Reached');
    	insert new List<Coupon_Seller__c>{cs1,cs2};
    }
    private static testMethod void cancelActionTest() {
        Test.startTest();
        List<Coupon_Seller__c> lstCs = [SELECT Id FROM Coupon_Seller__c];
        Test.setCurrentPage(Page.BulkSendCouponContractPage);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstCs);
        stdSetController.setSelected(lstCs);
        BulkSendCouponContractController ctr = new BulkSendCouponContractController(stdSetController);
        Test.stopTest();

    }
    
    static testMethod void testInitAndSaveCoupounSeller(){
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        //LA:05-12-2023-US-0014231
        //Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_DealsProgram__c='Accepted',EBH_RevRollup__c='DE',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='DE',EBH_BillingAddress__c='PP',EBH_BillingCity__c='pp',EBH_BillingCountry__c='US',EBH_CompanyName__c='test',EBH_BillingPostalCode__c='12102');
        acc.SP_Coupons__c = 'Full Access'; // 05.04.2023 / Sophal Noch / US-0013235 : fix test class
        insert acc;

        Contact con = new Contact(LastName='Test Con1', Email='test@test.com.invalid', AccountId=acc.Id);
        Contact con2 = new Contact(LastName='Test Con2', Email='test2@test.com.invalid', AccountId=acc.Id);
        insert new List<Contact>{con, con2};

        Coupon__c c1 = new Coupon__c(Coupon_ID__c='CC001',Main_Coupon_Site__c = 'ebay.de',Coupon_Co_invest_Type__c='Contra',Seller_Co_funding_share_forecast__c = null,Coupon_Start_Date__c = System.today(),Coupon_End_Date__c = System.today().addDays(1), Negotiation_End_Date__c=System.today().addDays(1));
        insert c1;

        Coupon_Seller__c cs1 = new Coupon_Seller__c(Seller_Contact__c = con.Id, Coupon__c = c1.Id,seller__c = acc.Id,Legal_Entity_Name_w__c = 'testName',Legal_Entity_Street_w__c='testStreet',Legal_Entity_Zip_w__c='testZip', Coupon_Seller_Stage__c = 'Reached');
        Coupon_Seller__c cs2 = new Coupon_Seller__c(Seller_Contact__c = con2.Id, Coupon__c = c1.Id,seller__c = acc.Id,Legal_Entity_Name_w__c = 'testName',Legal_Entity_Street_w__c='testStreet',Legal_Entity_Zip_w__c='testZip', Coupon_Seller_Stage__c = 'Reached');

        /* //MN-30082021-US-0009948-Replace Email_Adress__c with Seller_Contact__c
        Coupon_Seller__c cs1 = new Coupon_Seller__c(Email_Adress__c = 'sophal.noch@gaea-sys.com', Coupon__c = c1.Id,seller__c = acc.Id,Legal_Entity_Name_w__c = 'testName',Legal_Entity_Street_w__c='testStreet',Legal_Entity_Zip_w__c='testZip');
        Coupon_Seller__c cs2 = new Coupon_Seller__c(Email_Adress__c = 'sophal.noch@gaea-sys.com',Coupon__c = c1.Id,seller__c = acc.Id,Legal_Entity_Name_w__c = 'testName',Legal_Entity_Street_w__c='testStreet',Legal_Entity_Zip_w__c='testZip');
        */
        insert new List<Coupon_Seller__c>{cs1,cs2}; 

        cs1.Legal_Entity_Name_w__c = 'testName';
        cs1.Legal_Entity_Street_w__c = 'testStreet';
        cs1.Legal_Entity_Zip_w__c = 'testZip';

        cs2.Legal_Entity_Name_w__c = 'testName';
        cs2.Legal_Entity_Street_w__c = 'testStreet';
        cs2.Legal_Entity_Zip_w__c = 'testZip';

        update new List<Coupon_Seller__c>{cs1,cs2}; 

        
        Coupon_Co_Invest__c coInvestForCs1 = new Coupon_Co_Invest__c(Coupon_Seller__c=cs1.Id, Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Co_Invest__c=10);
        Coupon_Co_Invest__c coInvestForCs2 = new Coupon_Co_Invest__c(Coupon_Seller__c=cs2.Id, Seller_Name__c=acc.Id,Coupon_Name__c=c1.Id,Co_Invest__c=20);
        
        insert new List<Coupon_Co_Invest__c>{coInvestForCs1,coInvestForCs2}; 

        PermissionSet ps = Database.query('SELECT Id, Name FROM PermissionSet WHERE Name = \'Coupon_Special_Permission\'');

        User standardUser = [
            SELECT Id FROM User 
            WHERE Profile.Name = 'Standard User Profile' 
            AND IsActive = true
            AND Id NOT IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId =: ps.Id)
            LIMIT 1
        ];

        System.assertNotEquals(null, standardUser.Id);


        System.runAs(standardUser){

            Map<String,Object> mapResult = BulkSendCouponContractController.apexInit(c1.Id);

            System.assertEquals(System.Label.ErrorNoCouponSpecialPermission, (String)mapResult.get('error'));
            System.assertEquals('ko', (String)mapResult.get('status'));

        }

       

       
        
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Id customPermissionId = [SELECT Id FROM CustomPermission WHERE DeveloperName = 'Coupons_Bulk_Send_Contracts'][0].Id;
        
            // Check if the SetupEntityAccess record exists
            SetupEntityAccess existingSea = [SELECT Id FROM SetupEntityAccess WHERE ParentId = :ps.Id AND SetupEntityId = :customPermissionId LIMIT 1];
            System.debug('existingSea'+existingSea);
        
            if (existingSea == null) {
                // If the SetupEntityAccess record doesn't exist, create it
                SetupEntityAccess sea = new SetupEntityAccess(ParentId = ps.Id, SetupEntityId = customPermissionId);
                insert sea;
            }
            
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = standardUser.Id);
            insert psa;
        }
        System.runAs(standardUser){

            Map<String,Object> mapResult = BulkSendCouponContractController.apexInit(c1.Id);
            System.assertEquals('ok', (String)mapResult.get('status'));
    
            List<Coupon_Seller__c> listCoSeller = ((List<Coupon_Seller__c>)mapResult.get('listCoSeller'));
    
            System.assertEquals(2, listCoSeller.size());
    
    
            mapResult = BulkSendCouponContractController.apexSave(listCoSeller);
            System.assertEquals('ok', (String)mapResult.get('status'));
    
            listCoSeller[0].Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPONSELLER_STAGE_APPROVED;
            listCoSeller[1].Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPONSELLER_STAGE_APPROVED;
            listCoSeller[1].Legal_Entity_Name_w__c = '';//LA-28-04-2025-US-0016656
            update listCoSeller;
     
            mapResult = BulkSendCouponContractController.apexSave(listCoSeller);
            String csName = '('+listCoSeller[1].Name+')';//LA-28-04-2025-US-0016656
            System.assertEquals(csName + System.Label.ErrorMsgCompanyDetailForContractSend, (String)mapResult.get('error'));//LA-28-04-2025-US-0016656
            //System.assertEquals(null, (String)mapResult.get('error'));//LA-28-04-2025-US-0016656
            //System.assertEquals('ok', (String)mapResult.get('status'));//LA-28-04-2025-US-0016656
    
            List<Coupon_Seller__c> listCoSellerAfterUpdated = [SELECT Id,Coupon_Seller_Stage__c FROM Coupon_Seller__c where Id =: listCoSeller[0].Id OR Id =: listCoSeller[1].Id];
            System.assertEquals(EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND, listCoSellerAfterUpdated[0].Coupon_Seller_Stage__c);
            // System.assertEquals(EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND, listCoSellerAfterUpdated[1].Coupon_Seller_Stage__c);//LA-28-04-2025-US-0016656
            System.assertEquals(EBH_ConstantsUtility.COUPONSELLER_STAGE_APPROVED, listCoSellerAfterUpdated[1].Coupon_Seller_Stage__c);//LA-28-04-2025-US-0016656

        }
        Test.stopTest();


        


    }

}