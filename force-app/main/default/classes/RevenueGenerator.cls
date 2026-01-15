/*********************************************************************************************************************************
@ Class:          RevenueGenerator
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0007980 Class for generating Ad_Revenue_Monthly__c and Ad_Revenue_Daily__c
@                 This class is based on logic of Methods in GW_IO class. They are :
@                 - public static void createRSDailyAndMonthly(List<IO_LineItem__c> IOlines)
@                 - public static void createRSDailyAndMonthly (Set<Id> sIO)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  21.08.2020 / Sophal Noch / Created the class. Run AdProductTriggerHandlerTest for test coverage
                   29.10.2020 / Sophal Noch / US-0008471 update the class.
                   11.05.2021 / Mony Nou / US-0009530 - Ads UAT Bug - Currency not transferred to Ad Revenue Monthly/Daily
                   26.05.2021 / Mony Nou / US-0009583 - Ads UAT Bug - Ad_Revenue_Monthly__c.Product__c not populated
                   05.11.2021 / Sophal Noch / US-0010628 - ADS - Allow edit rights on Revised Quote Line Items in past (with date validation)
                   20.07.2022 / Sophal Noch / US-0012062 - NA ADS - Monthly Forecasting Incorrect
                   29.07.2022 / Chetra Sarom / US-0009038 - Edit/ Delete line items with dates in the past
*********************************************************************************************************************************/
public without sharing class RevenueGenerator {


    private Map<Id,Ad_Product__c> mapAdProdForGenerating = new Map<Id,Ad_Product__c> ();

    private Map<Id, List<Ad_Revenue_Monthly__c>> mapAdProdToListMonthly = new Map<Id, List<Ad_Revenue_Monthly__c>>();
    private Map<Id, List<Ad_Revenue_Daily__c>> mapMonthlyToListDaily = new Map<Id, List<Ad_Revenue_Daily__c>>();


    private List<Ad_Revenue_Monthly__c> listMonthlyToUpsert = new List<Ad_Revenue_Monthly__c>();
    private List<Ad_Revenue_Monthly__c> listShortenMonthlyToDelete = new List<Ad_Revenue_Monthly__c>();

    private List<Ad_Revenue_Daily__c> listDailyToUpsert = new List<Ad_Revenue_Daily__c>();
    private List<Ad_Revenue_Daily__c> listShortenDailyToDelete = new List<Ad_Revenue_Daily__c>();

    private Boolean isUpdate = false;

    private Map<Id, Decimal> mapAdProdToSpentAmount = new Map<Id, Decimal>();
    private Map<Id, Date> mapAdProdIdToLatestDailyDate = new Map<Id, Date>();

    Date currentDate;

    // 20.07.2022 / Sophal Noch / US-0012062 : get pricebook from custom metadatatype for revised quote logic calculation
    private static final String ATC_PRICEBOOK_NAME = Label.ApexTestClass_Pricebook_Name;
    private static final Map<String, Set<String>> MAP_VALID_REVISED_QUOTE_PRICEBOOK {
        get{
            if(MAP_VALID_REVISED_QUOTE_PRICEBOOK == null){
                Map<String, Set<String>> mapValidReQuotePb = new Map<String, Set<String>>();
                for(RevisedQuote_Calculation_Pricebook__mdt pb : [Select Id, Label, Opp_RecTypeDevName__c From RevisedQuote_Calculation_Pricebook__mdt Where IsActive__c = true]){
                    Set<String> oppRecType = new Set<String>();
                    if(String.isBlank(pb.Opp_RecTypeDevName__c)) continue;
                    for(String rec : pb.Opp_RecTypeDevName__c.split(',')){
                        oppRecType.add(rec.trim());
                    }
                    mapValidReQuotePb.put(pb.Label, oppRecType);
                }
                MAP_VALID_REVISED_QUOTE_PRICEBOOK = mapValidReQuotePb;
            }
            return MAP_VALID_REVISED_QUOTE_PRICEBOOK;
        }
        set;
    }

    public RevenueGenerator(){
        // Run AdProductTriggerHandlerTest for test coverage
        currentDate = Date.today();
    }

    /*****************************************************************************************************************************
    @ Method:       filterRecords
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0007980 filter for only records that need to populate Ad_Revenue_Monthly__c and Ad_Revenue_Daily__c
    @ Event:		after RevenueGenerator is initialized
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  21.08.2020 / Sophal Noch / Created the method.
    @                  10.09.2021 / Sophal Noch / US-0010379 : not used anymore.
    @*****************************************************************************************************************************/
    // public RevenueGenerator filterRecords(List<Ad_Product__c> newAdProductList, Map<Id,Ad_Product__c> oldAdProductMap) {

    //     isUpdate = oldAdProductMap != null ? true : false;

    //     // US-0007980 : When users create Ad_Product__c with fields from_Date__c and until_Date__c not empty
    //     // Or When users update Ad_Product__c fields like from_Date__c, until_Date__c, TotalPrice__c with fields from_Date__c and until_Date__c not empty 
    //     // Those created or updated records are used to populate Ad_Revenue_Monthly__c and Ad_Revenue_Daily__c
    //     for(Ad_Product__c eachAdProduct : newAdProductList){

    //         if(
    //             eachAdProduct.from_Date__c != null && eachAdProduct.until_Date__c != null
    //             &&
    //             (
    //                 !isUpdate
    //                 || eachAdProduct.from_Date__c != oldAdProductMap.get(eachAdProduct.Id).from_Date__c
    //                 || eachAdProduct.until_Date__c != oldAdProductMap.get(eachAdProduct.Id).until_Date__c
    //                 || eachAdProduct.TotalPrice__c != oldAdProductMap.get(eachAdProduct.Id).TotalPrice__c
    //             )
    //         ){
                   
    //                 mapAdProdForGenerating.put(eachAdProduct.Id,eachAdProduct);
    //         }
    //     }


    //     return this;
    // }

    /*****************************************************************************************************************************
    @ Method:       setRecords
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0010379 - ADS - Bug, Quote cannot be made primary due to size
    @ Event:		after RevenueGenerator is initialized in trigger or in Queue
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	map of AdProduct__c records
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  10.09.2021 / Sophal Noch / US-0010379 set map Ad_Product__c with records coming from after-trigger or from QueueGenerateRevenue.cls
    @*****************************************************************************************************************************/
    public RevenueGenerator setRecords(Map<Id,Ad_Product__c> mapAdProdForGenerating) {
        this.mapAdProdForGenerating = mapAdProdForGenerating;
        return this;
    }


    /*****************************************************************************************************************************
    @ Method:       retrieveExistingAdRevenue
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0007980 get Ad_Revenue_Monthly__c records of Ad_Product__c and get Ad_Revenue_Daily__c record is child of Ad_Revenue_Monthly__c
    @ Event:		after records have been filter in method filterRecords
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  21.08.2020 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/

    public RevenueGenerator retrieveExistingAdRevenue(){

        // US-0007980 : when user update Ad_Product__c and that Ad_Product__c has child records like Ad_Revenue_Monthly__c and Ad_Revenue_Daily__c
        // the logic retrieve the existing child records, the records will be updated or deleted depending on its Unique_Key__c later.
        
        // if(isUpdate && !mapAdProdForGenerating.isEmpty()){
        if(!mapAdProdForGenerating.isEmpty()){ // 10.09.2021 / Sophal Noch / US-0010379

            Set<Id> adProductIds = mapAdProdForGenerating.keySet();

            Set<Id> setMonthlyId = new Set<Id> ();
            
            List<Ad_Revenue_Monthly__c> listMonthly = [SELECT Id, Unique_Key__c,Ad_Product__c,Transaction_Date__c,Amount__c FROM Ad_Revenue_Monthly__c Where Ad_Product__c IN: adProductIds Order By Transaction_Date__c ASC]; // Transaction_Date__c must be ASC
            
            if(!listMonthly.isEmpty()){

                for(Ad_Revenue_Monthly__c eachAdRevenueMonthly : listMonthly){

                    setMonthlyId.add(eachAdRevenueMonthly.Id);
                    
                    if(mapAdProdToListMonthly.containsKey(eachAdRevenueMonthly.Ad_Product__c)){
                        mapAdProdToListMonthly.get(eachAdRevenueMonthly.Ad_Product__c).add(eachAdRevenueMonthly);
                    }else{
                        mapAdProdToListMonthly.put(eachAdRevenueMonthly.Ad_Product__c, new List<Ad_Revenue_Monthly__c> {eachAdRevenueMonthly});
                    }
                }

            }

            if(!setMonthlyId.isEmpty()){

                List<Ad_Revenue_Daily__c> listDaily = [SELECT Id, Unique_Key__c,Ad_Product__c,Ad_Revenue_Monthly__c,Transaction_Date__c,Amount__c FROM Ad_Revenue_Daily__c Where Ad_Revenue_Monthly__c IN: setMonthlyId Order By Transaction_Date__c ASC]; // Transaction_Date__c must be ASC

                if(!listDaily.isEmpty()){
    
                    for(Ad_Revenue_Daily__c eachAdRevenueDaily : listDaily){
    
                        if(mapMonthlyToListDaily.containsKey(eachAdRevenueDaily.Ad_Revenue_Monthly__c)){
                            mapMonthlyToListDaily.get(eachAdRevenueDaily.Ad_Revenue_Monthly__c).add(eachAdRevenueDaily);
                        }else{
                            mapMonthlyToListDaily.put(eachAdRevenueDaily.Ad_Revenue_Monthly__c, new List<Ad_Revenue_Daily__c> {eachAdRevenueDaily});
                        }
    
                    }
    
                }
            }


            
        }
        


        return this;
    }

    /*****************************************************************************************************************************
    @ Method:       populateAdRevenue
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0007980 insert or update Ad_Revenue_Monthly__c and Ad_Revenue_Daily__c records and delete shorten records
    @ Event:		when Ad_Revenue_Monthly__c and Ad_Revenue_Daily__c are generated
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  21.08.2020 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/        
    public RevenueGenerator populateAdRevenue(){


        if(!mapAdProdForGenerating.isEmpty()){


            generateAdRevenueMonthly();

            if(!listShortenMonthlyToDelete.isEmpty()){
                delete listShortenMonthlyToDelete;
            }

            if(!listMonthlyToUpsert.isEmpty()){
                upsert listMonthlyToUpsert;
            }

            if(!listMonthlyToUpsert.isEmpty()){
                
                for(Ad_Revenue_Monthly__c eachAdRevenueMonthly : listMonthlyToUpsert){

                    generateAdRevenueDaily(eachAdRevenueMonthly);
                }

                if(!listShortenDailyToDelete.isEmpty()){
                    delete listShortenDailyToDelete;
                }

                if(!listDailyToUpsert.isEmpty()){
                    upsert listDailyToUpsert;
                }

            }

            

        }

        
        return this;
    }

    private void generateAdRevenueMonthly(){

        // 20.07.2022 / Sophal Noch / US-0012062  : store adproduct Id in a set for any adproduct that need to do revised quote calculation
        Boolean isRunningTest = Test.isRunningTest();
        Set<Id> setAdProdIdToDoRevQuoteCal = new Set<Id>();
        Map<Id,QuoteLineItem> mapQli = new Map<Id,QuoteLineItem>([Select Id, Quote.Pricebook2.Name, Quote.Opportunity.RecordType.DeveloperName From QuoteLineItem Where AdProduct__c In: mapAdProdForGenerating.keySet() And Quote.Is_Revised_Quote__c = true And Quote.Pricebook2Id != null And Quote.Opportunity.RecordTypeId != null]);
        if(!mapQli.isEmpty()){
            for(Ad_Product__c adProd : mapAdProdForGenerating.values()){
                QuoteLineItem qli = mapQli.get(adProd.Quote_Line_Item__c);
                if(qli == null) continue;
                String pricebookName = !isRunningTest ? qli.Quote.Pricebook2.Name : ATC_PRICEBOOK_NAME;
                Set<String> oppRecType = MAP_VALID_REVISED_QUOTE_PRICEBOOK.get(pricebookName);
                if(oppRecType != null && oppRecType.contains(qli.Quote.Opportunity.RecordType.DeveloperName)) setAdProdIdToDoRevQuoteCal.add(adProd.Id);
            }
        }

        // US-0007980 : Ad_Revenue_Monthly__c records are generated by the range between Ad_Product__c.from_Date__c and Ad_Product__c.until_Date__c
        // newly generated records that has the same Unique_Key__c as existing records will be updated
        // newly generated records that doesn't have the same Unique_Key__c as exsting records will be insert
        // existing records that has doesn't have Unique_Key__c in newly generated records will be deleted
        // newly generated records field Amount__c = Ad_Product__c.TotalPrice__c divide by the range of months.

        mapAdProdToSpentAmount = new Map<Id, Decimal>();

        for(Ad_Product__c eachAdProduct : mapAdProdForGenerating.values()) {

            // 29.07.2022 / Chetra Sarom / US-0009038 : user can decrease qli.enddate when qli.enddate is the past now so from_Date__c can be < current datae.
            Date pastDate = eachAdProduct.until_Date__c < currentDate ? eachAdProduct.until_Date__c : currentDate; // 05.11.2021 / Sophal Noch / US-0010628

            Map<String, Ad_Revenue_Monthly__c> mapExistMonthly = new Map<String, Ad_Revenue_Monthly__c>();

            Map<String, ExistingRevenue> mapMonthlyToSpendingDay = new Map<String, ExistingRevenue>();

            List<Ad_Revenue_Monthly__c> listMonthlyWithRevisedQ =  new List<Ad_Revenue_Monthly__c>();


            if(mapAdProdToListMonthly.containsKey(eachAdProduct.Id)){
               
                for(Ad_Revenue_Monthly__c eachExistMonthly : mapAdProdToListMonthly.get(eachAdProduct.Id)) {

                    if(eachExistMonthly.Unique_Key__c == null){continue;}

                    mapExistMonthly.put(eachExistMonthly.Unique_Key__c,eachExistMonthly);

                    // 20.07.2022 / Sophal Noch / US-0012062 : skip revised quote calculation for adproduct is not in set<Id> setAdProdIdToDoRevQuoteCal 
                    if(setAdProdIdToDoRevQuoteCal.isEmpty() || !setAdProdIdToDoRevQuoteCal.contains(eachAdProduct.Id)) continue;

                    // 29.10.2020 / Sophal Noch / US-0008471
                    // this happen when revised quote is set to primary.
                    // Quotelineitem will sync to AdProduct
                    if(eachAdProduct.Is_Revised_Quote__c && mapMonthlyToListDaily.containsKey(eachExistMonthly.Id)
                    ){
                        // 05.11.2021 / Sophal Noch / US-0010628 recalculate amount evenly in revenue when totalprice is changed for past adproduct
                        // if(eachAdProduct.until_Date__c == eachAdProduct.Prior_Until_Date__c && eachAdProduct.until_Date__c <= currentDate && eachAdProduct.TotalPrice__c != eachAdProduct.Prior_TotalPrice__c){continue;}
                        
                        // 29.07.2022 / Chetra Sarom / US-0009038 if TotalPrice__c is changed, revised quote calculation must not run, we do not need to keep old Revenue Amount.
                        if(eachAdProduct.TotalPrice__c != eachAdProduct.Prior_TotalPrice__c){continue;}

                        listMonthlyWithRevisedQ.add(eachExistMonthly);
                    }

                }

            }

            if(!listMonthlyWithRevisedQ.isEmpty()){

                // monthly and daily must come from query with Transaction_Date__c order by ASC

                for(Ad_Revenue_Monthly__c eachExistMonthly : listMonthlyWithRevisedQ){

                    for(Ad_Revenue_Daily__c eachExistDaily : mapMonthlyToListDaily.get(eachExistMonthly.Id)){
    
                        Decimal eachDailyAmount = eachExistDaily.Amount__c != null ? eachExistDaily.Amount__c : 0;
    
                        // 29.10.2020 / Sophal Noch / US-0008471 :
                        // if ad revenue daily Transaction_Date__c <= today, it mean ad revenue daily has been used.
                        // if(eachExistDaily.Transaction_Date__c <= currentDate){
                        // 29.07.2022 / Chetra Sarom / US-0009038 :
                        if(eachExistDaily.Transaction_Date__c <= pastDate){   

                            Decimal totalDailyAmountPerAdProd = eachDailyAmount;
    
                            if(mapAdProdToSpentAmount.containsKey(eachExistDaily.Ad_Product__c)){
                                totalDailyAmountPerAdProd = mapAdProdToSpentAmount.get(eachExistDaily.Ad_Product__c) + eachDailyAmount;
                            }

                            // 29.10.2020 / Sophal Noch / US-0008471 :
                            // get the ad product and its amount that its ad revenue daily has been used before today and today.
                            mapAdProdToSpentAmount.put(eachExistDaily.Ad_Product__c,totalDailyAmountPerAdProd);
                            
                            // 07.01.2021 / Sophal Noch / US-0008932 :
                            // if(eachExistDaily.Transaction_Date__c.toStartOfMonth() == currentDate.toStartOfMonth()){
                            // 29.07.2022 / Chetra Sarom / US-0009038 :
                            if(eachExistDaily.Transaction_Date__c.toStartOfMonth() == pastDate.toStartOfMonth()){

                                Integer numberOfDay = 1;
                                
                                Decimal totalDailyAmountPerMonth = eachDailyAmount;

                                if(mapMonthlyToSpendingDay.containsKey(eachExistMonthly.Unique_Key__c)){

                                    Integer spendingDays = mapMonthlyToSpendingDay.get(eachExistMonthly.Unique_Key__c).existingDays;
                                    numberOfDay = spendingDays + numberOfDay;
                                    totalDailyAmountPerMonth  = mapMonthlyToSpendingDay.get(eachExistMonthly.Unique_Key__c).existingAmount + eachDailyAmount;
                                }
                                mapMonthlyToSpendingDay.put(eachExistMonthly.Unique_Key__c,new ExistingRevenue(numberOfDay,totalDailyAmountPerMonth,eachExistDaily.Transaction_Date__c));
                                
                            }

                            // 05.11.2021 / Sophal Noch / US-0010628 map latest AdProduct Id to Latest Ad Revenue Daily Date
                            Date lastestDailyDate = mapAdProdIdToLatestDailyDate.get(eachExistDaily.Ad_Product__c);
                            if(lastestDailyDate == null || eachExistDaily.Transaction_Date__c > lastestDailyDate){
                                mapAdProdIdToLatestDailyDate.put(eachExistDaily.Ad_Product__c, eachExistDaily.Transaction_Date__c);
                            }

                        }
                        
                    }
                }
            }

            Date startDate = eachAdProduct.from_Date__c.toStartOfMonth();
            Integer totalMonth = startDate.monthsBetween(eachAdProduct.until_Date__c);

            Decimal dayAmount = 0;
                
            Decimal totalPrice = eachAdProduct.TotalPrice__c != null ? eachAdProduct.TotalPrice__c : 0;


            Date fromDate = eachAdProduct.from_Date__c;

            Date latestDailyDate = mapAdProdIdToLatestDailyDate.get(eachAdProduct.Id);
            Boolean isUsingLastestDailyDate = false;

            if(mapAdProdToSpentAmount.containsKey(eachAdProduct.Id)){

                // 29.10.2020 / Sophal Noch / US-0008471 :
                // if the related quote is revised and it is syned to ad product by get set to primary
                // and there is ad revenue dailys < today in this ad product,
                // from Date is count from tomorrow instead of Ad Product.From Date
                // because some ad revenue dailys have been used. 
                totalPrice = totalPrice - mapAdProdToSpentAmount.get(eachAdProduct.Id);
                fromDate = currentDate.addDays(1);

                // 05.11.2021 / Sophal Noch / US-0010628 use marked-as-primary date for remaining revenue month calculation
                if(eachAdProduct.MarkedPrimaryQuoteDate__c != null && latestDailyDate != null && latestDailyDate < currentDate
                ){
                    fromDate = eachAdProduct.MarkedPrimaryQuoteDate__c > latestDailyDate ? eachAdProduct.MarkedPrimaryQuoteDate__c : (latestDailyDate.addDays(1));
                    isUsingLastestDailyDate = true;
                }

                // 25.12.2020 / Sophal Noch / US-0008471,US-0008866 : fix divide by zero
                Integer numberOfDays = (fromDate.daysBetween(eachAdProduct.until_Date__c) + 1); 
                dayAmount = numberOfDays <= 0 ? 0 : (totalPrice / numberOfDays); 

            }else{
                Integer numberOfDays = (eachAdProduct.from_Date__c.daysBetween(eachAdProduct.until_Date__c) + 1);
                dayAmount = numberOfDays <= 0 ? 0 : (totalPrice / numberOfDays);   
            }

            for(Integer m = 0; m <= totalMonth; m++) {

                Date monthlyStartDate = startDate.addMonths(m).toStartOfMonth();

                if( monthlyStartDate >= eachAdProduct.from_Date__c.toStartOfMonth() && monthlyStartDate <= eachAdProduct.until_Date__c.toStartOfMonth() ){
                    
                    Ad_Revenue_Monthly__c adRevenueMonthly = new Ad_Revenue_Monthly__c();
                    adRevenueMonthly.Ad_Product__c = eachAdProduct.Id;

                    adRevenueMonthly.Transaction_Date__c = monthlyStartDate;
                    adRevenueMonthly.Unique_Key__c = getAdRevenueMonthlyUniqueKey(eachAdProduct,adRevenueMonthly);

                    Ad_Revenue_Monthly__c eachExistMonthly = mapExistMonthly.get(adRevenueMonthly.Unique_Key__c);
                    
                    Decimal mAmount = 0;

                    // 07.01.2021 / Sophal Noch / US-0008932 :
                    if(mapMonthlyToSpendingDay.containsKey(adRevenueMonthly.Unique_Key__c)){

                        //  US-0008932 : get current month has revenue daily already in the past
                        ExistingRevenue existingMonth = mapMonthlyToSpendingDay.get(adRevenueMonthly.Unique_Key__c);

                        Integer daysInTheMonth = Date.daysInMonth(adRevenueMonthly.Transaction_Date__c.year(), adRevenueMonthly.Transaction_Date__c.month());
                        Date endOfTheMonth = Date.newInstance(adRevenueMonthly.Transaction_Date__c.year(), adRevenueMonthly.Transaction_Date__c.month(),daysInTheMonth);
                        if(endOfTheMonth > eachAdProduct.until_Date__c){endOfTheMonth = eachAdProduct.until_Date__c;} // US-0008932 : if the date of the date must not be above ad product.until date

                        // US-0008932 : get the day after latest date of the month which current date is in
                        Date nextDayOfLatestDate = existingMonth.latestDate.addDays(1);

                        // 05.11.2021 / Sophal Noch / US-0010628 use fromDate for remaining month calculation
                        if(isUsingLastestDailyDate){nextDayOfLatestDate = fromDate;}

                        Integer numberOfDays = (nextDayOfLatestDate.daysBetween(endOfTheMonth) + 1); 
                        if(numberOfDays > 0){mAmount = dayAmount * numberOfDays;}
                        adRevenueMonthly.Amount__c = existingMonth.existingAmount + (mAmount < 0 ? 0 : mAmount);
                        
                    }else{

                        // 05.11.2021 / Sophal Noch / US-0010628 keep orignal amount value for exisiting revenue monthly
                        Date latestExisingMonth = isUsingLastestDailyDate ? latestDailyDate.toStartOfMonth() : currentDate.toStartOfMonth();

                        if(mapAdProdToSpentAmount.containsKey(eachAdProduct.Id) && monthlyStartDate.toStartOfMonth() <= latestExisingMonth){

                            // 29.10.2020 / Sophal Noch / US-0008471 :
                            // there is ad revnue daily used in this ad product but today > date of exist ad revenue monthly, don't update the amount
                            // but if ad revenue monthly doesn't exist previously, update amount to 0
                            if(eachExistMonthly == null){adRevenueMonthly.Amount__c = 0;}
                        }else{
                            // 29.10.2020 / Sophal Noch / US-0008471 :
                            // update ad revenue monthly as ususal
                            mAmount = dayAmount * getDaysPerMonth(monthlyStartDate, fromDate, eachAdProduct.until_Date__c);
                            adRevenueMonthly.Amount__c = mAmount;
                        }
                        
                    }
                    
                    adRevenueMonthly.Opportunity__c = eachAdProduct.Opportunity__c;
 
                    if(eachExistMonthly != null){
                        adRevenueMonthly.Id = eachExistMonthly.Id;
                        mapExistMonthly.remove(adRevenueMonthly.Unique_Key__c);
                    }

                    //MN-11052021 - Sync Currency from AdProduct to AdRevenueMonly
                    adRevenueMonthly.CurrencyIsoCode = eachAdProduct.CurrencyIsoCode;


                    //MN-26052021 - US-0009583 - Sync Product__c from AdProduct to AdRevenueMonly
                    adRevenueMonthly.Product__c = eachAdProduct.Product2__c;


                    listMonthlyToUpsert.add(adRevenueMonthly);

                }

            }

            if(!mapExistMonthly.isEmpty()){
                listShortenMonthlyToDelete.addAll(mapExistMonthly.values());
            }


        }
        
       
    }


    private void generateAdRevenueDaily(Ad_Revenue_Monthly__c eachAdRevenueMonthly){

        // US-0007980 : Ad_Revenue_Daily__c records are generated by the range between days in Month of Ad_Revenue_Monthly__c.Transaction_Date__c
        // newly generated records that has the same Unique_Key__c as existing records will be updated
        // newly generated records that doesn't have the same Unique_Key__c as exsting records will be insert
        // existing records that has doesn't have Unique_Key__c in newly generated records will be deleted
        // newly generated records field Ad_Revenue_Daily__c = Ad_Revenue_Monthly__c.Amount__c divide by the range of days.


        Ad_Product__c adProduct = mapAdProdForGenerating.get(eachAdRevenueMonthly.Ad_Product__c);

        Integer year = eachAdRevenueMonthly.Transaction_Date__c.year();
        Integer month = eachAdRevenueMonthly.Transaction_Date__c.month();
        Integer daysOfMonth = Date.daysInMonth( year, month);

        Integer startDate = Date.newInstance( year, month, 1) > adProduct.from_Date__c ? 1: adProduct.from_Date__c.day();
        Integer endDate = Date.newInstance( year, month, daysOfMonth) < adProduct.until_Date__c ? daysOfMonth : adProduct.until_Date__c.day();

        Decimal dayAmount = 0;
        Decimal totalPrice = adProduct.TotalPrice__c != null ? adProduct.TotalPrice__c : 0;
        Boolean isHavingNoSpendAmount = false;

        Date latestDailyDate = mapAdProdIdToLatestDailyDate.get(adProduct.Id);
        Boolean isUsingLastestDailyDate = false;
        
        Date fromDate = currentDate.addDays(1);
        if(mapAdProdToSpentAmount.containsKey(adProduct.Id)){

            // 29.10.2020 / Sophal Noch / US-0008471 :
            // if the related quote is revised and it is syned to ad product by get set to primary
            // and there is ad revenue dailys < today in this ad product,
            // from Date is count from tomorrow instead of Ad Product.From Date
            // because some ad revenue dailys have been used. 
            isHavingNoSpendAmount = true;
            totalPrice = totalPrice - mapAdProdToSpentAmount.get(adProduct.Id);
            // Date fromDate = currentDate.addDays(1);

            // 05.11.2021 / Sophal Noch / US-0010628 use marked-as-primary date for remaining revenue daily calculation
            if(adProduct.MarkedPrimaryQuoteDate__c != null && latestDailyDate != null && latestDailyDate < currentDate){
                fromDate = adProduct.MarkedPrimaryQuoteDate__c > latestDailyDate ? adProduct.MarkedPrimaryQuoteDate__c : (latestDailyDate.addDays(1));
                isUsingLastestDailyDate = true;
            }

            Integer numberOfDays = (fromDate.daysBetween(adProduct.until_Date__c) + 1); // 26.07.2021 / Sophal Noch / US-0010005 fix 'divided by zero'
            dayAmount = numberOfDays <= 0 ? 0 : (totalPrice / numberOfDays);
        }else{
            Integer numberOfDays = (adProduct.from_Date__c.daysBetween(adProduct.until_Date__c) + 1); // 26.07.2021 / Sophal Noch / US-0010005 fix 'divided by zero'
            dayAmount = numberOfDays <= 0 ? 0 : (totalPrice / numberOfDays);
        }

        Map<String,Ad_Revenue_Daily__c> mapExistDaily = new Map<String,Ad_Revenue_Daily__c>();
        if(mapMonthlyToListDaily.containsKey(eachAdRevenueMonthly.Id)){

            for(Ad_Revenue_Daily__c eachExistDaily : mapMonthlyToListDaily.get(eachAdRevenueMonthly.Id)){

                if(eachExistDaily.Unique_Key__c != null){
                    mapExistDaily.put(eachExistDaily.Unique_Key__c,eachExistDaily);
                }

                
            }
        }

        for(Integer day = startDate; day <= endDate; day++) {

            Ad_Revenue_Daily__c adRevenueDaily = new Ad_Revenue_Daily__c();
            adRevenueDaily.Ad_Revenue_Monthly__c = eachAdRevenueMonthly.Id;
            adRevenueDaily.Opportunity__c = eachAdRevenueMonthly.Opportunity__c; //US-0008792
            adRevenueDaily.Ad_Product__c = adProduct.Id;

            adRevenueDaily.Transaction_Date__c = Date.newInstance( year, month, day);
            adRevenueDaily.Unique_Key__c = getAdRevenueDailyUniqueKey(adRevenueDaily);

            Ad_Revenue_Daily__c eachExistDaily = mapExistDaily.get(adRevenueDaily.Unique_Key__c);
        
            if(
                !isHavingNoSpendAmount
                // || (isHavingNoSpendAmount && adRevenueDaily.Transaction_Date__c > currentDate)
                || (isHavingNoSpendAmount && adRevenueDaily.Transaction_Date__c >= fromDate) // 05.11.2021 / Sophal Noch / US-0010628 set amount for daily revenues that are not exising daily revenues
            ){
                // 29.10.2020 / Sophal Noch / US-0008471 :
                // update amount as ususal is there are no previous ad revenue daily used.
                // still update amount too if there are previous ad revenue daily used but Transaction_Date__c > today
                adRevenueDaily.Amount__c = (dayAmount < 0 ? 0 : dayAmount);
            }else if(eachExistDaily == null){
                // 29.10.2020 / Sophal Noch / US-0008471 :
                // update amount to 0 if there are previous used but ad revenue daily doesn't exist previously.
                adRevenueDaily.Amount__c = 0;
            }
           
            if(eachExistDaily != null){
                adRevenueDaily.Id = eachExistDaily.Id;
                mapExistDaily.remove(adRevenueDaily.Unique_Key__c);
            }
            
            //MN-11052021 - Sync Currency from AdProduct to AdRevenueDaily
            adRevenueDaily.CurrencyIsoCode = adProduct.CurrencyIsoCode;

            listDailyToUpsert.add(adRevenueDaily);

        }


        if(!mapExistDaily.isEmpty()){
            listShortenDailyToDelete.addAll(mapExistDaily.values());
        }

    }


    private String getAdRevenueMonthlyUniqueKey(Ad_Product__c eachAdProduct, Ad_Revenue_Monthly__c eachAdRevenueMonthly){
        // 29.10.2020 / Sophal Noch / US-0008471 : remove product2Id from this unique key generation
        // because it helps identify ad revenue monthly whether its ad product has product2 or not.
        return String.valueOf(eachAdProduct.Id) + '_' + eachAdRevenueMonthly.Transaction_Date__c.year() + '_' + eachAdRevenueMonthly.Transaction_Date__c.month();
    }

    private String getAdRevenueDailyUniqueKey(Ad_Revenue_Daily__c eachAdRevenueDaily){
        String uniqueKey = String.valueOf(eachAdRevenueDaily.Ad_Revenue_Monthly__c);
        uniqueKey =   uniqueKey +  '_' + eachAdRevenueDaily.Transaction_Date__c.month()  + '_' + eachAdRevenueDaily.Transaction_Date__c.day();
        return uniqueKey;
    }

    //US-0007980 copy logic from GW_IO.getDaysPerMonth
    private Integer getDaysPerMonth (Date startOfMonth, Date adProdStartDate, Date adProdEndDate) {

        /*Find the exact number of days for Ad_product__c.StartDate.StartMonth and Ad_product__c.EndDate.StartMonth. The months in between will be get full days/month
            EX: Ad_product__c.StartDate = 15/Sep/2019 -> Ad_product__c.EndDate = 15/Nov/2019 => 
                - September = 15 days (need to calculate the exact number of days)
                - October = 31 days (full no need to calculate)
                - November = 15 days (need to calculate the exact number of days)
        */

        Integer numOfDays = 0;
        Integer daysInMonth = Date.daysInMonth(startOfMonth.year(), startOfMonth.month());
        Date endOfMonth = Date.newInstance(startOfMonth.year(), startOfMonth.month(), daysInMonth);

        //Check if Ad_product__c.StartDate is the same month as Ad_product__c.EndDate
        if (adProdStartDate.month() == adProdEndDate.month()) numOfDays = adProdStartDate.daysBetween(adProdEndDate) + 1;
        //Check if it is the StartMonth of Ad_product__c.StartDate
        else if (startOfMonth.month() == adProdStartDate.month()) numOfDays = adProdStartDate.daysBetween(endOfMonth) + 1;
        //Check if it is the StartMonth of Ad_product__c.EndDate
        else if (startOfMonth.month() == adProdEndDate.month()) numOfDays = startOfMonth.daysBetween(adProdEndDate) + 1;
        //For middle months
        else numOfDays = startOfMonth.daysBetween(endOfMonth) + 1;
        
        return numOfDays;

    }

    // US-0008932 :
    public class ExistingRevenue{
        Integer existingDays;
        Decimal existingAmount;
        Date latestDate; 
        public ExistingRevenue(Integer existingDays, Decimal existingAmount, Date latestDate){
            this.existingDays = existingDays;
            this.existingAmount = existingAmount;
            this.latestDate = latestDate;
        }
    }

    
}