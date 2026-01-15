/**
 Copyright 2005 Bytecode Pty Ltd.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

/**
 * A very simple CSV reader released under a commercial-friendly license.
 *
 * Java code Glen Smith.
 * Apex port Keith Clarke.
 */
public class OpenCSVReader {

    private String[] csvLines;
    private Integer lineIndex = 0;
    private Boolean hasNext = true;
    private OpenCSVParser parser;
    private Boolean isSimpleCSV = false;

    public OpenCSVReader(OpenCSVParser parser, String entireCsvFile, String lineSeparator) {
        // Java code uses a BufferedReader so this port is fairly different...
        this.csvLines = csvLines = entireCsvFile.split(lineSeparator);
        this.parser = parser;
    }

    public OpenCSVReader(OpenCSVParser parser, String entireCsvFile, String lineSeparator, Boolean simpleCSV) {
        // Java code uses a BufferedReader so this port is fairly different...
        this.csvLines = csvLines = entireCsvFile.split(lineSeparator);
        this.parser = parser;
        this.isSimpleCSV = simpleCSV;
    }

    /**
     * Reads the entire file into a List with each element being a List of tokens.
     * 
     * @return a List of List<String>, with each List<String> representing a line of the file.
     */
    public List<List<String>> readAll() {
        List<List<String>> allElements = new List<List<String>>();
        while (hasNext) {
            List<String> nextLineAsTokens = readNext();
            if (nextLineAsTokens != null) {
                allElements.add(nextLineAsTokens);
            }
        }
        return allElements;
    }

    /**
     * Reads the next line and converts to a string list.
     */
    public List<String> readNext() {
        List<String> result = null;
        do {
            String nextLine = getNextLine();
            if (!hasNext) {
                return result; // should throw if still pending?
            }
            List<String> r = isSimpleCSV ? parser.parseSimpleLine(nextLine) : parser.parseLineMulti(nextLine);
            if (result == null) {
                result = r;
            } else {
                result.addAll(r);
            }
        } while (parser.isPending());
        return result;
    }

    /**
     * Check whether there is next line.
     *
     * @return true if there is, false otherwise.
     */
    public Boolean hasNext() {
        return lineIndex < csvLines.size();
    }
    
    /**
     * Rewind the lines.
     */
    public void rewind() {
        lineIndex = 0;
    }
    
    /**
     * Reads the next line from the file.
     * 
     * @return the next line from the file without trailing newline
     */
    private String getNextLine() {
        hasNext = lineIndex < csvLines.size();
        return hasNext ? csvLines[lineIndex++] : null;
    }
    /*NK:23/11/2020:Not Used
    private static OpenCSVReader createReaderSpecialCases() {

        OpenCSVParser.StringBuilder sb = new OpenCSVParser.StringBuilder();
        sb.append('a,b,c').append('\n');   // standard case
        sb.append('a,\"b,b,b\",c').append('\n');  // quoted elements
        sb.append(',,').append('\n'); // empty elements
        sb.append('a,\"PO Box 123,\nKippax,ACT. 2615.\nAustralia\",d.\n');
        sb.append('\"Glen \"\"The Man\"\" Smith\",Athlete,Developer\n'); // Test quoted quote chars
        sb.append('\"\"\"\"\"\",\"test\","c"\n'); // """""","test","c"  representing:  "", test, c
        sb.append('\"a\nb\",b,\"\nd\"\n');
        
        // These tests just use new line as the separator
        return new OpenCSVReader (new OpenCSVParser(), sb.asString(), '\n');
    }
    
    private static OpenCSVReader createReaderSimpleData() {

        OpenCSVParser.StringBuilder sb = new OpenCSVParser.StringBuilder();
        sb.append('\"ID\",\"ISDELETED\",\"NAME\"').append('\n');
        sb.append('\"a0iA0000000UTcgIAG\",\"false\",\"PB-2010-1\"').append('\n');
        sb.append('\"a0iA0000000UTchIAG\",\"false\",\"PB-2010-2\"').append('\n');
        sb.append('\"a0iA0000000UTciIAG\",\"false\",\"PB-2010-3\"').append('\n');
        sb.append('\"a0iA0000000UTcjIAG\",\"false\",\"PB-2010-4\"').append('\n');
        sb.append('\"a0iA0000000UTckIAG\",\"false\",\"PB-2010-5\"').append('\n');
        // There was a bug with trailing empty cells
        sb.append('\"\",\"\",\"\"').append('\n');

        // These tests just use new line as the separator
        return new OpenCSVReader (new OpenCSVParser(), sb.asString(), '\n');
    }
   */
}