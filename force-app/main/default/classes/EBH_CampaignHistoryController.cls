/*********************************************************************************************************************************
@ Class:          EBH_CampaignHistoryController
@ Version:        1.0
@ Author:         JOY MONDOL
@ Purpose:        Extensions for Inline VF page - EBH_CampaignHistory
                  EPH-23 : Campaign Requests
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.06.2017 / JOY MONDOL / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 26.05.2022 / Mony Nou / US-0011525 - Expose Campaign detail on Customer account - AC2
*********************************************************************************************************************************/
public with sharing class EBH_CampaignHistoryController {
    
    Id accountId;
    public Integer RowCount { get; set; }   
    public Decimal PageCount { get; set; }
    public Integer PageNumber { get; set; }
    public Integer PageNumberDisplay { get; set; }
    public Integer PageSize { get { return Integer.valueOf(Label.EBH_DistinctSellerPageSize); } }

    private final String CMPCHANNEL_GCXOUTREACH = 'GCX Outreach (Phone)'; //MN-26052022-US-0011525
    private final String CMPCHANNEL_EMAIL = 'Email'; //MN-26052022-US-0011525
    private final String KEY_TASK = 'TASK'; //MN-26052022-US-0011525
    private final String KEY_IER = 'IER'; //MN-26052022-US-0011525
    
    public List<CampaignMember> CampaignMembers { 
        get {

            //MN-26052022-US-0011525
            Map<String,Map<String, Datetime>> mTaskIERDT = new Map<String,Map<String, Datetime>> {
                KEY_TASK => new Map<String, Datetime>(),
                KEY_IER => new Map<String, Datetime>()
            };

            List<CampaignMember> tmp = (List<CampaignMember>) Database.query(CampaignMemberQuery); 

            for (CampaignMember cm : tmp) {
                if (String.isNotBlank(cm.Related_Task__c)) mTaskIERDT.get(KEY_TASK).put(cm.Related_Task__c,null);
                if (String.isNotBlank(cm.IER_ID__c)) mTaskIERDT.get(KEY_IER).put(cm.IER_ID__c, null);
            }

            if (!mTaskIERDT.get(KEY_TASK).isEmpty()) {
                //Query Task to get Task_Completed_Date__c
                for (Task t : [SELECT Task_Completed_Date__c FROM Task WHERE Id IN:mTaskIERDT.get(KEY_TASK).keySet()]) {
                    if (t.Task_Completed_Date__c != null) mTaskIERDT.get(KEY_TASK).put(t.Id, t.Task_Completed_Date__c);
                }
            }

            if (!mTaskIERDT.get(KEY_IER).isEmpty()) {
                //Query IER to get et4ae5__DateSent__c
                for (et4ae5__IndividualEmailResult__c ier : [SELECT et4ae5__DateSent__c FROM et4ae5__IndividualEmailResult__c WHERE Id IN:mTaskIERDT.get(KEY_IER).keySet()]) {
                    if (ier.et4ae5__DateSent__c != null) mTaskIERDT.get(KEY_IER).put(ier.Id, ier.et4ae5__DateSent__c);
                }
            }

            for (CampaignMember cm : tmp) {
                if (cm.Campaign.EBH_Channel__c == CMPCHANNEL_GCXOUTREACH && mTaskIERDT.get(KEY_TASK).containsKey(cm.Related_Task__c) && mTaskIERDT.get(KEY_TASK).get(cm.Related_Task__c) != null) cm.Date_sent_completed__c = mTaskIERDT.get(KEY_TASK).get(cm.Related_Task__c);
                else if (cm.Campaign.EBH_Channel__c == CMPCHANNEL_EMAIL && mTaskIERDT.get(KEY_IER).containsKey(cm.IER_ID__c) && mTaskIERDT.get(KEY_IER).get(cm.IER_ID__c) != null) cm.Date_sent_completed__c = mTaskIERDT.get(KEY_IER).get(cm.IER_ID__c);
            }
            


            return tmp;


            //return Database.query(CampaignMemberQuery); //MN-26052022-US-0011525
        }
    }
    
    public String CampaignMemberQuery {
        get {
            //query campaign members using pagenumber offset
            String query = EBH_ConstantsUtility.CMQUERY;
            
            String PLACEHOLDER = EBH_ConstantsUtility.FR_BLANK;
            
            //All the fields are being queried which are present in the fieldset
            for(Schema.FieldSetMember fld : SObjectType.CampaignMember.FieldSets.EBH_CampaignMemberFields.getFields()) {
                PLACEHOLDER += EBH_ConstantsUtility.ATCH_COMMA + fld.getFieldPath();
            }

            //MN-26052022-US-0011525
            PLACEHOLDER += ', Related_Task__c, IER_ID__c';
            
            return !String.isBlank(PLACEHOLDER) ? query.replace(EBH_ConstantsUtility.PLACEH, PLACEHOLDER) : 
                   query.replace(EBH_ConstantsUtility.PLACEH, EBH_ConstantsUtility.FR_BLANK);
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:         Constructor - EBH_CampaignHistoryController
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        To get the Seller Id, passed through inline VF page
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      ApexPages.StandardController 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    public EBH_CampaignHistoryController(ApexPages.StandardController controller) {        
        accountId = controller.getId();
        PageNumber = PageNumberDisplay = 0; 
        RowCount = Database.countQuery(EBH_ConstantsUtility.CMCOUNTQUERY);
        PageCount = Math.ceil(Decimal.valueOf(RowCount).divide(PageSize, 1));
    }
    
    /*****************************************************************************************************************************
    @ Method:         first
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        To get the first page of paginated records
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      No Parameters
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    public void first() {
        PageNumber = PageNumberDisplay = 0;
    }
    
   /*****************************************************************************************************************************
    @ Method:         next
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        To get the next set of paginated records
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      No Parameters
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    public void next() {
        PageNumber += PageSize;
        PageNumberDisplay++;
    }
    
    /*****************************************************************************************************************************
    @ Method:         previous
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        To get the previous set of paginated records
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      No Parameters
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    public void previous() {
        PageNumber -= PageSize;
        PageNumberDisplay--;
    }
    
    /*****************************************************************************************************************************
    @ Method:         last
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Used for getting the last set of records
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      No Parameter
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.06.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    public void last() {
        PageNumber = Integer.valueOf(PageCount - 1) * PageSize;
        PageNumberDisplay = Integer.valueOf(PageCount - 1);
    }
}