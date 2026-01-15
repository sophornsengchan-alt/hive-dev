/*********************************************************************************************************************************
@ Class:          DD_SendToSellerHelper
@ Version:        2.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Helper class for DD_SendToSellerController.cls
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  16.11.2020 / Sophal Noch / US-0008605 Update the class.
				:  17.03.2023 / Loumang SENG / US-0012803 - Deal Contract Agreement - Default to create PM Deals only
				: 07.02.2025 / vadhanak voun /US-0016747 - NA Seller Eligible validation error is fired for IT Deals
*********************************************************************************************************************************/
public without sharing class DD_SendToSellerHelper {

	private final static String ALG = 'hmacSHA1';
	private final static String SELLER_APPROVER_CONTACT = 'Contact';
	private static String DEAL_CONTRACT_SELLER_API_NAME = '{!EBH_Deal__c.Deal_Contract_Seller_Name__c}';
	private static String DEAL_SITE_URL_API_NAME = '{!EBH_Deal__c.SiteURL__c}';
	private static String DEAL_CURRENT_DIGEST_API_NAME = '{!EBH_Deal__c.Current_Digest__c}';
	private static String SELLER_APPROVER_API_NAME = '{!EBH_Deal__c.Seller_Approver_1__c}';
	private static String NA_DEALS_SEND_TO_SELLER_TEMPLATE =  'NA_Deals_Send_to_Seller';

	private static Seller_Approver_Setting__mdt sellerApproverSettingContact;
	private static Boolean isSandbox;
	
	/**
	*
	*/
	/*public static void sendEmail(List<ContractAgreementWrapper> dcas, List<EBH_Deal__c> deals,Boolean isBatch) {
		sendEmail( dcas, deals, isBatch, true);
	}*/
	
	/*public static void sendEmail(List<ContractAgreementWrapper> dcas, List<EBH_Deal__c> deals,Boolean isBatch, Boolean isDealUpdate) {
		if (dcas!=null) {
	    
	    	Set<String> sellersid = new Set<String>();
	    	Map<String,List<String>> contactemails = new Map<String,List<String>>();
	    	for (ContractAgreementWrapper ca : dcas) {
	    		sellersid.add(ca.seller);
	    		
	    		
	    		contactemails.put(ca.dca.Id, loadEmails(ca.approvers));
	    	}
	    	
	    	
		     // create 1 email per group of seller and send to all seller contacts
		    if (contactemails.keyset().isEmpty()) {
		 		throw new SendtoSellerException('No Contact Email Found');
		    }
		 	
		 	Set<String> sellersent = generateDealContractandSend(dcas,contactemails,sellersid,isBatch);
		    if (isDealUpdate) {
		    	updateDeals(deals, sellersent);
		    }
	            
	     }
	}*/
	
	/**
	* Convert List deals to List<ContractAgreementWrapper> for existing Contract Aggreement
	*/
	public static List<ContractAgreementWrapper> convertTContractAgreementWrapper(List<EBH_Deal__c> deals, List<EBH_Deal__c> listPrevDeal) {

		
		// List<ContractAgreementWrapper> cawFromPrev = new List<ContractAgreementWrapper>();
		// // Sophal:27/04/2021: US-0009436 for checking in pervious chunk Deal_Contract_Agreement__c with listPrevDeal

		// for(EBH_Deal__c eachDeal : listPrevDeal){
		// 	groupDealContract(cawFromPrev, eachDeal, null);
		// }
		

		List<ContractAgreementWrapper> caw = new List<ContractAgreementWrapper>();


        for (EBH_Deal__c d : deals) {
            
        //   groupDealContract(caw, d, cawFromPrev); Sophal:29/04/2021: US-0009476 no need to check previous deal for already 'sent to seller' deals
			groupDealContract(caw, d, null);
            
		}

        
             // generate digest for the Deal_Contract_Agreement__c
             // dont regenerate digest ?
         List<Deal_Contract_Agreement__c> dcatobeupdated = new List<Deal_Contract_Agreement__c>();
          for (ContractAgreementWrapper ca :caw) {            	
            	


			
            	Deal_Contract_Agreement__c  dca = ca.dca;
            	
            	if (String.isBlank(dca.Current_Digest__c)) {

	            	String data = dca.Id; // we can append timestamp  - so we can give access to teh contract few minutes, after it is exprired.
	            	String key = UserInfo.getUserId();
	            	dca.Current_Digest__c = ApexUtil.doEncrypt(data, key.substring(0,16));
	            	
	            	dcatobeupdated.add(dca);
            	}
            }
            
            update dcatobeupdated;
            
        return caw;
		
	}
	
	/**
	Currently Deal Contract Agreement is created just based on Seller and Deal Status. Logic needs to be introduced to group Deal Contract Agreement creation based upon who is populated in Seller Approver fields. 
	Grouping would be made by combination of Seller Approver Ids. Uniqueness would be Seller Id + Seller Approvers
	
	*/
	
	public static void groupDealContract(List<ContractAgreementWrapper> cas, EBH_Deal__c c, List<ContractAgreementWrapper> prevCas) {
		Set<String> approvers = new Set<String>();
		if (c.Seller_Approver_1__c!=null) approvers.add(c.Seller_Approver_1__c);
		if (c.Seller_Approver_2__c!=null) approvers.add(c.Seller_Approver_2__c);
		if (c.Seller_Approver_3__c!=null) approvers.add(c.Seller_Approver_3__c);
		if (c.Seller_Approver_4__c!=null) approvers.add(c.Seller_Approver_4__c);
		if (c.Seller_Approver_5__c!=null) approvers.add(c.Seller_Approver_5__c);
            
		for (ContractAgreementWrapper ca : cas) {
            
             
            if (c.EBH_BusinessName__c==ca.Seller & ca.approvers.containsAll(approvers)) {
             	ca.deals.add(c);
            	return ;
            }
		}
		
		// not found
		ContractAgreementWrapper ret = new ContractAgreementWrapper();
		ret.approvers = approvers;
        ret.seller = c.EBH_BusinessName__c ;
        ret.dca = new Deal_Contract_Agreement__c();
		ret.dca.RecordtypeId = ApexUtil.getRecordTypeByName('Deal_Contract_Agreement__c','Subsidized_Deals').Id;//LA-17-03-2023-US-0012803
        ret.deals.add(c);
		if (c.Deal_Contract_Agreement__c!=null) {
        	ret.dca.Id = c.Deal_Contract_Agreement__c;
        }else if(prevCas != null && !prevCas.isEmpty()){  // Sophal:27/04/2021: US-0009436 for checking in pervious chunk

			for (ContractAgreementWrapper prevCa : prevCas) {

				if(
					prevCa.dca.Id != null
					&& prevCa.seller == ret.seller 
					&& prevCa.approvers.containsAll(ret.approvers)
				){
					ret.dca.Id = prevCa.dca.Id;

					break;
				}
				
			}
			
		}
		
		cas.add(ret);
	
		
	}

	/*****************************************************************************************************************************************************************
    @ Method:         sendApprovalToExternalSeller
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008605
    @                 Seller Approver for an NA Deal Want to...
	@				  have my email address saved to the Deal record which I approve or reject
	@				  So that my email address can be used to trace who from my company has approved or rejected the Deal
	@				  Description
	@				  Summary: Capture the Seller Approver's email address on Deal record on Approval or Rejection
	@				  AC 1)
	@ 				  When a Seller Approver approves or rejects an NA Deal, their email address is updated on the Deal record for the field 'Seller Email'
    @ Event:          It is called from Process Builder 'Deal Status Changed',
    @                 When Deal is upated and Its status = 'Sent to Seller'
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.11.2020 / Sophal Noch / Created the method.
    ***********************************************************************************************************************************************************/
    @InvocableMethod
	public static void sendApprovalToExternalSeller(List<EBH_Deal__c> listDeal){

		// US-0008605 call from process builder 'Deal Status Changed'.
		// it was orignally a workflow named 'Send_Approval_To_External_Seller' but workflow feature lacks feature for story requirement.

		List<EBH_Deal__c> listEmailingDeal = new List<EBH_Deal__c>();
		Set<Id> setDcgId = new Set<Id>();
		Map<Id, EBH_Deal__c> mapDealContract = new Map<Id,EBH_Deal__c>();

		for(EBH_Deal__c deal : listDeal){
			if(deal.Deal_Contract_Agreement__c != null){
				listEmailingDeal.add(deal);
				setDcgId.add(deal.Deal_Contract_Agreement__c);
				//TH: 07/04/2021:Map contract with deal, US-0009308 - [NA] Send 1 approval email per Deals Group to Seller
				mapDealContract.put(deal.Deal_Contract_Agreement__c,deal);
			}
		}

		Map<Id,Deal_Contract_Agreement__c> mapDcg;

		if(!setDcgId.isEmpty()){
			mapDcg = new Map<Id,Deal_Contract_Agreement__c>([Select Id, Current_Digest__c From Deal_Contract_Agreement__c Where Id IN : setDcgId]);
		}

		if(mapDcg != null && !mapDcg.isEmpty()){
			
			Set<Id> sDealContractAgreement = new Set<Id>();
			List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
			//TH: 07/04/2021 : US-0009308 : replace listEmailingDeal to mapDealContract.values()
			//for(EBH_Deal__c deal : listEmailingDeal){
			for(EBH_Deal__c deal : mapDealContract.values()){
				
				Set<Id> setContactId = new Set<Id>();
				// US-0008605 for seller approver 1,2,3,4,5
				generateSellerApprovalEmail(deal, mapDcg, deal.Seller_Approver_1__c, deal.Seller_Approver_1_Email__c, setContactId, emails);
				generateSellerApprovalEmail(deal, mapDcg, deal.Seller_Approver_2__c, deal.Seller_Approver_2_Email__c, setContactId, emails);
				generateSellerApprovalEmail(deal, mapDcg, deal.Seller_Approver_3__c, deal.Seller_Approver_3_Email__c, setContactId, emails);
				generateSellerApprovalEmail(deal, mapDcg, deal.Seller_Approver_4__c, deal.Seller_Approver_4_Email__c, setContactId, emails);
				generateSellerApprovalEmail(deal, mapDcg, deal.Seller_Approver_5__c, deal.Seller_Approver_5_Email__c, setContactId, emails);
			}
	
			if (!emails.isEmpty() && !Test.isRunningTest()) { ApexUtil.sendEmail(emails); }
		
		
		}
		

	}

	private static void generateSellerApprovalEmail(EBH_Deal__c deal,  Map<Id,Deal_Contract_Agreement__c> mapDcg, String contactId, String email, Set<Id> setContactId, List<Messaging.SingleEmailMessage> emails){

		
		if(
			contactId != null 
			&& String.isNotBlank(email) 
			&& !setContactId.contains(contactId)
			&& mapDcg.containsKey(deal.Deal_Contract_Agreement__c)
		){
			
			String currentDealDigest = deal.Current_Digest__c; // must not use this for encrypting with approver seller email because sometimes this formula field give different value from original Deal_Contract_Agreement__c.Current_Digest__c
			String currentDcgDigest = mapDcg.get(deal.Deal_Contract_Agreement__c).Current_Digest__c;

			Map<String,String> binding = new Map<String,String>();
			binding.put(DEAL_CONTRACT_SELLER_API_NAME, (String.isNotBlank(deal.Deal_Contract_Seller_Name__c) ? deal.Deal_Contract_Seller_Name__c : '' ));
			binding.put(DEAL_SITE_URL_API_NAME, deal.SiteURL__c);
			binding.put(DEAL_CURRENT_DIGEST_API_NAME, currentDealDigest);

			// US-0008605 this token will be used to identify which email is the approver when he/she approve or reject agreement from his/her email.
			String token = generateSellerApproverToken(currentDcgDigest + email); // US-0008605 encrypting Deal_Contract_Agreement__c.currentDcgDigest with seller approver email
			
			binding.put(SELLER_APPROVER_API_NAME, token);
			emails.add(ApexUtil.prepareEmail(null, new String[] {email}, null, NA_DEALS_SEND_TO_SELLER_TEMPLATE, null, binding, null, null));
			
			// US-0008605 setContactId is used to skip generating email for contact that has already has its generated email per deal.
			setContactId.add(contactId);
		}
			


	}

	/*****************************************************************************************************************************************************************
    @ Method:         generateSellerApproverToken
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008605 generate token for identifying seller approver when approver approve or reject agreement.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.11.2020 / Sophal Noch / Created the method.
    ***********************************************************************************************************************************************************/
	public static String generateSellerApproverToken(String body){
		String secretKey = getSellerApproverSecretKey();
		Blob hmac = Crypto.generateMac(ALG, Blob.valueOf(body), Blob.valueOf(secretKey));
		String token = EncodingUtil.convertToHex(hmac);
		return token;
	}

	private static String getSellerApproverSecretKey(){


		if(sellerApproverSettingContact == null){
			sellerApproverSettingContact = [SELECT Production_Secret_Key__c, Sandbox_Secret_Key__c From Seller_Approver_Setting__mdt where DeveloperName =: SELLER_APPROVER_CONTACT LIMIT 1];
		}
		// System.debug('nsp: isSandbox is = '+isSandbox);
		if(isSandbox == null){
			isSandbox = ApexUtil.runningInASandbox();
		}

		return isSandbox ? sellerApproverSettingContact.Sandbox_Secret_Key__c : sellerApproverSettingContact.Production_Secret_Key__c;

	}
	
	public static List<ContractAgreementWrapper> createDealContractAgreement(List<EBH_Deal__c> deals, List<EBH_Deal__c> listPrevDeal) {
		return doCreateDealContractAgreement(deals,listPrevDeal,null);
		
	}
	public static List<ContractAgreementWrapper> createDealContractAgreement(List<EBH_Deal__c> deals, List<EBH_Deal__c> listPrevDeal,String dcaSite) {
		return doCreateDealContractAgreement(deals,listPrevDeal,dcaSite);
	}
	//: 07.02.2025 / vadhanak voun /US-0016747 - NA Seller Eligible validation error is fired for IT Deals
	private static List<ContractAgreementWrapper> doCreateDealContractAgreement(List<EBH_Deal__c> deals, List<EBH_Deal__c> listPrevDeal,String dcaSite) {
			// Sophal:27/04/2021: US-0009436 for checking in pervious chunk Deal_Contract_Agreement__c with listPrevDeal

			List<ContractAgreementWrapper> cawFromPrev = new List<ContractAgreementWrapper>();
			for(EBH_Deal__c eachDeal : listPrevDeal){
				groupDealContract(cawFromPrev, eachDeal, null);
			}


							
			List<ContractAgreementWrapper> caw = new List<ContractAgreementWrapper>();
					
			// first create the agreement
			// some may have some agreement but not sent ?
			for (EBH_Deal__c d : deals) {
				
			groupDealContract(caw, d, cawFromPrev);
				
			}


			// insert agreement 
			if (!caw.isEmpty()) {
				
				List<Deal_Contract_Agreement__c> dcas = new List<Deal_Contract_Agreement__c>();
				for (ContractAgreementWrapper ca : caw) {
					if(dcaSite != null && dcaSite == 'IT'){// SRONG TIN - 15.05.2023 - US-0013428
						ca.dca.eBay_Seller__c = ca.seller;
						ca.dca.Deal_Site__c = '101';	//NK:07/02/2025:US-0016747. 101 is IT site
					}
					
					dcas.add(ca.dca);
				}
				
				upsert dcas;

				// generate digest for the Deal_Contract_Agreement__c
				// dont regenerate digest ?
				List<Deal_Contract_Agreement__c> dcatobeupdated = new List<Deal_Contract_Agreement__c>();
				for (Deal_Contract_Agreement__c dca : dcas) {            	
					
					if (String.isBlank(dca.Current_Digest__c)) {
						String data = dca.Id; // we can append timestamp  - so we can give access to teh contract few minutes, after it is exprired.
						String key = UserInfo.getUserId();
						dca.Current_Digest__c = ApexUtil.doEncrypt(data, key.substring(0,16));
						
						dcatobeupdated.add(dca);
					}
				}
				
				update dcatobeupdated;
				
				// now link the Deal__c
				List<EBH_Deal__c> dealstoupdate = new List<EBH_Deal__c>();
				for (ContractAgreementWrapper ca : caw) {
				
					Deal_Contract_Agreement__c dca = ca.dca;
					
					for(EBH_Deal__c dd : ca.deals) {
						dd.Deal_Contract_Agreement__c = dca.Id;
						dealstoupdate.add(dd);
					}
					
				}
					update dealstoupdate;
			}

			return caw;
	}
	
	public static Boolean checkExpiredDeal(EBH_Deal__c deal, Datetime currentDateTime) {
		// 28.05.2021 / Sophal Noch / US-0009533 
		return (deal.EBH_DealStartDate__c < currentDateTime.dateGMT() || (deal.EBH_DealStartDate__c == currentDateTime.dateGMT() && deal.EBH_DealStartTime__c < currentDateTime.timeGMT()));
	}
    
    
     // update deals to 'Sent to Seller'     
    /*public static void updateDeals(List<EBH_Deal__c> deals, Set<String> sellersent) {
    	 
    	 if (!sellersent.isEmpty()) {
         
          	List<EBH_Deal__c> dealstobeupdated = new List<EBH_Deal__c>();
             for (EBH_Deal__c d : deals) {
             	if (sellersent.contains(d.EBH_BusinessName__c)) {
             		d.EBH_Status__c='Sent to Seller';
                	dealstobeupdated.add(d);
             	}
              }
                    
             if (!dealstobeupdated.isEmpty()) {
                 update dealstobeupdated;
              }
                
          }
    }*/
    
    /*public static Set<String> generateDealContractandSend(List<ContractAgreementWrapper> dcas,Map<String,List<String>> contactemails, Set<String> sellersid, Boolean isBatch) {
     		Set<String> sellersent = new Set<String>();
            String templatename = 'NA_Deals_Send_to_Seller';
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            
            Map<Id,Account> sellers  = new Map<Id,Account>([Select id, Name from Account where id in : sellersid]);
			OrgWideEmailAddress owa = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName =: SYSTEM.LABEL.Org_wide_address_noreplySFCD LIMIT 1];
		
            for (ContractAgreementWrapper ca :  dcas) {
                
                Deal_Contract_Agreement__c dca = ca.dca;
                String sellerid = ca.seller;
                List<String> emailtosend = contactemails.get(dca.Id);
               	String sendFromName = loadDealOwner(ca);
               
                Account eseller = sellers.get(sellerid);
                                
                Map<String,String> binding = new Map<String,String>();
				binding.put('{!Deal_Contract_Agreement__c.Seller_Name__c}',eseller.Name);
				binding.put('{!Deal_Contract_Agreement__c.Current_Digest__c}',EncodingUtil.urlEncode(dca.Current_Digest__c, 'UTF-8'));
				binding.put('{!Site.Url}',ApexUtil.getSiteUrl('Deal_Acceptance'));
              	
              	
              		
                // if email ok - then update status Deal to 'Sent to Seller'
                	//if(isBatch) emails.add(ApexUtil.prepareEmail(null,emailtosend, null,templatename,templatename,binding,null,owa));
               	//else emails.add(ApexUtil.prepareEmail(null,emailtosend, null,templatename,templatename,binding,sendFromName,null));
               	//emails.add(DD_Utils.prepareEmail(null,emailtosend, null,templatename,templatename,binding));
				emails.add(ApexUtil.prepareEmail(null,emailtosend, null,templatename,templatename,binding,null,owa));
                sellersent.add(sellerid);
                 
            
            } // end loop
		
			/*if (!emails.isEmpty()) {
				ApexUtil.sendEmail(emails);
			}*/
            
            /*return sellersent;
    }*/
    
    /*public static List<String> loadEmails(Set<String> approvers) {
    		Set<String> emails = new Set<String>();
        for (Contact c : [Select Name, c.Email From Contact c Where Id in: approvers]) {
                        
            if (String.isNotBlank(c.Email)) {
                emails.add(c.Email);
            }else{
            		throw new SendtoSellerException('No Email Found in the following Contact : '+c.Name);
            }
                                        
            }
     	return new List<String>(emails);   
    }*/
    
    /*public static String loadDealOwner(ContractAgreementWrapper ca){
    		Set<String> sOwnderName = new Set<String>();
    		for(EBH_Deal__c deal : ca.deals){
    			sOwnderName.add(deal.Owner.Name);
    		}
    		String ownderName = sOwnderName.isEmpty()?'':String.join(new List<String>(sOwnderName),',');
    		return ownderName;
    }*/
    
    public class ContractAgreementWrapper {
    
    	public Deal_Contract_Agreement__c dca;
    	public List<EBH_Deal__c> deals = new List<EBH_Deal__c>();
    	public Set<String> approvers;
    	public String seller;
    
    }
    
    public class SendtoSellerException extends Exception {}
    
 
            
}