/*****************************************************************************************************************************************************************
@ Class:         AdRevenueDailyTriggerHandler
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
@ Change history:  31.12.2020 / Sophal Noch / Created the class.
@                   08/06/2022/ Sovantheany Dim / US-0011096 - ADS - Packages show incorrectly in Excel reports
***********************************************************************************************************************************************************/
public without sharing class AdRevenueDailyTriggerHandler {

    private static final String BILLING_CATEGORY_FIXPRICE = 'Fix Price';
    private static final String BILLING_CATEGORY_CPA = 'CPA';
    private static final String BILLING_CATEGORY_CPO = 'CPO';
    private static final String BILLING_CATEGORY_CPM = 'CPM';
    private static final String BILLING_CATEGORY_CPC = 'CPC';
    private static final String ADPRODUCT_API_NAME = 'Ad_Product__c';
    private static final String PACKAGE_PRODUCT = 'Package';

    public static Boolean runAsFuture = false;

    
    public static void updateDeliverySummeDaily(List<Ad_Revenue_Daily__c> listNewDaily, Map<Id,Ad_Revenue_Daily__c> mapOldDaily){

        Set<Id> setAdProdIds = new Set<Id>();
        Set<Id> setAdProdIds2 = new Set<Id>();
        Date today = system.today();
        Date minimumDay = today;
        Map<Id, Date> mapDailyDate = new Map<Id, Date>();

        Boolean isDelete = listNewDaily == null ? true : false;
        Boolean isInsert = mapOldDaily == null ? true : false;

        List<Ad_Revenue_Daily__c> listDailyToSum = listNewDaily != null ? listNewDaily : mapOldDaily.values();

        for(Ad_Revenue_Daily__c eachDaily : listDailyToSum){

            if(
                !eachDaily.Billing_Category__c.equalsIgnoreCase(BILLING_CATEGORY_CPA)
                &&( 
                    isDelete 
                    || isInsert
                    || eachDaily.Delivered_AI__c != mapOldDaily.get(eachDaily.Id).Delivered_AI__c
                    || eachDaily.Clicks_Recorded__c != mapOldDaily.get(eachDaily.Id).Clicks_Recorded__c
                    || eachDaily.X3rd_Party_AI__c != mapOldDaily.get(eachDaily.Id).X3rd_Party_AI__c
                    || eachDaily.X3rd_Party_Clicks__c != mapOldDaily.get(eachDaily.Id).X3rd_Party_Clicks__c
                    || eachDaily.X3rd_Party_Gross__c != mapOldDaily.get(eachDaily.Id).X3rd_Party_Gross__c
                    || eachDaily.Daily_Quantity__c != mapOldDaily.get(eachDaily.Id).Daily_Quantity__c
                )
    
            ){

                if(mapDailyDate.get(eachDaily.Ad_Product__c) == null || mapDailyDate.get(eachDaily.Ad_Product__c) > eachDaily.Day__c){
                    if(!setAdProdIds.contains(eachDaily.Ad_Product__c)){ setAdProdIds.add(eachDaily.Ad_Product__c); }
                    mapDailyDate.put(eachDaily.Ad_Product__c, eachDaily.Day__c);
                }

                if (eachDaily.Day__c < minimumDay) {
                    minimumDay = eachDaily.Day__c;
                }
            }
            
            //TH:US-0011096:set Ad_Product__c Id
            if((eachDaily.Delivered_AI__c == null || eachDaily.Delivered_AI__c == 0) && (eachDaily.Clicks_Recorded__c == null || eachDaily.Clicks_Recorded__c == 0)) continue;
            if(isDelete || isInsert 
                || eachDaily.Delivered_AI__c != mapOldDaily.get(eachDaily.Id).Delivered_AI__c
                || eachDaily.Clicks_Recorded__c != mapOldDaily.get(eachDaily.Id).Clicks_Recorded__c){
                    setAdProdIds2.add(eachDaily.Ad_Product__c);
            }
        }
		
        //
        List<Ad_Revenue_Daily__c> listDailyToUpdate = new List<Ad_Revenue_Daily__c>();

        if(!setAdProdIds.isEmpty()){

            Id former = null;
            Double summe = 0;
            Map<Id, Integer> dailyDeliveries = new Map<Id, Integer>();

            for (AggregateResult ar : [Select 
                Ad_Product__c, 
                sum(Daily_Quantity__c) dqSumme from Ad_Revenue_Daily__c 
                Where ((Ad_Id__c != null AND Ad_Id__c != '' AND Ad_Id__c != '0') or (Order_Id__c != null AND Order_Id__c != '' AND Order_Id__c != '0')) 
                AND Billing_Category__c !=: BILLING_CATEGORY_FIXPRICE
                AND Billing_Category__c !=: BILLING_CATEGORY_CPO
                AND Billing_Category__c !=: BILLING_CATEGORY_CPA
                AND Day__c < :minimumDay AND Day__c < :today 
                AND Ad_Product__c IN :setAdProdIds Group By Ad_Product__c]
            ) {

        	    dailyDeliveries.put(String.valueOf(ar.get(ADPRODUCT_API_NAME)), Decimal.valueOf(String.valueOf(ar.get('dqSumme'))).intValue());
            }


            for (Ad_Revenue_Daily__c eachDaily : [
                Select Id, 
                    Ad_Product__c, 
                    Day__c, 
                    Booked_Quantity__c, 
                    Billing_Category__c, 
                    Daily_Quantity__c, 
                    Delivered_Sum__c, 
                    Invoice_Quantity__c 
                    From Ad_Revenue_Daily__c 
                Where (
                    ((Ad_Id__c != null AND Ad_Id__c != '' AND Ad_Id__c != '0') or (Order_Id__c != null And Order_Id__c != '' AND Order_Id__c != '0')) 
                    OR Billing_Category__c =: BILLING_CATEGORY_FIXPRICE 
                    OR Billing_Category__c =: BILLING_CATEGORY_CPO
                ) 
                AND Billing_Category__c !=: BILLING_CATEGORY_CPA
                AND Day__c >= :minimumDay AND Day__c <= :today 
                AND Ad_Product__c IN :setAdProdIds order by Ad_Product__c, Day__c asc]) 
            {
                
                if (former == null || former != eachDaily.Ad_Product__c) {

                    if (dailyDeliveries.containsKey(eachDaily.Ad_Product__c)) {
                        summe = dailyDeliveries.get(eachDaily.Ad_Product__c);
                    }
                    else {
                        summe = 0;
                    }
                    former = eachDaily.Ad_Product__c;
                }
    
                summe += eachDaily.Daily_Quantity__c;

                if (mapDailyDate.get(eachDaily.Ad_Product__c) != null 
                && mapDailyDate.get(eachDaily.Ad_Product__c) > eachDaily.Day__c 
                && !(eachDaily.Billing_Category__c.equalsIgnoreCase(BILLING_CATEGORY_FIXPRICE) || eachDaily.Billing_Category__c.equalsIgnoreCase(BILLING_CATEGORY_CPO))) {
                  continue;
                }
                
                populateDailyList(summe, eachDaily, listDailyToUpdate);


            }
        }

        Map<Id, Ad_Revenue_Daily__c> mapToUpdates = new Map<Id, Ad_Revenue_Daily__c>(listDailyToUpdate);
        //TH:US-0011096 - ADS - Packages show incorrectly in Excel reports
        if(!setAdProdIds2.isEmpty()){
            calculateDailyDelivery(setAdProdIds2,mapToUpdates);
        }
        //End US-0011096


        Boolean isNotFromFuture = (System.isFuture() || System.isBatch() || System.isQueueable()) ? false : true; // Sophal:28/06/2021: US-0009797 make sure only non future process can call future method, // 10.09.2021 / Sophal Noch / US-0010379 - ADS - Bug, Quote cannot be made primary due to size
            //TH:US-0011096: Comment out
             /*if(!listDailyToUpdate.isEmpty()){

                if (isNotFromFuture && ((listDailyToUpdate.size() > (100 * listDailyToSum.size())) || (Test.isRunningTest() && runAsFuture) )) {
                    // system.debug(rsds.size() + ' / ' + 100 * listDailyToSum.size() + ' DML Rows expected');
                    futureUpdateDeliverySummeDailyHandler(setAdProdIds);
                    
                }
                else {
                  
                    update listDailyToUpdate;
                }

                
            }*/
            //TH:US-0011096: updated 
            if(!mapToUpdates.isEmpty()){

                if (isNotFromFuture && ((mapToUpdates.size() > (100 * listDailyToSum.size())) || (Test.isRunningTest() && runAsFuture) )) {
                    // system.debug(rsds.size() + ' / ' + 100 * listDailyToSum.size() + ' DML Rows expected');
                    //futureUpdateDeliverySummeDailyHandler(setAdProdIds);
                    futureUpdateDeliverySummeDailyHandler(setAdProdIds,setAdProdIds2);
                    
                }
                else {
                  
                    update mapToUpdates.values();
                }

                
            }

    }

    @future
    public static void futureUpdateDeliverySummeDailyHandler (Set<Id> setAdProdIds,Set<Id> setAdProdIds2) {
        nonFutureUpdateDeliverySummeDailyHandler(setAdProdIds,setAdProdIds2);
    }
    public static void nonFutureUpdateDeliverySummeDailyHandler (Set<Id> setAdProdIds,Set<Id> setAdProdIds2) {

        List<Ad_Revenue_Daily__c> listDailyToUpdate= new List<Ad_Revenue_Daily__c>();
        if(!setAdProdIds.isEmpty()){
            Id former = null;
            Double summe = 0;
            Date today = System.today();
            for (Ad_Revenue_Daily__c eachDaily : [Select Id, Ad_Product__c, Day__c, Invoice_Quantity__c, Booked_Quantity__c, Billing_Category__c, Daily_Quantity__c, Delivered_Sum__c From Ad_Revenue_Daily__c Where Ad_Id__c != null  AND Ad_Id__c != '' AND Ad_Id__c != '0' and Day__c <= :today and Ad_Product__c IN :setAdProdIds order by Ad_Product__c, Day__c Asc]) {
                
                if (former == null || former != eachDaily.Ad_Product__c) {
                    summe = 0;
                    former = eachDaily.Ad_Product__c;
                }
    
                summe += eachDaily.Daily_Quantity__c;
    
                populateDailyList(summe, eachDaily, listDailyToUpdate);
            }

        }
         //TH: 15/06/2022: US-0011096
        Map<Id, Ad_Revenue_Daily__c> mapToUpdates = new Map<Id, Ad_Revenue_Daily__c>(listDailyToUpdate);
        if(!setAdProdIds2.isEmpty()){
            calculateDailyDelivery(setAdProdIds2,mapToUpdates);
        }
        //End US-0011096

        if (!mapToUpdates.isEmpty()) {
            update mapToUpdates.values();
        }

        // Sophal / 27.08.2021 / US-0010259 update to trigger worflow "Update PVP ID" to run.
        update [Select Id From Ad_Revenue_Daily__c Where Ad_Id__c != null AND Ad_Id__c != '' AND Ad_Product__c IN :setAdProdIds AND Id NOT IN: mapToUpdates.values() order by Ad_Product__c, Day__c Asc];
    }
    //TH: 15/06/2022: US-0011096 - comment out

    /*public static void futureUpdateDeliverySummeDailyHandler (Set<Id> setAdProdIds) {
        nonFutureUpdateDeliverySummeDailyHandler(setAdProdIds);
    }*/

    /*public static void nonFutureUpdateDeliverySummeDailyHandler (Set<Id> setAdProdIds) {

        List<Ad_Revenue_Daily__c> listDailyToUpdate= new List<Ad_Revenue_Daily__c>();
        Id former = null;
        Double summe = 0;
        Date today = System.today();
        for (Ad_Revenue_Daily__c eachDaily : [Select Id, Ad_Product__c, Day__c, Invoice_Quantity__c, Booked_Quantity__c, Billing_Category__c, Daily_Quantity__c, Delivered_Sum__c From Ad_Revenue_Daily__c Where Ad_Id__c != null  AND Ad_Id__c != '' AND Ad_Id__c != '0' and Day__c <= :today and Ad_Product__c IN :setAdProdIds order by Ad_Product__c, Day__c Asc]) {
            
            if (former == null || former != eachDaily.Ad_Product__c) {
                summe = 0;
                former = eachDaily.Ad_Product__c;
            }

            summe += eachDaily.Daily_Quantity__c;

            populateDailyList(summe, eachDaily, listDailyToUpdate);
        }

        if (!listDailyToUpdate.isEmpty()) {
            update listDailyToUpdate;
        }

        // Sophal / 27.08.2021 / US-0010259 update to trigger worflow "Update PVP ID" to run.
        update [Select Id From Ad_Revenue_Daily__c Where Ad_Id__c != null AND Ad_Id__c != '' AND Ad_Product__c IN :setAdProdIds AND Id NOT IN: listDailyToUpdate order by Ad_Product__c, Day__c Asc];
    }*/

    /*********************************************************************************************************************************
    @ Method:         calculateDailyDelivery
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        US-0011096 - ADS - Packages show incorrectly in Excel reports
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.06.2022 / Sovantheany Dim / Created the method.
    *********************************************************************************************************************************/    
    private static void calculateDailyDelivery (Set<Id> setAdProdIds2, Map<Id, Ad_Revenue_Daily__c> mapToUpdates){
        String soqlAdProduct = 'select id,Package_line_item__c from Ad_Product__c';
        String whereCls = ' Where id IN: setAdProdIds2 and Package_line_item__c != null';
        Set<String> sPackageItem= new Set<String>();
        //get Main package id
        for(Ad_Product__c addProd : Database.query(soqlAdProduct + whereCls)){
            sPackageItem.add(addProd.Package_line_item__c);
        }
        //get all main package product
        Set<String> sAddProduct = new Set<String>();
        String whereCls2 = ' Where Package_line_item__c IN: sPackageItem';
        for(Ad_Product__c addProd2 : Database.query(soqlAdProduct + whereCls2)){
            sAddProduct.add(addProd2.ID);
        }
        if(!sPackageItem.isEmpty() && !sAddProduct.isEmpty()){
            Date today = System.today();
            String soqlAdsDaily = 'select SUM(Delivered_AI__c)deliv, SUM(Clicks_Recorded__c)click, Day__c,Ad_Product__r.Package_line_item__c pakage FROM Ad_Revenue_Daily__c';
            String whereAdsDaily = ' Where Ad_Product__c IN: sAddProduct and Day__c <=: today and ((Delivered_AI__c != null AND Delivered_AI__c != 0) OR (Clicks_Recorded__c != null AND Clicks_Recorded__c != 0)) GROUP BY Ad_Product__r.Package_line_item__c,Day__c';
            Map<String, Double> mapSumDelivery = new Map<String,Double>();
            Map<String, Double> mapSumClick = new Map<String,Double>();
            //sum all child
            for(AggregateResult aggr : Database.query(soqlAdsDaily + whereAdsDaily)){
                String key = aggr.get('pakage')+'_'+aggr.get('Day__c');
                mapSumDelivery.put(key,Double.valueOf(aggr.get('deliv')));
                mapSumClick.put(key,Double.valueOf(aggr.get('click')));
            }
            //Update Main Package
            String soqlAdsDailyParent = 'select id, Ad_Product__r.Quote_Line_Item__c, Delivered_AI__c, Clicks_Recorded__c, Day__c FROM Ad_Revenue_Daily__c';
            String whereAdsDailyParent = ' Where Ad_Product__r.Quote_Line_Item__c IN: sPackageItem and Ad_Product__r.Package_line_item__c = null and ad_Product__r.Product2__r.RecordType.DeveloperName =: PACKAGE_PRODUCT';
            
            for(Ad_Revenue_Daily__c adsDaily :  Database.query(soqlAdsDailyParent + whereAdsDailyParent)){
                Boolean isUpdated = false;
                Ad_Revenue_Daily__c dailyToUpdated = new Ad_Revenue_Daily__c(id=adsDaily.Id);
                if(mapToUpdates.containsKey(adsDaily.Id)) dailyToUpdated = mapToUpdates.get(adsDaily.Id);

                String key = adsDaily.Ad_Product__r.Quote_Line_Item__c+'_'+adsDaily.Day__c;
                if(mapSumDelivery.containsKey(key) && mapSumDelivery.get(key) != null){
                    dailyToUpdated.Delivered_AI__c = mapSumDelivery.get(key);
                    isUpdated = true;
                }
                if(mapSumClick.containsKey(key) && mapSumClick.get(key) != null){
                    dailyToUpdated.Clicks_Recorded__c = mapSumClick.get(key);
                    isUpdated = true;
                }
                if(isUpdated) mapToUpdates.put(adsDaily.Id, dailyToUpdated);
            }
        }
    }

    private static void populateDailyList (Double summe, Ad_Revenue_Daily__c dailyToUpdate, List<Ad_Revenue_Daily__c> listDailyToUpdate){


            Boolean changed = false;

            if (summe != dailyToUpdate.Delivered_Sum__c) {
                dailyToUpdate.Delivered_Sum__c = summe;
                changed = true;
            }

            if ((dailyToUpdate.Billing_Category__c.equalsIgnoreCase(BILLING_CATEGORY_FIXPRICE) || dailyToUpdate.Billing_Category__c.equalsIgnoreCase(BILLING_CATEGORY_CPO)) && dailyToUpdate.Invoice_Quantity__c != 1) {
                dailyToUpdate.Invoice_Quantity__c = 1;
                changed = true;
            }

            if (dailyToUpdate.Billing_Category__c.equalsIgnoreCase(BILLING_CATEGORY_CPM) || dailyToUpdate.Billing_Category__c.equalsIgnoreCase(BILLING_CATEGORY_CPC)) {

                if (dailyToUpdate.Booked_Quantity__c >= dailyToUpdate.Delivered_Sum__c) {
                    if (dailyToUpdate.Invoice_Quantity__c != dailyToUpdate.Daily_Quantity__c) {
                        dailyToUpdate.Invoice_Quantity__c = dailyToUpdate.Daily_Quantity__c;
                        changed = true;
                    }
                }
                else if (dailyToUpdate.Booked_Quantity__c >= (dailyToUpdate.Delivered_Sum__c - dailyToUpdate.Daily_Quantity__c)) {
                    if (dailyToUpdate.Invoice_Quantity__c != dailyToUpdate.Booked_Quantity__c - (dailyToUpdate.Delivered_Sum__c - dailyToUpdate.Daily_Quantity__c)) {
                        dailyToUpdate.Invoice_Quantity__c = dailyToUpdate.Booked_Quantity__c - (dailyToUpdate.Delivered_Sum__c - dailyToUpdate.Daily_Quantity__c);
                        changed = true;
                    }
                }
                else if (dailyToUpdate.Invoice_Quantity__c != 0) {
                    dailyToUpdate.Invoice_Quantity__c = 0;
                    changed = true;
                }
            }

            if (changed) {
                // listDailyToUpdate.add(new Ad_Revenue_Daily__c(Id = dailyToUpdate.Id, Delivered_Sum__c = dailyToUpdate.Delivered_Sum__c, Invoice_Quantity__c = dailyToUpdate.Invoice_Quantity__c));
                listDailyToUpdate.add(dailyToUpdate);
            }

    }

}