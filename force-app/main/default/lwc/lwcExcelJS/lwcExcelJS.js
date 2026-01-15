/*
 * author: Mony
 * lwcExcelJS.js
 * this file is used to download excel file using exceljs
 * IMPORTANT: Parent LWC that want to use below method(s), must load exceljs library
 */
import { loadScript } from "lightning/platformResourceLoader";//SRONG TIN - 05/12/2023 : US-0014342
import EXCELJSLIB from '@salesforce/resourceUrl/exceljs';//SRONG TIN - 05/12/2023 : US-0014342

class EXCELJS {
    parent;
    constructor(parent) {
        this.parent = parent;
        this.init();
    }

    init() {
        // SRONG TIN - 05/12/2023 : US-0014342
        window.regeneratorRuntime = undefined;
        loadScript(this.parent, EXCELJSLIB)
        .then(() => {
            console.log('ExcelJS loaded');
        })
        .catch(error => {
            console.error('Error loading ExcelJS', error);
        });
    }

    downloadGenerateExcel(jsonData, excelName, excelSheetName) {

        let workbook = new ExcelJS.Workbook();
        let worksheet = workbook.addWorksheet(excelSheetName);
        
        // Convert JSON data to Excel worksheet
        jsonData.forEach((record, index) => {
            if (index === 0) {
                worksheet.columns = Object.keys(record).map(key => ({ header: key, key: key }));
            }
            worksheet.addRow(record);
        });
    
        // Trigger download
        workbook.xlsx.writeBuffer().then(buffer => {
            
            let blob = new Blob([buffer], { type: 'application/octet-stream' });
            
            let url = URL.createObjectURL(blob);
            let a = document.createElement('a');
            a.href = url;
            a.download = excelName;
            a.click();
        });
    
    }
}
export{EXCELJS};