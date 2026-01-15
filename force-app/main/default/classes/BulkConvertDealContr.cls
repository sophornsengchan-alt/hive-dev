/*********************************************************************************************************************************
@ Class:         BulkConvertDealContr clone from ProTrader_HomeController
@ Version:       2.0
@ Author:        Acmatac SEING (acmatac.seing@gaea-sys.com)
@ Purpose:       US-0013346 Bulk Convert the Unsub Deals to Sub Deals
@                Controller for aura: BulkConvertDeal.cmp    
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  	02.05.2023 / Acmatac Seing / US-0013346 - Created the class
@               :   06.06.2023 / Sovantheany Dim / US-0013751 - Issue Fixes on Deal Window Bulk Subsidize Deals
@               :   30.06.2023 / SRONG TIN / US-0013796 - Sub Category field Type needs to be changed to Text from Picklist
@               :   20.09.2023 / Mony Nou / US-0014129 - Bulk Subsidize Deals - Page need an Additional Column
@               :   26.01.2024 / Sambath Seng / US-0014482 - IT region: Subsidized deals: Enrich data set on Bulk Subsidize Deals window to include total sum of 'subsidy per sold line item', 'total planned gross' and 'seller comments'
@               :   24.01.2024 / Sovantheany Dim / US-0016410 - 5 - Bulk Subsidize Deals - Using the Bulk Subsidized Deals Button
*********************************************************************************************************************************/
public with sharing class BulkConvertDealContr {

    private final static Id dealRecordTypeV3 = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V3').Id;

    private final static List<Object> FIELD_LIST_DRC = new List<Object>{
        new Map<String,String>{'label'=>'WOW! Deal ID','api'=>'Name','type'=>'name','edit'=>'no'},
        new Map<String,String>{'label'=>'eBay Seller','api'=>'EBH_BusinessName__c','type'=>'lookup', 'edit'=>'no', 'lookupname'=>'EBH_BusinessName__r.Name'},
        new Map<String,String>{'label'=>'Product Title','api'=>'EBH_ProductTitle__c','type'=>'text','edit'=>'no'},
        new Map<String,String>{'label'=>'Item ID','api'=>'EBH_eBayItemID__c','type'=>'text','edit'=>'no'},//TH: US-0013751 : add eBay Item ID
        new Map<String,String>{'label'=>'Vertical','api'=>'EBH_Vertical__c','type'=>'picklist','edit'=>'no'},//TH: US-0013751 : add Column Vertical
        new Map<String,String>{'label'=>'Category','api'=>'EBH_Category__c','type'=>'picklist','edit'=>'no'},//TH: US-0013751 : add column Category
        new Map<String,String>{'label'=>'Sub Category','api'=>'Sub_Category__c','type'=>'text','edit'=>'no'},//30.06.2023/SRONG TIN/US-0013796 | //TH: US-0013751 : add column Sub Category
        new Map<String,String>{'label'=>'Comment from Seller','api'=>'EBH_CommentfromSeller__c','type'=>'text','edit'=>'no'},//SB 26.1.2024 US-0014482
        new Map<String,String>{'label'=>'Quantity','api'=>'EBH_Quantity__c','type'=>'integer','edit'=>'yes'},
        new Map<String,String>{'label'=>'Seller Price','api'=>'EBH_SellerPrice__c','type'=>'number','edit'=>'no'},
        new Map<String,String>{'label'=>'Deal Price','api'=>'EBH_DealPrice__c','type'=>'number','edit'=>'yes'},
        new Map<String,String>{'label'=>'Subsidy per Sold Item','api'=>'EBH_Subsidy__c','type'=>'number','edit'=>'no'},
        new Map<String,String>{'label'=>'Subsidy Planned Gross','api'=>'Subsidy_Planned_Gross__c','type'=>'number','edit'=>'no'}, //MN-20092023-US-0014129
        new Map<String,String>{'label'=>'Deal Format','api'=>'EBH_DealFormat__c','type'=>'picklist','edit'=>'yes'},
        new Map<String,String>{'label'=>'Spotlight Category','api'=>'EBH_SpotlightCategory__c','type'=>'lookup','edit'=>'no', 'lookupname'=>'EBH_SpotlightCategory__r.Name'},
        new Map<String,String>{'label'=>'Deal Start Date','api'=>'EBH_DealStartDate__c','type'=>'date','edit'=>'yes'},
        new Map<String,String>{'label'=>'Deal Start Time','api'=>'EBH_DealStartTime__c','type'=>'time','edit'=>'yes'},
        new Map<String,String>{'label'=>'Deal End Date','api'=>'EBH_DealEndDate__c','type'=>'date','edit'=>'yes'},
        new Map<String,String>{'label'=>'Deal End Time','api'=>'EBH_DealEndTime__c','type'=>'time','edit'=>'yes'}
    };

    //TH:US-0016410 : Field mapping for DCA
    private final static List<Object> FIELD_LIST_DCA = new List<Object>{
        new Map<String,String>{'label'=>'WOW! Deal ID','api'=>'Name','type'=>'name','edit'=>'no'},
        new Map<String,String>{'label'=>'Product Title','api'=>'EBH_ProductTitle__c','type'=>'text','edit'=>'no'},
        new Map<String,String>{'label'=>'eBay ItemID','api'=>'EBH_eBayItemID__c','type'=>'text','edit'=>'no'},
        new Map<String,String>{'label'=>'Seller Price','api'=>'EBH_SellerPrice__c','type'=>'number','edit'=>'yes'},
        new Map<String,String>{'label'=>'Deal Price','api'=>'EBH_DealPrice__c','type'=>'number','edit'=>'yes'},
        new Map<String,String>{'label'=>'Subsidy per Sold Item','api'=>'EBH_Subsidy__c','type'=>'number','edit'=>'no'},
        new Map<String,String>{'label'=>'Subsidy Planned Gross','api'=>'Subsidy_Planned_Gross__c','type'=>'number','edit'=>'no'},
        new Map<String,String>{'label'=>'Sub Ratio','api'=>'Sub_Ratio__c','type'=>'number','edit'=>'no'},
        new Map<String,String>{'label'=>'Quantity','api'=>'EBH_Quantity__c','type'=>'integer','edit'=>'yes'},
        new Map<String,String>{'label'=>'Maximum Purchase','api'=>'EBH_MaximumPurchases__c','type'=>'integer','edit'=>'yes'},
        new Map<String,String>{'label'=>'Deal Start Date','api'=>'EBH_DealStartDate__c','type'=>'date','edit'=>'yes'},
        new Map<String,String>{'label'=>'Deal Start Time','api'=>'EBH_DealStartTime__c','type'=>'time','edit'=>'yes'},
        new Map<String,String>{'label'=>'Deal End Date','api'=>'EBH_DealEndDate__c','type'=>'date','edit'=>'yes'},
        new Map<String,String>{'label'=>'Deal End Time','api'=>'EBH_DealEndTime__c','type'=>'time','edit'=>'yes'}
    };
    private final static Set<String> SET_STATUS = new Set<String>{'New','Internally Rejected'};
    private final static String DCA_SOBJECT_NAME = 'Deal_Contract_Agreement__c';
    //End:US-0016410

    @AuraEnabled
    public static Map<String,Object> apexInitRecordList(String selectedIds,Id parentId)
    {       
        String bindingIdsStr = ApexUtil.constructQuoteString((selectedIds.deleteWhitespace()).split(','));
        Map<String, Object> pklMap = new Map<String, Object>{
            'EBH_DealFormat__c'=> new List<Object> {
                new Map<String,String>{'label'=>'','value'=>null},
                new Map<String,String>{'label'=>'Primary','value'=>'Primary'},
                new Map<String,String>{'label'=>'Featured','value'=>'Featured'},
                new Map<String,String>{'label'=>'Core','value'=>'Core'},
                new Map<String,String>{'label'=>'Deal','value'=>'Deal'}
            }
            
        };

        List<Object> fieldList = FIELD_LIST_DRC;

        //String shortQuery = 'SELECT Id FROM EBH_Deal__c'; // reduce cpu amount
        //TH:US-0013751:add EBH_DealPrice__c, and EBH_SellerPrice__c to check when convert
        String shortQuery = 'SELECT Id,EBH_DealPrice__c,EBH_SellerPrice__c FROM EBH_Deal__c';
        //MN-20092023-US-0014129: Added Subsidy_Planned_Gross__c to below query
        //SB 26.1.2024 US-0014482 added EBH_CommentfromSeller__c to below query
        String baseQuery = 'SELECT Id, Name, EBH_BusinessName__r.Id, EBH_BusinessName__r.Name, EBH_ProductTitle__c, EBH_Quantity__c, EBH_SellerPrice__c, EBH_Subsidy__c,  Subsidy_Planned_Gross__c, EBH_DealPrice__c, EBH_DealFormat__c, EBH_SpotlightCategory__r.Id, EBH_SpotlightCategory__r.Name, EBH_DealStartDate__c, EBH_DealStartTime__c, EBH_DealEndDate__c, EBH_DealEndTime__c,EBH_Vertical__c,EBH_Category__c,EBH_eBayItemID__c,Sub_Category__c,EBH_CommentfromSeller__c  FROM EBH_Deal__c';
        String soqlWhere = ' WHERE Id IN('+bindingIdsStr+') AND RecordTypeId='+ApexUtil.constructQuoteString(new Set<String>{dealRecordTypeV3});
        //Set<Id> legitRecordIds = (new Map<Id, sObject>(Database.query(shortQuery+soqlWhere))).keySet();

        //TH:US-0016410 : BulkSubsidizeDeal For DCA
        String msgInfo = System.label.BulkSubsidizeMsg;
        Boolean isDCA = false;
        if(String.isNotBlank(parentId)){
            String sObjectName = parentId.getSObjectType().getDescribe().getName();
            if(sObjectName.equalsIgnoreCase(DCA_SOBJECT_NAME)){
                msgInfo = System.label.BulkSubsidizeMsg_DCA;
                isDCA = true;
                String bindingStatus = ApexUtil.constructQuoteString(SET_STATUS);
                fieldList = FIELD_LIST_DCA;
                baseQuery = 'SELECT Id, Name, EBH_ProductTitle__c, EBH_Quantity__c, EBH_SellerPrice__c, EBH_Subsidy__c,Subsidy_Planned_Gross__c ,Sub_Ratio__c, EBH_MaximumPurchases__c, EBH_DealPrice__c, EBH_DealStartDate__c, EBH_DealStartTime__c, EBH_DealEndDate__c, EBH_DealEndTime__c,EBH_Vertical__c,EBH_Category__c,EBH_eBayItemID__c  FROM EBH_Deal__c';
                soqlWhere = ' WHERE Id IN('+bindingIdsStr+') AND EBH_Status__c IN ('+bindingStatus+')';
            }
        }
        //END:US-0016410
        //Map<Id, sObject> mapLegitRecords = new Map<Id, sObject> (Database.query(shortQuery+soqlWhere));
        Map<Id, sObject> mapLegitRecords = new Map<Id, sObject> (ApexSafe.query().secCheck(false).doQuery(shortQuery+soqlWhere));
        String aggrTotalQuery = 'SELECT SUM(EBH_Subsidy__c) totalSubPerSoldItem,SUM(Subsidy_Planned_Gross__c) totalSubPlannedGross, SUM(Sub_Ratio__c) totalSubRatio FROM EBH_Deal__c'; // SB 25.1.2024 US-0014482
        //AggregateResult[] aggrResult = Database.query(aggrTotalQuery+soqlWhere);// SB 25.1.2024 US-0014482
        AggregateResult[] aggrResult = ApexSafe.query().secCheck(false).doQuery(aggrTotalQuery+soqlWhere);
        return new Map<String,Object>{
            'pklMap'=> pklMap,
            'baseQuery' => baseQuery,
            'fieldList' => fieldList,
            'soqlWhere' => soqlWhere,
            //'legitRecordIds' => legitRecordIds
            'mapLegitRecords' => mapLegitRecords,//TH:US-0013751:change to mapLegitRecords
            // SB 25.1.2024 US-0014482
            'totalSubPerSoldItem' => aggrResult[0].get('totalSubPerSoldItem'),
            'totalSubPlannedGross' => aggrResult[0].get('totalSubPlannedGross'),
            'totalSubRatio' => aggrResult[0].get('totalSubRatio'),//TH:US-0016410: sum total Sub_Ratio__c
            'isBulkFromDCA' => isDCA,//TH:US-0016410: sum total Sub_Ratio__c
            'msgInfo' => msgInfo //TH:US-0016410: sum total Sub_Ratio__c
        };
    }

    @AuraEnabled
    public static Map<String,Object> apexSaveRecordList(String listRecord, Boolean saveAndConvert)
    {   
        List<EBH_Deal__c> myListRecord =(List<EBH_Deal__c>) JSON.deserialize(listRecord, List<EBH_Deal__c>.class);
        Id dealRecordTypeV2 = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id;
        Map<String,Object> mapResult = new Map<String,Object>{'status'=>'ok'};
        Map<String, String> mapError = new Map<String, String>();

        if(saveAndConvert){
            List<EBH_Deal__c> lstDealToConvert = new List<EBH_Deal__c>();
            for(EBH_Deal__c sDeal : myListRecord){
                //TH:US-0013751:Add validation : Un Sub Deals cannot be converted in to Sub Deals if Subsidy is not provided.
                if(sDeal.EBH_DealPrice__c == sDeal.EBH_SellerPrice__c){
                    mapError.put(sDeal.Id, System.Label.Un_Sub_Deals_Convert_msg); 
                    continue;
                }
                sDeal.RecordTypeId = dealRecordTypeV2;
                sDeal.EBH_Status__c = 'New';
                lstDealToConvert.add(sDeal);
            }
            myListRecord = lstDealToConvert;
        }

        List<Database.SaveResult> updateResults = Database.update(myListRecord, false);
        
        Set<Id> successRecordIds = new Set<Id>();
        for(Integer i=0;i<updateResults.size();i++){
           //mapError.put(myListRecord.get(i).Id, 'test');
            if (updateResults.get(i).isSuccess()){
                successRecordIds.add(updateResults.get(i).getId());
                // updateResults.get(i).getId();

            }else if (!updateResults.get(i).isSuccess()){
                // DML operation failed
                List<String> listErr = new List<String>();
                for(Database.Error err : updateResults.get(i).getErrors()){
                    listErr.add(err.getMessage());
                }
                mapError.put(myListRecord.get(i).Id, String.join(listErr, '; '));
                
            }
        }
        mapResult.put('successRecordIds',successRecordIds);
        if(!mapError.isEmpty() || !saveAndConvert){
            mapResult.put('status','ko');
            mapResult.put('errorMap',mapError);
            
            return mapResult;
        }else{
            mapResult.put('status','ok');
            mapResult.put('errorMap',new  Map<String, String>());
            return mapResult;
        }
        
    }
}