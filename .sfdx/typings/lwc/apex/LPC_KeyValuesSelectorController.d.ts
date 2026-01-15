declare module "@salesforce/apex/LPC_KeyValuesSelectorController.initKeyN" {
  export default function initKeyN(param: {lineItemId: any}): Promise<any>;
}
declare module "@salesforce/apex/LPC_KeyValuesSelectorController.initValueN" {
  export default function initValueN(param: {nodeId: any, valueSearch: any, quoteLineId: any}): Promise<any>;
}
declare module "@salesforce/apex/LPC_KeyValuesSelectorController.loadKeyValueTemplate" {
  export default function loadKeyValueTemplate(param: {itemId: any, targetId: any}): Promise<any>;
}
declare module "@salesforce/apex/LPC_KeyValuesSelectorController.apexBuildKeyValueString" {
  export default function apexBuildKeyValueString(param: {keyValueSetLstJSON: any}): Promise<any>;
}
declare module "@salesforce/apex/LPC_KeyValuesSelectorController.saveKeyValue" {
  export default function saveKeyValue(param: {lineItemId: any, keyValueSetList: any, finalKVString: any}): Promise<any>;
}
declare module "@salesforce/apex/LPC_KeyValuesSelectorController.saveKeyValueTemplate" {
  export default function saveKeyValueTemplate(param: {targetId: any, keyValueSetList: any}): Promise<any>;
}
