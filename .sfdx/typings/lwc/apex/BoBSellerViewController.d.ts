declare module "@salesforce/apex/BoBSellerViewController.queryAllBoBSellers" {
  export default function queryAllBoBSellers(param: {parentId: any, bsType: any, requestPage: any, searchKey: any}): Promise<any>;
}
declare module "@salesforce/apex/BoBSellerViewController.queryBoBInfo" {
  export default function queryBoBInfo(param: {parentId: any}): Promise<any>;
}
declare module "@salesforce/apex/BoBSellerViewController.apexReomveBoBSeller" {
  export default function apexReomveBoBSeller(param: {bobSellerId: any, status: any}): Promise<any>;
}
declare module "@salesforce/apex/BoBSellerViewController.apexUndoReomveBoBSeller" {
  export default function apexUndoReomveBoBSeller(param: {bobSellerId: any}): Promise<any>;
}
declare module "@salesforce/apex/BoBSellerViewController.apexCloneBoB" {
  export default function apexCloneBoB(param: {parentId: any}): Promise<any>;
}
declare module "@salesforce/apex/BoBSellerViewController.apexSubmitBoB" {
  export default function apexSubmitBoB(param: {parentId: any}): Promise<any>;
}
declare module "@salesforce/apex/BoBSellerViewController.apexBoBConfirmNew" {
  export default function apexBoBConfirmNew(param: {parentId: any}): Promise<any>;
}
declare module "@salesforce/apex/BoBSellerViewController.apexBoBConfirmRemove" {
  export default function apexBoBConfirmRemove(param: {parentId: any}): Promise<any>;
}
