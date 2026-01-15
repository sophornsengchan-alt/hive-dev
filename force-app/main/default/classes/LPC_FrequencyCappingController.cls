/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description: 
 *	- FrequencyCapping Targeting
 * @references: 
 *	- LPC_FrequencyCapping lightning component
 * @changeLog:
 *
 */
public without sharing class LPC_FrequencyCappingController {
	
    static Map<String,Schema.SobjectType> mGlobal = Schema.getGlobalDescribe();
    
    /**
     * Availables PicklistValues for selection
     * @param sobjName, sobject name
     * @param fieldName, sobject field name
     * @return List<String>
     */
    @AuraEnabled
    public static List<String> getPicklistValues(String sobjName, String fieldName) {
    	
		List<String>lstOptions = new List<String>{'None'};
		if(!mGlobal.containsKey(sobjName)) return lstOptions;
		 
  		Schema.DescribeSObjectResult sobjectDescribe = mGlobal.get(sobjName).getDescribe();
  		Map<String, Schema.SObjectField> mField = sobjectDescribe.fields.getMap(); 
  		
  		if(!mField.containsKey(fieldName)) return lstOptions;
  		
  		List<Schema.PicklistEntry> picklistValues = mField.get(fieldName).getDescribe().getPickListValues(); 
  		for (Schema.PicklistEntry picklistEntry : picklistValues) {
  			lstOptions.add(picklistEntry.getValue());
  		}
  		return lstOptions; 
	}
    
    /**
     * Get List TargetingFrequencyAssociation__c
     * @param lineItemId, QuoteLineItem Id
     * @return List<TargetingFrequencyAssociation__c>
     */
    @AuraEnabled
    public static RemoteResponse getListTarFreAssociate(String lineItemId){
                
        QuoteLineItem quoteLine = [Select Product2.Name, Targeting__c, FC_Quantity__c, FC_Period__c, FC_Ad_served_every__c,  Product2.FC__c  
        								From QuoteLineItem Where Id =: lineItemId];
        								
        String targetId = quoteLine.Targeting__c;
        
        List<TargetingFrequencyAssociation__c> lstFreTar = getTargetingFrequencyAssociation(targetId);
        
        RemoteResponse response = new RemoteResponse();
        response.content = new Map<String, Object>{
            'tarFreAssociateList' => lstFreTar,
            'isEditable' => quoteLine.Product2.FC__c,
            'predefinedObject' => quoteLine
        };
        response.statusCode = RemoteResponse.STATUSCODE_OK;
        return response;
        
    }
    
    /**
     * Get List TargetingFrequencyAssociation__c
     * @param lineItemId, QuoteLineItem Id
     * @return List<TargetingFrequencyAssociation__c>
     */    
    @AuraEnabled
    public static RemoteResponse getListTarFreAssociateTemplate(String targetId){

        Targeting__c target = [Select Check_Inventory__c From Targeting__c Where Id =: targetId];
        List<TargetingFrequencyAssociation__c> lstFreTar = getTargetingFrequencyAssociation(targetId);

        RemoteResponse response = new RemoteResponse();
        response.content = new Map<String, Object>{
            'tarFreAssociateList' => lstFreTar,
            'predefinedObject' => new QuoteLineItem()
        };
        response.statusCode = RemoteResponse.STATUSCODE_OK;
        return response;
    }
	
	/**
     * Get TargetingFrequencyAssociation__c List for Targeting__c
     * @param targetId, Targeting__c Id
     * @return List<TargetingFrequencyAssociation__c>
     */
    public static List<TargetingFrequencyAssociation__c> getTargetingFrequencyAssociation(String targetId){
		
        List<TargetingFrequencyAssociation__c>lstTarFre = [Select FC_Check_Inventory__c, FC_Ad_served_every__c, FC_Period__c, FC_Quantity__c, Targeting__c From TargetingFrequencyAssociation__c 
                Where Targeting__c = :targetId];
        if(lstTarFre.isEmpty()) lstTarFre.add(new TargetingFrequencyAssociation__c(Targeting__c = targetId, FC_Period__c='None'));
        return lstTarFre;
    }
    
    /**
     * Save FrequencyCapping 
     * @param lineItemId, QuoteLineItem Id
     * @param lstTarFre, List<TargetingFrequencyAssociation__c> to save
     * @return List<TargetingFrequencyAssociation__c>
     */
    @AuraEnabled
    public static RemoteResponse saveFrequencyCapping(String lineItemId, List<TargetingFrequencyAssociation__c>lstTarFre){
        try{
            
            QuoteLineItem quoteLine = [Select Product2.Name, Targeting__c, Product2Id, Check_Inventory__c, quote.IO__c From QuoteLineItem Where Id =: lineItemId];
            String targetId = quoteLine.Targeting__c;
            system.debug('xxxxxxxxxsaveFrequencyCapping:'+targetId);
            if (quoteLine.Targeting__c == null) {
                Targeting__c tg = new Targeting__c(Description__c = quoteLine.Product2.Name + ' Targeting');
                insert tg;
                targetId = tg.Id;
                quoteLine.Targeting__c =  tg.Id;
            }
            
            List<TargetingFrequencyAssociation__c> newListTargetFre = saveFrequencyCappingTargeting(targetId, lstTarFre);
                        
            RemoteResponse response = new RemoteResponse();
            response.content = new Map<String, Object>{
                'lstTarFre' => newListTargetFre
            };
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
        }
        catch(Exception e){
            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }
    
    /**
     * Save FrequencyCappingTemplate 
     * @param targetId, Targeting__c Id
     * @param lstTarFre, List<TargetingFrequencyAssociation__c> to save
     * @return List<TargetingFrequencyAssociation__c>
     */
    @AuraEnabled
    public static RemoteResponse saveFrequencyCappingTemplate(String targetId, List<TargetingFrequencyAssociation__c>lstTarFre){
        try{

            List<TargetingFrequencyAssociation__c> newListTargetFre = saveFrequencyCappingTargeting(targetId, lstTarFre);
            
            RemoteResponse response = new RemoteResponse();
            response.content = new Map<String, Object>{
                'lstTarFre' => newListTargetFre
            };
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
        }
        catch(Exception e){
            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
        
    }
	
	/**
     * Save FrequencyCapping Targeting 
     * @param targetId, Targeting__c Id
     * @param lstTarFre, List<TargetingFrequencyAssociation__c> to save
     * @return List<TargetingFrequencyAssociation__c>
     */
    private static List<TargetingFrequencyAssociation__c> saveFrequencyCappingTargeting(String targetId, List<TargetingFrequencyAssociation__c>lstTarFre){
        
        List<TargetingFrequencyAssociation__c>lstExistTarFre = [Select Id From TargetingFrequencyAssociation__c Where Targeting__c=:targetId];
        if(!lstExistTarFre.isEmpty()) delete lstExistTarFre;
        List<TargetingFrequencyAssociation__c> lstTobeSaved  = new List<TargetingFrequencyAssociation__c>();
        for(TargetingFrequencyAssociation__c tf : lstTarFre){
            TargetingFrequencyAssociation__c tarfre = new TargetingFrequencyAssociation__c();
            tarfre.Targeting__c = targetId;
            tarfre.FC_Ad_served_every__c = tf.FC_Ad_served_every__c;
            tarfre.FC_Quantity__c = tf.FC_Quantity__c;
            tarfre.FC_Check_Inventory__c = tf.FC_Check_Inventory__c;
            tarfre.FC_Period__c = tf.FC_Period__c == 'None' ? '' : tf.FC_Period__c;
            if(tarfre.FC_Ad_served_every__c != null || tarfre.FC_Period__c != '' || tarfre.FC_Quantity__c != null){
                lstTobeSaved.add(tarfre);
            }
        }
        
        insert lstTobeSaved;

        return lstTarFre;
    }
}