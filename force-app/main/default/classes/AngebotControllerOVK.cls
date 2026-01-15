/**C.R.O*/
public virtual with sharing class AngebotControllerOVK {
    
    protected String quoteid;
    public String pdfFileName{get; set;}
    public Integer index{get;set;}
    public String dateToday{get;set;}
    public OpportunityContactRole oppContactRole{get;set;}
    public OpportunityContactRole oppContactRoleRecip{get; set;}
    public List<DtoLineItem> lstOppItem{get{If(lstOppItem == null) lstOppItem = new List<DtoLineItem>(); return lstOppItem;}set;}
    public String tableProduct{get;set;}
    public Integer Campaign_Label_Width{get;set;}
    public Integer Campaign_Label2_Width{get;set;}
    public Integer Campaign_Data_Width{get;set;}
    public Integer Campaign_Data2_Width{get;set;}
    public String lang{get;set;}
    public boolean isPageBreak{get;set;}
    public String discount{get;set;}
    public String amountDiscount{get;set;}
    public String amountTargeting{get;set;}
    public String customerNet{get;set;}
    public String commission{get;set;}
    public String netTotal{get;set;}
    public boolean isDealer{get;set;}
    protected String oppCurrency;
    
    public String oppAmount{get; set;}
    public String oppAmountInclTarg{get; set;} // Amount_incl_Targeting__c
    public String oppAmountNetNetNet{get; set;} // Amount_Net_Net_Net__c
    public String oppApreiszus{get; set;} 
    public String oppKundenetto{get; set;}
    public String oppAeProvision{get; set;}
    public String oppAmountNet2eBay{get; set;} //Sambath SENG 30.08.2021 US-0010236, Amount_Net2eBay__c
    public DtoInvoiceRecipient dtoInvRep{get; set;}
    
    public String oppAccName{get; set;}
    public String oppAgencyName{get; set;}
    public String oppConEmail{get; set;}
    public String oppConRolName{get; set;}

    public Quote quote{get; set;}
    
    protected String outputText = '';
    
    /*
    private Decimal amountInclTargeting = 0;
    private Decimal kRabattVorAE = 0;
    private Decimal cNet = 0;
    private Decimal amountNetNetNet = 0;
    */
    public boolean isPart{get;set;}
    public boolean isCon {get;set;}
    protected final Integer FIRST_PAGE = 16;//25; //19
    protected final Integer SECOND_PAGE= 26;//28;//38; //30
    
    public String loFo_Currency {get;set;}
    protected final Decimal BRUTTOUMSATZ_3 = 10000.00;
    protected final Decimal BRUTTOUMSATZ_5 = 25000.00;
    protected final Decimal BRUTTOUMSATZ_10 = 50000.00;
    protected final Decimal BRUTTOUMSATZ_15 = 150000.00;
    protected final Decimal BRUTTOUMSATZ_20 = 250000.00;
    protected final Decimal BRUTTOUMSATZ_25 = 500000.00;
    protected final Decimal BRUTTOUMSATZ_30 = 750000.00;
    public String loFo_Bruttoumsatz_3 {get;set;}
    public String loFo_Bruttoumsatz_5 {get;set;}
    public String loFo_Bruttoumsatz_10 {get;set;}
    public String loFo_Bruttoumsatz_15 {get;set;}
    public String loFo_Bruttoumsatz_20 {get;set;}
    public String loFo_Bruttoumsatz_25 {get;set;}
    public String loFo_Bruttoumsatz_30 {get;set;}
    
    protected Quote quoteBnd;
    public AngebotControllerOVK(ApexPages.StandardController controller){
    	
        quoteid = ((Quote)controller.getRecord()).Id;
        quote = ((Quote)controller.getRecord());
        pdfFileName = (((Quote)controller.getRecord()).Name).replaceAll(' ','_').replaceAll(',','_');
        dateToday = System.Now().format('dd.MM.yyyy');
        bindquote();
        getOppLineItem();
        getContactRole();
        getWidth();
        formatBruttoumsatz();
        Apexpages.currentPage().getHeaders().put('content-disposition', 'attachment; filename=' + pdfFileName+'.pdf');
        
       
 
        
    /*
    cNet = amountInclTargeting * ((100-kRabattVorAE)/100);
    
    amountTargeting = format(amountInclTargeting,' €');
    customerNet = format(cNet,' €');
    netTotal = format(amountNetNetNet,' €');
    */
    }
    
    protected virtual void formatBruttoumsatz() {
//      loFo_Currency = LocaleFormatter.getCurrency(null); // we need currency from the quote
        loFo_Bruttoumsatz_3 = LocaleFormatter.getLocaleFormat(BRUTTOUMSATZ_3, null);
        loFo_Bruttoumsatz_5 = LocaleFormatter.getLocaleFormat(BRUTTOUMSATZ_5, null);
        loFo_Bruttoumsatz_10 = LocaleFormatter.getLocaleFormat(BRUTTOUMSATZ_10, null);
        loFo_Bruttoumsatz_15 = LocaleFormatter.getLocaleFormat(BRUTTOUMSATZ_15, null);
        loFo_Bruttoumsatz_20 = LocaleFormatter.getLocaleFormat(BRUTTOUMSATZ_20, null);
        loFo_Bruttoumsatz_25 = LocaleFormatter.getLocaleFormat(BRUTTOUMSATZ_25, null);
        loFo_Bruttoumsatz_30 = LocaleFormatter.getLocaleFormat(BRUTTOUMSATZ_30, null);
    }
    
    protected void getWidth(){
        bindWidth(14,13,48,7);
        }
        
    private void bindWidth(Integer label,Integer label2,Integer width,Integer width2){
        Campaign_Label_Width = label;
        Campaign_Label2_Width = label2;
        Campaign_Data_Width = width;
        Campaign_Data2_Width = width2;
    }

    /*****************************************************************************************************************************
    @ Change history: 30.08.2021 / Sambath Seng / US-0010236, replace some of the revenue fields.
    *****************************************************************************************************************************/
    public virtual void bindquote(){
    	// System.debug('<<<<<ParentMethode');

        //Sambath SENG 30.08.2021 US-0010236, add 'Amount_Net2eBay__c' to query
        quoteBnd =[Select Id,RecordType.Name,Approved__c,Exit_Clause__c,Number_of_Exit_Days__c,opportunity.Owner.UserRole.Name
                         , Template_language__c,Amount_incl_Targeting__c
                         , kumulierter_Rabatt_vor_AE__c,Amount_Net_Net_Net__c, Amount_Net2eBay__c, CurrencyIsoCode
                         , Amount__c, AE__c, opportunity.Agency__r.BillingStreet, opportunity.Agency__r.BillingCity, opportunity.Agency__r.BillingPostalCode
                         , Account.BillingStreet, Account.BillingCity, Account.BillingPostalCode
                         , Account.Name, Account.EBH_VATNumber__c
                         , opportunity.Agency__r.Name, opportunity.Agency__r.EBH_VATNumber__c
                         , LineItems_Sort_Type__c, opportunityid 
                         from Quote 
                         where Id=: quoteid];
        If(quoteBnd.opportunity.Owner.UserRole.Name.contains('Dealer')) {
            isDealer = true;
        } else {
            isDealer = false;
        }
        loFo_Currency = quote.CurrencyIsoCode;
        amountTargeting = LocaleFormatter.getLocaleFormat(quoteBnd.Amount_incl_Targeting__c, null);
        discount = format(quoteBnd.kumulierter_Rabatt_vor_AE__c,'');
        Decimal discount = (checkNull(quoteBnd.Amount_incl_Targeting__c) * checkNull(quoteBnd.kumulierter_Rabatt_vor_AE__c)) /100;
        amountDiscount = LocaleFormatter.getLocaleFormat(discount, null);
        Decimal cusNet = checkNull(quoteBnd.Amount_incl_Targeting__c) * ((100-checkNull(quoteBnd.kumulierter_Rabatt_vor_AE__c))/100);
        customerNet = LocaleFormatter.getLocaleFormat(cusNet, null);

        //Sambath SENG 30.08.2021 US-0010236, replace 'Amount_Net_Net_Net__c' with 'Amount_Net2eBay__c'
        // Decimal com = (checkNull(quoteBnd.Amount_incl_Targeting__c) * ((100-checkNull(quoteBnd.kumulierter_Rabatt_vor_AE__c))/100))- checkNull(quoteBnd.Amount_Net_Net_Net__c);
        Decimal com = (checkNull(quoteBnd.Amount_incl_Targeting__c) * ((100-checkNull(quoteBnd.kumulierter_Rabatt_vor_AE__c))/100))- checkNull(quoteBnd.Amount_Net2eBay__c);

        commission = LocaleFormatter.getLocaleFormat(com, null);
        
        //Sambath SENG 30.08.2021 US-0010236, replace 'Amount_Net_Net_Net__c' with 'Amount_Net2eBay__c'
        // netTotal = LocaleFormatter.getLocaleFormat(quoteBnd.Amount_Net_Net_Net__c, null);
        netTotal = LocaleFormatter.getLocaleFormat(quoteBnd.Amount_Net2eBay__c, null);

        getLanguage(quoteBnd.Template_language__c == null ? 'German' : quoteBnd.Template_language__c);
        /*
        if(quote.kumulierter_Rabatt_vor_AE__c != null) {
        kRabattVorAE = quote.kumulierter_Rabatt_vor_AE__c;
        }
        */
        
        oppAmount =  LocaleFormatter.getLocaleFormat(checkNull(quoteBnd.Amount__c), null); // *1 quote.Amount__c
        oppApreiszus = LocaleFormatter.getLocaleFormat((checkNull(quoteBnd.Amount_incl_Targeting__c) - checkNull(quoteBnd.Amount__c)), null);   //*2 quote.Amount_incl_Targeting__c - quote.Amount__c
        oppAmountInclTarg = LocaleFormatter.getLocaleFormat(checkNull(quoteBnd.Amount_incl_Targeting__c), null); //*3 quote.Amount_incl_Targeting__c
        
        //Sambath SENG 30.08.2021 US-0010236, replace 'Amount_Net_Net_Net__c' with 'Amount_Net2eBay__c'
        // Double valoppKundenetto = (quoteBnd.AE__c && quoteBnd.Amount_Net_Net_Net__c != null ? (quoteBnd.Amount_Net_Net_Net__c / 0.85) : (quoteBnd.Amount_Net_Net_Net__c));  // *4 If quote.AE__c = True, quote.Amount_Net_Net_Net__c / 0.85, else quote.Amount_Net_Net_Net__c
        Double valoppKundenetto = (quoteBnd.AE__c && quoteBnd.Amount_Net2eBay__c != null ? (quoteBnd.Amount_Net2eBay__c / 0.85) : (quoteBnd.Amount_Net2eBay__c));
        
        oppKundenetto = LocaleFormatter.getLocaleFormat(valoppKundenetto, null);

        //Sambath SENG 30.08.2021 US-0010236, replace 'Amount_Net_Net_Net__c' with 'Amount_Net2eBay__c'
        // oppAeProvision = LocaleFormatter.getLocaleFormat((checkNull(quoteBnd.Amount_Net_Net_Net__c) - valoppKundenetto) * -1, null);  //*5 quote.Amount_Net_Net_Net__c - *4
        // oppAmountNetNetNet = LocaleFormatter.getLocaleFormat(checkNull(quoteBnd.Amount_Net_Net_Net__c), null); //*6 quote.Amount_Net_Net_Net__c
        oppAeProvision = LocaleFormatter.getLocaleFormat((checkNull(quoteBnd.Amount_Net2eBay__c) - valoppKundenetto) * -1, null);
        oppAmountNet2eBay = LocaleFormatter.getLocaleFormat(checkNull(quoteBnd.Amount_Net2eBay__c), null);
        
        oppAccName = doLineBreakText(quoteBnd.Account.Name);
        oppAgencyName = doLineBreakText(quoteBnd.opportunity.Agency__r.Name);
        
        
    }
    protected void getLanguage(String language){
        
        if(language == 'English'){
            lang = 'en';
        }else if(language == 'German'){
            lang = 'de';
        }else if(language == 'Romanian'){
            lang = 'da';
        }else if(language == 'Polish'){
            lang = 'nl';
        }else if(language == 'French'){
            lang = 'fr';
        }else if(language == 'Italian'){
            lang = 'it';
        }else if(language == 'Spanish'){
            lang = 'es';
        }
    }
    public String getFontFamily() {
        if(lang == 'nl' || lang == 'da'){
            return 'Arial Unicode MS,Helvetica,sans-serif';
        } else {
            return 'Arial,Helvetica,sans-serif';
        }
    }
    public String getFontSize8() {
        if(lang == 'nl' || lang == 'da'){
            return '6pt';
        } else {
            return '8pt';
        }
    }
    public String getFontSize9() {
        if(lang == 'nl' || lang == 'da'){
            return '7pt';
        } else {
            return '9pt';
        }
    }
    protected void getContactRole(){
        
        String contRolType = 'Invoice recipient';
        String oppId = quoteBnd.opportunityId;
        String soqlStr = 'Select o.Contact.OwnerId, o.Contact.Email, o.Contact.Phone, o.Contact.Name, ' 
                         + 'o.ContactId, o.Role, o.Contact.MailingStreet, o.Contact.MailingCity, o.Contact.MailingPostalCode, '
                         + 'o.Contact.Account.Name, o.Contact.Account.BillingStreet, o.Contact.Account.BillingCity, o.Contact.Account.BillingPostalCode, o.Contact.Account.EBH_VATNumber__c'
                         + ' From OpportunityContactRole o '
                         + ' where o.OpportunityId = :oppId ' ;
                        
        
        OpportunityContactRole[] lstContactRolePrim = Database.query(soqlStr + ' and o.IsPrimary=true');

        OpportunityContactRole[] lstContactRoleRecient = Database.query(soqlStr + ' and  Role=: contRolType');
        
        oppContactRole = (!lstContactRolePrim.isEmpty()) ? lstContactRolePrim.get(0) : new OpportunityContactRole();
        oppContactRoleRecip = (!lstContactRoleRecient.isEmpty()) ? lstContactRoleRecient.get(0) : new OpportunityContactRole();
        
        oppConEmail = doLineBreakText(oppContactRole.Contact.Email);
        oppConRolName = doLineBreakText(oppContactRole.Contact.Name);
        
        dtoInvRep = new DtoInvoiceRecipient();
        if(!lstContactRoleRecient.isEmpty())
        {
          dtoInvRep.invRep = doLineBreakText(oppContactRoleRecip.Contact.Account.Name);
          dtoInvRep.invRepStr = oppContactRoleRecip.Contact.Account.BillingStreet;
          dtoInvRep.invRepCity = oppContactRoleRecip.Contact.Account.BillingCity;
          dtoInvRep.invPostalCode = oppContactRoleRecip.Contact.Account.BillingPostalCode;
          dtoInvRep.invUstId = oppContactRoleRecip.Contact.Account.EBH_VATNumber__c;
          dtoInvRep.invConName = doLineBreakText(oppContactRoleRecip.Contact.Name);
          dtoInvRep.invEmailAdr = doLineBreakText(oppContactRoleRecip.Contact.Email);
          dtoInvRep.invTel = oppContactRoleRecip.Contact.Phone;
        } 
        else if(quote.opportunity.Agency__c != null && lstContactRoleRecient.isEmpty())
        {     
          dtoInvRep.invRep = doLineBreakText(quoteBnd.opportunity.Agency__r.Name);	
          dtoInvRep.invRepStr = quoteBnd.opportunity.Agency__r.BillingStreet;
          dtoInvRep.invRepCity = quoteBnd.opportunity.Agency__r.BillingCity;
          dtoInvRep.invPostalCode = quoteBnd.opportunity.Agency__r.BillingPostalCode;
          dtoInvRep.invUstId = quoteBnd.opportunity.Agency__r.EBH_VATNumber__c;
          dtoInvRep.invConName = doLineBreakText(oppContactRole.Contact.Name);
          dtoInvRep.invEmailAdr = doLineBreakText(oppContactRole.Contact.Email);
          dtoInvRep.invTel = oppContactRole.Contact.Phone;
        }else
        {
          dtoInvRep.invRep = doLineBreakText(quoteBnd.Account.Name);	
          dtoInvRep.invRepStr = quoteBnd.Account.BillingStreet;
          dtoInvRep.invRepCity = quoteBnd.Account.BillingCity;
          dtoInvRep.invPostalCode = quoteBnd.Account.BillingPostalCode;
          dtoInvRep.invUstId = quoteBnd.Account.EBH_VATNumber__c;
          dtoInvRep.invConName = doLineBreakText(oppContactRole.Contact.Name);
          dtoInvRep.invEmailAdr = doLineBreakText(oppContactRole.Contact.Email);
          dtoInvRep.invTel = oppContactRole.Contact.Phone;
        }
        
        // System.debug('===============> dtoInvRep: ' + dtoInvRep);
        //OpportunityContactRole[] lstContactRole = [Select o.Contact.OwnerId,
        //                                               o.Contact.Email, 
        //                                                  o.Contact.Phone, 
        //                                                  o.Contact.Name, 
        //                                                  o.ContactId,
        //                                                  o.Role,
        //                                                  o.Contact.MailingStreet,
        //                                                  o.Contact.MailingCity,
        //                                                  o.Contact.MailingPostalCode 
        //                                           From OpportunityContactRole o 
        //                                          where o.OpportunityId = : quoteid and  Role='Invoice recipient']; //o.IsPrimary=true and
        //if(!lstContactRole.isEmpty()){ 
        //    oppContactRole = lstContactRole.get(0);
            
        //}else{
            
        //    oppContactRole=new OpportunityContactRole();
            
        //}
    }
    
    /*
      private Integer getNumber(String tmp,Integer con){
        
        if(tmp==null ||tmp=='' || tmp.length()<con){
            return 1;
            
        }
        
        
        Integer i=tmp.length()/con;
        
        
        return i;
        
    }
    */
    
    /*****************************************************************************************************************************
    @ Change history: 30.08.2021 / Sambath Seng / US-0010236, replace some of the revenue fields.
    *****************************************************************************************************************************/
    public virtual void getOppLineItem(){
        isCon = false;
        isPart = false;
        integer tmpIndex = 0 ; 
        integer i = 1 ;  
        Integer breakP = FIRST_PAGE;
        Integer index = 1;
        Integer k=1;
        isPageBreak=false;
        Integer pos=1;
        
        Integer totalLengh=0;
        String strOrderBy = ('Manually'.equals(quoteBnd.LineItems_Sort_Type__c) ? ' ORDER BY SortOrder' : ' ORDER BY from_date__c ASC');

        //Sambath SENG 30.08.2021 US-0010236, add 'Amount_Net2eBay__c' to strQuery& replace 'CPM_net_net_net__c' with 'CPM_net__c'
        String strQuery = 'Select PricebookEntry.Product2.Site__r.Name,'+
                          ' PricebookEntry.Product2.Site__r.Quotation_text_DE__c, PricebookEntry.Product2.Advertising_Medium__r.Dart_MasterSize__c, '+
                          ' PricebookEntry.Product2.Advertising_Medium__r.Quote_text__c, PricebookEntry.Product2.Advertising_Medium__r.Format__c, '+
                          ' PricebookEntry.Product2.RecordType.Name,'+
                          ' Sales_Price_incl_Targeting__c, UnitPrice, Billing_category__c, from_Date__c, until_Date__c,'+
                          ' Guaranteed_AI__c, Quantity, Package__c, Total_price_incl_Targeting__c, Rate_Card_Discount_percent__c,'+
                          ' Special_Agency_Discount_Percent__c, Rate_Discount_I__c, Rate_Discount_II__c, Amount_Net_Net_Net__c, Amount_Net2eBay__c,'+
                          ' Description, PricebookEntry.Product2.Name, ListPrice, Targeting_fee2__c,'+
                          ' PricebookEntry.Product2.Placement__r.Quotation_text__c,'+
                          ' PricebookEntry.Product2.Advertising_Medium__r.Quotation_text__c, '+
                          ' AE__c, CPM_net__c, salespricenet__c '+
                          ' from QuoteLineItem '+
                      	  ' where quoteId =: quoteid '+
                          ' and package_line_item__c = null '
        				  + strOrderBy;
         //page 1st22 lines
         //page after 33 lines
         Integer condition=FIRST_PAGE;
        for(QuoteLineItem oppItem : Database.query(strQuery)){ //order by SortOrder
            /*
            amountInclTargeting += oppItem.Total_price_incl_Targeting__c;
            amountNetNetNet += oppItem.Amount_Net_Net_Net__c;
            */
             //updated cheasarat 2011.05.19
             // So that it does show Oli information for packages
             //It does not show Info for package parts (This is not quite right. They should be shown with name, format and start and enddate only but without the monetary information.)
             //It does show info for regular Olis 
               DtoLineItem dto = new DtoLineItem();
              
              dto.pos = pos++;
             if(oppItem.PricebookEntry.Product2.RecordType.Name!='Package' && (oppItem.Package__c=='Content Special'||oppItem.Package__c=='Partnerportal') ){               
                dto.isPacket=true;
             }  else{
                dto.isPacket=false;
                
             }  
             
            //Integer countFormat=getNumber(oppItem.PricebookEntry.Product2.Advertising_Medium_DB__r.Format__c,22);
            //Integer countQuote=getNumber(oppItem.PricebookEntry.Product2.Advertising_Medium_DB__r.Quote_text__c,10);
            
            //system.debug('\n\n oppItem.PricebookEntry.Product2.Site__r.Quotation_text_DE__c: '+oppItem.PricebookEntry.Product2.Site__r.Quotation_text_DE__c+'\n\n');
             Integer countSite = pageBreaker(oppItem.PricebookEntry.Product2.Site__r.Quotation_text_DE__c,13);
             dto.site = oppItem.PricebookEntry.Product2.Site__r.Name;
             //system.debug('\n\n countSite: '+countSite+' ### dto.site: '+dto.site+'\n\n');
             
             //Integer countSize = pageBreaker(oppItem.PricebookEntry.Product2.Size__c == null ? '' : oppItem.PricebookEntry.Product2.Size__c,10);
             outputText = oppItem.PricebookEntry.Product2.Advertising_Medium__r.Dart_MasterSize__c == null ? '' : oppItem.PricebookEntry.Product2.Advertising_Medium__r.Dart_MasterSize__c.replaceAll(';',';\n');
             Integer countSize = outputText.split('\n').size();
             dto.size = outputText;

             //system.debug('\n\n oppItem.PricebookEntry.Product2.Name: '+oppItem.PricebookEntry.Product2.Name+'\n\n');
             Integer countProduct = pageBreaker(oppItem.PricebookEntry.Product2.Name,23);
             dto.product = oppItem.PricebookEntry.Product2.Name;
             //system.debug('\n\n countProduct: '+countProduct+' ### dto.product: '+dto.product+'\n\n');
             
             if(countProduct < 2) {
                countProduct = 2;
             }
             
             if(countSize < 2) {
                countSize = 2;
             }

             if(countSite < 2) {
                countSite = 2;
             }
             
             Integer countLength = countSite>countProduct?countSite:countProduct;
             
             totalLengh+=countLength;
             
            // system.debug('===============oppItem.PricebookEntry.Product2.Advertising_Medium_DB__r.Quote_text__c=' + oppItem.PricebookEntry.Product2.Advertising_Medium_DB__r.Quote_text__c);
            // system.debug('===============oppItem.PricebookEntry.Product2.Advertising_Medium_DB__r.Format__c=' + oppItem.PricebookEntry.Product2.Advertising_Medium_DB__r.Format__c);
            // system.debug('===========countFormat=' + countFormat + '==============countQuote=' + countQuote);
             
            //totalLengh+=countFormat>countQuote?countFormat:countQuote;
                                                            
            Integer countDescription = 0;
          
            tmpIndex ++ ;
            if(oppItem.Description != null){
                tmpIndex ++; 
                //totalLengh+=getNumber(oppItem.Description, 103);
                Integer z = lang!='de'?140:120;
                
                countDescription = pageBreaker(oppItem.Description, z);
                totalLengh+=countDescription;
                dto.description = outputText;
                // system.debug('\n\n totalLengh: '+totalLengh+'\n\n');
                dto.isDescription=true;
            }else{
                
                
                dto.isDescription=false;
            }
            
            // system.debug('\n\n totalLengh: '+totalLengh+' >= condition: '+condition+'\n\n');
            
             if(totalLengh>condition){
                            
                          dto.breakPoint = true;
                            //totalLengh=0;
                            totalLengh = countLength+countDescription;
                            condition=SECOND_PAGE;
              }else{
                           dto.breakPoint = false;
                            
                            
              }                    
             // system.debug('============totalLengh='+totalLengh);
            if(oppItem.Billing_category__c == null || oppItem.Billing_category__c != 'CPM'){
                //dto.price = FormatHelper.format(oppItem.Sales_Price_incl_Targeting__c) + ' €'; 
                if(oppItem.Sales_Price_incl_Targeting__c != null) {
                    dto.price = LocaleFormatter.getLocaleFormat(oppItem.Sales_Price_incl_Targeting__c, null);
                }
            }else{
                Decimal price = checkNull(oppItem.Sales_Price_incl_Targeting__c) * 1000;
                //dto.price = FormatHelper.format(price) + ' €';
                if(price != null) {
                    dto.price = LocaleFormatter.getLocaleFormat(price, null);
                }
            }
            dto.Guaranteed_AI = format(oppItem.Guaranteed_AI__c,'') ;
            if(oppItem.Quantity != null) {
                dto.plan_Volume = formatQuantity(oppItem.Quantity.setScale(0).toPlainString());
            }
            //dto.plan_Volume = format(oppItem.Quantity,'');
            dto.price_Gross = LocaleFormatter.getLocaleFormat(oppItem.Total_price_incl_Targeting__c, null);
            dto.customer_discount = format(oppItem.Rate_Card_Discount_percent__c ,' %');
            dto.discount1 = format(oppItem.Special_Agency_Discount_Percent__c, ' %');
            dto.discount2 = format(oppItem.Rate_Discount_I__c , ' %');
            dto.discount3 = format(oppItem.Rate_Discount_II__c , ' %');
            //dto.price_net = format(oppItem.Amount_Net_Net_Net__c , ' €');
            if (oppItem.Rate_Card_Discount_percent__c == null) {
                oppItem.Rate_Card_Discount_percent__c = 0;
            }
            if (oppItem.Rate_Discount_I__c == null) {
                oppItem.Rate_Discount_I__c = 0;
            }
            if (oppItem.Rate_Discount_II__c == null) {
                oppItem.Rate_Discount_II__c = 0;
            }
            
            //Sambath SENG 30.08.2021 US-0010236, replace 'Amount_Net_Net_Net__c' with 'Amount_Net2eBay__c'
            // dto.amountNetNetNet =(oppItem.AE__c && oppItem.Amount_Net_Net_Net__c != null ? LocaleFormatter.getLocaleFormat((oppItem.Amount_Net_Net_Net__c / 0.85), null)  : LocaleFormatter.getLocaleFormat(oppItem.Amount_Net_Net_Net__c, null));
            dto.amountNet2eBay =(oppItem.AE__c && oppItem.Amount_Net2eBay__c != null ? LocaleFormatter.getLocaleFormat((oppItem.Amount_Net2eBay__c / 0.85), null)  : LocaleFormatter.getLocaleFormat(oppItem.Amount_Net2eBay__c, null));
            
            
            dto.price_net = LocaleFormatter.getLocaleFormat(oppItem.Total_price_incl_Targeting__c * ((100-oppItem.Rate_Card_Discount_percent__c)/100) * ((100-oppItem.Special_Agency_Discount_Percent__c)/100) * ((100-oppItem.Rate_Discount_I__c)/100) * ((100-oppItem.Rate_Discount_II__c)/100), null);
            //dto.index = tmpIndex > 16 ? 0 :tmpIndex; // for doing page break
            dto.oppItem = oppItem ;
            dto.isContent=false;
            dto.isPartnerportal=false;

            if(oppItem.ListPrice != null) {
                dto.listPrice = LocaleFormatter.getLocaleFormat(oppItem.ListPrice, null);
            }
            
            if(oppItem.Targeting_fee2__c != null) {
                dto.targetingFee = LocaleFormatter.getLocaleFormat(oppItem.Targeting_fee2__c, null);
            }
            
            dto.preisEinheit  =  (('CPM').equals(oppItem.Billing_category__c) && oppItem.UnitPrice != null ?  LocaleFormatter.getLocaleFormat((oppItem.SalesPriceNet__c ), null) : LocaleFormatter.getLocaleFormat(oppItem.SalesPriceNet__c, null));

            
            
            dto.targetingFee2 = (oppItem.Targeting_fee2__c != null?LocaleFormatter.getLocaleFormat(oppItem.Targeting_fee2__c , null):'');
            
            //Sambath SENG 30.08.2021 US-0010236, replace 'Amount_Net_Net_Net__c' with 'Amount_Net2eBay__c' & 'CPM_net_net_net__c' to 'CPM_net__c'
            // dto.oppItemCustNet = LocaleFormatter.getLocaleFormat(oppItem.Amount_Net_Net_Net__c, null);
            // dto.oppItemCPMNetNetNet = LocaleFormatter.getLocaleFormat(oppItem.CPM_net_net_net__c, null);
            dto.oppItemCustNet = LocaleFormatter.getLocaleFormat(oppItem.Amount_Net2eBay__c, null);
            dto.oppItemCPMNet = LocaleFormatter.getLocaleFormat(oppItem.CPM_net__c, null);
      
      
            index++;
          
            i += 1;
            if(k==1){
                 dto.isColorGray =  false;
                 k=0;
            }else{
                 dto.isColorGray =  true;
                 k=1;
                
            }
            
            if(dto.breakPoint) {
                dto.isColorGray = false;
                k=0;
            }
           
            lstOppItem.add(dto);
           
        }
        
        
         if(condition==FIRST_PAGE){
                if(totalLengh>=1){
                    isPageBreak=true;
                }
                
           }else{
                if(totalLengh>20){
                    isPageBreak=true;
                }
                
                
             }
             

    }
    
    protected String formatQuantity(String quantity) {
        if(quantity != null) {
            if(quantity.length() < 4) {
                return quantity;
            }
            else {
                Integer i = quantity.length();
                String n = quantity;
                String out ='';
        
                while(i > 3) {
                    String sString = n.substring(i-3,i);
                    i -=3;
                    
                    if(out != '') {
                        out = sString + '.' + out;
                    }
                    else {
                        out = sString;
                    }
                }
        
                if(i > 0) {
                    out = n.substring(0,i) + '.' + out;
                }
                
                return out;
            }
        }
    
        return null;
    }
    
    protected Integer pageBreaker(String text, Integer max) {
        
        if(text != null && max != null) {
            outputText = '';
            Integer lines = 0;
            
            if(text.length() <= max) {
                outputText = text;
                lines += 1;
            }
            else {
                while(text != '') {
                    String subText = null;
                    
                    if(text.length() >= max) {
                        subText = text.substring(0, max);
                        Integer lastSpace = subText.lastIndexOf(' ');
                        
                        if(lastSpace > 0) {
                            subText = subText.substring(0, lastSpace);
                        }
                        
                        if(subText == '' || subText == null) {
                            subText = text.substring(0, max);
                        }
                        
                        text = text.replace(subText, '');
                    }
                    else {
                        subText = text;
                        text = '';
                    }
                    
                    outputText += subText;
                    
                    if(text != '') {
                        outputText += '<br />';
                    }
                    
                    lines += 1;
                }
            }
            
            return lines;
        }
        
        return null;
    }
    
    /** 
        Desc: Text line breaking if length's text > 30 character
    	@param: strTxt: text to do line break
    	@return: String after  line breaking
     */
    public String doLineBreakText(String strTxt)
    {
		Integer startInd=0; 
		Integer endInd=30;
		String spStr='';
		Integer i=0;
		
		if(strTxt != null)
		{
			Integer lenStr = strTxt.length();
			Integer numLine=lenStr/30;
			if(lenStr>30)
			{
				while (i < numLine) {
				    
					spStr += strTxt.substring(startInd,endInd)+ '\n';
				    startInd+=30;
				    endInd+=30;
				    i++;
			    }
			    if(math.mod(lenStr, 30) != 0)
			    {
			    	spStr += strTxt.substring(numLine*30,lenStr);
			    }
			    
			}else spStr=strTxt;
		}else spStr='';
		//System.debug('============> spSTR: ' + spStr);
		
    	return spStr;
    }
    
    public Class DtoInvoiceRecipient{
      public String invRep{get; set;}
      public String invPostalCode{get; set;}
      public String invRepStr{get; set;}
      public String invRepCity{get; set;}
      public String invUstId{get; set;}
      public String invConName{get; set;}
      public String invEmailAdr{get; set;}
      public String invTel{get; set;}
      
      
      
    }
    
    public Class DtoLineItem{
        public Integer pos{get;set;} 
        public boolean isFirst{get;set;}
        public boolean isPartnerportal{get;set;}
        public boolean isContent{get;set;}
        public boolean breakPoint{get;set;}
        public boolean isColorGray{get;set;}
        public integer index {get;set;}
        public String price{get;set;}
        public String Guaranteed_AI{get;set;}
        public String plan_Volume{get;set;}
        public String price_Gross{get;set;}
        public String customer_discount{get;set;}
        public String discount1{get;set;}
        public String discount2{get;set;}
        public String discount3{get;set;}
        public String price_net{get;set;}
        public QuoteLineItem oppItem{get;set;}
        public Boolean isPacket{get;set;}
        public Boolean isDescription{get;set;}
        
        public String listPrice {get;set;}
        public String targetingFee {get;set;}
        public String site {get;set;}
        public String size {get;set;}
        public String product {get;set;}
        public String description {get;set;}
        
        public String targetingFee2 {get; set;}
        public String amountNetNetNet {get; set;}
        public String preisEinheit{get; set;}
        public String oppItemCustNet{get; set;}
        public String oppItemCPMNetNetNet{get; set;}
        public String amountNet2eBay {get; set;} //Sambath SENG 30.08.2021 US-0010236
        public String oppItemCPMNet{get; set;} //Sambath SENG 30.08.2021 US-0010236
        
    }
    protected String format(Decimal value,String typ){
        if(value == null || value == 0){
            return '';
        }else{
            return FormatHelper.format(value) + typ;
        }
    }
    protected Decimal checkNull(Decimal value){
        return value == null ? 0 : value;
    }
    
 
}