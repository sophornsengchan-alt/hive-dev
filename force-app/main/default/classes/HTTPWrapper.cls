/*********************************************************************************************************************************
@ Class:         HTTPWrapper
@ Version:       1.0
@ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       Wrapp all http into one place
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 24.02.2020 / Vadhanak Voun / Created the class.
                10.06.2020 / Acmatac SEING / Merge the HTTWrapper from NA Project (HTTPWrapper).
*********************************************************************************************************************************/
public without sharing class HTTPWrapper {
    public HTTPWrapper() {String s;}
    
    public virtual Interface IGenericRequest{
        String getInvokedMethod(); //what dart method has been invoked?
           
    }
    /** For new DFP invoker - apex classes from WSDL */
    public Interface IInvoker extends IGenericRequest{
        void invoke();
        Object getResponseObject();  
    } 
    /** for old API need raw xml body requests*/
    public Interface IRequest extends IGenericRequest{
        Map<String,String> getHeader();
        String getBody();
        String getEndPoint();
        String getMethod();
    }
    //to keep it live
    @TestVisible
    static final Http M_HTTP = new Http();
    /**
        Parent class for all responses
    */
    public without sharing abstract class AbstractResponse {
        private HttpResponse res;
        protected IRequest request;
        public String status = Test.isRunningTest()?'OK':'';
        public Integer statusCode = Test.isRunningTest()?200:0;
        public String mockBody = '';

        public AbstractResponse (IRequest request){
            this.request = request;
        }
        public abstract String getMockedBody();
        //void setRespone(HttpResponse res){} 
        //void setKeyElements(Set<String> keys){}
         
        HttpHandler handler;
        
        protected void excecute(){
            //if(!Test.isRunningTest()){
                handler = new HttpHandler(request);
                res = handler.sendRequest();
                if(res!=null) {
                    status=res.getStatus(); statusCode = res.getStatusCode();
                }
            //}
            
        }
         
        public String getResBody(){
            if(!Test.isRunningTest()){
                if(res==null) return '';
                return res.getBody();
            } 
            status='OK'; return getMockedBody();
        }
       
    }
    
    @TestVisible
    final static Integer HTTP_RETRY = 3;
    /**
    HttpHandler 
    **/
    public with sharing  class HttpHandler {
          
        String method;
        HttpRequest req;
        public HttpHandler(IRequest request){
            req = new HttpRequest();    
            req.setTimeout(120000); //12 sec

            if(request.getBody()!=null && request.getBody()!='') {
                req.setBody(request.getBody());
            } 
            if(request.getEndPoint()==null){
                //System.debug('>>>>>>>>>>>>>>> HttpHandler ERROR: Error: No Endpoint Specified!!');
                throw new ExceptionGroup.HTTPException('Error: No Endpoint Specified!!');
            }
            req.setEndpoint(request.getEndPoint());
            req.setMethod(request.getMethod());  
              
            //System.debug('>>>>>>>>>>>>>>> Request Body:'+request.getBody());
            for(String key: request.getHeader().keySet()){
                req.setHeader(key,request.getHeader().get(key));
            }
        }
        public void setMethod(String s){
            method = s;  
        }
        //NK:22/10/2013: timeout handler 
        Integer numTry = 0;
        public Httpresponse sendRequest(){      
            HttpResponse response = null;
            
            try{
                 if(!Test.isRunningTest()){
                     response = M_HTTP.send(req);
                 }

            }catch(CalloutException ex){
                //System.debug('=================='+response);
                //Logger.logError(c,Constants.CALL_OUT_ERROR);              
                if(ex.getMessage().contains('Read timed out') && numTry < HTTP_RETRY)
                 {
                     numTry++; return sendRequest();
                 }      
                throw new ExceptionGroup.HTTPException('Can not callout: due to error: '+ex +'\nRetried '+numTry);                
            }
            return response;
        }
       
    }
    
    public with sharing abstract class AbstractRequest implements HTTPWrapper.IRequest{
        protected String body='';
        protected String endPoint;
        protected String method='GET';
        protected Map<String,String> mapHeader; 

        public virtual String  getInvokedMethod()
        {
            return 'SimpleRequest';
        }
        public virtual Map<String,String> getHeader()
        {
            return mapHeader;            
        }       
        public virtual String getBody()
        {
            return body;
        }

        public String getEndPoint()
        {
            return endPoint; 
        }        
        public String getMethod()
        {
            return method; 
        }

    }
    
    /** For simple http request - for general - no specific call */ 
    public class SimpleRequest  extends AbstractRequest {
        
        public SimpleRequest(String myEndPoint,String myMethod,String myBody)
        {
            endPoint =  myEndPoint;
            method = myMethod;
            body = myBody;
            mapHeader = new Map<String,String>();
        }
        
        /* need header?*/
        public SimpleRequest(String myEndPoint,String myMethod,String myBody,Map<String,String> myHeader)
        {
            this(myEndPoint,myMethod,myBody);
            mapHeader = myHeader;
        }
  
    }

    public class SimpleResponse extends HTTPWrapper.AbstractResponse{
        
        public SimpleResponse(IRequest req)
        {
            super(req); 
            excecute();
        }
        public override String getMockedBody()
        {
            return mockBody;
        }
        
    }
    
    class HttpException extends Exception{
    
    }
}