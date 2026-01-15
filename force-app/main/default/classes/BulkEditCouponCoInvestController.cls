/*********************************************************************************************************************************
@ Class:          BulkEditCouponCoInvestController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Controller Class for BulkEditCouponCoInvest.cmp
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  07.09.2020 / Sophal Noch / Created the class.
@               :   13.06.2023 / Acmatac Seing / US-0013714 - Checking Custom Permission Set instead of Permission Set
@               :  11.07.2024 / SRONG TIN / US-0015086 - Coupon Manager for bulk edit functions
*********************************************************************************************************************************/
public without sharing class BulkEditCouponCoInvestController {

    private static final String COINVEST_FIELD_NAME = 'Co_Invest__c';
    //Start:11.07.2024 / SRONG TIN / US-0015086 
    public List<Coupon_Seller__c> selectedCouponSeller {get;set;}
    public List<Id> lstSelCSid {get{return lstSelCSid = (lstSelCSid !=null ? lstSelCSid : new List<Id>());} set;}
    public String reUrl{get;set;}
    public String recordId {get;set;}
    public BulkEditCouponCoInvestController(ApexPages.StandardSetController controller) {
        reUrl = controller.cancel().getUrl();
        recordId = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('id')+'');
		selectedCouponSeller = (List<Coupon_Seller__c>)controller.getSelected();
        for (Coupon_Seller__c cs : selectedCouponSeller) {
            lstSelCSid.add(cs.Id);
        }
    }
    
    public pageReference cancelAction() {
        String url = '/lightning/r/Coupon__c/'+recordId + '/related/Coupon_Sellers__r/view';
        PageReference pg = new PageReference(url);
        pg.setRedirect(true);
        return pg;
    }
    //End:US-0015086
    
    /*****************************************************************************************************************************
    @ Method:       apexInit
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0007710
    @               Summary
    @               As a...
    @               GCX Standard User when I go to coupon seller record (either category based or item based)
    @               Want to...
    @               to see a custom button on Top right corner. Clicking that button will open a window
    @               So that...
    @               I can mass edit the shares for all related co-invest records
    @               Description
    @               Summary: Re-use functionality of mass editing on Actions (screenshots attached in Files)
    @               As a Standard Profile User
    @               When I am on the Coupon Seller record (either Category Based or Item Based)
    @               I would like to be able to bulk edit the shares for the related 'coinvest records' on one screen, instead of having to navigate to the related list view.
    @               AC 1) Create a custom button on Top right corner to edit the shares for all related co-invest records
    @               Object: Coupon_Seller__c
    @               Record type: Manhattan coupon
    @               Where: pressing on "Update Co-invests Share" button on Coupon_Seller__c record , a window opens click "mass edit".
    @               AC 2) Add mass edit feature on right side of view to edit the shares for all related co-invest records
    @               Field label: Seller Share %
    @               API Name: Co_Invest__c
    @               Object: Coupon_Co_Invest__c
    @ Event:		after BulkEditCouponCoInvest.cmp init
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.09.2020 / Sophal Noch / Created the method.
    @               : 13.06.2023 / Acmatac Seing / US-0013714 - Checking Custom Permission Set instead of Permission Set
    @*****************************************************************************************************************************/
    @AuraEnabled
	public static Map<String,Object> apexInit(){

        Map<String,Object> mapResult = new Map<String,Object>();

        // 13.06.2023 / Acmatac Seing / US-0013714 - Checking Custom Permission Set instead of Permission Set
        // Boolean hasPromotionsUserPermission = ApexUtil.checkPermissionSet(new Set<String>{EBH_ConstantsUtility.PERMISSION_SET_PROMO});
        Boolean hasPromotionsUserPermission = FeatureManagement.checkPermission(ApexUtil.COUPON_BULK_EDITS_CUSTOM_PERMISSION);
        Boolean isAdmin = Userinfo.getprofileId() == EBH_ConstantsUtility.ADMIN_PROFILE_ID;

        if(!hasPromotionsUserPermission && !isAdmin){
            mapResult.put('status','ko'); mapResult.put('error',System.Label.ErrorNoPermissionToBulkEditCofundingShares); return mapResult;
        }

        String coInvestQuery = 'SELECT ';

        Map<String,String> mapFixLabel = new Map<String,String>{'Seller_Name__r.Name'=>'Seller Name'};

        List<ColName> listColNameCoInvest = new List<ColName>();

        for(Schema.FieldSetMember f: SObjectType.Coupon_Co_Invest__c.FieldSets.BulkEditCouponCoInvest.getFields())
        {
            coInvestQuery += f.getFieldPath() + ', ';
  
            String filedLabel = mapFixLabel.containsKey(f.getFieldPath())? mapFixLabel.get(f.getFieldPath()): f.getLabel();

            listColNameCoInvest.add(
                new ColName(filedLabel,
                f.getFieldPath(),
                f.getType()+'')
            );

        }
            
        coInvestQuery += 'Id FROM Coupon_Co_Invest__c ';

        mapResult.put('listColNameCoInvest',listColNameCoInvest);

        // US-0007710 baseSoqlCoInvest will be used in RecordNavigator.cmp
        mapResult.put('baseSoqlCoInvest',coInvestQuery);

        mapResult.put('status','ok');

        return mapResult;

    }

    /*****************************************************************************************************************************
    @ Method:       apexSave
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0007710
    @               update list Coupon_Co_Invest__c records that have been modified in js controller.
    @ Event:		after BulkSendCouponContract.cmp load
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	list Coupon_Co_Invest__c records 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  07.09.2020 / Sophal Noch / Created the method.
    @*****************************************************************************************************************************/
    @AuraEnabled
	public static Map<String,Object> apexSave(List<Coupon_Co_Invest__c> listCoInvestToUpdate) {

        Map<String,Object> mapResult = new Map<String,Object>();

        try {

            if(!listCoInvestToUpdate.isEmpty()){
                update listCoInvestToUpdate;
            }
            
            mapResult.put('status','ok');

        }catch(DMLException dex)
    	{	mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
    	}catch(Exception ex)
    	{   mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());	}

        return mapResult;

    }



    static Map<String,String> mapLinkField = new Map<String,String>{'Name'=>'Name','Seller_Name__r.Name'=>'SellerId',COINVEST_FIELD_NAME=>'CoInvest'};


    class ColName{
    	@AuraEnabled
    	public String label;
    	
    	@AuraEnabled
    	public String fieldName;
      
        @AuraEnabled
    	public String type;
    	
        @AuraEnabled
        public Boolean sortable = true;
        
        
    	
    	
    	@AuraEnabled
    	public Map<String,Object> typeAttributes;
    	
    	public ColName(String label,String fieldName,String type)
    	{
            
    		this.label = label;
    		this.fieldName = fieldName;
    		this.type = type.toLowerCase();

    		if(fieldName == COINVEST_FIELD_NAME){

                this.fieldName = mapLinkField.get(fieldName);
                typeAttributes = new Map<String,Object>{
    				'minimumFractionDigits' => 2
    			};

            }else if(mapLinkField.containsKey(fieldName)){
    			typeAttributes = new Map<String,Object>{
    				'label' => new Map<String,Object>{'fieldName'=>mapLinkField.get(fieldName)},
    				'target'=>'_blank',
    				'tooltip'=>''
    			};
    			this.fieldName = 'link_'+mapLinkField.get(fieldName);
    			this.type = 'url';
    		} 
    	}
    }
}