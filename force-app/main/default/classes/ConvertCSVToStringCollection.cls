public with sharing class ConvertCSVToStringCollection {

    @invocableMethod(label='Convert Comma-separated-values to String Collection')
    public static List<Response> execute (List<Request> requests) {

        List<Response> responseList = new List<Response>();
        for (Request curRequest : requests) {

            Response response = new Response();
          //  response.stringCollection = curRequest.csvString?.split(',');
          if (response.stringCollection == null){
              response.stringCollection = new List<String>();
          }
          for (String s : curRequest.csvString?.split(',')){
              response.stringCollection.add(s.trim());
          }
   
            responseList.add(response);
        }

        return responseList;
    }

    public class Request {
        @invocableVariable
        public String csvString;
    }

    public class Response {
        @invocableVariable
        public List<String> stringCollection;

    }
}