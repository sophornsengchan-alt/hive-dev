declare module "@salesforce/apex/CloneQuoteController.apexInit" {
  export default function apexInit(param: {oppId: any}): Promise<any>;
}
declare module "@salesforce/apex/CloneQuoteController.apexSave" {
  export default function apexSave(param: {quoteId: any, oppId: any}): Promise<any>;
}
