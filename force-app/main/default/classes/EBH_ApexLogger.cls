/*********************************************************************************************************************************
@ Class:          EBH_ApexLogger
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Static Class to log apex exception/errors
                  EPH-5, EPH-6, EPH-21 : Generic apex exception log
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.05.2017 / JOY MONDOL / Created the class.
@				: 20.06.2018/ Vadhanak Voun / added asyn method
@				: 09.12.2022/ Bora Chhorn / US-0012924 - Ad new method in EBH_ApexLogger invocable from Flows
@               : 15.08.2023 / Acmatac Seing / US-0014001 - Meta APIs seems to be not working for eBay Influencer Portal
@               : 08.12.2023 / Sambath Seng / US-0014263 - Store log of unsuccessful logins for sellers portal
@               : 06.06.2024 / Acmatac Seing / US-0015181 Adding UniqueId__c to the record
@               : 11.12.2024 / Sothea Horn / US-0015300 - Generic LWC Exception handling & Application to program participation component
*********************************************************************************************************************************/

public class EBH_ApexLogger {
    
    /*****************************************************************************************************************************
    @ Method:         logError
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Utility method to insert the exceptions to the Apex Log Object.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      exceptions: List of Exceptions
                      className:  Class name
                      methodName: Method name
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.09.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/
    public static void logError(List<Exception> exceptions, String className, String methodName) {
        
        List<EBH_ApexLog__c> logs = new List<EBH_ApexLog__c>();
        
        for(Exception ex : exceptions) {
            logs.add(
                new EBH_ApexLog__c(
                    EBH_ClassName__c                 = className,
                    EBH_MethodName__c                = methodName,
                    EBH_ExceptionCause__c            = String.valueOf(ex.getCause()),
                    EBH_ExceptionLineNumber__c       = ex.getLineNumber(),
                    EBH_ExceptionStackTraceString__c = ex.getStackTraceString(),
                    EBH_ExceptionType__c             = ex.getTypeName(),
                    EBH_Message__c                   = (ex.getMessage()).length()> 255?(ex.getMessage()).substring(0,255): ex.getMessage()));
        }
        
        if(!logs.isEmpty()) {
            insert logs;
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:         logError
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Overloaded utility method to insert the database errors to the Apex Log Object.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      errors:     List of Errors
                      className:  Class name
                      methodName: Method name
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.09.2017 / JOY MONDOL / Created the  Method.
    @ Change history: 15.07.2022 / Sophal Noch / US-0011996 modify method
    *****************************************************************************************************************************/
    public static void logError(List<Database.Error> errors, String className, String methodName) {
        
        List<EBH_ApexLog__c> logs = new List<EBH_ApexLog__c>();
        
        for(Database.Error err : errors) {
            logs.add(new EBH_ApexLog__c(
                    EBH_ClassName__c     = className,
                    // EBH_Message__c    = err.getMessage(), // 15.07.2022 / Sophal Noch / US-0011996
                    EBH_Message__c       = ((err.getMessage()).length()> 255?(err.getMessage()).substring(0,255): err.getMessage()), // 15.07.2022 / Sophal Noch / US-0011996
                    EBH_MethodName__c    = methodName,
                    EBH_StatusMessage__c = String.valueOf(err.getFields())));
        }
        
        if(!logs.isEmpty()) {
            insert logs;
        }
    }
	
	/*****************************************************************************************************************************
    @ Method:         logError
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        Utility method to insert the exceptions to the Apex Log Object as asynchronous mode.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      exceptions: List of Exceptions
                      className:  Class name
                      methodName: Method name
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 20.06.2018 / Vadhanak Voun / Created the  Method.
    @                   15.08.2023 / Acmatac Seing / US-0014001 - Meta APIs seems to be not working for eBay Influencer Portal
    *****************************************************************************************************************************/
    @future
    public static void logError(String errCause,Integer lineNumber,String stackTrace,String errType,String errorMsg, String className, String methodName) {
        
        // List<EBH_ApexLog__c> logs = new List<EBH_ApexLog__c>();
         
        // logs.add(
        //     new EBH_ApexLog__c(
        //         EBH_ClassName__c                 = className,
        //         EBH_MethodName__c                = methodName,
        //         EBH_ExceptionCause__c            = errCause,
        //         EBH_ExceptionLineNumber__c       = lineNumber,
        //         EBH_ExceptionStackTraceString__c = stackTrace,
        //         EBH_ExceptionType__c             = errType,
        //         EBH_Message__c                   = (errorMsg).length()> 255?(errorMsg).substring(0,255): errorMsg));
        
        
        // if(!logs.isEmpty()) {
        //     insert logs;
        // }
        EBH_ApexLogger.doLogError(errCause, lineNumber, stackTrace, errType, errorMsg, className, methodName);
    }

    /*****************************************************************************************************************************
    @ Method:         doLogError
    @ Version:        1.0
    @ Author:         Acmatac Seing (acmatac.seing@gaea-sys.com)
    @ Purpose:        Cloned from logError and make it none future. US-0014001 - Meta APIs seems to be not working for eBay Influencer Portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.08.2023 / Acmatac Seing / Cloned the  Method.
    *****************************************************************************************************************************/
    public static void doLogError(String errCause,Integer lineNumber,String stackTrace,String errType,String errorMsg, String className, String methodName) {
        
        List<EBH_ApexLog__c> logs = new List<EBH_ApexLog__c>();
         
        logs.add(
            new EBH_ApexLog__c(
                EBH_ClassName__c                 = className,
                EBH_MethodName__c                = methodName,
                EBH_ExceptionCause__c            = errCause,
                EBH_ExceptionLineNumber__c       = lineNumber,
                EBH_ExceptionStackTraceString__c = stackTrace,
                EBH_ExceptionType__c             = errType,
                EBH_Message__c                   = (errorMsg).length()> 255?(errorMsg).substring(0,255): errorMsg));
        
        
        if(!logs.isEmpty()) {
            insert logs;
        }
    }

    /*****************************************************************************************************************************
    @ Method:         logErrorLWC
    @ Version:        1.0
    @ Author:         Sohea Horn (sohorn@ebay.com)
    @ Purpose:        Utility method to insert LWC exceptions to the Apex Log Object.
                      US-0015300 - Generic LWC Exception handling & Application to program participation component   
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter 1:      errorMsg           Text of error message
    @ Parameter 2:      stackTrace         Stack trace of error
    @ Parameter 3:      lwcName            Name of LWC that cause error
    @ Parameter 4:      lwcMethodName      Name of LWC method that cause error
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.12.2024 / Sothea Horn / Created the  Method. 
    *****************************************************************************************************************************/
    @AuraEnabled
    public static String logErrorLWC (String errorMsg, String stackTrace, String lwcName, String lwcMethodName) {
        // Generate a unique alpha-numeric identifier for each incident
        String incidentId = ApexUtil.generateUniqueId(ApexUtil.IdPrefixType.LWC_FAILED);
        // create apex log 
        List<EBH_ApexLog__c> logs = new List<EBH_ApexLog__c>{
            new EBH_ApexLog__c(
                EBH_ClassName__c                 = lwcName,
                EBH_MethodName__c                = lwcMethodName,
                EBH_ExceptionStackTraceString__c = stackTrace,
                EBH_ExceptionType__c             = 'LWC',
                IncidentId__c                    = incidentId,
                EBH_Message__c                   = (errorMsg).length()> 255?(errorMsg).substring(0,255): errorMsg)
        };
        Database.SaveResult[] insertResult = ApexSafe.dml().secCheck(false).doInsert(logs, true);
        // Return the generated unique alpha-numeric identifier for the incident if apex log successfully created
        return incidentId;
    }

    /*****************************************************************************************************************************
    @ Method:         logErrorFlow
    @ Version:        1.0
    @ Author:         Bora Chhorn (bora.chhorn@gaea-sys.com)
    @ Purpose:        Utility method to insert the log error from Flow to the Apex Log Object.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      List<EBH_ApexLogger.CustomParameter> parameter
    
                      className: Flow Name
                      stackTrace        : Fault Message
                      errCause          : Flow Application Error
                      errorMessage      : Error message from Flow
                      errorActionName   : Error Action Name
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 09.12.2022 / Bora Chhorn / Created the  Method.
    @               : 01.12.2023/ vadhanak voun / US-0014472 - Trim flow message when creating apex log record on Share Case Flow
    *****************************************************************************************************************************/
    @Invocablemethod(label='logErrorFlow' description='Retrieve Log Error From Flow')
    public static void logErrorFlow(List<EBH_ApexLogger.CustomParameter> parameter) {
        
        insert new List<EBH_ApexLog__c>
        {
            new EBH_ApexLog__c(
                EBH_ClassName__c                 = parameter.get(0).className,
                EBH_MethodName__c                = String.isNotBlank(parameter.get(0).errorActionName) ? parameter.get(0).errorActionName : 'Flow Action',
                EBH_Message__c                   = (parameter.get(0).errorMessage+'').left(255),
                EBH_ExceptionStackTraceString__c = (parameter.get(0).stackTrace+'').left(32768),
                EBH_ExceptionCause__c            = (parameter.get(0).errorCause+'').left(255),
                EBH_ExceptionType__c             = 'Flow')
        };
    }
    
    public class CustomParameter{

        @InvocableVariable
        public String className;

        @InvocableVariable
        public String stackTrace;

        @InvocableVariable
        public String errorCause;

        @InvocableVariable
        public String errorMessage;

        @InvocableVariable
        public String errorActionName;
    }

    /*****************************************************************************************************************************
    @ Method:         logSellerPortal
    @ Version:        1.0
    @ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
    @ Purpose:        US-0014263 - Store log of unsuccessful logins for sellers portal
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String action, String sellerName, String sellerApiId, String userId, String page, String errorMessage, String sellerPortalDomain, String methodName
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.12.2023 / Sambath Seng / Created the  Method.
    @                   06.06.2024 / Acmatac Seing / US-0015181 Adding UniqueId__c to the record
    *****************************************************************************************************************************/
    public static String logSellerPortal(String action, String sellerName, String sellerApiId, String userId, String page, String errorMessage, String sellerPortalDomain, String methodName){
        String uniqueId = ApexUtil.generateUniqueId(ApexUtil.IdPrefixType.LOGIN_FAILED);
        Map<String,Object> jsonData = new Map<String,Object>{
            'action' => action,
            'targetObject' => 'Seller_Portal_Log__c',
            'targetData' => new Map<String,Object>{
                'Seller_Name__c' => String.isNotBlank(sellerName) ? sellerName : '',
                'Seller_API_Id__c' => String.isNotBlank(sellerApiId) ? sellerApiId : '',
                'User_ID__c' => String.isNotBlank(userId) ? userId : '',
                'Page_contact_tried_to_access__c' => String.isNotBlank(page) ? page : '',
                'Seller_Portal_Domain__c' => String.isNotBlank(sellerPortalDomain) ? sellerPortalDomain : '',
                'Error_Message__c' => errorMessage.left(32768),
                'Method_Name__c' => String.isNotBlank(methodName) ? methodName : '',
                'UniqueId__c' => uniqueId
            }
        };
        
        SellerPortalServiceEvent__e serviceEvent = new SellerPortalServiceEvent__e();
        serviceEvent.Json_Data__c = JSON.serialize(jsonData);

        // Publish the event
        List<Database.SaveResult> sr = EventBus.publish(new List<SellerPortalServiceEvent__e>{ serviceEvent });
        return uniqueId;
    }

}