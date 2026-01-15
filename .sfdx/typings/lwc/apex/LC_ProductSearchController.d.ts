declare module "@salesforce/apex/LC_ProductSearchController.initializeQuoteAndPricebookEntries" {
  export default function initializeQuoteAndPricebookEntries(param: {quoteId: any, productIds: any}): Promise<any>;
}
declare module "@salesforce/apex/LC_ProductSearchController.initializeData" {
  export default function initializeData(param: {quoteId: any}): Promise<any>;
}
declare module "@salesforce/apex/LC_ProductSearchController.saveQuoteLineItemsUsingMode" {
  export default function saveQuoteLineItemsUsingMode(param: {quoteId: any, quoteLineItems: any, mode: any, modeOverrideParamsJSON: any}): Promise<any>;
}
declare module "@salesforce/apex/LC_ProductSearchController.saveQuoteLineItemsWithDetails" {
  export default function saveQuoteLineItemsWithDetails(param: {quoteId: any, quoteLineItems: any}): Promise<any>;
}
declare module "@salesforce/apex/LC_ProductSearchController.saveQuoteLineItems" {
  export default function saveQuoteLineItems(param: {quoteId: any, quoteLineItems: any, additionalParam: any}): Promise<any>;
}
declare module "@salesforce/apex/LC_ProductSearchController.deleteQuoteLineItems" {
  export default function deleteQuoteLineItems(param: {quoteLineItemIds: any}): Promise<any>;
}
declare module "@salesforce/apex/LC_ProductSearchController.checkAvailability" {
  export default function checkAvailability(param: {quoteLineId: any}): Promise<any>;
}
declare module "@salesforce/apex/LC_ProductSearchController.searchPackage" {
  export default function searchPackage(param: {packageName: any, ids: any, quoteId: any}): Promise<any>;
}
declare module "@salesforce/apex/LC_ProductSearchController.copyTargetings" {
  export default function copyTargetings(param: {copyFromId: any, copyToIds: any}): Promise<any>;
}
declare module "@salesforce/apex/LC_ProductSearchController.getChildComponents" {
  export default function getChildComponents(param: {listMainQliId: any}): Promise<any>;
}
declare module "@salesforce/apex/LC_ProductSearchController.saveChildComponents" {
  export default function saveChildComponents(param: {quoteId: any, mainQli: any, childComponents: any, resetChanges: any}): Promise<any>;
}
