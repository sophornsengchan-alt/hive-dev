public with sharing class QuoteController {
        
    private Id quoteId;
    public Quote quote {get;set;} //NK:22/05/2019: #21293
    private String outputText = '';
    private Integer pageLines = 0;
    private Integer maxLines = 27;
    private Integer dLines = 0;
    private Set<String> ebaySitesSet = new Set<String>();
    
    //private Decimal amountInclTargeting = 0;
    //private Decimal amountNetNetNet = 0;
    
    public OpportunityContactRole oppContactRole {get;set;}
    public String dateToday {get;set;}
    public String amount_iT {get;set;}
    public String totalAmount {get;set;}
    public String amount_GST {get;set;}
    public String amount_GST_discount {get;set;}
    //public String amount_nNn {get;set;}
    public String lang {get;set;}
    public Boolean agency {get;set;}

    // for showing campaign totals and discounts update 8.12.2011
    public String amountDiscount{get;set;} 
    public String commission{get;set;}
    public String netTotal{get;set;}
    
    public Boolean pageBreakAfterTable {get;set;}
    public Boolean pageBreakCosts {get;set;}
    public String closeTable {get;set;}
    public String openTable {get;set;}
    public String oppDescription {get;set;}
    public String ebaySites {get;set;}
    
    public String rateDiscount2 {get;set;}
    public String amount_iT_rate {get;set;}
    
    public List<LineItem> LineItemList {get;set;}
    
    public String gst{get; set;}
    public String campaignCost{get; set;}
    public String vat{get; set;}
    public String A2OcampaignCost{get; set;}
    String strOrderBy;
    
    //NK:18/03/2020:US-0007344: here for page null and 0 check
    public Decimal discount {get;set;}
    
    public boolean isDealer{get;set;} //NK:26/12/2019:US-0006920
    
    public QuoteController(ApexPages.StandardController controller) {
        quoteId = ((Quote)controller.getRecord()).Id;
        selectQuote();
        dateToday = System.Now().format('dd/MM/yyyy'); //dd.MM.yyyy - old format
        getContactRole();
        
        if(quote.Description != null) {
            descrPageBreaker(quote.Description);
        }
        
        strOrderBy = ('Manually'.equals(quote.LineItems_Sort_Type__c) ? ' ORDER BY SortOrder' : ' ORDER BY from_date__c ASC');
        
        createLineItemList();
        
        closeTable = '</table>';
        openTable = '<table class="tableQuote">';
    }
    
    private void setLanguage(String language){
        if(language == 'English'){
            lang = 'en';
        }
        else if(language == 'German'){
            lang = 'de';
        }
    }
    
    private void getContactRole(){
        list<OpportunityContactRole> lstContactRole = [Select Role, ContactId, Contact.OwnerId, Contact.Email, Contact.Phone, Contact.Name, Contact.Fax,
                                                              Contact.MailingStreet, Contact.MailingPostalCode, Contact.MailingCity, Contact.MailingCountry, 
                                                              Contact.Account.Name, Contact.Account.BillingStreet, Contact.Account.BillingPostalCode, Contact.Account.BillingCity, 
                                                              Contact.Account.BillingCountry, Contact.Account.EBH_VATNumber__c
                                                       From OpportunityContactRole
                                                       Where OpportunityId = :quote.opportunityId and IsPrimary = true];
        
        if(lstContactRole.size() > 0) { 
            oppContactRole = lstContactRole.get(0);
            // CR: 2012-01-31
            //   Always use the Account-BillingStreet etc for Quote.
            //   Just reset values here to avoid modifying the Page(s).
            /*
            if (opp != null && quote.AccountId != null) {
                oppContactRole.Contact.MailingStreet = quote.Account.BillingStreet;
                oppContactRole.Contact.MailingPostalCode = quote.Account.BillingPostalCode;
                oppContactRole.Contact.MailingCity = quote.Account.BillingCity;
                oppContactRole.Contact.MailingCountry = quote.Account.BillingCountry;
            }
            */
            if (oppContactRole.ContactId != null && oppContactRole.Contact.AccountId != null) {
                oppContactRole.Contact.MailingStreet = oppContactRole.Contact.Account.BillingStreet;
                oppContactRole.Contact.MailingPostalCode = oppContactRole.Contact.Account.BillingPostalCode;
                oppContactRole.Contact.MailingCity = oppContactRole.Contact.Account.BillingCity;
                oppContactRole.Contact.MailingCountry = oppContactRole.Contact.Account.BillingCountry;
            }
        }
        else {
            oppContactRole=new OpportunityContactRole();
        }
    }
    /*
        HCS 18/03/2014
        //Small change on page "Quote_AU_2013"
    */
    public Boolean isVatCodeA4{
        get{
            return (quote.Vat_Code__c != null && (quote.Vat_Code__c=='A4' || quote.Vat_Code__c=='A3'));
        }
        set;}
        
    //NK:30/10/2019:US-0015825: AE__c
    /*****************************************************************************************************************************
    @ Change history: 30.08.2021 / Sambath Seng / US-0010236, replace some of the revenue fields.
    *****************************************************************************************************************************/
    private void selectQuote() {

        //Sambath SENG 30.08.2021 US-0010236, add 'Amount_Net2eBay__c' to quote
        quote = [select status, opportunity.payment_terms__c, opportunity.Company_Code__c,opportunity.owner.name, opportunity.owner.phone, opportunity.owner.fax, opportunity.owner.email, opportunity.Owner.UserRole.Name,Amount_Net_Net_Net__c,Amount_Net2eBay__c,Pricebook2.Name,AE__c,Vat_Code__c,Id, Amount_incl_Targeting__c, Template_language__c, opportunity.Agency__c, Description, 
              Rate_Discount_II__c, kumulierter_Rabatt_vor_AE__c, opportunity.Ext_Name_Campaign__c, CurrencyIsoCode, 
              AccountId, Account.Name, Account.BillingStreet, Account.BillingPostalCode, Account.BillingCity, Opportunity.Agency__r.Name, Opportunity.Primary_Contact__r.Name, Opportunity.Primary_Contact__r.Phone,
              Opportunity.Primary_Contact__r.Email, Account.BillingCountry, LineItems_Sort_Type__c, GST__c, GST_Amount__c, name, opportunityId from Quote where Id = :quoteId];
        
        setLanguage(quote.Template_language__c == null ? 'German' : quote.Template_language__c);
        
        isDealer = quote.opportunity.Owner.UserRole.Name.contains('Dealer');
        //system.debug('\n\n #lang: '+lang+'\n\n');
        
        Decimal amount_iT_rateDEC = null;
        
        if(quote.Rate_Discount_II__c != null && quote.Rate_Discount_II__c != 0) {
            Decimal rD2 = (quote.Amount_incl_Targeting__c / 100) * quote.Rate_Discount_II__c;
            //system.debug('\n\n rD2: '+rD2+'\n\n');
            rateDiscount2 = FormatHelper.format(rD2, UserInfo.getLocale());
            amount_iT_rateDEC = quote.Amount_incl_Targeting__c - rD2;
        }
        
        amount_iT = FormatHelper.format(quote.Amount_incl_Targeting__c,UserInfo.getLocale());
        
        if(amount_iT_rateDEC != null) {
            amount_iT_rate = FormatHelper.format(amount_iT_rateDEC, UserInfo.getLocale());
        }
        else {
            amount_iT_rate = amount_iT;
        }

        totalAmount = amount_iT;

        amount_GST = FormatHelper.format(quote.GST_Amount__c, UserInfo.getLocale());

        if(quote.GST_Amount__c != null){
            totalAmount = FormatHelper.format(quote.Amount_incl_Targeting__c + quote.GST_Amount__c, UserInfo.getLocale());
        }
        
        
        //amount_nNn = formatEuro(quote.Amount_Net_Net_Net__c.setScale(2).toPlainString().replace('.',','));
        
        if(lang != 'de') {
            /*amount_iT = kpChanger(amount_iT);*/
            //amount_nNn = kpChanger(amount_nNn);
            /*amount_iT_rate = kpChanger(amount_iT_rate);*/
            
            /*
            if(rateDiscount2 != null) {
                rateDiscount2 = kpChanger(rateDiscount2);
            }
            */
        }
        discount = (checkNull(quote.Amount_incl_Targeting__c) * checkNull(quote.kumulierter_Rabatt_vor_AE__c)) /100;
        //Decimal discount = checkNull(quote.Amount_incl_Targeting__c) * checkNull(quote.Rate_Discount_II__c) / 100;
        amountDiscount = FormatHelper.format(discount,UserInfo.getLocale());

        //Sambath SENG 30.08.2021 US-0010236, replace 'Amount_Net__c' with 'Amount_Net2eBay__c'
        // Decimal com = (checkNull(quote.Amount_incl_Targeting__c) * ((100-checkNull(quote.kumulierter_Rabatt_vor_AE__c))/100))- checkNull(quote.Amount_Net__c);
        Decimal com = checkNull(quote.Amount_incl_Targeting__c) - checkNull(quote.Amount_Net2eBay__c);

        //Decimal com = checkNull(quote.Amount_incl_Targeting__c) - checkNull(quote.Amount_Net__c) - discount;
        commission = FormatHelper.format(com, UserInfo.getLocale());
        //NK:28/11/2019: US-0006484
        //netTotal = FormatHelper.format(quote.Amount_Net__c,UserInfo.getLocale());

        //Sambath SENG 30.08.2021 US-0010236, replace 'Amount_Net__c' with 'Amount_Net2eBay__c' & replace 'Amount_Net__Net_Net__c' with 'Amount_Net2eBay__c'
        // netTotal = (quote.Pricebook2.Name+'').startsWith('DE')?FormatHelper.format(quote.Amount_Net_Net_Net__c,UserInfo.getLocale()):FormatHelper.format(quote.Amount_Net__c,UserInfo.getLocale());
        // gst = (quote.Amount_Net__c != null ? FormatHelper.format(quote.Amount_Net__c * 0.1, UserInfo.getLocale()):'');
        // campaignCost = (quote.Amount_Net__c != null ? FormatHelper.format(quote.Amount_Net__c * 1.1, UserInfo.getLocale()):'');
        // vat = (quote.Amount_Net__c != null ? FormatHelper.format(quote.Amount_Net__c * 0.2, UserInfo.getLocale()):'');
        // A2OcampaignCost = (quote.Amount_Net__c != null ? FormatHelper.format(quote.Amount_Net__c * 1.2, UserInfo.getLocale()):'');
        netTotal = (quote.Pricebook2.Name+'').startsWith('DE')?FormatHelper.format(quote.Amount_Net2eBay__c,UserInfo.getLocale()):FormatHelper.format(quote.Amount_Net2eBay__c,UserInfo.getLocale()); 
        gst = (quote.Amount_Net2eBay__c != null ? FormatHelper.format(quote.Amount_Net2eBay__c * 0.1, UserInfo.getLocale()):'');
        campaignCost = (quote.Amount_Net2eBay__c != null ? FormatHelper.format(quote.Amount_Net2eBay__c * 1.1, UserInfo.getLocale()):'');
        vat = (quote.Amount_Net2eBay__c != null ? FormatHelper.format(quote.Amount_Net2eBay__c * 0.2, UserInfo.getLocale()):'');
        A2OcampaignCost = (quote.Amount_Net2eBay__c != null ? FormatHelper.format(quote.Amount_Net2eBay__c * 1.2, UserInfo.getLocale()):'');

   //     amount_GST_discount = FormatHelper.format(checknull(quote.Amount_incl_Targeting__c)-checknull(com)+checknull(quote.GST_Amount__c), UserInfo.getLocale());
   //     //removed gst tax 
   //     //DHE 2019-06-04
          amount_GST_discount = FormatHelper.format(checknull(quote.Amount_incl_Targeting__c)-checknull(com), UserInfo.getLocale());
        if(quote.opportunity.Agency__c != null) {
            agency = true;
        }
        else {
            agency = false;
        }
    }
    
    /*
    private String kpChanger(String s) {
        s = s.replace('.','k');
        s = s.replace(',','p');
        s = s.replace('k',',');
        s = s.replace('p','.');
    
        return s;
    }
    */
    @testVisible 
    private void createLineItemList() {
        
        String strQuery = 'Select PricebookEntry.Product2.Site__r.Name, Sales_Price_incl_Targeting__c, Billing_category__c, from_Date__c, until_Date__c, Quantity,'+
                          ' Total_price_incl_Targeting__c, PricebookEntry.Product2.Name, Description'+
                          ' from QuoteLineItem '+
                          ' where quoteid =: quoteId '+
                          ' and package_line_item__c = null '
                          + strOrderBy;
        
        List<QuoteLineItem> qliList = Database.query(strQuery);
        
        LineItemList = new List<LineItem>();
        
        String nextColor = 'lightgrey';
        
        for(QuoteLineItem qli : qliList) {
            ebaySitesSet.add(qli.PricebookEntry.Product2.Site__r.Name);
            
            LineItem li = new LineItem();
            
            li.quoteLineItem = qli;
            
            if(qli.from_Date__c != null) {
                li.startDate = qli.from_Date__c.format();
            }
            
            if(qli.from_Date__c != null) {
                li.endDate = qli.until_Date__c.format();
            }

            
        
            //system.debug('\n\n #qli.Quantity: '+qli.Quantity+'\n\n');
            
            li.quantity = formatQuantity(qli.Quantity.setScale(0).toPlainString());
            
            //system.debug('\n\n #li.quantity: '+li.quantity+'\n\n');
            
            if (qli.Billing_category__c == 'CPM') {
                Decimal sPiT_cpm = qli.Sales_Price_incl_Targeting__c ;
                li.salesPrice_iT =FormatHelper.format(sPiT_cpm, UserInfo.getLocale());
            } else {
                li.salesPrice_iT =FormatHelper.format(qli.Sales_Price_incl_Targeting__c, UserInfo.getLocale());
            }
            
            li.totalPrice_iT = FormatHelper.format(qli.Total_price_incl_Targeting__c, UserInfo.getLocale());
            
            //amountInclTargeting += qli.Total_price_incl_Targeting__c;
            //amountNetNetNet += qli.Amount_Net_Net_Net__c;
            
            if(lang != 'de') {
                /*li.salesPrice_iT = kpChanger(li.salesPrice_iT);*/
                /*li.totalPrice_iT = kpChanger(li.totalPrice_iT);*/
                /*li.quantity = kpChanger(li.quantity);*/
            }
            
            li.quantity = FormatHelper.format(qli.quantity,UserInfo.getLocale());
            li.quantity = li.quantity.subString(0, li.quantity.length()-3); // quantity need to show as ex: 1,000 instead of 1,000.00
            
            if(nextColor == '') {
                li.backgroundColor = '';
                nextColor = 'lightgrey';
            }
            else if(nextColor == 'lightgrey') {
                li.backgroundColor = 'background-color:#F9F9F9;';
                nextColor = '';
            }
            
            Integer siteIdLines = pageBreaker(qli.PricebookEntry.Product2.Site__r.Name, 10);
            li.siteId = outputText;
            
            //system.debug('\n\n #li.siteId: '+li.siteId+' #lines: '+siteIdLines+'\n\n');
            
            Integer productLines = pageBreaker(qli.PricebookEntry.Product2.Name, 35);
            li.product = outputText;
            //system.debug('\n\n li.product: '+li.product+'\n\n');
            
            //system.debug('\n\n #li.product: '+li.product+' #lines: '+productLines+'\n\n');
            
            Integer moreLines = 0;
            
            if(siteIdLines > productLines) {
                pageLines += siteIdLines;
                moreLines = siteIdLines;
            }
            else {
                pageLines += productLines;
                moreLines = productLines;
            }
            
            Integer descriptionLines = 0;
            
            if(qli.Description != null) {
                descriptionLines = pageBreaker(qli.Description, 130);
                li.lineDescription = outputText;
                pageLines += descriptionLines;
            }
            
            // system.debug('\n\n #pageLines: '+pageLines+'\n\n');
            
            if(pageLines > maxLines) {
                li.pageBreak = true;
                pageLines = moreLines + descriptionLines;
                maxLines = 41;
                li.backgroundColor = 'background-color:#F9F9F9;';
                nextColor = '';
            }
            else {
                li.pageBreak = false;
            }
            
            LineItemList.add(li);
        }
        
        for(String eSite : ebaySitesSet) {
            if(ebaySites == null || ebaySites == '') {
                ebaySites = eSite;
            }
            else {
                ebaySites += ', ' + eSite;
            }
        }
        
        if(pageLines+3 > maxLines) {
            pageBreakCosts = true;
            pageLines = 0;
        }
        else {
            pageBreakCosts = false;
        }
        
        if(pageLines+3 > maxLines-(17+dLines)) {
            pageBreakAfterTable = true;
        }
        else {
            pageBreakAfterTable = false;
        }
        /*
        amount_iT = formatEuro(amountInclTargeting.setScale(2).toPlainString().replace('.',','));
        amount_nNn = formatEuro(amountNetNetNet.setScale(2).toPlainString().replace('.',','));
        
        if(lang != 'de') {
            amount_iT = kpChanger(amount_iT);
            amount_nNn = kpChanger(amount_nNn);
        }
        */
    }
    
    public class LineItem {
        public quoteLineItem quoteLineItem {get;set;}
        public String startDate {get;set;}
        public String endDate {get;set;}
        public String quantity {get;set;}
        public String salesPrice_iT {get;set;}
        public String totalPrice_iT {get;set;}
        public String backgroundColor {get;set;}

        public String siteId {get;set;}
        public String product {get;set;}
        
        public Boolean pageBreak {get;set;}
        public String lineDescription {get;set;}
    }
    
    /*
    private String formatEuro(String euro) {
        List<String> eList = euro.split(',');
        
        if(eList.size() > 1) {
            if(eList.get(0).length() < 4) {
                return euro + ' €';
            }
            else {
                Integer i = eList.get(0).length();
                String n = eList.get(0);
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
                
                out = out + ',' + eList.get(1) + ' €';
                
                return out;
            }
        }
    
        return null;
    }
    */
    
    private String formatQuantity(String quantity) {
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
   
   @testVisible 
    private Integer pageBreaker(String text, Integer max) {
        
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
                        
                        //text = text.replace(subText, '');
                        text = text.substring(subText.length());
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
    @testVisible
    private void descrPageBreaker(String descr) {
                    
        List<String> DescrList = descr.split('\n');
        Integer z = 0;
        String outputString = '';
        Integer max = 105;
        
        for(String s : DescrList) {
            // system.debug('\n\n #s: '+s+'\n\n');
            if(s.length() == 0) {
                outputString += '\n';
                z++;
            }
            else if(s.length() <= max) {
                outputString += s+'\n';
                z++;
            }
            else {
                String sWork = s;
                Boolean keepSpace = false;
                
                if(sWork.startsWith('-')) {
                    // system.debug('\n\n - \n\n');
                    keepSpace = true;
                }
                
                while(sWork != '') {
                    // system.debug('\n\n #sWork: '+sWork+'\n\n');
                    if(sWork.length() >= max) {
                        String sSub = sWork.substring(0, max);
                        Integer posLastSpace = sSub.lastIndexOf(' ');
                        
                        String sSubPart = '';
                        
                        if(posLastSpace > 0) {
                            sSubPart = sSub.substring(0, posLastSpace);
                        }
                        else {
                            sSubPart = sSub.substring(0, max);
                        }
                        
                        //sWork = sWork.replaceFirst(sSubPart, '');
                        sWork = sWork.substring(sSubPart.length());
                        
                        // system.debug('\n\n sSubPart: '+sSubPart+'\n\n');
                        
                        if(sSubPart.startsWith(' ') && keepSpace == false) {
                            outputString += sSubPart.replaceFirst(' ', '')+'\n';
                            z++;
                        }
                        else if(sSubPart.startsWith(' ') && keepSpace == true) {
                            // system.debug('\n\n keepSpace \n\n');
                            outputString += sSubPart.replaceFirst(' ', '&nbsp;&nbsp;')+'\n';
                            z++;
                        }
                        else {
                            outputString += sSubPart+'\n';
                            z++;
                        }
                    }
                    else {
                        String sSub2 = null;
                        
                        if(sWork.startsWith(' ') && keepSpace == true) {
                            // system.debug('\n\n keepSpace \n\n');
                            sWork = sWork.replaceFirst(' ', '&nbsp;&nbsp;');
                            sSub2 = sWork.substring(0, sWork.length());
                        }
                        else if(sWork.startsWith(' ')) {
                            sSub2 = sWork.substring(1, sWork.length());
                        }
                        else {
                            sSub2 = sWork.substring(0, sWork.length());
                        }
                        
                        sWork = '';
                        outputString += sSub2+'\n';
                        z++;
                    }
                }
            }
        }
        
        // system.debug('\n\n z: '+z+'\n\n');
        // system.debug('\n\n outputString: \n\n'+outputString+'\n\n');
        
        dLines = z;
        
        oppDescription = outputString.replace('\n', '<br />');
    }
    
    /**
     * test if a value is null. If the value is null return 0, if not return the original value
     */
    private Decimal checkNull(Decimal value){
        return value == null ? 0 : value;
    }
    /*
    private String format(Decimal value,String typ){
        if(value == null || value == 0){
            return '';
        }else{
            return FormatHelper.format(value) + typ;
        }
    }
    */
    public String getCurrencyCode() {
        if (quote != null && quote.CurrencyIsoCode != null) {
            return quote.CurrencyIsoCode;
        } else {
            return 'EUR';
        }
    }
    
}