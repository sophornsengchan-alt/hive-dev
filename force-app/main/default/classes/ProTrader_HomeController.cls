/*********************************************************************************************************************************
@ Class:         ProTrader_HomeController
@ Version:       1.0
@ Author:        vadhanak voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       US-0009768 - [Pro-Trader] New Home Page - Charts,Detail and BoB Categories component to be added
@                Controller for aura: ProTrader_Home    
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  	25.06.2021 / vadhanak voun (vadhanak.voun@gaea-sys.com) / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  	12.08.2021 / Mony Nou (mony.nou@gaea-sys.com) / US-0010020 - [Pro-Trader] "View Actions" and "Remove Actions" capability to be added for Pro-Trader Category leads
@                   22.06.2022 / Sovantheany (sovantheany.dim@gaea-sys.com) / US-0011890 - Grant "NA Standard User base" users with access to Light touch Pro-trader and aSelleration capablities
@                   11.11.2025 / Sothea Horn / US-0033664 - View All Actions Link (Seller Management Object)
*********************************************************************************************************************************/
public without sharing class ProTrader_HomeController {
    private final static String SOQL_BOB = 'Select Id,Name,EBH_BOBCNTRY__c,LTTM_Campaign_Name__c From BOB__c ';
    private final static String RECORDTYPE_LTTM = 'Light_Touch_Category_Cohort';
    public final static String MANAGED_TYPE_PROTRADER = 'LTTM Managed'; //label: Pro-Trader
    public final static String MANAGED_TYPE_LTTMPLUS = 'LTTM Plus'; //label: Pro-Trader
    public final static String STATUS_ACTIVE = 'BoB Active';
    public final static String PERMISSIONSET_GROWTHCOACHING = 'Growth_Coaching'; //MN-13082021-US-0010020
    public final static String PERMISSIONSET_BOBCATLEAD = 'BoB_Category_Lead'; //MN-13082021-US-0010020
    public final static String PERMISSIONSET_NA_STANDARD = 'US_CA_Standard_user';//TH:US-0011890- 22.06.2022
    public final static String PERMISSIONSET_ONEOFFACCMANAGEMENT = 'One_Off_Account_Management'; //11.11.2025 / Sothea Horn / US-0033664

    /*****************************************************************************************************************************
    @ Method:   apexInit
    @ Version:  1.0
    @ Author: 	vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:	US-0009768 - [Pro-Trader] New Home Page - Charts,Detail and BoB Categories component to be added
    @           Select your Cohort - Displays Cohort Names owned by Logged in Acc Mgr from Table BoB__c(with record type = Light Touch Category Cohort, Managed Type = Pro-Trader or LTTM Plus and Cohort Status = "Active" and BoB__c.Account Manager = Logged in user Name)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 28.06.2021 /  vadhanak voun (vadhanak.voun@gaea-sys.com) / Created the  Method.
    *****************************************************************************************************************************/    
    @AuraEnabled
    public static Map<String,Object> apexInit(String sWhere,String orderBy)
    {
        //Set<String> mType = new Set<String>{MANAGED_TYPE_PROTRADER};
        String currentUserId = UserInfo.getUserId();
        //String soqlWhere = ' WHERE Account_Manager__c = :currentUserId AND Status__c =:STATUS_ACTIVE AND Managed_Type__c IN :mType AND RecordType.DeveloperName =:RECORDTYPE_LTTM';
        String soql = SOQL_BOB + sWhere +orderBy;
        List<BOB__c> listBob = Database.query(soql);

        return new Map<String,Object>{
            'listBob'=>listBob             
        };
    }

    /*****************************************************************************************************************************
    @ Method:   apexInitActionList
    @ Version:  1.0
    @ Author: 	vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:	US-0009789 - [Pro-Trader] App with third tab "Actions List"
    @           init for aura: ProTrader_ActionList.cmp
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.07.2021 /  vadhanak voun (vadhanak.voun@gaea-sys.com) / Created the  Method.
    *****************************************************************************************************************************/    
    @AuraEnabled
    public static Map<String,Object> apexInitActionList(String recordId)
    {       
        //manually mapping for recordtype LTTM
        List<Object> listStatus = new List<Object>{
            new Map<String,String>{'label'=>'','value'=>''},
            new Map<String,String>{'label'=>'Not Started','value'=>'Not Started'},
            new Map<String,String>{'label'=>'In Progress','value'=>'In Progress'},
            new Map<String,String>{'label'=>'Completed','value'=>'Completed'},
            new Map<String,String>{'label'=>'Not Applicable','value'=>'Not Applicable'}
        };
        
        List<Object> listActionOutCome = new List<Object>{
            new Map<String,String>{'label'=>'','value'=>''},
            new Map<String,String>{'label'=>'DMC Committed','value'=>'DMC Committed'},
            new Map<String,String>{'label'=>'DMC Not Committed','value'=>'DMC Not Interested'}
            //new Map<String,String>{'label'=>'Exited Coaching','value'=>'Exited Coaching'} //MN-13082021-there is no such value for RecordType LTTM
            
        };
        Report[] reports = [Select Id,DeveloperName From Report Where DeveloperName='All_Actions_By_Seller_Management_001'];

        //MN-13082021-US-0010020
        
        RecordType rtLTTM = ApexUtil.getRecordTypeByName('Action__c','LTTM'); 

        //Check current user whether they have able to use Mass Edit button or not
        //Only System Admin and user with permission set "Growth Coaching" or "BoB Category Lead"
        Boolean isGrowthCoaching    = ApexUtil.checkPermissionSet(new Set<String>{PERMISSIONSET_GROWTHCOACHING});
        //TH:US-0011890-22.06.2022
        //Boolean isBoBCateLead       = ApexUtil.checkPermissionSet(new Set<String>{PERMISSIONSET_BOBCATLEAD});
        Boolean hasPermission       = ApexUtil.checkPermissionSet(new Set<String>{PERMISSIONSET_BOBCATLEAD, PERMISSIONSET_NA_STANDARD});
        //End US-0011890
        Boolean isAdmin = UserInfo.getProfileId() == ApexUtil.ADMIN_PROFILE_ID;
        //11.11.2025 / Sothea Horn / US-0033664
        Boolean isOneOffAccountManagement = ApexUtil.checkPermissionSet(new Set<String>{PERMISSIONSET_ONEOFFACCMANAGEMENT});

        //---MN-13082021-US-0010020

        return new Map<String,Object>{
            'listStatus'=>listStatus,
            'listActionOutCome'=> listActionOutCome,
            'reportId'=>reports.isEmpty()?'':reports[0].Id,
            'rtLTTM' => rtLTTM, //MN-13082021-US-0010020
            'hasDeleteAccess' => (isAdmin || hasPermission), //MN-13082021-US-0010020
            'hasMassEditAccess' => (isAdmin || isGrowthCoaching || isOneOffAccountManagement || hasPermission) //MN-13082021-US-0010020
        };
    }

    /*****************************************************************************************************************************
    @ Method:   apexSaveActionList
    @ Version:  1.0
    @ Author: 	vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:	US-0009789 - [Pro-Trader] App with third tab "Actions List"
    @           save the list from inline-editing
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.07.2021 /  vadhanak voun (vadhanak.voun@gaea-sys.com) / Created the  Method.
    *****************************************************************************************************************************/    
    @AuraEnabled
    public static Map<String,Object> apexSaveActionList(List<SObject> listActions)
    {       
        Map<String,Object> mapResult = new Map<String,Object>{'status'=>'ok'};
       try
        {
            update listActions;
       
        }catch(DMLException dex){mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());}
        catch(Exception ex){mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());}
    
        

        return mapResult;
    }

    /*****************************************************************************************************************************
    @ Method:   apexDeleteActionList
    @ Version:  1.0
    @ Author: 	Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:	US-0010020 - [Pro-Trader] "View Actions" and "Remove Actions" capability to be added for Pro-Trader Category leads
    @           delete selected actions from screen
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.08.2021 /  Mony Nou / Created the  Method.
    *****************************************************************************************************************************/    
    @AuraEnabled
    public static Map<String,Object> apexDeleteActionList(List<SObject> listActions)
    {       
        Map<String,Object> mapResult = new Map<String,Object>{'status'=>'ok'};
       try
        {
            delete listActions;
       
        }catch(DMLException dex){mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());}
        catch(Exception ex){mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());}
    
        

        return mapResult;
    }
}