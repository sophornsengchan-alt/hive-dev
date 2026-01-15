public class CategoryStringSplitter {

    @InvocableMethod(label='Split Two Strings by Semicolon' description='Splits two semicolon-separated strings into two lists of strings.')
    public static List<Response> splitStrings(List<Request> requests) {
        List<Response> results = new List<Response>();

        for (Request req : requests) {
            // Initialize empty lists to handle null or blank inputs
            List<String> icSplitValues = new List<String>();
            List<String> xcSplitValues = new List<String>();

            try {
                // Check and split the IC string if not null or blank
                if (String.isNotBlank(req.icString)) {
                    icSplitValues = req.icString.split(';');
                }

                // Check and split the XC string if not null or blank
                if (String.isNotBlank(req.xcString)) {
                    xcSplitValues = req.xcString.split(';');
                }
            } catch (Exception e) {
                // Log exception (if needed) and continue with empty lists
                System.debug('Exception occurred while splitting strings: ' + e.getMessage());
            }

            // Create a response object and add it to the results
            Response res = new Response();
            res.icCollection = icSplitValues;
            res.xcCollection = xcSplitValues;
            results.add(res);
        }

        return results;
    }

    public class Request {
        @InvocableVariable(label='IC String' description='The first semicolon-separated string to split.' required=true)
        public String icString;

        @InvocableVariable(label='XC String' description='The second semicolon-separated string to split.' required=false)
        public String xcString;
    }

    public class Response {
        @InvocableVariable(label='IC Collection' description='The list of strings resulting from splitting the IC string.')
        public List<String> icCollection;

        @InvocableVariable(label='XC Collection' description='The list of strings resulting from splitting the XC string.')
        public List<String> xcCollection;
    }
}