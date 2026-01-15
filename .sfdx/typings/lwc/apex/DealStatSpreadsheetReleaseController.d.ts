declare module "@salesforce/apex/DealStatSpreadsheetReleaseController.getSearchDealStatement" {
  export default function getSearchDealStatement(param: {status: any, ofst: any, lmt: any, search: any, sortByCol: any, colName: any, sortAction: any, listSentDs: any}): Promise<any>;
}
declare module "@salesforce/apex/DealStatSpreadsheetReleaseController.getDealStatement" {
  export default function getDealStatement(param: {status: any, ofst: any, lmt: any, listSentDs: any, defRecordType: any}): Promise<any>;
}
declare module "@salesforce/apex/DealStatSpreadsheetReleaseController.sendExcel" {
  export default function sendExcel(param: {listId: any}): Promise<any>;
}
declare module "@salesforce/apex/DealStatSpreadsheetReleaseController.checkUserPermission" {
  export default function checkUserPermission(): Promise<any>;
}
declare module "@salesforce/apex/DealStatSpreadsheetReleaseController.fetchRecordType" {
  export default function fetchRecordType(): Promise<any>;
}
