/*********************************************************************************************************************************
@ Class:          BookingEbayRegistrationHandler
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0013565 - eBay Registration Handler for Call booking site.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 24.04.2023 / Sophal Noch / create class
@                 21.05.2024 / Acmatac Seing / US-0015257 - Bookings.com NA Seller are getting DE language
*********************************************************************************************************************************/
global class BookingEbayRegistrationHandler extends EbayRegistrationHandler{

    //NK:14/10/2024:US-0015432 - contains meta that use field: Eligibility_Criteria_SOQL__c from metadata instead of Eligibility_Criteria__c
    // private Set<String> setUseSOQLEligibility = new Set<String>();
    private String soqlCohortSeller = 'SELECT Id,Name From BoB_Seller__c ';
    /*********************************************************************************************************************************
    @ Method:         getPortalEligibilityMdtName
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0013565 - eBay Registration Handler for Call booking site.
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.04.2023 / Sophal Noch / create method
    **********************************************************************************************************************************/
    protected override String getPortalEligibilityMdtName(){return 'Booking_Portal_Eligibility';}  // override method for booking portal to get custom metdata name


    /*********************************************************************************************************************************
    @ Method:         isFromBookingPortal
    @ Author:         Acmatac Seing
    @ Purpose:        US-0015257 - Knowing that the context is from Booking Portal
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.05.2024 / Acmatac Seing / create method
    **********************************************************************************************************************************/
    protected override Boolean isFromBookingPortal(){ return true; }

    

    /*********************************************************************************************************************************
    @ Method:         checkEligible
    @ Author:         vadhanak
    @ Purpose:        US-0015432 - ADS - Eligibility for Advertising program component
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.10.2024 / vadhanak / create method
    **********************************************************************************************************************************/
    protected override Account checkEligible(Set<String> setMetaIdentity, Map<String,String> mapSetting,String sellerId)
    {
        List<String> setFilters = new List<String>();
        for(String meta : setMetaIdentity)
        {
            String soqlBookingElig = mapSetting.get(meta);
            soqlBookingElig = ' WHERE Seller__r.eBay_API_User_Id__c=:sellerId AND '+ soqlBookingElig;
            BoB_Seller__c[] cohortSellers = (BoB_Seller__c[])ApexSafe.query().secCheck(false).doQuery(soqlCohortSeller+soqlBookingElig,new Map<String,Object>{'sellerId'=>sellerId});
            if(!cohortSellers.isEmpty())
            {
                String sellerIdOneFilter = ' WHERE eBay_API_User_Id__c=:sellerId';
                Account[] sellerMain = (Account[])ApexSafe.query().secCheck(false).doQuery(soqlSeller0 + sellerIdOneFilter,new Map<String,Object>{'sellerId'=>sellerId});
                return sellerMain[0];
            }       
        }     
        //System.debug('---checkEligible: KO!!!');
        return null;
    }

    

}