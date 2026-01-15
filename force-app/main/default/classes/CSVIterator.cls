/*********************************************************************************************************************************
@ Class:         CSVIterator
@ Version:       1.0
@ Author:        vadhanak.vounr (vadhanak.voun@gaea-sys.com)
@ Purpose:       Generic CSV Iterator for big csv file processing
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.02.2020 / vadhanank voun (vadhanak.voun@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
global without sharing class CSVIterator implements Iterator<String>, Iterable<String>{	

	private String[] listCSVData;
	
   	private String newLine ;
   	private Boolean skipHeader;
   	public CSVIterator(String fileData, String newLine,Boolean skipHeader)
   	{
      	listCSVData = fileData.split(newLine);
      	this.newLine = newLine; 
      	this.skipHeader = skipHeader;
      	
      	if(skipHeader && hasNext())
      	{
      		next();
      	}
   	}
   	global Boolean hasNext()
   	{
      	return !listCSVData.isEmpty() ;
   	}
   	global String next()
   	{
   		String row = listCSVData.get(0);
      	//system.debug('>>>row: '+row);
      	listCSVData.remove(0);
      return row;
   	}
   	
   	global Iterator<String> Iterator()
   	{
      	return this;   
   	} 
		
}