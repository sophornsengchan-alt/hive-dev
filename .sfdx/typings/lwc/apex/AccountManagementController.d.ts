declare module "@salesforce/apex/AccountManagementController.getSellerInfo" {
  export default function getSellerInfo(param: {sellerId: any}): Promise<any>;
}
declare module "@salesforce/apex/AccountManagementController.getActiveCohortSeller" {
  export default function getActiveCohortSeller(param: {sellerId: any}): Promise<any>;
}
declare module "@salesforce/apex/AccountManagementController.createSubscription" {
  export default function createSubscription(param: {sellerId: any}): Promise<any>;
}
declare module "@salesforce/apex/AccountManagementController.requestUnsubscription" {
  export default function requestUnsubscription(param: {sellerId: any}): Promise<any>;
}
declare module "@salesforce/apex/AccountManagementController.getAllAccounts" {
  export default function getAllAccounts(): Promise<any>;
}
declare module "@salesforce/apex/AccountManagementController.getAccountManagementMetadata" {
  export default function getAccountManagementMetadata(param: {metadataName: any}): Promise<any>;
}
declare module "@salesforce/apex/AccountManagementController.initDataBookingAdvertising" {
  export default function initDataBookingAdvertising(param: {cohortSellerId: any}): Promise<any>;
}
