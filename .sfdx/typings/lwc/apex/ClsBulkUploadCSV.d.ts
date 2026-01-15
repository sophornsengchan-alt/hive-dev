declare module "@salesforce/apex/ClsBulkUploadCSV.doSubmitMultipleCouponItems" {
  export default function doSubmitMultipleCouponItems(param: {lstCPItems: any, csCouponType: any}): Promise<any>;
}
declare module "@salesforce/apex/ClsBulkUploadCSV.doSubmitMultipleDealsForDCA" {
  export default function doSubmitMultipleDealsForDCA(param: {lstDeals: any}): Promise<any>;
}
declare module "@salesforce/apex/ClsBulkUploadCSV.doSubmitMultipleDeals" {
  export default function doSubmitMultipleDeals(param: {lstDeals: any, accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/ClsBulkUploadCSV.doLoadSetting" {
  export default function doLoadSetting(param: {dealReatilCampaingId: any}): Promise<any>;
}
declare module "@salesforce/apex/ClsBulkUploadCSV.doLoadSettingLinkedAccount" {
  export default function doLoadSettingLinkedAccount(param: {dealReatilCampaingId: any, accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/ClsBulkUploadCSV.getDealRetailCampaign" {
  export default function getDealRetailCampaign(param: {recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/ClsBulkUploadCSV.getDealOverlapDateDRC" {
  export default function getDealOverlapDateDRC(param: {drcId: any, currUserLang: any}): Promise<any>;
}
declare module "@salesforce/apex/ClsBulkUploadCSV.doLoadCouponUploadItems" {
  export default function doLoadCouponUploadItems(param: {couponSellerId: any}): Promise<any>;
}
declare module "@salesforce/apex/ClsBulkUploadCSV.doLoadDCAUploadDeal" {
  export default function doLoadDCAUploadDeal(param: {dcaID: any}): Promise<any>;
}
