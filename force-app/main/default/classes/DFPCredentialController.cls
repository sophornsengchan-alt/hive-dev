/**
 * Process to get Oauth token
     : 14.09.2023 /vadhanak voun / US-0013942 - PART 4 - Upgrade API version of all classes having an API version lower than 31
 */
public with sharing class DFPCredentialController {
    
    public static final String ENDPOINT_GOOGLE_OAUTH2_TOKEN = 'https://accounts.google.com/o/oauth2/token';

    public List<AdserverLoginDTO> lstAdsDTO{get; set;}
    public String selectedValue { get; set; }
    public Boolean isChecked{get;set;}
    public String refreshToken{get; set;}
    public Boolean isSaveToken{get; set;}
    
    public static final String REDIRECT_URI = 'https://'+URL.getSalesforceBaseURL().getHost() + Page.DFPCredentialPage.getUrl()+'?retgoogle=1';
    public static final String DFP_SCOPE = 'https://www.googleapis.com/auth/dfp';
    public static final String ADX_SCOPE = 'https://www.googleapis.com/auth/adexchange.seller';
    final String CREDENTIAL_PAGE_NAME = Page.DFPCredentialPage.getUrl();  
    
    
    /**
     * constructor
     */
    public DFPCredentialController()
    {
        lstAdsDTO  = new List<AdserverLoginDTO>();
        for(AdServer_Login__c adslog : [SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c, Network_Name__c, Active__c, Refresh_token__c FROM AdServer_Login__c WHERE isDeleted=false])
        {
            AdserverLoginDTO adsDto = new AdserverLoginDTO(adslog, false);
            lstAdsDTO.add(adsDto);
        }       
        
        // Get authorization code after authentication
        String AuthorizeCode = ApexPages.currentPage().getParameters().get('code');
            
        // Exchange authorization code for refresh token
        if(AuthorizeCode != null)   
        {
            isSaveToken=true;
            refreshToken = exchangeCodeForRefreshToken(AuthorizeCode);
        }
        
    }
    
    /**
     * Process to get oauth token
     */
    public PageReference processCredential()
    {
        
        if(selectedValue==null || selectedValue=='')
        {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Please select one record to process.'));
            return null;
        }
        PageReference pg;
        
        List<AdServer_Login__c> lstAdLoginSelected = [Select Client_Secret__c, Client_Id__c, Refresh_Token__c, Network_ID__c From AdServer_Login__c Where id =: selectedValue];
        String scope='';
        if(!lstAdLoginSelected.isEmpty())
        {
            AdServer_Login__c lg = lstAdLoginSelected.get(0);
            scope = (lg.Network_ID__c==null?ADX_SCOPE:DFP_SCOPE);
            if(lg.Client_Id__c == null || lg.Client_Secret__c == null)
            {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Required field missing: '+(lg.Client_Id__c==null?Util.NS+'Client_Id__c':Util.NS+'Client_Secret__c')+' in the selected record.'));
                return null;
            } 
            lg.RT_Waiting__c = true;
            update lg;

            String urlOfflineAccess = 'https://accounts.google.com/o/oauth2/auth?access_type=offline&approval_prompt='+
               'force&scope='+ scope +'&response_type=code'+
               '&client_id='+ lg.Client_Id__c +
               '&redirect_uri='+ EncodingUtil.urlEncode(REDIRECT_URI, 'UTF-8');

            pg = new PageReference(urlOfflineAccess);
            pg.setRedirect(true);
        }
        
        return pg;
    }
    
    /** 
     * After user login, google returns the oauthCode, use it to exchange for the refresh token 
     */
    public  String exchangeCodeForRefreshToken(String oauthCode)
    {
        String refresh_token;
        try
        {
            List<AdServer_Login__c> lstAds = getListAdsLogin();
            String body ='code=%code%&client_id=%clid%&client_secret=%secret%&redirect_uri=%redirecturi%&grant_type=authorization_code'; //  refresh_token
            body=body.replace('%code%',oauthCode).replace('%clid%',lstAds.get(0).Client_Id__c).replace('%secret%',lstAds.get(0).Client_Secret__c).replace('%redirecturi%',REDIRECT_URI);
            refresh_token = DARTUtil.oauth2Request(body,'refresh_token'); //pick up the field "refresh_token" from the response
        }
        catch(Exception ex){throw ex;} 
        
        return refresh_token;
    }
    
    /**
     * Save oauth refresh token to AdserverLogin
     */
    public PageReference saveToken()
    {
        isSaveToken=false;
        try
        {
            List<AdServer_Login__c> lstAdsLog =  getListAdsLogin();
            lstAdsLog.get(0).Refresh_Token__c = refreshToken;
            lstAdsLog.get(0).RT_Waiting__c = false;
            update lstAdsLog;
        }
        catch(Exception ex){ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex+''));}

        PageReference pg = new PageReference(CREDENTIAL_PAGE_NAME);
        pg.setRedirect(true);
        return pg;
    }
    
    /**
     * Cancel if user dont want to save refresh token
     */
    public PageReference cancel()
    {
        List<AdServer_Login__c> lstAdsLog =  getListAdsLogin();
        lstAdsLog.get(0).RT_Waiting__c = false;
        update lstAdsLog;
        PageReference pg = new PageReference(CREDENTIAL_PAGE_NAME);
        pg.setRedirect(true);
        return pg;
    }
    
    /**
     * @return list of AdserverLogins where RT_Waiting__c=true
     */
    public static List<AdServer_Login__c> getListAdsLogin()
    {
        List<AdServer_Login__c> lstLog = [SELECT Client_Id__c, Client_Secret__c, Refresh_Token__c, RT_Waiting__c From AdServer_Login__c WHERE RT_Waiting__c = true Order By LastModifiedDate DESC limit 1 ];
        if(lstLog.isEmpty())
        {
            throw new ExceptionGroup.DARTException('There is no Adserver login to get refresh token.');
        }
        
        return lstLog;
    }
    
    /**
     * @createdDate: Chr - 10-04-2015
     * @Desc: Get Run of nework Id for default adunitId
     * and save to Site__c.Run_of_Network_ID__c (site will get where site.country__c = AdserverLogin.name)
     */
     public PageReference getRunOfNetworkID()
     {
        try{
            if(selectedValue==null || selectedValue=='')
            {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Please select one record to process.'));
                return null;
            }
            List<AdServer_Login__c> lstAdLogin = [Select Client_Secret__c, Client_Id__c, Refresh_Token__c, Network_Id__c, Name From AdServer_Login__c Where id =: selectedValue];
            if(!lstAdLogin.isEmpty() && (lstAdLogin[0].Client_Id__c == null || lstAdLogin[0].Client_Secret__c == null || lstAdLogin[0].Refresh_Token__c == null))
            {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Required field missing: '+(lstAdLogin[0].Client_Id__c==null?Util.NS+'Client_Id__c':(lstAdLogin[0].Client_Secret__c==null?Util.NS+'Client_Secret__c':Util.NS+'Refresh_Token__c')+' in the selected record.')));
                return null;
            }
            String authToken = (!lstAdLogin.isEmpty()?DARTUtil.getAccessToken(lstAdLogin.get(0)):''); 
             
            DART6_NETWORKSERVICE.SoapRequestHeader header = new DART6_NETWORKSERVICE.SoapRequestHeader();
            header.applicationName = 'NetworkService'; 
            header.networkCode= lstAdLogin[0].Network_Id__c; 
           
            Map<String,String> inputHttpHeaders_x = new Map<String, String>();
            inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken); 
             
            DART6_NETWORKSERVICE.NetworkServiceInterfacePort creRequest = new DART6_NETWORKSERVICE.NetworkServiceInterfacePort();
            creRequest.RequestHeader = header;
            creRequest.inputHttpHeaders_x = inputHttpHeaders_x;  
            System.debug('-------->>creRequest::::' + creRequest);    
            DART6_NETWORKSERVICE.Network network = creRequest.getCurrentNetwork();
            String siteName =  (!lstAdLogin.isEmpty()?lstAdLogin.get(0).Name:'');
            List<Site__c> sites = [Select id, Name, Run_of_Network_ID__c From Site__c Where Country__c=:siteName];
            if(!sites.isEmpty()) sites.get(0).Run_of_Network_ID__c = network.effectiveRootAdUnitId+'';
            else {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'There is no site related to AdserverLogin\'s Name: '+ siteName));
                return null;
            }
            update sites;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Run of Network ID has been saved to site: '+sites[0].Name));
        }catch(Exception ex){
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex+''));
        }    
        return null;
     }
    
    
    
    /** AdserverLogin DTO */
    public class AdserverLoginDTO
    {
        public AdServer_Login__c adserverLogin{get; set;}
        public Boolean isChecked{get;set;}
        
        public AdserverLoginDTO(AdServer_Login__c adserverLogin, Boolean isChecked)
        {
            this.isChecked = isChecked;
            this.adserverLogin = adserverLogin;
        }
        
    }
}