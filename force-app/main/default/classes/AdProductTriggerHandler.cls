/*********************************************************************************************************************************
@ Class:          AdProductTriggerHandler
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Handler Class for AdProductTrigger Trigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  17.08.2020 / Sophal Noch / Created the class.
@                  24.03.2021 / Mony Nou / US-0009260 - [Ads 2020] OLI Trigger to QLI/AP, Fields & Syncing
@                  05.11.2021 / Sophal Noch / US-0010628 - ADS - Allow edit rights on Revised Quote Line Items in past (with date validation)
@                  12.08.2022 / SRONG TIN / US-0012252 - SPIKE - Advertising - Intermittent Row Lock errors on Delivery Updates
@                  24.04.2024 / Sophal Noch / US-0014879 - 2.1 SAP for ADS - Billing Invoice record creation (monthly)
*********************************************************************************************************************************/
public without sharing class AdProductTriggerHandler {

    // Sophal Noch 21.08.2020  : US-0008007 populate field IsHavingProduct__c in order to differentiate Record Having Product or not
    // Sophal Noch 18.12.2020  : US-0008838 Rename method from differentiateRecordHavingProduct to populateFields
    //                           and update IsPendingDfpPush__c to true if specific fields are changed.
    //                           It runs on Trigger.BeforeUpdate
    
    public static Integer RG_DML_CHUNK_LIMIT = Integer.valueOf(Label.RG_DML_CHUNK_LIMIT); // 10.09.2021 / Sophal Noch / US-0010379 - ADS - Bug, Quote cannot be made primary due to size
    //12.08.2022 / SRONG TIN / US-0012252
    private static Set<Id> setAdProdIdsWhenGeneratingRevenue = new Set<Id>();

    public static void populateFields(List<Ad_Product__c> newAdProductList, Map<Id,Ad_Product__c> oldAdProductMap){

        for(Ad_Product__c eachAdProd : newAdProductList){

            Ad_Product__c oldAdProd = oldAdProductMap == null ? null : oldAdProductMap.get(eachAdProd.Id);

            if(oldAdProd == null || eachAdProd.Product2__c != oldAdProd.Product2__c){
                eachAdProd.IsHavingProduct__c = eachAdProd.Product2__c != null ? true : false;  // US-0008007, IsHavingProduct__c use in opportunity roll-up summary field
            }
            
            // check QLI2AP Mappings of Custom Metadata Types to see complete field mapping between Ad_product__c and Quotelineitem
            if(
                oldAdProd != null // for trigger update only. when trigger is update, oldAdProductMap is not null.
                // && eachAdProd.Is_Revised_Quote__c == true // no need to specfic it is revised quote.
                && eachAdProd.IsPendingDfpPush__c == false
                &&(
                    eachAdProd.Quantity__c != oldAdProd.Quantity__c // adproduct.Quantity__c is from quotelineitem.Quantity__c
                    || eachAdProd.TotalPrice__c != oldAdProd.TotalPrice__c // adproduct.TotalPrice__c is from  quotelineitem.Budget__c
                    || eachAdProd.until_date__c != oldAdProd.until_date__c // adproduct.until_Date__c is from quotelineitem.until_Date__c
                )
            ){
                eachAdProd.IsPendingDfpPush__c = true; // US-0008838 update this field, so it can be rebook to DFP
            }

            // 26.03.2021 / Sophal Noch / US-0008908 sync Quantity__c to Booked_Quantity__c
            if(oldAdProd == null || eachAdProd.Quantity__c != eachAdProd.Booked_Quantity__c){
                eachAdProd.Booked_Quantity__c = eachAdProd.Quantity__c;
            }

            // 05.11.2021 / Sophal Noch / US-0010628 store previous state of fields in new fields, it is used in queue.
            if(needToCalculateRevenue(eachAdProd, oldAdProd)){
                eachAdProd.Prior_Until_Date__c = oldAdProd != null ? oldAdProd.until_date__c : eachAdProd.until_date__c;
                eachAdProd.Prior_TotalPrice__c = oldAdProd != null ? oldAdProd.totalprice__c : eachAdProd.totalprice__c;
            }

                    
        }
    }

    /*****************************************************************************************************************************
    @ Method:       populateAdRevenueMonthlyAndDaily
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0007980
    @               Summary: When an Ad Product is added to an Opportunity, the child records for Ad Revenue Daily & Ad Revenue Monthly should be created.
    @               AC1) When an 'Ad Product' is inserted or created or updated - the start and end dates of the Ad Product are used to create and populate entries for
    @               Ad Revenue Daily
    @               Ad Revenue Monthly
    @               Technical Notes:
    @               The class and methods GW_IO.RevenueScheduleCreator can be used as a starting point, however note:
    @               Only needs to work on Ad Product, Ad Revenue Monthly and Ad Revenue Daily
    @               IO and Ad Campaign are no longer needed, neither are the monthly/daily revenue schedule objects associated. (will be deleted later)
    @               We will never generate revenue schedules directly off an opportunity, only via Ad Product. The FMRS and FDRS objects will not be used.
    @               The process must allow for actuals in the future, so when updating the schedule in the future, existing revenue lines must be updated,
    @               AC2) The Ad Revenue Daily & Ad Revenue Monthly records associated with an Ad Product should be re-calculated and updated each time a change is made to any of the following fields (from_Date__c, until_Date__c, TotalPrice__c) on Ad_Product__c. 
    @ Event:		after insert, after update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	List<Ad_Product__c> newAdProductList, Map<Id,Ad_Product__c> oldAdProductMap
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  21.08.2020 / Sophal Noch / Created the method.
    @ Change history:  10.09.2021 / Sophal Noch / US-0010379 modified the method.
    @                  24.04.2024 / Sophal Noch / US-0014879 - 2.1 SAP for ADS - Billing Invoice record creation (monthly)
    @*****************************************************************************************************************************/
    public static void populateAdRevenueMonthlyAndDaily(List<Ad_Product__c> newAdProductList, Map<Id,Ad_Product__c> oldAdProductMap){

        Map<Id,Ad_Product__c> mapAdProdForGenerating = new Map<Id,Ad_Product__c> ();
        List<Map<Id,Ad_Product__c>> listMapAdprod = new List<Map<Id,Ad_Product__c>>();

        // new RevenueGenerator() // 10.09.2021 / Sophal Noch / US-0010379 not used anymore
        // .filterRecords(newAdProductList,oldAdProductMap)
        // .retrieveExistingAdRevenue()
        // .populateAdRevenue();

        Integer numberOfDayPerChunk = 0;
        Boolean isUpdate = oldAdProductMap != null ? true : false;
        for(Ad_Product__c eachAdProduct : newAdProductList){

            Ad_Product__c oldAdProd = oldAdProductMap == null ? null : oldAdProductMap.get(eachAdProduct.Id);

            if(
                eachAdProduct.from_Date__c != null && eachAdProduct.until_Date__c != null
                && (!isUpdate
                    // || eachAdProduct.from_Date__c != oldAdProductMap.get(eachAdProduct.Id).from_Date__c
                    // || eachAdProduct.until_Date__c != oldAdProductMap.get(eachAdProduct.Id).until_Date__c
                    // || eachAdProduct.TotalPrice__c != oldAdProductMap.get(eachAdProduct.Id).TotalPrice__c
                    || needToCalculateRevenue(eachAdProduct, oldAdProd) // 05.11.2021 / Sophal Noch / US-0010628 reused method whether reveneue should be populated or not
                )
            ){
                //12.08.2022 / SRONG TIN / US-0012252
                setAdProdIdsWhenGeneratingRevenue.add(eachAdProduct.Id);

                // 10.09.2021 / Sophal Noch / US-0010379 :
                Integer currentNumberOfDay = Integer.valueOf(eachAdProduct.FromDateUntilDate_Days__c); // number of days between Ad_Product__c.from_date__c and Ad_Product__c.until_date__c, it also means the numbers of ad_revenue_daily__c per ad_product__c
                numberOfDayPerChunk += currentNumberOfDay;

                if(numberOfDayPerChunk > RG_DML_CHUNK_LIMIT){ // limit size of Ad_revenue_daily__c per chunk
                    if(!mapAdProdForGenerating.isEmpty()){
                        listMapAdprod.add(new Map<Id,Ad_Product__c>(mapAdProdForGenerating.values()));  // group previous available ad_product__c except the current and future ad_product__c
                        mapAdProdForGenerating = new Map<Id,Ad_Product__c>();
                    }
                    numberOfDayPerChunk = currentNumberOfDay; // current ad_product__c will be grouped in the next chunk
                }
                mapAdProdForGenerating.put(eachAdProduct.Id,eachAdProduct);
 
            }
        }

        if (!mapAdProdForGenerating.isEmpty()) listMapAdprod.add(mapAdProdForGenerating); // leftover or final chunk

        if(!listMapAdprod.isEmpty()){

            // 05.11.2021 / Sophal Noch / US-0010628 check if trigger run in future or not
            Boolean isNotFromFuture = (System.isFuture() || System.isBatch() || System.isQueueable()) ? false : true;

            // 10.09.2021 / Sophal Noch / US-0010379 :
            if(isNotFromFuture && (!Test.isRunningTest() || (Test.isRunningTest() && listMapAdprod.size() > 1))){
                // call queue to generate revenue
                System.enqueueJob(new QueueGenerateRevenue(listMapAdprod, 0));  // 0 is index of the first chunk of records to start with, index will be increased in queue until all chunks are processed 
            }else{ 
                // for cover all kind of logic in test class without running in async
                new RevenueGenerator().setRecords(listMapAdprod[0]).retrieveExistingAdRevenue().populateAdRevenue();
                new QueueGenerateBillingInvoice(listMapAdprod).execute(null);  // 24.04.2024 / Sophal Noch / US-0014879
            }

        }

    }
    

    /*****************************************************************************************************************************************************************
    @ Method:         preventDeleteAdProduct
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008866
	@                 As a...
    @                 Advertising User in Hive
    @                 Want to...
    @                 ensure that Quote Line Items and Ad Products cannot be deleted once they have been booked to DFP
    @                 So that...
    @                 we can ensure that delivery and financial forecasts are not deleted.
    @                 Description
    @                 AC 1) As any user, I should not be able to delete a Quote Line Item & Ad Product when the Ad Product has been booked to DFP.
    @                 Any Ad Product with an 'Ad Id' populated means that it has been booked to DFP - the Ad Product should not be able to be deleted.
    @                 
    @                 Where the Ad Product has an Ad Id - the associated Quote Line Item (via Lookup to Ad Product) should also not be able to be deleted.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  18.12.2020 / Sophal Noch / Created the method.
    @               :  04.10.2021 / Sophal Noch/ US-0010555 - ADS - Validation skip on setting AD on Ad product for PVP
    ***********************************************************************************************************************************************************/
    public static void preventDeleteAdProduct(List<Ad_Product__c> oldAdprod){
        for(Ad_Product__c eachAdProd : oldAdprod){
            // if(String.isNotBlank(eachAdProd.Ad_Id__c)){eachAdProd.addError(Label.Error_AdProduct_Cannot_Be_Deleted_When_It_Has_Been_Booked);}
            if(eachAdProd.IsInGamOrCallisto__c){eachAdProd.addError(Label.Error_AdProduct_Cannot_Be_Deleted_When_It_Has_Been_Booked);} // 04.10.2021 / Sophal Noch / US-0010555
        }
    }

    
    /*****************************************************************************************************************************************************************
    @ Method:         updateDeliverySummeDaily
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008300
    @                 As a...
    @                 Advertising user in Hive
    @                 Want to...
    @                 have a single object to track daily ads revenue forecasts and actuals
    @                 So that...
    @                 we have a single source of truth
    @                 Description
    @                 Summary: Recreate ' UpdateDeliverySummerRSD2' Apex trigger for NA Advertising
    @                 AC 1) Migrate the 'updateDeliverySummeRSD2' Apex Trigger from EU Advertising to 'Ad Revenue Daily' in Hive and change references accordingly.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  31.12.2020 / Sophal Noch / Created the method.
    ***********************************************************************************************************************************************************/
    /*****************************************************************************************************************************************************************
    @ Method:         updateDeliverySumme
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008300
    @                 As a...
    @                 Advertising user in Hive
    @                 Want to...
    @                 have a single object to track daily ads revenue forecasts and actuals
    @                 So that...
    @                 we have a single source of truth
    @                 Description
    @                 Summary: Recreate ' UpdateDeliverySummerRSD2' Apex trigger for NA Advertising
    @                 AC 1) Migrate the 'updateDeliverySummeRSD2' Apex Trigger from EU Advertising to 'Ad Revenue Daily' in Hive and change references accordingly.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  31.12.2020 / Sophal Noch / Created the method.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  08.02.2021 / Sophal Noch / modified the method. US-0008908 - [Ads 2020] Monthly Ads Revenue - Delivery Summer Trigger for Accruals  
    ***********************************************************************************************************************************************************/
    public static void updateDeliverySumme(List<Ad_Product__c> newAdProductList, Map<Id,Ad_Product__c> oldAdProductMap){
        
        Set<Id> setAdProdIds = new Set<Id> ();
        
        for(Ad_Product__c eachAdProd : newAdProductList){
            //12.08.2022 / SRONG TIN / US-0012252
            if(
                !setAdProdIdsWhenGeneratingRevenue.contains(eachAdProd.Id)
                && eachAdProd.Billing_Category__c != null
                // && eachAdProd.Ad_Id__c != null
                && eachAdProd.Booked_Quantity__c != null
                && (
                    (eachAdProd.Billing_Category__c != oldAdProductMap.get(eachAdProd.Id).Billing_Category__c)
                    || (eachAdProd.Ad_Id__c != oldAdProductMap.get(eachAdProd.Id).Ad_Id__c)
                    || (eachAdProd.Booked_Quantity__c != oldAdProductMap.get(eachAdProd.Id).Booked_Quantity__c)
                )
            ){
                setAdProdIds.add(eachAdProd.Id);
            }
        }

        if(!setAdProdIds.isEmpty()){

            if(System.isFuture() || System.isBatch() || System.isQueueable()){ // Sophal:28/06/2021: US-0009797 if future process, run non-future method
                AdRevenueMonthlyTriggerHandler.nonFutureUpdateDeliverySummeMonthlyHandler(setAdProdIds);
                AdRevenueDailyTriggerHandler.nonFutureUpdateDeliverySummeDailyHandler(setAdProdIds,new Set<Id>{});
            }else{ // Sophal:28/06/2021: US-0009797 if not future process, run future method
                AdRevenueMonthlyTriggerHandler.futureUpdateDeliverySummeMonthlyHandler(setAdProdIds); // 08.02.2021 / Sophal Noch / US-0008908
                AdRevenueDailyTriggerHandler.futureUpdateDeliverySummeDailyHandler(setAdProdIds,new Set<Id>{});
            }
        }
    }


    /*********************************************************************************************************************************
    @ Method:         updateInvoiceAmount
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0009328 update Invoice_amount__c to Invoice_amount2__c on child record Ad_Revenue_Monthly__c
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  08.04.2021 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/    
    public static void updateInvoiceAmount(List<Ad_Product__c> newAdProductList, Map<Id,Ad_Product__c> oldAdProductMap){
        
        Set<Id> setAdsProd = new Set<Id>();

        for(Ad_Product__c eachAdProd : newAdProductList){
            // Sophal / 08.04.2021 / US-0009328 : no need to check Booked_Quantity__c and Billing_Category__c, because updateDeliverySumme already do the work for it.
            if(eachAdProd.Net_Net_Net__c != oldAdProductMap.get(eachAdProd.Id).Net_Net_Net__c){
                setAdsProd.add(eachAdProd.Id);
            }
        }

        if(!setAdsProd.isEmpty()){
            // Sophal / 08.04.2021 / US-0009328 : Ad_Revenue_Monthly__c trigger will detect it own formula field update because Ad_Product__c.Net_Net_Net__c changed
            update [Select Id from Ad_Revenue_Monthly__c Where Ad_Product__c IN : setAdsProd Order By Ad_Product__c, Transaction_Date__c ASC]; 
        }




    }


    /*****************************************************************************************************************************
    @ Method:       calcAmountByDelivery
    @ Author:       Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:      US-0009260
    @ Event:		before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	List<Ad_Product__c> newAdProd
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  24.03.2021 / Mony Nou / Created the method.
    @*****************************************************************************************************************************/

    public static void calcAmountByDelivery (List<Ad_Product__c> newAdProd) {
        
        Map<String, String> mBillingCateCalculation1 = new Map<String, String> {
            'CPM'           => 'Delivered_Impressions__c',
            'CPC'           => 'Delivered_Clicks__c'
        };
        
        Set<String> sBillingCateCalculation2 = new Set<String>{'CPD','Fix Price','ServiceFee','Subscription'};
        Set<String> sBillingCateCalculation3 = new Set<String>{'CPO'};

        Date now = Date.today();

        for (Ad_Product__c ap : newAdProd) {

            String bc = ap.Billing_category__c;
            
            if (String.isNotBlank(bc) && now > ap.from_Date__c) {
                
                    Decimal turnoverval = 0;
                    /*
                    *   Calculation-1 is for Billing Category = CPM & CPC
                    *       CPM = It will calculate with Delivered_Impressions__c so if Quantity__c > Delivered_Impressions__c => calculate by (CPM_net__c * Delivered_Impressions__c)/1000, else => eqaul Amount_Net_Net_Net__c
                    *       CPC = It will caclulate with Delivered_Clicks__c so if Quantity__c > Delivered_Clicks__c => calculate by CPM_net__c * Delivered_Clicks__c, else => eqaul Amount_Net_Net_Net__c
                    */
                    if (mBillingCateCalculation1.containsKey(bc)) {
                        Decimal val         = ApexUtil.toDecimal0(String.valueOf(ap.get(mBillingCateCalculation1.get(bc))),0);
                        Decimal qty         = ApexUtil.toDecimal0(String.valueOf(ap.Quantity__c),2);
                        Decimal division    = (bc == 'CPM')?1000:1;
                        turnoverval = (qty > val)?(ApexUtil.toDecimal0(String.valueOf(ap.CPM_net__c),2) * val)/division:ap.Amount_Net_Net_Net__c;
                    }
                    /*
                    *   Calculation-2 is for Billing Category CPD, Fix Price, ServiceFee, Subscription => eqaul Amount_Net_Net_Net__c
                    */
                    else if (sBillingCateCalculation2.contains(bc)) {
                        Decimal val = ApexUtil.toDecimal0(String.valueOf(ap.Amount_Net_Net_Net__c),2);
                        turnoverval = val;  
                    }
                    /*
                    *   Calculation-3 is for Billing Category CPO
                            If until_Date__c is already reached => equal Amount_Net_Net_Net__c
                            If until_Date__c is not yet reached => calculate the amount of the day that it's already reached (from_Date__c until NOW). 
                                Ex: - from_Date__c to until_Date__c = 10 days and Amount_Net_Net_Net__c = 5$ (per day) 
                                    - If until_Date__c is already reached => 10 days * 5$ = 50$
                                    - If until_Date__c is not yet reached => 
                                        + from_Date__c = 2 days ago => 2 days * 5$ = 10$
                    */
                    else if (sBillingCateCalculation3.contains(ap.Billing_category__c)) {
                        Decimal val = ApexUtil.toDecimal0(String.valueOf(ap.Amount_Net_Net_Net__c),2);
                        if (now > ap.until_Date__c) turnoverval = val;  
                        else {
                            if (ap.from_Date__c != null && ap.until_Date__c != null && ap.from_Date__c <= ap.until_Date__c) {
                                Double n1 = Double.valueOf(ap.from_Date__c.daysBetween(now)) + 1;
                                Double n2 = Double.valueOf(ap.from_Date__c.daysBetween(ap.until_Date__c)) + 1;
                                turnoverval = (n1 / n2 * val);
                            } 
                        }
                    }

                    ap.Turnover_actual_by_delivery__c = turnoverval;
                    
            } else {
                ap.Turnover_actual_by_delivery__c = 0; 
            }
        }
        
    }

    private static Boolean needToCalculateRevenue(Ad_Product__c adProd, Ad_Product__c oldAdProd){
        if(oldAdProd == null || adProd.from_Date__c != oldAdProd.from_Date__c || adProd.until_Date__c != oldAdProd.until_Date__c || adProd.TotalPrice__c != oldAdProd.TotalPrice__c){
            return true;
        }
        return false;
    }

}