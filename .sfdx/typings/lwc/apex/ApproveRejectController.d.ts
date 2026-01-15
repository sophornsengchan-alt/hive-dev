declare module "@salesforce/apex/ApproveRejectController.apexInit" {
  export default function apexInit(param: {parentId: any}): Promise<any>;
}
declare module "@salesforce/apex/ApproveRejectController.apexDoApprove" {
  export default function apexDoApprove(param: {parentId: any, comments: any}): Promise<any>;
}
declare module "@salesforce/apex/ApproveRejectController.apexDoReject" {
  export default function apexDoReject(param: {parentId: any, comments: any}): Promise<any>;
}
