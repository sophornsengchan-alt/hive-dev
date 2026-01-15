/**
 Utilities
*/
public without sharing class DARTUtil {
     
    final static String DART_DATEFORMAT = 'EEE MMM dd HH:mm z yyyy';
    public final static String DART_DATEFORMAT_QUERY = 'yyyy-MM-dd';
    
    public static String CLIENT_AUTH_URL = 'https://www.google.com/accounts/ClientLogin';
     
    
    public final static String DART5 = 'DART5';
    public final static String DART6 = 'DART6';
    public final static String PRODUCT_PACKAGE = 'Package';
    public final static String AUTHENTICATION_TYPE = 'ClientLogin';
    public final static String URL_INSTANCE = 'https://'+Url.getOrgDomainURL();
    public final static String EMAIL_SUBJECT = 'Availability Forecast' ;
    public final static String EMAIL_SUBJECT_BOOKING = 'Booking results' ;
    
    public final static String USER_ROLE_SALESPERSON = '1';
    public final static String USER_ROLE_PRIMARY_TRAFICKER = '2';
    
    public final static String TEAM_MEMBER_ROLE = 'Primary Trafficker'; 
    public static final String ENDPOINT_GOOGLE_OAUTH2_TOKEN = 'https://accounts.google.com/o/oauth2/token';
     
    
    /** 
     * @param username
     * @param password
     * @param server param
     * @param method
     * i.e:
     * 'myacc','mypwd','/xmlserver/','POST'
     */
    public static String composeDigestAuthorizationHeader(String paramString1, String paramString2, String paramString3, String paramString4)
    {
        try
        { 
          
          String str1 = 'DART';
          String str2 = computeDigest(System.now().format(DART_DATEFORMAT));//Wed Sep 05 15:37:21 ICT 2012
          String str3 = '00000001';
          String str4 = computeDigest(System.now().format(DART_DATEFORMAT));
          String str5 = 'auth';
          String str6 = computeDigest(paramString1 + ':' + str1 + ':' + paramString2);
          String str7 = computeDigest(paramString4 + ':' + paramString3);
          String str8 = str2 + ':' + str3 + ':' + str4 + ':' + str5 + ':' + str7;
          String str9 = computeDigest(str6 + ':' + str8);
          String strDigest = 'Digest ';
          strDigest+='username="' + paramString1 + '", realm="' + str1 + '", qop="' + str5 + '", ';
          strDigest+='algorithm="MD5", uri="' + paramString3 + '", nonce="' + str2 + '", nc=' + str3 + ', ';
          strDigest+='cnonce="' + str4 + '", response="' + str9 + '"';
          //System.debug('>>>>>>>>>>>>System.now().format(df):'+System.now().format(df));
          //System.debug('>>>>strDigest.toString:'+strDigest);
          return strDigest;
        }
        catch (Exception ex)
        {
            //System.debug('>>>>>>>>>>>>ERRRROR:'+ex);
            throw new ExceptionGroup.DigestException('Could not compose digest authorization.\n'+ex.getStackTraceString());
        } 
    }
    private static String computeDigest(String paramString) 
    {
        Blob hash = Crypto.generateDigest('MD5',Blob.valueOf(paramString));
        String hexDigest = EncodingUtil.convertToHex(hash);
        
        return  hexDigest;
    }
    static Map<String, String> mapDart6Token = new Map<String, String>();
    /**
     * @param countryCode: country's code that defined in Adserverlogin, ex:AU, UK, CA, NL,....
     * @return Auth token code
     */
    public static String getRequestToken(String countryCode)
    {       
        if(!mapDart6Token.containsKey(countryCode)){     
            try
            { 
                 String authToken='';
                AdServer_Login__c login = getCredential(DART6, countryCode);
                
                HTTPWrapper.IRequest tokenReq = new DART6Message.DART6TokenRequest(login);
                DART6Message.GenericResponse tokeResponse = new DART6Message.GenericResponse(tokenReq);
                  
                String responseBody = tokeResponse.getResBody();
                 
                 
                if(!(responseBody+'').contains('Auth='))
                {
                    throw new ExceptionGroup.FetchTokenException(responseBody);
                }
                
                authToken = responseBody.substring(responseBody.indexOf('Auth=') + 5).trim();
                
                 mapDart6Token.put(countryCode,authToken);
                 
            }catch(Exception ex)
            {
                throw new ExceptionGroup.FetchTokenException('Could not fetch token for DART6.\n'+ex.getStackTraceString());
            }
            
        }   
        return mapDart6Token.get(countryCode); 
    }
    
    static Map<String,AdServer_Login__c> mapCredential;
    /**
     * Get AdServerLogin by dartversion and country's code
     * @param   dartVersion, ex: DART6
     * @param   countryCode, ex: AU, CA,...
     * @return  list of AdServer_Login__c
     * @see     AdServer_Login__c
     */
    public static AdServer_Login__c getCredential(String dartVersion, String countryCode)
    {
        if(mapCredential==null)
        {
            mapCredential = new Map<String,AdServer_Login__c>();
            for( AdServer_Login__c login: [SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c, Refresh_Token__c, Client_Id__c, Client_Secret__c, Timezone__c, ExternalLineDescriptionId__c  FROM AdServer_Login__c WHERE Active__c=true AND isDeleted=false])
            {
                mapCredential.put(login.RecordType.name + '_' + login.Name,login);//DART Version, Login
            }
            //if(mapCredential.isEmpty() || !mapCredential.containsKey(dartVersion + '_' + countryCode) && !PRODUCT_PACKAGE.equals(dartVersion))
            if(mapCredential.isEmpty() || !mapCredential.containsKey(dartVersion + '_' + countryCode))
            {
                throw new ExceptionGroup.FetchTokenException('Please make sure that product site was assigned correctly.');
            } 
            
        }
        
        return mapCredential.get(dartVersion + '_' + countryCode);
    }

 	public static void sendMail(String[] addr, String[] cc, String subject,String displayName,String body){
         
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        mail.setToAddresses(addr);
        
        if(cc != null)
        {
            mail.setCcAddresses(cc);
        }

        mail.setSenderDisplayName(displayName);
        
        mail.setSubject(subject);
        
        mail.setBccSender(false);

        mail.setUseSignature(false);

        mail.setHtmlBody(body);
        
        //start sending
        if(!Test.isRunningTest()) Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
     /** 
     * @description generated Ids for IN where clause
     * @param   sIds: list of string ids
     * @return  string of ids after generated
     */
    public static String generateIds(Set<String> sIds){
        String ids = '(';
        for(String s: sIds) {
            ids+='\''+s+'\',';
        }
        ids = ids.substring(0,ids.length()-1)+')';
        
        return ids; 
    }
    
    
    public static Geography__c[] getListGeographies(String targetingId)
    {
        return [Select Name, Country_Code__c, Dart_ID__c, Node_ID__c, Type__c From Geography__c Where ID IN (Select Geography__c From TargetingGeographyAssociation__c Where Targeting__c=:targetingId)];
    }
    
    
    public static Devices__c[] getListDevices(String targetingId)
    {
        return [Select Name, DFP_API_Name__c, Dart_ID__c, Node_ID__c From Devices__c Where ID IN (Select Device__c From TargetingDeviceAssociation__c Where Targeting__c=:targetingId)];
    }
    
     
    public static TargetingFrequencyAssociation__c[] getListFrequencyCappings(String targetingId)
    {
        return [Select Targeting__c, FC_Quantity__c, FC_Period__c, FC_Check_Inventory__c, FC_Ad_served_every__c From TargetingFrequencyAssociation__c Where Targeting__c=:targetingId AND FC_Check_Inventory__c=true];
    }
     
    public static Connection__c[] getListConnections(String targetingId)
    {
        return [Select Name, DFP_API_Name__c, Dart_ID__c, Node_ID__c From Connection__c Where ID IN (Select Connection__c From TargetingConnectionAssociation__c Where Targeting__c=:targetingId)];
    }
    
    /**Get list of Contents either by targetingId or ProductId
     * @param targetingId
     * @param productId
     * @return list of contents 
     */
     public static Content__c[] getListContents(String targetingId,String productId)
     {
        //1-Oppproduct.Targeting__r. TargetingContentAssociation__r.Content__r. Name 
        Content__c[] contents = getContentsByTargetType(targetingId, New List<String>{'Dart - Site'});//'a07R0000006nHV5'
        //get Content Id from Product
        Set<String> siteConId = new Set<String>();
        for(Product2 p: [SELECT PlacementDB__r.Content_Category_Site__c FROM Product2  WHERE ID=:productId])
        {
            siteConId.add(p.PlacementDB__r.Content_Category_Site__c);
        }
        
        //get Content from related Product and add to the existing list of Contents
        contents.addAll([SELECT Name,DartName__c  FROM Content__c WHERE ID IN:siteConId]); 
        
        return contents;
     }
     
     public static Content__c[] getPredefinedContents(String contId){
        return [SELECT Name, DartName__c, Id, Type__c  FROM Content__c Where Id=:contId];
     }
     public static Content__c[] getContentsByTargetType(String targetingId,List<String> cTypes) {
        return [SELECT Name,DartName__c,Site__r.Name,Site_Content_Category__r.Name, Type__c  FROM Content__c  
       					WHERE (Id IN (SELECT TargetingContent__c FROM TargetingContentAssociation__c
       			WHERE Targeting__c=:targetingId) AND Type__c IN :cTypes)];
     }
     
     public static Placement__c[] getPlacementTargeting(String targetingId) {
        return [SELECT Name, Dart_ID__c FROM Placement__c 
       				WHERE Dart_ID__c != null and (Id IN (Select Placement__c From PlacementTargetingAssociation__c WHERE Targeting__c =:targetingId))];
     }
      
     
      public static Devices__c[] getListDevicesCategory(List<String> lstDevName)
      {
            return [Select Id, Name, DFP_API_Name__c, Dart_ID__c, Node_ID__c From Devices__c Where Name IN:lstDevName and DFP_API_Name__c='DeviceCategory'];
      }
      
     
     public static Advertiser__c[] getAdvertiser(String accId, String agency) {
        return [Select id, Name, Dart5_Advertiser_Id__c, Dart6_Advertiser_Id__c, AdServer_Login_Name__c From Advertiser__c Where Advertiser__c.Account__c =: accId AND Advertiser__c.Agency__c =: agency];
     }
     
     
    
     public static Content__c[] getListAvailSites(String productId,Set<String> cType) {
         return [SELECT Name,DartName__c,Site_Content_Category__r.Name  FROM Content__c WHERE Id IN 
                (SELECT available_Site__c FROM Available_Site__c WHERE Product__c=:productId) and Type__c IN:cType];
     }
     
     final static String TD_STYLE='style="border:solid gray 1pt; padding:3pt 3pt 3pt 3pt"';
     final static String TD_TEMPLATE = '<TD '+ TD_STYLE +'>{0}</TD>';
     
     public static String genTD(String val) {
        return String.format(TD_TEMPLATE, new String[]{val});
     }
    
     final static String TR_TEMPLATE = '<TR>{0}</TR>';
     
     public static String genTR(String val) {
        return String.format(TR_TEMPLATE, new String[]{val});
     }
     
    
   	public static String generateTableForecastError(Map<String, Exception> mapError) {
       String trBody = '';//all TRs and TDs
       for(String st : mapError.keySet()) {
           String tds = genTD('<a href='+ URL_INSTANCE+'/'+st +'>'+st+'</a>')+ 
                        genTD(mapError.get(st).getMessage());          
           String trs = genTR(tds);            
           trBody += trs;
       }
       return trBody;   
	}
   
    public static Integer countCurrentBatch() { return [select count() FROM AsyncApexJob a WHERE Status='Queued']; }  
    
    
    public static Double toDouble(String s) {
        try{
            return Double.valueOf((s+'').replace(',','.'));
        } catch(Exception ex) { return 0; }
    }   
    
   
    public static Integer toInteger(String s) {
        try{
            return (s==null?0:Integer.valueOf((s+'')));
        } catch(Exception ex) { return 0; }
    } 
    
    
    public static Integer toInteger(Decimal d) {
        try{ 
        	return (d==null?0:Integer.valueOf((d+'')));
        } catch(Exception ex) { return 0; }
    }  
    
    /** 
     * Excract the user friendly message from webserice call out failure 
     * ex:
     * Web service callout failed: WebService returned a SOAP Fault: [RequiredError.REQUIRED @ targeting.inventoryTargeting] faultcode=soap:Server faultactor=
    
     * -> RequiredError.REQUIRED @ targeting.inventoryTargeting
     * @param msg
     * @return string
    */
    public static String extractMessage(String msg) {
        Matcher m = Pattern.compile(DART6Message.DART6_WS_ERROR_PATTERN).matcher(msg);
        while (m.find()) { return m.group(1); }
        //in case...
        return msg; 
    }
    
    
    
    public static boolean isNumber(String s) {
        try {
            Double.valueOf(s);
            return true;
        } catch(Exception ex) { return false; }
    }
    
    private static final String[] HTML_CHAR  = new String[]{ '<', '>', '"', '\'','&'};
    private static final String[] HTML_CHAR_ENCODED  = new String[]{ '&lt;', '&gt;', '&quot;', '&#39;','&amp;' };
    
    public static String encodeHTML(String s) {
        if (String.isBlank(s)) return s;

        for (Integer i = 0; i < HTML_CHAR.size(); ++i) {
            s = s.replace(HTML_CHAR[i], HTML_CHAR_ENCODED[i]);
        }
        return s;
    }
    /**
     * @description: get googe access token
     * @createdDate: 11-04-2014
     * @param: AdserverLogin__c login
     * @return google access token
     */
    static String access_token;
    public static String getAccessToken(AdServer_Login__c login)
    {
        //get custtom setting
        //String access_token;
        try {
            if(access_token == null) {
                if(login.Refresh_Token__c==null) {
                    throw new ExceptionGroup.DARTException('Refresh Token is not defined in the AdserverLogin. Please login and save via DFPCredential Page.');
                }
                
                String body ='refresh_token=%rtoken%&client_id=%clid%&client_secret=%secret%&grant_type=refresh_token';
                body=body.replace('%rtoken%',login.Refresh_Token__c).replace('%clid%',login.Client_Id__c).replace('%secret%',login.Client_Secret__c);
                
                if(Test.isRunningTest()) {
                    return 'xxxxxxxxxxxxxxxxxx';
                }
                access_token = oauth2Request(body,'access_token'); //pick up the field "access_token" from the response
            }
        } catch(Exception ex){throw ex;} 
        return access_token;
    }

    public static void clearAccessToken(){access_token = null;} // 01.12.2021 / Sophal Noch / US-0009927
    
    /**
     * @param body
     * @param requestFieldName
     * @return string
     */
    public static String oauth2Request(String body,String requestFieldName) {
        HTTPWrapper.IRequest reqToken = new HTTPWrapper.SimpleRequest(ENDPOINT_GOOGLE_OAUTH2_TOKEN,'POST',body);
        HTTPWrapper.SimpleResponse resToken = new HTTPWrapper.SimpleResponse(reqToken);
        
        //resp is a JSON string
        JSONParser parser = JSON.createParser(resToken.getResBody()); 
        while (parser.nextToken() != null) {
        	if((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                String fieldName = parser.getText();
                parser.nextToken();
                if(requestFieldName == fieldName) {
                    return parser.getText();
                } else if(fieldName=='error') {
                    throw new ExceptionGroup.DARTException('Request to DFP returns error: '+parser.getText());
                }
        	}
		}
        return null;
    }
    
    /**https://help.salesforce.com/articleView?id=000233174&type=1
     * Convert string datetime to userTimezone, Help Reference:
     * Bunhor @17-Mar-17: update this method
     */
    public static DateTime fixTimezoneDateTime(String sourceDateStr, String userTimezone){
        TimeZone extz = TimeZone.getTimeZone(userTimezone);
        
        Integer ex = - extz.getOffset(system.now());
		
		DateTime dfpTime = DateTime.valueOfGmt(sourceDateStr);
		
		DateTime dfpTimeGmt = dfpTime.addMinutes((ex) / (1000 * 60));
		
        return dfpTimeGmt;
    }
    

	public static string checkDfpReuiredFields(SObject item) {
		/** Commented out this code as ad unit is not required any more, and default is Site__r.Run_of_Network_ID__c
		Id tgId = (Id) item.get(Util.NS+'Targeting__c');
		if (tgId == null) return Label.ERR_DFP_REQUIRED_ADUNIT;
		if (item.get(Util.NS+'Predefined_Adunit__c') != null) return null;
        
      	boolean hasInventoryTargeting = false;
      	for(TargetingContentAssociation__c ass : [select id from TargetingContentAssociation__c where Targeting__c = :tgId]) {
      		hasInventoryTargeting = true;
      	}
      	if(hasInventoryTargeting == false) {
      		for(PlacementTargetingAssociation__c ass : [Select id From PlacementTargetingAssociation__c WHERE Targeting__c = :tgId]) {
	      		hasInventoryTargeting = true;
	      	}
      	}
      	if(hasInventoryTargeting == false) {
      		return Label.ERR_DFP_REQUIRED_ADUNIT;
      	}
      	*/
      	return null;
    }
}