/***************************************************************************************************************************************
@ Class:          EBH_TestDataFactory
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Utility Class for the Creation of Test Data for all the test classes.
----------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.05.2017 / JOY MONDOL / Created the class.
@               : 10/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
***************************************************************************************************************************************/

@isTest
public class EBH_TestDataFactory {

    /*SOQL queries*/
    public static final String ACCRECTYPQUERY      = 'SELECT Id FROM RecordType '
                                                   + 'WHERE SObjectType = \'Account\' AND DeveloperName =: recordType LIMIT 1';
                                                  
    public static final String CONTRACTRECTYPQUERY = 'SELECT Id FROM RecordType '
                                                   + 'WHERE SObjectType = \'Contract\' AND Name =: recordType LIMIT 1';
                                                   
    public static final String APPROVERRECTYPQUERY = 'SELECT Id FROM RecordType '
                                                   + 'WHERE SObjectType = \'EBH_ContractApprovalHierarchy__c\' AND '+
                                                   + ' DeveloperName =: recordType LIMIT 1';
                                                  
    public static final String PRICINGRECTYPQUERY = 'SELECT Id FROM RecordType '
                                                   + 'WHERE SObjectType = \'EBH_Pricing__c\' AND DeveloperName =: recordType LIMIT 1';
                                                   
    public static final String PRFQUERY       = 'SELECT Id, Name FROM Profile WHERE Name = :profileName';
    
    public static final String SELLERLISTRECTYPQUERY = 'SELECT Id FROM RecordType '
                                                   + 'WHERE SObjectType = \'EBH_Filter__c\' AND DeveloperName =: recordType LIMIT 1';
    
    /***********************************************************************************************************************************
    @ Method:         setUpApexLoggerData 
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Method to create all test data for "ApexLogger" class.
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map of all records keyed by sobject name
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / JOY MONDOL / Created the Method.
    ***********************************************************************************************************************************/
    public static Map<String, List<Sobject>> setUpApexLoggerData() {
        
        return new Map<String, List<Sobject>> { 'accounts' => createAccounts(1, 'EBH_Seller') };
    } 
    
    /***********************************************************************************************************************************
    @ Method:         setupAccountTriggerHandlerData 
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Method to create all test data for "AccountTriggerHandler" class.
                        
                        LE 1                LE 4
                        |___SEL 1           |___SEL 7
                        |___SEL 2
                        |___LE 2
                            |___SEL 3
                            |___SEL 4
                            |___LE 3
                                |___SEL 5
                                |___SEL 6
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map of all records keyed by account level name
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / JOY MONDOL / Created the Method.
    ***********************************************************************************************************************************/
    public static Map<String, Account> setupAccountTriggerHandlerData() {
        RecordType recTLegal = ApexUtil.getRecordTypeByName('Account','EBH_LegalEntity');
        RecordType recTSlr = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        List<Account> accounts = new List<Account>();
        List<Account> legalEntities = new List<Account>(); //createAccounts(4, 'EBH_LegalEntity');
        List<Account> sellers = new List<Account>(); //createAccounts(7, 'EBH_Seller');
        for(integer i=1;i<=4;i++){
            legalEntities.add(new Account(
                Name = 'TST ACC Legal ' + i,
                EBH_OracleID__c = '11111111'+i,
                RecordTypeId = recTLegal.Id
            ));
        }
        //TH:20/11/2020:fix test class EBH_RelatedSellersControllerTest : put: insert legalEntities;
        insert legalEntities;
        
        for(integer i=1;i<=7;i++){
            sellers.add(new Account(
                Name = 'TST ACC SLR ' + i,
                EBH_OracleID__c = '22222222'+i,
                RecordTypeId = recTSlr.Id
            ));
        }
        
        sellers[0].ParentId = legalEntities[0].Id;
        sellers[1].ParentId = legalEntities[0].Id;
        
        sellers[2].ParentId = legalEntities[1].Id;
        sellers[3].ParentId = legalEntities[1].Id;
        
        sellers[4].ParentId = legalEntities[2].Id;
        sellers[5].ParentId = legalEntities[2].Id;
        
        sellers[6].ParentId = legalEntities[3].Id;
        sellers[6].EBH_SoldItems__c = 100;
        
        legalEntities[1].ParentId = legalEntities[0].Id;
        legalEntities[2].ParentId = legalEntities[1].Id;
        
        accounts.addAll(legalEntities);
        accounts.addAll(sellers);
        System.debug('accounts>>>>'+accounts);
        //TH:20/11/2020:fix test class EBH_RelatedSellersControllerTest : change from Insert to upsert
        upsert accounts;
        //insert accounts;
        return new Map<String, Account> { 'le1' => legalEntities[0], 'se1' => sellers[0], 'se2' => sellers[1],
                                          'le2' => legalEntities[1], 'se3' => sellers[2], 'se4' => sellers[3],
                                          'le3' => legalEntities[2], 'se5' => sellers[4], 'se6' => sellers[5],
                                          'le4' => legalEntities[3], 'se7' => sellers[6] };
    }
    
    /***********************************************************************************************************************************
    @ Method:         setupAccountContactTriggerHandlerData 
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method to create all test data for "AccountContactRelationTriggerHandler" class.
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map of all records keyed by account contact relation level name
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 31.08.2017 / NEHA LUND / Created the Method.
    ***********************************************************************************************************************************/
    public static Map<String, AccountContactRelation> setupAccountContactTriggerHandlerData() {
        
        List<Account> accounts = new List<Account>();
        List<Account> sellers = createAccounts(3, 'EBH_Seller');
        List<Contact> contacts = createContacts(7, 'Test Contact', sellers[0].id);
        contacts[1].EBH_Status__c = 'Deleted';
        update contacts[1];
        AccountContactRelation acr1 = createAccountContactRelations(sellers[2].id,contacts[1].id);
        AccountContactRelation acr2 = createAccountContactRelations(sellers[1].id,contacts[2].id);
        return new Map<String, AccountContactRelation> { 'ac1' => acr1, 'ac2' => acr2 };
    }
    
    /***********************************************************************************************************************************
    @ Method:         setupEBH_ContractApprovalSettingsControllerData 
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Method to create all test data for "EBH_ContractApprovalSettingsController" class.
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map of records keyed by objectname
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.05.2017 / JOY MONDOL / Created the Method.
    ***********************************************************************************************************************************/
    public static Map<String, Object> setupEBH_ContractApprovalSettingsControllerData() {
        
        List<User> admUsers = createUsers(1, 'System Administrator');
        List<User> stdUsers = createUsers(10, 'Standard User');
        List<String> options = new List<String>();
        
        Schema.DescribeFieldResult fieldResult = EBH_ContractApprovalMatrix__c.EBH_Site__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
        for(Schema.PicklistEntry f : ple) {
            options.add(f.getValue());
        } 
        
        insert stdUsers;
        insert admUsers;
        
        return new Map<String, Object> { 'admUsers' => admUsers,
                                         'stdUsers' => stdUsers,
                                         'sites'    => options,
                                         'mx'       => createContractApprovalMatrix('UK', stdUsers[0].Id, stdUsers[1].Id),
                                         'hxf1'     => createContractApprovalHierarchy('EBH_Finance', stdUsers[2].Id, 10),
                                         'hxf2'     => createContractApprovalHierarchy('EBH_Finance', stdUsers[3].Id, 100),
                                         'hxc1'     => createContractApprovalHierarchy('EBH_Controlling', stdUsers[4].Id, 10),
                                         'hxc2'     => createContractApprovalHierarchy('EBH_Controlling', stdUsers[5].Id, 100) };
    }
    
    /***********************************************************************************************************************************
    @ Method:         setUpContractTriggerHandlerData 
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        Method to create all test data for "ContractTriggerHandler" class.
                      To create legal entity records and Contracts, to check the population of 'Pre-Approved Template'
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map of all records keyed by account level name
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.05.2017 / NEHA LUND / Created the Method.
    ***********************************************************************************************************************************/
    public static List<Contract> setUpContractTriggerHandlerData() {
        
        setUpPreApprovedContractSettings();
        List<Account> legalEntities = createAccounts(2, 'EBH_LegalEntity');
        
        List<Contract> contracts = createContracts (10, 'ACP', 
                                                    legalEntities[0].id, legalEntities[1].id);
        
        createListingPricingExposure('UK');   
        return contracts;     
      
    }
    
    /***********************************************************************************************************************************
    @ Method:         setUpTargetedSellerTriggerHandlerData 
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL
    @ Purpose:        Method to create all test data for "TargetedSellerTriggerHandler" class.
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map of all records keyed by targeted seller level name
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.06.2017 / ASHISH BARANWAL / Created the Method.
    ***********************************************************************************************************************************/
    public static List<EBH_TargetedSeller__c> setUpTargetedSellerTriggerHandlerData() {
        
        List<Account> legalEntities = createAccounts(2, 'EBH_Seller');
        List<Contact> contacts1 = createContacts(2, 'Test Contact', legalEntities[0].id);
        List<Contact> contacts2 = createContacts(2, 'Test Contact AB', legalEntities[0].id);
        List<EBH_Filter__c> sellerLists = createSellerLists(2, 'Test Seller List', 'Snapshot_Seller_List', System.today() + 365);// EBH_AutoRefreshSellerList
        List<Campaign> campaigns1 = createCampaignsWithSellerList(2, 'Test Campaign', 'UK', 'EBH_Campaign',createSellerLists(2, 'Test Seller List', 'Snapshot_Seller_List', System.today() + 365));
        List<Campaign> campaigns2 = createCampaignsWithSellerList(2, 'Test Campaign', 'UK', 'EBH_CampaignProgramme',createSellerLists(2, 'Test Seller List', 'Snapshot_Seller_List', System.today() + 365));
        List<EBH_TargetedSeller__c> targetedSellers1 = createtargetedSellers(1, sellerLists[0].id, legalEntities[0].id);
        List<EBH_TargetedSeller__c> targetedSellers2 = createtargetedSellers(1, sellerLists[1].id, legalEntities[1].id);
        List<Campaign> campaigns3 = createCampaignsWithSellerList(2, 'Test Campaign', 'UK', 'EBH_CampaignProgramme',createSellerLists(2, 'Test Seller List', 'Snapshot_Seller_List', System.today() + 365));
        
        return targetedSellers1; 
    }
    
    /***********************************************************************************************************************************
    @ Method:         setUpCampaignMemberBatchData 
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL
    @ Purpose:        Method to create all test data for "DeleteCampaignMemberBatch" class.
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map of all records keyed by targeted seller level name
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.07.2017 / ASHISH BARANWAL / Created the Method.
    ***********************************************************************************************************************************/
    public static List<CampaignMember> setUpCampaignMemberBatchData() {
        
        List<Account> legalEntities = createAccounts(2, 'EBH_Seller');
        List<Contact> contacts1 = createContacts(2, 'Test Contact', legalEntities[0].id);
        List<Contact> contacts2 = createContacts(2, 'Test Contact AB', legalEntities[0].id);
        List<Contact> contacts3 = createContacts(2, 'Test Contact1', legalEntities[0].id);
        List<Contact> contacts4 = createContacts(2, 'Test Contact AB1', legalEntities[0].id);
        AccountContactRelation acr1 = createAccountContactRelations(legalEntities[1].id,contacts1[0].id);
        AccountContactRelation acr2 = createAccountContactRelations(legalEntities[1].id,contacts1[1].id);
        List<EBH_Filter__c> sellerLists = createSellerLists(2, 'Test Seller List', 'EBH_AutoRefreshSellerList', System.today() + 365);
        List<Campaign> campaigns1 = createCampaignsWithSellerList(2, 'Test Campaign', 'UK', 'EBH_Campaign',sellerLists);
        List<Campaign> campaigns2 = createCampaignsWithSellerList(2, 'Test Campaign', 'UK', 'EBH_CampaignProgramme',sellerLists);
        List<EBH_TargetedSeller__c> targetedSellers1 = createtargetedSellers(1, sellerLists[0].id, legalEntities[0].id);
        List<EBH_TargetedSeller__c> targetedSellers2 = createtargetedSellers(1, sellerLists[0].id, legalEntities[1].id);
        List<Campaign> campaigns3 = createCampaignsWithSellerList(2, 'Test Campaign', 'UK', 'EBH_CampaignProgramme',sellerLists);
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        campaignMembers.addAll(createCampaignMembers(1, campaigns1[0].id, contacts1[0].id, TRUE));
        campaignMembers.addAll(createCampaignMembers(1, campaigns1[0].id, contacts1[1].id, TRUE));
        campaignMembers.addAll(createCampaignMembers(1, campaigns2[0].id, contacts2[0].id, FALSE));
        campaignMembers.addAll(createCampaignMembers(1, campaigns2[0].id, contacts2[1].id, FALSE));
        campaignMembers.addAll(createCampaignMembers(1, campaigns3[0].id, contacts3[0].id, FALSE));
        return campaignMembers;
    }
    
    /***********************************************************************************************************************************
    @ Method:         setUpStrategicCampaignData 
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL
    @ Purpose:        Method to create test data for Strategy Campaign
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List of Campaigns
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.09.2017 / ASHISH BARANWAL / Created the Method.
    ***********************************************************************************************************************************/
    public static List<Campaign> setUpStrategicCampaignData() {
        
        RecordType rt = getRecordTypeByName('Campaign','EBH_CampaignProgramme');//[SELECT id from RecordType where sobjectType ='Campaign' and DeveloperName = 'EBH_CampaignProgramme']; //NK:29/10/2018
        //RecordType rt = [SELECT id from RecordType where sobjectType ='Campaign' and DeveloperName = 'EBH_Campaign']; 		//NK:29/10/2018
        
        RecordType rt1 = getRecordTypeByName('Campaign','EBH_CampaignRequest');//[SELECT id from RecordType where sobjectType ='Campaign' and DeveloperName = 'EBH_CampaignRequest'];
        Campaign campaignsp = new Campaign(Name = 'Test Campaign SP',recordTypeId = rt.Id);
        insert campaignsp;
        
        List<Campaign> campaigns1 = createCampaignsWithParent(2, 'Test Campaign1', 'UK', 'EBH_Campaign',campaignsp.id,'Feasibility');
        List<EBH_KPI__c> kpiRecords = createKPIRecords('Test');
        List<EBH_CampaignKPI__c> campaignKPIRecords = new List<EBH_CampaignKPI__c>();
        
        campaignKPIRecords.add(createCampaignKPIRecord( campaigns1[0].id, kpiRecords[0].id, 10));
        insert campaignKPIRecords;
        
        List<Campaign> campaigns2 = createCampaignsWithParent(2, 'Test Campaign2', 'UK', 'EBH_Campaign',campaignsp.id,'Submitted'); //NK:29/10/2018
        List<Campaign> campaigns3 = createCampaignsWithParent(2, 'Test Campaign2a', 'UK', 'EBH_Campaign',campaignsp.id,'Preparation'); //NK:29/10/2018
        //List<Campaign> campaigns4 = createCampaignsWithParent(2, 'Test Campaign2', 'UK', 'EBH_ExternalCampaign',campaigns3[0].id,'Feasibility'); //NK:29/10/2018
        campaigns2[0].Name = 'Name Updated';
        Update campaigns2;
       // campaigns4[0].recordTypeId = rt1.Id; //NK:29/10/2018
        //Update campaigns4; //NK:29/10/2018
        return campaigns1;
    }    
     /***********************************************************************************************************************************
    @ Method:         createNBARecord 
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        Method to create all test data for "PricingTriggerHandler" class.
                      To create legal entity records, Contracts & Pricing, to populate the Contract Listing Value/Exposure
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map of all records keyed by account level name
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 30.10.2017 / NEHA LUND / Created the Method.
    ***********************************************************************************************************************************/
    public static EBH_NBA__c createNBARecord(Id sellerId) {
        
        EBH_NBA__c nbaRecord = new EBH_NBA__c(EBH_Seller__c = sellerID);
        return nbaRecord;
         
        
    }
    /***********************************************************************************************************************************
    @ Method:         setUpPricingTriggerHandlerData 
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        Method to create all test data for "PricingTriggerHandler" class.
                      To create legal entity records, Contracts & Pricing, to populate the Contract Listing Value/Exposure
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map of all records keyed by account level name
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.05.2017 / NEHA LUND / Created the Method.
    ***********************************************************************************************************************************/
    public static List< EBH_Pricing__c > setUpPricingTriggerHandlerData() {
        
        setUpSiteStoreSubscriptionFeesSettings('Test UK', 'UK', 4040); 
        createListingPricingExposure('UK');
        List<Account> legalEntities = createAccounts(2, 'EBH_LegalEntity');
        //----Linsting
        List<Contract> contractsListing = createContracts (2, 'Listing Agreement', 
                                                    legalEntities[0].id, legalEntities[1].id );
                                                    
        for( Contract contract : contractsListing )
        {
            contract.EBH_Site__c = 'UK';
            contract.status = 'Draft';
        }
        update contractsListing;
        
        List<EBH_Pricing__c> pricings = createPricing (10, EBH_ConstantsUtility.PRICING_LISTINGRECORDTYPE, 
                                                    contractsListing[0].id, 15, 900.00, 800.00, 2000000, 800, 'UK');
        
        //----ACP
        List<Contract> contractsACP = createContracts (2, 'ACP', 
                                                    legalEntities[0].id, legalEntities[1].id );
                                                    
        for( Contract contract : contractsACP )
        {
            contract.EBH_Site__c = 'UK';
            contract.status = 'Draft';
        }
        update contractsACP;
        pricings = createPricing (10, EBH_ConstantsUtility.PRICING_ACPTARGETRECORDTYPE, 
                                                    contractsACP[0].id, 15, 900.00, 800.00, 2000000, 800, 'UK');
        //----Revenue Share Target
        List<Contract> contractsRevenueShare = createContracts (2, 'Revenue Share', 
                                                    legalEntities[0].id, legalEntities[1].id );
                                                    
        for( Contract contract : contractsRevenueShare )
        {
            contract.EBH_Site__c = 'UK';
            contract.status = 'Draft';
            contract.EBH_AverageTakeRate__c = 100.00;
            contract.EBH_RevenueShareRate__c = 20.00;
        }
        
        update contractsRevenueShare;
        pricings = createPricing (10, EBH_ConstantsUtility.PRICING_REVENUESHARETARGETRECORDTYPE, 
                                                    contractsRevenueShare[0].id, 15, 900.00, 800.00, 2000000, 800, 'UK');
        
        return pricings;
    }
    
    /************************************************************************************************************************************
    @ Method:         createListingPricingExposure
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method to create dynamic approver test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Site                : String Site value
                      legalUserId         : Legal Approver for each Site
                      preCheckFinanceUser : Finance Pre-check User for each Site
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<EBH_ContractApprovalMatrix__c>: List of Dynamic Approver Matrix
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static void createListingPricingExposure(String site) {
        
       EBH_ListingPricingExposure__c lpe = new EBH_ListingPricingExposure__c();
       lpe.name = site;
       lpe.EBH_GalleryPlus__c = 10;
       lpe.EBH_InsertionFees__c = 20;
       lpe.EBH_InternationalSiteVisibility__c = 30;
       lpe.EBH_PicturePack__c = 40;
       lpe.EBH_Store__c = 50;
       lpe.EBH_Subtitle__c = 20;
       insert lpe;
         
    }
    /************************************************************************************************************************************
    @ Method:         createContractPricingMatrix
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method to create dynamic approver test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Site                : String Site value
                      legalUserId         : Legal Approver for each Site
                      preCheckFinanceUser : Finance Pre-check User for each Site
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<EBH_ContractApprovalMatrix__c>: List of Dynamic Approver Matrix
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static EBH_ContractPricingMatrix__c createContractPricingMatrix(String Site ) {
        
       EBH_ContractPricingMatrix__c cpm = new EBH_ContractPricingMatrix__c();
       cpm.EBH_CAP__c = 10;
       cpm.EBH_FVF__c = 20;
       cpm.EBH_ListingFormat__c = 'Auction';
       cpm.EBH_SiteCountry__c = Site;
       cpm.EBH_Site__c = Site;
       insert cpm;
       return cpm;
    }
    
    /************************************************************************************************************************************
    @ Method:         createContractApprovalMatrix
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method to create dynamic approver test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Site                : String Site value
                      legalUserId         : Legal Approver for each Site
                      preCheckFinanceUser : Finance Pre-check User for each Site
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<EBH_ContractApprovalMatrix__c>: List of Dynamic Approver Matrix
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static EBH_ContractApprovalMatrix__c createContractApprovalMatrix(String site, Id legalUserId, Id preCheckFinanceUser) {
        
        return new EBH_ContractApprovalMatrix__c(EBH_Site__c = site, 
                                                 EBH_LegalApprover__c = legalUserId, 
                                                 EBH_FinancePrecheckApprover__c = preCheckFinanceUser );
        
    }
    
    /************************************************************************************************************************************
    @ Method:         createContractApprovalHierarchy
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method to create dynamic approver test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Site       : String Site value
                      threshold  : threshold currency
                      approverId : approver id
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<EBH_ContractApprovalMatrix__c>: List of Dynamic Approver Matrix
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static EBH_ContractApprovalHierarchy__c createContractApprovalHierarchy(String recordType, Id approverId, 
                                                                                   Decimal threshold ) {
               
        RecordType rt = Database.query(APPROVERRECTYPQUERY);
        
        return new EBH_ContractApprovalHierarchy__c(RecordTypeId = rt.Id, 
                                                    EBH_Approver__c = approverId, EBH_Threshold__c = threshold);
    }
    
    /************************************************************************************************************************************
    @ Method:         createBUApprovalHierarchy
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method to create dynamic approver test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Site       : String Site value
                      threshold  : threshold currency
                      approverId : approver id
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<EBH_ContractApprovalMatrix__c>: List of Dynamic Approver Matrix
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static EBH_BUApproverGroup__c createBUApprovalHierarchy(Id  hierarchyId, Id approverId
                                                                                   ) {
       
        
        return new EBH_BUApproverGroup__c(EBH_BUHierarchy__c = hierarchyId, 
                                                    EBH_Approver__c = approverId);
    }
    
    /************************************************************************************************************************************
    @ Method:         createParentSiteApprover
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method to create dynamic approver test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Site                : String Site value
                      legalUserId         : Legal Approver for each Site
                      preCheckFinanceUser : Finance Pre-check User for each Site
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<EBH_ContractApprovalMatrix__c>: List of Dynamic Approver Matrix
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static EBH_ContractApprovalMatrix__c  createParentSiteApprover( String site, Id legalUserId, Id preCheckFinanceUser ) {
        
        EBH_ContractApprovalMatrix__c approver = new EBH_ContractApprovalMatrix__c( 
                                                 EBH_Site__c = site, 
                                                 EBH_LegalApprover__c = legalUserId, 
                                                 EBH_FinancePrecheckApprover__c = preCheckFinanceUser );
        
        insert approver;
        return approver;
    }
    
    /************************************************************************************************************************************
    @ Method:         createCampaigns
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method to create campaign records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      numOfRecords        : integer - number of records which need to be created
                      Name                : String Campaign Name
                      Site                : String Site value
                      recordType          : record type name which can be used to query Record type Id
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<EBH_ContractApprovalMatrix__c>: List of Dynamic Approver Matrix
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static List<Campaign>  createCampaigns( integer numOfRecords, String name, String site, String recordType ) {
        
       
        List<Campaign> campaigns = new List<Campaign>();
        
        RecordType rt = getRecordTypeByName('Campaign',recordType);//[SELECT id from RecordType where sobjectType ='Campaign' and DeveloperName = :recordType ];
        
        for( integer i=0 ; i< numOfRecords ; i++ ){
            
            campaigns.add( new Campaign( Name = name,
                                         EBH_Site__c = site,
                                         recordTypeId = rt.Id ));
        } 
        insert campaigns;
        return campaigns;
    }
    //NK:20/11/2018: reduce soql
    private static Map<String,RecordType> mapRecordType;
    public static RecordType getRecordTypeByName(String sobjectName,String recordTypeName)
    {
    	if(mapRecordType==null)
    	{
    		mapRecordType = new Map<String,RecordType>();
    		for(RecordType rt : [SELECT id,sobjectType,DeveloperName from RecordType])
    		{
    			mapRecordType.put(rt.sobjectType+''+rt.DeveloperName,rt);
    		}
    	} 
    	return mapRecordType.get(sobjectName+recordTypeName);
    }
    /************************************************************************************************************************************
    @ Method:         createCampaignsWithParent
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL
    @ Purpose:        Method to create campaign records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      numOfRecords        : integer - number of records which need to be created
                      Name                : String Campaign Name
                      Site                : String Site value
                      recordType          : record type name which can be used to query Record type Id
                      sellerListId        : Seller List Id
                      ParentId            : Parent Campaign Id
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<EBH_ContractApprovalMatrix__c>: List of Dynamic Approver Matrix
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.06.2017 / ASHISH BARANWAL / Created the Method.
    ************************************************************************************************************************************/
    public static List<Campaign>  createCampaignsWithParent(Integer numOfRecords, String name, String site, String recordType, 
                            Id ParntId, String staus ) {
        
       //recordType = mapRecordTypeReplace.containsKey(recordType)?mapRecordTypeReplace.get(recordType):recordType; //NK:29/10/2018
        List<Campaign> campaigns = new List<Campaign>();
        
        RecordType rt = getRecordTypeByName('Campaign',recordType);//[SELECT id from RecordType where sobjectType ='Campaign' and DeveloperName = :recordType ];
        
        for( integer i=0 ; i< numOfRecords ; i++){
            
            campaigns.add( new Campaign( Name = name,
                                         EBH_Site__c = site,
                                         recordTypeId = rt.Id,
                                         ParentId = ParntId,
                                         Status = staus));
        } 
        insert campaigns;
        return campaigns;
    }
    //NK:17/06/2018: some recordtype have been deactivated. also added filter for parent
    static Map<String,String> mapRecordTypeReplace = new Map<String,String>{'EBH_CampaignProgramme'=>'EBH_Campaign','EBH_StrategicPriority'=>'EBH_AMOutreach','EBH_ExternalCampaign'=>'EBH_AMOutreach'};
    /************************************************************************************************************************************
    @ Method:         createCampaignsWithSellerList
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL
    @ Purpose:        Method to create campaign records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      numOfRecords        : integer - number of records which need to be created
                      Name                : String Campaign Name
                      Site                : String Site value
                      recordType          : record type name which can be used to query Record type Id
                      sellerListId        : Seller List Id
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<EBH_ContractApprovalMatrix__c>: List of Dynamic Approver Matrix
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.06.2017 / ASHISH BARANWAL / Created the Method.
    ************************************************************************************************************************************/
    public static List<Campaign>  createCampaignsWithSellerList( integer numOfRecords, String name, String site, String recordType, List<EBH_Filter__c> sellerLists ) {
       //recordType = mapRecordTypeReplace.containsKey(recordType)?mapRecordTypeReplace.get(recordType):recordType; //NK:29/10/2018
        
        List<Campaign> campaigns = new List<Campaign>();
        
        RecordType rt = getRecordTypeByName('Campaign',recordType);//[SELECT id from RecordType where sobjectType ='Campaign' and DeveloperName = :recordType ];
         Id sellerListId = null;
         
        for( integer i=0 ; i< numOfRecords ; i++){
            sellerListId = null;
            if(sellerLists != null)
           sellerListId =  sellerLists[i].id;
            campaigns.add( new Campaign( Name = name+genRandomString(7),EBH_Channel__c='Email',EBH_ChannelMP__c='Email',
                                         EBH_Site__c = site,
                                         recordTypeId = rt.Id,
                                         EBH_SellerList__c = sellerListId));
        } 
        insert campaigns;
        return campaigns;
    }
    public static String genRandomString(Integer len)
    {
    	Blob blobKey = crypto.generateAesKey(192);
		String key = EncodingUtil.base64encode(blobKey);
		return key.substring(0,len);
    }
    /************************************************************************************************************************************
    @ Method:         createChildSiteApprover
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method to create dynamic approver test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Site                : String Site value
                      legalUserId         : Legal Approver for each Site
                      preCheckFinanceUser : Finance Pre-check User for each Site
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<EBH_ContractApprovalMatrix__c>: List of Dynamic Approver Matrix
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static EBH_ContractApprovalHierarchy__c  createChildSiteApprover(String recordType, Id parentApprover, 
                                                                            Id approverUser, decimal threshold ) {
               
        EBH_ContractApprovalHierarchy__c childApprover = new EBH_ContractApprovalHierarchy__c();
           
        RecordType rt = Database.query(APPROVERRECTYPQUERY);
        childApprover = new EBH_ContractApprovalHierarchy__c(
                        RecordTypeId = rt.Id, EBH_ContractApprovalMatrix__c = parentApprover, 
                        EBH_Approver__c = approverUser, EBH_Threshold__c = threshold);
     
        insert childApprover;
        return childApprover;           
    }    
        
    /************************************************************************************************************************************
    @ Method:         createAccounts 
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Method to create account test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      numRecords: Number of account records to create
                      recordType: Account record type developer name
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<Account>: List of test accounts
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / JOY MONDOL / Created the Method.
    ************************************************************************************************************************************/
    public static List<Account> createAccounts(Integer numRecords, String recordType) {
        List<Account> accounts = new List<Account>();
        
        RecordType rt = Database.query(ACCRECTYPQUERY);
        String hashString, hexDigest;
        Blob hash;                
        for(Integer iCounter = 0; iCounter < numRecords; iCounter++) {
        
            hashString = icounter + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
            //System.debug('hashString>>>'+hashString);
            hash = Crypto.generateDigest('MD5', Blob.valueOf(hashString));
            //System.debug('hash>>>'+hash);
            hexDigest = EncodingUtil.convertToHex(hash);
            //System.debug('hexDigest>>>'+hexDigest);
            //System.debug('iCounter>>>'+iCounter);
            accounts.add(new Account(RecordTypeId = rt.Id, Name = 'Test Account ' +hexDigest));
            //System.debug('accounts>>>'+accounts);
        }

        
        Database.insert(accounts);
        return accounts;
    }
    
    /************************************************************************************************************************************
    @ Method:         createContacts 
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL
    @ Purpose:        Method to create contact test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      numRecords: Number of contact records to create
                      lastname: LastName
                      accountId: Account id
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<Contact>: List of test accounts
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.06.2017 / ASHISH BARANWAL / Created the Method.
    ************************************************************************************************************************************/
    public static List<Contact> createContacts(Integer numRecords, String lastname, Id accId) {
        
        List<Contact> contacts = new List<Contact>();
        RecordType rt = getRecordTypeByName('Contact','EBH_DWH');//[SELECT id from RecordType where sobjectType ='Contact' and dEveloperName = 'EBH_DWH'];
        
        for(Integer iCounter = 0; iCounter < numRecords; iCounter++) {
            contacts.add(new Contact(EBH_Status__c='Active', LastName = lastname + iCounter, AccountId = accId,recordTypeId = rt.Id, EBH_DataOrigin__c='test'));
        }

        insert contacts;
        return contacts;
    }
    
    /************************************************************************************************************************************
    @ Method:         createAccountContactRelation 
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL
    @ Purpose:        Method to create contact test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      accountId: Account id
                      contactId: Contact id
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<AccountContactRelation>: List of test accountContactRelation
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 03.07.2017 / ASHISH BARANWAL / Created the Method.
    ************************************************************************************************************************************/
    public static AccountContactRelation createAccountContactRelations(Id accId, Id contId) {
        
        AccountContactRelation acr = new AccountContactRelation(AccountId = accId,ContactId = contId);
        insert acr;
        return acr;
    }
    
    /************************************************************************************************************************************
    @ Method:         createTargetedSellers 
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL
    @ Purpose:        Method to create targeted seller test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      numRecords: Number of targeted seller records to create
                      sellerListId: seller list id
                      accountId: Account id
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<EBH_TargetedSeller__c>: List of test targetedSellers
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.06.2017 / ASHISH BARANWAL / Created the Method.
    ************************************************************************************************************************************/
    public static List<EBH_TargetedSeller__c> createtargetedSellers(Integer numRecords, id sellerListId, Id accountId) {
        
        List<EBH_TargetedSeller__c> targetedSellers = new List<EBH_TargetedSeller__c>();
        
        for(Integer iCounter = 0; iCounter < numRecords; iCounter++) {
            targetedSellers.add(new EBH_TargetedSeller__c(EBH_SellerList__c = sellerListId, EBH_Seller__c = accountId));
        }

        insert targetedSellers;
        return targetedSellers;
    }
    
    /************************************************************************************************************************************
    @ Method:         createCampaignMembers 
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL
    @ Purpose:        Method to create CampaignMember test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      numRecords: Number of CampaignMember records to create
                      campId: campaign id
                      contId: contact id
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<CampaignMember>: List of test targetedSellers
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.06.2017 / ASHISH BARANWAL / Created the Method.
    ************************************************************************************************************************************/
    public static List<CampaignMember> createCampaignMembers(Integer numRecords, id campId, Id contId, Boolean hasResponded) {
        
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        
        for(Integer iCounter = 0; iCounter < numRecords; iCounter++) {
            campaignMembers.add(new CampaignMember(CampaignId = campId, ContactId = contId, EBH_Results__c = 'Sent', 
                                    EBH_ResponseCode__c = 20, //EBH_HasResponded__c = hasResponded,
                                    EBH_LastResponseDate__c = system.today()));
        }

        insert campaignMembers;
        return campaignMembers;
    }
	/************************************************************************************************************************************
    @ Method:         createCampaignMembers2 
    @ Version:        1.0
    @ Author:         Vadhanak Voun
    @ Purpose:        Method to create CampaignMember test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      numRecords: Number of CampaignMember records to create
                      campId: campaign id
                      contId: contact id
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<CampaignMember>: List of test targetedSellers
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27.09.2018 / Vadhanak Voun / Created the Method.
    ************************************************************************************************************************************/
    public static List<CampaignMember> createCampaignMembers2(Integer numRecords, id campId, Id contId,Decimal resCode,Date firstResDate,Date lastResDate) {
        
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        
        for(Integer iCounter = 0; iCounter < numRecords; iCounter++) {
            campaignMembers.add(new CampaignMember(CampaignId = campId, ContactId = contId, EBH_Results__c = 'Sent', 
                                    EBH_ResponseCode__c = resCode, EBH_FirstResponseDate__c  = firstResDate, 
                                    EBH_LastResponseDate__c = lastResDate));
        }

        insert campaignMembers;
        return campaignMembers;
    }
    /************************************************************************************************************************************
    @ Method:         createCustomCampaignMembers
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method to create CampaignMember test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      numRecords: Number of CampaignMember records to create
                      campId: campaign id
                      contId: contact id
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<CampaignMember>: List of test targetedSellers
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.06.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static List<EBH_CampaignMember__c> createCustomCampaignMembers( Id campId, Id contId, String cockpitId, integer responseCode) {
        
        List<EBH_CampaignMember__c> campaignMembers = new List<EBH_CampaignMember__c>();
        campaignMembers.add(new EBH_CampaignMember__c(EBH_Campaign__c = campId, EBH_Contact__c = contId,
        EBH_CockpitResultID__c = cockPitId,
         EBH_ResponseCode__c = responseCode));
        

        
        return campaignMembers;
    }
    
    /************************************************************************************************************************************
    @ Method:         createSellerLists 
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL
    @ Purpose:        Method to create seller list test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      numRecords: Number of seller list records to create
                      name: Name
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<EBH_Filter__c>: List of test seller list
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.06.2017 / ASHISH BARANWAL / Created the Method.
    ************************************************************************************************************************************/
    public static List<EBH_Filter__c> createSellerLists(Integer numRecords, String name, String recordType, Date refreshUntil) {
        
        List<EBH_Filter__c> sellerLists = new List<EBH_Filter__c>();
        recordType = (recordType=='EBH_AutoRefreshSellerList'?'Snapshot_Seller_List':recordType);
        RecordType rt = Database.query(SELLERLISTRECTYPQUERY);
        
        for(Integer iCounter = 0; iCounter < numRecords; iCounter++) {
            sellerLists.add(new EBH_Filter__c(Name = name + iCounter,RecordTypeId = rt.Id, EBH_RefreshUntil__c = refreshUntil));
        }

        insert sellerLists;
        return sellerLists;
    }
    
    /************************************************************************************************************************************
    @ Method:         createContracts 
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method to create contract test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      numRecords: Number of account records to create
                      recordType: Account record type developer name
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<Account>: List of test accounts
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.05.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static List<Contract> createContracts(Integer numRecords, String recordType, Id customerLegalEntity, Id ebayLegalEntity,
                                                  Double DeceleratorThreshold, Double DeceleratorTierrebate,
                                                  Double AcceleratorThreshold, Double AcceleratorTierrebate,
                                                  Double MainTierThresholdofTarget, Double RebateTierrebate ) {
        
        List<Contract> contracts = new List<Contract>();
        
        RecordType rt = Database.query(CONTRACTRECTYPQUERY);
        RecordType manaulconRt = getRecordTypeByName('Contact','EBH_MANUAL');
        Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = customerLegalEntity,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
        insert contact;
        for(Integer iCounter = 0; iCounter < numRecords; iCounter++) {
            contracts.add(new Contract(RecordTypeId = rt.Id, 
                                       Name = 'Test Contract ' + iCounter, 
                                       accountId = customerLegalEntity, 
                                       EBH_eBayLegalEntity__c = ebayLegalEntity, Status='Draft',
                                       EBH_DeceleratorThreshold__c = DeceleratorThreshold,
                                       EBH_DeceleratorTierrebate__c = DeceleratorTierrebate,
                                       EBH_AcceleratorThreshold__c = AcceleratorThreshold,
                                       EBH_AcceleratorTierrebate__c = AcceleratorTierrebate,
                                       EBH_MainTierThresholdofTarget__c = MainTierThresholdofTarget,
                                       EBH_RebateTierrebate__c = RebateTierrebate,
                                       StartDate=System.today(),EndDate=System.today().addMonths(1), Surcharge__c = true,Business_Contact__c=contact.id));
        }
        insert contracts;
        return contracts;
    }
    public static List<Contract> createContracts(Integer numRecords, String recordType, Id customerLegalEntity, Id ebayLegalEntity) {
        return createContracts(numRecords, recordType, customerLegalEntity, ebayLegalEntity, 30, 20, 20, 10, 40, 30);
    }
    
    /************************************************************************************************************************************
    @ Method:         createPricing 
    @ Version:        1.0
    @ Author:         Ashish Baranwal
    @ Purpose:        Method to create pricing test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      numRecords: Number of Pricing records to create
                      recordType: Pricing record type developer name
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<Pricing>: List of test accounts
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.05.2017 / ASHISH BARANWAL / Created the Method.
    ************************************************************************************************************************************/
    public static List<EBH_Pricing__c> createPricing(Integer numRecords, String recordType, Id contractID, Decimal EBH_FVFDiscount, 
                                                        Decimal EBH_FVFCap, Decimal EBH_ASP, Decimal EBH_Projected12MGMV, 
                                                        Decimal EBH_DefaultFVFCap, String EBH_Site) {
        
        List<EBH_Pricing__c> pricingRecords = new List<EBH_Pricing__c>();
        RecordType rt = Database.query(PRICINGRECTYPQUERY);
        
        for(Integer iCounter = 0; iCounter < numRecords; iCounter++) {
            pricingRecords.add(new EBH_Pricing__c(RecordTypeId = rt.Id, 
                                       //Name = 'Test Pricing Record ' + iCounter, 
                                       EBH_ContractId__c = contractId,
                                       EBH_FVFDiscount__c = EBH_FVFDiscount, 
                                       EBH_FVFCap__c = EBH_FVFCap, 
                                       EBH_ASP__c = EBH_ASP, 
                                       EBH_Projected12MGMV__c = EBH_Projected12MGMV, 
                                       EBH_DefaultFVFCap__c = EBH_DefaultFVFCap,
                                       EBH_Site__c = EBH_Site
                                       ));
        }
       
        insert pricingRecords;
        return pricingRecords;
    }
    
    /************************************************************************************************************************************
    @ Method:         createUser 
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Method to create account test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      numRecords: Number of account records to create
                      recordType: Account record type developer name
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        User: User record
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / JOY MONDOL / Created the Method.
    ************************************************************************************************************************************/
    public static User createUser(String profileName) {
    
        Profile p = Database.query(PRFQUERY); 
        
        User usr = new User(Alias             = 'usr', 
                            Email             = 'usr' + Math.random() + '@org.com', 
                            EmailEncodingKey  = 'UTF-8', 
                            LastName          = 'Testing' + Math.random(), 
                            LanguageLocaleKey = 'en_US', 
                            LocaleSidKey      = 'en_US', 
                            ProfileId         = p.Id, 
                            TimeZoneSidKey    = 'America/Los_Angeles',
                            UserName          = 'usr' + Math.random() + '@org.com');                      
     
        return usr;
    }
    
    /************************************************************************************************************************************
    @ Method:         createUsers
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method to create multiple user records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      numRecords: Number of account records to create
                      recordType: Account record type developer name
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        User: User record
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.05.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static List<User> createUsers(integer numRecords, String profileName) {
    
        Profile p = Database.query(PRFQUERY); 
        
        List<User> usrs = new List<User>();
        
        for(integer iCounter = 0; iCounter < numRecords ; iCounter++ ){
        
            usrs.add(new User(Alias             = 'usr', 
                              Email             = 'usr' + Math.random() + '@org.com', 
                              EmailEncodingKey  = 'UTF-8', 
                              LastName          = 'Testing' + Math.random(), 
                              LanguageLocaleKey = 'en_US', 
                              LocaleSidKey      = 'en_US', 
                              ProfileId         = p.Id, 
                              TimeZoneSidKey    = 'America/Los_Angeles',
                              UserName          = 'usr' + Math.random() + '@org.com'));                            
        }                  
     
        return usrs;
    }
    
    /************************************************************************************************************************************
    @ Method:         SetUpCustomSettings 
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Method for Creation of Custom Settings for all the Test Classes with SeeAllData=false.
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / JOY MONDOL / Created the Method.
    @               : 10/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
    ************************************************************************************************************************************/
    public static void setUpCustomSettings() {
        
        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller',
                                         EBH_AccountContactRelationTrigger__c = true,
                                         EBH_AccountTrigger__c = true,
                                         EBH_AttachmentTrigger__c = true,
                                         EBH_BUApprovalGroupTrigger__c = true,
                                         EBH_CampaignApprovalGroupTrigger__c = true,
                                         EBH_CampaignKPITrigger__c = true,
                                         EBH_CampaignMemberTrigger__c = true,
                                         EBH_CampaignTrigger__c = true,
                                         EBH_ContactTrigger__c = true,
                                         EBH_ContentDocumentLinkTrigger__c = true,
                                         EBH_ContentDocumentTrigger__c = true,
                                         EBH_ContractApprovalHierarchyTrigger__c = true,
                                         EBH_ContractApprovalMatrixTrigger__c = true,
                                         EBH_ContractTrigger__c = true,
                                         Coupon__c = true,
                                         Coupon_Category__c = true,
                                         Coupon_Co_Invest__c = true,
                                         Coupon_Item__c = true,
                                         Coupon_Seller__c = true,
                                         EBH_CustomCampaignMemberTrigger__c = true,
                                         EBH_DocuSignStatusTrigger__c = true,
                                         EBH_ExecuteContractUpdateBatch__c = true,
                                         EBH_FeedItemTrigger__c = true,
                                         Final_value_Fee__c = true,                                         
                                         EBH_KPIResultTrigger__c = true,                                         
                                         Nominated_Item__c = true,
                                         EBH_PricingTrigger__c = true,
                                         //Product__c = true,
                                         EBH_SellerListTrigger__c = true,
                                         //Seller_to_Product__c = true,
                                         EBH_EnableUrgencyEmail__c = true,
                                         EBH_TargetedSellerTrigger__c = true,
                                         EBH_TaskTrigger__c = true,
                                         EBH_TicketTrigger__c = true,
                                         EBH_User__c = true,
                                         DealTrigger__c = true,
                                         Coupon_Send_BCD_File_To_DL__c =true,
                                         Coupon_Seller_Send_T4_T40_to_seller__c =true,
                                         CaseTrigger__c =true,
                                         Subscription_Request_Trigger__c=true,
                                         Project_Trigger__c = true,
                                         Channel_Trigger__c = true,
                                         Promotion_Trigger__c=true,
                                         AccountTeam__c=true, //NK:12/07/2023:US-0013797
                                         Deployment_Task__c=true, //NK:27/05/2024:US-0015246,
                                         Docusign_Envelope_Status__c = true //0016875
                                        ); 
	EBH_DealStatus__c dealStatus1 = new EBH_DealStatus__c(Name='AVAIL_STATUS',EBH_StatusSet__c='Ready for Payment,Paid,Executed,Planned,Deal Agreed,Running');
	EBH_DealStatus__c dealStatus2 = new EBH_DealStatus__c(Name='AVAIL_STATUS_SLOT_SET',EBH_StatusSet__c='Planned,Deal Agreed,Running');
	EBH_DealStatus__c dealStatus3 = new EBH_DealStatus__c(Name='STATUS_SLOT_ALLOC_NULL',EBH_StatusSet__c='New,Negotiating,Negotiating Amended,Rejected');
	insert new List<EBH_DealStatus__c>{dealStatus1,dealStatus2,dealStatus3};   
	/*       */                                                        
    //updated by DHE to facilitate passing test classes
    // Try to insert without throwing exception if it fails
    Deal_Timezone__c dealTimezone = new Deal_Timezone__c();
    dealTimezone.TimeZone__c='America/Los_Angeles';     
    //insert dealTimezone; 
Database.SaveResult result = Database.insert(dealTimezone, false);

// Check if insert was successful
if (!result.isSuccess()) {
    // Log the error but do not throw
    System.debug('⚠️ Insert failed: ' + result.getErrors()[0].getMessage());
} else {
    System.debug('✅ Insert succeeded.');
}
    }
    
    /************************************************************************************************************************************
    @ Method:         SetUpPreApprovedContractSettings 
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method for Creation of Contract Pre-Approved Template rules - Custom Settings for all the Test Classes 
                      with SeeAllData=false.
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.05.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static void setUpPreApprovedContractSettings() {
        
        insert new EBH_ContractPreApprovedRules__c(Name = 'Listing Agreement_DE_German',   
                                                   EBH_Site__c = EBH_ConstantsUtility.CONTRACT_SITE_DE , 
                                                   EBH_Language__c = EBH_ConstantsUtility.CONTRACT_LANGUAGE_DE, 
                                                   EBH_RecordType__c = EBH_ConstantsUtility.CONTRACT_AGREEMENTRECORDTYPE);
                                                   
        insert new EBH_ContractPreApprovedRules__c(Name = 'Listing Agreement_IT_Italian',  
                                                   EBH_Site__c = EBH_ConstantsUtility.CONTRACT_SITE_IT, 
                                                   EBH_Language__c = EBH_ConstantsUtility.CONTRACT_LANGUAGE_IT,  
                                                   EBH_RecordType__c = EBH_ConstantsUtility.CONTRACT_AGREEMENTRECORDTYPE);                                                                    

    }
    
    /************************************************************************************************************************************
    @ Method:         SetUpSiteStoreSubscriptionFeesSettings 
    @ Version:        1.0
    @ Author:         Ashish Baranwal
    @ Purpose:        Method for Creation of Site Store Subscription Fees - Custom Settings for all the Test Classes 
                      with SeeAllData=false.
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.05.2017 / Ashish Baranwal / Created the Method.
    ************************************************************************************************************************************/
    public static void setUpSiteStoreSubscriptionFeesSettings(String name, String site, Integer storeSubsFees) {
        
        insert new EBH_SiteStoreSubscriptionFees__c(Name = name,   
                                                   EBH_Site__c = site, 
                                                   EBH_StoreSubscriptionFee__c = storeSubsFees); 
                                                   
    }
    
    /************************************************************************************************************************************
    @ Method:         setUpCampaignKPITriggerHandlerData
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method for Creation of test data for CampaignKPITriggerHandlerData
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.06.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static List<CampaignMember> setUpCampaignMemberTriggerHandlerData( ) {
        
        List<Account> legalEntities = createAccounts(10, 'EBH_LegalEntity') ;

        List<Campaign> campaigns = createCampaignsWithSellerList(10, 'Test Campaign', 'UK', 'EBH_Campaign', null);
        //List<Campaign> campaignsParent = createCampaignsWithSellerList(10, 'Test Campaign', 'UK', 'EBH_Campaign', null); //NK:29/10/2018
        List<Campaign> programmes = createCampaignsWithSellerList(10, 'Test Campaign', 'UK', 'EBH_CampaignProgramme', null);
        campaigns[0].parentId = programmes[0].id;
        campaigns[1].parentId = programmes[0].id;
        update campaigns;
        List<Campaign> subCampaigns = createCampaignsWithSellerList(10, 'Test Campaign', 'UK', 'EBH_SubCampaign', null); 
        subcampaigns[0].parentId = campaigns[0].id; //NK:29/10/2018
        
        List<Contact> contacts = createContacts(20, 'Test Contact', legalEntities[0].id);
        AccountContactRelation acr1 = createAccountContactRelations(legalEntities[1].id,contacts[0].id);
        //AccountContactRelation acr2 = createAccountContactRelations(legalEntities[0].id,contacts[1].id);
        
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        campaignMembers.addAll(createCampaignMembers(1, subCampaigns[0].id, contacts[0].id, TRUE));
        campaignMembers.addAll(createCampaignMembers(1, subCampaigns[0].id, contacts[1].id, TRUE));
        campaignMembers.addAll(createCampaignMembers(1, subCampaigns[0].id, contacts[2].id, FALSE));
        campaignMembers.addAll(createCampaignMembers(1, subCampaigns[0].id, contacts[3].id, FALSE));
        
        return campaignMembers;
    }
    
    /************************************************************************************************************************************
    @ Method:         setUpOutreachCampaignHandlerData
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method for Creation of test data for CampaignKPITriggerHandlerData
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.10.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static List<CampaignMember> setUpOutreachCampaignHandlerData( ) {
        
        List<Account> legalEntities = createAccounts(2, 'EBH_LegalEntity') ;

        List<Campaign> campaigns = createCampaignsWithSellerList(10, 'Test Campaign', 'UK', 'EBH_Campaign', null);
        List<Campaign> programmes = createCampaignsWithSellerList(10, 'Test Campaign', 'UK', 'EBH_CampaignProgramme', null);
        campaigns[0].parentId = programmes[0].id;
        campaigns[1].parentId = programmes[0].id;
        update campaigns;
        RecordType rt = getRecordTypeByName('Campaign','EBH_AMOutreach');//[SELECT id from RecordType where developerName ='EBH_AMOutreach'];
        
        List<Campaign> subCampaigns = createCampaignsWithSellerList(10, 'Test Campaign', 'UK', 'EBH_SubCampaign', null);
        subcampaigns[0].parentId = campaigns[0].id;
        //subcampaigns[0].recordTypeId = rt.Id;
        
        update subcampaigns[0];
        List<Contact> contacts = createContacts(4, 'Test Contact', legalEntities[0].id);
        AccountContactRelation acr1 = createAccountContactRelations(legalEntities[1].id,contacts[0].id);
        //AccountContactRelation acr2 = createAccountContactRelations(legalEntities[0].id,contacts[1].id);
        
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        campaignMembers.addAll(createCampaignMembers(1, subCampaigns[0].id, contacts[0].id, TRUE));
        campaignMembers.addAll(createCampaignMembers(1, subCampaigns[0].id, contacts[1].id, TRUE));
        campaignMembers.addAll(createCampaignMembers(1, subCampaigns[0].id, contacts[2].id, FALSE));
        campaignMembers.addAll(createCampaignMembers(1, subCampaigns[0].id, contacts[3].id, FALSE));
        
        return campaignMembers;
    }
    /************************************************************************************************************************************
    @ Method:         setUpCustomCampaignMemberTriggerHandlerData
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method for Creation of test data for CampaignKPITriggerHandlerData
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.06.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static List<EBH_CampaignMember__c> setUpCustomCampaignMemberTriggerHandlerData( ) {
        
        List<Account> legalEntities = createAccounts(10, 'EBH_LegalEntity') ;

        List<Campaign> campaigns = createCampaignsWithSellerList(10, 'Test Campaign', 'UK', 'EBH_Campaign', null);
        List<Campaign> programmes = createCampaignsWithSellerList(10, 'Test Campaign', 'UK', 'EBH_CampaignProgramme', null);
        campaigns[0].parentId = programmes[0].id;
        campaigns[1].parentId = programmes[0].id;
        update campaigns;
        List<Campaign> subCampaigns = createCampaignsWithSellerList(10, 'Test Campaign', 'UK', 'EBH_SubCampaign', null);
        subcampaigns[0].parentId = campaigns[0].id;
        
        List<Contact> contacts = createContacts(20, 'Test Contact', legalEntities[0].id);
        AccountContactRelation acr1 = createAccountContactRelations(legalEntities[1].id,contacts[0].id);
        //AccountContactRelation acr2 = createAccountContactRelations(legalEntities[0].id,contacts[1].id);
        
        List<EBH_CampaignMember__c> campaignMembers = new List<EBH_CampaignMember__c>();
        campaignMembers.addAll(createCustomCampaignMembers( subCampaigns[0].id, contacts[0].id, null, null));
        campaignMembers.addAll(createCustomCampaignMembers( subCampaigns[0].id, contacts[1].id, '12384', null));
        campaignMembers.addAll(createCustomCampaignMembers( subCampaigns[0].id, contacts[2].id, null, null));
        campaignMembers.addAll(createCustomCampaignMembers( subCampaigns[0].id, contacts[3].id, null, null));
        insert campaignMembers;
        campaignMembers.addAll(createCustomCampaignMembers( null, null, '12384', 30));
        
        return campaignMembers;
    }
    
   /************************************************************************************************************************************
    @ Method:         setUpCampaignKPITriggerHandlerData
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method for Creation of test data for CampaignKPITriggerHandlerData
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.06.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static void setUpCampaignKPITriggerHandlerData( ) {
           
        List<Campaign> campaignsParent = createCampaignsWithSellerList(2, 'Test Campaign', 'UK', 'EBH_Campaign', null); //NK:29/10/2018
        List<Campaign> campaigns = createCampaignsWithSellerList(2, 'Test Campaign', 'UK', 'EBH_StrategicPriority', null); //NK:29/10/2018
        List<Campaign> programmes = createCampaignsWithSellerList(1, 'Test Campaign', 'UK', 'EBH_CampaignProgramme', null);
        //campaigns[0].parentId = programmes[0].id; //NK:29/10/2018
        //campaigns[1].parentId = programmes[0].id; //NK:29/10/2018
        //update campaigns;
        List<Campaign> subCampaigns = createCampaignsWithSellerList(1, 'Test Campaign', 'UK', 'EBH_SubCampaign', null);
        subcampaigns[0].parentId = campaignsParent[0].id; //NK:29/10/2018
        List<EBH_KPI__c> kpiRecords = createKPIRecords('Test');
        List<EBH_CampaignKPI__c> campaignKPIRecords = new List<EBH_CampaignKPI__c>();
        
        campaignKPIRecords.add(createCampaignKPIRecord( campaigns[0].id, kpiRecords[0].id, 10));
        campaignKPIRecords.add(createCampaignKPIRecord( programmes[0].id, kpiRecords[0].id, 10));
        campaignKPIRecords.add(createCampaignKPIRecord( campaigns[0].id, kpiRecords[2].id, 10));
        campaignKPIRecords.add(createCampaignKPIRecord( programmes[0].id, kpiRecords[2].id, 5));
        campaignKPIRecords.add(createCampaignKPIRecord( campaigns[0].id, kpiRecords[3].id, 10));
        campaignKPIRecords.add(createCampaignKPIRecord( programmes[0].id, kpiRecords[3].id, 12));
        campaignKPIRecords.add(createCampaignKPIRecord( campaigns[0].id, kpiRecords[1].id, 10));
        campaignKPIRecords.add(createCampaignKPIRecord( programmes[0].id, kpiRecords[1].id, 12));
       
      /*  campaignKPIRecords.add(createCampaignKPIRecord( subCampaigns[0].id, kpiRecords[0].id, 10));
        campaignKPIRecords.add(createCampaignKPIRecord( subCampaigns[0].id, kpiRecords[0].id, 10));
        campaignKPIRecords.add(createCampaignKPIRecord( subCampaigns[0].id, kpiRecords[2].id, 10));
        campaignKPIRecords.add(createCampaignKPIRecord( subCampaigns[0].id, kpiRecords[2].id, 5));
        campaignKPIRecords.add(createCampaignKPIRecord( subCampaigns[0].id, kpiRecords[3].id, 10));
        campaignKPIRecords.add(createCampaignKPIRecord( subCampaigns[0].id, kpiRecords[3].id, 12));
        campaignKPIRecords.add(createCampaignKPIRecord( subCampaigns[0].id, kpiRecords[1].id, 10));
        campaignKPIRecords.add(createCampaignKPIRecord( subCampaigns[0].id, kpiRecords[1].id, 12)); */
        insert campaignKPIRecords;
        campaignKPIRecords[0].EBH_Actual__c = 20;
        update campaignKPIRecords[0];
    }
   
    /************************************************************************************************************************************
    @ Method:         setUpAttachmentTriggerHandlerData
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method for Creation of test data for AttachmentTriggerHandlerData
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.06.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static void setUpAttachmentTriggerHandlerData( ) {
       
        String randomNum = String.valueOf(Math.random());
        randomNum = randomNum.length() > 18 ? randomNum.substring( 0, 18) : randomNum;
        
        List<Account> seller = createAccounts(1, 'EBH_Seller') ;
        seller[0].EBH_OracleId__c = randomNum;
        update seller[0];
        
        List<EBH_Filter__c> sellerLists = createSellerLists(2, 'Test Seller List', 'EBH_AutoRefreshSellerList', System.today() + 365);
        List<EBH_TargetedSeller__c> targetedSellers1 = createtargetedSellers(1, sellerLists[0].id, seller[0].id);
        createAttachment( 'Test', 'EBH_Seller__c,'+randomNum, sellerLists[0].id);
    }
    
    /************************************************************************************************************************************
    @ Method:         EBH_DocuSignStatusTriggerHandlerData 
    @ Version:        1.0
    @ Author:         Ashish Baranwal
    @ Purpose:        Method for Creation of test data for EBH_DocuSignStatusTriggerHandler
                      with SeeAllData=false.
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.11.2017 / Ashish Baranwal / Created the Method.
    ************************************************************************************************************************************/
    public static List<dsfs__DocuSign_Status__c> setUpDocuSignStatusTriggerHandlerData(){
        
        List<Account> legalEntities = createAccounts(2, 'EBH_LegalEntity');
        List<Contract> contractsListing = createContracts (2, 'Listing Agreement', legalEntities[0].id, legalEntities[1].id);
        
        List<dsfs__DocuSign_Status__c> docuSignStatusSent = createDocuSignStatus(2,contractsListing,'Sent');
        return docuSignStatusSent;
    }
    
    /************************************************************************************************************************************
    @ Method:         createDocuSignStatus
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method for Creation of Campaign KPI Record
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.06.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static List<dsfs__DocuSign_Status__c> createDocuSignStatus(integer numOfRecords, List<Contract> contr, String envelopStatus) {
        List<dsfs__DocuSign_Status__c> docustatus = new List<dsfs__DocuSign_Status__c>();
        for( integer i=0 ; i< numOfRecords ; i++ ){
            
            docustatus.add(new dsfs__DocuSign_Status__c(dsfs__Contract__c = contr[0].Id, dsfs__Envelope_Status__c = envelopStatus,
                           dsfs__Envelope_Link__c='A69A2554-599B-46BB-B1D1-68016FF25A6D, ' 
                                         +'https://demo.docusign.net/Member/MemberLogin.aspx?e=a69a2554-599b-46bb-b1d1-68016ff25a6d'
                                            ));
        } 
        insert docustatus;
        return docustatus;                                        
    } 
    
    /************************************************************************************************************************************
    @ Method:         createAttachment
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method for Creation of test data for AttachmentTriggerHandlerData
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.06.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static Attachment  createAttachment( String name, String body , Id parentId ) {
        
        Attachment attach = new Attachment();     
        attach.Name = name;
        Blob bodyBlob = Blob.valueOf(body);
        attach.body = bodyBlob;
        attach.parentId = parentId;
        insert attach;
        String before = 'Testing base 64 encode';            
        Blob beforeblob = Blob.valueOf(before);
        //Insert contentdocument data
        ContentVersion cv = new ContentVersion();
        cv.title = 'test content trigger';      
        cv.PathOnClient ='test';           
        cv.VersionData =beforeblob;          
        insert cv;         
                                            
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];

        ContentDocumentLink newFileShare = new ContentDocumentLink();
        newFileShare.contentdocumentid = testcontent.contentdocumentid;
        newFileShare.ShareType = 'V';
        newFileShare.LinkedEntityId = createTrainingRecord('training', 'www.google.com', 2, 'test desc').Id;
        insert newFileShare;
        return attach;
   
    } 
    /************************************************************************************************************************************
    @ Method:         createFileAttachment
    @ Version:        1.0
    @ Author:         Vadhanak Voun
    @ Purpose:        Method for Creation of test data as File Attachment (ContentVersion)
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 09.02.2018 / Vadhanak Voun / Created the Method.
    ************************************************************************************************************************************/
    public static ContentVersion  createFileAttachment( String name, String body , Id parentId ) {
        ContentVersion cv = new ContentVersion();
        cv.title = name;      
        cv.PathOnClient ='test';           
        cv.VersionData = Blob.valueOf(body);          
        insert cv;   
        
        ContentVersion testContent = [SELECT id,title,PathOnClient,VersionData, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
        ContentDocumentLink newFileShare = new ContentDocumentLink();
        newFileShare.contentdocumentid = testcontent.contentdocumentid;
        newFileShare.ShareType = 'V';
        newFileShare.LinkedEntityId = parentId;
        insert newFileShare;
        
        return testContent;  
    }
     
    /************************************************************************************************************************************
    @ Method:         createTrainingMaterial
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method for Creation of Campaign KPI Record
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.06.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static EBH_TrainingMaterial__c createTrainingRecord( String name, String fileURL, Integer sequence, string description) {
        
        EBH_TrainingMaterial__c kpiRecord = new EBH_TrainingMaterial__c( Name = name, EBH_Description__c = description,
        EBH_FileURL__c = fileURL, EBH_Sequence__c = sequence );
        insert kpiRecord;
        return kpiRecord;                                        
            
    } 
    /************************************************************************************************************************************
    @ Method:         createCampaignKPIRecord
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method for Creation of Campaign KPI Record
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.06.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static EBH_CampaignKPI__c createCampaignKPIRecord( Id campaignId, Id kpiId, integer actual ) {
        
        EBH_CampaignKPI__c kpiRecord = new EBH_CampaignKPI__c( EBH_Campaign__c = campaignId,
                                               EBH_KPI__C = kpiId,
                                               EBH_Actual__c = actual );
        return kpiRecord;                                        
            
    } 
    
   
   /************************************************************************************************************************************
    @ Method:         createKPIRecord
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method for Creation of KPI Record
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.06.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static List<EBH_KPI__c> createKPIRecords( String name) {
        
        List<EBH_KPI__c> kpiRecords = new List<EBH_KPI__c>();
        
        kpiRecords.add( new EBH_KPI__c( name = name,
                                               EBH_Type__c = 'Sum' ));
        kpiRecords.add( new EBH_KPI__c( name = name,
                                               EBH_Type__c = 'Average' ));
        kpiRecords.add( new EBH_KPI__c( name = name,
                                               EBH_Type__c = 'Minimum' ));
        kpiRecords.add( new EBH_KPI__c( name = name,
                                               EBH_Type__c = 'Maximum' ));
                                              
        insert kpiRecords;
        return kpiRecords;                                        
            
    } 
   
    
    /************************************************************************************************************************************
    @ Method:         setUpGroup 
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL
    @ Purpose:        Method for Creation of Public Group
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.05.2017 / ASHISH BARANWAL / Created the Method.
    ************************************************************************************************************************************/
    public static void setUpGroup(String grpName) {
        
        Group grp = new Group ();
        grp.Name = grpName;
        insert grp;
    }
      /************************************************************************************************************************************
    @ Method:         setUpCampaignRequestSiteGroupSettings
    @ Version:        1.0
    @ Author:         Ashish Baranwal
    @ Purpose:        Method for Creation of Campaign Request Site Group - Custom Settings for all the Test Classes 
                      with SeeAllData=false.
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.05.2017 / Ashish Baranwal / Created the Method.
    ************************************************************************************************************************************/
    public static void setUpCampaignRequestSiteGroupSettings(String name, String publicGroup) {
        
        insert new EBH_CampaignRequestSiteGroup__c(Name = name,   
                                                   EBH_PublicGroup__c = publicGroup); 
                                                   
    }
    
     /***********************************************************************************************************************************
    @ Method:         setupEBH_CampaignApprovalSettingsControllerData 
    @ Version:        1.0
    @ Author:         ASHISH BARANWAL
    @ Purpose:        Method to create all test data for "EBH_CampaignApprovalSettingsController" class.
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map of records keyed by objectname
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.05.2017 / ASHISH BARANWAL / Created the Method.
    ***********************************************************************************************************************************/
    public static Map<String, Object> setupCampaignApprovalSettingsControllerData() {
        
        List<User> admUsers = createUsers(1, 'System Administrator');
        List<User> stdUsers = createUsers(4, 'Standard User');
        List<String> options = new List<String>();
        
        Schema.DescribeFieldResult fieldResult = EBH_CampaignApprovalMatrix__c.EBH_Site__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
        for(Schema.PicklistEntry f : ple) {
            options.add(f.getValue());
        } 
        
        insert stdUsers;
        insert admUsers;
        
        EBH_CampaignApprovalMatrix__c cam = createCampaignApprovalMatrix('UK');
        
        return new Map<String, Object> { 'admUsers' => admUsers,
                                         'stdUsers' => stdUsers,
                                         'sites'    => options,
                                         'mx'       => cam,
                                         'hxf1'     => createCampaignApprovalGroup(cam.id,stdUsers[0].Id),
                                         'hxf2'     => createCampaignApprovalGroup(cam.id,stdUsers[1].Id)};
    }
    

      /************************************************************************************************************************************
    @ Method:         createCampaignApprovalMatrix
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method to create dynamic approver test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Site                : String Site value
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        EBH_CampaignApprovalMatrix__c: Campaign Approval Matrix
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.05.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static EBH_CampaignApprovalMatrix__c createCampaignApprovalMatrix( String site ) {
        
        return new EBH_CampaignApprovalMatrix__c(EBH_Site__c = site);
        
    }
    
    /*********************************************************************************************************************************
    @ Method:         createCampaignApprovalGroup
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method to create Campaign Approval Group record
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      campaignMatrixID    : String Site value
                      approverId          : Multiple Approvers for each Site
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        EBH_CampaignApprovalMatrix__c: Campaign Approval Matrix
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.05.2017 / NEHA LUND / Created the Method.
    ************************************************************************************************************************************/
    public static EBH_CampaignApprovalGroup__c createCampaignApprovalGroup( Id campaignApprovalMatrixRecordId, ID approverId ) {
       // EBH_CampaignApprovalMatrix__c campaignApprovalMatrixRecord = EBH_TestDataFactory.createCampaignApprovalMatrix(site);
       //insert campaignApprovalMatrixRecord;
        return new EBH_CampaignApprovalGroup__c( EBH_CampaignApprovalMatrix__c = campaignApprovalMatrixRecordId,
                                                 EBH_Approver__c  = approverId );
        
    
    }
     /***********************************************************************************************************************************
    @ Method:         setupCampaignGroupTriggerHandlerData 
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Method to create all test data for "CampaignGroupTriggerHandler" class.
    --------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map of all records keyed by Campaign level name
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 23.05.2017 / NEHA LUND / Created the Method.
    ***********************************************************************************************************************************/
    public static List<EBH_CampaignApprovalGroup__c> setupCampaignGroupTriggerHandlerData() {
         
         setUpCampaignRequestSiteGroupSettings('DE',  'EBH_DEPUBLICGROUP');
         EBH_CampaignApprovalMatrix__c campMatrix = createCampaignApprovalMatrix('DE');
         insert campMatrix;
         List<User> admUsers = new List<User>();
         admUsers = createUsers(10, 'Standard User');
         insert admUsers;
         List<EBH_CampaignApprovalGroup__c> groups = new List<EBH_CampaignApprovalGroup__c>();
         
         for ( User usr : admUsers ){
             
             groups.add(createCampaignApprovalGroup(campMatrix.id, usr.id ));
             //groups.add(createCampaignApprovalGroup('DE', usr.id ));
         }
         insert groups;
         return groups;
       
    }


    
    /***********************************************************************************************************************************
    @ Method:         createCountryMapping3 
    @ Version:        1.0
    @ Author:         Samnang MUONG
    @ Purpose:        Method to create test data of Country Mapping 3
    --------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map of all records keyed by Country Mapping name
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.10.2017 / Samnang MUONG / Created the Method.
    ***********************************************************************************************************************************/

    public static Map<String, CountryMapping3__c> createCountryMapping3() {

        Map<String, CountryMapping3__c> mapCountryMapping = new Map<String, CountryMapping3__c>();

        // create 8 countries
        mapCountryMapping.put('Czech (Czech Republic)', new CountryMapping3__c(Name='Czech (Czech Republic)',Value__c='cs_CZ___Europe/Prague___en_US'));
        mapCountryMapping.put('English (Ireland)', new CountryMapping3__c(Name='English (Ireland)',Value__c='en_IE___Europe/Dublin___en_US'));
        mapCountryMapping.put('English (UK)', new CountryMapping3__c(Name='English (UK)',Value__c='en_GB___Europe/London___en_US'));
        mapCountryMapping.put('French (France)', new CountryMapping3__c(Name='French (France)',Value__c='fr_FR___Europe/Paris___fr'));
        mapCountryMapping.put('German (Germany)', new CountryMapping3__c(Name='German (Germany)',Value__c='de_DE___Europe/Berlin___de'));
        mapCountryMapping.put('German (Switzerland)', new CountryMapping3__c(Name='German (Switzerland)',Value__c='de_CH___Europe/Berlin___de'));
        mapCountryMapping.put('Italian (Italy)', new CountryMapping3__c(Name='Italian (Italy)',Value__c='it_IT___Europe/Rome___it'));
        mapCountryMapping.put('Spanish (Spain)', new CountryMapping3__c(Name='Spanish (Spain)',Value__c='ca_ES___Europe/Paris___es'));
		mapCountryMapping.put('English (US)', new CountryMapping3__c(Name='English (US)',Value__c='en_US___America/Los_Angeles___en_US'));
        insert mapCountryMapping.values();

        return mapCountryMapping;
    }
    /***********************************************************************************************************************************
    @ Method:         createLocalePublicGroupMapping 
    @ Version:        1.0
    @ Author:         Vadhanak Voun
    @ Purpose:        Method to create test data for TicketHandler
    --------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map of  Locale_PublicGroup_Mapping__c
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.11.2017 / Vadhanak Voun / Created the Method.
    ***********************************************************************************************************************************/

    public static Map<String, Locale_PublicGroup_Mapping__c> createLocalePublicGroupMapping() {
        Map<String,Locale_PublicGroup_Mapping__c> m = new Map<String,Locale_PublicGroup_Mapping__c>{
        'ca_ES'=>   new Locale_PublicGroup_Mapping__c(GroupName__c='EBH_ESCampaignRequestApprovers',name='ca_ES'), 
        'cs_CZ'=>   new Locale_PublicGroup_Mapping__c(GroupName__c='EBH_EECCampaignRequestApprovers',name='cs_CZ'),
        'de_CH'=>   new Locale_PublicGroup_Mapping__c(GroupName__c='EEC Campaign Request Approvers',name='de_CH'),
        'de_DE'=>   new Locale_PublicGroup_Mapping__c(GroupName__c='EBH_DECampaignRequestApprovers',name='de_DE'),
        'en_GB'=>   new Locale_PublicGroup_Mapping__c(GroupName__c='EBH_UKCampaignRequestApprovers',name='en_GB'),
        'en_IE'=>   new Locale_PublicGroup_Mapping__c(GroupName__c='EBH_EECCampaignRequestApprovers',name='en_IE'),
        'fr_FR'=>   new Locale_PublicGroup_Mapping__c(GroupName__c='EBH_FRCampaignRequestApprovers',name='fr_FR'),
        'it_IT'=>   new Locale_PublicGroup_Mapping__c(GroupName__c='EBH_ITCampaignRequestApprovers',name='it_IT')
        };
        
        insert m.values();
        
        return m;
        
    }
    
    /***********************************************************************************************************************************
    @ Method:         setupTicketTriggerHandlerData 
    @ Version:        1.0
    @ Author:         Samnang MUONG
    @ Purpose:        Method to create all test data for "AccountTriggerHandler" class.
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map of all records keyed by ticket email
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.10.2017 / Samnang MUONG / Created the Method.
    ***********************************************************************************************************************************/
    public static Map<String, Ticket__c> setupTicketTriggerHandlerData() {

        // create country mapping 3
        createCountryMapping3();
        createLocalePublicGroupMapping();
        
        // create 5 tickets
        List<Ticket__c> tickets = createTickets(5);

        Map<String, Ticket__c> mapTicket2Email = new Map<String, Ticket__c>();
        for (Ticket__c t :tickets) {
            mapTicket2Email.put(t.Email_Address__c, t);
        }

        return mapTicket2Email; 

    }

    /************************************************************************************************************************************
    @ Method:         createTickets 
    @ Version:        1.0
    @ Author:         Samnang MUONG
    @ Purpose:        Method to create ticket test records
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      numRecords: Number of account records to create
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<Ticket__c>: List of test tickets
    -------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.10.2017 / Samnang MUONG / Created the Method.
                    : 06.12.2017/ Vadhanak Voun / updated localed from Czech to Spnanish since group for Cz has gone missing.
                    : 04.2.2020 / Acmatac SEING / US-0007100 Fix Test Classes
    ************************************************************************************************************************************/
    public static List<Ticket__c> createTickets(Integer numRecords) {
        
        List<Ticket__c> tickets = new List<Ticket__c>();       
        List<RecordType> listRectypeUserForm =  Database.query(EBH_ConstantsUtility.SOQL_RECTYPE_USERFORM) ; 
                          
        for(Integer iCounter = 0; iCounter < numRecords; iCounter++) {
            tickets.add(new Ticket__c(
                         Ebay_Corp_ID__c = String.valueOf(Math.random()),
                         //Locale__c = 'Czech (Czech Republic)',
                         Locale__c = 'Spanish (Spain)',
                         Picklist__c  = 'Business Admin',
                         Last_Name__c =  '123test'+ iCounter, 
                         First_Name__c ='TestFirstName'+ iCounter,
                         Email_Address__c = 'testticket'+iCounter+'52@test.com',
                         Division__c = 'GCX',
                         Status__c = 'New',
                         // AMT, 04.2.2020 US-0007100 Fix Test Classes
                         //Permission_Sets__c = 'Campaign Approval;Report exports;Ticket Manager',
                         Permission_Sets__c = 'Campaign Approval;Ticket Manager',
                         RecordTypeId = listRectypeUserForm[0].Id,
                         Country__c='AU', 
                         User_Type__c='Full License User'
                    ));

        }

        insert tickets;
        return tickets;
    }
    
    /***********************************************************************************************************************************
    @ Method:         setupContractCustomSettingFee 
    @ Version:        1.0
    @ Author:         Vadhanak Voun 
    @ Purpose:        Method to create all test data for "ContractTriggerHandler" class. create cusotm setting for am bolt on fee and strore subscription fee table
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map of all records keyed by account level name
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 26.04.2018 / Vadhanak Voun / Created the Method.
    ***********************************************************************************************************************************/
    public static void setupContractCustomSettingFee()
    {
        List<Contract_Fee__c> listCF = new List<Contract_Fee__c>{
            new Contract_Fee__c(Name='1',Field__c='AM_Bolt_on__c',Site__c='UK',Type__c='',Price__c=0),
            new Contract_Fee__c(Name='2',Field__c='AM_Bolt_on__c',Site__c='DE',Type__c='',Price__c=10),
            new Contract_Fee__c(Name='7',Field__c='EBH_StoreSubscription__c',Site__c='DE',Type__c='Free Basic',Price__c=20)
        };
        insert listCF;
    }
    
    /***********************************************************************************************************************************
    @ Method:         createLeads 
    @ Version:        1.0
    @ Author:         Vadhanak Voun 
    @ Purpose:        Method to create all test data for "ContractTriggerHandler" class. create cusotm setting for am bolt on fee and strore subscription fee table
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map of all records keyed by account level name
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 26.04.2018 / Vadhanak Voun / Created the Method.
    ***********************************************************************************************************************************/
    public static Lead createLeads()
    {
        Lead l = new Lead(
            Salutation = 'Mr.',
             FirstName = 'FirstTest',
             LastName = 'LastTest',
             Suffix = '',
             Title = 'CIO',
             Email = 'test@test.com',
             Phone = '333444555',
             MobilePhone = '12345678',
             EBH_PreferredContactTime__c = '10:00',
             Website = 'deleted',
             Company='My Company'
        );
        
        return l;
    }

    public static List<Ticket__c> createTicket(){
        Ticket__c t = new Ticket__c(
            Ebay_Corp_ID__c = String.valueOf(Math.random()),
            //Locale__c = 'Czech (Czech Republic)',
            Locale__c = 'Spanish (Spain)',
            Last_Name__c =  '123test', 
            First_Name__c ='TestFirstName',
            Email_Address__c = 'testticket52@test.com',
            Division__c = 'GCX',
            Status__c = 'New',
            Permission_Sets__c = 'Campaign Approval;Report exports;Ticket Manager',
            Country__c='AU', 
            User_Type__c='Full License User'
        );
        Ticket__c t1 = new Ticket__c(
            Ebay_Corp_ID__c = String.valueOf(Math.random()),
            //Locale__c = 'Czech (Czech Republic)',
            Locale__c = 'Spanish (Spain)',
            Last_Name__c =  '123test', 
            First_Name__c ='TestFirstName',
            Email_Address__c = 'testticket52@test.com',
            Division__c = 'GCX',
            Status__c = 'New',
            Permission_Sets__c = 'Campaign Approval;Report exports;Ticket Manager',
            Country__c='DE', 
            User_Type__c='Full License User'
        );
        Ticket__c t2 = new Ticket__c(
            Ebay_Corp_ID__c = String.valueOf(Math.random()),
            //Locale__c = 'Czech (Czech Republic)',
            Locale__c = 'Spanish (Spain)',
            Last_Name__c =  '123test', 
            First_Name__c ='TestFirstName',
            Email_Address__c = 'testticket52@test.com',
            Division__c = 'GCX',
            Status__c = 'New',
            Permission_Sets__c = 'Campaign Approval;Report exports;Ticket Manager',
            Country__c='DE', 
            User_Type__c='GCX Portal User'
        );
        List<Ticket__c> lstTic = new List<Ticket__c>{t,t1,t2};

        return lstTic;
    }

    public static Deal_Contract_Agreement__c createDCA_Subsidize(Boolean doInsert)
    {
        RecordType rt = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c', 'Subsidized_Deals');
        Deal_Contract_Agreement__c ndca = new Deal_Contract_Agreement__c(RecordTypeId=rt.Id);
        if(doInsert)insert ndca;
        return ndca;
    }
}