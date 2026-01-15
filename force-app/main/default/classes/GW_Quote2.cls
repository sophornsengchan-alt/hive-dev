/*****************************************************************************************************************************
@ Class:   GW_Quote2
@ Author:   Acmatac SEING (acmatac.seing@gaea-sys.com)
@ Purpose:  All Quote related functions. Another new version of GW_Quote but new features.
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 8.09.2020 / Acmatac SEING / Created the  Class
@                 25.03.2021/ Mony Nou / US-0009260 - [Ads 2020] OLI Trigger to QLI/AP, Fields & Syncing
@                 08.04.2021/ Mony Nou / US-0009334 - [Ads 2020] Handling Discounts
@                 19.10.2021/ Mony Nou / US-0010299 - ADS - Ability to Withdraw an Approved Quotev
@                 25.10.2021/ Mony Nou / US-0008416 - Move method from GW_Quote to GW_Quote2 so that we can completely deprecated GW_Quote
@                 05.11.2021/ Sophal Noch / US-0010628 - ADS - Allow edit rights on Revised Quote Line Items in past (with date validation)
@               : 22.03.2022/ Loumang SENG / US-0011508 - NA ADS - Unable to Create Revised Quote on PG Opps
@               : 21.07.2022/ Sophal Noch / US-0012062 - NA ADS - Monthly Forecasting Incorrect
@               : 06.09.2023 / Sophal Noch / US-0014020 - PL Opportunity Process - Ad product Sync
@               : 30.06.2025 / Sambath Seng / Cannot withdraw approval on quote that I approved
*****************************************************************************************************************************/
public with sharing class GW_Quote2 {
    public static final String QUOTE_STATUS_APPROVED = 'Approved';
    private static final String QUOTE_PG_RT_ID = ApexUtil.getRecordTypeByName('Quote','PG_PMP_Quote').Id;
    public static final String ADVERTISING_NA = 'Advertising NA';

    /*****************************************************************************************************************************
    @ Method:   copyQlinesToAP
    @ Author:   Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:  US-0008016 [Ads 2020] New Functionality - Sync of QuoteLineItems-> to Ad Product
    @ Event:    Quote
                - After Update
                QuoteLine Item
                - After Insert
                - After Update
                - After Delete
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     Set<Id> primQuoteIds => Quote Id
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 2.09.2020 / Acmatac SEING / Created the  Method
    @                 21.07.2022 / Sophal Noch / US-0012062 - NA ADS - Monthly Forecasting Incorrect
    *****************************************************************************************************************************/
    public static void copyQlinesToAP(Set<Id> primQuoteIds){
        if(primQuoteIds.isEmpty()) return;

        // US-0008726 Sophal 16/12/2020 query AdProduct__r.Opportunity__c, so it can check if thier opportunity is the same.
        Map<Id, QuoteLineItem> mQLI = new Map<Id, QuoteLineItem>((List<QuoteLineItem>) QueryUtil.queryRecords('QuoteLineItem', 'QuoteId IN:value1 ', new Set<String>{'Quote.OpportunityId','AdProduct__r.Opportunity__c'}, new Map<String,Object>{'value1' => primQuoteIds}));
        //List<QuoteLineItem> lstQLI = [SELECT Id, AdProduct__c FROM QuoteLineItem]; //MN-12052021-Unuse 
        Set<Id> adIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();

        List<QLI2AP_Mapping__mdt> fieldMappers = (List<QLI2AP_Mapping__mdt>) QueryUtil.queryRecords('QLI2AP_Mapping__mdt');
        
        Set<Id> setPrimQuoteIdWithoutQli = primQuoteIds.clone(); // 21.07.2022/ Sophal Noch / US-0012062
        Map<Id, Ad_Product__c> mQLI_AP = new Map<Id, Ad_Product__c>();
        for(QuoteLineItem qli : mQLI.values()){
            setPrimQuoteIdWithoutQli.remove(qli.QuoteId); // Sophal : remove primary QuoteId from Set because it still has QLI.
            Ad_Product__c oAP = new Ad_Product__c(Opportunity__c = qli.Quote.OpportunityId);
            for(QLI2AP_Mapping__mdt fieldMapper: fieldMappers) {
                oAP.put(fieldMapper.AP_Field__c, qli.get( fieldMapper.Quote_LineItem_Field__c) );
            }
            if(String.isNotBlank(qli.AdProduct__c) && qli.Quote.OpportunityId == qli.AdProduct__r.Opportunity__c){ // US-0008726 Sophal 16/12/2020 only quotelineitem and ad product that share the same opp can be synced
                adIds.add(qli.AdProduct__c);
                oAP.Id = qli.AdProduct__c;
            }
            oAP.Quote_Line_Item__c = qli.Id; // 29.10.2020 / Sophal Noch / US-0008471 : so in Ad Product Trigger,it know Quote is revised or not.
            mQLI_AP.put(qli.Id, oAP);
            oppIds.add(qli.Quote.OpportunityId);
        }

        if(!setPrimQuoteIdWithoutQli.isEmpty()){ // 21.07.2022/ Sophal Noch / US-0012062 if setPrimQuoteIdWithoutQli is not empty, it mean that There are Primary Quotes that has no QLI so All Ad_Product__c records for Those Primary Quote should be deleted.
            for(Quote prQuote : [Select Id, OpportunityId From Quote Where Id IN :setPrimQuoteIdWithoutQli]){
                oppIds.add(prQuote.OpportunityId); // Sophal : add Quote.OpportunityId to the set oppIds, so Ad_Product__c records below are deleted accordingly 
            }
        }

        // Delete all unrelated AdProduct to the Primary Quote
        
        // Sophal/ 26.04.2021 / US-0009456 delete childs of adproduct to bypass error "Record has too many associations with other objects to be deleted"
        // Sophal/ 26.04.2021 / US-0009456 checking Ad_Product__r.Ad_Id__c = null because of this story US-0008866
        // WithoutSharing.doDelete([SELECT Id FROM Ad_Revenue_Monthly__c WHERE Ad_Product__r.Ad_Id__c = null AND Ad_Product__r.Opportunity__c IN: oppIds AND Ad_Product__c NOT IN: adIds]);
        // 21.07.2022/ Sophal Noch / US-0012062 using Ad_Product__r.IsInGamOrCallisto__c is more correct than Ad_Product__r.Ad_Id__c because Callisto with Ad_Product__r.Ad_Id__c Not Empty can still be deleted if Opportunity__r.StageName is not 'Closed Won' yet.
        WithoutSharing.doDelete([SELECT Id FROM Ad_Revenue_Monthly__c WHERE Ad_Product__r.IsInGamOrCallisto__c = false AND Ad_Product__r.Opportunity__c IN: oppIds AND Ad_Product__c NOT IN: adIds]);
        WithoutSharing.doDelete([SELECT Id FROM Ad_Product__c WHERE Opportunity__c IN: oppIds AND Id NOT IN: adIds]);

        // Insert/Update AdProduct to make it Sync with QLI
        WithoutSharing.doUpsert(mQLI_AP.values());

        // After AdProduct inserted, Link it back to QLI
        List<QuoteLineItem> lstNewQLI = new List<QuoteLineItem>();
        for(Id qliId : mQLI_AP.keySet()){
            Ad_Product__c oAP = mQLI_AP.get(qliId);
            if(!adIds.contains(oAP.Id)){
                // QuoteLineItem qli = mQLI.get(qliId); // US-0008726 Sophal 16/12/2020 disable because to avoid uneccessary fields in updating records
                QuoteLineItem qli = new QuoteLineItem(Id = mQLI.get(qliId).Id); // US-0008726 Sophal 16/12/2020 just use id to set in object and add AdProduct__c Id later.
                qli.AdProduct__c = oAP.Id;
                lstNewQLI.add(qli);
            }
        }

        if(GW_QuoteLineItem.byPassValidation) { //US-0011508
            if(!lstNewQLI.isEmpty()) WithoutSharing.doUpdate(lstNewQLI);
        }else{
            GW_QuoteLineItem.byPassValidation = true;
            if(!lstNewQLI.isEmpty()) WithoutSharing.doUpdate(lstNewQLI);
            GW_QuoteLineItem.byPassValidation = false;
        }

        // Calculate Amount of Opportunity
        if(!oppIds.isEmpty()) calculateOppAmount(oppIds);
    }
    
    /*****************************************************************************************************************************
    @ Method:   calculateOppAmount
    @ Author:   Acmatac SEING (acmatac.seing@gaea-sys.com)
    @ Purpose:  US-0008016 Recalculate the Opportunity Amount based on the Total Amount of each Ad Product
                - Set Quote Is Sync'ing to True
                - Set Opportunity Amount to the Total of each Ad Product
                - Set 'Quote is Sync'ing' to False
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     Set<Id> oppIds => Opportunity Id
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 2.09.2020 / Acmatac SEING / Created the  Method
    @               : 16.03.2021/ Vadhanak Voun/ US-0009221 - [Ads 2020] Field & Formulas for Revenue Recognition and Compliance
    @               : 03.06.2021/ Sophal Noch/ US-0009585 [NA] NA Deals, Recall Deals out of Approval Process if Deal is Cancelled
    @               : 26.01.2022/ Sophal Noch/ US-0010886 - 1PD Campaign Tracking
    @               : 01.04.2022/ Loumang SENG / US-0011424 - NA Ads - Sync Amount net2eBay w PG Opps
    *****************************************************************************************************************************/
    public static void calculateOppAmount(Set<Id> oppIds){
        List<Opportunity> lstOpp = [
            SELECT Id,
                (Select Id, RecordTypeId,Price_Book__c, Pricebook2Id, Campaign_Start__c, Campaign_End__c, AE__c, Name_Discount_I__c,Name_Discount_II__c,Rate_Discount_II__c,Rate_Special_Agency_Discount__c From Quotes Where Primary_Quote__c = true Order by Id Desc Limit 1), 
                // (SELECT Id, TotalPrice__c FROM Ad_Products__r)
                (SELECT Id,Amount_Net2eBay__c, TotalPrice__c FROM Ad_Products__r Where Quote_Line_Item__c = null OR Quote_Line_Item__r.package_line_item__c = null OR Quote_Line_Item__r.package_line_item__c = '') // Sophal:26/01/2022:US-0010886
            FROM Opportunity WHERE Id IN: oppIds
        ];
        
        List<Opportunity> listOppToDisableSync = new List<Opportunity>();

        for(Opportunity opp : lstOpp){

            // Set Quote Is Sync'ing to True
            opp.Quote_Sync_In_Progress__c = true;
            opp.Amount = 0;
            
            //NK:US-0009221
            if(!opp.Quotes.isEmpty())
            {
                opp.Pricebook2Id = opp.Quotes[0].Pricebook2Id; 
                opp.AE__c = opp.Quotes[0].AE__c;  //MN:US-0009260 - Sync AE from Quote -> Opportunity
                
                //MN:US-0009334 - [Ads 2020] Handling Discounts 
                opp.Name_Discount_I__c = opp.Quotes[0].Name_Discount_I__c;
                opp.Name_Discount_II__c = opp.Quotes[0].Name_Discount_II__c;
                opp.Rate_Discount_II__c = opp.Quotes[0].Rate_Discount_II__c; 
                opp.Rate_Discount_II__c = opp.Quotes[0].Rate_Discount_II__c; 
                opp.Rate_Special_Agency_Discount__c = opp.Quotes[0].Rate_Special_Agency_Discount__c;
                //END - MN:US-0009334
                
            }           

            listOppToDisableSync.add(new Opportunity(Id=opp.Id,Quote_Sync_In_Progress__c=false)); // US-0008726 Sophal 16/12/2020 for update Quote_Sync_In_Progress__c = false later.

            // US-0008472, @Ratha Sim [Ads 2020] Sync Primary Quote start and end dates to Opportunity
            // 03.06.2021/ Sophal Noch/ US-0009608 move to where we check Quotes.Campaign_Start__c or Quotes.Campaign_End__c
            // if(!opp.Quotes.isEmpty() && opp.Quotes[0].Campaign_Start__c != null && opp.Quotes[0].Campaign_End__c != null){
            //     opp.Start_Date__c = opp.Quotes[0].Campaign_Start__c;
            //     opp.End_Date__c = opp.Quotes[0].Campaign_End__c;
            // }

    
            for(Ad_Product__c aP : opp.Ad_Products__r){
                //LA-01-04-2022: US-0011424
                if(opp.Quotes[0].RecordTypeId == QUOTE_PG_RT_ID && opp.Quotes[0].Price_Book__c == ADVERTISING_NA){
                    aP.Amount_Net2eBay__c = aP.Amount_Net2eBay__c == null ? 0 : aP.Amount_Net2eBay__c;
                    opp.Amount += aP.Amount_Net2eBay__c;
                }else {//END - LA:US-0011424
                    aP.TotalPrice__c = aP.TotalPrice__c == null ? 0 : aP.TotalPrice__c;
                    opp.Amount += aP.TotalPrice__c;

                }
               
            }
        }
        WithoutSharing.doUpdate(lstOpp);


        // US-0008726 Sophal 16/12/2020 disable because no need to loop over opp record again
        // // Set 'Quote is Sync'ing' to False
        // for(Opportunity opp : lstOpp){
        //  opp.Quote_Sync_In_Progress__c = false;
        // }
        // WithoutSharing.doUpdate(lstOpp);

        // US-0008726 Sophal 16/12/2020 Set 'Quote is Sync'ing' to False
        if(!listOppToDisableSync.isEmpty()){
            WithoutSharing.doUpdate(listOppToDisableSync);
        }

    }

    /*****************************************************************************************************************************************************************
    @ Method:         updateQuoteToNonPrimary
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008858
    @                 As a...
    @                 account manager
    @                 Want to...
    @                 click 'send to docusign' on a quote
    @                 So that...
    @                 when everyone signs, the system automatically updates 'dually signed' and 'make primary' checkbox from DocuSign
    @                 Description
    @                 AC1) As a user with 'standard ads user profile' and 'ebay advertisment account manager' permission set
    @                 When i click on 'primary quote' checkbox on a revised quote
    @                 the 1st primary quote needs to be unmarked as primary quote.
    @                 currently, when i do this, there are 2 primary quotes
    @                 image.png
    @                 The 'dually signed' checkbox need to follow the same logic as clicking the 'Make Primary' button on Quote.
    @                 when i click on 'Make Primary' button on a quote, the previous primary quote is unchecked as primary.
    @                 Once the same logic is available on the 'primary quote' checkbox as the 'make primary' button,
    @                 Docusign will mark 'dually signed' and 'primary quote' checkbox as true.
    @ Event:          after update trigger, it run after a quote is set to primary and it has to update other quote to non primary
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  17.12.2020 / Sophal Noch / Created the method.
    ***********************************************************************************************************************************************************/
    public static void updateQuoteToNonPrimary(Map<Id,Id> oppIdsMapToPrimQuoteIds){

        List<Quote> quoteToUpdate = new List<Quote>();

        for(Quote eachQuote : [Select Id,Primary_Quote__c From Quote Where OpportunityId IN: oppIdsMapToPrimQuoteIds.keySet() AND Id NOT IN: oppIdsMapToPrimQuoteIds.values() AND Primary_Quote__c = true]){
            quoteToUpdate.add(new Quote(Id=eachQuote.Id,Primary_Quote__c=false));
        }

        if(!quoteToUpdate.isEmpty()){
            update quoteToUpdate;
        }
    }




    /*****************************************************************************************************************************************************************
    @ Method:         populateAndValidateFields
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008874
    @                 As a...
    @                 any user
    @                 Want to...
    @                 ensure that once an Opportunity is 'Closed Won' the Ad Products & Quote Line Items which have been booked to DFP cannot be deleted
    @                 So that...
    @                 We can maintain Ad Revenue Daily & Ad Revenue Monthly records that are accurate.
    @                 Description
    @                 Once an Advertising Opportunity has Stage = 'Closed Won' and the Ad Products contain Ad Id's, users should be prevented from clicking 'Make Primary' on another pre-existing quote.
    @                 At the moment it is possible for multiple quotes to be created, for a single quote to be dually signed (closed won) to be booked to DFP and then for the user to select another existing quote and click 'Make Primary'
    @                 Due to the Quote Sync, this results in the Ad Products being deleted - therefore once a Quote has been 'Dually Signed' and the Opportunity 'Closed Won' the only way for a user to make a change should be by either creating a new revised quote or editing the existing quote line items.
    @ Event:          before insert and update trigger.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  23.12.2020 / Sophal Noch / Created the method.
    @ Change history:  05.11.2021 / Sophal Noch / Modified the method.
    ***********************************************************************************************************************************************************/
    public static void populateAndValidateFields(List<Quote> listNewQuote, map<Id,Quote> mapOldQuote){

        Datetime currentTime = System.now();
        Date currentDate = Date.today();

        Boolean hasBypass = hasSetQuoteToPrimaryByPass(); // 12.01.2020 / Sophal Noch / US-0008951

        for(Quote eachQuote : listNewQuote){

            Quote oldQuote = mapOldQuote != null ? mapOldQuote.get(eachQuote.Id) : null;

            // note: method setDuallySignedOrBuyerAcceptedQuoteToPrimary must run before methods markQuoteHavingBeenPrimary and preventPreviousQuoteBecomingPrimary
            // inside setDuallySignedOrBuyerAcceptedQuoteToPrimary, the logic can update quote.Primary_Quote__c = true and the other methods will use quote.Primary_Quote__c in their condtion
            
            setDuallySignedOrBuyerAcceptedQuoteToPrimary(eachQuote,oldQuote); // US-0008874 must run first.

            if(!hasBypass){ // 12.01.2020 / Sophal Noch / US-0008951

                preventPreviousQuoteBecomingPrimary(eachQuote,oldQuote,currentTime); // US-0008858
            }
            

            markQuoteToHavingBeenPrimary(eachQuote,oldQuote,currentDate); // US-0008874
        }

        
    }


    /*****************************************************************************************************************************************************************
    @ Method:         setDuallySignedOrBuyerAcceptedQuoteToPrimary
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008858
    @                 As a...
    @                 account manager
    @                 Want to...
    @                 click 'send to docusign' on a quote
    @                 So that...
    @                 when everyone signs, the system automatically updates 'dually signed' and 'make primary' checkbox from DocuSign
    @                 Description
    @                 AC1) As a user with 'standard ads user profile' and 'ebay advertisment account manager' permission set
    @                 When i click on 'primary quote' checkbox on a revised quote
    @                 the 1st primary quote needs to be unmarked as primary quote.
    @                 currently, when i do this, there are 2 primary quotes
    @                 image.png
    @                 The 'dually signed' checkbox need to follow the same logic as clicking the 'Make Primary' button on Quote.
    @                 when i click on 'Make Primary' button on a quote, the previous primary quote is unchecked as primary.
    @                 Once the same logic is available on the 'primary quote' checkbox as the 'make primary' button,
    @                 Docusign will mark 'dually signed' and 'primary quote' checkbox as true.
    @ Event:          before update or insert trigger, it set quote to primary when dually sign is set to true.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  17.12.2020 / Sophal Noch / Created the method.
    @ Change history:  23.12.2020 / Sophal Noch / US-0008874 Modify method parameters to called from other method.
    @ Change history:  01.12.2021 / Sophal Noch / US-0009927 - Update PG Opportunity Flow
    @               :  06.09.2023 / Sophal Noch / US-0014020 - PL Opportunity Process - Ad product Sync
    ***********************************************************************************************************************************************************/    
    public static void setDuallySignedOrBuyerAcceptedQuoteToPrimary(Quote newQuote, Quote oldQuote){

        if(
            (newQuote.Buyer_Accepted__c == true && (oldQuote == null || newQuote.Buyer_Accepted__c != oldQuote.Buyer_Accepted__c))
            || (newQuote.Dually_Signed__c == true && (oldQuote == null || newQuote.Dually_Signed__c != oldQuote.Dually_Signed__c))
            || (newQuote.RecordTypeId == QUOTE_PG_RT_ID && newQuote.Status == QUOTE_STATUS_APPROVED && oldQuote != null && newQuote.Status != oldQuote.Status) // 01.12.2021 / Sophal Noch / US-0009927
            || (newQuote.Invoice_Authorization__c == true && (oldQuote == null || newQuote.Invoice_Authorization__c != oldQuote.Invoice_Authorization__c)) //  06.09.2023 / Sophal Noch / US-0014020
        ){
            newQuote.Primary_Quote__c = true;
        }

    }


    /*****************************************************************************************************************************************************************
    @ Method:         preventPreviousQuoteBecomingPrimary
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008874
    @                 As a...
    @                 any user
    @                 Want to...
    @                 ensure that once an Opportunity is 'Closed Won' the Ad Products & Quote Line Items which have been booked to DFP cannot be deleted
    @                 So that...
    @                 We can maintain Ad Revenue Daily & Ad Revenue Monthly records that are accurate.
    @                 Description
    @                 Once an Advertising Opportunity has Stage = 'Closed Won' and the Ad Products contain Ad Id's, users should be prevented from clicking 'Make Primary' on another pre-existing quote.
    @                 At the moment it is possible for multiple quotes to be created, for a single quote to be dually signed (closed won) to be booked to DFP and then for the user to select another existing quote and click 'Make Primary'
    @                 Due to the Quote Sync, this results in the Ad Products being deleted - therefore once a Quote has been 'Dually Signed' and the Opportunity 'Closed Won' the only way for a user to make a change should be by either creating a new revised quote or editing the existing quote line items.
    @ Event:          before insert and update trigger.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  23.12.2020 / Sophal Noch / Created the method.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.01.2021 / Sophal Noch / US-0008951, US-0008975 modify the method.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  18.01.2021 / Sophal Noch / US-0008988 modify the method.
    ***********************************************************************************************************************************************************/
    public static void preventPreviousQuoteBecomingPrimary(Quote newQuote, Quote oldQuote, Datetime currentTime){

            // if mapOldQuote == null, trigger is before insert.
            // because before insert, quote.CreatedDate is null, we current date time instead.
            Datetime quoteCreatedDate = oldQuote == null ? currentTime : newQuote.CreatedDate; 

            if(

                (oldQuote == null || newQuote.Primary_Quote__c != oldQuote.Primary_Quote__c)
                && newQuote.Primary_Quote__c == true
                && newQuote.Number_of_Quotes__c > 0
            ){

                if(!newQuote.Is_Revised_Quote__c && newQuote.Number_of_Revised_Quotes__c <= 0 && (newQuote.Number_of_Dually_Signed_Quote__c > 0 || newQuote.Number_of_Buyer_Accepted_Quote__c > 0)){
                    // US-0008988
                    newQuote.addError(Label.Error_Quote_Cannot_Be_Primary_If_DuallySigned_Or_BuyerAccepted);
                }else if(
                    (!newQuote.Is_Revised_Quote__c && newQuote.Number_of_Revised_Quotes__c > 0)
                    || (newQuote.Is_Revised_Quote__c && newQuote.Status != Label.QUOTE_STATUS_APPROVED && newQuote.LatestCreatedQuoteDate__c > quoteCreatedDate)
                ){
                    // US-0008951, US-0008975
                    newQuote.addError(Label.Error_Only_Latest_Quote_Can_Be_Primary);
                }
                
            }

    }



    /*****************************************************************************************************************************************************************
    @ Method:         markQuoteToHavingBeenPrimary
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008874
    @                 As a...
    @                 any user
    @                 Want to...
    @                 ensure that once an Opportunity is 'Closed Won' the Ad Products & Quote Line Items which have been booked to DFP cannot be deleted
    @                 So that...
    @                 We can maintain Ad Revenue Daily & Ad Revenue Monthly records that are accurate.
    @                 Description
    @                 Once an Advertising Opportunity has Stage = 'Closed Won' and the Ad Products contain Ad Id's, users should be prevented from clicking 'Make Primary' on another pre-existing quote.
    @                 At the moment it is possible for multiple quotes to be created, for a single quote to be dually signed (closed won) to be booked to DFP and then for the user to select another existing quote and click 'Make Primary'
    @                 Due to the Quote Sync, this results in the Ad Products being deleted - therefore once a Quote has been 'Dually Signed' and the Opportunity 'Closed Won' the only way for a user to make a change should be by either creating a new revised quote or editing the existing quote line items.
    @ Event:          before insert and update trigger.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  23.12.2020 / Sophal Noch / Created the method.
    ***********************************************************************************************************************************************************/
    public static void markQuoteToHavingBeenPrimary(Quote newQuote, Quote oldQuote, Date currentDate){

        if(
            newQuote.Primary_Quote__c == true
            &&(oldQuote == null || newQuote.Primary_Quote__c != oldQuote.Primary_Quote__c)
        ){
                // US-0008874 so we can know which quote has been primary before.
                newQuote.HasBeenPrimary__c = true;
                newQuote.MarkedPrimaryQuoteDate__c = currentDate;  // 05.11.2021 / Sophal Noch / US-0010628 store date when quote is set as primary
        }
    }

    /*****************************************************************************************************************************************************************
    @ Method:         hasSetQuoteToPrimaryByPass
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008951
    @ Event:          before insert and update trigger.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  12.01.2020 / Sophal Noch / Created the method.
    ***********************************************************************************************************************************************************/

    public static Boolean hasSetQuoteToPrimaryByPass(){

        byPass__c profileCustomSetting = byPass__c.getInstance(UserInfo.getUserId());
        Boolean hasByPass = false;

        if( 
            profileCustomSetting != null && 
            profileCustomSetting.triggerObjects__c != null && 
            profileCustomSetting.triggerObjects__c.contains('Quote') && 
            profileCustomSetting.ByPass_PrimaryQuoteRule__c
        ) 
        {
            hasByPass = true;
        }

        return hasByPass;

    }

    /*****************************************************************************************************************************
    @ Method:   copyDiscountsFromQuoteToQuoteLineItems
    @ Author:   Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:  US-0009260 - [Ads 2020] OLI Trigger to QLI/AP, Fields & Syncing
    @ Event:    Quote
                - After Update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     Set<Id> sQuoteIds => Quote Id
                     Map<Id, Quote> qValuesMap => Map with Quote's records
                     Map<Id, Boolean> qR2Changed => Map with Quote that has changed Quote.Rate_Discount_II__c
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.03.2021 / Mony Nou / Created the  Method
    *****************************************************************************************************************************/
    public static void copyDiscountsFromQuoteToQuoteLineItems (Set<Id> sQuoteIds, map<Id, Quote> qValuesMap, map<Id, Boolean> qR2Changed) {

        if (!sQuoteIds.isEmpty()) {

            List<QuoteLineItem> qlis = new List<QuoteLineItem>();
            for (QuoteLineItem qli : [ SELECT Pricebook_Name__c,Billing_Category__c, Rate_Discount_I__c, Rate_Discount_II__c, Rate_Card_Discount_percent__c, Special_Agency_Discount_Percent__c, Quantity, Sales_Price_incl_Targeting__c, QuoteId, Rebate_In_Kind__c 
                                        FROM QuoteLineItem 
                                        WHERE QuoteId IN :sQuoteIds]) {
                
                qli.Rate_Discount_I__c              = qli.Rebate_In_Kind__c ? 0 : qValuesMap.get(qli.QuoteId).Rate_Discount_I__c;

                if (qR2Changed.containsKey(qli.QuoteId)) { qli.Rate_Discount_II__c = qValuesMap.get(qli.QuoteId).Rate_Discount_II__c; }
		
    
                qli.AE__c                           = qli.Rebate_In_Kind__c                     ? false : qValuesMap.get(qli.QuoteId).AE__c;
                qli.Rate_Discount_II__c             = qli.Rebate_In_Kind__c                     ? 100   : qli.Rate_Discount_II__c;
                qli.Rate_Discount_II__c             = qli.Rate_Discount_II__c == null           ? 0     : qli.Rate_Discount_II__c;

                qli.Rate_Card_Discount_percent__c   = qli.Rate_Card_Discount_percent__c == null ? 0     : qli.Rate_Card_Discount_percent__c;
                qli.Rate_Discount_I__c              = qli.Rate_Discount_I__c == null            ? 0     : qli.Rate_Discount_I__c;
                
                /* MN-27052021 - Using method instead
                Double nnn = 0;
                nnn =  qli.Sales_Price_incl_Targeting__c;
                nnn *= qli.Billing_Category__c=='CPM'?qli.Quantity/1000:qli.Quantity;
                nnn *= (1 - qli.Special_Agency_Discount_Percent__c / 100);
                nnn *= (1 - qli.Rate_Discount_I__c / 100);
                nnn *= (1 - qli.Rate_Discount_II__c / 100);
                nnn *= qli.AE__c ? 0.85 : 1;

                qli.Amount_Net_Net_Net__c = nnn;
                */
                
                qli.Amount_Net_Net_Net__c = calculateAmountNetNetNet(qli); //MN-27052021 - Using method instead

                qlis.add(qli);
            }
            
            if (!qlis.isEmpty()) { update qlis; }

        }

        
    }

    /*****************************************************************************************************************************************************************
    @ Method:         calculateAmountNetNetNet 
    @ Version:        1.0
    @ Author:         Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:        Calculate for QuoteLineItem.Amount_Net_Net_Net__c
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  27.05.2021 / Mony Nou / Created method.
    ***********************************************************************************************************************************************************/
    public static Decimal calculateAmountNetNetNet(QuoteLineItem qli) {

        Double nnn = 0;
        nnn =  qli.Sales_Price_incl_Targeting__c;
        nnn *= qli.Billing_Category__c=='CPM'?qli.Quantity/1000:qli.Quantity;
        nnn *= (1 - ((qli.Special_Agency_Discount_Percent__c!=null?qli.Special_Agency_Discount_Percent__c:0)) / 100);
        nnn *= (1 - ((qli.Rate_Discount_I__c != null)?qli.Rate_Discount_I__c:0) / 100);
        nnn *= (1 - ((qli.Rate_Discount_II__c != null)?qli.Rate_Discount_II__c:0) / 100);
        //nnn *= qli.AE__c ? 0.85 : 1;
        nnn *= (!qli.AE__c ? 1 : 1 - ((qli.Pricebook_Name__c+'').startsWith('AU') ? 0.10 : 0.15 )); //NK:09/06/2021:US-0009640

        return nnn;
    }

    /*****************************************************************************************************************************************************************
    @ Method:         calculateBudget 
    @ Version:        1.0
    @ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:        US-0009640
    @                 Calculate for QuoteLineItem.Budget__c
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  09.06.2021 / Vadhanak / Created method.
    @                                       / not used at the moment. maybe future if we need Budget__c is fully automated
    ***********************************************************************************************************************************************************/
    public static Decimal calculateBudget(QuoteLineItem qli) 
    {
        // Double budget = 0;
        // budget +=  qli.SalesPriceNet__c==null?0:qli.SalesPriceNet__c;
        // budget +=  qli.Targeting_Fee2__c==null?0:qli.Targeting_Fee2__c;
        
        // budget *= qli.Billing_Category__c=='CPM'?qli.Quantity/1000:qli.Quantity;

        // budget *= (1 - ((qli.Special_Agency_Discount_Percent__c!=null?qli.Special_Agency_Discount_Percent__c:0)) / 100);
        // budget *= (1 - ((qli.Rate_Discount_I__c != null)?qli.Rate_Discount_I__c:0) / 100);
        // budget *= (1 - ((qli.Rate_Discount_II__c != null)?qli.Rate_Discount_II__c:0) / 100);
        // budget *= (1 - (!qli.AE__c ? 1 : ((qli.Pricebook_Name__c+'').startsWith('AU') ? 0.10 : 0.15 )));

        // return budget;
        return null;
    }

    /*****************************************************************************************************************************************************************
    @ Method:         updateOppCampaignDate
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0009608 Ads UAT Bug- Sync Quote Start and End Dates to Opportunity
    @ Event:          after update trigger.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  03.06.2021 / Sophal Noch / Created the method.
    ***********************************************************************************************************************************************************/
    public static void updateOppCampaignDate(List<Quote> lstQuote){

        Map<Id,Opportunity> mapOppToUpdate = new  Map<Id,Opportunity>();
        for(Quote q : lstQuote){
            mapOppToUpdate.put(q.OpportunityId, new Opportunity(Id = q.OpportunityId, Start_Date__c = q.Campaign_Start__c, End_Date__c = q.Campaign_End__c));
        }
        update mapOppToUpdate.values();


    }

    /*****************************************************************************************************************************************************************
    @ Method:         withdrawApprovalQuote
    @ Version:        1.0
    @ Author:         Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:        US-0010299 - ADS - Ability to Withdraw an Approved Quote
    @                   - Execute logic under Quote's Quick Action 	"Withdraw Approval"
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  19.10.2021 / Mony Nou / Created the method.
    @               :  30.06.2025 / Sambath Seng / Cannot withdraw approval on quote that I approved
    ***********************************************************************************************************************************************************/
    public static Map<String,Object>  withdrawApprovalQuote(String qId){

        Map<String, Object> mResult = new Map<String, Object>();
        
        mResult.put('status', 'ko');
        mResult.put('msg', Label.Ads_Quote_Withdraw_Error_1);

        try {

            if (String.isNotBlank(qId)) {

                /*Map<Integer, String> mPermsissnSet = new Map<Integer, String>{
                    1 => 'Ebay_Advertisement_Account_Managers',
                    2 => 'eBay_Ads_Withdraw_Quote_Approval'
                };*/
                
                Boolean isAdmin = (Userinfo.getprofileId()==ApexUtil.ADMIN_PROFILE_ID);

                //Check for valid User's Profile & Permission Set which are 'Standard Ads User Profile' or 'Standard EU Ads User Profile' and 'eBay Ads - CSM' or 'eBay Ads - Withdraw Quote Approval' permission set
                //Boolean isValidProfile = false; // SB 30.09.2025 US-0033002
                //for (Profile pro : [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId() AND Name LIKE 'Standard Ads%']) { isValidProfile = true; } // SB 30.09.2025 US-0033002
                // SB 30.09.2025 US-0033002
                Boolean hasCustomPermission = FeatureManagement.checkPermission('eBay_Ads_Withdraw_Quote');

                //Boolean hasPermission1 = ApexUtil.checkPermissionSet(new Set<String>{mPermsissnSet.get(1)}); //For 'eBay Ads - CSM' Permission Set
                //Boolean hasPermission2 = ApexUtil.checkPermissionSet(new Set<String>{mPermsissnSet.get(2)}); //For 'eBay Ads - Withdraw Quote Approval' Permission Set

                //For Valid User's Profile & Permission Set
                if (isAdmin || hasCustomPermission) { // SB 30.09.2025 US-0033002
                    
                    //Admin or user has 'eBay Ads - Withdraw Quote Approval' (new): should always have access to withdraw quote at all times.
                    //Boolean isValidQuote = (isAdmin || hasPermission2); 
                    
                    /* // SB 30.09.2025 US-0033002 Comment out and checking for custom permission instead of permission set
                        User with 'eBay Ads - CSM' permission set should only be able to withdraw a quote if:
                            - the 1st quote on the opportunity isn't closed won yet
                            - revised quote isn't primary yet

                    if (!isValidQuote && hasPermission1) {
                        //1st - Check if it a first Quote or not primary Revised Quote on Opportunity that is not closed won
                        for (Opportunity opp : [SELECT Id, (SELECT Is_Revised_Quote__c FROM Quotes ORDER BY CREATEDDATE ASC LIMIT 1) FROM Opportunity 
                                                    WHERE Id IN (SELECT OpportunityId FROM Quote WHERE Id=:qId) and IsClosed = FALSE and IsWon = FALSE]) {
                            if (!opp.Quotes.isEmpty() && opp.Quotes[0].Id == qId && !opp.Quotes[0].Is_Revised_Quote__c) isValidQuote = true;
                        }

                        //2nd - If it not match 1st, then check if it is Revised Quote and Not Primary
                        if (!isValidQuote) {
                            for (Quote q : [SELECT Id FROM Quote WHERE Id=:qId AND Is_Revised_Quote__c = TRUE AND Primary_Quote__c = FALSE]) { isValidQuote = true; }
                        }
                    }
                    */
                    
                    //If it is a valid quote that able to withdraw => set status back to Draft and if it is in Approval Process, recall it from Approval Process
                    if (hasCustomPermission) {// SB 30.09.2025 US-0033002

                        //Check if it is in Approval Process if so, recall it and then set status back to "Draft"
                        //Find quote that still in Approval Process
                        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
                        List<ProcessInstanceWorkitem> listWorkItems = [Select id, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =:qId];
                        Map<id,Id> mapQuoteWorkItem = new Map<id,id>();
                        for(ProcessInstanceWorkitem WorkItem:listWorkItems){
                            mapQuoteWorkItem.put(workItem.ProcessInstance.TargetObjectId, workitem.id);
                        }
                        

                        if (mapQuoteWorkItem.containsKey(qId)) {
                            
                            //Remove it from Approval Process
                            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                            req.setAction('Removed');
                            req.setWorkItemId(mapQuoteWorkItem.get(qId));
                            requests.add(req);
                        }
                        
                        //Set Quote Status to Draft
                        Quote quote = new Quote( Id = qId, Status = 'Draft');

                        //MN-22102021-US-0010299 - Confirm from BA: we want to withdraw for these quotes too. So make sure that if dually signed field is true, make dually signed false if the withdraw approval button is clicked.
                        for (Quote q : [SELECT Dually_Signed__c, Buyer_Accepted__c FROM Quote WHERE Id=:qId]) {
                            if (q.Dually_Signed__c) quote.Dually_Signed__c = false;
                            if (q.Buyer_Accepted__c) quote.Buyer_Accepted__c = false;
                        }
                        
                        if(!requests.isEmpty()){ Approval.ProcessResult[] processResults = Approval.process(requests, true); }

                        update quote;

                        mResult.put('status','ok');
                        mResult.put('msg', Label.Ads_Quote_Withdraw_Success);
                    }
                    else { mResult.put('msg', Label.Ads_Quote_Withdraw_Error_4); }

                    
                }
                //For Invalid User's Profile & Permission Set
                else { mResult.put('msg', Label.Ads_Quote_Withdraw_Error_3); }

            } 
            else { mResult.put('msg',Label.Ads_Quote_Withdraw_Error_2); }

        }catch(Exception ex) { mResult.put('msg', ex.getMessage()); }

        return mResult;
    }


    //MN-25102021-US-0008416 - Moved from GW_Quote
    public static Map<String, Object> initValue = new Map<String, Object>{
		'Status' => 'Draft',
		Util.NS + 'Total_Budget_Change__c' => false,
		Util.NS + 'Total_Impressions_Change__c' => false
	};

    /*****************************************************************************************************************************************************************
    @ Method:         applyInitValue
    @ Version:        1.0
    @ Author:         Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:        US-0008416 - Moved from GW_Quote
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  25.10.2021 / Mony Nou / Created the method.
    ***********************************************************************************************************************************************************/
    public static void applyInitValue(Quote newQuote) {
		for (String fldName : initValue.keySet()) {
			newQuote.put(fldName, initValue.get(fldName));
		}
	}
    
}