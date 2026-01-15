/*********************************************************************************************************************************
@ Class:         BatchUpdateCouponSellerStage
@ Version:       1.0
@ Author:        Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:       US-0012069 - Issue with automatic update of coupon seller stage
@                   - This batch schedule is the replica of Flow "Coupon Seller After Flow" and will run every 2 hours 
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 18.07.2022 / Mony Nou / Created the class.
@                 20.02.2023 / Sovantheany Dim / Updated US-0013119 - Issue with timebased coupon seller stage update flow
@                 05.04.2023 / Acmatac Seing / US-0013406 - Do not decline coupon seller if Allow Accept Contract After Due Date = true
@               : 26.07.2023 / LoumAng SENG / US-0013606 - Replace Co-Fund End/Start Date with Coupon Starrt/End Date in automatic Coupon Seller stage updates
@               : 21.08.2023 / Sambath Seng / US-0013978 - Introduce new Coupon Seller type for Long term Coupons
@				: 29.09.2023 / Loumang SENG / US-0013980 - Retire Contract Template field on Coupon
@               : 11.01.2024 / Loumang SENG / US-0014546 - Set Default Seller Declined Reason
@               : 01.02.2024 / Mony Nou / US-0014777 - Coupon Seller Records not auto-updating to Seller Declined
@               : 15.02.2024 / Mony Nou / US-0014839 - Set Default Seller Declined Reason (correction
@               : 31.01.2025 / Mony Nou / US-0016370 - Coupon Sellers stage not updated from Signed to Running.
@               : 17.04.2025 / Mony Nou / US-0016026 - Coupon(Seller) Stage is able to update from 'Seller Declined' to 'Contract Signed'
@               : 23.09.2025 / Veenus Gollapalli / US-0033438 - CA Coupons - Update required to Coupon Seller Stage batch job
@               : 25.09.2025 / Veenus Gollapalli / US-0033514 - Batch doesn’t move Manhattan Coupon Sellers to “Coupon executed” when end date has passed (filters only = TODAY)
@               : 20.11.2025 / Sovantheany Dim / US-0033704 - Auto Seller Decline past due date 
----------------------------------------------------------------------------------------------------------------------------------
*/
global with sharing class BatchUpdateCouponSellerStage implements Database.Batchable<SObject>, Schedulable {
    
    private final static String STAGE_CONTSIGNED = 'Contract Signed';
    private final static String STAGE_CONTTERMINATED = 'Contract Terminated';
    private final static String STAGE_CONTACCEPTED = 'Contract Accepted';
    private final static String STAGE_CPRUNNING = 'Coupon Running';
    private final static String STAGE_CPEXECUTED = 'Coupon executed';
    private final static String STAGE_RUNNING = 'Running';
    private final static String STAGE_DECLINED = 'Seller Declined';
    private final static String STAGE_CONTRACT_SEND = 'Contract Send';
    private final static String DECLINED_REASON_VOID = 'Contract Voided';
    private final static String DECLINED_REASON_SELLER_DID_NOT_RESPOND = 'Seller did not respond';
    
    private final static String RT_MANHATTAN = 'Manhattan_Coupon';
    private final static String RT_POPCP = 'Pop_Coupon'; 
    private final static String RT_CATEGORY_BASE = 'Category_Based';
    private final static String RT_ITEM_BASED = 'Item_Based';
    private final static String RT_SCMC_SELLER = 'SCMC_Seller';// SB 18.08.2023 US-0013978
    private final static Set<String> CS_RECORD_TYPE = new Set<String>{RT_CATEGORY_BASE,RT_ITEM_BASED};

    //LA-28-09-2023-US-0013980: set coupon main site to CS_LANGUAGE_VOID_2 , CS_LANGUAGE_AU
    // private final static Set<String> CS_LANGUAGE_VOID_2 = new Set<String>{'DE','UK','FR','IT','ES','US'};
    // private final static String CS_LANGUAGE_AU = 'AU';
    private final static Set<String> CS_LANGUAGE_VOID_2 = new Set<String>{'ebay.de','ebay.co.uk','ebay.fr','ebay.it','ebay.es','ebay.ca'}; //VG-23092025-US-0033438
    private final static String CS_LANGUAGE_AU = 'ebay.com.au';
    private final static String CS_LANGUAGE_US = 'ebay.com';//TH: US-0033704
    private final static String CS_LANGUAGE_UK = 'ebay.co.uk'; //MN-15022024-US-0014839

    private String sQuery = 'Select Id, Coupon_Start_Date__c, Coupon_Start_Time__c, Cofund_Start_Date__c, Cofund_End_Date__c, Coupon_Seller_Stage__c, RecordType.DeveloperName,Coupon_Contract_Due_Date__c,Contract_Accept_Date__c,Contract_Language__c,Coupon__r.RecordType.DeveloperName, Allow_reaccept_contract__c, Coupon_End_Date__c, Coupon_End_Time__c  From Coupon_Seller__c'; 
    
    //LA-26-07-2023:US-0013606 - Replace (Cofund_Start_Date__c with Coupon_Start_Date__c) and (Cofund_End_Date__c with Coupon_End_Date__c) in where condition
    private String sWhere = ' WHERE ((Coupon_Start_Date__c = TODAY OR Coupon_End_Date__c = LAST_N_DAYS:7) AND (' //VG-25092025-US-0033514
                            + '(Coupon_Start_Date__c != NULL AND Coupon_Seller_Stage__c =:STAGE_CONTSIGNED AND RecordType.DeveloperName =:RT_MANHATTAN)'
                            + ' OR (Coupon_End_Date__c != NULL AND Coupon_Seller_Stage__c =:STAGE_CPRUNNING AND RecordType.DeveloperName =:RT_MANHATTAN)'
                            + ' OR (Coupon_End_Date__c != NULL AND Coupon_Seller_Stage__c !=:STAGE_CONTTERMINATED AND RecordType.DeveloperName =:RT_POPCP)'
                            + ' OR (Coupon_Start_Date__c != NULL AND Coupon_Seller_Stage__c =:STAGE_CONTACCEPTED AND RecordType.DeveloperName =:RT_POPCP)))'
                            + ' OR '
                            + ' (Coupon_Contract_Due_Date__c != NULL AND Coupon__r.RecordType.DeveloperName IN: CS_RECORD_TYPE AND Contract_Accept_Date__c = null AND Coupon_Seller_Stage__c !=: STAGE_DECLINED AND ((Contract_Language__c IN: CS_LANGUAGE_VOID_2 AND Coupon_Contract_Due_Date__c <= YESTERDAY) OR ((Contract_Language__c =:CS_LANGUAGE_AU OR Contract_Language__c =:CS_LANGUAGE_US) AND Coupon_Contract_Due_Date__c <= TODAY)))'//TH:US-0013119: replicate from Workflow rules : Contract Void 2, Contract Void AU 
                            + ' OR (Coupon_End_Date__c != NULL AND Coupon_Seller_Stage__c =:STAGE_CONTSIGNED AND RecordType.DeveloperName =:RT_SCMC_SELLER)' // SB 18.08.2023 US-0013978
                            + ' OR (Coupon_End_Date__c != NULL AND Coupon_Seller_Stage__c =:STAGE_CPRUNNING AND RecordType.DeveloperName =:RT_SCMC_SELLER)' // SB 18.08.2023 US-0013978
                            + ' OR (Coupon__r.RecordType.DeveloperName IN: CS_RECORD_TYPE AND Coupon_Seller_Stage__c =:STAGE_CONTSIGNED AND Coupon_Start_Date__c < TODAY)'; //MN-31012025-US-0016370
    private String cpSellerId;

    //MN-17042025-US-0016026--START: Convert System DateTime to Site Timezone
    private Map<String,String> mapSiteTimezone = new Map<String,String>{
        'ebay.de' => 'Europe/Berlin',
        'ebay.co.uk' => 'Europe/London',
        'ebay.es' => 'Europe/Madrid',
        'ebay.fr' => 'Europe/Paris',
        'ebay.it' => 'Europe/Rome',
        'ebay.ch' => 'Europe/Zurich',
        'ebay.at' => 'Europe/Vienna',
        'ebay.pl' => 'Europe/Warsaw',
        'ebay.nl' => 'Europe/Amsterdam',
        'ebay.com' => 'America/Los_Angeles',
        'ebay.com.au' => 'Australia/Sydney',
        'ebay.ca' => 'America/Vancouver' //VG-23092025-US-0033438
    };

    private Datetime convertSystemDateTimeByTimeZone(String siteName){
        // Get the timezone dynamically
        TimeZone tz = TimeZone.getTimeZone(mapSiteTimezone.get(siteName));
        // Datetime.now() returns the current system time in GMT
        Datetime dt = Datetime.now();

        return dt.addSeconds(tz.getOffset(dt) / 1000);
    }
    //--END

    public BatchUpdateCouponSellerStage() {}

    public BatchUpdateCouponSellerStage(String cpSellerId) {
        this.cpSellerId = cpSellerId;
        this.sWhere = ' WHERE Id=:cpSellerId';
    }

    global Database.QueryLocator start(Database.BatchableContext BC){

        return Database.getQueryLocator(sQuery+sWhere);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope){

        List<Coupon_Seller__c> lstCS2Update = new List<Coupon_Seller__c>();

        
        Date dToday = Date.today();
        Date dYesterday = Date.today().addDays(-1);

        for (Coupon_Seller__c cs : (List<Coupon_Seller__c>) scope) {
            
            Coupon_Seller__c tmp = new Coupon_Seller__c(Id = cs.Id); //MN-31012025-US-0016370: Using tmp to update the record instead in order to avoid the error "Cannot specify both an external ID reference Coupon__r and a salesforce id, Coupon__c"
            
            // US-0013119: if Coupon Contract Due Date and Contract_Accept_Date__c = null and Stage != 'Seller Declined'
            // US-0013406 - Do not decline coupon seller if Allow Accept Contract After Due Date = true
            /* MN-17042025-US-0016026--Replace logic below for RT Manhattan only (Item Based and Category Based): 
                cs.Coupon_Contract_Due_Date__c with dtContractDueDate
                dYesterday with dtYesterday
                dToday with dtToday
                cs.Coupon_Start_Date__c with cpStartDateTime
                cs.Coupon_End_Date__c with cpEndDateTime
            */

            Date contractDueDate = cs.Coupon_Contract_Due_Date__c; //MN-17042025-US-0016026
            Datetime dtContractDueDate = (contractDueDate != null)?Datetime.newInstanceGMT( contractDueDate.year(), contractDueDate.month(), contractDueDate.day(), 23, 59, 0):null; //MN-17042025-US-0016026

            Datetime cpStartDateTime = Datetime.newInstanceGMT(cs.Coupon_Start_Date__c,cs.Coupon_Start_Time__c); //MN-17042025-US-0016026
            Datetime cpEndDateTime = Datetime.newInstanceGMT(cs.Coupon_End_Date__c,cs.Coupon_End_Time__c); //MN-17042025-US-0016026

            Datetime dtToday = convertSystemDateTimeByTimeZone(cs.Contract_Language__c); //MN-17042025-US-0016026
            Datetime dtYesterday = dtToday.addDays(-1); //MN-17042025-US-0016026

            if (dtContractDueDate != null && cs.Contract_Accept_Date__c == null && cs.Coupon_Seller_Stage__c != STAGE_DECLINED && CS_RECORD_TYPE.contains(cs.Coupon__r.RecordType.DeveloperName)
                    && ((CS_LANGUAGE_VOID_2.contains(cs.Contract_Language__c) && dtContractDueDate <= dtYesterday) || ((cs.Contract_Language__c == CS_LANGUAGE_AU || cs.Contract_Language__c == CS_LANGUAGE_US) && dtContractDueDate <= dtToday))) {
                
                if(!cs.Allow_reaccept_contract__c){ //MN-01022024-US-0014777: Revert the original condition back
                    tmp.Coupon_Seller_Stage__c = STAGE_DECLINED;
                    
                    //MN-15022024-US-0014839: Set Default Seller Declined Reason for UK
                    tmp.Seller_Declined_Reasons__c = (cs.Contract_Language__c == CS_LANGUAGE_UK)? DECLINED_REASON_SELLER_DID_NOT_RESPOND : DECLINED_REASON_VOID;
                    
                }
                // US-0013406, Allow_reaccept_contract__c = true and Today >= Contract Due Date
                else if(dtToday >= cpEndDateTime){ // Should be cs.Cofund_End_Date__c?
                    if(cs.Coupon_Seller_Stage__c == STAGE_CONTRACT_SEND){ // Contract Sent but Seller Did not response
                        tmp.Seller_Declined_Reasons__c = DECLINED_REASON_SELLER_DID_NOT_RESPOND;
                    }else{
                        tmp.Seller_Declined_Reasons__c = DECLINED_REASON_VOID;
                    }
                    tmp.Coupon_Seller_Stage__c = STAGE_DECLINED;
                }
            }
            //1) From Flow: Contact Signed?
            //LA-26-07-2023:US-0013606 - Replace Cofund_Start_Date__c with Coupon_Start_Date__c
            //MN-31012025-US-0016370: Add condition where Coupon_Start_Date__c < TODAY so that Coupon Seller that signed after Coupon Start Date can still be updated to Running
            else if (cpStartDateTime != null && cpStartDateTime <= dtToday && cs.Coupon_Seller_Stage__c == STAGE_CONTSIGNED && cs.RecordType.DeveloperName == RT_MANHATTAN) {
                tmp.Coupon_Seller_Stage__c = STAGE_CPRUNNING;
            }
            
            //2) From Flow: Coupon Running?
            //LA-26-07-2023:US-0013606 - Replace Cofund_End_Date__c with Coupon_End_Date__c
            else if (cpEndDateTime != null && cpEndDateTime <= dtToday && cs.Coupon_Seller_Stage__c == STAGE_CPRUNNING && cs.RecordType.DeveloperName == RT_MANHATTAN) {
                tmp.Coupon_Seller_Stage__c = STAGE_CPEXECUTED;
            }

            //3) From Flow: PopCouponRunning?
            //LA-26-07-2023:US-0013606 - Replace Cofund_End_Date__c with Coupon_End_Date__c
            else if (cs.Coupon_End_Date__c != null && cs.Coupon_End_Date__c == dToday && cs.Coupon_Seller_Stage__c != STAGE_CONTTERMINATED && cs.RecordType.DeveloperName == RT_POPCP) {
                tmp.Coupon_Seller_Stage__c = STAGE_CONTTERMINATED;
            }

            //4) Contract Accepted?
            //LA-26-07-2023:US-0013606 - Replace Cofund_Start_Date__c with Coupon_Start_Date__c
            else if (cs.Coupon_Start_Date__c != null && cs.Coupon_Start_Date__c == dToday && cs.Coupon_Seller_Stage__c == STAGE_CONTACCEPTED && cs.RecordType.DeveloperName == RT_POPCP) {
                tmp.Coupon_Seller_Stage__c = STAGE_RUNNING;
            }

            // Start SB 18.08.2023 US-0013978
            else if (cs.Coupon_Start_Date__c != null && cs.Coupon_Start_Date__c == dToday && cs.Coupon_Seller_Stage__c == STAGE_CONTSIGNED && cs.RecordType.DeveloperName == RT_SCMC_SELLER) {
                tmp.Coupon_Seller_Stage__c = STAGE_CPRUNNING;
            }

            else if (cs.Coupon_End_Date__c != null && cs.Coupon_End_Date__c == dToday && cs.Coupon_Seller_Stage__c == STAGE_CPRUNNING && cs.RecordType.DeveloperName == RT_SCMC_SELLER) {
                tmp.Coupon_Seller_Stage__c = STAGE_CPEXECUTED;
            }
            // End SB 18.08.2023 US-0013978

            tmp.TriggerStageUpdatedDate__c = System.now();
            
            lstCS2Update.add(tmp);

        }
        
        try {
            
            Database.SaveResult[] results = ApexSafe.dml().doUpdate(lstCS2Update, false);

            List<Database.Error> dbError = new List<Database.Error>();
            for (Database.SaveResult result : results) {
                if (!result.isSuccess() && !Test.isRunningTest()) { dbError.addAll(result.getErrors()); }
            }

            if (!dbError.isEmpty()) { EBH_ApexLogger.logError(dbError, 'BatchUpdateCouponSellerStage','execute (batch)'); }

        } catch(Exception ex) { EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchUpdateCouponSellerStage','execute (batch)'); }
        
        
        
    }

    global void finish(Database.BatchableContext pBc){

    }

    global void execute(SchedulableContext sc) { 
        BatchUpdateCouponSellerStage b = new BatchUpdateCouponSellerStage();
        Database.executeBatch(b, 100);
    }
}