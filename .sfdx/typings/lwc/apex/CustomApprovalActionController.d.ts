declare module "@salesforce/apex/CustomApprovalActionController.getCurrentUserInfo" {
  export default function getCurrentUserInfo(): Promise<any>;
}
declare module "@salesforce/apex/CustomApprovalActionController.getApprovalHistory2" {
  export default function getApprovalHistory2(param: {parentId: any, limitClause: any, pendIngOnly: any}): Promise<any>;
}
declare module "@salesforce/apex/CustomApprovalActionController.doApprove" {
  export default function doApprove(param: {targetObjectId: any, comments: any}): Promise<any>;
}
declare module "@salesforce/apex/CustomApprovalActionController.doReject" {
  export default function doReject(param: {targetObjectId: any, comments: any}): Promise<any>;
}
declare module "@salesforce/apex/CustomApprovalActionController.doRecall" {
  export default function doRecall(param: {targetObjectId: any, comments: any}): Promise<any>;
}
declare module "@salesforce/apex/CustomApprovalActionController.getItemDetail" {
  export default function getItemDetail(param: {instId: any, itemId: any}): Promise<any>;
}
