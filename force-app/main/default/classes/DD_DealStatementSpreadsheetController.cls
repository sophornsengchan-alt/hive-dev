/**
Changes:
#21880--comment#21
Date:16-12-2019
Have a couple of additions to make to the spreadsheet generation:

Need to create an ebay review worksheet like the one in the spreadsheet this should only be created if a Deal Statement was disputed ie Case related to Deal Statement
Columns should be in field set by default should show Listing Id, Item Title, Deal State Date/Time, Deal End Date/Time, Subsidy, Final Sold Items, Dispute Type.
If Dispute Type = 'Quantity Variance' show Sellers Dispute Quantity, Sold Items Disputes, Dispute Approval Comments
If Dispute Type = 'Subsidy Per Unit' show Sellers Dispute Subsidy, Subsidy per Unit Disputes, Dispute Approval Comments
If Dispute Type = 'Quantity Variance & Subsidy per Unit' show Sellers Dispute Quantity, Sold Items Disputes, Sellers Dispute Subsidy, Subsidy Per Unit Disputes, Dispute Approval Comments
If Sold Items Further Disputes is populated show after Sold Items Disputes
If Subsidy per Unit Further Disputes is populated show after Subsidy per Unit Disputes
On main worksheet need to add a couple of more subtotals at the bottom of the current subtotals
If Dispute Payout != null or != 0 then show Subtotal title Month + 'Dispute Adjustment Paid' then in the numbers column show Dispute Payout amount
If Further Dispute Payout != null or != 0 then show Subtotal title Month + Further Dispute Adjustment Paid' then in the numbers column show Further Dispute Payout amount
I assume already but Total amount should be a calculation of Total Paid Out
*/
/*********************************************************************************************************************************
@ Class:          DD_DealStatementSpreadsheetController
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        US-0008785 - [NA] Resend Deal Statements to Seller
@                 Migrated from Join-instance
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 08.01.2021 / Vadhanak Voun / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@               :  11.10.2021 / Mony Nou / US-0010374 - [NA Deal Statement] Adjusted Statement Generation
@               :  06.04.2022 / Loumang SENG / US-0011117 - NA Reconciliation & Statement Processes modifications
@               :  17.05.2022 / Sophal Noch / US-0011767 - NA Adjusted Statement generation (continuation)
@               : 18.05.023 / Sovantheany Dim / US-0013550 - 4. Deal Statement xl sheet is generated which can be shared with the Seller
@               : 17.10.2023 / SRONG TIN / US-0014159 - Include more fields for NA/IT Deals Statement
@               : 17.01.2024 / SRONG TIN / US-0014459 - NA Region (CA): Update Statement Generation Cycle for Canada
@               : 12.03.2024 / Mony Nou / US-0014785 - NA Region (US Only): Update 1st and Final (2nd) deal statement to accommodate for the introduction of Subsidy%
@               : 18.03.2024 / Mony Nou / US-0014789 - NA Region (US Only): Update Deals Subsidy Adjusted Statement to accommodate for the introduction of Subsidy%
@               : 18.03.2024 / Mony Nou / US-0014820 - NA Region (US Only): Update calculation logic for ‘Subsidy Adjusted Calculation’ & ‘Adjusted Payout’ field on deal statement to account for subsidy% calculation
@               : 04.04.2024 / Mony Nou / US-0015071 - NA Region (US Only): Update field Mapping for Deal Statements (First, Final, Adjusted) to accommodate for the introduction of Subsidy%
@               : 05.04.2024 / Mony Nou / US-0015079 - NA Region (US Only): Remap mapping for Deal Statements (First, Final, Adjusted) for sold item at deal price
@               : 18.04.2024 / Mony Nou / US-0015168 - NA percentage Deals - adjustment statement
@               : 10.12.2024 / Loumang SENG / US-0016250 - Deal Payment disputes from CA users should be routed to a new DL
@               : 13.03.2025 / vadhanak voun / US-0016842 - Based on the Contract Amendment New Process - Deal Statement for Seller
*********************************************************************************************************************************/
public Without sharing class DD_DealStatementSpreadsheetController {
    private static Deal_Statement_Setting__c ds_setting = Deal_Statement_Setting__c.getOrgDefaults();
    private static Map<String,String> id2Value;
    public string xmlheader {get;set;}
    public string sellerName {get;set;}
    public string endfile{get;set;}  
    public DtoDealSheet dealList {get;set;}

    // 20.05.2021 / Sophal Noch / US-0009544 to highligh row (by cell) with color striped
    public Integer spdIndex {get;set;}
    public Integer erIndex  {get;set;}
    public Integer dealIndex  {get;set;}

    public Integer[] spdRow {get;set;}
    public Integer[] erRow {get;set;}

    public final static string CACHE_PARAM = 'useCache';

    public final static string DS_CACHE_KEY = 'local.DealStatementSpreadsheetCache.ds';
    public final static string DEALS_CACHE_KEY = 'local.DealStatementSpreadsheetCache.listDeal';
     
    private final static String PLV_ADJUS_STATEM = 'In Dispute'; //MN-12102021-US-0010374
    
    // 17.05.2022 / Sophal Noch / US-0011767 - NA Adjusted Statement generation (continuation)
    private final static String PLV_ADJUS_STATEM_APPROVAL = 'In Dispute Payout Approval';
    private final static String PLV_ADJUS_STATEM_APPROVED = 'Dispute Payout Approved';
    private final static String PLV_ADJUS_STATEM_SENTOUT = 'Dispute Statement Sent Out';
    private final static Set<String> SET_PLV_ADJUS_STATEM = new Set<String>{PLV_ADJUS_STATEM,PLV_ADJUS_STATEM_APPROVAL,PLV_ADJUS_STATEM_APPROVED,PLV_ADJUS_STATEM_SENTOUT};

    private final static String RT_DEAL_V2 = 'Deal_V2'; //MN-04042024-US-0015071
    private final static String HIDEN_SHEET = 'SheetHidden';//LA-06-04-2022:US-0011117
    private final static String VISIBLE_SHEET = 'SheetVisible';//LA-06-04-2022:US-0011117
    private final static String PLACEHOLDER = '[PLACEHOLDER]';
    private final static String curFormatText = '_("' + PLACEHOLDER + '"* #,##0.00_);_("' + PLACEHOLDER + '"* \\(#,##0.00\\);_("' + PLACEHOLDER + '"* "-"??_);_(@_)';
    private final static String SOQL_DEAL_STATEMENT = 'Select Site__c,RecordType.DeveloperName,MostRecentFirstStatement__c,MostRecentFinalStatement__c,MostRecentAdjustStatement__c,Second_Payout__c,Disputes_Payout__c,Further_Dispute_Payout__c,Id,Name,eBay_Seller__c,eBay_Seller__r.Name,Month__c, Year__c, Status__c from deal_statement__c';

    public static Map<String,String> mapSite_CurrencyCode= new Map<String,String>
    {   
        '101'=>'EUR',//IT
        '0'=>'USD'//US
    };
    public String numberFormat{
        get{
            return '_(* #,##0.00_);_(* \\(#,##0.00\\);_(* "-"??_);_(@_)';
        }
    }
    
    public String currencyFormat{
        get{
            //TH:US-0013550
            return checkCurrencyFormat(curFormatText);
            
        }
    }
    
    public String swissFormat{
        get{
            //TH:US-0013550
            return checkCurrencyFormat(curFormatText);
            
        }
    }

     //TH:US-0013550
    private String checkCurrencyFormat(String formatText){
        String currCode = (mapSite_CurrencyCode.containsKey(dealList.ds.Site__c))?mapSite_CurrencyCode.get(dealList.ds.Site__c):'';
        String curSign =  (ApexUtil.mapCurrencySign.containsKey(currCode))?ApexUtil.mapCurrencySign.get(currCode):'$';
        return formatText.replace(PLACEHOLDER, curSign);
    }
       
    @AuraEnabled
    public static Map<String, Object> doGenerateSpeedsheet(String recordId){
        try{
            //System.debug('DS Id:'+recordId);
            Map<String, Object> mpRes = new Map<String, Object>{'isSuccess' => true, 'message'=> 'success'};
            //NK:US-0008785: also added missing fields in the query
            // 20.05.2021 / Sophal Noch / US-0009544 Query eBay_Seller__r.Name,
            //MN-15102021-US-0010374 - Add MostRecentAdjustStatement__c into query
            //LA-22-02-2023-US-0012687- Add RecordType.DeveloperName into query
            //Start-LA-10.12.2024-US-0016250- Add Site__c into query and fix ApexCRUDViolation
            String sWhere = ' where id=:recordId';
            List<Deal_Statement__c> lstDS = ApexSafe.query().doQuery(SOQL_DEAL_STATEMENT+sWhere,new Map<String, Object> {'recordId' => recordId});
            //for(Deal_Statement__c ds:[Select Site__c,RecordType.DeveloperName,MostRecentFirstStatement__c,MostRecentFinalStatement__c,MostRecentAdjustStatement__c,Second_Payout__c,Disputes_Payout__c,Further_Dispute_Payout__c,Id,Name,eBay_Seller__c,eBay_Seller__r.Name,Month__c, Year__c, Status__c from deal_statement__c where id=:recordId]){
            for(Deal_Statement__c ds : lstDS){ //END-LA-10.12.2024-US-0016250  
                DD_DealStatementSpreadsheetBatch.doGenerateSpeedsheet(ds);
            }
            return mpRes;
        } catch(Exception ex) {
            System.debug(ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }
   
    public static Map<String,String> monthId2Value(){
        if(id2Value==null){
             id2Value = new Map<String,String>();
            Schema.DescribeFieldResult fieldResult = Deal_Statement__c.Month__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pick : ple){
                id2Value.put(pick.getValue(),pick.getLabel());
            }     
        }
        return id2Value;
    }
    
    public static String getMonthLabel(String id){
        return monthId2Value().get(id);
    }
   
    public DD_DealStatementSpreadsheetController() {

        String dsIdParm = String.escapeSingleQuotes(Apexpages.currentPage().getParameters().get('id'));
        // System.debug('nsp: dsIdParm '+dsIdParm);

        String cacheParam = Apexpages.currentPage().getParameters().get(CACHE_PARAM);
        Boolean useCache = cacheParam != null ? Boolean.valueOf(cacheParam) : false;
        //System.debug('nsp: cacheParam '+cacheParam);

        //VF page gives some issues directly using the below code there, so wrap up in variable    
        xmlheader ='<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        // System.debug('nsp: Cache.Org.get(DS_CACHE_KEY) == '+Cache.Org.get(DS_CACHE_KEY));

        Boolean skippedNextCache = false;

        Deal_Statement__c ds;
        // 05.05.2021 / Sophal Noch / US-0009424 use cache so it is not using DML because It calls from loop in trigger
        if(useCache){
             // 20.05.2021 / Sophal Noch / US-0009544 group cache by deal statement id
            ds =  ((Deal_Statement__c)(Cache.Org.get(DS_CACHE_KEY + dsIdParm)));
            skippedNextCache = ds == null ? true : false;
        }

        // System.debug('nsp: ds == '+ds);
        // System.debug('nsp: ds name == '+ds.Name);

        List<EBH_Deal__c> dsDeals;
        // 05.05.2021 / Sophal Noch / US-0009424 use cache so it is not using DML because It calls from loop in trigger
        if(!skippedNextCache && useCache){
            dsDeals = ((List<EBH_Deal__c>)(Cache.Org.get(DEALS_CACHE_KEY +  dsIdParm)));
            dsDeals = dsDeals == null ? new List<EBH_Deal__c>() : dsDeals;
        }

        // System.debug('nsp: dsDeals == '+dsDeals);

        // dealList = getDeals(controller.getRecord().Id);
        // 05.05.2021 / Sophal Noch / US-0009424 use parameter so it is not using DML because It calls from loop in trigger
        dealList = getDeals(dsIdParm, ds, dsDeals);
        spdRow = new Integer[]{};
        erRow = new Integer[]{};
        for(Integer i = 0; i < 20; i++){
            spdRow.add(0);
            erRow.add(0);
        }

    }

    //MN-15102021-US-0010374 - Update the recalculate Adjust Payout to DS back
    public void updateAdjustPayout() {
        
        
        if (this.dealList.isAdjustStatement) {
            
            Deal_Statement__c ds = new Deal_Statement__c(
                Id = this.dealList.ds.Id,
                SubsidyAdjustedCalculation__c = this.dealList.total,
                Disputes_Payout__c = this.dealList.currentPay

            );

            update ds;

        }
    }
    
    public static DtoDealSheet getDeals(Id dsId, Deal_Statement__c ds, List<EBH_Deal__c> dsDeals){

        ds = ds == null ? queryDealStatement(new Set<Id>{dsId}).get(dsId) : ds;

        return new DtoDealSheet(ds, dsDeals);
    }
    
    public class DealDTO{
        public String eBayItemId{get;set;}
        public String productTitle{get;set;}
        public DateTime startTime{get;set;}
        public DateTime endTime{get;set;}
        public Double subsidy{get;set;}
        //SRONG​:17.10.2023/US-0014159        
        public Double soldItemsTotal{get;set;}
        public Double soldItemsDealPrice{get;set;}
        public Double payoutSoldItems{get;set;}
        public Double nonPayoutSoldItems{get;set;}
        // end US-0014159
        public Double finalSoldItems{get;set;}
        public Double netSubsidyAmount{get;set;}
        public Boolean isSelected{get;set;}
        public Double eppFinalUnitsSold{get;set;}  // 20.05.2021 / Sophal Noch / US-0009544 new field on excel
        public Double spFinalUnitsSold{get;set;} // 20.05.2021 / Sophal Noch / US-0009544 new field on excel
        public Double ebayReview{get;set;} // 20.05.2021 / Sophal Noch / US-0009544 new field on excel
        public String comments{get;set;} // 20.05.2021 / Sophal Noch / US-0009544 new field on excel
        public Double ppFinalUnitSold{get;set;}
        public EBH_Deal__c deal{get;set;}

        public Double adjustedUnits {get;set;} //MN-12102021-US-0010374

        public Double epppAmount {get;set;} //MN-15032024-US-0014785: for column eBay Prior Proposed Amount
        public Boolean isSubTypePer {get;set;} //MN-18032024-US-0014789: TRUE if Subsidy Type = Percentage
        public Double netAdjustedPayout {get;set;} //MN-18032024-US-0014820 calculation of adjusted payout for each deal

        public Boolean isDealV2 {get;set;} //MN-04042024-US-0015071: TRUE if Deal is Deal V2

        public DealDTO(EBH_Deal__c deal){
            this.deal = deal;
            this.eBayItemId = deal.EBH_eBayItemID__c;
            this.productTitle = deal.EBH_ProductTitle__c;
            if(deal.EBH_DealStartDate__c!=null && deal.EBH_DealStartTime__c!=null ){
                this.startTime=DateTime.newInstanceGMT(deal.EBH_DealStartDate__c, deal.EBH_DealStartTime__c);
            }
            if(deal.EBH_DealEndTime__c!=null && deal.EBH_DealEndDate__c!=null ){
                this.endTime=DateTime.newInstanceGMT(deal.EBH_DealEndDate__c, deal.EBH_DealEndTime__c);
            }
            this.subsidy = deal.EBH_Subsidy__c;
            //SRONG​:17.10.2023/US-0014159
            this.soldItemsTotal = deal.EBH_SoldItems__c;
            this.soldItemsDealPrice = deal.EBH_Sold_Items_at_Deal_Price__c;
            this.payoutSoldItems = deal.EBH_Payout_SI_calc__c;
            this.nonPayoutSoldItems = deal.EBH_NonPayoutSI__c;

            // this.finalSoldItems=deal.Final_Sold_Items__c;
            this.finalSoldItems = deal.EBH_Payout_SI_calc__c; // 17.05.2021 / Sophal Noch / US-0009536
            // this.eppFinalUnitsSold = this.finalSoldItems; // 26.05.2021 / Sophal Noch / US-0009544
            if(deal.Sold_Items_Disputes__c != null)this.finalSoldItems+=deal.Sold_Items_Disputes__c;
            if(deal.Sold_Items_Further_Disputes__c != null)this.finalSoldItems+=deal.Sold_Items_Further_Disputes__c;
            // this.netSubsidyAmount=deal.Net_Subsidy_Amount__c; 
            // this.netSubsidyAmount=deal.X1st_Payout_Amount__c; // 17.05.2021 / Sophal Noch / US-0009536
            this.netSubsidyAmount=deal.EBH_SubsidyFinal__c; // 11.06.2021 / Sophal Noch / US-0009686
            if(deal.Subsidy_Due_Disputes__c != null)this.netSubsidyAmount+=deal.Subsidy_Due_Disputes__c;
            if(deal.Subsidy_Due_Further_Dispute__c != null)this.netSubsidyAmount+=deal.Subsidy_Due_Further_Dispute__c;          
            this.isSelected = false;

            this.adjustedUnits = deal.AdjustedSoldItems__c; //MN-12102021-US-0010374
            this.comments = deal.eBayReviewComments__c; //LA-06-04-2022:US-0011117
            // this.ebayReview = deal.Seller_s_Dispute_Quantity__c; //LA-06-04-2022:US-0011117
            this.ebayReview = this.finalSoldItems; // 17.05.2022 / Sophal Noch / US-0011767
            this.spFinalUnitsSold = deal.Seller_s_Dispute_Quantity__c; //LA-06-04-2022:US-0011117
            this.ppFinalUnitSold = deal.EBH_Payout_SI_calc__c - (deal.AdjustedSoldItems__c != null ? deal.AdjustedSoldItems__c : 0); // 17.05.2022 / Sophal Noch / US-0011767

            //MN-15032024-US-0014785
            this.epppAmount = (deal.X1st_Payout_Amount__c != null? deal.X1st_Payout_Amount__c : 0) + (deal.X2nd_Payout_Amount__c != null ? deal.X2nd_Payout_Amount__c:0);

            this.isSubTypePer = (String.isNotBlank(deal.Subsidy_Type__c) && deal.Subsidy_Type__c == 'Percentage'); //MN-18032024-US-0014789

            //MN-18032024-US-0014820 -- START:
            Double adjusted_units = (deal.AdjustedSoldItems__c != null ? deal.AdjustedSoldItems__c : 0);
            Double total_adjusted_amount = (deal.TotalAdjustedAmount__c != null ? deal.TotalAdjustedAmount__c : 0);
            this.netAdjustedPayout = (isSubTypePer)?(adjusted_units * this.subsidy) + total_adjusted_amount:0; //(Column "Subsidy Per Unit" * Column "Adjusted Units") + Column "Total Adjusted Amount"
            //--END

            this.isDealV2 = (deal.RecordType.DeveloperName == RT_DEAL_V2); //MN-04042024-US-0015071

        }
    }
    public class DtoDealSheet{
        public DateTime lastStatementSentOut{get;set;}
        public Double total{get;set;}
        public List<List<DealDTO>> deals{get;set;}
        public List<DealDTO> diputes{get;set;}
        public Double totalItem{get;set;}
        //public String logo{get;set;}
        public String month{get;set;}
        public Boolean isSecondPay{get;set;}
        public Boolean isDisputePay{get;set;}        
        public Boolean isFurtherDisputePay{get;set;}        
        public Deal_Statement__c ds{get;set;}
        public Boolean isQuantityVariance{get;set;}
        public Boolean isSubsidyPerUnit{get;set;}
        public Boolean isQtyVarianceAndSubPerUnit{get;set;}
        public Boolean isHasSoldItemFurtherDisputes{get;set;}
        public Boolean isHsSubsidyPerUnitFurtherDisputes{get;set;}

        public Boolean isAdjustStatement {get;set;} //MN-12102021-US-0010374
        public Double totalForAdjustState {get;set;} //MN-13102021-US-0010374
        public String ebayReviewVisible{get;set;} //LA-06-04-2022:US-0011117
        public String paymentDisputeVisible{get;set;} //TH-18-05-2023:US-0013550
        public String sellerPaymentVisible{get;set;} //TH-18-05-2023:US-0013550
        public Boolean isIT {get;set;} //TH:US-0013550
        public Boolean isUS {get;set;} //SRO:US-0014159 
        public Boolean isCA {get;set;} //SRO:US-0014459
        public String ds_Lang {get; set;} //TH:US-0013550
        public String monthIT{get;set;}//TH:US-0013550
        public String year{get;set;}//TH:US-0013550

        public Double totalAdjustedAmount {get;set;} //MN-18032024-US-0014789
        public Boolean hasDealWithSubTypePer {get;set;} //MN-18032024-US-0014789
        public Double totalAdjustedPayout {get;set;} //MN-18032024-US-
        
        public Boolean isSubDeal {get;set;} //NK:14/02/2025:US-0016842

        public DtoDealSheet(Deal_Statement__c ds, List<EBH_Deal__c> dsDeals){
            this.ds = ds;

            // this.isAdjustStatement = (String.isNotBlank(ds.Status__c) && ds.Status__c == DD_DealStatementSpreadsheetController.PLV_ADJUS_STATEM); //MN-12102021-US-0010374
            this.isAdjustStatement = SET_PLV_ADJUS_STATEM.contains(ds.Status__c); // 17.05.2022 / Sophal Noch / US-0011767

            //StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'eBayLogo' LIMIT 1];
            //logo= 'data:image/png;base64, '+ EncodingUtil.base64Encode(sr.Body);
            
            //SRO: US-0014159
            this.isUS = ds.Site__c == '0';
            this.isCA = ds.Site__c == '2';//SRO:US-0014459
            //TH: US-0013550
            this.isIT = ds.Site__c == '101';
            this.ds_Lang = ApexUtil.MAP_CODE_LANG.containsKey(ds.Site__c)?ApexUtil.MAP_CODE_LANG.get(ds.Site__c):'en';
            //END US-0013550

            this.hasDealWithSubTypePer = false; //MN-18032024-US-0014789
            this.isSubDeal = ApexUtil.getRecordTypeByName('Deal_Statement__c', 'Subsidised_Deals').DeveloperName == this.ds.RecordType.DeveloperName; //NK:14/02/2025:US-0016842
            init(ds, dsDeals);
        }
        
        private void init(Deal_Statement__c ds, List<EBH_Deal__c> dsDeals){
            isQuantityVariance=false;
            isSubsidyPerUnit=false;
            isQtyVarianceAndSubPerUnit=false;
            total=ds.Subsidy_30_Day_Calculation__c;
            totalItem=0;
            totalForAdjustState = 0; //MN-13102021-US-0010374
            totalAdjustedAmount = 0; //MN-18032024-US-0014789
            totalAdjustedPayout = 0; //MN-18032024-US-0014820
            
            deals = new List<List<DealDTO>>();
            diputes = new List<DealDTO>();

            // 05.05.2021 / Sophal Noch / US-0009424 add '2nd Statement' and 'In 2nd Payout Approval' for checking isSecondPay
            this.isSecondPay = isSecondPayDs(ds);
            this.isDisputePay = (ds.Status__c=='Dispute Payout Approved'||ds.Status__c=='Dispute Statement Sent out');
            this.isFurtherDisputePay = (ds.Further_Dispute_Payout__c!=null);
            this.ebayReviewVisible = this.isAdjustStatement ? VISIBLE_SHEET : HIDEN_SHEET; //LA-06-04-2022:US-0011117
            this.paymentDisputeVisible = this.isIT ? HIDEN_SHEET:VISIBLE_SHEET;//TH-18-05-2023:US-0013550
            this.sellerPaymentVisible = this.isIT ? HIDEN_SHEET:VISIBLE_SHEET;//TH-18-05-2023:US-0013550
            // System.debug('nsp: ds.Status__c '+ds.Status__c);
            // System.debug('nsp: isSecondPay '+isSecondPay);

            if(this.isSecondPay){ this.total =ds.Subsidy_Final_Calculation__c; }
            else if(this.isDisputePay){ this.total =ds.Subsidy_Final_Calculation__c + ds.Disputes_Payout__c; }
            else if(this.isFurtherDisputePay){ this.total =ds.Subsidy_Final_Calculation__c + ds.Disputes_Payout__c + ds.Further_Dispute_Payout__c; }

            this.lastStatementSentOut =ds.Last_Statement_Sent_Out__c;
            this.month=getMonthLabel(ds.Month__c);
            this.monthIT = ds.Month__c;//TH:US-0013550
            this.year = String.valueOf(ds.Year__c);//TH:US-0013550

             // 05.05.2021 / Sophal Noch / US-0009424 check where should dsDeals come from DML or cache
            dsDeals = dsDeals == null ? queryDealByDsId(new Set<Id>{ds.Id}).get(ds.Id) : dsDeals;

            //MN-19032024-US-0014820--START: INIT blank value to avoid error of "Argument cannot be null." in any calculation
            if (ds.Second_Payout__c == null) ds.Second_Payout__c = 0;
            if (ds.Initial_Payout__c == null) ds.Initial_Payout__c = 0;
            //--END

            if(dsDeals != null){

                for(EBH_Deal__c d: dsDeals){
                    DealDTO dto = this.addDeal(d);
                    // if(d.Dispute_Type__c!=null){
                    //     if(d.Dispute_Type__c=='Quantity Variance'){
                    //         isQuantityVariance=true;
                    //     }else {
                    //         isSubsidyPerUnit= true;
                    //     }
                    //     this.diputes.add(dto); // 11.06.2021 / Sophal Noch / US-0009686 not used for now
                    // }

                    //LA-06-04-2022:US-0011117 
                    if(d.Dispute_Status__c!=null){ this.diputes.add(dto); }
                    
                    if(d.Sold_Items_Further_Disputes__c!=null){ isHasSoldItemFurtherDisputes=true; }

                    if(d.Subsidy_Per_Unit_Further_Disputes__c!=null){ isHsSubsidyPerUnitFurtherDisputes=true; }

                    //MN-15032024-US-0014785
                    if (this.isUS) { 
                        //dto.spFinalUnitsSold = d.SoldItemsBelowDealPrice__c; //MN-18042023-US-0015168
                        this.hasDealWithSubTypePer |= dto.isSubTypePer; //MN-18032024-US-0014789
                    }

                }
            }


            isQtyVarianceAndSubPerUnit = isQuantityVariance&&isSubsidyPerUnit;
            
            //MN-13102021-US-0010374
            if (this.isAdjustStatement) { this.total = this.totalForAdjustState; }

        }
        
        public DealDTO addDeal(EBH_Deal__c d){
            // if(d.Final_Sold_Items__c!=null){
            if(d.EBH_Payout_SI_calc__c != null){
                // totalItem+=d.Final_Sold_Items__c;
                totalItem += d.EBH_Payout_SI_calc__c; // 27.05.2021 / Sophal Noch / US-0009544
                if(d.Sold_Items_Disputes__c != null)totalitem+=d.Sold_Items_Disputes__c;
                if(d.Sold_Items_Further_Disputes__c != null)totalitem+=d.Sold_Items_Further_Disputes__c;
                //total+=d.Net_Subsidy_Amount__c;               
            }   
            DealDTO dto = new DealDTO(d) ;
            List<DealDTO> lst = null;
            if(!deals.isEmpty()){
                lst=deals.get(deals.size()-1);
            }
            if(lst==null||lst.size()>999){
                lst = new List<DealDTO>();
                deals.add(lst);
            }
            lst.add(dto);

            //MN-04042024-US-0015071--START: Calculate of column "Total Subisdy Due" for Deal_V2 with Percentage Subsidy Type
            if (dto.isDealV2 && dto.isSubTypePer) {
                
                
                //For Final Statement
                if (this.isSecondPay) dto.netSubsidyAmount = (d.X2nd_Payout_Amount__c != null ? d.X2nd_Payout_Amount__c:0);
                //For Adjusted Statement
                else if (this.isAdjustStatement) {
                    
                    //dto.netSubsidyAmount += ((d.X2nd_Payout_Amount__c != null ? d.X2nd_Payout_Amount__c:0) + (dto.deal.TotalAdjustedAmount__c != null?dto.deal.TotalAdjustedAmount__c:0));
                    //dto.epppAmount = (d.X2nd_Payout_Amount__c != null ? d.X2nd_Payout_Amount__c:0); //AC4
                    dto.netSubsidyAmount = (d.X2nd_Payout_Amount__c != null ? d.X2nd_Payout_Amount__c:0) + ((dto.subsidy!=null?dto.subsidy:0) * (dto.adjustedUnits!=null?dto.adjustedUnits:0)) + (dto.deal.TotalAdjustedAmount__c != null?dto.deal.TotalAdjustedAmount__c:0);
                }
                //For 1st Statement
                else { 
                    dto.netSubsidyAmount = (d.X1st_Payout_Amount__c != null ? d.X1st_Payout_Amount__c:0) + (d.X1st_Payout_Amount_Remaining__c != null ? d.X1st_Payout_Amount_Remaining__c:0);
                }

                //MN-05042024-US-0015079: Chnage mapping field of column "Sold Item (Deal Price)" for Deal_V2 with Percentage Subsidy Type
                dto.soldItemsDealPrice = d.SoldItemsatDealPrice__c;

            }
            //MN-04042024-US-0015071--END:

            //MN-13102021-US-0010374
            if (this.isAdjustStatement) {
                dto.epppAmount = (d.X2nd_Payout_Amount__c != null ? d.X2nd_Payout_Amount__c:0); //MN-05042024-US-0015071:AC4
                //if (this.isUS && dto.isSubTypePer) dto.netSubsidyAmount += (dto.deal.TotalAdjustedAmount__c != null?dto.deal.TotalAdjustedAmount__c:0); //MN-19032024-US-0014820 //MN-04042024-US-0015071:Move to above IF
                totalForAdjustState += dto.netSubsidyAmount;
                if (dto.isSubTypePer) totalAdjustedAmount += (d.TotalAdjustedAmount__c != null)?d.TotalAdjustedAmount__c:0;//MN-18032024-US-0014789
                totalAdjustedPayout += dto.netAdjustedPayout; //MN-18032024-US-0014820
            }

            

            return dto;
        }
        public String subTotalLabel{
            get{
                String title = this.isCA?Label.DD_SSG_Subsidy_Final_Calculation_CA:Label.DD_SSG_Subsidy_Final_Calculation;//SRO:US-0014459
                
                if (isAdjustStatement) { title =Label.DD_SSG_AdjustedSubsidy_Final_Calculation; } //MN-12102021-US-0010374
                else if(!isSecondPay&&!isDisputePay){
                    title =Label.DD_SSG_Subsidy_Initial_Calculation;
                }
                //TH:US-0013550: add condition for IT : the Month in MM/YYYY format
                return title.replace('{month}', this.isIT ? (this.monthIT+'/'+this.year) : this.month);
            }
        }
        
        public String remainingLabel{
            get{
                String title =Label.DD_SSG_Remaining_estimated_30_60_days;
                if(isSecondPay){                    
                    String lastSentOut = '';
                    if(this.lastStatementSentOut!=null){
                        lastSentOut=this.lastStatementSentOut.format('MMM,dd yyyy');
                    }
                    title = Label.DD_SSG_payout_1_Date.replace('{month}', this.month);
                }
                return title;
            }
        }
        
        public String alreadyPaidLabel{
            get{
                
                String title =Label.DD_SSG_AlreadyPaid;
                title = Label.DD_SSG_AlreadyPaid.replace('{month}', this.month);
                
                return title;
            }
        }
        
        public String totalLabel{
            get{
                Decimal percent = ds_setting.Initial_Payout__c*100;
                String title = Label.DD_SSG_payout_1_Initial_calculation.replace('{month}', this.month);
                title = title.replace('{percent}', percent.intValue()+'');
                
                if (isAdjustStatement) { title =Label.DD_SSG_Adjusted_Total; } //MN-12102021-US-0010374
                
                if(isSecondPay){ title =Label.DD_SSG_payout_2_Final_remainder.replace('{month}', this.month); }

                if(isDisputePay){
                    title =Label.DD_SSG_DisputePayoutLabel.replace('{month}', this.month);  
                    if(isFurtherDisputePay){
                        title.replace('3','4');
                    }               
                }
                return title;
            }
        }
        
        public Double currentPay{
            get{
                Double currentPay = ds.Initial_Payout__c;
                
                if(this.isSecondPay){ currentPay = ds.Second_Payout__c; }
                
                if(isDisputePay){ currentPay = ds.Disputes_Payout__c; }
                
                if(isFurtherDisputePay){ currentPay = ds.Further_Dispute_Payout__c; }   

                
                //MN-13102021-US-0010374
                if (isAdjustStatement) { 
                    currentPay = totalForAdjustState - ds.Second_Payout__c - ds.Initial_Payout__c; 
                    if (this.isUS && this.hasDealWithSubTypePer) currentPay = totalAdjustedPayout; //MN-18032024-US-0014820
                }            
                
                
                
                return currentPay;
            }
        }
        
        public Double remainingPay{
            get{
                Double remaining = ds.Amount_Held_Back__c;
                if(this.isSecondPay){
                    remaining = ds.Initial_Payout__c;
                }
                //remaining always negative
                if(remaining!=null && remaining>0){
                    remaining =-remaining;
                }
                return remaining;
            }
        }
        
        public Double alreadyPaid{
            get{
                Double paid = ds.Initial_Payout__c;
                if(this.isDisputePay){
                    paid += ds.Second_Payout__c;
                }/*else if(this.isDisputePay){
                    paid += ds.Second_Payout__c + ds.Disputes_Payout__c;
                }*/
                return paid;
            }
        }
        
        public String dealSheetName{
            get{        
            //{month} Deals
                return Label.DD_SSG_SheetName.replace('{month}', this.month);
            }
        }
        
        public String paymentDisputeSheetName{
            get{
            return Label.DD_SSG_Payment_Dispute_Guidelines;
            }
        }
        public String sellerPaymentSheetName{
            get{
            return Label.DD_SSG_Seller_Payment_Dispute;
            }
        }
        //DD_SSG_Month_Dispute_Adjustment_Paid
        public string monthDisputeAdjustmentPaid{
            get{
                String title = Label.DD_SSG_Month_Dispute_Adjustment_Paid.replace('{month}', this.month);
                if(isFurtherDisputePay){
                    title.replace('due','paid');
                }
                return title;
            }
        }
        //Month Further Dispute Adjustment Paid
        public string monthFurtherDisputeAdjustmentPaid{
            get{
                return Label.DD_SSG_Month_Further_Dispute_Adjustment_Paid.replace('{month}', this.month);
            }
        }

        //MN-12102021-US-0010374 - Month Payout 1 for Adjustment Statement Deal_Statement__c
        public string monthAdjustmentPayout1{
            get{
                return Label.DD_SSG_Adjusted_Payout1.replace('{month}', this.month);
            }
        }

        //MN-12102021-US-0010374 - Month Payout 2 for Adjustment Statement Deal_Statement__c
        public string monthAdjustmentPayout2{
            get{
                return Label.DD_SSG_Adjusted_Payout2.replace('{month}', this.month);
            }
        }
        
        public String createdDate{
            get{
            DateTime dt = DateTime.now();
            //2018-11-15T14:00:00.000           
            return dt.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
            }
        }
    }

    public static Map<Id,Deal_Statement__c> queryDealStatement(Set<Id> setDsId){

        // 05.05.2021 / Sophal Noch / US-0009424

        // System.debug('nsp: inside queryDealStatement ');
        
        return new Map<Id,Deal_Statement__c>([Select Id,RecordTypeId,RecordType.DeveloperName, Name,Further_Dispute_Payout__c,Disputes_Payout__c,Subsidy_Final_Calculation__c,Subsidy_30_Day_Calculation__c,Amount_Held_Back__c,Initial_Payout__c,Last_Statement_Sent_Out__c,Month__c,Second_Payout__c,Status__c,eBay_seller__r.Name,Site__c,Year__c from deal_statement__c where id IN: setDsId]);
    }

    public static Map<Id,List<EBH_Deal__c>> queryDealByDsId(Set<Id> setDsId){
        // 05.05.2021 / Sophal Noch / US-0009424
         // 20.05.2021 / Sophal Noch / US-0009544 optimize how records are store after query

        // System.debug('nsp: inside queryDealByDsId ');
    
        Map<Id,List<EBH_Deal__c>> mapDsIdToListDeal = new Map<Id,List<EBH_Deal__c>>();
        
        for(EBH_Deal__c deal : [Select Amendment_Date__c,//NK:13/03/2025:US-0016842
                                Id, Name, deal_statement__c,Subsidy_per_Unit_Disputes__c,Sellers_Dispute_Subsidy__c
                                ,Sold_Items_Disputes__c,Seller_s_Dispute_Quantity__c,Dispute_Approval_Comments__c
                                ,Subsidy_Per_Unit_Further_Disputes__c,Sold_Items_Further_Disputes__c,Dispute_Type__c
                                ,EBH_Subsidy__c,EBH_ProductTitle__c,EBH_eBayItemID__c
                                // ,Net_Subsidy_Amount__c,Final_Sold_Items__c,X1st_Payout_Amount__c
                                ,EBH_DealStartTime__c,EBH_DealStartDate__c,EBH_DealEndDate__c,EBH_DealEndTime__c
                                ,Subsidy_Due_Disputes__c,Subsidy_Due_Further_Dispute__c, Sold_Items_30_Days__c
                                ,EBH_SoldItems__c,EBH_Sold_Items_at_Deal_Price__c,EBH_NonPayoutSI__c//SRONG​:17.10.2023/US-0014159
                                ,EBH_Payout_SI_calc__c,EBH_SubsidyFinal__c // 11.06.2021 / Sophal Noch / US-0009686
                                , AdjustedSoldItems__c //MN-12102021-US-0010374 - Added AdjustedSoldItems__c in query
                                ,eBayReviewComments__c //LA-06-04-2022:US-0011117
                                ,Dispute_Status__c //LA-06-04-2022:US-0011117
                                , EBH_SubsidyP__c, EBH_DealPrice__c, SoldItemsBelowDealPrice__c, SellerProposedUnitsSoldAtDealPrice__c //MN-12032024-US-0014785
                                , SellerProposedUnitsSoldBelowDealPrice__c, SellerProposedFinalAmount__c, X1st_Payout_Amount__c, X2nd_Payout_Amount__c  //MN-12032024-US-0014785
                                , Subsidy_Type__c, TotalAdjustedAmount__c //MN-18032024-US-0014789
                                , Recordtype.DeveloperName, X1st_Payout_Amount_Remaining__c //MN-04042024-US-0015071
                                , SoldItemsatDealPrice__c //MN-05042024-US-0015079
                                from EBH_Deal__c where deal_statement__c IN: setDsId]){
            
            if(!mapDsIdToListDeal.containsKey(deal.deal_statement__c)){
                mapDsIdToListDeal.put(deal.deal_statement__c,new List<EBH_Deal__c>());
            }

            mapDsIdToListDeal.get(deal.deal_statement__c).add(deal);
            
        }

        return mapDsIdToListDeal;

    }

    private static Boolean isSecondPayDs(Deal_Statement__c ds){
         // 17.05.2021 / Sophal Noch / US-0009536
        return (ds.Status__c=='2nd Payout Approved'|| ds.Status__c=='2nd Statement Sent out' || ds.Status__c == '2nd Statement' || ds.Status__c == 'In 2nd Payout Approval');
    }
}