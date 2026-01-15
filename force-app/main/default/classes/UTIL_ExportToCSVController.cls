/**
 * Usage URL: /apex/UTIL_ExportToCSV?filename=filename.csv&columns=Col1,Col2&rows=Data1,Data2newlineData1,Data2&rowSep=newline
 */ 
public with sharing class UTIL_ExportToCSVController {
    
    public UTIL_ExportToCSVController() {
    
    }
    
    public List<String> getRows() {
        String exportRows = apexpages.currentpage().getparameters().get('rows');
        String rowSep = UTIL.getString(apexpages.currentpage().getparameters().get('rowSep'));
        if (String.isEmpty(exportRows)) return new List<String>();
        return exportRows.split(rowSep);
    }
}