/*********************************************************************************************************************************
@ Class:          ExcelImporterControllerSEPTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0013657 - Bulk Upload - Copy Paste Functionality in Seller Portal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 07.06.2023 / Sophal Noch / Create Class
*********************************************************************************************************************************/
@isTest
class ExcelImporterControllerSEPTest {
    
    @isTest
    private static void testGetExcelImporterTemplate() {
        // 07.06.2023 / Sophal Noch / US-0013657
        ExcelImporterControllerSEP.getExcelImporterTemplate('SEP_Upload_NA_Deal', null);
    }
}