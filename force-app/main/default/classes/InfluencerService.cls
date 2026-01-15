/*********************************************************************************************************************************
    @ Class:         InfluencerService
    @ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0011821 - 1.2.2 Influencer (API for channel record)
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  04.07.2022 / Acmatac SEING / Created the class.
    @               :  22.11.2022 / Bora CHHORN / US-0012636 - Influencer (API Profile Picture)
    @               :  06.04.2023 / Bora CHHORN / US-0013438 - Remove access_token parameter from Influencer Service
*********************************************************************************************************************************/
public with sharing class InfluencerService {
    private static final String INSTAGRAM_CHANNEL = 'instagram';
    private static final String UKNOWN_ERROR = 'Unknown Error';
    private static final String OTHER_CHANNEL = 'other';
    // Instagram Service
    private static final String INSTAGRAM_BUSINESS_DISCOVERY_SERVICE = 'instagram_business_discovery';

    private static final Map<String, String> mSocialChannel = new Map<String, String>{
        'twitter' => 'Twitter',
        'instagram' => 'Instagram',
        'tiktok' => 'TikTok',
        'youtube' => 'YouTube',
        'facebook' => 'Facebook',
        'snapchat' => 'Snapchat',
        'twitch' => 'Twitch',
        'blog' => 'Blog',
        'other' => 'Other'
    };

    private static final string IG_MOCK_BODY= '{ "business_discovery": { "username": "justinbieber", "followers_count": 247265482, "follows_count": 715, "media_count": 7313, "id": "17841400365670107" }, "id": "17841454032970258" }';
    private static final string DEFAULT_MOCK_BODY= '{ "business_discovery": { "username": "justinbieber", "followers_count": 247265482, "follows_count": 715, "media_count": 7313, "id": "17841400365670107" }, "id": "17841454032970258" }';

    /*********************************************************************************************************************************
    @ Method:         getUserInformation
    @ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0011821 - 1.2.2 Influencer (API for channel record)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    List<InfluencerService.CustomParameter> parameter
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  04.07.2022 / Acmatac SEING / Created the method.
    *********************************************************************************************************************************/
    @InvocableMethod(label='getUserInformation' description='Retrieve User Information')
    public static List<InfluencerService.ResultWrapper> getUserInformation(List<InfluencerService.CustomParameter> parameter) {
        InfluencerService.ResultWrapper rw = new InfluencerService.ResultWrapper();
        rw.channelRecord = new Channel__c();

        IService callService = null;
        String serviceName = checkServiceName(parameter);
        String domainName = getDomain_FromURL(parameter);
        rw.channelRecord.Social_Media_Channel_Type__c = mSocialChannel.get(domainName);
        // If Domain not instagram then let user manual populate
        if(domainName != INSTAGRAM_CHANNEL){
            return new List<InfluencerService.ResultWrapper>{rw}; 
        }

        if(serviceName==INSTAGRAM_BUSINESS_DISCOVERY_SERVICE)
        {
            callService = new InstagramService(parameter);
        }else {
            InfluencerService.ResultWrapper rwE = new InfluencerService.ResultWrapper('Error: Unknown Service');
            return new List<InfluencerService.ResultWrapper>{rwE};
        }
       
        //if good continue result inspection
        callService.sendRequest();
        if(callService.hasError())
        {
            List<Object> listMessage = callService.getMessages();
            rw.hasError = true;
            rw.errorMessage = String.join(listMessage, ', ');
        }else 
        {
            //handle result
            List<Object> listResult = callService.getResult();
            rw.hasError = callService.hasError();
            rw.channelRecord = (Channel__c) listResult[0];
            rw.channelRecord.Social_Media_Channel_Type__c = mSocialChannel.get(domainName);
        }

        return new List<InfluencerService.ResultWrapper>{rw};
    }

    private static String checkServiceName(List<InfluencerService.CustomParameter> parameter)
    {
        return parameter[0].target; 
    }

    public class CustomParameter{
        @InvocableVariable
        public String target;

        @InvocableVariable
        public String url;
    }

    public class ResultWrapper{
        @InvocableVariable
        public Channel__c channelRecord;

        @InvocableVariable
        public Boolean hasError;
        @InvocableVariable
        public String errorMessage;
        public ResultWrapper(){
            this.channelRecord = new Channel__c();
            this.hasError = false;
            this.errorMessage = '';
        }
        public ResultWrapper(String errorMessage){
            this.channelRecord = new Channel__c();
            if(String.isBlank(errorMessage)){
                this.hasError = false;
            }else{
                this.hasError = true;
            }
            this.errorMessage = errorMessage;
        }
        
    }

    /*********************************************************************************************************************************
    @ Change history:  22.11.2022 / Bora CHHORN / US-0012636 - Influencer (API Profile Picture)
    *********************************************************************************************************************************/
    public class InstagramParser implements IParser{
        private Channel__c instaObj = new Channel__c();
        private String jsonInstagram;

        public InstagramParser(){}

        public InstagramParser(String jsonInsta){
            jsonInstagram = jsonInsta;
        }

        public void parse(){
            Map<String,Object> mObjRaw = (Map<String,Object>) JSON.deserializeUntyped(jsonInstagram);
            Map<String,Object> mObjBD = (Map<String,Object>) mObjRaw.get('business_discovery');
            instaObj = new Channel__c(
               Name = String.valueOf(mObjBD.get('username')),
               Followers_Subscribers__c = Integer.valueOf(mObjBD.get('followers_count')),
               Following__c = Integer.valueOf(mObjBD.get('follows_count')),
               Posts_total__c = Integer.valueOf(mObjBD.get('media_count')),
               Profile_Picture_Source__c = String.valueOf(mObjBD.get('profile_picture_url')) //BR-22-11-22-US-0012636
            );
        }
        public void parse(String data)
        {
            jsonInstagram = data;
            parse();
        }

        public Object getData(){
            return instaObj;
        }
    }
    private static String getDomain_FromURL(List<InfluencerService.CustomParameter> parameter){
        return getDomain_FromURL(parameter[0].url);
    }
    private static String getDomain_FromURL(String url){
        // Example: www.instagram.com/username => ['www', 'instagram', 'com/username'];
        List<String> splitedLinks = url.contains('.') ? url.split('\\.') : new List<String>();
        String strDomain = splitedLinks.size()>1 ? splitedLinks.get(1).toLowerCase() : '';
        return mSocialChannel.keySet().contains(strDomain) ? strDomain : InfluencerService.OTHER_CHANNEL;
    }

    class InfluencerException extends Exception{

    }
    class ParseException extends Exception{

    }
    
    interface IParser{
        void parse();

        void parse(String resBody);
        Object getData();
    }

    interface IService{
        void sendRequest();
        List<Object> getResult();
        Boolean hasError();
        List<Object> getMessages();
    }

    abstract class BaseService implements IService{
        protected List<InfluencerService.CustomParameter> parameters;
        protected String method = 'GET'; // default
        protected String endpoint;
        protected Map<String,String> mapHeaders;
        protected Influencer_Service_Provider__mdt mdt;
        protected String metadataName;
        protected ResultWrapper resultWrap;
        protected IParser parser;
        protected Boolean hasError = false;
        protected List<Object> listMessage;

        protected HTTPWrapper.IRequest request;
        protected HTTPWrapper.SimpleResponse responseResult ;
        protected String reqBody;
        public BaseService(String metadataName,IParser parser)
        {
            this.metadataName = metadataName;
            this.parser = parser;
            getMetadata();
            mapHeaders = new Map<String,String>();
            listMessage = new List<Object>();
        }

        public void sendRequest()
        {    
            try{  
                constructEndpoint();
                constructHeader(); 
                request = new HTTPWrapper.SimpleRequest(endpoint,method,reqBody, mapHeaders);
                responseResult = new HTTPWrapper.SimpleResponse(request); 
                constructMockBody();
                
                if (responseResult.statusCode==200){
                    parser.parse(responseResult.getResBody());     
                }
                else{
                    constructError();
                }
            }catch(ParseException ipex){
                constructError(ipex);
            }
        }
        //error from internal exception
        private void constructError(Exception ex)
        {
            hasError = true;
            listMessage.add(InfluencerService.UKNOWN_ERROR+ex.getMessage()+', Trace:'+ex.getStackTraceString());
        }
        protected virtual void constructError()
        {
            hasError = true;
        }

        protected virtual void constructMockBody(){
            responseResult.mockBody = InfluencerService.DEFAULT_MOCK_BODY;
        }

        public Boolean hasError()
        {
            return hasError;
        }
        public List<Object> getMessages()
        {
            return listMessage;
        }

        public virtual List<Object> getResult()
        {
            return new List<Object>{parser.getData()};
        }

        private Influencer_Service_Provider__mdt getMetadata()
        {             
            // US-0012874 - Moving from query customMetadata to GetInstance
            // mdt = [SELECT DeveloperName
            //     , Access_Token__c
            //     , Base_URL__c
            //     , Mulesoft_Client_Id__c
            //     , Mulesoft_Client_Secret__c
            //     , Target__c
            //     , Instagram_Id__c
            //     , Fields__c
            // FROM Influencer_Service_Provider__mdt WHERE DeveloperName = :metadataName];
            mdt = Influencer_Service_Provider__mdt.getInstance(metadataName);
            return mdt;
        }
        protected virtual void constructEndpoint()
        {
             
        }
        protected virtual void constructHeader()
        {
            mapHeaders.put('Authorization','Basic '+EncodingUtil.base64Encode(Blob.valueOf(mdt.Mulesoft_Client_Id__c+':'+mdt.Mulesoft_Client_Secret__c)));
        }
        public String getEndpoint()
        {
            return endpoint;
        }
        public Map<String,String> getHeaders()
        {
            return mapHeaders;
        }
    }


    //service for Instagram. another new service needs to extends the same BaseService
    /*
    @ Change history:  06.04.2023 / Bora CHHORN / US-0013438 - Remove access_token parameter from Influencer Service
    */
    class InstagramService extends BaseService{
        private String igUsername;
        public InstagramService(List<InfluencerService.CustomParameter> parameter)
        {
            super(INSTAGRAM_BUSINESS_DISCOVERY_SERVICE,new InstagramParser());
            this.parameters = parameter;
            getIGUsername();
        }

        protected override void constructEndpoint()
        {
            //BR-06-04-23-US-0013438 / Remove access_token parameter
            this.endpoint = mdt.Base_URL__c + '?username='+igUsername+'&target='+mdt.Target__c+'&instagram_id='+mdt.Instagram_Id__c+'&fields='+mdt.Fields__c.deleteWhitespace(); 
        }
        protected override void constructHeader()
        {
            mapHeaders = new Map<String,String>{'Content-Type'=>'application/x-www-form-urlencoded'};
            super.constructHeader();
        } 

        //error from server
        protected override void constructError()
        {
            hasError = true;
            Map<String,Object> mapResponse = (Map<String,Object>) JSON.deserializeUntyped(responseResult.getResBody());
            
            if(mapResponse.containsKey('error_response')){
                listMessage.add(INSTAGRAM_CHANNEL+':'+String.valueOf(mapResponse.get('error_response')));

            }else {
                listMessage.add(String.valueOf(responseResult.getResBody()));
            }
        }

        private void getIGUsername(){
            String url = this.parameters[0].url;
            // Example: www.instagram.com/username => ['www', 'instagram', 'com/username'];
            List<String> splitedLinks = url.contains('.') ? url.split('\\.') : new List<String>();
            this.igUsername = splitedLinks.size()>2 && splitedLinks.get(2).contains('/') ? splitedLinks.get(2).split('/').size()>1 ? splitedLinks.get(2).split('/')[1] : '' : '';
        }

        protected override void constructMockBody(){
            responseResult.mockBody = InfluencerService.IG_MOCK_BODY;
        }

        
    }
}