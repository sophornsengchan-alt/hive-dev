/** Controller responsible to process AvailabilityForecast
    
    Created Date: 22/11/2012
	@				: 11.09.2023 /vadhanak voun/ US-0013940 - PART 2 - Upgrade API version of all classes having an API version lower than 31
*/
public with sharing class ForecastController{

    QuoteLineItem item;
    List<DARTObject.DARTForecast> listForecast;
    
    /** for log */  
    String invokedMethod;
     

    public ForecastController(QuoteLineItem item)
    {    
         this.item = item;   
    }
    
    public void forecastProcess()
    {  
        // request to get Availability Forecast
        
        // Acmatac SEING, 2 March 2022 US-0010618 - ADS - New Product record types and rename existing
        String dartVersion = item.PricebookEntry.Product2.RecordType.DeveloperName;
        
        AdServer_Login__c credential = DARTUtil.getCredential(dartVersion,item.PriceBookEntry.Product2.Site__r.Name); //NK:21/04/2021
        //System.debug('>>>>>>>>>>>>>>.credential:'+credential); 
        //create request DART5/6
        
        HTTPWrapper.IGenericRequest dartForecastRequest = FactoryDARTRequest.getInstance().createDartForecastRequest(credential,item);
        
        //create Parser accordingly

        DART6Parser.IDartParser forecastParser = FactoryParser.getInstance().createForecastParser(dartVersion, item);
       
        //create Connection DART5/6 
        DARTObject.IDARTConnector forecastCon = FactoryConnector.getInstance().createConnector(dartVersion,dartForecastRequest, forecastParser);
        forecastCon.connect();    
        
        invokedMethod = dartForecastRequest.getInvokedMethod();
          
        //get result 
        listForecast = (List<DARTObject.DARTForecast>)forecastCon.getDartObjects();
        system.debug('forecastCon' + listForecast);
 
    }
    
    
    public List<DARTObject.DARTForecast> getObjectForecast() 
    {
        return listForecast;
    } 
    
    public String getInvokedMethod()
    {
        return invokedMethod;
    }
    
}