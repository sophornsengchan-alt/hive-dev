declare module "@salesforce/apex/LinkedAccountsController.getAccounts" {
  export default function getAccounts(): Promise<any>;
}
declare module "@salesforce/apex/LinkedAccountsController.apexEbayConfirmIdentity" {
  export default function apexEbayConfirmIdentity(): Promise<any>;
}
declare module "@salesforce/apex/LinkedAccountsController.apexGetEbaySessionId" {
  export default function apexGetEbaySessionId(): Promise<any>;
}
declare module "@salesforce/apex/LinkedAccountsController.apexManageGroup" {
  export default function apexManageGroup(param: {groupName: any, groupId: any, mainAccId: any, newLinkAccountId: any, groupAt: any}): Promise<any>;
}
declare module "@salesforce/apex/LinkedAccountsController.removeLinkedAccount" {
  export default function removeLinkedAccount(param: {accId: any}): Promise<any>;
}
