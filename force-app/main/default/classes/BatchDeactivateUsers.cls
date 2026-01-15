/*********************************************************************************************************************************
@ Class:        BatchDeactivateUsers
@ Version:      1.0
@ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:      EPH-5578: Auto deactivation of users if inactive for 30 days or over
@               - Send 1st Notification to user 30 days after last login
@               - Send 2nd Notification to user 40 days after Last login
@               - Deactivate User 45 days after Last Login
@               - Wait 7 days from reactivated date before deactavation    
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 04.06.2018 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / Created the class.
@               : 15.02.2021/ Vadhanak Voun (vadhanak.voun@gaea-sys.com) / US-0008327 - [Dev Only] - Finalize user deactivation process
@                                                                      /emails sent by Process
@               : 10.10.2021/ Acmatac SEING (acmatac.seing@gaea-sys.com) / US-0010679 - Exclude Seller Portal Users from the User deactivation batch
@               : 12.07.2022/ Mony Nou (mony.nou@gaea-sys.com) / US-0011940 - User Deactivation Badge error
@                   - After investigation, the reason we got MIXED_DML_OPERATION error when create ApexLog record because because we try to update users that using in FieldUpdate/Email Alert or Integration user 
@                       + Field Update: DEPENDENCY_EXISTS, Cannot complete this operation. This user is a target of a workflow field update. : Field Update
@                       + Email Alert: DEPENDENCY_EXISTS, Cannot complete this operation. This user is being used by email alerts. : Email Alert 
@                       + Integration User (Ex: B2BMA Integration): UNKNOWN_EXCEPTION, You cannot edit this field: [IsActive]  
@               : 12.12.2022/ Srong Tin (srong.tin@gaea-sys.com) / US-0012996 - Change logic in BatchDeactivateUsers Apex Class
@               : 17.01.2023 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) - US-0013105 - Deactivate Influencer accounts based on INACTIVITY
*********************************************************************************************************************************/

global  without sharing class BatchDeactivateUsers implements Database.Batchable<SObject>,Schedulable ,Database.stateful
{   
    private final String SOQL_USER_DEACTIVATION = 'SELECT CreatedDate, Profile.Name, First_Notification__c,Second_Notification__c,Final_Notification__c,Reactivated_Date__c,Name, LastLoginDate,IsActive, Id From User ';
    //private final String SOQL_DEACTIVATION_TEMPLATE = 'Select  Id,DeveloperName from EmailTemplate WHERE DeveloperName IN(\'We_Want_you_back\',\'Final_Notification2\')';//UPDATED BY DHE US-0007085
    
    // private final String DEACTIVATION_TEMPLATE_FIRST_NOTIFICATION  = 'We_Want_you_back';
    // private final String DEACTIVATION_TEMPLATE_FINAL_NOTIFICATION  = 'Final_Notification2'; //UPDATED BY DHE US-0007085
    
    // private final String DEACTIVATION_SENDER_DISPLAY ='Hive Support';

    @TestVisible private DateTime lastLoginDateStrict30 = System.now().addDays(ApexUtil.toInteger(System.Label.UserDeactivate_First_Notification));  //-30
    @TestVisible private DateTime lastLoginDateStrict37 = System.now().addDays(ApexUtil.toInteger(System.Label.UserDeactivate_Second_Notification)); //-37
    @TestVisible private DateTime lastLoginDateStrict45 = System.now().addDays(ApexUtil.toInteger(System.Label.UserDeactivate_Third_Notification)); // -45
    @TestVisible private DateTime lastLoginDateStrict80 = System.now().addDays(ApexUtil.toInteger(System.Label.Influence_UserDeactivate_First_Notification));  //-80 // TH: US-0013105
    @TestVisible private DateTime lastLoginDateStrict90 = System.now().addDays(ApexUtil.toInteger(System.Label.Influence_UserDeactivate_Third_Notification)); // -90 // TH: US-0013105

    private DateTime last7Days = System.now().addDays(-7);
    private static final String DEPLOYMENT_USER_ID = '0056A000000yx6iQAA';
    
    // US-0010679 - Exclude Seller Portal Users from the User deactivation batch
    // SRONGTIN-12.12.2022-US-0012996
    private String[] includedProfile = Label.PROFILES_FOR_DEACTIVATE_USERS.split(',');
    private static final String INFLUENCER_PARTNER_PROFILE = 'Influencer Partner Profile';//TH:US-0013105
    @TestVisible private String soql = null;
    
    @TestVisible private String lastLoginField = 'LastLoginDate';
    @TestVisible private Integer batchSize = 10;
    private Set<String> setUidToCreateCase = new Set<String>(); //create case log for user to be DeActivated
    // SRONGTIN-12.12.2022-US-0012996
    // TH : US-0013105 : add ((LastLoginDate <:lastLoginDateStrict80 OR (LastLoginDate=null AND CreatedDate<:lastLoginDateStrict80)) AND Profile.Name =: INFLUENCER_PARTNER_PROFILE)
    String sWhere = ' WHERE IsActive = true AND Active_Approver__c=false AND ( ((LastLoginDate <:lastLoginDateStrict30 OR (LastLoginDate=null AND CreatedDate<:lastLoginDateStrict30)) AND Profile.Name IN: includedProfile) OR ((LastLoginDate <:lastLoginDateStrict80 OR (LastLoginDate=null AND CreatedDate<:lastLoginDateStrict80)) AND Profile.Name =: INFLUENCER_PARTNER_PROFILE) )';

    String sLimit = Test.isRunningTest()?' LIMIT 1':'';

    private Set<String> sSkipErrorType = new Set<String>{'DEPENDENCY_EXISTS','UNKNOWN_EXCEPTION','INSUFFICIENT_ACCESS_OR_READONLY'}; //MN-12072022-US-0011940

    public BatchDeactivateUsers()
    {
        this.soql = SOQL_USER_DEACTIVATION + sWhere + sLimit;
    }

    //test purpose (test coverage)
    public BatchDeactivateUsers(String soql)
    {
        this.soql = soql;
    }
    global Database.querylocator start(Database.BatchableContext bc)
    {
        return Database.getQueryLocator(soql);
    }
    
    global void execute(Database.BatchableContext bc,List<User> scope)
    {
        List<User> userstToUpdate = new List<User>(); 

        for(User u :scope)
        {
            //TH:US-0013105: Check lastLogin for Influencer Partner Profile
            if(u.Profile.Name == INFLUENCER_PARTNER_PROFILE){
                checkLastLoginDateInfluencer(u,userstToUpdate);
            }else{
                checkLastLoginDate(u,userstToUpdate);
            }
           /* DateTime lastLoginDate = (DateTime)u.get(lastLoginField);

            //45-final notification - farewell, deactivate!
            //wait 7 days from reactivated date before deactavation OR never reactivated
            if( lastLoginDate < lastLoginDateStrict45 && u.Final_Notification__c==null && (u.Reactivated_Date__c == null || u.Reactivated_Date__c <> null && u.Reactivated_Date__c < last7Days) )
            {                 
                u.isActive = false;
                u.Final_Notification__c = System.now();
                userstToUpdate.add(u); 
                setUidToCreateCase.add(u.Id);               
                //system.debug('>>>u in : '+u);  
            //37-second notification
            }else if(lastLoginDate < lastLoginDateStrict37 && u.Second_Notification__c==null)
            {
                u.Second_Notification__c = System.now();
                userstToUpdate.add(u);
            
            //30- first notification    
            }else if(lastLoginDate< lastLoginDateStrict30 && u.First_Notification__c==null) 
            {
                u.First_Notification__c = System.now();
                userstToUpdate.add(u);
            }*/

        }
        
        if(!userstToUpdate.isEmpty())
        {

            //MN-12072022-US-0011940
            Database.SaveResult[] results = Database.update(userstToUpdate,false);

            for (Database.SaveResult result : results) {

                if (!result.isSuccess()){

                    for (Database.Error err : result.getErrors()){
                        /*In case the error are from type = DEPENDENCY_EXISTS & UNKNOWN_EXCEPTION => we will skip the ApexLog creation because for some reason, for such error type => caused following error:
                            Insert failed. First exception on row 0; first error: MIXED_DML_OPERATION, DML operation on setup object is not permitted after you have updated a non-setup object (or vice versa): EBH_ApexLog__c, original object: User: []
                        */
                        
                        if(!Test.isRunningTest() && !sSkipErrorType.contains(String.valueOf(err.getStatusCode()))) EBH_ApexLogger.logError(new List<Database.Error> { err }, 'BatchDeactivateUsers','execute (batch)');
                    }

                }
            }

            /* MN-12072022-US-0011940-Comment old version 
            try {

                update userstToUpdate;  //emails sent by Process                
                
            } catch(Exception ex) {
                
                system.debug(ex);if(!Test.isRunningTest())EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchDeactivateUsers','execute (batch)');
                //US-0000227 : Future method cannot be called from a future or batch method 
                //EBH_ApexLogger.logError(ex.getCause()+'',ex.getLineNumber(),ex.getStackTraceString(), ex.getTypeName(),ex.getMessage(), 'BatchDeactivateUsers', 'execute (batch)');            
            }
            */

        }
                
    }
   
    /*****************************************************************************************************************************
    @ Method:       finish
    @ Version:      1.0
    @ Author:       Vadhanak Voun
    @ Purpose:      AC6: When user has been deactivated, a user deactivation ticket is created & closed to track total number of deactivations for adoption reporting.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     set of user id for ticket (case) creation
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.02.2021 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    global void finish(Database.BatchableContext bc)
    {
        //
        List<Case> listCases = new List<Case>();
        RecordType rt_Deactivate = ApexUtil.getRecordTypeByName('Case', 'User_Deactivation');
        for(String uid: setUidToCreateCase)
        {
            listCases.add(
                new Case(
                    RecordTypeId = rt_Deactivate.Id,
                    Deactivate_User__c = uid,
                    Status = 'Closed',
                    Description = 'BatchDeactivateUsers',
                    OwnerId = DEPLOYMENT_USER_ID
                )
            );
        }
        //System.debug('>>setUidToCreateCase: '+setUidToCreateCase);
        //System.debug('>>listCases: '+listCases);
        if(!listCases.isEmpty())
        {
            try {
                insert listCases;              
               
            } catch(Exception ex) {
                system.debug(ex);if(!Test.isRunningTest())EBH_ApexLogger.logError(new List<Exception> { ex }, 'BatchDeactivateUsers','finish (batch)');                     
            }
        }
    } 

    private void checkLastLoginDate(User u,List<User> userstToUpdate){
        DateTime lastLoginDate = (DateTime)u.get(lastLoginField);

            //45-final notification - farewell, deactivate!
            //wait 7 days from reactivated date before deactavation OR never reactivated
            if( ((LastLoginDate == null && u.CreatedDate < lastLoginDateStrict45 ) || (lastLoginDate < lastLoginDateStrict45)) && u.Final_Notification__c==null && (u.Reactivated_Date__c == null || u.Reactivated_Date__c <> null && u.Reactivated_Date__c < last7Days) )
            {                 
                u.isActive = false;
                u.Final_Notification__c = System.now();
                userstToUpdate.add(u); 
                setUidToCreateCase.add(u.Id);     
            //37-second notification
            }else if(((LastLoginDate == null && u.CreatedDate < lastLoginDateStrict37 ) || lastLoginDate < lastLoginDateStrict37) && u.Second_Notification__c==null)
            {
                u.Second_Notification__c = System.now();
                userstToUpdate.add(u);
            
            //30- first notification    
            }else if(((LastLoginDate == null && u.CreatedDate < lastLoginDateStrict30 ) || lastLoginDate< lastLoginDateStrict30) && u.First_Notification__c==null) 
            {
                u.First_Notification__c = System.now();
                userstToUpdate.add(u);
            }
    }
    //TH:US-0013105
    private void checkLastLoginDateInfluencer(User u,List<User> userstToUpdate){
        DateTime lastLoginDate = (DateTime)u.get(lastLoginField);

        //90-final notification - farewell, deactivate!
        //wait 7 days from reactivated date before deactavation OR never reactivated
        if( ((LastLoginDate == null && u.CreatedDate < lastLoginDateStrict90 ) || lastLoginDate < lastLoginDateStrict90) && u.Final_Notification__c==null && (u.Reactivated_Date__c == null || u.Reactivated_Date__c <> null && u.Reactivated_Date__c < last7Days) )
        {                 
            u.isActive = false;
            u.Final_Notification__c = System.now();
            userstToUpdate.add(u); 
            setUidToCreateCase.add(u.Id);                 
        } //80- first notification    
        else if(((LastLoginDate == null && u.CreatedDate < lastLoginDateStrict80 ) || lastLoginDate< lastLoginDateStrict80) && u.First_Notification__c==null) 
        {
            u.First_Notification__c = System.now();
            userstToUpdate.add(u); 
        }
    }

    //for 
    //for scheduler
    global void execute(SchedulableContext ctx){
        BatchDeactivateUsers batchDeactivation = new BatchDeactivateUsers();
        Database.executeBatch(batchDeactivation,batchSize);
    }
     
}