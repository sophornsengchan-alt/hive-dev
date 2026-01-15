/** All exceptions go here
  14.09.2023 /vadhanak voun / US-0013942 - PART 4 - Upgrade API version of all classes having an API version lower than 31
**/
public with sharing class ExceptionGroup {
    
    public ExceptionGroup(){}
    
    /**
     HTTP Exception
    */
    public  with sharing class HTTPException extends Exception{
        
    }
    
    /**
     Parser Exception
    */
    public  with sharing class ParserException extends Exception{
        
    }
    
    /** DART EXCEPTION */
    public class DARTException extends Exception{
        
    }
    
    /** Digest EXCEPTION */
    public class DigestException extends Exception{
        
    }
    /** FetchToken EXCEPTION (DART6?!)*/
    public class FetchTokenException extends Exception{
        
        
    }
    
    /** AvailForecast EXCEPTION (DART6?!)*/
    public class AvailForecastException extends Exception{
        
        
    }
    
    /** Keyvalue EXCEPTION (DART6?!)*/
    public class DARTKeyValueException extends Exception{
        
        
    }
    
    public class CustomException extends Exception{}

    
}