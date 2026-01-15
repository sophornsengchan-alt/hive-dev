@IsTest
public class CategoryStringSplitterTest {

    @IsTest
    static void testSplitStrings() {
        // Create a list of requests
        List<CategoryStringSplitter.Request> requests = new List<CategoryStringSplitter.Request>();
        
        // Add a request with sample data
        CategoryStringSplitter.Request req = new CategoryStringSplitter.Request();
        req.icString = '1;28938;9873;00001;89389';
        req.xcString = 'A;B;C;D;E';
        requests.add(req);
        
        // Call the method to test
        List<CategoryStringSplitter.Response> responses = CategoryStringSplitter.splitStrings(requests);
        
        // Verify the results
        System.assertEquals(1, responses.size(), 'There should be one response.');
        
        CategoryStringSplitter.Response response = responses[0];
        
        // Verify IC Collection
        List<String> expectedIC = new List<String>{'1', '28938', '9873', '00001', '89389'};
        System.assertEquals(expectedIC, response.icCollection, 'IC Collection does not match expected values.');
        
        // Verify XC Collection
        List<String> expectedXC = new List<String>{'A', 'B', 'C', 'D', 'E'};
        System.assertEquals(expectedXC, response.xcCollection, 'XC Collection does not match expected values.');
    }
}