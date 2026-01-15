/** 
 * Connector for new DFP
 * Connect to invoke the process & parse DFP response object to apex dart object
 * @				: 11.09.2023 /vadhanak voun/ US-0013940 - PART 2 - Upgrade API version of all classes having an API version lower than 31
 */
public without sharing class DART6Connector implements DARTObject.IDARTConnector{
     
    protected HTTPWrapper.IGenericRequest request;
    protected DART6Parser.IDartParser parser; 
    
    /**
     * Constructor
     * @param request
     * @param parser
     */ 
    public DART6Connector(HTTPWrapper.IGenericRequest request,DART6Parser.IDartParser parser)
    {
        this.request =  request;
        this.parser = parser;
    }
    
    /**
     * request to DFP & parse responsed DFP object to Apex dart object
     */
    public void connect()
    { 
        HTTPWrapper.IInvoker invoker = (HTTPWrapper.IInvoker)request;
        invoker.invoke();   
         
 
        ((DART6Parser.IDART6Parser)parser).setObjectDFP(invoker.getResponseObject()); 
        parser.parse();  
    } 
      
    /**
     * @return dart generice object
     */
    public List<DARTObject.IDARTGenericObject> getDartObjects()
    {
        return parser.getListDartObject();
    }  
    
    
}