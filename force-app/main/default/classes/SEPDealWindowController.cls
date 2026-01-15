/*********************************************************************************************************************************
@ Class:          SEPDealWindowController
@ Version:        1.0
@ Author:         Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:        Controller class for “Deal Window Feature in SEP”
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 11.05.2023 / Mony Nou / Created the class.
@               : 05.06.2023 / Sambath Seng / US-0013723 - SP - IT Home page useful link and other issue fixes in the portal
@               : 25.07.2023 / LoumAng SENG / US-0013830 - SKU number field - IT Deals submission
@               : 01.12.2023 / SRONG TIN / US-0013759 - [SEP] Tabs should not visible on Standard Campaign ( DRC )
@               : 12.01.2024 / Sambath Seng / US-0013136 - Seller_Portal_Status__c - Deprecate
*********************************************************************************************************************************/
public with sharing class SEPDealWindowController {
    
    //SB 5.6.2023 US-0013723 add EBH_Subsidy__c to query
    // SB 12.01.2024 US-0013136 replace Seller_Portal__c with Status_Seller_Portal__c
    private final static String SOQL_DW_DEAL = 'SELECT Id,SKU_Number__c, CurrencyIsoCode, eBay_Seller_Name__c, EBH_eBayItemID__c, Deal_Price_Seller_Portal__c, EBH_RRPWASPrice__c, List_Price__c, EBH_Quantity__c, EBH_MaximumPurchases__c, EBH_ProductTitle__c, EBH_Vertical__c, EBH_Category__c, Sub_Category__c, EBH_DealStartDate__c, EBH_DealEndDate__c, EBH_SpotlightCategory__c, EBH_SpotlightCategory__r.Name, Status_Seller_Portal__c, EBH_ReasonforRejection__c, EBH_ReasonforRejectionextd__c, Cancellation_Reason__c, EBH_DealSiteId__c, toLabel(EBH_DealSiteId__c) siteVal, EBH_DealStartTime__c, EBH_DealEndTime__c, EBH_Subsidy__c FROM EBH_Deal__c';
    private final static Integer ROW_LIMIT = 1000; //apex:repeat limit 1000
    private final static string AU_COUNTRY = '15';
	private final static String US_COUNTRY = '0';
    private final static String IT_COUNTRY = '101';
    private final static String DE_COUNTRY = '77';//SRONG-01-12-2023-US-0013759

    private static Map<String, String> mDateFormat = ApexUtil.MAP_LOCALE_DATEONLY();
    private final static Map<String, Object> PORTAL_DOMAIN = SEP_Helper.getPortalDomain();//LA-25-07-2023-US-0013830

    private static Map<String, String> mSiteDateFormat = new Map<String, String> {
        US_COUNTRY => mDateFormat.get('en_US'),
        AU_COUNTRY => mDateFormat.get('en_AU'),
        IT_COUNTRY => mDateFormat.get('it'),
        DE_COUNTRY => mDateFormat.get('de_DE')//SRONG-01-12-2023-US-0013759
    };

    public string xmlheader{ get{return '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';}}
    public string currentUser{get;set;}
    public List<List<EBH_Deal__c>> listChunkDeals{get;set;}
    public List<List<DealWrapper>> listChunkDealWrappers  {get;set;}
    public static Boolean isIT{get;set;} //LA-25-07-2023-US-0013830

    //Controller's Constructor for VF Page: DWDealsDownloadPage
    public SEPDealWindowController() {

        String dwId = String.escapeSingleQuotes(String.isBlank(ApexPages.currentPage().getParameters().get('id')) ? '': ApexPages.currentPage().getParameters().get('id'));
        currentUser = UserInfo.getUserName();

        listChunkDeals = new List<List<EBH_Deal__c>>();
        if(String.isNotBlank(dwId)){
            
            List<EBH_Deal__c> listDeals = getDWDeals(dwId);
            Map<String,Object> mapResult = ApexUtil.chunkListSOBJ(listDeals, ROW_LIMIT);
            listChunkDeals = (List<List<EBH_Deal__c>>)mapResult.get('listAllChunk');

            listChunkDealWrappers = new List<List<DealWrapper>>();
            for (List<EBH_Deal__c> lstDeals : listChunkDeals) {
                List<DealWrapper> lstDealWrapper = new List<DealWrapper>();
                for (EBH_Deal__c d : lstDeals) {
                    DealWrapper dw = new DealWrapper(d);
                    lstDealWrapper.add(dw);
                }
                listChunkDealWrappers.add(lstDealWrapper);
            }
            
        }
    }

    private List<EBH_Deal__c> getDWDeals(String dwId){
        String sWhere = ' WHERE EBH_DealRetailCampaign__c ='+ ApexUtil.closeSQoute(dwId);
        return Database.query(SOQL_DW_DEAL+sWhere);
    }

    
    
    public String currencyFormat{
        get{

            String user_cur = UserInfo.getDefaultCurrency();
            String curSign = (ApexUtil.mapCurrencySign.containsKey(user_cur))?ApexUtil.mapCurrencySign.get(user_cur):'$';
            return '_("' + curSign + '"* #,##0.00_);_("' + curSign + '"* \\(#,##0.00\\);_("' + curSign + '"* "-"??_);_(@_)';
            //return '_("$"* #,##0.00_);_("$"* \\(#,##0.00\\);_("$"* "-"??_);_(@_)';
        }
    }
    

    public class DealWrapper {

        public EBH_Deal__c deal{get;set;}
        public String startDate {get;set;}
        public String endDate {get;set;}
        // public String spotlight_cate {get;set;}
        // public String dealPrice {get;set;}
        // public String listPrice {get;set;}
        private final String IS_IT = 'isIT';//LA-25-07-2023-US-0013830

        public DealWrapper (EBH_Deal__c deal) {
            this.deal = deal;
            isIT = PORTAL_DOMAIN.get(IS_IT)==true ? true : false;//LA-25-07-2023-US-0013830
            
            if (mSiteDateFormat.containsKey(deal.EBH_DealSiteId__c)) {

                String dateFormat = mSiteDateFormat.get(deal.EBH_DealSiteId__c);

                if(deal.EBH_DealStartDate__c!=null){ 
                    this.startDate = generateDatePerRegion(deal.EBH_DealStartDate__c, deal.EBH_DealStartTime__c, dateFormat);
                }

                if(deal.EBH_DealEndDate__c!=null){ 
                    this.endDate = generateDatePerRegion(deal.EBH_DealEndDate__c, deal.EBH_DealEndTime__c, dateFormat);
                }
                
            }
            
            // this.spotlight_cate = (deal.EBH_SpotlightCategory__c != null)?deal.EBH_SpotlightCategory__r.Name:'';

            // this.dealPrice = (deal.Deal_Price_Seller_Portal__c==null)?'N/A':ApexUtil.mapCurrencySign.get(deal.CurrencyIsoCode)+ApexUtil.formatNumber(deal.Deal_Price_Seller_Portal__c ,2,String.valueOf(deal.get('siteVal')));
            // this.listPrice = (deal.List_Price__c==null)?'N/A':ApexUtil.mapCurrencySign.get(deal.CurrencyIsoCode)+ApexUtil.formatNumber(deal.List_Price__c ,2,String.valueOf(deal.get('siteVal')));
            
        }   

        private String generateDatePerRegion (Date dVal, Time tVal, String dateFormat) {
            DateTime dt = DateTime.newInstance(dVal, tVal);
            return dt.format(dateFormat);
        } 

    }
    /*****************************************************************************************************************************
    @ Method:         getDWDailyDealRetailWeekExcel
    @ Version:        1.0
    @ Author:         Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:        US-0013472 - Related Deal List view in the Deal Window Related List
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String dwId (Id of Deal Retail Campaign with RecordType = Deal Window)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.05.2023 / Mony Nou / Created the method
    *****************************************************************************************************************************/
    @AuraEnabled
    public static String getDWDailyDealRetailWeekExcel(String dwId) {

        PageReference xlsGenerater = new PageReference('/apex/DWDealsDownloadPage');
        xlsGenerater.getParameters().put('id',dwId);
        return  EncodingUtil.base64encode(!Test.isRunningTest() ? xlsGenerater.getContent() : Blob.valueOf('test'));

    }
}