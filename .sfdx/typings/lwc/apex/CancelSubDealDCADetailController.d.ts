declare module "@salesforce/apex/CancelSubDealDCADetailController.apexInit" {
  export default function apexInit(param: {dcaId: any}): Promise<any>;
}
declare module "@salesforce/apex/CancelSubDealDCADetailController.apexCancelDeals" {
  export default function apexCancelDeals(param: {dcaId: any, cancelReason: any, currentChunk: any}): Promise<any>;
}
