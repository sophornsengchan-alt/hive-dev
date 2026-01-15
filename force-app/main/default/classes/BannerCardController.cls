/**
 * @description EBAY-222
 * @createdDate 28-June-2021
 * @author      Samnang MUONG
 */
public with sharing class BannerCardController {    
    
    @AuraEnabled(cacheable=true)   
    public static retWrapper getCount(String lastNday, String objectName) {     
        objectName = objectName.trim();
        //try {
            retWrapper obj = new retWrapper();
            if(objectName == 'EBH_Deal__c')
            obj.dealCount = initCountDeal(lastNday);
            if(objectName == 'Coupon__c')
            obj.dealCouponSeller = initCountCouponSeller(lastNday); 
            system.debug('full obj >>>>>>>> '+obj);

            return obj;
           
            
        /*} catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }*/


    }

    @AuraEnabled(cacheable=true)   
    public static String initCountDeal(String lastNday) {     

        //try {

            String accId = BannerCardController.getCurrentUserAccountId();
           
            String sql = 'SELECT COUNT() FROM EBH_Deal__c WHERE CreatedDate = LAST_N_DAYS:'+lastNday;

            if (String.isNotBlank(accId)) sql += ' AND EBH_BusinessName__c = \''+accId+'\'';

            system.debug('full sql >>>>>>>> '+sql);

            Integer numberDeals = Database.countQuery(sql);           


            return String.valueOf(numberDeals);
           
            
        /*} catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }*/


    }

    @AuraEnabled(cacheable=true)   
    public static String initCountCouponSeller(String lastNday) {     

       // try {

            String accId = BannerCardController.getCurrentUserAccountId();
            String Coupon_Record_Type_Id = Schema.SObjectType.Coupon__c.getRecordTypeInfosByName().get('Seller / Category Based').getRecordTypeId();
            system.debug('full accId >>>>>>>> '+accId);
            String sql = 'SELECT COUNT() FROM Coupon__c WHERE RecordTypeId =: Coupon_Record_Type_Id';
            
             sql+= ' AND CreatedDate = LAST_N_DAYS:'+lastNday;

            system.debug('full sql >>>>>>>> '+sql);

            Integer numberCouponSeller = Database.countQuery(sql);
               
            return String.valueOf(numberCouponSeller);
           
            
        /*} catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }*/

    }

    private static String getCurrentUserAccountId() {

        List<Contact> lstCons = [SELECT AccountId FROM Contact WHERE Id IN (SELECT ContactId FROM User WHERE Id =:UserInfo.getUserID())];

            List<Account> lstDefaultAcc = [SELECT Id FROM Account WHERE Name = 'Trigg Digital Ltd' LIMIT 1];

            return (!lstCons.isEmpty()) ? lstCons[0].AccountId : lstDefaultAcc[0].Id; // fixed Id of account Trigg Digital Ltd use as default on sandbox         
    }

    public class retWrapper{
        @AuraEnabled public String dealCount{get;set;}
        @AuraEnabled public String dealCouponSeller{get;set;}
    }
}