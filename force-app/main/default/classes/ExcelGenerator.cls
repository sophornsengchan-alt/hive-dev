/*********************************************************************************************************************************
@ Class:          ExcelGenerator
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Generic class to generate xml excel
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.07.2019 / Vadhanak Voun / Created the class.
@				: 03.08.2020 / Vadhanak Voun / have predefine style of font color: f_red, f_green for cell value
@											/ e.g.g 20.0%__{!}__f_red
@				: 07.09.2023 / Mony Nou / US-0013897 - Deals Mass Payment File Generation (US/IT)
@											+ Add more predefined style ID
@												- b_yellow:  for yellow background (#FFFF00)
@												- f_bold: bold font 
*********************************************************************************************************************************/
public without sharing class ExcelGenerator {
	
	public static final String XLS_DATEFORMAT = 'YYYY-MM-dd\'T\'HH:mm:ss\'Z\''; //2019-03-15T12:56:18Z
	public final static String STYLE_SEP = '__!!__';

    String author;
    List<xSheet> listSheets;
	String workbookXML;
	Integer rowHeader;
	Boolean isCustomizedHeader = false; //MN-07092023-US-0013897

    public ExcelGenerator(String author,List<xSheet> listSheets)
    {
    	this.author = author;
    	this.listSheets = listSheets;
	}
	
	public ExcelGenerator(String author,List<xSheet> listSheets, Integer rowHeader)
    {
    	this.author = author;
		this.listSheets = listSheets;
		this.rowHeader = rowHeader;
    }
	//MN-07092023-US-0013897:New constructor for customized header cells
	public ExcelGenerator(String author,List<xSheet> listSheets, Boolean isCustomizedHeader)
    {
    	this.author = author;
    	this.listSheets = listSheets;
		this.isCustomizedHeader = isCustomizedHeader;
	}
    
    private String getTimeStamp()
    {
    	return System.now().format(XLS_DATEFORMAT);
    }
    
    public class xSheet{
    	public String sheetName;
    	public List<List<String>>lisRows;
    	
    	public xSheet(String sheetName,List<List<String>>lisRows)
    	{
    		this.sheetName = sheetName;
    		this.lisRows = lisRows;
    	}
    }
    
    private String generateWorkSheet(xSheet sheet1)
    {
    	String sheet_s = '<Worksheet ss:Name="'+sheet1.sheetName+'">'+
    	 '<Table ss:ExpandedColumnCount="11" ss:ExpandedRowCount="'+sheet1.lisRows.size()+'" x:FullColumns="1" x:FullRows="1" ss:DefaultColumnWidth="57" ss:DefaultRowHeight="15">'+
  		'<Column ss:AutoFitWidth="0" ss:Width="217.80000000000001"/>'+
  		'<Column ss:Width="268.8"/>'+
  		'<Column ss:AutoFitWidth="0" ss:Width="217.79999999999998"/>'+
  		((isCustomizedHeader)?'<Column ss:Width="565"/>':'<Column ss:AutoFitWidth="0" ss:Width="87"/>')+ //MN-07092023-US-0013897
  		'<Column ss:Width="77.399999999999991"/>'+
  		'<Column ss:AutoFitWidth="0" ss:Width="58.8"/>';
   		Integer i = 0;
   		for(List<String> row : sheet1.lisRows)
   		{
   			sheet_s += generateRow(row,(i==0 || (rowHeader != null && i == rowHeader)));
   			i++;
   		}
   		
   		sheet_s +='</Table>'+
   		'<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'+
   		'<PageSetup>'+
   		'<Header x:Margin="0.3"/>'+
   		'<Footer x:Margin="0.3"/>'+
   		'<PageMargins x:Bottom="0.78740157499999996" x:Left="0.7" x:Right="0.7" x:Top="0.78740157499999996"/>'+
   		'</PageSetup>'+
   		'<Unsynced/>'+
   		'<ProtectObjects>False</ProtectObjects>'+
   		'<ProtectScenarios>False</ProtectScenarios>'+
   		'</WorksheetOptions>'+
   		'</Worksheet>';
    	
    	return sheet_s;
    }    

    private String generateRow(List<String> row,Boolean isFirstRow)
    {
    	String row_s = '<Row ss:AutoFitHeight="0">';
    	for(String s: row)
    	{
			String styleId = (s+'').contains(STYLE_SEP) ? 'ss:StyleID="' + (s+'').split(STYLE_SEP)[1] + '"' : '';  
			/*
    		row_s+= isFirstRow?'<Cell ss:StyleID="s66"><Data ss:Type="String">'+s+'</Data></Cell>':
    			   '<Cell '+styleId+'><Data ss:Type="String">'+ (String.isBlank(styleId) ? s : (s+'').split(STYLE_SEP)[0] ) +'</Data></Cell>';*/
			
				   //MN-07092023-US-0013897: Enabled Header to be able to customized with predefined StyleId when isFirstRow = true and isCustomizedHeader = true
			row_s+= (isFirstRow && !isCustomizedHeader)?'<Cell ss:StyleID="s66"><Data ss:Type="String">'+s+'</Data></Cell>':
    			   '<Cell '+styleId+'><Data ss:Type="String">'+ (String.isBlank(styleId) ? s : (s+'').split(STYLE_SEP)[0] ) +'</Data></Cell>';
    	}
    	row_s+='</Row> ';
    	
    	return row_s;
    }
    
    public void generateWorkBook()
    {
    	workbookXML = ''+
    	'<?xml version="1.0"?>'+
    	'<?mso-application progid="Excel.Sheet"?>'+
    	'<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet" xmlns:html="http://www.w3.org/TR/REC-html40">'+
    	'<DocumentProperties xmlns="urn:schemas-microsoft-com:office:office">'+
    	'<Author>'+author+'</Author>'+
    	'<LastAuthor>'+author+'</LastAuthor>'+
    	'<TotalTime>0</TotalTime>'+
    	'<Created>'+getTimeStamp()+'</Created>'+
    	'<LastSaved>'+getTimeStamp()+'</LastSaved>'+
    	'<Company>eBay</Company>'+
    	'<Version>12.00</Version>'+
    	'</DocumentProperties>'+
    	'<OfficeDocumentSettings xmlns="urn:schemas-microsoft-com:office:office"><AllowPNG/></OfficeDocumentSettings>'+
    	'<ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel">'+
    	'<WindowHeight>9768</WindowHeight>'+
    	'<WindowWidth>23256</WindowWidth>'+
    	'<WindowTopX>0</WindowTopX>'+
    	'<WindowTopY>0</WindowTopY>'+
    	'<ProtectStructure>False</ProtectStructure>'+
    	'<ProtectWindows>False</ProtectWindows>'+
    	'</ExcelWorkbook>'+
    	'<Styles>'+
    	'<Style ss:ID="Default" ss:Name="Normal">'+
    	'<Alignment ss:Vertical="Bottom"/>'+
    	'<Borders/>'+
    	'<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000"/>'+
    	'<Interior/>'+
    	'<NumberFormat/>'+
    	'<Protection/>'+
    	'</Style>'+
    	'<Style ss:ID="s62">'+
    	'<Alignment ss:Horizontal="Center" ss:Vertical="Center"/>'+
    	'<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000" ss:Bold="1"/>'+
    	'<Interior ss:Color="#92D050" ss:Pattern="Solid"/>'+
    	'</Style>'+
    	'<Style ss:ID="s63">'+
    	'<Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'+
    	'<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000" ss:Bold="1"/>'+
    	'<Interior ss:Color="#92D050" ss:Pattern="Solid"/>'+
    	'</Style>'+
    	'<Style ss:ID="s64">'+
    	'<Alignment ss:Horizontal="Center" ss:Vertical="Center"/>'+
    	'<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000" ss:Bold="1"/>'+
    	'<Interior ss:Color="#92D050" ss:Pattern="Solid"/>'+
    	'<NumberFormat ss:Format="0"/>'+
    	'</Style>'+
    	'<Style ss:ID="s65">'+
    	'<NumberFormat ss:Format="0"/>'+
    	'</Style>'+
    	'<Style ss:ID="s66">'+
    	'<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000" ss:Bold="1"/>'+
    	'<Interior ss:Color="#92D050" ss:Pattern="Solid"/>'+
    	'</Style>'+
    	'<Style ss:ID="s67"><Borders/>'+
    	'</Style>'+
    	'<Style ss:ID="s68">'+
    	'<Alignment ss:Vertical="Center" ss:WrapText="1"/><Borders/>'+
    	'<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000"/>'+
    	'</Style>'+
		'<Style ss:ID="f_red"><Font ss:Color="#ff0000" ss:FontName="Arial" ss:Size="10"/></Style><Style ss:ID="f_green"><Font ss:Color="#127622" ss:FontName="Arial" ss:Size="10"/></Style>'+
		//MN-07092023-US-0013897: For yellow background cell
		'<Style ss:ID="b_yellow">'+
    	'<Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'+
    	'<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000" ss:Bold="1"/>'+
    	'<Interior ss:Color="#FFFF00" ss:Pattern="Solid"/>'+
    	'</Style>'+
		'<Style ss:ID="f_bold">'+
    	'<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000" ss:Bold="1"/>'+
    	'</Style>'+
    	'</Styles>';
    	 
    	 for(xSheet sheet: listSheets)
    	 {
    	 	workbookXML += generateWorkSheet(sheet);
    	 }
    	 
    	 workbookXML +='</Workbook>';
    }
    
    public String getWorkbookXML()
    {
    	return workbookXML;
    }
}