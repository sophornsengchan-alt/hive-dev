/*****************************************************************************************************************************************************************
@ Class:          QueueGenerateRevenue
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
----------------------------------------------------------------------------------------------------------------------------------------------------------
@ Change history:  10.09.2021 / Sophal Noch / US-0010379 Create class, Run AdProductTriggerHandlerTest.testGenerateRevenueWithQueue to cover this class
                :  24.04.2024 / Sophal Noch / US-0014879 - 2.1 SAP for ADS - Billing Invoice record creation (monthly)
***********************************************************************************************************************************************************/
public with sharing class QueueGenerateRevenue implements Queueable{

    private List<Map<Id,Ad_Product__c>> listMapAdprod = new List<Map<Id,Ad_Product__c>>();
    Integer index;
    private final static Integer RETRY_LIMIT = 5;
    private String className = 'AdProductTriggerHandler';
    private String methodName = 'populateAdRevenueMonthlyAndDaily';
    Integer retryCounter = 0;
    public static Boolean isRunning = false;

    public QueueGenerateRevenue(List<Map<Id,Ad_Product__c>> listMapAdprod, Integer index) {
        isRunning = true;
        this.listMapAdprod = listMapAdprod;
        this.index = index;
    }
    public QueueGenerateRevenue(List<Map<Id,Ad_Product__c>> listMapAdprod, Integer index, Integer retryCounter) {
        this(listMapAdprod, index);
        this.retryCounter = retryCounter;
    }


    /*********************************************************************************************************************************
    @ Method:         execute
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Event:		  trigger after-update
    @ Purpose:        US-0010379 - ADS - Bug, Quote cannot be made primary due to size
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  10.09.2021 / Sophal Noch / US-0010379 create the method      
                    :  24.04.2024 / Sophal Noch / US-0014879 - 2.1 SAP for ADS - Billing Invoice record creation (monthly)
    *********************************************************************************************************************************/
    public void execute(QueueableContext context) {

        isRunning = true;

        try {

            new RevenueGenerator().setRecords(listMapAdprod[index]).retrieveExistingAdRevenue().populateAdRevenue();

        }catch (System.DMLException ex) {if (StatusCode.UNABLE_TO_LOCK_ROW==ex.getDmlType(0)){if(retryCounter > RETRY_LIMIT){EBH_ApexLogger.logError(new List<Exception> { ex }, className+'(QueueGenerateRevenue-LIMIT)', methodName);}else{doRetry();}}else{EBH_ApexLogger.logError(new List<Exception> { ex }, className+'(QueueGenerateRevenue-UNKNOWN-DML)', className);} return;}
        catch(Exception ex2) {EBH_ApexLogger.logError(new List<Exception> { ex2 }, className+'(QueueGenerateRevenue-UNKNOWN-Exception)', methodName); return;}
        
        index++; // chain queue with next chunk of a list of adProduct records.
        if(!Test.isRunningTest() && listMapAdprod.size() > index) {
            System.enqueueJob(new QueueGenerateRevenue(listMapAdprod,index));
        }else if(!Test.isRunningTest() && listMapAdprod.size() == index) { // 24.04.2024 / Sophal Noch / US-0014879
            System.enqueueJob(new QueueGenerateBillingInvoice(listMapAdprod));
        }
    }

    @TestVisible
    private void doRetry(){ 
        retryCounter++; 
        System.enqueueJob(new QueueGenerateRevenue(listMapAdprod,index,retryCounter));
    }
}