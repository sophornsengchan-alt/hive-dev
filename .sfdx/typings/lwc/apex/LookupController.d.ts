declare module "@salesforce/apex/LookupController.doSearch" {
  export default function doSearch(param: {sobjType: any, key: any, displayEntity1: any, displayEntity2: any, displayEntity3: any}): Promise<any>;
}
declare module "@salesforce/apex/LookupController.doFullSearch" {
  export default function doFullSearch(param: {sobjectType: any, key: any, fullSearchFields: any, sortClause: any}): Promise<any>;
}
declare module "@salesforce/apex/LookupController.describeFieldsType" {
  export default function describeFieldsType(param: {sobjectType: any, strFullSearchFields: any}): Promise<any>;
}
