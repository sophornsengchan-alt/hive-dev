declare module "@salesforce/apex/CustomDealController.getAccountIdUser" {
  export default function getAccountIdUser(): Promise<any>;
}
declare module "@salesforce/apex/CustomDealController.initData" {
  export default function initData(): Promise<any>;
}
declare module "@salesforce/apex/CustomDealController.getExistingDeals" {
  export default function getExistingDeals(param: {searchKey: any, sortedBy: any, sortedDirection: any}): Promise<any>;
}
declare module "@salesforce/apex/CustomDealController.apexUpdateDeal" {
  export default function apexUpdateDeal(param: {deal: any, isEnterEID: any}): Promise<any>;
}
declare module "@salesforce/apex/CustomDealController.getTodayDealSetting" {
  export default function getTodayDealSetting(param: {dealReatilCampaingId: any}): Promise<any>;
}
declare module "@salesforce/apex/CustomDealController.getTodayDEDealSetting" {
  export default function getTodayDEDealSetting(param: {dealReatilCampaingId: any, accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/CustomDealController.getDuplicateEbayItemID" {
  export default function getDuplicateEbayItemID(param: {dealReatilCampaingId: any, eBayItemId: any}): Promise<any>;
}
declare module "@salesforce/apex/CustomDealController.getSelectedCategories" {
  export default function getSelectedCategories(): Promise<any>;
}
declare module "@salesforce/apex/CustomDealController.getLinkedAccSpDeal" {
  export default function getLinkedAccSpDeal(): Promise<any>;
}
declare module "@salesforce/apex/CustomDealController.processDealCancellation" {
  export default function processDealCancellation(param: {dealId: any, cancelReason: any}): Promise<any>;
}
declare module "@salesforce/apex/CustomDealController.checkCurrentUserEligible" {
  export default function checkCurrentUserEligible(param: {mdtName: any, userID: any}): Promise<any>;
}
