declare module "@salesforce/apex/UploadController.apexInit" {
  export default function apexInit(): Promise<any>;
}
declare module "@salesforce/apex/UploadController.checkPermissionFVFUser" {
  export default function checkPermissionFVFUser(): Promise<any>;
}
declare module "@salesforce/apex/UploadController.apexCouponCoInvestImport" {
  export default function apexCouponCoInvestImport(param: {parentId: any, csvString: any, listAllChunk: any, listIndex: any, csvFormat: any, numFormat: any}): Promise<any>;
}
declare module "@salesforce/apex/UploadController.apexCouponSellerImport" {
  export default function apexCouponSellerImport(param: {parentId: any, csvString: any, listAllChunk: any, listIndex: any, csvFormat: any, numFormat: any}): Promise<any>;
}
declare module "@salesforce/apex/UploadController.apexNominatedItemImport" {
  export default function apexNominatedItemImport(param: {parentId: any, csvString: any, listAllChunk: any, listIndex: any, isProductsUpload: any, allowOverrideListingId: any, numFormat: any, seperator: any}): Promise<any>;
}
declare module "@salesforce/apex/UploadController.apexFVFCampaignInit" {
  export default function apexFVFCampaignInit(param: {parentId: any}): Promise<any>;
}
declare module "@salesforce/apex/UploadController.apexBobInit" {
  export default function apexBobInit(param: {parentId: any}): Promise<any>;
}
declare module "@salesforce/apex/UploadController.apexImportSellerAndNominatedItemForFVFCampaign" {
  export default function apexImportSellerAndNominatedItemForFVFCampaign(param: {parentId: any, csvString: any, numFormat: any, seperator: any}): Promise<any>;
}
declare module "@salesforce/apex/UploadController.apexImportBobSeller" {
  export default function apexImportBobSeller(param: {parentId: any, csvString: any, numFormat: any, seperator: any}): Promise<any>;
}
declare module "@salesforce/apex/UploadController.getDocumentUrl" {
  export default function getDocumentUrl(param: {isBtnProduct: any, isfvfCampaign: any}): Promise<any>;
}
declare module "@salesforce/apex/UploadController.doSendEmailForReachingMaxRecord" {
  export default function doSendEmailForReachingMaxRecord(param: {itemId: any, insertCount: any, updateCount: any}): Promise<any>;
}
