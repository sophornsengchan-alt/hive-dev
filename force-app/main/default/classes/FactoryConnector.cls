/**
 * Factory of Connector</br>
 * for Switching from DART to DFP
  14.09.2023 /vadhanak voun / US-0013942 - PART 4 - Upgrade API version of all classes having an API version lower than 31
*/
public without sharing class FactoryConnector {

    private static FactoryConnector instance;
    private FactoryConnector(){}
    
    public static FactoryConnector getInstance()
    {
        if(instance==null)
        {
            instance = new FactoryConnector();
        }
         
        return instance;
    } 
        
    public DARTObject.IDARTConnector createConnector(String dartVersion,HTTPWrapper.IGenericRequest request,DART6Parser.IDartParser parser)
    {   
        if(DARTUtil.DART6.equals(dartVersion)) // new version
        {   
            return new DART6Connector(request,parser);
        } 
         
        return null; 
        
        //if new -> DFP here:
        //return new DFPConnector(request,parser);
    }
}