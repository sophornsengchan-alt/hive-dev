declare module "@salesforce/apex/SEPDealContractAgreementController.getDealContractAgreement" {
  export default function getDealContractAgreement(param: {dcaId: any}): Promise<any>;
}
declare module "@salesforce/apex/SEPDealContractAgreementController.getDealContractAgreementData" {
  export default function getDealContractAgreementData(param: {dcaId: any}): Promise<any>;
}
declare module "@salesforce/apex/SEPDealContractAgreementController.doAgreeOrDeclineDealContractAgreement" {
  export default function doAgreeOrDeclineDealContractAgreement(param: {jsonData: any}): Promise<any>;
}
declare module "@salesforce/apex/SEPDealContractAgreementController.checkDCA" {
  export default function checkDCA(param: {dealId: any}): Promise<any>;
}
declare module "@salesforce/apex/SEPDealContractAgreementController.doApproveOrDeclineDeals" {
  export default function doApproveOrDeclineDeals(param: {dealIds: any, isSelected: any, declineReason: any, status: any, sellerId: any}): Promise<any>;
}
declare module "@salesforce/apex/SEPDealContractAgreementController.generateDealApprovedPDF" {
  export default function generateDealApprovedPDF(param: {dcaId: any}): Promise<any>;
}
declare module "@salesforce/apex/SEPDealContractAgreementController.getDealsRelatedToDCA" {
  export default function getDealsRelatedToDCA(param: {dcaId: any, mdtName: any}): Promise<any>;
}
declare module "@salesforce/apex/SEPDealContractAgreementController.getSelectedSellerDeclineReason" {
  export default function getSelectedSellerDeclineReason(param: {mdtName: any, objectApiName: any, fieldName: any}): Promise<any>;
}
declare module "@salesforce/apex/SEPDealContractAgreementController.doApproveOrDeclineSubsidizeDeals" {
  export default function doApproveOrDeclineSubsidizeDeals(param: {dealIds: any, isSelectedAll: any, declineReason: any, status: any, dcaId: any, totalRecord: any}): Promise<any>;
}
