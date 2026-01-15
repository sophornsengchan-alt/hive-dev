/*********************************************************************************************************************************
@ Class:          EBH_CurrencyConverter 
@ Version:        1.0
@ Author:         NEHA LUND 
@ Purpose:        Handler Class for Pricing Trigger
                  EPH-5026 : Currency Converter
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 07.12.2017 / NEHA LUND / Created the class.
*********************************************************************************************************************************/

public class EBH_CurrencyConverter {

     Map<String, CurrencyType > conversionMap = new Map<String, CurrencyType >();
       public  EBH_CurrencyConverter (){
        for(CurrencyType curr : [SELECT ISOCode, DecimalPlaces,ConversionRate FROM CurrencyType WHERE IsActive=TRUE]){
            
            conversionMap.put(curr.ISOCode, curr);
        }
     }
   
    
    /*****************************************************************************************************************************
    @ Method:         convert
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        EPH-5026 : Reusable method for both Pricing & Contract two way synchronization
                      Updates custom roll ups on Contract (record type: Listing Agreement) from all child Pricings of record Type 
                      Listing Agreement
                       - Contract Listing Value - Value + Store Subscription Fees (if subscription type is Free)
                       - Contract Exposure Value - Exposure + Store Subscription Fees (if subscription type is Non Free) 
                       
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Pricings:      Pricings from the trigger scope
                      PricingOldMap: Pricings old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.12.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
   
    public Decimal convert(Decimal value, String fromIso, String toIso) {
        if (String.isEmpty(fromIso) || String.isEmpty(toIso)) {
            return value;
        }
  
        // get values and then rate
        final CurrencyType fromCur = conversionMap.get(fromIso.toUpperCase());
        final Decimal fromRate = fromCur.ConversionRate;
        final CurrencyType toCur = conversionMap.get(toIso.toUpperCase());
        final Decimal toRate = toCur.ConversionRate;
        final Decimal rate = toRate/fromRate;
        
        // calc
        final Decimal result = value * rate;
        final Decimal resultRounded = result.setScale(toCur.DecimalPlaces, System.RoundingMode.HALF_UP);
        
        // return
        return resultRounded;
    }
    
   
}