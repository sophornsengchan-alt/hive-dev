/*********************************************************************************************************************************
@ Class:          FinalValueFee_FVF_Handler
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        Handler Class for trigger Coupon Seller
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.04.2019 / Sovantheany Dim / Created the class.
@				  09.06.2023 / Sovantheany Dim / US-0013726 - FVF Roles
@				  17.08.2023 / SRONG TIN / 0013664 - Block FVF records for Change after submission
@				  06.11.2023 / SRONG TIN / US-0014202 - Clean Permission Sets (FVF)
@				  22.07.2024/ vadhanak voun/ US-0015373 - Align Apex Classes with Deactivated FVF_Campaign Record Type
*********************************************************************************************************************************/
public without sharing class FinalValueFee_FVF_Handler {
  // 19.01.2021 / Acmatac SEING / US-0008752
  public final static String FVF_STAGE_EBAY_SENT_TO_APPROVE = 'Sent_to_eBay_Approval';
  public final static String FVF_LISTING_RECORDTYPE = 'FVF_Listing_Level';
  public final static String FVF_SELLER_RECORDTYPE = 'FVF_Seller_Level';
  public final static String FVF_STAGE_DRAFT = 'Draft';
  public static Set<String> SET_STAGE_CHANGE = new Set<String>();
  public final static String SOQL_FINAL_VALUE_FEE = 'SELECT Id, Final_Value_Fee_FVF__r.RecordType.DevelopeName, Final_Value_Fee_FVF__r.Final_Value_Fee_Stage__ FROM Final_Value_Fee_FVF__c';
  // 06.11.2023 / SRONG TIN / US-0014202
  public final static String PERMISSION_SET_FVF_USER = 'FVF_User'; //Change From Nominated_Item_Editable to FVF_User

  /*****************************************************************************************************************************
    @ Method:   createNorminatedItem
    @ Version:  1.0
    @ Author: 	Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:	EPH-7267 New Object: Nominated Items & Nominate for FVF Discount
    AC3:
	Given that I am Any User
	When I chose multiple listings and press on "Nominate for FVF Discount" and create a new FVF(Listing Level) record
	Then per each selected "Seller Product" record from Inventory Diagnostic one record of the new object "Nominated Items" is created.
	Selected Values from "Seller Product" are copied to "Nominated Items"
    @ Event:	After Insert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Final_Value_Fee_FVF__c> listNewFVF
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 18.04.2019 / Sovantheany Dim / Created the  Method
	@				: 14/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
    *****************************************************************************************************************************/
  /*
	public static void createNorminatedItem(List<Final_Value_Fee_FVF__c> listNewFVF)
    {
    	Map<String,List<String>> mapFVF = new Map<String,List<String>>();
    	for(Final_Value_Fee_FVF__c fvf : listNewFVF){
    		if(fvf.Seller_to_Product_IDS__c == null) continue;
    		List<String> sellerToProductIds = fvf.Seller_to_Product_IDS__c.split(',');
    		mapFVF.put(fvf.Id,sellerToProductIds);
    		
    	}
    	if(mapFVF.isEmpty()) return;
    	
    	List<Nominated_Item__c> lstNorminatedItem = new List<Nominated_Item__c>();
    	for(String fvfId : mapFVF.keySet()){
    		for(String sellerToProductId : mapFVF.get(fvfId)){
    			Nominated_Item__c norItem = new Nominated_Item__c(Final_Value_Fee_FVF__c = fvfId,Inventory_Diagnostic__c = sellerToProductId);
    			lstNorminatedItem.add(norItem);
    		}
    	}
    	if(!lstNorminatedItem.isEmpty()) insert lstNorminatedItem;
    }
	*/
  /*****************************************************************************************************************************
    @ Method:   lockRecords
    @ Version:  1.0
    @ Author: 	SRONG TIN (srong.tin@gaea-sys.com)
    @ Purpose:	US-0013664 - Block FVF records for Change after submission
    @ Event:	Before Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Final_Value_Fee_FVF__c> listFVF, Map<Id,Final_Value_Fee_FVF__c> mapOld
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 16.08.2023 / Srong Tin / Created the  Method
					  21.10.2024 / David Herrero / Added bypass
    *****************************************************************************************************************************/
  public static void lockRecords(
    List<Final_Value_Fee_FVF__c> listFVF,
    Map<Id, Final_Value_Fee_FVF__c> mapOld
  ) {
    Boolean isAdmin = (Userinfo.getprofileId() == ApexUtil.ADMIN_PROFILE_ID);
    Boolean isAdminPriv = (Userinfo.getprofileId() ==
    ApexUtil.ADMIN_LT_PRIV_PROFILE_ID);
    RecordType fvfRecordTypeListing = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      FVF_LISTING_RECORDTYPE
    );
    RecordType fvfRecordTypeSeller = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      FVF_SELLER_RECORDTYPE
    );

    // 2024.10.21 DHE Include Bypass
    byPass__c bp = byPass__c.getInstance(UserInfo.getUserId()); //initiate bypass trigger
    Boolean bypassed = false;
    Boolean bypassValidation = FeatureManagement.checkPermission(
      'Bypass_Validation_Rule'
    );

    if (
      bp != null &&
      bp.byPass_Trigger__c &&
      !String.isBlank(bp.triggerObjects__c) &&
      bp.triggerObjects__c.containsIgnoreCase('Final_Value_Fee_FVF__c')
    ) {
      bypassed = true && bypassValidation;
    } //bypass trigger
	if (!(isAdmin || isAdminPriv || bypassed)) {
      for (Final_Value_Fee_FVF__c fvf : listFVF) {
        if (
          mapOld.get(fvf.Id).Final_Value_Fee_Stage__c !=
          fvf.Final_Value_Fee_Stage__c
        ) {
          SET_STAGE_CHANGE.add(fvf.Id);
        }
        if (
          (fvf.RecordTypeId == fvfRecordTypeListing.Id ||
          fvf.RecordTypeId == fvfRecordTypeSeller.Id) &&
          fvf.Final_Value_Fee_Stage__c != FVF_STAGE_DRAFT &&
          mapOld.get(fvf.Id).Final_Value_Fee_Stage__c ==
          fvf.Final_Value_Fee_Stage__c &&
          !SET_STAGE_CHANGE.contains(fvf.Id)
        ) {
          fvf.addError(Label.Error_Update_Record_Not_Stage_Draft);
        }
      }
    }
  }

  /*****************************************************************************************************************************
    @ Method:   sendEmailApproval
    @ Version:  1.0
    @ Author: 	Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:	[#EPH-7104] New Permission Set_ Final Value Fee Approval
    @			Workflow email alert not able get Name of the user in group when sending email to group
    @ Event:	After Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Final_Value_Fee_FVF__c> listNewFVF
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 22.5.2019 / Vadhanak Voun / Created the  Method
   	@				: 31.07.2019/ Vadhanak Voun/ EPH-7767 FVF Approval Process
	@				: 19.02.2020/ Vadhanak Voun/ US-0007178 FVF Campaign Approval Process
	@               : 31.31.2020/ Sreymeas Nao/ US-0007274 - FVF. save approval email on record
	@				: 10.11.2020/ Acmatac Seing/ [US-0008652] Hyper care : UK - Wrong FVF seller level Approval email
	@				: 09.06.2023/ Sovantheany Dim / US-0013726 - FVF Roles
	@				: 22.07.2024/ vadhanak voun/ US-0015373 - Align Apex Classes with Deactivated FVF_Campaign Record Type
	@											/Deactivated the method sendEmailApproval, since it is now only for FVFCampaign	
    *****************************************************************************************************************************/
  /*
	public static void sendEmailApproval(List<Final_Value_Fee_FVF__c> listNew, Map<Id,Final_Value_Fee_FVF__c> mapOld)
	{
		Set<String> setFvFIds = new Set<String>();
		List<Task> lstTask = new List<Task>();
		for(Final_Value_Fee_FVF__c fvf : listNew)
		{
			if(fvf.Final_Value_Fee_Stage__c== EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE && fvf.Final_Value_Fee_Stage__c <> mapOld.get(fvf.Id).Final_Value_Fee_Stage__c)
			{
				setFvFIds.add(fvf.Id);
			}
		}
		
		if(!setFvFIds.isEmpty())
		{
			List<Final_Value_Fee_FVF__c> listProcess = Database.query(EBH_ConstantsUtility.SOQL_FVF + ' Where Id IN:setFvFIds');
			Map<Id,User> mapUsers = ApexUtil.getUsersMemberByGroup(new Set<String>{EBH_ConstantsUtility.PERMISSION_SET_FVFAPPROVAL}); //same group name
			
			String fvfRequestEmail = EBH_ConstantsUtility.EMAILTEMPLATE_FVF_APPROVAL_REQUEST;
			String fvfCampaignNotifyEmail = EBH_ConstantsUtility.EMAILTEMPLATE_FVF_CAMPAIGN_APPROVAL_NOTIFY;
			String sWhere = ' Where DeveloperName IN(:fvfRequestEmail,:fvfCampaignNotifyEmail)';
			Map<String,EmailTemplate> mapemailTemplates = new Map<String,EmailTemplate>();
			for(EmailTemplate emt: Database.query(EBH_ConstantsUtility.SOQLEMAIL_TEMPLATES+sWhere))
			{
			mapemailTemplates.put(emt.DeveloperName,emt);
			}
			
			List<Messaging.SingleEmailMessage> listEmail = new List<Messaging.SingleEmailMessage>();
			
			if(FVF_Approval_Matrix__c.getAll()==null)
			{
			throw new FVF_Exception('No FVF Approval Matrix Defined in custom setting: FVF_Approval_Matrix__c');
			}
			
			List<FVF_Approval_Matrix__c> listMatrix = FVF_Approval_Matrix__c.getAll().values();
			Map<Final_Value_Fee_FVF__c,FVF_Approval_Matrix__c>  mapFVF_Matrix = new Map<Final_Value_Fee_FVF__c,FVF_Approval_Matrix__c>();
			
			//NK:20/02/2020: mapping for less loop for each fvf
			Map<String,FVF_Approval_Matrix__c[]> mapMatrix = mappingMatrix(listMatrix);
	
			RecordType recTypeFVFCampaign = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c','FVF_Campaign');
			RecordType fvfRecordTypeListing = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c',EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE);
			RecordType fvfRecordTypeSeller = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c',EBH_ConstantsUtility.FVF_SELLER_RECORDTYPE);
			List<String> toUserFVFListing = new List<String>();
			User uFVFListing= new User();
			EmailTemplate emTemp = new EmailTemplate();
			Messaging.SingleEmailMessage mailFVFListing = new Messaging.SingleEmailMessage();

			//NK:22/07/2024:US-0015373
			 
			for(Final_Value_Fee_FVF__c fvf : listProcess)
			{
				// Remove fvf.RecordTypeId==fvfRecordTypeSeller.Id from IF Condition, Acmatac 10/11/2020, [US-0008652] Hyper care : UK - Wrong FVF seller level Approval email
				// when FVF Listing doesn't have FVF campaign then don't send email
				//Remove (fvf.RecordTypeId==fvfRecordTypeListing.Id && fvf.FVF_Campaign__c==null) from IF Condition, LoumAng 14/01/2021: US-0008690 - FVF listing Approval Migration to standard process
				if (fvf.RecordTypeId==recTypeFVFCampaign.Id) {
					List<FVF_Approval_Matrix__c> listFoundMatrix = mapMatrix.get(fvf.RecordTypeId+(recTypeFVFCampaign.Id==fvf.RecordTypeId?fvf.Site__c:fvf.Rev_RollUp__c)); //Site__c
					//NK:31/07/2019: EPH-7767
					FVF_Approval_Matrix__c matrix = checkApprovalMatrix(listFoundMatrix,fvf);
				
					if(matrix <> null)
					{
						mapFVF_Matrix.put(fvf,matrix);
					}else//not match, go existing logic
					{
						for(User u: mapUsers.values())
						{
							uFVFListing = u;
							emTemp = mapemailTemplates.get(EBH_ConstantsUtility.EMAILTEMPLATE_FVF_APPROVAL_REQUEST);
							mailFVFListing = constructEmail(fvf,u,emTemp,ApexUtil.getCurrentUser());
							listEmail.add(mailFVFListing);
							toUserFVFListing.add(String.join(mailFVFListing.getToAddresses(), ','));
						}

						// add task record to show sent email history
						lstTask.add(createTaskLog_FVF(fvf,mergeFieldBodyFvF(uFVFListing, emTemp.Body, fvf, ApexUtil.getCurrentUser()),mailFVFListing,toUserFVFListing));
						 
					}
				}
			
			}
			 
			List<Final_Value_Fee_FVF__c> listFVFCampaign = new List<Final_Value_Fee_FVF__c>();
			
			//matrix found. could be child fvf (listing/seller) or parent fvf (Campaign)
			if(!mapFVF_Matrix.isEmpty())
			{
				//TODO
				//get users from matrix
				//construct email
				//add to listEmail
				Set<String> setUser = new Set<String>();
				for(FVF_Approval_Matrix__c mtx : mapFVF_Matrix.values())
				{
					String[] uids = (mtx.User_Id__c).split(',');
						setUser.addAll(uids);			 		
				}
				
				//18 char ids. user defined in custom setting
				Map<Id,User> mapUsersMTX = new Map<Id,User>((User[])Database.query(EBH_ConstantsUtility.SOQL_User));
				
				//for user checking whether user from the matrix is also in the permission set
				//TH:US-0013726:comment out permission set "Final Value Fee Approval"
				//Set<String> setPermissionCheck = ApexUtil.permissionSetMembers(EBH_ConstantsUtility.PERMISSION_SET_FVFAPPROVAL);
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				User u = new User();
				EmailTemplate etemplate = new EmailTemplate();
				List<String> toUser = new List<String>();
				for(Final_Value_Fee_FVF__c fvf : mapFVF_Matrix.keySet())
				{
					FVF_Approval_Matrix__c mtx = mapFVF_Matrix.get(fvf);
					for(String uid : (mtx.User_Id__c).split(','))
					{
						//if user defined in the matrix but not in permission set
						//TH:US-0013726:comment out permission set "Final Value Fee Approval"
						//if(!setPermissionCheck.contains(uid)) continue;
						
						u = mapUsersMTX.get(uid);
						etemplate = fvf.RecordTypeId == recTypeFVFCampaign.Id?
														mapemailTemplates.get(EBH_ConstantsUtility.EMAILTEMPLATE_FVF_CAMPAIGN_APPROVAL_NOTIFY)
														:mapemailTemplates.get(EBH_ConstantsUtility.EMAILTEMPLATE_FVF_APPROVAL_REQUEST);
						String bodyText = etemplate.Body;
						mail = constructEmail(fvf,u,etemplate,ApexUtil.getCurrentUser());
						listEmail.add(mail);
						toUser.add(String.join(mail.getToAddresses(), ', '));
													
						
					} 
					// add task record to show sent email history	
					lstTask.add(createTaskLog_FVF(fvf,mergeFieldBodyFvF(u, etemplate.Body, fvf, ApexUtil.getCurrentUser()),mail,toUser));
					
				}
			}
			
			if(!listEmail.isEmpty() && !Test.isRunningTest())
			{
				Messaging.sendEmail(listEmail);
				insert lstTask; 
			}
		}
	}
	*/
  /*****************************************************************************************************************************
    @ Method:   mappingMatrix
    @ Version:  1.0
    @ Author: 	Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:	US-0007178 FVF Campaign Approval Process
    @			mapping for less loop. return only 2 rows for each (recodtype + revRol) "<= and >"
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<FVF_Approval_Matrix__c> list matrix from custom setting
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 20.02.2020/ Vadhanak Voun / Created the  Method
	@				: 22.07.2024/ vadhanak voun/ US-0015373 - Align Apex Classes with Deactivated FVF_Campaign Record Type
	@											/Deactivated the method sendEmailApproval, since it is now only for FVFCampaign	
    *****************************************************************************************************************************/
  /*
	private static Map<String,FVF_Approval_Matrix__c[]> mappingMatrix(List<FVF_Approval_Matrix__c> listMatrix)
	{
		Map<String,FVF_Approval_Matrix__c[]> mapResult = new Map<String,FVF_Approval_Matrix__c[]>();
		for(FVF_Approval_Matrix__c mtx: listMatrix)
		{
			for(String recTypeName: mtx.RecordType__c.split(','))
			{
				RecordType recType = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c',recTypeName);
				for(String revRol: mtx.Rev_RollUp__c.split(','))
				{
					if(!mapResult.containsKey(recType.Id+revRol))
					{
						mapResult.put(recType.Id+revRol,new List<FVF_Approval_Matrix__c>());
					}
					mapResult.get(recType.Id+''+revRol).add(mtx); //map: recordtypeId + recRollup
				}
			}
		}
		
		return mapResult;
	}
	*/

  /* //NK:22/07/2024:US-0015373
	//check the number from fvf againts the pre-defined matrix
	private static FVF_Approval_Matrix__c checkApprovalMatrix(List<FVF_Approval_Matrix__c> listMatrix,Final_Value_Fee_FVF__c fvf)
	{
		 
		if((!hasValue(fvf.Budget_estimated_w__c) &&  !hasValue(fvf.Budget_Manually_Estimated__c)) || listMatrix == null )
		{
			return null; 
		}
		Decimal maxPrice =  Math.max((fvf.Budget_estimated_w__c==null?0:fvf.Budget_estimated_w__c), (fvf.Budget_Manually_Estimated__c==null?0:fvf.Budget_Manually_Estimated__c));
		
		for(FVF_Approval_Matrix__c matrix : listMatrix)
		{		
				Boolean result = ApexUtil.doCompare(matrix.Operator__c,maxPrice,matrix.Limitation__c);
				 
				if(result)
				{
					return matrix;
				}
		}
		return null;
	}
	*/

  private static Messaging.SingleEmailMessage constructEmail(
    Final_Value_Fee_FVF__c fvf,
    User u,
    EmailTemplate etemplate,
    User currentUser
  ) {
    String bodHtml = mergeFieldBodyFvF(
      u,
      etemplate.htmlValue,
      fvf,
      currentUser
    );
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(new List<String>{ u.Email });
    mail.setSenderDisplayName('Hive Support');
    mail.setSubject(etemplate.subject);
    mail.setBccSender(false);
    mail.setUseSignature(false);
    mail.setHtmlBody(bodHtml);
    return mail;
  }

  private static Boolean hasValue(Decimal val1) {
    return (val1 <> null && val1 > 0);
  }

  /*******************************************************************************************************
    @ Method:   mergeFieldBodyFvF
    @ Version:  1.0
    @ Author: 	LoumAng SENG (loumang.seng@gaea-sys.com)
    @ Purpose:	US-0006888- Specify Business Reason for FVF
    @			AC2:Given that I am a User with Permission set "Final Value Fee Approval"
	@			When a status of the new object: Final Value Fee (FVF) is changed to "Sent to eBay Approval"
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     User u,String ebody,Final_Value_Fee_FVF__c fvf
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 4/12/2019 / LoumAng SENG/ add mapping fields in the email template name: Final_Value_Fee_Discount_Request
   	@				: 20/02/2020/ Vadhanak Voun/ US-0007178 FVF Campaign Approval Process. added more merged fields
    ************************************************************/
  private static String mergeFieldBodyFvF(
    User u,
    String ebody,
    Final_Value_Fee_FVF__c fvf,
    User currentUser
  ) {
    eBody = eBody.replace('{!User.Name}', u.Name + '')
      .replace(
        '{!Final_Value_Fee_FVF__c.OwnerFullName}',
        fvf.Owner.Name == null ? '' : fvf.Owner.Name + ''
      )
      .replace(
        '{!Final_Value_Fee_FVF__c.Seller_Name__c}',
        fvf.Seller_Name__r.Name == null ? '' : fvf.Seller_Name__r.Name + ''
      )
      .replace(
        '{!Final_Value_Fee_FVF__c.Business_Reason__c}',
        fvf.Business_Reason__c == null ? '' : fvf.Business_Reason__c + ''
      )
      .replace(
        '{!Final_Value_Fee_FVF__c.Start_Date_w__c}',
        fvf.Start_Date_w__c == null ? '' : fvf.Start_Date_w__c.format()
      )
      .replace(
        '{!Final_Value_Fee_FVF__c.End_Date_w__c}',
        fvf.End_Date_w__c == null ? '' : fvf.End_Date_w__c.format()
      )
      .replace(
        '{!Final_Value_Fee_FVF__c.Budget_Manually_Estimated__c}',
        fvf.Budget_Manually_Estimated__c == null
          ? ''
          : ApexUtil.formatNumber(fvf.Budget_Manually_Estimated__c, ',', '.', 2)
      )
      .replace(
        '{!Final_Value_Fee_FVF__c.Budget_estimated_w__c}',
        fvf.Budget_estimated_w__c == null
          ? ''
          : ApexUtil.formatNumber(fvf.Budget_estimated_w__c, ',', '.', 2)
      )
      .replace(
        '{!Final_Value_Fee_FVF__c.Total_Number_of_Listings__c}',
        fvf.Total_Number_of_Listings__c == null
          ? ''
          : fvf.Total_Number_of_Listings__c + ''
      )
      .replace(
        '{!Final_Value_Fee_FVF__c.Link}',
        System.URL.getOrgDomainUrl().toExternalForm() +
          '/lightning/r/Final_Value_Fee_FVF__c/' +
          fvf.Id +
          '/view'
      )
      .replace(
        '{!Final_Value_Fee_FVF__c.Name}',
        fvf.Name == null ? '' : fvf.Name + ''
      )
      .replace('{!CurrentUser}', currentUser == null ? '' : currentUser.Name)
      .replace(
        '{!Final_Value_Fee_FVF__c.Total_Number_of_Listings_fvfcampaign__c}',
        fvf.Total_Number_of_Listings_fvfcampaign__c == null
          ? ''
          : fvf.Total_Number_of_Listings_fvfcampaign__c + ''
      )
      .replace(
        '{!Final_Value_Fee_FVF__c.Total_Number_of_Sellers__c}',
        fvf.Total_Number_of_Sellers__c == null
          ? ''
          : fvf.Total_Number_of_Sellers__c + ''
      );

    return ebody;
  }

  /*****************************************************************************************************************************
    @ Method:   sendClickContract
    @ Version:  1.0
    @ Author: 	Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:	EPH-7608 Send click contract to a seller as part of FVF process
    @			 AC2:
	@		Given that status of the Final Value Fee (FVF) record is changed to "Contract Sent"
	@		Then a click contract is sent to an email address of the related contact 
	@		Contact information is taken from Final Value Fee (FVF). Contact
	@		The owner of the record is CCed in the email /contract that is sent to a seller.
	@			AC3:  
	@		Contact will be populated with fields from FVF record.
	@		It will also contain Excel list attachement with the content from the related Nominated Items.
	@		See details of the mock-up of the email /Excel file attached.
	@		There will be several type of templates used for contract.
	@		Type of the contract is dependent on FVF.Seller. Rev RollUp
	@		If Rev RollUp = UK, use the templates attached
	@		Templates for other values of Rev RollUp  are not a part of this use story
	@ Purpose:	US-0007065 Status change. FVF Campaign
    @ AC1:
    @ Given that I am any User
    @ When i go to the new FVF Campaign record (US-0006963)
    @ When I change the status of the record to "Contract(s) Sent"
    @ Then all related FVF(Listing level) records do change their status to "Contract Sent"
    @ and contracts are triggered to FVF(Listing level).Seller Email
    @ After this action is complete, I either see a pop-up message or receive an email with the following information:
    @ "Thank you for changing the status of your campaign to "Contract(s) Sent".
    @ Final Value Fee contracts have been triggered from the system.
    @ % Sum (FVF listing level) that were successfully sent% were successfully sent.
    @ % Sum (FVF listing level) that could not be send because of existing validation rules % could not be sent.
    @ Possible reasons why contracts could not be sent - missing Seller Email, Legal Entity Name, Legal Entity Street, Legal Entity Zip, Legal Entity Country"
    @ Event:	Before Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Final_Value_Fee_FVF__c> listNewFVF
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 29.07.2019 / Vadhanak Voun / Created the  Method
   	@				: 19.9.2019 / Vadhanak Voun / DE Version: US-0009433 - Click contract to a seller as part of FVF process. DE version
   	@				: 27.11.2019/Vadhanak Voun/ US-0006871 FVF Contract Sender is not corrcet
   	@				: 04.12.2019/Sovantheany Dim/ US-0006893 IT & ES. FVF Contract
   	@				: 23.12.2019/Vadhanak Voun/ US-0006841 Chase Email for FVF & Compliance contract send date email
   	@				: 17/02/2020 / Sovantheany Dim/ update the method US-0007065 Status change. FVF Campaign
	@				: 22.07.2024/ vadhanak voun/ US-0015373 - Align Apex Classes with Deactivated FVF_Campaign Record Type
    *****************************************************************************************************************************/
  public static void sendClickContract(
    List<Final_Value_Fee_FVF__c> listNew,
    Map<Id, Final_Value_Fee_FVF__c> mapOld
  ) {
    RecordType fvfListingRecordType = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE
    );
    RecordType fvfCampaignRecordType = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      EBH_ConstantsUtility.FVF_CAMPAIGN_RECORDTYPE
    );
    RecordType fvfSellerRecordType = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      EBH_ConstantsUtility.FVF_SELLER_RECORDTYPE
    );
    Set<String> setFvFListingIds = new Set<String>();
    //Set<String> setfvfCampaignId = new Set<String>();
    for (Final_Value_Fee_FVF__c fvf : listNew) {
      if (
        fvf.Final_Value_Fee_Stage__c <>
        mapOld.get(fvf.Id).Final_Value_Fee_Stage__c &&
        fvf.Final_Value_Fee_Stage__c ==
        EBH_ConstantsUtility.FVF_STAGE_CONTRACT_SENT
      ) {
        //LA 01/10/202: US-0008188 - [UK] FVF (seller level) contract template
        //EPH-7608 TH: Send contract for only listing level by Natalia
        if (
          fvf.RecordTypeId == fvfListingRecordType.Id ||
          fvf.RecordTypeId == fvfSellerRecordType.Id
        ) {
          setFvFListingIds.add(fvf.Id);
          if (fvf.Seller_Email__c == null) {
            fvf.addError('Seller Email is required.');
          }
          //NK:23/12/2019: US-0006841
          fvf.Contract_Send_Date__c = System.today();
        }
        //NK:22/07/2024:US-0015373
        //Th 18/02/2020: US-0007065 Status change. FVF Campaign
        //else if(fvf.RecordTypeId == fvfCampaignRecordType.Id){
        //	setfvfCampaignId.add(fvf.Id);
        //}
      }
    }
    //EPH-7608
    if (!setFvFListingIds.isEmpty()) {
      processEmailSend(setFvFListingIds, false);
    }
    //NK:22/07/2024:US-0015373
    //US-0007065 Status change. FVF Campaign
    //if(!setfvfCampaignId.isEmpty()){
    //	processFVFCampaignEmail(fvfListingRecordType,setfvfCampaignId);
    //}
  }

  /*****************************************************************************************************************************
    @ Method:   processFVFCampaignEmail
    @ Version:  1.0
    @ Author: 	Sovantheany Dim (sovantheany.dim@gaea-sys.com)
	@ Purpose:	sharing for method: sendClickContract()
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     RecordType fvfListingRecordType,Set<String> setfvfCampaignId
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 17/02/2020 / Sovantheany Dim/ moved out of sendClickContract() for sharing
	@				: 22.07.2024/ vadhanak voun/ US-0015373 - Align Apex Classes with Deactivated FVF_Campaign Record Type
    *****************************************************************************************************************************/
  /*
	private static void processFVFCampaignEmail(RecordType fvfListingRecordType,Set<String> setfvfCampaignId){
		String listingRecordTypeId = fvfListingRecordType.Id;
			List<Final_Value_Fee_FVF__c> lstFvfToUpdate = new List<Final_Value_Fee_FVF__c>();
			//query all listing fvf related to Campaign fvf
			for(Final_Value_Fee_FVF__c listingfvf : Database.query(EBH_ConstantsUtility.SOQL_FVF + ' Where FVF_Campaign__c IN: setfvfCampaignId and RecordTypeId =: listingRecordTypeId')){
				listingfvf.Final_Value_Fee_Stage__c = EBH_ConstantsUtility.FVF_STAGE_CONTRACT_SENT;
				lstFvfToUpdate.add(listingfvf);
			}
			if(lstFvfToUpdate.isEmpty()) return;
			List<Database.SaveResult> results = Database.update(lstFvfToUpdate, false);
			Integer successSend = 0;
			Integer failSend = 0;
			Map<String,String> mapLastError = new Map<String,String>();
			for (Database.SaveResult result : results) {
				if (!result.isSuccess()){
					failSend += 1;
					mapLastError.put('fvf',result.getErrors()[0].getMessage());
				}else{
					successSend += 1;
				}
			}
			
			String fvfCampaignEmail = 'FVFCampaignEmailTemplate';
			String sWhere = ' Where DeveloperName =:fvfCampaignEmail';
			List<EmailTemplate>  emailTemplates = Database.query(EBH_ConstantsUtility.SOQLEMAIL_TEMPLATES+sWhere);
			String bodyHtml = emailTemplates[0].htmlValue;
			bodyHtml = bodyHtml.replace('{!successSend}',successSend+'')
			.replace('{!failSend}',failSend+'')
			.replace('{!reasonFail}',mapLastError.containsKey('fvf')?mapLastError.get('fvf')+'':'')
			.replace('{!possibleReason}',mapLastError.isEmpty()?'':System.label.PossibleReason+' ');
			if(!Test.isRunningTest()){
				ApexUtil.doSend(emailTemplates[0].subject,UserInfo.getUserEmail(),bodyHtml);
			}
	}
	*/
  /*******************************************************************************************************
    @ Method:   processEmailSend
    @ Version:  1.0
    @ Author: 	vadhanak Voun(vadhanak.voun@gaea-sys.com) 	
    @ Purpose:	sharing for both method: sendClickContract() and reminderClickContract
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     setFvFIds , isReminder: if trigger for reminding.
    ------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 23/12/2019 / vadhanak Voun/ moved out of sendClickContract() for sharing
	@				: 06.March.2020/ Acmatac SEING/ [US-0007198] - [FVF] Attach Contracts
	@				: 10.04.2020/vadhanak voun/US-0007440 - Hypercare_ FVF Status Change is not possible
	@				: added @future for bigger cpu and heap
    ************************************************************************************************************/
  @future
  private static void processEmailSend(
    Set<String> setFvFIds,
    Boolean isReminder
  ) {
    //e.g. FVF_Click_Contract_UK_Reminder for reminder
    //FVF_Click_Contract_UK original Click Contract for FVF
    String templateNameSuffix = isReminder ? '_Reminder' : '';

    Set<String> setRevRoll = new Set<String>();
    //Map<String,String> mapTemplateNames = new Map<String,String>();
    Set<String> setTemplateNames = new Set<String>();
    List<Final_Value_Fee_FVF__c> listFvF = Database.query(
      EBH_ConstantsUtility.SOQL_FVF + ' Where Id IN:setFvFIds'
    );
    for (Final_Value_Fee_FVF__c fvf : listFvF) {
      setRevRoll.add(fvf.Seller_Name__r.EBH_RevRollup__c);
      if (
        fvf.Seller_Name__r.EBH_RevRollup__c <> null &&
        mapEmailTempalteClickContract.containsKey(
          fvf.Seller_Name__r.EBH_RevRollup__c
        )
      ) {
        setTemplateNames.add(
          mapEmailTempalteClickContract.get(fvf.Seller_Name__r.EBH_RevRollup__c)
        );
        //in case reminder, need to include the original templat too
        setTemplateNames.add(
          mapEmailTempalteClickContract.get(
            fvf.Seller_Name__r.EBH_RevRollup__c
          ) + templateNameSuffix
        );
      }
    }
    if (!setRevRoll.isEmpty() && !setTemplateNames.isEmpty()) {
      Map<String, EmailTemplate> mapEmailTemplates = new Map<String, EmailTemplate>();
      String sWhereTemplate = ' Where DeveloperName IN:setTemplateNames ';
      for (
        EmailTemplate et : Database.query(
          EBH_ConstantsUtility.SOQLEMAIL_TEMPLATES + sWhereTemplate
        )
      ) {
        mapEmailTemplates.put(et.DeveloperName, et);
      }

      String fvfWhere = ' Where Final_Value_Fee_FVF__c IN:setFvFIds';
      Map<String, List<Nominated_Item__c>> mapNominatedItems = new Map<String, List<Nominated_Item__c>>();
      //system.debug('>>>mapEmailTemplates: '+mapEmailTemplates.size());
      if (!mapEmailTemplates.isEmpty()) {
        for (
          Nominated_Item__c nit : Database.query(
            EBH_ConstantsUtility.SOQL_NOMINATED_ITEMS + fvfWhere
          )
        ) {
          //mapping FVF to list Items
          if (!mapNominatedItems.containsKey(nit.Final_Value_Fee_FVF__c)) {
            mapNominatedItems.put(
              nit.Final_Value_Fee_FVF__c,
              new List<Nominated_Item__c>()
            );
          }
          mapNominatedItems.get(nit.Final_Value_Fee_FVF__c).add(nit);
        }
        Set<String> setUser = new Set<String>{ UserInfo.getUserId() };
        User currentUser = Database.query(EBH_ConstantsUtility.SOQL_User);

        List<Messaging.SingleEmailMessage> listEmail = new List<Messaging.SingleEmailMessage>();
        Map<String, List<Messaging.EmailFileAttachment>> mapListAtt = new Map<String, List<Messaging.EmailFileAttachment>>();
        List<Task> lstTask = new List<Task>();
        //system.debug('>>>listFvF: '+listFvF);
        for (Final_Value_Fee_FVF__c fvf : listFvF) {
          if (
            !mapEmailTempalteClickContract.containsKey(
              fvf.Seller_Name__r.EBH_RevRollup__c
            )
          )
            continue;
          if (
            !mapEmailTemplates.containsKey(
              mapEmailTempalteClickContract.get(
                fvf.Seller_Name__r.EBH_RevRollup__c
              )
            )
          )
            continue;
          EmailTemplate eTemplate = mapEmailTemplates.get(
            mapEmailTempalteClickContract.get(
              fvf.Seller_Name__r.EBH_RevRollup__c
            )
          );
          EmailTemplate eTemplateReminder = mapEmailTemplates.get(
            mapEmailTempalteClickContract.get(
              fvf.Seller_Name__r.EBH_RevRollup__c
            ) + templateNameSuffix
          );
          Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
          //mail.setToAddresses(new String[]{Test.isRunningTest()?'test@test.com':fvf.Contact_Person__r.Email});
          //NK:16/08/2019: EPH-7973
          mail.setToAddresses(
            new List<String>{
              Test.isRunningTest() ? 'test@test.com' : fvf.Seller_Email__c
            }
          );
          String ccAddr = (isReminder ||
            fvf.RecordType.DeveloperName ==
            EBH_ConstantsUtility.FVF_SELLER_RECORDTYPE)
            ? fvf.Requestor__r.Email
            : fvf.Owner.Email; //NK:23/12/2019:US-0006841 //LA:05/10/2020:US-0008188
          mail.setCcAddresses(
            new List<String>{ Test.isRunningTest() ? 'test2@test.com' : ccAddr }
          );
          //NK:27/11/2019:US-0006871
          //mail.setSenderDisplayName('Hive Support');
          mail.setSenderDisplayName(currentUser.Name);
          String subject = isReminder
            ? doMearchClickContractSubject(fvf, eTemplateReminder.subject)
            : doMearchClickContractSubject(fvf, eTemplate.subject);
          mail.setSubject(subject);
          mail.setBccSender(false);
          mail.setUseSignature(false);

          String bodyHtml = isReminder
            ? doMearchClickContract(
                  currentUser,
                  fvf,
                  eTemplateReminder.HtmlValue
                )
                .replace(
                  '{!OriginalFVFDiscountEmailBody}',
                  doMearchClickContract(currentUser, fvf, eTemplate.HtmlValue)
                )
            : doMearchClickContract(currentUser, fvf, eTemplate.HtmlValue);
          String bodyText = isReminder
            ? doMearchClickContract(currentUser, fvf, eTemplateReminder.Body)
                .replace(
                  '{!OriginalFVFDiscountEmailBody}',
                  doMearchClickContract(currentUser, fvf, eTemplate.Body)
                )
            : doMearchClickContract(currentUser, fvf, eTemplate.Body);
          mail.setHtmlBody(bodyHtml);
          if (mapNominatedItems.containsKey(fvf.Id)) {
            //header
            List<List<String>> listRowNIT_all = new List<List<String>>{
              //new List<String>{
              //	'Product Name',	'Ebay Listing ID', 'Recommended price', 'FVF Discount %*'
              //  }
              mapColHeaders.containsKey(fvf.Seller_Name__r.EBH_RevRollup__c)
                ? mapColHeaders.get(fvf.Seller_Name__r.EBH_RevRollup__c)
                : mapColHeaders.get('UK') //default uk
            };

            for (Nominated_Item__c nitem : mapNominatedItems.get(fvf.Id)) {
              listRowNIT_all.add(
                getListValue(fvf.Seller_Name__r.EBH_RevRollup__c, nitem)
              );
            }
            //NK:17/10/2019: US-0018737
            if (fvf.Seller_Name__r.EBH_RevRollup__c == 'UK') {
              //static text below the the rows
              listRowNIT_all.add(new List<String>{ '' });
              listRowNIT_all.add(new List<String>{ '' });
              listRowNIT_all.add(new List<String>{ '' });
              listRowNIT_all.add(new List<String>{ '' });
              listRowNIT_all.add(
                new List<String>{ System.Label.FVF_XLS_UK_note }
              );
            }

            List<ExcelGenerator.xSheet> listSheetsNIT = new List<ExcelGenerator.xSheet>();
            ExcelGenerator.xSheet sheetNIT = new ExcelGenerator.xSheet(
              'NominatedItems',
              listRowNIT_all
            );
            listSheetsNIT.add(sheetNIT);
            ExcelGenerator genNIT = new ExcelGenerator(
              currentUser.Name,
              listSheetsNIT
            );
            genNIT.generateWorkBook();

            Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
            att.setBody(Blob.valueOf(genNIT.getWorkbookXML()));
            //att.setFileName('NominatedItems.xls');
            att.setFileName(
              getAttachmentName(fvf.Seller_Name__r.EBH_RevRollup__c)
            );

            mail.setFileAttachments(
              new List<Messaging.EmailFileAttachment>{ att }
            );
            mapListAtt.put(fvf.Id, mail.getFileAttachments());
          }

          listEmail.add(mail);

          // AMT, [US-0007198] - [FVF] Attach Contracts
          lstTask.add(createTaskLog_FVF(fvf, bodyText, mail, null));
        }
        //system.debug('>>>listEmail: '+listEmail);
        if (!listEmail.isEmpty() && !Test.isRunningTest()) {
          Messaging.sendEmail(listEmail);
          insert lstTask;
          List<Attachment> listTaskAtt = new List<Attachment>();
          for (Task t : lstTask) {
            List<Messaging.EmailFileAttachment> listEFA = mapListAtt.get(
              t.WhatId
            );
            if (listEFA <> null) {
              for (Messaging.EmailFileAttachment efa : listEFA) {
                //xls body, and pdf body from sent email attament and attach to Task
                Attachment att = new Attachment(
                  ParentId = t.Id,
                  Name = efa.FileName,
                  Body = efa.Body,
                  ContentType = efa.ContentType
                );
                listTaskAtt.add(att);
              }
            }
          }
          if (!listTaskAtt.isEmpty()) {
            insert listTaskAtt;
          }
        }
      }
    }
  }
  private static String getAttachmentName(String country) {
    Map<String, String> mapAttName = new Map<String, String>{
      'UK' => 'NominatedItems.xls',
      'DE' => 'Anlage 1.xls',
      'ES' => 'Anexo 1.xls',
      'IT' => 'Appendice 1.xls',
      'FR' => 'Annexe 1.xls'
    };
    return mapAttName.containsKey(country)
      ? mapAttName.get(country)
      : mapAttName.get('UK');
  }

  private static String doMearchClickContractSubject(
    Final_Value_Fee_FVF__c fvf,
    String subject
  ) {
    return subject.replace(
        '{!FVF_SellerName}',
        (fvf.Seller_Name__c == null ||
          fvf.RecordType.DeveloperName ==
          EBH_ConstantsUtility.FVF_SELLER_RECORDTYPE)
          ? ''
          : fvf.Seller_Name__r.Name
      ) //LA:05/10/2020: show empty for FVF(seller level)
      .replace(
        '{!Action_Require}',
        (fvf.Seller_Name__c == null ||
          fvf.RecordType.DeveloperName !=
          EBH_ConstantsUtility.FVF_SELLER_RECORDTYPE)
          ? ''
          : '(action required)'
      ) //LA:05/10/2020: show string only FVF(seller level)
      .replace(
        '{!FVF_StartDate}',
        (fvf.Start_Date_w__c == null ||
          fvf.RecordType.DeveloperName ==
          EBH_ConstantsUtility.FVF_SELLER_RECORDTYPE)
          ? ''
          : fvf.Start_Date_w__c.format()
      ); //LA:05/10/2020: show empty for FVF(seller level)
  }
  private static String doMearchClickContract(
    User u,
    Final_Value_Fee_FVF__c fvf,
    String htmlBody
  ) {
    String acceptURl =
      ApexUtil.getSiteUrl('Deal_Acceptance') +
      '?restype=' +
      EBH_TrackingResponseController.CONRACT_FVF_URL_TYPE +
      '&' +
      EBH_TrackingResponseController.CONRACT_FVF_PARAM_FVFID +
      '=' +
      fvf.Id +
      '&' +
      EBH_TrackingResponseController.REDIRECT_URL;
    //String applicableTo = fvf.RecordType.DeveloperName==EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE?'The items specified in the attached Excel spreadsheet':'All of Seller’s listings';
    String applicableTo = 'The items/categories/stores specified in the attached Excel spreadsheet'; //LA:05/10/2020:US-0008188: Update the string
    return htmlBody.replace(
        '{!FVF_SellerOracleId}',
        fvf.Seller_Name__r.Name +
          ' (' +
          ApexUtil.checkNull(fvf.Seller_Name__r.EBH_OracleID__c) +
          ')'
      )
      .replace(
        '{!FVF_DiscountFVF}',
        fvf.Discount_FVF__c == null ? '' : fvf.Discount_FVF__c + '%'
      )
      .replace('{!FVF_StartTime}', ApexUtil.formatTime(fvf.Start_Time__c) + '')
      .replace(
        '{!FVF_StartDate}',
        fvf.Start_Date_w__c == null ? '' : fvf.Start_Date_w__c.format()
      )
      .replace('{!FVF_EndTime}', ApexUtil.formatTime(fvf.End_Time__c) + '')
      .replace(
        '{!FVF_EndDate}',
        fvf.End_Date_w__c == null ? '' : fvf.End_Date_w__c.format()
      )
      .replace(
        '{!FVF_AddtionalTerm}',
        ApexUtil.checkNull(fvf.Additional_Terms__c) + ''
      )
      .replace('{!FVF_ApplicableTo}', applicableTo)
      .replace(
        '{!SellerCompanyName}',
        ApexUtil.checkNull(fvf.Seller_Name__r.EBH_CompanyName__c) + ''
      )
      //.replace('{!SellerAddress}',ApexUtil.checkNull(fvf.Seller_Name__r.EBH_BillingAddress__c)+'')
      .replace(
        '{!SellerAddress}',
        ApexUtil.nullStr(fvf.Seller_Name__r.EBH_BillingStreet__c) +
          ', ' +
          ApexUtil.nullStr(fvf.Seller_Name__r.EBH_BillingCity__c) +
          ' ' +
          ApexUtil.nullStr(fvf.Seller_Name__r.EBH_BillingPostalCode__c)
      )
      .replace(
        '{!SellerRegisterCountry}',
        ApexUtil.checkNull(fvf.Seller_Name__r.EBH_RegistrationCountry__c) + ''
      )
      .replace(
        '{!SellerVatNumber}',
        ApexUtil.checkNull(fvf.Seller_Name__r.EBH_VATNumber__c) + ''
      )
      .replace('{!urlAccept}', acceptURl)
      .replace(
        '{!SellerLegalEntity}',
        fvf.Seller_Name__r.ParentId == null
          ? ''
          : fvf.Seller_Name__r.EBH_ParentAccount__c
      )
      .replace(
        '{!FVF_SellerName}',
        fvf.Seller_Name__c == null ? '' : fvf.Seller_Name__r.Name
      )
      .replace(
        '{ifFreeShipping}',
        (fvf.Free_shipping__c &&
          mapFreeShippingLabel.containsKey(fvf.Seller_Name__r.EBH_RevRollup__c))
          ? mapFreeShippingLabel.get(fvf.Seller_Name__r.EBH_RevRollup__c)
          : ''
      )
      .replace(
        '{!LegalEntity}',
        fvf.Legal_Entity_Name__c == null ? '' : fvf.Legal_Entity_Name__c
      )
      //LA:05/10/2020:US-0008188-For FVF(Seller level) show only Legal_Entity_Street__c,Legal_Entity_Zip__c, Legal_Entity_Country__c in {!SellerAddress1}
      .replace(
        '{!SellerAddress1}',
        fvf.RecordType.DeveloperName ==
          EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE
          ? (ApexUtil.nullStr(fvf.Seller_Name__r.Name) +
            ', ' +
            ApexUtil.nullStr(fvf.Legal_Entity_Street__c) +
            ', ' +
            ApexUtil.nullStr(fvf.Seller_Name__r.Parent.EBH_BillingCity__c) +
            ', ' +
            ApexUtil.nullStr(fvf.Legal_Entity_Zip__c) +
            ', ' +
            ApexUtil.nullStr(fvf.Legal_Entity_Country__c))
          : (ApexUtil.nullStr(fvf.Legal_Entity_Name__c) +
            ', ' +
            ApexUtil.nullStr(fvf.Legal_Entity_Street__c) +
            ', ' +
            ApexUtil.nullStr(fvf.Legal_Entity_Zip__c) +
            ', ' +
            ApexUtil.nullStr(fvf.Legal_Entity_Country__c))
      )
      .replace(
        '{!Contact_Person__r.Name}',
        fvf.Contact_Person__c == null ? '' : fvf.Contact_Person__r.Name
      )
      .replace(
        '{!Contract_Send_Date__c}',
        fvf.Contract_Send_Date__c == null
          ? ''
          : fvf.Contract_Send_Date__c.format()
      )
      .replace(
        '{!Start_Date_w__c-1}',
        fvf.Start_Date_w__c == null
          ? ''
          : fvf.Start_Date_w__c.addDays(-1).format()
      )
      .replace('{!CurrentUserName}', u.Name);
  }

  //TH:04/12/2019: US-0006893 IT & ES. FVF Contract
  private static Map<String, String> mapFreeShippingLabel = new Map<String, String>{
    'UK' => System.Label.FVF_FreeShipping_UK,
    'DE' => System.Label.FVF_FreeShipping_DE,
    'ES' => System.Label.FVF_FreeShipping_ES,
    'IT' => System.Label.FVF_FreeShipping_IT,
    'FR' => System.Label.FVF_FreeShipping_FR
  };
  private static Map<String, String> mapEmailTempalteClickContract = new Map<String, String>{
    'UK' => 'FVF_Click_Contract_UK',
    'DE' => 'FVF_Click_Contract_DE',
    'ES' => 'FVF_Click_Contract_ES',
    'IT' => 'FVF_Click_Contract_IT',
    'FR' => 'FVF_Click_Contract_FR'
  };
  private static Map<String, List<String>> mapColHeaders = new Map<String, List<String>>{
    'UK' => new List<String>{
      'Product Name',
      'eBay Listing ID',
      'Maximum Recommended Price*',
      'FVF Discount %' //NK:15/10/2019: US-0018784
    },
    'DE' => new List<String>{
      'Artikelbezeichnung',
      'eBay Artikelnummer',
      'Verkaufspreis'
    },
    'ES' => new List<String>{
      'Nombre del Anuncio',
      'ID del Articulo',
      'Precio'
    },
    'IT' => new List<String>{
      'Nome del prodotto',
      'ID inserzione eBay',
      'Prezzo massimo consigliato'
    },
    'FR' => new List<String>{
      'Nom de l’objet',
      'ID de l’objet',
      'Prix maximum recommandé'
    }
  };
  private static Map<String, String[]> mapListFields = new Map<String, String[]>{
    'UK' => new List<String>{
      'Listing_Name_w__c',
      'Listing_ID_w__c',
      'Price_target_w__c', //NK:29/11/2019: US-0006908: Max_Price_During_Promotion__c -> Price_target_w__c
      'Discount_FVF_w__c'
    }, //Th:11/02/2019 : US-0007060 change from Discount_FVF__c to Discount_FVF_w__c
    'DE' => new List<String>{
      'Listing_Name_w__c',
      'Listing_ID_w__c',
      'Price_target_w__c'
    },
    'ES' => new List<String>{
      'Listing_Name_w__c',
      'Listing_ID_w__c',
      'Price_target_w__c'
    },
    'IT' => new List<String>{
      'Listing_Name_w__c',
      'Listing_ID_w__c',
      'Price_target_w__c'
    },
    'FR' => new List<String>{
      'Listing_Name_w__c',
      'Listing_ID_w__c',
      'Price_target_w__c'
    }
  };

  private static List<String> getListValue(String revRoll, SObject sobj) {
    List<String> listFields = mapListFields.containsKey(revRoll)
      ? mapListFields.get(revRoll)
      : mapListFields.get('UK');
    List<String> listValues = new List<String>();
    for (String f : listFields) {
      Object val = ApexUtil.getValue(f, sobj);
      listValues.add(val == null ? '' : val + '');
    }
    return listValues;
  }
  class FVF_Exception extends Exception {
  }
  /*****************************************************************************************************************************
    @ Method:   assignPermset_NominatedItemEdit
    @ Version:  1.0
    @ Author: 	LoumAng SENG (loumang.seng@gaea-sys.com)
    @ Purpose:	US-0015722 Enable Users to edit fields in Nominated Items
	@		    AC: Given that I am either Owner or Requestor of the FVF record
	@		    Then I  can edit the following fields in the related Nominated Items records: 
    @ Event:	After Insert, After Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Final_Value_Fee_FVF__c> listNewFVF, mapOld
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 23.09.2019 / LoumAng SENG / Created the  Method
    *****************************************************************************************************************************/
  public static void assignPermset_NominatedItemEdit(
    List<Final_Value_Fee_FVF__c> listNewFVF,
    Map<Id, Final_Value_Fee_FVF__c> mapOldFVF
  ) {
    Boolean isNew = (mapOldFVF == null);
    Set<String> setFvFIds = new Set<String>();
    Set<String> setUserToGetPermission = new Set<String>();
    RecordType fvfRecordTypeSellerCommunication = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      'Seller_Communication'
    );
    for (Final_Value_Fee_FVF__c fvf : listNewFVF) {
      if (
        (isNew ||
        (!isNew && ((fvf.Requestor__c <> mapOldFVF.get(fvf.Id).Requestor__c)) ||
        fvf.OwnerId <> mapOldFVF.get(fvf.Id).OwnerId)) &&
        fvf.RecordTypeId <> fvfRecordTypeSellerCommunication.Id
      ) {
        setUserToGetPermission.add(fvf.OwnerId);
        if (fvf.Requestor__c <> null) {
          setUserToGetPermission.add(fvf.Requestor__c);
        }
      }
    }

    if (!setUserToGetPermission.isEmpty()) {
      // 06.11.2023 / SRONG TIN / US-0014202
      String permNEditName = PERMISSION_SET_FVF_USER;
      String sWhere = ' Where PermissionSet.Name =:permNEditName AND AssigneeId IN :setUserToGetPermission';
      Set<String> setAssignedUser = new Set<String>(); // for user who already assign to this permission set to avoid duplicate error
      for (
        PermissionSetAssignment psa : Database.query(
          EBH_ConstantsUtility.SOQL_PERMISSIONSET_ASSIGNMENT + sWhere
        )
      ) {
        setAssignedUser.add(psa.AssigneeId); //existing user
      }

      Set<String> setUserIdToAssign = new Set<String>();
      for (String uId : setUserToGetPermission) {
        //if not yet exist, then assign new permset
        if (!setAssignedUser.contains(uId)) {
          setUserIdToAssign.add(uId);
        }
      }
      if (!setUserIdToAssign.isEmpty()) {
        doCreateAssignment(setUserIdToAssign);
      }
    }
  }

  @future
  private static void doCreateAssignment(Set<String> setUserId) {
    // 06.11.2023 / SRONG TIN / US-0014202
    String permNEditName = PERMISSION_SET_FVF_USER;
    PermissionSet ps = Database.query(
      EBH_ConstantsUtility.SOQL_PERMISSIONSET + ' Where Name =:permNEditName'
    );
    List<PermissionSetAssignment> listNewAssign = new List<PermissionSetAssignment>();
    for (String uid : setUserId) {
      PermissionSetAssignment psa = new PermissionSetAssignment(
        AssigneeId = uId,
        PermissionSetId = ps.Id
      );
      listNewAssign.add(psa);
    }
    insert listNewAssign;
  }

  /*****************************************************************************************************************************
    @ Method:   checkNominateItemPriceisNotNull
    @ Version:  1.0
    @ Author: 	Sreymeas Nao (sreymeas.nao@gaea-sys.com)
    @ Purpose:	US-0006900 Given that I am any User
	@			I am not able to move the status of my Final value Fee record to “Sent to Approver”
	@			Unless any related “Nominated Items “ record has field Price( target) that does not have any value ( Equals Null)
    @ Event:	Before Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Final_Value_Fee_FVF__c> listNewFVF, mapOld
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 05.12.2019 / Sreymeas Nao / Created the  Method
    *****************************************************************************************************************************/
  public static void checkNominateItemPriceisNotNull(
    List<Final_Value_Fee_FVF__c> listNewFVF,
    Map<Id, Final_Value_Fee_FVF__c> mapOldFVF
  ) {
    //1, check if record is changed the stage or insert with that stage
    Boolean isInsert = mapOldFVF == null; // when insert, there is no old trigger
    Map<String, Final_Value_Fee_FVF__c> mapChange = new Map<String, Final_Value_Fee_FVF__c>();
    for (Final_Value_Fee_FVF__c fvf : listNewFVF) {
      if (
        fvf.Final_Value_Fee_Stage__c ==
        EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE &&
        (!isInsert &&
        fvf.Final_Value_Fee_Stage__c <>
        mapOldFVF.get(fvf.Id).Final_Value_Fee_Stage__c)
      ) {
        mapChange.put(fvf.Id, fvf);
      } else if (
        isInsert &&
        fvf.Final_Value_Fee_Stage__c ==
        EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE
      ) {
        fvf.addError(Label.Err_msg_Nominated_Item_has_no_target_price);
      }
    }

    //some records changed the stage to what we need
    if (!mapChange.isEmpty()) {
      Set<String> setFVFIds = mapChange.keySet();
      String soql = 'Select Id, (Select Id,Name,Price_target_w__c From Nominated_Items__r where Price_target_w__c=null OR Price_target_w__c=0 LIMIT 1) From Final_Value_Fee_FVF__c Where Id IN:setFVFIds';
      for (Final_Value_Fee_FVF__c fvf : Database.query(soql)) {
        if (
          fvf.Nominated_Items__r <> null &&
          !fvf.Nominated_Items__r.isEmpty() // at least 1 Nominated Item has null or 0 value
        ) {
          mapChange.get(fvf.Id)
            .addError(Label.Err_msg_Nominated_Item_has_no_target_price);
        }
      }
    }
  }

  /*******************************************************************************************************
    @ Method:   reminderClickContract
    @ Version:  1.0
    @ Author: 	vadhanak Voun(vadhanak.voun@gaea-sys.com) 	
    @ Purpose:	US-0006841 Chase Email for FVF & Compliance contract send date email
    @			AC2:
	@		Given that FVF. Contract Send Date is not NULL
	@		and FVF. Start Date - TODAY =3 (three days before the start date)
	@		and FVF. Status =eBay Approved
	@		and Seller. rev Roll up =UK
	@		Then system is automatically sending email to Seller_Email__c with FVF. Requestor. Email in CC
	@		See content of the email attached.
	@ Event after Update: timebase workflow(FVF_Discount_Reminder) 3 days before stardate sets Reminder_Email_Send_Date__c to Today, and then comes into this trigger
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     Final_Value_Fee_FVF__c fvf new, old
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 23/12/2019 / vadhanak Voun/ created the method
    ************************************************************************************************************/
  public static void reminderClickContract(
    List<Final_Value_Fee_FVF__c> listFVF,
    Map<Id, Final_Value_Fee_FVF__c> mapOld
  ) {
    Set<String> setFvFIds = new Set<String>();
    for (Final_Value_Fee_FVF__c fvf : listFVF) {
      if (
        fvf.Reminder_Email_Send_Date__c <>
        mapOld.get(fvf.Id).Reminder_Email_Send_Date__c && //updated from time base workflow. 3 days before startdate
        fvf.Rev_RollUp__c == 'UK' && //uk for now
        fvf.Final_Value_Fee_Stage__c ==
        EBH_ConstantsUtility.FVF_STAGE_CONTRACT_SENT && // constract still not signed
        fvf.Contract_Send_Date__c <> null //
      ) {
        setFvFIds.add(fvf.Id);
      }
    }
    if (!setFvFIds.isEmpty()) {
      processEmailSend(setFvFIds, true);
    }
  }

  /*******************************************************************************************************
    @ Method:   populateContactPerson
    @ Version:  1.0
    @ Author: 	Sovantheany Dim(sovantheany.dim@gaea-sys.com) 	
    @ Purpose:	US-0005905 FVF Contact Person
    @ AC2: 
    @ Given that I am Any User
    @ When I create a new FVF (Listing or Seller level) record type and do not populate Contact Person field
    @ Then Contact Person is automatically populated by the following contact person: 
    @ a) If exists then with the Seller. Contact where Decision maker role contains Final Value Fee
    @ b) if a does not exist then with the primary decision maker
    @
    @ 			EPH-7607 Add Contact information to FVF record
    @			Description : Automatically pre-populate Contact Person with the primary contact or DWH (if no primary) person related to the seller chosen in FVF record
	@ @ Event:  before Insert
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Final_Value_Fee_FVF__c> listFVF
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 11/02/2020 / sovantheany dim/ created the method
   	@ 					12/02/2020/ sovantheany dim / updated the method : move logic from Acmatac(EPH-7607) to this mothod together
    ************************************************************************************************************/
  public static void populateContactPerson(
    List<Final_Value_Fee_FVF__c> listFVF
  ) {
    RecordType fvfRecordTypeListing = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE
    );
    RecordType fvfRecordTypeSeller = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      EBH_ConstantsUtility.FVF_SELLER_RECORDTYPE
    );
    RecordType contacDW_RT = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
    set<String> sSeller = new Set<String>();
    for (Final_Value_Fee_FVF__c fvf : listFVF) {
      if (fvf.Seller_Name__c == null || fvf.Contact_Person__c != null)
        continue;
      sSeller.add(fvf.Seller_Name__c);
    }
    if (sSeller.isEmpty())
      return;

    Map<String, Contact> mapSellerFVFDecisioncontact = new Map<String, Contact>();
    Map<String, Contact> mapSellerPrimarycontact = new Map<String, Contact>();
    Map<String, Contact> mapSellerDWHcontact = new Map<String, Contact>();
    String sWhere = ' where AccountId IN: sSeller';
    for (
      Contact con : Database.query(EBH_ConstantsUtility.SOQL_CONTACT + sWhere)
    ) {
      //map seller with decision maker rule contact that contain Final Value Fee
      if (
        con.EBH_Decision_Maker_Role__c != null &&
        con.EBH_Decision_Maker_Role__c.contains(
          EBH_ConstantsUtility.FVF_DECISION_MAKER_ROLE
        )
      ) {
        mapSellerFVFDecisioncontact.put(con.AccountId, con);
      }
      //map seller with primary contact
      else if (con.Primary_Contact__c) {
        mapSellerPrimarycontact.put(con.AccountId, con);
      }
      //map seller with DWH contact
      else if (con.RecordTypeID == contacDW_RT.Id) {
        mapSellerDWHcontact.put(con.AccountId, con);
      }
    }

    for (Final_Value_Fee_FVF__c fvf : listFVF) {
      if (
        fvf.RecordTypeId == fvfRecordTypeListing.Id ||
        fvf.RecordTypeId == fvfRecordTypeSeller.Id
      ) {
        if (mapSellerFVFDecisioncontact.containsKey(fvf.Seller_Name__c)) {
          fvf.Contact_Person__c = mapSellerFVFDecisioncontact.get(
              fvf.Seller_Name__c
            )
            .Id;
          fvf.Seller_Email__c = mapSellerFVFDecisioncontact.get(
              fvf.Seller_Name__c
            )
            .Email;
        }
      }
      //EPH-7607 Add Contact information to FVF record
      if (fvf.Contact_Person__c == null) {
        //populate primary contact to contact person
        if (mapSellerPrimarycontact.containsKey(fvf.Seller_Name__c)) {
          fvf.Contact_Person__c = mapSellerPrimarycontact.get(
              fvf.Seller_Name__c
            )
            .Id;
          fvf.Seller_Email__c = mapSellerPrimarycontact.get(fvf.Seller_Name__c)
            .Email;
        }
        //populate DWH contact to contact person
        else if (mapSellerDWHcontact.containsKey(fvf.Seller_Name__c)) {
          fvf.Contact_Person__c = mapSellerDWHcontact.get(fvf.Seller_Name__c)
            .Id;
          fvf.Seller_Email__c = mapSellerDWHcontact.get(fvf.Seller_Name__c)
            .Email;
        }
      }
    }
  }

  /*******************************************************************************************************
    @ Method:   sumTotalListingNumberAndSeller
    @ Version:  1.0
    @ Author: 	Sreymeas Nao(sreymeas.nao@gaea-sys.com) 	
    @ Purpose:	US-0006963 FVF. Campaign
    @ AC1: Given that I am any User
	@ I am able to go to Final Value Fee object and create new FVF Campaign Record
	@ This record has fields attached in the layout
	@ @ Event:  After Insert, After Update
    @------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     List<Final_Value_Fee_FVF__c> listFVF,Map<Id,Final_Value_Fee_FVF__c> mapOldFVF
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 12/02/2020 / Sreymeas Nao/ created the method
	@				: 22/07/2024/ vadhanak voun/ US-0015373 - Align Apex Classes with Deactivated FVF_Campaign Record Type
	@				 						  / deactivate the method!
    ************************************************************************************************************/
  /**
	public static void sumTotalListingNumberAndSeller(List<Final_Value_Fee_FVF__c> listFVF,Map<Id,Final_Value_Fee_FVF__c> mapOldFVF){
		
		Boolean isInsert = mapOldFVF==null; //when insert mapOld doesn't have value
		Set<Id> fvfCampaignId = new Set<Id>();

		RecordType fvfRecordTypeListing = ApexUtil.getRecordTypeByName('Final_Value_Fee_FVF__c',EBH_ConstantsUtility.FVF_LISTING_RECORDTYPE);
		
		//sum number of listing from related fvf listing
		for(Final_Value_Fee_FVF__c onefvf : listFVF){
			if (onefvf.RecordTypeId == fvfRecordTypeListing.Id && onefvf.FVF_Campaign__c <> null) {
				if(isInsert || (!isInsert && onefvf.Total_Number_of_Listings__c <> mapOldFVF.get(onefvf.Id).Total_Number_of_Listings__c)) {
					 fvfCampaignId.add(onefvf.FVF_Campaign__c);
				}
			}
		}
		
		if(fvfCampaignId.isEmpty()) return;
		
		List<Final_Value_Fee_FVF__c> listFVFCampaignToUpdate = new List<Final_Value_Fee_FVF__c>(); 
		for(Aggregateresult arr : [select FVF_Campaign__c,count(Id) totalSeller, sum(Total_Number_of_Listings__c) totalListing From Final_Value_Fee_FVF__c Where FVF_Campaign__c IN :fvfCampaignId  Group By FVF_Campaign__c])
		{
			listFVFCampaignToUpdate.add(new Final_Value_Fee_FVF__c(
				Id= (Id)arr.get('FVF_Campaign__c'),
				Total_Number_of_Listings_fvfcampaign__c = (Decimal)arr.get('totalListing'), 
				Total_Number_of_Sellers__c = (Decimal)arr.get('totalSeller')
			));
		}
		
		//update parent FVF Campaign with aggregation of child listing
		if(!listFVFCampaignToUpdate.isEmpty())
		{
			update listFVFCampaignToUpdate;
		}
	}
	*/
  // AMT, [US-0007198] - [FVF] Attach Contracts
  private static Task createTaskLog_FVF(
    Final_Value_Fee_FVF__c fvf,
    String bodyText,
    Messaging.SingleEmailMessage mail,
    List<String> toUser
  ) {
    String fileName = '';
    String description;
    String recordTypeSeller = fvf.RecordType.DeveloperName;
    if (
      mail.getFileAttachments() != null && !mail.getFileAttachments().isEmpty()
    ) {
      for (Messaging.EmailFileAttachment fileAtt : mail.getFileAttachments()) {
        fileName += ' ' + fileAtt.filename + ',';
      }
      fileName = fileName.removeEnd(',');
    }

    // US-0007274 - FVF. save approval email on record
    if (mail.getCcAddresses() == null || fileName == null || toUser <> null) {
      description =
        'To: ' +
        String.join(toUser, ', ') +
        '\n' +
        'Subject: ' +
        mail.getSubject() +
        '\n' +
        'Body: \n' +
        bodyText;
    } else {
      description =
        'To: ' +
        String.join(mail.getToAddresses(), ', ') +
        '\n' +
        'CC: ' +
        String.join(mail.getCcAddresses(), ', ') +
        '\n' +
        'BCC: \n' +
        'Attachment:' +
        fileName +
        '\n\n' +
        'Subject: ' +
        mail.getSubject() +
        '\n' +
        'Body: \n' +
        bodyText;
    }

    Task t = new Task();
    t.Subject = 'Email: ' + mail.getSubject();
    t.WhatId = fvf.Id;
    t.Status = 'Completed';
    t.ActivityDate = System.today();
    t.Description = fvf.RecordType.DeveloperName ==
      EBH_ConstantsUtility.FVF_SELLER_RECORDTYPE
      ? ''
      : description; //LA:05/10/2020:US-0008188:don't show discription for FVF(Seller Level)
    t.IsVisibleInSelfService = false;
    t.TaskSubtype = 'Email';
    t.RecordTypeId = ApexUtil.getRecordTypeByName('Task', 'Standard_Task').Id;
    t.Log_Task__c = true;
    t.Task_Completed_Date__c = fvf.RecordType.DeveloperName !=
      EBH_ConstantsUtility.FVF_SELLER_RECORDTYPE
      ? null
      : System.today(); //LA:05/10/2020:US-0008188

    return t;
  }

  /*****************************************************************************************************************************
    @ Method	:   validateStagePermission
    @ Version	:   1.0
    @ Author	: 	LoumAng SENG (loumang.seng@gaea-sys.com)
    @ Purpose	:	US-0007322-Bug on FVF : User should not allowed to manually update FVF Stage
    @               Only user with Final Value Fee Approval permission can move stage to 'Send to ebay approver' or 'ebay approved'
    @ Trigger 	: 	before update
	@ Param 	: 	Map<Id, Final_Value_Fee_FVF__c> mOldFVF, List<Final_Value_Fee_FVF__c> lstFVF
    ------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 10.03.2020 / LoumAng SENG / Method Creation
	@				: 09.06.2023/ Sovantheany Dim / US-0013726 - Comment out validateStagePermission
    *****************************************************************************************************************************/
  /*
	public static void validateStagePermission(Map<Id, Final_Value_Fee_FVF__c> mOldFVF, List<Final_Value_Fee_FVF__c> lstFVF){
     	Boolean isAdmin = (Userinfo.getprofileId()==EBH_ConstantsUtility.ADMIN_PROFILE_ID);
     	//permission set to allow changing the stages
     	Boolean hasPermissionSet = ApexUtil.checkPermissionSet(new Set<String>{EBH_ConstantsUtility.PERMISSION_SET_FVFAPPROVAL});
     	if(isAdmin || hasPermissionSet) return;
		for(Final_Value_Fee_FVF__c fvf : lstFVF){
			if (fvf.Final_Value_Fee_Stage__c==EBH_ConstantsUtility.FVF_STAGE_EBAY_APPROVED && mOldFVF.get(fvf.Id).Final_Value_Fee_Stage__c == EBH_ConstantsUtility.FVF_STAGE_EBAY_SENT_TO_APPROVE) {
				fvf.addError(Label.Error_Validate_Stage);
			}	
         }
	 }*/

  /*****************************************************************************************************************************
    @ Method	:   validateEmptyNominatedItem
    @ Author	: 	Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose	:	US-0008752 - FVF listing Approval Migration - validation rules
    @               AC5: Nominated items must be attached before sending for approval
						Given that I am Any User
						When I try to move FVF (listing level) record to status "Sent to eBay Approver"
						and my record does not have any Nominated Items attached
						then I get error message:
						"Your Final Value Fee request does not have any Nominated Items (listings).
						Please make sure to upload Nominated Items with target price before submitting request for approval"
    @ Trigger 	: 	before update
	@ Param 	: 	Map<Id, Final_Value_Fee_FVF__c> mOldFVF, Map<Id, Final_Value_Fee_FVF__c> mNewFVF
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 19.01.2021 / Acmatac SEING / Method Creation
    *****************************************************************************************************************************/
  public static void validateEmptyNominatedItem(
    Map<Id, Final_Value_Fee_FVF__c> mOldFVF,
    Map<Id, Final_Value_Fee_FVF__c> mNewFVF
  ) {
    RecordType fvfRecordTypeListing = ApexUtil.getRecordTypeByName(
      'Final_Value_Fee_FVF__c',
      FVF_LISTING_RECORDTYPE
    );
    for (Final_Value_Fee_FVF__c fvf : mNewFVF.values()) {
      if (
        fvf.Final_Value_Fee_Stage__c !=
        mOldFVF.get(fvf.Id).Final_Value_Fee_Stage__c &&
        fvf.RecordTypeId == fvfRecordTypeListing.Id &&
        fvf.Final_Value_Fee_Stage__c == FVF_STAGE_EBAY_SENT_TO_APPROVE &&
        fvf.Total_Number_of_Listings__c == 0
      ) {
        fvf.addError(Label.Validate_Empty_NominatedItem_Error_Message);
      }
    }
  }
}