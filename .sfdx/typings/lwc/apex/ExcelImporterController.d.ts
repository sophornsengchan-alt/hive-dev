declare module "@salesforce/apex/ExcelImporterController.getExcelImporterTemplate" {
  export default function getExcelImporterTemplate(param: {templateName: any, parentId: any}): Promise<any>;
}
declare module "@salesforce/apex/ExcelImporterController.saveRecords" {
  export default function saveRecords(param: {sobjectApiName: any, operator: any, listRecord: any, templateName: any}): Promise<any>;
}
declare module "@salesforce/apex/ExcelImporterController.serverSidePreDMLCheck" {
  export default function serverSidePreDMLCheck(param: {className: any, methodName: any, mapArgs: any}): Promise<any>;
}
declare module "@salesforce/apex/ExcelImporterController.bulkExport" {
  export default function bulkExport(param: {templateName: any, parentId: any}): Promise<any>;
}
declare module "@salesforce/apex/ExcelImporterController.sendEmailResult" {
  export default function sendEmailResult(param: {insertedCount: any, listError: any}): Promise<any>;
}
declare module "@salesforce/apex/ExcelImporterController.apexProcessPostDML" {
  export default function apexProcessPostDML(param: {postData: any, templateName: any}): Promise<any>;
}
