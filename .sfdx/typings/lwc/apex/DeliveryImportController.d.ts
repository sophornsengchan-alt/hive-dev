declare module "@salesforce/apex/DeliveryImportController.processImportDeliveryZone" {
  export default function processImportDeliveryZone(param: {zone: any}): Promise<any>;
}
declare module "@salesforce/apex/DeliveryImportController.processImportDeliveryRS_DailyZone" {
  export default function processImportDeliveryRS_DailyZone(param: {zone: any}): Promise<any>;
}
declare module "@salesforce/apex/DeliveryImportController.processImportDeliveryRS_MonthlyZone" {
  export default function processImportDeliveryRS_MonthlyZone(param: {zone: any}): Promise<any>;
}
declare module "@salesforce/apex/DeliveryImportController.processImportLast30Days" {
  export default function processImportLast30Days(param: {sobj: any}): Promise<any>;
}
declare module "@salesforce/apex/DeliveryImportController.doImport_ByDate" {
  export default function doImport_ByDate(param: {sobj: any, zone: any, startDate: any, endDate: any}): Promise<any>;
}
