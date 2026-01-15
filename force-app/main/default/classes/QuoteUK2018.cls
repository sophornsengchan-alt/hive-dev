/**C.R.O*/
public with sharing class QuoteUK2018 extends AngebotControllerOVK{

    public QuoteUK2018(ApexPages.StandardController controller){
        super(controller);
        dateToday = System.Now().format('dd/MM/yyyy');
    }
    
	protected override void formatBruttoumsatz() {
//      loFo_Currency = LocaleFormatter.getCurrency(null); // we need currency from the opp
        loFo_Bruttoumsatz_3 = LocaleFormatter.getLocaleFormat(BRUTTOUMSATZ_3, 'de_DE');
        loFo_Bruttoumsatz_5 = LocaleFormatter.getLocaleFormat(BRUTTOUMSATZ_5, 'de_DE');
        loFo_Bruttoumsatz_10 = LocaleFormatter.getLocaleFormat(BRUTTOUMSATZ_10, 'de_DE');
        loFo_Bruttoumsatz_15 = LocaleFormatter.getLocaleFormat(BRUTTOUMSATZ_15, 'de_DE');
        loFo_Bruttoumsatz_20 = LocaleFormatter.getLocaleFormat(BRUTTOUMSATZ_20, 'de_DE');
        loFo_Bruttoumsatz_25 = LocaleFormatter.getLocaleFormat(BRUTTOUMSATZ_25, 'de_DE');
        loFo_Bruttoumsatz_30 = LocaleFormatter.getLocaleFormat(BRUTTOUMSATZ_30, 'de_DE');
    }

    /*****************************************************************************************************************************
    @ Change history: 30.08.2021 / Sambath Seng / US-0010236, replace some of the revenue fields.
    *****************************************************************************************************************************/
    public override void bindQuote(){
    	// System.debug('<<<<<SubMethode');

        //Sambath SENG 30.08.2021 US-0010236, add 'Amount_Net2eBay__c' to quoteBnd
        quoteBnd =[Select Id,RecordType.Name,Approved__c,Exit_Clause__c,Number_of_Exit_Days__c,Owner.UserRole.Name
                         , Template_language__c,Amount_incl_Targeting__c
                         , kumulierter_Rabatt_vor_AE__c, Amount_Net_Net_Net__c, Amount_Net2eBay__c, CurrencyIsoCode
                         , Amount__c, AE__c, opportunity.Agency__r.BillingStreet, opportunity.Agency__r.BillingCity, opportunity.Agency__r.BillingPostalCode
                         , Account.BillingStreet, Account.BillingCity, Account.BillingPostalCode
                         , Account.Name, Account.EBH_VATNumber__c
                         , opportunity.Agency__r.Name, opportunity.Agency__r.EBH_VATNumber__c
                         , LineItems_Sort_Type__c, opportunityId
                         from Quote 
                         where Id=: quoteId];
        /*If(quoteBnd.Owner.UserRole.Name.contains('Dealer')) {
            isDealer = true;
        } else {
            isDealer = false;
        }*/
        loFo_Currency = quote.CurrencyIsoCode;
        amountTargeting = LocaleFormatter.getLocaleFormat(quoteBnd.Amount_incl_Targeting__c, 'de_DE');
        discount = format(quoteBnd.kumulierter_Rabatt_vor_AE__c,'');
        Decimal discount = (checkNull(quoteBnd.Amount_incl_Targeting__c) * checkNull(quoteBnd.kumulierter_Rabatt_vor_AE__c)) /100;
        amountDiscount = LocaleFormatter.getLocaleFormat(discount, 'de_DE');
        Decimal cusNet = checkNull(quoteBnd.Amount_incl_Targeting__c) * ((100-checkNull(quoteBnd.kumulierter_Rabatt_vor_AE__c))/100);
        customerNet = LocaleFormatter.getLocaleFormat(cusNet, 'de_DE');

        //Sambath SENG 30.08.2021 US-0010236, replace 'Amount_Net_Net_Net__c' with 'Amount_Net2eBay__c'
        //Decimal com = (checkNull(quoteBnd.Amount_incl_Targeting__c) * ((100-checkNull(quoteBnd.kumulierter_Rabatt_vor_AE__c))/100))- checkNull(quoteBnd.Amount_Net_Net_Net__c);
        Decimal com = (checkNull(quoteBnd.Amount_incl_Targeting__c) * ((100-checkNull(quoteBnd.kumulierter_Rabatt_vor_AE__c))/100))- checkNull(quoteBnd.Amount_Net2eBay__c);

        commission = LocaleFormatter.getLocaleFormat(com, 'de_DE');

        //Sambath SENG 30.08.2021 US-0010236, replace 'Amount_Net_Net_Net__c' with 'Amount_Net2eBay__c'
        //netTotal = LocaleFormatter.getLocaleFormat(quoteBnd.Amount_Net_Net_Net__c, 'de_DE');
        netTotal = LocaleFormatter.getLocaleFormat(quoteBnd.Amount_Net2eBay__c, 'de_DE');

        getLanguage(quoteBnd.Template_language__c == null ? 'German' : quoteBnd.Template_language__c);
        /*
        if(opp.kumulierter_Rabatt_vor_AE__c != null) {
        kRabattVorAE = opp.kumulierter_Rabatt_vor_AE__c;
        }
        */
        
        oppAmount =  LocaleFormatter.getLocaleFormat(checkNull(quoteBnd.Amount__c), 'de_DE'); // *1 opp.Amount__c
        oppApreiszus = LocaleFormatter.getLocaleFormat((checkNull(quoteBnd.Amount_incl_Targeting__c) - checkNull(quoteBnd.Amount__c)), 'de_DE');   //*2 opp.Amount_incl_Targeting__c - opp.Amount__c
        oppAmountInclTarg = LocaleFormatter.getLocaleFormat(checkNull(quoteBnd.Amount_incl_Targeting__c), 'de_DE'); //*3 opp.Amount_incl_Targeting__c
        
        //Sambath SENG 30.08.2021 US-0010236, replace 'Amount_Net_Net_Net__c' with 'Amount_Net2eBay__c'
        //Double valoppKundenetto = (quoteBnd.AE__c && quoteBnd.Amount_Net_Net_Net__c != null ? (quoteBnd.Amount_Net_Net_Net__c / 0.85) : (quoteBnd.Amount_Net_Net_Net__c));  // *4 If opp.AE__c = True, opp.Amount_Net_Net_Net__c / 0.85, else opp.Amount_Net_Net_Net__c
        Double valoppKundenetto = (quoteBnd.AE__c && quoteBnd.Amount_Net2eBay__c != null ? (quoteBnd.Amount_Net2eBay__c / 0.85) : (quoteBnd.Amount_Net2eBay__c));
        
        oppKundenetto = LocaleFormatter.getLocaleFormat(valoppKundenetto, 'de_DE');

        //Sambath SENG 30.08.2021 US-0010236, replace 'Amount_Net_Net_Net__c' with 'Amount_Net2eBay__c'
        //oppAeProvision = LocaleFormatter.getLocaleFormat((checkNull(quoteBnd.Amount_Net_Net_Net__c) - valoppKundenetto) * -1, 'de_DE');  //*5 opp.Amount_Net_Net_Net__c - *4
        //oppAmountNetNetNet = LocaleFormatter.getLocaleFormat(checkNull(quoteBnd.Amount_Net_Net_Net__c), 'de_DE'); //*6 opp.Amount_Net_Net_Net__c
        oppAeProvision = LocaleFormatter.getLocaleFormat((checkNull(quoteBnd.Amount_Net2eBay__c) - valoppKundenetto) * -1, 'de_DE');
        oppAmountNet2eBay = LocaleFormatter.getLocaleFormat(checkNull(quoteBnd.Amount_Net2eBay__c), 'de_DE');
        
        oppAccName = doLineBreakText(quoteBnd.Account.Name);
        oppAgencyName = doLineBreakText(quoteBnd.opportunity.Agency__r.Name);
        
       
    }

    /*****************************************************************************************************************************
    @ Change history: 30.08.2021 / Sambath Seng / US-0010236, replace some of the revenue fields.
    *****************************************************************************************************************************/
    public override void getOppLineItem(){
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

        //Sambath SENG 30.08.2021 US-0010236, add 'Amount_Net2eBay__c' to strQuery and replace 'CPM_net_net_net__c' with 'CPM_net__c'
        String strQuery = 'Select PricebookEntry.Product2.Site__r.Name,'+
                          ' PricebookEntry.Product2.Site__r.Quotation_text_DE__c, PricebookEntry.Product2.Advertising_Medium__r.Dart_MasterSize__c, '+
                          ' PricebookEntry.Product2.Advertising_Medium__r.Quote_text__c, PricebookEntry.Product2.Advertising_Medium__r.Format__c, '+
                          ' PricebookEntry.Product2.RecordType.Name,'+
                          ' Sales_Price_incl_Targeting__c, UnitPrice, Billing_category__c, from_Date__c, until_Date__c,'+
                          ' Guaranteed_AI__c, Quantity, Package__c, Total_price_incl_Targeting__c, Rate_Card_Discount_percent__c,'+
                          ' Special_Agency_Discount_Percent__c, Rate_Discount_I__c, Rate_Discount_II__c, Amount_Net_Net_Net__c, Amount_Net2eBay__c,'+
                          ' Description, PricebookEntry.Product2.Name, ListPrice, '+
                          ' PricebookEntry.Product2.Placement__r.Quotation_text__c,'+
                          ' PricebookEntry.Product2.Advertising_Medium__r.Quotation_text__c, Targeting_fee2__c,'+
                          ' AE__c, CPM_net__c, SalesPriceNet__c '+
                          ' from quoteLineItem '+
                      	  ' where quoteId =: quoteId '+
                          ' and package_line_item__c = null '
        				  + strOrderBy;
         //page 1st22 lines
         //page after 33 lines
         Integer condition=FIRST_PAGE;
        for(quoteLineItem oppItem : Database.query(strQuery)){ //order by SortOrder
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
            
             //dto.site = outputText;
             dto.site=oppItem.PricebookEntry.Product2.Site__r.Name;
             //system.debug('\n\n countSite: '+countSite+' ### dto.site: '+dto.site+'\n\n');
             
             //Integer countSize = pageBreaker(oppItem.PricebookEntry.Product2.Size__c == null ? '' : oppItem.PricebookEntry.Product2.Size__c,10);
             outputText = oppItem.PricebookEntry.Product2.Advertising_Medium__r.Dart_MasterSize__c == null ? '' : oppItem.PricebookEntry.Product2.Advertising_Medium__r.Dart_MasterSize__c.replaceAll(';',';\n');
             Integer countSize = outputText.split('\n').size();
             dto.size = outputText;

             //system.debug('\n\n oppItem.PricebookEntry.Product2.Name: '+oppItem.PricebookEntry.Product2.Name+'\n\n');
             Integer countProduct = pageBreaker(oppItem.PricebookEntry.Product2.Name,23);
             //dto.product = outputText;
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
                    dto.price = LocaleFormatter.getLocaleFormat(oppItem.Sales_Price_incl_Targeting__c, 'de_DE');
                }
            }else{
                Decimal price = checkNull(oppItem.Sales_Price_incl_Targeting__c) ;
                //dto.price = FormatHelper.format(price) + ' €';
                if(price != null) {
                    dto.price = LocaleFormatter.getLocaleFormat(price, 'de_DE');
                }
            }
            dto.Guaranteed_AI = format(oppItem.Guaranteed_AI__c,'') ;
            if(oppItem.Quantity != null) {
                dto.plan_Volume = LocaleFormatter.getLocaleFormat(oppItem.Quantity, 'de_DE');//formatQuantity(oppItem.Quantity.setScale(0).toPlainString());
            }
            //dto.plan_Volume = format(oppItem.Quantity,'');
            dto.price_Gross = LocaleFormatter.getLocaleFormat(oppItem.Total_price_incl_Targeting__c, 'de_DE');
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
            //dto.amountNetNetNet =(oppItem.AE__c && oppItem.Amount_Net_Net_Net__c != null ? LocaleFormatter.getLocaleFormat((oppItem.Amount_Net_Net_Net__c / 0.85), 'de_DE')  : LocaleFormatter.getLocaleFormat(oppItem.Amount_Net_Net_Net__c, 'de_DE'));
            dto.amountNet2eBay =(oppItem.AE__c && oppItem.Amount_Net2eBay__c != null ? LocaleFormatter.getLocaleFormat((oppItem.Amount_Net2eBay__c / 0.85), 'de_DE')  : LocaleFormatter.getLocaleFormat(oppItem.Amount_Net2eBay__c, 'de_DE'));
            
            
            dto.price_net = LocaleFormatter.getLocaleFormat(oppItem.Total_price_incl_Targeting__c * ((100-oppItem.Rate_Card_Discount_percent__c)/100) * ((100-oppItem.Special_Agency_Discount_Percent__c)/100) * ((100-oppItem.Rate_Discount_I__c)/100) * ((100-oppItem.Rate_Discount_II__c)/100), 'de_DE');
            //dto.index = tmpIndex > 16 ? 0 :tmpIndex; // for doing page break
            dto.oppItem = oppItem ;
            dto.isContent=false;
            dto.isPartnerportal=false;

            if(oppItem.ListPrice != null) {
                dto.listPrice = LocaleFormatter.getLocaleFormat(oppItem.ListPrice, 'de_DE');
            }
            

            
            dto.preisEinheit  =  (('CPM').equals(oppItem.Billing_category__c) && oppItem.SalesPriceNet__c != null ?  LocaleFormatter.getLocaleFormat((oppItem.SalesPriceNet__c /* * 1000 - US9135 */), 'de_DE') : LocaleFormatter.getLocaleFormat(oppItem.SalesPriceNet__c, 'de_DE'));

            
            
            dto.targetingFee2 = (oppItem.Targeting_fee2__c != null?LocaleFormatter.getLocaleFormat(oppItem.Targeting_fee2__c, 'de_DE'):'');
            
            //Sambath SENG 30.08.2021 US-0010236, replace 'Amount_Net_Net_Net__c' with 'Amount_Net2eBay__c' & 'CPM_net_net_net__c' to 'CPM_net__c'
            // dto.oppItemCustNet = LocaleFormatter.getLocaleFormat(oppItem.Amount_Net_Net_Net__c, 'de_DE');
            //dto.oppItemCPMNetNetNet = LocaleFormatter.getLocaleFormat(oppItem.CPM_net_net_net__c, 'de_DE');
            dto.oppItemCustNet = LocaleFormatter.getLocaleFormat(oppItem.Amount_Net2eBay__c, 'de_DE');
            dto.oppItemCPMNet = LocaleFormatter.getLocaleFormat(oppItem.CPM_net__c, 'de_DE');
            
      
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
    
 
}