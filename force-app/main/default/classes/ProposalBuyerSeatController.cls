/*********************************************************************************************************************************
@ Class:          ProposalBuyerSeatController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Class for handle response and request of Buyer Seat in GAM
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  17.12.2021 / Sophal Noch / Create Class. US-0009971 - Buyer Seat on PG Opportunities 
*********************************************************************************************************************************/
public with sharing class ProposalBuyerSeatController {
    private static final String FTYPE_TXT = 'text';
    private static final String FTYPE_BOOLEAN = 'boolean';
    private static final String BUYER_PQL = 'select BuyerAccountId, Name, EnabledForProgrammaticGuaranteed from Programmatic_Buyer';
    private final static String BUTTON_NAME = 'Select_Buyer_Seat';
    private final static String STR_AUTHORIZATION = 'Authorization';
    private final static String STR_BEARER = 'Bearer';
    private final static String APP_NAME = 'PublisherQueryLanguageService';

    /*********************************************************************************************************************************
    @ Method:         apexInit
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        check permission and get all available site from AdServer_Login__c
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  17.12.2021 / Sophal Noch / Create method. US-0009971 - Buyer Seat on PG Opportunities 
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexInit()
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        try {

          Id profileId = Userinfo.getprofileId();
          if(profileId != ApexUtil.ADMIN_PROFILE_ID && !Util.hasPermission(BUTTON_NAME)){mapResult.put('status','ko');mapResult.put('error',label.Error_No_Permission_To_Select_Buyer_Seat);return mapResult;}
          mapResult.put('listSite',[SELECT Name FROM AdServer_Login__c WHERE Active__c=true AND isDeleted=false]);
          mapResult.put('status','ok');
          
        }catch(DMLException dex){mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());}
        catch(Exception ex){mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());}

        return mapResult;
    }

    /*********************************************************************************************************************************
    @ Method:         getBuyers
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        Request to get buyers from GAM
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  17.12.2021 / Sophal Noch / Create method. US-0009971 - Buyer Seat on PG Opportunities 
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> getBuyers(String siteName, String whereCondition){
      Map<String,Object> mapResult = new Map<String,Object>();

      try {

        AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6, siteName);
        
        String authToken = DARTUtil.getAccessToken(login);
        Map<String, String> inputHttpHeaders_x = new Map<String, String> ();
        inputHttpHeaders_x.put(STR_AUTHORIZATION, STR_BEARER + ' ' + authToken);

        Dart6_PublisherQueryLanguageService.SoapRequestHeader header = new Dart6_PublisherQueryLanguageService.SoapRequestHeader();
        header.applicationName = APP_NAME;
        header.networkCode = login.Network_ID__c;

        Dart6_PublisherQueryLanguageService.PublisherQueryLanguageServiceInterfacePort queryLangService = new Dart6_PublisherQueryLanguageService.PublisherQueryLanguageServiceInterfacePort();
        queryLangService.RequestHeader = header;
        queryLangService.timeout_x = 120000;
        queryLangService.inputHttpHeaders_x = inputHttpHeaders_x;

        Dart6_PublisherQueryLanguageService.Statement filterItem = new Dart6_PublisherQueryLanguageService.Statement();
        filterItem.query = BUYER_PQL + (String.isNotBlank(whereCondition) ? whereCondition : '');

        Dart6_PublisherQueryLanguageService.ResultSet result =  queryLangService.select_x(filterItem);
        // pql = 'select BuyerAccountId, Name, EnabledForProgrammaticGuaranteed from Programmatic_Buyer';
        // columns in return result, first column = BuyerAccountId, second column = EnabledForProgrammaticGuaranteed, third column = EnabledForProgrammaticGuaranteed

        ColName buyerIdCol = new ColName(result.columnTypes[0].labelName,result.columnTypes[0].labelName ,FTYPE_TXT);
        ColName nameCol = new ColName(result.columnTypes[1].labelName,result.columnTypes[1].labelName, FTYPE_TXT);
        ColName isProgramic = new ColName(result.columnTypes[2].labelName,result.columnTypes[2].labelName, FTYPE_BOOLEAN);
        
        List<ColName> listCols = new List<ColName>{buyerIdCol,nameCol,isProgramic};

        List<ProgrammaticBuyer> listBuyers = new List<ProgrammaticBuyer>();
        if(result.rows != null && !result.rows.isEmpty()){
          for(Integer i = 0; i < result.rows.size(); i++){
            // each row represents each buyer, and each row has field values.
            // first index = BuyerAccountId value, second index = EnabledForProgrammaticGuaranteed value, third index = EnabledForProgrammaticGuaranteed value
            Dart6_PublisherQueryLanguageService.Row row = result.rows[i];
            ProgrammaticBuyer buyer = new ProgrammaticBuyer(row.values[0].value, row.values[1].value, Boolean.valueOf(row.values[2].value));
            listBuyers.add(buyer);
          }
        }

        mapResult.put('listCols',listCols);
        mapResult.put('listBuyers',listBuyers);
        mapResult.put('status','ok');

    }catch(DMLException dex){mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());}
    catch(Exception ex){mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());}

      return mapResult;
    }

  /*********************************************************************************************************************************
    @ Method:         apexSave
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        check save buyeraccount id to opp
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  17.12.2021 / Sophal Noch / Create method. US-0009971 - Buyer Seat on PG Opportunities 
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexSave(String oppId, String buyerId)
    {
      Map<String,Object> mapResult = new Map<String,Object>();
      try { 
        Opportunity opp = new Opportunity(Id=oppId, Buyer_Seat__c = buyerId);
        update opp;
        mapResult.put('status','ok');
      }catch(DMLException dex){mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());}
      catch(Exception ex){mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());}
      return mapResult;
    }

    class ColName{
    	@AuraEnabled
    	public String label;
    	
    	@AuraEnabled
    	public String fieldName;
      
      @AuraEnabled
    	public String type;

    	public ColName(String label,String fieldName,String type)
    	{
    		this.label = label;
    		this.fieldName = fieldName;
    		this.type = type.toLowerCase();
    	}
    }

    class ProgrammaticBuyer{
      @AuraEnabled
      public String buyeraccountid;
      @AuraEnabled
      public String name;
      @AuraEnabled
      public Boolean enabledforprogrammaticguaranteed;

      public ProgrammaticBuyer(String buyeraccountid,String name, Boolean enabledforprogrammaticguaranteed){
        this.buyeraccountid = buyeraccountid;
        this.name = name;
        this.enabledforprogrammaticguaranteed = enabledforprogrammaticguaranteed;
      }

    }



}