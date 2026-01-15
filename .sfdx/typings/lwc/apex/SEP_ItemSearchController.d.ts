declare module "@salesforce/apex/SEP_ItemSearchController.getCategories" {
  export default function getCategories(param: {siteId: any}): Promise<any>;
}
declare module "@salesforce/apex/SEP_ItemSearchController.apexSearch" {
  export default function apexSearch(param: {sellerId: any, siteId: any, catId: any, brand: any, searchKey: any, searchOffset: any, searchLimit: any}): Promise<any>;
}
declare module "@salesforce/apex/SEP_ItemSearchController.apexGetItemDetail" {
  export default function apexGetItemDetail(param: {siteId: any, itemId: any}): Promise<any>;
}
declare module "@salesforce/apex/SEP_ItemSearchController.fetchSEPGlobalVarWithPrefix" {
  export default function fetchSEPGlobalVarWithPrefix(param: {prefix: any}): Promise<any>;
}
