/*********************************************************************************************************************************
@ Class:          FinalValueFee_FVF_HandlerTest
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        test Class for trigger FinalValueFee_FVF
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.05.2019 / Sovantheany Dim / Created the class.
				  12.06.2019 / Acmatac Seing / EPH-7607 New method prepopulateContactPersonTest_NoPrimaryContact(), prepopulateContactPersonTest_HavePrimaryContact()
				: 13/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
				: 22/05/2024/ vadhanak voun/ US-0015117 - 3. Deletion of custom objects
*********************************************************************************************************************************/
@isTest
private class FinalValueFee_FVF_HandlerTest {
  static testMethod void setupData() {
    EBH_TestDataFactory.setUpCustomSettings();

    String myUId = UserInfo.getUserId();

    List<FVF_Approval_Matrix__c> listMatrix = new List<FVF_Approval_Matrix__c>{
      //apply new recordtype to the existing
      new FVF_Approval_Matrix__c(
        Name = '1',
        Limitation__c = 10000,
        Operator__c = '<=',
        Rev_RollUp__c = 'UK',
        User_Id__c = myUId,
        RecordType__c = 'FVF_Listing_Level,FVF_Seller_Level'
      ),
      new FVF_Approval_Matrix__c(
        Name = '2',
        Limitation__c = 10000,
        Operator__c = '>',
        Rev_RollUp__c = 'UK',
        User_Id__c = myUId,
        RecordType__c = 'FVF_Listing_Level,FVF_Seller_Level'
      ),
      new FVF_Approval_Matrix__c(
        Name = '3',
        Limitation__c = 10000,
        Operator__c = '<=',
        Rev_RollUp__c = 'DE',
        User_Id__c = myUId,
        RecordType__c = 'FVF_Listing_Level,FVF_Seller_Level'
      ),
      new FVF_Approval_Matrix__c(
        Name = '4',
        Limitation__c = 10000,
        Operator__c = '>',
        Rev_RollUp__c = 'DE',
        User_Id__c = myUId,
        RecordType__c = 'FVF_Listing_Level,FVF_Seller_Level'
      ),
      new FVF_Approval_Matrix__c(
        Name = '5',
        Limitation__c = 10000,
        Operator__c = '<=',
        Rev_RollUp__c = 'FR,IT,ES',
        User_Id__c = myUId,
        RecordType__c = 'FVF_Listing_Level,FVF_Seller_Level'
      ),
      new FVF_Approval_Matrix__c(
        Name = '6',
        Limitation__c = 10000,
        Operator__c = '>',
        Rev_RollUp__c = 'FR,IT,ES',
        User_Id__c = myUId,
        RecordType__c = 'FVF_Listing_Level,FVF_Seller_Level'
      ),
      //for fvf campaign matrix
      new FVF_Approval_Matrix__c(
        Name = '7',
        RecordType__c = 'FVF_Campaign',
        Limitation__c = 10000,
        Operator__c = '<=',
        Rev_RollUp__c = 'UK',
        User_Id__c = myUId
      ),
      new FVF_Approval_Matrix__c(
        Name = '8',
        RecordType__c = 'FVF_Campaign',
        Limitation__c = 10000,
        Operator__c = '>',
        Rev_RollUp__c = 'UK',
        User_Id__c = myUId
      ),
      new FVF_Approval_Matrix__c(
        Name = '9',
        RecordType__c = 'FVF_Campaign',
        Limitation__c = 5000,
        Operator__c = '<=',
        Rev_RollUp__c = 'DE',
        User_Id__c = myUId
      ),
      new FVF_Approval_Matrix__c(
        Name = '10',
        RecordType__c = 'FVF_Campaign',
        Limitation__c = 5000,
        Operator__c = '>',
        Rev_RollUp__c = 'DE',
        User_Id__c = myUId
      ),
      new FVF_Approval_Matrix__c(
        Name = '11',
        RecordType__c = 'FVF_Campaign',
        Limitation__c = 5000,
        Operator__c = '<=',
        Rev_RollUp__c = 'FR,IT,ES',
        User_Id__c = myUId
      ),
      new FVF_Approval_Matrix__c(
        Name = '12',
        RecordType__c = 'FVF_Campaign',
        Limitation__c = 5000,
        Operator__c = '>=',
        Rev_RollUp__c = 'FR,IT,ES',
        User_Id__c = myUId
      )
    };
    upsert listMatrix Name;
    //--end script
  }

  /*
	static testMethod void testSendMail()
    {
        setupdata();
    	//FVF_Approval_Matrix__c fmx = new FVF_Approval_Matrix__c(Name='1',Limitation__c=10000,Operator__c='<=',Rev_RollUp__c='UK',User_Id__c=UserInfo.getUserId());
    	//insert fmx;
    	
    	RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
    	Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK');
    	insert acc;
    	 
    	RecordType recTypeFVFCampaign = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c','FVF_Seller_Level');
    	Final_Value_Fee_FVF__c fvf3 = new Final_Value_Fee_FVF__c(RecordTypeId=recTypeFVFCampaign.Id,Seller_Name__c=acc.Id,Seller_Email__c='test@test.com',Budget_Manually_Estimated__c=3000,Site__c='UK');
    	
    	//insert new List<Final_Value_Fee_FVF__c>{fvf,fvf2,fvf3};
        insert fvf3;
        Test.startTest();
         
        	
        	fvf3.Final_Value_Fee_Stage__c =  EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE;
			
        	update fvf3;
		
        Test.stopTest();
    }	
	*/

  @isTest
  private static void prepopulateContactPersonTest_NoPrimaryContact() {
    setupdata();
    RecordType sellerRecordType = ApexUtil.getRecordTypeByName(
      'Account',
      'EBH_Seller'
    );
    Account acc = new Account(
      Name = 'Test Acc1',
      RecordTypeID = sellerRecordType.Id
    );
    insert acc;
    RecordType contacDW_RT = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
    Contact cont = new Contact(
      LastName = 'Test Cont1',
      RecordTypeID = contacDW_RT.Id,
      AccountId = acc.Id
    );
    insert cont;

    Test.startTest();
    RecordType fvfRecordType = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE
    );
    Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(
      RecordTypeId = fvfRecordType.Id,
      Seller_Name__c = acc.Id,
      Seller_Email__c = 'test@test.com',
      Site__c = 'UK'
    );
    insert fvf;
    Test.stopTest();

    fvf = [SELECT Contact_Person__c FROM Final_Value_Fee_FVF__c];
    System.assert(fvf.Contact_Person__c == cont.Id);
  }

  @isTest
  private static void prepopulateContactPersonTest_HavePrimaryContact() {
    setupdata();
    RecordType contacDW_RT = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
    RecordType sellerRecordType = ApexUtil.getRecordTypeByName(
      'Account',
      'EBH_Seller'
    );
    Account acc = new Account(
      Name = 'Test Acc1',
      RecordTypeID = sellerRecordType.Id
    );
    insert acc;
    Contact cont = new Contact(
      LastName = 'Test Cont1',
      RecordTypeID = contacDW_RT.Id,
      Primary_Contact__c = true,
      AccountId = acc.Id
    );
    insert cont;

    Test.startTest();
    RecordType fvfRecordType = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE
    );
    Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(
      RecordTypeId = fvfRecordType.Id,
      Seller_Name__c = acc.Id,
      Seller_Email__c = 'test@test.com',
      Site__c = 'UK'
    );
    insert fvf;
    Test.stopTest();

    fvf = [SELECT Contact_Person__c FROM Final_Value_Fee_FVF__c];

    System.assert(fvf.Contact_Person__c == cont.Id);
  }

  @isTest
  private static void assignPermset_NominatedItemEditTest() {
    setupdata();
    RecordType contacDW_RT = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
    Contact cont = new Contact(
      LastName = 'Test Cont1',
      RecordTypeID = contacDW_RT.Id
    );
    insert cont;

    RecordType sellerRecordType = ApexUtil.getRecordTypeByName(
      'Account',
      'EBH_Seller'
    );
    Account acc = new Account(
      Name = 'Test Acc1',
      RecordTypeID = sellerRecordType.Id,
      Primary_Contact__c = cont.Id
    );
    insert acc;

    // Setup test data
    // Create a unique UserName
    // String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
    // // This code runs as the system user
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    // User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
    // EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
    // LocaleSidKey='en_US', ProfileId = p.Id,
    // TimeZoneSidKey='America/Los_Angeles',
    //  UserName=uniqueUserName);
    String ADMIN_PROFILE_ID = ApexUtil.ADMIN_PROFILE_ID;
    User[] allAdmins = [
      SELECT Id
      FROM User
      WHERE ProfileId = :ADMIN_PROFILE_ID AND ISActive = TRUE
      LIMIT 1
    ];

    System.runAs(allAdmins[0]) {
      User usr = new User(
        Username = 'test@32samppp.com',
        Email = 'test32@samp.com',
        Alias = 'tsamp',
        IsActive = true,
        LastName = 'Test',
        TimeZoneSidKey = 'America/Los_Angeles',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'ISO-8859-1',
        ProfileId = p.ID,
        LanguageLocaleKey = 'en_US'
      );
      insert usr;

      Test.startTest();
      RecordType fvfRecordType = ApexUtil.getRecordTypeByName(
        'Final_Value_Fee_FVF__c',
        EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE
      );
      Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(
        Site__c = 'UK',
        RecordTypeId = fvfRecordType.Id,
        Seller_Name__c = acc.Id,
        Seller_Email__c = 'test@test.com',
        Requestor__c = usr.Id
      );
      insert fvf;
      Test.stopTest();

      PermissionSetAssignment[] pset = [
        SELECT PermissionSet.Name
        FROM PermissionSetAssignment
        WHERE AssigneeId = :usr.Id AND PermissionSet.Name = 'FVF_User'
      ];
      System.assert(!pset.isEmpty(), 'FVF_User has been assigned by trigger');
    }
  }

  static testMethod void testSendClickContract() {
    setupdata();
    RecordType contacDW_RT = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
    Contact cont = new Contact(
      LastName = 'Test Cont1',
      RecordTypeID = contacDW_RT.Id,
      Email = 'test@test.com'
    );
    insert cont;

    RecordType sellerRecordType = ApexUtil.getRecordTypeByName(
      'Account',
      'EBH_Seller'
    );
    //LA:05-12-2023-US-0014231
    //Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',Primary_Contact__c=cont.Id,EBH_DealsProgram__c ='Accepted');
    Account acc = new Account(
      Name = 'Test Acc1',
      RecordTypeID = sellerRecordType.Id,
      EBH_RevRollup__c = 'UK',
      Primary_Contact__c = cont.Id
    );
    insert acc;

    RecordType fvfRecordType = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE
    );
    // Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(Site__c='UK',RecordTypeId =fvfRecordType.Id ,Legal_Entity_Country__c='UK', Legal_Entity_Name__c='My Company',Legal_Entity_Street__c='street1',Legal_Entity_Zip__c='12345',Seller_Name__c=acc.Id,Seller_Email__c='test@test.com',Seller_to_Product_IDS__c = sellerToProduct.Id,Final_Value_Fee_Stage__c=EBH_ConstantsUtility.FVF_STAGE_EBAY_APPROVED);
    Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(
      Site__c = 'UK',
      RecordTypeId = fvfRecordType.Id,
      Legal_Entity_Country__c = 'UK',
      Legal_Entity_Name__c = 'My Company',
      Legal_Entity_Street__c = 'street1',
      Legal_Entity_Zip__c = '12345',
      Seller_Name__c = acc.Id,
      Seller_Email__c = 'test@test.com',
      Final_Value_Fee_Stage__c = 'Draft'
    );
    insert fvf;

    fvf.Final_Value_Fee_Stage__c = 'eBay Approved';
    update fvf;

    Test.startTest();

    User deploymentUser = [
      SELECT Id, Name
      FROM User
      WHERE FirstName = 'Deployment'
      LIMIT 1
    ];
    System.runAs(deploymentUser) {
      fvf.Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_CONTRACT_SENT;
      update fvf;
    }

    Test.stopTest();
  }

  static testMethod void testSendClickContractReminder() {
    setupdata();
    RecordType contacDW_RT = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
    Contact cont = new Contact(
      LastName = 'Test Cont1',
      RecordTypeID = contacDW_RT.Id,
      Email = 'test@test.com'
    );
    insert cont;

    RecordType sellerRecordType = ApexUtil.getRecordTypeByName(
      'Account',
      'EBH_Seller'
    );
    //LA:05-12-2023-US-0014231
    //Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',Primary_Contact__c=cont.Id,EBH_DealsProgram__c ='Accepted');
    Account acc = new Account(
      Name = 'Test Acc1',
      RecordTypeID = sellerRecordType.Id,
      EBH_RevRollup__c = 'UK',
      Primary_Contact__c = cont.Id
    );
    insert acc;

    RecordType fvfRecordType = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE
    );
    Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(
      Site__c = 'UK',
      Contract_Send_Date__c = System.today(),
      RecordTypeId = fvfRecordType.Id,
      Legal_Entity_Country__c = 'UK',
      Legal_Entity_Name__c = 'My Company',
      Legal_Entity_Street__c = 'street1',
      Legal_Entity_Zip__c = '12345',
      Seller_Name__c = acc.Id,
      Seller_Email__c = 'test@test.com',
      Final_Value_Fee_Stage__c = 'Draft'
    );
    insert fvf;

    Nominated_Item__c nom1 = new Nominated_Item__c(
      Final_Value_Fee_FVF__c = fvf.Id,
      Price_target_w__c = 12
    );
    Nominated_Item__c nom2 = new Nominated_Item__c(
      Final_Value_Fee_FVF__c = fvf.Id,
      Price_target_w__c = 12
    );
    insert new List<Nominated_Item__c>{ nom1, nom2 };

    fvf.Final_Value_Fee_Stage__c = 'eBay Approved';
    update fvf;

    Test.startTest();

    User deploymentUser = [
      SELECT Id, Name
      FROM User
      WHERE FirstName = 'Deployment'
      LIMIT 1
    ];
    System.runAs(deploymentUser) {
      fvf.Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_CONTRACT_SENT;
      fvf.Reminder_Email_Send_Date__c = System.today();
      update fvf;
    }

    Test.stopTest();
  }

  static testMethod void checkNominateItemPriceisNotNullTest() {
    setupdata();
    RecordType contacDW_RT = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
    Contact cont = new Contact(
      LastName = 'Test Cont1',
      RecordTypeID = contacDW_RT.Id,
      Email = 'test@test.com'
    );
    insert cont;

    RecordType sellerRecordType = ApexUtil.getRecordTypeByName(
      'Account',
      'EBH_Seller'
    );
    //LA:05-12-2023-US-0014231
    //Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',Primary_Contact__c=cont.Id,EBH_DealsProgram__c ='Accepted');
    Account acc = new Account(
      Name = 'Test Acc1',
      RecordTypeID = sellerRecordType.Id,
      EBH_RevRollup__c = 'UK',
      Primary_Contact__c = cont.Id
    );
    insert acc;

    RecordType fvfRecordType = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE
    );
    Final_Value_Fee_FVF__c fvf1 = new Final_Value_Fee_FVF__c(
      Site__c = 'UK',
      RecordTypeId = fvfRecordType.Id,
      Budget_Manually_Estimated__c = 40,
      Legal_Entity_Country__c = 'UK',
      Legal_Entity_Name__c = 'My Company1',
      Legal_Entity_Street__c = 'street11',
      Legal_Entity_Zip__c = '123451',
      Seller_Name__c = acc.Id,
      Seller_Email__c = 'test1@test.com',
      Final_Value_Fee_Stage__c = 'Draft',
      Budget_FVF_Exposure__c = 100
    );
    Final_Value_Fee_FVF__c fvf2 = new Final_Value_Fee_FVF__c(
      Site__c = 'UK',
      RecordTypeId = fvfRecordType.Id,
      Budget_Manually_Estimated__c = 40,
      Legal_Entity_Country__c = 'UK',
      Legal_Entity_Name__c = 'My Company1',
      Legal_Entity_Street__c = 'street11',
      Legal_Entity_Zip__c = '123451',
      Seller_Name__c = acc.Id,
      Seller_Email__c = 'test1@test.com',
      Final_Value_Fee_Stage__c = 'Draft',
      Budget_FVF_Exposure__c = 100
    );

    insert new List<Final_Value_Fee_FVF__c>{ fvf1, fvf2 };

    Test.startTest();
    Nominated_Item__c nom1 = new Nominated_Item__c(
      Final_Value_Fee_FVF__c = fvf1.Id,
      Price_target_w__c = 12
    );
    Nominated_Item__c nom2 = new Nominated_Item__c(
      Final_Value_Fee_FVF__c = fvf2.Id,
      Price_target_w__c = null
    );
    List<Nominated_Item__c> lstNom = new List<Nominated_Item__c>{ nom1, nom2 };
    insert lstNom;

    //case 1: FVF update to Approve, and nominated item has price target = 12: OK
    fvf1.Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE;
    update fvf1;

    try {
      //case 2: VFV update to Approve, and nominated item has price target = null: KO
      fvf2.Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE;
      update fvf1;
    } catch (Exception e) {
      System.assert(
        e.getMessage()
          .contains(Label.Err_msg_Nominated_Item_has_no_target_price)
      );
    }
    try {
      Final_Value_Fee_FVF__c fvf3 = new Final_Value_Fee_FVF__c(
        Site__c = 'UK',
        Budget_Manually_Estimated__c = 40,
        Legal_Entity_Country__c = 'UK',
        Legal_Entity_Name__c = 'My Company2',
        Legal_Entity_Street__c = 'street11',
        Legal_Entity_Zip__c = '123451',
        Seller_Name__c = acc.Id,
        Seller_Email__c = 'test1@test.com',
        Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE
      );
      //case 3: FVF inserted with stage Approve. considered as error: KO
      insert fvf3;
    } catch (Exception e) {
      System.assert(
        e.getMessage()
          .contains(Label.Err_msg_Nominated_Item_has_no_target_price)
      );
    }
    Test.stopTest();
  }

  static testMethod void populateContactPersonTest() {
    setupdata();
    RecordType sellerRecordType = ApexUtil.getRecordTypeByName(
      'Account',
      'EBH_Seller'
    );
    Account acc = new Account(
      Name = 'Test Acc1',
      RecordTypeID = sellerRecordType.Id
    );
    insert acc;
    RecordType contacManul_RT = ApexUtil.getRecordTypeByName(
      'Contact',
      'EBH_MANUAL'
    );
    Contact cont = new Contact(
      LastName = 'Test Cont1',
      RecordTypeID = contacManul_RT.Id,
      AccountId = acc.Id,
      EBH_Decision_Maker_Role__c = EBH_ConstantsUtility.FVF_DECISION_MAKER_ROLE,
      EBH_Status__c = 'Active'
    );
    Contact cont2 = new Contact(
      LastName = 'Test Cont2',
      RecordTypeID = contacManul_RT.Id,
      AccountId = acc.Id,
      Primary_Contact__c = true,
      EBH_Status__c = 'Active'
    );
    insert new List<Contact>{ cont, cont2 };

    Test.startTest();
    RecordType fvfRecordType = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE
    );
    Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(
      RecordTypeId = fvfRecordType.Id,
      Site__c = 'UK',
      Seller_Name__c = acc.Id,
      Seller_Email__c = 'test@test.com'
    );
    insert fvf;
    Test.stopTest();

    fvf = [SELECT Contact_Person__c FROM Final_Value_Fee_FVF__c];
    System.assert(fvf.Contact_Person__c == cont.Id);
  }

  /* //NK:22/07/2024:US-0015373
	static testMethod void sumTotalListingNumberAndSellerTest(){
		String ADMIN_PROFILE_ID = ApexUtil.ADMIN_PROFILE_ID;
		User[] allAdmins = [Select Id From User where ProfileId=:ADMIN_PROFILE_ID AND ISActive=true limit 1];
		Profile profileId = [SELECT Id FROM Profile WHERE Name = 'AU Standard User Profile' LIMIT 1];
		UserRole usrRole = [select id, name, DeveloperName from UserRole where DeveloperName = 'Global'];
		RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
		RecordType fvfRecordTypeListing = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c',EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE);
		RecordType fvfRecordTypeCampaign = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c',EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE);
		Account acc;
		User usr;

		System.runAs(allAdmins[0]) {

			setupdata();
		
			acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id);
			insert acc;

			
			usr = new User(UserRoleId=usrRole.Id, LastName = 'testt', FirstName='test',Alias = 'test', Email = 'test99@asdf.com', Username = 'test.liveston99@asdf.com', ProfileId = profileId.id,TimeZoneSidKey = 'GMT',LanguageLocaleKey = 'en_US',EmailEncodingKey = 'UTF-8',LocaleSidKey = 'en_US');
			insert usr;

		}

		Final_Value_Fee_FVF__c fvfCam = new Final_Value_Fee_FVF__c(Site__c='UK',Seller_Name__c = acc.Id,Seller_Email__c='testtt@test.com',RecordTypeId=fvfRecordTypeCampaign.Id);
		insert fvfCam;
		
		Test.startTest();

			
    		System.runAs(usr)
    		{	

					
				 
					Final_Value_Fee_FVF__c fvf1 = new Final_Value_Fee_FVF__c(Site__c='UK',Seller_Name__c = acc.Id,Seller_Email__c='test@test.com',RecordTypeId=fvfRecordTypeListing.Id);
					Final_Value_Fee_FVF__c fvf2 = new Final_Value_Fee_FVF__c(Site__c='UK',Seller_Name__c = acc.Id,Seller_Email__c='test1@test.com',RecordTypeId=fvfRecordTypeListing.Id);
					insert new Final_Value_Fee_FVF__c[]{fvf1,fvf2};
					    
					Nominated_Item__c nom1 = new Nominated_Item__c(Final_Value_Fee_FVF__c=fvf1.Id, Price_target_w__c=12); 
					Nominated_Item__c nom2 = new Nominated_Item__c(Final_Value_Fee_FVF__c=fvf2.Id,Price_target_w__c=12);
					insert new Nominated_Item__c[]{nom1,nom2};
					
					Final_Value_Fee_FVF__c fvfCamSel1 = [Select Id,Total_Number_of_Listings_fvfcampaign__c,Total_Number_of_Sellers__c From Final_Value_Fee_FVF__c Where Id=:fvfCam.Id];
					
					//System.assertEquals(2, fvfCamSel1.Total_Number_of_Listings_fvfcampaign__c,'sum of child fvf listing (2 nominated item)');
					//System.assertEquals(2, fvfCamSel1.Total_Number_of_Sellers__c, '2 related fvf listing');
					
					Nominated_Item__c nom3 = new Nominated_Item__c(Final_Value_Fee_FVF__c=fvf2.Id,Price_target_w__c=12);
					insert nom3;

					fvfCamSel1 = [Select Id,Total_Number_of_Listings_fvfcampaign__c,Total_Number_of_Sellers__c From Final_Value_Fee_FVF__c Where Id=:fvfCam.Id];
					//System.assertEquals(3, fvfCamSel1.Total_Number_of_Listings_fvfcampaign__c,'sum of child fvf listing (2 nominated item) added 1 more');
					//System.assertEquals(2, fvfCamSel1.Total_Number_of_Sellers__c, '2 related fvf listing');
				 
				
			}
			
        Test.stopTest();

	}
	*/
  static testMethod void sendContractFVFCampaignTest() {
    String ADMIN_PROFILE_ID = ApexUtil.ADMIN_PROFILE_ID;
    User[] allAdmins = [
      SELECT Id
      FROM User
      WHERE ProfileId = :ADMIN_PROFILE_ID AND ISActive = TRUE
      LIMIT 1
    ];

    Profile profileId = [
      SELECT Id
      FROM Profile
      WHERE Name = 'AU Standard User Profile'
      LIMIT 1
    ];

    UserRole usrRole = [
      SELECT id, name, DeveloperName
      FROM UserRole
      WHERE DeveloperName = 'Global'
    ];

    User usr;
    Account acc;
    Account acc2;
    Final_Value_Fee_FVF__c fvfCam;

    RecordType fvfRecordTypeListing = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE
    );
    RecordType fvfRecordTypeCampaign = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE
    );
    PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'FVF_User'];

    System.runAs(allAdmins[0]) {
      setupdata();
      RecordType sellerRecordType = ApexUtil.getRecordTypeByName(
        'Account',
        'EBH_Seller'
      );
      RecordType legalEntityRecordType = ApexUtil.getRecordTypeByName(
        'Account',
        'EBH_LegalEntity'
      );
      acc = new Account(
        Name = 'Test Acc1',
        RecordTypeID = legalEntityRecordType.Id,
        EBH_RevRollup__c = 'UK'
      );
      insert acc;
      acc2 = new Account(
        EBH_RevRollup__c = 'UK',
        Name = 'Test Acc2',
        RecordTypeID = sellerRecordType.Id,
        ParentId = acc.Id,
        EBH_BillingStreet__c = 'testStreet',
        EBH_BillingCountry__c = 'testCountry',
        EBH_BillingPostalCode__c = 'testCode'
      );
      insert acc2;

      usr = new User(
        UserRoleId = usrRole.Id,
        LastName = 'testt',
        FirstName = 'test',
        Alias = 'test',
        Email = 'test88@asdf.com',
        Username = 'test.liveston88@asdf.com',
        ProfileId = profileId.id,
        TimeZoneSidKey = 'GMT',
        LanguageLocaleKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LocaleSidKey = 'en_US'
      );
      insert usr;

      insert new PermissionSetAssignment(
        AssigneeId = usr.id,
        PermissionSetId = pset.Id
      );
    }

    System.runAs(usr) {
      RecordType fvfRecordTypeCam = ApexUtil.getRecordTypeByName(
        'Final_Value_Fee_FVF__c',
        'FVF_Seller_Level'
      );
      fvfCam = new Final_Value_Fee_FVF__c(
        Site__c = 'UK',
        Seller_Name__c = acc2.Id,
        Seller_Email__c = 'testtt@test.com',
        RecordTypeId = fvfRecordTypeCam.Id,
        Final_Value_Fee_Stage__c = 'Draft'
      );
      insert fvfCam;

      Final_Value_Fee_FVF__c fvf1 = new Final_Value_Fee_FVF__c(
        Site__c = 'UK',
        Seller_Name__c = acc2.Id,
        Seller_Email__c = 'test@test.com',
        RecordTypeId = fvfRecordTypeListing.Id
      );
      Final_Value_Fee_FVF__c fvf2 = new Final_Value_Fee_FVF__c(
        Site__c = 'UK',
        Seller_Name__c = acc2.Id,
        Seller_Email__c = 'test1@test.com',
        RecordTypeId = fvfRecordTypeListing.Id
      );
      insert new List<Final_Value_Fee_FVF__c>{ fvf1, fvf2 };
      Test.startTest();
      fvf1.Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_EBAY_APPROVED;
      update fvf1;

      fvfCam.Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_EBAY_APPROVED;
      update fvfCam;
      //fvfCam.Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_CONTRACT_SENT;
      //update fvfCam;
      Test.stopTest();
      //System.assertEquals(EBH_ConstantsUtility.FVF_STAGE_CONTRACT_SENT,[select Final_Value_Fee_Stage__c from Final_Value_Fee_FVF__c where id =: fvf1.Id].Final_Value_Fee_Stage__c,'1 were successfully sent');
      //System.assertEquals('Draft',[select Final_Value_Fee_Stage__c from Final_Value_Fee_FVF__c where id =: fvf2.Id].Final_Value_Fee_Stage__c,'1 could not be sent.');
    }

  }

  static testMethod void testValidateStagePermission() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    User[] u_admin = [
      SELECT Id, Name, ProfileId
      FROM User
      WHERE ProfileId = :p.Id AND IsActive = TRUE
      LIMIT 2
    ];
    Final_Value_Fee_FVF__c fvf1;
    Final_Value_Fee_FVF__c fvf2;
    Final_Value_Fee_FVF__c fvf4;
    Account acc;

    Nominated_Item__c nomi1;
    Nominated_Item__c nomi2;
    RecordType prodRecordType;
    RecordType contacDW_RT;
    RecordType sellerRecordType;
    //User u_permission;
    User u_no_permission;
    PermissionSet pset;
    Contact cont;

    System.runAs(u_admin[0]) {
      setupdata();
      contacDW_RT = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
      cont = new Contact(
        LastName = 'Test Cont1',
        RecordTypeID = contacDW_RT.Id,
        Email = 'test@test.com'
      );
      insert cont;

      sellerRecordType = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
      //LA:05-12-2023-US-0014231
      //acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',Primary_Contact__c=cont.Id,EBH_DealsProgram__c ='Accepted');
      acc = new Account(
        Name = 'Test Acc1',
        RecordTypeID = sellerRecordType.Id,
        EBH_RevRollup__c = 'UK',
        Primary_Contact__c = cont.Id
      );
      insert acc;

      RecordType fvfRecordType = ApexUtil.getRecordTypeByName(
        'Final_Value_Fee_FVF__c',
        EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE
      );
      fvf1 = new Final_Value_Fee_FVF__c(
        RecordTypeId = fvfRecordType.Id,
        Budget_Manually_Estimated__c = 40,
        Legal_Entity_Country__c = 'UK',
        Legal_Entity_Name__c = 'My Company1',
        Legal_Entity_Street__c = 'street11',
        Legal_Entity_Zip__c = '123451',
        Seller_Name__c = acc.Id,
        Seller_Email__c = 'test1@test.com',
        Final_Value_Fee_Stage__c = 'Draft'
      );
      fvf2 = new Final_Value_Fee_FVF__c(
        RecordTypeId = fvfRecordType.Id,
        Budget_Manually_Estimated__c = 50,
        Legal_Entity_Country__c = 'UK',
        Legal_Entity_Name__c = 'My Company2',
        Legal_Entity_Street__c = 'street12',
        Legal_Entity_Zip__c = '123451',
        Seller_Name__c = acc.Id,
        Seller_Email__c = 'test2@test.com',
        Final_Value_Fee_Stage__c = 'Draft'
      );
      fvf4 = new Final_Value_Fee_FVF__c(
        RecordTypeId = fvfRecordType.Id,
        Site__c = 'UK',
        Budget_Manually_Estimated__c = 40,
        Legal_Entity_Country__c = 'UK',
        Legal_Entity_Name__c = 'My Company2',
        Legal_Entity_Street__c = 'street11',
        Legal_Entity_Zip__c = '123451',
        Seller_Name__c = acc.Id,
        Seller_Email__c = 'test1@test.com',
        Final_Value_Fee_Stage__c = 'Draft'
      );
      insert new List<Final_Value_Fee_FVF__c>{ fvf1, fvf2, fvf4 };

      Nominated_Item__c nom1 = new Nominated_Item__c(
        Final_Value_Fee_FVF__c = fvf1.Id,
        Price_target_w__c = 12
      );
      Nominated_Item__c nom2 = new Nominated_Item__c(
        Final_Value_Fee_FVF__c = fvf2.Id,
        Price_target_w__c = 12
      );
      Nominated_Item__c nom3 = new Nominated_Item__c(
        Final_Value_Fee_FVF__c = fvf4.Id,
        Price_target_w__c = 12
      );
      insert new List<Nominated_Item__c>{ nom1, nom2, nom3 };

      fvf1.Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE;
      fvf1.Budget_FVF_Exposure__c = 20;
        update fvf1;
      fvf2.Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE;
      fvf2.Budget_FVF_Exposure__c = 20;
      update fvf2;
      fvf4.Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE;
      fvf4.Budget_FVF_Exposure__c = 20;
      update fvf4;

      fvf1.Final_Value_Fee_Stage__c = FinalValueFee_FVF_Handler.FVF_STAGE_DRAFT;
      update fvf1;
      fvf2.Final_Value_Fee_Stage__c = FinalValueFee_FVF_Handler.FVF_STAGE_DRAFT;
      update fvf2;

      nomi1 = new Nominated_Item__c(
        Final_Value_Fee_FVF__c = fvf1.Id,
        Price_target_w__c = 12
      );
      nomi2 = new Nominated_Item__c(
        Final_Value_Fee_FVF__c = fvf2.Id,
        Price_target_w__c = 12
      );
      insert new List<Nominated_Item__c>{ nomi1, nomi2 };
    }

    System.runAs(u_admin[1]) {
      //u_permission = EBH_TestDataFactory.createUser(EBH_ConstantsUtility.TICKET_STANDARD_PROFILE);
      u_no_permission = EBH_TestDataFactory.createUser(
        EBH_ConstantsUtility.TICKET_STANDARD_PROFILE
      );
      //insert new List<User>{u_permission,u_no_permission};
      insert u_no_permission;

      //pset= [SELECT Id FROM PermissionSet WHERE Name = 'Final_Value_Fee_Approval'];
      //insert new PermissionSetAssignment(AssigneeId = u_permission.Id, PermissionSetId = pset.Id);
    }

    Test.startTest();
    System.runAs(u_admin[0]) {
      //Case Succes with admin profile
      fvf1.Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_EBAY_APPROVED;
      update fvf1;
      fvf1 = [
        SELECT Final_Value_Fee_Stage__c
        FROM Final_Value_Fee_FVF__c
        WHERE Id = :fvf1.Id
      ];
      System.assertEquals(
        EBH_ConstantsUtility.FVF_STAGE_EBAY_APPROVED,
        fvf1.Final_Value_Fee_Stage__c
      );
    }
    System.runAs(u_no_permission) {
      //Case false without permissionset and not admin profile
      try {
        fvf2.Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_EBAY_APPROVED;
        update fvf2;
      } catch (Exception e) {
        System.assert(
          e.getMessage().contains(Label.Error_Validate_Stage),
          e.getMessage()
        );
      }

      // fvf2 = [SELECT Final_Value_Fee_Stage__c FROM Final_Value_Fee_FVF__c Where Id=:fvf2.Id];
      // System.assertEquals(EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE,fvf2.Final_Value_Fee_Stage__c);
    }

    //System.runAs(u_permission){ ////Case Succes with permissionset and not admin profile
    System.runAs(u_admin[0]) {
      fvf4.Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_EBAY_APPROVED;
      update fvf4;

      fvf4 = [
        SELECT Final_Value_Fee_Stage__c
        FROM Final_Value_Fee_FVF__c
        WHERE Id = :fvf4.Id
      ];
      System.assertEquals(
        EBH_ConstantsUtility.FVF_STAGE_EBAY_APPROVED,
        fvf4.Final_Value_Fee_Stage__c
      );
    }
    //}

    Test.stopTest();
  }

  //US-0008752 - FVF listing Approval Migration - validation rules
  @isTest
  static void testListingApprovalValidationRules() {
    setupdata();
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    User[] u_admin = [
      SELECT Id, Name, ProfileId
      FROM User
      WHERE ProfileId = :p.Id AND IsActive = TRUE
      LIMIT 2
    ];
    Final_Value_Fee_FVF__c fvf1;
    Final_Value_Fee_FVF__c fvf2;
    Final_Value_Fee_FVF__c fvf3;
    Final_Value_Fee_FVF__c fvf4;
    Final_Value_Fee_FVF__c fvf5;
    Account acc;

    Nominated_Item__c nomi1;
    Nominated_Item__c nomi2;
    RecordType prodRecordType;
    RecordType contacDW_RT;
    RecordType sellerRecordType;
    User u_permission;
    User u_no_permission;
    PermissionSet pset;
    Contact cont;

    System.runAs(u_admin[0]) {
      contacDW_RT = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
      cont = new Contact(
        LastName = 'Test Cont1',
        RecordTypeID = contacDW_RT.Id,
        Email = 'test@test.com'
      );
      insert cont;

      sellerRecordType = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
      //LA:05-12-2023-US-0014231
      //acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',Primary_Contact__c=cont.Id,EBH_DealsProgram__c ='Accepted');
      acc = new Account(
        Name = 'Test Acc1',
        RecordTypeID = sellerRecordType.Id,
        EBH_RevRollup__c = 'UK',
        Primary_Contact__c = cont.Id
      );
      insert acc;

      RecordType fvfRecordType = ApexUtil.getRecordTypeByName(
        'Final_Value_Fee_FVF__c',
        EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE
      );
      fvf1 = new Final_Value_Fee_FVF__c(
        RecordTypeId = fvfRecordType.Id,
        Budget_Manually_Estimated__c = 40,
        Legal_Entity_Country__c = 'UK',
        Legal_Entity_Name__c = 'My Company1',
        Legal_Entity_Street__c = 'street11',
        Legal_Entity_Zip__c = '123451',
        Seller_Name__c = acc.Id,
        Seller_Email__c = 'test1@test.com',
        Final_Value_Fee_Stage__c = 'Draft',
        Budget_FVF_Exposure__c = 100
      );
      fvf2 = new Final_Value_Fee_FVF__c(
        RecordTypeId = fvfRecordType.Id,
        Budget_Manually_Estimated__c = 50,
        Legal_Entity_Country__c = 'UK',
        Legal_Entity_Name__c = 'My Company2',
        Legal_Entity_Street__c = 'street12',
        Legal_Entity_Zip__c = '123451',
        Seller_Name__c = acc.Id,
        Seller_Email__c = 'test2@test.com',
        Final_Value_Fee_Stage__c = 'Draft',
        Budget_FVF_Exposure__c = 100
      );
      fvf3 = new Final_Value_Fee_FVF__c(
        RecordTypeId = fvfRecordType.Id,
        Site__c = 'UK',
        Budget_Manually_Estimated__c = 40,
        Legal_Entity_Country__c = 'UK',
        Legal_Entity_Name__c = 'My Company2',
        Legal_Entity_Street__c = 'street11',
        Legal_Entity_Zip__c = '123451',
        Seller_Name__c = acc.Id,
        Seller_Email__c = 'test1@test.com',
        Final_Value_Fee_Stage__c = 'Draft',
        Budget_FVF_Exposure__c = 100
      );
      RecordType recTypeFVFCampaign = ApexUtil.getRecordTypeByName(
        'Final_Value_Fee_FVF__c',
        'FVF_Seller_Level'
      );
      fvf4 = new Final_Value_Fee_FVF__c(
        RecordTypeId = recTypeFVFCampaign.Id,
        Seller_Name__c = acc.Id,
        Seller_Email__c = 'test@test.com',
        Budget_Manually_Estimated__c = 3000,
        Site__c = 'UK',
        Budget_FVF_Exposure__c = 100
      );
      fvf5 = new Final_Value_Fee_FVF__c(
        RecordTypeId = fvfRecordType.Id,
        Discount_FVF__c = 25,
        Seller_Name__c = acc.Id,
        Seller_Email__c = 'test2@test.com',
        Budget_FVF_Exposure__c = 100
      );

      insert new List<Final_Value_Fee_FVF__c>{ fvf1, fvf2, fvf3, fvf4, fvf5 };

      Nominated_Item__c nom1a = new Nominated_Item__c(
        Final_Value_Fee_FVF__c = fvf1.Id,
        Price_target_w__c = 12
      );
      Nominated_Item__c nom2a = new Nominated_Item__c(
        Final_Value_Fee_FVF__c = fvf2.Id,
        Price_target_w__c = 12
      );

      insert new List<Nominated_Item__c>{ nom1a, nom2a };

      fvf1.Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE;
      update fvf1;
      fvf2.Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE;
      update fvf2;

      nomi1 = new Nominated_Item__c(
        Final_Value_Fee_FVF__c = fvf1.Id,
        Price_target_w__c = 12
      );
      nomi2 = new Nominated_Item__c(
        Final_Value_Fee_FVF__c = fvf2.Id,
        Price_target_w__c = 12
      );
    }

    Test.startTest();
    // US-0008752 AC3 - FVF listing Approval Migration - validation rules
    try {
      insert new List<Nominated_Item__c>{ nomi1, nomi2 };
      //System.assert(false, 'This should throw error');
    } catch (Exception ex) {
      System.assert(
        ex.getMessage()
          .contains(
            'You can only edit or upload Nominated Items on your Final Value Fee listing when the status is Draft.'
          ),
        ex.getMessage()
      );
    }

    fvf1.Final_Value_Fee_Stage__c = FinalValueFee_FVF_Handler.FVF_STAGE_DRAFT;
    update fvf1;
    fvf2.Final_Value_Fee_Stage__c = FinalValueFee_FVF_Handler.FVF_STAGE_DRAFT;
    update fvf2;

    try {
      insert new List<Nominated_Item__c>{ nomi1, nomi2 };
    } catch (Exception ex) {
      //US-0008752 AC3 - FVF listing Approval Migration - validation rules
      //System.assert(false, 'This should no error');
    }

    // US-0008752 AC5 - FVF listing Approval Migration - validation rules

    try {
      fvf5.Final_Value_Fee_Stage__c = FinalValueFee_FVF_Handler.FVF_STAGE_EBAY_SENT_TO_APPROVE;
      update fvf5;
      //System.assert(false, 'This should throw error');
    } catch (Exception ex) {
      // US-0008752 AC5 - FVF listing Approval Migration - validation rules
      System.assert(
        ex.getMessage()
          .contains(Label.Validate_Empty_NominatedItem_Error_Message),
        ex.getMessage()
      );
    }

    try {
      Nominated_Item__c nomi3 = new Nominated_Item__c(
        Final_Value_Fee_FVF__c = fvf3.Id,
        Price_target_w__c = 12
      );
      insert nomi3;

      fvf3.Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE;
      update fvf3;
    } catch (Exception ex) {
      // US-0008752 AC5 - FVF listing Approval Migration - validation rules
      System.assert(false, 'This should no error');
    }
    Test.stopTest();
  }

  //LA: US-0009242: Process Builder Name: FVF_Process
  @isTest
  static void test_Process_FVFStageToContractDeclined() {
    setupdata();
    RecordType contacDW_RT = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
    Contact cont = new Contact(
      LastName = 'Test Cont1',
      RecordTypeID = contacDW_RT.Id,
      Email = 'test@test.com'
    );
    insert cont;
    RecordType sellerRecordType = ApexUtil.getRecordTypeByName(
      'Account',
      'EBH_Seller'
    );
    //LA:05-12-2023-US-0014231
    //Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',Primary_Contact__c=cont.Id,EBH_DealsProgram__c ='Accepted');
    Account acc = new Account(
      Name = 'Test Acc1',
      RecordTypeID = sellerRecordType.Id,
      EBH_RevRollup__c = 'UK',
      Primary_Contact__c = cont.Id
    );
    insert acc;

    RecordType fvfRecordType = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE
    );
    Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(
      Site__c = 'UK',
      RecordTypeId = fvfRecordType.Id,
      Legal_Entity_Country__c = 'UK',
      Legal_Entity_Name__c = 'My Company',
      Legal_Entity_Street__c = 'street1',
      Legal_Entity_Zip__c = '12345',
      Seller_Name__c = acc.Id,
      Seller_Email__c = 'test@test.com',
      Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_CONTRACT_SENT
    );
    insert fvf;

    Test.startTest();

    fvf.Final_Value_Fee_Stage__c = 'Contract Declined';
    update fvf;

    Final_Value_Fee_FVF__c fvf1 = [
      SELECT Id, Contract_Declined_Date__c
      FROM Final_Value_Fee_FVF__c
      WHERE Id = :fvf.Id
    ];
    //System.assertEquals(fvf1.Contract_Declined_Date__c, System.now());
    Test.stopTest();
  }
  @isTest
  static void test_Process_FVFStageNotContractDeclined() {
    setupdata();
    RecordType contacDW_RT = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
    Contact cont = new Contact(
      LastName = 'Test Cont1',
      RecordTypeID = contacDW_RT.Id,
      Email = 'test@test.com'
    );
    insert cont;
    RecordType sellerRecordType = ApexUtil.getRecordTypeByName(
      'Account',
      'EBH_Seller'
    );
    //LA:05-12-2023-US-0014231
    //Account acc = new Account(Name='Test Acc1',RecordTypeID = sellerRecordType.Id,EBH_RevRollup__c='UK',Primary_Contact__c=cont.Id,EBH_DealsProgram__c ='Accepted');
    Account acc = new Account(
      Name = 'Test Acc1',
      RecordTypeID = sellerRecordType.Id,
      EBH_RevRollup__c = 'UK',
      Primary_Contact__c = cont.Id
    );
    insert acc;

    RecordType fvfRecordType = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE
    );
    Final_Value_Fee_FVF__c fvf = new Final_Value_Fee_FVF__c(
      Site__c = 'UK',
      RecordTypeId = fvfRecordType.Id,
      Legal_Entity_Country__c = 'UK',
      Legal_Entity_Name__c = 'My Company',
      Legal_Entity_Street__c = 'street1',
      Legal_Entity_Zip__c = '12345',
      Seller_Name__c = acc.Id,
      Seller_Email__c = 'test@test.com',
      Final_Value_Fee_Stage__c = 'Contract Declined'
    );
    insert fvf;

    Test.startTest();
    fvf.Final_Value_Fee_Stage__c = 'Draft';
    update fvf;

    Final_Value_Fee_FVF__c fvf1 = [
      SELECT Id, Contract_Declined_Date__c
      FROM Final_Value_Fee_FVF__c
      WHERE Id = :fvf.Id
    ];
    //System.assertEquals(fvf1.Contract_Declined_Date__c, null);
    Test.stopTest();
  }
}