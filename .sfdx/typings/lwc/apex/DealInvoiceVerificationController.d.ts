declare module "@salesforce/apex/DealInvoiceVerificationController.apexInit" {
  export default function apexInit(param: {parentId: any}): Promise<any>;
}
declare module "@salesforce/apex/DealInvoiceVerificationController.apexReadyPayment" {
  export default function apexReadyPayment(param: {parentId: any, recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/DealInvoiceVerificationController.apexReject" {
  export default function apexReject(param: {parentId: any, comments: any, recordId: any}): Promise<any>;
}
