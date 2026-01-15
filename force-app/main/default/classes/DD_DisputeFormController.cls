/**
The page will receive an Id parameter similar to DocumentApproval it will be an encrypted Id but this time we will be receiving the Deal Statement ID

With deal Statement id we will populate the first section

Title will be {Statement.Name}

Use a field set to show all the following fields:
30 day calculation
30 day payout
Amount held back
Total paid out(show at end of all these fields)
Conditionally Render if 60 day calculation has been populated:
60 day calculation
60 day payout
If dispute payout has been populated show:
Dispute Payout
If further dispute payout has populated show:
Further dispute payout

If Dispute window is closed take the styling from the success message at the bottom of the html and create an error message panel:
Instead of green styling should be red
Instead of success message tick replace with error message x attached to CR
Create different custom labels for me to enter verbiage
Deal Statement details should still show at the top
If deal statement record can’t be found just show error message window created from previous item without deal statement detail section with new custom labels so that I can update.

Select a dispute type should also automatically render if dispute windows are open:
If they select Quantity Variance or Subsidy per unit and Dispute Window formula says ‘Closed’ error message should show
If they select Quantity Variance or Subsidy per unit and Dispute Window formula says ’Not Open’ then also show error message verbiage but create new labels for this as will have different verbiage
If they select Quantity Variance or Subsidy per unit and Dispute Window formula says 'Open’ allow table view of all Deals related to that statement.
Use field set to show deal fields
List needs to be paginated as there could be over 1000 Deal records
List needs to be searchable
can we use a jquery library to do all of the above? and keep styling as per html
User can select as many deals as they would like
Dispute details must be populated in order for user to click submit
Add fields for Name and Email address
On clicking submit new Case must be created with the following details
Dispute Details = Description
Name = SuppliedName
Email address = SuppliedEmail
Subject = Deal Statement Name + ‘Error Type’
Owner = Daily Deals Team
Case Origin = ‘Dispute Form'
Case Reason = Error Type
Deal Statement = Id
Update each deal selected - Status = ‘Disputed’, Dispute_Type__c = Error Type
Once submitted successfully show success message at the bottom of the HTML (still show the statement detail)
If the user selects the other two then no error message needs to be shown
If user selects Deal Omitted from Statement section to indicate what Deals the user thinks are missing
Use same styling as html
Add fields to field set (deal dates should be date only)
Add fields for Name and Email address
Dispute details must be entered before user submitts
On clicking submit new case must be created with the following details
Dispute Details = Description
Name = SuppliedName
Email address = SuppliedEmail
Subject = Deal Statement Name + Error Type
Owner = Daily Deals Team
Case Origin = ‘Dispute Form'
Case Reason = Error Type
Deal Statement = Id
Create csv file File associated to Case with all the details entered on the page by the user
Once submitted successfully show success message at the bottom of the HTML (still show the statement detail)
If user selects other they will only be shown dispute details window
Add fields for Name and email address
Dispute details must be entered before user submitts
On clicking submit new case must be created with the following details
Dispute Details = Description
Name = SuppliedName
Email address = SuppliedEmail
Subject = Deal Statement Name + Error Type
Owner = Daily Deals Team
Case Origin = ‘Dispute Form'
Case Reason = Error Type
Deal Statement = Id
Once submitted successfully show success message at the bottom of the HTML (still show the statement detail)
*/
/*********************************************************************************************************************************
@ Class:          DD_DisputeFormController
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        US-0009180 - [NA] Migrate Disputes Microsite for Seller Case creation
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.04.2021 /Vadhanak Voun/ Migrated from join-instance
*********************************************************************************************************************************/
public without sharing class DD_DisputeFormController {

    static Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();

    public String recordId {get;set;}
    public String backUrl {get;set;}
    public String searchItem {get;set;}
    public DealStatementDTO dealStatement{get;set;}
    public Map<String,RowData> mapItems{get;set;}
    public Integer mapItemsSize { get { return mapItems.size( ); } }
    public Deal_Statement__c currentDealStatement {get;set;}
    public String selectedId{get;set;}
    public Boolean checkedAll{get;set;}
    public Boolean isLoading{get;set;}
    public Boolean isNoDealStatementId{get;set;}
    public Boolean isSubmitSuccess {get;set;}
    public Boolean isSubmitError {get;set;}
    public String errorMessage{get;set;}
    
    public Boolean isDisputeWindowClose {get;set;}
    public Boolean isDTypeWindowCloseOrNotOpen {get;set;}
    
    public Boolean isQuantityVariance {get;set;}
    public Boolean isDealOmitted {get;set;}
    public Boolean isDisputeOther {get;set;}
    
    public String descriptionOmit {get;set;}
    public String descriptionOther {get;set;}
    

    public String webnameOmit {get;set;}
    public String webnameOther {get;set;}

    public String webemailOmit {get;set;}
    public String webemailOther {get;set;}
    
    public String suppliedName {get;set;}
    public String suppliedEmail {get;set;}
    public String description {get;set;}
    
    
    public Case caseInfo{get;set;}
    public List<DealOmittedDTO> dealOmitted {get;set;}
    public Integer dealOmitDeleteIndex {get;set;}
    public Integer offset {get;set;}
    public Integer limit_deals_size {get;set;}
    public Integer total_deals_size {get;set;}
    
    public Integer current_page {get;set;}
    public Integer total_Page {get;set;}
    
    public List<String> labels {get;set;}
    
    //  Cases should be assigned to Daily Deals Team Queue
    static Group grpDailyDealsBU = [Select g.Id From Group g where DeveloperName='Daily_Deals_BU' AND Type = 'Queue'];
    
    
    public DD_DisputeFormController(){
        recordId = ApexPages.currentPage().getParameters().get('pid');
        String pId = ApexPages.currentPage().getParameters().get('pid');
        pId = EncodingUtil.urlEncode(pId, 'UTF-8');
        backUrl = '/apex/DD_DisputeForm?pid='+ pId;
        mapItems = new Map<String,RowData>();
        caseInfo = new Case();
        currentDealStatement = new Deal_Statement__c();
        caseInfo.Reason = 'Quantity variance';
        isQuantityVariance = false;
        dealOmitted = new List<DealOmittedDTO>();
        DealOmittedDTO defualtDealOmitted = new DealOmittedDTO('','',null,null);
        dealOmitted.add(defualtDealOmitted);
        isLoading = true;
        isNoDealStatementId = false;
        isSubmitSuccess = false;
        current_page = 1;
        total_Page = 1;
        offset = 0;
        limit_deals_size = 12;
        searchItem = null;
        
        labels = new List<String>();
        loadheader();
        
        
        
        // if user is guest - we should get a encrypt record id
        if (UserInfo.getUserType() == 'Guest') {
             backUrl = '/DD_DisputeForm?pid='+ pId; 
             recordId = ApexUtil.doDecrypt(recordId, ApexUtil.encryptionkey);
        }
        //System.debug('recordId ::' + recordId);
        //System.debug('UserInfo.getUserType ::'+ UserInfo.getUserType());
        //TODO decrypt record id
        List<Deal_Statement__c> lst = [Select Id,Name,Subsidy_30_Day_Calculation__c,Initial_Payout__c,
                                        Amount_Held_Back__c,Subsidy_Final_Calculation__c,Second_Payout__c,Total_Paid_Out__c,
                                        Disputes_Payout__c,Further_Dispute_Payout__c,Dispute_Window__c 
                                        from Deal_Statement__c where id=:recordId ];
        
        if(lst!=null && !lst.isEmpty()){
            currentDealStatement = lst[0];
            if(currentDealStatement.Dispute_Window__c == 'Closed'){isDisputeWindowClose = true;}
            recordId = currentDealStatement.Id;
            total_deals_size = getDealsSize(lst[0],null);
            dealStatement = new DealStatementDTO(lst[0]);
            searchDS(currentDealStatement.Id,null,dealStatement,limit_deals_size,offset);
            isLoading = false;
          //  caseInfo.OwnerId = lst[0].OwnerId;
            // check page number
            checkPageNumber();
        }else{ isNoDealStatementId = true; }
    }
    
   private void loadheader() {
        Schema.SObjectType convertType = gd.get('EBH_Deal__c');
        Map<String, Schema.FieldSet> fieldSetNameMapToFieldSet = convertType.getDescribe().fieldSets.getMap();          
        Schema.FieldSetMember[] flst = fieldSetNameMapToFieldSet.get('Deal_Statement_Dispute').getFields();
        if(caseInfo.Reason != 'Quantity variance'){
            flst = fieldSetNameMapToFieldSet.get('Deal_Statement_Dispute_Subsidy').getFields();
        }
            
        for(Schema.FieldSetMember f: flst){
            labels.add(f.getLabel());
        }
    }
    
    public void searchDS(String recId, String searchTitle, DealStatementDTO ds, Integer limit_deals, integer counter) {
        
            Schema.SObjectType convertType = gd.get('EBH_Deal__c');
            
            Map<String, Schema.FieldSet> fieldSetNameMapToFieldSet = convertType.getDescribe().fieldSets.getMap();          
            Schema.FieldSetMember[] flst = fieldSetNameMapToFieldSet.get('Deal_Statement_Dispute').getFields();
            if(caseInfo.Reason != 'Quantity variance'){
                flst = fieldSetNameMapToFieldSet.get('Deal_Statement_Dispute_Subsidy').getFields();
            }
            String query = 'SELECT ';
            for(Schema.FieldSetMember f: flst){
                    query += f.getFieldPath() + ', ' ;
            }
            
            //query = 'select Id,EBH_Subsidy__c,Returns_Cncl_UPI__c,Net_Subsidy_Amount__c,EBH_ProductTitle__c,EBH_eBayItemID__c,Final_Sold_Items__c,EBH_DealStartTime__c,EBH_DealStartDate__c,EBH_DealEndDate__c,EBH_DealEndTime__c'+ 
            //               ' from EBH_Deal__c where deal_statement__c=:recId AND Status__c != \'In Dispute\'';
     
            query += 'Id FROM EBH_Deal__c WHERE Deal_Statement__c =: recId';//AND Status__c != \'In Dispute\'
            
            String name= '%'+searchTitle+'%';
             if(searchTitle != null){
                    query+=' AND EBH_ProductTitle__c Like :name';
                }
                query+=' order by EBH_ProductTitle__c Limit :limit_deals offset :counter';
            
            List<EBH_Deal__c> dealLst = Database.query(query); 

            for (EBH_Deal__c deal : dealLst) {
                
                RowData rd = new RowData(deal,flst);
                
                rd.recordid = deal.Id;
                ds.rowLst.add(rd);
            }
            
   }
  public PageReference searchItemData(){
        checkedAll = true;
        isLoading = true;
        current_page = 1;
        total_Page = 1;
        offset = 0;

        if(searchItem.length()<3){ searchItem = null; }
        
        if(currentDealStatement!=null){
            total_deals_size = getDealsSize(currentDealStatement,searchItem);
            dealStatement = new DealStatementDTO(currentDealStatement);
            searchDS(currentDealStatement.Id,searchItem,dealStatement,limit_deals_size,0);
            // check is item selected
            if(dealStatement.rowLst == null || dealStatement.rowLst.size() == 0){ checkedAll = false; }
            checkItemIsSelected();
        }
        checkPageNumber();
        
        return null;
    }
    
    
    private Integer getDealsSize(Deal_Statement__c ds,String searchTitle){
        String name = '%'+searchTitle+'%';
        Id recordId = ds.Id;
        String query = 'Select Id from EBH_Deal__c Where deal_statement__c=:recordId';// AND Status__c != \'In Dispute\'
        if(searchTitle != null){
          query+=' AND EBH_ProductTitle__c Like :name';
        }
        List<EBH_Deal__c> deals = Database.query(query);
        return deals.size();
    }
    
    private void checkPageNumber(){
        if(total_deals_size > limit_deals_size){
           Decimal totalDeals = total_deals_size;
           Decimal limitPage = limit_deals_size;
           total_Page = (Integer) (totalDeals/limitPage).round(System.RoundingMode.CEILING);
        }
    }
    
    private void checkItemIsSelected(){
        List<RowData> listDeals = new List<RowData>();
        for(RowData deal: dealStatement.rowLst){
            for(RowData mapDeal: mapItems.values()){
                if(deal.recordId == mapDeal.recordId){
                    deal.isSelected = true;
                    break;
                }
            }
            if(!deal.isSelected){
                checkedAll = false;
            }
            listDeals.add(deal);
        }
        dealStatement.rowLst = listDeals;
        isLoading = false;
    }
    
    // prev
    public PageReference prev(){
        if(offset == 0){return null;}
        checkedAll = true;
        isLoading = true;
        offset -= limit_deals_size;
        current_page -=1;
        if(currentDealStatement!=null){
            dealStatement = new DealStatementDTO(currentDealStatement);
            searchDS(currentDealStatement.Id,searchItem,dealStatement,limit_deals_size,offset);
            // check is item selected
            
            checkItemIsSelected();
        }
        return null;
    }
    // next
    public PageReference next(){
        if(current_page == total_Page || total_Page == 1){return null;}
        checkedAll = true;
        isLoading = true;
        offset += limit_deals_size;
        current_page +=1;
         if(currentDealStatement!=null){
            dealStatement = new DealStatementDTO(currentDealStatement);
            
            searchDS(currentDealStatement.Id,searchItem,dealStatement,limit_deals_size,offset);
            // check is item selected
            checkItemIsSelected();
            
            
        }
        return null;
    }
    
    public PageReference selectedItem() {
        for(RowData deal: dealStatement.rowLst){
            if(deal.recordid == selectedId){
                if(deal.isSelected != null && deal.isSelected){
                    if(!mapItems.containsKey(deal.recordid)){
                         mapItems.put(deal.recordid,deal);
                    }
                }else{
                    mapItems.remove(deal.recordid);
                }
            }
        }
        return null;
    }
    public PageReference selectedAllItem() {
        for(RowData deal: dealStatement.rowLst){
            if(checkedAll){
                deal.isSelected = true;
                if(!mapItems.containsKey(deal.recordid)){
                    mapItems.put(deal.recordid,deal);
                }
            }else{
                deal.isSelected = false;
                mapItems.remove(deal.recordid);
            }
        }
        return null;        
    }
    public pageReference getDisputeTypeQV(){
        caseInfo.Reason = 'Quantity variance';
        getDisputeType();
        return null;
    }
    public pageReference getDisputeTypeSPU(){
        caseInfo.Reason = 'Subsidy per unit';
        getDisputeType();
        return null;
    }
    public pageReference getDisputeTypeDOS(){
        caseInfo.Reason = 'Deal omitted from statement';
        getDisputeType();
        return null;
    }
    public pageReference getDisputeTypeOTH(){
        caseInfo.Reason = 'Other';
        getDisputeType();
        return null;
    }
    public pageReference getDisputeType(){
        isDTypeWindowCloseOrNotOpen = false;
        caseInfo.Subject  = dealStatement.title + ' '+ caseInfo.Reason;
        if(caseInfo.Reason == 'Quantity variance' || caseInfo.Reason == 'Subsidy per unit'){
            if(currentDealStatement!=null && ( currentDealStatement.Dispute_Window__c == 'Closed' || currentDealStatement.Dispute_Window__c == 'Not Open')){
               isDTypeWindowCloseOrNotOpen = true;
            }
            
            isQuantityVariance = true;
            isDealOmitted = false;
            isDisputeOther = false;
        }else if(caseInfo.Reason == 'Deal omitted from statement'){
            isQuantityVariance  = false;
            isDealOmitted = true;
            isDisputeOther = false;
        }else{
            isDealOmitted = false;
            isQuantityVariance = false;
            isDisputeOther = true;
        }
        labels = new List<String>();
        loadheader();
        searchItemData();
        
        return null;
    }
        
    public pageReference deleteDeal(){
        //dealOmitDeleteIndex
        Integer index = 1;
        List<DealOmittedDTO> lstDeals = new List<DealOmittedDTO>();
        for(DealOmittedDTO deal: dealOmitted){
            if(index != dealOmitDeleteIndex){
                lstDeals.add(deal);
            }
            index++;
        }
        dealOmitted = lstDeals;
        return null;
    }
    
    public pageReference createCaseUpdateDeal(){
        try{
            isSubmitSuccess = false;
            if(description == null || String.isBlank(description)){
                return null;
            }
            System.Debug('### suppliedEmail'+suppliedEmail);
            // case fields
            Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('ebay NA Daily Deals').getRecordTypeId();
            caseInfo.Status = 'New';
            caseInfo.SuppliedName = suppliedName;
            caseInfo.suppliedEmail = suppliedEmail;
            caseInfo.Description = description;
            caseInfo.RecordTypeId = recordTypeId;
            caseInfo.Subject  = dealStatement.title + ' '+ caseInfo.Reason;
            caseInfo.Origin = 'Dispute Form';
            caseInfo.Deal_Statement__c = recordId;
            caseInfo.OwnerId = grpDailyDealsBU.Id;
            caseInfo.ContactId = lookupContact(caseInfo.suppliedEmail);
         
            insert caseInfo;
            List<Id> ids = new List<Id>();
            for(RowData item: mapItems.values()){
                if(item.isSelected){
                    ids.add(item.recordid);
                }
            }
            List<EBH_Deal__c> deals =  [SELECT Id, EBH_Status__c,Seller_s_Dispute_Quantity__c,Sellers_Dispute_Subsidy__c, Dispute_Type__c FROM EBH_Deal__c where Id in :ids];
            //System.debug('deals === '+ deals);
            if(deals!=null && !deals.isEmpty()){
                for(EBH_Deal__c deal: deals){
                    //deal.Status__c = 'In Dispute';

                    if(deal.dispute_type__c == null) deal.dispute_type__c = caseInfo.Reason;
                    else if(!deal.dispute_type__c.containsIgnoreCase(caseInfo.Reason))deal.dispute_type__c = deal.dispute_type__c + ';' + caseInfo.Reason;
                    
                    RowData item = mapItems.get(deal.Id);
                    for(ColData data: item.rowData){
                        if(data.colApiName == 'Seller_s_Dispute_Quantity__c' || data.colApiName == 'Sellers_Dispute_Subsidy__c'){
                            if(caseInfo.Reason == 'Quantity variance'){
                                deal.Seller_s_Dispute_Quantity__c = Decimal.valueOf(data.value);
                            }else{
                                deal.Sellers_Dispute_Subsidy__c = Decimal.valueOf(data.value);
                            }
                        }
                    }
                    
                    
                }
                update deals;  

                // refresh data
                mapItems = new Map<String,RowData>();
                caseInfo = new Case();
                //TODO decrypt record id
                if(currentDealStatement!=null){
                    total_deals_size = getDealsSize(currentDealStatement,searchItem);
                    dealStatement = new DealStatementDTO(currentDealStatement);
                    searchDS(currentDealStatement.Id,searchItem,dealStatement,limit_deals_size,offset);
                    // check page number
                    checkPageNumber();
                }
                isSubmitSuccess = true;
                isSubmitError = false;
                
            }
        }catch(Exception e){
           System.debug(e); errorMessage = e.getMessage();isSubmitSuccess = false; isSubmitError = true;
        }
        
        return null;
    }
    
    
      private String lookupContact(String webemail) {
        
        List<Contact> c =[Select id from Contact where email=:webemail];
        
        if (c.isEmpty()) { return null;
            
        } else {
            
            return c.get(0).Id;
        }
        
        
        
    }
    
    public pageReference createCaseDeal(){
        
        try{
            isSubmitSuccess = false;
            // case fields
            Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('ebay NA Daily Deals').getRecordTypeId();
            caseInfo.Status = 'New';
            caseInfo.RecordTypeId = recordTypeId;
            caseInfo.Subject  = dealStatement.title + ' '+ caseInfo.Reason;
            caseInfo.Origin = 'Dispute Form';
            caseInfo.Deal_Statement__c = recordId;
            caseInfo.Description = descriptionOmit; 
            caseInfo.SuppliedEmail = webemailOmit;
            caseInfo.SuppliedName = webnameOmit;
            caseInfo.OwnerId = grpDailyDealsBU.Id;
            caseInfo.ContactId = lookupContact(webemailOmit);
            
            
            insert caseInfo;
            
            List<EBH_Deal__c> deals = new List<EBH_Deal__c>();
            if(dealOmitted!=null && !dealOmitted.isEmpty()){
                String csv = 'Listing ID,Item name,Started,Ended\n';
                for(DealOmittedDTO item: dealOmitted){
                    csv += item.listId.escapeCsv() + ',' + item.itemName.escapeCsv() + ',' + item.startDate.format() + ',' + item.endDate.format() + '\n';
                }
               /* Attachment attachment = new Attachment();
                attachment.Body =  Blob.valueOf( csv );
                attachment.Name = String.valueOf(caseInfo.Subject + '.csv');
                attachment.ParentId = caseInfo.Id;
                insert attachment; */
                ContentVersion cv = new ContentVersion( 
                    title = String.valueOf(caseInfo.Subject + '.csv'),
                    versionData = Blob.valueOf( csv ),
                    pathOnClient = '/' + String.valueOf(caseInfo.Subject + '.csv')
                );
                insert cv;
                ContentVersion contentVersion = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
                ContentDocumentLink contentlink = new ContentDocumentLink();
                contentlink.LinkedEntityId = caseInfo.id;
                contentlink.ContentDocumentId = contentVersion.ContentDocumentId;
                contentlink.ShareType = 'V';
                insert contentlink; 
                
                isSubmitSuccess = true;
                isSubmitError = false;
            }
           }catch(Exception e){
            System.debug(e);errorMessage = e.getMessage(); isSubmitSuccess = false;  isSubmitError = true;
        }
        return null;
    }
    
    public pageReference createCaseDealOther(){
        try{
            Id recordTypeId = ApexUtil.getRecordTypeByName('Case', 'ebay_NA_Daily_Deals').Id;//Schema.SObjectType.Case.getRecordTypeInfosByName().get('ebay NA Daily Deals').getRecordTypeId();
            caseInfo.Status = 'New';
            caseInfo.Reason = 'Other';
            caseInfo.RecordTypeId = recordTypeId;
            caseInfo.Subject  = dealStatement.title + ' '+ caseInfo.Reason;
            caseInfo.Origin = 'Dispute Form';
            caseInfo.Deal_Statement__c = recordId;
            caseInfo.Description = descriptionOther;
            caseInfo.SuppliedEmail = webemailOther;
            caseInfo.SuppliedName = webnameOther;
            caseInfo.OwnerId = grpDailyDealsBU.Id;
            caseInfo.ContactId = lookupContact(webemailOther);

            //System.debug('>>case: '+ JSON.serialize(caseInfo));

            insert caseInfo;                  
    
            isSubmitSuccess = true;
            isSubmitError = false;
        }catch(Exception e){
           System.debug(e); errorMessage = e.getMessage();  isSubmitSuccess = false;  isSubmitError = true;
        }
        return null;
    }
    
    public pageReference addAnotherDeal(){
        DealOmittedDTO defualtDealOmitted = new DealOmittedDTO('','',null,null);
        dealOmitted.add(defualtDealOmitted);
        return null;
    }
    
    public class DealStatementDTO{
        public String dsId{get;set;}
        public String title{get;set;}
        public Double pay30DayCalculation{get;set;}
        public Double total30DayPayout{get;set;}
        public Double amountHeldBack{get;set;}
        //show at end of all these fields
        public Double totalPayout{get;set;}
        //Conditionally Render if 60 day calculation has been populated:
        public Double pay60DayCalculation{get;set;}
        public Double total60DayPayout{get;set;}
        //If dispute payout has been populated show:
        public Double diputePayout{get;set;}
        //If further dispute payout has populated show:
        public Double furtherDisputePayout{get;set;}
        public List<RowData> rowLst{get;set;}
        
        public DealStatementDTO(Deal_Statement__c ds){
            init(ds);
        }
        
        
        private void init(Deal_Statement__c ds){
            this.dsId = ds.Id;
            this.title=ds.Name;
            this.pay30DayCalculation = ds.Subsidy_30_Day_Calculation__c;
            this.total30DayPayout = ds.Initial_Payout__c;
            this.amountHeldBack = ds.Amount_Held_Back__c;
            this.pay60DayCalculation = ds.Subsidy_Final_Calculation__c;
            this.total60DayPayout = ds.Second_Payout__c;
            this.totalPayout = ds.Total_Paid_Out__c;
            this.diputePayout = ds.Disputes_Payout__c;
            this.furtherDisputePayout= ds.Further_Dispute_Payout__c;
            rowLst = new List<RowData>();
           
            
        }
    }
    
    public class DealOmittedDTO{
        public String listId {get;set;}
        public String itemName {get;set;}
        public Date startDate {get;set;}
        public Date endDate {get;set;}
        public DealOmittedDTO(String listId,String itemName,Date startDate, Date endDate){
            this.listId = listId;
            this.itemName = itemName;
            this.startDate = startDate;
            this.endDate = endDate;
        }
        
    }
     public class DealDTO{
        public Id id{get;set;}
        public String eBayItemId{get;set;}
        public String productTitle{get;set;}
        public DateTime startTime{get;set;}
        public DateTime endTime{get;set;}
        public Double subsidy{get;set;}
        public Double finalSoldItems{get;set;}
        public Double netSubsidyAmount{get;set;}
        public Boolean isSelected{get;set;}
        public Double returnUPI {get;set;}
        
        
        public DealDTO(EBH_Deal__c deal){
            this.id = deal.Id;
            this.eBayItemId = deal.EBH_eBayItemID__c;
            this.productTitle = deal.EBH_ProductTitle__c;
            this.returnUPI = deal.Returns_Cncl_UPI__c;
            if(deal.EBH_DealStartDate__c!=null && deal.EBH_DealStartTime__c!=null ){
                this.startTime=DateTime.newInstance(deal.EBH_DealStartDate__c, deal.EBH_DealStartTime__c);
            }
            if(deal.EBH_DealEndTime__c!=null && deal.EBH_DealEndDate__c!=null ){
                this.endTime=DateTime.newInstance(deal.EBH_DealEndDate__c, deal.EBH_DealEndTime__c);
            }
            this.subsidy = deal.EBH_Subsidy__c;
            this.finalSoldItems=deal.Final_Sold_Items__c;
            this.netSubsidyAmount=deal.Net_Subsidy_Amount__c;
            this.isSelected = false;
        }
    }
    
    
     public class ColData {
        public string value {set; get;}
        public string colApiName {set; get;}
        
        public boolean required {set; get;}
        public string colDisplayType {set; get;}
       
        
    } 
    
    public class RowData {
        
        public ColData[] rowData {set; get;}
        public String recordid {set; get;}
        public Boolean isSelected {get;set;}
       
        
        
        public RowData(EBH_Deal__c deal, Schema.FieldSetMember[] flst) {
            recordid = deal.Id;
           
            rowData = new List<ColData>(); 
            isSelected = false;
            for(Schema.FieldSetMember f: flst){
                ColData coldata = new ColData();
                
                  if (f.getType()==Schema.DisplayType.DateTime || f.getType()==Schema.DisplayType.Date) {
                            //Datetime d = 
                            Datetime dvalue = (DateTime)deal.get(f.getFieldPath());
                            coldata.value = dvalue.format('MM/dd/yyyy') ;
                        } else {
                            coldata.value = deal.get(f.getFieldPath()) == null ? '' : String.valueOf(deal.get(f.getFieldPath()));
                        }
                 
               
                        
                coldata.colApiName = f.getFieldPath();
                coldata.required = false;
                rowData.add(coldata);
            }
        }
    } 
}