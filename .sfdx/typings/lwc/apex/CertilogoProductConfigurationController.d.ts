declare module "@salesforce/apex/CertilogoProductConfigurationController.initData" {
  export default function initData(param: {opportunityId: any, pricebookId: any, sPricebookEntrytIds: any}): Promise<any>;
}
declare module "@salesforce/apex/CertilogoProductConfigurationController.saveRecords" {
  export default function saveRecords(param: {listRecord: any}): Promise<any>;
}
declare module "@salesforce/apex/CertilogoProductConfigurationController.validateProducts" {
  export default function validateProducts(param: {oppId: any, oppLineIds: any, buttonName: any, validations: any}): Promise<any>;
}
declare module "@salesforce/apex/CertilogoProductConfigurationController.getFieldSetFields" {
  export default function getFieldSetFields(param: {objectName: any, fieldSetName: any}): Promise<any>;
}
declare module "@salesforce/apex/CertilogoProductConfigurationController.submitProducts" {
  export default function submitProducts(param: {oppLineIds: any, buttonName: any, oppProdDoc: any, mAdditionalParams: any}): Promise<any>;
}
declare module "@salesforce/apex/CertilogoProductConfigurationController.mergeDocument" {
  export default function mergeDocument(param: {oppProdDocId: any, docRecordType: any}): Promise<any>;
}
