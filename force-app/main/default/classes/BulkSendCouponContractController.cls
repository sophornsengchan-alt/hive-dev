/*********************************************************************************************************************************
@ Class:          BulkSendCouponContractController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Controller Class for BulkSendCouponContract.cmp
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  27.08.2020 / Sophal Noch / Created the class.
@				:  05.04.2023 / Sophal Noch / US-0013235 - [UK only] Only allow certain users to move coupon seller to contract send
@				:  14.06.2023 / Chetra Sarom / US-0013475 - Deactivate redundant Coupon Approval process & email
@               :  28.07.2023 / Sovantheany Dim / US-0013895 - Remove Approval stage validation on coupon seller before contract send
@				:  04.01.2024 / Veenus Gollapalli/US-0014841 - Improve efficiency of Bulk Coupon Contract Send
@               :  30.04.2024 / Sambath Seng / US-0014373 - Notify users that do not have permissions for Bulk Send Contracts
@               :  11.07.2024 / SRONG TIN / US-0015086 - Coupon Manager for bulk edit functions
@               :  22.07.2024 / Mony Nou / US-0015525 - Exclude 'Reached' Coupon Sellers from Bulk contract send
@               :  23.07.2024 / Mony Nou / US-0015524 - Add coupon seller owner to bulk contract sends
@				:  28.04.2025 / Loumang SENG / US-0016656 - Improve the "Bulk Contract Send" process for Coupon Sellers to process as many eligible records as possible
@               :  15.10.2025 / Davy Sorn / US-0033595 - CA SP - Fix SP UI Contract Display Issues
*********************************************************************************************************************************/
public without sharing class BulkSendCouponContractController {

    // private final static String COUPON_SPECIAL_PERMISSION = 'Coupon_Special_Permission'; // SB 30.04.2024 US-0014373
    private final static String COUPON_BULK_SEND_CONTRACTS_PERMISSION = 'Coupons_Bulk_Send_Contracts'; // SB 30.04.2024 US-0014373
    private final static String COUPON_SITE_AU = 'ebay.com.au'; //14.06.2023 / Chetra Sarom / US-0013475
    //Start:US-0013895
    private final static String COUPON_SITE_DE = 'ebay.de';
    private final static String COUPON_SITE_IT = 'ebay.it';
    private final static String COUPON_SITE_FR = 'ebay.fr';
    private final static String COUPON_SITE_UK = 'ebay.co.uk';
    private final static String COUPON_SITE_CA = 'ebay.ca'; //US-0033595 - CA SP - Fix SP UI Contract Display Issues
    private static Set<String> setAllowMainCouponSite = new Set<String>{COUPON_SITE_DE,COUPON_SITE_IT,COUPON_SITE_FR,COUPON_SITE_UK,COUPON_SITE_AU,COUPON_SITE_CA}; //US-0033595 - CA SP - Fix SP UI Contract Display Issues
    private final static String SOQL_COUPON_SELLER = 'Select Id,Name,Seller__c,Seller__r.Name,SellerShareHolder__c,Email_Adress__c,EBH_CouponSellerOwner__c,EBH_CouponSellerOwner__r.Name,Main_Coupon_Site__c,Coupon_Seller_Stage__c,Legal_Entity_Name_w__c,Legal_Entity_Street_w__c,Legal_Entity_Zip_w__c From Coupon_Seller__c ' ;
    //END:US-0013895
    //Start:11.07.2024 / SRONG TIN / US-0015086  
    public String recordId {get;set;}
    public BulkSendCouponContractController(ApexPages.StandardSetController controller) {
		recordId = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('id')+'');
    }
    //End:US-0015086
    /*****************************************************************************************************************************
    @ Method:       apexInit
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0000792
    @               Summary
    @               ADMIN
    @               AC1 :
    @               Create New Permision Set "Coupon Special Permission"
    @               Create New Button in the "Coupon Seller" Related List -> "Send Bulk Contract" in the Coupon Seller Detail page (Refer the attached PPT Slide 1 for the mock layout where the button needs to be placed)
    @               Create a new Coupon Seller Stage "Approved" in between Stage "Negotiation" and "Contract Send" for Coupon Seller Record.
    @               
    @               AC2: "Send Bulk Contract"(Button Logic)
    @               Prerequisite : Only Users with Permission "Coupon Special Permission" can click this button to send Contracts in Bulk.
    @               Button Logic : Check if user has the Permission "Coupon Special Permission" and if yes ,based on the Coupon type ->Coupon Contract Email to be sent to all Coupon Sellers in bulk whose stage is "Approved".
    @               update the stage to "Contract Send" for all the Coupon Sellers which will trigger bulk email send to all the sellers and once complete display the below success pop up message as shown in Slide 3(Refer attached PPT for UI Mock UI)
    @               
    @               Coupon Contracts successfully sent!
    @               
    @               You check the individual status under Coupon Sellers "View All" or Summary Funnel at the bottom of the Coupon record.
    @               
    @               AC3: Validations for the Button :
    @               When there are no "Coupon Seller" records in "Approved" Stage and the Coupon owner clicks "Send Bulk Contract".
    @               Error Message : There are no "Coupon Sellers" in "Approved" stage. Please move them to "Approved" stage and click "Send Bulk Contract".
    @               2. When any user without the "Coupon Special Permission" permission set clicks "Send Bulk Contract" button
    @               Error Message : You do not have Permission "Coupon Special Permission" to bulk send Coupon Contracts.Please raise a Support ticket to add this Permission.
    @               
    @               Testing AC
    @               General Note - Test the ACs with both "AU Standard user profile" and "Standard user profile" users as well
    @               AC4
    @               As Any user with the "Coupon Special Permission  Contract Bulk Send" permission set
    @               Verify coupon Contracts can be sent in bulk to all Sellers with "Coupon Seller Stage" is "Negotiation Complete  'Approved'.  Verify the "Coupon Seller Stage" is updated to "Contract Send" when the bulk eMail alerts are triggered to Sellers. 
    @               Verify if the Success message is displayed to the Coupon Owner.
    @               
    @               AC5 : Verify the Validation Error Messages are displayed as expected for users who click the "Send Bulk Contract" as mentioned in AC3
    @ Event:		after BulkSendCouponContract.cmp init
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	coupon Id
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  27.08.2020 / Sophal Noch / Created the method.
    @				:  05.04.2023 / Sophal Noch / US-0013235 - [UK only] Only allow certain users to move coupon seller to contract send
    @               :  30.04.2024 / Sambath Seng / US-0014373 - Notify users that do not have permissions for Bulk Send Contracts
    @*****************************************************************************************************************************/
    @AuraEnabled
	public static Map<String,Object> apexInit(String couponId) {
        

        // query coupon sellers by coupon id, to display on table

        Map<String,Object> mapResult = new Map<String,Object>();

        // Boolean hasCouponSpecialPermission = ApexUtil.checkPermissionSet(new Set<String>{COUPON_SPECIAL_PERMISSION}); // SB 30.04.2024 US-0014373
        Boolean hasCouponSpecialPermission = FeatureManagement.checkPermission(COUPON_BULK_SEND_CONTRACTS_PERMISSION); // SB 30.04.2024 US-0014373
        Boolean isAdmin = Userinfo.getprofileId() == EBH_ConstantsUtility.ADMIN_PROFILE_ID;

        if(!hasCouponSpecialPermission && !isAdmin){
            mapResult.put('status','ko');
            mapResult.put('error',System.Label.ErrorNoCouponSpecialPermission);
            return mapResult;
        }


        Set<String> setFieldNameCoSeller = new Set<String>{'id','Main_Coupon_Site__c'}; // 14.06.2023 / Chetra Sarom / US-0013475

        Map<String,String> mapFixLabel = new Map<String,String>{'Seller__r.Name'=>'Seller', 'EBH_CouponSellerOwner__r.Name' => 'Coupon Seller Owner'}; //MN-22072024-US-0015524:Add mapping label for };
        Map<String, String> mapColLabel2FldApi = new Map<String, String>{
            'link_OwnerId' => 'EBH_CouponSellerOwner__r.Name', 
            'link_Name' => 'Name',
            'link_SellerId' => 'Seller__r.Name'
        };

        //START--MN-22072024-US-0015525: Move excluded stages into custom labels
        //List<String> ExcludeCoSellerstage = new List<String>{'Contract Send','Contract Signed','Coupon executed','Seller Declined','T34 Statement Send','Coupon Running', 'Reached'};
        List<String> excludeCoSellerstage = new List<String>();
        excludeCoSellerstage.addAll(System.Label.CouponSellerExcludedStages.split(';'));
        //--END

        List<ColName> listColNameCoSeller = new List<ColName>();

        for(Schema.FieldSetMember f: SObjectType.Coupon_Seller__c.FieldSets.BulkSendCouponContract.getFields())
        {
            setFieldNameCoSeller.add(f.getFieldPath());
            if(f.getFieldPath().contains('.') && f.getFieldPath().endsWith('Name'))
            {
                String fId = ApexUtil.getFieldIdRef(f.getFieldPath());
                setFieldNameCoSeller.add(fId);
            }

            String filedLabel = mapFixLabel.containsKey(f.getFieldPath())? mapFixLabel.get(f.getFieldPath()): f.getLabel();

            listColNameCoSeller.add(
                new ColName(filedLabel,
                f.getFieldPath(),
                f.getType()+'')
            );

        }

        String soqlCoSeller = ' Select '+String.join(new List<String>(setFieldNameCoSeller),',')+' From Coupon_Seller__c Where Coupon__c=:couponId and Coupon_Seller_Stage__c NOT IN :excludeCoSellerstage';
	        
        List<Coupon_Seller__c> listCoSeller = Database.query(soqlCoSeller);

        if(listCoSeller.isEmpty()){
        	mapResult.put('status','ko');
        	mapResult.put('error',System.Label.ErrorNoRelatedCouponSeller);
        }else{
            //MN-23072024-US-0015524--START
            String baseSoqlCoSel = 'Select '+String.join(new List<String>(setFieldNameCoSeller),',')+' From Coupon_Seller__c ';
            String excludeCoSellerstageText = '\'' + String.join(excludeCoSellerstage, '\',\'') + '\'';
            String soqlWhereCoSel = ' Where Coupon__c = \''+ String.escapeSingleQuotes(couponId) +'\' AND Coupon_Seller_Stage__c NOT IN (' + excludeCoSellerstageText + ')';
            mapResult.put('baseSoqlCoSel', baseSoqlCoSel);
            mapResult.put('soqlWhereCoSel', soqlWhereCoSel); 
            mapResult.put('mapColLabel2FldApi', mapColLabel2FldApi);
            //END

            mapResult.put('listColNameCoSeller',listColNameCoSeller);
            mapResult.put('listCoSeller',listCoSeller);
            mapResult.put('status','ok');
        }


        return mapResult;
    
    }


    /*****************************************************************************************************************************
    @ Method:       apexSave
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0000792
    @               updated selected couponSeller records from BulkSendCouponContract.cmp and update status to = 'Contract Sent'
    @ Event:		after BulkSendCouponContract.cmp load
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	list of couponSeller 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  27.08.2020 / Sophal Noch / Created the method.
    @               :  05.04.2023 / Sophal Noch / US-0013235 - [UK only] Only allow certain users to move coupon seller to contract send
    @				:  14.06.2023 / Chetra Sarom / US-0013475 - Deactivate redundant Coupon Approval process & email
    @               :  28.07.2023 / Sovantheany Dim / US-0013895 - Remove Approval stage validation on coupon seller before contract send
    @				:  28.04.2025 / Loumang SENG / US-0016656 - Improve the "Bulk Contract Send" process for Coupon Sellers to process as many eligible records as possible
    @*****************************************************************************************************************************/
    @AuraEnabled
	public static Map<String,Object> apexSave(List<Coupon_Seller__c> listCoSeller) {

        // change coupon sellers which have status = 'Approved' to 'Contract Sent'

        Map<String,Object> mapResult = new Map<String,Object>();

        try {

            //List<Coupon_Seller__c> listCoSellerToUpdate = new List<Coupon_Seller__c>();//LA-28-04-2025-US-0016656
            Set<String> setCoSellerIds = new Set<String>();

            if(!listCoSeller.isEmpty()){
                
                for(Coupon_Seller__c eachCoSeller : listCoSeller){
                    //TH:US-0013895: check coupon site can be allow to change stage to Contract Send without validation block
                    if(setAllowMainCouponSite.contains(eachCoSeller.Main_Coupon_Site__c) || eachCoSeller.Coupon_Seller_Stage__c == EBH_ConstantsUtility.COUPONSELLER_STAGE_APPROVED){ //14.06.2023 / Chetra Sarom / US-0013475
                        //LA-28-04-2025-US-0016656--START--//
                        //eachCoSeller.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND;
                        //listCoSellerToUpdate.add(eachCoSeller);
                        setCoSellerIds.add(eachCoSeller.id);
    
                    }
    
                }
            }
            if(setCoSellerIds.isEmpty()){
                mapResult.put('status','ko');
                mapResult.put('error',System.Label.ErrorNoCouponSellerInApprovedStage);
            }else{

                List<Coupon_Seller__c> listCoSellerToUpdate = new List<Coupon_Seller__c>();
                String sWhere = ' Where Id IN :setCoSellerIds';
                List<Coupon_Seller__c> listCS = ApexSafe.query().secCheck(false).doQuery(SOQL_COUPON_SELLER+sWhere, new Map<String, Object> {'setCoSellerIds' => setCoSellerIds});
                Set<String> setInElegibleIds = new Set<String>();
                List<String> listCoSellerName = new List<String>();

                for(Coupon_Seller__c cs : listCS){
                    // check VR: Coupon_Seller__c.Validate_CompanyDetailForContractSend
                    if(cs.Main_Coupon_Site__c <> COUPON_SITE_UK && (cs.Legal_Entity_Name_w__c == null || cs.Legal_Entity_Street_w__c == null || cs.Legal_Entity_Zip_w__c == null))
                    {
                        setInElegibleIds.add(cs.Id);
                        listCoSellerName.add(cs.Name);

                    }else{
                        cs.Coupon_Seller_Stage__c = EBH_ConstantsUtility.COUPON_SELLER_STAGE_CONTRACT_SEND;
                        listCoSellerToUpdate.add(cs);    
                    }
                }

                if(!listCoSellerToUpdate.isEmpty()){//LA-28-04-2025-US-0016656: List of success records
                    CouponSellerTriggerHandler.IS_UPDATED_BY_SYSTEM = true; // 05.04.2023 / Sophal Noch / US-0013235 : bypass trigger validation
                    //update listCoSellerToUpdate; //MN-22072024-US-0015525
                    ApexSafe.dml().secCheck(false).doUpdate(listCoSellerToUpdate, true); //MN-22072024-US-0015525
                    mapResult.put('status','ok');
                    mapResult.put('numsuccess',listCoSellerToUpdate.size()); //LA-28-04-2025-US-0016656
                }
                
                if(!setInElegibleIds.isEmpty()){//LA-28-04-2025-US-0016656: : List of failed records
                    String sWhereCondition = ' Where Id IN :setInElegibleIds';
                    List<Coupon_Seller__c> listCoSellerInElegible = ApexSafe.query().secCheck(false).doQuery(SOQL_COUPON_SELLER+sWhereCondition, new Map<String, Object> {'setInElegibleIds' => setInElegibleIds});
                    mapResult.put('status','ko');
                    mapResult.put('error', listCoSellerName + System.Label.ErrorMsgCompanyDetailForContractSend);
                    mapResult.put('listCoSellerInElegible',listCoSellerInElegible);
                    mapResult.put('numerror',setInElegibleIds.size());
                }
            }
    
            // if(listCoSellerToUpdate.isEmpty()){
            //     mapResult.put('status','ko');
            //     mapResult.put('error',System.Label.ErrorNoCouponSellerInApprovedStage);
            // }else{
            //     CouponSellerTriggerHandler.IS_UPDATED_BY_SYSTEM = true; // 05.04.2023 / Sophal Noch / US-0013235 : bypass trigger validation
            //     //update listCoSellerToUpdate; //MN-22072024-US-0015525
            //     ApexSafe.dml().secCheck(false).doUpdate(listCoSellerToUpdate, true); //MN-22072024-US-0015525
            //     mapResult.put('status','ok');
            // }
            //LA-28-04-2025-US-0016656--END--//



        }catch(DMLException dex)
    	{	mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
    	}catch(Exception ex)
    	{   mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());	}

        return mapResult;


    }

    static Map<String,String> mapLinkField = new Map<String,String>{'Name'=>'Name','Seller__r.Name'=>'SellerId'};

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
    		//this.editable = setEditableFields.contains(fieldName);
            if(mapLinkField.containsKey(fieldName)){
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