/**10/10/2017:
 vadhanak.voun@gaea-sys.com
 #12702:
   1.  Scheduled job collects all deal__c records where Status__c = “Deal Agreed” or “Running” and Deal_Start_Date__c = Today and ebay_Link__c <> “Item ID missing”
  2.  From these records use the URL in ebay_Link__c to go to the eBay Website of the deal.
  3.  Identify the price of the deal from the website (see screenshot).
     If I understand correctly there is an item on the page with ID prcIsum which contains the price.
    <span class="notranslate" id="prcIsum" itemprop="price" style="" content="439.0">EUR 439,00</span>
  4.  Compare this identified price with Deal_Price__c. If they don’t match set Price_not_matching__c = True
  
  changes:
  	+ 02/03/2018: Vadhanak: findEbayPrice(): replaced regex that unknown reason causes regex too complicate.
  				  Handle redirect in case item moved to HTTPS 
  	+ 03/03/3030: Vadhanak: US-0007241 Rework existing EBH_ScrapDeal class to use API call instead of Web Crawling approach.
   + 06/10/2022: Mony Nou: US-0009568 - Price Drop Reminder email to the Seller
*/

global without sharing class EBH_ScrapDeal implements Database.Batchable<SObject>,Database.AllowsCallouts,Schedulable, Database.Stateful {

   String query = 'Select Id,EBH_DealSiteId__c,EBH_eBayItemID__c,EBH_Status__c,EBH_ebayLink__c,EBH_DealPrice__c,EBH_Pricenotmatching__c From EBH_Deal__c ';
   
   @testVisible
   private List<String> lstAPIErrMsg = new List<String>(); //MN-17102022-US-0009568

   global Database.QueryLocator start(Database.BatchableContext BC)
   {
      String sWhere = ' WHERE EBH_Status__c IN(\'Deal Agreed\',\'Running\') AND EBH_DealStartDate__c=TODAY AND EBH_ebayLink__c <> \'Item ID missing\'';
      return Database.getQueryLocator(query+sWhere);
   }
   public EBH_ScrapDeal(){}
   
   global void execute(Database.BatchableContext BC, List<EBH_Deal__c> scope)
   {
      try {
         EBH_DealTriggerHandler.doProcessDealItems(scope);
      } catch(PriceMatchingAPIException ex) { lstAPIErrMsg.add(ex.getMessage()); }
       

       
   }

   global void finish(Database.BatchableContext BC)
   {
      

      //MN-17102022-US-0009568 : In case there are any error from API => Send email to Deployment User
      if (!lstAPIErrMsg.isEmpty()) { sendAPIErrorEmail(); }

      //MN-06102022-US-0009568-Called new batch when done scrap
      BatchDealPriceChangeAlert batch = new BatchDealPriceChangeAlert();
      Database.executebatch(batch,50);

   }

   //MN-17102022-US-0009568 : Send simple message to Deployment User to let them know about the error we got from requested to eBay API
   private void sendAPIErrorEmail() {

      String email;
      for (User usr : [SELECT Email FROM User WHERE Alias='duser' and IsActive=TRUE]) { email = usr.Email; }

      if (String.isNotBlank(email)) {
         String body = 'Below is/are the error(s) from API: <br/><br/>' + String.join(lstAPIErrMsg, '<br/>');
         ApexUtil.doSend('Batch EBH_ScrapDeal - API Error(s)', email, body);
      }
      
   }
   
   global void execute(SchedulableContext sc) {
      EBH_ScrapDeal sdbatch = new EBH_ScrapDeal(); 
      Database.executebatch(sdbatch,20); //MN-17102022-US-0009568-reduced from 50 to 20 //reduced from 100 to 50; there could be another redirect request 
   }

   public class PriceMatchingAPIException extends Exception {}
}