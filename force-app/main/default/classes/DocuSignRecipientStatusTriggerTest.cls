/*********************************************************************************************************************************
@ Class:          DocuSignRecipientStatusTriggerTest
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        Test class for DocuSignRecipientStatusTriggerHandler class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.07.2021 / Sophal Noch / Create Class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 04.12.2023 / Vimean Heng / Fixed Timezone Issues
*********************************************************************************************************************************/
@isTest(seeAllData = False)
private class DocuSignRecipientStatusTriggerTest {

    private static final String ACCRECTYPQUERY      = 'SELECT Id FROM RecordType '
                                                   + 'WHERE SObjectType = \'Account\' AND DeveloperName =: recordType LIMIT 1';

    private static final String CONTRACTRECTYPQUERY = 'SELECT Id FROM RecordType '
                                                   + 'WHERE SObjectType = \'Contract\' AND Name =: recordType LIMIT 1';
    
    /*****************************************************************************************************************************
    @ Method:         test_updateContractSellerContact
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        testMethod when recipients complete docuSign and then contract Contract_Signed_by__c & Seller_Signed_Date__c are populated
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  22.07.2021 / Sophal Noch / US-0009886 Create Method
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 04.12.2023 / Vimean Heng / US-0014428 run as (Deployment User) Fixed Timezone Issues 
    *****************************************************************************************************************************/
    static testMethod void test_updateContractSellerContact() {
        //US-0014428
        User dev = [SELECT Id FROM User WHERE Name = 'Deployment User'];
        System.runAs(dev) {
            byPass__c bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'DocuSign Status', byPass_Trigger__c = false, byPass_WFRule__c = false, ByPass_Validation__c = true);
            insert bp;

            EBH_TestDataFactory.setUpCustomSettings();     
            
            List<Account> legalEntities = createAccounts(2, 'EBH_LegalEntity');
            List<Contract> contractsListing = createContracts (1, 'Listing Agreement', legalEntities[0].id, legalEntities[1].id);
            
            for (Contract con : contractsListing) {
                con.PricingVersion__c = 'P1.0';
            }

            update contractsListing;

            EBH_ContractPricingMatrix__c contractPricingMatrix = EBH_TestDataFactory.createContractPricingMatrix('UK');
            Id pricingRecordTypeId = ApexUtil.getRecordTypeByName('EBH_Pricing__c','EBH_ListingPricing').Id;
            EBH_Pricing__c pricing1 = new EBH_Pricing__c(EBH_ContractId__c=contractsListing[0].Id,
                EBH_Site__c='UK',
                EBH_ContractPricingMatrix__c = contractPricingMatrix.Id,
                EBH_Projected12MGMV__c = 11,
                EBH_ASP__c =11,
                RecordTypeId = pricingRecordTypeId
            );
            insert pricing1;

            Id contRtId = [SELECT id from recordType where sobjectType ='Contact' and developerName ='EBH_MANUAL'].Id;
        
            Contact cont1 = new Contact();
            cont1.LastName = 'NSP_Contact_1';
            cont1.AccountId = legalEntities[0].Id;
            cont1.Email ='test1@ebay.com';
            cont1.RecordTypeId = contRtId;
            
            Contact cont2 = new Contact();
            cont2.LastName = 'NSP_Contact_2';
            cont2.AccountId = legalEntities[0].Id;
            cont2.Email ='test2@ebay.com';
            cont2.RecordTypeId = contRtId;

            insert new List<Contact>{cont1,cont2};

            contractsListing[0].List_Control_Values__c = '5'; // 22.07.2021 / Sophal Noch / US-0009886 status skip validation
            contractsListing[0].EBH_FinanceAgreesinPrincipal__c = true; // 22.07.2021 / Sophal Noch / US-0009886 status skip validation
            contractsListing[0].Status = 'Ready for eBay Signature';
            contractsListing[0].Business_Contact__c = cont2.Id;

            update contractsListing;
        
            dsfs__DocuSign_Status__c docuSign = new dsfs__DocuSign_Status__c();
        
            docuSign = new dsfs__DocuSign_Status__c(dsfs__Contract__c = contractsListing[0].Id, dsfs__Envelope_Status__c = 'Sent',
                            dsfs__Completed_Date_Time__c = Date.today(),
                            dsfs__Envelope_Link__c='A69A2554-599B-46BB-B1D1-68016FF25A6D, ' 
                                            +'https://demo.docusign.net/Member/MemberLogin.aspx?e=a69a2554-599b-46bb-b1d1-68016ff25a6d'
                                            );
            insert docuSign;
        
            dsfs__DocuSign_Recipient_Status__c dsdrs1 = new dsfs__DocuSign_Recipient_Status__c(
                dsfs__DocuSign_Recipient_Email__c = cont1.Email,
                dsfs__Date_Signed__c = null,
                dsfs__Parent_Status_Record__c = docuSign.Id,
                dsfs__DocuSign_Recipient_Id__c = 'test_recipient_id_1',
                dsfs__DocuSign_Routing_Order__c = 1
            
            );
        
            dsfs__DocuSign_Recipient_Status__c dsdrs2 = new dsfs__DocuSign_Recipient_Status__c(
                dsfs__DocuSign_Recipient_Email__c = cont2.Email,
                dsfs__Date_Signed__c = null,
                dsfs__Parent_Status_Record__c = docuSign.Id,
                dsfs__DocuSign_Recipient_Id__c = 'test_recipient_id_2',
                dsfs__DocuSign_Routing_Order__c = 2
            );
        
            insert new List<dsfs__DocuSign_Recipient_Status__c> {dsdrs1,dsdrs2}; // 22.07.2021 / Sophal Noch / US-0009886 insert 2 recipients for docusign, latest recipient is depended on dsfs__DocuSign_Routing_Order__c
        
            Test.startTest();
            
                docuSign.dsfs__Envelope_Status__c = 'Completed';
                update docuSign;

                dsdrs1.dsfs__Date_Signed__c = Date.today().addDays(-5);
                dsdrs2.dsfs__Date_Signed__c = Date.today();

                update new List<dsfs__DocuSign_Recipient_Status__c> {dsdrs1,dsdrs2};
        
                Contract contrct = [Select Id,Contract_Signed_by__c,Seller_Signed_Date__c, EBH_EnvelopLink__c From Contract Where Id =:docuSign.dsfs__Contract__c];
                System.assertNotEquals(null, contrct.Contract_Signed_by__c);
                System.assertEquals(cont2.Id, contrct.Contract_Signed_by__c); // 22.07.2021 / Sophal Noch / US-0009886 compare latest recipient field with contract field
                System.assertNotEquals(null, contrct.Seller_Signed_Date__c);
                System.assertEquals(dsdrs2.dsfs__Date_Signed__c, contrct.Seller_Signed_Date__c);
                
            Test.stopTest();
        }
        
    }
    
    private  static List<Account> createAccounts(Integer numRecords, String recordType) {
        // 22.07.2021 / Sophal Noch / US-0009886 copy from EBH_TestDataFactory.createAccounts
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
    
    private static List<Contract> createContracts(Integer numRecords, String recordType, Id customerLegalEntity, Id ebayLegalEntity) {
        // 22.07.2021 / Sophal Noch / US-0009886 copy from EBH_TestDataFactory.createContracts
        List<Contract> contracts = new List<Contract>();
        
        RecordType rt = Database.query(CONTRACTRECTYPQUERY);
                          
        for(Integer iCounter = 0; iCounter < numRecords; iCounter++) {
            contracts.add(new Contract(RecordTypeId = rt.Id, 
                                       Name = 'Test Contract ' + iCounter, 
                                       accountId = customerLegalEntity, 
                                       EBH_eBayLegalEntity__c = ebayLegalEntity, Status='Draft'
                                       ,StartDate=System.today(),EndDate=System.today().addMonths(1), Surcharge__c = true));
        }
        insert contracts;
        return contracts;
    }
}