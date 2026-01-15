declare module "@salesforce/apex/CategoryTreeController.apexQueryCat" {
  export default function apexQueryCat(param: {country: any, parentBoBId: any, parentCatId: any, textSearch: any}): Promise<any>;
}
declare module "@salesforce/apex/CategoryTreeController.apexSaveCat" {
  export default function apexSaveCat(param: {parentBoBId: any, listSelectedCat: any}): Promise<any>;
}
