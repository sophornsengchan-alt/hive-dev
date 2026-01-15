/*****************************************************************************************************************************
    @ Method:         NewEbayLivePricingController
    @ Author:         Mony Nou
    @ Purpose:        US-0033112 - eBay Live: Pricing Guided Flow - Part 1
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.08.2025 / Mony Nou / Created Class
    *****************************************************************************************************************************/
    public with sharing class NewEbayLivePricingController {
    

    /*****************************************************************************************************************************
    @ Method:         splitString
    @ Author:         Mony Nou
    @ Purpose:        This method is used to join list of string into a string by semicolon
    @ Description:    This method is designed to be used in a Flow to process a string
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     inputs - List of InputWrapper containing the input string to be joined.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 07.08.2025 / Mony Nou / Created Method
    *****************************************************************************************************************************/
    @InvocableMethod(label='Join String by Semicolon')
    public static List<String> joinStrings(List<Request> requests) {
        List<String> results = new List<String>();
        for (Request req : requests) {
            results.add(String.join(req.values, ';'));
        }
        return results;
    }

    public class Request {
        @InvocableVariable(required=true)
        public List<String> values;
    }

}