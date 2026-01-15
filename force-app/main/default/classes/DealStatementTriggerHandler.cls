/*********************************************************************************************************************************
@ Class:          DealStatementTriggerHandler
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Handler Class for DealStatementTrigger Trigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  05.05.2021 / Sophal Noch / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  11.10.2021 / Mony Nou / US-0010374 - [NA Deal Statement] Adjusted Statement Generation
                :  27.02.2021 / Loumang SENG / US-0012652 - [NA] PM Deal Statement Approval Process
                : 18.05.2023 / Sovantheany Dim / US-0013550 - 4. Deal Statement xl sheet is generated which can be shared with the Seller
*********************************************************************************************************************************/
public without sharing class DealStatementTriggerHandler {

    private static String PLV_1ST_STATEM = '1st Statement';
    private static String PLV_FINAL_STATEM = '2nd Statement';
    private static String PLV_ADJUS_STATEM = 'In Dispute'; //MN-11102021-US-0010374

    // private static String PLV_1ST_STATEM_SENTOUT = '1st Statement Sent Out';
    // private static String PLV_FINAL_STATEM_SENTOUT = 'Final Statement Sent Out';

    private static String FIRST_STATEM_FILENAME = '{0} - {1} {2} Deals Subsidy 1st Statement';
    private static String FINAL_STATEM_FILENAME = '{0} - {1} {2} Deals Subsidy Final Statement';
    private static String ADJUS_STATEM_FILENAME = '{0} - {1} {2} Deals Subsidy Adjusted Statement'; //MN-11102021-US-0010374

    

    // private static String PLV_1ST_STATEM_APPROVAL = 'In 1st Payout Approval';
    // private static String PLV_FINAL_STATEM_APPROVAL = 'In 2nd Payout Approval';

    private static String VF_DS_PAGE = 'DD_DealStatementSpreadsheet';

    // private static Integer CHUNK_SIZE_LIMIT = 25;
    private static final String FIRST_APPROVED_STATUS = '1st Payout Approved';
    private static final String FINAL_APPROVED_STATUS = '2nd Payout Approved';
    private static final String DISPUTE_APPROVED_STATUS = 'Dispute Payout Approved';
    private static final String IN_FIRST_APPROVED_STATUS = 'In 1st Payout Approval';
    private static final String IN_FINAL_APPROVED_STATUS = 'In 2nd Payout Approval';
    private static final String IN_DISPUTE_APPROVED_STATUS = 'In Dispute Payout Approval';
    private static final Id RECORDTYPE_PM_DEALS_ID = ApexUtil.getRecordTypeByName('Deal_Statement__c', 'Promotion_Manager_Deals').Id;
    private static final Id RECORDTYPE_EU_SUBSIDIZED_DEALS_ID = ApexUtil.getRecordTypeByName('Deal_Statement__c', 'EU_Subsidized_Deals').Id;
    public static final String TRIGGERCONTROLLER  = 'EBH Trigger Controller'; // custom setting
    /*****************************************************************************************************************************
    @ Method:       autoPopulatedFinalPayout
    @ Author:       Sovantheany Dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      US-0013550 - 4. Deal Statement xl sheet is generated which can be shared with the Seller
    @ Event:		before update , before Insert.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  25.05.2023 / Sovantheany Dim / US-0013550 Created the method.
    @*****************************************************************************************************************************/
    public static void autoPopulatedFinalPayout(List<Deal_Statement__c> listDs, Map<Id,Deal_Statement__c> mapOldDs){
        Boolean isNew = mapOldDs == null ? true : false;
        for(Deal_Statement__c ds : listDs){
            if((isNew && ds.Subsidy_Final_Calculation__c != null) || (!isNew && ds.Subsidy_Final_Calculation__c != mapOldDs.get(ds.Id).Subsidy_Final_Calculation__c)){
                ds.Second_Payout__c = (ds.Subsidy_Final_Calculation__c != null ? ds.Subsidy_Final_Calculation__c : 0) - (ds.Initial_Payout__c != null ? ds.Initial_Payout__c : 0);  // 26.05.2021 / Sophal Noch / US-0009562
            }
        }
    }

    /*****************************************************************************************************************************
    @ Method:       detectStatusChangedAndGenerateXsl
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-000942  - NA Deal Statements - Process fixes and updates
    @               Change Deal Statement Status and Generate Attachment
    @ Event:		before update.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  05.05.2021 / Sophal Noch / US-000942 Created the method.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  11.10.2021 / Mony Nou / US-0010374 - [NA Deal Statement] Adjusted Statement Generation
                    :  27.02.2021 / Loumang SENG / US-0012652 - [NA] PM Deal Statement Approval Process
                    : 18.05.2023 / Sovantheany Dim / US-0013550 - 4. Deal Statement xl sheet is generated which can be shared with the Seller
    @*****************************************************************************************************************************/
    public static void detectStatusChangedAndGenerateXsl(List<Deal_Statement__c> listDs, Map<Id,Deal_Statement__c> mapOldDs){

            List<Deal_Statement__c> list1stDs = new List<Deal_Statement__c>();
            List<Deal_Statement__c> listfinalDs = new List<Deal_Statement__c>();
            List<Deal_Statement__c> listadjusDs = new List<Deal_Statement__c>(); //MN-11102021-US-0010374

            Map<Id,Attachment> mapDsIdToAtt = new Map<Id,Attachment>();

            datetime currentTime  = System.now();

            for(Deal_Statement__c ds : listDs){
                //TH:US-0013550: move this block code to method "autoPopulatedFinalPayout"
                /*if(ds.Subsidy_Final_Calculation__c != mapOldDs.get(ds.Id).Subsidy_Final_Calculation__c){
                    ds.Second_Payout__c = (ds.Subsidy_Final_Calculation__c != null ? ds.Subsidy_Final_Calculation__c : 0) - (ds.Initial_Payout__c != null ? ds.Initial_Payout__c : 0);  // 26.05.2021 / Sophal Noch / US-0009562
                }*/
                
                if(ds.RecordTypeId == RECORDTYPE_PM_DEALS_ID){ //LA-27-02-2023-US-0012652: Don't generate the excel for promotion manager deals

                    if(ds.Status__c == PLV_FINAL_STATEM && ds.Status__c != mapOldDs.get(ds.Id).Status__c){
                        // set current date time to MostRecentFinalStatementDate__c field and update status to 'In 2nd Payout Approval', so exist flow can submit record for approval.
                        ds.MostRecentFinalStatementDate__c = currenttime;
                        ds.Status__c = IN_FINAL_APPROVED_STATUS;
                    }

                }else{ //END-LA-27-02-2023-US-0012652

                    String fileName = '.xls';
                    if(ds.Status__c == PLV_1ST_STATEM && ds.Status__c != mapOldDs.get(ds.Id).Status__c && ds.RecordTypeId != RECORDTYPE_EU_SUBSIDIZED_DEALS_ID ){//TH:US-0013550: IT not Generate Fist Statement
                        list1stDs.add(ds);
                        fileName = String.format(FIRST_STATEM_FILENAME, getFieldMatches(ds)) + fileName; // 11.06.2021 / Sophal Noch / US-0009686 change the name of first statement excel
                        mapDsIdToAtt.put( ds.Id, createXslFile(ds.Id,fileName) );
    
                    }else if(ds.Status__c == PLV_FINAL_STATEM && ds.Status__c != mapOldDs.get(ds.Id).Status__c){
                        listfinalDs.add(ds);
                        fileName = String.format(FINAL_STATEM_FILENAME, getFieldMatches(ds)) + fileName; // 11.06.2021 / Sophal Noch / US-0009686 change the name of final statement excel
                        mapDsIdToAtt.put( ds.Id, createXslFile(ds.Id,fileName) );
                    }
                    //MN-11102021-US-0010374
                    else if(ds.Status__c == PLV_ADJUS_STATEM && ds.Status__c != mapOldDs.get(ds.Id).Status__c && ds.RecordTypeId != RECORDTYPE_EU_SUBSIDIZED_DEALS_ID){ //TH:US-0013550: IT not Generate Dispute Statement
                        listadjusDs.add(ds);
                        fileName = String.format(ADJUS_STATEM_FILENAME, getFieldMatches(ds)) + fileName; 
                        mapDsIdToAtt.put( ds.Id, createXslFile(ds.Id,fileName) );
                    }

                }




            }
            if(!mapDsIdToAtt.isEmpty()){
                // 05.05.2021 / Sophal Noch / US-0009424 insert Attachment but the content is empty here.
                insert mapDsIdToAtt.values();


                if(!list1stDs.isEmpty()){
                    for(Deal_Statement__c ds : list1stDs){
                        ds.MostRecentFirstStatement__c = mapDsIdToAtt.get(ds.Id).Id; // 05.05.2021 / Sophal Noch / US-0009424 update attachment for first statement
                    }
                }
    
                if(!listfinalDs.isEmpty()){
                    for(Deal_Statement__c ds : listfinalDs){
                        ds.MostRecentFinalStatement__c = mapDsIdToAtt.get(ds.Id).Id; // 05.05.2021 / Sophal Noch / US-0009424 update content version for final statement
                    }
                }

                //MN-11102021-US-0010374
                if(!listadjusDs.isEmpty()){ 
                    for(Deal_Statement__c ds : listadjusDs){
                        ds.MostRecentAdjustStatement__c = mapDsIdToAtt.get(ds.Id).Id; 
                    }
                }

            }

    }

    /*****************************************************************************************************************************
    @ Method:       updateXslFromVF
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-000942  - NA Deal Statements - Process fixes and updates
    @               Change Deal Statement Status and Generate Attachment
    @ Event:		after update.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  06.05.2021 / Sophal Noch / US-000942 Created the method.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  11.10.2021 / Mony Nou / US-0010374 - [NA Deal Statement] Adjusted Statement Generation
                    :  27.02.2021 / Loumang SENG / US-0012652 - [NA] PM Deal Statement Approval Process
    @*****************************************************************************************************************************/
    public static void updateXslFromVF(List<Deal_Statement__c> listDs, Map<Id,Deal_Statement__c> mapOldDs){
        
        Map<Id,Id> mapDsIdToAttId = new Map<Id,Id>();

        // Set<String> criteriaStatus = new Set<String>{PLV_1ST_STATEM,PLV_FINAL_STATEM,PLV_1ST_STATEM_APPROVAL,PLV_FINAL_STATEM_APPROVAL};
        Set<String> criteriaStatus = new Set<String>{PLV_1ST_STATEM,PLV_FINAL_STATEM,PLV_ADJUS_STATEM} ; //MN-11102021-US-0010374 - Added status "Adjust Statement"
        
        for(Deal_Statement__c ds : listDs){

            if(ds.RecordTypeId == RECORDTYPE_PM_DEALS_ID ) continue; //LA-27-02-2023-US-0012652: Don't generate the excel for promotion manager deals
            
            if( criteriaStatus.contains(ds.Status__c)){
                if(ds.MostRecentFirstStatement__c != null && ds.MostRecentFirstStatement__c != mapOldDs.get(ds.Id).MostRecentFirstStatement__c){
                    mapDsIdToAttId.put(ds.Id,ds.MostRecentFirstStatement__c);
                }else if(ds.MostRecentFinalStatement__c != null && ds.MostRecentFinalStatement__c != mapOldDs.get(ds.Id).MostRecentFinalStatement__c){
                    mapDsIdToAttId.put(ds.Id,ds.MostRecentFinalStatement__c);
                }else if(ds.MostRecentAdjustStatement__c != null && ds.MostRecentAdjustStatement__c != mapOldDs.get(ds.Id).MostRecentAdjustStatement__c){ //MN-11102021-US-0010374 
                    mapDsIdToAttId.put(ds.Id,ds.MostRecentAdjustStatement__c);
                }
            }   

        }
        if(!mapDsIdToAttId.isEmpty()){
            // 05.05.2021 / Sophal Noch / US-0009424 update attachment content

            setupCache(mapDsIdToAttId.keySet());
            updateAttContent(mapDsIdToAttId.values(), mapDsIdToAttId.keySet());

            // (not used for now) split to chunck records to avoid memory limit error when generating xsl file on future method
            // Integer index = 0;
            // Map<Integer,Map<Id,Id>> mapIndexToDsMap = new  Map<Integer,Map<Id,Id>>();
            
            // for(Id dsId : mapDsIdToAttId.keySet()){

            //     if(!mapIndexToDsMap.containsKey(index)){
            //         mapIndexToDsMap.put(index, new Map<Id,Id>() );
            //     }

            //    if(mapIndexToDsMap.get(index).size() < CHUNK_SIZE_LIMIT){
            //         mapIndexToDsMap.get(index).put(dsId, mapDsIdToAttId.get(dsId));
            //    }
            //    if(mapIndexToDsMap.get(index).size() >= CHUNK_SIZE_LIMIT){
            //      index++;
            //    }
                
            // }

            // System.debug('nsp: index === '+index);
            // System.debug('nsp: mapDsIdToAttId === '+mapIndexToDsMap.size());

            // for(Integer chunkIndex : mapIndexToDsMap.keySet()){
            //     Map<Id,Id> mapIdToId = mapIndexToDsMap.get(chunkIndex);
            //     updateAttContent(mapIdToId.values(), mapIdToId.keySet());
            // }   


            
        }

    }

    private static void setupCache(Set<Id> setDsId){
        // these cache will be used in vf page.


        // 20.05.2021 / Sophal Noch / US-0009544 store cache by deal statement id
        for(Deal_Statement__c ds : DD_DealStatementSpreadsheetController.queryDealStatement(setDsId).values()){
            Cache.Org.put(DD_DealStatementSpreadsheetController.DS_CACHE_KEY + ds.Id, ds,300);
        }
        // 20.05.2021 / Sophal Noch / US-0009544 store deal list cache by deal statement id
        Map<Id,List<EBH_Deal__c>> mapCacheDsToListDeal = DD_DealStatementSpreadsheetController.queryDealByDsId(setDsId);
        for(Id dsId : mapCacheDsToListDeal.keySet()){
            Cache.Org.put(DD_DealStatementSpreadsheetController.DEALS_CACHE_KEY + dsId, mapCacheDsToListDeal.get(dsId),300);
        }

    }




    private static Attachment createXslFile(Id dsId,String fileName){
        // 05.05.2021 / Sophal Noch / US-0009424 generate default attachment.

        Blob xlsContent = !Test.isRunningTest() ? Blob.valueOf('') : Blob.valueOf('test');
        Attachment attachment = new Attachment();
        attachment.Body = xlsContent;
        attachment.Name = fileName;
        attachment.ParentId = dsId; 
        return attachment;

    }
    //NK:27/09/2022/US-0012661
    @Future(callout=true)
    private static void updateAttContentFuture(List<Id> setAttId, Set<Id> setDsId)
    {
        doUpdateAttContent(setAttId,setDsId);
    }
    //NK:27/09/2022/US-0012661
    private static void doUpdateAttContent(List<Id> setAttId, Set<Id> setDsId)
    {
        // 05.05.2021 / Sophal Noch / US-0009424 content is from vf page
        List<Attachment> listAtt = [Select Id, Name, ParentId From Attachment Where Id IN: setAttId And ParentId In : setDsId];
        if(!listAtt.isEmpty())
        {

            datetime currenttime  = System.now();
            List<Deal_Statement__c> listDsToUpdate = new List<Deal_Statement__c>();

            
            for(Attachment att : listAtt){

                // System.debug('nsp: att.ParentId == '+att.ParentId);

                PageReference xlsGenerater = new PageReference('/apex/'+VF_DS_PAGE);

                xlsGenerater.getParameters().put('Id', att.ParentId);
                xlsGenerater.getParameters().put(DD_DealStatementSpreadsheetController.CACHE_PARAM, 'true'); // will use cache instead of dml in vf page
                
                Blob xlsContent = !Test.isRunningTest() ? xlsGenerater.getContent() : Blob.valueOf('test');

                att.Body = xlsContent;
                

                listDsToUpdate.add(new Deal_Statement__c(Id=att.ParentId,MostRecentFirstStatementDate__c = currenttime, MostRecentFinalStatementDate__c = currenttime, MostRecentAdjustStatementDate__c = currenttime)); //MN-11102021-US-0010374 - Added MostRecentAdjustStatementDate__c
                
            }
            if(!listDsToUpdate.isEmpty()){
                update listAtt;
                listAtt.clear(); // to reduce memory consumption after xsl files are updated.

                update listDsToUpdate; // to trigger processs builder to submit for approval

                for(Id dsId: setDsId){
                    Cache.Org.remove(DD_DealStatementSpreadsheetController.DS_CACHE_KEY + dsId);
                    Cache.Org.remove(DD_DealStatementSpreadsheetController.DEALS_CACHE_KEY + dsId);
                }

            }

            
           
        }

    }
  //NK:27/09/2022/US-0012661
   private static void updateAttContent(List<Id> setAttId, Set<Id> setDsId){
        
        if(Test.isRunningTest())
        {
            doUpdateAttContent(setAttId,setDsId);
        }else
        {
            updateAttContentFuture(setAttId,setDsId);
        }
   }

   private static String[] getFieldMatches(Deal_Statement__c ds){
    // 11.06.2021 / Sophal Noch / US-0009686 get field values to match excel filename format

    String month = String.isBlank(ds.Month__c) ? '0' : ds.Month__c;
    month = Decimal.valueOf(month) > 9 ? ds.Month__c : '0'+month;

    String year = ds.Year__c == null ? '0000': (''+Integer.valueOf(ds.Year__c));

    return new String[]{ds.eBaySeller_Name__c,month, year};
   }
   
   /*****************************************************************************************************************************
    @ Method:       updateDealStatementApprovalCheckbox
    @ Author:       sovantheany dim (sovantheany.dim@gaea-sys.com)
    @ Purpose:      US-0010376 - [NA Deal Statement] Monthly Statement Summary and Approval
    @               AC2) Update Deal Statement Approval process to execute field update to new fields in AC1 based on if 1st, Final or Adjusted Statements are Approved.
    @ Event:		before update.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  19.10.2021 / Sophal Noch / US-0010376 Created the method.
    @*****************************************************************************************************************************/
    public static void updateDealStatementApprovalCheckbox(List<Deal_Statement__c> listDs, Map<Id,Deal_Statement__c> mapOldDs){
    	for(Deal_Statement__c ds : listDs){
    		Deal_Statement__c old_ds = mapOldDs.get(ds.id);
			if(old_ds.Status__c == IN_FIRST_APPROVED_STATUS && ds.Status__c == FIRST_APPROVED_STATUS){
				ds.X1st_Statement_Approved__c = true;
			}else if(old_ds.Status__c == IN_FINAL_APPROVED_STATUS && ds.Status__c == FINAL_APPROVED_STATUS){
				ds.Final_Statement_Approved__c = true;
			}else if(old_ds.Status__c == IN_DISPUTE_APPROVED_STATUS && ds.Status__c == DISPUTE_APPROVED_STATUS){
				ds.Adjustment_Approved__c = true;
			}
    	}
    }
   
   
}