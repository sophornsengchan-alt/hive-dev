/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class HTTPWrapperTest {

    static testMethod void testHttp() {
         //******************************************** **************************************************//
    /*public class TestDARTRequest implements IRequest{
        Map<String,String> mapHeader;
        public TestDARTRequest()
        {
            mapHeader = new Map<String,String>();
            mapHeader.put('Cookie','');
            mapHeader.put('Content-type','text/xml');
            mapHeader.put('Accept-Encoding','gzip, deflate');
            mapHeader.put('User-Agent','API_VERSION_DARTAPI_13.6.9 JRE_1.6.0_25');
            
            //Blob headerValue = Blob.valueOf('nakb_angkor@yahoo.com:dart123456');
            //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            String authsss = Tester.composeDigestAuthorizationHeader('cambodia_DE-API','dartebaytest2012','/xmlserver/','POST');
            //System.debug('>>>>>>>> AUTHORIZATION ' + authorizationHeader);
     
            mapHeader.put('Authorization',authsss);
       
        }
        
        public Map<String,String> getHeader()
        {
            return mapHeader;
            
        }
        
        public String getBody()
        {
            return 
            '<dart:request-template select="xmlserver/session/UserInfo.xml" method="get" xmlns:dart="http://www.doubleclick.net">'+
                '<dart:parameters>'+
                    '<UpdateLastLoginDate>true</UpdateLastLoginDate>'+
                '</dart:parameters>'+
            '</dart:request-template>';

        }
        
        public String getEndPoint()
        {
            return 'http://dfpapitest.doubleclick.net/xmlserver/';
        }
        
        public String getMethod()
        {
            return 'POST';
        }
    }
    
    public class TestDARTResponse extends AbstractResponse{
        
        public TestDARTResponse(IRequest req)
        {
            super(req); 
            excecute();
        }
        public override String getMockedBody()
        {
            return '';
        }
    }
    
    */
    
    
     	HTTPWrapper.IRequest req1 = new HTTPWrapper.SimpleRequest('http://test.com','GET','testbody');
        HTTPWrapper.SimpleResponse resp1 = new HTTPWrapper.SimpleResponse(req1);
        System.debug('>>>>>>>>>>Resbody: '+resp1.getResBody());
        req1.getInvokedMethod();
        
        req1 = new HTTPWrapper.SimpleRequest('http://test2.com','GET','testbody2',new Map<String,String>{'k'=>'v'});
        resp1 = new HTTPWrapper.SimpleResponse(req1);
        
        
        HTTPWrapper httwrp = new HTTPWrapper();
        Http http = HTTPWrapper.M_HTTP;
        Integer i = HTTPWrapper.HTTP_RETRY;
         
    }
}