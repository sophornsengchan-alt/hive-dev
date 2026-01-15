/*********************************************************************************************************************************
@ Class:          OpenCSVTest
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Test class for OpenCSVParser and OpenCSVReader
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 20.11.2020 / Vadhanak Voun / Created the class.
**********************************************************************************************************************************/
@isTest
private class OpenCSVTest{

    @IsTest
    static void testCSV(){
        
        String csv_separator = ',';        
        String newLineToUse = '\r';
        String csvFile = 'Id,Name,Price\r00000,Test1,10\r00001,Test2,12.5';

        Test.startTest();
         
        OpenCSVParser parser = new OpenCSVParser(csv_separator,OpenCSVParser.DEFAULT_QUOTE_CHARACTER, OpenCSVParser.DEFAULT_ESCAPE_CHARACTER,OpenCSVParser.DEFAULT_STRICT_QUOTES, OpenCSVParser.DEFAULT_IGNORE_LEADING_WHITESPACE);
    	OpenCSVReader reader = new OpenCSVReader(parser,csvFile,newLineToUse,false);//unix user only \r //to false to allow double quote with comma: 123,"1,23"
    	List<List<String>>listAllRows = reader.readAll();

        reader = new OpenCSVReader(parser,csvFile, csv_separator) ;
        listAllRows = reader.readAll();
        reader.hasNext();
        reader.rewind();

        parser = new OpenCSVParser();
 
        parser.parseSimpleLine('Id,Name,Price');
        parser.parseLine('Small test,\"This is a test across \ntwo lines.\"');
        parser.isNextCharacterEscapable('test', false,1);
         
        parser.parseLine('\\\\1\\2\\\"3\\');
        parser.parseLine('\n\rtest\n\n\ntest\r\ntesttest,test\n\',"test3"');
         
        parser.parseLineMulti('test\n\n\n"test"\n\'test2\'\n"test3\ntest4"\n');
        parser.quoteInAnyElement(new List<String>{'t1'});
        parser.quoteInAnyElement(new List<String>{'"t1"'});
        parser.parseLine(null,false);
        Test.stopTest();
        
    }
}