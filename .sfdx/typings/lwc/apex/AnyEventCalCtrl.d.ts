declare module "@salesforce/apex/AnyEventCalCtrl.initLocalCode" {
  export default function initLocalCode(): Promise<any>;
}
declare module "@salesforce/apex/AnyEventCalCtrl.getAccounts" {
  export default function getAccounts(): Promise<any>;
}
declare module "@salesforce/apex/AnyEventCalCtrl.getCoupan" {
  export default function getCoupan(param: {couponObject: any, couponstartdate: any, couponenddate: any, dealRetailObject: any}): Promise<any>;
}
declare module "@salesforce/apex/AnyEventCalCtrl.getCalendarItems" {
  export default function getCalendarItems(param: {dateFrom: any, dateTo: any, statusFilter: any, searchingObj: any, sellers: any, metadata: any}): Promise<any>;
}
declare module "@salesforce/apex/AnyEventCalCtrl.fetchStatusFilterMetadata" {
  export default function fetchStatusFilterMetadata(param: {prefix: any, specificMeta: any}): Promise<any>;
}
