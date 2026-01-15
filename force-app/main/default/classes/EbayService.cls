/*********************************************************************************************************************************
@ class:        EbayService
@ Version:       1.0
@ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       US-0009877 - [SEP-EU] Item Listing for the Deals creation for EU Deals@                
@                https://developer.ebay.com/api-docs/buy/browse/resources/item/methods/getItemByLegacyId
@                https://developer.ebay.com/devzone/finding/CallRef/findItemsAdvanced.html
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.09.2021 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / request_token
*********************************************************************************************************************************/
public with sharing class EbayService {
     
    private static Access intel_access;
    public static Access getAccess()
    {   
        if(intel_access==null)
        {
            intel_access = new Access();
        }
        return intel_access;
    }

    class EbayException extends Exception{

    }
     
    public class Access{
         
        Ebay_SSO_Provider__mdt cred;

        public String accesToken {get;private set;}        
        private Map<String,Object> mapResult;

        

        public String request_token()
        {
            if(accesToken !=null)
            {
                return accesToken;
            }

            Ebay_SSO_Provider__mdt cred =  Ebay_SSO_Provider__mdt.getInstance('ebay_sep');
            if(cred == null)
            {
                throw new EbayException('No Credential defined in Ebay_SSO_Provider__mdt for this org.');
            }

            String endPoint = cred.Token_URL__c+'?grant_type=client_credentials&scope=https%3A%2F%2Fapi.ebay.com%2Foauth%2Fapi_scope';
            Map<String,String> mapHeader = new Map<String,String>{'Content-Type'=>'application/x-www-form-urlencoded'};             
           
            String pHeader = EncodingUtil.base64Encode(Blob.valueOf(cred.Client_Id__c+':'+cred.Client_Secret__c));            
            mapHeader.put('Authorization','Basic '+pHeader);            
         

            HTTPWrapper.IRequest reqToken = new HTTPWrapper.SimpleRequest(endPoint,'POST','',mapHeader);
            HTTPWrapper.SimpleResponse resToken = new HTTPWrapper.SimpleResponse(reqToken); 
            
            resToken.mockBody = MOCK_TOKEN_RES;
            
            mapResult = (Map<String,Object>)JSON.deserializeUntyped(resToken.getResBody());

            //System.debug('----res body-----: '+resToken.getResBody());
            if(mapResult.containsKey('error'))
            {
                throw new EbayException('Authentication: '+resToken.status+' : '+mapResult.get('error')+ ' : ' +mapResult.get('error_description')+'');
            }else if(!mapResult.containsKey('error') && !mapResult.containsKey('access_token'))
            {
                throw new EbayException('Unknown Authentication Error: '+resToken.status+' : '+resToken.getResBody());
            }

            accesToken = mapResult.get('access_token')+'';

            return accesToken;
        }

    }

    interface IService{
        void sendRequest();
        Map<String,Object> getResult();
        List<Object> getListObject();   //In case we need a ready-object

        Boolean isSuccess();
        
    }

    abstract class BaseService implements IService{
        
        protected String endPoint;
        protected String servicePath;
        protected Map<String,String> mapHeader;
        protected String method;
        protected String payload = '';
        protected String mockBody = '';

        protected String resMessage = '';
        protected Boolean isSuccess;

        protected Map<String,Object> mapResponse;

        protected Map<String,Object> mapParam; //body of the request  

        protected boolean useAuthorization = true;

        public BaseService(String method)
        {            
            this.method = method;
            
            mapHeader = new Map<String,String>{'Content-Type'=>'application/json'};
        }
        
        protected virtual void constructEndpoint()
        {
            Ebay_SSO_Provider__mdt cred =  Ebay_SSO_Provider__mdt.getInstance('ebay_sep');      
            endPoint = cred.FindingService_Endpoint__c;  
            mapHeader.put('X-EBAY-SOA-SECURITY-APPNAME',cred.Client_Id__c);  
        }
        
        public void sendRequest()
        {
            isSuccess = true;
            try
            {
                if(useAuthorization)
                {
                    String accToken = getAccess().request_token();
                    mapHeader.put('Authorization','Bearer '+accToken);
                }                
                
                constructEndpoint();
                //endPoint = 'https://api.ebay.com/buy/browse/v1/item_summary/search?q=BlasterX&category_ids=58058&filter=sellers:{noborie95731}&aspect_filter=categoryId:58058,Brand:{Creative Media}&limit=20&offset=0';
                
                endPoint = Test.isRunningTest()?'https://test.test':endPoint;

                HTTPWrapper.IRequest request = new HTTPWrapper.SimpleRequest(endPoint,method,payload,mapHeader);
                HTTPWrapper.SimpleResponse response = new HTTPWrapper.SimpleResponse(request); 
                response.mockBody = mockBody;
                system.debug('--endPoint: '+endPoint);
                system.debug('--payload: '+payload);
                system.debug('--mapHeader: '+mapHeader);
                system.debug('--getResBody: '+response.getResBody());

                if((response.getResBody()+'').startsWith('{'))
                {
                    mapResponse = (Map<String,Object>)JSON.deserializeUntyped(response.getResBody());
                }else
                {
                    mapResponse= new Map<String,Object>{'response'=>response.getResBody()};
                }
                
                
                isSuccess = response.statusCode == 200;

                if(mapResponse.containsKey('error'))
                {
                    isSuccess = false;throw new EbayException(mapResponse.get('error_description')+'');
                }else if(mapResponse.containsKey('errors'))
                {
                    isSuccess = false;throw new EbayException(mapResponse.get('errors')+'');
                }else if(response.statusCode != 200)
                {
                    isSuccess = false;throw new EbayException('Unknown Error: '+response.status+' : ' +response.getResBody());
                }

            }catch (Exception ex)
            {                
                isSuccess = false;System.debug(ex);throw new EbayException(ex.getMessage());
            }
           
        }

        public Map<String,Object> getResult()
        {
            return mapResponse;
        }

        public virtual List<Object> getListObject(){
            return null;
        }

        public virtual Boolean isSuccess()
        {
            return isSuccess;
        }
         
    }
    public final static Map<String,String> MAP_EBAY_SITE = new Map<String,String>
    {
        '0'=>'EBAY-US',
        '2'=>'EBAY-CA',
        '3'=>'EBAY-GB',
        '77'=>'EBAY-DE',
        '15'=>'EBAY-AU',
        '71'=>'EBAY-FR',
        '101'=>'EBAY-IT',
        '186'=>'EBAY-ES'    
    };

    final static Map<String,String> BRAND_FILTER_LANG = new Map<String,String>
    {
        '0'=>'Brand',
        '2'=>'Brand',
        '3'=>'Brand',
        '77'=>'Marke',
        '15'=>'Brand',
        '71'=>'Marque',
        '101'=>'Marca',
        '186'=>'Marca'    
    };

    // public class SearchService extends BaseService{

    //     private Integer search_limit = 20; //item per page result        
    //     private Integer totalResult = 0;    // number of all item
    //     private Integer totalPage = 1; 
    //     private Integer requestPage = 1; 
       
    //     private String sellerId;
    //     private String siteId;
    //     private String catId;
    //     private String brand;
    //     private String searchKey;        

    
    //     public SearchService(String sellerId,String siteId,String catId,String brand,String searchKey,Integer requestPage,Integer search_limit)
    //     {
    //         super('POST');

    //         this.sellerId = sellerId;
    //         this.siteId = siteId;
    //         this.catId = catId;
    //         this.brand = brand;//EncodingUtil.urlEncode(brand,'UTF-8');
    //         this.searchKey = searchKey;//EncodingUtil.urlEncode(searchKey,'UTF-8');
    //         this.requestPage = requestPage;
    //         this.search_limit = search_limit;
            
    //         mockBody = MOCK_SEARCH_RESULT;
    //     }
        
    //     protected override void constructEndpoint()
    //     {                       
    //         Map<String,Object> mapPayload = new Map<String,Object>
    //         {
    //             'findItemsAdvancedRequest'=> new Map<String,Object>
    //             {
    //                 'categoryId'=>catId,
    //                 'keywords'=>searchKey,
    //                 'itemFilter'=> new Map<String,Object>
    //                     {
    //                         'name'=>'Seller',
    //                         'value'=>sellerId
    //                     },
    //                 'aspectFilter'=> new Map<String,Object>
    //                     {
    //                         'aspectName'=> (siteId=='77'?'Marke':'Brand'),  //NK:25/10/2021: german uses Marke as aspec filter
    //                         'aspectValueName'=>brand
    //                     },
    //                 'paginationInput'=> new Map<String,Object>
    //                     {
    //                         'pageNumber'=>requestPage,
    //                         'entriesPerPage'=>search_limit
    //                     }
    //             }
    //         };

    //         payload = JSON.serialize(mapPayload);

    //         mapHeader.put('X-EBAY-SOA-SECURITY-APPNAME','');
    //         mapHeader.put('X-EBAY-SOA-OPERATION-NAME','findItemsAdvanced');
    //         mapHeader.put('X-EBAY-SOA-REQUEST-DATA-FORMAT','JSON');
    //         mapHeader.put('X-EBAY-SOA-RESPONSE-DATA-FORMAT','JSON');            
    //         mapHeader.put('X-EBAY-SOA-GLOBAL-ID',MAP_EBAY_SITE.containsKey(siteId)? MAP_EBAY_SITE.get(siteId):'');

    //         super.constructEndpoint();
            
    //     }
      
    //     public Object getPage()
    //     {
    //         List<Object> listResRoot = (List<Object>)mapResponse.get('findItemsAdvancedResponse');   
    //         Map<String,Object> mapResult    = (Map<String,Object>)listResRoot.get(0);   
         
    //         return (List<Object>)ApexUtil.getJSONValue(mapResult,'paginationOutput');
    //     }
        
    //     public override List<Object> getListObject()
    //     {    
            
    //         List<Object> listResRoot = (List<Object>)mapResponse.get('findItemsAdvancedResponse');            
    //         Map<String,Object> mapResult    = (Map<String,Object>)listResRoot.get(0);   
           
    //         return (List<Object>)ApexUtil.getJSONValue(mapResult,'searchResult');
 
    //     }

    //     public override Boolean isSuccess()
    //     {
    //         List<Object> listResRoot = (List<Object>)mapResponse.get('findItemsAdvancedResponse');   
    //         Map<String,Object> mapResult    = (Map<String,Object>)listResRoot.get(0);   
    //         return (String) ((Object[])mapResult.get('ack'))[0] =='Success';
    //     }
    // }

    

    /*********************************************************************************************************************************
    @ class:   SearchService
    @ Version:       2.0
    @ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:       US-0010734 - [SP - EU Deals] [Bug] Upgrade the API to get all the products under the Brand filter. Fix issue with Brand filter on Item Picker
    @                 new search api - to  fix the issue when filter brand (missing item)
    @                 https://developer.ebay.com/api-docs/buy/browse/resources/item_summary/methods/search
    @----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.11.2021 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / created class
    *********************************************************************************************************************************/
    public class SearchService extends BaseService{

        private Integer search_limit = 50; //item per page result        
        private Integer totalResult = 0;    // number of all item
        private Integer totalPage = 1;       
        private Integer requestOffset = 0;
       
        private String sellerId;
        private String siteId;
        private String catId;
        private String brand;
        private String searchKey;        

    
        public SearchService(String sellerId,String siteId,String catId,String brand,String searchKey,Integer requestOffset,Integer search_limit)
        {
            super('GET');

            this.sellerId = sellerId;
            this.siteId = siteId;
            this.catId = catId;
            this.brand = brand;//EncodingUtil.urlEncode(brand,'UTF-8');
            this.searchKey = searchKey;//EncodingUtil.urlEncode(searchKey,'UTF-8');
            this.requestOffset = requestOffset;
            this.search_limit = search_limit;
            
            mockBody = MOCK_SEARCH_RESULT2;
        }
        
        protected override void constructEndpoint()
        {  
            List<String> listParam  = new List<String>{
                'q='+(String.isBlank(searchKey)?'':EncodingUtil.urlEncode(searchKey.trim(), 'UTF-8')),
                'filter=sellers:{'+sellerId+'}',
                'aspect_filter=categoryId:'+catId+','+ BRAND_FILTER_LANG.get(siteId)+':{'+(String.isBlank(brand)?'':EncodingUtil.urlEncode(brand, 'UTF-8'))+'}', 
                'category_ids='+catId,
                'limit='+search_limit,
                'offset='+requestOffset,
                'fieldgroups=ASPECT_REFINEMENTS,CATEGORY_REFINEMENTS,EXTENDED'

            };

            mapHeader.put('X-EBAY-C-MARKETPLACE-ID', MAP_EBAY_SITE.containsKey(siteId)? MAP_EBAY_SITE.get(siteId):'');
            Ebay_SSO_Provider__mdt cred =  Ebay_SSO_Provider__mdt.getInstance('ebay_sep');
            endPoint = cred.Base_Server__c +'/buy/browse/v1/item_summary/search?'+String.join(listParam,'&');
            
        }
      
        public Object getRefinement()
        {
            return mapResponse.get('refinement');
        }
        public Integer getTotal()
        {
            return (Integer)mapResponse.get('total');
        }
        
        public override List<Object> getListObject()
        { 
            return (List<Object>)mapResponse.get('itemSummaries'); 
        }
        
    }
    
    /*********************************************************************************************************************************
    @ class:   GetItemService
    @ Version:       2.0
    @ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:       US-0010734 - [SP - EU Deals] [Bug] Upgrade the API to get all the products under the Brand filter. Fix issue with Brand filter on Item Picker
    @                 new search api - to  fix the issue when filter brand (missing item)
    @                 https://developer.ebay.com/api-docs/buy/browse/resources/item_summary/methods/search
    @----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 01.12.2021 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / created class
    *********************************************************************************************************************************/
    public class GetItemService extends BaseService{       

        private String itemId;
        
        //v1 format: v1|393488034877|662291214436
        public GetItemService(String siteId,String itemIdv1)
        {
            super('GET');

            this.itemId = itemIdv1;
            mapHeader.put('X-EBAY-C-MARKETPLACE-ID', MAP_EBAY_SITE.containsKey(siteId)? MAP_EBAY_SITE.get(siteId):'');
            mockBody = MOCK_GETITEM;
        }

        protected override void constructEndpoint()
        {
            Ebay_SSO_Provider__mdt cred =  Ebay_SSO_Provider__mdt.getInstance('ebay_sep');              
            //endPoint = cred.Base_Server__c +'/buy/browse/v1/item/get_item_by_legacy_id?legacy_item_id='+itemId;
            endPoint = cred.Base_Server__c +'/buy/browse/v1/item/'+EncodingUtil.urlEncode(itemId,'UTF-8');
        }

        public override List<Object> getListObject()
        {    
            return new List<Object>{mapResponse};   //single item response
        }

        public String getEmail()
        {    
            return (String)ApexUtil.getJSONValue(mapResponse, 'seller.sellerLegalInfo.email');
        }

    }   

    /*********************************************************************************************************************************
    @ class:   GetItemService
    @ Version:       1.0
    @ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:       US-0011082 - Allow Sellers to link Accounts
    @                 getSessionId to pass to Consent Screen
    @                https://signin.sandbox.ebay.com/ws/eBayISAPI.dll?SignIn&runame=MyRUName&SessID=encodedSessionId
    @----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 26.04.2022 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / created class
    *********************************************************************************************************************************/
    public class GetSessionService extends BaseService{  
        String metadataName; //eBay_DE_Login, Sign_in_with_eBay_Logins
        String siteId;
        String xmlRequest = '<?xml version="1.0" encoding="utf-8"?><GetSessionIDRequest xmlns="urn:ebay:apis:eBLBaseComponents"><RuName>{!RuName}</RuName></GetSessionIDRequest>';
        
        public GetSessionService(String siteId,String metadataName)
        {
            super('POST');
            this.metadataName = metadataName;            
            this.siteId = siteId;
            super.useAuthorization = false;

            mockBody = MOCK_GETSESSION;
        }

        protected override void constructEndpoint()
        {
            Ebay_SSO_Provider__mdt cred =  Ebay_SSO_Provider__mdt.getInstance(metadataName);
            payload = xmlRequest.replace('{!RuName}', cred.RuName__c);
            mapHeader = new Map<String,String>();

            mapHeader.put('X-EBAY-API-SITEID', siteId);
            mapHeader.put('X-EBAY-API-APP-NAME', cred.Client_Id__c);
            mapHeader.put('X-EBAY-API-CERT-NAME',cred.Client_Secret__c );
            mapHeader.put('X-EBAY-API-DEV-NAME', cred.Dev_ID__c);
            mapHeader.put('X-EBAY-API-CALL-NAME', 'GetSessionID');
            mapHeader.put('X-EBAY-API-COMPATIBILITY-LEVEL', cred.API_Level__c);

            endPoint = cred.Base_Server__c +'/ws/api.dll';
        }

        //get sessionId
        public override List<Object> getListObject()
        {
            if(isSuccess)
            {
                DOM.Document doc=new DOM.Document();                
                doc.load(mapResponse.get('response')+'');                 
                DOM.XmlNode rootNode = doc.getRootElement();   
                //system.debug('--getNamespace: '+rootNode.getNamespace());
                object val = rootNode.getChildElement('SessionID',rootNode.getNamespace()).getText();

                system.debug('--val: '+val);                            
                return new List<Object>{val}; 
            }
            return null;
        }

    }

    /*********************************************************************************************************************************
    @ class:   GetItemService
    @ Version:       1.0
    @ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:       US-0011082 - Allow Sellers to link Accounts
    @                 confirm the identity by the session id
    @                https://signin.sandbox.ebay.com/ws/eBayISAPI.dll?SignIn&runame=MyRUName&SessID=encodedSessionId
    @----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 26.04.2022 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / created class
    *********************************************************************************************************************************/
    public class IdentityConfirmService extends BaseService{  
        String metadataName; //eBay_DE_Login, Sign_in_with_eBay_Logins
        String siteId;
        String sessionId;
        String xmlRequest = '<?xml version="1.0" encoding="utf-8"?><ConfirmIdentityRequest xmlns="urn:ebay:apis:eBLBaseComponents"><SessionID>{!SessionId}</SessionID></ConfirmIdentityRequest>';
        
        public IdentityConfirmService(String siteId,String metadataName,String sessionId)
        {
            super('POST');
            this.metadataName = metadataName;            
            this.siteId = siteId;
            this.sessionId = sessionId;
            super.useAuthorization = false;

            mockBody = MOCK_IDENTITY;
        }

        protected override void constructEndpoint()
        {
            Ebay_SSO_Provider__mdt cred =  Ebay_SSO_Provider__mdt.getInstance(metadataName);
            payload = xmlRequest.replace('{!SessionId}', sessionId);
            mapHeader = new Map<String,String>();

            mapHeader.put('X-EBAY-API-SITEID', siteId);
            mapHeader.put('X-EBAY-API-APP-NAME', cred.Client_Id__c);
            mapHeader.put('X-EBAY-API-CERT-NAME',cred.Client_Secret__c );
            mapHeader.put('X-EBAY-API-DEV-NAME', cred.Dev_ID__c);
            mapHeader.put('X-EBAY-API-CALL-NAME', 'ConfirmIdentity');
            mapHeader.put('X-EBAY-API-COMPATIBILITY-LEVEL', cred.API_Level__c);

            endPoint = cred.Base_Server__c +'/ws/api.dll';
        }

        //get sessionId
        public override List<Object> getListObject()
        {
            if(isSuccess)
            {
                List<Object> lisResult = new List<Object>();
                DOM.Document doc=new DOM.Document();                
                doc.load(mapResponse.get('response')+'');                 
                DOM.XmlNode rootNode = doc.getRootElement();   
                //system.debug('--getNamespace: '+rootNode.getNamespace());
                String ack = rootNode.getChildElement('Ack',rootNode.getNamespace()).getText();
                lisResult.add(ack);
                if(ack=='Success')
                {
                    String userID = rootNode.getChildElement('UserID',rootNode.getNamespace()).getText();
                    lisResult.add(userID);
                }else
                {
                    lisResult.add(rootNode.getChildElement('Errors',rootNode.getNamespace()));
                }
                                         
                return lisResult; 
            }
            return null;
        }

    }

    private static String MOCK_SEARCH_RESULT2 ='{"href":"--","total":10,"next":"--","limit":1,"offset":0,"itemSummaries":[{"itemId":"v1|392192630100|0","title":"Microsoft Xbox ONE","shortDescription":"Es handelt ","image":{"imageUrl":"--"},"price":{"value":"279.95","currency":"EUR"},"itemHref":"--","seller":{"username":"condrux","feedbackPercentage":"99.2","feedbackScore":91338,"sellerAccountType":"BUSINESS"},"condition":"Gebraucht","conditionId":"3000","thumbnailImages":[{"imageUrl":"--"}],"buyingOptions":["FIXED_PRICE"],"itemWebUrl":"--","itemLocation":{"city":"Dresden","postalCode":"01***","country":"DE"},"categories":[{"categoryId":"139971"},{"categoryId":"1249"}],"adultOnly":false,"qualifiedPrograms":["EBAY_PLUS"],"legacyItemId":"392192630100","availableCoupons":false,"topRatedBuyingExperience":true,"priorityListing":false}],"refinement":{"dominantCategoryId":"139971","categoryDistributions":[{"categoryName":"Konsolen","categoryId":"139971","refinementHref":"--"}],"aspectDistributions":[{"localizedAspectName":"Marke","aspectValueDistributions":[{"localizedAspectValue":"Microsoft","matchCount":8,"refinementHref":"--"},{"localizedAspectValue":"Sony","matchCount":2,"refinementHref":"--"}]}]}}';
    private static String MOCK_SEARCH_RESULT = '{"findItemsAdvancedResponse":[{"ack":["Success"],"version":["1.13.0"],"timestamp":["2021-09-20T13:57:35.096Z"],"searchResult":[{"@count":"1","item":[{"itemId":["284418365260"],"title":["Creative Sound Blaster X3 Super X-Fi Hi-Res 7.1 USB DAC 32bit/192kHz W/T Jap"],"globalId":["EBAY-US"],"primaryCategory":[{"categoryId":["44980"],"categoryName":["Sound Cards (Internal)"]}],"galleryURL":["https://thumbs1.ebaystatic.com/m/mzbZVY9Go8XsH3RXVsyQMDg/140.jpg"],"viewItemURL":["https://www.ebay.com/itm/Creative"],"autoPay":["false"],"postalCode":["*******"],"location":["Japan"],"country":["JP"],"shippingInfo":[{"shippingServiceCost":[{"@currencyId":"USD","__value__":"0.0"}],"shippingType":["Free"],"shipToLocations":["Worldwide"],"expeditedShipping":["false"],"oneDayShippingAvailable":["false"],"handlingTime":["5"]}],"sellingStatus":[{"currentPrice":[{"@currencyId":"USD","__value__":"262.94"}],"convertedCurrentPrice":[{"@currencyId":"USD","__value__":"262.94"}],"sellingState":["Active"],"timeLeft":["P0DT19H39M48S"]}],"listingInfo":[{"bestOfferEnabled":["false"],"buyItNowAvailable":["false"],"startTime":["2021-08-21T15:37:23.000Z"],"endTime":["2021-09-21T09:37:23.000Z"],"listingType":["FixedPrice"],"gift":["false"]}],"returnsAccepted":["true"],"condition":[{"conditionId":["1000"],"conditionDisplayName":["New"]}],"isMultiVariationListing":["false"],"topRatedListing":["false"]}]}],"paginationOutput":[{"pageNumber":["1"],"entriesPerPage":["1"],"totalPages":["4"],"totalEntries":["4"]}],"itemSearchURL":["https://www.ebay.com/sch/58058/"]}]}';
    private static String MOCK_TOKEN_RES = '{"access_token":"v^1.1#i^1#r^0#p^","expires_in": 7200,"token_type": "Application Access Token"}';
    private static String MOCK_GETITEM = '{"itemId":"v1|171575589602|0","sellerItemRevision":"85","title":"TomTom Start 42 M W. ","shortDescription":"So verpassen Sie ","price":{"value":"93.79","currency":"USD","convertedFromValue":"79.99","convertedFromCurrency":"EUR"},"categoryPath":"Auto & Motorrad: Teile","condition":"New other (see details)","conditionId":"1500","conditionDescription":"Versandrückläufer","itemLocation":{"city":"Nienhagen","postalCode":"29***","country":"DE"},"image":{"imageUrl":"https://i.ebayimg.com/images/g/W9YAAOSwlGxZmvmE/s-l1600.jpg"},"seller":{"username":"lcd-plasma-service","feedbackPercentage":"99.3","feedbackScore":73764,"sellerLegalInfo":{"name":"LCD & Plasma Service GmbH","legalContactFirstName":"Andreas","legalContactLastName":"111111","sellerProvidedLegalAddress":{"addressLine1":"Nordfeld","city":"Nienhagen","postalCode":"11111","country":"DE","countryName":"Germany"},"phone":"111111111","fax":"05144 / 1111111","imprint":"Vertretungsberechtigter","email":"test@test.de","registrationNumber":"Registergericht: Amtsgericht Lüneburg ","vatDetails":[{"vatId":"267984430","issuingCountry":"DE"},{"vatId":"89844758896","issuingCountry":"FR"},{"vatId":"00259089993","issuingCountry":"IT"}]}}},"localizedAspects":[{"type":"STRING","name":"Herstellernummer","value":"1AA4.002.01"}],"topRatedBuyingExperience":false,"buyingOptions":["FIXED_PRICE"],"itemWebUrl":"https://www.ebay.com/itm/171575589602","description":"test","enabledForGuestCheckout":true,"eligibleForInlineCheckout":false,"lotSize":0,"legacyItemId":"171575589602","adultOnly":false,"categoryId":"184979"}';
    private static String MOCK_GETSESSION = '<?xml version="1.0" encoding="UTF-8"?><GetSessionIDResponse xmlns="urn:ebay:apis:eBLBaseComponents"><Timestamp>2022-04-26T05:30:06.951Z</Timestamp><Ack>Success</Ack><Version>1207</Version><Build>E1207_CORE_APISIGNIN_19151597_R1</Build><SessionID>r2oGAA**64592ae51800a77f9f7641fdffffed8e</SessionID></GetSessionIDResponse>';
    private static String MOCK_IDENTITY = '<?xml version="1.0" encoding="UTF-8"?><ConfirmIdentityResponse xmlns="urn:ebay:apis:eBLBaseComponents"><Timestamp>2022-04-26T12:04:33.985Z</Timestamp><Ack>Success</Ack><Version>1201</Version><Build>E1201_CORE_API6_19110890_R1</Build><EIASToken>nY+sHZ2PrBmdj6wVnY+sEZ2PrA2dj6AEkYWjD5SLoQWdj6x9nY+seQ==</EIASToken><UserID>test_seller007</UserID></ConfirmIdentityResponse>';
}