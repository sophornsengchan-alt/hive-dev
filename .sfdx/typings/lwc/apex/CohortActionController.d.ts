declare module "@salesforce/apex/CohortActionController.getBobSellerId" {
  export default function getBobSellerId(param: {bobId: any, fromCohort: any}): Promise<any>;
}
declare module "@salesforce/apex/CohortActionController.validateBeforeActivate" {
  export default function validateBeforeActivate(param: {bobId: any}): Promise<any>;
}
declare module "@salesforce/apex/CohortActionController.getBobSellerToActivate" {
  export default function getBobSellerToActivate(param: {bobId: any, listBsId: any, isInvitedToActive: any}): Promise<any>;
}
declare module "@salesforce/apex/CohortActionController.activateCohort" {
  export default function activateCohort(param: {bobId: any}): Promise<any>;
}
declare module "@salesforce/apex/CohortActionController.activateCohortSeller" {
  export default function activateCohortSeller(param: {bobId: any, listBsId: any, isInvitedToActive: any}): Promise<any>;
}
declare module "@salesforce/apex/CohortActionController.runActivateCohortSellerBatch" {
  export default function runActivateCohortSellerBatch(param: {bobId: any, listBsId: any}): Promise<any>;
}
declare module "@salesforce/apex/CohortActionController.getBobSellerToDeactivate" {
  export default function getBobSellerToDeactivate(param: {bobId: any, listBsId: any, isToDelete: any}): Promise<any>;
}
declare module "@salesforce/apex/CohortActionController.deactivateCohort" {
  export default function deactivateCohort(param: {bobId: any, listBsId: any}): Promise<any>;
}
declare module "@salesforce/apex/CohortActionController.deactivateCohortWhenNoCs" {
  export default function deactivateCohortWhenNoCs(param: {bobId: any}): Promise<any>;
}
declare module "@salesforce/apex/CohortActionController.runDeactivateCohortSellerBatch" {
  export default function runDeactivateCohortSellerBatch(param: {bobId: any, listBsId: any}): Promise<any>;
}
declare module "@salesforce/apex/CohortActionController.deleteCohortSeller" {
  export default function deleteCohortSeller(param: {listBsId: any}): Promise<any>;
}
