/*********************************************************************************************************************************@ Class:          ApexUtil
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Utility class for everyone
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 24.12.2018 / Vadhanak Voun / Created the class.
@ Change history: 05.01.2023 / Bora Chhorn / US-0013027 - Add System Admin limited privileges to profiles who can edit contracts
@                 15.05.2023 / Mony Nou / Added new map variable for Date only format
@                 11.08.2023 / vadhanak voun / US-0013997 - Tech Debt: fix hardcoded Id (part 2)
@                 13.11.2023 / Sophal Noch / US-0014345 - Cohort Activation Process Part 1
@                 08.01.2024/ vadhanak voun/ US-0014643 - Hyperforce - Remove hard-coded instance references
@                 06.06.2024 / Acmatac Seing / US-0015181 Adding UniqueId__c to the record
@                 13.08.2024 / Acmatac Seing / US-0015650, US-0015662 : Reusable method to auto link seller whenever a seller or oracleId field get changed Using in Lead, Project and Opportunity
@                 29.08.2024 / Acmatac Seing / US-0015663 - Auto Seller Linking - Project
@                 11.12.2024 / Sothea Horn / US-0015300 - Generic LWC Exception handling & Application to program participation component
@                 15.01.2025 / vadhanak voun / US-0016265 - (2) Upload Sub Deals in Hive
@                 31.07.2025 / Davy Sorn / US-0033116 - Genesys - Pro-Trader Cohort Seller Initiate Call seamless flow
@                 14.10.2025 / Davy Sorn / US-0033595 - CA SP - Fix SP UI Contract Display Issues
*********************************************************************************************************************************/
public without sharing class ApexUtil {

    //NK:11/08/2023:US-0013997
    public final static String PROFILE_GCX_PARTNER_ID = '00e6A000001o6m4QAA'; 
    public final static String GCX_RT_ID = '0126A000000M9xKQAS'; 
    public final static String PERMISSION_SET_LICENSE_COMMUNITYWAVE_ID = '0PL6A000000MD9LWAW';
	public final static String PERMISSION_SET_COMMUNITY_ANALYTICS_ID = '0PS6A000001p7NzWAI';
    public final static String CAMP_RECORDTYPE_OUTREACH_ID = '0126A0000009qNBQAY';
    public final static String COMMUNITY_SITE_ID = '0DB6A000000UABsWAO';
    public static final string VALIDATE_SURVEY_RECORDTYPEID='0123u0000019nl3AAA';
    //--NK:11/08/2023:US-0013997

    public final static String ADMIN_PROFILE_ID = '00e6A000000HNzwQAG'; //MN-06082021-US-0009746
    public final static String INTEGRATION_USER_ID = '0056A000000zaxM'; //MN-17092021-US-0010407
    public final static String ADMIN_LT_PRIV_PROFILE_ID = '00e3u000000S5pPAAS'; //Sophal-31032022-US-0011453
    public final static String PROFILE_ID_STANDARD='00e6A000000hSSQQA2'; //BR-05012023-US-0013027
    public final static String BUSINESS_ADMIN_PROFILE = '00e6A000000hSSOQA2'; //VM-US-0015680
    public final static String NA_STANDARD_USER_PROFILE_ID = '00e3u000000VTthAAG';//TH-US-0015571
    //NK:08/01/2021:US-0008785
    public static String encryptionkey = '01IS0000000IZrJX';

    //NK:29/12/2020
    public final static map<String,String> MAP_COUNTRY_LANG = new Map <String,STring>{'de'=>'de','uk'=>'en','es'=>'es','fr'=>'fr','it'=>'it','us'=>'en','ca'=>'en','au'=>'en'};   
    public final static map<String,String> MAP_CODE_LANG = new Map <String,STring>{'77'=>'de','3'=>'en','186'=>'es','71'=>'fr','101'=>'it','1'=>'en','2'=>'en','15'=>'en'};
    public final static Map<String,String> MAP_COUNTRY_CODE  = new Map<String,String>{
        '3'=> 'UK','77'=> 'DE','71'=> 'FR','101'=> 'IT','186'=> 'ES','163'=> 'PL','99'=> 'IE','193'=> 'CH','146'=> 'NL','23'=> 'BE','168'=> 'EEC-Unsited','15'=> 'AU','1'=>'US','2'=>'CA',
        'UK'=>'3','DE'=>'77','FR'=>'71','IT'=>'101','ES'=>'186','PL'=>'163','IE'=>'99','CH'=>'193','NL'=>'146','BE'=>'23','EEC-Unsited'=>'168','AU'=>'15','US'=>'1','CA'=>'2'
    };

    //TH:07/06/2022:Move from EBH_ConstantsUtility
    public final static string TRIGGERCONTROLLER     = 'EBH Trigger Controller'; //custom setting name

    public static final string SOQL_ORGWIDE = 'select id,Address from OrgWideEmailAddress';
    public static Map<String,EmailTemplate> mapEmailTemplate = new Map<String,EmailTemplate>();
    public final static String COUPON_BULK_EDITS_CUSTOM_PERMISSION='Coupon_Bulk_Edits_Custom_Permission';// 14.06.2023 / Acmatac Seing / US-0013714
    public final static String ACCESS_GENESYS_CUSTOM_PERMISSION='Access_Genesys'; // 31.07.2025 / Davy Sorn / US-0033116
    public static final String ACCOUNT_SOQL = 'SELECT Id, Name, Website, EBH_VATNumber__c, EBH_OracleId__c FROM Account ';

    private static final Set<String> SET_BATCH_RUNNING_STATUS = new Set<String>{'Holding', 'Queued','Processing','Preparing'}; // 13.11.2023 / Sophal Noch / US-0014345


    private static Map<String,String> localeToDateTimeFmtMap;
    private static Map<String, String> localeToDateFmtMap; //MN-15052023
    private static final String LOGIN_FAILED_PREFIX = 'LNF';
    private static final String COUPON_PREFIX = 'CPN';
    private static final String DEAL_PREFIX = 'DL';
    private static final String GENERAL_PREFIX = 'GEN';
    //11.12.2024 / Sothea Horn / US-0015300 - Generic LWC Exception handling & Application to program participation component
    private static final String LWC_FAILED_PREFIX = 'LWCF'; 

    //NK:03/06/2019: 
    //e.g. formatNumber(123456789,',','.',3) -> 123,456,789.000
    public static String formatNumber(Decimal val, String osep, String nsep, Integer sclVal)
    {
        osep =  String.isEmpty(osep)?'!*!':osep;
        if(val == null){val = 0;}
        String s, tmp; Integer i = (sclVal==0?3: (4+sclVal)); //3: thousand char 
        s = val.setScale(sclVal).toPlainString().replace(osep, nsep);
        String negSign = s.startsWith('-')?'-':''; //preserve the minus sign
        s = s.replace('-',''); //remove it for cal then add later
        osep = osep.replace('!*!','');
        while(s.length() > i)
        {
            tmp = s.substring(0, s.length() - i) + osep + s.substring(s.length() - i);
            s = tmp;
            i += 4;
        }
        return negSign+s;
    }
    public static String formatNumber(Decimal val,Integer n_scale,String countryCode)
    {
        String osep = map_K_Separator.containsKey(countryCode)?map_K_Separator.get(countryCode):map_K_Separator.get('UK');
        String nsep = mapNumSeparator.containsKey(countryCode)?mapNumSeparator.get(countryCode):mapNumSeparator.get('UK');
        return formatNumber(val,osep,nsep,n_scale);
    }
    private static Map<String,String> mapNumSeparator = new Map<String,String>
    {
        'DE'=>',','UK'=>'.','EN'=>'.','FR'=>',','IT'=>',','ES'=>','
    };
    private static Map<String,String> map_K_Separator = new Map<String,String>
    {
        'DE'=>'.',      //4 294 967.295,000  
        'UK'=>',',      //4,294,967,295.00  
        'EN'=>',',      //4,294,967,295.00  
        'FR'=>' ',      //4 294 967 295,000  
        'IT'=>'.',      //4.294.967.295,000 
        'ES'=>'.'       //4.294.967.295,000  
    };
    //NK:03/06/2019
    public static Object checkNull(Object o)
    {
        return (o==null?'':o);
    }
    public static String nullStr(Object o)
    {
        return (o==null?'':o+'');
    }
    public static String formatTime(Time myTime)
    {
        return myTime==null?'': Datetime.newInstance(Date.today(), myTime).format('h:mm a');
    }
    public static Map<String,String> mapCurrencySign = new Map<String,String>
    {   'AUD'=>'$',
        'GBP'=>'£',
        'EUR'=>'€',
        'PLN'=>'zł',
        'CHF'=>'CHF',
        'USD'=>'$',
        'CAD'=>'CAD' //US-0033595 - CA SP - Fix SP UI Contract Display Issues
    };
    public static Decimal toDecimal(String s,Integer scale)
    {
        try{
            return (s==null?null:Decimal.valueOf((s+'')).setScale(scale));
        }catch(Exception ex)
        {
            return null;
        }
         
    } 

    public static Decimal toDecimal0(String s,Integer scale)
    {
        Decimal tmp = toDecimal(s,scale);
        return (tmp==null?0:tmp);
    
    } 

    public static Integer toInteger(String s)
    {
        try{
            return (s==null?0:Integer.valueOf((s+'')));
        }catch(Exception ex)
        {
            return null;
        }
         
    } 
    public static Double toDouble(String s)
    {
        try{
            return Double.valueOf((s+'').replace(',','.'));
        }catch(Exception ex)
        {
            return null;
        }
        
    } 
    public static Long toLong(String s)
    {
        try{
            return (s==null?0:Long.valueOf((s+'')));
        }catch(Exception ex)
        {
            return null;
        }
         
    }   
    private static Map<String,UserRole> mapUserRole;
    public static Userrole getUserRoleByName(String userRolename){
        if (mapUserRole==null){
            mapUserRole = new Map<String,UserRole>();
            for (UserRole ur :[select id,name from UserRole]){
                mapUserRole.put(ur.name,ur);
            }
        }
        return mapUserRole.get(userRolename);
    }
    //NK:20/11/2018: reduce soql
    private static Map<String,RecordType> mapRecordType;
    public static RecordType getRecordTypeByName(String sobjectName,String recordTypeName)
    {
        if(mapRecordType==null)
        {
            mapRecordType = new Map<String,RecordType>();
            for(RecordType rt : [SELECT id,sobjectType,DeveloperName from RecordType])
            {
                mapRecordType.put(rt.sobjectType+''+rt.DeveloperName,rt);
            }
        } 
        return mapRecordType.get(sobjectName+recordTypeName);
    } 
    //TH : 10/04/2019
    public static Map<String,RecordType> getRecordTypeBySobjectName(String sobjectName){
        Map<String,RecordType> mapRecordType = new Map<String,RecordType>();
        for(RecordType rt : [SELECT id,sobjectType,DeveloperName from RecordType where sobjectType =: sobjectName]){
            mapRecordType.put(rt.DeveloperName,rt);
        }
        return mapRecordType;
    }
    //NK:08/03/2019
    public static void doSend(String subject,String email,String bodHtml){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setToAddresses(new String[]{email});
                        mail.setSenderDisplayName('Hive Support');
                        mail.setSubject(subject);
                        mail.setBccSender(false);
                        mail.setUseSignature(false); 
                        mail.setHtmlBody(bodHtml);
        if(!test.isRunningTest()) Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
    }
    //NK:05/04/2019
    public static Boolean checkPermissionSet(Set<String> setPName)
    {
        String currentUserId = UserInfo.getUserId();
        String sWhere = ' WHERE AssigneeId =:currentUserId AND PermissionSet.Name IN :setPName';     
        List<PermissionSetAssignment> listPSA = Database.query(EBH_ConstantsUtility.SOQL_PERMISSIONSET_ASSIGNMENT + sWhere); 
        return !listPSA.isEmpty();
    }
    //NK:18/04/2019
    public static Object getValue(String fieldName,Sobject sobj)
   {    
            String[] sFields = fieldName.split('[.]');
            Integer i = 1;
            Sobject tmp = sobj;
            //ParentTicket__r.Opportunity__r.Name
            //ParentTicket__r.Name
            //Name
            while(i<sFields.size() && tmp<>null) //0 < 3
            {
                tmp = tmp.getSObject(sFields[i-1]);
                i++;
            }
         return tmp==null?null:tmp.get(sFields[i-1]);
     }
    //DHE 2019-05-09
    public static Boolean runningInASandbox() {
  return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
}
    //NK:15/05/2019:  
    public static String getSiteUrl(String siteName)
    {
        if(mapSiteUrl==null)
        {
            mapSiteUrl = new Map<String,String>();
            Map<String,String> siteIds = new Map<String,String>();
            for(Site site1: [SELECT Id, GuestUserId, Name, Subdomain, UrlPathPrefix FROM Site])
            {
                siteIds.put((site1.Id+'').substring(0,15),site1.Name);
            }
            for(SiteDetail sdt: [Select SecureUrl, IsRegistrationEnabled, Id, DurableId From SiteDetail where DurableId IN:siteIds.keySet()])
            {
                mapSiteUrl.put(siteIds.get(sdt.DurableId),sdt.SecureUrl); //DurableId: 15 char
            }
        }
        return mapSiteUrl.get(siteName);
    }
    private static Map<String,String> mapSiteUrl;
    public static Map<Id,User> getUsersMemberByGroup(Set<String> setGoups)
    {
        Map<Id,User> mapUser = new Map<Id,User>();
        Set<String> setUserId = new Set<String>();
        for(GroupMember gm: Database.query(EBH_ConstantsUtility.SOQL_GROUP_MEMBER))
        {
            //filter only user
            if(gm.UserOrGroupId.getSObjectType()==Schema.User.SObjectType)
            {
                setUserId.add(gm.UserOrGroupId);
            }               
        }
        if(Test.isRunningTest())
        {
            setUserId.add(UserInfo.getUserId());
        }
        if(!setUserId.isEmpty())
        {
             mapUser = new Map<Id,User>((List<User>)Database.query(EBH_ConstantsUtility.SOQL_BOB_USER_BY_ID +' AND isActive=true'));
        } 
        return mapUser;
    }
    //NK:21/06/2019: Set<String> to quoted string: 'A','B','C' 
    public static String constructQuoteString(Set<String> setString)
    {
        return ('\''+String.join(new List<String>(setString),'\',\'')+'\''); 
    }
    public static String constructQuoteString(List<String> listString)
    {
        return ('\''+String.join(listString,'\',\'')+'\''); 
    }
    //NK:19/07/2019: ->f1,f2,f3...
    public static String generateSQOLFields(String sobjectName)
    {
        return  doGenerateSQOLFields(sobjectName,true,new Set<String>{});//access only
    }

    //access only or All Field without access checking
    public static String generateSQOLFields(String sobjectName,Boolean accessOnly)
    {
        return doGenerateSQOLFields(sobjectName,accessOnly,new Set<String>{});
    }
    //NK:25/04/2025 - added setExculdedFields to exclude fields from the result
    public static String generateSQOLFields(String sobjectName,Boolean accessOnly,Set<String> setExculdedFields)
    {
        return doGenerateSQOLFields(sobjectName,accessOnly,setExculdedFields);
    }

    private static String doGenerateSQOLFields(String sobjectName,Boolean accessOnly,Set<String> setExculdedFields)
    {
        List<String> fieldsResult = new List<String>();
        Map<String, Schema.SObjectField> allFieldDes = Schema.getGlobalDescribe().get(sobjectName).getDescribe().fields.getMap();
        for(Schema.SObjectField f  : allFieldDes.values())
        {
            String apiNameField = f.getDescribe().getName();
            if(((accessOnly && f.getDescribe().isAccessible()) || !accessOnly) && !setExculdedFields.contains(apiNameField))
            {
                fieldsResult.add(apiNameField);
            }
        }
        if(!fieldsResult.isEmpty())
        {
            return String.join(fieldsResult,',').replace('IndividualId,',''); 
            //IndividualId: Data Protection and PrivacyHelp for this Page
            //When Query: No such column 'IndividualId' on entity 'Contact'
        }
        return null;
    }

    public static Boolean doCompare(String operator,Decimal val1,Decimal val2)
    {
        val1 = val1==null?0:val1;
        val2 = val2==null?0:val2;
        if(operator=='=')
        {
            return val1 == val2;
        }else if(operator=='<=')    
        {
            return val1<= val2;
        }else if(operator=='<')
        {
            return val1<val2;
        }else if(operator=='>')
        {
            return val1>val2;
        }else if(operator=='>=')
        {
            return val1>=val2;
        }
        return false;
    }
    //NK:06/11/2020:128->256
    public static String genUniqueString(Integer len)
    {
        Blob blobKey = crypto.generateAesKey(256);
        String key = EncodingUtil.base64encode(blobKey);
        return key.substring(0, len <=key.length()?len:key.length() ); //e.g. Iwy3RWl1M+uuLZbHeZzuPDEJalO1t/cdQhOr/9lVzBo=
    }

    //TH:26/07/2022:US-0012199
    public static String genUniqueStringNoSymbol(Integer len)
    {
        String uniqueString = ApexUtil.genUniqueString(len);
        return uniqueString.replaceAll('[^a-zA-Z0-9]', '');
    }

    /*
    NK:02/10/2019
        check if batch alreay running or about to run to preven duplicate job 
    */
    public static Map<String,Integer> countRunningBatch(Set<String> batchClassNames)
    {
        Map<String,Integer> mapResult = new Map<String,Integer>();
        Set<String> runningStatus = new Set<String>{'Queued','Processing','Preparing'};
        AggregateResult[] result =  [Select ApexClass.Name className,count(Id) countx  FROM AsyncApexJob WHERE ApexClass.Name IN :batchClassNames AND Status IN: runningStatus group by ApexClass.Name];
        for(aggregateresult ar : result)
        {
         //system.debug('>>class: '+ar.get('className') + ' >>: '+ ar.get('countx'));
         mapResult.put(ar.get('className')+'',(Integer)ar.get('countx'));
        }
        for(String cname: batchClassNames)
        {
            if(mapResult.get(cname) ==null)
            {
                mapResult.put(cname,0);
            }
        }
        return mapResult;
    }

    /*********************************************************************************************************************************
    @ Method:         countRunningBatchByUser
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014345 - Cohort Activation Process Part 1
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  13.11.2023 / Sophal Noch / Created the method.
    ----------------------------------------------------------------------------------------------------------------------------------
    *********************************************************************************************************************************/
    public static Integer countRunningBatchByUser(Set<String> setBatchName, Set<String> setJobType, Set<Id> setUserId){
        Integer countRunningBatch = [SELECT Count() from AsyncApexJob Where ApexClass.Name IN: setBatchName And JobType IN: setJobType And CreatedById IN: setUserId And Status IN : SET_BATCH_RUNNING_STATUS];
        return countRunningBatch;
    }

    //NK:15/11/2019
    public static CronTrigger[] findCronJob(Set<String> batchClassNames)
    {
        Set<String> setStates = new Set<String>{'WAITING','PAUSED','BLOCKED','PAUSED_BLOCKED'};//ACQUIRED,EXECUTING,PAUSED,BLOCKED,PAUSED_BLOCKED
        //7: schedule apex, 9 batch
        return [Select TimesTriggered, State, StartTime, PreviousFireTime, NextFireTime, Id, EndTime, CronJobDetailId, CronExpression From CronTrigger c where CronJobDetail.Name IN:batchClassNames AND CronJobDetail.JobType IN ('7','9') AND State in:setStates];
    } 
   //NK:17/11/2019: get dependant picklist value 
    public static Map<String, List<PicklistEntryWrapper>> getDependentMap(Schema.sObjectType objType, string contrfieldApiName,string depfieldApiName) {
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();
        Map<String,List<PicklistEntryWrapper>> objResults = new Map<String,List<PicklistEntryWrapper>>();
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        Schema.SObjectField theField = objFieldMap.get(dependentField);
        Schema.SObjectField ctrlField = objFieldMap.get(controllingField);
        List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
        List<String> controllingValues = new List<String>();
        for (Schema.PicklistEntry ple : contrEntries) {
            //String label = ple.getLabel();
            //objResults.put(label, new List<String>());
            //controllingValues.add(label);
            if(ple.isActive())
            {
                String val = ple.getValue();
                objResults.put(val, new List<PicklistEntryWrapper>());
                controllingValues.add(val);
            }
        }
        for (PicklistEntryWrapper plew : depEntries) {
            String label = plew.label;
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    ((List<PicklistEntryWrapper>)objResults.get(controllingValues.get(i))).add(plew);
                }
            }
        }
        return objResults;
    }
    private static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }
    private static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';
        String validForBits = '';
        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        return validForBits;
    }
    private static final String base64Chars = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';
    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }
    public class PicklistEntryWrapper{
        @auraEnabled public String active {get;set;}
        @auraEnabled public String defaultValue {get;set;}
        @auraEnabled public String label {get;set;}
        @auraEnabled public String value {get;set;}
        public String validFor {get;set;}
        public PicklistEntryWrapper(){            
        }
    }
    public static List<Map<String,String>> getPicklistValues(Schema.SObjectField pklField)
    {
        List<Map<String,String>> listResult = new List<Map<String,String>>();
        for(Schema.PicklistEntry pkl: pklField.getDescribe().getPicklistValues())
        {
            if(pkl.isActive())
            {
                listResult.add(new Map<String,String>{'label'=>pkl.getLabel(),'value'=>pkl.getValue(),'isActive'=>pkl.isActive()+'','isDefaultValue'=>pkl.isDefaultValue()+''});    
            }
        }
        return listResult;
    }
    public static PicklistEntryWrapper getSpecificPicklistValue(Schema.SObjectField pklField, String pklVal)
    {
        PicklistEntryWrapper oResult = new PicklistEntryWrapper();
        for(Schema.PicklistEntry pkl: pklField.getDescribe().getPicklistValues())
        {
            if(pkl.isActive() && pklVal == pkl.getValue())
            {
                oResult.label = pkl.getLabel();
                oResult.value = pkl.getValue();
                oResult.defaultValue = pkl.isDefaultValue()+'';
                return oResult;
            }
        }
        return oResult;
    }
    public static String getFieldIdRef(String fullNamePath)
    {
        if(fullNamePath.contains('.') )
        {
            String fId = fullNamePath.substring(0,fullNamePath.lastIndexOf('.'))+'.Id';
            return fId;
        }
        return fullNamePath;
    }
    // public static Profile getProfileByName(String name)
    // {
    //     return [SELECT Name FROM Profile WHERE Name =: name];
    // }
    private static Map<String,Profile> mProfile;
    public static Profile getProfileByName(String name)
    {
        if(mProfile==null)
        {
            mProfile = new Map<String, Profile>();
            for(Profile profl : Database.query('SELECT Id, Name FROM Profile'))
            {
                mProfile.put(profl.Name, profl);
            }
        } 
        return (mProfile.containsKey(name)) ? mProfile.get(name):null;
    }
    //correct number. e.g. from csv. user selected opion of format
    public static String fixNumber(String value, String locale){
        value = value.replaceAll('[^0-9.,]', '');
        value = locale == 'de' ? value.replace('.','').replace(',','.') : value.replace(',','');
        return value;
    }
    //NK: check if userid is a member of permission set
    public static Set<String> permissionSetMembers(String setPName)
    {
        Set<String> setPSA = new Set<String>();
        String sWhere = ' WHERE PermissionSet.Name =:setPName';  
         for(PermissionSetAssignment psa: Database.query(EBH_ConstantsUtility.SOQL_PERMISSIONSET_ASSIGNMENT + sWhere))
         {
            setPSA.add(psa.AssigneeId);
         }
        return setPSA;
    }
    private static User currentUser = null;
    public static User getCurrentUser()
    {
        if(currentUser==null)
        {
            Set<String> setUser = new Set<String>{UserInfo.getUserId()};
            currentUser =  Database.query(EBH_ConstantsUtility.SOQL_User);
        }
        return currentUser;
    }
    
    private static Map<String,PermissionSetLicense> mapPSL;
    //NK:20/07/2020: get PermissionSetLicense (not simiple permission set)
    public static PermissionSetLicense getPermissionSetL(String psl_DEVName)
    {
        if(mapPSL==null)
        {
            mapPSL = new Map<String,PermissionSetLicense>();
            for(PermissionSetLicense psl: [Select Id,MasterLabel,DeveloperName,TotalLicenses From PermissionSetLicense]){
                mapPSL.put(psl.DeveloperName,psl);
            }
        }
        return mapPSL.get(psl_DEVName);
    } 
    
    //TH: 02/09/2020    : get OrgWideEmailAddress by email
    private static Map<String,OrgWideEmailAddress> mapOrgWide;
    public static OrgWideEmailAddress getOWDbyAddress(String addr){
        if(mapOrgWide == null){
            mapOrgWide = new Map<String,OrgWideEmailAddress>();
            for(OrgWideEmailAddress orgWide : Database.query(SOQL_ORGWIDE)){
                mapOrgWide.put(orgWide.Address, orgWide);
            }
        }
        return mapOrgWide.get(addr);
    }
    /*********************************************************************************************************************************
    @ Method:         getFieldSet
    @ Version:        1.0
    @ Author:         Sreymeas Nao (sreymeas.nao@gaea-sys.com)
    @ Purpose:        US-0008103 - [US]* Deals Internal Bulk/Mass Approval Functionality
                      It was migrated from join instance with original name: DD_Utils.getFieldSet
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    String strToEncrypt, String pkey
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  02/10/2020 / Sreymeas Nao / Created the method.
    *********************************************************************************************************************************/
    public static String getFieldSet(String sObjectName, String fieldSetName) {
        String result = '';
        try{
            SObjectType objToken = Schema.getGlobalDescribe().get(sObjectName);
            Schema.DescribeSObjectResult d = objToken.getDescribe();
            Map<String, Schema.FieldSet> FsMap = d.fieldSets.getMap();
     
            if(FsMap.containsKey(fieldSetName))
                for(Schema.FieldSetMember f : FsMap.get(fieldSetName).getFields()) {
                    if(result != ''){
                        result += ',';
                    }
                    String jsonPart = '{';
                    jsonPart += '"label":"' + f.getLabel() + '",';
                    jsonPart += '"required":"' + (f.getDBRequired() || f.getRequired()) + '",';
                    jsonPart += '"type":"' + (f.getType()) + '",';
                    jsonPart += '"name":"' + f.getFieldPath() + '"';
                    jsonPart += '}';
                    result += jsonPart;
            }
        }
        catch(Exception e){
            result += e.getLineNumber() + ' : ' + e.getMessage();
        }
        return '['+result+']';
    }
	//NK:15/10/2023:US-0014270
    public static List<Object> getFieldSet(String sObjectName, String fieldSetName,Boolean respectPermission) 
    {
        List<Object> listResult = new List<Object>();
         
        SObjectType objToken = Schema.getGlobalDescribe().get(sObjectName);
        Schema.DescribeSObjectResult d = objToken.getDescribe();
        Map<String, Schema.FieldSet> FsMap = d.fieldSets.getMap();
    
        if(FsMap.containsKey(fieldSetName))
            for(Schema.FieldSetMember f : FsMap.get(fieldSetName).getFields()) 
            {
                if(respectPermission && !f.getSObjectField().getDescribe().isAccessible())continue;
                listResult.add(
                    new Map<String,Object>{'label'=>f.getLabel(),
                    'required'=>(f.getDBRequired() || f.getRequired()),
                    'type'=>f.getType()+'',
                    'value'=>f.getFieldPath(),
                    'referenceto'=>f.getType()==Schema.DisplayType.REFERENCE?f.getSObjectField().getDescribe().getReferenceTo().get(0)+'':null
                }
                );
               
        }
    
        
        return listResult;
    }
    

    /*********************************************************************************************************************************
    @ Method:         prepareEmail
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008230 
                      It was migrated from join instance with original name: DD_Utils.prepareEmail
                      it for preparing email before sending them.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    targetobjectid : object id, tos: main recipients, cc : more recipients, templateName : email template, 
                    defaulttemplate: default email template, binding : field to replace in email content, 
                    sendFromName : sender display name in email, owa: Id of Organization-Wide Email Address
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  07.10.2020 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    public static Messaging.SingleEmailMessage prepareEmail(String targetobjectid, String[] tos, String cc, String templateName, String defaulttemplate, Map<String,String> binding, String sendFromName, OrgWideEmailAddress owa) {
       
        // read from cache
        EmailTemplate template = mapEmailTemplate.get(templateName);
        
        if (template==null) {
            List<EmailTemplate> templates = [select Id, Name, Body, Subject, HtmlValue, DeveloperName from EmailTemplate where DeveloperName =:templateName];
           
            
            if (templates.isEmpty()) {
                
                template = [select Id, Name, Body, Subject, HtmlValue, DeveloperName from EmailTemplate where DeveloperName =:defaulttemplate LIMIT 1];
    
            } else {
                template = templates.get(0);
            }
            
            // put in cache
             mapEmailTemplate.put(templateName,template);
        }
        
        // build body
        String body = template.HtmlValue;
        String subject = template.Subject;
   
        if (binding!=null)
        for (String k : binding.keySet()) {
            if(binding.get(k) != null) {
                body = body.replace(k,binding.get(k));
                subject = subject.replace(k,binding.get(k));
            }
        }  
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
         
        if (targetobjectid==null) {
            email.setSubject(subject);
            email.setHtmlBody(body); 
            email.setToAddresses(tos);
            if(sendFromName != null) email.setSenderDisplayName(sendFromName);
            if(owa != null) email.setOrgWideEmailAddressId(owa.Id);
        } else {
            email.setTargetObjectId(targetobjectid);
            email.setTemplateId(template.Id);
        }
        
     
        
        return email;
        
    }
    
    /*********************************************************************************************************************************
    @ Method:         sendEmail
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008230 
                      It was migrated from join instance with original name: DD_Utils.sendEmail
                      it is for sending email
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    emails: list of email to send
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  07.10.2020 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    public static Messaging.SendEmailResult[] sendEmail(List<Messaging.SingleEmailMessage> emails) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);
            if (results[0].success) {System.debug('The email was sent successfully.');
            } else {System.debug('The email failed to send: ' + results[0].errors[0].message);}
            return results;
      
    }
    /*********************************************************************************************************************************
    @ Method:         doEncrypt
    @ Version:        1.0
    @ Author:         Sreymeas Nao (sreymeas.nao@gaea-sys.com)
    @ Purpose:        US-0008102 
                      It was migrated from join instance with original name: DD_Utils.doEncrypt
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    String strToEncrypt, String pkey
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  23.10.2020 / Sreymeas Nao / Created the method.
    *********************************************************************************************************************************/
    public static String doEncrypt(String strToEncrypt, String pkey) {
        
        Blob key =  Blob.valueOf(pkey);
        Blob data = Blob.valueOf(strToEncrypt);
        Blob encrypted = Crypto.encryptWithManagedIV('AES128', key, data);
        return EncodingUtil.base64Encode(encrypted); 
        
    }

    /*********************************************************************************************************************************
    @ Method:         generateUniqueString
    @ Version:        1.0
    @ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:        US-0011631 - Create invocable method to encrypt SF record Ids or generate random unique value
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    List<ID> ids
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.05.2022 / Sovantheany Dim / Created the method.
    @                   26.07.2022 / Sovantheany Dim / US-0012199 - Minor Improvements required to finis work with MC team
    *********************************************************************************************************************************/
    @InvocableMethod(label='generateUniqueString' description='Generate random unique value')
    public static List<String> generateUniqueString(List<ID> ids) {
        List<String> lstUniqueString = new List<String>();
        for(ID objectId : ids){
            lstUniqueString.add(ApexUtil.genUniqueStringNoSymbol(40));
        }
        return lstUniqueString;   
    }

     /*********************************************************************************************************************************
    @ Method:         validSFId
    @ Version:        1.0
    @ Author:         vadhanak.voun(vadhanak.voun@gaea-sys.com)
    @ Purpose:        check if the string is a valid sfid. sfdc throws error is id is not valid
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    String to validate
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  06.11.2020 / vadhanak.voun / Created the method.
    *********************************************************************************************************************************/
    public static Boolean validSFId(String sfId)
    {         
        return sfId instanceOf Id;
    }


    /*********************************************************************************************************************************
    @ Method:         getLocaleToDateTimeFmtMap
    @ Version:        1.0
    @ Author:         Ratha.Sim(ratha.sim@gaea-sys.com)
    @ Purpose:        Returns a map of user locale | datetime format for that locale
    ------------------------------------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  21.12.2020 / ratha.sim / Created the method.
    @                  06.06.2025 / Mony Nou / US-0002188 - Contract preview is not loading on Coupon(Seller)
    *********************************************************************************************************************************/
    public static Map<String,String> MAP_LOCALE_DATEFORMAT() {
        if(localeToDateTimeFmtMap != null) {
            return localeToDateTimeFmtMap;
        }
        localeToDateTimeFmtMap = new Map<String,String> {
                'ar'            => 'dd/MM/yyyy hh:mm a',
                'ar_AE'         => 'dd/MM/yyyy hh:mm a',
                'ar_BH'         => 'dd/MM/yyyy hh:mm a',
                'ar_JO'         => 'dd/MM/yyyy hh:mm a',
                'ar_KW'         => 'dd/MM/yyyy hh:mm a',
                'ar_LB'         => 'dd/MM/yyyy hh:mm a',
                'ar_SA'         => 'dd/MM/yyyy hh:mm a',
                'bg_BG'         => 'yyyy-M-d H:mm',
                'ca'            => 'dd/MM/yyyy HH:mm',
                'ca_ES'         => 'dd/MM/yyyy HH:mm',
                'ca_ES_EURO'    => 'dd/MM/yyyy HH:mm',
                'cs'            => 'd.M.yyyy H:mm',
                'cs_CZ'         => 'd.M.yyyy H:mm',
                'da'            => 'dd-MM-yyyy HH:mm',
                'da_DK'         => 'dd-MM-yyyy HH:mm',
                'de'            => 'dd.MM.yyyy HH:mm',
                'de_AT'         => 'dd.MM.yyyy HH:mm',
                'de_AT_EURO'    => 'dd.MM.yyyy HH:mm',
                'de_CH'         => 'dd.MM.yyyy HH:mm',
                'de_DE'         => 'dd.MM.yyyy HH:mm',
                'de_DE_EURO'    => 'dd.MM.yyyy HH:mm',
                'de_LU'         => 'dd.MM.yyyy HH:mm',
                'de_LU_EURO'    => 'dd.MM.yyyy HH:mm',
                'el_GR'         => 'd/M/yyyy h:mm a',
                'en_AU'         => 'd/MM/yyyy HH:mm',
                'en_B'          => 'M/d/yyyy h:mm a',
                'en_BM'         => 'M/d/yyyy h:mm a',
                'en_CA'         => 'dd/MM/yyyy h:mm a',
                'en_GB'         => 'dd/MM/yyyy HH:mm',
                'en_GH'         => 'M/d/yyyy h:mm a',
                'en_ID'         => 'M/d/yyyy h:mm a',
                'en_IE'         => 'dd/MM/yyyy HH:mm',
                'en_IE_EURO'    => 'dd/MM/yyyy HH:mm',
                'en_NZ'         => 'd/MM/yyyy HH:mm',
                'en_SG'         => 'M/d/yyyy h:mm a',
                'en_US'         => 'M/d/yyyy h:mm a',
                'en_ZA'         => 'yyyy/MM/dd hh:mm a',
                'en_DE'         => 'dd/MM/yyyy', //MN-06062025-US-0002188
                'es'            => 'd/MM/yyyy H:mm',
                'es_AR'         => 'dd/MM/yyyy HH:mm',
                'es_BO'         => 'dd-MM-yyyy hh:mm a',
                'es_CL'         => 'dd-MM-yyyy hh:mm a',
                'es_CO'         => 'd/MM/yyyy hh:mm a',
                'es_CR'         => 'dd/MM/yyyy hh:mm a',
                'es_EC'         => 'dd/MM/yyyy hh:mm a',
                'es_ES'         => 'd/MM/yyyy H:mm',
                'es_ES_EURO'    => 'd/MM/yyyy H:mm',
                'es_GT'         => 'd/MM/yyyy hh:mm a',
                'es_HN'         => 'MM-dd-yyyy hh:mm a',
                'es_MX'         => 'd/MM/yyyy hh:mm a',
                'es_PE'         => 'dd/MM/yyyy hh:mm a',
                'es_PR'         => 'MM-dd-yyyy hh:mm a',
                'es_PY'         => 'dd/MM/yyyy hh:mm a',
                'es_SV'         => 'MM-dd-yyyy hh:mm a',
                'es_UY'         => 'dd/MM/yyyy hh:mm a',
                'es_VE'         => 'dd/MM/yyyy hh:mm a',
                'et_EE'         => 'd.MM.yyyy H:mm',
                'fi'            => 'd.M.yyyy H:mm',
                'fi_FI'         => 'd.M.yyyy H:mm',
                'fi_FI_EURO'    => 'd.M.yyyy H:mm',
                'fr'            => 'dd/MM/yyyy HH:mm',
                'fr_BE'         => 'd/MM/yyyy H:mm',
                'fr_CA'         => 'yyyy-MM-dd HH:mm',
                'fr_CH'         => 'dd.MM.yyyy HH:mm',
                'fr_FR'         => 'dd/MM/yyyy HH:mm',
                'fr_FR_EURO'    => 'dd/MM/yyyy HH:mm',
                'fr_LU'         => 'dd/MM/yyyy HH:mm',
                'fr_MC'         => 'dd/MM/yyyy HH:mm',
                'hr_HR'         => 'yyyy.MM.dd HH:mm',
                'hu'            => 'yyyy.MM.dd. H:mm',
                'hy_AM'         => 'M/d/yyyy h:mm a',
                'is_IS'         => 'd.M.yyyy HH:mm',
                'it'            => 'dd/MM/yyyy H.mm',
                'it_CH'         => 'dd.MM.yyyy HH:mm',
                'it_IT'         => 'dd/MM/yyyy H.mm',
                'iw'            => 'HH:mm dd/MM/yyyy',
                'iw_IL'         => 'HH:mm dd/MM/yyyy',
                'ja'            => 'yyyy/MM/dd H:mm',
                'ja_JP'         => 'yyyy/MM/dd H:mm',
                'kk_KZ'         => 'M/d/yyyy h:mm a',
                'km_KH'         => 'M/d/yyyy h:mm a',
                'ko'            => 'yyyy. M. d a h:mm',
                'ko_KR'         => 'yyyy. M. d a h:mm',
                'lt_LT'         => 'yyyy.M.d HH.mm',
                'lv_LV'         => 'yyyy.d.M HH:mm',
                'ms_MY'         => 'dd/MM/yyyy h:mm a',
                'nl'            => 'd-M-yyyy H:mm',
                'nl_BE'         => 'd/MM/yyyy H:mm',
                'nl_NL'         => 'd-M-yyyy H:mm',
                'nl_SR'         => 'd-M-yyyy H:mm',
                'no'            => 'dd.MM.yyyy HH:mm',
                'no_NO'         => 'dd.MM.yyyy HH:mm',
                'pl'            => 'yyyy-MM-dd HH:mm',
                'pt'            => 'dd-MM-yyyy H:mm',
                'pt_AO'         => 'dd-MM-yyyy H:mm',
                'pt_BR'         => 'dd/MM/yyyy HH:mm',
                'pt_PT'         => 'dd-MM-yyyy H:mm',
                'ro_RO'         => 'dd.MM.yyyy HH:mm',
                'ru'            => 'dd.MM.yyyy H:mm',
                'sk_SK'         => 'd.M.yyyy H:mm',
                'sl_SI'         => 'd.M.y H:mm',
                'sv'            => 'yyyy-MM-dd HH:mm',
                'sv_SE'         => 'yyyy-MM-dd HH:mm',
                'th'            => 'M/d/yyyy h:mm a',
                'th_TH'         => 'd/M/yyyy, H:mm ?.',
                'tr'            => 'dd.MM.yyyy HH:mm',
                'ur_PK'         => 'M/d/yyyy h:mm a',
                'vi_VN'         => 'HH:mm dd/MM/yyyy',
                'zh'            => 'yyyy-M-d ah:mm',
                'zh_CN'         => 'yyyy-M-d ah:mm',
                'zh_HK'         => 'yyyy-M-d ah:mm',
                'zh_TW'         => 'yyyy/M/d a h:mm'
            };
            return localeToDateTimeFmtMap;
    }

    /*********************************************************************************************************************************
    @ Method:         getLocaleToDateFmtMap
    @ Version:        1.0
    @ Author:         Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:        Returns a map of user locale | date format for that locale
    ------------------------------------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.05.2023 / Mony Nou / Created the method.
    @                  06.06.2025 / Mony Nou / US-0002188 - Contract preview is not loading on Coupon(Seller)
    *********************************************************************************************************************************/
    public static Map<String,String> MAP_LOCALE_DATEONLY() {
        if(localeToDateFmtMap != null) {
            return localeToDateFmtMap;
        }
        localeToDateFmtMap = new Map<String,String> {
                'ar'            => 'dd/MM/yyyy',
                'ar_AE'         => 'dd/MM/yyyy',
                'ar_BH'         => 'dd/MM/yyyy',
                'ar_JO'         => 'dd/MM/yyyy',
                'ar_KW'         => 'dd/MM/yyyy',
                'ar_LB'         => 'dd/MM/yyyy',
                'ar_SA'         => 'dd/MM/yyyy',
                'bg_BG'         => 'yyyy-M-d',
                'ca'            => 'dd/MM/yyyy',
                'ca_ES'         => 'dd/MM/yyyy',
                'ca_ES_EURO'    => 'dd/MM/yyyy',
                'cs'            => 'd.M.yyyy',
                'cs_CZ'         => 'd.M.yyyy',
                'da'            => 'dd-MM-yyyy',
                'da_DK'         => 'dd-MM-yyyy',
                'de'            => 'dd.MM.yyyy',
                'de_AT'         => 'dd.MM.yyyy',
                'de_AT_EURO'    => 'dd.MM.yyyy',
                'de_CH'         => 'dd.MM.yyyy',
                'de_DE'         => 'dd.MM.yyyy',
                'de_DE_EURO'    => 'dd.MM.yyyy',
                'de_LU'         => 'dd.MM.yyyy',
                'de_LU_EURO'    => 'dd.MM.yyyy',
                'el_GR'         => 'd/M/yyyy',
                'en_AU'         => 'd/MM/yyyy',
                'en_B'          => 'M/d/yyyy',
                'en_BM'         => 'M/d/yyyy',
                'en_CA'         => 'dd/MM/yyyy',
                'en_GB'         => 'dd/MM/yyyy',
                'en_GH'         => 'M/d/yyyy',
                'en_ID'         => 'M/d/yyyy',
                'en_IE'         => 'dd/MM/yyyy',
                'en_IE_EURO'    => 'dd/MM/yyyy',
                'en_NZ'         => 'd/MM/yyyy',
                'en_SG'         => 'M/d/yyyy',
                'en_US'         => 'M/d/yyyy',
                'en_ZA'         => 'yyyy/MM/dd',
                'en_DE'         => 'dd/MM/yyyy', //MN-06062025-US-0002188
                'es'            => 'd/MM/yyyy',
                'es_AR'         => 'dd/MM/yyyy',
                'es_BO'         => 'dd-MM-yyyy',
                'es_CL'         => 'dd-MM-yyyy',
                'es_CO'         => 'd/MM/yyyy',
                'es_CR'         => 'dd/MM/yyyy',
                'es_EC'         => 'dd/MM/yyyy',
                'es_ES'         => 'd/MM/yyyy',
                'es_ES_EURO'    => 'd/MM/yyyy',
                'es_GT'         => 'd/MM/yyyy',
                'es_HN'         => 'MM-dd-yyyy',
                'es_MX'         => 'd/MM/yyyy',
                'es_PE'         => 'dd/MM/yyyy',
                'es_PR'         => 'MM-dd-yyyy',
                'es_PY'         => 'dd/MM/yyyy',
                'es_SV'         => 'MM-dd-yyyy',
                'es_UY'         => 'dd/MM/yyyy',
                'es_VE'         => 'dd/MM/yyyy',
                'et_EE'         => 'd.MM.yyyy',
                'fi'            => 'd.M.yyyy',
                'fi_FI'         => 'd.M.yyyy',
                'fi_FI_EURO'    => 'd.M.yyyy',
                'fr'            => 'dd/MM/yyyy',
                'fr_BE'         => 'd/MM/yyyy',
                'fr_CA'         => 'yyyy-MM-dd',
                'fr_CH'         => 'dd.MM.yyyy',
                'fr_FR'         => 'dd/MM/yyyy',
                'fr_FR_EURO'    => 'dd/MM/yyyy',
                'fr_LU'         => 'dd/MM/yyyy',
                'fr_MC'         => 'dd/MM/yyyy',
                'hr_HR'         => 'yyyy.MM.dd',
                'hu'            => 'yyyy.MM.dd',
                'hy_AM'         => 'M/d/yyyy',
                'is_IS'         => 'd.M.yyyy',
                'it'            => 'dd/MM/yyyy',
                'it_CH'         => 'dd.MM.yyyy',
                'it_IT'         => 'dd/MM/yyyy',
                'iw'            => 'dd/MM/yyyy',
                'iw_IL'         => 'dd/MM/yyyy',
                'ja'            => 'yyyy/MM/dd',
                'ja_JP'         => 'yyyy/MM/dd',
                'kk_KZ'         => 'M/d/yyyy',
                'km_KH'         => 'M/d/yyyy',
                'ko'            => 'yyyy. M. d',
                'ko_KR'         => 'yyyy. M. d',
                'lt_LT'         => 'yyyy.M.d',
                'lv_LV'         => 'yyyy.d.M',
                'ms_MY'         => 'dd/MM/yyyy',
                'nl'            => 'd-M-yyyy',
                'nl_BE'         => 'd/MM/yyyy',
                'nl_NL'         => 'd-M-yyyy',
                'nl_SR'         => 'd-M-yyyy',
                'no'            => 'dd.MM.yyyy',
                'no_NO'         => 'dd.MM.yyyy',
                'pl'            => 'yyyy-MM-dd',
                'pt'            => 'dd-MM-yyyy',
                'pt_AO'         => 'dd-MM-yyyy',
                'pt_BR'         => 'dd/MM/yyyy',
                'pt_PT'         => 'dd-MM-yyyy',
                'ro_RO'         => 'dd.MM.yyyy',
                'ru'            => 'dd.MM.yyyy',
                'sk_SK'         => 'd.M.yyyy',
                'sl_SI'         => 'd.M.y',
                'sv'            => 'yyyy-MM-dd',
                'sv_SE'         => 'yyyy-MM-dd',
                'th'            => 'M/d/yyyy',
                'th_TH'         => 'd/M/yyyy',
                'tr'            => 'dd.MM.yyyy',
                'ur_PK'         => 'M/d/yyyy',
                'vi_VN'         => 'dd/MM/yyyy',
                'zh'            => 'yyyy-M-d',
                'zh_CN'         => 'yyyy-M-d',
                'zh_HK'         => 'yyyy-M-d',
                'zh_TW'         => 'yyyy/M/d'
            };
            return localeToDateFmtMap;
    }

    public static Map<String,Object> chunkList(List<Object> listItem,Integer rowLimit)
    {
        Map<String,Object> mapResult  = new Map<String,Object>();
        List<List<Object>> listAllChunk = new List<List<Object>>();        
					 
					 
        Decimal d = Decimal.valueOf(listItem.size()) / Decimal.valueOf(rowLimit);
        Integer numOfChunk = d.round(System.RoundingMode.CEILING).intValue();        

        if(listItem.size()<=rowLimit)
        {
            listAllChunk.add(listItem);
            
        }else{
            for(Integer i=0;i<numOfChunk;i++)
            {
                Integer startIndex = i==0?0:i*rowLimit;
                Integer endIndex = i==0?rowLimit: (i*rowLimit)+rowLimit;
                endIndex = endIndex > listItem.size()?listItem.size():endIndex;

                List<Object> listChunk = new List<Object>();
                for(Integer j = startIndex;j<endIndex;j++)
                {
                    listChunk.add(listItem[j]);
                }
                listAllChunk.add(listChunk);
            }
        }
         
        mapResult.put('totalRow',listItem.size());
        mapResult.put('chunkSize',listAllChunk.size());
        mapResult.put('listAllChunk',listAllChunk);

        return mapResult;
    }

    //NK:10/10/2022: specific to chunk list of sobject
    public static Map<String,Object> chunkListSOBJ(List<SObject> listItem,Integer rowLimit)
    {
        Map<String,Object> mapResult  = new Map<String,Object>();
        List<List<SObject>> listAllChunk = new List<List<SObject>>();
        Decimal d = Decimal.valueOf(listItem.size()) / Decimal.valueOf(rowLimit);
        Integer numOfChunk = d.round(System.RoundingMode.CEILING).intValue();        

        if(listItem.size()<=rowLimit)
        {
            listAllChunk.add(listItem);
            
        }else{
            for(Integer i=0;i<numOfChunk;i++)
            {
                Integer startIndex = i==0?0:i*rowLimit;
                Integer endIndex = i==0?rowLimit: (i*rowLimit)+rowLimit;
                endIndex = endIndex > listItem.size()?listItem.size():endIndex;

                List<SObject> listChunk = new List<SObject>();
                for(Integer j = startIndex;j<endIndex;j++)
                {
                    listChunk.add(listItem[j]);
                }
                listAllChunk.add(listChunk);
            }
        }
         
        mapResult.put('totalRow',listItem.size());
        mapResult.put('chunkSize',listAllChunk.size());
        mapResult.put('listAllChunk',listAllChunk);

        return mapResult;
    }

    public static String doDecrypt(String encryptedTxt, String pkey) {


        Blob encryptedData = EncodingUtil.base64Decode(encryptedTxt);

        Blob key =  Blob.valueOf(pkey);

        Blob decrypted = Crypto.decryptWithManagedIV('AES128', key , encryptedData);

        String decryptedString = decrypted.toString();

        return  decryptedString;
    }
    
    public static boolean isProduction()
    {
        return UserInfo.getOrganizationId() == '00D6A0000002HftUAE';
    }

     //support nested object
     //e.g. Object val = ApexUtil.getJSONValue(mapParam,'enrollment.course.id');
     public static Object getJSONValue(Map<String,Object>mapJson,String fname)
     {  
        String key1 = !fname.contains('.') ? fname : fname.substring(0,fname.indexOf('.'));         
        return !fname.contains('.') ? (mapJson==null?'':mapJson.get(fname)) : getJSONValue((Map<String,Object>)mapJson.get(key1),fname.substring(fname.indexOf('.')+1,fname.length()));
     }

     public static String closeSQoute(String str)
     {
         return '\''+str+'\'';
     }

     //Sovantheany Dim : 31/01/2022 : US-0010648 - [BUG][NA DEALS] Canada Contracts on microsite and PDF Attachment showing incorrect EST times
     public static Datetime gmtDateToDTZone(Date d, Time t, String toZone){
        if(t == null || d == null) return null;
        Datetime dt0 = Datetime.newInstanceGmt(d.year(), d.month(), d.day(), 0,0,0);
        TimeZone tzGMT = TimeZone.getTimeZone('GMT');
        TimeZone tztoZone = TimeZone.getTimeZone(toZone);

        Integer offGMT = (((tzGMT.getOffset(dt0.date())/1000)/60)/60);
        Integer offZone = (((tztoZone.getOffset(dt0.date())/1000)/60)/60);

        Integer addHour = offGMT > offZone ? Math.abs(offZone) : offZone;
        Datetime dt1 = dt0.addHours(addHour);
        Datetime dt2 = dt1.addHours(t.hour()).addMinutes(t.minute());

        return dt2;                          
    }


    /***********************************************************************************************************************************
    @ Method:       revokeUserAccess3PLink
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns map of result
    @ Param: map user id and identifier (e.g.Account.eBay_API_User_Id__c)
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.05.2022 / vadhanak voun / US-0011343
    ***********************************************************************************************************************************/
    public static Boolean revokeUserAccess3PLink(String userId,String remoteId)   
    {
        // String authProviderId = '';//Provide the Auth. Provider Id
        // String strUserId = '';//Provide the User Id
        Boolean result = false;
        String soqlTPA = 'select id,Provider, UserId, RemoteIdentifier, SsoProviderId  from ThirdPartyAccountLink ';
        String sWehere1 = ' WHERE RemoteIdentifier='+closeSQoute(remoteId);
        String sWehere2 = String.isBlank(userId)?'':' AND UserId='+closeSQoute(userId);
        for(ThirdPartyAccountLink tpl: Database.query(soqlTPA+sWehere1+sWehere2))
        { 
            //system.debug('--tpl'+tpl);
            result = Auth.AuthToken.revokeAccess( tpl.SsoProviderId, tpl.Provider, tpl.UserId, tpl.RemoteIdentifier);
            //system.debug('--result: '+result);
          
        }
                
        return result;
    }

    /***********************************************************************************************************************************
    @ Method:       numberToWordsCurrency
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns        number as words
    @ e.g.           123.01 --> one hundred twenty-three dollars and one cent
    @ Param:        Decimal number to convert. upto 13 decimal number
    @ Purpose       currency has only .99 cents.                  
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.08.2022 / vadhanak voun / created the method
    ***********************************************************************************************************************************/ 
    public static String numberToWordsCurrency(Decimal n)
    {
        String[] num2 = n.toPlainString().split('[.]');        
        Integer tail = num2.size() > 1 ? Integer.valueOf( num2[1].left(2) ) : 0;
        if(tail>0)
        {
            Integer cents =  num2[1].startsWith('0')? tail*10 : tail  ;
            return numberToWords(Long.valueOf(num2[0])) + ' and ' + numberToWords(Long.valueOf(tail+'')) + (num2[1].startsWith('0')?' cent':' cents');
        }else 
        {
            return numberToWords(n.longValue());
        }
    }
    /***********************************************************************************************************************************
    @ Method:       numberToWords
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns       number as words
    @ e.g.          123345678.1 --> one hundred twenty-three million three hundred forty-five thousand six hundred seventy eight point one
    @ Param:        Decimal number to convert. upto 13 decimal number. number with precision.
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.08.2022 / vadhanak voun / created the method
    ***********************************************************************************************************************************/
    public static String numberToWords(Decimal n)
    {
        String[] num2 = n.toPlainString().split('[.]');
        Integer tail = num2.size() > 1 ? Integer.valueOf(num2[1]) : 0;
        if(tail>0)
        {           
            return numberToWords(Long.valueOf(num2[0])) + ' point ' + numberToWords(Long.valueOf(tail+''));
        }else 
        {
            return numberToWords(n.longValue());
        }
    }
    /***********************************************************************************************************************************
    @ Method:       numberToWords
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns       number as words
    @ e.g.          123345678 --> one hundred twenty-three million three hundred forty-five thousand six hundred seventy eight
    @               no precision
    @ Param:        long number to convert. upto 13 decimal number
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.08.2022 / vadhanak voun / created the method. upto 13 decimal number
    ***********************************************************************************************************************************/
    public static String numberToWords(long n)
    {
        long numLimit = 1000000000000L, curr_hun, t = 0;

        // If zero return zero
        if (n == 0)
            return ('Zero');

        if(String.valueOf(n).length()>13)
            return n.format(); //not convert

        // Array to store the powers of 10
        String[] multiplier = new String[]{ '','Trillion', 'Billion','Million', 'Thousand' };

        // Array to store numbers till 20
        String[] first_twenty = new String[]{
            '',        'One',       'Two',      'Three',
            'Four',    'Five',      'Six',      'Seven',
            'Eight',   'Nine',      'Ten',      'Eleven',
            'Twelve',  'Thirteen',  'Fourteen', 'Fifteen',
            'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
        };

        // Array to store multiples of ten
        String[] tens = new String[]{ '',        'Twenty', 'Thirty',
                        'Forty',   'Fifty',  'Sixty',
                        'Seventy', 'Eighty', 'Ninety' };

        // If number is less than 20, return without any
        // further computation
        if (n < 20L)
            return (first_twenty[(integer)n]);
        String answer = '';
        long i = n;
        while ( i > 0 ) {
            
            // Store the value in multiplier[t], i.e n =
            // 1000000, then r = 1, for multiplier(million),
            // 0 for multipliers(trillion and billion)
            // multiplier here refers to the current
            // accessible numLimit
            curr_hun = i / numLimit;

            // It might be possible that the current
            // multiplier is bigger than your number
            while (curr_hun == 0) {

                // Set i as the remainder obtained when n
                // was divided my the numLimit
                i = Math.mod(i,numLimit);

                // Divide the numLimit by 1000, shifts the
                // multiplier
                numLimit /= 1000;

                // Get the current value in hundereds, as
                // English system works in hundreds
                if(numLimit <> 0)curr_hun = i / numLimit;

                // Shift the multiplier
                ++t;
            }

            // If current hundered is greater that 99, Add
            // the hundreds' place
            if (curr_hun > 99)
                answer += (first_twenty[(integer)curr_hun / 100] + ' Hundred ');

            // Bring the current hundered to tens
            curr_hun = Math.mod(curr_hun , 100);

            // If the value in tens belongs to [1,19], add
            // using the first_twenty
            if (curr_hun > 0 && curr_hun < 20)
                answer += (first_twenty[(integer)curr_hun] + ' ');

            // If curr_hun is now a multiple of 10, but not
            // 0 Add the tens' value using the tens array
            else if (Math.mod(curr_hun , 10) == 0 && curr_hun != 0)
                answer += (tens[(integer)curr_hun / 10 - 1] + ' ');

            // If the value belongs to [21,99], excluding
            // the multiples of 10 Get the ten's place and
            // one's place, and print using the first_twenty
            // array
            else if (curr_hun > 20 && curr_hun < 100)
                answer += (tens[(integer)curr_hun / 10 - 1] + ' '+ first_twenty[(integer)Math.mod(curr_hun , 10)] + ' ');

            // If Multiplier has not become less than 1000,
            // shift it
            if (t < 4)
            {
                answer += (multiplier[(integer)++t] + ' ');
            }

            if(numLimit <> 0)i = Math.mod(i,numLimit);
            numLimit /= 1000;

        }
        return (answer.trim());
    }
    /***********************************************************************************************************************************
    @ Method:       formatTime12H
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Version:        1.0
    @ Author:         Bora Chhorn (bora.chhorn@gaea-sys.com)
    @ Purpose:        For format from Time field to 12h
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    Time myTime
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  29/09/2022 / Bora Chhorn / Created the method.
    ***********************************************************************************************************************************/
    public static String formatTime12H(Time myTime)
    {
        return ('0'+(myTime.hour()>12?(myTime.hour()-12):myTime.hour())).right(2) +':'+('0'+myTime.minute()).right(2)+' '+(myTime.hour()>12?'PM':'AM');
    }

    /***********************************************************************************************************************************
    @ Method:       formatTime24h
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Version:        1.0
    @ Author:         Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:        For format from Time field to 24h
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    Time myTime
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  10/10/2022 / Mony Nou / Created the method for US-0012630 - Change time format for DE coupons in portal
    ***********************************************************************************************************************************/
    public static String formatTime24h (Time myTime) {
        return myTime==null?'': Datetime.newInstance(Date.today(), myTime).format('HH:mm');
    }

    /***********************************************************************************************************************************
    @ Method:       getDomain
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Version:        1.0
    @ Author:         Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:        To get Salesforce Domain url string
    @ Return:         For instance: sellerportal.ebay.co.uk
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  21/11/2022 / Mony Nou / US-0012333 - UK Seller Portal Profile/ Permission Set and Auto Provisioning
    ***********************************************************************************************************************************/

    public static String getDomain() {
        return URL.getSalesforceBaseUrl().getHost();
    }

    public enum IdPrefixType {GENERAL, LOGIN_FAILED, COUPON, DEAL, LWC_FAILED}
    private static Map<IdPrefixType, String> idPrefixMap = new Map<IdPrefixType, String>{
        IdPrefixType.LOGIN_FAILED => LOGIN_FAILED_PREFIX,
        IdPrefixType.COUPON => COUPON_PREFIX,
        IdPrefixType.DEAL => DEAL_PREFIX,
        IdPrefixType.GENERAL => GENERAL_PREFIX,
        //11.12.2024 / Sothea Horn / US-0015300 - Generic LWC Exception handling & Application to program participation component
        IdPrefixType.LWC_FAILED => LWC_FAILED_PREFIX
    };
    /***********************************************************************************************************************************
    @ Method:       generateUniqueId
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Author:       Acmatac Seing
    @ Purpose:      Generates a unique ID with a specified prefix. The unique ID is composed of the prefix followed by a 15-character
    @               unique string generated by ApexUtil.genUniqueStringNoSymbol(15).
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  06/06/2024 / Acmatac Seing / US-0015181 Implement Seamless eBay SSO Authentication
    ***********************************************************************************************************************************/
    public static String generateUniqueId(IdPrefixType prefixEnum) {
        // GENERAL
        String strPrefix = GENERAL_PREFIX;
        if (idPrefixMap.containsKey(prefixEnum)) {
            strPrefix = idPrefixMap.get(prefixEnum);
        }

        return strPrefix + ApexUtil.genUniqueStringNoSymbol(15);
    }
    
    /***********************************************************************************************************************************
    @ Method:       getInstance
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Author:       vadhanak voun
    @ Param:        String nameSpace, String className
    @ Purpose:       Create an instance of a class by its name
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15/01/2025 / vadhanak voun / US-0016265 - (2) Upload Sub Deals in Hive
    ***********************************************************************************************************************************/
    public static Object getInstance(String nameSpace,string className) {
        Type mytype = Type.forName(className);
        if(String.isBlank(nameSpace)) 
        {
            mytype = Type.forName(className);
        }else{
            mytype = Type.forName(nameSpace, className);
        }
        if(mytype == null) 
        {
            System.debug(LoggingLevel.Error, 'Failed to find type for ['+className+']');
            return null;
        }             

        return mytype.newInstance();
    }

    private static UserFormatIndex userDTIndex = null;
    public static UserFormatIndex getIndexOfUserDateFormat(String sep)
    {
        if(userDTIndex==null)
        {
            Date dChkFormat = Date.newInstance(2125, 1, 31);
            String[] df = dChkFormat.format().replace('0','').split(sep);   //df: (1, 31, 2125)
            Integer sY = df.indexOf('2125');    //sY: 2
            Integer sD = df.indexOf('31');      //sD: 1
            Integer sM = df.indexOf('1');       //sM: 0
    
            userDTIndex = new UserFormatIndex(sY,sM,sD);
        }
       return userDTIndex;
    }
    public class UserFormatIndex{
        public Integer yearIndex;
        public Integer monthIndex;
        public Integer dateIndex;
        public UserFormatIndex(Integer yearIndex,Integer monthIndex,Integer dateIndex)
        {
            this.yearIndex = yearIndex;
            this.monthIndex = monthIndex;
            this.dateIndex = dateIndex;
        }       
    }

    /*****************************************************************************************************************************
    @ Method:         getDateTimezoneOffsetForSite
    @ Version:        1.0
    @ Author:         GitHub Copilot
    @ Purpose:        US-0033985: Get timezone offset in seconds for a specific date and site
    @ Parameters:     dateValue - The date to calculate offset for
    @                 siteCode - The site code (UK, DE, US, etc.)
    @ Returns:        Integer - Timezone offset in seconds, null if site not found
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.12.2025 / GitHub Copilot / Method Creation
    *****************************************************************************************************************************/
    public static Integer getDateTimezoneOffsetForSite(Date dateValue, String siteCode) {
        if (dateValue == null || String.isBlank(siteCode)) {
            return null;
        }
        
        // Timezone mapping based on site codes
        Map<String, String> siteToTimezoneMap = new Map<String, String>{
            'UK' => 'Europe/London',
            'DE' => 'Europe/Berlin',
            'FR' => 'Europe/Paris',
            'IT' => 'Europe/Rome',
            'ES' => 'Europe/Madrid',
            'NL' => 'Europe/Amsterdam',
            'CH' => 'Europe/Zurich',
            'AT' => 'Europe/Vienna',
            'BE' => 'Europe/Brussels',
            'IE' => 'Europe/Dublin',
            'PL' => 'Europe/Warsaw',
            'US' => 'America/Los_Angeles',
            'US-MOTORS' => 'America/Los_Angeles',
            'CA' => 'America/Toronto',
            'CA-FR' => 'America/Toronto',
            'AU' => 'Australia/Sydney'
        };
        
        if (!siteToTimezoneMap.containsKey(siteCode)) {
            return null;
        }
        
        String timezoneName = siteToTimezoneMap.get(siteCode);
        TimeZone tz = TimeZone.getTimeZone(timezoneName);
        DateTime dateTimeAtMidnight = DateTime.newInstance(dateValue, Time.newInstance(0, 0, 0, 0));
        
        // Return offset in seconds
        return tz.getOffset(dateTimeAtMidnight) / 1000;
    }
}