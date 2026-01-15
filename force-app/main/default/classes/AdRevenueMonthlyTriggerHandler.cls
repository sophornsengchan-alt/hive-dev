/*****************************************************************************************************************************************************************
@ Class:          AdRevenueMonthlyTriggerHandler
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0008908
@                 As a...
@                 Advertising user in Hive
@                 Want to...
@                 have a single object to track monthly ads revenue forecasts and actuals
@                 So that...
@                 we have a single source of truth
@                 Description
@                 Summary: Recreate ' UpdateDeliverySummerRS2' Apex Class from EU Advertising so it can be used for NA Advertising in Hive
@                 AC 1) Migrate the 'updateDeliverySummeRS2' Apex Class from EU Advertising to 'Ad Revenue Monthly' in Hive and change references accordingly.
----------------------------------------------------------------------------------------------------------------------------------------------------------
@ Change history:  08.02.2021 / Sophal Noch / Created the class.
----------------------------------------------------------------------------------------------------------------------------------------------------------
@ Change history:  08.04.2021 / Sophal Noch / US-0009328 Modified the class.
----------------------------------------------------------------------------------------------------------------------------------------------------------
@ Change history:  12.11.2021 / Sophal Noch / US-0010680 - ADS - Delivery Override field creation on Ad Revenue Monthly & Ad Revenue Daily
                :  07.09.2025 / Sovantheany Dim / US-0032987 - BF Opportunities: Update invoice amount calculations to prevent overcharging 
***********************************************************************************************************************************************************/
public without sharing class AdRevenueMonthlyTriggerHandler {

    private static final String BILLING_CATEGORY_FIXPRICE = 'Fix Price';
    private static final String BILLING_CATEGORY_CPA = 'CPA';
    private static final String BILLING_CATEGORY_CPO = 'CPO';
    private static final String BILLING_CATEGORY_CPM = 'CPM';
    private static final String BILLING_CATEGORY_CPC = 'CPC';
    private static final String ADPRODUCT_API_NAME = 'Ad_Product__c';

    public static Boolean runAsFuture = false;
    public static Boolean preventCirularUpdates = false;//TH:US-0032987
    public static Boolean isExceeded = false;//TH:US-0032987

    public static void updateDeliverySummeMonthly(List<Ad_Revenue_Monthly__c> listNewMonthly, Map<Id,Ad_Revenue_Monthly__c> mapOldMonthly){

        if (preventCirularUpdates) {return;}//TH:US-0032987

        Set<Id> setAdProdIds = new Set<Id>();
        Map<Id, Date> mapMonthlyDate = new Map<Id, Date>();

        Boolean isDelete = listNewMonthly == null ? true : false;
        Boolean isInsert = mapOldMonthly == null ? true : false;

        List<Ad_Revenue_Monthly__c> listMonthlyToSum = listNewMonthly != null ? listNewMonthly : mapOldMonthly.values();

        for(Ad_Revenue_Monthly__c eachMonthly : listMonthlyToSum){

            if(

                (
                    (
                        ((eachMonthly.Ad_Id__c != null && eachMonthly.Ad_Id__c != '' && eachMonthly.Ad_Id__c != '0') || (eachMonthly.Order_Id__c != null && eachMonthly.Order_Id__c != '' && eachMonthly.Order_Id__c != '0')) 
                        && !eachMonthly.Billing_Category__c.equalsIgnoreCase(BILLING_CATEGORY_CPA)
                    )
                    || (eachMonthly.X3rd_Party_AI__c != null || eachMonthly.X3rd_Party_Clicks__c != null)
                    || (eachMonthly.Delivered_AI_Override__c != null || eachMonthly.Delivered_Clicks_Override__c != null) // 12.11.2021 / Sophal Noch / US-0010680 let calculation run when field Delivered_AI_Override__c or Delivered_Clicks_Override__c is Not empty
                    || eachMonthly.Billing_Category__c.equalsIgnoreCase(BILLING_CATEGORY_FIXPRICE)
                    || eachMonthly.Billing_Category__c.equalsIgnoreCase(BILLING_CATEGORY_CPO)
                )
                &&( 
                    isDelete 
                    || isInsert
                    || eachMonthly.Delivered_AI__c != mapOldMonthly.get(eachMonthly.Id).Delivered_AI__c
                    || eachMonthly.Clicks_Recorded__c != mapOldMonthly.get(eachMonthly.Id).Clicks_Recorded__c
                    || eachMonthly.X3rd_Party_AI__c != mapOldMonthly.get(eachMonthly.Id).X3rd_Party_AI__c
                    || eachMonthly.X3rd_Party_Clicks__c != mapOldMonthly.get(eachMonthly.Id).X3rd_Party_Clicks__c
                    || eachMonthly.X3rd_Party_Monthly_Gross__c != mapOldMonthly.get(eachMonthly.Id).X3rd_Party_Monthly_Gross__c //TH:US-0032987
                    || eachMonthly.Monthly_Quantity__c != mapOldMonthly.get(eachMonthly.Id).Monthly_Quantity__c
                    || eachMonthly.Invoice_Quantity__c != mapOldMonthly.get(eachMonthly.Id).Invoice_Quantity__c // Sophal:28/06/2021: US-0009797 add invoice qty to check excceed invoice qty logic
                )
    
            ){

                if(mapMonthlyDate.get(eachMonthly.Ad_Product__c) == null || mapMonthlyDate.get(eachMonthly.Ad_Product__c) > eachMonthly.Transaction_Date__c){
                    if(!setAdProdIds.contains(eachMonthly.Ad_Product__c)){ setAdProdIds.add(eachMonthly.Ad_Product__c); }
                    mapMonthlyDate.put(eachMonthly.Ad_Product__c, eachMonthly.Transaction_Date__c);
                }
            }
        }

        if(!setAdProdIds.isEmpty()){

            updateDeliverySummeMonthlyHandler(setAdProdIds, mapMonthlyDate);


        }

    }

    @future
    public static void futureUpdateDeliverySummeMonthlyHandler (Set<Id> setAdProdIds) {
        updateDeliverySummeMonthlyHandler(setAdProdIds, null);
    }

    public static void nonFutureUpdateDeliverySummeMonthlyHandler (Set<Id> setAdProdIds) {
        updateDeliverySummeMonthlyHandler(setAdProdIds, null);
    }

    private static void updateDeliverySummeMonthlyHandler (Set<Id> setAdProdIds, Map<Id, Date> mapMonthlyDate) {

        List<Ad_Revenue_Monthly__c> listMonthlyToUpdate = new List<Ad_Revenue_Monthly__c>();
        Id former = null;
        Double summe = 0;
        Double totalActualBF = 0; //TH:US-0032987
        Double totalBookedBF = 0; //TH:US-0032987
        Double totalInvoiceQty = 0; // Sophal:28/06/2021: US-0009797 use to sum all invoice qty of ad revenue monthly
        // Date today = System.today();
        // Date currentMonth = Date.newInstance(today.year(), today.month(), 1);

        Boolean isUpdatedFromParent = mapMonthlyDate == null ? true : false; // Sophal:28/06/2021: US-0009797 if there are specific fields updated from ad product

       
        String soql = 'Select Id, Ad_Product__c, Transaction_Date__c, ' +
              'Invoice_Quantity__c, Booked_Quantity__c, Billing_Category__c, ' +
              'Monthly_Quantity__c, Delivered_Sum__c, ' +
              'Is_Exceeding_BookedQuantity__c, ' +
              'X3rd_Party_Monthly_Gross__c, ' +
              'ad_product__r.TotalPrice__c ' +
              'From Ad_Revenue_Monthly__c ' +
              'Where ' +
              '( ' +
              '    (((Ad_Id__c != null And Ad_Id__c != \'\' And Ad_Id__c != \'0\') OR (Order_Id__c != null And Order_Id__c != \'\' And Order_Id__c != \'0\')) And Billing_Category__c !=: BILLING_CATEGORY_CPA) ' +
              '    OR (X3rd_Party_AI__c != null Or X3rd_Party_Clicks__c != null) ' +
              '    OR (Delivered_AI_Override__c != null OR Delivered_Clicks_Override__c != null) ' +
              '    OR Billing_Category__c =: BILLING_CATEGORY_FIXPRICE ' +
              '    OR Billing_Category__c =: BILLING_CATEGORY_CPO ' +
              ') ' +
              'And Ad_Product__c IN :setAdProdIds ' +
              'Order By Ad_Product__c, Transaction_Date__c Asc';

        List<Ad_Revenue_Monthly__c> adRevenueList = (List<Ad_Revenue_Monthly__c>) ApexSafe.query().doQuery(soql, 
                                                        new Map<String, Object> {
                                                            'BILLING_CATEGORY_CPA' => BILLING_CATEGORY_CPA,
                                                            'BILLING_CATEGORY_FIXPRICE' => BILLING_CATEGORY_FIXPRICE,
                                                            'BILLING_CATEGORY_CPO' => BILLING_CATEGORY_CPO,
                                                            'setAdProdIds' => setAdProdIds
                                                        });
         //TH:US-0032987 : comment out                                                
        /*for (Ad_Revenue_Monthly__c eachMonthly : [Select Id, Ad_Product__c, Transaction_Date__c, 
                                                Invoice_Quantity__c, Booked_Quantity__c, Billing_Category__c, 
                                                Monthly_Quantity__c, Delivered_Sum__c,
                                                Is_Exceeding_BookedQuantity__c,
                                                X3rd_Party_Monthly_Gross__c,
                                                ad_product__r.TotalPrice__c
                                                From Ad_Revenue_Monthly__c 
                                                Where 
                                                (
                                                    (((Ad_Id__c != null And Ad_Id__c != '' And Ad_Id__c != '0') OR (Order_Id__c != null And Order_Id__c != '' And Order_Id__c != '0')) And Billing_Category__c !=: BILLING_CATEGORY_CPA)
                                                    OR (X3rd_Party_AI__c != null Or X3rd_Party_Clicks__c != null)
                                                    OR (Delivered_AI_Override__c != null OR Delivered_Clicks_Override__c != null) // 12.11.2021 / Sophal Noch / US-0010680 run calculation with Delivered_AI_Override__c or Delivered_Clicks_Override__c even Ad_Id__c is populated or not
                                                    OR Billing_Category__c =: BILLING_CATEGORY_FIXPRICE
                                                    OR Billing_Category__c =: BILLING_CATEGORY_CPO
                                                )
                                                //And Transaction_Date__c <= :currentMonth 
                                                And Ad_Product__c IN :setAdProdIds
                                                Order By Ad_Product__c, Transaction_Date__c Asc]) {*/
        for (Ad_Revenue_Monthly__c eachMonthly : adRevenueList) {
            
            if (former == null || former != eachMonthly.Ad_Product__c) {
                summe = 0;
                totalActualBF = 0;                                          //TH:US-0032987 Total Actual for Brand Funding lines - reset to zero for each Ad Product
                totalBookedBF = eachMonthly.ad_product__r.TotalPrice__c;    //TH:US-0032987 Total Booked Amount for the entire Ad Product
                former = eachMonthly.Ad_Product__c;
                isExceeded = false;
            }

            summe += eachMonthly.Monthly_Quantity__c;
            totalInvoiceQty += (eachMonthly.Invoice_Quantity__c != null ? eachMonthly.Invoice_Quantity__c : 0); // Sophal:28/06/2021: US-0009797 use to sum each invoice qty per month

            totalActualBF += (eachMonthly.X3rd_Party_Monthly_Gross__c != null ? eachMonthly.X3rd_Party_Monthly_Gross__c : 0); //TH:US-0032987 totals up the X3rd Party Gross for this Ad Product

            Date triggerMinDate = mapMonthlyDate != null ? mapMonthlyDate.get(eachMonthly.Ad_Product__c) : null;

            if (triggerMinDate != null && triggerMinDate > eachMonthly.Transaction_Date__c && !(eachMonthly.Billing_Category__c.equalsIgnoreCase(BILLING_CATEGORY_FIXPRICE) || eachMonthly.Billing_Category__c.equalsIgnoreCase(BILLING_CATEGORY_CPO))) {
                continue;
            }

            populateMonthlyList(summe, totalInvoiceQty ,eachMonthly, listMonthlyToUpdate, isUpdatedFromParent, totalActualBF, totalBookedBF); //TH:US-0032987 added totalActualBF and totalBookedBF
        }

        if (!listMonthlyToUpdate.isEmpty()) {
            preventCirularUpdates = true; //TH:US-0032987 prevent multiple iterations of this trigger
            //update listMonthlyToUpdate;//TH:US-0032987 replace with ApexSafe
            Database.SaveResult[] result = ApexSafe.dml().secCheck(false).doUpdate(listMonthlyToUpdate, true);
            preventCirularUpdates = false;//TH:US-0032987
        }
    }



    public static void populateMonthlyList (Double summe, Double totalInvoiceQty, Ad_Revenue_Monthly__c monthlyToUpdate, List<Ad_Revenue_Monthly__c> listMonthlyToUpdate, Boolean isUpdatedFromParent, Double totalActualBF, Double totalBookedBF) { //TH:US-0032987 added totalActualBF and totalBookedBF


        totalInvoiceQty -=  (monthlyToUpdate.Invoice_Quantity__c != null ? monthlyToUpdate.Invoice_Quantity__c : 0); // Sophal:28/06/2021: US-0009797 remove current month's invoice qty from summary because invoice qty need to be calculated fist

        Boolean changed = false;

        if ((monthlyToUpdate.Billing_Category__c.equalsIgnoreCase(BILLING_CATEGORY_FIXPRICE) || monthlyToUpdate.Billing_Category__c.equalsIgnoreCase(BILLING_CATEGORY_CPO)) && monthlyToUpdate.Invoice_Quantity__c != 1) {
            monthlyToUpdate.Invoice_Quantity__c = 1;
            changed = true;
        }
        // TH:US-0032987 Start
        if ((monthlyToUpdate.Billing_Category__c.equalsIgnoreCase(BILLING_CATEGORY_CPO))  && monthlyToUpdate.X3rd_Party_Monthly_Gross__c != null && monthlyToUpdate.X3rd_Party_Monthly_Gross__c <> 0) {
            Double diff = (totalActualBF - totalBookedBF);
            if (diff > 0) {
                if (!isExceeded) { // if already isExceeded, then there is no further calculation needed, all subsequent ARM records will be set to 0
                    monthlyToUpdate.X3rd_Party_Monthly_Gross__c = (monthlyToUpdate.X3rd_Party_Monthly_Gross__c - diff);
                    isExceeded = true;
                } else {
                    monthlyToUpdate.X3rd_Party_Monthly_Gross__c = 0;
                }
                changed = true;

            } 
            
        }
        // TH:US-0032987 End
        if (summe != monthlyToUpdate.Delivered_Sum__c) {
            monthlyToUpdate.Delivered_Sum__c = summe;
            changed = true;
        }

        if (monthlyToUpdate.Billing_Category__c.equalsIgnoreCase(BILLING_CATEGORY_CPM) || monthlyToUpdate.Billing_Category__c.equalsIgnoreCase(BILLING_CATEGORY_CPC)) {

            Boolean isExceedingBookedQuantity = false; // Sophal / 06.04.2021 / US-0009328

            if ((isUpdatedFromParent || changed) && (monthlyToUpdate.Booked_Quantity__c >= monthlyToUpdate.Delivered_Sum__c)) { // Sophal:28/06/2021: US-0009797 calculated only when Delivered_Sum__c is changed
                if (monthlyToUpdate.Invoice_Quantity__c != monthlyToUpdate.Monthly_Quantity__c) {
                    monthlyToUpdate.Invoice_Quantity__c = monthlyToUpdate.Monthly_Quantity__c;
                    changed = true;
                }
            }
            else if ((isUpdatedFromParent || changed) && (monthlyToUpdate.Booked_Quantity__c >= (monthlyToUpdate.Delivered_Sum__c - monthlyToUpdate.Monthly_Quantity__c))) { // US-0009797 calculated only when Delivered_Sum__c is changed
                // Sophal:25/03/2021: US-0008908  This is when (Delivered_Sum__c Not Including current iterated Monthly_Quantity__c) > Booked_Quantity__c

                // isExceedingBookedQuantity = true; // Sophal / 06.04.2021 / US-0009328 Booked Quantity has been exceeded.

                if (monthlyToUpdate.Invoice_Quantity__c != monthlyToUpdate.Booked_Quantity__c - (monthlyToUpdate.Delivered_Sum__c - monthlyToUpdate.Monthly_Quantity__c)) {
                    monthlyToUpdate.Invoice_Quantity__c = monthlyToUpdate.Booked_Quantity__c - (monthlyToUpdate.Delivered_Sum__c - monthlyToUpdate.Monthly_Quantity__c);
                    changed = true;
                }
            }
            else if((isUpdatedFromParent || changed) && monthlyToUpdate.Delivered_Sum__c > monthlyToUpdate.Booked_Quantity__c){ // Sophal:28/06/2021: US-0009797 calculated only when Delivered_Sum__c is changed

                // isExceedingBookedQuantity = true; // Sophal / 06.04.2021 / US-0009328 Booked Quantity has been exceeded.

                if (monthlyToUpdate.Invoice_Quantity__c != 0) {

                    // Sophal:25/03/2021: US-0008908 This is When (Delivered_Sum__c Including current iterated Monthly_Quantity__c) > Booked_Quantity__c
                    // Bascially Update Invoice_Quantity__c to 0 when Booked_Quantity__c is completely exceeded.
                    monthlyToUpdate.Invoice_Quantity__c = 0;
                    changed = true;
                }
            }

            totalInvoiceQty +=  (monthlyToUpdate.Invoice_Quantity__c != null ? monthlyToUpdate.Invoice_Quantity__c : 0); // Sophal:28/06/2021: US-0009797 // add current month's invoice qty after calculation to summary
            if(monthlyToUpdate.Booked_Quantity__c < totalInvoiceQty) isExceedingBookedQuantity = true;

            if(monthlyToUpdate.Is_Exceeding_BookedQuantity__c != isExceedingBookedQuantity){ // Sophal / 06.04.2021 / US-0009328
                monthlyToUpdate.Is_Exceeding_BookedQuantity__c = isExceedingBookedQuantity;
                changed = true;
            }

            
        }

        if (changed) {
            listMonthlyToUpdate.add(monthlyToUpdate);
        }

    }


    /*********************************************************************************************************************************
    @ Method:         prePopulateFields
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0009328 update Invoice_amount__c to Invoice_amount2__c. so Invoice_amount2__c can be used in Ad_product__c rollup summary field
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  08.04.2021 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    public static void prePopulateFields(List<Ad_Revenue_Monthly__c> listNewMonthly, Map<Id,Ad_Revenue_Monthly__c> mapOldMonthly){

        Boolean isInsert = mapOldMonthly == null ? true : false;

        for(Ad_Revenue_Monthly__c eachMonthly : listNewMonthly){

            if(isInsert || eachMonthly.Invoice_amount2__c != eachMonthly.Invoice_amount__c){
                eachMonthly.Invoice_amount2__c = eachMonthly.Invoice_amount__c;
            }
        }


    }


}