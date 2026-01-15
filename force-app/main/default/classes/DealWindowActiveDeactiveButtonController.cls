/*********************************************************************************************************************************
@ Class:          DealWindowActiveDeactiveButtonController
@ Version:        1.0
@ Author:         SRONG TIN (srong.tin@gaea-sys.com)
@ Purpose:        Controller Class for DealWindowActiveDeactiveButton.cmp
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 16.07.2021 / SRONG TIN / Created the class.
                : US-0009946 - [SEP] NA Deal Window: Page Layout and New Buttons
*********************************************************************************************************************************/
public class DealWindowActiveDeactiveButtonController {

    private final static String SOQL_DRC = 'SELECT Id,Status__c FROM EBH_DealRetailCampaign__c';
    public final static String STATUS_DRAFT = 'Draft';
    public final static String STATUS_PENDING = 'Pending';


/*****************************************************************************************************************************
    @ Method:       activateDeactivateDRC
    @ Author:       SRONG TIN (srong.tin@gaea-sys.com)
    @ Purpose:      US-0009946 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	id : Deal Retail Campaign Id, 
    @               isActive : Activated Deactivated button,
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 19.07.2021 / SRONG TIN / Created the method.
    @*****************************************************************************************************************************/    
    @AuraEnabled
    public static Map<String,String> activateDeactivateDRC(Id id,Boolean isActive){
        Map<String,String> response = new Map<String,String>();
        try{
            String whereCl = ' where Id =:id ';
            EBH_DealRetailCampaign__c drc = Database.query(SOQL_DRC+whereCl);
            if(isActive && drc.Status__c == STATUS_DRAFT){
                drc.Status__c = STATUS_PENDING;
            }else if(!isActive && drc.Status__c == STATUS_PENDING){
                drc.Status__c = STATUS_DRAFT;
            }else{
                response.put('status','ko'); 
				response.put('message',System.Label.DealRetailCampaign_Status_fail_txt); 
                return response;
            }
            // update Deal Retail Campaign status
            update drc;
			response.put('status','ok'); 
			response.put('message',System.Label.DealRetailCampaign_Status_success_txt); 

        }catch(Exception ex){
            response.put('status','ko');
            response.put('message',ex.getMessage());
            response.put('errorDetail',ex.getStackTraceString());
        }
        
        return response;
    }

}