declare module "@salesforce/apex/MassUploadObjectController.apexInit" {
  export default function apexInit(param: {settingName: any, drcId: any}): Promise<any>;
}
declare module "@salesforce/apex/MassUploadObjectController.doSaveChunkRecords" {
  export default function doSaveChunkRecords(param: {listChunk: any, rowColumns: any, csvRowCount: any, numFormat: any, setting: any, paramVal: any, defVal: any, sendResult: any, dateFormat: any, isPreview: any, fieldsiteColIndex: any, colVerticalIndex: any, colCategoryIndex: any, pklDepVertical: any, pklDepCategory: any, drcId: any}): Promise<any>;
}
declare module "@salesforce/apex/MassUploadObjectController.handleSendResult" {
  export default function handleSendResult(param: {insertedCount: any, listError: any}): Promise<any>;
}
declare module "@salesforce/apex/MassUploadObjectController.getDocumentUrl" {
  export default function getDocumentUrl(param: {sobjectApiName: any, isDealRetailCampaign: any}): Promise<any>;
}
