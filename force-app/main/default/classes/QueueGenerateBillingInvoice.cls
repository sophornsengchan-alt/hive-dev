/*********************************************************************************************************************************
@ Class:          QueueGenerateBillingInvoice
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        24.04.2024 / Sophal Noch / US-0014879 - 2.1 SAP for ADS - Billing Invoice record creation (monthly)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  24.04.2024 / Sophal Noch / Created the class.
@               :  15.10.2024 / Vimean Heng / US-0015475 - SAP for ADS - Invoice fields and automations
*********************************************************************************************************************************/
public inherited sharing class QueueGenerateBillingInvoice implements Queueable{

    private String CLASS_NAME = 'QueueGenerateBillingInvoice';

    private Set<Id> setOppId;
    private String closeWon = 'Closed Won';
    private final Set<String> SET_RTYPE = new Set<String>{'eBay', 'eBay_Ads_Promoted_Listings'};
    private final String SOQL_OPP = 'Select Id, StageName, Payment_Terms__c, Amount, AccountId, Agency__c, Bill_To_Party__c from Opportunity Where Id IN: setOppId and RecordType.DeveloperName IN: setRType and StageName = :stageName';


    /*********************************************************************************************************************************
    @ Method:         QueueGenerateBillingInvoice
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        24.04.2024 / Sophal Noch / US-0014879 - 2.1 SAP for ADS - Billing Invoice record creation (monthly)
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Set<Id> setOppId : Ids of Opportunities
    -----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.04.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    public QueueGenerateBillingInvoice(Set<Id> setOppId) { // use in class OpportunityTriggerHandler
        this.setOppId = setOppId;
    }

    /*********************************************************************************************************************************
    @ Method:         QueueGenerateBillingInvoice
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        24.04.2024 / Sophal Noch / US-0014879 - 2.1 SAP for ADS - Billing Invoice record creation (monthly)
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Map<Id,Ad_Product__c>> listMapAdprod : List of Map Id To Sobject Ad_Product__c
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  24.04.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    public QueueGenerateBillingInvoice(List<Map<Id,Ad_Product__c>> listMapAdprod){ // use in class AdProductTriggerHandler, QueueGenerateRevenue
        Set<Id> setOppId = new Set<Id>();
        for(Map<Id,Ad_Product__c> mapAdprod : listMapAdprod){
            for(Ad_Product__c adProd : mapAdprod.values()){
                setOppId.add(adProd.Opportunity__c);
            }
        }
        this.setOppId = setOppId;
    }

    /*********************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        24.04.2024 / Sophal Noch / US-0014879 - 2.1 SAP for ADS - Billing Invoice record creation (monthly)
    -----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.04.2024 / Sophal Noch / Created the method.
    @               :  15.10.2024 / Vimean Heng / US-0015475 - SAP for ADS - Invoice fields and automations
    *********************************************************************************************************************************/
    public void execute(QueueableContext context){

        try {

            List<Opportunity> listOpp = (List<Opportunity>) ApexSafe.query().secCheck(false).doQuery(SOQL_OPP,new Map<String, Object> {'setOppId' => setOppId, 'setRType' => SET_RTYPE, 'stageName'=> closeWon});

            if(listOpp.isEmpty()){
                return;
            }
    
            Map<Id, Opportunity> mapOpp = new Map<Id, Opportunity>();
            for(Opportunity opp : listOpp){
                mapOpp.put(opp.Id, opp);
            }
    
            new BillingInvoiceGenerator(mapOpp).retrieveExistingRMonthly().populateBillingInvoice();

        } catch (Exception e) {
            EBH_ApexLogger.logError(new List<Exception>{e}, CLASS_NAME, 'execute'); 
        }

    }

}