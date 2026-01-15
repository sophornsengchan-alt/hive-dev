/*********************************************************************************************************************************
    @ Class:          SellerCommunicationTriggerHandler
    @ Author:         Acmatac Seing(acmatac.seing@gaea-sys.com)
    @ Purpose:        Trigger handler SellerCommunicationTrigger for US-0013994 - Bookings - Date/Time format in Bookings emails
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  24.08.2023 / Acmatac Seing / Created the class
    @                   05.09.2023 / Acmatac Seing / US-0014068 - Bookings - Date/Time improvements
*********************************************************************************************************************************/
public class SellerCommunicationTriggerHandler {
    public static final String SF_DEFAULT_TIMEZONE = 'Europe/London';
    public static final String SF_DEFAULT_UTC_TIME_FORMAT = 'dd/MM/yyyy HH:mm';
    private static RecordType EBAY_BOOKING_MEETING_SELLERCOM_RTID = ApexUtil.getRecordTypeByName('Seller_Communication__c', 'eBay_Bookings_Meetings');

    public static Map<String, String> mapRegionWithDateTimeFormat = new Map<String, String>{
        'NA' => ApexUtil.MAP_LOCALE_DATEFORMAT().get('en_US'), //'M/d/yyyy h:mm a'
        'UK' => ApexUtil.MAP_LOCALE_DATEFORMAT().get('en_GB'), //'dd/MM/yyyy HH:mm'
        'DE' => ApexUtil.MAP_LOCALE_DATEFORMAT().get('de'), //'dd.MM.yyyy HH:mm'
        'IT' => ApexUtil.MAP_LOCALE_DATEFORMAT().get('it'), //'dd/MM/yyyy H.mm'
        'FR' => ApexUtil.MAP_LOCALE_DATEFORMAT().get('fr') //'dd/MM/yyyy HH:mm'
    };

    /*********************************************************************************************************************************
    @ Method:         convertDateTimeToOtherTimeZone
    @ Author:         Acmatac Seing(acmatac.seing@gaea-sys.com)
    @ Purpose:        US-0013994 - Bookings - Date/Time format in Bookings emails
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  24.08.2023 / Acmatac Seing / Created the method
    @                   05.09.2023 / Acmatac Seing / US-0014068 - Bookings - Date/Time improvements
    *********************************************************************************************************************************/
    public static void convertDateTimeToOtherTimeZone(List<Seller_Communication__c> listNewSellerComm){
        if(!isRecordType_BookingMeeting(listNewSellerComm)) return;

        for(Seller_Communication__c sellerComm: listNewSellerComm){
            if(sellerComm.Calendly_EventStartTime__c != null){
                String strTimeZone = String.isNotBlank(sellerComm.Calendly_Timezone__c) ? sellerComm.Calendly_Timezone__c : SF_DEFAULT_TIMEZONE;
                String strTimeFormat = mapRegionWithDateTimeFormat.containsKey(sellerComm.Region__c) ? mapRegionWithDateTimeFormat.get(sellerComm.Region__c) : SF_DEFAULT_UTC_TIME_FORMAT;
                sellerComm.Calendly_EventStartTimeByRegion__c = sellerComm.Calendly_EventStartTime__c.format(strTimeFormat, strTimeZone)+' ('+strTimeZone+')';
            }
        }
    }

    private static Boolean isRecordType_BookingMeeting(List<Seller_Communication__c> listSellerComm){
        return listSellerComm.isEmpty() ? false : listSellerComm[0].RecordTypeId == EBAY_BOOKING_MEETING_SELLERCOM_RTID.Id ? true : false;
    }
}