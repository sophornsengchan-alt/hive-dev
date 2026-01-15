/*********************************************************************************************************************************
@ Class:          DealRetailCampaignTriggerHandler
@ Version:        1.0
@ Author:         SRONG TIN (srong.tin@gaea-sys.com)
@ Purpose:        Handler Class for DealRetailCampaign Trigger
@ Change history: 01.July.2021 / SRONG TIN / Created the class.
@                 20.July.2021 / MONY NOU  / US-0009853 - [SEP] Email notification to Seller when Deal Window is Scheduled
@                 07.September.2021 / SOCHETTRA SAING / EBAY-345 - Automatically relate records for Deal Window <> Campaign
@                 25.November.2021 / MONY NOU / US-0010732 - [SP - Na Deals][Bug]Deal Window Campaign is not showing the updated version under the Deal Window in Portal.
@				  11.August.2022 / BORA CHHORN / US-0011459 - Deal Retail Campaigns for AU	
@                 21.September.2022 / BORA CHHORN / US-0011147 - Seller email notification when Deal Window is Scheduled
@                 16.March.2023 / BORA CHHORN / US-0013216 - Attach the T&Cs when the Deal Window is Open for Deal Site=AU
@                 21/03/2023 / Sambath Seng / US-0013219 - Seller email notification with PDF Deal Window Agreement when Deal Window is Scheduled
@                 25/04/2023 / SRONG TIN / US-0013353 - IT Deals SP Home Page
@                 15/05/2023 / sovantheany Dim / US-0013393 - Scheduled email notification for Sellers
*********************************************************************************************************************************/
public without sharing class DealRetailCampaignTriggerHandler {
    public static final String SOQL_DEAL= 'SELECT Id, EBH_Status__c,EBH_DealRetailCampaign__c FROM EBH_Deal__c ';
    public static final String DRC_Deal_WINDOW = 'Deal_Campaign_V2';
    public static final String UNSUB_DEAL = 'Deal_V3';
    public static final String OPS_REVIEW = 'Ops Review';
    public static final String CM_REVIEW = 'CM Review';
    public static final String SCHEDULED = 'Scheduled';
    public static final String RUNNING = 'Running';
    public static final String COMPLETED = 'Completed';
    public static final String OPEN_FOR_SUBMISSION = 'Open for Submissions'; //BR-US-0013216
    
    private static final String EMAILTEMPLATE_AU_DEALWINDOWSCH = 'AU_Deal_Window_Scheduled'; //BR-21092022-US-US-0011147
    private static final String EMAILTEMPLATE_DEALWINDOWSCH = 'Deal_Window_Scheduled'; //MN-20072021-US-0009853
    private static Id RT_DEALWINDOW = ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', DRC_Deal_WINDOW).Id; //MN-20072021-US-0009853

    public static Boolean isFDRCHandler = false;
    //private static final String DRC_Deal_WINDOW = 'Deal_Campaign_V2';
    public static final String DRC_Deal_WINDOW_CAMPAIGN = 'Deal_Campaign_V3';
    public static final String clone_deal_windowrecordtypeName = 'Cloned_Deal_Campaign';
    //private static Id RT_DEALWINDOW = ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', DRC_Deal_WINDOW).Id;
    private static Id recordtypeidDeal_WINDOW_CAMPAIGN = ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', DRC_Deal_WINDOW_CAMPAIGN).Id;
    //private static Id clone_deal_windowrecordtypeId = ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', clone_deal_windowrecordtypeName).Id;
	private static final String DE_COUNTRY = '77'; //Sambath Seng 25/4/2022 US-0011625 - Bugs/issues and user feedback
	// BORA CHHORN / 11/8/2022 - US-0011459 - Deal Retail Campaigns for AU
	private static final String AU_COUNTRY = '15';
	private static final String US_COUNTRY = '0';
    // SRONG TIN / 25/04/2023 - IT Deals SP Home Page
    private static final String IT_COUNTRY = '101';
    // BORA CHHORN / 21/9/2022 - US-0011147 - Seller email notification when Deal Window is Scheduled
    static Map<String,String> MAP_COUNTRY_TO_OWD_EMAIL = new Map<String,String>{ 
        AU_COUNTRY => Label.OWD_AU_Unsub_Deal,
        US_COUNTRY => Label.OWD_Unsub_Deal_Daily_Deals_Team
    };
    static Map<String,String> MAP_COUNTRY_TO_EMAIL_TEMPLATE = new Map<String,String>{ 
        AU_COUNTRY => EMAILTEMPLATE_AU_DEALWINDOWSCH,
        US_COUNTRY => EMAILTEMPLATE_DEALWINDOWSCH
    };
    //TH:US-0013393
    private final static string SELCOM_IT_SCHEDULE_EMAILTEMPLATE = 'Deal Window Schedule email to Seller - IT';
    /*****************************************************************************************************************************
    @ Method:   updateDealStatusByTimeBaseChange
    @ Version:  1.0
    @ Author:   SRONG TIN (srong.tin@gaea-sys.com)
    @ Purpose:  US-0009685 - [SEP] US - NA Unsub Deal - Time Based Status Changes and it related to US-0009684
    ------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 01.July.2021 / SRONG TIN / Created the  Method.
    @                 16.March.2023 / BORA CHHORN / US-0013216 - Attach the T&Cs when the Deal Window is Open for Deal Site=AU
    *****************************************************************************************************************************/
    public static void updateDealStatusByTimeBaseChange(Map<Id,EBH_DealRetailCampaign__c> mNewDRC,Map<Id,EBH_DealRetailCampaign__c> mOldDRC){
        Id dealRetailCampaignRecordTypeId =  ApexUtil.getRecordTypeByName('EBH_DealRetailCampaign__c', DRC_Deal_WINDOW).Id;
        Id dealRecordTypeId =  ApexUtil.getRecordTypeByName('EBH_Deal__c', UNSUB_DEAL).Id;
        Set<Id> dealRetailCampaignIds = new Set<Id>();
        Set<String> statusList = new Set<String>{CM_REVIEW,SCHEDULED,RUNNING,COMPLETED,OPEN_FOR_SUBMISSION}; 
        // Get all dealRetailCampaignIds 
        for(EBH_DealRetailCampaign__c newDRC : mNewDRC.values()){
            EBH_DealRetailCampaign__c newDealRetailCampaign = mNewDRC.get(newDRC.Id);
            EBH_DealRetailCampaign__c oldDealRetailCampaign = mOldDRC.get(newDRC.Id);
            if( newDealRetailCampaign.RecordTypeId == dealRetailCampaignRecordTypeId && 
                String.isNotBlank(newDealRetailCampaign.Status__c) && 
                newDealRetailCampaign.Status__c != oldDealRetailCampaign.Status__c &&
                statusList.Contains(newDealRetailCampaign.Status__c)
            ){
                if(newDealRetailCampaign.EBH_Country__c == AU_COUNTRY && newDealRetailCampaign.Status__c == OPEN_FOR_SUBMISSION){
                    createPDFAttachment(System.Label.AU_Seller_Portal_Deals_Master_Terms_and_Conditions, newDealRetailCampaign.Id);
                }
                dealRetailCampaignIds.add(newDealRetailCampaign.Id);
            }
        }
        // if dealRetailCampaignIds not empty
        if(!dealRetailCampaignIds.isEmpty()){
            Batch_DRC_DealUpdate drc = new Batch_DRC_DealUpdate(dealRetailCampaignIds);
            Database.executeBatch(drc,20); 
        }
    }

    /*****************************************************************************************************************************
    @ Method:        sendEmailToDealSellerContact
    @ Version:       1.0
    @ Author:        Mony Nou (mony.nou@gaea-sys.com)  
    @ Purpose:       US-0009853 - [SEP] Email notification to Seller when Deal Window is Scheduled
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:  Map<Id,EBH_DealRetailCampaign__c> newMap,Map<Id,EBH_DealRetailCampaign__c> oldMap     
    @ event    :  After Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20/07/2021 / Mony Nou  / Created the  Method.
    @                 21/09/2022 / BORA CHHORN / US-0011147 - Seller email notification when Deal Window is Scheduled
    @                 15/05/2023 / sovantheany Dim / US-0013393 - Scheduled email notification for Sellers
    *****************************************************************************************************************************/
    public static void sendEmailToDealSellerContact (Map<Id,EBH_DealRetailCampaign__c> newMap,Map<Id,EBH_DealRetailCampaign__c> oldMap) {

        Map<Id, List<Id>> mDealWindowSellerContact = new Map<Id, List<Id>>();
        Map<Id, String> mDealWindowSRW = new Map<Id, String>();
        Map<Id, EBH_DealRetailCampaign__c> mDRC = new Map<Id, EBH_DealRetailCampaign__c>(); //BR-21092022-US-US-0011147

        for (EBH_DealRetailCampaign__c drc : newMap.values()) {

            //Filtering: for Deal Window that is updated to 'Scheduled' only
            if (drc.RecordTypeId == RT_DEALWINDOW && drc.Status__c == SCHEDULED && oldMap.get(drc.Id).Status__c != drc.Status__c) {
                mDealWindowSellerContact.put(drc.Id, new List<Id>());
                mDealWindowSRW.put(drc.Id, newMap.get(drc.Id).Start_Retail_Week__c);
                 //TH:US-0013393:add drc.EBH_Country__c != '101' to avoid IT add to mDRC
                if(drc.EBH_Country__c != '101') mDRC.put(drc.Id, drc);
            }
            
        }

        if (mDealWindowSellerContact.isEmpty()) return; //Skip is no record to process

       //Find all Seller Contact that submitted Deals against each Deal Window
        List<Seller_Communication__c> lstSellerComToCreated = new List<Seller_Communication__c>();
        RecordType rectypeDeal = ApexUtil.getRecordTypeByName('Seller_Communication__c','Deals');
        Map<Id,Seller_Communication__c> mapSellerCom = new Map<Id,Seller_Communication__c>();
        //TH:US-0013393: add EBH_DealSiteId__c , and EBH_BusinessName__c
        for (AggregateResult agg : [SELECT EBH_DealRetailCampaign__c dw, Seller_Contact__c sc, EBH_DealSiteId__c site, EBH_BusinessName__c bsn
                                        FROM EBH_Deal__c 
                                        WHERE EBH_DealRetailCampaign__c IN:mDealWindowSellerContact.keySet() AND Seller_Contact__c != null GROUP BY EBH_DealRetailCampaign__c,Seller_Contact__c,EBH_BusinessName__c,EBH_DealSiteId__c]) {
            Id bsnId = Id.valueOf(String.valueOf(agg.get('bsn')));//TH:US-0013393
            Id dwId = Id.valueOf(String.valueOf(agg.get('dw')));
            Id scId = Id.valueOf(String.valueOf(agg.get('sc')));
            
            //TH:US-0013393:AC1: Create a Seller communication record grouped by the Seller Contact of the related Deal Window (DRC_V2) when the Deal status is updated to Scheduled.
            String site = String.valueOf(agg.get('site'));
            if(site == '101'){
                lstSellerComToCreated.add(new Seller_Communication__c(
                        RecordTypeId = rectypeDeal.Id,
                        Contact__c = scId,
                        Account__c = bsnId,
                        Region__c = 'IT',
                        Deal_Retail_Campaign__c = dwId,
                        Email_Template__c = SELCOM_IT_SCHEDULE_EMAILTEMPLATE,
                        Name = SELCOM_IT_SCHEDULE_EMAILTEMPLATE,
                        Platform__c = 'Seller Portal'
                    ));
            }else if (mDealWindowSellerContact.containsKey(dwId)) {
                mDealWindowSellerContact.get(dwId).add(scId);
            }
        }

        if(!lstSellerComToCreated.isEmpty()) insert lstSellerComToCreated;
        if(!mDRC.isEmpty()) acsyn_sendEmailToDealSellerContact(JSON.serialize(mDealWindowSellerContact), JSON.serialize(mDealWindowSRW), JSON.serialize(mDRC));
        
    }

    /*****************************************************************************************************************************
    @ Method:        acsyn_sendEmailToDealSellerContact
    @ Version:       1.0
    @ Author:        Mony Nou (mony.nou@gaea-sys.com)  
    @ Purpose:       US-0009853 - Create future method to send an email with attachment (Excel File from VF Page) because we cannot
    @                                do that inside Trigger Context
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21/07/2021 / Mony Nou  / Created the  Method.
	@                 21/09/2022 / BORA CHHORN / US-0011147 - Seller email notification when Deal Window is Scheduled
    @               : 21/03/2023 / Sambath Seng / US-0013219 - Seller email notification with PDF Deal Window Agreement when Deal Window is Scheduled
    *****************************************************************************************************************************/
    @Future(callout=true)
    private static void acsyn_sendEmailToDealSellerContact(String jsonDWSC, String jsonDWSRW, String jsonDRC) {

        Map<Id, List<Id>> mDWSC = (Map<Id, List<Id>>) JSON.deserialize(jsonDWSC, Map<Id, List<Id>>.class);
        Map<Id, String> mDWSRW = (Map<Id, String>) JSON.deserialize(jsonDWSRW, Map<Id, String>.class);
        Map<Id, EBH_DealRetailCampaign__c> mDRC = (Map<Id, EBH_DealRetailCampaign__c>) JSON.deserialize(jsonDRC, Map<Id, EBH_DealRetailCampaign__c>.class); //BR-21092022-US-0011147
        
        // SB 21.03.2023 US-0013219 - Seller email notification with PDF Deal Window Agreement when Deal Window is Scheduled
        Map<Id,Id> mContentDocLinkEntityID = new Map<Id,Id>();
        Map<Id,ContentVersion> mDRCContentVersion = new Map<Id,ContentVersion>();
        if(!mDRC.isEmpty()){
            Set<Id> cdlIds = new Set<Id>();
            String auCVTitle = System.Label.AU_Deal_Window_Agreement_Terms_ContentVersion_Title;
            for (ContentDocumentLink cdl : [SELECT LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:mDRC.keySet()]) {
                mContentDocLinkEntityID.put(cdl.ContentDocumentId,cdl.LinkedEntityId);
                cdlIds.add(cdl.ContentDocumentId);
            }
            for (ContentVersion cv : [SELECT Title,VersionData,FileExtension,ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN:cdlIds AND Title =: auCVTitle]) {
                if(!mDRCContentVersion.containsKey(mContentDocLinkEntityID.get(cv.ContentDocumentId))){
                    mDRCContentVersion.put(mContentDocLinkEntityID.get(cv.ContentDocumentId),cv);
                }
            }
        }

        List<Messaging.SingleEmailMessage> listEmail = new List<Messaging.SingleEmailMessage>(); 
        // Comment BLOCK BY BR-21092022-US-0011147
        //OrgWideEmailAddress orgWide = ApexUtil.getOWDbyAddress(System.label.OWD_Unsub_Deal_Daily_Deals_Team);
        //Id orgWideId = orgWide != null ? orgWide.Id : null;

        //List<EmailTemplate> templates = [SELECT Id FROM EmailTemplate WHERE DeveloperName =:EMAILTEMPLATE_DEALWINDOWSCH];
        //if (templates.isEmpty()) return; //Skip is there is no email template 
        // END Comment BLOCK BY BR-21092022-US-0011147
        Map<String, EmailTemplate> mapApiNameToEmailTemplate = new Map<String, EmailTemplate>();
        for(EmailTemplate templates : [Select Id, DeveloperName from EmailTemplate Where DeveloperName IN: MAP_COUNTRY_TO_EMAIL_TEMPLATE.values()]){
            mapApiNameToEmailTemplate.put(templates.DeveloperName, templates);
        }

        for (Id dwId : mDWSC.keySet()) {
            List<Id> lstscID = mDWSC.get(dwId);
            if(lstscID.isEmpty()) continue;
            String dwrw = mDWSRW.get(dwId);
            
            // BR-21092022-US-0011147
            EBH_DealRetailCampaign__c dw = mDRC.get(dwId);
            String owdEmail = MAP_COUNTRY_TO_OWD_EMAIL.get(dw.EBH_Country__c);
            
            OrgWideEmailAddress orgWide = ApexUtil.getOWDbyAddress(owdEmail);
            Id orgWideId = orgWide != null ? orgWide.Id : null;
            
            EmailTemplate template = mapApiNameToEmailTemplate.get(MAP_COUNTRY_TO_EMAIL_TEMPLATE.get(dw.EBH_Country__c));
            // END BR-21092022-US-0011147
            
            for(Id scId : mDWSC.get(dwId)) {
                
                List<String> tmp = new List<String>();
                tmp.add('dwid='+dwId);
                tmp.add('scid='+scId);
                tmp.add('dwrw='+dwrw);
            
                PageReference xls_file = new PageReference('/apex/DD_RetailWeekSpreadsheet?' + String.join(tmp, '&'));
                Blob xlsContent = (!Test.isRunningTest())?xls_file.getContent():Blob.valueOf('test');

                List<Messaging.EmailFileAttachment> lstAtt = new List<Messaging.EmailFileAttachment>();// SB 21.03.2023 US-0013219
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName('eBay Daily Deals Retail Week ' + dwrw + '.xls');
                efa.setBody(xlsContent);
                efa.setContentType('application/vnd.ms-excel');
                lstAtt.add(efa);
                // SB 21.03.2023 US-0013219 - Seller email notification with PDF Deal Window Agreement when Deal Window is Scheduled
                if(dw.EBH_Country__c == AU_COUNTRY && !mDRCContentVersion.isEmpty()){
                    Messaging.EmailFileAttachment efaPdf = new Messaging.EmailFileAttachment();
                    Blob pdfData = (!Test.isRunningTest())?mDRCContentVersion.get(dwId).VersionData:Blob.valueOf('test');
                    efaPdf.setFileName('eBay Deals Window Agreement Retail Week ' + dwrw + '.pdf');
                    efaPdf.setBody(pdfData);
                    lstAtt.add(efaPdf);
                }
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setOrgWideEmailAddressId(orgWideId);
                email.setTargetObjectId(scId);
                email.setWhatId(dwId);
                //email.setTemplateId(templates.get(0).Id);
                email.setTemplateId(template.Id); // BR-21092022-US-0011147
                email.setFileAttachments(lstAtt); // SB 21.03.2023 US-0013219

                listEmail.add(email);
            }
            
        }

        if (!listEmail.isEmpty() && !Test.isRunningTest()) ApexUtil.sendEmail(listEmail);

    }

    /*****************************************************************************************************************************
    @ Method:   insertDealRetailCampaign
    @ Version:  2.0
    @ Author:   Rishi K
    @ Purpose:  EBAY-345 - Automatically relate records for Deal Window <> Campaign
    ------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08/10/2021 / Rishi K / updated the  Method.
    *****************************************************************************************************************************/

    public static void insertDealRetailCampaign(Map<Id,EBH_DealRetailCampaign__c> mNewDRC){

        Set<Id> allDRCIds = new Set<Id>();
        Set<String> sites = new Set<String>();
        Date startmaxdate;
        Date startmindate;
        for(EBH_DealRetailCampaign__c newsingDRC : mNewDRC.values()){
            
            if(newsingDRC.recordTypeId == recordtypeidDeal_WINDOW_CAMPAIGN){
                
                allDRCIds.add(newsingDRC.id);
                sites.add(newsingDRC.EBH_Country__c);
                if(startmindate!=null && newsingDRC.EBH_Date__c < startmindate) startmindate = newsingDRC.EBH_Date__c;
                else if(startmindate==null) startmindate = newsingDRC.EBH_Date__c;

                if(startmaxdate!=null && newsingDRC.EPH_EndDate__c >startmaxdate) startmaxdate = newsingDRC.EPH_EndDate__c;
                else if(startmaxdate==null) startmaxdate = newsingDRC.EPH_EndDate__c;
                
            }
        }

        if(allDRCIds.size()>0){              
            List<EBH_DealRetailCampaign__c> allDealWindows = new List<EBH_DealRetailCampaign__c>([Select Id, EBH_Date__c, EPH_EndDate__c from EBH_DealRetailCampaign__c WHERE RecordTypeId=:RT_DEALWINDOW AND EBH_Country__c in :sites
                                                                                                AND ((EBH_Date__c <=: startmindate AND EPH_EndDate__c >=: startmindate) OR ( EBH_Date__c >=: startmindate AND EBH_Date__c <=: startmaxdate)) limit 5000]);
            
            Map<Id,EBH_DealRetailCampaign__c> allDealWindowCampaigns = new  Map<Id,EBH_DealRetailCampaign__c>([Select  EBH_DealTitle__c, EPH_EndDate__c ,EBH_Date__c,id,Related_Deal_Retail_Campaign__c, EBH_Description__c from EBH_DealRetailCampaign__c WHERE id in :allDRCIds]); 
            
            List<NA_Deal_Window_Retail_Campaign_Junction__c> createJuctionrecord = new List<NA_Deal_Window_Retail_Campaign_Junction__c>();
            for(EBH_DealRetailCampaign__c newDRC : allDealWindowCampaigns.values()){                                        
                for(EBH_DealRetailCampaign__c rec: allDealWindows){
                    if((rec.EBH_Date__c <= newDRC.EBH_Date__c && rec.EPH_EndDate__c >= newDRC.EBH_Date__c) || (rec.EBH_Date__c >= newDRC.EBH_Date__c && rec.EBH_Date__c <= newDRC.EPH_EndDate__c)){
                        NA_Deal_Window_Retail_Campaign_Junction__c  newDRCjunction = new NA_Deal_Window_Retail_Campaign_Junction__c(); 
                        newDRCjunction.Deal_Retail_Campaign__c = newDRC.id;
                        newDRCjunction.Deal_Window__c=  rec.id;  
                        newDRCjunction.NA_Retail_Campaign_Description__c = newDRC.EBH_Description__c;  
                        newDRCjunction.NA_Retail_Campaign_Title__c =  newDRC.EBH_DealTitle__c;               
                        newDRCjunction.NA_Retail_Campaign_Start_Date__c =  newDRC.EBH_Date__c;                      
                        newDRCjunction.NA_Retail_Campaign_End_Date__c =  newDRC.EPH_EndDate__c;                      
                        createJuctionrecord.add(newDRCjunction);                     
                    }
                }
                                        
            }
            
            if(createJuctionrecord.size()>0){
                DealRetailCampaignTriggerHandler.isFDRCHandler = true; 
                upsert createJuctionrecord;
            }         
           

        }
        
    }

    // logic for update SCH-08092021-ebay-345
    // MN-25112021-US-0010732 - Need to make junction update whenever DealRetailCampaign is update Title/Description
    public static void updateDealRetailCampaign(Map<Id,EBH_DealRetailCampaign__c> mNewDRC, Map<Id,EBH_DealRetailCampaign__c> mOldDRC){
        Map<Id,EBH_DealRetailCampaign__c> mDRCforClone = new Map<Id,EBH_DealRetailCampaign__c>(); 
        Set<Id> rootRecIds = new Set<Id>(); // store the id of record for delete clone       
        for(EBH_DealRetailCampaign__c drc:mNewDRC.values()){
                if(drc.recordTypeId == recordtypeidDeal_WINDOW_CAMPAIGN && (drc.EBH_Date__c != mOldDRC.get(drc.id).EBH_Date__c || drc.EPH_EndDate__c != mOldDRC.get(drc.id).EPH_EndDate__c || drc.EBH_Description__c != mOldDRC.get(drc.Id).EBH_Description__c || drc.EBH_DealTitle__c != mOldDRC.get(drc.Id).EBH_DealTitle__c)){ //MN-25112021-US-0010732 
                    mDRCforClone.put(drc.id,drc);
                    rootRecIds.add(drc.Id); // delete all clone                    
                }
        }
        List<NA_Deal_Window_Retail_Campaign_Junction__c> listrecfordel = new List<NA_Deal_Window_Retail_Campaign_Junction__c>([Select id from NA_Deal_Window_Retail_Campaign_Junction__c where  Deal_Retail_Campaign__c IN: rootRecIds ]);
        DealRetailCampaignTriggerHandler.isFDRCHandler = true;
        if(!listrecfordel.isEmpty()) delete listrecfordel;
        if(!mDRCforClone.isEmpty()) insertDealRetailCampaign(mDRCforClone);
    }
    //SCH-09092021-ebay-345
    public static void deleteDealRetailCampaign(Map<Id,EBH_DealRetailCampaign__c> mOldDRC){
        List<String> drcIds = new List<String>();
        for(Id drcId:mOldDRC.keyset()){
            drcIds.add(drcId);
        }

        List<EBH_DealRetailCampaign__c> dealRetailCampaigns = [SELECT Id, (SELECT Id FROM Deal_Retail_Campaign_Items__r), (SELECT Id FROM Deal_Window_Items__r) FROM EBH_DealRetailCampaign__c WHERE Id IN :drcIds];
        List<NA_Deal_Window_Retail_Campaign_Junction__c> listOfJunctionRecordsToDelete = new List<NA_Deal_Window_Retail_Campaign_Junction__c>();
        for(EBH_DealRetailCampaign__c drc:dealRetailCampaigns){
            listOfJunctionRecordsToDelete.addAll(drc.Deal_Retail_Campaign_Items__r);
            listOfJunctionRecordsToDelete.addAll(drc.Deal_Window_Items__r);
        }

        delete listOfJunctionRecordsToDelete;
        // List<NA_Deal_Window_Retail_Campaign_Junction__c> recs1 = new List<NA_Deal_Window_Retail_Campaign_Junction__c>([Select Deal_Window__c from NA_Deal_Window_Retail_Campaign_Junction__c LIMIT 10]);
        // SYstem.debug('recs1: '+recs1);

        // List<NA_Deal_Window_Retail_Campaign_Junction__c> recs = new List<NA_Deal_Window_Retail_Campaign_Junction__c>([Select id from NA_Deal_Window_Retail_Campaign_Junction__c where Deal_Window__c IN: mOldDRC.keyset()]);
        // SYstem.debug('recs: '+recs);

        // List<NA_Deal_Window_Retail_Campaign_Junction__c> listrecfordel = new List<NA_Deal_Window_Retail_Campaign_Junction__c>([Select id from NA_Deal_Window_Retail_Campaign_Junction__c where Deal_Window__c IN: mOldDRC.keyset() OR Deal_Retail_Campaign__c IN: mOldDRC.keyset() ]);
        // SYstem.debug('listrecfordel: '+listrecfordel);

        // DealRetailCampaignTriggerHandler.isFDRCHandler = true;

        // delete listrecfordel;
    }
    
    /*****************************************************************************************************************************
    @ Method:   setStartAndEndTimeDE
    @ Author:   Sambath Seng (Sambath.seng@gaea-sys.com)
    @ Purpose:  US-0011625 - Bugs/issues and user feedback
	@ Event:    before insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25/4/2022 / Sambath Seng / Create the  Method.
	@				  11/8/2022 / BORA CHHORN - US-0011459 - Deal Retail Campaigns for AU
    @                 25/04/2023 / SRONG TIN / US-0013353 - IT Deals SP Home Page
    *****************************************************************************************************************************/
    public static void setStartAndEndTimeDE(List<EBH_DealRetailCampaign__c> lstNewDRC){
        for(EBH_DealRetailCampaign__c oDRC : lstNewDRC){
            if(oDRC.EBH_Country__c == DE_COUNTRY){
                if(oDRC.Start_Time__c == null){
                    oDRC.Start_Time__c = Time.newInstance(9, 0, 0, 0);
                }
                if(oDRC.End_Time__c == null){
                    oDRC.End_Time__c = Time.newInstance(8, 59, 0, 0);
                }
            } 
            // BORA CHHORN - US-0011459 - Deal Retail Campaigns for AU
            else if(oDRC.EBH_Country__c == AU_COUNTRY){
                if(oDRC.Start_Time__c == null){
                    oDRC.Start_Time__c = Time.newInstance(10, 0, 0, 0);
                }
                if(oDRC.End_Time__c == null){
                    oDRC.End_Time__c = Time.newInstance(23, 59, 0, 0);
                }
            } else if(oDRC.EBH_Country__c == US_COUNTRY){
                if(oDRC.Start_Time__c == null){
                    oDRC.Start_Time__c = Time.newInstance(5, 0, 0, 0);
                }
                if(oDRC.End_Time__c == null){
                    oDRC.End_Time__c = Time.newInstance(4, 59, 0, 0);
                }
            } 
            // 25/04/2023 / SRONG TIN / US-0013353
            else if(oDRC.EBH_Country__c == IT_COUNTRY){
                if(oDRC.Start_Time__c == null){
                    oDRC.Start_Time__c = Time.newInstance(8, 0, 0, 0);
                }
                if(oDRC.End_Time__c == null){
                    oDRC.End_Time__c = Time.newInstance(7, 59, 0, 0);
                }
            }
            // END US-0011459
        }
    }
    /*****************************************************************************************************************************
    @ Method:   createPDFAttachment
    @ Author:   Bora CHHORN (bora.chhorn@gaea-sys.com)
    @ Purpose:  US-0013216 - Attach the T&Cs when the Deal Window is Open for Deal Site=AU
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11/8/2022 / BORA CHHORN - US-0011459 - Deal Retail Campaigns for AU
    *****************************************************************************************************************************/
    @future(callout=true)
    public static void createPDFAttachment(String fileName, String drcId){
        
        Pagereference pdfPage = Page.AgreementTermsDownloadSEPPage;
        pdfPage.getParameters().put(AbstractAgreementTermsController.PARAM_AGMT_MDT_NAME,System.Label.AU_Deal_Window_Agreement_Terms_MDT_Name);
        Blob content = !Test.isRunningTest()?pdfPage.getContentAsPdf():Blob.valueOf('test');

        ContentVersion cVersion = new ContentVersion();
        cVersion.ContentLocation = 'S'; 
        cVersion.PathOnClient = fileName + '.pdf';
        cVersion.Origin = 'C';
        cVersion.OwnerId = ApexUtil.getCurrentUser().Id;
        cVersion.Title = fileName;
        cVersion.VersionData = content;
        //Error: INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.: [NetworkId]
        if (Test.isRunningTest()) {
            Id networkId = [SELECT Id FROM Network LIMIT 1].Id;
            cVersion.NetworkId = networkId;
        }
        insert cVersion;
        
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;

        ContentDocumentLink cDocLink = new ContentDocumentLink();
        cDocLink.ContentDocumentId = contentDocId;
        cDocLink.LinkedEntityId = drcId;
        cDocLink.ShareType = 'V';
        insert cDocLink;
    }
}