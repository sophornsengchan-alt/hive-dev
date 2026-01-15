/*
* Test class for CertilogoGenerateInvoicesController
*/
@isTest
private class CertilogoGenerateInvoicesControllerTest {

    static void setupTestData() {

        //START-LA-18-07-2025-US-0032977//
        RecordType recordTypeCertilogo = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Certilogo' LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();
        Contact conTDD = new Contact(
                FirstName = 'Test TDD',
                LastName = 'Contact',
                Email =  'testcertilogo@test.com'
            );
        insert conTDD;

        RecordType rtAccountCertilogo = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Certilogo' LIMIT 1];
        Account accTDD = new Account(
                Name = 'Test Account TDD',
                Country_Code__c = 'US',
                Primary_Contact__c = conTDD.Id,
                RecordTypeId = rtAccountCertilogo.Id,
                Payment_Terms__c = 'NT30'
            );
        insert accTDD;
        //END-LA-18-07-2025-US-0032977//

        Opportunity testOpportunity1 = new Opportunity(
            Name = 'Test Opportunity1',
            StageName = 'Draft',
            CloseDate = Date.today().addDays(30), // Set a valid close date
            Amount = 10000.00,
            AccountId = accTDD.Id,//LA-18-07-2025-US-0032977
            RecordTypeId = recordTypeCertilogo.Id
        );
        Opportunity testOpportunity2 = new Opportunity(
            Name = 'Test Opportunity2',
            StageName = 'Draft',
            CloseDate = Date.today().addDays(30), // Set a valid close date
            Amount = 10000.00,
            AccountId = accTDD.Id,//LA-18-07-2025-US-0032977
            RecordTypeId = recordTypeCertilogo.Id
        );
        insert new List<Opportunity>{ testOpportunity1, testOpportunity2};

        //Create your product
        List<Product2> listprod = new List<Product2>();
        for(Integer i=0; i<10 ; i++){
            listprod.add(new Product2(
            BillingType__c ='SaaS',
            Family = 'SaaS',
            Name = 'Test Product'+i,
            isActive = true));
        }
        if(!listprod.isEmpty()){
            insert listprod;

            //Create your pricebook entry
            List<PricebookEntry> listpbe = new List<PricebookEntry>();
            for(Integer i=0; i<listprod.size() ; i++){
                listpbe.add(new PricebookEntry(
                    Pricebook2Id = pricebookId,
                    Product2Id = listprod[i].Id,
                    UnitPrice = 100.00,
                    IsActive = true
                ));
            }
            if(!listpbe.isEmpty()){
                insert listpbe;
                
                List<OpportunityLineItem> listoli = new List<OpportunityLineItem>();
                for(Integer i=0; i<listpbe.size(); i++){
                    if(i<5){
                        listoli.add(new OpportunityLineItem(
                            OpportunityId = testOpportunity1.Id,
                            Quantity = 5,
                            UnitPrice = 100,
                            Description = 'Test only',
                            Frequency__c = 'Yearly',
                            PricebookEntryId = listpbe[i].Id
                        ));

                    }else{
                        listoli.add(new OpportunityLineItem(
                            OpportunityId = testOpportunity2.Id,
                            Quantity = 10,
                            UnitPrice = 200,
                            Frequency__c = 'Quarterly',
                            Description = 'Test only',
                            PricebookEntryId = listpbe[i].Id
                        ));
                    }    
                }
                if(!listoli.isEmpty()){
                    insert listoli;
                }
            }

        }

    }
    @isTest
    private static void testGenerateBillInv() {
        // Set up test data
        setupTestData();
        //LA-18-07-2025-US-0032977- Add Opportunity.Account.Payment_Terms__c to query
        List<OpportunityLineItem> listoli = [SELECT Id,Opportunity.Account.Payment_Terms__c,LastBilledDate__c,InvoiceStatus__c,ReadytoInvoiceTimestamp__c FROM OpportunityLineItem];
        System.debug('listoli Payment_Terms__c: ' + listoli[0].Opportunity.Account.Payment_Terms__c);
        for(OpportunityLineItem oli : listoli){
            oli.InvoiceStatus__c = 'Ready for Invoice';
            oli.ReadytoInvoiceTimestamp__c = Date.Today();

        }
        update listoli;

        Test.startTest();
        
            CertilogoGenerateInvoicesController.generateBillInv();
            //LA-18-07-2025-US-0032977-Add new field Payment_Terms__c and RelatedBillingOpportunity__r.Account.Payment_Terms__c to query
            List<BillingInvoice__c> listBillInv = [SELECT Id,PaymentTerms__c,RelatedBillingOpportunity__r.Account.Payment_Terms__c FROM BillingInvoice__c];
            List<BillingInvoiceLine__c> listBillInvLine = [SELECT Id FROM BillingInvoiceLine__c];
            System.assert(listBillInv.size()==2,'There are 2 billing invoices that were auto generated');
            System.assert(listBillInvLine.size()==10,'There are 10 billing invoice lines that were auto generated');
            System.assertEquals('NT30',listBillInv[0].PaymentTerms__c);//LA-18-07-2025-US-0032977: populate related apportunity Account Payment_Terms__c 
        Test.stopTest();
    }
    @isTest
    private static void testGenerateFrequencyBillInv() {
        // Set up test data
        setupTestData();
        List<OpportunityLineItem> listoli = new List<OpportunityLineItem>();
        
        for(OpportunityLineItem oli : [SELECT Id,InvoiceStatus__c,ReadytoInvoiceTimestamp__c,Frequency__c,LastBilledDate__c,AutoRenewal__c FROM OpportunityLineItem]){
            oli.InvoiceStatus__c = 'Invoiced';
            oli.ReadytoInvoiceTimestamp__c = Date.Today();
            oli.Frequency__c = 'Yearly';
            oli.LastBilledDate__c = Date.Today().addYears(-1);
            oli.AutoRenewal__c = true;
            listoli.add(oli);

        }
        update listoli;

        Test.startTest();
            CertilogoGenerateInvoicesController.generateFrequencyBillInv();
            //LA-18-07-2025-US-0032977-Add new field Payment_Terms__c and RelatedBillingOpportunity__r.Account.Payment_Terms__c to query
            List<BillingInvoice__c> listBillInv = [SELECT Id,PaymentTerms__c,RelatedBillingOpportunity__r.Account.Payment_Terms__c FROM BillingInvoice__c];
            List<BillingInvoiceLine__c> listBillInvLine = [SELECT Id FROM BillingInvoiceLine__c];
            System.assert(listBillInv.size()==2,'There are 2 billing invoices that were auto generated');
            System.assert(listBillInvLine.size()==10,'There are 10 billing invoice lines that were auto generated');
            System.assertEquals('NT30',listBillInv[0].PaymentTerms__c);//LA-18-07-2025-US-0032977: populate related apportunity Account Payment_Terms__c 
        Test.stopTest();
    }



}