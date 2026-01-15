declare module "@salesforce/apex/NewPricingRequestController.getCategories" {
  export default function getCategories(param: {searchKey: any, site: any, isChangeSite: any}): Promise<any>;
}
declare module "@salesforce/apex/NewPricingRequestController.getCategoryTree" {
  export default function getCategoryTree(param: {siteList: any, searchKey: any, isSearchCategory: any, isContractLA: any, cateLevel: any, cateList: any}): Promise<any>;
}
declare module "@salesforce/apex/NewPricingRequestController.getContractCategories" {
  export default function getContractCategories(param: {pricingId: any, site: any, queryAllCategoryTree: any, searchKey: any, isSearch: any, cateList: any, defExclCate: any}): Promise<any>;
}
