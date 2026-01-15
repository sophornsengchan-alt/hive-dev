/*********************************************************************************************************************************
@ Class:          BatchDealPriceChangeAlert
@ Version:        1.0
@ Author:         Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:        US-0009568 - Price Drop Reminder email to the Seller
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.Oct.2022 / Mony Nou / Created the class.
@                11.07.2023 / Acmatac Seing / US-0013804 Price Mismatch emails
@                24.04.2024 / Sambath Seng / US-0014810 - [Tech Debt] - Add Email Address Criteria to BatchDealPriceChangeAlert
*********************************************************************************************************************************/
global with sharing class BatchDealPriceChangeAlert implements Database.Batchable<SObject> {
    
    private static final String STRING_ITEMIDMISSING = 'Item ID missing';
    private static final String SELCOM_EMAILTEMPLATE = 'Deals Price Drop Reminder';
    private static final String SITE_DE = 'DE';
    private static final String DF_DD_MM_YYYY = 'dd/MM/yyyy';
    private static final String SPLIT_CHAR = '#';
    private static final String RT_DEALV1 = 'Deal_V1';
    private static final Id SELCOM_RT_DEALS = ApexUtil.getRecordTypeByName('Seller_Communication__c', 'Deals').Id;

    private static Set<String> sDealStatus = new Set<String>{ 'Deal Agreed','Running' };
    private static Set<String> sEnabledSite = new Set<String>{
        SITE_DE
    };
    private static Map<String, String> mSiteColumnHeader = new Map<String, String> {
        SITE_DE => System.Label.DPCA_ColumnHeader_DE
    };

    private static Map<String, String> mSiteDateFormat = new Map<String, String> {
        SITE_DE => DF_DD_MM_YYYY
    };

    Set<Id> accIds = new Set<Id>();
    String query = 'Select Id, Name From Account';
    String sWhere = ' WHERE Id IN (SELECT EBH_BusinessName__c FROM EBH_Deal__c WHERE EBH_Pricenotmatching__c = TRUE AND EBH_Status__c IN:sDealStatus AND toLabel(EBH_DealSiteId__c ) IN:sEnabledSite AND EBH_DealStartDate__c=TODAY AND EBH_ebayLink__c <>:STRING_ITEMIDMISSING)';
    
    public BatchDealPriceChangeAlert(Set<Id> accIds) {
        this.accIds = accIds;
        if (!accIds.isEmpty()) sWhere = ' WHERE Id IN:accIds';
    }

    public BatchDealPriceChangeAlert () {}

    global Database.QueryLocator start (Database.BatchableContext BC) {

        return Database.getQueryLocator( query + sWhere );
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {

        Map<Id, Set<Id>> mAcc2ContIds = new Map<Id, Set<Id>>();

        /* MN-28102022-No longer send to Active Community User but send to Seller Contact(s) that link to those deals
        for (Contact con : [SELECT AccountId, Original_Seller__c FROM Contact WHERE Active_Community_User__c = true AND ((AccountId IN:scope AND Original_Seller__c = NULL) OR (Original_Seller__r.Seller_Portal_Group__c <> null AND Original_Seller__c IN:scope))]) {

            Id accId = (con.Original_Seller__c == null)?con.AccountId:con.Original_Seller__c;
            
            if (!mAcc2ContIds.containsKey(accId)) mAcc2ContIds.put(accId, new Set<Id>());
            mAcc2ContIds.get(accId).add(con.Id);
        
        }
        */

        Map<String, List<EBH_Deal__c>> mSellerDealsPerSite = new Map<String, List<EBH_Deal__c>>();
        

        //Retreive Deal based on Group Seller from Account pass in scope variable
        //MN-06102022-As discussed with BA, we agreed to group Seller with Deal Site, in case One Seller can have multiples Deals with different Site 
        //MN-06102022-We need to limit for 100 deals only for Email
        // 24.04.2024 / Sambath Seng / US-0014810 add Seller_Contact__r.Email to query
        for (Account acc : [SELECT Id, (SELECT Current_Seller_Price__c, RecordType.DeveloperName, Seller_Contact__c, Seller_Contact__r.Email, EBH_eBayItemID__c, EBH_BusinessName__c, EBH_MarketingTitle__c, EBH_Quantity__c, EBH_DealFormat__c, EBH_DealStartDate__c, EBH_DealEndDate__c, EBH_SellerPrice__c, EBH_DealPrice__c, toLabel(EBH_DealSiteId__c) FROM EBH_BusinessName__r WHERE toLabel(EBH_DealSiteId__c ) IN:sEnabledSite AND EBH_Pricenotmatching__c = TRUE AND EBH_Status__c IN:sDealStatus AND EBH_DealStartDate__c=TODAY AND EBH_ebayLink__c <>:STRING_ITEMIDMISSING LIMIT 100) FROM Account WHERE Id IN:scope]) {

            for (EBH_Deal__c deal : acc.EBH_BusinessName__r) {

                if (deal.Seller_Contact__c != null && deal.Seller_Contact__r.Email != null) { // 24.04.2024 / Sambath Seng / US-0014810 add Seller_Contact__r.Email != null
                    if (!mAcc2ContIds.containsKey(acc.Id)) mAcc2ContIds.put(acc.Id, new Set<Id>());
                    mAcc2ContIds.get(acc.Id).add(deal.Seller_Contact__c);
                }

                String key = acc.Id + SPLIT_CHAR + deal.EBH_DealSiteId__c;
                if (!mSellerDealsPerSite.containsKey(key)) mSellerDealsPerSite.put(key, new List<EBH_Deal__c>());
                mSellerDealsPerSite.get(key).add(deal);

            }

            
        }

        List<Seller_Communication__c> lstSelCom2Create = new List<Seller_Communication__c>();

        for (String key : mSellerDealsPerSite.keySet()) {
            
            List<String> tmp = key.split(SPLIT_CHAR);
            Id accId = Id.valueOf(tmp[0]);
            String site = tmp[1];

            List<EBH_Deal__c> lstDeal = mSellerDealsPerSite.get(key);

            String htmlTable = generateTable(lstDeal, site);

            if (mAcc2ContIds.containsKey(accId)) {

                for (Id conId : mAcc2ContIds.get(accId)) {

                    lstSelCom2Create.add(new Seller_Communication__c(

                        RecordTypeId = SELCOM_RT_DEALS,
                        Contact__c = conId,
                        Account__c = accId,
                        Email_Template__c = SELCOM_EMAILTEMPLATE,
                        Name = SELCOM_EMAILTEMPLATE,
                        Email_Body__c = htmlTable,
                        Region__c = site,
                        Deal__c = lstDeal.get(0).Id
                    ));
                }
            }
            
        }

        try {
            insert lstSelCom2Create; 
        }catch(Exception ex) {
            System.debug('$$$$$$ exception on creating seller communication :: ' + ex.getMessage());
            EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchDealPriceChangeAlert','execute');
        }
        
        
            
    }

    private final static Integer TABLECHARLIMIT = 131072;
    private final static String  HTMLTABLE_STTAG = System.Label.DPCA_HTMLDealTableStartTag;
    private final static String  HTMLTABLE_ENTAG = '</table>';
    
    private static String generateTable (List<EBH_Deal__c> lstDeal, String site) {
        
        

        String htmlTable = '';

        if (lstDeal.isEmpty()) return htmlTable;

        if (mSiteColumnHeader.containsKey(site)) {

            htmlTable += HTMLTABLE_STTAG;

            htmlTable += mSiteColumnHeader.get(site);

            for (EBH_Deal__c deal : lstDeal) {

                DealWrapper dw = new DealWrapper(deal);

                String row = System.Label.DPCA_HTMLDealRow;

                row = row.replace('{EBH_MarketingTitle__c}', dw.marketingTitle)
                    .replace('{EBH_eBayItemID__c}', dw.ebayItemID)
                    .replace('{EBH_Quantity__c}', dw.quantity)
                    .replace('{EBH_DealFormat__c}', dw.dealFormat)
                    .replace('{EBH_DealStartDate__c}', dw.formatStartDate)
                    .replace('{EBH_DealEndDate__c}', dw.formatEndDate)
                    // 11.07.2023 / Acmatac Seing / US-0013804 Price Mismatch emails
                    // .replace('{EBH_SellerPrice__c}', dw.sellerPrice)
                    .replace('{Current_Seller_Price__c}', dw.currentSellerPrice)
                    .replace('{EBH_DealPrice__c}', dw.dealPrice);

                //Check if reach limit then skip that Deal
                Integer char_size = htmlTable.length() + row.length() + HTMLTABLE_ENTAG.length();
                if (char_size >= TABLECHARLIMIT) break;

                htmlTable += row;

            }

            htmlTable += HTMLTABLE_ENTAG;
        }

        return htmlTable;
    }


    public class DealWrapper {

        public String marketingTitle;
        public String ebayItemID;
        public String quantity;
        public String dealFormat;
        public Datetime dealStartDateDT;
        public String formatStartDate;
        public Datetime dealEndDateDT;
        public String formatEndDate;
        public String sellerPrice;
        public String dealPrice;
        public String dealSite;
        // 11.07.2023 / Acmatac Seing / US-0013804 Price Mismatch emails
        public String currentSellerPrice;

        public DealWrapper (EBH_Deal__c deal) {

            dealSite = deal.EBH_DealSiteId__c;

            marketingTitle = deal.EBH_MarketingTitle__c;
            ebayItemID = deal.EBH_eBayItemID__c;
            quantity = (deal.EBH_Quantity__c == null)?'':String.valueOf(deal.EBH_Quantity__c);
            dealFormat = deal.EBH_DealFormat__c;

            String siteDF = (mSiteDateFormat.containsKey(dealSite))?mSiteDateFormat.get(dealSite):DF_DD_MM_YYYY;

            dealStartDateDT = Datetime.newInstance(deal.EBH_DealStartDate__c.Year(),deal.EBH_DealStartDate__c.Month(),deal.EBH_DealStartDate__c.Day());
            formatStartDate = dealStartDateDT == null ? '' : dealStartDateDT.format(siteDF);

            dealEndDateDT = Datetime.newInstance(deal.EBH_DealEndDate__c.Year(),deal.EBH_DealEndDate__c.Month(),deal.EBH_DealEndDate__c.Day());
            formatEndDate = dealEndDateDT == null ? '' : dealEndDateDT.format(siteDF);

            //MN-11102022-Added fixed Time after Start/End Date for DE Site
            if (dealSite == SITE_DE) {
                formatStartDate += ', 9:00';
                formatEndDate += ', 8:59'; 
            }

            sellerPrice = (deal.EBH_SellerPrice__c==null)?'':ApexUtil.formatNumber(deal.EBH_SellerPrice__c ,2,dealSite);
            dealPrice = (deal.EBH_DealPrice__c==null)?'':ApexUtil.formatNumber(deal.EBH_DealPrice__c ,2,dealSite);
            // 11.07.2023 / Acmatac Seing / US-0013804 Price Mismatch emails
            currentSellerPrice = (deal.Current_Seller_Price__c==null)?'':ApexUtil.formatNumber(deal.Current_Seller_Price__c ,2,dealSite);
        }

    }

    global void finish(Database.BatchableContext BC) {
     
    }
   
    
}